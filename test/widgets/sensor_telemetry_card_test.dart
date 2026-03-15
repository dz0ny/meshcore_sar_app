import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_telemetry_card.dart';

void main() {
  Contact buildContact() {
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
        temperature: 21.5,
        extraSensorData: const {
          '__source_channel:temperature': 1,
          'illuminance_2': 500.0,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
  }

  testWidgets('renders custom labels and channel badges', (tester) async {
    final contact = buildContact();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SensorTelemetryCard(
            contact: contact,
            state: SensorRefreshState.idle,
            visibleFields: const {'temperature', 'extra:illuminance_2'},
            labelOverrides: const {
              'temperature': 'Ambient',
              'extra:illuminance_2': 'Light',
            },
            fieldSpans: sensorFullWidthFieldSpans(
              const {'temperature', 'extra:illuminance_2'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ambient'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Temperature'), findsNothing);
    expect(find.text('Illuminance'), findsNothing);
    expect(
      find.byKey(const ValueKey('sensor_metric_channel_temperature')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sensor_metric_channel_extra:illuminance_2')),
      findsOneWidget,
    );
  });

  testWidgets('renders metrics in the provided order', (tester) async {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x45;
    final contact = Contact(
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

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SensorTelemetryCard(
            contact: contact,
            state: SensorRefreshState.idle,
            visibleFields: const {
              'battery',
              'temperature',
              'extra:illuminance_2',
            },
            fieldOrder: const [
              'extra:illuminance_2',
              'temperature',
              'battery',
            ],
            fieldSpans: sensorFullWidthFieldSpans(
              const {
                'battery',
                'temperature',
                'extra:illuminance_2',
              },
            ),
          ),
        ),
      ),
    );

    final illuminanceTop = tester.getTopLeft(
      find.byKey(const ValueKey('sensor_metric_extra:illuminance_2')),
    );
    final temperatureTop = tester.getTopLeft(
      find.byKey(const ValueKey('sensor_metric_temperature')),
    );
    final batteryTop = tester.getTopLeft(
      find.byKey(const ValueKey('sensor_metric_battery')),
    );

    expect(illuminanceTop.dy, lessThan(temperatureTop.dy));
    expect(temperatureTop.dy, lessThan(batteryTop.dy));
  });
}
