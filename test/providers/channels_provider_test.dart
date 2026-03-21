import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';

void main() {
  group('ChannelsProvider device sync preparation', () {
    test('clears runtime channel state before sync', () {
      final provider = ChannelsProvider();

      provider.addOrUpdateChannel(
        index: 2,
        name: 'Ops',
        secret: Uint8List.fromList(List<int>.filled(16, 7)),
      );
      provider.selectChannel(2);

      provider.prepareForDeviceSync();

      expect(provider.channels, isEmpty);
      expect(provider.selectedChannelIndex, 0);
      expect(provider.selectedChannel, isNull);
    });
  });
}
