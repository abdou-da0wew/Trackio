/// Parsers for the exact text frames emitted by the ESP32 firmware.
///
/// Two wire formats, both defined in the firmware:
///  • telemetry notify (`main/telemetry.c`):
///      `T,<st>,<dist_m>,<rssi>,<bearing>,<conf>,<front_cm>,<rear_cm>,`
///      `<servo_deg>,<L%>,<R%>,<heap_kb>`
///  • command responses (`main/commands.c`): `OK …` / `E <n> <reason>`,
///    including the `STAT` key=value line and the `GET ALL` settings dump.
library;

/// Navigation state characters returned by `nav_state_char()` in `nav.c`.
enum CarNavState {
  idle, // I
  waitLink, // W
  scan, // S
  turn, // T
  drive, // D
  hold, // H
  avoid, // A
  manual, // M
  test, // X
  stopWait, // E
  unknown;

  static CarNavState fromChar(String c) => switch (c) {
        'I' => CarNavState.idle,
        'W' => CarNavState.waitLink,
        'S' => CarNavState.scan,
        'T' => CarNavState.turn,
        'D' => CarNavState.drive,
        'H' => CarNavState.hold,
        'A' => CarNavState.avoid,
        'M' => CarNavState.manual,
        'X' => CarNavState.test,
        'E' => CarNavState.stopWait,
        _ => CarNavState.unknown,
      };
}

/// One decoded telemetry frame. Every field is nullable/guarded so a
/// single malformed frame can never poison the tracking state.
class TelemetryFrame {
  final CarNavState navState;
  final String navStateChar;
  final double distanceM; // path-loss distance computed on the module
  final int rssi; // filtered link RSSI, dBm (-100 when no link)
  final double? bearingDeg; // servo-space bearing, null when invalid (999)
  final int confidence; // 0..100
  final double frontCm;
  final double rearCm;
  final double servoDeg;
  final int motorLPct;
  final int motorRPct;
  final int freeHeapKb;
  final DateTime receivedAt;

  const TelemetryFrame({
    required this.navState,
    required this.navStateChar,
    required this.distanceM,
    required this.rssi,
    required this.bearingDeg,
    required this.confidence,
    required this.frontCm,
    required this.rearCm,
    required this.servoDeg,
    required this.motorLPct,
    required this.motorRPct,
    required this.freeHeapKb,
    required this.receivedAt,
  });

  /// Parses a `T,…` notification. Returns null when the frame is not a
  /// telemetry frame or cannot be decoded.
  static TelemetryFrame? parse(String raw) {
    final line = raw.trim();
    if (!line.startsWith('T,')) return null;
    final p = line.split(',');
    if (p.length < 12) return null;
    try {
      final bearing = double.parse(p[4]);
      return TelemetryFrame(
        navStateChar: p[1],
        navState: CarNavState.fromChar(p[1]),
        distanceM: double.parse(p[2]),
        rssi: int.parse(p[3]),
        bearingDeg: bearing >= 999 ? null : bearing,
        confidence: int.parse(p[5]).clamp(0, 100),
        frontCm: double.parse(p[6]),
        rearCm: double.parse(p[7]),
        servoDeg: double.parse(p[8]),
        motorLPct: int.parse(p[9]),
        motorRPct: int.parse(p[10]),
        freeHeapKb: int.parse(p[11]),
        receivedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Decoded `STAT` response. Only the fields Trackio surfaces are kept;
/// the rest stay available in [raw].
class StatResponse {
  final String raw;
  final String? mode; // IDLE | FOLLOW | MANUAL
  final bool? armed;
  final bool? connected;
  final bool? encrypted;
  final int? rssi;
  final double? distanceM;
  final double? bearingDeg;
  final int? confidence;
  final int? bonds;

  const StatResponse({
    required this.raw,
    this.mode,
    this.armed,
    this.connected,
    this.encrypted,
    this.rssi,
    this.distanceM,
    this.bearingDeg,
    this.confidence,
    this.bonds,
  });

  static StatResponse? parse(String raw) {
    final line = raw.trim();
    if (!line.startsWith('OK ')) return null;
    final kv = <String, String>{};
    for (final token in line.substring(3).split(' ')) {
      final eq = token.indexOf('=');
      if (eq > 0) kv[token.substring(0, eq)] = token.substring(eq + 1);
    }
    if (kv.isEmpty) return null;
    int? intOf(String k) => int.tryParse(kv[k] ?? '');
    double? doubleOf(String k) => double.tryParse(kv[k] ?? '');
    return StatResponse(
      raw: line,
      mode: kv['mode'],
      armed: kv['arm'] == null ? null : kv['arm'] == '1',
      connected: kv['conn'] == null ? null : kv['conn'] == '1',
      encrypted: kv['enc'] == null ? null : kv['enc'] == '1',
      rssi: intOf('rssi'),
      distanceM: doubleOf('dist'),
      bearingDeg: doubleOf('brg'),
      confidence: intOf('conf'),
      bonds: intOf('bonds'),
    );
  }
}

/// Subset of the `GET ALL` settings dump Trackio cares about (the RSSI
/// model parameters, so distance math can track a recalibrated module).
class DeviceSettingsDump {
  final String? name;
  final int? passkey;
  final double? rssiAt1m;
  final double? pathN;

  const DeviceSettingsDump({this.name, this.passkey, this.rssiAt1m, this.pathN});

  static DeviceSettingsDump? parse(String raw) {
    if (!raw.contains('rssi1m=')) return null;
    final kv = <String, String>{};
    for (final token in raw.split(RegExp(r'\s+'))) {
      final eq = token.indexOf('=');
      if (eq > 0) kv[token.substring(0, eq)] = token.substring(eq + 1);
    }
    return DeviceSettingsDump(
      name: kv['name'],
      passkey: int.tryParse(kv['passkey'] ?? ''),
      rssiAt1m: double.tryParse(kv['rssi1m'] ?? ''),
      pathN: double.tryParse(kv['pathn'] ?? ''),
    );
  }
}
