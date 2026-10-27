import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_profile.dart';
import 'telemetry.dart';

/// Lifecycle phase of the BLE link, surfaced directly to the connect
/// screen and the device control panel.
enum BlePhase {
  unsupported,
  bluetoothOff,
  idle,
  scanning,
  connecting,
  pairing,
  discovering,
  connected,
  reconnecting,
  disconnected,
}

/// Plugin-free scan candidate so UI layers never import flutter_blue_plus.
class BleDeviceCandidate {
  final String id;
  final String name;
  final int rssi;
  const BleDeviceCandidate({required this.id, required this.name, required this.rssi});
}

/// Real GATT central transport for the ESP32 bag module.
///
/// Responsibilities:
///  • adapter state + permission flow (permissions are requested by the UI)
///  • scan for the Trackio GATT service, device selection + persistence
///  • GATT connect, MTU negotiation, secure (bonded) pairing,
///    telemetry/response subscriptions and command writes
///  • telemetry + response streams for the tracking engine
///  • automatic reconnect with exponential backoff after unexpected drops
class Esp32BleService extends ChangeNotifier {
  Esp32BleService(this._prefs);

  final SharedPreferences _prefs;

  static const String _prefsDeviceId = 'trackio_ble_device_id';
  static const String _prefsDeviceName = 'trackio_ble_device_name';
  static const Duration scanTimeout = Duration(seconds: 15);
  static const List<Duration> _backoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 8),
    Duration(seconds: 12),
    Duration(seconds: 12),
    Duration(seconds: 16),
  ];

  // ── observable state ──────────────────────────────────────────────────
  BlePhase phase = BlePhase.idle;
  String? errorMessage;
  List<BleDeviceCandidate> scanResults = [];
  int reconnectAttempts = 0;
  String? connectedId;
  String? connectedName;
  TelemetryFrame? lastFrame;
  final List<String> responseLog = [];

  /// RSSI model parameters reported by the module (`GET ALL`). Null until
  /// the module answers; the engine then uses firmware factory defaults.
  double? rssiAt1m;
  double? pathN;

  // ── streams ───────────────────────────────────────────────────────────
  final StreamController<TelemetryFrame> _telemetryCtrl =
      StreamController<TelemetryFrame>.broadcast();
  final StreamController<String> _responseCtrl = StreamController<String>.broadcast();
  Stream<TelemetryFrame> get telemetry => _telemetryCtrl.stream;
  Stream<String> get responses => _responseCtrl.stream;

  // ── internals ─────────────────────────────────────────────────────────
  final Map<String, BluetoothDevice> _devicesById = {};
  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmd;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<int>>? _tlmSub;
  StreamSubscription<List<int>>? _rspSub;
  StreamSubscription<BluetoothBondState>? _bondSub;
  Timer? _reconnectTimer;
  Timer? _pairingGuard;
  bool _manualDisconnect = false;
  bool _bootstrapped = false;

  bool get isConnected => phase == BlePhase.connected;
  String? get savedDeviceId => _prefs.getString(_prefsDeviceId);

  /// One-time adapter wiring + auto-connect to the last bonded module.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    if (!await FlutterBluePlus.isSupported) {
      phase = BlePhase.unsupported;
      notifyListeners();
      return;
    }

    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      final on = state == BluetoothAdapterState.on;
      if (!on && phase != BlePhase.disconnected && phase != BlePhase.idle) {
        _setPhase(BlePhase.bluetoothOff);
      } else if (on && (phase == BlePhase.bluetoothOff)) {
        _setPhase(BlePhase.idle);
        final saved = savedDeviceId;
        if (saved != null) _scheduleReconnect(saved);
      }
    });

    try {
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        phase = BlePhase.bluetoothOff;
        notifyListeners();
        return;
      }
    } catch (_) {
      // adapterStateNow unsupported (older platforms) — assume on, scan
      // failures will surface the real state below.
    }

    final saved = savedDeviceId;
    if (saved != null) {
      connectedName = _prefs.getString(_prefsDeviceName);
      _scheduleReconnect(saved);
    } else {
      _setPhase(BlePhase.idle);
    }
  }

  /// Android only: prompt the system to enable the adapter.
  Future<void> requestEnableBluetooth() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await FlutterBluePlus.turnOn();
    } catch (_) {/* user declined — the adapter listener updates state */}
  }

  // ── scanning ──────────────────────────────────────────────────────────

  Future<void> startScan() async {
    if (phase == BlePhase.scanning) return;
    errorMessage = null;
    scanResults = [];
    notifyListeners();

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      final seen = <String>{};
      final next = <BleDeviceCandidate>[];
      for (final r in results) {
        final d = r.device;
        _devicesById[d.remoteId.str] = d;
        final name = d.platformName.isNotEmpty ? d.platformName : r.advertisingData.advName;
        // The service UUID is advertised in the scan response; accept any
        // device carrying it, and prefer the known module name.
        final hasService = r.advertisingData.serviceUuids
            .map((u) => u.str.toLowerCase())
            .contains(BleProfile.serviceUuid.toLowerCase());
        final nameMatch = name.toLowerCase().startsWith(BleProfile.deviceNamePrefix.toLowerCase());
        if (!hasService && !nameMatch) continue;
        if (seen.contains(d.remoteId.str)) continue;
        seen.add(d.remoteId.str);
        next.add(BleDeviceCandidate(
          id: d.remoteId.str,
          name: name.isEmpty ? BleProfile.deviceNamePrefix : name,
          rssi: r.rssi,
        ));
      }
      scanResults = next;
      notifyListeners();
    }, onError: (Object e) {
      errorMessage = e.toString();
      _setPhase(BlePhase.idle);
    });

    _setPhase(BlePhase.scanning);
    try {
      // Web Bluetooth requires the service filter; Android/iOS honor it too.
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        withServices: [Guid(BleProfile.serviceUuid)],
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      errorMessage = e.toString();
      _setPhase(BlePhase.idle);
      return;
    }

    // End-of-scan fallback when nothing advertised during the window.
    Future.delayed(scanTimeout, () {
      if (phase == BlePhase.scanning) _setPhase(BlePhase.idle);
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    if (phase == BlePhase.scanning) _setPhase(BlePhase.idle);
  }

  // ── connection ────────────────────────────────────────────────────────

  Future<void> connectDevice(BleDeviceCandidate candidate) =>
      _connect(candidate.id, candidate.name, userInitiated: true);

  Future<void> _connect(String id, String? name, {required bool userInitiated}) async {
    _reconnectTimer?.cancel();
    await stopScan();
    _manualDisconnect = false;

    final device = _devicesById[id] ?? BluetoothDevice.fromId(id);
    _device = device;
    connectedId = id;
    connectedName = name ?? connectedName;
    _setPhase(BlePhase.connecting);

    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _handleDrop();
      }
    });

    try {
      await device.connect(
        timeout: const Duration(seconds: 20),
        autoConnect: false,
        mtu: BleProfile.mtu,
      );
    } catch (e) {
      if (_manualDisconnect) return;
      errorMessage = e.toString();
      if (userInitiated) {
        _setPhase(BlePhase.idle);
      } else {
        reconnectAttempts++;
        _scheduleReconnect(id);
      }
      return;
    }

    await _onPhysicalConnect(device, id, userInitiated);
  }

  Future<void> _onPhysicalConnect(
      BluetoothDevice device, String id, bool userInitiated) async {
    try {
      // Best-effort MTU negotiation (Android; web/iOS ignore/handle it).
      try {
        await device.requestMtu(BleProfile.mtu).timeout(const Duration(seconds: 4));
      } catch (_) {}

      _setPhase(BlePhase.pairing);

      // Subscribing to the encrypted telemetry characteristic triggers
      // LE Secure Connections pairing — the OS dialog asks for the
      // static passkey (BleProfile.pairingPasskey).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _bondSub?.cancel();
        _bondSub = device.bondState.listen((s) {
          if (s == BluetoothBondState.bonded && phase == BlePhase.pairing) {
            _setPhase(BlePhase.discovering);
          }
        });
      }

      // The first descriptor write can land while the system pairing
      // dialog is still open (the user is entering the static passkey).
      // Retry discovery/subscription a few times to let bonding finish.
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await _discoverAndSubscribe(device);
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          _setPhase(BlePhase.pairing);
          await Future.delayed(const Duration(seconds: 3));
        }
      }
      if (lastError != null) throw lastError;

      // Pairing completion on iOS is implicit; on Android some stacks
      // deliver services before the bond event. The guard just keeps the
      // UI from hanging in "pairing" if the event order differs.
      _pairingGuard?.cancel();
      _pairingGuard = Timer(const Duration(seconds: 12), () {
        if (phase == BlePhase.pairing) _setPhase(BlePhase.discovering);
      });

      await _prefs.setString(_prefsDeviceId, id);
      if (connectedName != null) await _prefs.setString(_prefsDeviceName, connectedName!);

      reconnectAttempts = 0;
      _setPhase(BlePhase.connected);

      // Handshake: firmware identity, model params, current status.
      await sendCommand('PING');
      await sendCommand('VER');
      await sendCommand('GET ALL');
      await sendCommand('STAT');
    } catch (e) {
      if (_manualDisconnect) return;
      errorMessage = e.toString();
      if (userInitiated) {
        await _teardownSubs();
        _cmd = null;
        _setPhase(BlePhase.idle);
      } else {
        _handleDrop();
      }
    }
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices().timeout(const Duration(seconds: 10));
    final svc = services.firstWhere(
      (s) => s.uuid.str.toLowerCase() == BleProfile.serviceUuid.toLowerCase(),
      orElse: () => throw StateError('Trackio GATT service not found on device'),
    );

    BluetoothCharacteristic char(String uuid) => svc.characteristics.firstWhere(
          (c) => c.uuid.str.toLowerCase() == uuid.toLowerCase(),
          orElse: () => throw StateError('Characteristic $uuid missing'),
        );

    final tlm = char(BleProfile.telemetryUuid);
    final rsp = char(BleProfile.responseUuid);
    _cmd = char(BleProfile.commandUuid);

    _tlmSub?.cancel();
    _tlmSub = tlm.onValueReceived.listen(_onTelemetryBytes);
    await tlm.setNotifyValue(true);

    _rspSub?.cancel();
    _rspSub = rsp.onValueReceived.listen(_onResponseBytes);
    await rsp.setNotifyValue(true);
  }

  // ── inbound data ──────────────────────────────────────────────────────

  void _onTelemetryBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    final frame = TelemetryFrame.parse(text);
    if (frame == null) return;
    lastFrame = frame;
    _telemetryCtrl.add(frame);
    notifyListeners();
  }

  void _onResponseBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) return;
    responseLog.add('[${_clock()}] $text');
    if (responseLog.length > 60) responseLog.removeAt(0);
    _responseCtrl.add(text);

    final settings = DeviceSettingsDump.parse(text);
    if (settings?.rssiAt1m != null) rssiAt1m = settings!.rssiAt1m;
    if (settings?.pathN != null) pathN = settings!.pathN;
    notifyListeners();
  }

  // ── outbound commands ─────────────────────────────────────────────────

  /// Writes a firmware command (see firmware `commands.c`).
  /// Returns false when no encrypted command characteristic is ready.
  Future<bool> sendCommand(String line) async {
    final cmd = _cmd;
    final device = _device;
    if (cmd == null || device == null || !device.isConnected) return false;
    try {
      await cmd.write(utf8.encode(line));
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── teardown / reconnect ──────────────────────────────────────────────

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _pairingGuard?.cancel();
    reconnectAttempts = 0;
    await _teardownSubs();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _cmd = null;
    connectedId = null;
    _setPhase(BlePhase.disconnected);
  }

  /// User-triggered retry after a failed auto-reconnect sequence.
  Future<void> retry() async {
    final id = savedDeviceId;
    if (id == null || kIsWeb) {
      // Web: reconnection goes through an interactive scan instead.
      _setPhase(BlePhase.idle);
      return;
    }
    reconnectAttempts = 0;
    await _connect(id, _prefs.getString(_prefsDeviceName), userInitiated: false);
  }

  /// Forgets the persisted module (keeps the OS bond; firmware `UNBOND`
  /// removes the module-side bond).
  Future<void> forgetDevice() async {
    await sendCommand('UNBOND');
    await disconnect();
    await _prefs.remove(_prefsDeviceId);
    await _prefs.remove(_prefsDeviceName);
    _setPhase(BlePhase.idle);
  }

  void _handleDrop() {
    _teardownSubs();
    _cmd = null;
    lastFrame = null;
    if (_manualDisconnect) {
      _setPhase(BlePhase.disconnected);
      return;
    }
    final id = connectedId;
    if (id != null) _scheduleReconnect(id);
  }

  void _scheduleReconnect(String id) {
    _reconnectTimer?.cancel();
    // Web Bluetooth has no fromId: reconnection requires a user-initiated
    // scan (browser security gesture), so stop at the connect screen.
    if (kIsWeb) {
      errorMessage = 'reconnect_exhausted';
      _setPhase(BlePhase.idle);
      return;
    }
    if (reconnectAttempts >= _backoff.length) {
      errorMessage = 'reconnect_exhausted';
      _setPhase(BlePhase.idle);
      return;
    }
    final delay = _backoff[math.min(reconnectAttempts, _backoff.length - 1)];
    _setPhase(BlePhase.reconnecting);
    _reconnectTimer = Timer(delay, () async {
      reconnectAttempts++;
      notifyListeners();
      // A cached handle survives adapter cycling on Android/iOS; web has
      // no fromId support, so after exhaustion the user reconnects via scan.
      await _connect(id, connectedName, userInitiated: false);
    });
  }

  Future<void> _teardownSubs() async {
    await _tlmSub?.cancel();
    _tlmSub = null;
    await _rspSub?.cancel();
    _rspSub = null;
    await _bondSub?.cancel();
    _bondSub = null;
    _pairingGuard?.cancel();
  }

  void _setPhase(BlePhase p) {
    phase = p;
    notifyListeners();
  }

  String _clock() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _pairingGuard?.cancel();
    _scanSub?.cancel();
    _connSub?.cancel();
    _adapterSub?.cancel();
    _teardownSubs();
    _telemetryCtrl.close();
    _responseCtrl.close();
    super.dispose();
  }
}
