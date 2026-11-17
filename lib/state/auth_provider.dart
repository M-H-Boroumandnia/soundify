import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/security/biometric_service.dart';
import '../core/storage/app_prefs.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  final AppPrefs _prefs;
  final BiometricService _biometric;

  AuthProvider(this._repo, this._prefs, this._biometric);

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _sessionExpired = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get biometricEnabled => _prefs.biometricEnabled;
  bool get sessionExpired => _sessionExpired;

  Future<bool> hasStoredSession() => _repo.hasSession();

  Future<bool> canUseBiometricLogin() async =>
      biometricEnabled &&
      await _repo.hasSession() &&
      await _biometric.isAvailable();

  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    await _onSignedIn();
  }

  Future<bool> verifyOtp(String email, String code, {String? password}) async {
    if (await _repo.verifyOtp(email, code)) {
      await _onSignedIn();
      return true;
    }
    if (password == null) return false;
    await login(email, password);
    return true;
  }

  Future<bool> loginWithBiometric() async {
    if (!await canUseBiometricLogin()) return false;
    final ok = await _biometric.authenticate('برای ورود به ساندیفای هویت خود را تأیید کنید');
    if (!ok) return false;
    await _onSignedIn();
    return _status == AuthStatus.authenticated;
  }

  Future<void> restoreSession() async {
    if (await _repo.hasSession()) {
      try {
        await _onSignedIn();
      } on ApiException {
        return;
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      _user = await _repo.me();
      notifyListeners();
    } on ApiException {
      return;
    }
  }

  Future<String?> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      if (!await _biometric.isAvailable()) {
        return 'حسگر بیومتریک در دسترس نیست یا اثر انگشتی ثبت نشده است';
      }
      final ok = await _biometric.authenticate('برای فعال‌سازی ورود بیومتریک تأیید کنید');
      if (!ok) return 'احراز هویت بیومتریک ناموفق بود';
    }
    await _prefs.setBiometricEnabled(enabled);
    notifyListeners();
    return null;
  }

  Future<void> logout({bool forgetDevice = false}) async {
    if (forgetDevice || !biometricEnabled) {
      await _repo.logout();
      await _prefs.setBiometricEnabled(false);
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void handleSessionExpired() {
    if (_status != AuthStatus.authenticated) return;
    _prefs.setBiometricEnabled(false);
    _user = null;
    _sessionExpired = true;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void consumeSessionExpired() => _sessionExpired = false;

  Future<void> _onSignedIn() async {
    try {
      _user = await _repo.me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _repo.logout();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        rethrow;
      }
    }
    _sessionExpired = false;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
}
