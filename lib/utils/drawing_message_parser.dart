import 'dart:convert';

import '../models/map_coordinate_space.dart';
import '../models/map_drawing.dart';
import 'custom_map_id.dart';

class DrawingMessageParser {
  static const String legacyPrefix = 'D:';
  static const String customMapPrefix = 'D2:';

  static bool isDrawingMessage(String text) {
    return text.startsWith(legacyPrefix) || text.startsWith(customMapPrefix);
  }

  static MapDrawing? parseDrawingMessage(
    String text, {
    String? senderName,
    String? messageId,
  }) {
    if (!isDrawingMessage(text)) {
      return null;
    }

    try {
      if (text.startsWith(customMapPrefix)) {
        final json =
            jsonDecode(text.substring(customMapPrefix.length))
                as Map<String, dynamic>;
        final mapId = normalizeCustomMapId(json['m'] as String?);
        if (mapId == null || mapId.isEmpty) {
          return null;
        }
        return MapDrawing.fromNetworkJson(
          json,
          senderName: senderName,
          messageId: messageId,
          coordinateSpace: MapCoordinateSpace.customMap,
          mapId: mapId,
        );
      }

      final json =
          jsonDecode(text.substring(legacyPrefix.length))
              as Map<String, dynamic>;
      return MapDrawing.fromNetworkJson(
        json,
        senderName: senderName,
        messageId: messageId,
        coordinateSpace: MapCoordinateSpace.geo,
      );
    } catch (_) {
      return null;
    }
  }

  static String createDrawingMessage(MapDrawing drawing) {
    final json = drawing.toNetworkJson();
    final prefix = drawing.coordinateSpace == MapCoordinateSpace.customMap
        ? customMapPrefix
        : legacyPrefix;
    return '$prefix${jsonEncode(json)}';
  }

  static String? getDrawingTypeDisplay(String text) {
    final metadata = getDrawingMetadata(text);
    return metadata?['type'] as String?;
  }

  static String? getColorName(String text) {
    final metadata = getDrawingMetadata(text);
    return metadata?['color'] as String?;
  }

  static Map<String, dynamic>? getDrawingMetadata(String text) {
    if (!isDrawingMessage(text)) return null;

    try {
      final json =
          jsonDecode(
                text.startsWith(customMapPrefix)
                    ? text.substring(customMapPrefix.length)
                    : text.substring(legacyPrefix.length),
              )
              as Map<String, dynamic>;

      final typeNum = json['t'] as int?;
      final colorIndex = json['c'] as int?;
      if (typeNum == null || colorIndex == null) return null;

      String type;
      int? pointCount;
      switch (typeNum) {
        case 0:
          type = 'Line';
          final points = json['p'] as List?;
          pointCount = points != null ? points.length ~/ 2 : null;
          break;
        case 1:
          type = 'Rectangle';
          pointCount = 4;
          break;
        default:
          return null;
      }

      const colorNames = [
        'Red',
        'Blue',
        'Green',
        'Yellow',
        'Orange',
        'Purple',
        'Pink',
        'Cyan',
      ];
      final color = colorIndex >= 0 && colorIndex < colorNames.length
          ? colorNames[colorIndex]
          : 'Unknown';

      return {
        'type': type,
        'color': color,
        'pointCount': pointCount,
        'coordinateSpace': text.startsWith(customMapPrefix)
            ? MapCoordinateSpace.customMap.name
            : MapCoordinateSpace.geo.name,
        'mapId': normalizeCustomMapId(json['m'] as String?),
      };
    } catch (_) {
      return null;
    }
  }
}
