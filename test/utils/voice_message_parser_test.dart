import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';

void main() {
  group('VoiceEnvelope', () {
    test('encodes and parses valid envelope', () {
      final env = VoiceEnvelope(
        sessionId: '0000000a',
        mode: VoicePacketMode.mode1200,
        total: 4,
        durationMs: 3000,
      );

      final text = env.encodeText();
      expect(VoiceEnvelope.isVoiceEnvelopeText(text), isTrue);
      expect(text.startsWith('VE3:'), isTrue);
      expect(text.split(':')[1], equals('a'));

      final parsed = VoiceEnvelope.tryParseText(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('0000000a'));
      expect(parsed.mode, equals(VoicePacketMode.mode1200));
      expect(parsed.total, equals(4));
      expect(parsed.durationMs, equals(3000));
      expect(parsed.version, equals(3));
    });

    test('rejects invalid envelope payload', () {
      final text = 'VE3:bad_sid:1:2:1000';
      expect(VoiceEnvelope.tryParseText(text), isNull);
    });

    test('rejects legacy v1 envelope prefix', () {
      const legacy = 'VE1:deadbeef:1:4:3200:aabbccddeeff:1700000000:1';
      expect(VoiceEnvelope.tryParseText(legacy), isNull);
    });
  });

  group('VoiceFetchRequest', () {
    test('encodes and parses valid request', () {
      final req = VoiceFetchRequest(
        sessionId: '0000000a',
        requesterKey6: 'ffeeddccbbaa',
      );
      final text = req.encodeText();
      expect(VoiceFetchRequest.isVoiceFetchRequestText(text), isTrue);
      expect(text.startsWith('VR3:'), isTrue);
      expect(text.split(':')[1], equals('a'));

      final parsed = VoiceFetchRequest.tryParseText(text);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('0000000a'));
      expect(parsed.want, equals('all'));
      expect(parsed.requesterKey6, equals('ffeeddccbbaa'));
      expect(parsed.version, equals(3));
    });

    test('rejects invalid request payload', () {
      expect(
        VoiceFetchRequest.tryParseText(
          'VR3:a:chunk:ffeeddccbbaa',
        ),
        isNull,
      );
    });

    test('rejects legacy v1 request prefix', () {
      const legacy = 'VR1:00112233:a:ffeeddccbbaa:1700000001:1';
      expect(VoiceFetchRequest.tryParseText(legacy), isNull);
    });

    test('encodes and parses missing-packet request', () {
      final req = VoiceFetchRequest(
        sessionId: '0000000a',
        want: 'missing',
        missingIndices: const [0, 1, 2, 3, 7],
        requesterKey6: 'ffeeddccbbaa',
      );
      final text = req.encodeText();
      expect(text, contains(':m0-3.7:'));

      final parsed = VoiceFetchRequest.tryParseText(text);
      expect(parsed, isNotNull);
      expect(parsed!.want, equals('missing'));
      expect(parsed.missingIndices, equals([0, 1, 2, 3, 7]));
    });

    test('encodes and parses binary fetch request', () {
      final req = VoiceFetchRequest(
        sessionId: '01020304',
        want: 'missing',
        missingIndices: const [1, 4],
        requesterKey6: 'ffeeddccbbaa',
      );

      final payload = req.encodeBinary();
      expect(VoiceFetchRequest.isVoiceFetchRequestBinary(payload), isTrue);

      final parsed = VoiceFetchRequest.tryParseBinary(payload);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.want, equals('missing'));
      expect(parsed.missingIndices, equals([1, 4]));
      expect(parsed.requesterKey6, equals('ffeeddccbbaa'));
      expect(parsed.version, equals(3));
    });
  });

  group('VoiceFragmentAck', () {
    test('encodes and parses binary ack', () {
      final ack = VoiceFragmentAck(sessionId: '01020304', index: 7);
      final payload = ack.encodeBinary();
      expect(VoiceFragmentAck.isVoiceFragmentAckBinary(payload), isTrue);
      final parsed = VoiceFragmentAck.tryParseBinary(payload);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.index, equals(7));
    });
  });

  group('VoicePacket binary format', () {
    test('constructs binary datagram from actual packet data', () {
      final actualCodec2 = Uint8List.fromList([
        0xD3,
        0x19,
        0x7A,
        0x00,
        0xFE,
        0x44,
        0xC1,
        0x2B,
        0x88,
      ]);

      final pkt = VoicePacket(
        sessionId: '01020304',
        mode: VoicePacketMode.mode1300,
        index: 2,
        total: 5,
        codec2Data: actualCodec2,
      );

      final datagram = pkt.encodeBinary();
      expect(datagram[0], equals(0x56)); // magic 'V'
      expect(datagram.sublist(1, 5), equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(datagram[5], equals(2));
      expect(datagram.sublist(6), equals(actualCodec2));

      final parsed = VoicePacket.tryParseBinary(datagram);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, equals('01020304'));
      expect(parsed.mode, equals(VoicePacketMode.mode1300));
      expect(parsed.index, equals(2));
      expect(parsed.total, equals(0));
      expect(parsed.codec2Data, equals(actualCodec2));
    });
  });

  group('VoiceWaveform', () {
    test('builds bars from packet bytes', () {
      final packet = VoicePacket(
        sessionId: '1234abcd',
        mode: VoicePacketMode.mode1200,
        index: 0,
        total: 1,
        codec2Data: Uint8List.fromList([
          0,
          255,
          10,
          245,
          120,
          130,
          64,
          192,
          32,
          224,
        ]),
      );

      final bars = VoiceWaveform.buildBarsFromPackets([packet], bars: 8);
      expect(bars.length, equals(8));
      expect(bars.every((v) => v >= 0.0 && v <= 1.0), isTrue);
      expect(bars.any((v) => v > 0.2), isTrue);
    });

    test('returns zeros for missing packet data', () {
      final bars = VoiceWaveform.buildBarsFromPackets(const [], bars: 6);
      expect(bars, equals(List<double>.filled(6, 0.0)));
    });
  });
}
