import 'dart:async';

import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import '../ble/esp32_ble_service.dart';
import '../ble/rssi_model.dart';
import '../ble/telemetry.dart';
import '../settings_service.dart';
import 'tracking_engine.dart';

/// Live tracking engine driven by the ESP32 module over BLE.
///
/// Unlike the simulator, this engine never invents a measurement: every
/// distance/RSSI/bearing value comes from a telemetry frame, and every
/// state transition is caused by a real link event (frame, RSSI level or
/// GATT disconnect/reconnect).
///
/// Loss rules (the firmware clamps path-loss distance to 25 m, so RSSI
/// and link health carry the loss decision, matching the PRD's
/// "≥ 80 m **or** link drop" rule):
///  • warning  — RSSI ≤ −82 dBm or distance ≥ 30 m
///  • lost     — link drop or RSSI ≤ −94 dBm sustained 3 s → panic after
///               a 1.6 s grace beat, exactly like the simulated flow
///  • recovering — reconnect while a loss alert is active
///  • found    — explicit user confirmation ("I found my bag")
class BleTrackingEngine extends ChangeNotifier implements TrackingEngine {
  BleTrackingEngine(this._ble, this._settings) {
    _ble.addListener(_onBleChange);
    _rspSub = _ble.responses.listen(_onResponse);
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _onWatchdog());
    _bag = BagDevice(
      name: _ble.connectedName ?? 'Trackio ESP32',
      firmware: _firmware,
      batteryPct: 0,
      rssi: -100,
      radioLink: false,
      batteryAvailable: false,
    );
  }

  final Esp32BleService _ble;
  final SettingsService _settings;
  final RssiFilter _rssiFilter = RssiFilter();
  StreamSubscription<String>? _rspSub;

  // ── thresholds (dBm) — the module clamps distance at 25 m so the radio
  //    signal and link state are the primary loss cues.
  static const int warningRssiDbm = -82;
  static const int lostRssiDbm = -94;
  static const int releaseRssiDbm = -78;
  static const Duration weakLinkSustain = Duration(seconds: 3);
  static const Duration staleAfter = Duration(seconds: 4);

  /// The live module reports no geographic coordinates; BLE-mode widgets
  /// render the polar [RelativeRadarMap] and never read these. They exist
  /// only to satisfy the shared [TrackingEngine] surface.
  static final LatLng _noGeo = LatLng(0, 0);

  // ── live state ────────────────────────────────────────────────────────
  TrackStatus _status = TrackStatus.tracking;
  double _distance = 0;
  int _rssi = -100;
  late BagDevice _bag;
  double _accuracyM = -1;
  bool _lostAlertActive = false;
  int _panicPackets = 0;
  bool _everConnected = false;
  bool _returning = false;
  bool _warningFired = false;
  bool _lostFired = false;
  String _firmware = 'ESP32 follow-car · BLE';
  double? _bearingDeg;
  int _bearingConfidence = 0;
  DateTime? _weakSince;
  DateTime? _lastFrameAt;
  DateTime? _lastQuietLog;
  Timer? _watchdog;
  Timer? _panicTimer;
  BlePhase? _lastPhase;
  TelemetryFrame? _lastHandled;

  final List<TrackEvent> _events = [];
  final List<DistanceSample> _distanceHistory = [];
  int _frameCount = 0;

  @override
  TrackingSource get source => TrackingSource.ble;
  @override
  bool get isLive => true;
  @override
  bool get hasBattery => false;
  @override
  bool get everConnected => _everConnected;
  @override
  double get distance => _distance;
  @override
  TrackStatus get status => _status;
  @override
  BagDevice get bag => _bag;
  @override
  double get phoneBattery => 0;
  @override
  double get bagAccuracyM => _accuracyM;
  @override
  bool get connectionCut => !_ble.isConnected;
  @override
  bool get lostAlertActive => _lostAlertActive;
  @override
  int get panicPacketsSent => _panicPackets;
  @override
  int get radioRetries => _ble.reconnectAttempts;
  @override
  DateTime get lastPhoneFix => _lastFrameAt ?? DateTime.now();
  @override
  DateTime get lastBagFix => _lastFrameAt ?? DateTime.now();
  @override
  String? get scenarioPhase => null;
  @override
  bool get scenarioRunning => false;
  @override
  double get speedMultiplier => 1;
  @override
  double? get bearingDeg => _bearingDeg;
  @override
  int get bearingConfidence => _bearingConfidence;
  @override
  LatLng get phonePos => _noGeo;
  @override
  LatLng get bagPos => _noGeo;
  @override
  List<LatLng> get phoneRoute => const [];
  @override
  List<LatLng> get bagRoute => const [];
  @override
  List<TrackEvent> get events => List.unmodifiable(_events);
  @override
  List<DistanceSample> get distanceHistory => List.unmodifiable(_distanceHistory);
  @override
  List<LatLng> get panicPings => const [];
  @override
  bool get radioOk => _ble.isConnected;
  @override
  bool get isPanic => _status == TrackStatus.panic;
  @override
  bool get inDanger => _status == TrackStatus.lost || _status == TrackStatus.panic;
  @override
  double get warningMeters => SimulationThresholds.warningM;
  @override
  double get lostMeters => SimulationThresholds.lostM;
  @override
  double get reconnectedMeters => SimulationThresholds.reconnectedM;

  // ── BLE events ────────────────────────────────────────────────────────

  void _onBleChange() {
    final phase = _ble.phase;
    final wasConnected = _lastPhase == BlePhase.connected;
    final nowConnected = phase == BlePhase.connected;

    if (nowConnected && !wasConnected) _handleConnect();
    if (!nowConnected && wasConnected) _handleDisconnect();
    _lastPhase = phase;

    final frame = _ble.lastFrame;
    if (frame != null && frame != _lastHandled) {
      _lastHandled = frame;
      _handleFrame(frame);
    }
    notifyListeners();
  }

  /// Command responses: the `VER` reply carries the firmware identity.
  void _onResponse(String line) {
    if (line.contains('follow-car v')) {
      const marker = 'OK ';
      final i = line.indexOf(marker);
      if (i >= 0) {
        _firmware = line.substring(i + marker.length);
        _bag = _bag.copyWith(firmware: _firmware);
        notifyListeners();
      }
    }
  }

  void _handleConnect() {
    _rssiFilter.reset();
    _weakSince = null;
    _bag = _bag.copyWith(
      name: _ble.connectedName ?? _bag.name,
      radioLink: true,
      rssi: _rssi.toDouble(),
    );

    // A fresh link after a completed recovery starts a new watch session.
    if (_status == TrackStatus.found) {
      _status = TrackStatus.tracking;
      _lostFired = false;
      _warningFired = false;
      _returning = false;
    }

    if (!_everConnected) {
      _everConnected = true;
      _logEvent(TrackEventType.locationUpdate, code: 'sessionStarted');
      _logEvent(TrackEventType.reconnect, code: 'bleLinkUp');
    } else if (inDanger || _lostAlertActive) {
      // Reacquisition after a loss → guided recovery.
      _status = TrackStatus.recovering;
      _returning = true;
      _lostFired = false;
      _logEvent(
        TrackEventType.recovered,
        code: 'linkRestored',
        params: {
          'meters': _distance.round(),
          'accuracy': _accuracyM < 0 ? '—' : _accuracyM.toStringAsFixed(1),
        },
      );
    } else {
      _logEvent(TrackEventType.reconnect, code: 'bleLinkUp');
    }
  }

  void _handleDisconnect() {
    _bag = _bag.copyWith(radioLink: false, rssi: -100);
    _accuracyM = -1;
    _bearingDeg = null;
    _bearingConfidence = 0;
    _weakSince = null;
    if (!_everConnected || _status == TrackStatus.found) return;

    // A real link drop is a loss event — the alert cannot self-dismiss.
    _logEvent(TrackEventType.connectionLost, code: 'linkLost');
    if (!_lostFired) {
      _lostFired = true;
      _lostAlertActive = true;
      _status = TrackStatus.lost;
      _schedulePanic();
    }
  }

  void _handleFrame(TelemetryFrame f) {
    _lastFrameAt = f.receivedAt;

    // The module's own filtered RSSI is authoritative; run it through the
    // same EMA locally as a light smoothing stage.
    final filtered = _rssiFilter.update(f.rssi);
    _rssi = filtered == -100 ? f.rssi : filtered.round();

    // Prefer the module's path-loss distance; recompute locally when the
    // module reports an invalid one.
    var d = f.distanceM;
    if (d <= 0) {
      d = RssiModel.rssiToDistanceM(
        _rssi,
        rssiAt1m: _ble.rssiAt1m ?? RssiModel.defaultRssiAt1m,
        pathN: _ble.pathN ?? RssiModel.defaultPathN,
      );
    }
    if (d > 0) _distance = d;

    _accuracyM = (_distance * 0.3).clamp(0.5, 8.0);
    _bearingDeg = f.bearingDeg;
    _bearingConfidence = f.confidence;
    _bag = _bag.copyWith(radioLink: true, rssi: _rssi.toDouble());

    if (inDanger) {
      // Every frame during a loss is a live fix packet from the module.
      _panicPackets++;
      _logEvent(TrackEventType.panicSent,
          code: 'panicPacketN', params: {'n': _panicPackets}, quiet: true);
    }

    _recordHistory(f.receivedAt);
    if (!_returning) _evaluateThresholds();
  }

  void _evaluateThresholds() {
    if (_status == TrackStatus.found) return;

    if (_rssi <= lostRssiDbm || _distance >= lostMeters) {
      _weakSince ??= DateTime.now();
      if (_weakSince != null &&
          DateTime.now().difference(_weakSince!) >= weakLinkSustain &&
          !_lostFired) {
        _lostFired = true;
        _lostAlertActive = true;
        _status = TrackStatus.lost;
        _logEvent(TrackEventType.lost,
            code: 'linkLost',
            params: {'meters': _distance.round(), 'limit': lostMeters.round()});
        _schedulePanic();
      }
      return;
    }

    if ((_rssi <= warningRssiDbm || _distance >= warningMeters) && !_warningFired) {
      _warningFired = true;
      if (_status == TrackStatus.tracking) {
        _status = TrackStatus.warning;
        _logEvent(TrackEventType.warning,
            code: 'bleWeakLink', params: {'rssi': _rssi});
      }
    } else if (_rssi >= releaseRssiDbm && _distance < warningMeters) {
      _weakSince = null;
      _warningFired = false;
      _lostFired = false;
      if (_status == TrackStatus.warning) _status = TrackStatus.tracking;
    }
  }

  void _onWatchdog() {
    // Stale frames while the GATT still claims connected → treat as drop.
    final last = _lastFrameAt;
    if (_ble.isConnected &&
        last != null &&
        DateTime.now().difference(last) > staleAfter &&
        _everConnected &&
        _status != TrackStatus.found) {
      _handleDisconnect();
    }
    notifyListeners();
  }

  void _schedulePanic() {
    _panicTimer?.cancel();
    _panicTimer = Timer(const Duration(milliseconds: 1600), () {
      if (inDanger || _lostAlertActive) {
        _status = TrackStatus.panic;
        _logEvent(TrackEventType.panicSent, code: 'panicPacket');
        notifyListeners();
      }
    });
  }

  void _recordHistory(DateTime at) {
    _frameCount++;
    final cadence = (_settings.recheckIntervalS * 2).clamp(1, 120); // 2 Hz frames
    if (_frameCount % cadence != 0) return;
    _distanceHistory.add(DistanceSample(time: at, meters: _distance, wasLost: inDanger));
    if (_distanceHistory.length > 400) _distanceHistory.removeAt(0);

    // Periodic quiet telemetry event, mirroring the simulator's bag-fix log.
    if (_lastQuietLog == null || at.difference(_lastQuietLog!) >= const Duration(seconds: 10)) {
      _lastQuietLog = at;
      _logEvent(
        TrackEventType.locationUpdate,
        code: 'bleTelemetry',
        params: {'accuracy': _accuracyM.toStringAsFixed(1)},
        quiet: true,
      );
    }
  }

  void _logEvent(TrackEventType type,
      {required String code, Map<String, Object> params = const {}, bool quiet = false}) {
    _events.add(TrackEvent(time: DateTime.now(), type: type, code: code, params: params));
    if (_events.length > 300) _events.removeAt(0);
  }

  // ── TrackingEngine controls ───────────────────────────────────────────

  @override
  void start() => notifyListeners();

  @override
  void resetSession({bool clearHistory = false}) {
    _panicTimer?.cancel();
    if (clearHistory) {
      _events.clear();
      _distanceHistory.clear();
    }
    _frameCount = 0;
    _panicPackets = 0;
    _lostAlertActive = false;
    _warningFired = false;
    _lostFired = false;
    _returning = false;
    _weakSince = null;
    _status = TrackStatus.tracking;
    notifyListeners();
  }

  @override
  void markFound() {
    _panicTimer?.cancel();
    _status = TrackStatus.found;
    _lostAlertActive = false;
    _returning = false;
    _lostFired = false;
    _warningFired = false;
    _logEvent(TrackEventType.found,
        code: 'recoveryConfirmed', params: {'meters': _distance.round()});
    notifyListeners();
  }

  @override
  void beginRecovery() {
    _returning = true;
    if (inDanger || _status == TrackStatus.warning) {
      _status = TrackStatus.recovering;
      _logEvent(TrackEventType.recovered, code: 'recoveryStarted');
    }
    notifyListeners();
  }

  @override
  void clearAlertFlag() {
    _lostAlertActive = false;
    notifyListeners();
  }

  // ── simulation-only surface: honest no-ops / link actions ────────────

  @override
  void driftAway() {}

  @override
  void cutConnection() => _ble.disconnect();

  @override
  void enterPanic() {}

  @override
  void sendPanicPacket() {}

  @override
  void setSpeed(double v) {}

  @override
  void poseForShot(String state) {}

  @override
  void seedDemoHistory() {}

  @override
  void dispose() {
    _watchdog?.cancel();
    _panicTimer?.cancel();
    _rspSub?.cancel();
    _ble.removeListener(_onBleChange);
    super.dispose();
  }
}

/// Threshold constants shared with the simulator's state machine.
class SimulationThresholds {
  const SimulationThresholds._();
  static const double warningM = 30;
  static const double lostM = 80;
  static const double reconnectedM = 25;
}
