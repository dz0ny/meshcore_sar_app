import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart';
import 'package:meshcore_sar_app/providers/voice_provider.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:meshcore_sar_app/services/voice_codec_service.dart';
import 'package:meshcore_sar_app/services/voice_player_service.dart';
import 'package:meshcore_sar_app/utils/image_message_parser.dart';
import 'package:meshcore_sar_app/utils/voice_message_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
  });

  test('VoiceProvider reloads profile-scoped sessions', () async {
    final player = _FakeVoicePlayerService();
    final provider = VoiceProvider(codec: VoiceCodecService(), player: player);
    addTearDown(provider.dispose);

    await provider.reloadProfileScopedState();
    provider.registerEnvelope(
      const VoiceEnvelope(
        sessionId: 'a1b2c3d4',
        mode: VoicePacketMode.mode1200,
        total: 2,
        durationMs: 1600,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'beta',
    );
    await provider.reloadProfileScopedState();
    expect(provider.session('a1b2c3d4'), isNull);

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
    await provider.reloadProfileScopedState();
    expect(provider.session('a1b2c3d4'), isNotNull);
  });

  test('ImageProvider reloads profile-scoped sessions', () async {
    final provider = ImageProvider();

    await provider.reloadProfileScopedState();
    provider.registerEnvelope(
      const ImageEnvelope(
        sessionId: 'a1b2c3d4',
        format: ImageFormat.avif,
        total: 2,
        width: 32,
        height: 32,
        sizeBytes: 8,
      ),
    );
    provider.addFragment(
      ImagePacket(
        sessionId: 'a1b2c3d4',
        format: ImageFormat.avif,
        index: 0,
        total: 2,
        data: Uint8List.fromList([1, 2, 3, 4]),
      ),
      width: 32,
      height: 32,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'beta',
    );
    await provider.reloadProfileScopedState();
    expect(provider.session('a1b2c3d4'), isNull);

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
    await provider.reloadProfileScopedState();
    expect(provider.session('a1b2c3d4'), isNotNull);
  });
}

class _FakeVoicePlayerService implements VoicePlayerService {
  final StreamController<void> _events = StreamController<void>.broadcast();
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  Stream<void> get events => _events.stream;

  @override
  Future<void> play(Int16List pcmSamples, {required int sampleRateHz}) async {
    _isPlaying = true;
    _events.add(null);
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _events.add(null);
  }

  @override
  void dispose() {
    _events.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
