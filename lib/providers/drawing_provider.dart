import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_drawing.dart';

/// Drawing mode state
enum DrawingMode {
  none,
  line,
  rectangle,
}

/// Provider for managing map drawings
class DrawingProvider with ChangeNotifier {
  static const String _storageKey = 'map_drawings';

  // Drawing state
  DrawingMode _drawingMode = DrawingMode.none;
  Color _selectedColor = DrawingColors.palette[0];

  // Completed drawings
  final List<MapDrawing> _drawings = [];

  // In-progress drawing
  MapDrawing? _currentDrawing;
  List<LatLng> _currentLinePoints = [];
  LatLng? _rectangleStartPoint;

  // Getters
  DrawingMode get drawingMode => _drawingMode;
  Color get selectedColor => _selectedColor;
  List<MapDrawing> get drawings => List.unmodifiable(_drawings);
  MapDrawing? get currentDrawing => _currentDrawing;
  List<LatLng> get currentLinePoints => List.unmodifiable(_currentLinePoints);
  LatLng? get rectangleStartPoint => _rectangleStartPoint;
  bool get isDrawing => _drawingMode != DrawingMode.none;

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
    if (_drawingMode != DrawingMode.rectangle || _rectangleStartPoint == null) return;

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

  /// Cancel current drawing in progress
  void _cancelCurrentDrawing() {
    _currentLinePoints = [];
    _rectangleStartPoint = null;
    _currentDrawing = null;
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
    } else if (_drawingMode == DrawingMode.rectangle && _currentDrawing != null) {
      return _currentDrawing;
    }
    return null;
  }
}
