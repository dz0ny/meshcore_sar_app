import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ImageProvider cancel receive', () {
    test('ignores incoming fragments after cancel until resumed', () {
      final provider = ImageProvider();
      const sessionId = '01020304';
      const envelope = ImageEnvelope(
        sessionId: sessionId,
        format: ImageFormat.avif,
        total: 2,
        width: 32,
        height: 32,
        sizeBytes: 4,
      );
      final fragment = ImagePacket(
        sessionId: sessionId,
        format: ImageFormat.avif,
        index: 0,
        total: 2,
        data: Uint8List.fromList([1, 2]),
      );

      provider.registerEnvelope(envelope);
      provider.cancelIncomingSession(sessionId);

      expect(provider.isReceiveCanceled(sessionId), isTrue);
      expect(provider.session(sessionId), isNull);

      provider.addFragment(fragment, width: 32, height: 32);

      expect(provider.session(sessionId), isNull);

      provider.resumeIncomingSession(sessionId);
      provider.registerEnvelope(envelope);
      provider.addFragment(fragment, width: 32, height: 32);

      expect(provider.isReceiveCanceled(sessionId), isFalse);
      expect(provider.session(sessionId)?.receivedCount, equals(1));
    });
  });
}
