# Advertisement Path Tracking Implementation

## Overview
Contacts now automatically track their advertisement location history, allowing visualization of movement paths on the map.

## Implementation Details

### 1. Data Model (lib/models/)

#### AdvertLocation Model
**File**: `lib/models/advert_location.dart`

- Stores a single GPS point with timestamp
- Provides `timeAgo` display formatting
- Immutable value object with proper equality implementation

#### Contact Model Updates
**File**: `lib/models/contact.dart`

**New fields:**
- `advertHistory: List<AdvertLocation>` - Stores up to 100 most recent location points

**New methods:**
- `addAdvertLocation(LatLng, DateTime)` - Intelligently adds location to history
  - Deduplicates points (skips if <5m apart and <60s interval)
  - Maintains max 100 points (oldest removed first)
  - Uses Haversine formula for distance calculation

### 2. State Management (lib/providers/)

#### ContactsProvider Updates
**File**: `lib/providers/contacts_provider.dart`

**Modified**: `addOrUpdateContact()` method
- Automatically adds advertisement location to history when contact is updated
- Preserves existing history when updating contacts
- Timestamp extracted from `lastAdvert` field (Unix seconds)

#### MapProvider Updates
**File**: `lib/providers/map_provider.dart`

**New state:**
- `_visibleContactPaths: Set<String>` - Tracks which paths are currently visible

**New methods:**
- `toggleContactPath(publicKeyHex)` - Show/hide path for specific contact
- `isContactPathVisible(publicKeyHex)` - Check path visibility
- `hideAllPaths()` - Clear all visible paths
- `showOnlyPath(publicKeyHex)` - Isolate single contact's path

### 3. Map Rendering (lib/screens/)

#### MapTab Updates
**File**: `lib/screens/map_tab.dart`

**Added**: `PolylineLayer` before `MarkerLayer`
- Renders blue polylines with white borders (3px stroke + 1px border)
- Only renders paths for contacts marked as visible in MapProvider
- Only renders if contact has ≥2 location points
- Uses `Consumer<MapProvider>` to reactively update when visibility changes

**Visual styling:**
- Color: `Colors.blue` with 70% opacity
- Border: `Colors.white` with 50% opacity
- Stroke width: 3px (main), 1px (border)

### 4. User Interface (lib/widgets/)

#### DetailedCompassDialog Updates
**File**: `lib/widgets/map/detailed_compass_dialog.dart`

**Added**: Path toggle button in contact detail view
- Only visible when contact has ≥2 location points
- Shows route icon (filled when active, outlined when inactive)
- Tooltip displays current state and point count
- Primary color when path is visible
- Uses `Consumer<MapProvider>` for reactivity

**User flow:**
1. Tap contact marker on map → opens detailed compass dialog
2. If contact has movement history (≥2 points), path toggle button appears
3. Tap button → path appears on map as blue polyline
4. Tap again → path disappears

### 5. Data Flow

```
BLE Device → PUSH_CODE_NEW_ADVERT (0x8A)
    ↓
FrameParser.parseContact()
    ↓
ContactsProvider.addOrUpdateContact()
    ↓
Contact.addAdvertLocation() [auto-deduplication]
    ↓
advertHistory updated (max 100 points)
    ↓
MapTab.PolylineLayer renders if path visible
```

### 6. Storage Behavior

**Persistence**: Advertisement history is persisted via `ContactStorageService`
- Uses `contact_storage.json` in app documents directory
- Automatically saved when contacts are updated
- Loaded on app startup

**Capacity**: Each contact stores up to 100 location points
- Oldest points automatically removed when limit reached
- Prevents unbounded memory growth

## Usage Example

1. **Automatic tracking** - No user action required:
   ```
   Contact broadcasts location → History automatically updated
   ```

2. **View path on map**:
   ```
   Tap contact marker → Path toggle button → Tap to show → Blue line appears
   ```

3. **Multiple paths**:
   ```
   Each contact has independent path visibility
   Can show multiple paths simultaneously
   ```

## Performance Considerations

1. **Deduplication**: Prevents excessive data accumulation for stationary contacts
   - Skip if <5 meters apart AND <60 seconds interval

2. **Bounded history**: Max 100 points per contact
   - Typical SAR operation: 1 point/minute × 8 hours = 480 points (trimmed to 100)

3. **Conditional rendering**: Polylines only rendered when:
   - Path visibility enabled via MapProvider
   - Contact has ≥2 location points

4. **Memory efficiency**:
   - Each AdvertLocation: ~48 bytes (2 doubles + DateTime)
   - Max per contact: 100 × 48 = ~4.8KB
   - 50 contacts: ~240KB total

## Future: GPX Export (Not Implemented)

### Rationale for Deferring
GPX export was intentionally NOT implemented in this iteration to:
1. Validate path tracking UX first
2. Gather user feedback on data granularity needs
3. Determine preferred export formats (GPX vs KML vs GeoJSON)

### Implementation Considerations

When implementing GPX export, consider:

1. **Track segmentation**:
   ```xml
   <trk>
     <name>Contact Name - YYYY-MM-DD</name>
     <trkseg>
       <trkpt lat="46.0569" lon="14.5058">
         <time>2025-01-15T10:30:00Z</time>
       </trkpt>
       <!-- More points -->
     </trkseg>
   </trk>
   ```

2. **Metadata**:
   - Contact name
   - Date range of track
   - Device type (from contact telemetry)
   - Total distance traveled
   - Duration

3. **Gap handling**:
   - Break into segments if gap >15 minutes between points
   - Prevents drawing straight lines across large time gaps

4. **Multi-contact export**:
   - Option to export all visible paths as separate tracks
   - Single GPX file with multiple `<trk>` elements

5. **UI integration**:
   - Add "Export Path" button in detailed compass dialog
   - Share sheet for exporting GPX file
   - Option to select date range

### Recommended Package
```yaml
dependencies:
  gpx: ^2.2.0  # GPX file generation and parsing
```

### Sample Implementation (Future)
```dart
import 'package:gpx/gpx.dart';

String exportContactPathToGpx(Contact contact) {
  final gpx = Gpx();
  gpx.creator = 'MeshCore SAR';

  final track = Trk();
  track.name = '${contact.advName} - ${DateTime.now().toIso8601String()}';

  final segment = Trkseg();
  for (final point in contact.advertHistory.reversed) {
    segment.trkpts.add(Wpt(
      lat: point.location.latitude,
      lon: point.location.longitude,
      time: point.timestamp,
    ));
  }

  track.trksegs.add(segment);
  gpx.trks.add(track);

  return GpxWriter().asString(gpx, pretty: true);
}
```

## Testing Checklist

- [x] Advertisement locations automatically tracked when contact updates
- [x] Deduplication prevents duplicate points for stationary contacts
- [x] History limited to 100 points per contact
- [x] Path toggle button appears only when ≥2 points exist
- [x] Polyline renders correctly on map
- [x] Path visibility persists across dialog open/close
- [x] Multiple contact paths can be visible simultaneously
- [ ] GPX export (deferred to future iteration)

## Known Limitations

1. **No manual path clearing**: Users cannot manually clear a contact's path history
   - Workaround: Path auto-trims to 100 points

2. **No date range filtering**: Cannot view path for specific time period
   - All points always rendered (up to 100)

3. **No distance/duration display**: Path metadata not calculated
   - Future enhancement: Show "Total: 2.4km over 3h"

## Migration Notes

**Existing contacts**: No migration required
- Existing contacts start with empty `advertHistory`
- History begins accumulating from first update after app upgrade
- No data loss or corruption risk

**Storage format**: JSON-compatible
- `advertHistory` serialized as array of objects
- Standard DateTime ISO-8601 strings
- LatLng as lat/lon decimal degrees
