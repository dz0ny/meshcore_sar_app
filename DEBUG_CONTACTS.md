# Debugging "Not Found" Error When Logging Into Room

## The Problem

You're seeing this error:
```
📤 [TX] Sending command: SEND_LOGIN (0x1A)
📥 [RX] Received: ERROR (0x01)
❌ [Error] Not found
```

This means the companion radio doesn't have a room contact with that public key in its contact table.

## What's Happening

When you send `CMD_SEND_LOGIN` with a public key, the companion radio needs to:
1. Look up that public key in its internal contact table
2. Find the matching room contact
3. Send the login request to that room via the mesh network

**If the contact doesn't exist → ERR_CODE_NOT_FOUND (2)**

## Your Login Command Breakdown

From your hex dump:
```
1a d2 b3 ee 68 00 00 00 00 15 59 89 54 b4 d4 e1 d5 d3 12 a7 4e 44 ed d3 68 95 7c ee f3 3e 86 ec 88 b9 8f ab 62 24 6b ae c5 77 65 74 77 65 74
```

Decoded:
- `1a` = CMD_SEND_LOGIN
- `d2 b3 ee 68` = timestamp (1754059730)
- `00 00 00 00` = sync_since (0 = all messages)
- `15 59 89 54 ... ae c5` = Room public key (32 bytes)
- `77 65 74 77 65 74` = "wetwet" (password)

**You're trying to login to room with public key starting with: `15:59:89:54:b4:d4`**

## How to Fix

### Option 1: Sync Contacts First (RECOMMENDED)

Add this before trying to login:

```dart
// In your UI code, before showing the login dialog:
await connectionProvider.getContacts();
await Future.delayed(Duration(milliseconds: 500));

// Now show the login dialog - the room should exist
```

### Option 2: Check What Rooms You Have

Add debug logging to see what rooms are actually synced:

```dart
// In contacts_tab.dart, add a debug button:
FloatingActionButton(
  onPressed: () {
    final rooms = contactsProvider.rooms;
    print('📋 Available Rooms (${rooms.length}):');
    for (final room in rooms) {
      final pkHex = room.publicKey.sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
      print('  - ${room.advName}');
      print('    Public key prefix: $pkHex...');
      print('    Full public key: ${room.publicKeyHex}');
    }
  },
  child: Icon(Icons.bug_report),
)
```

### Option 3: Wait for Room to Advertise

If the room is actively broadcasting:
1. Wait for `PUSH_CODE_ADVERT` (0x80) from the room
2. If `manual_add_contacts=0`, you'll automatically receive `PUSH_CODE_NEW_ADVERT` (0x8A)
3. The room will be added to your contacts
4. Then you can login

### Option 4: Import Room Contact Manually

If you have the room's "business card" (from CMD_EXPORT_CONTACT):

```dart
await connectionProvider.importContact(cardData);
```

## Add Pre-Login Check

Modify your login dialog to check if the room exists first:

```dart
// In _RoomLoginSheetState._loginToRoom()
Future<void> _loginToRoom() async {
  final password = _passwordController.text.trim().isEmpty
      ? 'hello'
      : _passwordController.text.trim();

  final connectionProvider = context.read<ConnectionProvider>();
  final contactsProvider = context.read<ContactsProvider>();

  // ✅ CHECK: Does the room exist in our contacts?
  final roomExists = contactsProvider.rooms.any(
    (room) => room.publicKeyHex == widget.contact.publicKeyHex
  );

  if (!roomExists) {
    print('⚠️ [RoomLogin] Room not found in contacts, syncing...');

    // Try to sync contacts first
    await connectionProvider.getContacts();
    await Future.delayed(Duration(milliseconds: 500));

    // Check again
    final stillNotFound = !contactsProvider.rooms.any(
      (room) => room.publicKeyHex == widget.contact.publicKeyHex
    );

    if (stillNotFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room "${widget.contact.advName}" not found on device.\n'
                       'Make sure the room is advertising or sync contacts.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
  }

  // Now proceed with login...
  setState(() {
    _isLoggingIn = true;
  });

  // ... rest of your login code
}
```

## Verify Your Device Settings

Check if your device is in manual or automatic mode:

```dart
// In HomeScreen or somewhere visible:
Consumer<ConnectionProvider>(
  builder: (context, connectionProvider, child) {
    final manualMode = connectionProvider.deviceInfo.manualAddContacts;
    return Text(
      'Contact Mode: ${manualMode == true ? "Manual" : "Automatic"}',
      style: TextStyle(fontSize: 10),
    );
  },
)
```

- **Automatic mode (0)**: Rooms will appear automatically when they advertise
- **Manual mode (1)**: You must call `getContacts()` after receiving adverts

## Expected Flow (Automatic Mode)

```
1. Room broadcasts advertisement on mesh
        ↓
2. Companion radio receives advert
        ↓
3. PUSH_CODE_ADVERT (0x80) sent to app
   📥 Advert received from: 15:59:89:54:b4:d4
        ↓
4. PUSH_CODE_NEW_ADVERT (0x8A) sent to app
   📥 New contact: "MyRoom" (type: room)
        ↓
5. contactsProvider.addOrUpdateContact() called
   ✅ Room added to contacts list
        ↓
6. NOW you can login successfully
   📤 SEND_LOGIN to 15:59:89:54:b4:d4
   📥 LOGIN_SUCCESS (0x85)
```

## Quick Test

Run this in your app to see what's in your contacts:

```dart
// Add a button somewhere:
ElevatedButton(
  onPressed: () async {
    final contactsProvider = context.read<ContactsProvider>();
    final connectionProvider = context.read<ConnectionProvider>();

    print('🔍 CONTACT SYNC TEST');
    print('══════════════════════════════════════');

    // Force sync
    await connectionProvider.getContacts();
    await Future.delayed(Duration(milliseconds: 1000));

    final allContacts = contactsProvider.allContacts;
    print('Total contacts: ${allContacts.length}');
    print('');

    final rooms = contactsProvider.rooms;
    print('Rooms (${rooms.length}):');
    for (final room in rooms) {
      final pk = room.publicKey.sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
      print('  📍 ${room.advName}');
      print('     PK: $pk...');
      print('     Type: ${room.type}');
      print('     Last seen: ${room.timeSinceLastSeen}');
      print('');
    }
    print('══════════════════════════════════════');
  },
  child: Text('Debug: List All Rooms'),
)
```

## Common Causes

1. **Room hasn't advertised yet** - Wait for advertisement or import contact
2. **Device in manual mode** - Need to call `getContacts()` manually
3. **Wrong public key** - Verify you're using the correct public key
4. **Room was deleted** - Re-add or re-import the room contact

## Next Steps

1. Add the pre-login check to your login dialog
2. Always call `getContacts()` before attempting login
3. Add debug logging to see what rooms are available
4. Check your device's `manual_add_contacts` setting
