import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_tile_cache_service.dart';
import 'tile_sharing_service.dart';

/// A [MapCachingProvider] that checks the offline AVIF tile cache (and
/// optionally peers) before falling through to the built-in cache.
///
/// This allows preloaded tiles to be served during normal map browsing.
class OfflineMapCachingProvider implements MapCachingProvider {
  final MapCachingProvider _delegate;
  final OfflineTileCacheService _cache = OfflineTileCacheService.instance;
  final TileSharingService _sharing = TileSharingService.instance;

  OfflineMapCachingProvider(this._delegate);

  @override
  bool get isSupported => true;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    // Extract tile coordinates from URL to check our AVIF cache
    final coords = _parseTileUrl(url);
    if (coords != null) {
      final styleHash = _cache.styleHashFromUrl(_extractUrlTemplate(url));

      // Check local AVIF cache first
      final pngBytes = await _cache.getTileAsPng(
          styleHash, coords.z, coords.x, coords.y);
      if (pngBytes != null) {
        return (
          bytes: pngBytes,
          metadata: CachedMapTileMetadata(
            staleAt: DateTime.now().add(const Duration(days: 365)),
            lastModified: null,
            etag: null,
          ),
        );
      }

      // Try peers
      if (_sharing.discoveredPeers.isNotEmpty) {
        final avifBytes = await _sharing.fetchFromAnyPeer(
            styleHash, coords.z, coords.x, coords.y);
        if (avifBytes != null) {
          // Cache locally for next time
          await _cache.putRawTile(
              styleHash, coords.z, coords.x, coords.y, avifBytes);
          final decoded = await OfflineTileCacheService.getTileAsPngStatic(avifBytes);
          if (decoded != null) {
            return (
              bytes: decoded,
              metadata: CachedMapTileMetadata(
                staleAt: DateTime.now().add(const Duration(days: 365)),
                lastModified: null,
                etag: null,
              ),
            );
          }
        }
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

  /// Parse z/x/y from a tile URL.
  static _TileCoords? _parseTileUrl(String url) {
    // Match common patterns: /{z}/{x}/{y}.png, /tile/{z}/{y}/{x}, etc.
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
    // Replace the last three numeric path segments with placeholders
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
