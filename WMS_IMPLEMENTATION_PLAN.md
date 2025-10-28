# Implementation Plan: Generic WMS Server Support

## Overview
Refactor the hardcoded Slovenian WMS implementation to support adding custom WMS servers while preserving existing functionality.

## Goals
1. **Add WMS Server Management** - UI to add/edit/delete custom WMS servers via GetCapabilities URL
2. **Layer Selection** - Allow users to select base layers and overlays from any WMS server
3. **Preserve Slovenian Layers** - Keep existing EPSG:3794 support and language filtering
4. **Dynamic CRS** - Support common coordinate systems (EPSG:3857, 4326, 3794)
5. **Base Layer Switching** - Allow switching base layers on top of other layers

## Implementation Phases

### Phase 1: Core Models & Parsing (Foundation)

**1.1 Create WMS Server Model** (`lib/models/wms_server.dart`)
- `WmsServer` class with id, name, capabilitiesUrl, version, layers list
- `WmsLayer` class with name, title, abstract, styles, CRS support, bounds
- JSON serialization for persistence

**1.2 Implement WMS Capabilities Parser** (`lib/services/wms_capabilities_parser.dart`)
- Add `xml: ^7.0.0` dependency to pubspec.yaml
- Parse WMS 1.3.0 GetCapabilities XML
- Extract service metadata, supported formats, CRS list
- Recursively parse layer hierarchy (handle groups vs leaf layers)
- Extract bounding boxes, styles, and metadata

**1.3 Create CRS Factory** (`lib/utils/crs_factory.dart`)
- Registry for common CRS: EPSG:3857 (Web Mercator), EPSG:4326 (WGS84), EPSG:3794 (Slovenian)
- Cache CRS instances to avoid re-creating projection objects
- Support for retrieving CRS by EPSG code

**1.4 Create Storage Repository** (`lib/services/wms_server_repository.dart`)
- Store custom WMS servers in SharedPreferences as JSON
- CRUD operations: save, load, delete servers
- Persist layer visibility state per server/layer

### Phase 2: UI Implementation

**2.1 WMS Server Management Screen** (`lib/screens/wms_server_management_screen.dart`)
- List of saved WMS servers (edit/delete actions)
- "Add WMS Server" button → capabilities URL input dialog
- Show loading indicator while fetching GetCapabilities
- Parse and preview available layers
- Layer picker with checkboxes (base layers vs overlays)
- Validate CRS compatibility (warn if unsupported)
- Save button stores server + selected layers

**2.2 Refactor Layer Selector** (`lib/screens/map_tab.dart`)
- Keep existing sections: Standard Online Layers, Built-in WMS (Slovenian - language filtered), MBTiles
- Add new section: "Custom WMS Servers" (expandable)
- Each custom server shows its base layers as selectable tiles
- "Manage WMS Servers" button at bottom → opens management screen

**2.3 Overlay Management**
- Extend existing cadastral/forest roads overlay pattern to custom WMS layers
- Store overlay visibility per server/layer combination
- Add overlay toggles to layer selector when custom WMS base layer active

### Phase 3: Integration & Testing

**3.1 Refactor MapLayer Model** (`lib/models/map_layer.dart`)
- Add fields: `wmsServerId` (reference to custom server), `crsCode` (EPSG string)
- Add `isBuiltIn` flag to distinguish Slovenian layers from custom
- Factory method: `MapLayer.fromWmsServer(WmsServer, WmsLayer, Crs)`
- Keep existing Slovenian layer factories unchanged

**3.2 Update MapProvider** (`lib/providers/map_provider.dart`)
- Load custom WMS servers on init
- Handle base layer switching with CRS changes
- Automatically clamp zoom level when switching to layers with lower maxZoom
- Persist selected custom WMS layer to SharedPreferences

**3.3 Tile Caching Integration**
- Verify existing `getTileProviderForWms()` works with custom servers
- No changes needed (already uses `flutter_map`'s WMS tile URL generation)

**3.4 Testing**
- Test with known WMS servers: NASA GIBS, USGS, OpenStreetMap WMS
- Test Slovenian layers still work (no regression)
- Test CRS switching (3857 ↔ 4326 ↔ 3794)
- Test offline caching with custom WMS tiles
- Test error cases: invalid URL, timeout, unsupported CRS, malformed XML

### Phase 4: Polish & Documentation

**4.1 Localization**
- Add strings to `lib/l10n/app_*.arb` files:
  - "Add WMS Server", "Capabilities URL", "Custom WMS Servers"
  - Error messages: "Invalid URL", "Parsing failed", "Unsupported CRS"
- Generate with `flutter gen-l10n`

**4.2 Error Handling**
- Network timeout (30s) with user-friendly error
- XML parsing errors with "Invalid GetCapabilities response"
- Unsupported CRS warning with fallback suggestion
- Handle missing layer names, invalid bounds gracefully

**4.3 Update Documentation** (`CLAUDE.md`)
- Document WMS server management workflow
- Add custom WMS section to "Common Tasks"
- Update architecture diagram with new models/services
- Add troubleshooting section for common WMS issues

## Technical Decisions

### Preservation of Slovenian Layers
- **Approach**: Keep existing code paths intact, add `isBuiltIn: true` flag
- **Language Filtering**: Remains unchanged (sl/hr only see Slovenian layers)
- **CRS**: EPSG:3794 remains as singleton in `slovenian_crs.dart`

### Storage Strategy
- **Choice**: SharedPreferences (JSON serialization)
- **Rationale**: Estimated 700KB for 10 servers × 50 layers (under 1MB limit)
- **Migration Path**: Can move to SQLite if users need >10 servers

### CRS Support (Initial Release)
- **Supported**: EPSG:3857 (Web Mercator), EPSG:4326 (WGS84), EPSG:3794 (Slovenian)
- **Unsupported**: Show warning, prevent selection
- **Future**: Add manual CRS configuration for advanced users

### WMS Version Support
- **Phase 1**: WMS 1.3.0 only (most common)
- **Future**: Add WMS 1.1.1 (requires axis order handling)

## Key Files to Modify

**New Files**:
- `lib/models/wms_server.dart`
- `lib/services/wms_capabilities_parser.dart`
- `lib/services/wms_server_repository.dart`
- `lib/utils/crs_factory.dart`
- `lib/screens/wms_server_management_screen.dart`

**Modified Files**:
- `lib/models/map_layer.dart` (add fields, factory method)
- `lib/screens/map_tab.dart` (layer selector UI)
- `lib/providers/map_provider.dart` (load custom servers, persistence)
- `lib/l10n/app_*.arb` (localized strings)
- `pubspec.yaml` (add `xml: ^7.0.0`)
- `CLAUDE.md` (documentation update)

**Unchanged Files** (critical for backward compatibility):
- `lib/utils/slovenian_crs.dart` ✅
- `lib/services/tile_cache_service.dart` ✅

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Slow GetCapabilities responses (5-30s) | Show loading indicator, 30s timeout, cache for 24h |
| Unsupported CRS breaks map | Validate CRS before saving, show warning, fallback to 3857 |
| Tile matrix mismatch causes 400 errors | Document limitation, suggest WMTS if available |
| Breaking existing Slovenian functionality | Keep all existing code paths, add `isBuiltIn` flag, extensive testing |

## Estimated Timeline
- **Phase 1**: 1-2 weeks (models, parser, storage)
- **Phase 2**: 1 week (UI screens)
- **Phase 3**: 1-2 weeks (integration, testing)
- **Phase 4**: 1 week (polish, docs)
- **Total**: 4-6 weeks (single developer, full-time)

## Success Criteria
✅ Users can add custom WMS servers via GetCapabilities URL
✅ Users can select base layers and overlays from custom servers
✅ Slovenian layers continue to work with language filtering
✅ Base layer switching works (including CRS changes)
✅ Custom WMS tiles are cached for offline use
✅ Clear error messages for invalid/unsupported servers
✅ No regressions in existing map functionality

---

## Detailed Implementation Notes

### WMS Server Model Structure

```dart
class WmsServer {
  final String id;                    // UUID for persistence
  final String name;                  // User-friendly name
  final String capabilitiesUrl;       // GetCapabilities endpoint
  final String version;               // WMS version (1.1.1, 1.3.0)
  final List<WmsLayer> availableLayers;
  final List<String> supportedCrs;
  final DateTime lastUpdated;         // Cache invalidation

  Map<String, dynamic> toJson();
  factory WmsServer.fromJson(Map<String, dynamic> json);
}

class WmsLayer {
  final String name;                  // Layer identifier
  final String title;                 // Human-readable title
  final String? abstract;
  final List<String> styles;
  final LatLngBounds? boundingBox;
  final List<String> supportedCrs;
  final bool supportsTransparency;
  final String? legendUrl;
}
```

### WMS GetCapabilities XML Parsing

Key elements to extract:

```xml
<WMS_Capabilities version="1.3.0">
  <Service>
    <Title>Server Name</Title>
  </Service>
  <Capability>
    <Layer>
      <Title>Root Layer</Title>
      <CRS>EPSG:4326</CRS>
      <CRS>EPSG:3857</CRS>
      <Layer queryable="1">
        <Name>layer_name</Name>
        <Title>Layer Title</Title>
        <CRS>EPSG:3857</CRS>
        <EX_GeographicBoundingBox>
          <westBoundLongitude>-180</westBoundLongitude>
          <eastBoundLongitude>180</eastBoundLongitude>
          <southBoundLatitude>-90</southBoundLatitude>
          <northBoundLatitude>90</northBoundLatitude>
        </EX_GeographicBoundingBox>
        <Style>
          <Name>default</Name>
        </Style>
      </Layer>
    </Layer>
  </Capability>
</WMS_Capabilities>
```

### CRS Factory Implementation

```dart
class CrsFactory {
  static final Map<String, Crs> _crsCache = {
    'EPSG:3794': getSlovenianCrs(),
    'EPSG:3857': const Epsg3857(),
    'EPSG:4326': const Epsg4326(),
  };

  static Crs? getCrs(String epsgCode) {
    return _crsCache[epsgCode];
  }

  static bool isSupported(String epsgCode) {
    return _crsCache.containsKey(epsgCode);
  }
}
```

### Storage JSON Schema

```json
{
  "id": "uuid-here",
  "name": "My WMS Server",
  "capabilitiesUrl": "https://example.com/wms?SERVICE=WMS&REQUEST=GetCapabilities",
  "version": "1.3.0",
  "lastUpdated": "2025-10-28T12:00:00Z",
  "layers": [
    {
      "name": "layer_name",
      "title": "Layer Title",
      "abstract": "Description...",
      "supportedCrs": ["EPSG:3857", "EPSG:4326"],
      "boundingBox": {
        "south": -90, "west": -180,
        "north": 90, "east": 180
      },
      "styles": ["default"],
      "supportsTransparency": true
    }
  ],
  "supportedCrs": ["EPSG:3857", "EPSG:4326"]
}
```

### UI Flow Diagrams

**Adding a WMS Server**:
1. User taps "Manage WMS Servers" in Map Management screen
2. User taps "Add WMS Server" button
3. Dialog appears with text field for capabilities URL
4. User enters URL (e.g., `https://prostor.zgs.gov.si/geoserver/wms?SERVICE=WMS&REQUEST=GetCapabilities`)
5. App fetches and parses GetCapabilities
6. Layer picker shows available layers with checkboxes
7. User selects layers to use as base layers or overlays
8. User taps "Save" → server stored in SharedPreferences
9. Layers appear in map layer selector

**Using a Custom WMS Layer**:
1. User opens layer selector in Map tab
2. User scrolls to "Custom WMS Servers" section
3. User taps custom layer → map switches to that layer
4. If CRS differs from previous layer, map CRS updates
5. If zoom level exceeds layer's maxZoom, zoom is clamped
6. Overlay toggles appear if custom server has overlay layers

### Testing Checklist

**Functional Tests**:
- [ ] Add WMS server with valid GetCapabilities URL
- [ ] Parse layers with nested hierarchy (group layers)
- [ ] Select base layer from custom WMS server
- [ ] Switch between standard tile layer and custom WMS layer
- [ ] Switch between custom WMS layers with different CRS
- [ ] Toggle overlay layers from custom WMS server
- [ ] Delete custom WMS server
- [ ] Edit custom WMS server (re-fetch capabilities)
- [ ] Persist selected custom WMS layer across app restarts

**Error Handling Tests**:
- [ ] Invalid URL (malformed)
- [ ] Network timeout (30s)
- [ ] Invalid XML (not a GetCapabilities response)
- [ ] Empty layer list
- [ ] Unsupported CRS (show warning, prevent selection)
- [ ] Missing required fields (layer name, title)

**Regression Tests**:
- [ ] Slovenian aerial imagery still loads
- [ ] Slovenian overlays (cadastral, forest roads) still work
- [ ] Language filtering (sl/hr) still hides WMS layers for other locales
- [ ] EPSG:3794 CRS still works correctly
- [ ] Standard tile layers (OSM, OpenTopoMap) still work
- [ ] MBTiles offline layers still work
- [ ] Tile caching still works for WMS tiles

**Performance Tests**:
- [ ] GetCapabilities fetch completes within 30s
- [ ] Large layer lists (>100 layers) render without lag
- [ ] Switching layers is smooth (no UI freeze)
- [ ] SharedPreferences storage under 1MB for 10 servers

### Example WMS Servers for Testing

**Public WMS Servers**:
1. **NASA GIBS** (satellite imagery):
   - URL: `https://gibs.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi?SERVICE=WMS&REQUEST=GetCapabilities`
   - CRS: EPSG:4326
   - Layers: MODIS, VIIRS, Landsat

2. **USGS National Map** (US topographic):
   - URL: `https://basemap.nationalmap.gov/arcgis/services/USGSTopo/MapServer/WMSServer?SERVICE=WMS&REQUEST=GetCapabilities`
   - CRS: EPSG:3857
   - Layers: US Topo

3. **OpenStreetMap WMS** (reference):
   - URL: `https://ows.terrestris.de/osm/service?SERVICE=WMS&REQUEST=GetCapabilities`
   - CRS: EPSG:3857, EPSG:4326
   - Layers: OSM-WMS

4. **Slovenian Government** (current built-in):
   - URL: `https://prostor.zgs.gov.si/geowebcache/service/wms?SERVICE=WMS&REQUEST=GetCapabilities`
   - CRS: EPSG:3794, EPSG:3857
   - Layers: DOF_2024, kn_parcele, gozdne_ceste

### Critical Gotchas

**WMS Version Differences**:
- WMS 1.1.1 uses `<SRS>`, WMS 1.3.0 uses `<CRS>`
- EPSG:4326 axis order differs (lon,lat vs lat,lon)
- bbox parameter order changes between versions

**Layer Inheritance**:
- Child layers inherit CRS from parent if not specified
- Root layer CRS applies to all children unless overridden

**Group vs Leaf Layers**:
- Only layers with `<Name>` can be requested in GetMap
- Layers without `<Name>` are groups (organizational only)

**Namespace Prefixes**:
- Layer names may include workspace namespace (e.g., `pregledovalnik:DOF_2024`)
- Must be included in GetMap request exactly as in GetCapabilities

**Tile Grid Alignment**:
- WMS uses arbitrary bounding boxes (not aligned tile grids)
- Works for dynamic rendering but may have caching issues
- WMTS is better for tile caching but requires separate implementation

### Future Enhancements (Post-MVP)

**Phase 5: Advanced Features** (not in initial scope):
- WMS 1.1.1 support (axis order handling)
- WMTS support (better tile caching)
- Custom CRS registration (manual proj4 definition input)
- Layer groups (hierarchical tree view)
- Legend display for overlay layers
- GetFeatureInfo support (tap on map to query layer attributes)
- Layer metadata viewer (abstract, attribution, keywords)
- Batch import/export of WMS server configurations

**Phase 6: Performance Optimization**:
- Background GetCapabilities refresh (update layer list without blocking UI)
- Lazy loading of layer metadata (only fetch when user expands server)
- Thumbnail preview for layers (GetMap with small bbox)
- Server health check (ping before adding)

---

## References

- **WMS 1.3.0 Specification**: https://www.ogc.org/standards/wms
- **EPSG Registry**: https://epsg.io/
- **Proj4 Definitions**: https://proj4.org/
- **flutter_map WMS Docs**: https://docs.fleaflet.dev/layers/tile-layer/wms-tile-layer
- **xml package**: https://pub.dev/packages/xml
- **Slovenian WMS**: https://prostor.zgs.gov.si/geowebcache/service/wms?REQUEST=GetCapabilities&SERVICE=WMS
- **NASA GIBS**: https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers
- **OGC WMS Best Practices**: https://www.ogc.org/standards/wms

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Add `xml: ^7.0.0` to pubspec.yaml
- [ ] Create `lib/models/wms_server.dart` with JSON serialization
- [ ] Create `lib/services/wms_capabilities_parser.dart` with XML parsing
- [ ] Create `lib/utils/crs_factory.dart` with CRS registry
- [ ] Create `lib/services/wms_server_repository.dart` with SharedPreferences storage
- [ ] Write unit tests for capabilities parser

### Phase 2: UI
- [ ] Create `lib/screens/wms_server_management_screen.dart`
- [ ] Add "Manage WMS Servers" button to Map Management screen
- [ ] Implement "Add WMS Server" dialog with URL input
- [ ] Implement layer picker with checkbox selection
- [ ] Add custom WMS section to layer selector in `map_tab.dart`
- [ ] Add "Manage WMS Servers" button to layer selector

### Phase 3: Integration
- [ ] Add `wmsServerId`, `crsCode`, `isBuiltIn` fields to `MapLayer`
- [ ] Add `MapLayer.fromWmsServer()` factory method
- [ ] Update `MapProvider` to load custom WMS servers on init
- [ ] Update layer switching logic to handle CRS changes
- [ ] Update zoom clamping logic for custom layers
- [ ] Add overlay management for custom WMS layers
- [ ] Verify tile caching works with custom WMS

### Phase 4: Polish
- [ ] Add localized strings to all `app_*.arb` files (en, hr, sl, de, es, fr, it)
- [ ] Add error handling with user-friendly messages
- [ ] Add loading indicators for GetCapabilities fetch
- [ ] Add CRS compatibility warnings
- [ ] Update `CLAUDE.md` with WMS documentation
- [ ] Test with multiple public WMS servers
- [ ] Regression test Slovenian layers
- [ ] Performance test with large layer lists

---

**Document Version**: 1.0
**Last Updated**: 2025-10-28
**Status**: Ready for Implementation
