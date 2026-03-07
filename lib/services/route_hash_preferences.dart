import 'package:shared_preferences/shared_preferences.dart';

class RouteHashPreferences {
  static const String _hashSizeKey = 'route_hash_size';
  static const int defaultHashSize = 1;

  static Future<int> getHashSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_hashSizeKey) ?? defaultHashSize;
    return _normalize(value);
  }

  static Future<void> setHashSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hashSizeKey, _normalize(value));
  }

  static int normalizeSync(int value) => _normalize(value);

  static int _normalize(int value) {
    if (value < 1 || value > 3) {
      return defaultHashSize;
    }
    return value;
  }
}
