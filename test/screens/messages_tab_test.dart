import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/providers/app_provider.dart';
import 'package:meshcore_sar_app/providers/channels_provider.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/drawing_provider.dart';
import 'package:meshcore_sar_app/providers/image_provider.dart' as ip;
import 'package:meshcore_sar_app/providers/map_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/voice_provider.dart';
import 'package:meshcore_sar_app/screens/messages_tab.dart';
import 'package:meshcore_sar_app/services/message_destination_preferences.dart';
import 'package:meshcore_sar_app/services/voice_codec_service.dart';
import 'package:meshcore_sar_app/services/voice_player_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Contact buildContact({
    required String name,
    required ContactType type,
    int secondByte = 1,
  }) {
    final publicKey = Uint8List(32);
    publicKey[0] = secondByte;
    publicKey[1] = secondByte;

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: 0,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('marks public channel as read after 5 seconds of viewing', (
    tester,
  ) async {
    final connectionProvider = ConnectionProvider();
    final contactsProvider = ContactsProvider();
    final messagesProvider = MessagesProvider();
    final mapProvider = MapProvider();
    final drawingProvider = DrawingProvider();
    final channelsProvider = ChannelsProvider()..initializePublicChannel();
    final voiceProvider = VoiceProvider(
      codec: VoiceCodecService(),
      player: VoicePlayerService(),
    );
    final imageProvider = ip.ImageProvider();
    final appProvider = AppProvider(
      connectionProvider: connectionProvider,
      contactsProvider: contactsProvider,
      messagesProvider: messagesProvider,
      drawingProvider: drawingProvider,
      channelsProvider: channelsProvider,
      voiceProvider: voiceProvider,
      imageProvider: imageProvider,
    );

    messagesProvider.addMessage(
      Message(
        id: 'public-unread',
        messageType: MessageType.channel,
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: 1700000100,
        text: 'Unread on public channel',
        receivedAt: DateTime.now(),
        channelIdx: 0,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connectionProvider),
          ChangeNotifierProvider.value(value: contactsProvider),
          ChangeNotifierProvider.value(value: messagesProvider),
          ChangeNotifierProvider.value(value: mapProvider),
          ChangeNotifierProvider.value(value: drawingProvider),
          ChangeNotifierProvider.value(value: channelsProvider),
          ChangeNotifierProvider.value(value: voiceProvider),
          ChangeNotifierProvider.value(value: imageProvider),
          ChangeNotifierProvider.value(value: appProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MessagesTab(isActive: true)),
        ),
      ),
    );

    await tester.pump();

    expect(messagesProvider.unreadCount, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(messagesProvider.unreadCount, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(messagesProvider.unreadCount, 0);

    appProvider.dispose();
    voiceProvider.dispose();
    imageProvider.dispose();
    drawingProvider.dispose();
    mapProvider.dispose();
    messagesProvider.dispose();
    contactsProvider.dispose();
    connectionProvider.dispose();
    channelsProvider.dispose();
  });

  testWidgets('shows mention overlay above composer and inserts selection', (
    tester,
  ) async {
    final connectionProvider = ConnectionProvider();
    final contactsProvider = ContactsProvider();
    final messagesProvider = MessagesProvider();
    final mapProvider = MapProvider();
    final drawingProvider = DrawingProvider();
    await messagesProvider.initialize();
    await drawingProvider.initialize();
    final channelsProvider = ChannelsProvider()..initializePublicChannel();
    final voiceProvider = VoiceProvider(
      codec: VoiceCodecService(),
      player: VoicePlayerService(),
    );
    final imageProvider = ip.ImageProvider();
    final appProvider = AppProvider(
      connectionProvider: connectionProvider,
      contactsProvider: contactsProvider,
      messagesProvider: messagesProvider,
      drawingProvider: drawingProvider,
      channelsProvider: channelsProvider,
      voiceProvider: voiceProvider,
      imageProvider: imageProvider,
    );

    contactsProvider.addContacts([
      buildContact(name: 'Tim', type: ContactType.chat, secondByte: 2),
      buildContact(name: 'Slane', type: ContactType.chat, secondByte: 3),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connectionProvider),
          ChangeNotifierProvider.value(value: contactsProvider),
          ChangeNotifierProvider.value(value: messagesProvider),
          ChangeNotifierProvider.value(value: mapProvider),
          ChangeNotifierProvider.value(value: drawingProvider),
          ChangeNotifierProvider.value(value: channelsProvider),
          ChangeNotifierProvider.value(value: voiceProvider),
          ChangeNotifierProvider.value(value: imageProvider),
          ChangeNotifierProvider.value(value: appProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: MessagesTab(isActive: true)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 60));

    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '@t');
    await tester.pumpAndSettle();

    expect(find.text('Tim'), findsOneWidget);
    expect(find.text('Slane'), findsNothing);

    await tester.tap(find.text('Tim'));
    await tester.pumpAndSettle();

    expect(find.text('@[Tim] '), findsOneWidget);
    expect(find.text('Tim'), findsNothing);

    appProvider.dispose();
    voiceProvider.dispose();
    imageProvider.dispose();
    drawingProvider.dispose();
    mapProvider.dispose();
    messagesProvider.dispose();
    contactsProvider.dispose();
    connectionProvider.dispose();
    channelsProvider.dispose();
  });

  testWidgets(
    'locks messages tab to the configured channel and removes the selector affordance',
    (tester) async {
      final lockedChannel = buildContact(
        name: '#ops',
        type: ContactType.channel,
        secondByte: 2,
      );
      SharedPreferences.setMockInitialValues({
        'message_locked_destination_enabled': true,
        'message_locked_destination_type':
            MessageDestinationPreferences.destinationTypeChannel,
        'message_locked_recipient_public_key': lockedChannel.publicKeyHex,
      });

      final connectionProvider = ConnectionProvider();
      final contactsProvider = ContactsProvider();
      final messagesProvider = MessagesProvider();
      final mapProvider = MapProvider();
      final drawingProvider = DrawingProvider();
      await messagesProvider.initialize();
      await drawingProvider.initialize();
      final channelsProvider = ChannelsProvider()..initializePublicChannel();
      final voiceProvider = VoiceProvider(
        codec: VoiceCodecService(),
        player: VoicePlayerService(),
      );
      final imageProvider = ip.ImageProvider();
      final appProvider = AppProvider(
        connectionProvider: connectionProvider,
        contactsProvider: contactsProvider,
        messagesProvider: messagesProvider,
        drawingProvider: drawingProvider,
        channelsProvider: channelsProvider,
        voiceProvider: voiceProvider,
        imageProvider: imageProvider,
      );

      contactsProvider.addContacts([lockedChannel]);
      messagesProvider.addMessage(
        Message(
          id: 'public-message',
          messageType: MessageType.channel,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000200,
          text: 'Public chatter',
          receivedAt: DateTime.now(),
          channelIdx: 0,
        ),
      );
      messagesProvider.addMessage(
        Message(
          id: 'locked-message',
          messageType: MessageType.channel,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000201,
          text: 'Ops chatter',
          receivedAt: DateTime.now(),
          channelIdx: 2,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: connectionProvider),
            ChangeNotifierProvider.value(value: contactsProvider),
            ChangeNotifierProvider.value(value: messagesProvider),
            ChangeNotifierProvider.value(value: mapProvider),
            ChangeNotifierProvider.value(value: drawingProvider),
            ChangeNotifierProvider.value(value: channelsProvider),
            ChangeNotifierProvider.value(value: voiceProvider),
            ChangeNotifierProvider.value(value: imageProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: MessagesTab(isActive: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ops chatter'), findsOneWidget);
      expect(find.text('Public chatter'), findsNothing);
      expect(
        find.byKey(const ValueKey('messages_composer_destination_locked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messages_composer_destination_selector')),
        findsNothing,
      );

      appProvider.dispose();
      voiceProvider.dispose();
      imageProvider.dispose();
      drawingProvider.dispose();
      mapProvider.dispose();
      messagesProvider.dispose();
      contactsProvider.dispose();
      connectionProvider.dispose();
      channelsProvider.dispose();
    },
  );

  testWidgets(
    'contact navigation temporarily overrides the lock while keeping the selector hidden',
    (tester) async {
      final directContact = buildContact(
        name: 'Tim',
        type: ContactType.chat,
        secondByte: 9,
      );
      SharedPreferences.setMockInitialValues({
        'message_locked_destination_enabled': true,
        'message_locked_destination_type':
            MessageDestinationPreferences.destinationTypeChannel,
      });

      final connectionProvider = ConnectionProvider();
      final contactsProvider = ContactsProvider();
      final messagesProvider = MessagesProvider();
      final mapProvider = MapProvider();
      final drawingProvider = DrawingProvider();
      await messagesProvider.initialize();
      await drawingProvider.initialize();
      final channelsProvider = ChannelsProvider()..initializePublicChannel();
      final voiceProvider = VoiceProvider(
        codec: VoiceCodecService(),
        player: VoicePlayerService(),
      );
      final imageProvider = ip.ImageProvider();
      final appProvider = AppProvider(
        connectionProvider: connectionProvider,
        contactsProvider: contactsProvider,
        messagesProvider: messagesProvider,
        drawingProvider: drawingProvider,
        channelsProvider: channelsProvider,
        voiceProvider: voiceProvider,
        imageProvider: imageProvider,
      );

      contactsProvider.addContacts([directContact]);
      messagesProvider.addMessage(
        Message(
          id: 'public-message',
          messageType: MessageType.channel,
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000300,
          text: 'Public chatter',
          receivedAt: DateTime.now(),
          channelIdx: 0,
        ),
      );
      messagesProvider.addMessage(
        Message(
          id: 'direct-message',
          messageType: MessageType.contact,
          senderPublicKeyPrefix: directContact.publicKey.sublist(0, 6),
          pathLen: 1,
          textType: MessageTextType.plain,
          senderTimestamp: 1700000301,
          text: 'Direct chatter',
          receivedAt: DateTime.now(),
        ),
      );
      messagesProvider.navigateToDestination(
        MessageDestinationPreferences.destinationTypeContact,
        recipientPublicKeyHex: directContact.publicKeyHex,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: connectionProvider),
            ChangeNotifierProvider.value(value: contactsProvider),
            ChangeNotifierProvider.value(value: messagesProvider),
            ChangeNotifierProvider.value(value: mapProvider),
            ChangeNotifierProvider.value(value: drawingProvider),
            ChangeNotifierProvider.value(value: channelsProvider),
            ChangeNotifierProvider.value(value: voiceProvider),
            ChangeNotifierProvider.value(value: imageProvider),
            ChangeNotifierProvider.value(value: appProvider),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: MessagesTab(isActive: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Direct chatter'), findsOneWidget);
      expect(find.text('Public chatter'), findsNothing);
      expect(
        find.byKey(const ValueKey('messages_composer_destination_locked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('messages_composer_destination_selector')),
        findsNothing,
      );

      appProvider.dispose();
      voiceProvider.dispose();
      imageProvider.dispose();
      drawingProvider.dispose();
      mapProvider.dispose();
      messagesProvider.dispose();
      contactsProvider.dispose();
      connectionProvider.dispose();
      channelsProvider.dispose();
    },
  );
}
