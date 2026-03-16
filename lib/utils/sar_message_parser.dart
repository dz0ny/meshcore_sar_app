import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../models/map_coordinate_space.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';
import 'custom_map_id.dart';

class SarMessageParser {
  static const String legacyPrefix = 'S:';
  static const String customMapPrefix = 'S2:';

  static final RegExp _sarPatternNew = RegExp(
    r'^S:([^:]+):(\d):(-?\d+\.?\d*),(-?\d+\.?\d*):?(.*)',
    multiLine: false,
  );

  static final RegExp _sarPatternOld = RegExp(
    r'^S:([^:]+):(-?\d+\.?\d*),(-?\d+\.?\d*):?(.*)',
    multiLine: false,
  );

  static bool isSarMessage(String text) {
    final lines = text.trim().split('\n');
    final firstLine = lines.isEmpty ? text.trim() : lines.first;
    return firstLine.startsWith(legacyPrefix) ||
        firstLine.startsWith(customMapPrefix);
  }

  static SarMarkerInfo? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith(customMapPrefix)) {
      return _parseCustomMap(trimmed);
    }
    if (!trimmed.startsWith(legacyPrefix)) {
      return null;
    }

    final firstLine = trimmed.split('\n').first;
    var match = _sarPatternNew.firstMatch(firstLine);
    final isNewFormat = match != null;
    match ??= _sarPatternOld.firstMatch(firstLine);
    if (match == null) return null;

    try {
      final emoji = match.group(1)!;
      final colorIndex = isNewFormat ? int.parse(match.group(2)!) : null;
      final latitude = double.parse(match.group(isNewFormat ? 3 : 2)!);
      final longitude = double.parse(match.group(isNewFormat ? 4 : 3)!);
      final inlineMessage = match.group(isNewFormat ? 5 : 4)?.trim();
      if (latitude < -90 || latitude > 90) return null;
      if (longitude < -180 || longitude > 180) return null;

      final additionalNotes = extractNotes(text);
      String? notes;
      if (inlineMessage != null && inlineMessage.isNotEmpty) {
        notes = inlineMessage;
      }
      if (additionalNotes != null && additionalNotes.isNotEmpty) {
        notes = notes != null ? '$notes\n$additionalNotes' : additionalNotes;
      }

      return SarMarkerInfo(
        type: SarMarkerType.fromEmoji(emoji),
        location: LatLng(latitude, longitude),
        emoji: emoji,
        notes: notes,
        colorIndex: colorIndex != null && colorIndex >= 0 && colorIndex <= 7
            ? colorIndex
            : null,
        coordinateSpace: MapCoordinateSpace.geo,
      );
    } catch (_) {
      return null;
    }
  }

  static SarMarkerInfo? _parseCustomMap(String text) {
    try {
      final json =
          jsonDecode(text.substring(customMapPrefix.length))
              as Map<String, dynamic>;
      final emoji = json['e'];
      final mapId = normalizeCustomMapId(json['m'] as String?);
      final rawPoint = json['p'];
      if (emoji is! String || mapId == null || rawPoint is! List) {
        return null;
      }
      final point = rawPoint.cast<num>();
      if (point.length != 2) return null;
      final colorIndex = json['c'];
      final notes = json['n'];
      return SarMarkerInfo(
        type: SarMarkerType.fromEmoji(emoji),
        location: LatLng(point[0].toDouble(), point[1].toDouble()),
        emoji: emoji,
        notes: notes is String && notes.isNotEmpty ? notes : null,
        colorIndex: colorIndex is int ? colorIndex : null,
        coordinateSpace: MapCoordinateSpace.customMap,
        mapId: mapId,
      );
    } catch (_) {
      return null;
    }
  }

  static Message enhanceMessage(Message message) {
    final sarInfo = parse(message.text);
    if (sarInfo == null) return message;

    return message.copyWith(
      isSarMarker: true,
      sarGpsCoordinates: sarInfo.coordinateSpace == MapCoordinateSpace.geo
          ? sarInfo.location
          : null,
      sarCustomMapPoint: sarInfo.coordinateSpace == MapCoordinateSpace.customMap
          ? sarInfo.location
          : null,
      sarCustomMapId: sarInfo.mapId,
      sarNotes: sarInfo.notes,
      sarCustomEmoji: sarInfo.emoji,
      sarColorIndex: sarInfo.colorIndex,
    );
  }

  static String createSarMessage({
    required SarMarkerType type,
    required LatLng location,
    String? notes,
    int? colorIndex,
  }) {
    final colorIdx = colorIndex ?? 0;
    final text =
        'S:${type.emoji}:$colorIdx:${location.latitude},${location.longitude}';
    if (notes != null && notes.isNotEmpty) {
      return '$text:$notes';
    }
    return text;
  }

  static String createCustomMapSarMessage({
    required String emoji,
    required String mapId,
    required LatLng point,
    String? notes,
    int? colorIndex,
  }) {
    final payload = <String, dynamic>{
      'e': emoji,
      'c': colorIndex ?? 0,
      'm': normalizeCustomMapId(mapId),
      'p': [point.latitude.round(), point.longitude.round()],
    };
    if (notes != null && notes.isNotEmpty) {
      payload['n'] = notes;
    }
    return '$customMapPrefix${jsonEncode(payload)}';
  }

  static String? extractNotes(String text) {
    final trimmed = text.trim();
    final lines = trimmed.split('\n');
    if (lines.length <= 1) return null;
    return lines.sublist(1).join('\n').trim();
  }

  static bool isValidFormat(String text) {
    return isSarMessage(text) && parse(text) != null;
  }

  static String? getFormatError(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith(customMapPrefix)) {
      return parse(text) == null
          ? 'Invalid format for custom map SAR marker'
          : null;
    }
    if (!trimmed.startsWith(legacyPrefix)) {
      return 'SAR message must start with "S:"';
    }

    final firstLine = trimmed.split('\n').first;
    if (firstLine == legacyPrefix) {
      return 'Invalid format for SAR marker';
    }
    final parts = firstLine.split(':');
    if (parts.length < 2 || parts[1].isEmpty) {
      return 'Missing emoji';
    }

    return parse(text) == null ? 'Invalid format for SAR marker' : null;
  }
}

class SarMarkerInfo {
  final SarMarkerType type;
  final LatLng location;
  final String emoji;
  final String? notes;
  final int? colorIndex;
  final MapCoordinateSpace coordinateSpace;
  final String? mapId;

  SarMarkerInfo({
    required this.type,
    required this.location,
    required this.emoji,
    this.notes,
    this.colorIndex,
    required this.coordinateSpace,
    this.mapId,
  });

  @override
  String toString() {
    return 'SarMarkerInfo(type: ${type.displayName}, location: $location, colorIndex: $colorIndex, space: ${coordinateSpace.name}, mapId: $mapId)';
  }
}
