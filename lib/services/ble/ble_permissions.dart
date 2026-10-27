import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions required to scan for and connect to BLE devices.
///
/// Android 12+ (API 31) uses the dedicated BLUETOOTH_SCAN / BLUETOOTH_CONNECT
/// runtime permissions. Older Android releases gate scanning behind a
/// location permission. iOS shows its own usage-description dialog and
/// needs no runtime request from the app; web delegates to the browser.
///
/// Deliberately free of `dart:io` so the file compiles on the web target.
class BlePermissions {
  const BlePermissions._();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Requests the platform permissions a BLE scan needs.
  /// Returns true when scanning may proceed.
  static Future<bool> requestScan() async {
    if (kIsWeb) return true;
    if (_isIOS) {
      return Permission.bluetooth.request().then((s) => s.isGranted);
    }
    if (!_isAndroid) return true;

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (scan.isGranted && connect.isGranted) return true;

    // API < 31 fallback: discovery requires location.
    final location = await Permission.locationWhenInUse.request();
    return location.isGranted;
  }

  static Future<bool> get isGranted async {
    if (kIsWeb) return true;
    if (_isIOS) return Permission.bluetooth.isGranted;
    if (!_isAndroid) return true;
    if (await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      return true;
    }
    return Permission.locationWhenInUse.isGranted;
  }

  static Future<void> openSettings() => openAppSettings();
}
