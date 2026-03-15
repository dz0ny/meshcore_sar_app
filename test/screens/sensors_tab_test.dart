import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/screens/sensors_tab.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> waitUntilLoaded(SensorsProvider provider) async {
    for (var i = 0; i < 20 && !provider.isLoaded; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.isLoaded, isTrue);
  }

  Contact buildSensorContact() {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x44;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: 'WX Station',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      telemetry: ContactTelemetry(
        batteryPercentage: 84,
        temperature: 21.5,
        extraSensorData: const {
          '__source_channel:battery': 1,
          '__source_channel:temperature': 1,
          'illuminance_2': 500.0,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
  }

  testWidgets('customize sheet shows metric value previews and channels', (
    tester,
  ) async {
    final contact = buildSensorContact();
    final sensorsProvider = SensorsProvider();
    final contactsProvider = ContactsProvider();

    await waitUntilLoaded(sensorsProvider);
    contactsProvider.addOrUpdateContact(contact);
    await sensorsProvider.addSensor(contact);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContactsProvider>.value(
              value: contactsProvider,
            ),
            ChangeNotifierProvider<SensorsProvider>.value(value: sensorsProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SensorsTab(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Customize fields'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('sensor_selector_value_extra:illuminance_2')),
      findsOneWidget,
    );
    expect(find.text('500 lx'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sensor_selector_channel_extra:illuminance_2')),
      findsOneWidget,
    );
    expect(find.text('ch2'), findsOneWidget);
  });
}
