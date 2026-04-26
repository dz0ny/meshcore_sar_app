import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_tile_cache_service.dart';

/// A [MapCachingProvider] that checks the offline tile cache before
/// falling through to the built-in cache/network path.
///
/// This allows preloaded tiles to be served during normal map browsing.
class OfflineMapCachingProvider implements MapCachingProvider {
  final MapCachingProvider _delegate;
  final OfflineTileCacheService _cache = OfflineTileCacheService.instance;

  OfflineMapCachingProvider(this._delegate);

  @override
  bool get isSupported => true;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    // Extract tile coordinates from URL to check our AVIF cache
    final coords = _parseTileUrl(url);
    if (coords != null) {
      final styleHash = _cache.styleHashFromUrl(_extractUrlTemplate(url));

      // Check local offline cache first
      final cachedTile = await _cache.getTileData(
        styleHash,
        coords.z,
        coords.x,
        coords.y,
      );
      if (cachedTile != null) {
        return (
          bytes: cachedTile.bytes,
          metadata: CachedMapTileMetadata(
            staleAt: DateTime.now().add(const Duration(days: 365)),
            lastModified: null,
            etag: null,
          ),
        );
      }
    }

    // Fall through to delegate (built-in cache)
    return _delegate.getTile(url);
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) {
    // Only delegate to built-in cache for normal browsing tiles
    return _delegate.putTile(url: url, metadata: metadata, bytes: bytes);
  }

  @visibleForTesting
  static ({int z, int x, int y})? parseTileUrlForTesting(String url) {
    final coords = _parseTileUrl(url);
    if (coords == null) {
      return null;
    }
    return (z: coords.z, x: coords.x, y: coords.y);
  }

  @visibleForTesting
  static String extractUrlTemplateForTesting(String url) {
    return _extractUrlTemplate(url);
  }

  /// Parse z/x/y from a tile URL.
  static _TileCoords? _parseTileUrl(String url) {
    final queryStyleMatch = RegExp(
      r'(?:\?|&|/)(?:[^#]*&)?x=(\d+)&y=(\d+)&z=(\d+)(?:&|$)',
    ).firstMatch(url);
    if (queryStyleMatch != null) {
      return _TileCoords(
        z: int.parse(queryStyleMatch.group(3)!),
        x: int.parse(queryStyleMatch.group(1)!),
        y: int.parse(queryStyleMatch.group(2)!),
      );
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final z = int.tryParse(uri.queryParameters['z'] ?? '');
      final x = int.tryParse(uri.queryParameters['x'] ?? '');
      final y = int.tryParse(uri.queryParameters['y'] ?? '');
      if (z != null && x != null && y != null) {
        return _TileCoords(z: z, x: x, y: y);
      }
    }

    // Match known path formats.
    final yxTilePattern = RegExp(r'/tile/(\d+)/(\d+)/(\d+)$');
    final yxTileMatch = yxTilePattern.firstMatch(url);
    if (yxTileMatch != null) {
      return _TileCoords(
        z: int.parse(yxTileMatch.group(1)!),
        x: int.parse(yxTileMatch.group(3)!),
        y: int.parse(yxTileMatch.group(2)!),
      );
    }

    final patterns = [
      RegExp(r'/(\d+)/(\d+)/(\d+)\.(?:png|jpg|jpeg|webp)'),
      RegExp(r'/(\d+)/(\d+)/(\d+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return _TileCoords(
          z: int.parse(match.group(1)!),
          x: int.parse(match.group(2)!),
          y: int.parse(match.group(3)!),
        );
      }
    }
    return null;
  }

  /// Extract a URL template from a concrete URL by replacing coordinates.
  static String _extractUrlTemplate(String url) {
    final queryStylePattern = RegExp(r'([?&])x=\d+&y=\d+&z=\d+');
    if (queryStylePattern.hasMatch(url)) {
      return url.replaceAllMapped(
        queryStylePattern,
        (match) => '${match.group(1)}x={x}&y={y}&z={z}',
      );
    }

    final pathStyleQueryPattern = RegExp(r'(&)x=\d+&y=\d+&z=\d+');
    if (pathStyleQueryPattern.hasMatch(url)) {
      return url.replaceAllMapped(
        pathStyleQueryPattern,
        (match) => '${match.group(1)}x={x}&y={y}&z={z}',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      final query = Map<String, String>.from(uri.queryParameters);
      var replacedQuery = false;
      if (query.containsKey('z')) {
        query['z'] = '{z}';
        replacedQuery = true;
      }
      if (query.containsKey('x')) {
        query['x'] = '{x}';
        replacedQuery = true;
      }
      if (query.containsKey('y')) {
        query['y'] = '{y}';
        replacedQuery = true;
      }
      if (replacedQuery) {
        return uri.replace(queryParameters: query).toString();
      }
    }

    final yxTilePattern = RegExp(r'/tile/(\d+)/(\d+)/(\d+)$');
    final yxTileMatch = yxTilePattern.firstMatch(url);
    if (yxTileMatch != null) {
      return url.replaceRange(
        yxTileMatch.start,
        yxTileMatch.end,
        '/tile/{z}/{y}/{x}',
      );
    }

    return url.replaceAllMapped(
      RegExp(r'/(\d+)/(\d+)/(\d+)(\.(?:png|jpg|jpeg|webp))?$'),
      (m) => '/{z}/{x}/{y}${m.group(4) ?? ''}',
    );
  }
}

class _TileCoords {
  final int z, x, y;
  const _TileCoords({required this.z, required this.x, required this.y});
}
