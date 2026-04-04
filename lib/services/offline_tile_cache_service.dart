import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:path_provider/path_provider.dart';

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

/// Manages the offline AVIF tile cache on disk.
///
/// Tiles are stored as `{baseDir}/offline_tiles/{styleHash}/{z}/{x}/{y}.avif`.
/// Style metadata is stored as `{baseDir}/offline_tiles/{styleHash}/meta.json`.
/// This cache is separate from flutter_map's built-in cache and is used for
/// proactively downloaded tiles and WiFi sharing.
class OfflineTileCacheService {
  OfflineTileCacheService._();
  static final instance = OfflineTileCacheService._();

  String? _baseDir;

  Future<String> get baseDir async {
    if (_baseDir != null) return _baseDir!;
    final docs = await getApplicationDocumentsDirectory();
    _baseDir = '${docs.path}/offline_tiles';
    return _baseDir!;
  }

  /// Derive a short deterministic hash from a URL template.
  String styleHashFromUrl(String urlTemplate) {
    final bytes = sha256.convert(urlTemplate.codeUnits).bytes;
    return bytes
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _tilePath(String base, String styleHash, int z, int x, int y) {
    return '$base/$styleHash/$z/$x/$y.avif';
  }

  String _tileDir(String base, String styleHash, int z, int x) {
    return '$base/$styleHash/$z/$x';
  }

  // In-memory manifest cache: styleHash → set of "z/x/y" keys.
  // Loaded lazily, kept in sync with writes.
  final Map<String, Set<String>> _manifests = {};

  static String _tileKey(int z, int x, int y) => '$z/$x/$y';

  String _manifestPath(String base, String styleHash) =>
      '$base/$styleHash/manifest.txt';

  /// Load the manifest for a style into memory (if not already loaded).
  Future<Set<String>> loadManifest(String styleHash) async {
    if (_manifests.containsKey(styleHash)) return _manifests[styleHash]!;

    final base = await baseDir;
    final file = File(_manifestPath(base, styleHash));
    final Set<String> manifest;
    if (await file.exists()) {
      final lines = await file.readAsLines();
      manifest = lines.where((l) => l.isNotEmpty).toSet();
    } else {
      // First time — scan the filesystem and build the manifest
      manifest = {};
      final styleDir = Directory('$base/$styleHash');
      if (await styleDir.exists()) {
        final avifPattern = RegExp(r'/(\d+)/(\d+)/(\d+)\.avif$');
        await for (final entity in styleDir.list(recursive: true)) {
          if (entity is! File) continue;
          final match = avifPattern.firstMatch(entity.path);
          if (match != null) {
            manifest.add('${match.group(1)}/${match.group(2)}/${match.group(3)}');
          }
        }
        // Persist the scanned manifest
        await _writeManifest(base, styleHash, manifest);
      }
    }
    _manifests[styleHash] = manifest;
    return manifest;
  }

  Future<void> _writeManifest(
      String base, String styleHash, Set<String> manifest) async {
    final dir = Directory('$base/$styleHash');
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(_manifestPath(base, styleHash))
        .writeAsString(manifest.join('\n'), flush: true);
  }

  /// Append a tile key to the manifest (both in-memory and on disk).
  Future<void> _addToManifest(
      String base, String styleHash, String key) async {
    _manifests[styleHash] ??= {};
    if (_manifests[styleHash]!.add(key)) {
      final file = File(_manifestPath(base, styleHash));
      await file.writeAsString('$key\n',
          mode: FileMode.append, flush: true);
    }
  }

  /// Check if a tile exists in the cache (uses in-memory manifest).
  Future<bool> hasTile(String styleHash, int z, int x, int y) async {
    final manifest = await loadManifest(styleHash);
    return manifest.contains(_tileKey(z, x, y));
  }

  /// Read a cached tile's raw AVIF bytes (for serving to peers).
  Future<Uint8List?> getRawTile(String styleHash, int z, int x, int y) async {
    final base = await baseDir;
    final file = File(_tilePath(base, styleHash, z, x, y));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  /// Read a cached tile and decode AVIF → PNG bytes for flutter_map display.
  Future<Uint8List?> getTileAsPng(
      String styleHash, int z, int x, int y) async {
    final avifBytes = await getRawTile(styleHash, z, x, y);
    if (avifBytes == null) return null;
    return _avifToPng(avifBytes);
  }

  /// Store a tile: encode PNG bytes → AVIF, write to disk, update manifest.
  Future<void> putTile(
    String styleHash,
    int z,
    int x,
    int y,
    Uint8List pngBytes,
  ) async {
    final base = await baseDir;
    final dir = Directory(_tileDir(base, styleHash, z, x));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final avifBytes = await _pngToAvif(pngBytes);
    if (avifBytes == null) {
      await File(_tilePath(base, styleHash, z, x, y))
          .writeAsBytes(pngBytes, flush: true);
    } else {
      await File(_tilePath(base, styleHash, z, x, y))
          .writeAsBytes(avifBytes, flush: true);
    }

    await _addToManifest(base, styleHash, _tileKey(z, x, y));
  }

  /// Store raw AVIF bytes directly (from a peer), update manifest.
  Future<void> putRawTile(
    String styleHash,
    int z,
    int x,
    int y,
    Uint8List avifBytes,
  ) async {
    final base = await baseDir;
    final dir = Directory(_tileDir(base, styleHash, z, x));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(_tilePath(base, styleHash, z, x, y))
        .writeAsBytes(avifBytes, flush: true);
    await _addToManifest(base, styleHash, _tileKey(z, x, y));
  }

  /// Get total cache size in bytes.
  Future<int> getCacheSize() async {
    final base = await baseDir;
    final dir = Directory(base);
    if (!await dir.exists()) return 0;

    var totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// List all style hashes that have cached tiles.
  Future<List<String>> listStyles() async {
    final base = await baseDir;
    final dir = Directory(base);
    if (!await dir.exists()) return [];

    final styles = <String>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        styles.add(entity.path.split('/').last);
      }
    }
    return styles;
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

    // Merge with existing meta to preserve region if not provided
    final metaFile = File('$base/$styleHash/meta.json');
    Map<String, dynamic> meta = {
      'displayName': displayName,
      'urlTemplate': urlTemplate,
    };
    if (region != null) {
      meta['region'] = region.toJson();
    } else if (await metaFile.exists()) {
      try {
        final existing = jsonDecode(await metaFile.readAsString());
        if (existing['region'] != null) {
          meta['region'] = existing['region'];
        }
      } catch (_) {}
    }

    await metaFile.writeAsString(jsonEncode(meta), flush: true);
  }

  /// Read metadata for a style.
  Future<StyleInfo?> getStyleMeta(String styleHash) async {
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
    final base = await baseDir;
    final dir = Directory(base);
    if (!await dir.exists()) return [];

    final results = <StyleInfo>[];
    await for (final entity in dir.list()) {
      if (entity is! Directory) continue;
      final hash = entity.path.split('/').last;

      // Read meta
      String displayName = hash;
      String urlTemplate = '';
      DownloadRegion? region;
      final metaFile = File('${entity.path}/meta.json');
      if (await metaFile.exists()) {
        try {
          final json = jsonDecode(await metaFile.readAsString());
          displayName = json['displayName'] as String? ?? hash;
          urlTemplate = json['urlTemplate'] as String? ?? '';
          if (json['region'] != null) {
            region = DownloadRegion.fromJson(
                json['region'] as Map<String, dynamic>);
          }
        } catch (_) {}
      }

      // Count tiles and size
      var tileCount = 0;
      var sizeBytes = 0;
      await for (final file in entity.list(recursive: true)) {
        if (file is File && file.path.endsWith('.avif')) {
          tileCount++;
          sizeBytes += await file.length();
        }
      }

      results.add(StyleInfo(
        hash: hash,
        displayName: displayName,
        urlTemplate: urlTemplate,
        tileCount: tileCount,
        sizeBytes: sizeBytes,
        region: region,
      ));
    }
    return results;
  }

  /// List all tile coordinates cached for a given style.
  Future<List<CachedTileCoord>> listTilesForStyle(String styleHash) async {
    final base = await baseDir;
    final styleDir = Directory('$base/$styleHash');
    if (!await styleDir.exists()) return [];

    final tiles = <CachedTileCoord>[];
    final avifPattern = RegExp(r'/(\d+)/(\d+)/(\d+)\.avif$');

    await for (final entity in styleDir.list(recursive: true)) {
      if (entity is! File) continue;
      final match = avifPattern.firstMatch(entity.path);
      if (match != null) {
        tiles.add(CachedTileCoord(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        ));
      }
    }
    return tiles;
  }

  /// Delete a single style's tiles, manifest, and metadata.
  Future<void> deleteStyle(String styleHash) async {
    _manifests.remove(styleHash);
    final base = await baseDir;
    final dir = Directory('$base/$styleHash');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Delete all cached tiles, manifests, and metadata.
  Future<void> clearCache() async {
    _manifests.clear();
    final base = await baseDir;
    final dir = Directory(base);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Decode AVIF bytes to PNG (static helper for use by caching provider).
  static Future<Uint8List?> getTileAsPngStatic(Uint8List avifBytes) {
    return _avifToPng(avifBytes);
  }

  /// Encode PNG → AVIF for tile storage.
  /// Uses moderate quality for good compression with acceptable quality.
  static Future<Uint8List?> _pngToAvif(Uint8List pngBytes) async {
    try {
      final avif = await encodeAvif(
        pngBytes,
        maxThreads: 2,
        maxQuantizer: 40, // Good quality (0=lossless, 63=worst)
        minQuantizer: 25,
        maxQuantizerAlpha: 63,
        minQuantizerAlpha: 63,
        speed: 6,
        keepExif: false,
      );
      if (avif.isEmpty) return null;
      return avif;
    } catch (e) {
      debugPrint('[OfflineTileCache] AVIF encode error: $e');
      return null;
    }
  }

  /// Decode AVIF → PNG bytes for display.
  static Future<Uint8List?> _avifToPng(Uint8List avifBytes) async {
    try {
      // Use Flutter's image codec which can handle AVIF via flutter_avif
      final codec = await ui.instantiateImageCodec(avifBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[OfflineTileCache] AVIF decode error: $e');
      return null;
    }
  }
}
