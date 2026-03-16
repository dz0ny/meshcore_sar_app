import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/config_profile.dart';
import 'profiles_feature_service.dart';

class ProfileManager with ChangeNotifier {
  static const String _profilesKey = 'profiles_library';
  static const String activeProfileIdKey = 'profiles_active_profile_id';
  static const String _transferHistoryKey = 'profiles_transfer_history';

  final List<ConfigProfile> _customProfiles = <ConfigProfile>[];
  final List<ProfileTransferRecord> _transferHistory =
      <ProfileTransferRecord>[];
  bool _isInitialized = false;
  bool _profilesEnabled = false;
  String _activeProfileId = ConfigProfile.defaultProfileId;

  bool get isInitialized => _isInitialized;
  bool get profilesEnabled => _profilesEnabled;
  String get activeProfileId => _activeProfileId;
  List<ConfigProfile> get customProfiles => List.unmodifiable(_customProfiles);
  List<ProfileTransferRecord> get transferHistory =>
      List.unmodifiable(_transferHistory);

  List<ConfigProfile> get visibleProfiles => [
    if (_profilesEnabled) ConfigProfile.defaultProfile(),
    ..._customProfiles,
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _profilesEnabled = await ProfilesFeatureService.isEnabled();
    _activeProfileId =
        prefs.getString(activeProfileIdKey) ?? ConfigProfile.defaultProfileId;

    final profilesJson = prefs.getString(_profilesKey);
    if (profilesJson != null && profilesJson.isNotEmpty) {
      final decoded = jsonDecode(profilesJson) as List<dynamic>;
      _customProfiles
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(ConfigProfile.fromJson),
        );
    }

    final historyJson = prefs.getString(_transferHistoryKey);
    if (historyJson != null && historyJson.isNotEmpty) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      _transferHistory
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(
            ProfileTransferRecord.fromJson,
          ),
        );
    }

    _isInitialized = true;
    ProfileStorageScope.setScope(
      profilesEnabled: _profilesEnabled,
      activeProfileId: _activeProfileId,
    );
    notifyListeners();
  }

  ConfigProfile? getProfile(String id) {
    if (id == ConfigProfile.defaultProfileId) {
      return ConfigProfile.defaultProfile();
    }
    for (final profile in _customProfiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  Future<void> setProfilesEnabled(bool enabled) async {
    _profilesEnabled = enabled;
    await ProfilesFeatureService.setEnabled(enabled);
    ProfileStorageScope.setScope(
      profilesEnabled: _profilesEnabled,
      activeProfileId: _activeProfileId,
    );
    notifyListeners();
  }

  Future<void> setActiveProfileId(String id) async {
    _activeProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeProfileIdKey, id);
    ProfileStorageScope.setScope(
      profilesEnabled: _profilesEnabled,
      activeProfileId: _activeProfileId,
    );
    notifyListeners();
  }

  Future<void> upsertProfile(ConfigProfile profile) async {
    final index = _customProfiles.indexWhere((item) => item.id == profile.id);
    if (index == -1) {
      _customProfiles.add(profile);
    } else {
      _customProfiles[index] = profile;
    }
    _customProfiles.sort((a, b) => a.name.compareTo(b.name));
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    _customProfiles.removeWhere((profile) => profile.id == id);
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> recordTransfer(ProfileTransferRecord record) async {
    _transferHistory.insert(0, record);
    if (_transferHistory.length > 100) {
      _transferHistory.removeRange(100, _transferHistory.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transferHistoryKey,
      jsonEncode(_transferHistory.map((item) => item.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> _persistProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(_customProfiles.map((profile) => profile.toJson()).toList()),
    );
  }
}
