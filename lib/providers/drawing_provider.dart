import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_drawing.dart';
import '../models/map_coordinate_space.dart';
import '../services/profiles_feature_service.dart';
import '../utils/drawing_message_parser.dart';

/// Drawing mode state
enum DrawingMode { none, line, rectangle, measure }

/// Provider for managing map drawings
class DrawingProvider with ChangeNotifier {
  static const String _storageKey = 'map_drawings';
  static const String _showReceivedDrawingsKey = 'map_show_received_drawings';
  static const String _showSarMarkersKey = 'map_show_sar_markers';

  // Drawing state
  DrawingMode _drawingMode = DrawingMode.none;
  Color _selectedColor = DrawingColors.palette[0];
  bool _showReceivedDrawings = true;
  bool _showSarMarkers = true;

  // Completed drawings
  final List<MapDrawing> _drawings = [];
  bool _isInitialized = false;

  // In-progress drawing
  MapDrawing? _currentDrawing;
  List<LatLng> _currentLinePoints = [];
  LatLng? _rectangleStartPoint;

  // Distance measurement state
  LatLng? _measurementPoint1;
  LatLng? _measurementPoint2;
  double? _measuredDistance; // in meters
  MapCoordinateSpace _activeCoordinateSpace = MapCoordinateSpace.geo;
  String? _activeMapId;
  double? _activeMetersPerPixel;

  // Getters
  DrawingMode get drawingMode => _drawingMode;
  Color get selectedColor => _selectedColor;
  bool get showReceivedDrawings => _showReceivedDrawings;
  bool get showSarMarkers => _showSarMarkers;
  MapCoordinateSpace get activeCoordinateSpace => _activeCoordinateSpace;
  String? get activeMapId => _activeMapId;
  double? get activeMetersPerPixel => _activeMetersPerPixel;
  List<MapDrawing> get drawings {
    // Filter out hidden drawings first
    var visibleDrawings = _drawings.where((d) => !d.isHidden);

    // Then filter by received status if needed
    if (!_showReceivedDrawings) {
      visibleDrawings = visibleDrawings.where((d) => !d.isReceived);
    }

    visibleDrawings = visibleDrawings.where((drawing) {
      if (drawing.coordinateSpace != _activeCoordinateSpace) {
        return false;
      }
      if (drawing.coordinateSpace == MapCoordinateSpace.customMap) {
        return drawing.mapId != null && drawing.mapId == _activeMapId;
      }
      return true;
    });

    return List.unmodifiable(visibleDrawings.toList());
  }

  MapDrawing? get currentDrawing => _currentDrawing;
  List<LatLng> get currentLinePoints => List.unmodifiable(_currentLinePoints);
  LatLng? get rectangleStartPoint => _rectangleStartPoint;
  bool get isDrawing => _drawingMode != DrawingMode.none;
  bool get isInitialized => _isInitialized;
  LatLng? get measurementPoint1 => _measurementPoint1;
  LatLng? get measurementPoint2 => _measurementPoint2;
  double? get measuredDistance => _measuredDistance;

  /// Initialize and load saved drawings
  Future<void> initialize() async {
    await _loadPreferences();
    await _loadDrawings();
    _isInitialized = true;
  }

  Future<void> reloadProfileScopedState() async {
    await _loadPreferences();
    await _loadDrawings();
    notifyListeners();
  }

  void setMapContext({
    required MapCoordinateSpace coordinateSpace,
    String? mapId,
    double? metersPerPixel,
  }) {
    final changed =
        coordinateSpace != _activeCoordinateSpace ||
        mapId != _activeMapId ||
        metersPerPixel != _activeMetersPerPixel;
    _activeCoordinateSpace = coordinateSpace;
    _activeMapId = mapId;
    _activeMetersPerPixel = metersPerPixel;
    if (_measurementPoint1 != null && _measurementPoint2 != null) {
      _measuredDistance = _calculateDistance(
        _measurementPoint1!,
        _measurementPoint2!,
      );
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Set drawing mode
  void setDrawingMode(DrawingMode mode) {
    if (_drawingMode != mode) {
      // Cancel any in-progress drawing when switching modes
      _cancelCurrentDrawing();
      _drawingMode = mode;
      notifyListeners();
    }
  }

  /// Set selected color
  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// Toggle visibility of received drawings
  Future<void> toggleReceivedDrawings() async {
    _showReceivedDrawings = !_showReceivedDrawings;
    notifyListeners();
    await _savePreferences();
  }

  /// Toggle visibility of SAR markers
  Future<void> toggleSarMarkers() async {
    _showSarMarkers = !_showSarMarkers;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showReceivedDrawings =
        prefs.getBool(_scopedKey(_showReceivedDrawingsKey)) ?? true;
    _showSarMarkers = prefs.getBool(_scopedKey(_showSarMarkersKey)) ?? true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _scopedKey(_showReceivedDrawingsKey),
      _showReceivedDrawings,
    );
    await prefs.setBool(_scopedKey(_showSarMarkersKey), _showSarMarkers);
  }

  /// Start drawing a line
  void startLine(LatLng point) {
    if (_drawingMode != DrawingMode.line) return;

    _currentLinePoints = [point];
    notifyListeners();
  }

  /// Add point to current line
  void addLinePoint(LatLng point) {
    if (_drawingMode != DrawingMode.line || _currentLinePoints.isEmpty) return;

    _currentLinePoints.add(point);
    notifyListeners();
  }

  /// Complete current line drawing
  void completeLine() {
    if (_drawingMode != DrawingMode.line || _currentLinePoints.length < 2) {
      _cancelCurrentDrawing();
      return;
    }

    final drawing = LineDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      color: _selectedColor,
      createdAt: DateTime.now(),
      points: List.from(_currentLinePoints),
      coordinateSpace: _activeCoordinateSpace,
      mapId: _activeCoordinateSpace == MapCoordinateSpace.customMap
          ? _activeMapId
          : null,
    );

    _drawings.add(drawing);
    _currentLinePoints = [];
    _saveDrawings();
    notifyListeners();
  }

  /// Start drawing a rectangle
  void startRectangle(LatLng point) {
    if (_drawingMode != DrawingMode.rectangle) return;

    _rectangleStartPoint = point;
    notifyListeners();
  }

  /// Update rectangle end point (for preview)
  void updateRectangleEndPoint(LatLng endPoint) {
    if (_drawingMode != DrawingMode.rectangle || _rectangleStartPoint == null) {
      return;
    }

    // Create preview rectangle
    _currentDrawing = RectangleDrawing(
      id: 'preview',
      color: _selectedColor,
      createdAt: DateTime.now(),
      topLeft: LatLng(
        _rectangleStartPoint!.latitude > endPoint.latitude
            ? endPoint.latitude
            : _rectangleStartPoint!.latitude,
        _rectangleStartPoint!.longitude < endPoint.longitude
            ? _rectangleStartPoint!.longitude
            : endPoint.longitude,
      ),
      bottomRight: LatLng(
        _rectangleStartPoint!.latitude < endPoint.latitude
            ? endPoint.latitude
            : _rectangleStartPoint!.latitude,
        _rectangleStartPoint!.longitude > endPoint.longitude
            ? _rectangleStartPoint!.longitude
            : endPoint.longitude,
      ),
      coordinateSpace: _activeCoordinateSpace,
      mapId: _activeCoordinateSpace == MapCoordinateSpace.customMap
          ? _activeMapId
          : null,
    );
    notifyListeners();
  }

  /// Complete current rectangle drawing
  void completeRectangle(LatLng endPoint) {
    if (_drawingMode != DrawingMode.rectangle || _rectangleStartPoint == null) {
      _cancelCurrentDrawing();
      return;
    }

    // Calculate top-left and bottom-right corners
    final topLeft = LatLng(
      _rectangleStartPoint!.latitude > endPoint.latitude
          ? endPoint.latitude
          : _rectangleStartPoint!.latitude,
      _rectangleStartPoint!.longitude < endPoint.longitude
          ? _rectangleStartPoint!.longitude
          : endPoint.longitude,
    );

    final bottomRight = LatLng(
      _rectangleStartPoint!.latitude < endPoint.latitude
          ? endPoint.latitude
          : _rectangleStartPoint!.latitude,
      _rectangleStartPoint!.longitude > endPoint.longitude
          ? _rectangleStartPoint!.longitude
          : endPoint.longitude,
    );

    final drawing = RectangleDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      color: _selectedColor,
      createdAt: DateTime.now(),
      topLeft: topLeft,
      bottomRight: bottomRight,
      coordinateSpace: _activeCoordinateSpace,
      mapId: _activeCoordinateSpace == MapCoordinateSpace.customMap
          ? _activeMapId
          : null,
    );

    _drawings.add(drawing);
    _rectangleStartPoint = null;
    _currentDrawing = null;
    _saveDrawings();
    notifyListeners();
  }

  /// Set first measurement point
  void setMeasurementPoint1(LatLng point) {
    if (_drawingMode != DrawingMode.measure) return;

    _measurementPoint1 = point;
    _measurementPoint2 = null;
    _measuredDistance = null;
    notifyListeners();
  }

  /// Set second measurement point and calculate distance
  void setMeasurementPoint2(LatLng point) {
    if (_drawingMode != DrawingMode.measure || _measurementPoint1 == null) {
      return;
    }

    _measurementPoint2 = point;
    _measuredDistance = _calculateDistance(_measurementPoint1!, point);
    notifyListeners();
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    if (_activeCoordinateSpace == MapCoordinateSpace.customMap &&
        _activeMetersPerPixel != null) {
      final dy = point2.latitude - point1.latitude;
      final dx = point2.longitude - point1.longitude;
      final pixelDistance = math.sqrt((dx * dx) + (dy * dy));
      return pixelDistance * _activeMetersPerPixel!;
    }
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Clear measurement points
  void clearMeasurement() {
    _measurementPoint1 = null;
    _measurementPoint2 = null;
    _measuredDistance = null;
    notifyListeners();
  }

  /// Cancel current drawing in progress
  void _cancelCurrentDrawing() {
    _currentLinePoints = [];
    _rectangleStartPoint = null;
    _currentDrawing = null;
    _measurementPoint1 = null;
    _measurementPoint2 = null;
    _measuredDistance = null;
  }

  /// Clear current drawing (public method)
  void cancelCurrentDrawing() {
    _cancelCurrentDrawing();
    notifyListeners();
  }

  /// Remove a specific drawing
  void removeDrawing(String id) {
    _drawings.removeWhere((d) => d.id == id);
    _saveDrawings();
    notifyListeners();
  }

  /// Clear all drawings
  void clearAllDrawings() {
    _drawings.clear();
    _cancelCurrentDrawing();
    _saveDrawings();
    notifyListeners();
  }

  /// Exit drawing mode
  void exitDrawingMode() {
    _cancelCurrentDrawing();
    _drawingMode = DrawingMode.none;
    notifyListeners();
  }

  /// Save drawings to persistent storage
  Future<void> _saveDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _drawings.map((d) => d.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_scopedKey(_storageKey), jsonString);
    } catch (e) {
      debugPrint('Error saving drawings: $e');
    }
  }

  /// Load drawings from persistent storage
  Future<void> _loadDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scopedKey(_storageKey));
      if (jsonString == null || jsonString.isEmpty) {
        _drawings.clear();
        return;
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      _drawings.clear();

      for (final json in jsonList) {
        final drawing = MapDrawing.fromJson(json as Map<String, dynamic>);
        if (drawing != null) {
          _drawings.add(drawing);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading drawings: $e');
    }
  }

  /// Get the current preview drawing for rendering
  MapDrawing? getPreviewDrawing() {
    if (_drawingMode == DrawingMode.line && _currentLinePoints.length >= 2) {
      return LineDrawing(
        id: 'preview',
        color: _selectedColor,
        createdAt: DateTime.now(),
        points: _currentLinePoints,
        coordinateSpace: _activeCoordinateSpace,
        mapId: _activeCoordinateSpace == MapCoordinateSpace.customMap
            ? _activeMapId
            : null,
      );
    } else if (_drawingMode == DrawingMode.rectangle &&
        _currentDrawing != null) {
      return _currentDrawing;
    }
    return null;
  }

  /// Add received drawing from another node
  void addReceivedDrawing(MapDrawing drawing) {
    // Check if drawing with this ID already exists
    if (_drawings.any((d) => d.id == drawing.id)) {
      debugPrint('Drawing ${drawing.id} already exists, skipping');
      return;
    }

    // Mark as received when adding
    final receivedDrawing = _createReceivedCopy(drawing);
    _drawings.add(receivedDrawing);
    _saveDrawings();
    notifyListeners();
  }

  /// Create a copy of a drawing marked as received
  MapDrawing _createReceivedCopy(MapDrawing drawing) {
    if (drawing is LineDrawing) {
      return LineDrawing(
        id: drawing.id,
        color: drawing.color,
        createdAt: drawing.createdAt,
        points: drawing.points,
        senderName: drawing.senderName,
        isReceived: true,
        messageId: drawing.messageId,
        isShared: drawing.isShared,
        isSent: drawing.isSent,
        isHidden: drawing.isHidden,
        coordinateSpace: drawing.coordinateSpace,
        mapId: drawing.mapId,
      );
    } else if (drawing is RectangleDrawing) {
      return RectangleDrawing(
        id: drawing.id,
        color: drawing.color,
        createdAt: drawing.createdAt,
        topLeft: drawing.topLeft,
        bottomRight: drawing.bottomRight,
        senderName: drawing.senderName,
        isReceived: true,
        messageId: drawing.messageId,
        isShared: drawing.isShared,
        isSent: drawing.isSent,
        isHidden: drawing.isHidden,
        coordinateSpace: drawing.coordinateSpace,
        mapId: drawing.mapId,
      );
    }
    return drawing;
  }

  /// Get a drawing by its ID
  MapDrawing? getDrawingById(String id) {
    try {
      return _drawings.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> exportDrawingsJson() {
    return _drawings.map((drawing) => drawing.toJson()).toList();
  }

  Future<void> replaceDrawingsFromJson(
    List<Map<String, dynamic>> jsonList,
  ) async {
    _drawings
      ..clear()
      ..addAll(jsonList.map(MapDrawing.fromJson).whereType<MapDrawing>());
    await _saveDrawings();
    notifyListeners();
  }

  String _scopedKey(String baseKey) {
    return ProfileStorageScope.scopedKey(baseKey);
  }

  /// Get all unshared drawings (local drawings not yet sent)
  List<MapDrawing> getUnsharedDrawings() {
    return drawings.where((d) => !d.isShared && !d.isReceived).toList();
  }

  /// Mark a drawing as shared
  void markDrawingAsShared(String id) {
    final index = _drawings.indexWhere((d) => d.id == id);
    if (index != -1) {
      final drawing = _drawings[index];

      // Create a copy with isShared = true
      if (drawing is LineDrawing) {
        _drawings[index] = LineDrawing(
          id: drawing.id,
          color: drawing.color,
          createdAt: drawing.createdAt,
          points: drawing.points,
          senderName: drawing.senderName,
          isReceived: drawing.isReceived,
          messageId: drawing.messageId,
          isShared: true,
          isSent: drawing.isSent,
          isHidden: drawing.isHidden,
          coordinateSpace: drawing.coordinateSpace,
          mapId: drawing.mapId,
        );
      } else if (drawing is RectangleDrawing) {
        _drawings[index] = RectangleDrawing(
          id: drawing.id,
          color: drawing.color,
          createdAt: drawing.createdAt,
          topLeft: drawing.topLeft,
          bottomRight: drawing.bottomRight,
          senderName: drawing.senderName,
          isReceived: drawing.isReceived,
          messageId: drawing.messageId,
          isShared: true,
          isSent: drawing.isSent,
          isHidden: drawing.isHidden,
          coordinateSpace: drawing.coordinateSpace,
          mapId: drawing.mapId,
        );
      }

      _saveDrawings();
      notifyListeners();
    }
  }

  /// Toggle visibility of a drawing (doesn't save to storage)
  void toggleDrawingVisibility(String id) {
    final index = _drawings.indexWhere((d) => d.id == id);
    if (index != -1) {
      final drawing = _drawings[index];

      // Create a copy with toggled isHidden flag
      if (drawing is LineDrawing) {
        _drawings[index] = LineDrawing(
          id: drawing.id,
          color: drawing.color,
          createdAt: drawing.createdAt,
          points: drawing.points,
          senderName: drawing.senderName,
          isReceived: drawing.isReceived,
          messageId: drawing.messageId,
          isShared: drawing.isShared,
          isSent: drawing.isSent,
          isHidden: !drawing.isHidden,
          coordinateSpace: drawing.coordinateSpace,
          mapId: drawing.mapId,
        );
      } else if (drawing is RectangleDrawing) {
        _drawings[index] = RectangleDrawing(
          id: drawing.id,
          color: drawing.color,
          createdAt: drawing.createdAt,
          topLeft: drawing.topLeft,
          bottomRight: drawing.bottomRight,
          senderName: drawing.senderName,
          isReceived: drawing.isReceived,
          messageId: drawing.messageId,
          isShared: drawing.isShared,
          isSent: drawing.isSent,
          isHidden: !drawing.isHidden,
          coordinateSpace: drawing.coordinateSpace,
          mapId: drawing.mapId,
        );
      }

      // Don't save to storage - visibility toggle is temporary
      notifyListeners();
    }
  }

  /// Remove a drawing and its linked message
  void removeDrawingAndMessage(String drawingId, dynamic messagesProvider) {
    final drawing = getDrawingById(drawingId);
    if (drawing == null) return;

    // Remove the drawing
    _drawings.removeWhere((d) => d.id == drawingId);

    // If the drawing has a linked message, remove it too
    if (drawing.messageId != null && messagesProvider != null) {
      messagesProvider.deleteMessage(drawing.messageId!);
    }

    _saveDrawings();
    notifyListeners();
  }

  /// Broadcast a drawing to contacts
  /// Returns the formatted message string ready to send
  /// Sender will be determined from packet metadata on receiving end
  String createDrawingBroadcastMessage(MapDrawing drawing) {
    return DrawingMessageParser.createDrawingMessage(drawing);
  }
}
