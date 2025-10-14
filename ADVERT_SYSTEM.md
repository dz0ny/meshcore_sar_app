# MeshCore Advertisement System

This document explains how the MeshCore mesh network advertisement system works and how your app receives and processes contact updates.

## Overview

The MeshCore mesh network uses a broadcast advertisement system where nodes periodically announce their presence, location, and metadata to the network. Your Flutter app receives these advertisements and automatically updates the contact list.

## Advertisement Flow

### 1. Node Broadcasts Advertisement

When a node in the mesh network wants to announce its presence:
- The node broadcasts an advertisement packet over LoRa
- Advertisement contains: public key, name, location, type, etc.
- Advertisements are typically sent every few minutes or when data changes

### 2. Companion Radio Receives Advertisement

Your BLE-connected companion radio listens to the mesh network and receives these advertisements:

```
[Mesh Network] ───(LoRa)──→ [Companion Radio]
```

### 3. Companion Radio Notifies App

The companion radio forwards advertisement notifications to your app via BLE:

#### Step 3a: PUSH_CODE_ADVERT (0x80)
First, you receive a simple notification that an advert was received:

```dart
flutter: 📥 [RX] Received: ADVERT (0x80)
flutter:   Data size: 33 bytes
flutter:   Payload: 32 bytes
flutter:   → Handling Advert push
flutter:   [Advert] Parsing advert push notification...
flutter:     📡 ADVERT RECEIVED FROM NODE:
flutter:        Public key prefix (6 bytes): a5:9c:36:02:c0:d7
flutter:        Public key (full 32 bytes): a5:9c:36:02:c0:d7:e4:c3:...
flutter:     ℹ️  This indicates the node is broadcasting its presence
flutter:     ℹ️  The companion radio will automatically update contact info
flutter:     ℹ️  Expected follow-up:
flutter:        - If manual_add_contacts=0: PUSH_CODE_NEW_ADVERT with full details
flutter:        - If manual_add_contacts=1: Call CMD_GET_CONTACTS to sync
```

**Protocol Format:**
```
[0x80] - PUSH_CODE_ADVERT
[32 bytes] - Public key of advertising node
```

#### Step 3b: PUSH_CODE_NEW_ADVERT (0x8A) - Automatic Contact Update

If your device has `manual_add_contacts=0` (automatic mode), the companion radio automatically sends the full contact details:

```dart
flutter: 📥 [RX] Received: NEW_ADVERT (0x8A)
flutter:   Data size: 145 bytes
flutter:   Payload: 144 bytes
flutter:   → Handling NewAdvert push
flutter:   [NewAdvert] Parsing new advertisement...
flutter:     Public key prefix: a5:9c:36:02:c0:d7
flutter:     Type byte: 1 → Type: ContactType.chat
flutter:     Advertised name: "SAR Team Alpha"
flutter:     Latitude: 46.056900°
flutter:     Longitude: 14.505800°
flutter:   ✅ [NewAdvert] Parsed successfully - new contact advertised on network
```

**Protocol Format:**
```
[0x8A] - PUSH_CODE_NEW_ADVERT
[32 bytes] - Public key
[1 byte] - Type (ADV_TYPE_*)
[1 byte] - Flags
[1 byte] - Out path length
[64 bytes] - Out path
[32 bytes] - Advertised name (null-terminated)
[4 bytes] - Last advert timestamp (uint32)
[4 bytes] - Latitude * 1E6 (int32)
[4 bytes] - Longitude * 1E6 (int32)
[4 bytes] - Last modified timestamp (uint32)
```

The app automatically adds/updates this contact via the `onContactReceived` callback!

## Manual vs Automatic Contact Management

Your companion radio has a setting called `manual_add_contacts`:

### Automatic Mode (manual_add_contacts=0) - RECOMMENDED

**Behavior:**
1. ✅ PUSH_CODE_ADVERT (0x80) received → just informational
2. ✅ PUSH_CODE_NEW_ADVERT (0x8A) received → **contact automatically added to app**
3. ✅ No action needed from app

**Advantages:**
- Contacts appear instantly when they advertise
- No need to manually sync
- Perfect for SAR operations where team members join dynamically

### Manual Mode (manual_add_contacts=1)

**Behavior:**
1. ✅ PUSH_CODE_ADVERT (0x80) received → informational
2. ❌ PUSH_CODE_NEW_ADVERT (0x8A) NOT sent
3. 📞 App must call `CMD_GET_CONTACTS` to sync

**When to use:**
- When you want control over which contacts are added
- When bandwidth is very limited
- When you have a static team roster

## Implementation in Your App

### Current Implementation

The app is already fully configured to handle advertisements automatically:

```dart
// In MeshCoreBleService (_handleNewAdvert)
final contact = Contact(
  publicKey: publicKey,
  type: type,
  flags: flags,
  outPathLen: outPathLen,
  outPath: outPath,
  advName: advName,
  lastAdvert: lastAdvert,
  advLat: advLat,
  advLon: advLon,
  lastMod: lastMod,
);

// This callback automatically updates the contact list
onContactReceived?.call(contact);
```

```dart
// In AppProvider (_setupCallbacks)
connectionProvider.onContactReceived = (contact) {
  // Automatically add or update contact in the list
  contactsProvider.addOrUpdateContact(contact);
};
```

### Event Flow

```
[Mesh Node Advertises]
        ↓
[Companion Radio Receives via LoRa]
        ↓
[PUSH_CODE_ADVERT (0x80) sent to app]
        ↓ (if manual_add_contacts=0)
[PUSH_CODE_NEW_ADVERT (0x8A) sent to app]
        ↓
[onContactReceived callback fired]
        ↓
[contactsProvider.addOrUpdateContact(contact)]
        ↓
[UI automatically updates via notifyListeners()]
```

## Checking Your Device Settings

To see if your device is in automatic or manual mode:

```dart
// Check the manualAddContacts field from SelfInfo
final manualMode = connectionProvider.deviceInfo.manualAddContacts;

if (manualMode == false) {
  print('✅ Automatic mode: Contacts will appear automatically');
} else {
  print('⚠️ Manual mode: You need to call getContacts() after adverts');
}
```

You can change this setting:

```dart
await connectionProvider.setOtherParams(
  manualAddContacts: 0, // 0 = automatic, 1 = manual
  telemetryModes: currentTelemetryModes,
  advertLocationPolicy: currentLocationPolicy,
);
```

## Troubleshooting

### "I receive ADVERT (0x80) but no NEW_ADVERT (0x8A)"

**Cause:** Your device is in manual mode (`manual_add_contacts=1`)

**Solution:**
1. Check device settings via SelfInfo
2. Change to automatic mode, OR
3. Call `CMD_GET_CONTACTS` after receiving adverts

### "Contacts don't appear on the map"

**Possible causes:**
1. Contact type is not `ContactType.chat` (only chat contacts show on map)
2. Contact has no GPS coordinates (lat/lon = 0)
3. Contact hasn't advertised recently

**Debug:**
```dart
// Check contact properties
print('Contact: ${contact.advName}');
print('Type: ${contact.type}'); // Should be ContactType.chat
print('Lat: ${contact.latitude}'); // Should not be null
print('Lon: ${contact.longitude}'); // Should not be null
```

### "Room contact not found for login"

**Cause:** Room hasn't advertised yet or wasn't synced

**Solution:**
```dart
// Force sync contacts first
await connectionProvider.getContacts();

// Small delay to ensure contacts are loaded
await Future.delayed(const Duration(milliseconds: 500));

// Then try login
await connectionProvider.loginToRoom(
  roomPublicKey: roomContact.publicKey,
  password: 'your_password',
);
```

## Best Practices

1. **Use automatic mode for SAR operations** - Team members will appear as they join
2. **Sync contacts on first connect** - Always call `getContacts()` after connecting
3. **Handle both modes gracefully** - Check `manual_add_contacts` setting
4. **Monitor advert activity** - Use `onAdvertReceived` callback to show network activity
5. **Cache contacts locally** - Don't rely solely on live advertisements

## Protocol Summary

| Push Code | Name | When Sent | Contains | Action Required |
|-----------|------|-----------|----------|-----------------|
| 0x80 | PUSH_CODE_ADVERT | When any node advertises | Just public key | None (informational) |
| 0x8A | PUSH_CODE_NEW_ADVERT | After ADVERT, if manual_add_contacts=0 | Full contact details | None (auto-added) |

## Example Logs

### Successful Automatic Flow

```
📥 [RX] Received: ADVERT (0x80)
  📡 ADVERT RECEIVED FROM NODE:
     Public key prefix (6 bytes): a5:9c:36:02:c0:d7
📥 [Provider] Advert received from node
  Note: Waiting for PUSH_CODE_NEW_ADVERT (0x8A) with full contact details

📥 [RX] Received: NEW_ADVERT (0x8A)
  [NewAdvert] Parsing new advertisement...
    Advertised name: "SAR Team Alpha"
    Latitude: 46.056900°
    Longitude: 14.505800°
  ✅ [NewAdvert] Parsed successfully
✅ [Provider] Contact added: SAR Team Alpha
```

### Manual Mode Flow

```
📥 [RX] Received: ADVERT (0x80)
  📡 ADVERT RECEIVED FROM NODE:
     Public key prefix (6 bytes): a5:9c:36:02:c0:d7
📥 [Provider] Advert received from node
  Note: manual_add_contacts=1, you need to call CMD_GET_CONTACTS

📤 [TX] Sending command: GET_CONTACTS (0x04)
📥 [RX] Received: CONTACTS_START (0x02)
📥 [RX] Received: CONTACT (0x03)
  [Contact] Parsing contact...
    Advertised name: "SAR Team Alpha"
✅ [Provider] Contact added: SAR Team Alpha
```

## Related Files

- `lib/services/meshcore_ble_service.dart:876` - `_handleAdvert()` implementation
- `lib/services/meshcore_ble_service.dart:924` - `_handleNewAdvert()` implementation
- `lib/providers/connection_provider.dart:164` - `onAdvertReceived` callback setup
- `lib/providers/app_provider.dart:44` - Contact sync setup
- `lib/models/contact.dart` - Contact data model

## Further Reading

- [MeshCore Protocol Documentation](CLAUDE.md) - Full protocol specification
- [Contact Management](lib/providers/contacts_provider.dart) - Contact provider implementation
