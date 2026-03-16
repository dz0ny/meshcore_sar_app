import 'package:shared_preferences/shared_preferences.dart';

import '../models/config_profile.dart';
import '../providers/drawing_provider.dart';
import '../providers/map_provider.dart';
import 'profiles_feature_service.dart';

class MapWorkspaceSnapshotService {
  Future<MapWorkspaceProfileSection> capture({
    required MapProvider mapProvider,
    required DrawingProvider drawingProvider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return MapWorkspaceProfileSection(
      mapPrefs: {
        'map_rotate_with_heading':
            prefs.getBool(
              ProfileStorageScope.scopedKey('map_rotate_with_heading'),
            ) ??
            false,
        'map_show_debug_info':
            prefs.getBool(
              ProfileStorageScope.scopedKey('map_show_debug_info'),
            ) ??
            false,
        'map_fullscreen':
            prefs.getBool(ProfileStorageScope.scopedKey('map_fullscreen')) ??
            false,
        'map_last_latitude': prefs.getDouble(
          ProfileStorageScope.scopedKey('map_last_latitude'),
        ),
        'map_last_longitude': prefs.getDouble(
          ProfileStorageScope.scopedKey('map_last_longitude'),
        ),
        'map_last_zoom': prefs.getDouble(
          ProfileStorageScope.scopedKey('map_last_zoom'),
        ),
        'map_last_layer_type': prefs.getInt(
          ProfileStorageScope.scopedKey('map_last_layer_type'),
        ),
        'map_gps_update_distance': prefs.getDouble(
          ProfileStorageScope.scopedKey('map_gps_update_distance'),
        ),
        'background_tracking_enabled': prefs.getBool(
          ProfileStorageScope.scopedKey('background_tracking_enabled'),
        ),
      },
      drawings: drawingProvider.exportDrawingsJson(),
      currentTrail: mapProvider.currentTrail?.toJson(),
      trailHistory: mapProvider.trailHistory
          .map((trail) => trail.toJson())
          .toList(),
      importedTrail: mapProvider.importedTrail?.toJson(),
      isTrailVisible: mapProvider.isTrailVisible,
      showCadastralOverlay: mapProvider.showCadastralOverlay,
      showForestRoadsOverlay: mapProvider.showForestRoadsOverlay,
      showHikingTrailsOverlay: mapProvider.showHikingTrailsOverlay,
      showMainRoadsOverlay: mapProvider.showMainRoadsOverlay,
      showHouseNumbersOverlay: mapProvider.showHouseNumbersOverlay,
      showFireHazardZonesOverlay: mapProvider.showFireHazardZonesOverlay,
      showHistoricalFiresOverlay: mapProvider.showHistoricalFiresOverlay,
      showFirebreaksOverlay: mapProvider.showFirebreaksOverlay,
      showKrasFireZonesOverlay: mapProvider.showKrasFireZonesOverlay,
      showPlaceNamesOverlay: mapProvider.showPlaceNamesOverlay,
      showMunicipalityBordersOverlay:
          mapProvider.showMunicipalityBordersOverlay,
      showAllContactTrails: mapProvider.showAllContactTrails,
      hideRepeatersOnMap: mapProvider.hideRepeatersOnMap,
    );
  }

  Future<void> apply(
    MapWorkspaceProfileSection? section, {
    required MapProvider mapProvider,
    required DrawingProvider drawingProvider,
  }) async {
    if (section == null || section.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final mapPrefs = section.mapPrefs ?? const <String, dynamic>{};
    for (final entry in mapPrefs.entries) {
      final key = ProfileStorageScope.scopedKey(entry.key);
      final value = entry.value;
      if (value == null) {
        await prefs.remove(key);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    }

    mapProvider.applyWorkspaceJson(section.toJson());
    await drawingProvider.replaceDrawingsFromJson(section.drawings);
  }
}
