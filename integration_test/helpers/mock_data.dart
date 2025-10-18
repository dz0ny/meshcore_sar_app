import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/message.dart';
import 'package:meshcore_sar_app/models/sar_marker.dart';

/// Mock data for integration tests and screenshots
class MockData {
  /// Generate mock contacts with predictable data
  static List<Contact> getMockContacts() {
    return [
      Contact(
        publicKey: '0x1111111111111111111111111111111111111111111111111111111111111111',
        name: 'Alpha Team Lead',
        contactType: ContactType.chat,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 2)),
        lastLocation: const ContactLocation(
          latitude: 46.0569,
          longitude: 14.5058,
          altitude: 295.0,
        ),
        batteryMillivolts: 3850,
        hopCount: 1,
        rssi: -45,
      ),
      Contact(
        publicKey: '0x2222222222222222222222222222222222222222222222222222222222222222',
        name: 'Bravo Scout',
        contactType: ContactType.chat,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 5)),
        lastLocation: const ContactLocation(
          latitude: 46.0589,
          longitude: 14.5078,
          altitude: 310.0,
        ),
        batteryMillivolts: 3700,
        hopCount: 2,
        rssi: -68,
      ),
      Contact(
        publicKey: '0x3333333333333333333333333333333333333333333333333333333333333333',
        name: 'Charlie Base',
        contactType: ContactType.chat,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 1)),
        lastLocation: const ContactLocation(
          latitude: 46.0549,
          longitude: 14.5038,
          altitude: 285.0,
        ),
        batteryMillivolts: 4100,
        hopCount: 0,
        rssi: -35,
      ),
      Contact(
        publicKey: '0x4444444444444444444444444444444444444444444444444444444444444444',
        name: 'Delta Medic',
        contactType: ContactType.chat,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 8)),
        lastLocation: const ContactLocation(
          latitude: 46.0609,
          longitude: 14.5098,
          altitude: 320.0,
        ),
        batteryMillivolts: 3600,
        hopCount: 3,
        rssi: -75,
      ),
      Contact(
        publicKey: '0x5555555555555555555555555555555555555555555555555555555555555555',
        name: 'Mountain Repeater 1',
        contactType: ContactType.repeater,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 1)),
        lastLocation: const ContactLocation(
          latitude: 46.0650,
          longitude: 14.5150,
          altitude: 450.0,
        ),
        batteryMillivolts: 4150,
        hopCount: 0,
        rssi: -40,
      ),
      Contact(
        publicKey: '0x6666666666666666666666666666666666666666666666666666666666666666',
        name: 'SAR Command Room',
        contactType: ContactType.room,
        lastAdvertisement: DateTime.now().subtract(const Duration(minutes: 30)),
        hopCount: 1,
        rssi: -50,
      ),
    ];
  }

  /// Generate mock messages with SAR markers
  static List<Message> getMockMessages() {
    final now = DateTime.now();
    return [
      Message(
        id: 'msg1',
        sender: '0x1111111111111111111111111111111111111111111111111111111111111111',
        senderName: 'Alpha Team Lead',
        content: 'Team Alpha in position, beginning sweep of sector 3',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg2',
        sender: '0x2222222222222222222222222222222222222222222222222222222222222222',
        senderName: 'Bravo Scout',
        content: 'S:🧑:46.0589,14.5078:Found injured hiker near trail marker 7',
        timestamp: now.subtract(const Duration(minutes: 12)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg3',
        sender: 'self',
        senderName: 'You',
        content: 'Copy that Bravo, sending medic to your location',
        timestamp: now.subtract(const Duration(minutes: 11)),
        isSent: true,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg4',
        sender: '0x4444444444444444444444444444444444444444444444444444444444444444',
        senderName: 'Delta Medic',
        content: 'En route to Bravo position, ETA 5 minutes',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg5',
        sender: '0x3333333333333333333333333333333333333333333333333333333333333333',
        senderName: 'Charlie Base',
        content: 'S:🏕️:46.0549,14.5038:Staging area established, supplies available',
        timestamp: now.subtract(const Duration(minutes: 8)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg6',
        sender: '0x1111111111111111111111111111111111111111111111111111111111111111',
        senderName: 'Alpha Team Lead',
        content: 'S:🔥:46.0620,14.5120:Small campfire spotted in sector 4, monitoring',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg7',
        sender: '0x2222222222222222222222222222222222222222222222222222222222222222',
        senderName: 'Bravo Scout',
        content: 'Patient stabilized, waiting for extraction',
        timestamp: now.subtract(const Duration(minutes: 3)),
        isSent: false,
        isPublicChannel: false,
      ),
      Message(
        id: 'msg8',
        sender: 'self',
        senderName: 'You',
        content: 'All teams: Weather window closing in 2 hours, prepare to RTB',
        timestamp: now.subtract(const Duration(minutes: 1)),
        isSent: true,
        isPublicChannel: true,
      ),
    ];
  }

  /// Generate mock SAR markers from messages
  static List<SarMarker> getMockSarMarkers() {
    final now = DateTime.now();
    return [
      SarMarker(
        id: 'sar1',
        type: SarMarkerType.foundPerson,
        latitude: 46.0589,
        longitude: 14.5078,
        message: 'Found injured hiker near trail marker 7',
        timestamp: now.subtract(const Duration(minutes: 12)),
        sender: '0x2222222222222222222222222222222222222222222222222222222222222222',
        senderName: 'Bravo Scout',
      ),
      SarMarker(
        id: 'sar2',
        type: SarMarkerType.stagingArea,
        latitude: 46.0549,
        longitude: 14.5038,
        message: 'Staging area established, supplies available',
        timestamp: now.subtract(const Duration(minutes: 8)),
        sender: '0x3333333333333333333333333333333333333333333333333333333333333333',
        senderName: 'Charlie Base',
      ),
      SarMarker(
        id: 'sar3',
        type: SarMarkerType.fireLocation,
        latitude: 46.0620,
        longitude: 14.5120,
        message: 'Small campfire spotted in sector 4, monitoring',
        timestamp: now.subtract(const Duration(minutes: 5)),
        sender: '0x1111111111111111111111111111111111111111111111111111111111111111',
        senderName: 'Alpha Team Lead',
      ),
    ];
  }

  /// Mock device info for connection status
  static Map<String, dynamic> getMockDeviceInfo() {
    return {
      'deviceName': 'MeshCore-SAR-DEMO',
      'firmwareVersion': '2.1.0',
      'hardwareVersion': 'v3',
      'publicKey': '0xAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899',
      'batteryMillivolts': 3950,
      'storageUsed': 1024 * 512, // 512 KB
      'storageTotal': 1024 * 1024 * 4, // 4 MB
    };
  }

  /// Mock radio parameters
  static Map<String, dynamic> getMockRadioParams() {
    return {
      'frequency': 915.0,
      'bandwidth': 125.0,
      'spreadingFactor': 9,
      'codingRate': 7,
      'txPower': 20,
    };
  }
}
