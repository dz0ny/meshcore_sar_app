# CLAUDE.md - MeshCore SAR App Technical Reference

This document provides technical details for AI assistants (like Claude) working with this codebase.

## Project Overview

**Type**: Flutter Mobile Application
**Purpose**: Search and Rescue (SAR) operations with MeshCore mesh network devices
**Architecture**: Provider-based state management with BLE communication
**Target Platforms**: iOS 13+, Android 5.0+ (API 21+)

## Project Structure

```
lib/
├── models/              # Data models
│   ├── contact.dart            # Contact with telemetry
│   ├── contact_telemetry.dart  # GPS, battery, temperature
│   ├── message.dart            # Messages and SAR markers
│   ├── sar_marker.dart         # SAR tactical markers
│   ├── device_info.dart        # BLE device connection state
│   └── map_layer.dart          # Map tile layer definitions
├── services/            # Business logic services
│   ├── meshcore_ble_service.dart      # BLE communication
│   ├── meshcore_constants.dart        # Protocol constants
│   ├── buffer_reader.dart             # Binary protocol reader
│   ├── buffer_writer.dart             # Binary protocol writer
│   ├── cayenne_lpp_parser.dart        # Telemetry decoder
│   └── tile_cache_service.dart        # Offline map tiles
├── providers/           # State management
│   ├── connection_provider.dart       # BLE connection state
│   ├── contacts_provider.dart         # Contact list management
│   ├── messages_provider.dart         # Message history + SAR markers
│   ├── map_provider.dart              # Map navigation state
│   └── app_provider.dart              # Coordinator provider
├── screens/             # UI screens
│   ├── home_screen.dart        # Main screen with tabs
│   ├── messages_tab.dart       # Message list view
│   ├── contacts_tab.dart       # Contact list view
│   └── map_tab.dart            # Interactive map view
├── widgets/             # Reusable UI components
│   └── map_markers.dart        # Custom map marker widgets
├── utils/               # Utilities
│   └── sar_message_parser.dart # Parse S:<emoji>:lat,lon format
└── main.dart            # App entry point
```

## Key Technologies

### Core Dependencies
- **flutter_blue_plus** (^2.0.0): BLE communication
- **flutter_map** (^8.2.2): Interactive mapping with OpenStreetMap
- **flutter_map_tile_caching** (^10.1.1): Offline map tile storage
- **provider** (^6.1.0): State management
- **latlong2** (^0.9.0): GPS coordinate handling
- **geolocator** (^14.0.2): Precise GPS location tracking
- **permission_handler** (^12.0.1): Runtime permissions

### MeshCore Protocol

The app implements the MeshCore BLE protocol based on https://github.com/meshcore-dev/meshcore.js

**BLE Service**: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
**RX Characteristic** (write): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
**TX Characteristic** (notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

#### Command Codes (Client → Device)
- `4`: Get contacts list
- `2`: Send text message
- `39`: Request telemetry

#### Response Codes (Device → Client)
- `3`: Contact information
- `7`: Message received
- `0x8B` (139): Telemetry response (Cayenne LPP format)

#### Binary Protocol Format

All protocol messages use little-endian byte order.

**Get Contacts Request**:
```
[0x04] - Command code
```

**Contact Response**:
```
[0x03] - Response code
[32 bytes] - Public key
[1 byte] - Contact type (0=none, 1=chat, 2=repeater, 3=room)
[64 bytes] - Advertised name (null-terminated string)
[4 bytes] - Latitude (int32, divide by 10000 for degrees)
[4 bytes] - Longitude (int32, divide by 10000 for degrees)
```

**Message Received**:
```
[0x07] - Response code
[1 byte] - Message type (0=contact, 1=channel)
[4 bytes] - Sender public key prefix
[4 bytes] - Recipient public key prefix
[2 bytes] - Text length (uint16)
[N bytes] - UTF-8 text
```

**Send Text Message**:
```
[0x02] - Command code
[32 bytes] - Recipient public key
[2 bytes] - Text length (uint16)
[N bytes] - UTF-8 text
```

**Request Telemetry**:
```
[0x27] (39) - Command code
[32 bytes] - Contact public key
```

**Telemetry Response**:
```
[0x8B] (139) - Response code
[4 bytes] - Contact public key prefix
[N bytes] - Cayenne LPP payload
```

### Cayenne LPP Format

Telemetry data uses Cayenne Low Power Payload format:

```
[Channel] [Type] [Data...]
```

**Supported Types**:
- `136` (0x88): GPS Location
  - 4 bytes: Latitude (int32, divide by 10000)
  - 4 bytes: Longitude (int32, divide by 10000)
  - 4 bytes: Altitude (int32, divide by 100)
- `103` (0x67): Temperature Sensor
  - 2 bytes: Temperature (int16, divide by 10 for °C)
- `2` (0x02): Analog Input (used for battery voltage)
  - 2 bytes: Value (uint16, divide by 100 for volts)

### SAR Message Format

Special tactical markers embedded in messages:

```
S:<emoji>:<latitude>,<longitude>
```

**Recognized Emojis**:
- `🧑` or `👤`: Found Person
- `🔥`: Fire Location
- `🏕️` or `⛺`: Staging Area

**Examples**:
- `S:🧑:46.0569,14.5058` - Person found at coordinates
- `S:🔥:46.0570,14.5060` - Fire detected
- `S:🏕️:46.0571,14.5062` - Base camp location

**Parsing Rules**:
- Must start with `S:`
- Single emoji character after first colon
- Comma-separated lat,lon after second colon
- Coordinates can be negative (e.g., `-12.3456`)
- No spaces allowed in format

## State Management Architecture

### Provider Hierarchy

```
MultiProvider
├── ConnectionProvider      # BLE connection state
├── ContactsProvider        # Contact list
├── MessagesProvider        # Messages + SAR markers
├── MapProvider            # Map navigation
└── AppProvider            # Coordinator (uses all above)
```

### Event Flow

```
BLE Device → MeshCoreBleService → ConnectionProvider → AppProvider
                                         ↓
                                    ContactsProvider
                                    MessagesProvider
                                         ↓
                                        UI
```

**Example: Receiving a Message**

1. BLE device sends message via TX characteristic
2. `MeshCoreBleService._onDataReceived()` parses binary data
3. Calls `onMessageReceived` callback
4. `ConnectionProvider` receives message
5. `AppProvider` enhances message (check for SAR format)
6. `MessagesProvider.addMessage()` stores message
7. UI rebuilds via `Consumer<MessagesProvider>`

### Contact Types

```dart
enum ContactType {
  none(0),      // Unknown/invalid
  chat(1),      // Team member (shown on map)
  repeater(2),  // Network repeater node
  room(3),      // Communication channel/room
}
```

**Map Display Rules**:
- Only `ContactType.chat` contacts with valid GPS are shown on map
- Repeaters and rooms are listed in Contacts tab but not mapped

## Map Implementation

### Tile Layers

Three tile sources are supported via `MapLayer` enum:

1. **OpenStreetMap** (default)
   - URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
   - Max zoom: 19
   - Best for street-level navigation

2. **OpenTopoMap**
   - URL: `https://a.tile.opentopomap.org/{z}/{x}/{y}.png`
   - Max zoom: 17
   - Shows topographic features, elevation contours

3. **ESRI World Imagery**
   - URL: `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}`
   - Max zoom: 19
   - Satellite imagery

### Offline Tile Caching

Uses `flutter_map_tile_caching` with ObjectBox backend:

```dart
// Initialize cache
await FMTCObjectBoxBackend().initialise();
final store = FMTCStore('meshcore_sar_tiles');
await store.manage.create();

// Download region
final region = RectangleRegion(bounds);
await store.download.startForeground(region: region);
```

**Cache Behavior**:
- `CacheBehavior.cacheFirst`: Use cached tiles if available
- 30-day validity period
- Automatic background updates when online

### Map Markers

**Team Member Markers** (Blue):
- CircleAvatar with person icon
- Battery percentage badge at top
- Name label at bottom
- Tap to show details dialog

**SAR Event Markers** (Color-coded):
- Found Person: Green with 🧑
- Fire: Red with 🔥
- Staging Area: Orange with 🏕️
- Time ago label at top
- Type label at bottom
- Tap to show details dialog

### Map Navigation

**Navigation from Messages Tab**:
1. User taps SAR marker message
2. `MapProvider.navigateToLocation()` called
3. Target location and zoom stored in provider
4. Tab switches to Map
5. `MapTab._handleMapNavigation()` moves map
6. `MapProvider.clearNavigation()` resets state

**Zoom State Preservation**:
- Current zoom stored in `MapProvider`
- Maintained across tab switches
- Updated on user zoom gestures

### User Location Tracking

The app tracks the user's precise GPS location in real-time:

**Permission Setup** (iOS Info.plist):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>MeshCore SAR needs location access to display team members and SAR markers on the map</string>
<key>NSLocationTemporaryPreciseUsageDescription</key>
<string>MeshCore SAR needs precise location for accurate positioning in SAR operations</string>
<key>NSLocationDefaultAccuracyReduced</key>
<false/>
```

**Implementation** (lib/screens/map_tab.dart):
```dart
Position? _currentPosition;
bool _trackingLocation = false;

// Request permission and start tracking
final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
  ),
);

// Listen to continuous position updates
Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10, // Update every 10 meters
  ),
).listen((Position position) {
  setState(() => _currentPosition = position);
  if (_trackingLocation) {
    // Auto-center map on user location
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      _mapController.camera.zoom
    );
  }
});
```

**User Location Marker**:
- Blue pulsing circle showing current position
- Navigation icon indicating heading
- Tap location button to center map on user
- Tap again to enable tracking mode (map follows user movement)

### Map Legend

**Collapsible Legend** (lib/screens/map_tab.dart):
- Shows counts of team members and SAR markers
- Click to collapse to compact view
- Click again to expand
- Positioned in top-right corner

```dart
bool _showLegend = true;

GestureDetector(
  onTap: () => setState(() => _showLegend = !_showLegend),
  child: _showLegend
      ? _MapLegend(/* full legend with all counts */)
      : Card(
          child: Column([
            Text('Legend'),
            Icon(Icons.expand_more),
          ]),
        ),
)
```

### Detailed Compass Dialog

**Location Display** (lib/screens/map_tab.dart):
- Ultra-compact location format display with tap-to-toggle formats
- Tap location text to switch between DD and DMS formats
- No labels - just the coordinates for maximum space efficiency
- Two formats available:
  - DD (Decimal Degrees): 5 decimal places (e.g., "46.05690, 14.50580")
  - DMS (Degrees, Minutes, Seconds): Traditional format (e.g., "46°03'24.84"N, 14°30'20.88"E")
- Monospace font for coordinate values

**Dialog Controls**:
- Tap anywhere outside interactive elements to close dialog
- Tap location coordinates to toggle format
- No close button - cleaner, more compact interface

```dart
class _LocationFormatToggle extends StatefulWidget {
  bool _showDMS = false;

  @override
  Widget build(BuildContext context) {
    final displayText = _showDMS
        ? 'DMS format with newline'
        : 'DD format single line';

    return GestureDetector(
      onTap: () => setState(() => _showDMS = !_showDMS),
      behavior: HitTestBehavior.opaque,
      child: Container(/* compact display */),
    );
  }
}
```

## Building and Development

### Development Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run with specific device
flutter run -d <device-id>

# Hot reload (during debug)
# Press 'r' in terminal

# Hot restart (during debug)
# Press 'R' in terminal

# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
dart format lib/

# Clean build
flutter clean
```

### iOS Build

```bash
# Open Xcode workspace
open ios/Runner.xcworkspace

# Build from command line
flutter build ios --release

# Create IPA (requires signing)
flutter build ipa
```

**Key iOS Files**:
- `ios/Runner/Info.plist`: Permissions and app configuration
- `ios/Podfile`: CocoaPods dependencies
- `ios/Runner.xcodeproj`: Xcode project

### Android Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release

# Split APKs by ABI
flutter build apk --split-per-abi
```

**Key Android Files**:
- `android/app/src/main/AndroidManifest.xml`: Permissions and app configuration
- `android/app/build.gradle`: App-level build configuration
- `android/build.gradle`: Project-level build configuration

## Common Development Tasks

### Adding a New BLE Command

1. **Add command code** to `lib/services/meshcore_constants.dart`:
   ```dart
   static const int cmdYourCommand = 42;
   ```

2. **Create command method** in `lib/services/meshcore_ble_service.dart`:
   ```dart
   Future<void> yourCommand() async {
     final writer = BufferWriter();
     writer.writeByte(MeshCoreConstants.cmdYourCommand);
     await _sendCommand(writer.toBytes());
   }
   ```

3. **Handle response** in `_onDataReceived()`:
   ```dart
   case MeshCoreConstants.respYourResponse:
     // Parse response data
     onYourCallback?.call(data);
     break;
   ```

### Adding a New SAR Marker Type

1. **Update enum** in `lib/models/sar_marker.dart`:
   ```dart
   enum SarMarkerType {
     // existing types...
     yourType('🆕', 'Your Type');
   }
   ```

2. **Add to parser** in `lib/utils/sar_message_parser.dart`:
   ```dart
   case '🆕':
     return SarMarkerType.yourType;
   ```

3. **Add color** in `lib/widgets/map_markers.dart`:
   ```dart
   case SarMarkerType.yourType:
     return Colors.purple;
   ```

4. **Update providers** in `lib/providers/messages_provider.dart`:
   ```dart
   List<SarMarker> get yourTypeMarkers =>
       sarMarkers.where((m) => m.type == SarMarkerType.yourType).toList();
   ```

### Adding a New Map Layer

1. **Add to model** in `lib/models/map_layer.dart`:
   ```dart
   static const yourLayer = MapLayer(
     type: MapLayerType.yourLayer,
     name: 'Your Layer',
     urlTemplate: 'https://your-tile-server/{z}/{x}/{y}.png',
     attribution: '© Your Attribution',
     maxZoom: 19,
   );
   ```

2. **Add to list**:
   ```dart
   static const List<MapLayer> allLayers = [
     openStreetMap,
     openTopoMap,
     esriWorldImagery,
     yourLayer, // Add here
   ];
   ```

3. Layer automatically appears in layer selector UI

## Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Manual Testing Checklist

**BLE Connection**:
- [ ] Scan discovers MeshCore devices
- [ ] Connection successful
- [ ] Device info displayed in status bar
- [ ] Disconnect works properly

**Contacts**:
- [ ] Contacts load after connection
- [ ] Contacts grouped by type
- [ ] Telemetry request works
- [ ] Battery/GPS displayed correctly

**Messages**:
- [ ] Messages received and displayed
- [ ] SAR markers highlighted
- [ ] Tap SAR marker navigates to map
- [ ] Message timestamps correct

**Map**:
- [ ] Map loads and displays tiles
- [ ] Team member markers appear
- [ ] SAR markers appear with correct colors
- [ ] Layer switching works
- [ ] Zoom/pan gestures work
- [ ] Marker tap shows details
- [ ] Offline tiles load

## Troubleshooting

### BLE Issues

**"Bluetooth adapter not available"**:
- Check device Bluetooth is on
- Verify permissions granted
- iOS: Check Info.plist has usage descriptions
- Android: Check AndroidManifest.xml has permissions

**"Connection failed"**:
- Device must support BLE
- Check service UUID matches
- Verify device is in range (<10m typically)
- Try scanning again

### Runtime Issues

**MissingPluginException for geolocator or other plugins**:

Example error:
```
MissingPluginException(No implementation found for method isLocationServiceEnabled
on channel flutter.baseflow.com/geolocator_apple)
```

This occurs when native plugin implementations aren't properly installed. Common after adding new dependencies.

**Solution**:
```bash
# For iOS
cd ios
pod install
cd ..

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**If still failing on iOS**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod install
cd ..
flutter clean
flutter pub get
```

### Build Issues

**iOS Pod Install Fails**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod install --repo-update
cd ..
```

**CocoaPods ObjectBox Version Conflict**:

This error occurs when flutter_map_tile_caching updates its ObjectBox dependency but the cached Podfile.lock has an older version:

```
[!] CocoaPods could not find compatible versions for pod "ObjectBox":
  In snapshot (Podfile.lock): ObjectBox (= 1.9.2)
  In Podfile: objectbox_flutter_libs depends on ObjectBox (= 4.4.1)
```

**Solution**:
```bash
# Navigate to iOS directory
cd ios

# Remove cached dependency lock file
rm Podfile.lock

# Remove all installed pods
rm -rf Pods/

# Update CocoaPods repository (this may take a few minutes)
pod repo update

# Reinstall all pods with updated versions
pod install

# Return to project root
cd ..

# Clean Flutter build cache
flutter clean

# Reinstall Flutter dependencies
flutter pub get

# Run the app
flutter run
```

**Alternative solution** (if the above doesn't work):
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod deintegrate
pod cache clean --all
pod setup
pod install
cd ..
flutter clean
flutter pub get
```

**Note**: The `pod repo update` command can take 5-10 minutes as it downloads the entire CocoaPods specifications repository. This is normal.

**Android Gradle Timeout**:
```gradle
// android/gradle.properties
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx4096m
```

**Flutter Version Conflicts**:
```bash
flutter channel stable
flutter upgrade
flutter pub upgrade
```

## Performance Optimization

### BLE Communication
- Buffer incoming data to handle partial packets
- Throttle telemetry requests (max 1 per second per contact)
- Use `notifyListeners()` sparingly in providers

### Map Performance
- Limit visible markers (cluster if >100 markers)
- Use `repaint boundary` for marker widgets
- Implement marker virtualization for large datasets

### Memory Management
- Dispose controllers in `dispose()` methods
- Clear message history after 1000 messages
- Implement tile cache size limits

## Security Considerations

- **BLE**: No authentication in current protocol - add encryption for production
- **Permissions**: Request minimum required permissions
- **Data**: No sensitive data should be logged
- **Network**: Use HTTPS for all tile sources

## Future Enhancements

Potential features to add:

1. **Message Sending**: UI to compose and send messages
2. **Route Recording**: Track team member paths over time
3. **Geofencing**: Alerts when team members enter/exit areas
4. **Voice Notes**: Attach audio to SAR markers
5. **Team Chat**: Real-time chat between team members
6. **Mission Plans**: Pre-loaded search patterns
7. **Statistics**: Coverage analysis, search time tracking

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [flutter_blue_plus API](https://pub.dev/documentation/flutter_blue_plus/)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [MeshCore Protocol](https://github.com/meshcore-dev/meshcore.js)
- [Cayenne LPP Specification](https://developers.mydevices.com/cayenne/docs/lora/#lora-cayenne-low-power-payload)
- [Provider Package](https://pub.dev/packages/provider)

## Contact

For questions or contributions, please refer to the project repository or contact the development team.
