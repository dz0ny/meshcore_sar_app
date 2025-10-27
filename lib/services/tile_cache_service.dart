import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:mbtiles/mbtiles.dart';
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
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
    }
    return _store.getTileProvider(
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
      cachedValidDuration: const Duration(days: 30),
    );
  }

  /// Get tile provider for WMS layers with caching support
  /// WMS layers require special handling because they use WMSTileLayerOptions
  FMTCTileProvider getTileProviderForWms(MapLayer layer) {
    if (!_isInitialized) {
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
    }
    if (!layer.isWms) {
      throw ArgumentError('Layer must be a WMS layer');
    }

    // Return the same cached tile provider
    // The WMS URL construction is handled by flutter_map's WMSTileLayerOptions
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
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
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
        options: TileLayer(urlTemplate: layer.urlTemplate),
      );

      final download = _store.download.startForeground(region: downloadable);

      await for (final progress in download.downloadProgress) {
        if (onProgress != null && progress.maxTilesCount > 0) {
          // Use attemptedTilesCount instead of successfulTilesCount
          // attemptedTilesCount includes successful + buffered + skipped tiles
          final percentage = progress.percentageProgress;
          debugPrint(
            'Download progress: ${progress.attemptedTilesCount}/${progress.maxTilesCount} = ${percentage.toStringAsFixed(1)}% (successful: ${progress.successfulTilesCount}, buffered: ${progress.bufferedTilesCount}, skipped: ${progress.skippedTilesCount})',
          );
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

  Future<List<String>> getAvailableStores() async {
    if (!_isInitialized) {
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
    }

    final stores = await FMTCRoot.stats.storesAvailable;
    return stores.map((store) => store.storeName).toList();
  }

  Future<Map<String, dynamic>> getStoreStats() async {
    if (!_isInitialized) return {};

    final length = await _store.stats.length;
    final size = await _store.stats.all.then((a) => a.size);

    return {
      'tileCount': length,
      'sizeMB': size / 1024,
      'storeName': _storeName,
    };
  }

  /// Get vector tile provider for MBTiles layers
  MbTilesVectorTileProvider? getVectorTileProvider(MapLayer layer) {
    if (!layer.isVector || layer.mbtilesFile == null) {
      return null;
    }

    try {
      final mbtiles = MbTiles(
        mbtilesPath: layer.mbtilesFile!.path,
        gzip: layer.isGzipped ?? false,
      );

      return MbTilesVectorTileProvider(
        mbtiles: mbtiles,
        silenceTileNotFound: true,
      );
    } catch (e) {
      debugPrint('Error creating vector tile provider: $e');
      return null;
    }
  }

  /// Export the current tile cache store to an archive file
  ///
  /// [outputPath] - Full path where the archive should be saved (e.g., '/path/to/export.fmtc')
  ///
  /// Returns the number of tiles exported
  Future<int> exportStore(String outputPath) async {
    if (!_isInitialized) {
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
    }

    try {
      final external = FMTCRoot.external(pathToArchive: outputPath);
      final result = await external.export(storeNames: [_storeName]);

      debugPrint('Export completed: $result tiles exported to $outputPath');
      return result;
    } catch (e) {
      debugPrint('Error exporting store: $e');
      rethrow;
    }
  }

  /// Import a tile cache store from an archive file
  ///
  /// [filePath] - Path to the .fmtc archive file to import
  /// [storeNames] - Optional list of store names to import (null = import all)
  /// [strategy] - Conflict resolution strategy (default: merge)
  ///
  /// Returns a map with import statistics (e.g., tile count, stores imported)
  Future<Map<String, dynamic>> importStore(
    String filePath, {
    List<String>? storeNames,
    ImportConflictStrategy strategy = ImportConflictStrategy.merge,
  }) async {
    if (!_isInitialized) {
      throw StateError(
        'TileCacheService not initialized. Call initialize() first.',
      );
    }

    try {
      final external = FMTCRoot.external(pathToArchive: filePath);
      final result = external.import(storeNames: storeNames, strategy: strategy);

      // Wait for the import to complete and get tile count
      final tileCount = await result.complete;

      // Wait for store states
      final storesToStates = await result.storesToStates;

      debugPrint('Import completed: $tileCount tiles imported, ${storesToStates.length} stores');

      // Count successful stores (those that weren't skipped)
      final successfulCount = storesToStates.values.where((state) => state.name != null).length;

      return {
        'successfulStores': successfulCount,
        'tileCount': tileCount,
        'storesToStates': storesToStates,
      };
    } catch (e) {
      debugPrint('Error importing store: $e');
      rethrow;
    }
  }

  /// List all stores available in an archive file without importing
  ///
  /// [filePath] - Path to the .fmtc archive file to inspect
  ///
  /// Returns a list of store names contained in the archive
  Future<List<String>> listArchiveStores(String filePath) async {
    try {
      final external = FMTCRoot.external(pathToArchive: filePath);
      final stores = await external.listStores;
      debugPrint('Archive contains ${stores.length} stores: $stores');
      return stores;
    } catch (e) {
      debugPrint('Error listing archive stores: $e');
      rethrow;
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}
