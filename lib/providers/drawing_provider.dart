import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_drawing.dart';
import '../utils/drawing_message_parser.dart';

/// Drawing mode state
enum DrawingMode { none, line, rectangle, measure }

/// Provider for managing map drawings
class DrawingProvider with ChangeNotifier {
  static const String _storageKey = 'map_drawings';

  // Drawing state
  DrawingMode _drawingMode = DrawingMode.none;
  Color _selectedColor = DrawingColors.palette[0];
  bool _showReceivedDrawings = true;
  bool _showSarMarkers = true;

  // Completed drawings
  final List<MapDrawing> _drawings = [];

  // In-progress drawing
  MapDrawing? _currentDrawing;
  List<LatLng> _currentLinePoints = [];
  LatLng? _rectangleStartPoint;

  // Distance measurement state
  LatLng? _measurementPoint1;
  LatLng? _measurementPoint2;
  double? _measuredDistance; // in meters

  // Getters
  DrawingMode get drawingMode => _drawingMode;
  Color get selectedColor => _selectedColor;
  bool get showReceivedDrawings => _showReceivedDrawings;
  bool get showSarMarkers => _showSarMarkers;
  List<MapDrawing> get drawings {
    // Filter out hidden drawings first
    var visibleDrawings = _drawings.where((d) => !d.isHidden);

    // Then filter by received status if needed
    if (!_showReceivedDrawings) {
      visibleDrawings = visibleDrawings.where((d) => !d.isReceived);
    }

    return List.unmodifiable(visibleDrawings.toList());
  }
  MapDrawing? get currentDrawing => _currentDrawing;
  List<LatLng> get currentLinePoints => List.unmodifiable(_currentLinePoints);
  LatLng? get rectangleStartPoint => _rectangleStartPoint;
  bool get isDrawing => _drawingMode != DrawingMode.none;
  LatLng? get measurementPoint1 => _measurementPoint1;
  LatLng? get measurementPoint2 => _measurementPoint2;
  double? get measuredDistance => _measuredDistance;

  /// Initialize and load saved drawings
  Future<void> initialize() async {
    await _loadDrawings();
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
  void toggleReceivedDrawings() {
    _showReceivedDrawings = !_showReceivedDrawings;
    notifyListeners();
  }

  /// Toggle visibility of SAR markers
  void toggleSarMarkers() {
    _showSarMarkers = !_showSarMarkers;
    notifyListeners();
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
    if (_drawingMode != DrawingMode.measure || _measurementPoint1 == null) return;

    _measurementPoint2 = point;
    _measuredDistance = _calculateDistance(_measurementPoint1!, point);
    notifyListeners();
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
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
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving drawings: $e');
    }
  }

  /// Load drawings from persistent storage
  Future<void> _loadDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return;

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

  /// Get all unshared drawings (local drawings not yet sent)
  List<MapDrawing> getUnsharedDrawings() {
    return _drawings.where((d) => !d.isShared && !d.isReceived).toList();
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
