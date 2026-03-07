import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
import 'package:meshcore_sar_app/utils/fast_gps_packet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List createPublicKey(int seed) {
    return Uint8List.fromList(List<int>.generate(32, (index) => seed + index));
  }

  Contact createContact({
    required Uint8List key,
    required ContactType type,
    String? name,
  }) {
    return Contact(
      publicKey: key,
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name ?? 'Test Contact',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: (46.0569 * 1e6).toInt(),
      advLon: (14.5058 * 1e6).toInt(),
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  group('ContactsProvider.updateTelemetry', () {
    late ContactsProvider provider;
    late Uint8List publicKey;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ContactsProvider();
      publicKey = Uint8List.fromList([
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x01,
        0x02,
        0x03,
        0x04,
        0x05,
        0x06,
        0x07,
        0x08,
        0x09,
        0x0A,
        0x0B,
        0x0C,
        0x0D,
        0x0E,
        0x0F,
        0x10,
        0x11,
        0x12,
        0x13,
        0x14,
        0x15,
        0x16,
        0x17,
        0x18,
        0x19,
        0x1A,
      ]);

      provider.addOrUpdateContact(
        Contact(
          publicKey: publicKey,
          type: ContactType.chat,
          flags: 0,
          outPathLen: 0,
          outPath: Uint8List(64),
          advName: 'Test Contact',
          lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          advLat: (46.0569 * 1e6).toInt(),
          advLon: (14.5058 * 1e6).toInt(),
          lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
    });

    test('ignores telemetry GPS at 0,0 and keeps advert location', () {
      final lppData = CayenneLppParser.createGpsData(
        latitude: 0.0,
        longitude: 0.0,
      );

      provider.updateTelemetry(publicKey.sublist(0, 6), lppData);
      final updated = provider.findContactByKey(publicKey)!;

      expect(updated.telemetry, isNotNull);
      expect(updated.telemetry!.gpsLocation, isNull);
      expect(updated.displayLocation, isNotNull);
      expect(updated.displayLocation!.latitude, closeTo(46.0569, 0.000001));
      expect(updated.displayLocation!.longitude, closeTo(14.5058, 0.000001));
    });

    test('keeps valid telemetry GPS and uses it for display location', () {
      final lppData = CayenneLppParser.createGpsData(
        latitude: 45.0001,
        longitude: 13.9999,
      );

      provider.updateTelemetry(publicKey.sublist(0, 6), lppData);
      final updated = provider.findContactByKey(publicKey)!;

      expect(updated.telemetry, isNotNull);
      expect(updated.telemetry!.gpsLocation, isNotNull);
      expect(
        updated.telemetry!.gpsLocation!.latitude,
        closeTo(45.0001, 0.0001),
      );
      expect(
        updated.telemetry!.gpsLocation!.longitude,
        closeTo(13.9999, 0.0001),
      );
      expect(updated.displayLocation, isNotNull);
      expect(updated.displayLocation!.latitude, closeTo(45.0001, 0.0001));
      expect(updated.displayLocation!.longitude, closeTo(13.9999, 0.0001));
      expect(updated.advLat, equals((45.0001 * 1e6).round()));
      expect(updated.advLon, equals((13.9999 * 1e6).round()));
    });

    test(
      'retains last valid gps for any contact when telemetry gps is invalid or missing',
      () {
        final contactTypes = <ContactType>[
          ContactType.chat,
          ContactType.repeater,
          ContactType.room,
          ContactType.channel,
        ];

        for (var i = 0; i < contactTypes.length; i++) {
          final scopedProvider = ContactsProvider();
          final scopedKey = createPublicKey(16 + i);
          final contactType = contactTypes[i];
          scopedProvider.addOrUpdateContact(
            createContact(
              key: scopedKey,
              type: contactType,
              name: 'Contact ${contactType.name}',
            ),
          );

          final validGps = CayenneLppParser.createGpsData(
            latitude: 45.1234,
            longitude: 13.8765,
          );
          scopedProvider.updateTelemetry(scopedKey.sublist(0, 6), validGps);

          // No GPS frame should keep previous valid GPS.
          final batteryOnly = CayenneLppParser.createBatteryData(3.8);
          scopedProvider.updateTelemetry(scopedKey.sublist(0, 6), batteryOnly);

          var updated = scopedProvider.findContactByKey(scopedKey)!;
          expect(updated.telemetry, isNotNull);
          expect(updated.telemetry!.gpsLocation, isNotNull);
          expect(
            updated.telemetry!.gpsLocation!.latitude,
            closeTo(45.1234, 0.0001),
          );
          expect(
            updated.telemetry!.gpsLocation!.longitude,
            closeTo(13.8765, 0.0001),
          );

          // Invalid 0,0 GPS frame should also keep previous valid GPS.
          final invalidGps = CayenneLppParser.createGpsData(
            latitude: 0.0,
            longitude: 0.0,
          );
          scopedProvider.updateTelemetry(scopedKey.sublist(0, 6), invalidGps);

          updated = scopedProvider.findContactByKey(scopedKey)!;
          expect(updated.telemetry, isNotNull);
          expect(updated.telemetry!.gpsLocation, isNotNull);
          expect(
            updated.telemetry!.gpsLocation!.latitude,
            closeTo(45.1234, 0.0001),
          );
          expect(
            updated.telemetry!.gpsLocation!.longitude,
            closeTo(13.8765, 0.0001),
          );
        }
      },
    );

    test(
      'retains last known gps when a contact refresh arrives without location',
      () {
        final firstFix = CayenneLppParser.createGpsData(
          latitude: 45.1234,
          longitude: 13.8765,
        );
        provider.updateTelemetry(publicKey.sublist(0, 6), firstFix);

        provider.addOrUpdateContact(
          Contact(
            publicKey: publicKey,
            type: ContactType.chat,
            flags: 0,
            outPathLen: 0,
            outPath: Uint8List(64),
            advName: 'Test Contact',
            lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            advLat: 0,
            advLon: 0,
            lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );

        final updated = provider.findContactByKey(publicKey)!;
        expect(updated.telemetry, isNotNull);
        expect(updated.telemetry!.gpsLocation, isNotNull);
        expect(
          updated.telemetry!.gpsLocation!.latitude,
          closeTo(45.1234, 0.0001),
        );
        expect(
          updated.telemetry!.gpsLocation!.longitude,
          closeTo(13.8765, 0.0001),
        );
        expect(updated.advLat, equals((45.1234 * 1e6).round()));
        expect(updated.advLon, equals((13.8765 * 1e6).round()));
        expect(updated.displayLocation, isNotNull);
        expect(updated.displayLocation!.latitude, closeTo(45.1234, 0.0001));
        expect(updated.displayLocation!.longitude, closeTo(13.8765, 0.0001));
      },
    );

    test('builds message snapshot from latest valid telemetry', () {
      final telemetryData = CayenneLppParser.createGpsData(
        latitude: 45.0001,
        longitude: 13.9999,
      );

      provider.updateTelemetry(publicKey.sublist(0, 6), telemetryData);
      final contact = provider.findContactByKey(publicKey)!;
      final snapshot = provider.buildMessageContactLocationSnapshot(
        contact,
        capturedAt: DateTime.now(),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.source, equals('telemetry'));
      expect(snapshot.location.latitude, closeTo(45.0001, 0.0001));
      expect(snapshot.location.longitude, closeTo(13.9999, 0.0001));
    });

    test('builds message snapshot from advert when telemetry is invalid', () {
      final invalidTelemetry = CayenneLppParser.createGpsData(
        latitude: 0.0,
        longitude: 0.0,
      );

      provider.updateTelemetry(publicKey.sublist(0, 6), invalidTelemetry);
      final contact = provider.findContactByKey(publicKey)!;
      final snapshot = provider.buildMessageContactLocationSnapshot(
        contact,
        capturedAt: DateTime.now(),
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.source, equals('advert'));
      expect(snapshot.location.latitude, closeTo(46.0569, 0.000001));
      expect(snapshot.location.longitude, closeTo(14.5058, 0.000001));
    });

    test(
      'persists last valid telemetry gps on the contact across reloads',
      () async {
        final telemetryData = CayenneLppParser.createGpsData(
          latitude: 45.0001,
          longitude: 13.9999,
        );

        provider.updateTelemetry(publicKey.sublist(0, 6), telemetryData);
        await Future<void>.delayed(Duration.zero);

        final reloadedProvider = ContactsProvider();
        await reloadedProvider.initializeEarly();

        final reloaded = reloadedProvider.findContactByKey(publicKey)!;
        expect(reloaded.advLat, equals((45.0001 * 1e6).round()));
        expect(reloaded.advLon, equals((13.9999 * 1e6).round()));
        expect(reloaded.advertLocation, isNotNull);
        expect(reloaded.advertLocation!.latitude, closeTo(45.0001, 0.0001));
        expect(reloaded.advertLocation!.longitude, closeTo(13.9999, 0.0001));
      },
    );
  });

  group('ContactsProvider route updates', () {
    late ContactsProvider provider;
    late Uint8List publicKey;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ContactsProvider();
      publicKey = createPublicKey(64);
      provider.addOrUpdateContact(
        createContact(key: publicKey, type: ContactType.chat, name: 'Routey'),
      );
    });

    test('optimistically stores a multi-byte route locally', () {
      final route = ContactRouteCodec.parse('AABB,CCDD');

      provider.setContactRouteLocal(
        publicKey,
        signedEncodedPathLen: route.signedEncodedPathLen,
        paddedPathBytes: route.paddedPathBytes,
      );

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.routeHasPath, isTrue);
      expect(updated.routeHashSize, 2);
      expect(updated.routeHopCount, 2);
      expect(updated.routeCanonicalText, 'AABB,CCDD');
    });

    test('resetContactRouteLocal clears route state', () {
      final route = ContactRouteCodec.parse('AA,BB,CC');
      provider.setContactRouteLocal(
        publicKey,
        signedEncodedPathLen: route.signedEncodedPathLen,
        paddedPathBytes: route.paddedPathBytes,
      );

      provider.resetContactRouteLocal(publicKey);

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.routeHasPath, isFalse);
      expect(updated.routeSummary, 'Flood/Unknown');
    });
  });

  group('ContactsProvider.updateFastGps', () {
    late ContactsProvider provider;
    late Uint8List publicKey;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ContactsProvider();
      publicKey = createPublicKey(50);
      provider.addOrUpdateContact(
        createContact(key: publicKey, type: ContactType.chat, name: 'Fast GPS'),
      );
    });

    test('updates gps while preserving other telemetry fields', () {
      final batteryOnly = CayenneLppParser.createBatteryData(3.9);
      provider.updateTelemetry(publicKey.sublist(0, 6), batteryOnly);

      provider.updateFastGps(
        publicKey.sublist(0, 6),
        const FastGpsPacket(
          senderKey6: '323334353637',
          latitude: 44.123456,
          longitude: 13.654321,
          timestampSeconds: 1700001234,
        ),
      );

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.telemetry, isNotNull);
      expect(updated.telemetry!.gpsLocation, isNotNull);
      expect(
        updated.telemetry!.gpsLocation!.latitude,
        closeTo(44.123456, 0.000001),
      );
      expect(
        updated.telemetry!.gpsLocation!.longitude,
        closeTo(13.654321, 0.000001),
      );
      expect(updated.telemetry!.batteryMilliVolts, isNotNull);
      expect(updated.advLat, equals((44.123456 * 1e6).round()));
      expect(updated.advLon, equals((13.654321 * 1e6).round()));
      expect(updated.lastAdvert, equals(1700001234));
    });

    test('ignores unknown sender prefix safely', () {
      final before = provider.findContactByKey(publicKey)!;
      provider.updateFastGps(
        Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        const FastGpsPacket(
          senderKey6: '010203040506',
          latitude: 10,
          longitude: 20,
          timestampSeconds: 99,
        ),
      );
      final after = provider.findContactByKey(publicKey)!;
      expect(after.advLat, equals(before.advLat));
      expect(after.advLon, equals(before.advLon));
    });
  });
}
