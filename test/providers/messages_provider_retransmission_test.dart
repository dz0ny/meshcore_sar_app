import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      provider.addSentMessage(
        Message(
          id: 'c1',
          messageType: MessageType.channel,
          senderPublicKeyPrefix: Uint8List.fromList([0, 1, 2, 3, 4, 5]),
          channelIdx: 0,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000000,
          text: 'broadcast',
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
        ),
      );

      provider.markMessageSent('c1', 0, 0);

      expect(
        provider.messages.single.deliveryStatus,
        MessageDeliveryStatus.sent,
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

        async.elapse(const Duration(seconds: 4));
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

    test('repeated max-retry failures request path reset', () async {
      final provider = MessagesProvider();
      final contact = _buildContact();
      final resetRequests = <(String, int)>[];
      provider.onDirectPathFailedCallback =
          ({required contact, required failureStreak}) async {
            resetRequests.add((contact.advName, failureStreak));
          };

      provider.addSentMessage(
        _buildDirectMessage(
          'm5',
        ).copyWith(retryAttempt: 3, usedFloodFallback: true),
        contact: contact,
      );
      provider.markMessageFailed('m5');

      provider.addSentMessage(
        _buildDirectMessage(
          'm6',
        ).copyWith(retryAttempt: 3, usedFloodFallback: true),
        contact: contact,
      );
      provider.markMessageFailed('m6');

      await Future<void>.delayed(Duration.zero);

      expect(resetRequests, [('Teammate', 2)]);
    });

    test('successful delivery clears path failure streak', () async {
      final provider = MessagesProvider();
      final contact = _buildContact();
      final resetRequests = <int>[];
      provider.onDirectPathFailedCallback =
          ({required contact, required failureStreak}) async {
            resetRequests.add(failureStreak);
          };

      provider.addSentMessage(
        _buildDirectMessage(
          'm7',
        ).copyWith(retryAttempt: 3, usedFloodFallback: true),
        contact: contact,
      );
      provider.markMessageFailed('m7');

      provider.addSentMessage(_buildDirectMessage('m8'), contact: contact);
      provider.markMessageSent('m8', 123, 10);
      provider.markMessageDelivered(123, 150);

      provider.addSentMessage(
        _buildDirectMessage(
          'm9',
        ).copyWith(retryAttempt: 3, usedFloodFallback: true),
        contact: contact,
      );
      provider.markMessageFailed('m9');

      await Future<void>.delayed(Duration.zero);

      expect(resetRequests, isEmpty);
    });
  });
}
