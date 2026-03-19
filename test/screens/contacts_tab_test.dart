import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/channel.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/contact_group.dart';
import 'package:meshcore_sar_app/models/device_info.dart' as device_info;
import 'package:meshcore_sar_app/providers/app_provider.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/drawing_provider.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart'
    as image_provider;
import 'package:meshcore_sar_app/providers/map_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/voice_provider.dart';
import 'package:meshcore_sar_app/screens/contacts_tab.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:meshcore_sar_app/services/voice_codec_service.dart';
import 'package:meshcore_sar_app/services/voice_player_service.dart';
import 'package:meshcore_sar_app/utils/contact_grouping.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectionProvider extends ConnectionProvider {
  _FakeConnectionProvider({required bool isConnected})
    : _isConnected = isConnected;

  final bool _isConnected;

  @override
  device_info.DeviceInfo get deviceInfo => device_info.DeviceInfo(
    connectionState: _isConnected
        ? device_info.ConnectionState.connected
        : device_info.ConnectionState.disconnected,
  );
}

class _FakeMessagesProvider extends MessagesProvider {
  @override
  bool get isInitialized => true;
}

class _FakeDrawingProvider extends DrawingProvider {
  @override
  bool get isInitialized => true;
}

void main() {
  String? clipboardText;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: 'default',
    );
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              clipboardText =
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return <String, dynamic>{'text': clipboardText};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Contact buildChannel({required String name, required int channelIndex}) {
    final publicKey = Uint8List(32);
    publicKey[0] = 0xFF;
    publicKey[1] = channelIndex;

    return Contact(
      publicKey: publicKey,
      type: ContactType.channel,
      flags: 0,
      outPathLen: -1,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Contact buildRepeater({required int seed, required String name}) {
    final publicKey = Uint8List(32);
    publicKey[0] = seed;
    publicKey[1] = seed + 1;

    return Contact(
      publicKey: publicKey,
      type: ContactType.repeater,
      flags: 0,
      outPathLen: -1,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 46056000 + seed,
      advLon: 14505000 + seed,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Contact buildSensor({required int seed, required String name}) {
    final publicKey = Uint8List(32);
    publicKey[0] = seed;
    publicKey[1] = seed + 1;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: -1,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 46056000 + seed,
      advLon: 14505000 + seed,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> pumpContactsTab(
    WidgetTester tester, {
    List<Contact> contacts = const [],
    List<SavedContactGroup> savedGroups = const [],
    ConnectionProvider? connectionProvider,
  }) async {
    final contactsProvider = ContactsProvider();
    final resolvedConnectionProvider =
        connectionProvider ?? ConnectionProvider();
    final messagesProvider = _FakeMessagesProvider();
    final drawingProvider = _FakeDrawingProvider();
    final channelsProvider = ChannelsProvider();
    final voiceProvider = VoiceProvider(
      codec: VoiceCodecService(),
      player: VoicePlayerService(),
    );
    final imageProvider = image_provider.ImageProvider();
    final appProvider = AppProvider(
      connectionProvider: resolvedConnectionProvider,
      contactsProvider: contactsProvider,
      messagesProvider: messagesProvider,
      drawingProvider: drawingProvider,
      channelsProvider: channelsProvider,
      voiceProvider: voiceProvider,
      imageProvider: imageProvider,
    );
    for (final contact in contacts) {
      contactsProvider.addOrUpdateContact(contact);
    }
    if (savedGroups.isNotEmpty) {
      await contactsProvider.replaceAutoGroupsForSection(
        'repeaters',
        savedGroups,
      );
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ContactsProvider>(
            create: (_) => contactsProvider,
          ),
          ChangeNotifierProvider<ConnectionProvider>(
            create: (_) => resolvedConnectionProvider,
          ),
          ChangeNotifierProvider<MessagesProvider>(
            create: (_) => messagesProvider,
          ),
          ChangeNotifierProvider(create: (_) => MapProvider()),
          ChangeNotifierProvider<AppProvider>(create: (_) => appProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ContactsTab()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('private channel activity card shows delete action in sheet', (
    tester,
  ) async {
    await pumpContactsTab(
      tester,
      contacts: [buildChannel(name: 'Ops', channelIndex: 3)],
    );

    expect(find.text('Ops'), findsOneWidget);
    await tester.tap(find.text('Ops'));
    await tester.pumpAndSettle();

    expect(find.text('Export psk_base64'), findsNothing);
    expect(find.text('Delete Channel'), findsOneWidget);

    await tester.tap(find.text('Delete Channel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Channel'), findsWidgets);
    expect(
      find.text(
        'Are you sure you want to delete channel "Ops"? This action cannot be undone.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hash channel activity card exports psk_base64', (tester) async {
    await pumpContactsTab(
      tester,
      contacts: [buildChannel(name: '#ops', channelIndex: 3)],
    );

    expect(find.text('#ops'), findsOneWidget);
    await tester.tap(find.text('#ops'));
    await tester.pumpAndSettle();

    expect(find.text('Export psk_base64'), findsOneWidget);

    await tester.tap(find.text('Export psk_base64'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(clipboardText, Channel.pskBase64ForHashChannelName('#ops'));
    expect(find.text('psk_base64 copied to clipboard'), findsOneWidget);
  });

  testWidgets('repeaters show Others group when multiple groups exist', (
    tester,
  ) async {
    final repeaters = [
      buildRepeater(seed: 10, name: 'AL-1'),
      buildRepeater(seed: 11, name: 'AL-2'),
      buildRepeater(seed: 12, name: 'AL-3'),
      buildRepeater(seed: 13, name: 'AL-4'),
      buildRepeater(seed: 20, name: 'BR-1'),
      buildRepeater(seed: 21, name: 'BR-2'),
      buildRepeater(seed: 22, name: 'BR-3'),
      buildRepeater(seed: 23, name: 'BR-4'),
      buildRepeater(seed: 30, name: 'Lone Relay'),
    ];
    final inferredGroups = ContactGrouping.inferGroups(repeaters);
    final savedGroups = inferredGroups
        .map(
          (group) => SavedContactGroup(
            id: 'repeaters_${group.key}',
            sectionKey: 'repeaters',
            label: group.label,
            query: group.label,
            createdAt: DateTime(2026, 3, 13, 10),
            matchPrefixes: group.matchPrefixes,
            isAutoGroup: true,
          ),
        )
        .toList();

    await pumpContactsTab(
      tester,
      contacts: repeaters,
      savedGroups: savedGroups,
    );

    expect(find.text('AL-'), findsOneWidget);
    expect(find.text('BR-'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget);
    expect(find.text('Lone Relay'), findsNothing);
  });

  testWidgets('repeaters stay flat when only one group exists', (tester) async {
    final repeaters = [
      buildRepeater(seed: 40, name: 'AL-1'),
      buildRepeater(seed: 41, name: 'AL-2'),
      buildRepeater(seed: 42, name: 'AL-3'),
      buildRepeater(seed: 43, name: 'AL-4'),
      buildRepeater(seed: 50, name: 'Lone Relay'),
    ];
    final inferredGroups = ContactGrouping.inferGroups(repeaters);
    final savedGroups = inferredGroups
        .map(
          (group) => SavedContactGroup(
            id: 'repeaters_${group.key}',
            sectionKey: 'repeaters',
            label: group.label,
            query: group.label,
            createdAt: DateTime(2026, 3, 13, 10),
            matchPrefixes: group.matchPrefixes,
            isAutoGroup: true,
          ),
        )
        .toList();

    await pumpContactsTab(
      tester,
      contacts: repeaters,
      savedGroups: savedGroups,
    );

    expect(find.text('AL-'), findsOneWidget);
    expect(find.text('Others'), findsNothing);
    expect(find.text('Lone Relay'), findsOneWidget);
  });

  testWidgets('sensor contacts render in their own section', (tester) async {
    await pumpContactsTab(
      tester,
      contacts: [buildSensor(seed: 60, name: 'WX Station')],
    );

    expect(find.text('Sensors'), findsWidgets);
    expect(find.text('WX Station'), findsOneWidget);
  });

  testWidgets(
    'contacts sections do not show sensor or repeater discovery actions',
    (tester) async {
      await pumpContactsTab(
        tester,
        contacts: [
          buildRepeater(seed: 70, name: 'Relay 1'),
          buildSensor(seed: 71, name: 'WX Station'),
        ],
        connectionProvider: _FakeConnectionProvider(isConnected: true),
      );

      expect(find.byTooltip('Discover repeaters'), findsNothing);
      expect(find.byTooltip('Discover sensors'), findsNothing);
      expect(find.byIcon(Icons.radar), findsNothing);
    },
  );
}
