import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/services/contact_storage_service.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Contact createContact({required Uint8List key, required String name}) {
    return Contact(
      publicKey: key,
      type: ContactType.chat,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: (46.0569 * 1e6).round(),
      advLon: (14.5058 * 1e6).round(),
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'default',
    );
  });

  test(
    'initializeEarly respects the active profile storage namespace',
    () async {
      final storage = ContactStorageService();
      final defaultContact = createContact(
        key: Uint8List.fromList(List<int>.filled(32, 1)),
        name: 'Default Contact',
      );
      final alphaContact = createContact(
        key: Uint8List.fromList(List<int>.filled(32, 2)),
        name: 'Alpha Contact',
      );

      await storage.saveContacts([defaultContact]);
      await storage.saveContacts([alphaContact], namespace: 'alpha');

      ProfileStorageScope.setScope(
        profilesEnabled: true,
        activeProfileId: 'alpha',
      );

      final provider = ContactsProvider();
      await provider.initializeEarly();

      final names = provider.contacts
          .where((contact) => !contact.isChannel)
          .map((contact) => contact.advName)
          .toList();

      expect(names, <String>['Alpha Contact']);
      expect(provider.storageNamespace, 'alpha');
    },
  );
}
