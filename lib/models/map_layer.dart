import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum MapLayerType {
  openStreetMap,
  openTopoMap,
  esriWorldImagery,
  vectorMbtiles,
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
      case MapLayerType.vectorMbtiles:
        // For vector tiles, use the name from metadata
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

  static const List<MapLayer> allLayers = [
    openStreetMap,
    openTopoMap,
    esriWorldImagery,
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
