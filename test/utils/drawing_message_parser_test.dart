import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/map_drawing.dart';
import 'package:meshcore_sar_app/models/map_coordinate_space.dart';
import 'package:meshcore_sar_app/utils/drawing_message_parser.dart';

void main() {
  group('DrawingMessageParser - Critical String Formatting Tests', () {
    test('createDrawingMessage returns raw string, not Object', () {
      final drawing = LineDrawing(
        id: 'test-123',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [LatLng(37.7749, -122.4194), LatLng(37.7750, -122.4195)],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      // CRITICAL: Must be a String type
      expect(message, isA<String>());

      // CRITICAL: Must NOT contain "Instance of" or "Object"
      expect(message, isNot(contains('Instance of')));
      expect(message, isNot(contains('Object')));

      // CRITICAL: Must start with D: prefix
      expect(message, startsWith('D:'));

      // CRITICAL: Must be valid JSON after prefix
      final jsonPart = message.substring(2);
      expect(() => jsonPart, returnsNormally);
    });

    test('createDrawingMessage produces parseable JSON string', () {
      final drawing = LineDrawing(
        id: 'test-456',
        color: DrawingColors.palette[2], // green
        createdAt: DateTime.now(),
        points: [
          LatLng(40.7128, -74.0060),
          LatLng(40.7129, -74.0061),
          LatLng(40.7130, -74.0062),
        ],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      // Should be parseable back
      final parsed = DrawingMessageParser.parseDrawingMessage(
        message,
        senderName: 'Test Sender',
        messageId: 'msg-123',
      );

      expect(parsed, isNotNull);
      expect(parsed, isA<LineDrawing>());
      expect((parsed as LineDrawing).points.length, equals(3));
    });

    test(
      'createDrawingMessage handles rectangle with proper string format',
      () {
        final drawing = RectangleDrawing(
          id: 'rect-789',
          color: DrawingColors.palette[4], // orange
          createdAt: DateTime.now(),
          topLeft: LatLng(45.5231, -122.6765),
          bottomRight: LatLng(45.5100, -122.6600),
        );

        final message = DrawingMessageParser.createDrawingMessage(drawing);

        // CRITICAL: Must be pure string
        expect(message, isA<String>());
        expect(message, startsWith('D:'));

        // Should contain compact JSON format
        expect(message, contains('"t":'));
        expect(message, contains('"c":'));
        expect(message, contains('"b":'));

        // Must NOT contain any object representations
        expect(message, isNot(contains('RectangleDrawing')));
        expect(message, isNot(contains('Instance')));
      },
    );

    test('custom-map drawings use D2 format and preserve map metadata', () {
      final drawing = LineDrawing(
        id: 'custom-1',
        color: DrawingColors.palette[1],
        createdAt: DateTime.now(),
        points: [LatLng(120, 200), LatLng(320, 450)],
        coordinateSpace: MapCoordinateSpace.customMap,
        mapId: '1234567890abcdef',
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      expect(message, startsWith('D2:'));

      final parsed = DrawingMessageParser.parseDrawingMessage(message);
      expect(parsed, isA<LineDrawing>());
      expect(parsed!.coordinateSpace, MapCoordinateSpace.customMap);
      expect(parsed.mapId, '1234567890ab');
      final parsedLine = parsed as LineDrawing;
      expect(parsedLine.points.first.latitude, 120);
      expect(parsedLine.points.first.longitude, 200);
    });

    test('JSON encoding produces string with coordinates as numbers', () {
      final drawing = LineDrawing(
        id: 'coord-test',
        color: DrawingColors.palette[1], // blue
        createdAt: DateTime.now(),
        points: [LatLng(37.77490, -122.41940)],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      // Extract JSON part
      final jsonStr = message.substring(2);

      // CRITICAL: Coordinates must be numbers, not strings
      // Format: {"t":0,"c":1,"p":[37.7749,-122.4194]}
      expect(jsonStr, contains('37.7749'));
      expect(jsonStr, contains('-122.4194'));

      // Should NOT have coordinates as quoted strings
      expect(jsonStr, isNot(contains('"37.7749"')));
      expect(jsonStr, isNot(contains('"-122.4194"')));
    });

    test('isDrawingMessage correctly identifies valid drawing messages', () {
      expect(
        DrawingMessageParser.isDrawingMessage('D:{"t":0,"c":1,"p":[1,2]}'),
        isTrue,
      );
      expect(DrawingMessageParser.isDrawingMessage('S:🧑:37,-122'), isFalse);
      expect(DrawingMessageParser.isDrawingMessage('Plain text'), isFalse);
      expect(DrawingMessageParser.isDrawingMessage('D:'), isTrue);
    });

    test('parseDrawingMessage returns null for malformed messages', () {
      expect(DrawingMessageParser.parseDrawingMessage('Not a drawing'), isNull);
      expect(
        DrawingMessageParser.parseDrawingMessage('D:invalid json'),
        isNull,
      );
    });

    test('round-trip: create -> parse -> create produces consistent output', () {
      final original = LineDrawing(
        id: 'roundtrip-1',
        color: DrawingColors.palette[3], // yellow
        createdAt: DateTime.now(),
        points: [LatLng(51.5074, -0.1278), LatLng(51.5075, -0.1279)],
      );

      // Create message
      final message1 = DrawingMessageParser.createDrawingMessage(original);

      // Parse it
      final parsed = DrawingMessageParser.parseDrawingMessage(
        message1,
        senderName: 'TestUser',
        messageId: 'msg-rt1',
      );

      expect(parsed, isNotNull);

      // Create message again from parsed
      final message2 = DrawingMessageParser.createDrawingMessage(parsed!);

      // Both messages should have same structure (excluding metadata like IDs)
      expect(message1.substring(0, 10), equals(message2.substring(0, 10)));
    });

    test('color indices are preserved as integers in JSON', () {
      for (int i = 0; i < DrawingColors.palette.length; i++) {
        final drawing = LineDrawing(
          id: 'color-$i',
          color: DrawingColors.palette[i],
          createdAt: DateTime.now(),
          points: [LatLng(0, 0)],
        );

        final message = DrawingMessageParser.createDrawingMessage(drawing);
        final jsonStr = message.substring(2);

        // Color index should be integer in JSON
        expect(jsonStr, contains('"c":$i'));
      }
    });

    test('type indices are preserved correctly', () {
      // Line = type 0
      final line = LineDrawing(
        id: 'line-type',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [LatLng(1, 1), LatLng(2, 2)],
      );

      final lineMsg = DrawingMessageParser.createDrawingMessage(line);
      expect(lineMsg, contains('"t":0'));

      // Rectangle = type 1
      final rect = RectangleDrawing(
        id: 'rect-type',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        topLeft: LatLng(1, 1),
        bottomRight: LatLng(2, 2),
      );

      final rectMsg = DrawingMessageParser.createDrawingMessage(rect);
      expect(rectMsg, contains('"t":1'));
    });

    test('coordinates are rounded to 5 decimal places', () {
      final drawing = LineDrawing(
        id: 'precision-test',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [LatLng(37.774901234567, -122.419401234567)],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);
      final jsonStr = message.substring(2);

      // Should be rounded to 5 decimals
      expect(jsonStr, contains('37.7749'));
      expect(jsonStr, contains('-122.4194'));

      // Should NOT contain extra precision
      expect(jsonStr, isNot(contains('37.774901234567')));
    });

    test('empty points array produces valid message', () {
      final drawing = LineDrawing(
        id: 'empty-line',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      expect(message, isA<String>());
      expect(message, startsWith('D:'));
      expect(message, contains('"p":[]'));
    });

    test('large coordinate values are handled correctly', () {
      final drawing = LineDrawing(
        id: 'large-coords',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [
          LatLng(89.99999, 179.99999), // Near max valid coords
          LatLng(-89.99999, -179.99999), // Near min valid coords
        ],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      expect(message, isA<String>());
      expect(message, contains('89.99999'));
      expect(message, contains('179.99999'));
      expect(message, contains('-89.99999'));
      expect(message, contains('-179.99999'));
    });

    test('getDrawingTypeDisplay returns correct type names', () {
      final lineMsg = 'D:{"t":0,"c":1,"p":[1,2,3,4]}';
      final rectMsg = 'D:{"t":1,"c":2,"b":[1,2,3,4]}';

      expect(
        DrawingMessageParser.getDrawingTypeDisplay(lineMsg),
        equals('Line'),
      );
      expect(
        DrawingMessageParser.getDrawingTypeDisplay(rectMsg),
        equals('Rectangle'),
      );
      expect(DrawingMessageParser.getDrawingTypeDisplay('Invalid'), isNull);
    });

    test('getColorName returns correct color names', () {
      for (int i = 0; i < 8; i++) {
        final msg = 'D:{"t":0,"c":$i,"p":[0,0]}';
        final colorName = DrawingMessageParser.getColorName(msg);
        expect(colorName, isNotNull);
        expect(colorName, isA<String>());
      }

      expect(DrawingMessageParser.getColorName('Invalid'), isNull);
    });

    test('getDrawingMetadata extracts correct information', () {
      final lineMsg = 'D:{"t":0,"c":2,"p":[1,2,3,4,5,6]}';
      final metadata = DrawingMessageParser.getDrawingMetadata(lineMsg);

      expect(metadata, isNotNull);
      expect(metadata!['type'], equals('Line'));
      expect(metadata['color'], equals('Green'));
      expect(metadata['pointCount'], equals(3)); // 6 values = 3 points
    });

    test('message does not contain sender metadata in JSON', () {
      final drawing = LineDrawing(
        id: 'no-sender',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [LatLng(1, 2)],
        senderName: 'TestSender', // Should NOT be in network JSON
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      // CRITICAL: Sender name should NOT be in the message
      expect(message, isNot(contains('sender')));
      expect(message, isNot(contains('TestSender')));

      // Should only contain compact fields: t, c, p (or b)
      final jsonStr = message.substring(2);
      expect(jsonStr, contains('"t":'));
      expect(jsonStr, contains('"c":'));
      expect(jsonStr, matches(RegExp(r'"p":|"b":')));
    });

    test('special characters in metadata do not break format', () {
      // Even though sender name isn't included in network JSON,
      // test that it doesn't affect the message creation
      final drawing = LineDrawing(
        id: 'special-chars-"quotes"',
        color: DrawingColors.palette[0],
        createdAt: DateTime.now(),
        points: [LatLng(1, 2)],
      );

      final message = DrawingMessageParser.createDrawingMessage(drawing);

      expect(message, isA<String>());
      expect(message, startsWith('D:'));
      // Should still be parseable
      expect(
        () => DrawingMessageParser.parseDrawingMessage(message),
        returnsNormally,
      );
    });
  });
}
