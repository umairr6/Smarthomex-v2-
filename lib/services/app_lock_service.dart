import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const String _pinKey = 'app_lock_pin';
  static const String _enabledKey = 'app_lock_enabled';

  /// Check whether App Lock is enabled.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable or disable App Lock.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Save a new PIN.
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  /// Get the saved PIN.
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  /// Check whether a PIN has been configured.
  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Verify entered PIN.
  Future<bool> verifyPin(String pin) async {
    final savedPin = await getPin();
    return savedPin != null && savedPin == pin;
  }

  /// Remove App Lock completely.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pinKey);
    await prefs.remove(_enabledKey);
  }
}