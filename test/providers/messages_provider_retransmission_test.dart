import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/models/path_selection.dart';
import 'package:meshcore_sar_app/providers/helpers/message_retry_manager.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contact _buildContact() {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: 1,
    outPath: Uint8List.fromList([1, 2, 3, 4]),
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

    test('channel replay is deduped for self sender within repeat window', () {
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
      expect(provider.messages.single.senderName, equals('dz0ny (SI)'));
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
          senderTimestamp: 1700000306,
          senderName: 'dz0ny (SI)',
        ),
      );

      expect(provider.messages, hasLength(2));
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
