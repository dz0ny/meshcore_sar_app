# Fixing "Not Found" Error When Logging Into Room

## Your Current Situation

You're seeing this sequence:
```
✅ Room "Repetitor" found in app contacts
📤 Sending SEND_LOGIN command
❌ Companion radio responds: ERR_CODE_NOT_FOUND (2)
```

## Root Cause

Your **Flutter app** and the **companion radio firmware** maintain **separate contact lists**:

```
┌─────────────────────────┐          ┌──────────────────────────┐
│   Flutter App           │          │  Companion Radio         │
│  (ContactsProvider)     │          │  (Firmware Storage)      │
├─────────────────────────┤          ├──────────────────────────┤
│                         │          │                          │
│ ✅ Repetitor            │          │ ❌ Repetitor             │
│    15:59:89:54:b4:d4    │  BLE     │    (NOT FOUND!)          │
│                         │ <───>    │                          │
│ Other contacts...       │          │ Other contacts...        │
│                         │          │                          │
└─────────────────────────┘          └──────────────────────────┘
```

When you call `getContacts()`:
- The companion radio sends you a **snapshot** of its contact table
- Your app stores these contacts locally
- But if the radio's contact table changes, your app doesn't know

**The problem:** The room "Repetitor" exists in your app (from an old sync), but NOT in the radio's firmware anymore.

## Why This Happens

1. **Companion radio was factory reset** - Erased all contacts
2. **Contact was manually removed** - Via serial console or config tool
3. **Room never advertised** - Contact was temporary, never saved persistently
4. **Firmware bug** - Contact wasn't properly persisted to flash storage

## Solutions

### Solution 1: Force Re-Sync Contacts (Quick Test)

This will clear your app's contacts and re-fetch from the radio:

```dart
// In your app, add a button to force full sync:
await contactsProvider.clearContacts();
await connectionProvider.getContacts();
await Future.delayed(Duration(milliseconds: 1000));

// Now check what rooms exist:
final rooms = contactsProvider.rooms;
print('Rooms on device: ${rooms.length}');
for (final room in rooms) {
  print('  - ${room.advName}');
}
```

If "Repetitor" is NOT in the list after this sync, then the radio truly doesn't have it.

### Solution 2: Wait for Room to Advertise (Automatic)

If the room server is running and broadcasting:

1. The companion radio will receive the advertisement over LoRa
2. If `manual_add_contacts=0`, you'll automatically receive `PUSH_CODE_NEW_ADVERT` (0x8A)
3. The room will be added to both the radio AND your app
4. Then you can login

**Expected flow:**
```
Room broadcasts → Companion receives → PUSH_CODE_NEW_ADVERT → Contact added → Login works
```

### Solution 3: Manually Add Room Contact (CMD_ADD_UPDATE_CONTACT)

This requires implementing `CMD_ADD_UPDATE_CONTACT` (command code 9) in your app.

**Add this to `MeshCoreBleService`:**

```dart
/// Manually add or update a contact on the companion radio
///
/// This is useful when you need to add a room that hasn't advertised yet,
/// or restore a contact that was deleted from the radio's table.
///
/// Protocol format (CMD_ADD_UPDATE_CONTACT):
/// - 1 byte: command code (9)
/// - 32 bytes: public key
/// - 1 byte: type (ADV_TYPE_*)
/// - 1 byte: flags
/// - 1 byte: out path length (signed)
/// - 64 bytes: out path
/// - 32 bytes: advertised name (null-terminated)
/// - 4 bytes: last advert timestamp (uint32)
/// - 4 bytes: (optional) advert latitude * 1E6 (int32)
/// - 4 bytes: (optional) advert longitude * 1E6 (int32)
Future<void> addOrUpdateContact(Contact contact) async {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdAddUpdateContact); // 0x09
  writer.writeBytes(contact.publicKey); // 32 bytes
  writer.writeByte(contact.type.value); // ADV_TYPE_*
  writer.writeByte(contact.flags); // flags
  writer.writeInt8(contact.outPathLen); // path length (signed byte)
  writer.writeBytes(contact.outPath); // 64 bytes

  // Write name as null-terminated string in 32-byte field
  final nameBytes = Uint8List(32);
  final encoded = utf8.encode(contact.advName);
  final copyLen = encoded.length > 31 ? 31 : encoded.length;
  nameBytes.setRange(0, copyLen, encoded);
  writer.writeBytes(nameBytes);

  writer.writeUInt32LE(contact.lastAdvert); // timestamp
  writer.writeInt32LE(contact.advLat); // latitude * 1E6
  writer.writeInt32LE(contact.advLon); // longitude * 1E6

  await _writeData(writer.toBytes());

  print('✅ [BLE] Sent CMD_ADD_UPDATE_CONTACT for ${contact.advName}');
  print('    This adds the contact to the radio\'s internal table');
}
```

Add the constant:
```dart
// In meshcore_constants.dart
static const int cmdAddUpdateContact = 9;
```

Then in your app, before login:
```dart
// Add the room contact to the radio's table
await connectionProvider.bleService.addOrUpdateContact(widget.contact);

// Small delay to allow radio to save
await Future.delayed(Duration(milliseconds: 300));

// Now login should work
await connectionProvider.loginToRoom(...);
```

### Solution 4: Import Room Contact Card

If you have the room's "business card" (from `CMD_EXPORT_CONTACT`):

1. Get the card data (usually starts with `meshcore://`)
2. Implement `CMD_IMPORT_CONTACT` (command code 18)
3. Import the card

```dart
Future<void> importContact(String cardData) async {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdImportContact); // 0x12
  writer.writeString(cardData); // meshcore:// card data
  await _writeData(writer.toBytes());
}
```

## Recommended Approach

**Step 1:** Force re-sync to see current state
```dart
await contactsProvider.clearContacts();
await connectionProvider.getContacts();
```

**Step 2:** Check if room exists
```dart
final roomExists = contactsProvider.rooms.any(
  (r) => r.publicKeyPrefix.matches(targetPrefix)
);
```

**Step 3a:** If room doesn't exist → **Implement CMD_ADD_UPDATE_CONTACT** (Solution 3)

**Step 3b:** Or wait for room to advertise (Solution 2)

## Implementation Priority

### Immediate Fix (Easiest)
1. ✅ Add contact sync verification (already done!)
2. ✅ Show helpful error messages (already done!)

### Short Term (Recommended)
3. 🔧 **Implement `CMD_ADD_UPDATE_CONTACT`** - This lets you manually restore contacts
4. 🔧 **Implement `CMD_EXPORT_CONTACT`** - This lets you backup/share room contacts

### Long Term (Optional)
5. 📱 Add UI to manually add rooms by public key
6. 💾 Cache room contacts in SharedPreferences
7. 🔄 Auto-restore cached rooms on connect

## Testing Your Fix

1. **Clear app contacts:**
   ```dart
   await contactsProvider.clearContacts();
   ```

2. **Force fresh sync:**
   ```dart
   await connectionProvider.getContacts();
   await Future.delayed(Duration(seconds: 1));
   ```

3. **List actual rooms on device:**
   ```dart
   final rooms = contactsProvider.rooms;
   print('═══════════════════════════════');
   print('Rooms on companion radio: ${rooms.length}');
   for (final room in rooms) {
     print('📍 ${room.advName}');
     print('   PK: ${room.publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
     print('   Type: ${room.type}');
   }
   print('═══════════════════════════════');
   ```

4. **If "Repetitor" is NOT in the list:**
   - The radio truly doesn't have it
   - You need to add it using CMD_ADD_UPDATE_CONTACT
   - Or wait for it to advertise

## Expected Logs After Fix

**Before (Current - Broken):**
```
🔍 Checking room "Repetitor"...
   App contacts: ✅ Found
   Radio contacts: ❌ Not found
📤 Sending LOGIN
❌ ERROR: Not found
```

**After (Fixed - Option 1: Re-sync):**
```
🔍 Checking room "Repetitor"...
📤 Clearing app contacts
📤 Syncing from radio
📥 Got 5 contacts
   Room "Repetitor": ❌ NOT on radio
⚠️  Room needs to be added to radio first
```

**After (Fixed - Option 2: Manual add):**
```
🔍 Checking room "Repetitor"...
   App contacts: ✅ Found
   Radio contacts: ❌ Not found
📤 Sending CMD_ADD_UPDATE_CONTACT
✅ Contact added to radio
📤 Sending LOGIN
✅ LOGIN_SUCCESS
```

## Next Steps

1. Try Solution 1 (force re-sync) to confirm the issue
2. Implement Solution 3 (CMD_ADD_UPDATE_CONTACT) for permanent fix
3. Test by adding the room contact manually before login

Would you like me to implement `CMD_ADD_UPDATE_CONTACT` for you?
