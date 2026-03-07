import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';

void main() {
  Contact buildContact({
    required int signedPathLen,
    required Uint8List outPath,
  }) {
    return Contact(
      publicKey: Uint8List.fromList(List<int>.generate(32, (index) => index)),
      type: ContactType.chat,
      flags: 0,
      outPathLen: signedPathLen,
      outPath: outPath,
      advName: 'Route Contact',
      lastAdvert: 0,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
    );
  }

  group('ContactRouteCodec.parse', () {
    test('parses 1-byte hop routes', () {
      final route = ContactRouteCodec.parse('AA,BB,CC');

      expect(route.hashSize, 1);
      expect(route.hopCount, 3);
      expect(route.encodedPathLen, 0x03);
      expect(route.canonicalText, 'AA,BB,CC');
      expect(route.pathBytes, [0xAA, 0xBB, 0xCC]);
    });

    test('parses 2-byte hop routes', () {
      final route = ContactRouteCodec.parse('AABB,CCDD');

      expect(route.hashSize, 2);
      expect(route.hopCount, 2);
      expect(route.encodedPathLen, 0x42);
      expect(route.canonicalText, 'AABB,CCDD');
      expect(route.pathBytes, [0xAA, 0xBB, 0xCC, 0xDD]);
    });

    test('parses 3-byte hop routes', () {
      final route = ContactRouteCodec.parse('AABBCC,DDEEFF');

      expect(route.hashSize, 3);
      expect(route.hopCount, 2);
      expect(route.encodedPathLen, 0x82);
      expect(route.signedEncodedPathLen, -126);
      expect(route.pathBytes, [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
    });

    test('accepts colon-separated hops and normalizes output', () {
      final route = ContactRouteCodec.parse('AA:BB,CC:DD');

      expect(route.hashSize, 2);
      expect(route.canonicalText, 'AABB,CCDD');
    });

    test('rejects mixed hop widths', () {
      expect(
        () => ContactRouteCodec.parse('AA,AABB'),
        throwsA(isA<ContactRouteFormatException>()),
      );
    });

    test('rejects invalid tokens', () {
      expect(
        () => ContactRouteCodec.parse('AA,XYZ'),
        throwsA(isA<ContactRouteFormatException>()),
      );
      expect(
        () => ContactRouteCodec.parse('AAA'),
        throwsA(isA<ContactRouteFormatException>()),
      );
    });

    test('rejects routes over 64 bytes', () {
      final tooLong = List.filled(22, 'AABBCC').join(',');
      expect(
        () => ContactRouteCodec.parse(tooLong),
        throwsA(isA<ContactRouteFormatException>()),
      );
    });
  });

  group('Contact route helpers', () {
    test('interprets signed 3-byte descriptors as valid routes', () {
      final outPath = Uint8List(64)
        ..setRange(0, 6, [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
      final contact = buildContact(signedPathLen: -126, outPath: outPath);

      expect(contact.routeHasPath, isTrue);
      expect(contact.routeHashSize, 3);
      expect(contact.routeHopCount, 2);
      expect(contact.routeCanonicalText, 'AABBCC,DDEEFF');
      expect(contact.routeSupportsLegacyRawTransport, isFalse);
    });

    test('treats -1 as unknown route', () {
      final contact = buildContact(signedPathLen: -1, outPath: Uint8List(0));

      expect(contact.routeHasPath, isFalse);
      expect(contact.routeSummary, 'Flood/Unknown');
    });
  });
}
