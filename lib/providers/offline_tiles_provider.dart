import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_layer.dart';
import '../services/offline_tile_cache_service.dart';
import '../services/tile_download_service.dart';
import '../services/tile_math_service.dart';
import '../services/tile_sharing_service.dart';

export '../services/tile_sharing_service.dart' show TilePeer, PeerCatalog;
export '../services/offline_tile_cache_service.dart'
    show StyleInfo, DownloadRegion;

/// Download progress state.
class DownloadProgress {
  final int downloaded;
  final int skipped;
  final int failed;
  final int total;

  const DownloadProgress({
    this.downloaded = 0,
    this.skipped = 0,
    this.failed = 0,
    this.total = 0,
  });

  int get processed => downloaded + skipped + failed;
  double get percent => total == 0 ? 0 : processed / total;
  bool get isComplete => total > 0 && processed >= total;
}

/// A downloaded/skipped tile rectangle for map overlay.
class TileOverlay {
  final double north, south, east, west;
  final bool isSkipped;

  const TileOverlay({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    this.isSkipped = false,
  });
}

/// Drawing mode for polygon selection.
enum DrawingMode { none, polygon, rectangle }

/// State management for offline tile downloading.
class OfflineTilesProvider extends ChangeNotifier {
  final OfflineTileCacheService _cache = OfflineTileCacheService.instance;
  final TileSharingService _sharing = TileSharingService.instance;
  TileDownloadService? _downloadService;
  StreamSubscription<TileDownloadEvent>? _downloadSubscription;
  StreamSubscription<Set<TilePeer>>? _peersSubscription;

  // Drawing state
  DrawingMode _drawingMode = DrawingMode.none;
  DrawingMode _downloadSelectionMode = DrawingMode.none;
  final List<List<LatLng>> _polygons = [];
  List<LatLng> _currentVertices = [];
  LatLng? _rectangleFirstCorner;

  // Download settings
  int _minZoom = 8;
  int _maxZoom = 14;
  MapLayer _selectedLayer = MapLayer.openStreetMap;

  // Download progress
  bool _isDownloading = false;
  DownloadProgress _progress = const DownloadProgress();
  final List<TileOverlay> _tileOverlays = [];

  // Cache info
  int _cacheSizeBytes = 0;

  // Sharing state
  bool _isServerRunning = false;
  Set<TilePeer> _discoveredPeers = {};
  List<PeerCatalog> _peerCatalogs = [];
  bool _isFetchingCatalogs = false;
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0;

  // Local style info
  List<StyleInfo> _localStyles = [];

  // Coverage overlay — which cached style's tiles to show on the map
  StyleInfo? _coverageStyle;
  List<TileOverlay> _coverageOverlays = [];

  // Getters
  DrawingMode get drawingMode => _drawingMode;
  DrawingMode get downloadSelectionMode => _downloadSelectionMode;
  List<List<LatLng>> get polygons => List.unmodifiable(_polygons);
  List<LatLng> get currentVertices => List.unmodifiable(_currentVertices);
  LatLng? get rectangleFirstCorner => _rectangleFirstCorner;
  int get minZoom => _minZoom;
  int get maxZoom => _maxZoom;
  MapLayer get selectedLayer => _selectedLayer;
  bool get isDownloading => _isDownloading;
  DownloadProgress get progress => _progress;
  List<TileOverlay> get tileOverlays => _tileOverlays;
  int get cacheSizeBytes => _cacheSizeBytes;
  bool get hasPolygons => _polygons.isNotEmpty;
  bool get isServerRunning => _isServerRunning;
  Set<TilePeer> get discoveredPeers => _discoveredPeers;
  List<PeerCatalog> get peerCatalogs => _peerCatalogs;
  bool get isFetchingCatalogs => _isFetchingCatalogs;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  double get syncProgress => _syncProgress;
  List<StyleInfo> get localStyles => _localStyles;
  StyleInfo? get coverageStyle => _coverageStyle;
  List<TileOverlay> get coverageOverlays => _coverageOverlays;

  /// Estimated tile count for the current selection.
  int get estimatedTileCount {
    if (_polygons.isEmpty) return 0;
    return TileMathService.estimateTileCount(_polygons, _minZoom, _maxZoom);
  }

  // Drawing methods

  void setDrawingMode(DrawingMode mode) {
    _drawingMode = mode;
    _currentVertices = [];
    _rectangleFirstCorner = null;
    notifyListeners();
  }

  void startDownloadSelectionMode(DrawingMode mode) {
    _polygons.clear();
    _currentVertices = [];
    _rectangleFirstCorner = null;
    _downloadSelectionMode = mode;
    _drawingMode = mode;
    notifyListeners();
  }

  void addVertex(LatLng point) {
    if (_drawingMode == DrawingMode.polygon) {
      _currentVertices = [..._currentVertices, point];
      notifyListeners();
    } else if (_drawingMode == DrawingMode.rectangle) {
      if (_rectangleFirstCorner == null) {
        _rectangleFirstCorner = point;
        notifyListeners();
      } else {
        // Complete rectangle
        final corner1 = _rectangleFirstCorner!;
        final corner2 = point;
        final rect = [
          LatLng(corner1.latitude, corner1.longitude),
          LatLng(corner1.latitude, corner2.longitude),
          LatLng(corner2.latitude, corner2.longitude),
          LatLng(corner2.latitude, corner1.longitude),
        ];
        _polygons.add(rect);
        _rectangleFirstCorner = null;
        _drawingMode = DrawingMode.none;
        notifyListeners();
      }
    }
  }

  void finishPolygon() {
    if (_drawingMode == DrawingMode.polygon && _currentVertices.length >= 3) {
      _polygons.add(List.from(_currentVertices));
      _currentVertices = [];
      _drawingMode = DrawingMode.none;
      notifyListeners();
    }
  }

  void removePolygon(int index) {
    if (index >= 0 && index < _polygons.length) {
      _polygons.removeAt(index);
      notifyListeners();
    }
  }

  void clearPolygons() {
    _polygons.clear();
    _currentVertices = [];
    _rectangleFirstCorner = null;
    _drawingMode = DrawingMode.none;
    notifyListeners();
  }

  void setCurrentViewBounds({
    required double north,
    required double south,
    required double east,
    required double west,
  }) {
    _polygons
      ..clear()
      ..add([
        LatLng(north, west),
        LatLng(north, east),
        LatLng(south, east),
        LatLng(south, west),
      ]);
    _currentVertices = [];
    _rectangleFirstCorner = null;
    _downloadSelectionMode = DrawingMode.none;
    _drawingMode = DrawingMode.none;
    notifyListeners();
  }

  void undoLastVertex() {
    if (_currentVertices.isNotEmpty) {
      _currentVertices = _currentVertices.sublist(0, _currentVertices.length - 1);
      notifyListeners();
    }
  }

  // Download settings

  void setMinZoom(int zoom) {
    _minZoom = zoom.clamp(0, 19);
    if (_maxZoom < _minZoom) _maxZoom = _minZoom;
    notifyListeners();
  }

  void setMaxZoom(int zoom) {
    _maxZoom = zoom.clamp(0, 19);
    if (_minZoom > _maxZoom) _minZoom = _maxZoom;
    notifyListeners();
  }

  void setSelectedLayer(MapLayer layer) {
    _selectedLayer = layer;
    notifyListeners();
  }

  void setSelectedLayerIfDifferent(MapLayer layer) {
    if (_selectedLayer.type == layer.type &&
        _selectedLayer.urlTemplate == layer.urlTemplate) {
      return;
    }
    _selectedLayer = layer;
    notifyListeners();
  }

  // Download control

  Future<void> startDownload() async {
    if (_isDownloading || _polygons.isEmpty) return;

    _isDownloading = true;
    _progress = const DownloadProgress();
    _tileOverlays.clear();
    notifyListeners();

    _downloadService = TileDownloadService();
    final stream = _downloadService!.downloadTiles(
      polygons: _polygons,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      urlTemplate: _selectedLayer.urlTemplate,
      displayName: _selectedLayer.name,
    );

    await for (final event in stream) {
      switch (event) {
        case TileDownloadStarted(:final totalTiles):
          _progress = DownloadProgress(total: totalTiles);
          notifyListeners();

        case TileDownloaded(:final north, :final south, :final east, :final west):
          _progress = DownloadProgress(
            downloaded: _progress.downloaded + 1,
            skipped: _progress.skipped,
            failed: _progress.failed,
            total: _progress.total,
          );
          _addOverlay(TileOverlay(
            north: north, south: south, east: east, west: west,
          ));
          notifyListeners();

        case TileSkipped():
          _progress = DownloadProgress(
            downloaded: _progress.downloaded,
            skipped: _progress.skipped + 1,
            failed: _progress.failed,
            total: _progress.total,
          );
          notifyListeners();

        case TileBatchSkipped(:final count):
          _progress = DownloadProgress(
            downloaded: _progress.downloaded,
            skipped: _progress.skipped + count,
            failed: _progress.failed,
            total: _progress.total,
          );
          notifyListeners();

        case TileFailed():
          _progress = DownloadProgress(
            downloaded: _progress.downloaded,
            skipped: _progress.skipped,
            failed: _progress.failed + 1,
            total: _progress.total,
          );
          notifyListeners();

        case TileDownloadComplete():
          _isDownloading = false;
          _tileOverlays.clear();
          notifyListeners();

        case TileDownloadCancelled():
          _isDownloading = false;
          _tileOverlays.clear();
          notifyListeners();
      }
    }

    _isDownloading = false;
    _downloadService?.dispose();
    _downloadService = null;
    notifyListeners();
  }

  void cancelDownload() {
    _downloadService?.cancel();
  }

  void clearOverlays() {
    _tileOverlays.clear();
    notifyListeners();
  }

  void _addOverlay(TileOverlay overlay) {
    _tileOverlays.add(overlay);
    // Limit overlays to prevent OOM
    if (_tileOverlays.length > 500) {
      _tileOverlays.removeRange(0, _tileOverlays.length - 500);
    }
  }

  // Cache management

  Future<void> refreshCacheSize() async {
    _cacheSizeBytes = await _cache.getCacheSize();
    notifyListeners();
  }

  Future<void> deleteStyle(StyleInfo style) async {
    if (_coverageStyle?.hash == style.hash) hideCoverage();
    await _cache.deleteStyle(style.hash);
    await refreshCacheSize();
    await refreshLocalStyles();
  }

  Future<void> clearCache() async {
    hideCoverage();
    await _cache.clearCache();
    _cacheSizeBytes = 0;
    _localStyles = [];
    notifyListeners();
  }

  // Coverage overlay — show cached tile bounds on the map

  /// Show the coverage of a cached style on the map.
  /// Loads tile coordinates from the manifest and converts to bounds.
  Future<void> showCoverage(StyleInfo style) async {
    if (_coverageStyle?.hash == style.hash) {
      // Toggle off if same style tapped again
      hideCoverage();
      return;
    }

    _coverageStyle = style;
    _coverageOverlays = [];
    notifyListeners();

    final tiles = await _cache.listTilesForStyle(style.hash);

    // Convert cached tile coordinates to bound overlays
    final overlays = <TileOverlay>[];
    for (final tile in tiles) {
      final bounds = TileMathService.tileBounds(tile.x, tile.y, tile.z);
      overlays.add(TileOverlay(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
        isSkipped: true, // green color
      ));
    }

    _coverageOverlays = overlays;
    notifyListeners();
  }

  void hideCoverage() {
    _coverageStyle = null;
    _coverageOverlays = [];
    notifyListeners();
  }

  // Sharing controls

  Future<void> toggleServer() async {
    if (_isServerRunning) {
      await _sharing.stopServer();
      _isServerRunning = false;
    } else {
      await _sharing.startServer();
      _isServerRunning = _sharing.isRunning;
    }
    notifyListeners();
  }

  Future<void> startPeerDiscovery() async {
    _peersSubscription?.cancel();
    _peersSubscription = _sharing.peersStream.listen((peers) {
      _discoveredPeers = peers;
      notifyListeners();
    });
    await _sharing.startDiscovery();
  }

  Future<void> stopPeerDiscovery() async {
    _peersSubscription?.cancel();
    _peersSubscription = null;
    await _sharing.stopPeerDiscovery();
    _discoveredPeers = {};
    notifyListeners();
  }

  void addManualPeer(String ipAddress) {
    _sharing.addManualPeer(ipAddress);
    _discoveredPeers = _sharing.discoveredPeers;
    notifyListeners();
  }

  void removePeer(TilePeer peer) {
    _sharing.removePeer(peer);
    _discoveredPeers = _sharing.discoveredPeers;
    notifyListeners();
  }

  // Peer catalog & P2P sync

  /// Refresh local style info.
  Future<void> refreshLocalStyles() async {
    _localStyles = await _cache.listStylesDetailed();
    notifyListeners();
  }

  /// Fetch catalogs from all discovered peers to see what they have.
  Future<void> refreshPeerCatalogs() async {
    _isFetchingCatalogs = true;
    notifyListeners();

    _peerCatalogs = await _sharing.fetchAllPeerCatalogs();
    _isFetchingCatalogs = false;
    notifyListeners();
  }

  /// Sync a style from one or more peers that have it.
  /// Finds all peers offering [styleHash] and pulls missing tiles.
  Future<void> syncStyleFromPeers(StyleInfo style) async {
    if (_isSyncing) return;

    // Find all peers that have this style
    final peersWithStyle = <TilePeer>[];
    for (final catalog in _peerCatalogs) {
      if (catalog.styles.any((s) => s.hash == style.hash)) {
        peersWithStyle.add(catalog.peer);
      }
    }
    if (peersWithStyle.isEmpty) return;

    _isSyncing = true;
    _syncStatus = 'Starting sync of ${style.displayName}...';
    _syncProgress = 0;
    notifyListeners();

    final stream = _sharing.syncStyleFromPeers(
      peers: peersWithStyle,
      styleHash: style.hash,
      styleMeta: style,
    );

    await for (final event in stream) {
      switch (event) {
        case PeerSyncStarted(:final totalTiles):
          _syncStatus = 'Syncing ${style.displayName}: 0/$totalTiles tiles';
          _syncProgress = 0;
          notifyListeners();

        case PeerSyncTileDownloaded(:final downloaded, :final total):
          _syncStatus =
              'Syncing ${style.displayName}: $downloaded/$total tiles';
          _syncProgress = total > 0 ? downloaded / total : 0;
          notifyListeners();

        case PeerSyncTileSkipped(:final skipped, :final total):
          _syncProgress = total > 0 ? skipped / total : 0;
          notifyListeners();

        case PeerSyncComplete(:final downloaded, :final skipped, :final failed):
          _syncStatus =
              'Done! $downloaded new, $skipped cached, $failed failed';
          _isSyncing = false;
          notifyListeners();
          await refreshCacheSize();
          await refreshLocalStyles();

        case PeerSyncCancelled():
          _syncStatus = 'Sync cancelled';
          _isSyncing = false;
          notifyListeners();
      }
    }
  }

  void cancelSync() {
    _sharing.cancelSync();
  }

  // Presets — load a previously downloaded region for quick re-download

  /// Load a saved download region as the current selection.
  /// Restores polygons, zoom range, and map layer.
  void loadPreset(StyleInfo style) {
    if (style.region == null) return;

    final region = style.region!;

    // Restore polygons
    _polygons.clear();
    for (final polyData in region.polygons) {
      final poly = polyData.map((v) => LatLng(v[0], v[1])).toList();
      if (poly.length >= 3) _polygons.add(poly);
    }

    // Restore zoom range
    _minZoom = region.minZoom;
    _maxZoom = region.maxZoom;

    // Try to find the matching map layer
    if (style.urlTemplate.isNotEmpty) {
      final matchingLayer = MapLayer.allLayers.where(
        (l) => l.urlTemplate == style.urlTemplate,
      );
      if (matchingLayer.isNotEmpty) {
        _selectedLayer = matchingLayer.first;
      }
    }

    _currentVertices = [];
    _rectangleFirstCorner = null;
    _drawingMode = DrawingMode.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _downloadService?.dispose();
    _peersSubscription?.cancel();
    super.dispose();
  }
}
