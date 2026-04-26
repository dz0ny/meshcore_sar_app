import 'dart:math' as math;

enum CoordinateDisplayFormat { decimal, dms, utm }

String formatCoordinates(
  double latitude,
  double longitude,
  CoordinateDisplayFormat format,
) {
  switch (format) {
    case CoordinateDisplayFormat.decimal:
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    case CoordinateDisplayFormat.dms:
      return '${formatDmsCoordinate(latitude, true)} ${formatDmsCoordinate(longitude, false)}';
    case CoordinateDisplayFormat.utm:
      return formatUtm(latitude, longitude);
  }
}

String formatDmsCoordinate(double degrees, bool isLatitude) {
  final direction = isLatitude
      ? (degrees >= 0 ? 'N' : 'S')
      : (degrees >= 0 ? 'E' : 'W');

  final absolute = degrees.abs();
  final deg = absolute.floor();
  final minDecimal = (absolute - deg) * 60;
  final min = minDecimal.floor();
  final sec = (minDecimal - min) * 60;

  return '$deg°${min.toString().padLeft(2, '0')}\'${sec.toStringAsFixed(2).padLeft(5, '0')}"$direction';
}

String formatUtm(double latitude, double longitude) {
  if (latitude < -80 || latitude > 84) {
    return formatCoordinates(
      latitude,
      longitude,
      CoordinateDisplayFormat.decimal,
    );
  }

  final zone = _utmZone(latitude, longitude);
  final band = _utmLatitudeBand(latitude);
  final latRad = _degreesToRadians(latitude);
  final lonRad = _degreesToRadians(longitude);
  final centralMeridianRad = _degreesToRadians((zone - 1) * 6 - 180 + 3);

  const semiMajorAxis = 6378137.0;
  const flattening = 1 / 298.257223563;
  const scaleFactor = 0.9996;
  final eccentricitySquared = flattening * (2 - flattening);
  final secondEccentricitySquared =
      eccentricitySquared / (1 - eccentricitySquared);

  final sinLat = math.sin(latRad);
  final cosLat = math.cos(latRad);
  final tanLat = math.tan(latRad);
  final n = semiMajorAxis /
      math.sqrt(1 - eccentricitySquared * sinLat * sinLat);
  final t = tanLat * tanLat;
  final c = secondEccentricitySquared * cosLat * cosLat;
  final a = cosLat * (lonRad - centralMeridianRad);

  final meridianArc = semiMajorAxis *
      ((1 -
                  eccentricitySquared / 4 -
                  3 * eccentricitySquared * eccentricitySquared / 64 -
                  5 *
                      eccentricitySquared *
                      eccentricitySquared *
                      eccentricitySquared /
                      256) *
              latRad -
          (3 * eccentricitySquared / 8 +
                  3 * eccentricitySquared * eccentricitySquared / 32 +
                  45 *
                      eccentricitySquared *
                      eccentricitySquared *
                      eccentricitySquared /
                      1024) *
              math.sin(2 * latRad) +
          (15 * eccentricitySquared * eccentricitySquared / 256 +
                  45 *
                      eccentricitySquared *
                      eccentricitySquared *
                      eccentricitySquared /
                      1024) *
              math.sin(4 * latRad) -
          (35 *
                  eccentricitySquared *
                  eccentricitySquared *
                  eccentricitySquared /
                  3072) *
              math.sin(6 * latRad));

  final easting = scaleFactor *
          n *
          (a +
              (1 - t + c) * a * a * a / 6 +
              (5 - 18 * t + t * t + 72 * c - 58 * secondEccentricitySquared) *
                  a *
                  a *
                  a *
                  a *
                  a /
                  120) +
      500000;
  var northing = scaleFactor *
      (meridianArc +
          n *
              tanLat *
              (a * a / 2 +
                  (5 - t + 9 * c + 4 * c * c) * a * a * a * a / 24 +
                  (61 -
                          58 * t +
                          t * t +
                          600 * c -
                          330 * secondEccentricitySquared) *
                      a *
                      a *
                      a *
                      a *
                      a *
                      a /
                      720));
  if (latitude < 0) {
    northing += 10000000;
  }

  return '$zone$band ${easting.round()}E ${northing.round()}N';
}

int _utmZone(double latitude, double longitude) {
  var zone = ((longitude + 180) / 6).floor() + 1;
  if (longitude == 180) {
    zone = 60;
  }
  if (latitude >= 56 &&
      latitude < 64 &&
      longitude >= 3 &&
      longitude < 12) {
    zone = 32;
  }
  if (latitude >= 72 && latitude < 84) {
    if (longitude >= 0 && longitude < 9) {
      zone = 31;
    } else if (longitude >= 9 && longitude < 21) {
      zone = 33;
    } else if (longitude >= 21 && longitude < 33) {
      zone = 35;
    } else if (longitude >= 33 && longitude < 42) {
      zone = 37;
    }
  }
  return zone.clamp(1, 60);
}

String _utmLatitudeBand(double latitude) {
  const bands = 'CDEFGHJKLMNPQRSTUVWX';
  final index = ((latitude + 80) / 8).floor().clamp(0, bands.length - 1);
  return bands[index];
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

String formatPlusCode(double lat, double lon) {
  const base = '23456789CFGHJMPQRVWX';

  var normalizedLat = (lat + 90) / 180;
  var normalizedLon = (lon + 180) / 360;

  final buffer = StringBuffer();
  for (var i = 0; i < 8; i++) {
    if (i == 4) {
      buffer.write('+');
    }

    final latDigit = (normalizedLat * 20).floor() % 20;
    final lonDigit = (normalizedLon * 20).floor() % 20;

    buffer
      ..write(base[latDigit])
      ..write(base[lonDigit]);

    normalizedLat = (normalizedLat * 20) % 1;
    normalizedLon = (normalizedLon * 20) % 1;
  }

  return buffer.toString();
}
