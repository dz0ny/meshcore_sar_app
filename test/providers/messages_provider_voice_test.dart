import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/models/message_contact_location.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessagesProvider voice detection', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('marks VE3 envelope messages as voice', () {
      final provider = MessagesProvider();
      final envelope = VoiceEnvelope(
        sessionId: 'deafbead',
        mode: VoicePacketMode.mode1200,
        total: 3,
        durationMs: 2400,
      );

      final message = Message(
        id: 'm1',
        messageType: MessageType.channel,
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: envelope.encodeText(),
        receivedAt: DateTime.now(),
        senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        deliveryStatus: MessageDeliveryStatus.sent,
      );

      provider.addMessage(message);
      final stored = provider.messages.single;
      expect(stored.isVoice, isTrue);
      expect(stored.voiceId, equals('deafbead'));
    });

    test('does not mark legacy V text packets as voice', () {
      final provider = MessagesProvider();
      final packet = VoicePacket(
        sessionId: '00112233',
        mode: VoicePacketMode.mode700c,
        index: 0,
        total: 1,
        codec2Data: Uint8List.fromList([1, 2, 3]),
      );
      final message = Message(
        id: 'm2',
        messageType: MessageType.channel,
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000001,
        text: packet.encodeText(),
        receivedAt: DateTime.now(),
        senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        deliveryStatus: MessageDeliveryStatus.sent,
      );

      provider.addMessage(message);
      final stored = provider.messages.single;
      expect(stored.isVoice, isFalse);
      expect(stored.voiceId, isNull);
    });

    test('persists received contact location snapshots', () async {
      final provider = MessagesProvider();
      final message = Message(
        id: 'm3',
        messageType: MessageType.contact,
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000002,
        text: 'status update',
        receivedAt: DateTime.now(),
        senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
      );

      provider.addMessage(
        message,
        contactLocationSnapshot: MessageContactLocation(
          location: const LatLng(46.0569, 14.5058),
          source: 'advert',
          capturedAt: DateTime.now(),
          sourceTimestamp: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final restoredProvider = MessagesProvider();
      await restoredProvider.initialize();
      final snapshot = restoredProvider.getMessageContactLocation('m3');

      expect(snapshot, isNotNull);
      expect(snapshot!.source, equals('advert'));
      expect(snapshot.location.latitude, closeTo(46.0569, 0.000001));
      expect(snapshot.location.longitude, closeTo(14.5058, 0.000001));
    });

    test('tracks and persists media transfer counts and downloaders', () async {
      final provider = MessagesProvider();
      final voiceEnvelope = VoiceEnvelope(
        sessionId: 'deafbead',
        mode: VoicePacketMode.mode1200,
        total: 3,
        durationMs: 2400,
      );
      const imageEnvelope = ImageEnvelope(
        sessionId: '01020304',
        format: ImageFormat.avif,
        total: 2,
        width: 64,
        height: 64,
        sizeBytes: 2048,
      );

      provider.addMessage(
        Message(
          id: 'voice1',
          messageType: MessageType.contact,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000010,
          text: voiceEnvelope.encodeText(),
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        ),
      );
      provider.addMessage(
        Message(
          id: 'image1',
          messageType: MessageType.contact,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000011,
          text: imageEnvelope.encode(),
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        ),
      );

      provider.recordMediaTransfer(
        sessionId: 'deafbead',
        mediaType: 'voice',
        requesterKey6: '112233445566',
        requesterName: 'Alice',
      );
      provider.recordMediaTransfer(
        sessionId: 'deafbead',
        mediaType: 'voice',
        requesterKey6: '112233445566',
        requesterName: 'Alice',
      );
      provider.recordMediaTransfer(
        sessionId: '01020304',
        mediaType: 'image',
        requesterKey6: 'a1b2c3d4e5f6',
        requesterName: 'Bob',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final voiceDetails = provider.getMessageTransferDetails('voice1');
      final imageDetails = provider.getMessageTransferDetails('image1');
      expect(voiceDetails, isNotNull);
      expect(voiceDetails!.totalTransfers, equals(2));
      expect(voiceDetails.downloaders.single.requesterName, equals('Alice'));
      expect(voiceDetails.downloaders.single.transferCount, equals(2));
      expect(provider.transferCountForSession(voiceSessionId: 'deafbead'), 2);
      expect(imageDetails?.totalTransfers, equals(1));
      expect(provider.transferCountForSession(imageSessionId: '01020304'), 1);

      final restoredProvider = MessagesProvider();
      await restoredProvider.initialize();
      final restoredVoice = restoredProvider.getMessageTransferDetails(
        'voice1',
      );
      final restoredImage = restoredProvider.getMessageTransferDetails(
        'image1',
      );
      expect(restoredVoice?.totalTransfers, equals(2));
      expect(restoredVoice?.downloaders.single.requesterKey6, '112233445566');
      expect(restoredImage?.downloaders.single.requesterName, equals('Bob'));
    });
  });
}
