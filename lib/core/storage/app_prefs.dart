import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const _onboardingKey = 'onboarding_seen';
  static const _biometricKey = 'biometric_enabled';

  final SharedPreferences _prefs;

  AppPrefs(this._prefs);

  static Future<AppPrefs> create() async =>
      AppPrefs(await SharedPreferences.getInstance());

  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingKey, true);

  bool get biometricEnabled => _prefs.getBool(_biometricKey) ?? false;
  Future<void> setBiometricEnabled(bool value) =>
      _prefs.setBool(_biometricKey, value);
}
