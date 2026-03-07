import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/helpers/session_metadata_restore.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';

void main() {
  group('restoreSessionMetadataFromMessages', () {
    test(
      'restores voice and image session senders from persisted envelopes',
      () {
        final voiceEnvelope = VoiceEnvelope(
          sessionId: '00112233',
          mode: VoicePacketMode.mode1200,
          total: 4,
          durationMs: 4000,
        );
        final imageEnvelope = ImageEnvelope(
          sessionId: '195cb2fb',
          format: ImageFormat.avif,
          total: 7,
          width: 118,
          height: 256,
          sizeBytes: 1069,
        );

        final restored = restoreSessionMetadataFromMessages([
          Message(
            id: 'plain',
            messageType: MessageType.channel,
            channelIdx: 0,
            pathLen: 0,
            textType: MessageTextType.plain,
            senderTimestamp: 1,
            text: 'plain text',
            receivedAt: DateTime.now(),
            deliveryStatus: MessageDeliveryStatus.sent,
          ),
          Message(
            id: 'voice',
            messageType: MessageType.channel,
            channelIdx: 0,
            pathLen: 0,
            textType: MessageTextType.plain,
            senderTimestamp: 2,
            text: voiceEnvelope.encodeText(),
            receivedAt: DateTime.now(),
            senderPublicKeyPrefix: Uint8List.fromList(
              [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff],
            ),
            deliveryStatus: MessageDeliveryStatus.sent,
          ),
          Message(
            id: 'image',
            messageType: MessageType.channel,
            channelIdx: 0,
            pathLen: 0,
            textType: MessageTextType.plain,
            senderTimestamp: 3,
            text: imageEnvelope.encode(),
            receivedAt: DateTime.now(),
            senderPublicKeyPrefix: Uint8List.fromList(
              [0xfe, 0x8b, 0x30, 0xee, 0x05, 0xfc],
            ),
            deliveryStatus: MessageDeliveryStatus.sent,
          ),
        ]);

        expect(
          restored.voiceSenderKeyBySession,
          equals({'00112233': 'aabbccddeeff'}),
        );
        expect(
          restored.imageSenderKeyBySession,
          equals({'195cb2fb': 'fe8b30ee05fc'}),
        );
        expect(restored.imageEnvelopeBySession.keys, equals({'195cb2fb'}));
        expect(
          restored.imageEnvelopeBySession['195cb2fb']?.sessionId,
          equals('195cb2fb'),
        );
      },
    );

    test('keeps latest envelope when a session appears multiple times', () {
      final first = ImageEnvelope(
        sessionId: '195cb2fb',
        format: ImageFormat.avif,
        total: 7,
        width: 100,
        height: 100,
        sizeBytes: 900,
      );
      final second = ImageEnvelope(
        sessionId: '195cb2fb',
        format: ImageFormat.jpeg,
        total: 8,
        width: 118,
        height: 256,
        sizeBytes: 1069,
      );

      final restored = restoreSessionMetadataFromMessages([
        Message(
          id: 'first',
          messageType: MessageType.channel,
          channelIdx: 0,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: 1,
          text: first.encode(),
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
          deliveryStatus: MessageDeliveryStatus.sent,
        ),
        Message(
          id: 'second',
          messageType: MessageType.channel,
          channelIdx: 0,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: 2,
          text: second.encode(),
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: Uint8List.fromList(
            [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff],
          ),
          deliveryStatus: MessageDeliveryStatus.sent,
        ),
      ]);

      expect(restored.imageEnvelopeBySession.length, equals(1));
      expect(
        restored.imageSenderKeyBySession['195cb2fb'],
        equals('aabbccddeeff'),
      );
      expect(
        restored.imageEnvelopeBySession['195cb2fb']?.format,
        equals(ImageFormat.jpeg),
      );
    });
  });
}
