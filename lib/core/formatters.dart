/// Small formatting helpers used across the UI.
class Fmt {
  static String distance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km >= 100 ? '${km.round()} km' : '${km.toStringAsFixed(km >= 10 ? 1 : 2)} km';
    }
    return '${meters.round()} m';
  }

  static String clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String clockSec(DateTime t) =>
      '${clock(t)}:${t.second.toString().padLeft(2, '0')}';

  static String day(DateTime t) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[t.month - 1]} ${t.day}, ${t.year}';
  }

  static String ago(DateTime t, DateTime now) {
    final d = now.difference(t);
    if (d.inSeconds < 5) return 'now';
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  static String rssi(double dbm) => '${dbm.round()} dBm';
}
