import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'offline_tile_cache_service.dart';
import 'tile_math_service.dart';

/// Events emitted during tile download.
sealed class TileDownloadEvent {}

class TileDownloadStarted extends TileDownloadEvent {
  final int totalTiles;
  TileDownloadStarted(this.totalTiles);
}

class TileDownloaded extends TileDownloadEvent {
  final double north, south, east, west;
  TileDownloaded({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

class TileSkipped extends TileDownloadEvent {
  final double north, south, east, west;
  TileSkipped({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

class TileFailed extends TileDownloadEvent {
  final TileCoord coord;
  final String error;
  TileFailed(this.coord, this.error);
}

class TileDownloadComplete extends TileDownloadEvent {
  final int downloaded;
  final int skipped;
  final int failed;
  final int total;
  TileDownloadComplete({
    required this.downloaded,
    required this.skipped,
    required this.failed,
    required this.total,
  });
}

class TileBatchSkipped extends TileDownloadEvent {
  final int count;
  final int total;
  TileBatchSkipped({required this.count, required this.total});
}

class TileDownloadCancelled extends TileDownloadEvent {}

/// Downloads map tiles for given polygons and zoom levels.
class TileDownloadService {
  final OfflineTileCacheService _cache = OfflineTileCacheService.instance;
  final http.Client _httpClient = http.Client();

  bool _cancelled = false;

  /// Cancel an ongoing download.
  void cancel() {
    _cancelled = true;
  }

  /// Download tiles for the given polygons and zoom range.
  ///
  /// Returns a stream of [TileDownloadEvent]s.
  /// [urlTemplate] should contain `{z}`, `{x}`, `{y}` placeholders,
  /// and optionally `{s}` for subdomains.
  Stream<TileDownloadEvent> downloadTiles({
    required List<List<LatLng>> polygons,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    String? displayName,
    int maxConcurrency = 6,
    int rateLimit = 30,
  }) {
    final controller = StreamController<TileDownloadEvent>();

    _runDownload(
      controller: controller,
      polygons: polygons,
      minZoom: minZoom,
      maxZoom: maxZoom,
      urlTemplate: urlTemplate,
      displayName: displayName,
      maxConcurrency: maxConcurrency,
      rateLimit: rateLimit,
    );

    return controller.stream;
  }

  Future<void> _runDownload({
    required StreamController<TileDownloadEvent> controller,
    required List<List<LatLng>> polygons,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    String? displayName,
    required int maxConcurrency,
    required int rateLimit,
  }) async {
    _cancelled = false;

    final styleHash = _cache.styleHashFromUrl(urlTemplate);

    // Save style metadata with download region so it can be reused
    final region = DownloadRegion(
      polygons: polygons
          .map((poly) =>
              poly.map((p) => [p.latitude, p.longitude]).toList())
          .toList(),
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    await _cache.saveStyleMeta(
      styleHash,
      displayName: displayName ?? urlTemplate,
      urlTemplate: urlTemplate,
      region: region,
    );

    final allTiles =
        TileMathService.getTilesForPolygons(polygons, minZoom, maxZoom);

    // Load manifest once and partition tiles into needed vs already cached
    final manifest = await _cache.loadManifest(styleHash);
    final tilesToDownload = <TileCoord>[];
    var skipped = 0;

    for (final tile in allTiles) {
      final key = '${tile.z}/${tile.x}/${tile.y}';
      if (manifest.contains(key)) {
        skipped++;
      } else {
        tilesToDownload.add(tile);
      }
    }

    final total = allTiles.length;
    controller.add(TileDownloadStarted(total));

    // Report all skipped tiles immediately (no per-tile filesystem check)
    if (skipped > 0) {
      controller.add(TileBatchSkipped(count: skipped, total: total));
    }

    if (tilesToDownload.isEmpty) {
      controller.add(TileDownloadComplete(
          downloaded: 0, skipped: skipped, failed: 0, total: total));
      await controller.close();
      return;
    }

    var downloaded = 0;
    var failed = 0;

    final semaphore = _Semaphore(maxConcurrency);
    final rateLimiter = _RateLimiter(rateLimit);
    final futures = <Future<void>>[];

    for (final tile in tilesToDownload) {
      if (_cancelled) break;

      await rateLimiter.wait();
      if (_cancelled) break;

      await semaphore.acquire();
      if (_cancelled) {
        semaphore.release();
        break;
      }

      final future = _downloadSingleTile(tile, urlTemplate, styleHash)
          .then((event) {
        if (!controller.isClosed) {
          controller.add(event);
          if (event is TileDownloaded) {
            downloaded++;
          } else if (event is TileFailed) {
            failed++;
          }
        }
        semaphore.release();
      });
      futures.add(future);
    }

    // Wait for all in-flight downloads to finish
    await Future.wait(futures);

    if (_cancelled) {
      controller.add(TileDownloadCancelled());
    } else {
      controller.add(TileDownloadComplete(
        downloaded: downloaded,
        skipped: skipped,
        failed: failed,
        total: total,
      ));
    }

    await controller.close();
  }

  Future<TileDownloadEvent> _downloadSingleTile(
    TileCoord tile,
    String urlTemplate,
    String styleHash,
  ) async {
    final bounds = TileMathService.tileBounds(tile.x, tile.y, tile.z);

    // Build URL
    final subdomains = ['a', 'b', 'c'];
    var url = urlTemplate
        .replaceAll('{s}', subdomains[tile.x % 3])
        .replaceAll('{z}', '${tile.z}')
        .replaceAll('{x}', '${tile.x}')
        .replaceAll('{y}', '${tile.y}');

    // Download with retries
    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (_cancelled) {
        return TileFailed(tile, 'Cancelled');
      }

      try {
        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {'User-Agent': 'MeshCoreSAR/1.0'},
        );

        if (response.statusCode != 200) {
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(seconds: 1 << attempt));
            continue;
          }
          return TileFailed(tile, 'HTTP ${response.statusCode}');
        }

        // Store tile (PNG → AVIF conversion happens inside cache service)
        await _cache.putTile(
            styleHash, tile.z, tile.x, tile.y, response.bodyBytes);

        return TileDownloaded(
          north: bounds.north,
          south: bounds.south,
          east: bounds.east,
          west: bounds.west,
        );
      } catch (e) {
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
        return TileFailed(tile, e.toString());
      }
    }

    return TileFailed(tile, 'Max retries exceeded');
  }

  void dispose() {
    _cancelled = true;
    _httpClient.close();
  }
}

/// Simple counting semaphore for concurrency limiting.
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final _waitQueue = <Completer<void>>[];

  _Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
    } else {
      _currentCount--;
    }
  }
}

/// Rate limiter that ensures no more than [maxPerSecond] operations per second.
class _RateLimiter {
  final int maxPerSecond;
  final _timestamps = <DateTime>[];

  _RateLimiter(this.maxPerSecond);

  Future<void> wait() async {
    final now = DateTime.now();
    _timestamps
        .removeWhere((t) => now.difference(t) > const Duration(seconds: 1));

    if (_timestamps.length >= maxPerSecond) {
      final oldest = _timestamps.first;
      final waitTime = const Duration(seconds: 1) - now.difference(oldest);
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
      _timestamps.removeAt(0);
    }
    _timestamps.add(DateTime.now());
  }
}
