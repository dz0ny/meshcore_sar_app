import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/services/traffic_stats_reporting_service.dart';
import 'package:meshcore_sar_app/widgets/settings/traffic_stats_reporting_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launchedUrls = <String>[];

  setUp(() {
    launchedUrls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            switch (call.method) {
              case 'canLaunch':
                return true;
              case 'launch':
                final arguments = Map<dynamic, dynamic>.from(
                  call.arguments as Map<dynamic, dynamic>,
                );
                launchedUrls.add(arguments['url'] as String);
                return true;
            }
            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  testWidgets('starts enabled by default and can be disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = TrafficStatsReportingService(
      client: MockClient((request) async => http.Response('{}', 200)),
      now: () => DateTime.utc(2026, 4, 3, 10, 6),
      appVersionProvider: () async => '2026.0402.1+44',
    );
    await service.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: service,
            builder: (context, child) => TrafficStatsReportingSection(
              service: service,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Anonymous RX stats reporting'), findsOneWidget);
    expect(
      find.text(
        'Upload RX live-traffic packet type and path mode totals to the fixed Cloudflare worker every 5 minutes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reporting interval'), findsNothing);
    expect(service.isEnabled, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(service.isEnabled, isFalse);
    expect(service.intervalMinutes, 5);

    await tester.tap(find.widgetWithText(TextButton, 'View public stats'));
    await tester.pump();

    expect(launchedUrls, ['https://mcstats.dz0ny.dev']);

    service.dispose();
  });
}
