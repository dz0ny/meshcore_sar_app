import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/models/message_reception_details.dart';
import 'package:meshcore_sar_app/models/path_selection.dart';
import 'package:meshcore_sar_app/providers/helpers/message_retry_manager.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/services/message_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contact _buildContact({
  int outPathLen = 1,
  List<int> outPath = const [1, 2, 3, 4],
}) {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: outPathLen,
    outPath: Uint8List.fromList(outPath),
    advName: 'Teammate',
    lastAdvert: 1700000000,
    advLat: 0,
    advLon: 0,
    lastMod: 1700000000,
  );
}

Message _buildDirectMessage(String id) {
  return Message(
    id: id,
    messageType: MessageType.contact,
    senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
    pathLen: 0,
    textType: MessageTextType.plain,
    senderTimestamp: 1700000000,
    text: 'hello',
    receivedAt: DateTime.now(),
    deliveryStatus: MessageDeliveryStatus.sending,
    recipientPublicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
  );
}

Message _buildSentChannelMessage({
  required String id,
  required int senderTimestamp,
  String text = 'broadcast',
  int channelIdx = 0,
}) {
  return Message(
    id: id,
    messageType: MessageType.channel,
    senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
    channelIdx: channelIdx,
    pathLen: 0,
    textType: MessageTextType.plain,
    senderTimestamp: senderTimestamp,
    text: text,
    receivedAt: DateTime.now(),
    deliveryStatus: MessageDeliveryStatus.sending,
  );
}

Message _buildReceivedChannelReplay({
  required String id,
  required int senderTimestamp,
  String text = 'broadcast',
  int channelIdx = 0,
  String senderName = 'Radio Alpha',
}) {
  return Message(
    id: id,
    messageType: MessageType.channel,
    channelIdx: channelIdx,
    pathLen: 1,
    textType: MessageTextType.plain,
    senderTimestamp: senderTimestamp,
    text: text,
    senderName: senderName,
    receivedAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MessagesProvider retransmission', () {
    test('direct messages become sent before delivery ACK arrives', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage('m1'),
        contact: _buildContact(),
      );

      provider.markMessageSent('m1', 77, 250);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sent,
      );
      expect(provider.messages.single.expectedAckTag, 77);

      provider.markMessageDelivered(77, 180);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.delivered,
      );
      expect(provider.messages.single.roundTripTimeMs, 180);
    });

    test(
      'direct messages stay sent after device accept until confirm arrives',
      () {
        final provider = MessagesProvider();
        provider.addSentMessage(
          _buildDirectMessage('m1b'),
          contact: _buildContact(),
        );

        provider.markMessageSent('m1b', 78, 250);

        expect(
          provider.messages.single.deliveryStatus,
          MessageDeliveryStatus.sent,
        );
        expect(provider.messages.single.expectedAckTag, 78);
        expect(provider.messages.single.roundTripTimeMs, isNull);
        expect(provider.messages.single.deliveredAt, isNull);
      },
    );

    test('fallback sent state can later upgrade to ACK-tracked delivery', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage('m1c'),
        contact: _buildContact(),
      );

      provider.markMessageSent('m1c', 0, 0);
      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sent,
      );
      expect(provider.messages.single.expectedAckTag, isNull);

      provider.markMessageSent('m1c', 79, 250);
      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sent,
      );
      expect(provider.messages.single.expectedAckTag, 79);

      provider.markMessageDelivered(79, 190);
      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.delivered,
      );
      expect(provider.messages.single.roundTripTimeMs, 190);
    });

    test('delivered flood message upgrades to learned direct route from ACK path', () {
      final provider = MessagesProvider();
      final contactWithoutRoute = _buildContact(outPathLen: -1, outPath: []);
      provider.addSentMessage(
        _buildDirectMessage('m1d'),
        contact: contactWithoutRoute,
      );
      provider.updateMessageRouteSelection(
        'm1d',
        PathSelection.flood(),
        routerFallbackAttempted: false,
      );

      provider.markMessageSent('m1d', 80, 250);
      provider.markMessageDelivered(80, 200);
      provider.queueDeliveredMessageRouteRefresh('m1d', contactWithoutRoute);

      final applied = provider.applyDeliveredMessageRouteFromContact(
        _buildContact(outPathLen: 2, outPath: const [0xAA, 0xBB]),
      );

      expect(applied, isTrue);
      expect(provider.messages.single.deliveryStatus, MessageDeliveryStatus.delivered);
      expect(provider.messages.single.usedFloodFallback, isFalse);
      expect(provider.messages.single.pathLen, 2);
      expect(
        provider.getMessageRouteMetadata('m1d')?.mode,
        PathSelectionMode.directCurrent,
      );
      expect(
        provider.getMessageRouteMetadata('m1d')?.canonicalPath,
        'AA,BB',
      );
      expect(provider.getMessageRouteMetadata('m1d')?.hopCount, 2);
    });

    test('channel messages are marked sent immediately', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'c1', senderTimestamp: 1700000000),
      );

      provider.markMessageSent('c1', 0, 0);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sent,
      );
    });

    test('channel warning appears when no echo arrives in time', () {
      fakeAsync((async) {
        final provider = MessagesProvider();
        provider.addSentMessage(
          _buildSentChannelMessage(id: 'c-warn', senderTimestamp: 1700000000),
        );

        provider.markMessageSent('c-warn', 0, 0);
        expect(provider.hasChannelSendWarning('c-warn'), isFalse);

        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();

        expect(provider.hasChannelSendWarning('c-warn'), isTrue);
      });
    });

    test('channel warning clears when echo arrives before timeout', () {
      fakeAsync((async) {
        final provider = MessagesProvider();
        provider.addSentMessage(
          _buildSentChannelMessage(
            id: 'c-warn-echo',
            senderTimestamp: 1700000000,
          ),
        );

        provider.markMessageSent('c-warn-echo', 0, 0);
        async.elapse(const Duration(seconds: 6));
        provider.handleMessageEcho('c-warn-echo', 1, 4, -90);
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();

        expect(provider.hasChannelSendWarning('c-warn-echo'), isFalse);
      });
    });

    test('repeated echo callbacks accumulate when radio reports one each time', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildSentChannelMessage(
          id: 'c-echo-callbacks',
          senderTimestamp: 1700000002,
        ),
      );
      provider.markMessageSent('c-echo-callbacks', 0, 0);

      provider.handleMessageEcho(
        'c-echo-callbacks',
        1,
        4,
        -90,
        pathBytes: Uint8List.fromList([0xAA]),
      );
      provider.handleMessageEcho(
        'c-echo-callbacks',
        1,
        5,
        -89,
        pathBytes: Uint8List.fromList([0xAA, 0xBB]),
      );
      provider.handleMessageEcho(
        'c-echo-callbacks',
        1,
        6,
        -88,
        pathBytes: Uint8List.fromList([0xAA, 0xBB, 0xCC]),
      );

      expect(provider.messages.single.echoCount, equals(3));
      expect(provider.messages.single.lastEchoSnrRaw, equals(6));
      expect(provider.messages.single.lastEchoRssiDbm, equals(-88));
      expect(
        provider.getMessageReceptionDetails('c-echo-callbacks')?.pathBytes,
        [0xAA, 0xBB, 0xCC],
      );
    });

    test('channel warning clears when replay arrives after send', () {
      fakeAsync((async) {
        final provider = MessagesProvider();
        provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
        provider.addSentMessage(
          _buildSentChannelMessage(
            id: 'c-warn-replay',
            senderTimestamp: 1700000100,
          ),
        );

        provider.markMessageSent('c-warn-replay', 0, 0);
        async.elapse(const Duration(seconds: 12));
        async.flushMicrotasks();
        expect(provider.hasChannelSendWarning('c-warn-replay'), isTrue);

        provider.addMessage(
          _buildReceivedChannelReplay(
            id: 'c-warn-replay-incoming',
            senderTimestamp: 1700000101,
            senderName: 'dz0ny (SI)',
          ),
        );

        expect(provider.hasChannelSendWarning('c-warn-replay'), isFalse);
        expect(provider.messages, hasLength(1));
        expect(provider.messages.single.id, equals('c-warn-replay'));
      });
    });

    test('channel replay merges into sent message for self sender within repeat window', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'c-echo', senderTimestamp: 1700000100),
      );
      provider.markMessageSent('c-echo', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-echo-incoming',
          senderTimestamp: 1700000104,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('c-echo'));
      expect(provider.messages.single.echoCount, equals(1));
      expect(provider.messages.single.pathLen, equals(1));
    });

    test('channel replay count reflects how many times a sent message was heard', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(
          id: 'c-repeat-count',
          senderTimestamp: 1700000110,
        ),
      );
      provider.markMessageSent('c-repeat-count', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-repeat-count-1',
          senderTimestamp: 1700000111,
          senderName: 'dz0ny (SI)',
        ),
      );
      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-repeat-count-2',
          senderTimestamp: 1700000112,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.echoCount, equals(2));
      expect(provider.getMessageReceptionDetails('c-repeat-count')?.receivedCopies, equals(3));
    });

    test('channel replay keeps flood mode hop count untouched', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(
          id: 'c-flood-path',
          senderTimestamp: 1700000120,
        ),
      );
      provider.updateMessageRouteSelection(
        'c-flood-path',
        PathSelection.flood(),
        routerFallbackAttempted: false,
      );
      provider.markMessageSent('c-flood-path', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-flood-path-incoming',
          senderTimestamp: 1700000121,
          senderName: 'dz0ny (SI)',
        ).copyWith(pathBytes: Uint8List.fromList([0xAA, 0xBB])),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.echoCount, equals(1));
      expect(provider.messages.single.pathLen, equals(0));
      expect(provider.messages.single.pathBytes, isEmpty);
      expect(
        provider.getMessageRouteMetadata('c-flood-path')?.mode,
        PathSelectionMode.flood,
      );
    });

    test('channel replay preserves sent direct path bytes', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(
          id: 'c-direct-path',
          senderTimestamp: 1700000130,
        ),
      );
      provider.updateMessageRouteSelection(
        'c-direct-path',
        PathSelection(
          mode: PathSelectionMode.directCurrent,
          pathBytes: Uint8List.fromList([0x01, 0x02]),
          hopCount: 2,
          hashSize: 1,
        ),
        routerFallbackAttempted: false,
      );
      provider.markMessageSent('c-direct-path', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-direct-path-incoming',
          senderTimestamp: 1700000131,
          senderName: 'dz0ny (SI)',
        ).copyWith(pathBytes: Uint8List.fromList([0xAA, 0xBB])),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.echoCount, equals(1));
      expect(provider.messages.single.pathLen, equals(2));
      expect(provider.messages.single.pathBytes, [0x01, 0x02]);
    });

    test(
      'channel replay is not deduped for different sender with same text',
      () {
        final provider = MessagesProvider();
        provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
        provider.addSentMessage(
          _buildSentChannelMessage(
            id: 'c-no-echo',
            senderTimestamp: 1700000200,
          ),
        );
        provider.markMessageSent('c-no-echo', 0, 0);

        provider.addMessage(
          _buildReceivedChannelReplay(
            id: 'c-no-echo-incoming',
            senderTimestamp: 1700000201,
            senderName: 'Radio Alpha',
          ),
        );

        expect(provider.messages, hasLength(2));
      },
    );

    test('channel replay is not deduped outside repeat window', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'c-late', senderTimestamp: 1700000300),
      );
      provider.markMessageSent('c-late', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-late-incoming',
          senderTimestamp: 1700000331,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(2));
    });

    test('channel replay merges using lazily resolved self name', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'c-lazy', senderTimestamp: 1700000400),
      );
      provider.markMessageSent('c-lazy', 0, 0);
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-lazy-incoming',
          senderTimestamp: 1700000406,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('c-lazy'));
    });

    test('channel replay merges for meshcore-prefixed self sender name', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'MeshCore-dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'c-prefix', senderTimestamp: 1700000500),
      );
      provider.markMessageSent('c-prefix', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'c-prefix-incoming',
          senderTimestamp: 1700000500,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('c-prefix'));
    });

    test('duplicate incoming message increments received copy count', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([7, 7, 4, 1, 7, 2]);

      provider.addMessage(
        Message(
          id: 'copy-1',
          messageType: MessageType.contact,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000600,
          text: 'same payload',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
        receptionDetailsSnapshot: MessageReceptionDetails(
          capturedAt: DateTime.now(),
        ),
      );
      provider.addMessage(
        Message(
          id: 'copy-2',
          messageType: MessageType.contact,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000601,
          text: 'same payload',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
        receptionDetailsSnapshot: MessageReceptionDetails(
          capturedAt: DateTime.now(),
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(
        provider.getMessageReceptionDetails('copy-1')?.receivedCopies,
        equals(2),
      );
    });

    test('incoming contact messages dedupe by sender handle and text', () {
      final provider = MessagesProvider();

      provider.addMessage(
        Message(
          id: 'handle-1',
          messageType: MessageType.contact,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000800,
          text: 'same payload',
          senderName: 'Radio Alpha',
          receivedAt: DateTime.now(),
        ),
      );
      provider.addMessage(
        Message(
          id: 'handle-2',
          messageType: MessageType.contact,
          pathLen: 2,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000810,
          text: 'same payload',
          senderName: 'Radio Alpha',
          receivedAt: DateTime.now(),
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('handle-1'));
    });

    test('channel duplicates dedupe across recent interleaved channel traffic', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([9, 8, 7, 6, 5, 4]);

      provider.addMessage(
        Message(
          id: 'channel-first',
          messageType: MessageType.channel,
          channelIdx: 2,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000820,
          text: 'same payload',
          senderName: 'Radio Alpha',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
      );
      provider.addMessage(
        Message(
          id: 'channel-middle',
          messageType: MessageType.channel,
          channelIdx: 2,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000825,
          text: 'different payload',
          senderName: 'Radio Bravo',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        ),
      );
      provider.addMessage(
        Message(
          id: 'channel-repeat',
          messageType: MessageType.channel,
          channelIdx: 2,
          pathLen: 2,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000830,
          text: 'same payload',
          senderName: 'Radio Alpha',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
      );

      expect(provider.messages, hasLength(2));
      expect(provider.messages.first.id, equals('channel-first'));
      expect(provider.messages.last.id, equals('channel-middle'));
    });

    test('adjacent channel duplicates still dedupe within 5 seconds', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([4, 5, 6, 7, 8, 9]);
      final baseTime = DateTime.fromMillisecondsSinceEpoch(1700000840000);

      provider.addMessage(
        Message(
          id: 'adjacent-1',
          messageType: MessageType.channel,
          channelIdx: 3,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000840,
          text: 'same payload',
          senderName: 'Radio Charlie',
          receivedAt: baseTime,
          senderPublicKeyPrefix: sender,
        ),
      );
      provider.addMessage(
        Message(
          id: 'adjacent-2',
          messageType: MessageType.channel,
          channelIdx: 3,
          pathLen: 2,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000845,
          text: 'same payload',
          senderName: 'Radio Charlie',
          receivedAt: baseTime.add(const Duration(seconds: 4)),
          senderPublicKeyPrefix: sender,
        ),
      );

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('adjacent-1'));
    });

    test('channel duplicates still dedupe when traffic lands between them', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([4, 5, 6, 7, 8, 9]);
      final baseTime = DateTime.fromMillisecondsSinceEpoch(1700000840000);

      provider.addMessage(
        Message(
          id: 'interleaved-1',
          messageType: MessageType.channel,
          channelIdx: 3,
          pathLen: 4,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000840,
          text: 'Tudi vsm',
          senderName: 'Tady (SI)',
          receivedAt: baseTime,
          senderPublicKeyPrefix: sender,
        ),
      );
      provider.addMessage(
        Message(
          id: 'interleaved-other',
          messageType: MessageType.channel,
          channelIdx: 3,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000841,
          text: 'Different payload',
          senderName: 'MHQ-1 [SI]',
          receivedAt: baseTime.add(const Duration(seconds: 1)),
          senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        ),
      );
      provider.addMessage(
        Message(
          id: 'interleaved-2',
          messageType: MessageType.channel,
          channelIdx: 3,
          pathLen: 4,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000842,
          text: 'Tudi vsm',
          senderName: 'Tady (SI)',
          receivedAt: baseTime.add(const Duration(seconds: 2)),
          senderPublicKeyPrefix: sender,
        ),
      );

      expect(provider.messages, hasLength(2));
      expect(provider.messages.first.id, equals('interleaved-1'));
      expect(
        provider.getMessageReceptionDetails('interleaved-1')?.receivedCopies,
        equals(2),
      );
    });

    test('channel duplicates outside 5 second window are kept', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([6, 7, 8, 9, 0, 1]);
      final baseTime = DateTime.fromMillisecondsSinceEpoch(1700000850000);

      provider.addMessage(
        Message(
          id: 'window-1',
          messageType: MessageType.channel,
          channelIdx: 4,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000850,
          text: 'same payload',
          senderName: 'Radio Delta',
          receivedAt: baseTime,
          senderPublicKeyPrefix: sender,
        ),
      );
      provider.addMessage(
        Message(
          id: 'window-2',
          messageType: MessageType.channel,
          channelIdx: 4,
          pathLen: 2,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000855,
          text: 'same payload',
          senderName: 'Radio Delta',
          receivedAt: baseTime.add(const Duration(seconds: 6)),
          senderPublicKeyPrefix: sender,
        ),
      );

      expect(provider.messages, hasLength(2));
      expect(provider.messages.last.id, equals('window-2'));
    });

    test('display list collapses stored duplicates and sums copy counts', () {
      final provider = MessagesProvider();
      final sender = Uint8List.fromList([5, 4, 3, 2, 1, 0]);

      provider.addMessages([
        Message(
          id: 'dup-a',
          messageType: MessageType.channel,
          channelIdx: 0,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000705,
          text: 'same payload',
          senderName: 'Klemen',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
        Message(
          id: 'dup-b',
          messageType: MessageType.channel,
          channelIdx: 0,
          pathLen: 2,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000700,
          text: 'same payload',
          senderName: 'Klemen',
          receivedAt: DateTime.now(),
          senderPublicKeyPrefix: sender,
        ),
      ]);

      final display = provider.buildDisplayMessages(
        provider.getRecentMessages(),
      );

      expect(display, hasLength(1));
      expect(display.single.message.id, equals('dup-a'));
      expect(display.single.occurrenceCount, equals(2));
    });

    test('display list keeps a single sent message for self replay', () {
      final provider = MessagesProvider();
      provider.resolveContactNameCallback = (_) => 'dz0ny (SI)';
      provider.addSentMessage(
        _buildSentChannelMessage(id: 'display-sent', senderTimestamp: 1700000900),
      );
      provider.markMessageSent('display-sent', 0, 0);

      provider.addMessage(
        _buildReceivedChannelReplay(
          id: 'display-received',
          senderTimestamp: 1700000901,
          senderName: 'dz0ny (SI)',
        ),
      );

      final display = provider.buildDisplayMessages(
        provider.getRecentMessages(),
      );

      expect(display, hasLength(1));
      expect(display.single.message.id, equals('display-sent'));
    });

    test('initialize collapses persisted duplicates from storage', () async {
      final storage = MessageStorageService();
      final sender = Uint8List.fromList([5, 5, 5, 5, 5, 5]);
      final firstReceivedAt = DateTime.fromMillisecondsSinceEpoch(1700001000000);

      await storage.saveMessages(
        [
          Message(
            id: 'persist-a',
            messageType: MessageType.channel,
            channelIdx: 3,
            pathLen: 4,
            textType: MessageTextType.plain,
            senderTimestamp: 1700001000,
            text: 'Tudi vsm',
            senderName: 'Tady (SI)',
            receivedAt: firstReceivedAt,
            senderPublicKeyPrefix: sender,
          ),
          Message(
            id: 'persist-b',
            messageType: MessageType.channel,
            channelIdx: 3,
            pathLen: 4,
            textType: MessageTextType.plain,
            senderTimestamp: 1700001001,
            text: 'Tudi vsm',
            senderName: 'Tady (SI)',
            receivedAt: firstReceivedAt.add(const Duration(seconds: 2)),
            senderPublicKeyPrefix: sender,
          ),
        ],
        messageReceptionDetails: {
          'persist-a': MessageReceptionDetails(capturedAt: firstReceivedAt),
          'persist-b': MessageReceptionDetails(
            capturedAt: firstReceivedAt.add(const Duration(seconds: 2)),
          ),
        },
      );

      final provider = MessagesProvider();
      await provider.initialize();

      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, equals('persist-a'));
      expect(
        provider.getMessageReceptionDetails('persist-a')?.receivedCopies,
        equals(2),
      );
    });

    test('missing ACK schedules a delayed retransmission', () {
      fakeAsync((async) {
        final provider = MessagesProvider();
        var retryCalls = 0;
        provider.sendMessageCallback =
            ({
              required contactPublicKey,
              required text,
              required messageId,
              required contact,
              retryAttempt = 0,
            }) async {
              retryCalls += 1;
              return true;
            };

        provider.addSentMessage(
          _buildDirectMessage('m2'),
          contact: _buildContact(),
        );
        provider.markMessageSent('m2', 88, 10);

        async.elapse(const Duration(milliseconds: 11));
        async.flushMicrotasks();

        expect(provider.messages.single.retryAttempt, 1);
        expect(
          provider.messages.single.deliveryStatus,
          MessageDeliveryStatus.sending,
        );
        expect(retryCalls, 0);

        async.elapse(const Duration(milliseconds: 998));
        async.flushMicrotasks();
        expect(retryCalls, 0);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

        expect(retryCalls, 1);
      });
    });

    test('uses calculated timeout when radio timeout is missing', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage('m3'),
        contact: _buildContact(),
      );

      provider.markMessageSent('m3', 99, 0);

      expect(provider.messages.single.suggestedTimeoutMs, isNotNull);
      expect(
        provider.messages.single.suggestedTimeoutMs!,
        greaterThanOrEqualTo(4000),
      );
    });

    test('older retry ack still marks message delivered', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage('m4'),
        contact: _buildContact(),
      );

      provider.markMessageSent('m4', 111, 10);
      provider.markMessageSent('m4', 112, 10);
      provider.markMessageDelivered(111, 220);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.delivered,
      );
      expect(provider.messages.single.roundTripTimeMs, 220);
    });

    test('manual retry reuses the same message record', () {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage('m4b'),
        contact: _buildContact(),
      );

      provider.markMessageSent('m4b', 113, 10);
      provider.markMessageDelivered(113, 220);

      final prepared = provider.prepareMessageForRetry('m4b');

      expect(prepared, isTrue);
      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.id, 'm4b');
      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sending,
      );
      expect(provider.messages.single.expectedAckTag, isNull);
      expect(provider.messages.single.roundTripTimeMs, isNull);
      expect(provider.messages.single.deliveredAt, isNull);
      expect(provider.messages.single.retryAttempt, 0);
    });

    test(
      'final router fallback runs after all normal retries are exhausted',
      () async {
        final provider = MessagesProvider();
        final fallbackCalls = <String>[];
        provider.onFinalRouterFallbackCallback =
            ({required messageId, required contact, required message}) async {
              fallbackCalls.add(messageId);
              return true;
            };

        provider.addSentMessage(
          _buildDirectMessage(
            'm5',
          ).copyWith(retryAttempt: MessageRetryManager.maxRetryAttempts),
          contact: _buildContact(),
        );

        provider.markMessageFailed('m5');
        await Future<void>.delayed(Duration.zero);

        expect(fallbackCalls, ['m5']);
        expect(
          provider.messages.single.deliveryStatus,
          MessageDeliveryStatus.sending,
        );
      },
    );

    test('final router fallback is not retried twice', () async {
      final provider = MessagesProvider();
      provider.addSentMessage(
        _buildDirectMessage(
          'm6',
        ).copyWith(retryAttempt: MessageRetryManager.maxRetryAttempts),
        contact: _buildContact(),
      );
      provider.updateMessageRouteSelection(
        'm6',
        PathSelection.flood(),
        routerFallbackAttempted: true,
      );

      provider.markMessageFailed('m6');
      await Future<void>.delayed(Duration.zero);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.failed,
      );
    });

    test(
      'final permanent failure callback runs after router fallback failure',
      () async {
        final provider = MessagesProvider();
        final failedMessageIds = <String>[];
        provider.onFinalDirectMessageFailureCallback =
            ({required messageId, required contact, required message}) async {
              failedMessageIds.add(messageId);
            };

        provider.addSentMessage(
          _buildDirectMessage(
            'm7',
          ).copyWith(retryAttempt: MessageRetryManager.maxRetryAttempts),
          contact: _buildContact(),
        );
        provider.updateMessageRouteSelection(
          'm7',
          PathSelection.flood(),
          routerFallbackAttempted: true,
        );

        provider.markMessageFailed('m7');
        await Future<void>.delayed(Duration.zero);

        expect(failedMessageIds, ['m7']);
        expect(
          provider.messages.single.deliveryStatus,
          MessageDeliveryStatus.failed,
        );
      },
    );
  });
}
