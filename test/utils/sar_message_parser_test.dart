import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/sar_marker.dart';
import 'package:meshcore_sar_app/models/map_coordinate_space.dart';
import 'package:meshcore_sar_app/utils/sar_message_parser.dart';

void main() {
  group('SarMessageParser - Critical String Formatting Tests', () {
    test('createSarMessage returns raw string, not Object', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(37.7749, -122.4194),
        colorIndex: 2,
      );

      // CRITICAL: Must be a String type
      expect(message, isA<String>());

      // CRITICAL: Must NOT contain "Instance of" or "Object"
      expect(message, isNot(contains('Instance of')));
      expect(message, isNot(contains('Object')));
      expect(message, isNot(contains('LatLng')));

      // CRITICAL: Must start with S: prefix
      expect(message, startsWith('S:'));
    });

    test('createSarMessage produces correct format with all components', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(37.7749, -122.4194),
        notes: 'Found alive',
        colorIndex: 2,
      );

      // New format: S:<emoji>:<colorIndex>:<lat>,<lon>:<notes>
      expect(message, startsWith('S:'));
      expect(message, contains('🧑')); // or 👤
      expect(message, contains(':2:')); // color index
      expect(message, contains('37.7749'));
      expect(message, contains('-122.4194'));
      expect(message, contains('Found alive'));
    });

    test('coordinates are converted to strings properly', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.fire,
        location: LatLng(40.7128, -74.0060),
        colorIndex: 0,
      );

      // CRITICAL: Coordinates must be in string form, not Object
      expect(message, contains('40.7128'));
      expect(
        message,
        contains('-74.006'),
      ); // Trailing zero trimmed by toString()

      // Must NOT contain object representation
      expect(message, isNot(contains('LatLng')));
      expect(message, isNot(contains('latitude:')));
      expect(message, isNot(contains('longitude:')));
    });

    test('colorIndex is converted to string in format', () {
      for (int i = 0; i <= 7; i++) {
        final message = SarMessageParser.createSarMessage(
          type: SarMarkerType.stagingArea,
          location: LatLng(0, 0),
          colorIndex: i,
        );

        // Color index should be in string
        expect(message, contains(':$i:'));
        expect(message, isA<String>());
      }
    });

    test('null colorIndex defaults to 0', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(1, 1),
        colorIndex: null,
      );

      // Should default to color index 0
      expect(message, contains(':0:'));
    });

    test('isSarMessage correctly identifies SAR messages', () {
      expect(SarMessageParser.isSarMessage('S:🧑:2:37.7,-122.4'), isTrue);
      expect(SarMessageParser.isSarMessage('S:🔥:0:40.7,-74.0:Fire'), isTrue);
      expect(SarMessageParser.isSarMessage('D:{"t":0}'), isFalse);
      expect(SarMessageParser.isSarMessage('Plain text'), isFalse);
    });

    test('parse correctly extracts all components', () {
      final message = 'S:🧑:2:37.7749,-122.4194:Found alive';
      final info = SarMessageParser.parse(message);

      expect(info, isNotNull);
      expect(info!.type, equals(SarMarkerType.foundPerson));
      expect(info.location.latitude, equals(37.7749));
      expect(info.location.longitude, equals(-122.4194));
      expect(info.colorIndex, equals(2));
      expect(info.notes, contains('Found alive'));
    });

    test('parse handles old format without color index', () {
      // Old format: S:<emoji>:<lat>,<lon>:<notes>
      final message = 'S:🔥:40.7128,-74.0060:Large fire';
      final info = SarMessageParser.parse(message);

      expect(info, isNotNull);
      expect(info!.type, equals(SarMarkerType.fire));
      expect(info.location.latitude, equals(40.7128));
      expect(info.location.longitude, equals(-74.0060));
      expect(info.colorIndex, isNull); // Old format has no color index
      expect(info.notes, equals('Large fire'));
    });

    test('custom-map SAR markers use S2 format and preserve map metadata', () {
      final message = SarMessageParser.createCustomMapSarMessage(
        emoji: '📦',
        mapId: 'abcdef1234567890',
        point: LatLng(250, 400),
        notes: 'Cache location',
        colorIndex: 4,
      );

      expect(message, startsWith('S2:'));

      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
      expect(parsed!.coordinateSpace, MapCoordinateSpace.customMap);
      expect(parsed.mapId, 'abcdef123456');
      expect(parsed.location.latitude, 250);
      expect(parsed.location.longitude, 400);
      expect(parsed.notes, 'Cache location');
    });

    test('round-trip: create -> parse -> create preserves format', () {
      final original = SarMessageParser.createSarMessage(
        type: SarMarkerType.stagingArea,
        location: LatLng(51.5074, -0.1278),
        notes: 'Command center',
        colorIndex: 4,
      );

      // Parse it
      final parsed = SarMessageParser.parse(original);
      expect(parsed, isNotNull);

      // Create again
      final recreated = SarMessageParser.createSarMessage(
        type: parsed!.type,
        location: parsed.location,
        notes: parsed.notes,
        colorIndex: parsed.colorIndex,
      );

      // Should be identical
      expect(recreated, equals(original));
    });

    test('negative coordinates are handled correctly', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(-33.8688, -151.2093), // Sydney (negative coords)
        colorIndex: 1,
      );

      expect(message, contains('-33.8688'));
      expect(message, contains('-151.2093'));

      // Should be parseable
      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
      expect(parsed!.location.latitude, equals(-33.8688));
      expect(parsed.location.longitude, equals(-151.2093));
    });

    test('extreme valid coordinates work correctly', () {
      // Test near max valid latitude/longitude
      final message1 = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(89.99999, 179.99999),
        colorIndex: 0,
      );

      expect(message1, contains('89.99999'));
      expect(message1, contains('179.99999'));

      // Test near min valid latitude/longitude
      final message2 = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(-89.99999, -179.99999),
        colorIndex: 0,
      );

      expect(message2, contains('-89.99999'));
      expect(message2, contains('-179.99999'));
    });

    test('parse rejects invalid coordinates', () {
      expect(SarMessageParser.parse('S:🧑:0:91.0,0'), isNull); // lat > 90
      expect(SarMessageParser.parse('S:🧑:0:-91.0,0'), isNull); // lat < -90
      expect(SarMessageParser.parse('S:🧑:0:0,181.0'), isNull); // lon > 180
      expect(SarMessageParser.parse('S:🧑:0:0,-181.0'), isNull); // lon < -180
    });

    test('parse rejects invalid color indices', () {
      // Color index should be 0-7
      final message = 'S:🧑:9:37.7,-122.4'; // Invalid index 9
      final info = SarMessageParser.parse(message);

      expect(info, isNotNull);
      expect(info!.colorIndex, isNull); // Should be ignored if invalid
    });

    test('notes with special characters are preserved', () {
      final notes = 'Multi-line\nwith: colons, commas';
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(1, 2),
        notes: notes,
        colorIndex: 0,
      );

      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
      expect(parsed!.notes, contains('Multi-line'));
      expect(parsed.notes, contains('colons, commas'));
    });

    test('empty notes produce valid message', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.fire,
        location: LatLng(1, 2),
        notes: '',
        colorIndex: 0,
      );

      // Should not have trailing colon
      expect(message, isNot(endsWith(':')));

      // Should be parseable
      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
    });

    test('null notes produce valid message', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.stagingArea,
        location: LatLng(1, 2),
        notes: null,
        colorIndex: 0,
      );

      // Should not have notes section
      expect(message, isNot(endsWith(':')));

      // Should be parseable
      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
    });

    test('all emoji types produce valid strings', () {
      final types = [
        SarMarkerType.foundPerson,
        SarMarkerType.fire,
        SarMarkerType.stagingArea,
      ];

      for (final type in types) {
        final message = SarMessageParser.createSarMessage(
          type: type,
          location: LatLng(1, 2),
          colorIndex: 0,
        );

        expect(message, isA<String>());
        expect(message, startsWith('S:'));
        expect(message, contains(type.emoji));

        // Must not contain type name or object representation
        expect(message, isNot(contains('SarMarkerType')));
        expect(message, isNot(contains('Instance')));
      }
    });

    test('isValidFormat correctly validates messages', () {
      expect(
        SarMessageParser.isValidFormat('S:🧑:2:37.7749,-122.4194'),
        isTrue,
      );

      expect(SarMessageParser.isValidFormat('S:invalid:format'), isFalse);

      expect(SarMessageParser.isValidFormat('Not SAR message'), isFalse);
    });

    test('getFormatError provides helpful error messages', () {
      expect(
        SarMessageParser.getFormatError('Not SAR'),
        contains('must start with "S:"'),
      );

      expect(SarMessageParser.getFormatError('S:'), contains('Invalid format'));

      expect(
        SarMessageParser.getFormatError('S::37.7,-122.4'),
        contains('Missing emoji'),
      );
    });

    test('extractNotes correctly handles multi-line messages', () {
      final message = 'S:🧑:0:37.7,-122.4:First line\nSecond line\nThird line';
      final notes = SarMessageParser.extractNotes(message);

      expect(notes, isNotNull);
      expect(notes, contains('Second line'));
      expect(notes, contains('Third line'));
    });

    test('message format is compact and efficient', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(37.7749, -122.4194),
        colorIndex: 2,
      );

      // Should be very compact: S:🧑:2:37.7749,-122.4194
      expect(message.length, lessThan(50));

      // Should not have extra whitespace
      expect(message, isNot(contains('  ')));
      expect(message, isNot(contains('\n')));
    });

    test('coordinates maintain precision', () {
      final precise = LatLng(37.774901234, -122.419401234);
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: precise,
        colorIndex: 0,
      );

      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);

      // Should maintain reasonable precision (Dart's toString default)
      expect(parsed!.location.latitude, closeTo(37.774901234, 0.000001));
      expect(parsed.location.longitude, closeTo(-122.419401234, 0.000001));
    });

    test('zero coordinates work correctly', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.stagingArea,
        location: LatLng(0.0, 0.0),
        colorIndex: 0,
      );

      expect(message, contains('0.0,0.0'));

      final parsed = SarMessageParser.parse(message);
      expect(parsed, isNotNull);
      expect(parsed!.location.latitude, equals(0.0));
      expect(parsed.location.longitude, equals(0.0));
    });

    test('emoji is preserved as string, not code points', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(1, 2),
        colorIndex: 0,
      );

      // Should contain actual emoji character
      expect(message, contains('🧑'));

      // Should NOT contain unicode code points or escape sequences
      expect(message, isNot(contains(r'\u')));
      expect(message, isNot(contains('U+')));
    });

    test('format is compatible with CLAUDE.md specification', () {
      // According to CLAUDE.md:
      // New format: S:<emoji>:<colorIndex>:<latitude>,<longitude>:<optional_message>
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.fire,
        location: LatLng(40.7128, -74.0060),
        notes: 'Large wildfire spreading rapidly',
        colorIndex: 0,
      );

      // Should match: S:🔥:0:40.7128,-74.006:Large wildfire spreading rapidly
      expect(message, startsWith('S:🔥:0:'));
      expect(message, contains('40.7128,-74.006')); // Trailing zero trimmed
      expect(message, endsWith('Large wildfire spreading rapidly'));
    });

    test('backward compatibility with old format', () {
      // Old format without color index: S:<emoji>:<lat>,<lon>:<notes>
      final oldMessage = 'S:🧑:37.7749,-122.4194:Found person';
      final parsed = SarMessageParser.parse(oldMessage);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SarMarkerType.foundPerson));
      expect(parsed.colorIndex, isNull); // Old format has no color index
      expect(parsed.notes, equals('Found person'));
    });

    test('new format with color index is preferred', () {
      final message = SarMessageParser.createSarMessage(
        type: SarMarkerType.foundPerson,
        location: LatLng(1, 2),
        colorIndex: 3,
      );

      // Should use new format with color index
      expect(message, contains(':3:'));
      expect(message, contains('🧑'));
    });

    test('toString produces human-readable output for SarMarkerInfo', () {
      final info = SarMarkerInfo(
        type: SarMarkerType.foundPerson,
        location: LatLng(37.7749, -122.4194),
        emoji: '🧑',
        notes: 'Test notes',
        colorIndex: 2,
        coordinateSpace: MapCoordinateSpace.geo,
      );

      final str = info.toString();
      expect(str, contains('SarMarkerInfo'));
      expect(str, contains('Found Person')); // Display name, not enum name
      expect(str, contains('colorIndex: 2'));
    });
  });
}
