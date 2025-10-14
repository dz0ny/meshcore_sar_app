# CLAUDE.md - MeshCore SAR Technical Reference

This document provides technical details for AI assistants (like Claude) working with this codebase.

## ⚠️ IMPORTANT: Flutter Development Rules

**NEVER run or kill Flutter processes:**
- **DO NOT** execute `flutter run` command
- **DO NOT** kill Flutter processes (e.g., `pkill flutter`, `killall flutter`)
- The user manages the Flutter development server themselves
- Only make code changes and let the user trigger hot reload manually

**Hot reload happens automatically when you save files** - the user has their own Flutter process running and will see changes instantly.

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

The app implements the MeshCore BLE Companion Radio protocol based on https://github.com/meshcore-dev/meshcore.js

**BLE Service**: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
**RX Characteristic** (write): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
**TX Characteristic** (notify): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`

#### Protocol Overview

The companion radio acts as a 'server', responding to requests from the connected app (the 'client').

**Frame Delimiters**:
- **BLE**: A frame is a single characteristic value (BLE link layer handles integrity)
- **USB**:
  - Outbound (radio → app): Starts with `>` (0x3E), 2-byte length (LE), then frame data
  - Inbound (app → radio): Starts with `<` (0x3C), 2-byte length (LE), then frame data

**NOTE**: All uint32 values use Little Endian byte order!

#### Command Codes (App → Radio)

| Code | Name | Description |
|------|------|-------------|
| 1 | CMD_APP_START | First command after connection, returns RESP_CODE_SELF_INFO(5) |
| 2 | CMD_SEND_TXT_MSG | Send text message to contact (DM) |
| 3 | CMD_SEND_CHANNEL_TXT_MSG | Send flood-mode text message to channel |
| 4 | CMD_GET_CONTACTS | Sync contacts list (optional 'since' param) |
| 5 | CMD_GET_DEVICE_TIME | Get device clock (epoch secs, UTC) |
| 6 | CMD_SET_DEVICE_TIME | Set device clock |
| 7 | CMD_SEND_SELF_ADVERT | Send Advertisement packet (optional flood-mode) |
| 8 | CMD_SET_ADVERT_NAME | Update node name in advertisements |
| 9 | CMD_ADD_UPDATE_CONTACT | Add or modify a contact |
| 10 | CMD_SYNC_NEXT_MESSAGE | Get next text message from queue |
| 11 | CMD_SET_RADIO_PARAMS | Save new radio parameters |
| 12 | CMD_SET_RADIO_TX_POWER | Set radio TX power level |
| 13 | CMD_RESET_PATH | Reset out_path for a contact |
| 14 | CMD_SET_ADVERT_LATLON | Update lat/lon in advertisements |
| 15 | CMD_REMOVE_CONTACT | Remove a contact |
| 16 | CMD_SHARE_CONTACT | Share contact via zero-hop advert |
| 17 | CMD_EXPORT_CONTACT | Export contact as 'business card' |
| 18 | CMD_IMPORT_CONTACT | Import contact from 'business card' |
| 19 | CMD_REBOOT | Reboot companion device |
| 20 | CMD_GET_BATT_AND_STORAGE | Get battery mV and storage stats |
| 21 | CMD_SET_TUNING_PARAMS | Set tuning parameters |
| 22 | CMD_DEVICE_QUERY | First command to send, returns RESP_CODE_DEVICE_INFO(13) |
| 25 | CMD_SEND_RAW_DATA | Transmit PAYLOAD_TYPE_RAW_CUSTOM packet |
| 26 | CMD_SEND_LOGIN | Send login request to repeater/room |
| 27 | CMD_SEND_STATUS_REQ | Send status request to repeater/sensor |
| 36 | CMD_SEND_TRACE_PATH | Initiate TRACE packet with SNR collection |
| 37 | CMD_SET_DEVICE_PIN | Set BLE PIN code |
| 38 | CMD_SET_OTHER_PARAMS | Set various other parameters |
| 39 | CMD_SEND_TELEMETRY_REQ | Send telemetry request to node |
| 40 | CMD_GET_CUSTOM_VARS | Retrieve all custom variables |
| 41 | CMD_SET_CUSTOM_VAR | Set single custom variable |
| 42 | CMD_GET_ADVERT_PATH | Query last advert path for contact |
| 43 | CMD_GET_TUNING_PARAMS | Get airtime-factor and rx-delay settings |
| 50 | CMD_SEND_BINARY_REQ | Send binary request to node (preferred over CMD_SEND_TELEMETRY_REQ) |
| 51 | CMD_FACTORY_RESET | Erase flash file system |

#### Response Codes (Radio → App)

| Code | Name | Description |
|------|------|-------------|
| 0 | RESP_CODE_OK | Success |
| 1 | RESP_CODE_ERR | Error (includes err_code) |
| 2 | RESP_CODE_CONTACTS_START | Start of contacts sync sequence |
| 3 | RESP_CODE_CONTACT | Single contact information |
| 4 | RESP_CODE_END_OF_CONTACTS | End of contacts sync sequence |
| 5 | RESP_CODE_SELF_INFO | Node's own information |
| 6 | RESP_CODE_SENT | Message sent with expected ACK/TAG |
| 7 | RESP_CODE_CONTACT_MSG_RECV | Contact message received |
| 8 | RESP_CODE_CHANNEL_MSG_RECV | Channel message received |
| 9 | RESP_CODE_CURR_TIME | Current device time |
| 10 | RESP_CODE_NO_MORE_MESSAGES | Message queue empty |
| 11 | RESP_CODE_EXPORT_CONTACT | Contact export data |
| 12 | RESP_CODE_BATT_AND_STORAGE | Battery and storage info |
| 13 | RESP_CODE_DEVICE_INFO | Device firmware and hardware info |
| 21 | RESP_CODE_CUSTOM_VARS | Custom variables state |
| 22 | RESP_CODE_ADVERT_PATH | Last advert path for contact |

#### Push Notifications (Radio → App, Async)

| Code | Name | Description |
|------|------|-------------|
| 0x80 | PUSH_CODE_ADVERT | New advertisement packet received |
| 0x81 | PUSH_CODE_PATH_UPDATED | Contact received new path |
| 0x82 | PUSH_CODE_SEND_CONFIRMED | Message ACK received |
| 0x83 | PUSH_CODE_MSG_WAITING | New text message received |
| 0x84 | PUSH_CODE_RAW_DATA | PAYLOAD_TYPE_RAW_CUSTOM received |
| 0x85 | PUSH_CODE_LOGIN_SUCCESS | Login response successful |
| 0x86 | PUSH_CODE_LOGIN_FAIL | Login response failed |
| 0x87 | PUSH_CODE_STATUS_RESPONSE | Status response received |
| 0x89 | PUSH_CODE_TRACE_DATA | TRACE packet reached end of path |
| 0x8A | PUSH_CODE_NEW_ADVERT | New contact advert (manual_add_contacts=1) |
| 0x8B | PUSH_CODE_TELEMETRY_RESPONSE | Telemetry response received |
| 0x8C | PUSH_CODE_BINARY_RESPONSE | Binary response received |

#### Frame Formats

**CMD_DEVICE_QUERY (22)**:
```
[0x16] - Command code (22)
[1 byte] - App target version (protocol version app understands)
```

**RESP_CODE_DEVICE_INFO (13)**:
```
[0x0D] - Response code (13)
[1 byte] - Firmware version
[1 byte] - Max contacts ÷ 2 (ver 3+)
[1 byte] - Max channels (ver 3+)
[4 bytes] - BLE PIN (uint32, ver 3+)
[12 bytes] - Firmware build date (ASCII null-terminated, e.g., "19 Feb 2025")
[40 bytes] - Manufacturer model (ASCII null-terminated)
[20 bytes] - Semantic version (ASCII null-terminated)
```

**CMD_APP_START (1)**:
```
[0x01] - Command code (1)
[1 byte] - App version
[6 bytes] - Reserved (zeros)
[N bytes] - App name (remainder of frame, varchar)
```

**RESP_CODE_SELF_INFO (5)**:
```
[0x05] - Response code (5)
[1 byte] - Type (ADV_TYPE_*)
[1 byte] - TX power in dBm (current)
[1 byte] - Max TX power radio supports
[32 bytes] - Public key
[4 bytes] - Advert latitude * 1E6 (int32)
[4 bytes] - Advert longitude * 1E6 (int32)
[1 byte] - Multi ACKs (0=no extra, 1=send extra ACK)
[1 byte] - Advert location policy (0=don't share, 1=share)
[1 byte] - Telemetry modes (bits 0-1: Base mode, bits 2-3: Location mode)
           Modes: 0=DENY, 1=apply contact.flags, 2=ALLOW ALL
[1 byte] - Manual add contacts (0 or 1)
[4 bytes] - Radio freq * 1000 (uint32)
[4 bytes] - Radio bandwidth (kHz) * 1000 (uint32)
[1 byte] - Spreading factor
[1 byte] - Coding rate
[N bytes] - Name (remainder of frame, varchar)
```

**CMD_GET_CONTACTS (4)**:
```
[0x04] - Command code (4)
[4 bytes] - (Optional) Since timestamp (uint32, last contact.lastmod received)
```

**RESP_CODE_CONTACTS_START (2)**:
```
[0x02] - Response code (2)
[4 bytes] - Total contact count (uint32)
```

**RESP_CODE_CONTACT (3)**:
```
[0x03] - Response code (3)
[32 bytes] - Public key
[1 byte] - Type (ADV_TYPE_*)
[1 byte] - Flags
[1 byte] - Out path length (signed)
[64 bytes] - Out path
[32 bytes] - Advertised name (null-terminated)
[4 bytes] - Last advert timestamp (uint32)
[4 bytes] - Advert latitude * 1E6 (int32)
[4 bytes] - Advert longitude * 1E6 (int32)
[4 bytes] - Last modified timestamp (uint32)
```

**RESP_CODE_END_OF_CONTACTS (4)**:
```
[0x04] - Response code (4)
[4 bytes] - Most recent lastmod (uint32, use for next 'since' param)
```

**CMD_SET_DEVICE_TIME (6)**:
```
[0x06] - Command code (6)
[4 bytes] - Epoch seconds (uint32)
```

**RESP_CODE_CURR_TIME (9)**:
```
[0x09] - Response code (9)
[4 bytes] - Epoch seconds (uint32)
```

**CMD_SEND_SELF_ADVERT (7)**:
```
[0x07] - Command code (7)
[1 byte] - (Optional) Type: 1=flood, 0=zero-hop (default)
```

**CMD_SET_ADVERT_NAME (8)**:
```
[0x08] - Command code (8)
[N bytes] - Name (remainder of frame, varchar)
```

**CMD_SET_ADVERT_LATLON (14)**:
```
[0x0E] - Command code (14)
[4 bytes] - Latitude * 1E6 (int32)
[4 bytes] - Longitude * 1E6 (int32)
[4 bytes] - (Optional) Altitude (int32, future support)
```

**CMD_ADD_UPDATE_CONTACT (9)**:
```
[0x09] - Command code (9)
[32 bytes] - Public key
[1 byte] - Type (ADV_TYPE_*)
[1 byte] - Flags
[1 byte] - Out path length (signed)
[64 bytes] - Out path
[32 bytes] - Advertised name (null-terminated)
[4 bytes] - Last advert timestamp (uint32)
[4 bytes] - (Optional) Advert latitude * 1E6 (int32)
[4 bytes] - (Optional) Advert longitude * 1E6 (int32)
```

**CMD_REMOVE_CONTACT (15)**:
```
[0x0F] - Command code (15)
[32 bytes] - Public key
```

**CMD_SHARE_CONTACT (16)**:
```
[0x10] - Command code (16)
[32 bytes] - Public key
```

**CMD_EXPORT_CONTACT (17)**:
```
[0x11] - Command code (17)
[32 bytes] - (Optional) Public key (if omitted, export SELF)
```

**RESP_CODE_EXPORT_CONTACT (11)**:
```
[0x0B] - Response code (11)
[N bytes] - Card data (remainder of frame)
            Format: "meshcore://{hex(card_data)}"
```

**CMD_IMPORT_CONTACT (18)**:
```
[0x12] - Command code (18)
[N bytes] - Card data (remainder of frame)
```

**CMD_RESET_PATH (13)**:
```
[0x0D] - Command code (13)
[32 bytes] - Public key
```

**CMD_SEND_TXT_MSG (2)**:
```
[0x02] - Command code (2)
[1 byte] - Text type (TXT_TYPE_*, 0=plain)
[1 byte] - Attempt (0-3, attempt number)
[4 bytes] - Sender timestamp (uint32)
[6 bytes] - Recipient public key prefix (first 6 bytes)
[N bytes] - Text (remainder of frame, varchar, max 160 bytes)
```

**CMD_SEND_CHANNEL_TXT_MSG (3)**:
```
[0x03] - Command code (3)
[1 byte] - Text type (TXT_TYPE_*, 0=plain)
[1 byte] - Channel index (reserved, 0 for 'public')
[4 bytes] - Sender timestamp (uint32)
[N bytes] - Text (remainder of frame, max 160 - len(advert_name) - 2)
```

**RESP_CODE_SENT (6)**:
```
[0x06] - Response code (6)
[1 byte] - Send type: 1=flood, 0=direct
[4 bytes] - Expected ACK code or TAG
[4 bytes] - Suggested timeout (uint32, milliseconds)
```

**PUSH_CODE_SEND_CONFIRMED (0x82)**:
```
[0x82] - Push code
[4 bytes] - ACK code
[4 bytes] - Round trip time (uint32, milliseconds)
```

**RESP_CODE_CONTACT_MSG_RECV (7)**:
```
[0x07] - Response code (7)
[6 bytes] - Sender public key prefix (first 6 bytes)
[1 byte] - Path length (0xFF if direct, else hop count for flood-mode)
[1 byte] - Text type (TXT_TYPE_*, 0=plain)
[4 bytes] - Sender timestamp (uint32)
[N bytes] - Text (remainder of frame, varchar)
```

**RESP_CODE_CHANNEL_MSG_RECV (8)**:
```
[0x08] - Response code (8)
[1 byte] - Channel index (reserved, 0 for 'public')
[1 byte] - Path length (0xFF if direct, else hop count for flood-mode)
[1 byte] - Text type (TXT_TYPE_*, 0=plain)
[4 bytes] - Sender timestamp (uint32)
[N bytes] - Text (remainder of frame, varchar)
```

**CMD_SET_RADIO_PARAMS (11)**:
```
[0x0B] - Command code (11)
[4 bytes] - Radio freq * 1000 (uint32)
[4 bytes] - Radio bandwidth (kHz) * 1000 (uint32)
[1 byte] - Spreading factor
[1 byte] - Coding rate
```

**CMD_SET_RADIO_TX_POWER (12)**:
```
[0x0C] - Command code (12)
[1 byte] - TX power in dBm
```

**CMD_SET_TUNING_PARAMS (21) / RESP_CODE_TUNING_PARAMS**:
```
[0x15] - Command/Response code (21)
[4 bytes] - RX delay base * 1000 (uint32)
[4 bytes] - Airtime factor * 1000 (uint32)
[8 bytes] - Reserved (set to zero)
```

**CMD_SET_OTHER_PARAMS (38)**:
```
[0x26] - Command code (38)
[1 byte] - Manual add contacts (0 or 1)
[1 byte] - (Optional v5+) Telemetry modes
[1 byte] - (Optional v5+) Advert location policy
[1 byte] - (Optional v7+) Multi ACKs (0=no extra, 1=send extra)
```

**RESP_CODE_BATT_AND_STORAGE (12)**:
```
[0x0C] - Response code (12)
[2 bytes] - Millivolts (uint16)
[4 bytes] - (Optional) Used KB (uint32)
[4 bytes] - (Optional) Total KB (uint32, zero if unknown)
```

**CMD_SEND_RAW_DATA (25)**:
```
[0x19] - Command code (25)
[1 byte] - Path length
[N bytes] - Path (variable length)
[M bytes] - Payload (remainder of frame)
```

**PUSH_CODE_RAW_DATA (0x84)**:
```
[0x84] - Push code
[1 byte] - SNR * 4 (signed)
[1 byte] - RSSI (signed)
[1 byte] - Reserved (0xFF)
[N bytes] - Payload (remainder of frame)
```

**CMD_SEND_LOGIN (26)**:
```
[0x1A] - Command code (26)
[32 bytes] - Public key (repeater or room server)
[N bytes] - Password (remainder of frame, varchar, max 15 bytes)
```

**PUSH_CODE_LOGIN_SUCCESS (0x85)**:
```
[0x85] - Push code
[1 byte] - Permissions (lowest bit=is_admin)
[6 bytes] - Public key prefix (first 6 bytes)
[4 bytes] - Tag (int32)
[1 byte] - (V7+) New permissions
```

**CMD_SEND_STATUS_REQ (27)**:
```
[0x1B] - Command code (27)
[32 bytes] - Public key (repeater or sensor)
```

**PUSH_CODE_STATUS_RESPONSE (0x87)**:
```
[0x87] - Push code
[1 byte] - Reserved (zero)
[6 bytes] - Public key prefix (first 6 bytes)
[N bytes] - Status data (remainder of frame)
```

**CMD_SEND_TELEMETRY_REQ (39)**:
```
[0x27] - Command code (39)
[3 bytes] - Reserved (zeros)
[32 bytes] - Public key (destination node)
```

**PUSH_CODE_TELEMETRY_RESPONSE (0x8B)**:
```
[0x8B] - Push code
[1 byte] - Reserved (zero)
[6 bytes] - Public key prefix (first 6 bytes)
[N bytes] - LPP sensor data (Cayenne LPP format, remainder of frame)
```

**CMD_SEND_BINARY_REQ (50)** *(Preferred over CMD_SEND_TELEMETRY_REQ)*:
```
[0x32] - Command code (50)
[32 bytes] - Public key (contact to send request to)
[N bytes] - Request code and params (remainder of frame)
```

**PUSH_CODE_BINARY_RESPONSE (0x8C)**:
```
[0x8C] - Push code
[1 byte] - Reserved (zero)
[4 bytes] - Tag (uint32, matches RESP_CODE_SENT expected_ack_or_tag)
[N bytes] - Response data (remainder of frame)
```

**CMD_SEND_TRACE_PATH (36)**:
```
[0x24] - Command code (36)
[4 bytes] - Tag (int32, random initiator tag)
[4 bytes] - Auth code (int32, optional authentication)
[1 byte] - Flags (zero for now)
[N bytes] - Path (remainder of frame, hashes for TRACE to follow)
```

**PUSH_CODE_TRACE_DATA (0x89)**:
```
[0x89] - Push code
[1 byte] - Reserved (zero)
[1 byte] - Path length
[1 byte] - Flags (zero for now)
[4 bytes] - Tag (int32)
[4 bytes] - Auth code (int32)
[N bytes] - Path hashes (variable length)
[N+1 bytes] - Path SNRs (last byte = SNR for last hop, each byte = SNR * 4)
```

**CMD_SET_DEVICE_PIN (37)**:
```
[0x25] - Command code (37)
[4 bytes] - BLE PIN (uint32)
```

**CMD_GET_ADVERT_PATH (42)**:
```
[0x2A] - Command code (42)
[1 byte] - Reserved (zero)
[32 bytes] - Public key (contact being queried)
```

**RESP_CODE_ADVERT_PATH (22)**:
```
[0x16] - Response code (22)
[4 bytes] - Receive timestamp (uint32, by local clock)
[1 byte] - Path length
[N bytes] - Path (variable length)
```

**CMD_FACTORY_RESET (51)**:
```
[0x33] - Command code (51)
[5 bytes] - ASCII "reset" (confirmation)
```

**RESP_CODE_ERR (1)**:
```
[0x01] - Response code (1)
[1 byte] - Error code (ERR_CODE_*)
```

#### Constants

**ADV_TYPE (Advertisement/Contact Type)**:
- `0` - ADV_TYPE_NONE (unknown/invalid)
- `1` - ADV_TYPE_CHAT (team member, shown on map)
- `2` - ADV_TYPE_REPEATER (network repeater node)
- `3` - ADV_TYPE_ROOM (communication room/server - NOT the same as channel index!)

**IMPORTANT: Channels vs. Rooms**:
- **Channels** (channel index): Numeric identifiers used with `CMD_SEND_CHANNEL_TXT_MSG` for flood-mode broadcasts
  - Channel 0 = "Public Channel" (default flood-mode broadcast to all nodes)
  - Channel 1+ = Reserved for future use (not currently mapped to room contacts)
  - **Channels are ephemeral** - messages broadcast over the air are NOT persisted
- **Rooms** (ADV_TYPE_ROOM): Actual named contacts with public keys that provide persistent message storage
  - Rooms appear in the Contacts tab as ContactType.room
  - **Rooms provide persistent and immutable storage** - messages are stored even when offline
  - To communicate with a room, send direct messages using `CMD_SEND_TXT_MSG` with the room's public key
  - Optional: Login to rooms using `CMD_SEND_LOGIN` with password to read stored messages

**Room Login Protocol Flow (CRITICAL - Follow Exactly)**:

1. **Client sends login request** (`CMD_SEND_LOGIN`, code 26):
   ```
   [0x1A] - Command code (26)
   [4 bytes] - Sender timestamp (uint32, current epoch seconds)
   [4 bytes] - sync_since timestamp (uint32, epoch seconds - 0 for all messages)
   [32 bytes] - Room public key
   [N bytes] - Password (max 15 bytes, null-terminated)
   ```

2. **Room server processes login** (C++ code: `MyMesh::onAnonDataRecv()`):
   - Validates password against `_prefs.password` (admin) or `_prefs.guest_password` (read/write)
   - Stores `client->extra.room.sync_since = sender_sync_since` (line 324 of MyMesh.cpp)
   - Responds with `PAYLOAD_TYPE_RESPONSE` containing login result
   - Sets `next_push = futureMillis(PUSH_NOTIFY_DELAY_MILLIS)` to delay first push by 2000ms (line 346)

3. **Client receives login response**:
   - Success: `PUSH_CODE_LOGIN_SUCCESS` (0x85) with permissions, admin flag, tag
   - Failure: `PUSH_CODE_LOGIN_FAIL` (0x86) if password incorrect

4. **Room server automatically pushes messages** (C++ code: `MyMesh::loop()` lines 498-542):
   - Server runs round-robin polling every `SYNC_PUSH_INTERVAL` (1200ms)
   - For each logged-in client, checks if `post_timestamp > client->extra.room.sync_since`
   - Calls `pushPostToClient()` which sends `PAYLOAD_TYPE_TXT_MSG` directly to client
   - Waits for ACK, then advances `client->extra.room.sync_since` to next post
   - Continues until all messages where `post_timestamp > sync_since` are pushed

5. **Client receives pushed messages as they arrive**:
   - Each push triggers `PUSH_CODE_MSG_WAITING` (0x83)
   - App's `onMessageWaiting` callback fires automatically
   - App then calls `CMD_SYNC_NEXT_MESSAGE` (10) to fetch each message from device queue
   - Repeats until `RESP_CODE_NO_MORE_MESSAGES` (10) received

**CRITICAL IMPLEMENTATION RULES**:
- ❌ **DO NOT** call `syncAllMessages()` immediately after `PUSH_CODE_LOGIN_SUCCESS`
- ✅ **DO** wait for `PUSH_CODE_MSG_WAITING` push notifications
- ✅ **DO** call `syncNextMessage()` when `onMessageWaiting` callback fires
- The room server pushes messages **automatically** - the app only needs to listen and fetch when notified
- Server delays first push by 2000ms to allow login response to arrive first
- Server uses round-robin with 1200ms intervals between push attempts
- Each pushed message requires ACK before server advances to next message

**SAR Message Routing**:
- **SAR markers MUST be sent to rooms, NOT to public channel**
- Use `CMD_SEND_TXT_MSG` with the room's public key (direct message to room)
- This ensures SAR markers are **persisted and immutable** in the room's storage
- Public channel (`CMD_SEND_CHANNEL_TXT_MSG`) is ephemeral over-the-air only
- Rooms provide reliable message delivery and storage for critical SAR data

**TXT_TYPE (Text Message Type)**:
- `0` - TXT_TYPE_PLAIN (plain text message)
- `1` - TXT_TYPE_CLI_DATA (CLI command)
- `2` - TXT_TYPE_SIGNED_PLAIN (plain text, signed by sender)

**ERR_CODE (Error Codes)**:
- `1` - ERR_CODE_UNSUPPORTED_CMD
- `2` - ERR_CODE_NOT_FOUND
- `3` - ERR_CODE_TABLE_FULL
- `4` - ERR_CODE_BAD_STATE
- `5` - ERR_CODE_FILE_IO_ERROR
- `6` - ERR_CODE_ILLEGAL_ARG

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
