import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/contact_group.dart';
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
      'clears telemetry gps on refresh when gps is invalid or missing but keeps fallback display location',
      () {
        final contactTypes = <ContactType>[
          ContactType.chat,
          ContactType.repeater,
          ContactType.sensor,
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

          // No GPS frame should clear telemetry GPS but keep the last known
          // contact location as display fallback.
          final batteryOnly = CayenneLppParser.createBatteryData(3.8);
          scopedProvider.updateTelemetry(scopedKey.sublist(0, 6), batteryOnly);

          var updated = scopedProvider.findContactByKey(scopedKey)!;
          expect(updated.telemetry, isNotNull);
          expect(updated.telemetry!.gpsLocation, isNull);
          expect(updated.displayLocation!.latitude, closeTo(45.1234, 0.0001));
          expect(updated.displayLocation!.longitude, closeTo(13.8765, 0.0001));

          // Invalid 0,0 GPS frame should behave the same way.
          final invalidGps = CayenneLppParser.createGpsData(
            latitude: 0.0,
            longitude: 0.0,
          );
          scopedProvider.updateTelemetry(scopedKey.sublist(0, 6), invalidGps);

          updated = scopedProvider.findContactByKey(scopedKey)!;
          expect(updated.telemetry, isNotNull);
          expect(updated.telemetry!.gpsLocation, isNull);
          expect(updated.displayLocation!.latitude, closeTo(45.1234, 0.0001));
          expect(updated.displayLocation!.longitude, closeTo(13.8765, 0.0001));
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

    test('retains existing telemetry when contact refresh omits telemetry', () {
      final initialTelemetry = ContactTelemetry(
        gpsLocation: const LatLng(45.1234, 13.8765),
        batteryPercentage: 76.5,
        batteryMilliVolts: 3890,
        temperature: 21.5,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        humidity: 62.0,
        pressure: 1008.4,
        extraSensorData: const {'co2': 415.0},
      );

      provider.addOrUpdateContact(
        createContact(
          key: publicKey,
          type: ContactType.chat,
        ).copyWith(telemetry: initialTelemetry),
      );

      provider.addOrUpdateContact(
        Contact(
          publicKey: publicKey,
          type: ContactType.chat,
          flags: 0,
          outPathLen: 0,
          outPath: Uint8List(64),
          advName: 'Test Contact Refreshed',
          lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          advLat: 0,
          advLon: 0,
          lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.telemetry, isNotNull);
      expect(updated.telemetry!.gpsLocation, const LatLng(45.1234, 13.8765));
      expect(updated.telemetry!.batteryPercentage, equals(76.5));
      expect(updated.telemetry!.batteryMilliVolts, equals(3890));
      expect(updated.telemetry!.temperature, equals(21.5));
      expect(updated.telemetry!.humidity, equals(62.0));
      expect(updated.telemetry!.pressure, equals(1008.4));
      expect(updated.telemetry!.extraSensorData, containsPair('co2', 415.0));
    });

    test('retains existing telemetry during bulk contacts sync', () {
      final initialTelemetry = ContactTelemetry(
        gpsLocation: const LatLng(45.1234, 13.8765),
        batteryPercentage: 76.5,
        batteryMilliVolts: 3890,
        temperature: 21.5,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        humidity: 62.0,
        pressure: 1008.4,
        extraSensorData: const {'co2': 415.0},
      );

      provider.addOrUpdateContact(
        createContact(
          key: publicKey,
          type: ContactType.chat,
        ).copyWith(telemetry: initialTelemetry),
      );

      provider.addContacts([
        Contact(
          publicKey: publicKey,
          type: ContactType.chat,
          flags: 0,
          outPathLen: 0,
          outPath: Uint8List(64),
          advName: 'Synced Contact',
          lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          advLat: 0,
          advLon: 0,
          lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      ]);

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.telemetry, isNotNull);
      expect(updated.telemetry!.gpsLocation, const LatLng(45.1234, 13.8765));
      expect(updated.telemetry!.batteryPercentage, equals(76.5));
      expect(updated.telemetry!.batteryMilliVolts, equals(3890));
      expect(updated.telemetry!.temperature, equals(21.5));
      expect(updated.telemetry!.humidity, equals(62.0));
      expect(updated.telemetry!.pressure, equals(1008.4));
      expect(updated.telemetry!.extraSensorData, containsPair('co2', 415.0));
    });

    test(
      'retains scalar telemetry but wipes stale extra sensor fields on refresh',
      () {
        final fullTelemetry = ContactTelemetry(
          gpsLocation: const LatLng(46.0569, 14.5058),
          batteryPercentage: 54.0,
          batteryMilliVolts: 3780,
          temperature: 19.5,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          humidity: 58.0,
          pressure: 1011.2,
          extraSensorData: const {'pm25': 8.0},
        );

        provider.addOrUpdateContact(
          createContact(
            key: publicKey,
            type: ContactType.chat,
          ).copyWith(telemetry: fullTelemetry),
        );

        final batteryOnly = CayenneLppParser.createBatteryData(3.95);
        provider.updateTelemetry(publicKey.sublist(0, 6), batteryOnly);

        final updated = provider.findContactByKey(publicKey)!;
        expect(updated.telemetry, isNotNull);
        expect(updated.telemetry!.gpsLocation, isNull);
        expect(updated.displayLocation, const LatLng(46.0569, 14.5058));
        expect(updated.telemetry!.batteryMilliVolts, isNotNull);
        expect(updated.telemetry!.batteryPercentage, isNotNull);
        expect(updated.telemetry!.temperature, equals(19.5));
        expect(updated.telemetry!.humidity, equals(58.0));
        expect(updated.telemetry!.pressure, equals(1011.2));
        expect(
          updated.telemetry!.extraSensorData,
          containsPair('__source_channel:battery', 0),
        );
        expect(
          updated.telemetry!.extraSensorData,
          containsPair('__source_channel:voltage', 0),
        );
        expect(updated.telemetry!.extraSensorData, isNot(contains('pm25')));
      },
    );

    test(
      'replaces old source-channel mappings when a metric moves channels',
      () {
        final initialTelemetry = ContactTelemetry(
          gpsLocation: null,
          batteryPercentage: null,
          batteryMilliVolts: null,
          temperature: 21.5,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          humidity: null,
          pressure: null,
          extraSensorData: const {
            '__source_channel:temperature': 2,
            'temperature_2': 21.5,
            'humidity_4': 66.0,
          },
        );

        provider.addOrUpdateContact(
          createContact(
            key: publicKey,
            type: ContactType.chat,
          ).copyWith(telemetry: initialTelemetry),
        );

        final movedChannelTelemetry = CayenneLppParser.createTemperatureData(
          23.5,
          channel: 3,
        );

        provider.updateTelemetry(
          publicKey.sublist(0, 6),
          movedChannelTelemetry,
        );

        final updated = provider.findContactByKey(publicKey)!;
        expect(updated.telemetry, isNotNull);
        expect(updated.telemetry!.temperature, closeTo(23.5, 0.1));
        expect(
          updated.telemetry!.extraSensorData,
          containsPair('__source_channel:temperature', 3),
        );
        expect(
          updated.telemetry!.extraSensorData,
          containsPair('temperature_3', closeTo(23.5, 0.1)),
        );
        expect(
          updated.telemetry!.extraSensorData,
          isNot(contains('temperature_2')),
        );
        expect(
          updated.telemetry!.extraSensorData,
          isNot(contains('humidity_4')),
        );
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

    test('prefers a local name override and preserves it across refreshes', () {
      provider.setContactNameOverride(publicKeyHex(publicKey), 'Rescue One');

      final renamed = provider.findContactByKey(publicKey)!;
      expect(renamed.nameOverride, 'Rescue One');
      expect(renamed.displayName, 'Rescue One');

      provider.addOrUpdateContact(
        Contact(
          publicKey: publicKey,
          type: ContactType.chat,
          flags: 0,
          outPathLen: 0,
          outPath: Uint8List(64),
          advName: 'Updated Advertised Name',
          lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          advLat: (46.0569 * 1e6).toInt(),
          advLon: (14.5058 * 1e6).toInt(),
          lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      final refreshed = provider.findContactByKey(publicKey)!;
      expect(refreshed.nameOverride, 'Rescue One');
      expect(refreshed.displayName, 'Rescue One');
      expect(refreshed.advName, 'Updated Advertised Name');
    });

    test('persists a local name override across reloads', () async {
      provider.setContactNameOverride(publicKeyHex(publicKey), 'Rescue One');
      await Future<void>.delayed(Duration.zero);

      final reloadedProvider = ContactsProvider();
      await reloadedProvider.initializeEarly();

      final reloaded = reloadedProvider.findContactByKey(publicKey)!;
      expect(reloaded.nameOverride, 'Rescue One');
      expect(reloaded.displayName, 'Rescue One');
    });
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

    test('stores inferred fallback gps when route is set locally', () {
      final route = ContactRouteCodec.parse('AABB,CCDD');
      const fallback = LatLng(46.1001, 14.5002);

      provider.setContactRouteLocal(
        publicKey,
        signedEncodedPathLen: route.signedEncodedPathLen,
        paddedPathBytes: route.paddedPathBytes,
        inferredFallbackLocation: fallback,
      );

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.displayLocation, isNotNull);
      expect(updated.displayLocation!.latitude, closeTo(46.1001, 0.000001));
      expect(updated.displayLocation!.longitude, closeTo(14.5002, 0.000001));
      expect(updated.advertHistory, isNotEmpty);
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

    test('retains existing route when contact refresh omits path', () {
      final retainedRoute = ContactRouteCodec.parse('AABB,CCDD');
      provider.setContactRouteLocal(
        publicKey,
        signedEncodedPathLen: retainedRoute.signedEncodedPathLen,
        paddedPathBytes: retainedRoute.paddedPathBytes,
      );

      provider.addOrUpdateContact(
        createContact(
          key: publicKey,
          type: ContactType.chat,
          name: 'Routey',
        ).copyWith(outPathLen: -1, outPath: Uint8List(0)),
      );

      final updated = provider.findContactByKey(publicKey)!;
      expect(updated.routeHasPath, isTrue);
      expect(updated.routeCanonicalText, 'AABB,CCDD');
    });

    test('applies retained pending advert route when contact is resolved', () {
      final pendingKey = createPublicKey(96);
      final retainedRoute = ContactRouteCodec.parse('1122,3344');

      provider.retainReceivedRoute(
        pendingKey,
        signedEncodedPathLen: retainedRoute.signedEncodedPathLen,
        paddedPathBytes: retainedRoute.paddedPathBytes,
      );
      provider.addPendingAdvert(pendingKey);

      provider.addOrUpdateContact(
        createContact(
          key: pendingKey,
          type: ContactType.chat,
          name: 'Pending Routey',
        ).copyWith(outPathLen: -1, outPath: Uint8List(0)),
      );

      final updated = provider.findContactByKey(pendingKey)!;
      expect(updated.routeHasPath, isTrue);
      expect(updated.routeCanonicalText, '1122,3344');
      expect(
        provider.pendingAdverts.where(
          (advert) => advert.publicKeyHex == updated.publicKeyHex,
        ),
        isEmpty,
      );
    });

    test('infers a fallback location 100m from last-hop repeater', () {
      final repeaterKey = Uint8List.fromList([
        0xCC,
        0xDD,
        0x10,
        0x11,
        0x12,
        0x13,
        ...List<int>.generate(26, (index) => index + 20),
      ]);
      provider.addOrUpdateContact(
        createContact(
          key: repeaterKey,
          type: ContactType.repeater,
          name: 'Relay Alpha',
        ),
      );

      final targetKey = createPublicKey(120);
      final route = ContactRouteCodec.parse('AABB,CCDD');
      provider.addOrUpdateContact(
        Contact(
          publicKey: targetKey,
          type: ContactType.chat,
          flags: 0,
          outPathLen: route.signedEncodedPathLen,
          outPath: route.paddedPathBytes,
          advName: 'No GPS',
          lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          advLat: 0,
          advLon: 0,
          lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );

      final updated = provider.findContactByKey(targetKey)!;
      final inferred = updated.displayLocation;
      final repeater = provider.findContactByKey(repeaterKey)!;
      final repeaterLocation = repeater.displayLocation;

      expect(inferred, isNotNull);
      expect(repeaterLocation, isNotNull);

      final distanceMeters = Geolocator.distanceBetween(
        repeaterLocation!.latitude,
        repeaterLocation.longitude,
        inferred!.latitude,
        inferred.longitude,
      );
      expect(distanceMeters, closeTo(100.0, 8.0));
    });

    test(
      'does not infer a fallback location when the contact advertises one',
      () {
        final repeaterKey = Uint8List.fromList([
          0xCC,
          0xDD,
          0x10,
          0x11,
          0x12,
          0x13,
          ...List<int>.generate(26, (index) => index + 20),
        ]);
        provider.addOrUpdateContact(
          createContact(
            key: repeaterKey,
            type: ContactType.repeater,
            name: 'Relay Alpha',
          ),
        );

        final targetKey = createPublicKey(121);
        final route = ContactRouteCodec.parse('AABB,CCDD');
        provider.addOrUpdateContact(
          Contact(
            publicKey: targetKey,
            type: ContactType.chat,
            flags: 0,
            outPathLen: route.signedEncodedPathLen,
            outPath: route.paddedPathBytes,
            advName: 'Has Advert',
            lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            advLat: (45.1234 * 1e6).toInt(),
            advLon: (13.8765 * 1e6).toInt(),
            lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        );

        final updated = provider.findContactByKey(targetKey)!;
        expect(updated.displayLocation, isNotNull);
        expect(updated.displayLocation!.latitude, closeTo(45.1234, 0.000001));
        expect(updated.displayLocation!.longitude, closeTo(13.8765, 0.000001));
      },
    );
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

  group('ContactsProvider saved contact groups', () {
    late ContactsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ContactsProvider();
    });

    test('adds and removes saved groups by filter', () async {
      expect(provider.savedContactGroups, isEmpty);

      await provider.addSavedGroupForFilter('teamMembers', 'alpha');

      expect(provider.savedContactGroups, hasLength(1));
      expect(provider.hasSavedGroupForFilter('teamMembers', 'alpha'), isTrue);
      expect(provider.hasSavedGroupForFilter('teamMembers', 'ALPHA'), isTrue);

      await provider.removeSavedGroupForFilter('teamMembers', 'ALPHA');

      expect(provider.savedContactGroups, isEmpty);
      expect(provider.hasSavedGroupForFilter('teamMembers', 'alpha'), isFalse);
    });

    test('loads persisted saved groups during initialization', () async {
      await provider.addSavedGroupForFilter('rooms', 'ops');

      final restored = ContactsProvider();
      await restored.initializeEarly();

      expect(restored.savedGroupsForSection('rooms'), hasLength(1));
      expect(restored.savedGroupsForSection('rooms').first.query, 'ops');
      expect(restored.savedGroupsForSection('rooms').first.label, 'ops');
    });

    test('replaces persisted auto groups for a section', () async {
      await provider.replaceAutoGroupsForSection('repeaters', [
        SavedContactGroup(
          id: '${ContactsProvider.autoGroupIdPrefix}repeaters_al',
          sectionKey: 'repeaters',
          label: 'AL-',
          query: 'AL-',
          createdAt: DateTime(2026, 3, 10, 12),
          matchPrefixes: const ['AL-'],
          isAutoGroup: true,
        ),
        SavedContactGroup(
          id: '${ContactsProvider.autoGroupIdPrefix}repeaters_others',
          sectionKey: 'repeaters',
          label: 'Others',
          query: 'Others',
          createdAt: DateTime(2026, 3, 10, 12),
          matchPrefixes: const ['CR-', 'DE-'],
          isAutoGroup: true,
        ),
      ]);

      final restored = ContactsProvider();
      await restored.initializeEarly();

      expect(restored.savedGroupsForSection('repeaters'), hasLength(2));
      expect(
        restored.savedGroupsForSection('repeaters').first.matchPrefixes,
        isNotEmpty,
      );
      expect(
        restored.savedGroupsForSection('repeaters').first.isAutoGroup,
        isTrue,
      );
    });
  });

  group('ContactsProvider device sync preparation', () {
    late ContactsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ContactsProvider();
    });

    test(
      'clears runtime contacts before sync without erasing persisted contacts or saved groups',
      () async {
        final key = createPublicKey(140);
        final pendingKey = createPublicKey(180);

        provider.addOrUpdateContact(
          createContact(key: key, type: ContactType.chat, name: 'Synced Later'),
        );
        provider.addPendingAdvert(pendingKey);
        await provider.addSavedGroupForFilter('teamMembers', 'alpha');

        await provider.prepareForDeviceContactSync();

        expect(provider.chatContacts, isEmpty);
        expect(provider.pendingAdverts, isEmpty);
        expect(provider.savedGroupsForSection('teamMembers'), hasLength(1));

        final restored = ContactsProvider();
        await restored.initializeEarly();

        expect(
          restored.chatContacts.map((contact) => contact.advName),
          contains('Synced Later'),
        );
        expect(restored.savedGroupsForSection('teamMembers'), hasLength(1));
      },
    );
  });

  group('ContactsProvider self telemetry', () {
    test(
      'stores self telemetry without re-adding the device as a contact',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ContactsProvider();
        final selfKey = createPublicKey(200);

        await provider.initialize(devicePublicKey: selfKey);
        provider.updateTelemetry(
          selfKey.sublist(0, 6),
          CayenneLppParser.createTemperatureData(23.5, channel: 1),
        );

        expect(provider.selfTelemetry, isNotNull);
        expect(provider.selfTelemetry!.temperature, closeTo(23.5, 0.1));
        expect(provider.findContactByKey(selfKey), isNull);
        expect(
          provider.contacts.any(
            (contact) => contact.publicKeyHex == publicKeyHex(selfKey),
          ),
          isFalse,
        );
      },
    );
  });
}

String publicKeyHex(Uint8List publicKey) {
  return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
