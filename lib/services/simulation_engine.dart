import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import 'settings_service.dart';
import 'tracking/tracking_engine.dart';

/// Deterministic offline/QA implementation of [TrackingEngine].
///
/// The live app runs [BleTrackingEngine] against real ESP32 hardware; this
/// simulation is the explicit "Explore without hardware" source and the
/// engine behind the `?shot=…` staging deep links and scripted demo scenario.
/// It reproduces the complete pipeline:
///
///  • phone GPS + bag GPS + radio (ESP32) fixes fused into one distance signal
///  • continuous distance monitoring with warning / lost thresholds
///  • panic-packet mode with high-frequency, high-accuracy bag fixes
///  • connection loss + automatic reconnection attempts
///  • full event + distance history for the History screen
///
/// Both engines implement the same [TrackingEngine] surface, so the
/// presentation layer never knows which source is active.
class SimulationEngine extends ChangeNotifier implements TrackingEngine {
  SimulationEngine(this._settings);

  final SettingsService _settings;
  final Distance _dist = const Distance();
  final math.Random _rng = math.Random();

  // ── TrackingEngine source identity ──────────────────────────────────
  @override
  TrackingSource get source => TrackingSource.simulation;
  @override
  bool get isLive => false;
  @override
  bool get hasBattery => true;
  @override
  bool get everConnected => true;
  @override
  double? get bearingDeg => null;
  @override
  int get bearingConfidence => 0;
  @override
  double get warningMeters => warningM;
  @override
  double get lostMeters => lostM;
  @override
  double get reconnectedMeters => reconnectedM;

  // ── tuning ────────────────────────────────────────────────────────────
  static const double warningM = 30;
  static const double lostM = 80;
  static const double reconnectedM = 25;
  static const double nearM = 9;
  static const Duration tickEvery = Duration(milliseconds: 900);
  static const LatLng zamalekStart = LatLng(30.0605, 31.2148); // Zamalek, Cairo

  // ── live state ────────────────────────────────────────────────────────
  LatLng phonePos = zamalekStart;
  LatLng bagPos = zamalekStart;
  double distance = 4;
  TrackStatus status = TrackStatus.tracking;
  BagDevice bag = BagDevice(
    name: 'Trackio One · #A41F',
    firmware: 'fw 2.4.1 · ESP32-WROOM',
    batteryPct: 78,
    rssi: -52,
    radioLink: true,
  );
  double phoneBattery = 64;
  double bagAccuracyM = 8; // meters; drops to ~3 in panic mode
  bool connectionCut = false;
  bool lostAlertActive = false;
  int panicPacketsSent = 0;
  int radioRetries = 0;
  DateTime lastPhoneFix = DateTime.now();
  DateTime lastBagFix = DateTime.now();
  String? scenarioPhase;        // machine-readable demo phase (caption resolved in UI)
  bool scenarioRunning = false;
  double speedMultiplier = 1;   // 1x / 4x / 8x for scripted scenarios

  // ── history ───────────────────────────────────────────────────────────
  final List<LatLng> phoneRoute = [];
  final List<LatLng> bagRoute = [];
  final List<TrackEvent> events = [];
  final List<DistanceSample> distanceHistory = [];
  final List<LatLng> panicPings = [];

  // ── internal ──────────────────────────────────────────────────────────
  Timer? _timer;
  int _tick = 0;
  int _routeIdx = 0;
  LatLng? _bagLeftSpot;        // where the bag was left behind
  bool _phoneReturning = false;
  bool _warningFired = false;
  bool _lostFired = false;
  bool _reconnectFired = false;

  /// Walking loop around Zamalek island (lon, lat), ~1.9 km.
  static const List<List<double>> _loop = [
    [31.2140, 30.0568], [31.2158, 30.0592], [31.2166, 30.0618],
    [31.2182, 30.0641], [31.2201, 30.0656], [31.2226, 30.0660],
    [31.2251, 30.0652], [31.2266, 30.0631], [31.2270, 30.0606],
    [31.2260, 30.0582], [31.2242, 30.0566], [31.2216, 30.0558],
    [31.2188, 30.0556], [31.2162, 30.0560],
  ];

  bool get radioOk => bag.radioLink;
  bool get isPanic => status == TrackStatus.panic;
  bool get inDanger => status == TrackStatus.lost || status == TrackStatus.panic;

  void start() {
    _timer ??= Timer.periodic(tickEvery, (_) => _step());
    phoneRoute
      ..clear()
      ..add(phonePos);
    bagRoute
      ..clear()
      ..add(bagPos);
    _logEvent(TrackEventType.locationUpdate, code: 'sessionStarted');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── simulation step ───────────────────────────────────────────────────
  void _step() {
    _tick++;
    final stepM = 1.6 * speedMultiplier;

    // 1. move the phone (returning home during recovery, else loop walk)
    if (_phoneReturning) {
      phonePos = _advanceToward(phonePos, bagPos, stepM * 2.1);
    } else {
      phonePos = _advanceAlongLoop(phonePos, stepM);
    }
    phoneRoute.add(phonePos);

    // 2. bag position model
    if (_bagLeftSpot != null) {
      bagPos = _bagLeftSpot!; // left behind, static (or tiny drift in panic: GPS jitter)
      if (isPanic) bagPos = _jitter(bagPos, 0.00004);
    } else {
      // carried with the user, trailing a believable 4-9 m behind
      final t = _tick * 0.045;
      bagPos = LatLng(
        phonePos.latitude - 0.00006 - 0.00002 * math.sin(t),
        phonePos.longitude - 0.00004 - 0.00002 * math.cos(t),
      );
      bagPos = _jitter(bagPos, 0.000015);
    }
    if (bagRoute.isEmpty || bagRoute.last != bagPos) bagRoute.add(bagPos);

    // 3. distance
    distance = _dist(phonePos, bagPos);

    // 4. recovery conclusion
    if (_phoneReturning && distance <= reconnectedM && !_reconnectFired) {
      _reconnectFired = true;
      if (connectionCut) _restoreConnection(logIt: true);
      if (status == TrackStatus.panic || status == TrackStatus.lost) {
        status = TrackStatus.recovering;
        scenarioPhase = 'reconnected';
        _logEvent(TrackEventType.recovered,
            code: 'linkRestored',
            params: {'meters': distance.round(), 'accuracy': bagAccuracyM.toStringAsFixed(1)});
      }
    }
    if (_phoneReturning && distance <= nearM) {
      scenarioPhase = 'near';
    }

    // 5. signals / thresholds
    _updateSignals();
    _evaluateThresholds();

    // 6. periodic records (settings-driven cadence)
    _recordPeriodic();

    // 7. drains
    bag = bag.copyWith(
      batteryPct: math.max(5, bag.batteryPct - 0.004 * speedMultiplier),
      radioLink: bag.radioLink,
    );
    phoneBattery = math.max(2, phoneBattery - 0.003 * speedMultiplier);

    notifyListeners();
  }

  LatLng _advanceAlongLoop(LatLng p, double stepM) {
    final target = LatLng(_loop[(_routeIdx + 1) % _loop.length][1], _loop[(_routeIdx + 1) % _loop.length][0]);
    final moved = _advanceToward(p, target, stepM);
    if (_dist(p, target) < 6) _routeIdx = (_routeIdx + 1) % _loop.length;
    return moved;
  }

  LatLng _advanceToward(LatLng from, LatLng to, double stepM) {
    final d = _dist(from, to);
    if (d <= stepM) return to;
    final f = stepM / d;
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * f,
      from.longitude + (to.longitude - from.longitude) * f,
    );
  }

  LatLng _jitter(LatLng p, double amt) => LatLng(
        p.latitude + (_rng.nextDouble() - 0.5) * amt * 2,
        p.longitude + (_rng.nextDouble() - 0.5) * amt * 2,
      );

  void _updateSignals() {
    if (connectionCut) {
      bag = bag.copyWith(rssi: -100, radioLink: false);
      bagAccuracyM = -1; // no fix
    } else {
      final rssi = (-40 - 0.42 * math.min(distance, 160)).clamp(-100, -40).toDouble();
      bag = bag.copyWith(rssi: rssi, radioLink: true);
      final base = isPanic ? 3.0 : 9.0;
      bagAccuracyM = base + _rng.nextDouble() * (isPanic ? 1.5 : 5);
      lastBagFix = DateTime.now();
    }
    lastPhoneFix = DateTime.now();
  }

  void _evaluateThresholds() {
    if (status == TrackStatus.found) return;
    if (distance >= lostM && !_lostFired) {
      _lostFired = true;
      lostAlertActive = true;
      status = TrackStatus.lost;
      scenarioPhase = 'lost';
      _logEvent(TrackEventType.lost,
          code: 'distanceExceeded',
          params: {'meters': distance.round(), 'limit': lostM.round()});
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (inDanger || lostAlertActive) enterPanic();
      });
    } else if (distance >= warningM && !_warningFired) {
      _warningFired = true;
      if (status == TrackStatus.tracking) {
        status = TrackStatus.warning;
        scenarioPhase = 'warning';
        _logEvent(TrackEventType.warning, code: 'unusualDistance', params: {'meters': distance.round()});
      }
    } else if (distance < warningM) {
      _warningFired = false;
      _lostFired = _phoneReturning ? _lostFired : false;
      if (!_phoneReturning && status == TrackStatus.warning) {
        status = TrackStatus.tracking;
        scenarioPhase = null;
      }
    }
  }

  void _recordPeriodic() {
    final recheckEvery = (_settings.recheckIntervalS / 0.9).round().clamp(1, 60);
    if (_tick % recheckEvery == 0) {
      distanceHistory.add(DistanceSample(
        time: DateTime.now(),
        meters: distance,
        wasLost: inDanger,
      ));
      if (distanceHistory.length > 400) distanceHistory.removeAt(0);
    }
    final bagEvery = (_settings.bagGpsIntervalS / 0.9).round().clamp(1, 60);
    if (_tick % bagEvery == 0 && radioOk && status != TrackStatus.found) {
      _logEvent(
        TrackEventType.locationUpdate,
        code: isPanic ? 'bagGpsFixPanic' : 'bagGpsFix',
        params: {'accuracy': bagAccuracyM.toStringAsFixed(1)},
        quiet: true,
      );
    }
  }

  void _logEvent(TrackEventType type, {required String code, Map<String, Object> params = const {}, bool quiet = false}) {
    events.add(TrackEvent(time: DateTime.now(), type: type, code: code, params: params));
    if (events.length > 300) events.removeAt(0);
    if (!quiet && kDebugMode) {
      // ignore: avoid_print
      print('[trackio] $type $code $params');
    }
  }

  // ── manual demo triggers ──────────────────────────────────────────────

  /// Bag left behind — engine starts warning/losing naturally.
  void driftAway() {
    if (_bagLeftSpot != null) return;
    _bagLeftSpot = bagPos;
    scenarioPhase = 'drifting';
    _logEvent(TrackEventType.warning, code: 'motionChanged');
  }

  void cutConnection() {
    if (connectionCut) return;
    connectionCut = true;
    _logEvent(TrackEventType.connectionLost, code: 'linkLost');
    _startRadioRetry();
    notifyListeners();
  }

  void _startRadioRetry() {
    Timer.periodic(const Duration(milliseconds: 1400), (t) {
      radioRetries++;
      if (!connectionCut) {
        t.cancel();
      } else if (distance < reconnectedM || radioRetries > 40) {
        t.cancel();
        _restoreConnection(logIt: true);
      }
      notifyListeners();
    });
  }

  void _restoreConnection({bool logIt = false}) {
    connectionCut = false;
    radioRetries = 0;
    bagAccuracyM = 8;
    if (logIt) _logEvent(TrackEventType.reconnect, code: 'linkReestablished');
    notifyListeners();
  }

  void enterPanic() {
    if (status == TrackStatus.panic || status == TrackStatus.found) return;
    status = TrackStatus.panic;
    scenarioPhase = 'panic';
    _logEvent(TrackEventType.panicSent, code: 'panicPacket');
    panicPings.add(bagPos);
    notifyListeners();
  }

  void sendPanicPacket() {
    panicPacketsSent++;
    _logEvent(TrackEventType.panicSent, code: 'panicPacketN', params: {'n': panicPacketsSent}, quiet: true);
    notifyListeners();
  }

  void beginRecovery() {
    _phoneReturning = true;
    _reconnectFired = false;
    if (status == TrackStatus.tracking || status == TrackStatus.warning) {
      status = TrackStatus.recovering;
    }
    scenarioPhase = 'recovering';
    _logEvent(TrackEventType.recovered, code: 'recoveryStarted');
    notifyListeners();
  }

  void markFound() {
    status = TrackStatus.found;
    lostAlertActive = false;
    scenarioPhase = 'found';
    scenarioRunning = false;
    _phoneReturning = false;
    _bagLeftSpot = null;
    _logEvent(TrackEventType.found, code: 'recoveryConfirmed', params: {'meters': distance.round()});
    notifyListeners();
  }

  void resetSession({bool clearHistory = false}) {
    if (clearHistory) {
      events.clear();
      distanceHistory.clear();
    }
    phoneRoute.clear();
    bagRoute.clear();
    panicPings.clear();
    _routeIdx = 0;
    _tick = 0;
    _bagLeftSpot = null;
    _phoneReturning = false;
    _warningFired = false;
    _lostFired = false;
    _reconnectFired = false;
    connectionCut = false;
    radioRetries = 0;
    panicPacketsSent = 0;
    lostAlertActive = false;
    status = TrackStatus.tracking;
    scenarioPhase = null;
    scenarioRunning = false;
    phonePos = zamalekStart;
    bagPos = zamalekStart;
    distance = 4;
    bag = BagDevice(
      name: 'Trackio One · #A41F',
      firmware: 'fw 2.4.1 · ESP32-WROOM',
      batteryPct: 78,
      rssi: -52,
      radioLink: true,
    );
    phoneBattery = 64;
    start();
    notifyListeners();
  }

  /// Public notifier for the scenario director (ChangeNotifier.notifyListeners is protected).
  void notifyUI() => notifyListeners();

  void setSpeed(double v) {
    speedMultiplier = v;
    notifyListeners();
  }

  void clearAlertFlag() {
    lostAlertActive = false;
    notifyListeners();
  }

  // ── demo QA scaffolding ───────────────────────────────────────────────
  // Deterministic pose presets for screenshots / walkthroughs (?shot=…).
  // Not used by the production pipeline.

  void poseForShot(String state) {
    resetSession(clearHistory: true);
    seedDemoHistory();
    final base = zamalekStart;
    switch (state) {
      case 'warning':
        _bagLeftSpot = LatLng(base.latitude + 0.00035, base.longitude + 0.00030);
        bagPos = _bagLeftSpot!;
        distance = 46;
        status = TrackStatus.warning;
        _logEvent(TrackEventType.warning, code: 'unusualDistance', params: {'meters': 46});
      case 'alert' || 'panic' || 'lost':
        _bagLeftSpot = LatLng(base.latitude + 0.00085, base.longitude + 0.00075);
        bagPos = _bagLeftSpot!;
        distance = 128;
        status = TrackStatus.panic;
        lostAlertActive = true;
        panicPacketsSent = 14;
        panicPings.add(bagPos);
        scenarioPhase = 'panic';
        _logEvent(TrackEventType.lost, code: 'distanceExceeded', params: {'meters': 128, 'limit': 80});
        _logEvent(TrackEventType.panicSent, code: 'panicPacket');
      case 'found':
        status = TrackStatus.found;
        scenarioPhase = 'found';
        _logEvent(TrackEventType.found, code: 'recoveryConfirmed', params: {'meters': 7});
      case 'recovering':
        _bagLeftSpot = LatLng(base.latitude + 0.00042, base.longitude + 0.00036);
        bagPos = _bagLeftSpot!;
        distance = 52;
        status = TrackStatus.recovering;
        scenarioPhase = 'recovering';
        _logEvent(TrackEventType.recovered, code: 'recoveryStarted');
      default:
        break;
    }
    // give routes a believable breadcrumb trail
    for (var i = 8; i >= 1; i--) {
      phoneRoute.add(LatLng(
        phonePos.latitude - 0.00008 * i,
        phonePos.longitude - 0.00006 * i,
      ));
      bagRoute.add(LatLng(
        bagPos.latitude - 0.000012 * i,
        bagPos.longitude - 0.000010 * i,
      ));
    }
    start();
    notifyListeners();
  }

  /// Populates a believable tracking history so the History screen tells a
  /// full story from the first launch of the demo.
  void seedDemoHistory() {
    final now = DateTime.now();
    // yesterday's session (clean)
    final t0 = now.subtract(const Duration(hours: 26));
    for (var i = 0; i < 48; i++) {
      // narrative: calm morning, loss spike at minute 44, recovery by 52
      double m;
      if (i < 42) {
        m = 4 + _rng.nextDouble() * 14;
      } else if (i < 44) {
        m = 25 + _rng.nextDouble() * 25;        // drifting away
      } else if (i < 50) {
        m = 78 + _rng.nextDouble() * 50;        // lost · panic tracking
      } else {
        m = 60 - (i - 50) * 12 + _rng.nextDouble() * 6; // recovering
      }
      distanceHistory.add(DistanceSample(
        time: t0.add(Duration(minutes: i * 2)),
        meters: m.clamp(2, 140),
        wasLost: i >= 44 && i < 50,
      ));
    }
    events.addAll([
      TrackEvent(
        time: t0,
        type: TrackEventType.locationUpdate,
        code: 'sessionStarted',
      ),
      TrackEvent(
        time: t0.add(const Duration(minutes: 41)),
        type: TrackEventType.warning,
        code: 'unusualDistance',
        params: {'meters': 34},
      ),
      TrackEvent(
        time: t0.add(const Duration(minutes: 44)),
        type: TrackEventType.lost,
        code: 'distanceExceeded',
        params: {'meters': 96, 'limit': 80},
      ),
      TrackEvent(
        time: t0.add(const Duration(minutes: 44, seconds: 8)),
        type: TrackEventType.panicSent,
        code: 'panicPacket',
      ),
      TrackEvent(
        time: t0.add(const Duration(minutes: 52)),
        type: TrackEventType.recovered,
        code: 'linkRestored',
        params: {'meters': 18, 'accuracy': '3.2'},
      ),
      TrackEvent(
        time: t0.add(const Duration(minutes: 57)),
        type: TrackEventType.found,
        code: 'recoveryConfirmed',
        params: {'meters': 6},
      ),
    ]);
    // today's calm session
    for (var i = 0; i < 20; i++) {
      distanceHistory.add(DistanceSample(
        time: now.subtract(Duration(minutes: 40 - i * 2)),
        meters: 3 + _rng.nextDouble() * 10,
        wasLost: false,
      ));
    }
    distanceHistory.sort((a, b) => a.time.compareTo(b.time));
  }
}
