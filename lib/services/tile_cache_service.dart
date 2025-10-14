import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_tile_caching/custom_backend_api.dart';
import 'package:path_provider/path_provider.dart';
import '../models/map_layer.dart';

class TileCacheService {
  static const String _storeName = 'meshcore_sar_tiles';

  // Global flag to ensure ObjectBox is only initialized once
  static bool _objectBoxInitialized = false;
  static final _initLock = <String, Future<void>>{};

  late final FMTCStore _store;
  bool _isInitialized = false;
  bool _isDownloading = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Ensure we only initialize ObjectBox once globally
    if (!_objectBoxInitialized) {
      // Use a lock to prevent concurrent initialization attempts
      final initFuture = _initLock.putIfAbsent('objectbox', () async {
        try {
          await FMTCObjectBoxBackend().initialise();
          _objectBoxInitialized = true;
        } catch (e) {
          // Already initialized or error - that's okay
          _objectBoxInitialized = true;
        }
      });
      await initFuture;
    }

    try {
      _store = FMTCStore(_storeName);
      await _store.manage.create();
      _isInitialized = true;
    } catch (e) {
      // Store might already exist
      _store = FMTCStore(_storeName);
      _isInitialized = true;
    }
  }

  FMTCTileProvider getTileProvider(MapLayer layer) {
    if (!_isInitialized) {
      throw StateError('TileCacheService not initialized. Call initialize() first.');
    }
    return _store.getTileProvider(
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      cachedValidDuration: const Duration(days: 30),
    );
  }

  Future<void> downloadRegion({
    required MapLayer layer,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw StateError('TileCacheService not initialized. Call initialize() first.');
    }

    if (_isDownloading) {
      throw StateError('A download is already in progress. Cancel it first.');
    }

    _isDownloading = true;

    try {
      final region = RectangleRegion(bounds);

      final downloadable = region.toDownloadable(
        minZoom: minZoom,
        maxZoom: maxZoom,
        options: TileLayer(
          urlTemplate: layer.urlTemplate,
        ),
      );

      final download = _store.download.startForeground(
        region: downloadable,
      );

      await for (final progress in download.downloadProgress) {
        if (onProgress != null && progress.maxTilesCount > 0) {
          // Use attemptedTilesCount instead of successfulTilesCount
          // attemptedTilesCount includes successful + buffered + skipped tiles
          final percentage = progress.percentageProgress;
          print('Download progress: ${progress.attemptedTilesCount}/${progress.maxTilesCount} = ${percentage.toStringAsFixed(1)}% (successful: ${progress.successfulTilesCount}, buffered: ${progress.bufferedTilesCount}, skipped: ${progress.skippedTilesCount})');
          onProgress(percentage);
        }
      }
    } finally {
      _isDownloading = false;
    }
  }

  Future<void> cancelDownload() async {
    if (!_isInitialized) return;
    await _store.download.cancel();
  }

  Future<void> clearCache() async {
    if (!_isInitialized) return;
    await _store.manage.delete();
    await _store.manage.create();
  }

  Future<int> getCachedTileCount() async {
    if (!_isInitialized) return 0;
    final stats = await _store.stats.length;
    return stats;
  }

  Future<double> getCacheSizeMB() async {
    if (!_isInitialized) return 0.0;
    final stats = await _store.stats.size;
    return stats / (1024 * 1024);
  }

  Future<String> exportCache() async {
    if (!_isInitialized) {
      throw StateError('TileCacheService not initialized. Call initialize() first.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportPath = '${directory.path}/meshcore_maps_$timestamp.fmtc';

    // Export using FMTCBackendAccess
    await FMTCBackendAccess.internal.exportStores(
      storeNames: [_storeName],
      path: exportPath,
    );

    return exportPath;
  }

  Future<void> importCache(String filePath) async {
    if (!_isInitialized) {
      throw StateError('TileCacheService not initialized. Call initialize() first.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file not found: $filePath');
    }

    // Import using FMTCBackendAccess
    await FMTCBackendAccess.internal.importStores(
      storeNames: [_storeName],
      path: filePath,
      strategy: ImportConflictStrategy.rename,
    );
  }

  Future<List<String>> getAvailableStores() async {
    if (!_isInitialized) {
      throw StateError('TileCacheService not initialized. Call initialize() first.');
    }

    final stores = await FMTCRoot.stats.storesAvailable;
    return stores.map((store) => store.storeName).toList();
  }

  Future<Map<String, dynamic>> getStoreStats() async {
    if (!_isInitialized) return {};

    final length = await _store.stats.length;
    final size = await _store.stats.size;

    return {
      'tileCount': length,
      'sizeMB': size / (1024 * 1024),
      'storeName': _storeName,
    };
  }

  void dispose() {
    _isInitialized = false;
  }
}
