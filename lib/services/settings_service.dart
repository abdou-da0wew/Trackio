import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlertSound { sonarPing, alarmPulse, gentleChime }

extension AlertSoundX on AlertSound {
  String get label => switch (this) {
        AlertSound.sonarPing => 'Sonar Ping',
        AlertSound.alarmPulse => 'Alarm Pulse',
        AlertSound.gentleChime => 'Gentle Chime',
      };
  String get asset => switch (this) {
        AlertSound.sonarPing => 'sounds/sonar_ping.wav',
        AlertSound.alarmPulse => 'sounds/alarm_pulse.wav',
        AlertSound.gentleChime => 'sounds/gentle_chime.wav',
      };
}

/// Persists user preferences (theme, alert sound, tracking intervals).
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs) {
    _themeDark = _prefs.getBool('themeDark') ?? true;
    _sound = AlertSound.values[_prefs.getInt('alertSound') ?? 0];
    _phoneGpsIntervalS = _prefs.getInt('phoneInterval') ?? 5;
    _bagGpsIntervalS = _prefs.getInt('bagInterval') ?? 10;
    _recheckIntervalS = _prefs.getInt('recheckInterval') ?? 15;
    _onboardingSeen = _prefs.getBool('onboardingSeen') ?? false;
  }

  final SharedPreferences _prefs;
  late bool _themeDark;
  late AlertSound _sound;
  late int _phoneGpsIntervalS;
  late int _bagGpsIntervalS;
  late int _recheckIntervalS;
  late bool _onboardingSeen;

  bool get themeDark => _themeDark;
  AlertSound get sound => _sound;
  int get phoneGpsIntervalS => _phoneGpsIntervalS;
  int get bagGpsIntervalS => _bagGpsIntervalS;
  int get recheckIntervalS => _recheckIntervalS;
  bool get onboardingSeen => _onboardingSeen;

  ThemeMode get themeMode => _themeDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setThemeDark(bool dark) async {
    _themeDark = dark;
    await _prefs.setBool('themeDark', dark);
    notifyListeners();
  }

  Future<void> setSound(AlertSound s) async {
    _sound = s;
    await _prefs.setInt('alertSound', s.index);
    notifyListeners();
  }

  Future<void> setPhoneInterval(int v) async {
    _phoneGpsIntervalS = v;
    await _prefs.setInt('phoneInterval', v);
    notifyListeners();
  }

  Future<void> setBagInterval(int v) async {
    _bagGpsIntervalS = v;
    await _prefs.setInt('bagInterval', v);
    notifyListeners();
  }

  Future<void> setRecheckInterval(int v) async {
    _recheckIntervalS = v;
    await _prefs.setInt('recheckInterval', v);
    notifyListeners();
  }

  Future<void> setOnboardingSeen() async {
    _onboardingSeen = true;
    await _prefs.setBool('onboardingSeen', true);
    notifyListeners();
  }
}
