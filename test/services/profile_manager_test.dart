import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/config_profile.dart';
import 'package:meshcore_sar_app/services/profile_manager.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: ConfigProfile.defaultProfileId,
    );
  });

  group('ProfileManager', () {
    test(
      'hides the built-in default profile until profiles are enabled',
      () async {
        final manager = ProfileManager();

        await manager.initialize();

        expect(manager.activeProfileId, ConfigProfile.defaultProfileId);
        expect(manager.visibleProfiles, isEmpty);
        expect(
          manager.getProfile(ConfigProfile.defaultProfileId)?.isDefault,
          isTrue,
        );
        expect(ProfileStorageScope.profilesEnabled, isFalse);
        expect(ProfileStorageScope.effectiveNamespace, isNull);

        await manager.setProfilesEnabled(true);

        expect(manager.visibleProfiles, hasLength(1));
        expect(
          manager.visibleProfiles.single.id,
          ConfigProfile.defaultProfileId,
        );
        expect(manager.visibleProfiles.single.name, 'Default');
        expect(ProfileStorageScope.profilesEnabled, isTrue);
        expect(ProfileStorageScope.effectiveNamespace, isNull);
      },
    );

    test(
      'persists custom profiles and restores scoped active profile state',
      () async {
        final manager = ProfileManager();
        await manager.initialize();
        await manager.setProfilesEnabled(true);

        final profile = ConfigProfile(
          id: 'profile-alpha',
          name: 'Alpha',
          createdAt: DateTime.parse('2026-03-16T12:00:00Z'),
          updatedAt: DateTime.parse('2026-03-16T12:00:00Z'),
          sections: const ConfigProfileSections(),
        );

        await manager.upsertProfile(profile);
        await manager.setActiveProfileId(profile.id);

        final reloaded = ProfileManager();
        await reloaded.initialize();

        expect(reloaded.profilesEnabled, isTrue);
        expect(reloaded.activeProfileId, profile.id);
        expect(reloaded.visibleProfiles.map((item) => item.id), [
          ConfigProfile.defaultProfileId,
          profile.id,
        ]);
        expect(reloaded.getProfile(profile.id)?.name, profile.name);
        expect(ProfileStorageScope.effectiveNamespace, profile.id);

        await reloaded.setProfilesEnabled(false);

        expect(ProfileStorageScope.profilesEnabled, isFalse);
        expect(ProfileStorageScope.effectiveNamespace, isNull);
        expect(reloaded.activeProfileId, profile.id);
      },
    );
  });
}
