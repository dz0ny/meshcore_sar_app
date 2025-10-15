import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Drawing shape type
enum DrawingShapeType {
  line,
  rectangle,
}

/// Drawing colors available for user selection
class DrawingColors {
  static const List<Color> palette = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
  ];

  static String colorToName(Color color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.cyan) return 'Cyan';
    return 'Unknown';
  }
}

/// Base class for map drawings
abstract class MapDrawing {
  final String id;
  final DrawingShapeType type;
  final Color color;
  final DateTime createdAt;
  final String? senderName; // Name of sender (null if local drawing)
  final bool isReceived; // True if drawing was received from another node

  MapDrawing({
    required this.id,
    required this.type,
    required this.color,
    required this.createdAt,
    this.senderName,
    this.isReceived = false,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Convert to JSON for network transmission (includes sender name)
  Map<String, dynamic> toNetworkJson(String senderName) {
    final json = toJson();
    json['sender'] = senderName;
    return json;
  }

  /// Create from JSON
  static MapDrawing? fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    if (typeStr == null) return null;

    try {
      final type = DrawingShapeType.values.firstWhere(
        (e) => e.toString() == 'DrawingShapeType.$typeStr',
      );

      switch (type) {
        case DrawingShapeType.line:
          return LineDrawing.fromJson(json);
        case DrawingShapeType.rectangle:
          return RectangleDrawing.fromJson(json);
      }
    } catch (e) {
      return null;
    }
  }
}

/// Line drawing on map
class LineDrawing extends MapDrawing {
  final List<LatLng> points;

  LineDrawing({
    required super.id,
    required super.color,
    required super.createdAt,
    required this.points,
    super.senderName,
    super.isReceived,
  }) : super(type: DrawingShapeType.line);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'points': points.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList(),
    };
  }

  static LineDrawing fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson.map((p) => LatLng(p['lat'] as double, p['lon'] as double)).toList();
    final senderName = json['sender'] as String?;

    return LineDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      points: points,
      senderName: senderName,
      isReceived: senderName != null, // Mark as received if sender is present
    );
  }

  /// Create a copy with updated points
  LineDrawing copyWith({List<LatLng>? points}) {
    return LineDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      points: points ?? this.points,
    );
  }
}

/// Rectangle drawing on map
class RectangleDrawing extends MapDrawing {
  final LatLng topLeft;
  final LatLng bottomRight;

  RectangleDrawing({
    required super.id,
    required super.color,
    required super.createdAt,
    required this.topLeft,
    required this.bottomRight,
    super.senderName,
    super.isReceived,
  }) : super(type: DrawingShapeType.rectangle);

  /// Get all corner points for rendering
  List<LatLng> get corners => [
        topLeft,
        LatLng(topLeft.latitude, bottomRight.longitude), // top right
        bottomRight,
        LatLng(bottomRight.latitude, topLeft.longitude), // bottom left
        topLeft, // close the rectangle
      ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'topLeft': {'lat': topLeft.latitude, 'lon': topLeft.longitude},
      'bottomRight': {'lat': bottomRight.latitude, 'lon': bottomRight.longitude},
    };
  }

  static RectangleDrawing fromJson(Map<String, dynamic> json) {
    final topLeftJson = json['topLeft'] as Map<String, dynamic>;
    final bottomRightJson = json['bottomRight'] as Map<String, dynamic>;
    final senderName = json['sender'] as String?;

    return RectangleDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      topLeft: LatLng(topLeftJson['lat'] as double, topLeftJson['lon'] as double),
      bottomRight: LatLng(bottomRightJson['lat'] as double, bottomRightJson['lon'] as double),
      senderName: senderName,
      isReceived: senderName != null, // Mark as received if sender is present
    );
  }

  /// Create a copy with updated corners
  RectangleDrawing copyWith({
    LatLng? topLeft,
    LatLng? bottomRight,
  }) {
    return RectangleDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      topLeft: topLeft ?? this.topLeft,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }
}
