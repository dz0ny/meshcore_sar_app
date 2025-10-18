# Auto-Recovery System for ERR_CODE_NOT_FOUND

## Problem Statement

When sending a message to a room contact that exists in the app's contact list but not in the companion radio's contact table, the radio responds with:
```
ERROR (0x01) with error code 2 (ERR_CODE_NOT_FOUND)
```

This happens because:
1. Room contacts may have been deleted from the radio
2. New room contacts added to the app haven't been synced to the radio yet
3. The radio was factory reset but the app still has cached contacts

## Solution: Automatic Contact Recovery

The system now automatically detects and recovers from `ERR_CODE_NOT_FOUND` errors by:

1. **Detecting the error** in `BleResponseHandler` (ble_response_handler.dart:584-587)
2. **Tracking the failing contact** via `setLastContactPublicKey()`
3. **Triggering auto-recovery** via `onContactNotFound` callback
4. **Adding the missing contact** to the radio using `CMD_ADD_UPDATE_CONTACT`
5. **Retrying the send operation** automatically after 300ms delay

## Implementation Flow

```
┌─────────────────────────────────────────────────────────────┐
│ User sends message to room contact                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ ConnectionProvider.sendTextMessage()                        │
│  - Tracks pending operation: _PendingSendOperation          │
│  - Contains: contactPublicKey, text, messageId, contact     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ MeshCoreBleService.sendTextMessage()                        │
│  - Calls: responseHandler.setLastContactPublicKey()         │
│  - Sends: CMD_SEND_TXT_MSG (0x02)                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Radio processes command                                     │
│  ❌ Contact not found in radio's contact table             │
│  → Responds: RESP_CODE_ERR (0x01) with errCode=2          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ BleResponseHandler._handleError()                           │
│  - Detects: errorCode == 2 (ERR_CODE_NOT_FOUND)           │
│  - Triggers: onContactNotFound(lastContactPublicKey)       │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ ConnectionProvider.onContactNotFound callback               │
│  1. Looks up pending operation by public key                │
│  2. Calls: bleService.addOrUpdateContact(contact)           │
│     → Sends: CMD_ADD_UPDATE_CONTACT (0x09)                 │
│  3. Waits 300ms for contact to be added                     │
│  4. Retries: bleService.sendTextMessage()                   │
│     → Sends: CMD_SEND_TXT_MSG (0x02) again                 │
│  5. Clears pending operation on success                     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Radio processes retry                                       │
│  ✅ Contact now exists in radio's contact table            │
│  → Responds: RESP_CODE_SENT (0x06) with ACK tag           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ Message sent successfully                                   │
│  → UI shows "sent" status                                   │
│  → Normal delivery confirmation flow continues              │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. BleResponseHandler (lib/services/ble/ble_response_handler.dart)

**New Callbacks:**
```dart
typedef OnContactNotFoundCallback = void Function(Uint8List? contactPublicKey);
```

**Error Detection:**
```dart
void _handleError(BufferReader reader) {
  final errorCode = FrameParser.parseError(reader);
  if (errorCode == 2) {  // ERR_CODE_NOT_FOUND
    onContactNotFound?.call(_lastContactPublicKey);
  }
  onError?.call(errorMsg, errorCode: errorCode);
}
```

**Tracking:**
```dart
void setLastContactPublicKey(Uint8List? publicKey) {
  _lastContactPublicKey = publicKey;
}
```

### 2. MeshCoreBleService (lib/services/meshcore_ble_service.dart)

**Updated Typedef:**
```dart
typedef OnErrorCallback = void Function(String error, {int? errorCode});
typedef OnContactNotFoundCallback = void Function(Uint8List? contactPublicKey);
```

**Callback Forwarding:**
```dart
_responseHandler.onError = (error, {int? errorCode}) {
  onError?.call(error, errorCode: errorCode);
};
_responseHandler.onContactNotFound = (contactPublicKey) {
  onContactNotFound?.call(contactPublicKey);
};
```

**Contact Tracking:**
```dart
Future<void> sendTextMessage({...}) async {
  // Track the last contact for auto-recovery if contact not found
  _responseHandler.setLastContactPublicKey(contactPublicKey);
  await _commandSender.writeData(...);
}
```

### 3. ConnectionProvider (lib/providers/connection_provider.dart)

**Pending Operation Tracking:**
```dart
class _PendingSendOperation {
  final Uint8List contactPublicKey;
  final String text;
  final String? messageId;
  final Contact? contact;
  final int retryAttempt;
}

final Map<String, _PendingSendOperation> _pendingSendOperations = {};
```

**Auto-Recovery Logic:**
```dart
_bleService.onContactNotFound = (contactPublicKey) async {
  // 1. Look up pending operation
  final pendingOp = _pendingSendOperations[operationId];

  // 2. Add contact to radio
  await _bleService.addOrUpdateContact(pendingOp.contact!);
  await Future.delayed(const Duration(milliseconds: 300));

  // 3. Retry send
  await _bleService.sendTextMessage(
    contactPublicKey: pendingOp.contactPublicKey,
    text: pendingOp.text,
    attempt: pendingOp.retryAttempt,
  );

  // 4. Cleanup
  _pendingSendOperations.remove(operationId);
};
```

**Send Message Tracking:**
```dart
Future<bool> sendTextMessage({...}) async {
  // Track operation before sending
  if (contact != null) {
    _pendingSendOperations[operationId] = _PendingSendOperation(...);
  }

  await _bleService.sendTextMessage(...);

  // Clear after 500ms (if no error occurs)
  Future.delayed(const Duration(milliseconds: 500), () {
    _pendingSendOperations.remove(operationId);
  });
}
```

## Testing Scenarios

### Scenario 1: Room contact deleted from radio
1. User has room "SAR-Command" in app's contact list
2. Room was deleted from companion radio
3. User sends SAR marker to room
4. **Expected:** System automatically adds room and sends message
5. **Verify:** Message appears as "sent" in UI

### Scenario 2: New room added to app
1. User manually adds new room contact to app
2. Room not yet in companion radio's contact table
3. User sends message to new room
4. **Expected:** System automatically adds room and sends message
5. **Verify:** Message appears as "sent" in UI

### Scenario 3: Factory reset radio
1. Radio was factory reset (all contacts cleared)
2. App still has cached contacts
3. User sends message to any room
4. **Expected:** System automatically re-adds contact and sends message
5. **Verify:** Message appears as "sent" in UI

## Console Output Example

**Before (failed send):**
```
📤 [TX] Sending command: SEND_TXT_MSG (0x02)
  Data size: 46 bytes
📥 [RX] Received: ERROR (0x01)
  ❌ [Error] Not found
⚠️ [Provider] BLE error received: Not found
```

**After (auto-recovery):**
```
📤 [TX] Sending command: SEND_TXT_MSG (0x02)
  Data size: 46 bytes
  📝 Tracked pending operation for auto-recovery: 8f:a0:f2:68:d0:c1
📥 [RX] Received: ERROR (0x01)
  ❌ [Error] Not found
  ⚠️ [Error] Contact not found in radio - attempting auto-recovery
🔧 [Provider] Contact not found error detected - initiating auto-recovery
  📋 Found pending operation for: SAR-Command
  📤 Step 1: Adding contact to radio...
📝 [BLE] Adding/updating contact on companion radio:
    Name: SAR-Command
    Public key prefix: 8f:a0:f2:68:d0:c1
    Type: room (3)
📤 [TX] Sending command: ADD_UPDATE_CONTACT (0x09)
📥 [RX] Received: OK (0x00)
  ✅ Contact added successfully
  🔄 Step 2: Retrying message send...
📤 [TX] Sending command: SEND_TXT_MSG (0x02)
📥 [RX] Received: SENT (0x06)
  ✅ Auto-recovery completed - message resent
```

## Error Handling

### If contact is null
```
⚠️ No pending operation found for recovery: 8f:a0:f2:68:d0:c1
```
This happens if the send was called without a Contact object. Cannot auto-recover.

### If add contact fails
```
❌ Auto-recovery failed: BLE write error
```
Error is logged and operation is cleared. User must manually retry.

### If retry send fails
Same as above - error logged, operation cleared.

## Benefits

1. **Zero user intervention** - automatic recovery
2. **Transparent operation** - user sees "sent" status as expected
3. **Robust handling** - works for all ERR_CODE_NOT_FOUND scenarios
4. **Minimal latency** - 300ms delay is imperceptible to user
5. **Clean architecture** - isolated to ConnectionProvider layer

## Future Enhancements

1. **Batch recovery** - if multiple contacts missing, add all at once
2. **Proactive sync** - periodically sync app contacts to radio
3. **Smart caching** - track which contacts have been successfully added
4. **UI feedback** - optional: show "Adding contact..." toast during recovery
5. **Telemetry** - track auto-recovery success rate for monitoring

## Related Files

- `lib/services/ble/ble_response_handler.dart` - Error detection
- `lib/services/meshcore_ble_service.dart` - Service layer coordination
- `lib/providers/connection_provider.dart` - Auto-recovery orchestration
- `lib/services/protocol/frame_parser.dart` - Error code parsing
- `lib/services/meshcore_constants.dart` - Error code constants

## MeshCore Protocol Reference

**Error Codes (ERR_CODE):**
- 1: ERR_CODE_UNSUPPORTED_CMD
- **2: ERR_CODE_NOT_FOUND** ← This is what we handle
- 3: ERR_CODE_TABLE_FULL
- 4: ERR_CODE_BAD_STATE
- 5: ERR_CODE_FILE_IO_ERROR
- 6: ERR_CODE_ILLEGAL_ARG

**Recovery Commands:**
- CMD_ADD_UPDATE_CONTACT (9): Adds contact to radio's contact table
- CMD_SEND_TXT_MSG (2): Sends message to contact (retried after add)

## Conclusion

The auto-recovery system provides a seamless user experience by automatically handling missing contacts in the radio's contact table. Users can now send messages to room contacts without worrying about synchronization issues, and the system will intelligently recover from `ERR_CODE_NOT_FOUND` errors.
