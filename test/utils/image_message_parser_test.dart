import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';

void main() {
  group('ImageEnvelope', () {
    test('encodes and parses IE4 with compressed session id', () {
      final env = ImageEnvelope(
        sessionId: '0000000a',
        format: ImageFormat.avif,
        total: 14,
        width: 256,
        height: 171,
        sizeBytes: 2100,
      );

      final text = env.encode();
      expect(text.startsWith('IE4:'), isTrue);
      expect(text.split(':')[1], equals('a'));

      final parsed = ImageEnvelope.tryParse(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('0000000a'));
      expect(parsed.format, equals(ImageFormat.avif));
      expect(parsed.total, equals(14));
      expect(parsed.width, equals(256));
      expect(parsed.height, equals(171));
      expect(parsed.sizeBytes, equals(2100));
      expect(parsed.version, equals(4));
    });

    test('rejects IE1 legacy prefix', () {
      const legacy = 'IE1:deadbeef:0:7:128:128:1050:aabbccddeeff:1700000000:1';
      expect(ImageEnvelope.tryParse(legacy), isNull);
    });

  });

  group('ImageFetchRequest', () {
    test('encodes and parses IR4 with compressed sid', () {
      final req = ImageFetchRequest(
        sessionId: '0000000a',
        requesterKey6: 'ffeeddccbbaa',
      );

      final text = req.encode();
      expect(text.startsWith('IR4:'), isTrue);
      expect(text.split(':')[1], equals('a'));

      final parsed = ImageFetchRequest.tryParse(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('0000000a'));
      expect(parsed.want, equals('all'));
      expect(parsed.requesterKey6, equals('ffeeddccbbaa'));
      expect(parsed.version, equals(4));
    });

    test('encodes and parses compact missing index ranges', () {
      final req = ImageFetchRequest(
        sessionId: '0000000a',
        want: 'missing',
        missingIndices: const [0, 1, 2, 5, 6, 8],
        requesterKey6: 'ffeeddccbbaa',
      );

      final text = req.encode();
      expect(text, contains(':m0-2.5-6.8:'));

      final parsed = ImageFetchRequest.tryParse(text);
      expect(parsed, isNotNull);
      expect(parsed!.want, equals('missing'));
      expect(parsed.missingIndices, equals([0, 1, 2, 5, 6, 8]));
    });

    test('rejects IR1 legacy prefix', () {
      const legacy = 'IR1:00112233:a:ffeeddccbbaa:1700000001:1';
      expect(ImageFetchRequest.tryParse(legacy), isNull);
    });

    test('encodes and parses binary fetch request', () {
      final req = ImageFetchRequest(
        sessionId: '01020304',
        want: 'missing',
        missingIndices: const [0, 2, 5],
        requesterKey6: 'ffeeddccbbaa',
      );

      final payload = req.encodeBinary();
      expect(ImageFetchRequest.isRequestBinary(payload), isTrue);

      final parsed = ImageFetchRequest.tryParseBinary(payload);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.want, equals('missing'));
      expect(parsed.missingIndices, equals([0, 2, 5]));
      expect(parsed.requesterKey6, equals('ffeeddccbbaa'));
      expect(parsed.version, equals(4));
    });
  });

  group('ImageFragmentAck', () {
    test('encodes and parses binary ack', () {
      final ack = ImageFragmentAck(sessionId: '01020304', index: 9);
      final payload = ack.encodeBinary();
      expect(ImageFragmentAck.isImageFragmentAckBinary(payload), isTrue);
      final parsed = ImageFragmentAck.tryParseBinary(payload);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.index, equals(9));
    });
  });

  group('safeImageDataBytesForPath', () {
    test('caps direct-route fragments to conservative default size', () {
      expect(safeImageDataBytesForPath(0), equals(ImagePacket.maxDataBytes));
    });

    test('shrinks for longer paths but never exceeds conservative default', () {
      expect(
        safeImageDataBytesForPath(2),
        lessThanOrEqualTo(ImagePacket.maxDataBytes),
      );
    });
  });
}
