# MeshCore SAR: Off-Grid Communication for Search & Rescue Operations

When the grid goes down, lives are on the line. MeshCore SAR is a revolutionary mobile application that enables search and rescue teams to communicate, coordinate, and share critical information—even when cellular networks and internet connectivity are completely unavailable.

Built on cutting-edge mesh networking technology, MeshCore SAR transforms ordinary smartphones into powerful off-grid communication devices using low-power radio hardware. Whether you're coordinating a wilderness rescue, managing a disaster response, or operating in remote areas, MeshCore SAR keeps your team connected when it matters most.

## Why MeshCore SAR?

Traditional communication systems fail when you need them most:
- **Cellular networks** collapse during disasters or don't exist in remote wilderness
- **Satellite phones** are expensive and have limited messaging capabilities
- **Radio systems** require licensing and lack modern features like GPS integration

MeshCore SAR solves these problems by creating a resilient, self-healing mesh network that:
- ✅ **Works completely off-grid** - No cellular, WiFi, or internet required
- ✅ **Extends range through mesh routing** - Messages hop through nearby devices
- ✅ **Integrates GPS tracking** - Real-time location sharing on offline maps
- ✅ **Specializes in SAR operations** - Purpose-built features for emergency response
- ✅ **Uses affordable hardware** - Low-cost LoRa radios via Bluetooth

---

## 🗨️ Messages: Reliable Communication When Networks Fail

[*Image placeholder: Messages screen showing conversation with delivery status*]

At the heart of MeshCore SAR is a robust messaging system designed for mission-critical communication.

### Key Features:

**🎯 Multiple Communication Modes**
- **Direct Messages**: Private one-to-one communication with team members
- **Public Channel**: Broadcast updates to all nearby devices
- **Rooms**: Persistent message storage for coordination centers

**📡 Smart Message Delivery**
- **Intelligent routing**: Messages automatically find the best path through the mesh network
- **Delivery confirmation**: Know when your message reaches its destination with ACK tracking
- **Automatic retries**: Failed messages retry automatically with progressive timeouts
- **Flood fallback**: Critical messages use broadcast mode if routing fails

**🚨 SAR Marker Messages**
Send location-tagged alerts with a simple message format:
- **🧑 Found Person**: `S:🧑:37.7749,-122.4194:Survivor located, needs medical attention`
- **🔥 Fire Location**: `S:🔥:40.7128,-74.0060:Wildfire spreading rapidly northeast`
- **🏕️ Staging Area**: `S:🏕️:34.0522,-118.2437:Base camp established with supplies`

These special messages automatically appear as markers on the map, making critical information instantly visual for the entire team.

**📊 Message Status Tracking**
Every message shows its delivery status:
- ⏳ **Sending** - Message is being transmitted
- ✅ **Sent** - Message queued with expected acknowledgment
- ✔️✔️ **Delivered** - Confirmation received with round-trip time
- 🔄 **Retrying** - Automatic retry in progress
- ❌ **Failed** - Delivery unsuccessful after all attempts

**🌍 Multilingual Support**
Full localization in English, Croatian (Hrvatski), and Slovenian (Slovenščina) ensures teams can communicate in their native language.

---

## 👥 Contacts: Know Your Team's Status and Location

[*Image placeholder: Contacts list showing team members with GPS locations and battery levels*]

MeshCore SAR's contact system goes beyond simple names and numbers—it provides real-time situational awareness for your entire team.

### Contact Intelligence:

**📍 Real-Time Location Tracking**
- GPS coordinates automatically broadcast at configurable intervals
- Location history tracking (last 100 positions per contact)
- Distance and bearing calculations from your position
- "Last seen" timestamps for situational awareness

**🔋 Battery Monitoring**
- Battery percentage displayed for each team member
- Voltage telemetry via Cayenne LPP format
- Early warning when team members need to conserve power

**🛤️ Mesh Network Routing**
The app shows routing information for each contact:
- **Direct (0 hops)**: Connected directly to your radio
- **Good path (1-2 hops)**: Reliable routing through 1-2 intermediate devices
- **Medium/Long path (3-5+ hops)**: Extended range through multiple hops
- **No path (flood mode)**: Messages broadcast to entire network

**👔 Role-Based Identification**
- Add emoji prefixes to names (🧑🏻‍🚒 for firefighter, 👮 for police, 🏥 for medical)
- Instant visual identification on map and in contact lists
- Customizable display names

**📡 Contact Types**
- **Chat** (Team Members): Standard team members shown on map
- **Repeater**: Network infrastructure nodes that extend range
- **Room**: Message servers with persistent storage and login capabilities

**📞 Contact Sharing**
- Export contacts as business cards
- Share contacts directly over the mesh network
- Import contacts from other team members

---

## 🗺️ Map: Offline Navigation and Tactical Awareness

[*Image placeholder: Map screen showing team members, SAR markers, and offline terrain*]

The map is where everything comes together—combining team locations, SAR events, and offline navigation into a single, comprehensive tactical display.

### Map Features:

**🗺️ Offline Vector Maps**
- **MBTiles format**: Lightweight vector maps that work completely offline
- **Multiple layers**: Street maps (OpenStreetMap), topographic (OpenTopoMap), satellite imagery (ESRI)
- **High zoom levels**: Street-level detail up to zoom level 19
- **Smart caching**: Tiles cached locally for 30 days

**📍 Team Member Tracking**
Each team member appears on the map with:
- Blue circle markers with role emoji
- Battery level badge (green/yellow/red indicators)
- Distance from your location
- Tap to view detailed information and message directly

**🚨 SAR Event Markers**
Critical events appear as color-coded markers:
- 🟢 **Green** - Found Person
- 🔴 **Red** - Fire Location
- 🔵 **Blue** - Staging Area
- 🟣 **Purple** - Object
- Time elapsed since report
- Tap to navigate and view details

**✏️ Map Drawing Tools**
Collaborative tactical planning:
- **Line drawings**: Sketch routes, boundaries, or directions
- **Rectangle areas**: Mark zones, perimeters, or sectors
- **8 color palette**: Red, blue, green, yellow, orange, purple, pink, cyan
- **Share drawings**: Send to channel or specific rooms via mesh network
- **Collaborative editing**: All team members see drawings in real-time
- **Ultra-compact format**: Efficient JSON encoding reduces bandwidth usage by 37%

**🧭 Detailed Compass Dialog**
Ultra-compact location display:
- Current GPS coordinates
- Toggle between Decimal Degrees (DD) and Degrees/Minutes/Seconds (DMS)
- Tap outside to close (no buttons needed)
- Perfect for quick location checks

**📡 User Location Tracking**
- Blue pulsing circle shows your current position
- Navigation icon for direction
- Tap to center and track your movement
- Configurable accuracy settings

**📊 Map Legend**
Collapsible legend in top-right corner:
- Team member count
- SAR marker count by type
- Quick reference for marker colors

**🎯 Smart Navigation**
- Tap any SAR marker in messages to navigate on map
- Automatic tab switching
- Map centers and zooms to selected location
- Clears navigation after viewing

---

## 🔧 Technical Innovation

### Mesh Network Protocol
- **MeshCore Protocol**: Open-source, battle-tested mesh networking
- **LoRa Radio**: Long-range, low-power wireless technology
- **BLE Connection**: Smartphone connects to companion radio via Bluetooth
- **Intelligent routing**: Self-healing paths through the network
- **Flood mode fallback**: Guaranteed delivery for critical messages

### Smart Features
- **Adaptive location broadcasting**: Only sends updates when you move significantly
- **Progressive retry logic**: Failed messages retry with increasing timeouts
- **Cayenne LPP telemetry**: Standardized sensor data format
- **Contact synchronization**: Automatic contact list updates
- **Message persistence**: Rooms store messages for later retrieval

### Built for Reliability
- **Provider-based architecture**: Efficient state management
- **Automatic reconnection**: Handles radio disconnections gracefully
- **Message queue management**: Synchronizes messages in order
- **Battery optimization**: Configurable tracking intervals
- **Memory management**: Automatic history cleanup

---

## 🌟 Real-World Applications

**Search & Rescue Operations**
- Wilderness rescue coordination
- Missing person searches
- Cave rescue operations
- Mountain rescue teams

**Disaster Response**
- Hurricane and flood response
- Earthquake emergency communication
- Infrastructure failure scenarios
- Mass casualty incidents

**Remote Operations**
- Forestry operations
- Mining site communication
- Border patrol and security
- Wildlife management

**Training & Exercises**
- Team coordination drills
- Radio discipline training
- Navigation exercises
- Emergency preparedness

---

## 🚀 Getting Started

MeshCore SAR works with affordable LoRa companion radios that connect to your smartphone via Bluetooth. The app handles all the complexity—you just:

1. **Connect** your radio via Bluetooth
2. **Add contacts** to your team
3. **Start messaging** and tracking locations
4. **Download maps** for your area
5. **Coordinate** your mission

No cellular service. No internet. No limits.

---

## 🌍 Open Source & Community-Driven

MeshCore SAR is built on the open-source MeshCore protocol, fostering a community of developers and users who contribute to its continuous improvement. Whether you're a first responder, amateur radio enthusiast, or outdoor adventurer, you're part of a global network working to keep people connected when it matters most.

---

## 💡 The Future of Off-Grid Communication

In a world increasingly dependent on fragile infrastructure, MeshCore SAR represents a paradigm shift: resilient, decentralized communication that works when everything else fails. As climate change drives more frequent disasters and teams operate in increasingly remote locations, mesh networking isn't just an alternative—it's essential.

**MeshCore SAR isn't just an app. It's a lifeline.**

---

*MeshCore SAR is compatible with iOS 13+ and Android API 21+. Requires compatible LoRa companion radio hardware.*

**Repository**: [github.com/meshcore-dev/meshcore.js](https://github.com/meshcore-dev/meshcore.js)

---

## 📸 Screenshots

*[Placeholder sections for images]*

### Messages
*Screenshot showing conversation with delivery status, SAR marker messages, and message options*

### Contacts
*Screenshot showing contact list with GPS locations, battery levels, and routing information*

### Map - Team View
*Screenshot showing map with multiple team members, distance indicators, and user location*

### Map - SAR Markers
*Screenshot showing map with various SAR markers (person, fire, staging area) and color coding*

### Map - Drawing Tools
*Screenshot showing map with line and rectangle drawings, color palette, and toolbar*

### Map - Offline Layers
*Screenshot showing different map layers (street, topographic, satellite) selection*

### Settings
*Screenshot showing connection status, radio parameters, and location tracking settings*

### Contact Details
*Screenshot showing detailed contact information, telemetry data, and message history*

---

**Ready to experience off-grid communication?** Connect your radio and join the mesh network today.
