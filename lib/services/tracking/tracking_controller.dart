import 'package:flutter/foundation.dart';

import '../simulation_engine.dart';
import 'ble_tracking_engine.dart';
import 'tracking_engine.dart';

/// Owns both tracking engines and exposes whichever one the app currently
/// runs on. BLE (the real ESP32 link) is the default; simulation is an
/// explicit offline/QA choice.
///
/// Notifications from either engine are forwarded, so widgets watching
/// the controller rebuild exactly as they did when they watched a single
/// engine directly.
class TrackingController extends ChangeNotifier {
  TrackingController({
    required BleTrackingEngine ble,
    required SimulationEngine simulation,
    TrackingSource initial = TrackingSource.ble,
  })  : _ble = ble,
        _simulation = simulation,
        _source = initial {
    _ble.addListener(notifyListeners);
    _simulation.addListener(notifyListeners);
  }

  final BleTrackingEngine _ble;
  final SimulationEngine _simulation;
  TrackingSource _source;

  BleTrackingEngine get ble => _ble;
  SimulationEngine get simulation => _simulation;
  TrackingSource get source => _source;

  TrackingEngine get engine =>
      _source == TrackingSource.ble ? _ble : _simulation;

  bool get isLive => _source == TrackingSource.ble;

  void useBle() {
    if (_source == TrackingSource.ble) return;
    _source = TrackingSource.ble;
    notifyListeners();
  }

  void useSimulation() {
    if (_source == TrackingSource.simulation) return;
    _source = TrackingSource.simulation;
    notifyListeners();
  }

  @override
  void dispose() {
    _ble.removeListener(notifyListeners);
    _simulation.removeListener(notifyListeners);
    super.dispose();
  }
}
