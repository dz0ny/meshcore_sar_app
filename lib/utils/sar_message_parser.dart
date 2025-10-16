import 'package:latlong2/latlong.dart';
import '../models/sar_marker.dart';
import '../models/message.dart';

/// Parser for SAR (Search & Rescue) special messages
/// Format: S:<emoji>:<latitude>,<longitude>:<optional_message>
/// Examples:
///   S:🧑:37.7749,-122.4194
///   S:🔥:40.7128,-74.0060:Large wildfire spreading
///   S:🏕️:34.0522,-118.2437:Base camp established
class SarMessageParser {
  // Updated regex to capture optional message after coordinates
  // Captures: emoji (one or more non-colon chars), latitude, longitude, optional message
  // Note: Emojis are multi-byte characters, so we use [^:]+ instead of .
  static final RegExp _sarPattern = RegExp(
    r'^S:([^:]+):(-?\d+\.?\d*),(-?\d+\.?\d*):?(.*)',
    multiLine: false,
  );

  /// Check if a message is a SAR marker message
  static bool isSarMessage(String text) {
    // Extract just the first line for matching
    final firstLine = text.trim().split('\n').first;
    return firstLine.startsWith('S:') && _sarPattern.hasMatch(firstLine);
  }

  /// Parse a SAR message and extract marker information
  /// Returns null if the message is not a valid SAR message
  static SarMarkerInfo? parse(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('S:')) return null;

    // Extract first line (actual SAR marker)
    final firstLine = trimmed.split('\n').first;
    final match = _sarPattern.firstMatch(firstLine);
    if (match == null) return null;

    try {
      final emoji = match.group(1)!;
      final latitude = double.parse(match.group(2)!);
      final longitude = double.parse(match.group(3)!);
      final inlineMessage = match.group(4)?.trim(); // Optional message after colon

      // Validate coordinates
      if (latitude < -90 || latitude > 90) return null;
      if (longitude < -180 || longitude > 180) return null;

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
    );
  }

  /// Create a SAR marker message text
  static String createSarMessage({
    required SarMarkerType type,
    required LatLng location,
    String? notes,
  }) {
    final text = 'S:${type.emoji}:${location.latitude},${location.longitude}';
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

  SarMarkerInfo({
    required this.type,
    required this.location,
    required this.emoji,
    this.notes,
  });

  @override
  String toString() {
    return 'SarMarkerInfo(type: ${type.displayName}, location: $location, notes: $notes)';
  }
}
