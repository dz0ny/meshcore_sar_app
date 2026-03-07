import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/media_swarm_protocol.dart';

void main() {
  group('MediaSwarmProtocol', () {
    test('encodes and decodes binary missing-fragment requests', () {
      const request = MediaSwarmRequest(
        mediaType: 'image',
        sessionId: 'deadbeef',
        requesterKey6: 'aabbccddeeff',
        missingIndices: [9, 2, 9, 0],
      );

      final decoded = MediaSwarmRequest.tryParseBinary(request.encodeBinary());

      expect(decoded, isNotNull);
      expect(decoded!.mediaType, 'image');
      expect(decoded.sessionId, 'deadbeef');
      expect(decoded.requesterKey6, 'aabbccddeeff');
      expect(decoded.missingIndices, [0, 2, 9]);
      expect(decoded.requestsAll, isFalse);
    });

    test('encodes and decodes binary availability advertisements', () {
      const availability = MediaSwarmAvailability(
        mediaType: 'voice',
        sessionId: '01020304',
        requesterKey6: 'aabbccddeeff',
        responderKey6: '112233445566',
        availableIndices: [7, 1],
      );

      final decoded = MediaSwarmAvailability.tryParseBinary(
        availability.encodeBinary(),
      );

      expect(decoded, isNotNull);
      expect(decoded!.mediaType, 'voice');
      expect(decoded.sessionId, '01020304');
      expect(decoded.requesterKey6, 'aabbccddeeff');
      expect(decoded.responderKey6, '112233445566');
      expect(decoded.availableIndices, [1, 7]);
      expect(decoded.servesAll, isFalse);
    });

    test('uses zero-count semantics when no indices are provided', () {
      const request = MediaSwarmRequest(
        mediaType: 'voice',
        sessionId: '01020304',
        requesterKey6: 'aabbccddeeff',
      );
      const availability = MediaSwarmAvailability(
        mediaType: 'image',
        sessionId: 'deadbeef',
        requesterKey6: 'aabbccddeeff',
        responderKey6: '112233445566',
        availableIndices: [],
      );

      expect(
        MediaSwarmRequest.tryParseBinary(request.encodeBinary())?.requestsAll,
        isTrue,
      );
      expect(
        MediaSwarmAvailability.tryParseBinary(
          availability.encodeBinary(),
        )?.servesAll,
        isTrue,
      );
    });
  });
}
