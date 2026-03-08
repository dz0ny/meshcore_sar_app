import 'package:shared_preferences/shared_preferences.dart';

class MessagingRoutePreferences {
  static const bool defaultAutoRouteRotationEnabled = false;
  static const bool defaultClearPathOnMaxRetry = false;

  static const String _autoRouteRotationKey =
      'messaging_auto_route_rotation_enabled';
  static const String _clearPathOnMaxRetryKey =
      'messaging_clear_path_on_max_retry';

  static Future<bool> getAutoRouteRotationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoRouteRotationKey) ??
        defaultAutoRouteRotationEnabled;
  }

  static Future<void> setAutoRouteRotationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRouteRotationKey, enabled);
  }

  static Future<bool> getClearPathOnMaxRetry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clearPathOnMaxRetryKey) ?? defaultClearPathOnMaxRetry;
  }

  static Future<void> setClearPathOnMaxRetry(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clearPathOnMaxRetryKey, enabled);
  }
}
