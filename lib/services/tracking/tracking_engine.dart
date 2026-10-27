import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../models/models.dart';

/// Where the tracking state comes from.
enum TrackingSource {
  /// Live ESP32 module over a real BLE GATT link.
  ble,

  /// Deterministic on-device simulation (offline development / QA staging).
  simulation,
}

/// The full tracking surface consumed by the UI.
///
/// Two implementations exist:
///  • [BleTrackingEngine] — real RSSI/link telemetry from the ESP32 module
///  • [SimulationEngine] — the deterministic Cairo-walk simulation
///
/// The presentation layer depends only on this interface, so switching
/// sources never changes a single widget.
abstract class TrackingEngine extends ChangeNotifier {
  TrackingSource get source;
  bool get isLive;

  // ── live state ────────────────────────────────────────────────────────
  LatLng get phonePos;
  LatLng get bagPos;
  double get distance;
  TrackStatus get status;
  BagDevice get bag;
  double get phoneBattery;

  /// Fix accuracy in meters; -1 when no fix/link is available.
  double get bagAccuracyM;
  bool get connectionCut;
  bool get lostAlertActive;
  int get panicPacketsSent;
  int get radioRetries;
  DateTime get lastPhoneFix;
  DateTime get lastBagFix;
  String? get scenarioPhase;
  bool get scenarioRunning;
  double get speedMultiplier;

  /// Servo-space bearing to the module (0–180°, 90 = straight ahead),
  /// available from the BLE radar sweep; null when unsupported/unknown.
  double? get bearingDeg;
  int get bearingConfidence;

  /// The ESP32 module is wired-powered and reports no battery percentage.
  bool get hasBattery;

  /// True once a live BLE session has connected at least once. Drives the
  /// distinction between "not paired yet" and "link just dropped".
  bool get everConnected;

  // ── history ───────────────────────────────────────────────────────────
  List<LatLng> get phoneRoute;
  List<LatLng> get bagRoute;
  List<TrackEvent> get events;
  List<DistanceSample> get distanceHistory;
  List<LatLng> get panicPings;

  // ── status helpers ────────────────────────────────────────────────────
  bool get radioOk;
  bool get isPanic;
  bool get inDanger;

  // ── threshold meters (instance accessors so charts stay source-agnostic)
  double get warningMeters;
  double get lostMeters;
  double get reconnectedMeters;

  // ── lifecycle ─────────────────────────────────────────────────────────
  void start();
  void resetSession({bool clearHistory = false});
  void markFound();
  void beginRecovery();
  void clearAlertFlag();

  // ── simulation-only controls (no-ops on the live engine) ─────────────
  void driftAway();
  void cutConnection();
  void enterPanic();
  void sendPanicPacket();
  void setSpeed(double v);
  void poseForShot(String state);
  void seedDemoHistory();
}
