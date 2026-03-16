import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_map_config.dart';
import '../models/location_trail.dart';
import '../models/map_coordinate_space.dart';
import '../models/map_drawing.dart';
import '../models/sar_marker.dart';
import '../services/profiles_feature_service.dart';
import '../utils/custom_map_id.dart';

class MapProvider with ChangeNotifier {
  static const String _customMapConfigKey = 'custom_map_config_v1';
  static const String _customMapModeKey = 'custom_map_mode_v1';
  static const String _customMapsDirName = 'custom_maps';

  MapProvider() {
    unawaited(_loadInitialState());
  }

  final ImagePicker _imagePicker = ImagePicker();

  LatLng? _targetLocation;
  LatLngBounds? _targetBounds;
  double? _targetZoom;
  bool _shouldAnimate = false;
  MapCoordinateSpace _targetCoordinateSpace = MapCoordinateSpace.geo;
  String? _targetMapId;

  final Set<String> _visibleContactPaths = {};

  LocationTrail? _currentTrail;
  bool _isTrailVisible = true;
  final List<LocationTrail> _trailHistory = [];

  bool _showCadastralOverlay = false;
  bool _showForestRoadsOverlay = false;
  bool _showHikingTrailsOverlay = false;
  bool _showMainRoadsOverlay = false;
  bool _showHouseNumbersOverlay = false;
  bool _showFireHazardZonesOverlay = false;
  bool _showHistoricalFiresOverlay = false;
  bool _showFirebreaksOverlay = false;
  bool _showKrasFireZonesOverlay = false;
  bool _showPlaceNamesOverlay = false;
  bool _showMunicipalityBordersOverlay = false;

  bool _showAllContactTrails = true;
  bool _hideRepeatersOnMap = false;

  LocationTrail? _importedTrail;

  bool _isSelectingDownloadArea = false;
  LatLngBounds? _downloadAreaBounds;

  CustomMapConfig? _customMapConfig;
  bool _isUsingCustomMap = false;

  LatLng? get targetLocation => _targetLocation;
  LatLngBounds? get targetBounds => _targetBounds;
  double? get targetZoom => _targetZoom;
  bool get shouldAnimate => _shouldAnimate;
  MapCoordinateSpace get targetCoordinateSpace => _targetCoordinateSpace;
  String? get targetMapId => _targetMapId;
  Set<String> get visibleContactPaths => Set.unmodifiable(_visibleContactPaths);

  LocationTrail? get currentTrail => _currentTrail;
  bool get isTrailVisible => _isTrailVisible;
  List<LocationTrail> get trailHistory => List.unmodifiable(_trailHistory);
  bool get isTrailActive => _currentTrail?.isActive ?? false;

  bool get showCadastralOverlay => _showCadastralOverlay;
  bool get showForestRoadsOverlay => _showForestRoadsOverlay;
  bool get showHikingTrailsOverlay => _showHikingTrailsOverlay;
  bool get showMainRoadsOverlay => _showMainRoadsOverlay;
  bool get showHouseNumbersOverlay => _showHouseNumbersOverlay;
  bool get showFireHazardZonesOverlay => _showFireHazardZonesOverlay;
  bool get showHistoricalFiresOverlay => _showHistoricalFiresOverlay;
  bool get showFirebreaksOverlay => _showFirebreaksOverlay;
  bool get showKrasFireZonesOverlay => _showKrasFireZonesOverlay;
  bool get showPlaceNamesOverlay => _showPlaceNamesOverlay;
  bool get showMunicipalityBordersOverlay => _showMunicipalityBordersOverlay;

  bool get showAllContactTrails => _showAllContactTrails;
  bool get hideRepeatersOnMap => _hideRepeatersOnMap;

  LocationTrail? get importedTrail => _importedTrail;

  bool get isSelectingDownloadArea => _isSelectingDownloadArea;
  LatLngBounds? get downloadAreaBounds => _downloadAreaBounds;

  CustomMapConfig? get customMapConfig => _customMapConfig;
  bool get hasCustomMap => _customMapConfig != null;
  bool get isUsingCustomMap => _isUsingCustomMap && _customMapConfig != null;
  bool get shouldHideGpsData => isUsingCustomMap;

  LatLngBounds? get customMapBounds => _customMapConfig?.bounds;

  Future<void> reloadProfileScopedState() async {
    await _loadInitialState();
  }

  bool matchesActiveCustomMap(String? mapId) {
    return hasCustomMap &&
        normalizeCustomMapId(_customMapConfig!.mapId) ==
            normalizeCustomMapId(mapId);
  }

  void navigateToLocation({
    required LatLng location,
    double zoom = 15.0,
    bool animate = true,
  }) {
    if (_isUsingCustomMap) {
      _isUsingCustomMap = false;
      unawaited(_saveCustomMapState());
    }
    _targetLocation = location;
    _targetBounds = null;
    _targetZoom = zoom;
    _shouldAnimate = animate;
    _targetCoordinateSpace = MapCoordinateSpace.geo;
    _targetMapId = null;
    notifyListeners();
  }

  String? navigateToMapPoint({
    required LatLng point,
    required MapCoordinateSpace coordinateSpace,
    String? mapId,
    double zoom = 15.0,
    bool animate = true,
  }) {
    if (coordinateSpace == MapCoordinateSpace.customMap) {
      if (!matchesActiveCustomMap(mapId)) {
        return 'Load the matching custom map to view this item.';
      }
      if (!_isUsingCustomMap) {
        _isUsingCustomMap = true;
        unawaited(_saveCustomMapState());
      }
    } else if (_isUsingCustomMap) {
      _isUsingCustomMap = false;
      unawaited(_saveCustomMapState());
    }

    _targetLocation = point;
    _targetBounds = null;
    _targetZoom = zoom;
    _shouldAnimate = animate;
    _targetCoordinateSpace = coordinateSpace;
    _targetMapId = mapId;
    notifyListeners();
    return null;
  }

  String? navigateToBounds({
    required LatLngBounds bounds,
    required MapCoordinateSpace coordinateSpace,
    String? mapId,
    bool animate = true,
  }) {
    if (coordinateSpace == MapCoordinateSpace.customMap) {
      if (!matchesActiveCustomMap(mapId)) {
        return 'Load the matching custom map to view this item.';
      }
      if (!_isUsingCustomMap) {
        _isUsingCustomMap = true;
        unawaited(_saveCustomMapState());
      }
    } else if (_isUsingCustomMap) {
      _isUsingCustomMap = false;
      unawaited(_saveCustomMapState());
    }

    _targetBounds = bounds;
    _targetLocation = bounds.center;
    _targetZoom = null;
    _shouldAnimate = animate;
    _targetCoordinateSpace = coordinateSpace;
    _targetMapId = mapId;
    notifyListeners();
    return null;
  }

  void clearNavigation() {
    _targetLocation = null;
    _targetBounds = null;
    _targetZoom = null;
    _shouldAnimate = false;
    _targetCoordinateSpace = MapCoordinateSpace.geo;
    _targetMapId = null;
  }

  String? navigateToDrawing(String drawingId, dynamic drawingProvider) {
    final drawing = drawingProvider.getDrawingById(drawingId) as MapDrawing?;
    if (drawing == null) {
      return 'Drawing not found.';
    }

    if (drawing.coordinateSpace == MapCoordinateSpace.customMap) {
      if (!matchesActiveCustomMap(drawing.mapId)) {
        return 'Load the matching custom map to view this drawing.';
      }
      return navigateToBounds(
        bounds: drawing.getBounds(),
        coordinateSpace: drawing.coordinateSpace,
        mapId: drawing.mapId,
      );
    }

    final bounds = drawing.getBounds();
    final latDiff = (bounds.north - bounds.south).abs();
    final lonDiff = (bounds.east - bounds.west).abs();
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    double zoom = 15.0;
    if (maxDiff < 0.001) {
      zoom = 17.0;
    } else if (maxDiff < 0.005) {
      zoom = 16.0;
    } else if (maxDiff < 0.01) {
      zoom = 15.0;
    } else if (maxDiff < 0.05) {
      zoom = 13.0;
    } else if (maxDiff < 0.1) {
      zoom = 12.0;
    } else {
      zoom = 10.0;
    }

    navigateToLocation(
      location: drawing.getCenter(),
      zoom: zoom,
      animate: true,
    );
    return null;
  }

  String? navigateToSarMarker(SarMarker marker) {
    if (marker.coordinateSpace == MapCoordinateSpace.customMap) {
      return navigateToMapPoint(
        point: marker.location,
        coordinateSpace: MapCoordinateSpace.customMap,
        mapId: marker.mapId,
      );
    }
    navigateToLocation(location: marker.location, zoom: 15.0, animate: true);
    return null;
  }

  Future<bool> loadCustomMapFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return false;
    }
    final bytes = await picked.readAsBytes();
    await setCustomMapImage(bytes: bytes, displayName: picked.name);
    return true;
  }

  Future<void> replaceCustomMap() async {
    await loadCustomMapFromGallery();
  }

  Future<void> setCustomMapImage({
    required Uint8List bytes,
    required String displayName,
  }) async {
    final dimensions = await _decodeImageSize(bytes);
    final mapId = normalizeCustomMapId(sha256.convert(bytes).toString())!;
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/$_customMapsDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final extension = _normalizedExtension(displayName);
    final nextPath = '${dir.path}/custom_map_$mapId.$extension';
    final nextFile = File(nextPath);
    await nextFile.writeAsBytes(bytes, flush: true);

    final previousPath = _customMapConfig?.filePath;
    _customMapConfig = CustomMapConfig(
      filePath: nextPath,
      displayName: displayName,
      mapId: mapId,
      imageWidth: dimensions.$1,
      imageHeight: dimensions.$2,
    );
    _isUsingCustomMap = true;
    await _saveCustomMapState();

    if (previousPath != null && previousPath != nextPath) {
      unawaited(_deleteFileIfExists(previousPath));
    }

    notifyListeners();
  }

  Future<void> setCustomMapCalibration({
    required LatLng pointA,
    required LatLng pointB,
    required double metersPerPixel,
  }) async {
    if (_customMapConfig == null) return;
    _customMapConfig = _customMapConfig!.copyWith(
      calibrationPointA: pointA,
      calibrationPointB: pointB,
      metersPerPixel: metersPerPixel,
    );
    await _saveCustomMapState();
    notifyListeners();
  }

  Future<void> clearCustomMapCalibration() async {
    if (_customMapConfig == null) return;
    _customMapConfig = _customMapConfig!.copyWith(
      clearMetersPerPixel: true,
      clearCalibrationPointA: true,
      clearCalibrationPointB: true,
    );
    await _saveCustomMapState();
    notifyListeners();
  }

  Future<void> removeCustomMap() async {
    final filePath = _customMapConfig?.filePath;
    _customMapConfig = null;
    _isUsingCustomMap = false;
    clearNavigation();
    await _saveCustomMapState();
    if (filePath != null) {
      await _deleteFileIfExists(filePath);
    }
    notifyListeners();
  }

  Future<void> enterCustomMapMode() async {
    if (!hasCustomMap || _isUsingCustomMap) return;
    _isUsingCustomMap = true;
    await _saveCustomMapState();
    notifyListeners();
  }

  Future<void> exitCustomMapMode() async {
    if (!_isUsingCustomMap) return;
    _isUsingCustomMap = false;
    await _saveCustomMapState();
    notifyListeners();
  }

  void updateZoom(double zoom) {
    _targetZoom = zoom;
    notifyListeners();
  }

  void toggleContactPath(String publicKeyHex) {
    if (_visibleContactPaths.contains(publicKeyHex)) {
      _visibleContactPaths.remove(publicKeyHex);
    } else {
      _visibleContactPaths.add(publicKeyHex);
    }
    notifyListeners();
  }

  bool isContactPathVisible(String publicKeyHex) {
    return _visibleContactPaths.contains(publicKeyHex);
  }

  void hideAllPaths() {
    _visibleContactPaths.clear();
    notifyListeners();
  }

  void showOnlyPath(String publicKeyHex) {
    _visibleContactPaths.clear();
    _visibleContactPaths.add(publicKeyHex);
    notifyListeners();
  }

  void startTrail() {
    if (_currentTrail != null && _currentTrail!.isActive) {
      endTrail();
    }

    _currentTrail = LocationTrail(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );
    _isTrailVisible = true;
    notifyListeners();
  }

  void addTrailPoint(LatLng position, {double? accuracy, double? speed}) {
    if (_currentTrail == null || !_currentTrail!.isActive) {
      startTrail();
    }

    _currentTrail!.addPoint(
      TrailPoint(
        position: position,
        timestamp: DateTime.now(),
        accuracy: accuracy,
        speed: speed,
      ),
    );
    notifyListeners();
  }

  void endTrail() {
    if (_currentTrail != null) {
      _currentTrail!.isActive = false;
      _currentTrail!.endTime = DateTime.now();
      if (_currentTrail!.points.isNotEmpty) {
        _trailHistory.add(_currentTrail!);
      }
      _currentTrail = null;
      notifyListeners();
    }
  }

  void toggleTrailVisibility() {
    _isTrailVisible = !_isTrailVisible;
    notifyListeners();
  }

  void clearCurrentTrail() {
    if (_currentTrail != null) {
      _currentTrail = null;
      notifyListeners();
    }
  }

  void clearAllTrails() {
    _currentTrail = null;
    _trailHistory.clear();
    notifyListeners();
  }

  double get totalTrailDistance {
    if (_currentTrail == null) return 0;
    return _currentTrail!.totalDistance;
  }

  Duration get trailDuration {
    if (_currentTrail == null) return Duration.zero;
    return _currentTrail!.duration;
  }

  Future<void> toggleCadastralOverlay() async {
    _showCadastralOverlay = !_showCadastralOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleForestRoadsOverlay() async {
    _showForestRoadsOverlay = !_showForestRoadsOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleHikingTrailsOverlay() async {
    _showHikingTrailsOverlay = !_showHikingTrailsOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleMainRoadsOverlay() async {
    _showMainRoadsOverlay = !_showMainRoadsOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleHouseNumbersOverlay() async {
    _showHouseNumbersOverlay = !_showHouseNumbersOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleFireHazardZonesOverlay() async {
    _showFireHazardZonesOverlay = !_showFireHazardZonesOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleHistoricalFiresOverlay() async {
    _showHistoricalFiresOverlay = !_showHistoricalFiresOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleFirebreaksOverlay() async {
    _showFirebreaksOverlay = !_showFirebreaksOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleKrasFireZonesOverlay() async {
    _showKrasFireZonesOverlay = !_showKrasFireZonesOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> togglePlaceNamesOverlay() async {
    _showPlaceNamesOverlay = !_showPlaceNamesOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> toggleMunicipalityBordersOverlay() async {
    _showMunicipalityBordersOverlay = !_showMunicipalityBordersOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  Future<void> loadOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    _showCadastralOverlay =
        prefs.getBool(_scopedKey('map_show_cadastral_overlay')) ?? false;
    _showForestRoadsOverlay =
        prefs.getBool(_scopedKey('map_show_forest_roads_overlay')) ?? false;
    _showHikingTrailsOverlay =
        prefs.getBool(_scopedKey('map_show_hiking_trails_overlay')) ?? false;
    _showMainRoadsOverlay =
        prefs.getBool(_scopedKey('map_show_main_roads_overlay')) ?? false;
    _showHouseNumbersOverlay =
        prefs.getBool(_scopedKey('map_show_house_numbers_overlay')) ?? false;
    _showFireHazardZonesOverlay =
        prefs.getBool(_scopedKey('map_show_fire_hazard_zones_overlay')) ??
        false;
    _showHistoricalFiresOverlay =
        prefs.getBool(_scopedKey('map_show_historical_fires_overlay')) ?? false;
    _showFirebreaksOverlay =
        prefs.getBool(_scopedKey('map_show_firebreaks_overlay')) ?? false;
    _showKrasFireZonesOverlay =
        prefs.getBool(_scopedKey('map_show_kras_fire_zones_overlay')) ?? false;
    _showPlaceNamesOverlay =
        prefs.getBool(_scopedKey('map_show_place_names_overlay')) ?? false;
    _showMunicipalityBordersOverlay =
        prefs.getBool(_scopedKey('map_show_municipality_borders_overlay')) ??
        false;
    notifyListeners();
  }

  Future<void> _loadInitialState() async {
    await Future.wait([
      loadOverlayState(),
      loadTrailSettings(),
      loadRepeaterVisibilitySettings(),
      _loadCustomMapState(),
    ]);
  }

  Future<void> _saveOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _scopedKey('map_show_cadastral_overlay'),
      _showCadastralOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_forest_roads_overlay'),
      _showForestRoadsOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_hiking_trails_overlay'),
      _showHikingTrailsOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_main_roads_overlay'),
      _showMainRoadsOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_house_numbers_overlay'),
      _showHouseNumbersOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_fire_hazard_zones_overlay'),
      _showFireHazardZonesOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_historical_fires_overlay'),
      _showHistoricalFiresOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_firebreaks_overlay'),
      _showFirebreaksOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_kras_fire_zones_overlay'),
      _showKrasFireZonesOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_place_names_overlay'),
      _showPlaceNamesOverlay,
    );
    await prefs.setBool(
      _scopedKey('map_show_municipality_borders_overlay'),
      _showMunicipalityBordersOverlay,
    );
  }

  Future<void> toggleAllContactTrails() async {
    _showAllContactTrails = !_showAllContactTrails;
    notifyListeners();
    await _saveTrailSettings();
  }

  Future<void> loadTrailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAllContactTrails =
        prefs.getBool(_scopedKey('map_show_all_contact_trails')) ?? true;
    notifyListeners();
  }

  Future<void> _saveTrailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _scopedKey('map_show_all_contact_trails'),
      _showAllContactTrails,
    );
  }

  Future<void> setHideRepeatersOnMap(bool hide) async {
    if (_hideRepeatersOnMap == hide) return;
    _hideRepeatersOnMap = hide;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey('map_hide_repeaters'), _hideRepeatersOnMap);
  }

  Future<void> loadRepeaterVisibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _hideRepeatersOnMap =
        prefs.getBool(_scopedKey('map_hide_repeaters')) ?? false;
    notifyListeners();
  }

  void setImportedTrail(LocationTrail trail) {
    _importedTrail = trail;
    notifyListeners();
  }

  void clearImportedTrail() {
    _importedTrail = null;
    notifyListeners();
  }

  void replaceCurrentTrailWithImport(LocationTrail importedTrail) {
    if (_currentTrail != null && _currentTrail!.isActive) {
      endTrail();
    }
    _currentTrail = importedTrail;
    _isTrailVisible = true;
    notifyListeners();
  }

  void enterDownloadAreaMode(LatLngBounds initialBounds) {
    _isSelectingDownloadArea = true;
    _downloadAreaBounds = initialBounds;
    notifyListeners();
  }

  void exitDownloadAreaMode() {
    _isSelectingDownloadArea = false;
    _downloadAreaBounds = null;
    notifyListeners();
  }

  void updateDownloadAreaBounds(LatLngBounds bounds) {
    _downloadAreaBounds = bounds;
    notifyListeners();
  }

  Future<void> _loadCustomMapState() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_scopedKey(_customMapConfigKey));
    if (configJson != null && configJson.isNotEmpty) {
      final decoded = jsonDecode(configJson);
      if (decoded is Map<String, dynamic>) {
        final config = CustomMapConfig.fromJson(decoded);
        if (config != null && await File(config.filePath).exists()) {
          _customMapConfig = config;
        } else {
          _customMapConfig = null;
        }
      }
    } else {
      _customMapConfig = null;
    }
    _isUsingCustomMap =
        (prefs.getBool(_scopedKey(_customMapModeKey)) ?? false) &&
        _customMapConfig != null;
    notifyListeners();
  }

  Future<void> _saveCustomMapState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_customMapConfig == null) {
      await prefs.remove(_scopedKey(_customMapConfigKey));
    } else {
      await prefs.setString(
        _scopedKey(_customMapConfigKey),
        jsonEncode(_customMapConfig!.toJson()),
      );
    }
    await prefs.setBool(_scopedKey(_customMapModeKey), _isUsingCustomMap);
  }

  Future<(int, int)> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return (frame.image.width, frame.image.height);
  }

  String _normalizedExtension(String displayName) {
    final dotIndex = displayName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == displayName.length - 1) {
      return 'png';
    }
    return displayName.substring(dotIndex + 1).toLowerCase();
  }

  Future<void> _deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Map<String, dynamic> exportWorkspaceJson() {
    return {
      'currentTrail': _currentTrail?.toJson(),
      'trailHistory': _trailHistory.map((trail) => trail.toJson()).toList(),
      'importedTrail': _importedTrail?.toJson(),
      'isTrailVisible': _isTrailVisible,
      'showCadastralOverlay': _showCadastralOverlay,
      'showForestRoadsOverlay': _showForestRoadsOverlay,
      'showHikingTrailsOverlay': _showHikingTrailsOverlay,
      'showMainRoadsOverlay': _showMainRoadsOverlay,
      'showHouseNumbersOverlay': _showHouseNumbersOverlay,
      'showFireHazardZonesOverlay': _showFireHazardZonesOverlay,
      'showHistoricalFiresOverlay': _showHistoricalFiresOverlay,
      'showFirebreaksOverlay': _showFirebreaksOverlay,
      'showKrasFireZonesOverlay': _showKrasFireZonesOverlay,
      'showPlaceNamesOverlay': _showPlaceNamesOverlay,
      'showMunicipalityBordersOverlay': _showMunicipalityBordersOverlay,
      'showAllContactTrails': _showAllContactTrails,
      'hideRepeatersOnMap': _hideRepeatersOnMap,
    };
  }

  void applyWorkspaceJson(Map<String, dynamic> json) {
    _currentTrail = json['currentTrail'] is Map<String, dynamic>
        ? LocationTrail.fromJson(json['currentTrail'] as Map<String, dynamic>)
        : null;
    _trailHistory
      ..clear()
      ..addAll(
        (json['trailHistory'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LocationTrail.fromJson),
      );
    _importedTrail = json['importedTrail'] is Map<String, dynamic>
        ? LocationTrail.fromJson(json['importedTrail'] as Map<String, dynamic>)
        : null;
    _isTrailVisible = json['isTrailVisible'] as bool? ?? true;
    _showCadastralOverlay = json['showCadastralOverlay'] as bool? ?? false;
    _showForestRoadsOverlay = json['showForestRoadsOverlay'] as bool? ?? false;
    _showHikingTrailsOverlay =
        json['showHikingTrailsOverlay'] as bool? ?? false;
    _showMainRoadsOverlay = json['showMainRoadsOverlay'] as bool? ?? false;
    _showHouseNumbersOverlay =
        json['showHouseNumbersOverlay'] as bool? ?? false;
    _showFireHazardZonesOverlay =
        json['showFireHazardZonesOverlay'] as bool? ?? false;
    _showHistoricalFiresOverlay =
        json['showHistoricalFiresOverlay'] as bool? ?? false;
    _showFirebreaksOverlay = json['showFirebreaksOverlay'] as bool? ?? false;
    _showKrasFireZonesOverlay =
        json['showKrasFireZonesOverlay'] as bool? ?? false;
    _showPlaceNamesOverlay = json['showPlaceNamesOverlay'] as bool? ?? false;
    _showMunicipalityBordersOverlay =
        json['showMunicipalityBordersOverlay'] as bool? ?? false;
    _showAllContactTrails = json['showAllContactTrails'] as bool? ?? true;
    _hideRepeatersOnMap = json['hideRepeatersOnMap'] as bool? ?? false;
    notifyListeners();
  }

  String _scopedKey(String baseKey) {
    return ProfileStorageScope.scopedKey(baseKey);
  }
}
