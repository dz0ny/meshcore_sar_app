import 'dart:convert';
import '../models/map_drawing.dart';

/// Parser for drawing messages transmitted over mesh network
class DrawingMessageParser {
  /// Drawing message prefix
  static const String prefix = 'D:';

  /// Check if message is a drawing message
  static bool isDrawingMessage(String text) {
    return text.startsWith(prefix);
  }

  /// Parse drawing message text into MapDrawing object
  /// Returns null if parsing fails
  static MapDrawing? parseDrawingMessage(String text) {
    if (!isDrawingMessage(text)) {
      return null;
    }

    try {
      // Remove prefix
      final jsonStr = text.substring(prefix.length);

      // Parse JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Use existing fromJson method
      return MapDrawing.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Create drawing message text from MapDrawing object
  /// Includes sender name in the message
  static String createDrawingMessage(MapDrawing drawing, String senderName) {
    final json = drawing.toNetworkJson(senderName);
    final jsonStr = jsonEncode(json);
    return '$prefix$jsonStr';
  }
}
