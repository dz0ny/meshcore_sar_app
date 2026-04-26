import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/utils/log_rx_route_decoder.dart';

void main() {
  group('LogRxRouteDecoder.decode', () {
    test('parses route and sender from LOG_RX_DATA packet', () {
      final packet = Uint8List.fromList([
        0x88,
        0x37,
        0xae,
        0x05,
        0x04,
        0xc2,
        0xba,
        0x5f,
        0xde,
        0x5c,
      ]);

      final decoded = LogRxRouteDecoder.decode(packet);

      expect(decoded, isNotNull);
      expect(decoded!.payloadType, 0x01);
      expect(decoded.pathDescriptor, 0x04);
      expect(decoded.pathBytes, [0xc2, 0xba, 0x5f, 0xde]);
      expect(decoded.hashSize, 1);
      expect(decoded.hopHashes, ['c2', 'ba', '5f', 'de']);
      expect(decoded.originalSenderHashHex, 'c2');
    });

    test('parses legacy two byte paths as two one-byte hops', () {
      final packet = Uint8List.fromList([
        0x88,
        0x37,
        0xae,
        0x05,
        0x02,
        0xc2,
        0xba,
      ]);

      final decoded = LogRxRouteDecoder.decode(packet);

      expect(decoded, isNotNull);
      expect(decoded!.pathDescriptor, 0x02);
      expect(decoded.pathBytes, [0xc2, 0xba]);
      expect(decoded.hashSize, 1);
      expect(decoded.hopCount, 2);
      expect(decoded.hopHashes, ['c2', 'ba']);
    });

    test('parses encoded descriptor with 2-byte hashes', () {
      final packet = Uint8List.fromList([
        0x88,
        0x37,
        0xae,
        0x05,
        0x42,
        0xc2,
        0xba,
        0x5f,
        0xde,
        0x5c,
      ]);

      final decoded = LogRxRouteDecoder.decode(packet);

      expect(decoded, isNotNull);
      expect(decoded!.pathDescriptor, 0x42);
      expect(decoded.pathBytes, [0xc2, 0xba, 0x5f, 0xde]);
      expect(decoded.hashSize, 2);
      expect(decoded.hopCount, 2);
      expect(decoded.hopHashes, ['c2ba', '5fde']);
    });

    test('uses one byte hashes for legacy packet lengths', () {
      final packet = Uint8List.fromList([
        0x88,
        0x37,
        0xae,
        0x09,
        0x06,
        0xaa,
        0xbb,
        0xcc,
        0xdd,
        0xee,
        0xff,
      ]);

      final decoded = LogRxRouteDecoder.decode(packet, preferredHashSize: 2);

      expect(decoded, isNotNull);
      expect(decoded!.hashSize, 1);
      expect(decoded.hopHashes, ['aa', 'bb', 'cc', 'dd', 'ee', 'ff']);
    });
  });

  group('LogRxRouteDecoder.resolveHash', () {
    test('prefers own node when hash matches device key', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        'c201',
        contacts: const [],
        ownPublicKey: Uint8List.fromList([0xc2, 0x01, 0x02]),
        ownName: 'Base',
      );

      expect(resolved.isOwnNode, isTrue);
      expect(resolved.label, 'Base (you)');
    });

    test('resolves unique contact by first public key byte', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        'c211',
        contacts: [
          _contact(name: 'Alpha', keyPrefix: [0xc2, 0x11]),
        ],
      );

      expect(resolved.isUniqueMatch, isTrue);
      expect(resolved.label, 'Alpha');
    });

    test('marks ambiguous matches without pretending certainty', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        'c2',
        contacts: [
          _contact(name: 'Alpha', keyPrefix: [0xc2, 0x11]),
          _contact(name: 'Bravo', keyPrefix: [0xc2, 0x22]),
        ],
      );

      expect(resolved.isUniqueMatch, isFalse);
      expect(resolved.matchCount, 2);
    });
  });

  group('LogRxRouteDecoder.reverseHopBytes', () {
    test('reverses path by hop size', () {
      final reversed = LogRxRouteDecoder.reverseHopBytes([
        0xc2,
        0xba,
        0x5f,
        0xde,
        0xaa,
        0xbb,
      ], hashSize: 2);

      expect(reversed, [0xaa, 0xbb, 0x5f, 0xde, 0xc2, 0xba]);
    });
  });
}

Contact _contact({required String name, required List<int> keyPrefix}) {
  return Contact(
    publicKey: Uint8List.fromList([
      ...keyPrefix,
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
    ]),
    type: ContactType.chat,
    flags: 0,
    outPathLen: 0,
    outPath: Uint8List(0),
    advName: name,
    lastAdvert: 0,
    advLat: 0,
    advLon: 0,
    lastMod: 0,
  );
}
