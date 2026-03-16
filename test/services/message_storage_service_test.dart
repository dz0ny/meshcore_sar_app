import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'package:meshcore_sar_app/models/message_reception_details.dart';
import 'package:meshcore_sar_app/services/message_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'retains path bytes for stored unread message when reception sidecar is missing',
    () async {
      final storage = MessageStorageService();
      final message = Message(
        id: 'msg-1',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        pathLen: 2,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'Unread message',
        receivedAt: DateTime.fromMillisecondsSinceEpoch(1700000000500),
        isRead: false,
      );

      await storage.saveMessages(
        [message],
        messageReceptionDetails: {
          message.id: MessageReceptionDetails(
            capturedAt: DateTime.fromMillisecondsSinceEpoch(1700000000600),
            pathBytes: const [0xAA, 0xBB, 0xCC],
          ),
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('stored_message_reception_details');

      final restoredDetails = await storage.loadMessageReceptionDetails();
      final restoredMessages = await storage.loadMessages();

      expect(restoredDetails.keys, contains(message.id));
      expect(restoredDetails[message.id]?.pathBytes, [0xAA, 0xBB, 0xCC]);
      expect(restoredMessages.single.pathBytes, [0xAA, 0xBB, 0xCC]);
    },
  );

  test('retains embedded reception details when sidecar is missing', () async {
    final storage = MessageStorageService();
    final message = Message(
      id: 'msg-2',
      messageType: MessageType.channel,
      senderPublicKeyPrefix: Uint8List.fromList([6, 5, 4, 3, 2, 1]),
      channelIdx: 2,
      pathLen: 3,
      textType: MessageTextType.plain,
      senderTimestamp: 1700000100,
      text: 'Room update',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(1700000100500),
      isRead: false,
    );

    await storage.saveMessages(
      [message],
      messageReceptionDetails: {
        message.id: MessageReceptionDetails(
          capturedAt: DateTime.fromMillisecondsSinceEpoch(1700000100600),
          packetLoggedAt: DateTime.fromMillisecondsSinceEpoch(1700000100400),
          rssiDbm: -91,
          snrDb: 7.25,
          pathBytes: const [0xAA, 0xBB, 0xCC, 0xDD],
          senderToReceiptMs: 1200,
          estimatedTransmitMs: 800,
          postTransmitDelayMs: 400,
          receivedCopies: 3,
        ),
      },
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stored_message_reception_details');

    final restoredDetails = await storage.loadMessageReceptionDetails();
    final restored = restoredDetails[message.id];

    expect(restored, isNotNull);
    expect(restored!.pathBytes, [0xAA, 0xBB, 0xCC, 0xDD]);
    expect(restored.rssiDbm, -91);
    expect(restored.snrDb, 7.25);
    expect(restored.senderToReceiptMs, 1200);
    expect(restored.estimatedTransmitMs, 800);
    expect(restored.postTransmitDelayMs, 400);
    expect(restored.receivedCopies, 3);
    expect(
      restored.packetLoggedAt,
      DateTime.fromMillisecondsSinceEpoch(1700000100400),
    );
  });

  test('persists removed SAR marker IDs', () async {
    final storage = MessageStorageService();

    await storage.saveRemovedSarMarkerIds({'sar-2', 'sar-1'});

    final restored = await storage.loadRemovedSarMarkerIds();

    expect(restored, equals({'sar-1', 'sar-2'}));
  });

  test('keeps default and custom profile message storage isolated', () async {
    final storage = MessageStorageService();
    final defaultMessage = Message(
      id: 'default-msg',
      messageType: MessageType.channel,
      senderPublicKeyPrefix: Uint8List.fromList([1, 1, 1, 1, 1, 1]),
      channelIdx: 0,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: 1700001000,
      text: 'Default profile',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(1700001000500),
      isRead: true,
    );
    final customMessage = Message(
      id: 'custom-msg',
      messageType: MessageType.channel,
      senderPublicKeyPrefix: Uint8List.fromList([2, 2, 2, 2, 2, 2]),
      channelIdx: 1,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: 1700002000,
      text: 'Custom profile',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(1700002000500),
      isRead: false,
    );

    await storage.saveMessages([defaultMessage]);
    await storage.saveMessages([customMessage], namespace: 'alpha');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('stored_messages'), isNotNull);
    expect(prefs.getString('profile.alpha.stored_messages'), isNotNull);

    final defaultMessages = await storage.loadMessages();
    final customMessages = await storage.loadMessages(namespace: 'alpha');

    expect(defaultMessages.single.id, defaultMessage.id);
    expect(defaultMessages.single.text, defaultMessage.text);
    expect(customMessages.single.id, customMessage.id);
    expect(customMessages.single.text, customMessage.text);
  });
}
