/// GATT profile of the ESP32 follow-car / bag-module firmware.
///
/// Mirrors `main/ble_link.c` in the ESP-IDF firmware exactly. The device
/// runs a Bluedroid GATT **server**; the phone is the GATT **central**.
///
/// Service + characteristics live under one 128-bit base UUID
/// `f7a9xxxx-6b8d-4c3e-a2f1-5d4b9c8e7a10` (the firmware stores them
/// little-endian, which is why the byte tables in C read reversed).
class BleProfile {
  const BleProfile._();

  /// Primary service (advertised in the scan-response UUID list).
  static const String serviceUuid = 'f7a90001-6b8d-4c3e-a2f1-5d4b9c8e7a10';

  /// Phone → module command channel (write, encrypted after pairing).
  /// Text commands from the firmware command interpreter:
  /// `PING`, `VER`, `STAT`, `MODE`, `ARM`, `GET`, `SET`, `SAVE`, …
  static const String commandUuid = 'f7a90002-6b8d-4c3e-a2f1-5d4b9c8e7a10';

  /// Module → phone telemetry notifications, 2 Hz while subscribed.
  /// CSV frame: `T,<st>,<dist_m>,<rssi>,<bearing>,<conf>,<front_cm>,`
  /// `<rear_cm>,<servo_deg>,<L%>,<R%>,<heap_kb>`.
  static const String telemetryUuid = 'f7a90003-6b8d-4c3e-a2f1-5d4b9c8e7a10';

  /// Module → phone command responses (`OK …` / `E <n> <reason>`).
  static const String responseUuid = 'f7a90004-6b8d-4c3e-a2f1-5d4b9c8e7a10';

  /// Default advertised name (`settings_t.name` factory default).
  static const String deviceNamePrefix = 'ESP32-FollowCar';

  /// Static LE Secure Connections passkey (`settings_t.passkey` default).
  /// The OS pairing dialog asks for it; the app never sends it over GATT.
  static const String pairingPasskey = '246810';

  /// Negotiated ATT MTU (`esp_ble_gatt_set_local_mtu(220)` in firmware).
  static const int mtu = 220;
}
