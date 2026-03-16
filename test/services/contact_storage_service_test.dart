import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/contact_storage_service.dart';
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
  });

  test('keeps default and custom profile contact storage isolated', () async {
    final storage = ContactStorageService();
    final defaultContact = createContact(
      key: Uint8List.fromList(List<int>.filled(32, 1)),
      name: 'Default Contact',
    );
    final customContact = createContact(
      key: Uint8List.fromList(List<int>.filled(32, 2)),
      name: 'Custom Contact',
    );

    await storage.saveContacts([defaultContact]);
    await storage.saveContacts([customContact], namespace: 'alpha');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('stored_contacts'), isNotNull);
    expect(prefs.getString('profile.alpha.stored_contacts'), isNotNull);

    final defaultContacts = await storage.loadContacts();
    final customContacts = await storage.loadContacts(namespace: 'alpha');

    expect(defaultContacts.single.advName, defaultContact.advName);
    expect(customContacts.single.advName, customContact.advName);
    expect(defaultContacts.single.publicKey, defaultContact.publicKey);
    expect(customContacts.single.publicKey, customContact.publicKey);
  });
}
