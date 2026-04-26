import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/location_formats.dart';

void main() {
  group('formatUtm', () {
    test('formats northern hemisphere UTM coordinates', () {
      expect(formatUtm(37.7749, -122.4194), '10S 551131E 4180999N');
    });

    test('formats southern hemisphere UTM coordinates', () {
      expect(formatUtm(-33.8688, 151.2093), '56H 334369E 6250948N');
    });

    test('falls back to decimal outside the UTM latitude range', () {
      expect(formatUtm(85, 14.5), '85.00000, 14.50000');
    });
  });

  group('formatCoordinates', () {
    test('formats DMS coordinates', () {
      expect(
        formatCoordinates(
          46.0569,
          14.5058,
          CoordinateDisplayFormat.dms,
        ),
        '46°03\'24.84"N 14°30\'20.88"E',
      );
    });
  });
}
