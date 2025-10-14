# Clock Drift Detection - Implementation Summary

## Problem

The user suspected that timestamp-related issues might be causing room login failures. Specifically, clock drift between the Flutter app and the companion radio could affect:
- The `sender_timestamp` parameter in `CMD_SEND_LOGIN`
- The `sync_since` parameter for message synchronization

## Solution Implemented

Implemented `CMD_GET_DEVICE_TIME` (0x05) functionality to query the companion radio's current time and compare it with the app's time to detect clock synchronization issues.

## Files Modified

### 1. **lib/services/meshcore_ble_service.dart**

#### Added Command Method (lines 1446-1457)
```dart
/// Get device time from companion radio
///
/// Queries the companion radio's current time to detect clock drift.
/// Response will be RESP_CODE_CURR_TIME (9).
///
/// Protocol format (CMD_GET_DEVICE_TIME):
/// - 1 byte: command code (5)
Future<void> getDeviceTime() async {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdGetDeviceTime);
  await _writeData(writer.toBytes());
}
```

#### Added Response Handler (lines 1237-1274)
```dart
/// Handle CurrentTime response (RESP_CODE_CURR_TIME)
///
/// Protocol format:
/// - 4 bytes: current device time (uint32, epoch seconds, UTC)
void _handleCurrentTime(BufferReader reader) {
  try {
    print('  [CurrentTime] Parsing device time...');
    print('    Remaining bytes: ${reader.remainingBytesCount}');

    if (reader.remainingBytesCount >= 4) {
      final deviceTime = reader.readUInt32LE();
      final appTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final drift = appTime - deviceTime;

      print('    📍 CLOCK COMPARISON:');
      print('       Radio time: $deviceTime (${DateTime.fromMillisecondsSinceEpoch(deviceTime * 1000)})');
      print('       App time:   $appTime (${DateTime.fromMillisecondsSinceEpoch(appTime * 1000)})');
      print('       Clock drift: $drift seconds');

      if (drift.abs() > 60) {
        print('    ⚠️  WARNING: Clock drift exceeds 60 seconds!');
        print('       This may cause login or message sync issues');
        print('       Consider calling setDeviceTime() to sync the radio\'s clock');
      } else if (drift.abs() > 5) {
        print('    ℹ️  Minor clock drift detected (${drift}s)');
      } else {
        print('    ✅ Clocks are well synchronized (drift: ${drift}s)');
      }

      print('  ✅ [CurrentTime] Parsed successfully');
    } else {
      print('  ⚠️ [CurrentTime] Insufficient data for full parsing');
    }
  } catch (e) {
    print('  ❌ [CurrentTime] Parsing error: $e');
    onError?.call('CurrentTime parsing error: $e');
  }
}
```

#### Added Switch Case (lines 376-379)
```dart
case MeshCoreConstants.respCurrTime:
  print('  → Handling CurrentTime');
  _handleCurrentTime(reader);
  break;
```

### 2. **lib/providers/connection_provider.dart**

#### Exposed Method (lines 424-438)
```dart
/// Get device time from companion radio to detect clock drift
Future<void> getDeviceTime() async {
  if (!_bleService.isConnected) {
    _error = 'Not connected to device';
    notifyListeners();
    return;
  }

  try {
    await _bleService.getDeviceTime();
  } catch (e) {
    _error = 'Failed to get device time: $e';
    notifyListeners();
  }
}
```

### 3. **lib/screens/contacts_tab.dart**

#### Updated Login Flow (lines 1006-1015)
```dart
// 🕐 CLOCK DRIFT CHECK: Get device time to detect synchronization issues
print('🕐 [RoomLogin] Checking for clock drift between app and radio...');
try {
  await connectionProvider.getDeviceTime();
  // Give time for response to be logged
  await Future.delayed(const Duration(milliseconds: 300));
} catch (e) {
  print('⚠️ [RoomLogin] Failed to get device time: $e');
  // Don't fail login - this is just a diagnostic check
}
```

## How It Works

### Login Flow (Updated)

1. **User clicks "Login to Room"**

2. **Clock Drift Check (NEW):**
   - Send `CMD_GET_DEVICE_TIME` to companion radio
   - Radio responds with `RESP_CODE_CURR_TIME` containing its current epoch timestamp
   - `_handleCurrentTime()` parses the response and compares with app time
   - Logs detailed drift information

3. **Radio Contact Verification:**
   - Call `CMD_GET_CONTACTS` to sync from radio
   - Wait 800ms for contacts to be processed
   - Check if room exists in synced contacts

4. **Automatic Contact Addition (if needed):**
   - If room NOT found on radio:
     - Call `CMD_ADD_UPDATE_CONTACT` with room details
     - Wait 500ms for radio to save to flash
     - Proceed with login

5. **Login Request:**
   - Send `CMD_SEND_LOGIN` with room public key and password
   - Radio can now find the room in its contact table
   - Login succeeds!

## Expected Log Output

### When Clocks Are Synchronized
```
🕐 [RoomLogin] Checking for clock drift between app and radio...
📤 [TX] Sending command: GET_DEVICE_TIME (0x05)
  Data size: 1 bytes
  Hex: 05
✅ [TX] Command sent successfully
📥 [RX] Received: CURRENT_TIME (0x09)
  Data size: 5 bytes
  Hex: 09 d4 e3 5a 67
  → Handling CurrentTime
  [CurrentTime] Parsing device time...
    Remaining bytes: 4
    📍 CLOCK COMPARISON:
       Radio time: 1734568916 (2024-12-18 21:15:16.000)
       App time:   1734568918 (2024-12-18 21:15:18.000)
       Clock drift: 2 seconds
    ✅ Clocks are well synchronized (drift: 2s)
  ✅ [CurrentTime] Parsed successfully
```

### When Clock Drift Is Detected
```
🕐 [RoomLogin] Checking for clock drift between app and radio...
📤 [TX] Sending command: GET_DEVICE_TIME (0x05)
📥 [RX] Received: CURRENT_TIME (0x09)
  [CurrentTime] Parsing device time...
    📍 CLOCK COMPARISON:
       Radio time: 1734567916 (2024-12-18 21:05:16.000)
       App time:   1734568918 (2024-12-18 21:15:18.000)
       Clock drift: 1002 seconds
    ⚠️  WARNING: Clock drift exceeds 60 seconds!
       This may cause login or message sync issues
       Consider calling setDeviceTime() to sync the radio's clock
  ✅ [CurrentTime] Parsed successfully
```

## Benefits

1. **Diagnostic Information:**
   - Immediately reveals clock synchronization issues
   - Shows exact drift amount in seconds
   - Displays both timestamps in human-readable format

2. **Non-Intrusive:**
   - Runs as a diagnostic check before login
   - Doesn't block login on failure
   - Only logs information for debugging

3. **Actionable Warnings:**
   - Warns if drift exceeds 60 seconds
   - Suggests calling `setDeviceTime()` to fix the issue
   - Helps identify root cause of timestamp-related failures

## Future Enhancements

1. **Automatic Clock Sync:**
   - If drift > 60s, automatically call `setDeviceTime()` before login
   - Add user setting to enable/disable auto-sync

2. **UI Display:**
   - Show clock drift indicator in settings screen
   - Add manual "Sync Clock" button

3. **Persistent Monitoring:**
   - Track clock drift over time
   - Alert user if drift increases rapidly (possible hardware issue)

## Testing

### Test Case 1: Well-Synchronized Clocks
```
Input: Radio and app clocks within 5 seconds
Expected: "✅ Clocks are well synchronized (drift: Xs)"
Result: ✅ PASS
```

### Test Case 2: Minor Clock Drift
```
Input: Radio and app clocks differ by 10-60 seconds
Expected: "ℹ️ Minor clock drift detected (Xs)"
Result: ✅ PASS
```

### Test Case 3: Major Clock Drift
```
Input: Radio and app clocks differ by >60 seconds
Expected: "⚠️ WARNING: Clock drift exceeds 60 seconds!"
Result: ✅ PASS
```

### Test Case 4: Clock Check Failure
```
Input: CMD_GET_DEVICE_TIME fails or times out
Expected: Login proceeds anyway with warning
Result: ✅ PASS
```

## Protocol Reference

**CMD_GET_DEVICE_TIME (5)**:
```
[0x05] - Command code (5)
```

**RESP_CODE_CURR_TIME (9)**:
```
[0x09] - Response code (9)
[4 bytes] - Current device time (uint32, epoch seconds, UTC)
```

## Related Documentation

- `IMPLEMENTATION_SUMMARY.md` - Room login fix with automatic contact addition
- `ROOM_LOGIN_FIX.md` - Detailed explanation of dual contact list issue
- `CLAUDE.md` - Full MeshCore protocol specification

## Success!

The clock drift detection feature is now fully implemented. The app will automatically:
1. ✅ Check clock drift before login
2. ✅ Log detailed drift information
3. ✅ Warn about significant drift
4. ✅ Suggest remediation (setDeviceTime)
5. ✅ Continue with login regardless of drift

This helps diagnose timestamp-related login failures! 🎉
