import 'package:latlong2/latlong.dart';
import '../models/sar_marker.dart';
import '../models/message.dart';

/// Parser for SAR (Search & Rescue) special messages
/// Old format: S:<emoji>:<latitude>,<longitude>:<optional_message>
/// New format: S:<emoji>:<colorIndex>:<latitude>,<longitude>:<optional_message>
/// Examples:
///   S:🧑:37.7749,-122.4194 (old format)
///   S:🧑:2:37.7749,-122.4194 (new format with green color)
///   S:🔥:0:40.7128,-74.0060:Large wildfire spreading (new format with red color)
class SarMessageParser {
  // Regex for new format with color index: S:emoji:colorIndex:lat,lon:notes
  // Captures: emoji, colorIndex (single digit), latitude, longitude, optional message
  static final RegExp _sarPatternNew = RegExp(
    r'^S:([^:]+):(\d):(-?\d+\.?\d*),(-?\d+\.?\d*):?(.*)',
    multiLine: false,
  );

  // Regex for old format (backward compatibility): S:emoji:lat,lon:notes
  // Captures: emoji, latitude, longitude, optional message
  static final RegExp _sarPatternOld = RegExp(
    r'^S:([^:]+):(-?\d+\.?\d*),(-?\d+\.?\d*):?(.*)',
    multiLine: false,
  );

  /// Check if a message is a SAR marker message
  static bool isSarMessage(String text) {
    // Extract just the first line for matching
    final firstLine = text.trim().split('\n').first;
    return firstLine.startsWith('S:') && (_sarPatternNew.hasMatch(firstLine) || _sarPatternOld.hasMatch(firstLine));
  }

  /// Parse a SAR message and extract marker information
  /// Returns null if the message is not a valid SAR message
  /// Supports both old format (S:emoji:lat,lon:notes) and new format (S:emoji:colorIndex:lat,lon:notes)
  static SarMarkerInfo? parse(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('S:')) return null;

    // Extract first line (actual SAR marker)
    final firstLine = trimmed.split('\n').first;

    // Try new format first (with color index)
    var match = _sarPatternNew.firstMatch(firstLine);
    bool isNewFormat = match != null;

    // If new format didn't match, try old format
    if (match == null) {
      match = _sarPatternOld.firstMatch(firstLine);
      if (match == null) return null;
    }

    try {
      String emoji;
      double latitude;
      double longitude;
      String? inlineMessage;
      int? colorIndex;

      if (isNewFormat) {
        // New format: S:emoji:colorIndex:lat,lon:notes
        emoji = match!.group(1)!;
        colorIndex = int.parse(match.group(2)!);
        latitude = double.parse(match.group(3)!);
        longitude = double.parse(match.group(4)!);
        inlineMessage = match.group(5)?.trim();
      } else {
        // Old format: S:emoji:lat,lon:notes
        emoji = match!.group(1)!;
        colorIndex = null; // No color index in old format
        latitude = double.parse(match.group(2)!);
        longitude = double.parse(match.group(3)!);
        inlineMessage = match.group(4)?.trim();
      }

      // Validate coordinates
      if (latitude < -90 || latitude > 90) return null;
      if (longitude < -180 || longitude > 180) return null;

      // Validate color index if present
      if (colorIndex != null && (colorIndex < 0 || colorIndex > 7)) {
        colorIndex = null; // Invalid index, ignore it
      }

      final markerType = SarMarkerType.fromEmoji(emoji);
      final location = LatLng(latitude, longitude);

      // Combine inline message with multi-line notes
      String? notes;
      if (inlineMessage != null && inlineMessage.isNotEmpty) {
        notes = inlineMessage;
      }

      // Check for multi-line notes (lines after the first line)
      final additionalNotes = extractNotes(text);
      if (additionalNotes != null) {
        notes = notes != null ? '$notes\n$additionalNotes' : additionalNotes;
      }

      return SarMarkerInfo(
        type: markerType,
        location: location,
        emoji: emoji,
        notes: notes,
        colorIndex: colorIndex,
      );
    } catch (e) {
      return null;
    }
  }

  /// Enhance a Message with SAR marker information
  static Message enhanceMessage(Message message) {
    final sarInfo = parse(message.text);
    if (sarInfo == null) return message;

    return message.copyWith(
      isSarMarker: true,
      sarMarkerType: sarInfo.type,
      sarGpsCoordinates: sarInfo.location,
      sarNotes: sarInfo.notes, // Extract and store notes
      sarCustomEmoji: sarInfo.type == SarMarkerType.unknown
          ? sarInfo.emoji  // Preserve custom emoji for unknown types
          : null,
      sarColorIndex: sarInfo.colorIndex, // Store color index
    );
  }

  /// Create a SAR marker message text (new format with color index)
  static String createSarMessage({
    required SarMarkerType type,
    required LatLng location,
    String? notes,
    int? colorIndex,
  }) {
    // New format: S:emoji:colorIndex:lat,lon:notes
    final colorIdx = colorIndex ?? 0; // Default to red if not specified
    final text = 'S:${type.emoji}:$colorIdx:${location.latitude},${location.longitude}';
    if (notes != null && notes.isNotEmpty) {
      // Use colon-separated format for inline message
      return '$text:$notes';
    }
    return text;
  }

  /// Extract additional notes from SAR message (text after the marker)
  static String? extractNotes(String text) {
    final trimmed = text.trim();
    final lines = trimmed.split('\n');
    if (lines.length <= 1) return null;

    // Everything after the first line is considered notes
    return lines.sublist(1).join('\n').trim();
  }

  /// Validate SAR message format
  static bool isValidFormat(String text) {
    return isSarMessage(text) && parse(text) != null;
  }

  /// Get a user-friendly error message for invalid SAR format
  static String? getFormatError(String text) {
    if (!text.trim().startsWith('S:')) {
      return 'SAR message must start with "S:"';
    }

    final parts = text.trim().split(':');
    if (parts.length < 3) {
      return 'Invalid format. Use: S:<emoji>:<latitude>,<longitude>';
    }

    final emoji = parts[1];
    if (emoji.isEmpty) {
      return 'Missing emoji marker (🧑, 🔥, or 🏕️)';
    }

    final coords = parts[2];
    if (!coords.contains(',')) {
      return 'Coordinates must be separated by comma';
    }

    final coordParts = coords.split(',');
    if (coordParts.length != 2) {
      return 'Invalid coordinates format';
    }

    try {
      final lat = double.parse(coordParts[0]);
      final lon = double.parse(coordParts[1]);

      if (lat < -90 || lat > 90) {
        return 'Latitude must be between -90 and 90';
      }
      if (lon < -180 || lon > 180) {
        return 'Longitude must be between -180 and 180';
      }
    } catch (e) {
      return 'Invalid coordinate values';
    }

    return null;
  }
}

/// Parsed SAR marker information
class SarMarkerInfo {
  final SarMarkerType type;
  final LatLng location;
  final String emoji;
  final String? notes;
  final int? colorIndex; // Color index from standard palette (0-7), null for backward compatibility

  SarMarkerInfo({
    required this.type,
    required this.location,
    required this.emoji,
    this.notes,
    this.colorIndex,
  });

  @override
  String toString() {
    return 'SarMarkerInfo(type: ${type.displayName}, location: $location, colorIndex: $colorIndex, notes: $notes)';
  }
}
