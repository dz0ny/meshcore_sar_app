import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
    tempDir = await Directory.systemTemp.createTemp('offline_tile_cache_test_');
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

  test('stores original bytes and content type without conversion', () async {
    const styleHash = 'abcdef123456';
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    await cache.saveStyleMeta(
      styleHash,
      displayName: 'Test layer',
      urlTemplate: 'https://example.com/{z}/{x}/{y}.png',
    );
    await cache.putTile(
      styleHash,
      8,
      12,
      34,
      bytes,
      contentType: 'image/png; charset=binary',
      sourceUrl: 'https://example.com/8/12/34.png',
    );

    final tile = await cache.getTileData(styleHash, 8, 12, 34);
    expect(tile, isNotNull);
    expect(tile!.bytes, bytes);
    expect(tile.contentType, 'image/png');
    expect(await cache.hasTile(styleHash, 8, 12, 34), isTrue);
    expect(await cache.getCacheSize(), bytes.length);

    final styles = await cache.listStylesDetailed();
    expect(styles, hasLength(1));
    expect(styles.single.tileCount, 1);
    expect(styles.single.sizeBytes, bytes.length);
  });

  test('hydrates existing disk cache into sqlite on first access', () async {
    const styleHash = 'fedcba654321';
    final base = Directory('${tempDir.path}/tiles/$styleHash/9/13');
    await base.create(recursive: true);
    final file = File('${base.path}/42.avif');
    await file.writeAsBytes([9, 8, 7], flush: true);
    await File('${tempDir.path}/tiles/$styleHash/meta.json').writeAsString(
      jsonEncode({
        'displayName': 'Legacy layer',
        'urlTemplate': 'https://example.com/{z}/{x}/{y}.avif',
      }),
      flush: true,
    );

    final tiles = await cache.listTilesForStyle(styleHash);
    expect(tiles, hasLength(1));
    expect(tiles.single.z, 9);
    expect(tiles.single.x, 13);
    expect(tiles.single.y, 42);

    final tile = await cache.getTileData(styleHash, 9, 13, 42);
    expect(tile, isNotNull);
    expect(tile!.bytes, Uint8List.fromList([9, 8, 7]));
    expect(tile.contentType, 'image/avif');

    final styles = await cache.listStylesDetailed();
    expect(styles.single.displayName, 'Legacy layer');
    expect(styles.single.tileCount, 1);
    expect(styles.single.sizeBytes, 3);
  });

  test('deletes style metadata and files', () async {
    const styleHash = 'aabbccddeeff';

    await cache.saveStyleMeta(
      styleHash,
      displayName: 'Delete me',
      urlTemplate: 'https://example.com/{z}/{x}/{y}.jpg',
    );
    await cache.putTile(
      styleHash,
      1,
      2,
      3,
      Uint8List.fromList([5, 6]),
      contentType: 'image/jpeg',
    );

    expect(await cache.getCacheSize(), 2);
    await cache.deleteStyle(styleHash);
    expect(await cache.getCacheSize(), 0);
    expect(await cache.getTileData(styleHash, 1, 2, 3), isNull);
    expect(await Directory('${tempDir.path}/tiles/$styleHash').exists(), isFalse);
  });
}
