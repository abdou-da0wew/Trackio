import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory authentication used until the self-hosted Supabase backend
/// lands.
///
/// Mirrors the production Supabase auth contract (signup → OTP verify →
/// session) so the real backend can be swapped in behind this interface
/// without touching the UI layer. The live BLE tracking pipeline does not
/// depend on this service and works fully offline.
class AuthService extends ChangeNotifier {
  AuthService(this._prefs) {
    _user = _prefs.getString('demo_user_name') != null
        ? AppUser(
            name: _prefs.getString('demo_user_name')!,
            email: _prefs.getString('demo_user_email') ?? '')
        : null;
    _pendingEmail = _prefs.getString('pending_email');
    _pendingName = _prefs.getString('pending_name');
  }

  final SharedPreferences _prefs;
  AppUser? _user;
  String? _pendingEmail;
  String? _pendingName;
  String? _otpCode; // demo convenience: surfaced in a hint banner
  bool _verified = false;

  static final Random _rng = Random();

  AppUser? get user => _user;
  String? get pendingEmail => _pendingEmail;
  bool get otpSent => _otpCode != null;
  bool get verified => _verified;
  String? get demoOtp => _otpCode;

  Future<void> signUp({required String name, required String email}) async {
    _pendingName = name;
    _pendingEmail = email;
    _otpCode = _generateOtp();
    _verified = false;
    await _prefs.setString('pending_email', email);
    await _prefs.setString('pending_name', name);
    notifyListeners();
  }

  Future<bool> verifyOtp(String code) async {
    if (_otpCode == null) return false;
    if (code != _otpCode) return false;
    _verified = true;
    _user = AppUser(name: _pendingName ?? 'Trackio User', email: _pendingEmail ?? 'user@trackio.app');
    await _prefs.setString('demo_user_name', _user!.name);
    await _prefs.setString('demo_user_email', _user!.email);
    await _prefs.remove('pending_email');
    _otpCode = null;
    notifyListeners();
    return true;
  }

  Future<bool> login({required String email}) async {
    if (email.trim().isEmpty) return false;
    _user = AppUser(name: _prefs.getString('demo_user_name') ?? 'Abdou', email: email);
    await _prefs.setString('demo_user_name', _user!.name);
    await _prefs.setString('demo_user_email', email);
    notifyListeners();
    return true;
  }

  Future<void> resendOtp() async {
    _otpCode = _generateOtp();
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    _verified = false;
    await _prefs.remove('demo_user_name');
    await _prefs.remove('demo_user_email');
    notifyListeners();
  }

  static String _generateOtp() => List.generate(6, (_) => _rng.nextInt(10)).join();
}
