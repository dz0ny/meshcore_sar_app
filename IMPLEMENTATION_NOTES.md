# Vector Map Tiles Implementation - Technical Notes

## Successfully Implemented! ✅

The vector map tiles with MBTiles support has been successfully implemented and the app builds without errors.

## Final Package Versions

```yaml
vector_map_tiles: ^9.0.0-beta.8  # flutter_map 8.x compatible!
vector_map_tiles_mbtiles: 1.2.1  # from git repository (latest)
vector_tile_renderer: ^6.0.0
mbtiles: ^0.4.2
file_picker: ^8.3.7
http: 1.5.0
```

### Why Git Dependency?

The published version of `vector_map_tiles_mbtiles` on pub.dev doesn't support `vector_map_tiles` v9 beta yet. The git version from the flutter_map_plugins repository is compatible:

```yaml
vector_map_tiles_mbtiles:
  git:
    url: https://github.com/josxha/flutter_map_plugins.git
    path: vector_map_tiles_mbtiles
```

## API Compatibility Issues Resolved

### 1. Name Collision: Theme

**Problem**: Both Flutter Material and vector_tile_renderer export a `Theme` class.

**Solution**: Import vector_tile_renderer with alias:
```dart
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

// Usage
vtr.Theme? _vectorTheme;
final theme = vtr.ThemeReader().read(styleJson);
```

### 2. Name Collision: TileLayer

**Problem**: Both flutter_map and vector_tile_renderer export `TileLayer`.

**Solution**: Import flutter_map with alias for explicit TileLayer usage:
```dart
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_map/flutter_map.dart'; // Keep non-aliased for other classes

// Usage
flutter_map.TileLayer(...)
```

### 3. MBTiles API Changes

**Problem**: The `mbtiles` package v0.4.2 changed from Map-based to object-based API.

**Old API (v0.3.x)**:
```dart
final metadata = await mbtiles.getMetadata();
final name = metadata['name'];  // Map access
final minZoom = metadata['minzoom'];
```

**New API (v0.4.2)**:
```dart
final metadata = await mbtiles.getMetadata();
final name = metadata.name;  // Object property
final minZoom = metadata.minZoom?.toInt();  // Returns double?
```

**Key Changes**:
- `getMetadata()` returns `MbTilesMetadata` object, not `Map<String, dynamic>`
- Properties like `minZoom`, `maxZoom` are now `double?` instead of `int?`
- `bounds` is now `MbTilesBounds` object with no direct property access
- `type` is now `TileLayerType?` enum instead of `String?`
- Some properties removed: `attribution`, `center`, `json`

**Our Solution**:
```dart
final metadata = await mbtiles.getMetadata();

// Convert types appropriately
return MbtilesMetadata(
  name: metadata.name ?? _getFileNameWithoutExtension(file),
  description: metadata.description,
  version: metadata.version?.toString(),  // double? to String?
  attribution: null,  // Not available in new API
  bounds: metadata.bounds.toString(),  // Object to String
  center: null,  // Not available in new API
  minZoom: metadata.minZoom?.toInt(),  // double? to int?
  maxZoom: metadata.maxZoom?.toInt(),  // double? to int?
  format: metadata.format,
  type: metadata.type?.name,  // TileLayerType? to String?
  json: null,  // Not available in new API
  file: file,
  fileSize: fileSize,
);
```

### 4. Type Mismatch: maximumZoom

**Problem**: `VectorTileLayer.maximumZoom` expects `double`, not `int`.

**Solution**: Remove `.toInt()` call:
```dart
VectorTileLayer(
  theme: _vectorTheme!,
  tileProviders: TileProviders({...}),
  maximumZoom: _currentLayer.maxZoom,  // Already double
)
```

## File Structure

```
lib/
├── services/
│   ├── mbtiles_service.dart (280 lines) - NEW
│   └── tile_cache_service.dart (+20 lines)
├── models/
│   └── map_layer.dart (+40 lines)
├── screens/
│   ├── map_tab.dart (+50 lines)
│   └── map_management_screen.dart (+180 lines)
└── l10n/
    └── app_en.arb (+80 lines)

Total: ~650 new lines of code
```

## Build Status

- ✅ iOS: Build successful (28.7MB)
- ⏳ Android: Not tested yet
- ⏳ Runtime: Not tested with actual MBTiles file

## Testing Checklist

### Before Runtime Testing

- [x] Code compiles without errors
- [x] All imports resolved
- [x] API compatibility verified
- [ ] Import MBTiles file
- [ ] Switch to vector layer
- [ ] Verify style loading
- [ ] Verify vector rendering
- [ ] Test offline mode
- [ ] Test file deletion

### Known Limitations

1. **Missing Metadata**: `attribution`, `center`, and `json` fields are not available in mbtiles v0.4.2
2. **Bounds Format**: Bounds are stored as string representation of MbTilesBounds object
3. **Schema Detection**: Limited to checking description and name for "shortbread" or "openmaptiles" keywords

### Recommendations for Production

1. **Add Error Handling**: Wrap vector tile rendering in try-catch to fall back to raster
2. **Cache Styles**: Persist downloaded styles to avoid re-downloading
3. **Validate MBTiles**: Add file format validation before import
4. **Add Tests**: Unit tests for MbtilesService, integration tests for rendering
5. **Performance Monitoring**: Track render times and memory usage

## Quick Start for Testing

1. **Download Test File**:
```bash
wget https://geodata.maptiler.download/extracts/osm/v3.11/2020-02-10/europe/osm-2020-02-10-v3.11_europe_slovenia.mbtiles
```

2. **Run App**:
```bash
flutter run
```

3. **Import File**:
- Settings → Map Management
- Tap "Import MBTiles File"
- Select downloaded file

4. **Switch Layer**:
- Map tab → Layers button
- Select "Slovenia" (or imported name)
- Wait for style download

5. **Verify**:
- Check map renders vector tiles
- Test zooming (over-zoom should work)
- Test panning
- Toggle airplane mode (should still work)

## Support

For issues related to:
- **Package compatibility**: Check flutter_map_plugins repository
- **MBTiles format**: See MBTiles specification
- **Vector styles**: Check versatiles.org documentation
- **App-specific issues**: See CLAUDE.md and VECTOR_MAPS.md

## References

- [flutter_map v8 migration guide](https://docs.fleaflet.dev/)
- [vector_map_tiles documentation](https://pub.dev/packages/vector_map_tiles)
- [mbtiles package](https://pub.dev/packages/mbtiles)
- [MBTiles spec](https://github.com/mapbox/mbtiles-spec)
- [Shortbread schema](https://shortbread-tiles.org/)
