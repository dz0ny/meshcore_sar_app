import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// A saved download region (polygons + zoom range) for quick re-download.
class DownloadRegion {
  final List<List<List<double>>> polygons; // [polygon][vertex][lat, lng]
  final int minZoom;
  final int maxZoom;

  const DownloadRegion({
    required this.polygons,
    required this.minZoom,
    required this.maxZoom,
  });

  Map<String, dynamic> toJson() => {
        'polygons': polygons,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
      };

  factory DownloadRegion.fromJson(Map<String, dynamic> json) {
    final rawPolygons = json['polygons'] as List<dynamic>? ?? [];
    final polygons = rawPolygons.map<List<List<double>>>((poly) {
      return (poly as List<dynamic>).map<List<double>>((vertex) {
        final v = vertex as List<dynamic>;
        return [
          (v[0] as num).toDouble(),
          (v[1] as num).toDouble(),
        ];
      }).toList();
    }).toList();
    return DownloadRegion(
      polygons: polygons,
      minZoom: json['minZoom'] as int? ?? 8,
      maxZoom: json['maxZoom'] as int? ?? 14,
    );
  }
}

/// Metadata about a cached map style.
class StyleInfo {
  final String hash;
  final String displayName;
  final String urlTemplate;
  final int tileCount;
  final int sizeBytes;
  final DownloadRegion? region;

  const StyleInfo({
    required this.hash,
    required this.displayName,
    required this.urlTemplate,
    this.tileCount = 0,
    this.sizeBytes = 0,
    this.region,
  });

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'displayName': displayName,
        'urlTemplate': urlTemplate,
        'tileCount': tileCount,
        'sizeBytes': sizeBytes,
        if (region != null) 'region': region!.toJson(),
      };

  factory StyleInfo.fromJson(Map<String, dynamic> json) => StyleInfo(
        hash: json['hash'] as String,
        displayName: json['displayName'] as String? ?? json['hash'] as String,
        urlTemplate: json['urlTemplate'] as String? ?? '',
        tileCount: json['tileCount'] as int? ?? 0,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        region: json['region'] != null
            ? DownloadRegion.fromJson(json['region'] as Map<String, dynamic>)
            : null,
      );
}

/// A tile coordinate in the cache (z/x/y).
class CachedTileCoord {
  final int z, x, y;
  const CachedTileCoord(this.z, this.x, this.y);

  Map<String, int> toJson() => {'z': z, 'x': x, 'y': y};

  factory CachedTileCoord.fromJson(Map<String, dynamic> json) =>
      CachedTileCoord(
        json['z'] as int,
        json['x'] as int,
        json['y'] as int,
      );
}

class CachedTileData {
  final Uint8List bytes;
  final String? contentType;

  const CachedTileData({
    required this.bytes,
    required this.contentType,
  });
}

class _CachedTileLocation {
  final String relativePath;
  final String? contentType;

  const _CachedTileLocation({
    required this.relativePath,
    required this.contentType,
  });
}

/// Manages the offline tile cache on disk with a SQLite metadata index.
class OfflineTileCacheService {
  OfflineTileCacheService._();
  static final instance = OfflineTileCacheService._();

  static const int _memoryCacheMaxEntries = 4096;
  static const int _memoryCacheMaxBytes = 64 * 1024 * 1024;

  String? _baseDir;
  String? _databasePath;
  Database? _database;
  int _tileMemoryBytes = 0;

  final Map<String, Set<String>> _manifests = {};
  final Map<String, Future<void>> _styleHydrations = {};
  final Map<String, _CachedTileLocation> _tileLocationCache = {};
  final LinkedHashMap<String, CachedTileData> _tileMemoryCache =
      LinkedHashMap<String, CachedTileData>();

  Future<String> get baseDir async {
    if (_baseDir != null) return _baseDir!;
    final docs = await getApplicationDocumentsDirectory();
    _baseDir = '${docs.path}/offline_tiles';
    return _baseDir!;
  }

  Future<String> get _dbPath async {
    if (_databasePath != null) return _databasePath!;
    final docs = await getApplicationSupportDirectory();
    _databasePath = '${docs.path}/offline_tiles.db';
    return _databasePath!;
  }

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final path = await _dbPath;
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );
    return _database!;
  }

  @visibleForTesting
  void setBaseDirForTesting(String path) {
    _baseDir = path;
  }

  @visibleForTesting
  void setDatabasePathForTesting(String path) {
    _databasePath = path;
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    await _database?.close();
    _database = null;
    _baseDir = null;
    _databasePath = null;
    _manifests.clear();
    clearMemoryCacheForTesting();
  }

  @visibleForTesting
  void clearMemoryCacheForTesting() {
    _tileLocationCache.clear();
    _tileMemoryCache.clear();
    _tileMemoryBytes = 0;
  }

  /// Derive a short deterministic hash from a URL template.
  String styleHashFromUrl(String urlTemplate) {
    final bytes = sha256.convert(urlTemplate.codeUnits).bytes;
    return bytes
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _tileKey(int z, int x, int y) => '$z/$x/$y';

  String _tileDir(String base, String styleHash, int z, int x) {
    return '$base/$styleHash/$z/$x';
  }

  String _manifestPath(String base, String styleHash) =>
      '$base/$styleHash/manifest.txt';

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_tile_styles (
        style_hash TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        url_template TEXT NOT NULL,
        region_json TEXT,
        tile_count INTEGER NOT NULL DEFAULT 0,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_tile_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        style_hash TEXT NOT NULL,
        z INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        relative_path TEXT NOT NULL,
        content_type TEXT,
        size_bytes INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        UNIQUE(style_hash, z, x, y)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS offline_tile_entries_style_idx '
      'ON offline_tile_entries(style_hash)',
    );
  }

  /// Load the manifest for a style into memory (if not already loaded).
  Future<Set<String>> loadManifest(String styleHash) async {
    if (_manifests.containsKey(styleHash)) return _manifests[styleHash]!;

    var rows = await (await _db).query(
      'offline_tile_entries',
      columns: ['z', 'x', 'y'],
      where: 'style_hash = ?',
      whereArgs: [styleHash],
    );
    if (rows.isEmpty) {
      await _hydrateStyleFromDisk(styleHash);
      rows = await (await _db).query(
        'offline_tile_entries',
        columns: ['z', 'x', 'y'],
        where: 'style_hash = ?',
        whereArgs: [styleHash],
      );
    }

    final manifest = rows
        .map((row) => _tileKey(
              row['z'] as int,
              row['x'] as int,
              row['y'] as int,
            ))
        .toSet();
    _manifests[styleHash] = manifest;
    return manifest;
  }

  Future<CachedTileData?> getTileData(
    String styleHash,
    int z,
    int x,
    int y,
  ) async {
    final cacheKey = '$styleHash/${_tileKey(z, x, y)}';
    final cached = _tileMemoryCache.remove(cacheKey);
    if (cached != null) {
      _tileMemoryCache[cacheKey] = cached;
      return cached;
    }

    var location = _tileLocationCache[cacheKey];
    if (location == null) {
      final row = await _loadTileRow(styleHash, z, x, y);
      if (row == null) return null;
      location = _CachedTileLocation(
        relativePath: row['relative_path'] as String,
        contentType: row['content_type'] as String?,
      );
      _tileLocationCache[cacheKey] = location;
    }

    final base = await baseDir;
    final file = File('$base/${location.relativePath}');
    if (!await file.exists()) {
      await _deleteTileEntry(styleHash, z, x, y);
      return null;
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      await _deleteTileEntry(styleHash, z, x, y);
      return null;
    }
    final data = CachedTileData(
      bytes: bytes,
      contentType: location.contentType,
    );
    _rememberTile(cacheKey, data);
    return data;
  }

  /// Read a cached tile's raw bytes (for serving to peers).
  Future<Uint8List?> getRawTile(String styleHash, int z, int x, int y) async {
    final tile = await getTileData(styleHash, z, x, y);
    return tile?.bytes;
  }

  /// Check if a tile exists in the cache.
  Future<bool> hasTile(String styleHash, int z, int x, int y) async {
    final cacheKey = '$styleHash/${_tileKey(z, x, y)}';
    if (_tileLocationCache.containsKey(cacheKey)) {
      _manifests[styleHash] ??= {};
      _manifests[styleHash]!.add(_tileKey(z, x, y));
      return true;
    }

    final row = await _loadTileRow(styleHash, z, x, y);
    if (row != null) {
      _tileLocationCache[cacheKey] = _CachedTileLocation(
        relativePath: row['relative_path'] as String,
        contentType: row['content_type'] as String?,
      );
      _manifests[styleHash] ??= {};
      _manifests[styleHash]!.add(_tileKey(z, x, y));
      return true;
    }

    final manifest = await loadManifest(styleHash);
    return manifest.contains(_tileKey(z, x, y));
  }

  /// Store a tile's original bytes and update the SQLite index.
  Future<void> putTile(
    String styleHash,
    int z,
    int x,
    int y,
    Uint8List bytes, {
    String? contentType,
    String? sourceUrl,
  }) async {
    final resolvedContentType = _normalizeContentType(contentType);
    final fileExtension = _fileExtensionForTile(
      contentType: resolvedContentType,
      sourceUrl: sourceUrl,
    );
    final relativePath = '$styleHash/$z/$x/$y.$fileExtension';
    final base = await baseDir;
    final dir = Directory(_tileDir(base, styleHash, z, x));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('$base/$relativePath');
    await file.writeAsBytes(bytes, flush: true);
    await _upsertTileEntry(
      styleHash: styleHash,
      z: z,
      x: x,
      y: y,
      relativePath: relativePath,
      contentType: resolvedContentType,
      sizeBytes: bytes.length,
    );

    _manifests[styleHash] ??= {};
    _manifests[styleHash]!.add(_tileKey(z, x, y));
    await _writeManifest(base, styleHash, _manifests[styleHash]!);
    _rememberTile(
      '$styleHash/${_tileKey(z, x, y)}',
      CachedTileData(bytes: bytes, contentType: resolvedContentType),
    );
  }

  /// Store raw tile bytes directly (from a peer), update the SQLite index.
  Future<void> putRawTile(
    String styleHash,
    int z,
    int x,
    int y,
    Uint8List bytes, {
    String? contentType,
  }) async {
    await putTile(
      styleHash,
      z,
      x,
      y,
      bytes,
      contentType: contentType,
    );
  }

  /// Get total cache size in bytes.
  Future<int> getCacheSize() async {
    await _hydrateAllStylesIfDatabaseIsEmpty();
    final rows = await (await _db).rawQuery(
      'SELECT COALESCE(SUM(size_bytes), 0) AS total FROM offline_tile_entries',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  /// List all style hashes that have cached tiles.
  Future<List<String>> listStyles() async {
    final styles = await listStylesDetailed();
    return styles.map((style) => style.hash).toList();
  }

  /// Save metadata for a style (name, URL template, download region).
  Future<void> saveStyleMeta(
    String styleHash, {
    required String displayName,
    required String urlTemplate,
    DownloadRegion? region,
  }) async {
    final base = await baseDir;
    final dir = Directory('$base/$styleHash');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final metaFile = File('$base/$styleHash/meta.json');
    final existing = await getStyleMeta(styleHash);
    final regionJson = region != null
        ? jsonEncode(region.toJson())
        : existing?.region == null
            ? null
            : jsonEncode(existing!.region!.toJson());
    final meta = <String, dynamic>{
      'displayName': displayName,
      'urlTemplate': urlTemplate,
      if (regionJson != null) 'region': jsonDecode(regionJson),
    };
    await metaFile.writeAsString(jsonEncode(meta), flush: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).insert(
      'offline_tile_styles',
      {
        'style_hash': styleHash,
        'display_name': displayName,
        'url_template': urlTemplate,
        'region_json': regionJson,
        'tile_count': existing?.tileCount ?? 0,
        'size_bytes': existing?.sizeBytes ?? 0,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Read metadata for a style.
  Future<StyleInfo?> getStyleMeta(String styleHash) async {
    final rows = await (await _db).query(
      'offline_tile_styles',
      where: 'style_hash = ?',
      whereArgs: [styleHash],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return _styleInfoFromRow(rows.first);
    }

    final base = await baseDir;
    final metaFile = File('$base/$styleHash/meta.json');
    if (!await metaFile.exists()) return null;
    try {
      final json = jsonDecode(await metaFile.readAsString());
      return StyleInfo(
        hash: styleHash,
        displayName: json['displayName'] as String? ?? styleHash,
        urlTemplate: json['urlTemplate'] as String? ?? '',
        region: json['region'] != null
            ? DownloadRegion.fromJson(json['region'] as Map<String, dynamic>)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  /// List all styles with metadata, tile counts, and sizes.
  Future<List<StyleInfo>> listStylesDetailed() async {
    await _hydrateAllStylesIfDatabaseIsEmpty();
    final rows = await (await _db).query(
      'offline_tile_styles',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_styleInfoFromRow).toList();
  }

  /// List all tile coordinates cached for a given style.
  Future<List<CachedTileCoord>> listTilesForStyle(String styleHash) async {
    var rows = await (await _db).query(
      'offline_tile_entries',
      columns: ['z', 'x', 'y'],
      where: 'style_hash = ?',
      whereArgs: [styleHash],
      orderBy: 'z ASC, x ASC, y ASC',
    );
    if (rows.isEmpty) {
      await _hydrateStyleFromDisk(styleHash);
      rows = await (await _db).query(
        'offline_tile_entries',
        columns: ['z', 'x', 'y'],
        where: 'style_hash = ?',
        whereArgs: [styleHash],
        orderBy: 'z ASC, x ASC, y ASC',
      );
    }

    return rows
        .map((row) => CachedTileCoord(
              row['z'] as int,
              row['x'] as int,
              row['y'] as int,
            ))
        .toList();
  }

  /// Delete a single style's tiles, manifest, and metadata.
  Future<void> deleteStyle(String styleHash) async {
    _manifests.remove(styleHash);
    _removeStyleFromMemory(styleHash);
    final base = await baseDir;
    final dir = Directory('$base/$styleHash');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await (await _db).delete(
      'offline_tile_entries',
      where: 'style_hash = ?',
      whereArgs: [styleHash],
    );
    await (await _db).delete(
      'offline_tile_styles',
      where: 'style_hash = ?',
      whereArgs: [styleHash],
    );
  }

  /// Delete all cached tiles, manifests, and metadata.
  Future<void> clearCache() async {
    _manifests.clear();
    clearMemoryCacheForTesting();
    final base = await baseDir;
    final dir = Directory(base);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await (await _db).delete('offline_tile_entries');
    await (await _db).delete('offline_tile_styles');
  }

  StyleInfo _styleInfoFromRow(Map<String, Object?> row) {
    final regionJson = row['region_json'] as String?;
    return StyleInfo(
      hash: row['style_hash'] as String,
      displayName: row['display_name'] as String,
      urlTemplate: row['url_template'] as String,
      tileCount: row['tile_count'] as int? ?? 0,
      sizeBytes: row['size_bytes'] as int? ?? 0,
      region: regionJson == null
          ? null
          : DownloadRegion.fromJson(jsonDecode(regionJson) as Map<String, dynamic>),
    );
  }

  Future<void> _hydrateAllStylesIfDatabaseIsEmpty() async {
    final rows = await (await _db).rawQuery(
      'SELECT COUNT(*) AS count FROM offline_tile_styles',
    );
    if (((rows.first['count'] as int?) ?? 0) > 0) return;
    await _hydrateAllStylesFromDisk();
  }

  Future<void> _hydrateAllStylesFromDisk() async {
    final base = await baseDir;
    final dir = Directory(base);
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final styleHash = entity.path.split('/').last;
        await _hydrateStyleFromDisk(styleHash);
      }
    }
  }

  Future<void> _hydrateStyleFromDisk(String styleHash) {
    final existing = _styleHydrations[styleHash];
    if (existing != null) return existing;

    final hydration = _hydrateStyleFromDiskLocked(styleHash);
    _styleHydrations[styleHash] = hydration;
    return hydration.whenComplete(() {
      _styleHydrations.remove(styleHash);
    });
  }

  Future<void> _hydrateStyleFromDiskLocked(String styleHash) async {
    final base = await baseDir;
    final styleDir = Directory('$base/$styleHash');
    if (!await styleDir.exists()) return;

    String displayName = styleHash;
    String urlTemplate = '';
    DownloadRegion? region;
    final metaFile = File('$base/$styleHash/meta.json');
    if (await metaFile.exists()) {
      try {
        final json = jsonDecode(await metaFile.readAsString());
        displayName = json['displayName'] as String? ?? styleHash;
        urlTemplate = json['urlTemplate'] as String? ?? '';
        if (json['region'] != null) {
          region = DownloadRegion.fromJson(json['region'] as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    final entries = <({int z, int x, int y, String relativePath, String? contentType, int sizeBytes})>[];
    await for (final entity in styleDir.list(recursive: true)) {
      if (entity is! File) continue;
      final relativePath = entity.path.replaceFirst('$base/', '');
      final segments = relativePath.split('/');
      if (segments.length != 4) continue;
      if (segments[3] == 'meta.json' || segments[3] == 'manifest.txt') continue;

      final z = int.tryParse(segments[1]);
      final x = int.tryParse(segments[2]);
      final ySegment = segments[3].split('.').first;
      final y = int.tryParse(ySegment);
      if (z == null || x == null || y == null) continue;

      final int sizeBytes;
      try {
        if (!await entity.exists()) continue;
        sizeBytes = await entity.length();
      } on FileSystemException {
        continue;
      }

      entries.add((
        z: z,
        x: x,
        y: y,
        relativePath: relativePath,
        contentType: _contentTypeFromPath(relativePath),
        sizeBytes: sizeBytes,
      ));
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final totalSize = entries.fold<int>(
      0,
      (total, entry) => total + entry.sizeBytes,
    );
    await (await _db).transaction((txn) async {
      await txn.delete(
        'offline_tile_entries',
        where: 'style_hash = ?',
        whereArgs: [styleHash],
      );
      await txn.insert(
        'offline_tile_styles',
        {
          'style_hash': styleHash,
          'display_name': displayName,
          'url_template': urlTemplate,
          'region_json': region == null ? null : jsonEncode(region.toJson()),
          'tile_count': entries.length,
          'size_bytes': totalSize,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final entry in entries) {
        await txn.insert(
          'offline_tile_entries',
          {
            'style_hash': styleHash,
            'z': entry.z,
            'x': entry.x,
            'y': entry.y,
            'relative_path': entry.relativePath,
            'content_type': entry.contentType,
            'size_bytes': entry.sizeBytes,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _manifests[styleHash] =
        entries.map((entry) => _tileKey(entry.z, entry.x, entry.y)).toSet();
    for (final entry in entries) {
      _tileLocationCache['$styleHash/${_tileKey(entry.z, entry.x, entry.y)}'] =
          _CachedTileLocation(
        relativePath: entry.relativePath,
        contentType: entry.contentType,
      );
    }
    await _writeManifest(base, styleHash, _manifests[styleHash]!);
  }

  Future<void> _upsertTileEntry({
    required String styleHash,
    required int z,
    required int x,
    required int y,
    required String relativePath,
    required String? contentType,
    required int sizeBytes,
  }) async {
    final existingTile = await _loadTileRow(styleHash, z, x, y, hydrate: false);
    final existingStyle = await getStyleMeta(styleHash);
    if (existingTile != null &&
        existingTile['relative_path'] != null &&
        existingTile['relative_path'] != relativePath) {
      final base = await baseDir;
      final oldFile = File('$base/${existingTile['relative_path']}');
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    final tileCountDelta = existingTile == null ? 1 : 0;
    final sizeDelta = sizeBytes - ((existingTile?['size_bytes'] as int?) ?? 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).transaction((txn) async {
      await txn.insert(
        'offline_tile_entries',
        {
          'style_hash': styleHash,
          'z': z,
          'x': x,
          'y': y,
          'relative_path': relativePath,
          'content_type': contentType,
          'size_bytes': sizeBytes,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'offline_tile_styles',
        {
          'style_hash': styleHash,
          'display_name': existingStyle?.displayName ?? styleHash,
          'url_template': existingStyle?.urlTemplate ?? '',
          'region_json': existingStyle?.region == null
              ? null
              : jsonEncode(existingStyle!.region!.toJson()),
          'tile_count': (existingStyle?.tileCount ?? 0) + tileCountDelta,
          'size_bytes': (existingStyle?.sizeBytes ?? 0) + sizeDelta,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    _tileLocationCache['$styleHash/${_tileKey(z, x, y)}'] =
        _CachedTileLocation(
      relativePath: relativePath,
      contentType: contentType,
    );
  }

  Future<void> _deleteTileEntry(String styleHash, int z, int x, int y) async {
    final existingTile = await _loadTileRow(styleHash, z, x, y, hydrate: false);
    if (existingTile == null) return;

    final existingStyle = await getStyleMeta(styleHash);
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db).transaction((txn) async {
      await txn.delete(
        'offline_tile_entries',
        where: 'style_hash = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [styleHash, z, x, y],
      );
      if (existingStyle != null) {
        await txn.insert(
          'offline_tile_styles',
          {
            'style_hash': styleHash,
            'display_name': existingStyle.displayName,
            'url_template': existingStyle.urlTemplate,
            'region_json': existingStyle.region == null
                ? null
                : jsonEncode(existingStyle.region!.toJson()),
            'tile_count': (existingStyle.tileCount - 1).clamp(0, existingStyle.tileCount),
            'size_bytes': (existingStyle.sizeBytes - (existingTile['size_bytes'] as int))
                .clamp(0, existingStyle.sizeBytes),
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _manifests[styleHash]?.remove(_tileKey(z, x, y));
    _tileLocationCache.remove('$styleHash/${_tileKey(z, x, y)}');
    final removed = _tileMemoryCache.remove('$styleHash/${_tileKey(z, x, y)}');
    if (removed != null) {
      _tileMemoryBytes -= removed.bytes.length;
    }
    final base = await baseDir;
    final manifest = _manifests[styleHash];
    if (manifest != null) {
      await _writeManifest(base, styleHash, manifest);
    }
  }

  Future<void> _writeManifest(
      String base, String styleHash, Set<String> manifest) async {
    final dir = Directory('$base/$styleHash');
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(_manifestPath(base, styleHash))
        .writeAsString(manifest.join('\n'), flush: true);
  }

  void _rememberTile(String key, CachedTileData data) {
    final existing = _tileMemoryCache.remove(key);
    if (existing != null) {
      _tileMemoryBytes -= existing.bytes.length;
    }
    _tileMemoryCache[key] = data;
    _tileMemoryBytes += data.bytes.length;

    while (_tileMemoryCache.length > _memoryCacheMaxEntries ||
        _tileMemoryBytes > _memoryCacheMaxBytes) {
      final firstKey = _tileMemoryCache.keys.first;
      final removed = _tileMemoryCache.remove(firstKey);
      if (removed != null) {
        _tileMemoryBytes -= removed.bytes.length;
      }
    }
  }

  void _removeStyleFromMemory(String styleHash) {
    final prefix = '$styleHash/';
    _tileLocationCache.removeWhere((key, _) => key.startsWith(prefix));
    final keys = _tileMemoryCache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      final removed = _tileMemoryCache.remove(key);
      if (removed != null) {
        _tileMemoryBytes -= removed.bytes.length;
      }
    }
  }

  String? _normalizeContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) return null;
    return contentType.split(';').first.trim().toLowerCase();
  }

  String _fileExtensionForTile({
    required String? contentType,
    required String? sourceUrl,
  }) {
    if (contentType != null) {
      switch (contentType) {
        case 'image/png':
          return 'png';
        case 'image/jpeg':
          return 'jpg';
        case 'image/webp':
          return 'webp';
        case 'image/avif':
          return 'avif';
      }
    }

    final uri = sourceUrl == null ? null : Uri.tryParse(sourceUrl);
    final segment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    final match = RegExp(r'\.(png|jpg|jpeg|webp|avif)$', caseSensitive: false)
        .firstMatch(segment);
    final extension = match?.group(1)?.toLowerCase();
    if (extension == 'jpeg') return 'jpg';
    return extension ?? 'tile';
  }

  String? _contentTypeFromPath(String relativePath) {
    if (relativePath.endsWith('.png')) return 'image/png';
    if (relativePath.endsWith('.jpg') || relativePath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (relativePath.endsWith('.webp')) return 'image/webp';
    if (relativePath.endsWith('.avif')) return 'image/avif';
    return null;
  }

  Future<Map<String, Object?>?> _loadTileRow(
    String styleHash,
    int z,
    int x,
    int y, {
    bool hydrate = true,
  }) async {
    var rows = await (await _db).query(
      'offline_tile_entries',
      where: 'style_hash = ? AND z = ? AND x = ? AND y = ?',
      whereArgs: [styleHash, z, x, y],
      limit: 1,
    );
    if (rows.isEmpty && hydrate) {
      await _hydrateStyleFromDisk(styleHash);
      rows = await (await _db).query(
        'offline_tile_entries',
        where: 'style_hash = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [styleHash, z, x, y],
        limit: 1,
      );
    }
    return rows.isEmpty ? null : rows.first;
  }
}
