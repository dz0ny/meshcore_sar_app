import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/map_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/widgets/contacts/contact_tile.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_telemetry_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Contact buildContact({
    required String name,
    required ContactType type,
    int secondByte = 1,
  }) {
    final publicKey = Uint8List(32);
    publicKey[1] = secondByte;

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 46562000,
      advLon: 14950000,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> pumpTile(
    WidgetTester tester,
    Contact contact, {
    SensorsProvider? sensorsProvider,
  }) async {
    final resolvedSensorsProvider = sensorsProvider ?? SensorsProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
          ChangeNotifierProvider(create: (_) => ContactsProvider()),
          ChangeNotifierProvider(create: (_) => MessagesProvider()),
          ChangeNotifierProvider<SensorsProvider>.value(
            value: resolvedSensorsProvider,
          ),
          ChangeNotifierProvider(create: (_) => MapProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ContactTile(contact: contact)),
        ),
      ),
    );
  }

  testWidgets('shows trace action for non-channel contacts', (tester) async {
    await pumpTile(
      tester,
      buildContact(name: 'John Smith', type: ContactType.chat),
    );

    await tester.tap(find.text('John Smith'));
    await tester.pumpAndSettle();

    expect(find.text('Trace'), findsOneWidget);
  });

  testWidgets('does not show trace action for channels', (tester) async {
    await pumpTile(
      tester,
      buildContact(name: 'Ops', type: ContactType.channel, secondByte: 3),
    );

    await tester.tap(find.text('Ops'));
    await tester.pumpAndSettle();

    expect(find.text('Trace'), findsNothing);
  });

  testWidgets('shows overridden contact name as primary label', (tester) async {
    await pumpTile(
      tester,
      buildContact(
        name: 'John Smith',
        type: ContactType.chat,
      ).copyWith(nameOverride: 'Rescue One'),
    );

    expect(find.text('Rescue One'), findsOneWidget);
    expect(find.text('John Smith'), findsNothing);
  });

  testWidgets('hides public key in contact tile', (tester) async {
    final contact = buildContact(name: 'John Smith', type: ContactType.chat);

    await pumpTile(tester, contact);

    expect(find.text(contact.publicKeyShort), findsNothing);
    expect(find.byIcon(Icons.key_outlined), findsNothing);
  });

  testWidgets('sensor contacts can be added to sensors', (tester) async {
    await pumpTile(
      tester,
      buildContact(name: 'WX Station', type: ContactType.sensor),
    );

    await tester.tap(find.text('WX Station'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Sensors'), findsOneWidget);
  });

  testWidgets('sensor preview shows telemetry card', (tester) async {
    final contact = buildContact(name: 'WX Station', type: ContactType.sensor)
        .copyWith(
          telemetry: ContactTelemetry(
            batteryPercentage: 84,
            temperature: 21.5,
            humidity: 58.0,
            extraSensorData: const {
              '__source_channel:battery': 1,
              '__source_channel:temperature': 1,
              '__source_channel:humidity': 1,
              'co2': 415.0,
              'illuminance_2': 500.0,
              'current_2': 0.015,
              'power_2': 0.25,
              'distance_2': 1.234,
            },
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        );

    await pumpTile(tester, contact);

    await tester.tap(find.text('WX Station'));
    await tester.pumpAndSettle();

    expect(find.text('Preview'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('21.5°C'), findsOneWidget);
    expect(find.text('CO2'), findsOneWidget);
    expect(find.text('415 ppm'), findsOneWidget);
    expect(find.text('Illuminance'), findsOneWidget);
    expect(find.text('~4.2 W/m2 daylight'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('15 mA'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sensor_metric_channel_battery')),
      findsOneWidget,
    );
    expect(find.text('ch1'), findsWidgets);
    expect(
      find.byKey(const ValueKey('sensor_metric_channel_extra:illuminance_2')),
      findsOneWidget,
    );

    final sensorCardSize = tester.getSize(find.byType(SensorTelemetryCard));
    final batteryTileSize = tester.getSize(
      find.byKey(const ValueKey('sensor_metric_battery')),
    );
    expect(batteryTileSize.width, greaterThan(sensorCardSize.width * 0.8));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(SensorTelemetryCard), findsNothing);
  });
}
