import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_coordinate_space.dart';
import '../utils/custom_map_id.dart';

/// Drawing shape type
enum DrawingShapeType { line, rectangle }

/// Drawing color enum for compact network transmission
enum DrawingColor { red, blue, green, yellow, orange, purple, pink, cyan }

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

  static int colorToIndex(Color color) {
    for (int i = 0; i < palette.length; i++) {
      if (palette[i].toARGB32() == color.toARGB32()) {
        return i;
      }
    }
    return 0;
  }

  static Color indexToColor(int index) {
    if (index >= 0 && index < palette.length) {
      return palette[index];
    }
    return palette[0];
  }
}

abstract class MapDrawing {
  final String id;
  final DrawingShapeType type;
  final Color color;
  final DateTime createdAt;
  final String? senderName;
  final bool isReceived;
  final String? messageId;
  final bool isShared;
  final bool isSent;
  final bool isHidden;
  final MapCoordinateSpace coordinateSpace;
  final String? mapId;

  MapDrawing({
    required this.id,
    required this.type,
    required this.color,
    required this.createdAt,
    this.senderName,
    this.isReceived = false,
    this.messageId,
    this.isShared = false,
    this.isSent = false,
    this.isHidden = false,
    this.coordinateSpace = MapCoordinateSpace.geo,
    this.mapId,
  });

  bool get isCustomMap => coordinateSpace == MapCoordinateSpace.customMap;

  Map<String, dynamic> toJson();

  Map<String, dynamic> toNetworkJson();

  static MapDrawing? fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
    MapCoordinateSpace coordinateSpace = MapCoordinateSpace.geo,
    String? mapId,
  }) {
    final typeNum = json['t'] as int?;
    if (typeNum == null ||
        typeNum < 0 ||
        typeNum >= DrawingShapeType.values.length) {
      return null;
    }

    try {
      final type = DrawingShapeType.values[typeNum];
      switch (type) {
        case DrawingShapeType.line:
          return LineDrawing.fromNetworkJson(
            json,
            senderName: senderName,
            messageId: messageId,
            coordinateSpace: coordinateSpace,
            mapId: mapId,
          );
        case DrawingShapeType.rectangle:
          return RectangleDrawing.fromNetworkJson(
            json,
            senderName: senderName,
            messageId: messageId,
            coordinateSpace: coordinateSpace,
            mapId: mapId,
          );
      }
    } catch (_) {
      return null;
    }
  }

  static MapDrawing? fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    if (typeStr == null) return null;

    try {
      final type = DrawingShapeType.values.firstWhere(
        (value) => value.name == typeStr,
      );
      switch (type) {
        case DrawingShapeType.line:
          return LineDrawing.fromJson(json);
        case DrawingShapeType.rectangle:
          return RectangleDrawing.fromJson(json);
      }
    } catch (_) {
      return null;
    }
  }

  LatLng getCenter();

  LatLngBounds getBounds();
}

class LineDrawing extends MapDrawing {
  final List<LatLng> points;

  LineDrawing({
    required super.id,
    required super.color,
    required super.createdAt,
    required this.points,
    super.senderName,
    super.isReceived,
    super.messageId,
    super.isShared,
    super.isSent,
    super.isHidden,
    super.coordinateSpace,
    super.mapId,
  }) : super(type: DrawingShapeType.line);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'points': points
          .map((point) => {'lat': point.latitude, 'lon': point.longitude})
          .toList(),
      'isShared': isShared,
      'coordinateSpace': coordinateSpace.name,
      'mapId': normalizeCustomMapId(mapId),
    };
  }

  @override
  Map<String, dynamic> toNetworkJson() {
    final payload = <String, dynamic>{
      't': type.index,
      'c': DrawingColors.colorToIndex(color),
    };

    if (coordinateSpace == MapCoordinateSpace.customMap) {
      payload['m'] = normalizeCustomMapId(mapId);
      payload['p'] = points
          .expand((point) => [point.latitude.round(), point.longitude.round()])
          .toList();
      return payload;
    }

    payload['p'] = points
        .expand(
          (point) => [
            double.parse(point.latitude.toStringAsFixed(5)),
            double.parse(point.longitude.toStringAsFixed(5)),
          ],
        )
        .toList();
    return payload;
  }

  static LineDrawing fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson
        .map(
          (point) => LatLng(
            (point['lat'] as num).toDouble(),
            (point['lon'] as num).toDouble(),
          ),
        )
        .toList();
    final senderName = json['sender'] as String?;

    return LineDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      points: points,
      senderName: senderName,
      isReceived: senderName != null,
      isShared: json['isShared'] as bool? ?? false,
      coordinateSpace: MapCoordinateSpace.fromName(
        json['coordinateSpace'] as String?,
      ),
      mapId: normalizeCustomMapId(json['mapId'] as String?),
    );
  }

  static LineDrawing fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
    MapCoordinateSpace coordinateSpace = MapCoordinateSpace.geo,
    String? mapId,
  }) {
    final flatPoints = (json['p'] as List<dynamic>).cast<num>();
    final points = <LatLng>[];
    for (int i = 0; i < flatPoints.length; i += 2) {
      points.add(
        LatLng(flatPoints[i].toDouble(), flatPoints[i + 1].toDouble()),
      );
    }

    return LineDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      color: DrawingColors.indexToColor(json['c'] as int),
      createdAt: DateTime.now(),
      points: points,
      senderName: senderName,
      isReceived: true,
      messageId: messageId,
      coordinateSpace: coordinateSpace,
      mapId: normalizeCustomMapId(mapId),
    );
  }

  LineDrawing copyWith({
    List<LatLng>? points,
    bool? isHidden,
    bool? isShared,
    bool? isReceived,
    String? messageId,
    String? senderName,
    MapCoordinateSpace? coordinateSpace,
    String? mapId,
  }) {
    return LineDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      points: points ?? this.points,
      isHidden: isHidden ?? this.isHidden,
      isShared: isShared ?? this.isShared,
      isReceived: isReceived ?? this.isReceived,
      messageId: messageId ?? this.messageId,
      senderName: senderName ?? this.senderName,
      coordinateSpace: coordinateSpace ?? this.coordinateSpace,
      mapId: mapId ?? this.mapId,
    );
  }

  @override
  LatLng getCenter() {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points[0];

    double sumLat = 0;
    double sumLon = 0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }
    return LatLng(sumLat / points.length, sumLon / points.length);
  }

  @override
  LatLngBounds getBounds() {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }
    if (points.length == 1) {
      return LatLngBounds(points[0], points[0]);
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLon = points[0].longitude;
    double maxLon = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }
}

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
    super.messageId,
    super.isShared,
    super.isSent,
    super.isHidden,
    super.coordinateSpace,
    super.mapId,
  }) : super(type: DrawingShapeType.rectangle);

  List<LatLng> get corners => [
    topLeft,
    LatLng(topLeft.latitude, bottomRight.longitude),
    bottomRight,
    LatLng(bottomRight.latitude, topLeft.longitude),
    topLeft,
  ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'topLeft': {'lat': topLeft.latitude, 'lon': topLeft.longitude},
      'bottomRight': {
        'lat': bottomRight.latitude,
        'lon': bottomRight.longitude,
      },
      'isShared': isShared,
      'coordinateSpace': coordinateSpace.name,
      'mapId': normalizeCustomMapId(mapId),
    };
  }

  @override
  Map<String, dynamic> toNetworkJson() {
    final payload = <String, dynamic>{
      't': type.index,
      'c': DrawingColors.colorToIndex(color),
    };

    if (coordinateSpace == MapCoordinateSpace.customMap) {
      payload['m'] = normalizeCustomMapId(mapId);
      payload['b'] = [
        topLeft.latitude.round(),
        topLeft.longitude.round(),
        bottomRight.latitude.round(),
        bottomRight.longitude.round(),
      ];
      return payload;
    }

    payload['b'] = [
      double.parse(topLeft.latitude.toStringAsFixed(5)),
      double.parse(topLeft.longitude.toStringAsFixed(5)),
      double.parse(bottomRight.latitude.toStringAsFixed(5)),
      double.parse(bottomRight.longitude.toStringAsFixed(5)),
    ];
    return payload;
  }

  static RectangleDrawing fromJson(Map<String, dynamic> json) {
    final topLeftJson = json['topLeft'] as Map<String, dynamic>;
    final bottomRightJson = json['bottomRight'] as Map<String, dynamic>;
    final senderName = json['sender'] as String?;

    return RectangleDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      topLeft: LatLng(
        (topLeftJson['lat'] as num).toDouble(),
        (topLeftJson['lon'] as num).toDouble(),
      ),
      bottomRight: LatLng(
        (bottomRightJson['lat'] as num).toDouble(),
        (bottomRightJson['lon'] as num).toDouble(),
      ),
      senderName: senderName,
      isReceived: senderName != null,
      isShared: json['isShared'] as bool? ?? false,
      coordinateSpace: MapCoordinateSpace.fromName(
        json['coordinateSpace'] as String?,
      ),
      mapId: normalizeCustomMapId(json['mapId'] as String?),
    );
  }

  static RectangleDrawing fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
    MapCoordinateSpace coordinateSpace = MapCoordinateSpace.geo,
    String? mapId,
  }) {
    final bounds = (json['b'] as List<dynamic>).cast<num>();

    return RectangleDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      color: DrawingColors.indexToColor(json['c'] as int),
      createdAt: DateTime.now(),
      topLeft: LatLng(bounds[0].toDouble(), bounds[1].toDouble()),
      bottomRight: LatLng(bounds[2].toDouble(), bounds[3].toDouble()),
      senderName: senderName,
      isReceived: true,
      messageId: messageId,
      coordinateSpace: coordinateSpace,
      mapId: normalizeCustomMapId(mapId),
    );
  }

  RectangleDrawing copyWith({
    LatLng? topLeft,
    LatLng? bottomRight,
    bool? isHidden,
    bool? isShared,
    bool? isReceived,
    String? messageId,
    String? senderName,
    MapCoordinateSpace? coordinateSpace,
    String? mapId,
  }) {
    return RectangleDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      topLeft: topLeft ?? this.topLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      isHidden: isHidden ?? this.isHidden,
      isShared: isShared ?? this.isShared,
      isReceived: isReceived ?? this.isReceived,
      messageId: messageId ?? this.messageId,
      senderName: senderName ?? this.senderName,
      coordinateSpace: coordinateSpace ?? this.coordinateSpace,
      mapId: mapId ?? this.mapId,
    );
  }

  @override
  LatLng getCenter() {
    return LatLng(
      (topLeft.latitude + bottomRight.latitude) / 2,
      (topLeft.longitude + bottomRight.longitude) / 2,
    );
  }

  @override
  LatLngBounds getBounds() {
    return LatLngBounds(topLeft, bottomRight);
  }
}
