import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/app_provider.dart';

Uint8List _ownPublicKey() =>
    Uint8List.fromList([1, 2, 3, 4, 5, 6, ...List<int>.filled(26, 0)]);

void main() {
  group('AppProvider channel info handling', () {
    test('treats zeroed unnamed non-public channel as deleted', () {
      expect(AppProvider.isDeletedChannelInfo(2, '', Uint8List(16)), isTrue);
    });

    test('keeps unnamed non-public channel when secret is configured', () {
      final secret = Uint8List.fromList([1, ...List<int>.filled(15, 0)]);

      expect(AppProvider.isDeletedChannelInfo(2, '', secret), isFalse);
      expect(AppProvider.channelContactName(2, ''), 'Channel 2');
    });
  });

  group('AppProvider self replay handling', () {
    test('ignores direct self replay without hops', () {
      final message = Message(
        id: 'dm-self',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'hello',
        receivedAt: DateTime.now(),
      );

      expect(
        AppProvider.shouldIgnoreSelfReplay(
          message: message,
          ownPublicKey: _ownPublicKey(),
          ownName: 'dz0ny (SI)',
        ),
        isTrue,
      );
    });

    test('ignores room self replay without hops', () {
      final message = Message(
        id: 'room-self',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        recipientPublicKey: Uint8List.fromList([9, 9, 9, 9, 9, 9]),
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'hello room',
        receivedAt: DateTime.now(),
      );

      expect(
        AppProvider.shouldIgnoreSelfReplay(
          message: message,
          ownPublicKey: _ownPublicKey(),
          ownName: 'dz0ny (SI)',
        ),
        isTrue,
      );
    });

    test('keeps direct self replay when it traversed hops', () {
      final message = Message(
        id: 'dm-self-routed',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'hello',
        receivedAt: DateTime.now(),
      );

      expect(
        AppProvider.shouldIgnoreSelfReplay(
          message: message,
          ownPublicKey: _ownPublicKey(),
          ownName: 'dz0ny (SI)',
        ),
        isFalse,
      );
    });

    test('ignores channel self replay by self name without hops', () {
      final message = Message(
        id: 'channel-self',
        messageType: MessageType.channel,
        senderName: 'dz0ny (SI)',
        channelIdx: 0,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'hello public',
        receivedAt: DateTime.now(),
      );

      expect(
        AppProvider.shouldIgnoreSelfReplay(
          message: message,
          ownPublicKey: _ownPublicKey(),
          ownName: 'dz0ny (SI)',
        ),
        isTrue,
      );
    });

    test('keeps channel self replay when it traversed hops', () {
      final message = Message(
        id: 'channel-self-routed',
        messageType: MessageType.channel,
        senderName: 'dz0ny (SI)',
        channelIdx: 0,
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000000,
        text: 'hello public',
        receivedAt: DateTime.now(),
      );

      expect(
        AppProvider.shouldIgnoreSelfReplay(
          message: message,
          ownPublicKey: _ownPublicKey(),
          ownName: 'dz0ny (SI)',
        ),
        isFalse,
      );
    });
  });
}
