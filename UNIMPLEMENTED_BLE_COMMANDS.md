# Unimplemented BLE Commands - MeshCore SAR

This document catalogs all BLE commands from the MeshCore protocol that are **not yet implemented** in the Flutter application. Implementations are based on analysis of the C++ reference implementation at `/Users/dz0ny/meshcore-sar/MeshCore/examples/companion_radio/MyMesh.cpp`.

**Total Commands**: 52 defined in protocol
**Implemented in Flutter**: 30
**Not Implemented**: 22 (documented below)

---

## Table of Contents

1. [Commands Not Defined in Flutter](#commands-not-defined-in-flutter) (11 commands)
2. [Commands Defined But Not Implemented](#commands-defined-but-not-implemented) (11 commands)
3. [Implementation Priority Matrix](#implementation-priority-matrix)
4. [Quick Reference Table](#quick-reference-table)

---

## Commands Not Defined in Flutter

These commands don't exist in `lib/services/meshcore_constants.dart` at all.

### 1. CMD_SHARE_CONTACT (16)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Share contact info with nearby mesh nodes

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (16)
- Offset 1-32: Public key (32 bytes) of contact to share

**C++ Implementation** (`MyMesh.cpp:1059-1070`):
```cpp
else if (cmd_frame[0] == CMD_SHARE_CONTACT) {
  uint8_t *pub_key = &cmd_frame[1];
  ContactInfo *recipient = lookupContactByPubKey(pub_key, PUB_KEY_SIZE);
  if (recipient) {
    if (shareContactZeroHop(*recipient)) {
      writeOKFrame();
    } else {
      writeErrFrame(ERR_CODE_TABLE_FULL);
    }
  } else {
    writeErrFrame(ERR_CODE_NOT_FOUND);
  }
}
```

**What It Does**: Broadcasts a zero-hop advertisement of a contact in the local network. Used to share another contact's information with nearby mesh nodes.

**Error Codes**:
- `ERR_CODE_TABLE_FULL` (3): Packet pool exhausted
- `ERR_CODE_NOT_FOUND` (2): Contact not found

**Implementation Notes**:
- Validates contact exists by public key
- Sends contact advertisement with zero hops (direct only)
- No parameters beyond public key required
- Min frame length: 33 bytes

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdShareContact = 16;

// Frame Builder
static Uint8List buildShareContact(Uint8List contactPublicKey) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdShareContact);
  writer.writeBytes(contactPublicKey); // 32 bytes
  return writer.toBytes();
}

// Service API
Future<void> shareContact(Uint8List contactPublicKey) async {
  final frame = FrameBuilder.buildShareContact(contactPublicKey);
  await _commandSender.sendCommand(frame);
}
```

---

### 2. CMD_HAS_CONNECTION (28)

**Status**: Not defined
**Priority**: High
**Use Case**: Check if radio has a path to a contact before sending

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (28)
- Offset 1-32: Public key (32 bytes) to check connection

**C++ Implementation** (`MyMesh.cpp:1383-1389`):
```cpp
else if (cmd_frame[0] == CMD_HAS_CONNECTION && len >= 1 + PUB_KEY_SIZE) {
  uint8_t *pub_key = &cmd_frame[1];
  if (hasConnectionTo(pub_key)) {
    writeOKFrame();
  } else {
    writeErrFrame(ERR_CODE_NOT_FOUND);
  }
}
```

**What It Does**: Checks if the radio has a known path to a specific contact. Useful for app to determine reachability before sending messages.

**Error Codes**:
- `ERR_CODE_NOT_FOUND` (2): No connection path known

**Implementation Notes**:
- Validates minimum frame length: 33 bytes
- Returns OK if connection exists
- Does NOT verify contact is in local contact list
- Min frame length: 33 bytes

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdHasConnection = 28;

// Frame Builder
static Uint8List buildHasConnection(Uint8List contactPublicKey) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdHasConnection);
  writer.writeBytes(contactPublicKey); // 32 bytes
  return writer.toBytes();
}

// Service API
Future<bool> hasConnectionTo(Uint8List contactPublicKey) async {
  final frame = FrameBuilder.buildHasConnection(contactPublicKey);
  try {
    await _commandSender.sendCommand(frame);
    return true; // RESP_CODE_OK received
  } catch (e) {
    return false; // ERR_CODE_NOT_FOUND or timeout
  }
}
```

---

### 3. CMD_LOGOUT (29)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Disconnect from room servers

**Response**: `RESP_CODE_OK` (0)

**Parameters**:
- Offset 0: Command code (29)
- Offset 1-32: Public key (32 bytes) of room/server to disconnect from

**C++ Implementation** (`MyMesh.cpp:1390-1393`):
```cpp
else if (cmd_frame[0] == CMD_LOGOUT && len >= 1 + PUB_KEY_SIZE) {
  uint8_t *pub_key = &cmd_frame[1];
  stopConnection(pub_key);
  writeOKFrame();
}
```

**What It Does**: Disconnects/logs out from a room server or chat service. Stops receiving automatic message pushes from the service.

**Implementation Notes**:
- Also known as "Disconnect" per comment in header
- Always returns OK (success guaranteed)
- Calls internal `stopConnection()` to halt login/message polling
- Min frame length: 33 bytes
- Used with room-type contacts (ADV_TYPE_ROOM)

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdLogout = 29;

// Frame Builder
static Uint8List buildLogout(Uint8List roomPublicKey) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdLogout);
  writer.writeBytes(roomPublicKey); // 32 bytes
  return writer.toBytes();
}

// Service API
Future<void> logoutFromRoom(Uint8List roomPublicKey) async {
  final frame = FrameBuilder.buildLogout(roomPublicKey);
  await _commandSender.sendCommand(frame);
}
```

---

### 4. CMD_GET_CONTACT_BY_KEY (30)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Retrieve full contact details by public key

**Response**: `RESP_CODE_CONTACT` (3) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (30)
- Offset 1-32: Public key (32 bytes) to look up

**C++ Implementation** (`MyMesh.cpp:1071-1078`):
```cpp
else if (cmd_frame[0] == CMD_GET_CONTACT_BY_KEY) {
  uint8_t *pub_key = &cmd_frame[1];
  ContactInfo *contact = lookupContactByPubKey(pub_key, PUB_KEY_SIZE);
  if (contact) {
    writeContactRespFrame(RESP_CODE_CONTACT, *contact);
  } else {
    writeErrFrame(ERR_CODE_NOT_FOUND);
  }
}
```

**What It Does**: Retrieves full contact information by public key. Returns all stored contact details including GPS location, path, name, etc.

**Response Format** (`RESP_CODE_CONTACT` - 3):
- Byte 0: `RESP_CODE_CONTACT` (3)
- Bytes 1-32: Public key (32 bytes)
- Byte 33: Contact type (ADV_TYPE_*)
- Byte 34: Flags
- Byte 35: Out path length
- Bytes 36-77: Out path (MAX_PATH_SIZE = 64)
- Bytes 78-109: Contact name (32 bytes, null-padded)
- Bytes 110-113: Last advertisement timestamp (uint32_t LE)
- Bytes 114-117: GPS latitude (int32_t LE, 1E-6 scale)
- Bytes 118-121: GPS longitude (int32_t LE, 1E-6 scale)

**Error Codes**:
- `ERR_CODE_NOT_FOUND` (2): Contact not found

**Implementation Notes**:
- Simple lookup-only operation, no side effects
- Returns complete contact information
- Min frame length: 33 bytes
- Useful when you have a public key but need full contact details

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdGetContactByKey = 30;

// Frame Builder
static Uint8List buildGetContactByKey(Uint8List contactPublicKey) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdGetContactByKey);
  writer.writeBytes(contactPublicKey); // 32 bytes
  return writer.toBytes();
}

// Service API (use existing parseContact from FrameParser)
Future<Contact?> getContactByKey(Uint8List contactPublicKey) async {
  final frame = FrameBuilder.buildGetContactByKey(contactPublicKey);
  final completer = Completer<Contact?>();

  // Wait for RESP_CODE_CONTACT (3)
  _responseHandler.onContactReceived = (contact) {
    completer.complete(contact);
  };

  await _commandSender.sendCommand(frame);
  return completer.future.timeout(Duration(seconds: 5));
}
```

---

### 5. CMD_SET_DEVICE_PIN (37)

**Status**: Not defined
**Priority**: Low
**Use Case**: Secure BLE pairing with PIN

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (37)
- Offset 1-4: BLE PIN (uint32_t LE) - either 0 (disable) or 100000-999999 (6-digit PIN)

**C++ Implementation** (`MyMesh.cpp:1475-1488`):
```cpp
else if (cmd_frame[0] == CMD_SET_DEVICE_PIN && len >= 5) {
  uint32_t pin;
  memcpy(&pin, &cmd_frame[1], 4);
  if (pin == 0 || (pin >= 100000 && pin <= 999999)) {
    _prefs.ble_pin = pin;
    savePrefs();
    writeOKFrame();
  } else {
    writeErrFrame(ERR_CODE_ILLEGAL_ARG);
  }
}
```

**What It Does**: Sets or disables the BLE pairing PIN code for the radio device. Used to require a PIN for BLE connections.

**Error Codes**:
- `ERR_CODE_ILLEGAL_ARG` (6): Invalid PIN (not 0 or 100000-999999)

**Implementation Notes**:
- Min frame length: 5 bytes
- Validates PIN: must be 0 (disabled) or 6-digit number (100000-999999)
- Persisted to device preferences/EEPROM
- Requires `savePrefs()` to persist to storage

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdSetDevicePin = 37;

// Frame Builder
static Uint8List buildSetDevicePin(int pin) {
  if (pin != 0 && (pin < 100000 || pin > 999999)) {
    throw ArgumentError('PIN must be 0 (disabled) or 6-digit (100000-999999)');
  }
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSetDevicePin);
  writer.writeUInt32LE(pin);
  return writer.toBytes();
}

// Service API
Future<void> setDevicePin(int pin) async {
  final frame = FrameBuilder.buildSetDevicePin(pin);
  await _commandSender.sendCommand(frame);
}
```

---

### 6. CMD_GET_CUSTOM_VARS (40)

**Status**: Not defined
**Priority**: Low
**Use Case**: Read device-specific sensor settings

**Response**: `RESP_CODE_CUSTOM_VARS` (21)

**Parameters**:
- Offset 0: Command code (40)
- No additional parameters

**C++ Implementation** (`MyMesh.cpp:1489-1502`):
```cpp
else if (cmd_frame[0] == CMD_GET_CUSTOM_VARS) {
  out_frame[0] = RESP_CODE_CUSTOM_VARS;
  char *dp = (char *)&out_frame[1];
  for (int i = 0; i < sensors.getNumSettings() && dp - (char *)&out_frame[1] < 140; i++) {
    if (i > 0) {
      *dp++ = ',';
    }
    strcpy(dp, sensors.getSettingName(i));
    dp = strchr(dp, 0);
    *dp++ = ':';
    strcpy(dp, sensors.getSettingValue(i));
    dp = strchr(dp, 0);
  }
  _serial->writeFrame(out_frame, dp - (char *)out_frame);
}
```

**What It Does**: Returns all custom sensor/device configuration variables and their current values. Used to expose device-specific settings.

**Response Format**:
- Byte 0: `RESP_CODE_CUSTOM_VARS` (21)
- Bytes 1+: Comma-separated key:value pairs (variable length, max ~140 chars)
  - Format: `name1:value1,name2:value2,name3:value3`
  - Each pair separated by comma
  - Key and value separated by colon
  - Max buffer: 141 bytes total

**Implementation Notes**:
- Calls `sensors.getNumSettings()` to enumerate available settings
- Stops building if buffer reaches 140 bytes
- No input validation needed (no parameters)
- Response is variable length

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdGetCustomVars = 40;
static const int respCustomVars = 21;

// Frame Builder
static Uint8List buildGetCustomVars() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdGetCustomVars);
  return writer.toBytes();
}

// Frame Parser
static Map<String, String> parseCustomVars(BufferReader reader) {
  final csvData = reader.readRemainingBytes();
  final csvString = utf8.decode(csvData);
  final vars = <String, String>{};

  for (final pair in csvString.split(',')) {
    final parts = pair.split(':');
    if (parts.length == 2) {
      vars[parts[0]] = parts[1];
    }
  }
  return vars;
}

// Service API
Future<Map<String, String>> getCustomVars() async {
  final frame = FrameBuilder.buildGetCustomVars();
  // TODO: Implement response handler for RESP_CODE_CUSTOM_VARS
  await _commandSender.sendCommand(frame);
}
```

---

### 7. CMD_SET_CUSTOM_VAR (41)

**Status**: Not defined
**Priority**: Low
**Use Case**: Configure device-specific sensor settings

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (41)
- Offset 1+: Setting as "name:value" string (null-terminated)

**C++ Implementation** (`MyMesh.cpp:1503-1517`):
```cpp
else if (cmd_frame[0] == CMD_SET_CUSTOM_VAR && len >= 4) {
  cmd_frame[len] = 0;  // null terminate
  char *sp = (char *)&cmd_frame[1];
  char *np = strchr(sp, ':');
  if (np) {
    *np++ = 0;
    bool success = sensors.setSettingValue(sp, np);
    if (success) {
      writeOKFrame();
    } else {
      writeErrFrame(ERR_CODE_ILLEGAL_ARG);
    }
  } else {
    writeErrFrame(ERR_CODE_ILLEGAL_ARG);
  }
}
```

**What It Does**: Sets a custom sensor/device configuration variable to a new value. Modifies device-specific settings.

**Error Codes**:
- `ERR_CODE_ILLEGAL_ARG` (6): No ':' separator found or `setSettingValue()` failed

**Implementation Notes**:
- Min frame length: 4 bytes
- Format: "name:value" (colon-separated)
- Parses by looking for ':' separator character
- No persistence guarantee - depends on `sensors` implementation

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdSetCustomVar = 41;

// Frame Builder
static Uint8List buildSetCustomVar(String name, String value) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSetCustomVar);
  writer.writeString('$name:$value');
  return writer.toBytes();
}

// Service API
Future<void> setCustomVar(String name, String value) async {
  final frame = FrameBuilder.buildSetCustomVar(name, value);
  await _commandSender.sendCommand(frame);
}
```

---

### 8. CMD_GET_ADVERT_PATH (42)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Network topology analysis and debugging

**Response**: `RESP_CODE_ADVERT_PATH` (22) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (42)
- Offset 1: Reserved (for future use)
- Offset 2-8: Public key prefix (7 bytes) of advertised node

**C++ Implementation** (`MyMesh.cpp:1518-1537`):
```cpp
else if (cmd_frame[0] == CMD_GET_ADVERT_PATH && len >= PUB_KEY_SIZE+2) {
  uint8_t *pub_key = &cmd_frame[2];
  AdvertPath* found = NULL;
  for (int i = 0; i < ADVERT_PATH_TABLE_SIZE; i++) {
    auto p = &advert_paths[i];
    if (memcmp(p->pubkey_prefix, pub_key, sizeof(p->pubkey_prefix)) == 0) {
      found = p;
      break;
    }
  }
  if (found) {
    out_frame[0] = RESP_CODE_ADVERT_PATH;
    memcpy(&out_frame[1], &found->recv_timestamp, 4);
    out_frame[5] = found->path_len;
    memcpy(&out_frame[6], found->path, found->path_len);
    _serial->writeFrame(out_frame, 6 + found->path_len);
  } else {
    writeErrFrame(ERR_CODE_NOT_FOUND);
  }
}
```

**What It Does**: Returns the wireless path from which a node's advertisement was last received. Used to analyze network topology and signal paths.

**Response Format**:
- Byte 0: `RESP_CODE_ADVERT_PATH` (22)
- Bytes 1-4: Reception timestamp (uint32_t LE)
- Byte 5: Path length (number of hops)
- Bytes 6+: Path data (variable length, max MAX_PATH_SIZE)

**Error Codes**:
- `ERR_CODE_NOT_FOUND` (2): Node not in recent advertisements

**Implementation Notes**:
- Min frame length: 35 bytes (32 for pubkey + 2 for cmd + reserved)
- Searches circular table of size ADVERT_PATH_TABLE_SIZE (16 entries)
- Matches only first 7 bytes of public key (pubkey_prefix)
- Timestamp is when advertisement was received
- Table is circular and overwrites oldest entries

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdGetAdvertPath = 42;
static const int respAdvertPath = 22;

// Frame Builder
static Uint8List buildGetAdvertPath(Uint8List publicKeyPrefix) {
  if (publicKeyPrefix.length < 7) {
    throw ArgumentError('Public key prefix must be at least 7 bytes');
  }
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdGetAdvertPath);
  writer.writeByte(0); // Reserved
  writer.writeBytes(publicKeyPrefix.sublist(0, 7));
  return writer.toBytes();
}

// Frame Parser
static Map<String, dynamic> parseAdvertPath(BufferReader reader) {
  final timestamp = reader.readUInt32LE();
  final pathLen = reader.readByte();
  final path = reader.readBytes(pathLen);
  return {
    'timestamp': timestamp,
    'pathLen': pathLen,
    'path': path,
  };
}
```

---

### 9. CMD_GET_TUNING_PARAMS (43)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Read mesh network timing configuration

**Response**: `RESP_CODE_TUNING_PARAMS` (23)

**Parameters**:
- Offset 0: Command code (43)
- No additional parameters

**C++ Implementation** (`MyMesh.cpp:1175-1181`):
```cpp
else if (cmd_frame[0] == CMD_GET_TUNING_PARAMS) {
  uint32_t rx = _prefs.rx_delay_base * 1000, af = _prefs.airtime_factor * 1000;
  int i = 0;
  out_frame[i++] = RESP_CODE_TUNING_PARAMS;
  memcpy(&out_frame[i], &rx, 4); i += 4;
  memcpy(&out_frame[i], &af, 4); i += 4;
  _serial->writeFrame(out_frame, i);
}
```

**What It Does**: Returns mesh network tuning parameters - base RX delay and airtime factor. These control message retransmission timing.

**Response Format**:
- Byte 0: `RESP_CODE_TUNING_PARAMS` (23)
- Bytes 1-4: RX delay base (uint32_t LE, in milliseconds)
- Bytes 5-8: Airtime factor (uint32_t LE, scaled by 1000)

**Implementation Notes**:
- No input parameters
- Converts internal floats (milliseconds/factor) to uint32_t by multiplying by 1000
- Values allow app to understand current mesh timing constraints
- Related to `CMD_SET_TUNING_PARAMS` for configuration
- Pair command with code 21

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdGetTuningParams = 43;
static const int respTuningParams = 23;

// Frame Builder
static Uint8List buildGetTuningParams() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdGetTuningParams);
  return writer.toBytes();
}

// Frame Parser
static Map<String, dynamic> parseTuningParams(BufferReader reader) {
  final rxDelayMs = reader.readUInt32LE();
  final airtimeFactor = reader.readUInt32LE();
  return {
    'rxDelayBase': rxDelayMs / 1000.0, // Convert back to seconds
    'airtimeFactor': airtimeFactor / 1000.0,
  };
}
```

---

### 10. CMD_FACTORY_RESET (51)

**Status**: Not defined
**Priority**: Low (destructive)
**Use Case**: Complete device reset

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1), then device reboots

**Parameters**:
- Offset 0: Command code (51)
- Offset 1-5: Magic string "reset" (required for safety)

**C++ Implementation** (`MyMesh.cpp:1538-1546`):
```cpp
else if (cmd_frame[0] == CMD_FACTORY_RESET && memcmp(&cmd_frame[1], "reset", 5) == 0) {
  bool success = _store->formatFileSystem();
  if (success) {
    writeOKFrame();
    delay(1000);
    board.reboot();  // doesn't return
  } else {
    writeErrFrame(ERR_CODE_FILE_IO_ERROR);
  }
}
```

**What It Does**: Performs complete factory reset - erases all file system data (contacts, messages, settings) and reboots device. **DESTRUCTIVE** operation.

**Error Codes**:
- `ERR_CODE_FILE_IO_ERROR` (5): Erase failed

**Implementation Notes**:
- Safety check: requires magic string "reset" at offset 1-5
- Min frame length: 6 bytes
- Erases entire file system via `_store->formatFileSystem()`
- Does not preserve identity/private key - full reset
- Device reboots after 1-second delay (doesn't return from function)
- **CRITICAL**: No recovery possible after execution

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdFactoryReset = 51;

// Frame Builder
static Uint8List buildFactoryReset() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdFactoryReset);
  writer.writeString('reset'); // Magic string
  return writer.toBytes();
}

// Service API with confirmation dialog
Future<void> factoryReset() async {
  // IMPORTANT: Show user confirmation dialog first!
  final confirmed = await showConfirmationDialog(
    title: 'Factory Reset',
    message: 'This will erase ALL data and reboot the device. Continue?',
    destructive: true,
  );

  if (!confirmed) return;

  final frame = FrameBuilder.buildFactoryReset();
  await _commandSender.sendCommand(frame);
  // Device will reboot, connection will be lost
}
```

---

### 11. CMD_SEND_PATH_DISCOVERY_REQ (52)

**Status**: Not defined
**Priority**: Medium
**Use Case**: Network topology discovery

**Response**: `RESP_CODE_SENT` (6)

**Parameters**:
- Offset 0: Command code (52)
- Offset 1: Flags byte (currently only 0 is supported)
- Offset 2-33: Public key (32 bytes) of target node

**C++ Implementation** (`MyMesh.cpp:1298-1326`):
```cpp
else if (cmd_frame[0] == CMD_SEND_PATH_DISCOVERY_REQ && cmd_frame[1] == 0 && len >= 2 + PUB_KEY_SIZE) {
  uint8_t *pub_key = &cmd_frame[2];
  ContactInfo *recipient = lookupContactByPubKey(pub_key, PUB_KEY_SIZE);
  if (recipient) {
    uint32_t tag, est_timeout;
    uint8_t req_data[9];
    req_data[0] = REQ_TYPE_GET_TELEMETRY_DATA;
    req_data[1] = ~(TELEM_PERM_BASE);
    memset(&req_data[2], 0, 3);
    getRNG()->random(&req_data[5], 4);
    auto save = recipient->out_path_len;
    recipient->out_path_len = -1;  // force flood
    int result = sendRequest(*recipient, req_data, sizeof(req_data), tag, est_timeout);
    recipient->out_path_len = save;
    if (result == MSG_SEND_FAILED) {
      writeErrFrame(ERR_CODE_TABLE_FULL);
    } else {
      clearPendingReqs();
      pending_discovery = tag;
      out_frame[0] = RESP_CODE_SENT;
      out_frame[1] = (result == MSG_SEND_SENT_FLOOD) ? 1 : 0;
      memcpy(&out_frame[2], &tag, 4);
      memcpy(&out_frame[6], &est_timeout, 4);
      _serial->writeFrame(out_frame, 10);
    }
  } else {
    writeErrFrame(ERR_CODE_NOT_FOUND);
  }
}
```

**What It Does**: Sends a special telemetry request to discover paths to a target node. Forces flood routing to explore network topology and find all available paths.

**Response Format** (`RESP_CODE_SENT` - 6):
- Byte 0: `RESP_CODE_SENT` (6)
- Byte 1: Flood flag (1 = flooded, 0 = direct)
- Bytes 2-5: Request tag (uint32_t LE) - used to match responses
- Bytes 6-9: Estimated timeout (uint32_t LE, milliseconds)

**Error Codes**:
- `ERR_CODE_NOT_FOUND` (2): Contact not found
- `ERR_CODE_TABLE_FULL` (3): Packet pool exhausted

**Implementation Notes**:
- Min frame length: 35 bytes
- Flags byte must be 0 (only current valid value)
- Temporarily forces contact's path to -1 (flood mode)
- Includes telemetry request type with inverted BASE permission mask
- Adds 4 random bytes to make packet unique
- Clears any pending requests before sending
- Stores tag in `pending_discovery` for response matching

**Flutter Implementation Guide**:
```dart
// Constants
static const int cmdSendPathDiscoveryReq = 52;

// Frame Builder
static Uint8List buildSendPathDiscoveryReq(Uint8List contactPublicKey) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendPathDiscoveryReq);
  writer.writeByte(0); // Flags (must be 0)
  writer.writeBytes(contactPublicKey); // 32 bytes
  return writer.toBytes();
}

// Service API (reuses existing parseSentConfirmation)
Future<Map<String, dynamic>> discoverPathsTo(Uint8List contactPublicKey) async {
  final frame = FrameBuilder.buildSendPathDiscoveryReq(contactPublicKey);
  // Wait for RESP_CODE_SENT with tag
  await _commandSender.sendCommand(frame);
  // Returns: {expectedAckTag, suggestedTimeout, isFloodMode}
}
```

---

## Commands Defined But Not Implemented

These commands are defined in `lib/services/meshcore_constants.dart` but have no FrameBuilder method or service API.

### 12. CMD_EXPORT_CONTACT (17)

**Status**: Defined (`meshcore_constants.dart:31`)
**Priority**: Medium
**Use Case**: Backup/share contacts in portable format

**Response**: `RESP_CODE_EXPORT_CONTACT` (11) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (17)
- Offset 1-32: Public key (32 bytes) - optional; if missing, exports SELF

**C++ Implementation** (`MyMesh.cpp:1079-1108`):
```cpp
else if (cmd_frame[0] == CMD_EXPORT_CONTACT) {
  if (len < 1 + PUB_KEY_SIZE) {
    // export SELF
    mesh::Packet* pkt;
    if (_prefs.advert_loc_policy == ADVERT_LOC_NONE) {
      pkt = createSelfAdvert(_prefs.node_name);
    } else {
      pkt = createSelfAdvert(_prefs.node_name, sensors.node_lat, sensors.node_lon);
    }
    if (pkt) {
      pkt->header |= ROUTE_TYPE_FLOOD;
      out_frame[0] = RESP_CODE_EXPORT_CONTACT;
      uint8_t out_len = pkt->writeTo(&out_frame[1]);
      releasePacket(pkt);
      _serial->writeFrame(out_frame, out_len + 1);
    } else {
      writeErrFrame(ERR_CODE_TABLE_FULL);
    }
  } else {
    uint8_t *pub_key = &cmd_frame[1];
    ContactInfo *recipient = lookupContactByPubKey(pub_key, PUB_KEY_SIZE);
    uint8_t out_len;
    if (recipient && (out_len = exportContact(*recipient, &out_frame[1])) > 0) {
      out_frame[0] = RESP_CODE_EXPORT_CONTACT;
      _serial->writeFrame(out_frame, out_len + 1);
    } else {
      writeErrFrame(ERR_CODE_NOT_FOUND);
    }
  }
}
```

**What It Does**: Exports a contact (or self) in mesh packet format. Used to share contact information in a portable, encrypted format.

**Response Format**:
- Byte 0: `RESP_CODE_EXPORT_CONTACT` (11)
- Bytes 1+: Serialized mesh packet (variable length)

**Error Codes**:
- `ERR_CODE_TABLE_FULL` (3): Packet pool exhausted (self export)
- `ERR_CODE_NOT_FOUND` (2): Contact not found

**Implementation Notes**:
- Two modes: with/without pubkey parameter
- If no pubkey (len < 33): exports self advertisement
  - Respects `advert_loc_policy` (include GPS or not)
  - Sets ROUTE_TYPE_FLOOD flag in packet header
- If pubkey provided: exports stored contact via `exportContact()`
- Variable response length based on packet data
- Packet is serialized and ready to transmit

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdExportContact = 17;
static const int respExportContact = 11;

// Frame Builder
static Uint8List buildExportContact({Uint8List? contactPublicKey}) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdExportContact);
  if (contactPublicKey != null) {
    writer.writeBytes(contactPublicKey); // 32 bytes
  }
  // If no pubkey, exports SELF
  return writer.toBytes();
}

// Frame Parser
static Uint8List parseExportContact(BufferReader reader) {
  // Returns serialized packet data
  return reader.readRemainingBytes();
}

// Service API
Future<Uint8List> exportContact({Uint8List? contactPublicKey}) async {
  final frame = FrameBuilder.buildExportContact(contactPublicKey: contactPublicKey);
  // TODO: Wait for RESP_CODE_EXPORT_CONTACT and return packet data
  await _commandSender.sendCommand(frame);
}
```

---

### 13. CMD_IMPORT_CONTACT (18)

**Status**: Defined (`meshcore_constants.dart:32`)
**Priority**: Medium
**Use Case**: Restore/import contacts from portable format

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (18)
- Offset 1+: Serialized contact packet (min 97 bytes: 1 cmd + 32 pubkey + 64 signature)

**C++ Implementation** (`MyMesh.cpp:1109-1114`):
```cpp
else if (cmd_frame[0] == CMD_IMPORT_CONTACT && len > 2 + 32 + 64) {
  if (importContact(&cmd_frame[1], len - 1)) {
    writeOKFrame();
  } else {
    writeErrFrame(ERR_CODE_ILLEGAL_ARG);
  }
}
```

**What It Does**: Imports a contact from a serialized mesh packet. Parses and validates contact data, then adds to local contact list.

**Error Codes**:
- `ERR_CODE_ILLEGAL_ARG` (6): Packet is invalid/malformed

**Implementation Notes**:
- Min frame length: 98 bytes (1 cmd + 97 packet minimum)
- Validates packet format (32-byte pubkey, 64-byte signature minimum)
- Calls internal `importContact()` to parse and store
- Contact is added to local storage if successful
- Opposite of `CMD_EXPORT_CONTACT`

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdImportContact = 18;

// Frame Builder
static Uint8List buildImportContact(Uint8List packetData) {
  if (packetData.length < 96) { // 32 pubkey + 64 signature minimum
    throw ArgumentError('Contact packet too small (min 96 bytes)');
  }
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdImportContact);
  writer.writeBytes(packetData);
  return writer.toBytes();
}

// Service API
Future<void> importContact(Uint8List packetData) async {
  final frame = FrameBuilder.buildImportContact(packetData);
  await _commandSender.sendCommand(frame);
}
```

---

### 14. CMD_REBOOT (19)

**Status**: Defined (`meshcore_constants.dart:33`)
**Priority**: Low
**Use Case**: Restart radio device

**Response**: None (device reboots)

**Parameters**:
- Offset 0: Command code (19)
- Offset 1-6: Magic string "reboot" (required for safety)

**C++ Implementation** (`MyMesh.cpp:1198-1202`):
```cpp
else if (cmd_frame[0] == CMD_REBOOT && memcmp(&cmd_frame[1], "reboot", 6) == 0) {
  if (dirty_contacts_expiry) {
    saveContacts();
  }
  board.reboot();
}
```

**What It Does**: Reboots the radio device. Gracefully saves any pending contact changes before restart.

**Implementation Notes**:
- Safety check: requires magic string "reboot" at offset 1-6
- Min frame length: 7 bytes
- Checks for pending contact writes (dirty_contacts_expiry)
- Saves contacts if needed before rebooting
- Calls `board.reboot()` which doesn't return
- Device goes offline immediately (no response sent)

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdReboot = 19;

// Frame Builder
static Uint8List buildReboot() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdReboot);
  writer.writeString('reboot'); // Magic string
  return writer.toBytes();
}

// Service API
Future<void> rebootDevice() async {
  final frame = FrameBuilder.buildReboot();
  await _commandSender.sendCommand(frame);
  // Device will reboot, connection will be lost
  // App should handle disconnection gracefully
}
```

---

### 15. CMD_SET_TUNING_PARAMS (21)

**Status**: Defined (`meshcore_constants.dart:35`)
**Priority**: Medium
**Use Case**: Configure mesh network timing

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (21)
- Offset 1-4: RX delay base (uint32_t LE, milliseconds, scaled by 1000)
- Offset 5-8: Airtime factor (uint32_t LE, scaled by 1000)

**C++ Implementation** (`MyMesh.cpp:1164-1174`):
```cpp
else if (cmd_frame[0] == CMD_SET_TUNING_PARAMS) {
  int i = 1;
  uint32_t rx, af;
  memcpy(&rx, &cmd_frame[i], 4); i += 4;
  memcpy(&af, &cmd_frame[i], 4); i += 4;
  _prefs.rx_delay_base = ((float)rx) / 1000.0f;
  _prefs.airtime_factor = ((float)af) / 1000.0f;
  savePrefs();
  writeOKFrame();
}
```

**What It Does**: Configures mesh network tuning parameters - RX delay and airtime factor. Controls message retransmission behavior and timeout calculations.

**Implementation Notes**:
- Min frame length: 9 bytes
- RX delay base: milliseconds, stored as float by dividing by 1000
- Airtime factor: stored as float by dividing by 1000
- Values control flooding and direct message timeout calculations
- Always persists to preferences via `savePrefs()`
- No validation of ranges (accepts any uint32_t values)
- Pair command: `CMD_GET_TUNING_PARAMS` to read current values

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSetTuningParams = 21;

// Frame Builder
static Uint8List buildSetTuningParams({
  required double rxDelayBase, // seconds
  required double airtimeFactor,
}) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSetTuningParams);
  writer.writeUInt32LE((rxDelayBase * 1000).round()); // Convert to ms
  writer.writeUInt32LE((airtimeFactor * 1000).round());
  return writer.toBytes();
}

// Service API
Future<void> setTuningParams({
  required double rxDelayBase,
  required double airtimeFactor,
}) async {
  final frame = FrameBuilder.buildSetTuningParams(
    rxDelayBase: rxDelayBase,
    airtimeFactor: airtimeFactor,
  );
  await _commandSender.sendCommand(frame);
}
```

---

### 16. CMD_EXPORT_PRIVATE_KEY (23)

**Status**: Defined (`meshcore_constants.dart:37`)
**Priority**: Low (security risk)
**Use Case**: Device migration/backup

**Response**: `RESP_CODE_PRIVATE_KEY` (14) or `RESP_CODE_DISABLED` (15)

**Parameters**:
- Offset 0: Command code (23)
- No additional parameters

**C++ Implementation** (`MyMesh.cpp:1214-1222`):
```cpp
else if (cmd_frame[0] == CMD_EXPORT_PRIVATE_KEY) {
#if ENABLE_PRIVATE_KEY_EXPORT
  uint8_t reply[65];
  reply[0] = RESP_CODE_PRIVATE_KEY;
  self_id.writeTo(&reply[1], 64);
  _serial->writeFrame(reply, 65);
#else
  writeDisabledFrame();
#endif
}
```

**What It Does**: Exports the device's private key/identity. Used for backup or device migration. Can be disabled at compile-time for security.

**Response Format**:
- Byte 0: `RESP_CODE_PRIVATE_KEY` (14)
- Bytes 1-64: Serialized identity (64 bytes from self_id.writeTo())

**Implementation Notes**:
- No input parameters
- Guarded by compile-time flag `ENABLE_PRIVATE_KEY_EXPORT`
- If disabled, returns `RESP_CODE_DISABLED` (15) instead
- Exports complete private identity
- **SECURITY RISK**: Exposes private key over BLE
- Response always exactly 65 bytes when enabled

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdExportPrivateKey = 23;
// static const int respPrivateKey = 14;
// static const int respDisabled = 15;

// Frame Builder
static Uint8List buildExportPrivateKey() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdExportPrivateKey);
  return writer.toBytes();
}

// Frame Parser
static Uint8List parsePrivateKey(BufferReader reader) {
  return reader.readBytes(64); // 64-byte identity
}

// Service API
Future<Uint8List?> exportPrivateKey() async {
  final frame = FrameBuilder.buildExportPrivateKey();
  // TODO: Handle RESP_CODE_PRIVATE_KEY or RESP_CODE_DISABLED
  await _commandSender.sendCommand(frame);
}
```

---

### 17. CMD_IMPORT_PRIVATE_KEY (24)

**Status**: Defined (`meshcore_constants.dart:38`)
**Priority**: Low (security risk)
**Use Case**: Device migration/restore

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1) or `RESP_CODE_DISABLED` (15)

**Parameters**:
- Offset 0: Command code (24)
- Offset 1-64: Serialized identity (64 bytes)

**C++ Implementation** (`MyMesh.cpp:1223-1238`):
```cpp
else if (cmd_frame[0] == CMD_IMPORT_PRIVATE_KEY && len >= 65) {
#if ENABLE_PRIVATE_KEY_IMPORT
  mesh::LocalIdentity identity;
  identity.readFrom(&cmd_frame[1], 64);
  if (_store->saveMainIdentity(identity)) {
    self_id = identity;
    writeOKFrame();
    resetContacts();
    _store->loadContacts(this);
  } else {
    writeErrFrame(ERR_CODE_FILE_IO_ERROR);
  }
#else
  writeDisabledFrame();
#endif
}
```

**What It Does**: Imports a private key/identity from backup or migration. Replaces device identity and reloads all contacts.

**Error Codes**:
- `ERR_CODE_FILE_IO_ERROR` (5): Save failed

**Implementation Notes**:
- Min frame length: 65 bytes
- Guarded by compile-time flag `ENABLE_PRIVATE_KEY_IMPORT`
- If disabled, returns `RESP_CODE_DISABLED` (15)
- Parses 64-byte identity via `identity.readFrom()`
- Persists to storage via `_store->saveMainIdentity()`
- Updates internal `self_id` object
- Calls `resetContacts()` to clear existing contacts
- Reloads contacts from storage (recalculates shared secrets)
- **SECURITY RISK**: Changes device identity
- **SIDE EFFECT**: Clears and reloads contact list

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdImportPrivateKey = 24;

// Frame Builder
static Uint8List buildImportPrivateKey(Uint8List identity) {
  if (identity.length != 64) {
    throw ArgumentError('Identity must be exactly 64 bytes');
  }
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdImportPrivateKey);
  writer.writeBytes(identity);
  return writer.toBytes();
}

// Service API
Future<void> importPrivateKey(Uint8List identity) async {
  final frame = FrameBuilder.buildImportPrivateKey(identity);
  await _commandSender.sendCommand(frame);
  // Device identity changed, contacts will reload
}
```

---

### 18. CMD_SEND_RAW_DATA (25)

**Status**: Defined (`meshcore_constants.dart:39`)
**Priority**: Low (advanced use)
**Use Case**: Custom protocol development

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (25)
- Offset 1: Path length (-1 for flood, 0+ for direct path)
- Offset 2 to 2+pathlen: Path data (if path_len >= 0)
- Offset 2+pathlen+: Raw payload (min 4 bytes)

**C++ Implementation** (`MyMesh.cpp:1239-1254`):
```cpp
else if (cmd_frame[0] == CMD_SEND_RAW_DATA && len >= 6) {
  int i = 1;
  int8_t path_len = cmd_frame[i++];
  if (path_len >= 0 && i + path_len + 4 <= len) {
    uint8_t *path = &cmd_frame[i];
    i += path_len;
    auto pkt = createRawData(&cmd_frame[i], len - i);
    if (pkt) {
      sendDirect(pkt, path, path_len);
      writeOKFrame();
    } else {
      writeErrFrame(ERR_CODE_TABLE_FULL);
    }
  } else {
    writeErrFrame(ERR_CODE_UNSUPPORTED_CMD);
  }
}
```

**What It Does**: Sends raw binary data directly to a contact via specific path. Low-level packet transmission for custom protocols.

**Error Codes**:
- `ERR_CODE_TABLE_FULL` (3): Packet pool exhausted
- `ERR_CODE_UNSUPPORTED_CMD` (1): Flood mode not supported (path_len == -1)

**Implementation Notes**:
- Min frame length: 6 bytes
- Path length validation: must be >= 0 (flood not supported yet)
- Validates sufficient payload: min 4 bytes after path
- Validates frame length: i + path_len + 4 <= len
- Creates raw data packet via `createRawData()`
- Sends directly (not flood) via `sendDirect()`
- Currently **ONLY** supports direct path sending (path_len >= 0)

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSendRawData = 25;

// Frame Builder
static Uint8List buildSendRawData({
  required Uint8List path,
  required Uint8List payload,
}) {
  if (payload.length < 4) {
    throw ArgumentError('Payload must be at least 4 bytes');
  }
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendRawData);
  writer.writeByte(path.length); // Path length (must be >= 0)
  writer.writeBytes(path);
  writer.writeBytes(payload);
  return writer.toBytes();
}

// Service API
Future<void> sendRawData({
  required Uint8List path,
  required Uint8List payload,
}) async {
  final frame = FrameBuilder.buildSendRawData(path: path, payload: payload);
  await _commandSender.sendCommand(frame);
}
```

---

### 19. CMD_SIGN_START (33)

**Status**: Defined (`meshcore_constants.dart:43`)
**Priority**: Low (advanced use)
**Use Case**: Digital signatures for large data

**Response**: `RESP_CODE_SIGN_START` (19)

**Parameters**:
- Offset 0: Command code (33)
- No additional parameters

**C++ Implementation** (`MyMesh.cpp:1423-1434`):
```cpp
else if (cmd_frame[0] == CMD_SIGN_START) {
  out_frame[0] = RESP_CODE_SIGN_START;
  out_frame[1] = 0; // reserved
  uint32_t len = MAX_SIGN_DATA_LEN;
  memcpy(&out_frame[2], &len, 4);
  _serial->writeFrame(out_frame, 6);

  if (sign_data) {
    free(sign_data);
  }
  sign_data = (uint8_t *)malloc(MAX_SIGN_DATA_LEN);
  sign_data_len = 0;
}
```

**What It Does**: Initiates a multi-packet digital signature operation. Allocates buffer and resets state for accumulating data to sign.

**Response Format**:
- Byte 0: `RESP_CODE_SIGN_START` (19)
- Byte 1: Reserved (0)
- Bytes 2-5: Maximum data length (uint32_t LE)

**Implementation Notes**:
- No input parameters
- Always allocates MAX_SIGN_DATA_LEN bytes (8K per #define)
- Frees any previous sign_data buffer
- Initializes sign_data_len to 0
- Response always 6 bytes
- Max signature data: 8192 bytes
- Must be followed by `CMD_SIGN_DATA` calls, then `CMD_SIGN_FINISH`
- Overwrites any previous signing session

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSignStart = 33;
// static const int respSignStart = 19;

// Frame Builder
static Uint8List buildSignStart() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSignStart);
  return writer.toBytes();
}

// Frame Parser
static int parseSignStart(BufferReader reader) {
  reader.readByte(); // Skip reserved
  return reader.readUInt32LE(); // Max data length
}

// Service API
Future<int> signStart() async {
  final frame = FrameBuilder.buildSignStart();
  // TODO: Wait for RESP_CODE_SIGN_START and return max length
  await _commandSender.sendCommand(frame);
}
```

---

### 20. CMD_SIGN_DATA (34)

**Status**: Defined (`meshcore_constants.dart:44`)
**Priority**: Low (advanced use)
**Use Case**: Accumulate data for digital signature

**Response**: `RESP_CODE_OK` (0) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (34)
- Offset 1+: Data chunk to accumulate for signing

**C++ Implementation** (`MyMesh.cpp:1435-1442`):
```cpp
else if (cmd_frame[0] == CMD_SIGN_DATA && len > 1) {
  if (sign_data == NULL || sign_data_len + (len - 1) > MAX_SIGN_DATA_LEN) {
    writeErrFrame(sign_data == NULL ? ERR_CODE_BAD_STATE : ERR_CODE_TABLE_FULL);
  } else {
    memcpy(&sign_data[sign_data_len], &cmd_frame[1], len - 1);
    sign_data_len += (len - 1);
    writeOKFrame();
  }
}
```

**What It Does**: Accumulates data chunks to be digitally signed. Can be called multiple times to build up large data blocks.

**Error Codes**:
- `ERR_CODE_BAD_STATE` (4): Not initialized (sign_data == NULL)
- `ERR_CODE_TABLE_FULL` (3): Accumulated data exceeds MAX_SIGN_DATA_LEN (8K)

**Implementation Notes**:
- Min frame length: 2 bytes
- Requires `CMD_SIGN_START` to be called first
- Appends data_chunk to sign_data buffer
- Data size: len - 1 bytes (excluding command byte)
- Can be called multiple times to accumulate full message
- No response data, just success/error code

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSignData = 34;

// Frame Builder
static Uint8List buildSignData(Uint8List dataChunk) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSignData);
  writer.writeBytes(dataChunk);
  return writer.toBytes();
}

// Service API
Future<void> signData(Uint8List dataChunk) async {
  final frame = FrameBuilder.buildSignData(dataChunk);
  await _commandSender.sendCommand(frame);
}
```

---

### 21. CMD_SIGN_FINISH (35)

**Status**: Defined (`meshcore_constants.dart:45`)
**Priority**: Low (advanced use)
**Use Case**: Complete digital signature operation

**Response**: `RESP_CODE_SIGNATURE` (20) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (35)
- No additional parameters

**C++ Implementation** (`MyMesh.cpp:1443-1454`):
```cpp
else if (cmd_frame[0] == CMD_SIGN_FINISH) {
  if (sign_data) {
    self_id.sign(&out_frame[1], sign_data, sign_data_len);

    free(sign_data);
    sign_data = NULL;

    out_frame[0] = RESP_CODE_SIGNATURE;
    _serial->writeFrame(out_frame, 1 + SIGNATURE_SIZE);
  } else {
    writeErrFrame(ERR_CODE_BAD_STATE);
  }
}
```

**What It Does**: Completes the signing operation. Generates digital signature over accumulated data and returns result.

**Response Format**:
- Byte 0: `RESP_CODE_SIGNATURE` (20)
- Bytes 1+: Digital signature (SIGNATURE_SIZE bytes)

**Error Codes**:
- `ERR_CODE_BAD_STATE` (4): Not initialized (sign_data == NULL)

**Implementation Notes**:
- No input parameters
- Requires `CMD_SIGN_START` and one or more `CMD_SIGN_DATA` calls
- Signs accumulated data via `self_id.sign()`
- Frees sign_data buffer after signing
- Response length: 1 + SIGNATURE_SIZE bytes
- Signs all accumulated bytes from CMD_SIGN_DATA calls
- Signature uses device's private key (self_id)

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSignFinish = 35;
// static const int respSignature = 20;

// Frame Builder
static Uint8List buildSignFinish() {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSignFinish);
  return writer.toBytes();
}

// Frame Parser
static Uint8List parseSignature(BufferReader reader) {
  // Returns signature bytes (SIGNATURE_SIZE)
  return reader.readRemainingBytes();
}

// Service API
Future<Uint8List> signFinish() async {
  final frame = FrameBuilder.buildSignFinish();
  // TODO: Wait for RESP_CODE_SIGNATURE and return signature
  await _commandSender.sendCommand(frame);
}
```

---

### 22. CMD_SEND_TRACE_PATH (36)

**Status**: Defined (`meshcore_constants.dart:47`)
**Priority**: Medium
**Use Case**: Network diagnostics and topology analysis

**Response**: `RESP_CODE_SENT` (6) or `RESP_CODE_ERR` (1)

**Parameters**:
- Offset 0: Command code (36)
- Offset 1-4: Tag (uint32_t LE) - request identifier
- Offset 5-8: Auth code (uint32_t LE) - authentication/validation
- Offset 9: Flags byte
- Offset 10+: Path data (variable length, < MAX_PATH_SIZE)

**C++ Implementation** (`MyMesh.cpp:1455-1474`):
```cpp
else if (cmd_frame[0] == CMD_SEND_TRACE_PATH && len > 10 && len - 10 < MAX_PATH_SIZE) {
  uint32_t tag, auth;
  memcpy(&tag, &cmd_frame[1], 4);
  memcpy(&auth, &cmd_frame[5], 4);
  auto pkt = createTrace(tag, auth, cmd_frame[9]);
  if (pkt) {
    uint8_t path_len = len - 10;
    sendDirect(pkt, &cmd_frame[10], path_len);

    uint32_t t = _radio->getEstAirtimeFor(pkt->payload_len + pkt->path_len + 2);
    uint32_t est_timeout = calcDirectTimeoutMillisFor(t, path_len);

    out_frame[0] = RESP_CODE_SENT;
    out_frame[1] = 0;
    memcpy(&out_frame[2], &tag, 4);
    memcpy(&out_frame[6], &est_timeout, 4);
    _serial->writeFrame(out_frame, 10);
  } else {
    writeErrFrame(ERR_CODE_TABLE_FULL);
  }
}
```

**What It Does**: Sends a trace/path report packet to track network topology. Used for network path discovery and diagnostics.

**Response Format** (`RESP_CODE_SENT`):
- Byte 0: `RESP_CODE_SENT` (6)
- Byte 1: 0 (reserved/flags)
- Bytes 2-5: Tag (uint32_t LE, echoed from request)
- Bytes 6-9: Estimated timeout (uint32_t LE, milliseconds)

**Error Codes**:
- `ERR_CODE_TABLE_FULL` (3): Packet pool exhausted

**Implementation Notes**:
- Min frame length: 11 bytes (1 cmd + 4 tag + 4 auth + 1 flags + min 1 path)
- Max frame length: 10 + MAX_PATH_SIZE
- Path length: len - 10 bytes
- Creates trace packet via `createTrace(tag, auth, flags)`
- Sends directly to specified path via `sendDirect()`
- Calculates estimated airtime based on payload/path
- Response always 10 bytes if successful
- Tag parameter allows matching response to request
- Auth code included in packet for validation/replay protection
- Flags byte passed to createTrace (purpose depends on implementation)

**Flutter Implementation Guide**:
```dart
// Already defined in constants
// static const int cmdSendTracePath = 36;

// Frame Builder
static Uint8List buildSendTracePath({
  required int tag,
  required int authCode,
  required int flags,
  required Uint8List path,
}) {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendTracePath);
  writer.writeUInt32LE(tag);
  writer.writeUInt32LE(authCode);
  writer.writeByte(flags);
  writer.writeBytes(path);
  return writer.toBytes();
}

// Service API (reuses existing parseSentConfirmation)
Future<Map<String, dynamic>> sendTracePath({
  required int tag,
  required int authCode,
  required int flags,
  required Uint8List path,
}) async {
  final frame = FrameBuilder.buildSendTracePath(
    tag: tag,
    authCode: authCode,
    flags: flags,
    path: path,
  );
  // Wait for RESP_CODE_SENT
  await _commandSender.sendCommand(frame);
  // Returns: {expectedAckTag, suggestedTimeout, isFloodMode}
}
```

---

## Implementation Priority Matrix

### High Priority (Essential Features)
1. **CMD_HAS_CONNECTION (28)** - Check connectivity before sending
2. **CMD_GET_CONTACT_BY_KEY (30)** - Essential for contact lookup

### Medium Priority (Useful Features)
3. **CMD_LOGOUT (29)** - Room server management
4. **CMD_SHARE_CONTACT (16)** - Contact distribution
5. **CMD_EXPORT_CONTACT (17)** - Contact backup
6. **CMD_IMPORT_CONTACT (18)** - Contact restore
7. **CMD_SET_TUNING_PARAMS (21)** - Network optimization
8. **CMD_GET_TUNING_PARAMS (43)** - Read current settings
9. **CMD_GET_ADVERT_PATH (42)** - Network diagnostics
10. **CMD_SEND_PATH_DISCOVERY_REQ (52)** - Topology discovery
11. **CMD_SEND_TRACE_PATH (36)** - Path tracking

### Low Priority (Advanced/Specialized)
12. **CMD_REBOOT (19)** - Device management
13. **CMD_SET_DEVICE_PIN (37)** - BLE security
14. **CMD_GET_CUSTOM_VARS (40)** - Sensor config
15. **CMD_SET_CUSTOM_VAR (41)** - Sensor config
16. **CMD_SEND_RAW_DATA (25)** - Custom protocols
17. **CMD_SIGN_START (33)** - Digital signatures
18. **CMD_SIGN_DATA (34)** - Digital signatures
19. **CMD_SIGN_FINISH (35)** - Digital signatures

### Very Low Priority (Security Risks / Destructive)
20. **CMD_EXPORT_PRIVATE_KEY (23)** - May be disabled
21. **CMD_IMPORT_PRIVATE_KEY (24)** - May be disabled
22. **CMD_FACTORY_RESET (51)** - Destructive operation

---

## Quick Reference Table

| Code | Name | Status | Priority | Response | Min Len | Key Feature |
|------|------|--------|----------|----------|---------|-------------|
| 16 | SHARE_CONTACT | Not Defined | Medium | OK/ERR | 33 | Broadcasts contact zero-hop |
| 17 | EXPORT_CONTACT | Defined | Medium | RESP_11/ERR | 1-33 | Exports packet format |
| 18 | IMPORT_CONTACT | Defined | Medium | OK/ERR | 98 | Imports packet format |
| 19 | REBOOT | Defined | Low | None | 7 | Graceful restart |
| 21 | SET_TUNING_PARAMS | Defined | Medium | OK/ERR | 9 | Mesh timing config |
| 23 | EXPORT_PRIVATE_KEY | Defined | Very Low | RESP_14/DIS | 1 | 64B identity (risky) |
| 24 | IMPORT_PRIVATE_KEY | Defined | Very Low | OK/ERR/DIS | 65 | Changes identity (risky) |
| 25 | SEND_RAW_DATA | Defined | Low | OK/ERR | 6 | Custom protocol send |
| 28 | HAS_CONNECTION | Not Defined | High | OK/ERR | 33 | Check path exists |
| 29 | LOGOUT | Not Defined | Medium | OK | 33 | Disconnect from room |
| 30 | GET_CONTACT_BY_KEY | Not Defined | High | RESP_3/ERR | 33 | Full contact lookup |
| 33 | SIGN_START | Defined | Low | RESP_19 | 1 | Init signature (8K) |
| 34 | SIGN_DATA | Defined | Low | OK/ERR | 2 | Accumulate data |
| 35 | SIGN_FINISH | Defined | Low | RESP_20/ERR | 1 | Generate signature |
| 36 | SEND_TRACE_PATH | Defined | Medium | RESP_6/ERR | 11 | Network trace |
| 37 | SET_DEVICE_PIN | Not Defined | Low | OK/ERR | 5 | BLE pairing PIN |
| 40 | GET_CUSTOM_VARS | Not Defined | Low | RESP_21 | 1 | Sensor settings (CSV) |
| 41 | SET_CUSTOM_VAR | Not Defined | Low | OK/ERR | 4 | Set sensor value |
| 42 | GET_ADVERT_PATH | Not Defined | Medium | RESP_22/ERR | 9 | Advert path history |
| 43 | GET_TUNING_PARAMS | Not Defined | Medium | RESP_23 | 1 | Read mesh timing |
| 51 | FACTORY_RESET | Not Defined | Very Low | OK/ERR | 6 | Erase all (risky) |
| 52 | SEND_PATH_DISCOVERY | Not Defined | Medium | RESP_6 | 35 | Flood for paths |

---

## Notes

- All implementations based on analysis of `/Users/dz0ny/meshcore-sar/MeshCore/examples/companion_radio/MyMesh.cpp`
- Commands marked "Not Defined" need to be added to `lib/services/meshcore_constants.dart` first
- Commands marked "Defined" need FrameBuilder methods and service APIs
- Response codes not yet defined in Flutter:
  - `RESP_CODE_EXPORT_CONTACT` (11)
  - `RESP_CODE_SIGN_START` (19)
  - `RESP_CODE_SIGNATURE` (20)
  - `RESP_CODE_CUSTOM_VARS` (21)
  - `RESP_CODE_ADVERT_PATH` (22)
  - `RESP_CODE_TUNING_PARAMS` (23)
- Magic strings for safety: "reboot" (6 chars), "reset" (5 chars)
- Compile-time flags may disable private key import/export
- Some commands are destructive (factory reset, reboot)
- Digital signing commands (33-35) work as a sequence
- Network diagnostics commands (42, 52, 36) useful for mesh analysis

---

**Document Version**: 1.0
**Last Updated**: 2025-01-26
**Reference**: MeshCore Companion Radio Protocol v1
**Flutter App**: MeshCore SAR Application
