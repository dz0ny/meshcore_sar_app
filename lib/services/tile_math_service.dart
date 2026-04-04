import 'dart:math';

import 'package:latlong2/latlong.dart';

/// A tile coordinate with x, y, and zoom level.
class TileCoord {
  final int x;
  final int y;
  final int z;

  const TileCoord(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) =>
      other is TileCoord && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'TileCoord($z/$x/$y)';
}

/// A geographical bounding box.
class TileBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const TileBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

/// Pure math utilities for slippy map tile calculations.
///
/// Ported from the Go offline-map-tile-downloader.
class TileMathService {
  const TileMathService._();

  /// Convert latitude/longitude to tile coordinates at the given zoom level.
  static (int x, int y) latLonToTile(double lat, double lon, int zoom) {
    final latRad = lat * pi / 180;
    final n = pow(2, zoom).toDouble();
    final x = (n * ((lon + 180) / 360)).floor();
    final y =
        (n * (1 - (log(tan(latRad) + 1 / cos(latRad)) / pi)) / 2).floor();
    return (x, y);
  }

  /// Calculate the geographical bounding box of a tile.
  static TileBounds tileBounds(int x, int y, int z) {
    final n = pow(2.0, z).toDouble();
    final lonDeg = x / n * 360.0 - 180.0;
    final latRad = atan(sinh(pi * (1 - 2 * y / n)));
    final latDeg = latRad * 180.0 / pi;

    final lon2Deg = (x + 1) / n * 360.0 - 180.0;
    final lat2Rad = atan(sinh(pi * (1 - 2 * (y + 1) / n)));
    final lat2Deg = lat2Rad * 180.0 / pi;

    return TileBounds(
      north: latDeg,
      south: lat2Deg,
      east: lon2Deg,
      west: lonDeg,
    );
  }

  /// Hyperbolic sine.
  static double sinh(double x) => (exp(x) - exp(-x)) / 2;

  /// Check if a point is inside a polygon using the ray casting algorithm.
  static bool polygonContains(List<LatLng> poly, LatLng point) {
    var inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if ((poly[i].latitude > point.latitude) !=
              (poly[j].latitude > point.latitude) &&
          (point.longitude <
              (poly[j].longitude - poly[i].longitude) *
                      (point.latitude - poly[i].latitude) /
                      (poly[j].latitude - poly[i].latitude) +
                  poly[i].longitude)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Check if a bounding box contains a point.
  static bool boundsContains(TileBounds bounds, LatLng point) {
    return point.latitude <= bounds.north &&
        point.latitude >= bounds.south &&
        point.longitude >= bounds.west &&
        point.longitude <= bounds.east;
  }

  /// Check if a polygon intersects with a tile bounding box.
  static bool polygonIntersects(List<LatLng> poly, TileBounds bounds) {
    // Check if any polygon vertex is inside the tile
    for (final p in poly) {
      if (boundsContains(bounds, p)) return true;
    }

    // Check if any tile corner is inside the polygon
    final corners = [
      LatLng(bounds.north, bounds.west),
      LatLng(bounds.north, bounds.east),
      LatLng(bounds.south, bounds.west),
      LatLng(bounds.south, bounds.east),
    ];
    for (final corner in corners) {
      if (polygonContains(poly, corner)) return true;
    }

    // Check if any polygon edge intersects any tile edge
    final tileEdges = [
      (corners[0], corners[1]),
      (corners[1], corners[3]),
      (corners[3], corners[2]),
      (corners[2], corners[0]),
    ];
    for (int i = 0; i < poly.length; i++) {
      final p1 = poly[i];
      final p2 = poly[(i + 1) % poly.length];
      for (final edge in tileEdges) {
        if (_lineIntersects(p1, p2, edge.$1, edge.$2)) return true;
      }
    }

    return false;
  }

  /// Check if two line segments intersect.
  static bool _lineIntersects(LatLng p1, LatLng q1, LatLng p2, LatLng q2) {
    final o1 = _orientation(p1, q1, p2);
    final o2 = _orientation(p1, q1, q2);
    final o3 = _orientation(p2, q2, p1);
    final o4 = _orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && _onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && _onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && _onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && _onSegment(p2, q1, q2)) return true;

    return false;
  }

  /// Find orientation of ordered triplet (p, q, r).
  /// Returns 0 for collinear, 1 for clockwise, 2 for counterclockwise.
  static int _orientation(LatLng p, LatLng q, LatLng r) {
    final val = (q.longitude - p.longitude) * (r.latitude - q.latitude) -
        (q.latitude - p.latitude) * (r.longitude - q.longitude);
    if (val == 0) return 0;
    return val > 0 ? 1 : 2;
  }

  /// Check if point q lies on segment pr.
  static bool _onSegment(LatLng p, LatLng q, LatLng r) {
    return q.latitude <= max(p.latitude, r.latitude) &&
        q.latitude >= min(p.latitude, r.latitude) &&
        q.longitude <= max(p.longitude, r.longitude) &&
        q.longitude >= min(p.longitude, r.longitude);
  }

  /// Get all tiles that overlap with the given polygons across zoom levels.
  static List<TileCoord> getTilesForPolygons(
    List<List<LatLng>> polygons,
    int minZoom,
    int maxZoom,
  ) {
    final tileSet = <TileCoord>{};

    for (final poly in polygons) {
      if (poly.length < 3) continue;

      // Find bounding box of polygon
      var minLat = 90.0, minLon = 180.0;
      var maxLat = -90.0, maxLon = -180.0;
      for (final p in poly) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }

      for (int z = minZoom; z <= maxZoom; z++) {
        final (tlx, tly) = latLonToTile(maxLat, minLon, z);
        final (brx, bry) = latLonToTile(minLat, maxLon, z);

        for (int x = tlx; x <= brx; x++) {
          for (int y = tly; y <= bry; y++) {
            final tile = TileCoord(x, y, z);
            if (tileSet.contains(tile)) continue;

            final bounds = tileBounds(x, y, z);

            // Check if all tile corners are inside the polygon
            final allCornersInside = polygonContains(
                    poly, LatLng(bounds.north, bounds.west)) &&
                polygonContains(poly, LatLng(bounds.north, bounds.east)) &&
                polygonContains(poly, LatLng(bounds.south, bounds.west)) &&
                polygonContains(poly, LatLng(bounds.south, bounds.east));
            if (allCornersInside) {
              tileSet.add(tile);
              continue;
            }

            // Check if all polygon vertices are inside the tile
            var polyInTile = true;
            for (final p in poly) {
              if (!boundsContains(bounds, p)) {
                polyInTile = false;
                break;
              }
            }
            if (polyInTile) {
              tileSet.add(tile);
              continue;
            }

            // Check for intersection
            if (polygonIntersects(poly, bounds)) {
              tileSet.add(tile);
            }
          }
        }
      }
    }

    return tileSet.toList();
  }

  /// Estimate the number of tiles for given polygons and zoom range.
  /// Faster than getTilesForPolygons — uses bounding box approximation.
  static int estimateTileCount(
    List<List<LatLng>> polygons,
    int minZoom,
    int maxZoom,
  ) {
    var count = 0;
    for (final poly in polygons) {
      if (poly.length < 3) continue;

      var minLat = 90.0, minLon = 180.0;
      var maxLat = -90.0, maxLon = -180.0;
      for (final p in poly) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
      }

      for (int z = minZoom; z <= maxZoom; z++) {
        final (tlx, tly) = latLonToTile(maxLat, minLon, z);
        final (brx, bry) = latLonToTile(minLat, maxLon, z);
        count += (brx - tlx + 1) * (bry - tly + 1);
      }
    }
    return count;
  }
}
