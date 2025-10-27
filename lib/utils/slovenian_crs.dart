import 'dart:math' show Point;
import 'dart:ui' show Rect;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

/// EPSG:3794 - Slovenia 1996 / Slovene National Grid
/// Transverse Mercator projection for Slovenia
///
/// Official definition from https://epsg.io/3794:
/// +proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000
/// +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs
///
/// This CRS is used by Slovenian government WMS services (prostor.zgs.gov.si)

/// Register and get EPSG:3794 projection
proj4.Projection getEpsg3794Projection() {
  const epsg3794Def = '+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 '
      '+x_0=500000 +y_0=-5000000 +ellps=GRS80 '
      '+towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs';

  // Register projection if not already registered
  try {
    return proj4.Projection.get('EPSG:3794') ?? proj4.Projection.add('EPSG:3794', epsg3794Def);
  } catch (e) {
    // If already registered, get it
    return proj4.Projection.get('EPSG:3794')!;
  }
}

/// Create Proj4Crs for EPSG:3794
///
/// Configuration matches the GeoWebCache tile grid used by prostor.zgs.gov.si
///
/// Official tile grid from WMTS GetCapabilities:
/// - TopLeftCorner: 373217.6542445397, 246158.298050262
/// - Bounds: X: 373217.65 to 695777.65, Y: 31118.30 to 246158.30
/// - Tile size: 256x256 pixels
/// - Scale denominators converted to resolutions using: resolution = scaleDenom * 0.00028
Crs getSlovenianCrs() {
  final projection = getEpsg3794Projection();

  // Resolutions calculated from GeoWebCache scale denominators
  // Formula: resolution (m/px) = scaleDenominator * 0.00028 (OGC standard)
  final resolutions = <double>[
    420.0,    // Zoom 0  - ScaleDenom: 1500000
    280.0,    // Zoom 1  - ScaleDenom: 1000000
    210.0,    // Zoom 2  - ScaleDenom: 750000
    140.0,    // Zoom 3  - ScaleDenom: 500000
    70.0,     // Zoom 4  - ScaleDenom: 250000
    28.0,     // Zoom 5  - ScaleDenom: 100000
    14.0,     // Zoom 6  - ScaleDenom: 50000
    7.0,      // Zoom 7  - ScaleDenom: 25000
    4.2,      // Zoom 8  - ScaleDenom: 15000
    2.8,      // Zoom 9  - ScaleDenom: 10000
    1.4,      // Zoom 10 - ScaleDenom: 5000
    0.56,     // Zoom 11 - ScaleDenom: 2000
    0.28,     // Zoom 12 - ScaleDenom: 1000
    0.14,     // Zoom 13 - ScaleDenom: 500
    0.07,     // Zoom 14 - ScaleDenom: 250
    0.028,    // Zoom 15 - ScaleDenom: 100
  ];

  // Bounds from WMS capabilities (actual data extent in Slovenia)
  final bounds = Rect.fromLTRB(
    373217.65,  // min X (west)
    31118.30,   // min Y (south) - top in Rect coordinates
    695777.65,  // max X (east)
    246158.30,  // max Y (north) - bottom in Rect coordinates
  );

  // Origin from WMTS TileMatrixSet TopLeftCorner
  // This is the top-left corner of the tile pyramid (min X, max Y)
  final origin = Point<double>(373217.6542445397, 246158.298050262);

  return Proj4Crs.fromFactory(
    code: 'EPSG:3794',
    proj4Projection: projection,
    resolutions: resolutions,
    bounds: bounds,
    origins: [origin],
  );
}

/// Singleton instance of Slovenian CRS for reuse
final Crs slovenianCrs = getSlovenianCrs();
