import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../utils/custom_map_id.dart';

class CustomMapConfig {
  final String filePath;
  final String displayName;
  final String mapId;
  final int imageWidth;
  final int imageHeight;
  final double? metersPerPixel;
  final LatLng? calibrationPointA;
  final LatLng? calibrationPointB;

  const CustomMapConfig({
    required this.filePath,
    required this.displayName,
    required this.mapId,
    required this.imageWidth,
    required this.imageHeight,
    this.metersPerPixel,
    this.calibrationPointA,
    this.calibrationPointB,
  });

  bool get isCalibrated => metersPerPixel != null && metersPerPixel! > 0;

  LatLngBounds get bounds => LatLngBounds(
    const LatLng(0, 0),
    LatLng(imageHeight.toDouble(), imageWidth.toDouble()),
  );

  LatLngBounds get displayBounds => LatLngBounds(
    LatLng(imageHeight.toDouble(), 0),
    LatLng(0, imageWidth.toDouble()),
  );

  LatLng toDisplayPoint(LatLng point) {
    return LatLng(imageHeight.toDouble() - point.latitude, point.longitude);
  }

  LatLng fromDisplayPoint(LatLng point) {
    return LatLng(imageHeight.toDouble() - point.latitude, point.longitude);
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'displayName': displayName,
      'mapId': mapId,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'metersPerPixel': metersPerPixel,
      'calibrationPointA': calibrationPointA != null
          ? {
              'lat': calibrationPointA!.latitude,
              'lon': calibrationPointA!.longitude,
            }
          : null,
      'calibrationPointB': calibrationPointB != null
          ? {
              'lat': calibrationPointB!.latitude,
              'lon': calibrationPointB!.longitude,
            }
          : null,
    };
  }

  CustomMapConfig copyWith({
    String? filePath,
    String? displayName,
    String? mapId,
    int? imageWidth,
    int? imageHeight,
    double? metersPerPixel,
    bool clearMetersPerPixel = false,
    LatLng? calibrationPointA,
    bool clearCalibrationPointA = false,
    LatLng? calibrationPointB,
    bool clearCalibrationPointB = false,
  }) {
    return CustomMapConfig(
      filePath: filePath ?? this.filePath,
      displayName: displayName ?? this.displayName,
      mapId: normalizeCustomMapId(mapId) ?? this.mapId,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      metersPerPixel: clearMetersPerPixel
          ? null
          : (metersPerPixel ?? this.metersPerPixel),
      calibrationPointA: clearCalibrationPointA
          ? null
          : (calibrationPointA ?? this.calibrationPointA),
      calibrationPointB: clearCalibrationPointB
          ? null
          : (calibrationPointB ?? this.calibrationPointB),
    );
  }

  static CustomMapConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    final filePath = json['filePath'];
    final displayName = json['displayName'];
    final mapId = json['mapId'];
    final imageWidth = json['imageWidth'];
    final imageHeight = json['imageHeight'];
    if (filePath is! String ||
        displayName is! String ||
        mapId is! String ||
        imageWidth is! int ||
        imageHeight is! int) {
      return null;
    }

    LatLng? parsePoint(dynamic raw) {
      if (raw is! Map<String, dynamic>) return null;
      final lat = raw['lat'];
      final lon = raw['lon'];
      if (lat is! num || lon is! num) return null;
      return LatLng(lat.toDouble(), lon.toDouble());
    }

    final metersPerPixel = json['metersPerPixel'];
    return CustomMapConfig(
      filePath: filePath,
      displayName: displayName,
      mapId: normalizeCustomMapId(mapId) ?? mapId,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      metersPerPixel: metersPerPixel is num ? metersPerPixel.toDouble() : null,
      calibrationPointA: parsePoint(json['calibrationPointA']),
      calibrationPointB: parsePoint(json['calibrationPointB']),
    );
  }
}
