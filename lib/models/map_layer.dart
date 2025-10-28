import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../l10n/app_localizations.dart';

enum MapLayerType {
  openStreetMap,
  openTopoMap,
  esriWorldImagery,
  googleHybrid,
  googleRoadmap,
  googleTerrain,
  vectorMbtiles,
  wmsBase,
}

class MapLayer {
  final MapLayerType type;
  final String name;
  final String urlTemplate;
  final String attribution;
  final double maxZoom;

  // Vector tile specific properties
  final bool isVector;
  final File? mbtilesFile;
  final String? styleUrl;
  final String? sourceName;
  final bool? isGzipped;

  // WMS specific properties
  final bool isWms;
  final String? wmsBaseUrl;
  final List<String>? wmsLayers;
  final String? wmsFormat;
  final bool? wmsTransparent;
  final List<String>? wmsStyles;
  final Crs? crs;

  const MapLayer({
    required this.type,
    required this.name,
    required this.urlTemplate,
    required this.attribution,
    required this.maxZoom,
    this.isVector = false,
    this.mbtilesFile,
    this.styleUrl,
    this.sourceName,
    this.isGzipped,
    this.isWms = false,
    this.wmsBaseUrl,
    this.wmsLayers,
    this.wmsFormat,
    this.wmsTransparent,
    this.wmsStyles,
    this.crs,
  });

  /// Get localized name for the layer
  String getLocalizedName(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (type) {
      case MapLayerType.openStreetMap:
        return localizations.openStreetMap;
      case MapLayerType.openTopoMap:
        return localizations.openTopoMap;
      case MapLayerType.esriWorldImagery:
        return localizations.esriSatellite;
      case MapLayerType.googleHybrid:
        return localizations.googleHybrid;
      case MapLayerType.googleRoadmap:
        return localizations.googleRoadmap;
      case MapLayerType.googleTerrain:
        return localizations.googleTerrain;
      case MapLayerType.vectorMbtiles:
        // For vector tiles, use the name from metadata
        return name;
      case MapLayerType.wmsBase:
        // For WMS layers, use the name (will be localized separately)
        return name;
    }
  }

  static const openStreetMap = MapLayer(
    type: MapLayerType.openStreetMap,
    name: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19, // OSM standard maximum
  );

  static const openTopoMap = MapLayer(
    type: MapLayerType.openTopoMap,
    name: 'OpenTopoMap',
    urlTemplate: 'https://a.tile.opentopomap.org/{z}/{x}/{y}.png',
    attribution: '© OpenTopoMap (CC-BY-SA)',
    maxZoom: 17.49, // OpenTopoMap maximum (just below level 18)
  );

  static const esriWorldImagery = MapLayer(
    type: MapLayerType.esriWorldImagery,
    name: 'ESRI Satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
    maxZoom: 19, // ESRI World Imagery maximum
  );

  static const googleHybrid = MapLayer(
    type: MapLayerType.googleHybrid,
    name: 'Google Hybrid',
    urlTemplate: 'http://mt0.google.com/vt/lyrs=y&hl=en&x={x}&y={y}&z={z}',
    attribution: '© Google',
    maxZoom: 20, // Google Maps maximum
  );

  static const googleRoadmap = MapLayer(
    type: MapLayerType.googleRoadmap,
    name: 'Google Roadmap',
    urlTemplate: 'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
    attribution: '© Google',
    maxZoom: 20, // Google Maps maximum
  );

  static const googleTerrain = MapLayer(
    type: MapLayerType.googleTerrain,
    name: 'Google Terrain',
    urlTemplate: 'http://mt0.google.com/vt/lyrs=p&hl=en&x={x}&y={y}&z={z}',
    attribution: '© Google',
    maxZoom: 20, // Google Maps maximum
  );

  /// Slovenian Aerial Imagery 2024 (Ortofoto) - WMS Base Layer
  /// Uses EPSG:3794 coordinate system (GeoWebCache tile matrix zoom 0-15)
  /// Note: CRS is initialized at runtime in getSlovenianAerial2024()
  static MapLayer getSlovenianAerial2024(Crs slovenianCrs) {
    return MapLayer(
      type: MapLayerType.wmsBase,
      name: 'Ortofoto 2024 (Slovenija)',
      urlTemplate: '', // Not used for WMS
      attribution: '© GURS (Geodetska uprava Republike Slovenije)',
      maxZoom: 15, // GeoWebCache tile matrix maximum
      isWms: true,
      wmsBaseUrl: 'https://prostor.zgs.gov.si/geowebcache/service/wms?',
      wmsLayers: const ['pregledovalnik:DOF_2024'],
      wmsFormat: 'image/jpeg',
      wmsTransparent: false,
      crs: slovenianCrs,
    );
  }

  /// Slovenian Topographic Map 1:25000 (DTK25) - WMS Base Layer
  /// Uses EPSG:3794 coordinate system (GeoWebCache tile matrix zoom 0-15)
  /// Note: CRS is initialized at runtime in getDTK25()
  static MapLayer getDTK25(Crs slovenianCrs) {
    return MapLayer(
      type: MapLayerType.wmsBase,
      name: 'DTK25 (Slovenija)',
      urlTemplate: '', // Not used for WMS
      attribution: '© GURS (Geodetska uprava Republike Slovenije)',
      maxZoom: 15, // GeoWebCache tile matrix maximum
      isWms: true,
      wmsBaseUrl: 'https://prostor.zgs.gov.si/geowebcache/service/wms?',
      wmsLayers: const ['pregledovalnik:DTK25'],
      wmsFormat: 'image/jpeg',
      wmsTransparent: false,
      crs: slovenianCrs,
    );
  }

  static const List<MapLayer> allLayers = [
    openStreetMap,
    openTopoMap,
    esriWorldImagery,
    googleHybrid,
    googleRoadmap,
    googleTerrain,
    // Note: Slovenian aerial layer is added dynamically via getSlovenianAerial2024()
  ];

  static MapLayer fromType(MapLayerType type) {
    return allLayers.firstWhere((layer) => layer.type == type);
  }

  /// Create a MapLayer from an MBTiles file
  static MapLayer fromMbtilesFile({
    required String name,
    required File mbtilesFile,
    required String styleUrl,
    required String sourceName,
    required double maxZoom,
    required bool isGzipped,
    String? attribution,
  }) {
    return MapLayer(
      type: MapLayerType.vectorMbtiles,
      name: name,
      urlTemplate: '', // Not used for vector tiles
      attribution: attribution ?? 'MBTiles',
      maxZoom: maxZoom,
      isVector: true,
      mbtilesFile: mbtilesFile,
      styleUrl: styleUrl,
      sourceName: sourceName,
      isGzipped: isGzipped,
    );
  }
}
