import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/models/ble_packet_log.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:meshcore_sar_app/services/traffic_stats_reporting_service.dart';

BlePacketLog _log({
  required DateTime timestamp,
  required List<int> rawData,
  int responseCode = 0x88,
}) {
  return BlePacketLog(
    timestamp: timestamp,
    rawData: Uint8List.fromList(rawData),
    direction: PacketDirection.rx,
    responseCode: responseCode,
  );
}

List<int> _routeRaw({
  required int payloadType,
  required int pathDescriptor,
  List<int> pathBytes = const <int>[],
}) {
  return <int>[
    0x88,
    0x00,
    0x00,
    payloadType << 2,
    0x00,
    0x00,
    0x00,
    0x00,
    pathDescriptor,
    ...pathBytes,
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
  });

  test('uploads fixed packet type and path mode counters', () async {
    final capturedPayloads = <Map<String, dynamic>>[];
    DateTime now = DateTime.utc(2026, 4, 3, 10, 6);
    final service = TrafficStatsReportingService(
      client: MockClient((request) async {
        capturedPayloads.add(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        return http.Response('{}', 200);
      }),
      now: () => now,
      appVersionProvider: () async => '2026.0402.1+44',
    );

    await service.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );
    expect(service.isEnabled, isTrue);
    await service.processLogs(<BlePacketLog>[
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 5),
        rawData: _routeRaw(
          payloadType: 0x04,
          pathDescriptor: 0x01,
          pathBytes: const <int>[0xC0],
        ),
      ),
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 10),
        rawData: _routeRaw(
          payloadType: 0x05,
          pathDescriptor: 0x41,
          pathBytes: const <int>[0xC0, 0x10],
        ),
      ),
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 15),
        rawData: _routeRaw(
          payloadType: 0x08,
          pathDescriptor: 0x81,
          pathBytes: const <int>[0xC0, 0x10, 0x63],
        ),
      ),
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 20),
        rawData: _routeRaw(
          payloadType: 0x01,
          pathDescriptor: 0x00,
        ),
      ),
    ]);

    expect(capturedPayloads, hasLength(1));

    final payload = capturedPayloads.single;
    final counts = payload['counts'] as Map<String, dynamic>;
    expect(payload['deviceKey6'], 'a1b2c3d4e5f6');
    expect(payload.containsKey('publicKey'), isFalse);
    expect(payload.containsKey('location'), isFalse);
    expect(counts['pt_04'], 1);
    expect(counts['pt_05'], 1);
    expect(counts['pt_08'], 1);
    expect(counts['pt_01'], 1);
    expect(counts['path_mode_1b'], 1);
    expect(counts['path_mode_2b'], 1);
    expect(counts['path_mode_3b'], 1);
    expect(counts['path_mode_none'], 1);
    expect(service.pendingUploadCount, 0);

    service.dispose();
  });

  test('classifies malformed route descriptors as decode and path failures', () async {
    final capturedPayloads = <Map<String, dynamic>>[];
    final service = TrafficStatsReportingService(
      client: MockClient((request) async {
        capturedPayloads.add(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        return http.Response('{}', 200);
      }),
      now: () => DateTime.utc(2026, 4, 3, 10, 6),
      appVersionProvider: () async => '2026.0402.1+44',
    );

    await service.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );
    await service.setEnabled(true);
    await service.processLogs(<BlePacketLog>[
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 30),
        rawData: _routeRaw(
          payloadType: 0x04,
          pathDescriptor: 0x41,
        ),
      ),
    ]);

    final counts =
        (capturedPayloads.single['counts'] as Map<String, dynamic>);
    expect(counts['decode_fail'], 1);
    expect(counts['path_mode_unknown'], 1);

    service.dispose();
  });

  test('persists queue and retries deterministically', () async {
    final requestBodies = <Map<String, dynamic>>[];
    var shouldFail = true;
    DateTime now = DateTime.utc(2026, 4, 3, 10, 6);

    final failingService = TrafficStatsReportingService(
      client: MockClient((request) async {
        requestBodies.add(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        if (shouldFail) {
          return http.Response('nope', 503);
        }
        return http.Response('{}', 200);
      }),
      now: () => now,
      appVersionProvider: () async => '2026.0402.1+44',
    );

    await failingService.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );
    await failingService.setEnabled(true);
    await failingService.processLogs(<BlePacketLog>[
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 5),
        rawData: _routeRaw(
          payloadType: 0x04,
          pathDescriptor: 0x01,
          pathBytes: const <int>[0xC0],
        ),
      ),
    ]);

    expect(failingService.pendingUploadCount, 1);
    expect(failingService.lastError, 'Upload failed (503)');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey('traffic_stats_reporting_queue'),
      isTrue,
    );
    expect(
      requestBodies.single['reportId'],
      'a1b2c3d4e5f6:2026-04-03T10:00:00.000Z',
    );
    failingService.dispose();

    shouldFail = false;
    now = DateTime.utc(2026, 4, 3, 10, 7);
    final retryService = TrafficStatsReportingService(
      client: MockClient((request) async {
        requestBodies.add(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        return http.Response('{}', 200);
      }),
      now: () => now,
      appVersionProvider: () async => '2026.0402.1+44',
    );
    await retryService.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );
    await retryService.flushPendingUploads();

    expect(retryService.pendingUploadCount, 0);
    expect(retryService.lastError, isNull);
    expect(retryService.lastSuccessAt, now);
    retryService.dispose();
  });

  test('ignores legacy interval preferences and keeps 5 minute windows', () async {
    SharedPreferences.setMockInitialValues({
      'traffic_stats_reporting_interval_minutes': 15,
    });
    final capturedPayloads = <Map<String, dynamic>>[];
    final service = TrafficStatsReportingService(
      client: MockClient((request) async {
        capturedPayloads.add(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        return http.Response('{}', 200);
      }),
      now: () => DateTime.utc(2026, 4, 3, 10, 6),
      appVersionProvider: () async => '2026.0402.1+44',
    );

    await service.initialize(
      deviceKey6Provider: () => 'a1b2c3d4e5f6',
    );
    await service.setEnabled(true);
    await service.processLogs(<BlePacketLog>[
      _log(
        timestamp: DateTime.utc(2026, 4, 3, 10, 0, 5),
        rawData: _routeRaw(
          payloadType: 0x04,
          pathDescriptor: 0x01,
          pathBytes: const <int>[0xC0],
        ),
      ),
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('traffic_stats_reporting_enabled'), isTrue);
    expect(prefs.containsKey('traffic_stats_reporting_interval_minutes'), isFalse);
    expect(
      prefs.containsKey('profile.alpha.traffic_stats_reporting_enabled'),
      isFalse,
    );
    expect(
      prefs.containsKey(
        'profile.alpha.traffic_stats_reporting_interval_minutes',
      ),
      isFalse,
    );
    expect(service.intervalMinutes, 5);
    expect(capturedPayloads, hasLength(1));

    service.dispose();
  });
}
