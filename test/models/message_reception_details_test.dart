import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message_reception_details.dart';

void main() {
  test('drops impossible transmit estimate for received messages', () {
    expect(
      sanitizeEstimatedTransmitMs(
        estimatedTransmitMs: 16 * 60 * 1000 + 54 * 1000,
        senderToReceiptMs: 4200,
      ),
      isNull,
    );
  });

  test(
    'keeps close transmit estimate despite second-level timestamp rounding',
    () {
      expect(
        sanitizeEstimatedTransmitMs(
          estimatedTransmitMs: 1800,
          senderToReceiptMs: 900,
        ),
        1800,
      );
    },
  );

  test('round trips reception details json', () {
    final details = MessageReceptionDetails(
      capturedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      packetLoggedAt: DateTime.fromMillisecondsSinceEpoch(1700000000500),
      rssiDbm: -92,
      snrDb: 7.5,
      pathBytes: const [0xAA, 0xBB, 0xCC],
      senderToReceiptMs: 4200,
      estimatedTransmitMs: 1800,
      postTransmitDelayMs: 2400,
    );

    final decoded = MessageReceptionDetails.fromJson(details.toJson());

    expect(decoded, isNotNull);
    expect(decoded!.rssiDbm, -92);
    expect(decoded.snrDb, 7.5);
    expect(decoded.pathBytesHex, 'aa:bb:cc');
    expect(decoded.senderToReceiptMs, 4200);
    expect(decoded.estimatedTransmitMs, 1800);
    expect(decoded.postTransmitDelayMs, 2400);
  });
}
