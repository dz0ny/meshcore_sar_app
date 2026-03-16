import 'package:shared_preferences/shared_preferences.dart';

class ProfilesFeatureService {
  static const String enabledKey = 'profiles_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
  }
}

class ProfileStorageScope {
  static bool _profilesEnabled = false;
  static String _activeProfileId = 'default';

  static Future<void> bootstrap({
    required bool profilesEnabled,
    required String activeProfileId,
  }) async {
    _profilesEnabled = profilesEnabled;
    _activeProfileId = activeProfileId;
  }

  static void setScope({
    required bool profilesEnabled,
    required String activeProfileId,
  }) {
    _profilesEnabled = profilesEnabled;
    _activeProfileId = activeProfileId;
  }

  static bool get profilesEnabled => _profilesEnabled;
  static String get activeProfileId => _activeProfileId;

  static String? get effectiveNamespace {
    if (!_profilesEnabled || _activeProfileId == 'default') {
      return null;
    }
    return _activeProfileId;
  }

  static String scopedKey(String baseKey, {String? namespace}) {
    final scope = namespace ?? effectiveNamespace;
    if (scope == null || scope.isEmpty) {
      return baseKey;
    }
    return 'profile.$scope.$baseKey';
  }
}
