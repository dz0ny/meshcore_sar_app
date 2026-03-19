import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/widgets/messages/recipient_selector_sheet.dart';

void main() {
  Contact buildContact({
    required String name,
    required ContactType type,
    int secondByte = 0,
    int flags = 0,
    int lastAdvert = 0,
  }) {
    final publicKey = Uint8List(32);
    publicKey[1] = secondByte;

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: flags,
      outPathLen: 0,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: lastAdvert,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
    );
  }

  Future<void> pumpSheet(WidgetTester tester) async {
    final channel = buildContact(
      name: 'Ops',
      type: ContactType.channel,
      secondByte: 3,
    );
    final contact = buildContact(name: 'John Smith', type: ContactType.chat);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipientSelectorSheet(
            contacts: [contact],
            rooms: const [],
            channels: [channel],
            unreadCount: 11,
            unreadCountsByPublicKey: {
              channel.publicKeyHex: 7,
              contact.publicKeyHex: 3,
            },
            currentDestinationType: 'all',
            onSelect: (selectedContact, destinationType) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders unread badges for all and destination filters', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('unread-badge-11')), findsOneWidget);
    expect(find.byKey(const Key('unread-badge-7')), findsOneWidget);
    expect(find.byKey(const Key('unread-badge-3')), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('can hide show all option for contact-only flows', (
    tester,
  ) async {
    final contact = buildContact(name: 'John Smith', type: ContactType.chat);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipientSelectorSheet(
            contacts: [contact],
            rooms: const [],
            channels: const [],
            unreadCount: 0,
            unreadCountsByPublicKey: const {},
            showAllOption: false,
            onSelect: (selectedRecipient, draftMessage) {},
          ),
        ),
      ),
    );

    expect(find.text('Show all'), findsNothing);
    expect(find.text('John Smith'), findsOneWidget);
  });

  testWidgets('sorts contacts with favourites first, then last seen', (
    tester,
  ) async {
    final recentNonFavourite = buildContact(
      name: 'Alpha',
      type: ContactType.chat,
      secondByte: 1,
      lastAdvert: 300,
    );
    final olderFavourite = buildContact(
      name: 'Bravo',
      type: ContactType.chat,
      secondByte: 2,
      flags: 0x01,
      lastAdvert: 100,
    );
    final newerFavourite = buildContact(
      name: 'Charlie',
      type: ContactType.chat,
      secondByte: 3,
      flags: 0x01,
      lastAdvert: 200,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RecipientSelectorSheet(
            contacts: [recentNonFavourite, olderFavourite, newerFavourite],
            rooms: const [],
            channels: const [],
            unreadCount: 0,
            unreadCountsByPublicKey: const {},
            showAllOption: false,
            onSelect: (selectedRecipient, draftMessage) {},
          ),
        ),
      ),
    );

    final charlieY = tester.getTopLeft(find.text('Charlie')).dy;
    final bravoY = tester.getTopLeft(find.text('Bravo')).dy;
    final alphaY = tester.getTopLeft(find.text('Alpha')).dy;

    expect(charlieY, lessThan(bravoY));
    expect(bravoY, lessThan(alphaY));
  });
}
