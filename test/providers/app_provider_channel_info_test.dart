import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/models/device_info.dart';
import 'package:meshcore_sar_app/providers/app_provider.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/drawing_provider.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart' as ip;
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/voice_provider.dart';
import 'package:meshcore_sar_app/services/location_tracking_service.dart';
import 'package:meshcore_sar_app/services/voice_codec_service.dart';
import 'package:meshcore_sar_app/services/voice_player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _ownPublicKey() =>
    Uint8List.fromList([1, 2, 3, 4, 5, 6, ...List<int>.filled(26, 0)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final locationTrackingService = LocationTrackingService();
    locationTrackingService.fastLocationUpdatesEnabled = false;
    locationTrackingService.fastLocationChannelIdx = null;
    locationTrackingService.isTracking = false;
  });

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
    test('prefers self name over meshcore device name', () {
      expect(
        AppProvider.preferredSelfDisplayName(
          deviceName: 'MeshCore-dz0ny (SI)',
          selfName: 'dz0ny (SI)',
        ),
        'dz0ny (SI)',
      );
    });

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

  group('AppProvider channel location sharing state', () {
    test('clears app fallback sharing state when device disconnects', () async {
      final harness = _AppProviderHarness(
        connectionProvider: _FakeConnectionProvider(isConnected: true),
      );
      final locationTrackingService = harness.appProvider.locationTrackingService;

      await locationTrackingService.updateFastLocationChannelIdx(3);
      await locationTrackingService.setFastLocationUpdatesEnabled(true);

      harness.connectionProvider.setConnected(false);
      await Future<void>.delayed(Duration.zero);

      expect(locationTrackingService.fastLocationUpdatesEnabled, isFalse);
      expect(locationTrackingService.fastLocationChannelIdx, isNull);
      expect(harness.appProvider.channelLocationSharingModeForChannel(3), isNull);

      await harness.dispose();
    });

    test('preserves hardware sharing state when device disconnects', () async {
      final harness = _AppProviderHarness(
        connectionProvider: _FakeConnectionProvider(
          isConnected: true,
          customVars: const {'gps': '1', 'fast_gps_channel': '7'},
        ),
      );

      await harness.appProvider.refreshChannelLocationSharingState();

      expect(
        harness.appProvider.channelLocationSharingModeForChannel(7),
        ChannelLocationSharingMode.hardware,
      );

      harness.connectionProvider.setConnected(false);
      await Future<void>.delayed(Duration.zero);

      expect(
        harness.appProvider.channelLocationSharingModeForChannel(7),
        ChannelLocationSharingMode.hardware,
      );

      await harness.dispose();
    });

    test('clears app fallback sharing state when device connects', () async {
      final harness = _AppProviderHarness(
        connectionProvider: _FakeConnectionProvider(isConnected: false),
      );
      final locationTrackingService = harness.appProvider.locationTrackingService;

      await locationTrackingService.updateFastLocationChannelIdx(5);
      await locationTrackingService.setFastLocationUpdatesEnabled(true);

      harness.connectionProvider.setConnected(true);
      await Future<void>.delayed(Duration.zero);

      expect(locationTrackingService.fastLocationUpdatesEnabled, isFalse);
      expect(locationTrackingService.fastLocationChannelIdx, isNull);
      expect(harness.appProvider.channelLocationSharingModeForChannel(5), isNull);

      await harness.dispose();
    });
  });
}

class _AppProviderHarness {
  final _FakeConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final DrawingProvider drawingProvider;
  final ChannelsProvider channelsProvider;
  final VoiceProvider voiceProvider;
  final ip.ImageProvider imageProvider;
  late final AppProvider appProvider;

  _AppProviderHarness({required this.connectionProvider})
    : contactsProvider = ContactsProvider(),
      messagesProvider = MessagesProvider(),
      drawingProvider = DrawingProvider(),
      channelsProvider = ChannelsProvider(),
      voiceProvider = VoiceProvider(
        codec: VoiceCodecService(),
        player: _FakeVoicePlayerService(),
      ),
      imageProvider = ip.ImageProvider() {
    appProvider = AppProvider(
      connectionProvider: connectionProvider,
      contactsProvider: contactsProvider,
      messagesProvider: messagesProvider,
      drawingProvider: drawingProvider,
      channelsProvider: channelsProvider,
      voiceProvider: voiceProvider,
      imageProvider: imageProvider,
    );
  }

  Future<void> dispose() async {
    for (var i = 0; i < 10; i++) {
      if (appProvider.trafficStatsReportingService.isInitialized) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    appProvider.dispose();
    voiceProvider.dispose();
    imageProvider.dispose();
    drawingProvider.dispose();
    messagesProvider.dispose();
    contactsProvider.dispose();
    connectionProvider.dispose();
    channelsProvider.dispose();
  }
}

class _FakeConnectionProvider extends ConnectionProvider {
  DeviceInfo _deviceInfo;

  _FakeConnectionProvider({
    required bool isConnected,
    Map<String, String>? customVars,
  }) : _deviceInfo = DeviceInfo(
         connectionState: isConnected
             ? ConnectionState.connected
             : ConnectionState.disconnected,
       ),
       _customVars = customVars ?? <String, String>{};

  Map<String, String> _customVars;

  @override
  DeviceInfo get deviceInfo => _deviceInfo;

  void setConnected(bool isConnected) {
    _deviceInfo = _deviceInfo.copyWith(
      connectionState: isConnected
          ? ConnectionState.connected
          : ConnectionState.disconnected,
    );
    notifyListeners();
  }

  @override
  Future<Map<String, String>> getCustomVars() async =>
      Map<String, String>.from(_customVars);
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
