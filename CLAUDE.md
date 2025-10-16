# CLAUDE.md - MeshCore SAR Technical Reference

AI assistant guide for the MeshCore SAR Flutter application.

## ⚠️ CRITICAL: Flutter Development Rules

**NEVER run or kill Flutter processes:**
- DO NOT execute `flutter run` command
- DO NOT kill Flutter processes (`pkill flutter`, `killall flutter`)
- User manages Flutter development server - only make code changes
- Hot reload happens automatically when files are saved

## Quick Reference

**Project Type**: Flutter Mobile App (iOS 13+, Android API 21+)
**Architecture**: Provider-based state management + BLE communication
**Protocol**: MeshCore BLE Companion Radio (Little Endian byte order)
**Repository**: https://github.com/meshcore-dev/meshcore.js

**BLE Service UUIDs:**
- Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- RX (write): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
- TX (notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

**Key Dependencies:**
- flutter_blue_plus ^2.0.0 (BLE)
- flutter_map ^8.2.2 (mapping)
- provider ^6.1.0 (state)
- geolocator ^14.0.2 (GPS)

## Project Structure

```
lib/
├── l10n/                # Internationalization (i18n)
│   ├── app_localizations.dart         # Generated localization class
│   ├── app_en.arb                     # English (default)
│   ├── app_hr.arb                     # Croatian (Hrvatski)
│   └── app_sl.arb                     # Slovenian (Slovenščina)
├── models/              # Data models
│   ├── contact.dart, message.dart, sar_marker.dart
│   ├── map_drawing.dart           # MapDrawing, LineDrawing, RectangleDrawing
│   ├── device_info.dart, room_login_state.dart, map_layer.dart
├── services/            # Business logic
│   ├── meshcore_ble_service.dart      # BLE coordinator (399 lines)
│   ├── protocol/                      # Frame parsing & building (628 lines)
│   ├── ble/                           # Connection, commands, responses (963 lines)
│   ├── location_tracking_service.dart # GPS + mesh broadcast (501 lines)
│   ├── map_marker_service.dart        # Marker generation + geodesic (518 lines)
│   └── validation_service.dart        # Form validation (511 lines)
├── providers/           # State management
│   ├── connection_provider.dart       # BLE connection state
│   ├── contacts_provider.dart         # Contact list
│   ├── messages_provider.dart         # Messages + SAR markers
│   ├── map_provider.dart              # Map navigation
│   ├── drawing_provider.dart          # Map drawing state
│   └── app_provider.dart              # Coordinator (uses all above)
├── screens/             # UI screens (home, messages, contacts, map, settings, device_config, map_management, packet_log)
├── widgets/             # Reusable components
│   ├── map_markers.dart               # Map marker rendering
│   ├── map/                           # Map-specific widgets
│   │   ├── drawing_layer.dart         # Drawing rendering on map
│   │   ├── drawing_toolbar.dart       # Drawing UI controls
│   │   └── compass/                   # Compass dialog components (fully localized)
│   ├── messages/, contacts/           # Feature-specific widgets (fully localized)
└── utils/               # Utilities
    ├── sar_message_parser.dart        # SAR marker parsing
    └── drawing_message_parser.dart    # Drawing message parsing
```

## MeshCore Protocol

### Frame Delimiters
- **BLE**: Single characteristic value (link layer handles integrity)
- **USB**: `>` (0x3E) outbound, `<` (0x3C) inbound, 2-byte length (LE), then frame data
- **All uint32 values use Little Endian byte order**

### Command Codes (App → Radio)

| Code | Name | Description |
|------|------|-------------|
| 1 | CMD_APP_START | First command after connection → RESP_CODE_SELF_INFO(5) |
| 2 | CMD_SEND_TXT_MSG | Send text message to contact (DM) |
| 3 | CMD_SEND_CHANNEL_TXT_MSG | Send flood-mode text to channel |
| 4 | CMD_GET_CONTACTS | Sync contacts (optional 'since' param) |
| 5 | CMD_GET_DEVICE_TIME | Get device clock (epoch secs, UTC) |
| 6 | CMD_SET_DEVICE_TIME | Set device clock |
| 7 | CMD_SEND_SELF_ADVERT | Send Advertisement packet |
| 8 | CMD_SET_ADVERT_NAME | Update node name in adverts |
| 9 | CMD_ADD_UPDATE_CONTACT | Add/modify contact |
| 10 | CMD_SYNC_NEXT_MESSAGE | Get next text message from queue |
| 11 | CMD_SET_RADIO_PARAMS | Save radio parameters |
| 12 | CMD_SET_RADIO_TX_POWER | Set radio TX power |
| 13 | CMD_RESET_PATH | Reset out_path for contact |
| 14 | CMD_SET_ADVERT_LATLON | Update lat/lon in adverts |
| 15 | CMD_REMOVE_CONTACT | Remove contact |
| 16 | CMD_SHARE_CONTACT | Share contact via zero-hop advert |
| 17 | CMD_EXPORT_CONTACT | Export contact as business card |
| 18 | CMD_IMPORT_CONTACT | Import contact from business card |
| 19 | CMD_REBOOT | Reboot companion device |
| 20 | CMD_GET_BATT_AND_STORAGE | Get battery mV and storage stats |
| 21 | CMD_SET_TUNING_PARAMS | Set tuning parameters |
| 22 | CMD_DEVICE_QUERY | First command to send → RESP_CODE_DEVICE_INFO(13) |
| 25 | CMD_SEND_RAW_DATA | Transmit PAYLOAD_TYPE_RAW_CUSTOM |
| 26 | CMD_SEND_LOGIN | Send login to repeater/room |
| 27 | CMD_SEND_STATUS_REQ | Send status request |
| 36 | CMD_SEND_TRACE_PATH | Initiate TRACE with SNR collection |
| 37 | CMD_SET_DEVICE_PIN | Set BLE PIN code |
| 38 | CMD_SET_OTHER_PARAMS | Set various parameters |
| 39 | CMD_SEND_TELEMETRY_REQ | Request telemetry (deprecated) |
| 40 | CMD_GET_CUSTOM_VARS | Retrieve custom variables |
| 41 | CMD_SET_CUSTOM_VAR | Set single custom variable |
| 42 | CMD_GET_ADVERT_PATH | Query last advert path |
| 43 | CMD_GET_TUNING_PARAMS | Get airtime-factor & rx-delay |
| 50 | CMD_SEND_BINARY_REQ | Binary request (preferred over 39) |
| 51 | CMD_FACTORY_RESET | Erase flash file system |

### Response Codes (Radio → App)

| Code | Name | Description |
|------|------|-------------|
| 0 | RESP_CODE_OK | Success |
| 1 | RESP_CODE_ERR | Error (includes err_code) |
| 2 | RESP_CODE_CONTACTS_START | Start contacts sync |
| 3 | RESP_CODE_CONTACT | Single contact info |
| 4 | RESP_CODE_END_OF_CONTACTS | End contacts sync |
| 5 | RESP_CODE_SELF_INFO | Node's own information |
| 6 | RESP_CODE_SENT | Message sent with ACK/TAG |
| 7 | RESP_CODE_CONTACT_MSG_RECV | Contact message received |
| 8 | RESP_CODE_CHANNEL_MSG_RECV | Channel message received |
| 9 | RESP_CODE_CURR_TIME | Current device time |
| 10 | RESP_CODE_NO_MORE_MESSAGES | Message queue empty |
| 11 | RESP_CODE_EXPORT_CONTACT | Contact export data |
| 12 | RESP_CODE_BATT_AND_STORAGE | Battery and storage info |
| 13 | RESP_CODE_DEVICE_INFO | Device firmware/hardware info |
| 21 | RESP_CODE_CUSTOM_VARS | Custom variables state |
| 22 | RESP_CODE_ADVERT_PATH | Last advert path |

### Push Notifications (Radio → App, Async)

| Code | Name | Description |
|------|------|-------------|
| 0x80 | PUSH_CODE_ADVERT | New advertisement received |
| 0x81 | PUSH_CODE_PATH_UPDATED | Contact received new path |
| 0x82 | PUSH_CODE_SEND_CONFIRMED | Message ACK received |
| 0x83 | PUSH_CODE_MSG_WAITING | New text message received |
| 0x84 | PUSH_CODE_RAW_DATA | PAYLOAD_TYPE_RAW_CUSTOM received |
| 0x85 | PUSH_CODE_LOGIN_SUCCESS | Login successful |
| 0x86 | PUSH_CODE_LOGIN_FAIL | Login failed |
| 0x87 | PUSH_CODE_STATUS_RESPONSE | Status response received |
| 0x88 | PUSH_CODE_LOG_RX_DATA | Debug: raw OTA packet (diagnostic) |
| 0x89 | PUSH_CODE_TRACE_DATA | TRACE packet end of path |
| 0x8A | PUSH_CODE_NEW_ADVERT | New contact advert |
| 0x8B | PUSH_CODE_TELEMETRY_RESPONSE | Telemetry response |
| 0x8C | PUSH_CODE_BINARY_RESPONSE | Binary response |

### Constants

**ADV_TYPE (Contact Type):**
- 0: ADV_TYPE_NONE (unknown/invalid)
- 1: ADV_TYPE_CHAT (team member, shown on map)
- 2: ADV_TYPE_REPEATER (network repeater)
- 3: ADV_TYPE_ROOM (communication room/server)

**TXT_TYPE (Message Type):**
- 0: TXT_TYPE_PLAIN (plain text)
- 1: TXT_TYPE_CLI_DATA (CLI command)
- 2: TXT_TYPE_SIGNED_PLAIN (plain text + extra 4 bytes of sender's public key for verification)

**ERR_CODE:**
- 1: ERR_CODE_UNSUPPORTED_CMD
- 2: ERR_CODE_NOT_FOUND
- 3: ERR_CODE_TABLE_FULL
- 4: ERR_CODE_BAD_STATE
- 5: ERR_CODE_FILE_IO_ERROR
- 6: ERR_CODE_ILLEGAL_ARG

### CRITICAL: Channels vs. Rooms

**Channels** (numeric identifiers):
- Channel 0 = "Public Channel" (default flood-mode broadcast)
- Channel 1+ = Reserved for future
- **Ephemeral** - messages NOT persisted
- Use `CMD_SEND_CHANNEL_TXT_MSG`

**Rooms** (ADV_TYPE_ROOM contacts):
- Named contacts with public keys
- **Persistent and immutable storage**
- Use `CMD_SEND_TXT_MSG` with room's public key (direct message)
- Optional: Login with `CMD_SEND_LOGIN` to read stored messages

**SAR Message Routing:**
- **SAR markers MUST be sent to rooms, NOT public channel**
- Rooms provide reliable delivery and storage for critical SAR data

### Room Login Protocol Flow (CRITICAL)

1. **Client sends `CMD_SEND_LOGIN` (26)**: Radio internally generates sender_timestamp and sync_since
2. **Room server processes login**: Validates password, stores sync_since, delays first push 2000ms
3. **Client receives response**: `PUSH_CODE_LOGIN_SUCCESS` (0x85) or `PUSH_CODE_LOGIN_FAIL` (0x86)
4. **Room server auto-pushes messages**: Round-robin every 1200ms, sends messages where post_timestamp > sync_since
5. **Client receives pushed messages**: `PUSH_CODE_MSG_WAITING` (0x83) → call `CMD_SYNC_NEXT_MESSAGE` (10)

**Implementation Rules:**
- ❌ DO NOT call `syncAllMessages()` after `PUSH_CODE_LOGIN_SUCCESS`
- ✅ DO wait for `PUSH_CODE_MSG_WAITING` push notifications
- ✅ DO call `syncNextMessage()` when `onMessageWaiting` fires

### Cayenne LPP Format

Format: `[Channel] [Type] [Data...]`

**Supported Types:**
- 136 (0x88): GPS Location (lat/lon/alt: int32/10000, int32/10000, int32/100)
- 103 (0x67): Temperature (int16/10 for °C)
- 2 (0x02): Analog Input (uint16/100 for volts, used for battery)

### SAR Message Format

Format: `S:<emoji>:<latitude>,<longitude>:<optional_message>`

**Recognized Emojis:**
- 🧑 or 👤: Found Person
- 🔥: Fire Location
- 🏕️ or ⛺: Staging Area

**Rules:**
- Must start with `S:`
- Single emoji after first colon
- Comma-separated lat/lon coordinates
- Optional message after third colon (displayed in message bubble)
- No spaces in coordinates section

**Examples:**
- `S:🧑:37.7749,-122.4194` - Basic SAR marker
- `S:🔥:40.7128,-74.0060:Large wildfire spreading rapidly` - With message
- `S:🏕️:34.0522,-118.2437:Base camp established, supplies available` - With detailed note

**Message Display:**
- SAR markers shown with highlighted colored bubble
- Emoji, type name, and coordinates always displayed
- Optional message shown in secondary container below coordinates
- Tap to navigate to location on map

### Map Drawing Message Format

Format: `D:<json>`

**Ultra-Compact JSON Format:**
- **Prefix**: `D:` identifies drawing messages
- **Sender**: Extracted from packet metadata (not in JSON)
- **Type field (`t`)**: Shape type as integer
  - `0`: Line drawing
  - `1`: Rectangle drawing
- **Color field (`c`)**: Color index (0-7)
  - `0`: Red, `1`: Blue, `2`: Green, `3`: Yellow
  - `4`: Orange, `5`: Purple, `6`: Pink, `7`: Cyan
- **Points field (`p`)**: Flat array of coordinates `[lat1,lon1,lat2,lon2,...]`
- **Bounds field (`b`)**: Rectangle bounds `[topLat,topLon,botLat,botLon]`

**Example Line Drawing (red, 2 points):**
```json
D:{"t":0,"c":0,"p":[45.123,-122.456,45.234,-122.567]}
```

**Example Rectangle Drawing (blue):**
```json
D:{"t":1,"c":1,"b":[45.1,-122.5,45.2,-122.4]}
```

**Implementation Details:**
- Models: `lib/models/map_drawing.dart` (MapDrawing, LineDrawing, RectangleDrawing)
- Parser: `lib/utils/drawing_message_parser.dart` (DrawingMessageParser)
- Provider: `lib/providers/drawing_provider.dart` (DrawingProvider)
- Colors: 8 predefined colors mapped to indices for bandwidth efficiency
- Local persistence uses full JSON format with timestamps and IDs
- Network transmission uses ultra-compact format (~37% size reduction)

## State Management Architecture

### Provider Hierarchy
```
MultiProvider
├── ConnectionProvider      # BLE connection state
├── ContactsProvider        # Contact list
├── MessagesProvider        # Messages + SAR markers
├── MapProvider            # Map navigation
├── DrawingProvider        # Map drawing state
└── AppProvider            # Coordinator (uses all above)
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

**Drawing Message Flow:**
```
User draws → DrawingProvider → DrawingToolbar (share) → ConnectionProvider (BLE)
                                                              ↓
Remote User ← UI ← DrawingProvider ← AppProvider ← ConnectionProvider ← BLE Device
```

**Contact Types:**
- none(0): Unknown/invalid
- chat(1): Team member (shown on map)
- repeater(2): Network repeater node
- room(3): Communication channel/room

**Map Display:** Only `ContactType.chat` with valid GPS shown on map

## Service Layer

### LocationTrackingService (Singleton)
**Purpose:** GPS tracking + intelligent mesh network location broadcasting

**Key Features:**
- Callback-based architecture (onPositionUpdate, onError, onBroadcastSent, onTrackingStateChanged)
- Configurable thresholds (minDistanceMeters: 5.0m, maxDistanceMeters: 100.0m, minTimeIntervalSeconds: 30s)
- Smart broadcasting: First = immediate, ≥100m = immediate, ≥5m + ≥30s = broadcast
- Haversine distance calculation for GPS accuracy

**Files:** lib/services/location_tracking_service.dart (501 lines)

### MapMarkerService (Singleton)
**Purpose:** Map marker generation + geodesic calculations

**Key Features:**
- Pure functions (testability + performance)
- Contact markers (battery badge, distance from user)
- SAR markers (color-coded: green=person, red=fire, orange=staging)
- Calculate distance, bearing/azimuth, format distance display
- Automatic "time ago" labels

**Files:** lib/services/map_marker_service.dart (518 lines)

### ValidationService (Singleton)
**Purpose:** Form validation + input parsing with structured error handling

**Key Features:**
- Structured result types (`ValidationResult`, `ParseResult<T>`)
- Coordinate validation (lat: -90 to +90, lon: -180 to +180)
- Radio parameters (freq: 137-1020 MHz, bw: 7.8-500 kHz, sf: 5-12, cr: 5-8, tx: -9 to +22 dBm)
- Text/name validation, zoom level (0-19)

**Files:** lib/services/validation_service.dart (511 lines)

## Map Implementation

### Tile Layers
1. **OpenStreetMap** (default): Max zoom 19, street-level navigation
2. **OpenTopoMap**: Max zoom 17, topographic features
3. **ESRI World Imagery**: Max zoom 19, satellite imagery

### Offline Tile Caching
- Backend: `flutter_map_tile_caching` with ObjectBox
- Behavior: `CacheBehavior.cacheFirst`, 30-day validity
- Region downloads: `RectangleRegion(bounds)` → `store.download.startForeground()`

### Map Markers
**Team Member (Blue):** CircleAvatar, battery badge, name label, tap for details
**SAR Event (Color-coded):** Green (person), Red (fire), Orange (staging), time ago label, type label, tap for details

### Map Navigation
Message tab → tap SAR marker → `MapProvider.navigateToLocation()` → switch to Map tab → `MapTab._handleMapNavigation()` → `MapProvider.clearNavigation()`

### User Location Tracking
- Permission: `NSLocationWhenInUseUsageDescription`, `NSLocationTemporaryPreciseUsageDescription`
- Accuracy: `LocationAccuracy.best`, distance filter: 10m
- Marker: Blue pulsing circle, navigation icon, tap to center/track

### Map Legend
Collapsible legend (top-right), shows counts of team members and SAR markers

### Detailed Compass Dialog
Ultra-compact location display, tap to toggle DD/DMS formats, no close button (tap outside to close)

## Common Development Tasks

### Adding a New BLE Command
1. Add command code to `lib/services/meshcore_constants.dart`
2. Add frame builder in `lib/services/protocol/frame_builder.dart`
3. Add public API method in `lib/services/meshcore_ble_service.dart`
4. Add response parser in `lib/services/protocol/frame_parser.dart`
5. Handle response in `lib/services/ble/ble_response_handler.dart`
6. Add callback in `lib/services/meshcore_ble_service.dart`

### Adding a New SAR Marker Type
1. Update enum in `lib/models/sar_marker.dart`
2. Add to parser in `lib/utils/sar_message_parser.dart`
3. Add color in `lib/widgets/map_markers.dart`
4. Update providers in `lib/providers/messages_provider.dart`

### Adding a New Map Layer
1. Add to model in `lib/models/map_layer.dart`
2. Add to `allLayers` list
3. Layer appears automatically in layer selector UI

### Working with Map Drawings
**Drawing Flow:**
1. User selects drawing mode (line/rectangle) → `DrawingProvider.setDrawingMode()`
2. User taps map → touch events captured by `DrawingLayer`
3. Preview rendered during drawing → `DrawingProvider.getPreviewDrawing()`
4. User completes drawing → saved to `DrawingProvider._drawings` list
5. User shares drawing → `DrawingToolbar._shareDrawingsToChannel()` or `_shareDrawingsToRoom()`
6. Message sent via BLE → `ConnectionProvider.sendChannelMessage()` or `sendTextMessage()`
7. Receiver parses message → `DrawingMessageParser.parseDrawingMessage()` with sender from packet
8. Drawing added to map → `DrawingProvider.addReceivedDrawing()`

**Color Management:**
- UI uses `DrawingColors.palette` (8 Flutter Color objects)
- Network uses color indices (0-7) via `DrawingColors.colorToIndex()`/`indexToColor()`
- Persistence uses full ARGB32 color values

**Key Files:**
- Models: `lib/models/map_drawing.dart` (278 lines)
- Parser: `lib/utils/drawing_message_parser.dart` (45 lines)
- Provider: `lib/providers/drawing_provider.dart` (280 lines)
- UI: `lib/widgets/map/drawing_toolbar.dart`, `lib/widgets/map/drawing_layer.dart`

## Internationalization (i18n)

### Supported Languages
- **English (en)**: Default language
- **Croatian (hr)**: Hrvatski - Full localization
- **Slovenian (sl)**: Slovenščina - Full localization

### Localization Files
- **ARB files**: `lib/l10n/app_{locale}.arb` (Application Resource Bundle)
- **Generated class**: `lib/l10n/app_localizations.dart` (auto-generated, do not edit)
- **Configuration**: `l10n.yaml` in project root

### Adding Localized Strings

1. **Add to English ARB** (`lib/l10n/app_en.arb`):
```json
{
  "myNewString": "My new text",
  "@myNewString": {
    "description": "Description of what this string is for"
  },
  "stringWithParam": "Hello {name}",
  "@stringWithParam": {
    "description": "Greeting with name parameter",
    "placeholders": {
      "name": {"type": "String"}
    }
  }
}
```

2. **Add translations** to `app_hr.arb` and `app_sl.arb`

3. **Generate localization files**:
```bash
flutter gen-l10n
```

4. **Use in code**:
```dart
import '../l10n/app_localizations.dart';

// In build method:
Text(AppLocalizations.of(context)!.myNewString)
Text(AppLocalizations.of(context)!.stringWithParam('John'))
```

### Important Notes
- **Import path**: Always use `import '../l10n/app_localizations.dart'` (relative path from widget location)
- **Do NOT use**: `import 'package:flutter_gen/gen_l10n/app_localizations.dart'` (incorrect)
- **Generate after changes**: Run `flutter gen-l10n` after modifying ARB files
- **Null safety**: Use `AppLocalizations.of(context)!` (with null assertion operator)

### Localized Components
All major UI components are fully localized:
- Home screen and status indicators
- Settings screen and preferences
- Messages tab and SAR markers
- Contacts tab and contact details
- Map screen and compass dialog
- Drawing tools and filters
- All dialogs and confirmation messages

## Build Commands

```bash
# Dependencies
flutter pub get

# Localization
flutter gen-l10n        # Generate localization files after ARB changes

# Development
flutter run               # Debug mode
flutter run -d <device>   # Specific device
# Hot reload: press 'r'  |  Hot restart: press 'R'

# Code Quality
flutter analyze          # Static analysis
flutter test            # Run tests
dart format lib/        # Format code
flutter clean           # Clean build

# iOS
flutter build ios --release
flutter build ipa

# Android
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

## Troubleshooting

### BLE Issues
- **"Bluetooth adapter not available"**: Check Bluetooth on, verify permissions, check Info.plist/AndroidManifest.xml
- **"Connection failed"**: BLE support required, check service UUID, verify range (<10m), try scanning again

### Runtime Issues
**MissingPluginException**: Native plugin not installed (common after adding dependencies)
```bash
cd ios && pod install && cd .. && flutter clean && flutter pub get && flutter run
```

### Build Issues
**iOS Pod Install Fails**:
```bash
cd ios && rm Podfile.lock && rm -rf Pods/ && pod install --repo-update && cd ..
```

**CocoaPods ObjectBox Version Conflict**:
```bash
cd ios && rm Podfile.lock && rm -rf Pods/ && pod repo update && pod install && cd ..
flutter clean && flutter pub get && flutter run
```

**Android Gradle Timeout**: Add to `android/gradle.properties`:
```
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx4096m
```

**Flutter Version Conflicts**:
```bash
flutter channel stable && flutter upgrade && flutter pub upgrade
```

## Performance Optimization

### BLE Communication
- Buffer incoming data for partial packets
- Throttle telemetry requests (max 1/sec per contact)
- Use `notifyListeners()` sparingly

### Map Performance
- Limit visible markers (cluster if >100)
- Use `repaint boundary` for marker widgets
- Implement marker virtualization for large datasets

### Memory Management
- Dispose controllers in `dispose()` methods
- Clear message history after 1000 messages
- Implement tile cache size limits

## Security Considerations
- **BLE**: No authentication in current protocol - add encryption for production
- **Permissions**: Request minimum required
- **Data**: No sensitive data logging
- **Network**: HTTPS for all tile sources

## References
- [Flutter Documentation](https://docs.flutter.dev/)
- [flutter_blue_plus API](https://pub.dev/documentation/flutter_blue_plus/)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [MeshCore Protocol](https://github.com/meshcore-dev/meshcore.js)
- [Cayenne LPP Specification](https://developers.mydevices.com/cayenne/docs/lora/#lora-cayenne-low-power-payload)
- [Provider Package](https://pub.dev/packages/provider)
