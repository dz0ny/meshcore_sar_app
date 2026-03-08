import 'package:shared_preferences/shared_preferences.dart';

class DeveloperModeService {
  static const String _developerModeKey = 'developer_mode_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_developerModeKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_developerModeKey, enabled);
  }
}
