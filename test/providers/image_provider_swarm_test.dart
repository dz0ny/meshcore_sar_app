import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contact _buildRequester() {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: 1,
    outPath: Uint8List.fromList([1, 2, 3, 4]),
    advName: 'Requester',
    lastAdvert: 1700000000,
    advLat: 0,
    advLon: 0,
    lastMod: 1700000000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageProvider swarm serving', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('serves requested fragments from received session cache', () async {
      final provider = ImageProvider();
      provider.registerEnvelope(
        const ImageEnvelope(
          sessionId: 'deadbeef',
          format: ImageFormat.avif,
          total: 3,
          width: 64,
          height: 64,
          sizeBytes: 300,
        ),
      );

      provider.addFragment(
        ImagePacket(
          sessionId: 'deadbeef',
          format: ImageFormat.avif,
          index: 0,
          total: 3,
          data: Uint8List.fromList([1, 2]),
        ),
        width: 64,
        height: 64,
      );
      provider.addFragment(
        ImagePacket(
          sessionId: 'deadbeef',
          format: ImageFormat.avif,
          index: 2,
          total: 3,
          data: Uint8List.fromList([7, 8]),
        ),
        width: 64,
        height: 64,
      );

      final sent = <Uint8List>[];
      provider.sendRawPacketCallback =
          ({
            required contactPath,
            required contactPathLen,
            required payload,
          }) async {
            sent.add(payload);
          };

      final ok = await provider.serveSessionTo(
        sessionId: 'deadbeef',
        requester: _buildRequester(),
        requestedIndices: {2},
      );

      expect(ok, isTrue);
      expect(provider.availableFragmentIndices('deadbeef'), [0, 2]);
      expect(sent, hasLength(1));
      expect(ImagePacket.tryParseBinary(sent.single)?.index, 2);
    });
  });
}
