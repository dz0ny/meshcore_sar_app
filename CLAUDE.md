# CLAUDE.md - MeshCore SAR Technical Reference

AI assistant guide for the MeshCore SAR Flutter application.

## Table of Contents
1. [Critical Development Rules](#critical-development-rules)
2. [Quick Reference](#quick-reference)
3. [Project Structure](#project-structure)
4. [Protocol Reference](#protocol-reference)
5. [Architecture](#architecture)
6. [Common Tasks](#common-tasks)
7. [Build & Troubleshooting](#build--troubleshooting)

---

## Critical Development Rules

### Flutter Process Management
**NEVER run or kill Flutter processes:**
- ❌ DO NOT execute `flutter run` command
- ❌ DO NOT kill Flutter processes (`pkill flutter`, `killall flutter`)
- ✅ User manages Flutter development server - only make code changes
- ✅ Hot reload happens automatically when files are saved

### Key Architecture Constraints
- **Echo Detection**: Uses DJB2-style hash (NO crypto dependency needed)
- **Channel Messages**: NO ACKs (fire-and-forget flood routing)
- **Direct Messages**: Automatic ACKs via `PUSH_CODE_SEND_CONFIRMED`
- **SAR Markers**: MUST be sent to rooms, NOT public channel

---

## Quick Reference

**Project**: Flutter Mobile App (iOS 13+, Android API 21+)
**Architecture**: Provider pattern + BLE communication
**Protocol**: MeshCore BLE Companion Radio (Little Endian)
**Repository**: https://github.com/meshcore-dev/meshcore.js

### BLE UUIDs
```
Service: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
RX (write): 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
TX (notify): 6E400003-B5A3-F393-E0A9-E50E24DCCA9E
```

### Key Dependencies
```yaml
flutter_blue_plus: ^2.0.0  # BLE communication
flutter_map: ^8.2.2         # Mapping + WMS support
provider: ^6.1.0            # State management
geolocator: ^14.0.2         # GPS tracking
proj4dart: ^2.1.0           # Coordinate transformations (EPSG:3794)
flutter_map_tile_caching: ^10.1.1  # Offline tile caching
```

---

## Project Structure

```
lib/
├── l10n/                   # Internationalization (en, hr, sl)
│   ├── app_localizations.dart  # Generated (DO NOT EDIT)
│   └── app_*.arb              # Translation files
├── models/                 # Data models
│   ├── contact.dart, message.dart, sar_marker.dart
│   ├── map_drawing.dart       # Drawing shapes
│   └── sent_message_tracker.dart  # Echo detection
├── services/               # Business logic
│   ├── meshcore_ble_service.dart  # BLE coordinator
│   ├── protocol/              # Frame parsing & building
│   ├── ble/                   # Connection, commands, responses
│   ├── location_tracking_service.dart  # GPS + broadcast
│   ├── map_marker_service.dart    # Marker generation
│   ├── tile_cache_service.dart    # Offline tile caching (WMS + standard)
│   └── validation_service.dart    # Form validation
├── providers/              # State management
│   ├── connection_provider.dart   # BLE state
│   ├── contacts_provider.dart     # Contact list
│   ├── messages_provider.dart     # Messages + SAR
│   ├── map_provider.dart          # Map navigation
│   ├── drawing_provider.dart      # Map drawings
│   └── app_provider.dart          # Coordinator
├── screens/                # UI screens
│   └── (home, messages, contacts, map, settings, etc.)
├── widgets/                # Reusable components
│   ├── map_markers.dart
│   └── map/                   # Map-specific widgets
└── utils/                  # Utilities
    ├── sar_message_parser.dart
    ├── drawing_message_parser.dart
    └── slovenian_crs.dart         # EPSG:3794 CRS for WMS
```

---

## Protocol Reference

### Message Formats

#### SAR Marker Format
```
S:<emoji>:<latitude>,<longitude>:<optional_message>

Emojis:
  🧑 or 👤  → Found Person
  🔥        → Fire Location
  🏕️ or ⛺  → Staging Area

Examples:
  S:🧑:37.7749,-122.4194
  S:🔥:40.7128,-74.0060:Large wildfire spreading rapidly
```

#### Map Drawing Format
```
D:<json>

Line:      D:{"t":0,"c":0,"p":[lat1,lon1,lat2,lon2]}
Rectangle: D:{"t":1,"c":1,"b":[topLat,topLon,botLat,botLon]}

Fields:
  t = type (0=line, 1=rectangle)
  c = color index (0-7: red,blue,green,yellow,orange,purple,pink,cyan)
  p = points array (flat)
  b = bounds array (rectangles only)
```

#### Cayenne LPP Format
```
[Channel][Type][Data...]

Types:
  0x88 (136) → GPS: lat/lon/alt (int32/10000, int32/10000, int32/100)
  0x67 (103) → Temperature (int16/10 for °C)
  0x02 (2)   → Analog Input (uint16/100 for volts/battery)
```

### Command Quick Reference

| Code | Command | Response | Description |
|------|---------|----------|-------------|
| 1 | CMD_APP_START | RESP_CODE_SELF_INFO (5) | First command after connection |
| 2 | CMD_SEND_TXT_MSG | RESP_CODE_SENT (6) | Send DM to contact (with ACK) |
| 3 | CMD_SEND_CHANNEL_TXT_MSG | RESP_CODE_SENT (6) | Broadcast to channel (NO ACK) |
| 4 | CMD_GET_CONTACTS | RESP_CODE_CONTACTS_START (2) | Sync contact list |
| 10 | CMD_SYNC_NEXT_MESSAGE | RESP_CODE_CONTACT_MSG_RECV (7) | Pull next message from queue |
| 22 | CMD_DEVICE_QUERY | RESP_CODE_DEVICE_INFO (13) | Get device firmware/hardware info |
| 26 | CMD_SEND_LOGIN | PUSH_CODE_LOGIN_SUCCESS (0x85) | Login to room server |

### Push Notifications (Async)

| Code | Name | Purpose |
|------|------|---------|
| 0x80 | PUSH_CODE_ADVERT | New advertisement received |
| 0x82 | PUSH_CODE_SEND_CONFIRMED | Message ACK received (DMs only) |
| 0x83 | PUSH_CODE_MSG_WAITING | New message in queue → sync it |
| 0x88 | PUSH_CODE_LOG_RX_DATA | **Raw packet capture (always-on diagnostic)** |
| 0x85 | PUSH_CODE_LOGIN_SUCCESS | Room login successful |
| 0x86 | PUSH_CODE_LOGIN_FAIL | Room login failed |

### Constants

#### Contact Types (ADV_TYPE)
```
0 = ADV_TYPE_NONE      # Unknown/invalid
1 = ADV_TYPE_CHAT      # Team member (shown on map)
2 = ADV_TYPE_REPEATER  # Network repeater
3 = ADV_TYPE_ROOM      # Communication room/server
```

#### Message Types (TXT_TYPE)
```
0 = TXT_TYPE_PLAIN         # Plain text
1 = TXT_TYPE_CLI_DATA      # CLI command
2 = TXT_TYPE_SIGNED_PLAIN  # Text + 4-byte pubkey signature
```

#### Error Codes (ERR_CODE)
```
1 = ERR_CODE_UNSUPPORTED_CMD
2 = ERR_CODE_NOT_FOUND
3 = ERR_CODE_TABLE_FULL
4 = ERR_CODE_BAD_STATE
5 = ERR_CODE_FILE_IO_ERROR
6 = ERR_CODE_ILLEGAL_ARG
```

---

## Architecture

### Provider Hierarchy
```
MultiProvider
├── ConnectionProvider    # BLE connection state
├── ContactsProvider      # Contact list management
├── MessagesProvider      # Messages + SAR markers
├── MapProvider          # Map navigation state
├── DrawingProvider      # Map drawing state
└── AppProvider          # Coordinator (wires everything)
```

### Event Flow
```
BLE Device → MeshCoreBleService → ConnectionProvider → AppProvider
                                         ↓
                                  ContactsProvider
                                  MessagesProvider
                                  DrawingProvider
                                         ↓
                                        UI
```

### Contact Path Status

**outPathLen** indicates routing mode:
- **-1 (0xFF)**: Path unknown → **Flood mode** (broadcast to all neighbors)
- **0**: Direct connection → **Direct mode** (zero hops, best quality)
- **1-64**: Multi-hop path → **Direct mode** (uses learned routing)

**Map Display**: Only `ContactType.chat` contacts with valid GPS coordinates shown.

### Channels vs. Rooms

**Channels** (numeric identifiers):
- Channel 0 = "Public Channel" (default broadcast)
- **Ephemeral** - messages NOT persisted
- Uses `CMD_SEND_CHANNEL_TXT_MSG` (3)
- **NO ACKs** - fire-and-forget flood routing
- Pre-configured with secret: `8b3387e9c5cdea6ac9e5edbaa115cd72` (hex)

**Rooms** (ADV_TYPE_ROOM contacts):
- Named contacts with public keys
- **Persistent storage** on room server
- Uses `CMD_SEND_TXT_MSG` (2) with room's public key
- **Automatic ACKs** when messages stored
- Login via `CMD_SEND_LOGIN` (26) to receive stored messages

**SAR Routing**: SAR markers MUST go to rooms for reliable delivery.

### Room Login Protocol

```
1. Send CMD_SEND_LOGIN (26)
   ↓
2. Radio generates sender_timestamp & sync_since
   ↓
3. Room validates password, stores sync_since
   ↓
4. Receive PUSH_CODE_LOGIN_SUCCESS (0x85) or PUSH_CODE_LOGIN_FAIL (0x86)
   ↓
5. Room auto-pushes messages (1200ms intervals)
   ↓
6. Receive PUSH_CODE_MSG_WAITING (0x83) → call CMD_SYNC_NEXT_MESSAGE (10)
```

**CRITICAL**: Do NOT call `syncAllMessages()` after login. Wait for push notifications.

---

## Echo Detection Feature

### Overview
**Status**: ✅ Fully implemented and production-ready
**Purpose**: Detect when broadcast messages are rebroadcast by mesh nodes

### How It Works

1. **Packet Identification** (via `PUSH_CODE_LOG_RX_DATA` 0x88):
   ```
   Packet Structure (PAYLOAD_TYPE_GRP_TXT 0x05):
   [Byte 0] = Header (route + payload type + version)
   [Byte 1] = Path length
   [Byte 2] = Sender's node hash (first byte of public key) ✅
   [Byte 3+] = Rest of path + encrypted payload
   ```

2. **On Connection**:
   - Receive `RESP_CODE_SELF_INFO` with our public key
   - Extract **our node hash** (byte 0 of public key)
   - Store for packet matching

3. **Sending a Message**:
   - Call `trackSentMessage(messageId)` when user sends channel message
   - Status = "pending" (waiting for packet capture)

4. **Packet Capture** (50-200ms later):
   - Radio sends `PUSH_CODE_LOG_RX_DATA` with raw packet
   - Extract sender hash from packet[2]
   - If sender hash == our node hash → **This is our packet!**
   - Calculate DJB2-style hash of entire packet (no crypto dependency)
   - Store tracker by packet hash for echo detection

5. **Echo Detection**:
   - Future `PUSH_CODE_LOG_RX_DATA` packets arrive
   - Calculate packet hash and lookup in tracker map (O(1))
   - If match found → **Echo detected!** Increment counter
   - Track SNR/RSSI signature for path diversity
   - UI auto-updates to show "Rebroadcast by X nodes"

### Implementation Details

**Files**:
- `lib/models/sent_message_tracker.dart` - Tracker model
- `lib/models/message.dart` - echoCount, firstEchoAt fields
- `lib/services/ble/ble_response_handler.dart` - Detection engine
- `lib/services/meshcore_ble_service.dart` - Callback wiring
- `lib/providers/connection_provider.dart` - Provider callback
- `lib/providers/messages_provider.dart` - handleMessageEcho()

**Performance**:
- Packet ID: O(1) - byte comparison at offset 2
- Hash calc: O(n) where n = packet length (~38-200 bytes)
- Echo lookup: O(1) via HashMap
- Memory: ~150 bytes/message, max 100 messages = ~15KB
- TTL: 5-minute expiry, auto-cleanup

**Limitations**:
- Echo count ≠ exact receiver count (one node can echo multiple times)
- Only detects echoes while app connected
- Network topology dependent (dense networks → more echoes)

---

## Common Tasks

### Adding a New BLE Command

1. Add code to `lib/services/meshcore_constants.dart`
2. Build frame in `lib/services/protocol/frame_builder.dart`
3. Add API method in `lib/services/meshcore_ble_service.dart`
4. Parse response in `lib/services/protocol/frame_parser.dart`
5. Handle in `lib/services/ble/ble_response_handler.dart`
6. Add callback in `lib/services/meshcore_ble_service.dart`

### Adding a New SAR Marker Type

1. Update enum in `lib/models/sar_marker.dart`
2. Add parser logic in `lib/utils/sar_message_parser.dart`
3. Add color mapping in `lib/widgets/map_markers.dart`
4. Update handling in `lib/providers/messages_provider.dart`

### Adding Localized Strings

1. **Add to `lib/l10n/app_en.arb`**:
   ```json
   {
     "myNewString": "My new text",
     "@myNewString": {
       "description": "What this string is for"
     }
   }
   ```

2. **Add translations to `app_hr.arb` and `app_sl.arb`**

3. **Generate**: `flutter gen-l10n`

4. **Use in code**:
   ```dart
   import '../l10n/app_localizations.dart';

   Text(AppLocalizations.of(context)!.myNewString)
   ```

**IMPORTANT**: Always use relative import path `'../l10n/app_localizations.dart'`

### Importing/Exporting Map Tiles

The app supports importing and exporting cached map tiles using the `flutter_map_tile_caching` library's archive format (`.fmtc` files).

**Export Workflow**:
1. Navigate to Map Management screen
2. Tap "Export Tiles to File"
3. Archive is created in temporary directory with gzip compression
4. System share sheet appears (iOS/Android)
5. Choose where to save: Files app, email, cloud storage, etc.
6. File named: `meshcore_tiles_<timestamp>.fmtc`

**Import Workflow**:
1. Navigate to Map Management screen
2. Tap "Import Tiles from File"
3. Select `.fmtc` archive file
4. Tiles are merged with existing cache
5. Cache statistics refreshed automatically

**API Usage**:

```dart
// Export current cache to file
final tileCount = await tileCacheService.exportStore(
  '/path/to/export.fmtc',
);

// Import tiles from archive (with merge strategy)
final result = await tileCacheService.importStore(
  '/path/to/import.fmtc',
  storeNames: null, // null = import all stores
  strategy: ImportConflictStrategy.merge, // default: merge
);

// Preview stores in archive before importing
final stores = await tileCacheService.listArchiveStores(
  '/path/to/archive.fmtc',
);
```

**Use Cases**:
- **Backup**: Export tiles before clearing cache or reinstalling app
- **Sharing**: Pre-download maps once, distribute to team devices
- **Disaster Recovery**: Restore offline maps after device reset
- **Bandwidth Saving**: Reduce cellular data usage by sharing cached tiles

**Technical Details**:
- Archive format: `.fmtc` (FMTC native format)
- Compression: gzip (built-in by FMTC)
- Import strategy: Merge (tiles combined with existing cache)
- Export location: Temporary directory → system share sheet
- Import source: User-selected via `file_picker` package
- Conflict handling: Automatic merge of tile stores
- Cross-platform: Works on Android and iOS using native share mechanisms

**File**: `lib/services/tile_cache_service.dart` - Export/import methods
**UI**: `lib/screens/map_management_screen.dart` - Import/export card

### Map Drawing Workflow

```
User selects mode → DrawingProvider.setDrawingMode()
       ↓
User taps map → DrawingLayer captures touches
       ↓
Preview rendered → DrawingProvider.getPreviewDrawing()
       ↓
User completes → Saved to DrawingProvider._drawings
       ↓
User shares → DrawingToolbar._shareDrawingsToChannel/Room()
       ↓
BLE send → ConnectionProvider.sendChannelMessage/sendTextMessage()
       ↓
Receiver parses → DrawingMessageParser.parseDrawingMessage()
       ↓
Display → DrawingProvider.addReceivedDrawing()
```

---

## Build & Troubleshooting

### Build Commands

```bash
# Dependencies
flutter pub get
flutter gen-l10n          # After ARB file changes

# Development
flutter run               # Debug mode (user controls this)
# Hot reload: save file  |  Hot restart: press 'R' in terminal

# Code Quality
flutter analyze
flutter test
dart format lib/
flutter clean

# Release
flutter build ios --release
flutter build ipa
flutter build apk --release
flutter build appbundle --release
```

### Common Issues

**BLE Connection Failed**:
- Check Bluetooth enabled and permissions granted
- Verify device in range (<10m)
- Check service UUID matches: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`

**MissingPluginException** (after adding dependencies):
```bash
cd ios && pod install && cd ..
flutter clean
flutter pub get
flutter run
```

**iOS Pod Install Fails**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod install --repo-update
cd ..
```

**Android Gradle Timeout** - Add to `android/gradle.properties`:
```
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx4096m
```

### Performance Tips

**BLE**:
- Buffer partial packets
- Throttle telemetry (max 1/sec per contact)
- Use `notifyListeners()` sparingly

**Map**:
- Cluster markers if >100 visible
- Use `RepaintBoundary` for marker widgets
- Implement marker virtualization for large datasets

**Memory**:
- Dispose controllers in `dispose()` methods
- Limit message history to 1000 messages
- Set tile cache size limits

---

## Services Reference

### LocationTrackingService (Singleton)
**Purpose**: GPS tracking + intelligent mesh location broadcasting

**Callbacks**: `onPositionUpdate`, `onError`, `onBroadcastSent`, `onTrackingStateChanged`

**Thresholds**:
- Min distance: 5.0m
- Max distance: 100.0m
- Min time: 30s

**Logic**:
- First update → broadcast immediately
- ≥100m moved → broadcast immediately
- ≥5m + ≥30s → broadcast

**File**: `lib/services/location_tracking_service.dart` (501 lines)

### MapMarkerService (Singleton)
**Purpose**: Map marker generation + geodesic calculations

**Features**:
- Pure functions (testable)
- Contact markers with battery badge, distance
- SAR markers (color-coded by type)
- Distance/bearing calculations (Haversine)
- "Time ago" formatting

**File**: `lib/services/map_marker_service.dart` (518 lines)

### ValidationService (Singleton)
**Purpose**: Form validation + input parsing

**Returns**: Structured `ValidationResult<T>` or `ParseResult<T>`

**Validates**:
- Coordinates (lat: -90 to +90, lon: -180 to +180)
- Radio params (freq: 137-1020 MHz, bw: 7.8-500 kHz, sf: 5-12, cr: 5-8, tx: -9 to +22 dBm)
- Text/names, zoom levels (0-19)

**File**: `lib/services/validation_service.dart` (511 lines)

---

## Map Implementation

### Tile Layers
1. **OpenStreetMap** (default) - Max zoom 19
2. **OpenTopoMap** - Max zoom 17, topographic
3. **ESRI World Imagery** - Max zoom 19, satellite

### WMS Support
**Purpose**: Integration with Web Map Service (WMS) providers for specialized mapping data

**Slovenian CRS (EPSG:3794)**:
- Projection: Transverse Mercator (Slovenia 1996 / Slovene National Grid)
- Ellipsoid: GRS80
- Usage: Slovenian government WMS/WMTS services (prostor.zgs.gov.si)
- Zoom levels: 0-15 (GeoWebCache tile matrix)
- Bounds: X: 373217.65-695777.65m, Y: 31118.30-246158.30m
- Origin: Top-left (373217.65, 246158.30)
- Resolutions: Calculated from scale denominators (420m/px at zoom 0 to 0.028m/px at zoom 15)

**Tile Caching**:
- All WMS layers (base + overlays) use `flutter_map_tile_caching`
- Cache strategy: `cacheFirst` (offline-first with 30-day validity)
- Same caching infrastructure as standard tile layers

**Files**:
- `lib/utils/slovenian_crs.dart` - EPSG:3794 CRS definition
- `lib/services/tile_cache_service.dart` - getTileProviderForWms() method

**Example**:
```dart
import 'package:meshcore_sar_app/utils/slovenian_crs.dart';

// All WMS layers automatically use the cached tile provider
TileLayer(
  wmsOptions: WMSTileLayerOptions(
    baseUrl: 'https://prostor.zgs.gov.si/geowebcache/service/wms?',
    layers: ['pregledovalnik:DOF_2024'],
    format: 'image/jpeg',
    crs: slovenianCrs,
  ),
  tileProvider: tileCacheService.getTileProviderForWms(layer),
)
```

### WMS Implementation Details

#### Overview
The app integrates Slovenian government WMS (Web Map Service) layers using a custom EPSG:3794 coordinate reference system. This enables high-resolution aerial imagery and specialized overlays (cadastral parcels, forest roads) for SAR operations in Slovenia.

#### Architecture

**Layer Types**:
1. **Base Layer**: Slovenian Aerial Imagery 2024 (DOF_2024)
   - Source: `https://prostor.zgs.gov.si/geowebcache/service/wms`
   - Format: JPEG (better compression for aerial photos)
   - Transparency: False (opaque base layer)
   - Max zoom: 15 (GeoWebCache limit)

2. **Overlay Layers**: Cadastral Parcels, Forest Roads
   - Format: PNG (supports transparency)
   - Transparency: True (overlays on base layer)
   - Max zoom: 19

**Coordinate System (EPSG:3794)**:
- Official name: Slovenia 1996 / Slovene National Grid
- Projection: Transverse Mercator
- Parameters: `+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=GRS80`
- Why needed: Slovenian government services use this instead of standard Web Mercator (EPSG:3857)

**Tile Grid Alignment**:
The critical challenge with WMS layers is aligning the client-side tile grid with the server's GeoWebCache configuration. Misalignment causes 400 Bad Request errors.

**Correct Configuration** (`lib/utils/slovenian_crs.dart`):
```dart
// Origin MUST match WMTS TileMatrixSet TopLeftCorner
final origin = Point<double>(373217.6542445397, 246158.298050262);

// Bounds MUST match WMS capabilities extent
final bounds = Rect.fromLTRB(
  373217.65,  // min X (west)
  31118.30,   // min Y (south)
  695777.65,  // max X (east)
  246158.30,  // max Y (north)
);

// Resolutions MUST be calculated from scale denominators
// Formula: resolution = scaleDenominator * 0.00028 (OGC standard)
final resolutions = [
  420.0,  // Zoom 0: 1,500,000 * 0.00028
  280.0,  // Zoom 1: 1,000,000 * 0.00028
  // ... through zoom 15
];
```

**How to Get Correct Values**:
1. Query WMTS GetCapabilities:
   ```bash
   curl "https://prostor.zgs.gov.si/geowebcache/service/wmts?REQUEST=GetCapabilities&SERVICE=WMTS"
   ```
2. Find `<TileMatrixSet>` for EPSG:3794
3. Extract `<TopLeftCorner>` (origin)
4. Extract `<ScaleDenominator>` for each `<TileMatrix>` (convert to resolutions)
5. Query WMS GetCapabilities for bounds:
   ```bash
   curl "https://prostor.zgs.gov.si/geowebcache/service/wms?REQUEST=GetCapabilities&SERVICE=WMS"
   ```

#### Caching Strategy

**Implementation** (`lib/services/tile_cache_service.dart`):
```dart
FMTCTileProvider getTileProviderForWms(MapLayer layer) {
  return _store.getTileProvider(
    loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    cachedValidDuration: const Duration(days: 30),
  );
}
```

**Behavior**:
1. **Cache First**: Check local cache before network request
2. **30-Day Validity**: Tiles expire after 30 days (suitable for aerial imagery that updates infrequently)
3. **Automatic Caching**: All viewed tiles automatically saved to ObjectBox database
4. **Offline Support**: Cached tiles available when device offline

**Storage Location**:
- Backend: ObjectBox (embedded database)
- Store name: 'meshcore_tiles' (shared with standard tile layers)
- Format: Binary tile data + metadata (URL, timestamp, headers)

#### Usage in Map

**Base Layer** (`lib/screens/map_tab.dart`):
```dart
if (_currentLayer.isWms && _currentLayer.crs != null) {
  TileLayer(
    wmsOptions: WMSTileLayerOptions(
      baseUrl: _currentLayer.wmsBaseUrl!,
      layers: _currentLayer.wmsLayers ?? [],
      format: _currentLayer.wmsFormat ?? 'image/jpeg',
      crs: _currentLayer.crs!,  // EPSG:3794
    ),
    tileProvider: _tileCache.getTileProviderForWms(_currentLayer),
    maxZoom: _currentLayer.maxZoom,  // 15 for Slovenian layers
  );
}
```

**Map Options**:
```dart
MapOptions(
  // CRITICAL: Use layer's CRS, not default EPSG:3857
  crs: _currentLayer.crs ?? const Epsg3857(),
  // ... other options
)
```

#### Troubleshooting

**400 Bad Request Errors**:
- **Cause**: Tile grid misalignment (wrong origin, bounds, or resolutions)
- **Fix**: Verify values match WMTS GetCapabilities exactly
- **Debug**: Check WMS URL in error logs for out-of-bounds coordinates

**Tiles Not Caching**:
- **Cause**: Using wrong tile provider (e.g., NetworkTileProvider instead of FMTC)
- **Fix**: Ensure `getTileProviderForWms()` is used, not `NetworkTileProvider()` or custom providers
- **Verify**: Check `tile_cache_service.dart:75` is being called

**Layer Not Appearing**:
- **Cause 1**: Layer name mismatch (e.g., `DOF_2024` vs `pregledovalnik:DOF_2024`)
- **Cause 2**: Wrong CRS in MapOptions (using EPSG:3857 instead of EPSG:3794)
- **Fix**: Verify layer name in WMS GetCapabilities, ensure `crs: _currentLayer.crs` in MapOptions

**Performance Issues**:
- **Issue**: Slow tile loading on first view
- **Expected**: WMS tile generation is slower than pre-rendered tiles (100-500ms per tile)
- **Mitigation**: Pre-download regions using Map Management screen

#### Adding New WMS Layers

1. **Find Layer in GetCapabilities**:
   ```bash
   curl "https://prostor.zgs.gov.si/geowebcache/service/wms?REQUEST=GetCapabilities" | grep "<Name>"
   ```

2. **Add to MapLayer** (`lib/models/map_layer.dart`):
   ```dart
   static MapLayer getMyNewLayer(Crs slovenianCrs) {
     return MapLayer(
       type: MapLayerType.wmsBase,  // or create new enum value
       name: 'My New Layer',
       urlTemplate: '',  // Not used for WMS
       attribution: '© Data Provider',
       maxZoom: 15,  // Match GeoWebCache capability
       isWms: true,
       wmsBaseUrl: 'https://prostor.zgs.gov.si/geowebcache/service/wms?',
       wmsLayers: const ['workspace:layername'],
       wmsFormat: 'image/png',  // or 'image/jpeg'
       wmsTransparent: true,  // true for overlays, false for base
       crs: slovenianCrs,
     );
   }
   ```

3. **Verify CRS Support**: Ensure layer supports EPSG:3794 in GetCapabilities

4. **Test**: Check for 400 errors, verify tiles load correctly

#### Technical Notes

**Why Not Use WMTS Instead of WMS?**
- `flutter_map` has excellent WMS support via `WMSTileLayerOptions`
- WMS and WMTS use same GeoWebCache backend (identical tiles)
- WMS is simpler to configure (no manual tile URL template)
- Caching abstracts the protocol difference

**Proj4dart Integration**:
- Handles coordinate transformation from EPSG:4326 (GPS) to EPSG:3794 (map)
- Projection registered once at app startup: `proj4.Projection.add('EPSG:3794', ...)`
- Flutter Map uses it automatically when `crs: slovenianCrs` is set

**Memory Considerations**:
- Each CRS instance stores transformation matrices and bounds
- Use singleton pattern: `final Crs slovenianCrs = getSlovenianCrs();`
- Shared across all WMS layers

### Offline Caching
- Backend: `flutter_map_tile_caching` + ObjectBox
- Behavior: `CacheBehavior.cacheFirst`, 30-day validity
- Downloads: `RectangleRegion(bounds).download.startForeground()`

### Marker Types
**Team Member**: Blue circle, battery badge, name, distance, tap for details
**SAR Event**: Color-coded (green=person, red=fire, orange=staging), time ago, tap for details

### Navigation Flow
```
Messages tab → tap SAR marker
    ↓
MapProvider.navigateToLocation()
    ↓
Switch to Map tab
    ↓
MapTab._handleMapNavigation() → animate to location
    ↓
MapProvider.clearNavigation()
```

---

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [flutter_blue_plus API](https://pub.dev/documentation/flutter_blue_plus/)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [MeshCore Protocol](https://github.com/meshcore-dev/meshcore.js)
- [MeshCore FAQ](https://github.com/meshcore-dev/MeshCore/blob/main/docs/faq.md)
- [Cayenne LPP Specification](https://developers.mydevices.com/cayenne/docs/lora/#lora-cayenne-low-power-payload)
- [Provider Package](https://pub.dev/packages/provider)
- [EPSG:3794 Reference](https://epsg.io/3794) - Slovenian CRS definition
- [Proj4dart Package](https://pub.dev/packages/proj4dart) - Coordinate transformation library
- [OGC WMS Specification](https://www.ogc.org/standards/wms) - Web Map Service standard

---

## Security Considerations

- **BLE**: No authentication in current protocol - consider encryption for production
- **Permissions**: Request minimum required permissions only
- **Logging**: No sensitive data in logs
- **Network**: HTTPS for all tile sources
- **Raw Packets**: `PUSH_CODE_LOG_RX_DATA` exposes all radio traffic (diagnostic feature)
