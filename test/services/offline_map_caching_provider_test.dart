import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/services/offline_map_caching_provider.dart';
import 'package:meshcore_sar_app/services/offline_tile_cache_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  final cache = OfflineTileCacheService.instance;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_map_provider_test_');
    await cache.resetForTesting();
    cache.setBaseDirForTesting('${tempDir.path}/tiles');
    cache.setDatabasePathForTesting('${tempDir.path}/tiles.db');
  });

  tearDown(() async {
    await cache.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('parses query-style tile URLs used by Google layers', () {
    final coords = OfflineMapCachingProvider.parseTileUrlForTesting(
      'http://mt0.google.com/vt/lyrs=m&hl=en&x=4312&y=2810&z=13',
    );

    expect(coords, isNotNull);
    expect(coords!.z, 13);
    expect(coords.x, 4312);
    expect(coords.y, 2810);
    expect(
      OfflineMapCachingProvider.extractUrlTemplateForTesting(
        'http://mt0.google.com/vt/lyrs=m&hl=en&x=4312&y=2810&z=13',
      ),
      'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
    );
  });

  test('parses Esri tile URLs and preserves y/x order in template', () {
    final coords = OfflineMapCachingProvider.parseTileUrlForTesting(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/9/173/267',
    );

    expect(coords, isNotNull);
    expect(coords!.z, 9);
    expect(coords.x, 267);
    expect(coords.y, 173);
    expect(
      OfflineMapCachingProvider.extractUrlTemplateForTesting(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/9/173/267',
      ),
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    );
  });

  test('returns cached raw bytes directly', () async {
    const url =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/9/173/267';
    final template = OfflineMapCachingProvider.extractUrlTemplateForTesting(url);
    final styleHash = cache.styleHashFromUrl(template);
    final bytes = Uint8List.fromList([1, 2, 3]);

    await cache.saveStyleMeta(
      styleHash,
      displayName: 'Esri',
      urlTemplate: template,
    );
    await cache.putTile(
      styleHash,
      9,
      267,
      173,
      bytes,
      contentType: 'image/jpeg',
      sourceUrl: url,
    );

    final provider = OfflineMapCachingProvider(_NullMapCachingProvider());
    final tile = await provider.getTile(url);

    expect(tile, isNotNull);
    expect(tile!.bytes, bytes);
  });
}

class _NullMapCachingProvider implements MapCachingProvider {
  @override
  bool get isSupported => true;

  @override
  Future<CachedMapTile?> getTile(String url) async => null;

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {}
}
