import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_trail.dart';
import '../models/map_drawing.dart';

class MapProvider with ChangeNotifier {
  LatLng? _targetLocation;
  double? _targetZoom;
  bool _shouldAnimate = false;

  // Track which contact paths are currently visible
  final Set<String> _visibleContactPaths = {};

  // Location trail tracking
  LocationTrail? _currentTrail;
  bool _isTrailVisible = true;
  final List<LocationTrail> _trailHistory = [];

  // WMS overlay toggles
  bool _showCadastralOverlay = false;
  bool _showForestRoadsOverlay = false;

  // Contact trail toggles
  bool _showAllContactTrails = false;

  // Imported trail (from GPX)
  LocationTrail? _importedTrail;

  // Download area selection
  bool _isSelectingDownloadArea = false;
  LatLngBounds? _downloadAreaBounds;

  LatLng? get targetLocation => _targetLocation;
  double? get targetZoom => _targetZoom;
  bool get shouldAnimate => _shouldAnimate;
  Set<String> get visibleContactPaths => Set.unmodifiable(_visibleContactPaths);

  // Trail getters
  LocationTrail? get currentTrail => _currentTrail;
  bool get isTrailVisible => _isTrailVisible;
  List<LocationTrail> get trailHistory => List.unmodifiable(_trailHistory);
  bool get isTrailActive => _currentTrail?.isActive ?? false;

  // WMS overlay getters
  bool get showCadastralOverlay => _showCadastralOverlay;
  bool get showForestRoadsOverlay => _showForestRoadsOverlay;

  // Contact trail getters
  bool get showAllContactTrails => _showAllContactTrails;

  // Imported trail getters
  LocationTrail? get importedTrail => _importedTrail;

  // Download area getters
  bool get isSelectingDownloadArea => _isSelectingDownloadArea;
  LatLngBounds? get downloadAreaBounds => _downloadAreaBounds;

  void navigateToLocation({
    required LatLng location,
    double zoom = 15.0,
    bool animate = true,
  }) {
    _targetLocation = location;
    _targetZoom = zoom;
    _shouldAnimate = animate;
    notifyListeners();
  }

  void clearNavigation() {
    _targetLocation = null;
    _targetZoom = null;
    _shouldAnimate = false;
    // Don't notify listeners to avoid rebuilds
  }

  /// Navigate to a drawing by its ID
  void navigateToDrawing(String drawingId, dynamic drawingProvider) {
    debugPrint('🗺️ [MapProvider] navigateToDrawing called with ID: $drawingId');
    // Find the drawing in the provider
    final drawings = drawingProvider.drawings as List;
    debugPrint('🗺️ [MapProvider] Total drawings in provider: ${drawings.length}');
    final drawing = drawings.cast<dynamic>().firstWhere(
      (d) => d.id == drawingId,
      orElse: () => null,
    );

    if (drawing == null) {
      debugPrint('⚠️ [MapProvider] Drawing $drawingId not found');
      debugPrint('⚠️ [MapProvider] Available drawing IDs: ${drawings.map((d) => d.id).toList()}');
      return;
    }

    // Use MapDrawing's built-in getCenter and getBounds methods
    final center = drawing.getCenter();
    final bounds = drawing.getBounds();

    // Calculate appropriate zoom level based on bounds
    // For larger drawings, use lower zoom to fit the whole drawing
    // For smaller drawings, use higher zoom for better detail
    final latDiff = (bounds.north - bounds.south).abs();
    final lonDiff = (bounds.east - bounds.west).abs();
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Zoom scale: smaller drawings get higher zoom
    // 0.001 degrees (~100m) -> zoom 17
    // 0.005 degrees (~500m) -> zoom 16
    // 0.01 degrees (~1km) -> zoom 15
    // 0.05 degrees (~5km) -> zoom 13
    // 0.1 degrees (~10km) -> zoom 12
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

    final typeStr = drawing is LineDrawing ? 'line' : 'rectangle';
    debugPrint('🗺️ [MapProvider] Navigating to drawing: $typeStr, zoom: $zoom');
    navigateToLocation(location: center, zoom: zoom, animate: true);
  }

  void updateZoom(double zoom) {
    _targetZoom = zoom;
    notifyListeners();
  }

  /// Toggle path visibility for a contact
  void toggleContactPath(String publicKeyHex) {
    if (_visibleContactPaths.contains(publicKeyHex)) {
      _visibleContactPaths.remove(publicKeyHex);
    } else {
      _visibleContactPaths.add(publicKeyHex);
    }
    notifyListeners();
  }

  /// Check if a contact's path is visible
  bool isContactPathVisible(String publicKeyHex) {
    return _visibleContactPaths.contains(publicKeyHex);
  }

  /// Hide all contact paths
  void hideAllPaths() {
    _visibleContactPaths.clear();
    notifyListeners();
  }

  /// Show path for specific contact (hide all others)
  void showOnlyPath(String publicKeyHex) {
    _visibleContactPaths.clear();
    _visibleContactPaths.add(publicKeyHex);
    notifyListeners();
  }

  /// Start a new location trail
  void startTrail() {
    // End current trail if active
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

  /// Add a point to the current trail
  void addTrailPoint(LatLng position, {double? accuracy, double? speed}) {
    if (_currentTrail == null || !_currentTrail!.isActive) {
      startTrail();
    }

    _currentTrail!.addPoint(TrailPoint(
      position: position,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      speed: speed,
    ));
    notifyListeners();
  }

  /// End the current trail
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

  /// Toggle trail visibility
  void toggleTrailVisibility() {
    _isTrailVisible = !_isTrailVisible;
    notifyListeners();
  }

  /// Clear the current trail
  void clearCurrentTrail() {
    if (_currentTrail != null) {
      _currentTrail = null;
      notifyListeners();
    }
  }

  /// Clear all trail history
  void clearAllTrails() {
    _currentTrail = null;
    _trailHistory.clear();
    notifyListeners();
  }

  /// Get total trail distance in meters
  double get totalTrailDistance {
    if (_currentTrail == null) return 0;
    return _currentTrail!.totalDistance;
  }

  /// Get trail duration
  Duration get trailDuration {
    if (_currentTrail == null) return Duration.zero;
    return _currentTrail!.duration;
  }

  /// Toggle cadastral parcels overlay
  Future<void> toggleCadastralOverlay() async {
    _showCadastralOverlay = !_showCadastralOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  /// Toggle forest roads overlay
  Future<void> toggleForestRoadsOverlay() async {
    _showForestRoadsOverlay = !_showForestRoadsOverlay;
    notifyListeners();
    await _saveOverlayState();
  }

  /// Load overlay state from SharedPreferences
  Future<void> loadOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    _showCadastralOverlay = prefs.getBool('map_show_cadastral_overlay') ?? false;
    _showForestRoadsOverlay = prefs.getBool('map_show_forest_roads_overlay') ?? false;
    notifyListeners();
  }

  /// Save overlay state to SharedPreferences
  Future<void> _saveOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_show_cadastral_overlay', _showCadastralOverlay);
    await prefs.setBool('map_show_forest_roads_overlay', _showForestRoadsOverlay);
  }

  /// Toggle all contact trails on/off
  Future<void> toggleAllContactTrails() async {
    _showAllContactTrails = !_showAllContactTrails;
    notifyListeners();
    await _saveTrailSettings();
  }

  /// Load trail settings from SharedPreferences
  Future<void> loadTrailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showAllContactTrails = prefs.getBool('map_show_all_contact_trails') ?? false;
    notifyListeners();
  }

  /// Save trail settings to SharedPreferences
  Future<void> _saveTrailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_show_all_contact_trails', _showAllContactTrails);
  }

  /// Set imported trail (from GPX import)
  void setImportedTrail(LocationTrail trail) {
    _importedTrail = trail;
    notifyListeners();
  }

  /// Clear imported trail
  void clearImportedTrail() {
    _importedTrail = null;
    notifyListeners();
  }

  /// Replace current trail with imported trail
  void replaceCurrentTrailWithImport(LocationTrail importedTrail) {
    // End current trail if active
    if (_currentTrail != null && _currentTrail!.isActive) {
      endTrail();
    }

    // Set imported trail as current trail
    _currentTrail = importedTrail;
    _isTrailVisible = true;
    notifyListeners();
  }

  /// Enter download area selection mode with initial bounds
  void enterDownloadAreaMode(LatLngBounds initialBounds) {
    _isSelectingDownloadArea = true;
    _downloadAreaBounds = initialBounds;
    notifyListeners();
  }

  /// Exit download area selection mode
  void exitDownloadAreaMode() {
    _isSelectingDownloadArea = false;
    _downloadAreaBounds = null;
    notifyListeners();
  }

  /// Update the download area bounds (while dragging/resizing)
  void updateDownloadAreaBounds(LatLngBounds bounds) {
    _downloadAreaBounds = bounds;
    notifyListeners();
  }
}
