import 'package:shared_preferences/shared_preferences.dart';

/// Stores user-selected image compression settings.
class ImagePreferences {
  static const String _maxSizeKey = 'image_max_size';
  // Keep the legacy key name so existing users retain their saved value.
  static const String _qualityKey = 'image_quality';
  static const String _grayscaleKey = 'image_grayscale';
  static const String _ultraModeKey = 'image_ultra_mode';

  static const int defaultMaxSize = 256;
  static const int defaultQuality = 90;
  static const bool defaultGrayscale = true;
  static const bool defaultUltraMode = false;

  static const List<int> supportedSizes = [64, 96, 128, 256];

  static Future<int> getMaxSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_maxSizeKey) ?? defaultMaxSize;
    return supportedSizes.contains(value) ? value : defaultMaxSize;
  }

  static Future<void> setMaxSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxSizeKey, size);
  }

  static Future<int> getCompression() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_qualityKey) ?? defaultQuality;
    return value.clamp(10, 90);
  }

  static Future<void> setCompression(int compression) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_qualityKey, compression.clamp(10, 90));
  }

  static Future<bool> getGrayscale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_grayscaleKey) ?? defaultGrayscale;
  }

  static Future<void> setGrayscale(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grayscaleKey, value);
  }

  static Future<bool> getUltraMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ultraModeKey) ?? defaultUltraMode;
  }

  static Future<void> setUltraMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ultraModeKey, value);
  }

  static int effectiveMaxSize(
    int configuredMaxSize, {
    required bool ultraMode,
  }) {
    return configuredMaxSize.clamp(32, 1024);
  }
}
