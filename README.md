# MeshCore SAR

Flutter app for Search and Rescue operations over a [MeshCore](https://github.com/meshcore-dev) mesh radio network via Bluetooth Low Energy.

## Features

- **Messaging** — send/receive messages to contacts and channels
- **Contacts** — track team members, repeaters, and rooms with live telemetry
- **SAR Markers** — drop emoji-coded location pins (person found, fire, staging area) via chat messages
- **Map** — view team positions and markers on OpenStreetMap / topo / satellite; tiles cached for offline use
- **Location tracking** — periodic GPS updates broadcast to the mesh
- **Packet log** — inspect raw BLE frames for debugging

## BLE Protocol

The BLE communication layer lives in a separate reusable package:
**[github.com/dz0ny/meshcore_client](https://github.com/dz0ny/meshcore_client)**

It handles connection management, command queueing, and binary frame parsing/building.

## Requirements

- Flutter 3.19+ / Dart 3.3+
- Physical device with Bluetooth (BLE does not work on simulators)
- iOS 13+ or Android SDK 21+

## Build

```bash
flutter pub get
flutter run                        # debug
flutter build apk --release        # Android
flutter build ios --release        # iOS
```

### iOS signing

```bash
open ios/Runner.xcworkspace
# Select team in Signing & Capabilities, then run from Xcode
```

### Clean rebuild

```bash
flutter clean && flutter pub get
cd ios && pod deintegrate && pod install && cd ..
```

## Permissions

| Platform | Permissions |
|----------|-------------|
| iOS | Bluetooth, Location (when in use) |
| Android | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `INTERNET` |

## SAR Marker format

```
S:<emoji>:<lat>,<lon>
```

Examples: `S:🧑:46.0569,14.5058` · `S:🔥:46.057,14.506` · `S:🏕️:46.0571,14.506`

## Architecture

```
lib/
├── models/       — data types (re-exported from meshcore_client)
├── providers/    — state management (Provider pattern)
├── screens/      — top-level pages
├── services/     — location tracking, SSE bridge, tile cache
└── widgets/      — reusable UI components
```
