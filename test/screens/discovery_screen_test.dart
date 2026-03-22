import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/device_info.dart' as device_info;
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/screens/discovery_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectionProvider extends ConnectionProvider {
  _FakeConnectionProvider({required bool isConnected})
    : _isConnected = isConnected;

  final bool _isConnected;
  final List<int> discoveredAdvertTypes = <int>[];

  @override
  device_info.DeviceInfo get deviceInfo => device_info.DeviceInfo(
    connectionState: _isConnected
        ? device_info.ConnectionState.connected
        : device_info.ConnectionState.disconnected,
  );

  @override
  Future<void> discoverNodeType({
    required int advertType,
    bool prefixOnly = false,
    int since = 0,
  }) async {
    discoveredAdvertTypes.add(advertType);
  }
}

Future<void> _pumpDiscoveryScreen(
  WidgetTester tester, {
  ContactsProvider? contactsProvider,
  ConnectionProvider? connectionProvider,
}) async {
  final resolvedContactsProvider = contactsProvider ?? ContactsProvider();
  final resolvedConnectionProvider =
      connectionProvider ?? _FakeConnectionProvider(isConnected: true);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ContactsProvider>.value(
          value: resolvedContactsProvider,
        ),
        ChangeNotifierProvider<ConnectionProvider>.value(
          value: resolvedConnectionProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DiscoveryScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Uint8List _publicKey(int seed) {
  final bytes = Uint8List(32);
  bytes[0] = seed;
  bytes[1] = seed + 1;
  bytes[2] = seed + 2;
  return bytes;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'discovery actions are shown in the summary card instead of overflow menu',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final connectionProvider = _FakeConnectionProvider(isConnected: true);

      await _pumpDiscoveryScreen(
        tester,
        connectionProvider: connectionProvider,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Discover repeaters'), findsOneWidget);
      expect(find.text('Discover sensors'), findsOneWidget);
      expect(find.text('Resolve all'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
      expect(find.text('Search discovered nodes'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(
        find.text(
          'Use the discovery actions above to find repeaters and sensors on the mesh.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Discover repeaters'));
      await tester.pump();

      expect(connectionProvider.discoveredAdvertTypes, [2]);
      expect(find.text('Repeater discovery sent'), findsOneWidget);
    },
  );

  testWidgets('search and inline type filters narrow discovered nodes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contactsProvider = ContactsProvider()
      ..addOrUpdatePendingAdvertMetadata(
        publicKey: _publicKey(0x10),
        typeValue: 2,
        advName: 'Relay Alpha',
      )
      ..addOrUpdatePendingAdvertMetadata(
        publicKey: _publicKey(0x20),
        typeValue: 4,
        advName: 'WX Station',
      )
      ..addOrUpdatePendingAdvertMetadata(
        publicKey: _publicKey(0x30),
        typeValue: 3,
        advName: 'Ops Room',
      );

    await _pumpDiscoveryScreen(
      tester,
      contactsProvider: contactsProvider,
      connectionProvider: _FakeConnectionProvider(isConnected: true),
    );

    expect(find.text('Search discovered nodes'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Repeaters'), findsOneWidget);
    expect(find.text('Sensors'), findsOneWidget);
    expect(find.text('Others'), findsOneWidget);

    expect(find.text('Relay Alpha'), findsOneWidget);
    expect(find.text('WX Station'), findsOneWidget);
    expect(find.text('Ops Room'), findsOneWidget);

    await tester.tap(find.text('Sensors'));
    await tester.pumpAndSettle();

    expect(find.text('Relay Alpha'), findsNothing);
    expect(find.text('WX Station'), findsOneWidget);
    expect(find.text('Ops Room'), findsNothing);
    expect(find.text('Discovered nodes (1/3)'), findsOneWidget);

    await tester.tap(find.text('Others'));
    await tester.pumpAndSettle();

    expect(find.text('Relay Alpha'), findsNothing);
    expect(find.text('WX Station'), findsNothing);
    expect(find.text('Ops Room'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'relay');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Relay Alpha'), findsOneWidget);
    expect(find.text('Ops Room'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ops');
    await tester.pumpAndSettle();

    expect(find.text('Relay Alpha'), findsNothing);
    expect(find.text('WX Station'), findsNothing);
    expect(find.text('Ops Room'), findsOneWidget);
    expect(find.text('Discovered nodes (1/3)'), findsOneWidget);
  });
}
