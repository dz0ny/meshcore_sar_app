import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/channel.dart';

void main() {
  test('hash channels expose deterministic psk_base64', () {
    final channel = Channel.create(index: 3, name: '#ops');

    expect(channel.isHashChannel, isTrue);
    expect(channel.pskBase64, 'O2RN43fDLHh5NgWiWqkVvw==');
    expect(
      Channel.pskBase64ForHashChannelName('#ops'),
      'O2RN43fDLHh5NgWiWqkVvw==',
    );
  });

  test('normal channels reject derived hashtag psk export helper', () {
    expect(
      () => Channel.pskBase64ForHashChannelName('ops'),
      throwsArgumentError,
    );
  });

  test('normal channels still expose their stored psk_base64', () {
    final channel = Channel.create(
      index: 4,
      name: 'ops',
      explicitSecret: Uint8List.fromList(List<int>.generate(16, (i) => i)),
    );

    expect(channel.isHashChannel, isFalse);
    expect(channel.pskBase64, 'AAECAwQFBgcICQoLDA0ODw==');
  });
}
