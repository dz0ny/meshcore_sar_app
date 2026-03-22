import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
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
            fieldSpans: sensorFullWidthFieldSpans(const {
              'temperature',
              'extra:illuminance_2',
            }),
          ),
        ),
      ),
    );

    expect(find.text('Ambient'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Temperature'), findsNothing);
    expect(find.text('Illuminance'), findsNothing);
    expect(find.text('~4.2 W/m2'), findsOneWidget);
    expect(find.textContaining('lx'), findsNothing);
    expect(
      find.byKey(const ValueKey('sensor_metric_temperature')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sensor_metric_extra:illuminance_2')),
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
            fieldOrder: const ['extra:illuminance_2', 'temperature', 'battery'],
            fieldSpans: sensorFullWidthFieldSpans(const {
              'battery',
              'temperature',
              'extra:illuminance_2',
            }),
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

  testWidgets('renders MeshCore custom weather metrics', (tester) async {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x46;
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
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        extraSensorData: const {'gust_2': 3.7, 'dew_2': 2.0, 'rain_2': 12.3},
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
              'extra:gust_2',
              'extra:dew_2',
              'extra:rain_2',
            },
            fieldSpans: sensorFullWidthFieldSpans(const {
              'extra:gust_2',
              'extra:dew_2',
              'extra:rain_2',
            }),
          ),
        ),
      ),
    );

    expect(find.text('Wind gust'), findsOneWidget);
    expect(find.text('Dew point'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget);
    expect(find.text('3.7 m/s'), findsOneWidget);
    expect(find.text('2°C'), findsOneWidget);
    expect(find.text('12.3 mm'), findsOneWidget);
  });

  testWidgets('renders generic percentage separately from UV for weather payload', (tester) async {
    tester.view.physicalSize = const Size(1600, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final publicKey = Uint8List(32);
    publicKey[0] = 0x49;
    final payload = Uint8List.fromList([
      0x01, 0x74, 0x00, 0x00,
      0x02, 0x78, 0x64,
      0x02, 0x73, 0x24, 0x31,
      0x02, 0x65, 0x67, 0xDE,
      0x02, 0x8A, 0xFF, 0xE6,
      0x02, 0x74, 0x01, 0xE0,
      0x02, 0x9D, 0x00,
      0x02, 0x68, 0x76,
      0x02, 0x81, 0x00, 0xDC,
      0x02, 0x89, 0x01, 0x36,
      0x02, 0x67, 0x00, 0x2F,
      0x02, 0xAD, 0x0A,
      0x02, 0x84, 0x00, 0x50,
      0x02, 0x8B, 0x00, 0xB3,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ]);

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
      telemetry: CayenneLppParser.parse(payload),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SensorTelemetryCard(
              contact: contact,
              state: SensorRefreshState.idle,
              visibleFields: const {
                'temperature',
                'humidity',
                'pressure',
                'extra:percentage_2',
                'extra:dew_2',
                'extra:speed_2',
                'extra:gust_2',
                'extra:uv_2',
                'extra:direction_2',
                'extra:rain_2',
              },
              fieldSpans: sensorFullWidthFieldSpans(const {
                'temperature',
                'humidity',
                'pressure',
                'extra:percentage_2',
                'extra:dew_2',
                'extra:speed_2',
                'extra:gust_2',
                'extra:uv_2',
                'extra:direction_2',
                'extra:rain_2',
              }),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('sensor_metric_extra:percentage_2')), findsOneWidget);
    expect(find.byKey(const ValueKey('sensor_metric_extra:uv_2')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1%'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('80°'), findsOneWidget);
    expect(find.text('8°'), findsNothing);
  });

  testWidgets('renders direction metric with compact compass layout', (
    tester,
  ) async {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x47;
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
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        extraSensorData: const {'direction_2': 111.0},
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
            visibleFields: const {'extra:direction_2'},
            fieldSpans: sensorFullWidthFieldSpans(const {'extra:direction_2'}),
          ),
        ),
      ),
    );

    expect(find.text('Direction'), findsOneWidget);
    expect(find.text('111°'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
  });

  testWidgets('long pressing a telemetry bubble triggers refresh', (
    tester,
  ) async {
    final contact = buildContact();
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SensorTelemetryCard(
            contact: contact,
            state: SensorRefreshState.idle,
            visibleFields: const {'temperature'},
            fieldSpans: sensorFullWidthFieldSpans(const {'temperature'}),
            onRefresh: () async {
              refreshCount += 1;
            },
          ),
        ),
      ),
    );

    await tester.longPress(
      find.byKey(const ValueKey('sensor_metric_temperature')),
    );
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });

  testWidgets('overflow menu exposes move actions', (tester) async {
    final contact = buildContact();
    var moveUpCount = 0;
    var moveDownCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SensorTelemetryCard(
            contact: contact,
            state: SensorRefreshState.idle,
            visibleFields: const {'temperature'},
            fieldSpans: sensorFullWidthFieldSpans(const {'temperature'}),
            onMoveUp: () async {
              moveUpCount += 1;
            },
            onMoveDown: () async {
              moveDownCount += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Move up'), findsOneWidget);
    expect(find.text('Move down'), findsOneWidget);

    await tester.tap(find.text('Move down'));
    await tester.pumpAndSettle();

    expect(moveUpCount, 0);
    expect(moveDownCount, 1);
  });

  testWidgets('overflow menu copies raw response', (tester) async {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x48;
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
        temperature: 21.5,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        extraSensorData: const {'__raw_lpp_hex': '01 67 00 d7'},
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
            visibleFields: const {'temperature'},
            fieldSpans: sensorFullWidthFieldSpans(const {'temperature'}),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Copy raw response'), findsOneWidget);

    await tester.tap(find.text('Copy raw response'));
    await tester.pump();

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboardData?.text, '01 67 00 d7');
    expect(find.text('Raw response copied'), findsOneWidget);
  });
}
