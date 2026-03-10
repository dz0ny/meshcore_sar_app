import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_sar_app/services/mesh_map_nodes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MeshMapNodesService.clearCache();
  });

  test('fetchNodes persists nodes and cached lookup works offline', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://api.meshcore.nz/api/v1/map/nodes',
      );
      return http.Response(
        jsonEncode({
          'nodes': [
            {
              'type': 1,
              'name': 'Alpha',
              'public_key': 'aa11bb22',
              'latitude': 46.05,
              'longitude': 14.50,
              'updated_at': 123456,
            },
          ],
        }),
        200,
      );
    });

    final nodes = await MeshMapNodesService.fetchNodes(client: client);
    final cached = await MeshMapNodesService.fetchNodes(allowNetwork: false);

    expect(nodes, hasLength(1));
    expect(cached, hasLength(1));
    expect(cached.first.name, 'Alpha');
    expect(await MeshMapNodesService.hasFreshCache(), isTrue);
  });

  test('loadCachedNodes ignores stale persisted cache', () async {
    SharedPreferences.setMockInitialValues({
      'mesh_map_nodes_cache_v1': jsonEncode([
        {
          'type': 1,
          'name': 'Old node',
          'public_key': 'bb22cc33',
          'latitude': 46.05,
          'longitude': 14.50,
          'updated_at': 123456,
        },
      ]),
      'mesh_map_nodes_cache_timestamp_v1': DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch,
    });

    final nodes = await MeshMapNodesService.loadCachedNodes();

    expect(nodes, isEmpty);
    expect(await MeshMapNodesService.hasFreshCache(), isFalse);
  });

  test('clearCache removes persisted online trace database', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'nodes': [
            {
              'type': 1,
              'name': 'Alpha',
              'public_key': 'aa11bb22',
              'latitude': 46.05,
              'longitude': 14.50,
              'updated_at': 123456,
            },
          ],
        }),
        200,
      ),
    );

    await MeshMapNodesService.fetchNodes(client: client);
    await MeshMapNodesService.clearCache();

    expect(await MeshMapNodesService.loadCachedNodes(), isEmpty);
    expect(await MeshMapNodesService.cachedAt(), isNull);
  });
}
