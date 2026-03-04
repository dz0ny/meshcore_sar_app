<p align="center">
  <img src="./icon.png" alt="MeshCore SAR icon" width="120" />
</p>

<h1 align="center">MeshCore SAR</h1>

<p align="center">
  Field-ready Search and Rescue coordination over <a href="https://github.com/meshcore-dev">MeshCore</a> + BLE
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue" />
  <img alt="Mode" src="https://img.shields.io/badge/offline-first-success" />
  <img alt="Use case" src="https://img.shields.io/badge/use%20case-SAR-orange" />
</p>

MeshCore SAR helps teams coordinate in low-connectivity or no-connectivity environments with messaging, voice, images, maps, and live location context in one app.
It uses the MeshCore protocol over LoRa for long-range, infrastructure-free communication.

## Highlights

- Rapid mesh chat for both 1:1 and group coordination
- On-demand voice (Codec2) and image (AVIF) transfer tuned for low-bandwidth links
- Offline-first mapping with tactical overlays and SAR incident markers
- Live team location, movement trails, and shareable tactical drawings

## Demo Video

<<<<<<< Updated upstream
[<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/13ccacee-7306-4976-a408-f31f3336828a" />](https://youtu.be/rLsKeLJBpFg)


Watch on YouTube: https://youtu.be/rLsKeLJBpFg
=======
[Watch the MeshCore SAR demo on YouTube](https://youtu.be/rLsKeLJBpFg)
>>>>>>> Stashed changes

## Screenshots

<p align="center">
  <img src="./screenshots/ios/IMG_2953.PNG" alt="Map view with live team context" width="19%" />
  <img src="./screenshots/ios/IMG_2954.PNG" alt="Compass and navigation view" width="19%" />
  <img src="./screenshots/ios/IMG_2955.PNG" alt="Contacts and repeaters list" width="19%" />
  <img src="./screenshots/ios/IMG_2956.PNG" alt="Messages with voice and image cards" width="19%" />
  <img src="./screenshots/ios/IMG_2957.PNG" alt="Quick actions sheet for SAR, voice, and image" width="19%" />
</p>

## Feature Overview

| Area | What you get |
|---|---|
| Messaging | Direct and group chat over mesh, with contact/room awareness from live telemetry |
| Voice | Push-to-talk voice clips (Codec2), fetched on demand when play is pressed, auto-play on completion |
| Images | Camera/gallery image sending (AVIF), auto-compression, tap-to-load receiving, full-screen viewer |
| Maps | Street/topo/satellite/terrain layers, offline tile downloads, optional MBTiles import |
| SAR Operations | Team markers with freshness indicators, SAR markers for incidents and staging points |
| Tracking | Continuous GPS updates, personal trails, distance/duration trail stats |
| Trail Interop | GPX export/import for trail sharing and reuse |
| Tactical Drawing | Line/rectangle drawing, distance measurement, drawing sharing to channel/room |

## Voice, Image, and Maps

### Voice
- Built for short, urgent field communication
- On-demand playback fetch reduces unnecessary mesh traffic
- Ideal when typing is impractical during active operations

### Images
- Pre-send optimization for constrained links
- Tap-to-load receiving keeps channels lightweight
- Full-screen view supports rapid field verification

### Maps
- Works in both online and offline workflows
- SAR context with team markers, incident markers, and orientation tools
- Combines location, messaging, and tactical layers in one place

## Built For

- Search and Rescue field teams
- Incident command and coordination roles
- Operators working in weak/no cellular coverage

## Permissions (App Use)

- Bluetooth: mesh device communication
- Location: team tracking and map position updates
- Microphone: voice clip recording
- Camera / Photos: image messaging
