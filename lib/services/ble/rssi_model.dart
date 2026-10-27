import 'dart:math' as math;

/// RSSI signal processing, ported 1:1 from the ESP32 firmware
/// (`main/radar_math.c`) so the phone and the module derive the same
/// distance estimate from the same radio measurement.
///
/// Pipeline per sample:
///   1. reject physically impossible RSSI (≥ 0 or < -100 dBm)
///   2. single-sample spike gate (> [outlierDb] from the running estimate)
///   3. median-of-3 over the last accepted samples
///   4. exponential moving average with [emaAlpha]
///
/// Distance uses the log-distance path-loss model:
///   d = 10 ^ ((RSSI@1m − RSSI) / (10 · n)), clamped to 0.15–25 m.
class RssiModel {
  const RssiModel._();

  static const double outlierDb = 15.0; // RM_OUTLIER_DB
  static const double emaAlpha = 0.35; // RM_EMA_ALPHA
  static const double defaultRssiAt1m = -59.0; // settings_t.rssi_1m
  static const double defaultPathN = 2.6; // settings_t.path_n
  static const double minDistanceM = 0.15;
  static const double maxDistanceM = 25.0;

  static double clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static double median3(double a, double b, double c) {
    if (a > b) {
      final t = a;
      a = b;
      b = t;
    }
    if (b > c) {
      final t = b;
      b = c;
      c = t;
    }
    if (a > b) {
      final t = a;
      a = b;
      b = t;
    }
    return b;
  }

  /// Log-distance path-loss distance in meters.
  /// Returns -1 for impossible RSSI, matching `rm_rssi_to_dist_m`.
  static double rssiToDistanceM(
    int rssi, {
    double rssiAt1m = defaultRssiAt1m,
    double pathN = defaultPathN,
  }) {
    if (rssi >= 0 || rssi < -100) return -1.0;
    var n = pathN;
    if (n < 1.5) n = 1.5;
    if (n > 4.5) n = 4.5;
    final exponent = (rssiAt1m - rssi) / (10.0 * n);
    final d = math.pow(10.0, exponent).toDouble();
    return clamp(d, minDistanceM, maxDistanceM);
  }
}

/// Mutable filter equivalent to the C `rm_rssi_filt_t` struct.
class RssiFilter {
  double _ema = 0.0;
  final List<double> _win = [0.0, 0.0, 0.0];
  int _n = 0;
  bool _primed = false;

  bool get primed => _primed;
  double get ema => _primed ? _ema : -100.0;

  void reset() {
    _ema = 0.0;
    _n = 0;
    _primed = false;
  }

  /// Feeds a raw link-RSSI sample; returns the filtered estimate
  /// (or -100 while unprimed / for impossible input).
  double update(int rawRssi) {
    final r = rawRssi.toDouble();

    if (r >= 0.0 || r < -100.0) {
      return _primed ? _ema : -100.0;
    }
    if (_primed && (r - _ema).abs() > RssiModel.outlierDb) {
      return _ema;
    }

    _win[_n % 3] = r;
    _n++;
    final double med;
    if (_n < 3) {
      med = r;
    } else {
      med = RssiModel.median3(_win[0], _win[1], _win[2]);
    }

    if (!_primed) {
      _ema = med;
      _primed = true;
    } else {
      _ema = RssiModel.emaAlpha * med + (1.0 - RssiModel.emaAlpha) * _ema;
    }
    return _ema;
  }
}
