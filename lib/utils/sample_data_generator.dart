import 'dart:typed_data';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';

/// Generates sample data for testing/demo purposes
class SampleDataGenerator {
  static final Random _random = Random();

  /// Generate sample contacts around a center location
  static List<Contact> generateContacts({
    required LatLng centerLocation,
    int teamMemberCount = 5,
    int channelCount = 2,
  }) {
    final contacts = <Contact>[];
    final now = DateTime.now();

    final teamNames = [
      '👮Police Lead',
      '🚁Drone Operator',
      '🧑🏻‍🚒Firefighter Alpha',
      '🧑‍⚕️Medic Charlie',
      '📡Command Delta',
      '🚒Fire Engine',
      '👨‍✈️Air Support',
      '🧑‍💼Base Coordinator',
    ];

    final channelNames = [
      'General',
      'Emergency',
      'Coordination',
      'Updates',
    ];

    // Generate team members (chat contacts)
    for (int i = 0; i < teamMemberCount && i < teamNames.length; i++) {
      // Generate location within ~1km radius
      final latOffset = (_random.nextDouble() - 0.5) * 0.02; // ~1km
      final lonOffset = (_random.nextDouble() - 0.5) * 0.02;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      // Generate random public key
      final publicKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Random battery 20-100%
      final battery = 20 + _random.nextInt(81);

      // Random temperature 15-35°C
      final temp = 15.0 + _random.nextDouble() * 20.0;

      final telemetry = ContactTelemetry(
        gpsLocation: LatLng(lat, lon),
        batteryPercentage: battery.toDouble(),
        batteryMilliVolts: 3000.0 + (battery / 100.0) * 1200.0,
        temperature: temp,
        timestamp: now.subtract(Duration(minutes: _random.nextInt(10))),
      );

      final contact = Contact(
        publicKey: publicKey,
        type: ContactType.chat,
        flags: 0,
        outPathLen: 1,
        outPath: Uint8List(32),
        advName: teamNames[i],
        lastAdvert: now.millisecondsSinceEpoch ~/ 1000,
        advLat: (lat * 1e6).toInt(),
        advLon: (lon * 1e6).toInt(),
        lastMod: now.millisecondsSinceEpoch ~/ 1000,
        telemetry: telemetry,
      );

      contacts.add(contact);
    }

    // Generate channels/rooms
    for (int i = 0; i < channelCount && i < channelNames.length; i++) {
      // Generate random public key
      final publicKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Channel index stored in outPath[0]
      final outPath = Uint8List(32);
      outPath[0] = i; // Channel index

      final channel = Contact(
        publicKey: publicKey,
        type: ContactType.room,
        flags: 0,
        outPathLen: 1,
        outPath: outPath,
        advName: channelNames[i],
        lastAdvert: now.millisecondsSinceEpoch ~/ 1000,
        advLat: 0, // Channels don't have location
        advLon: 0,
        lastMod: now.millisecondsSinceEpoch ~/ 1000,
      );

      contacts.add(channel);
    }

    return contacts;
  }

  /// Generate sample SAR markers around a center location
  static List<Message> generateSarMarkerMessages({
    required LatLng centerLocation,
    int foundPersonCount = 2,
    int fireCount = 1,
    int stagingCount = 1,
    int objectCount = 1,
  }) {
    final messages = <Message>[];
    final now = DateTime.now();
    int messageId = 1;

    // Generate found person markers
    for (int i = 0; i < foundPersonCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 10 + i * 5));
      messages.add(Message(
        id: 'sample_fp_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🧑:${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarMarkerType: SarMarkerType.foundPerson,
        sarGpsCoordinates: LatLng(lat, lon),
        senderName: 'Sample Team Member',
      ));
      messageId++;
    }

    // Generate fire markers
    for (int i = 0; i < fireCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 20 + i * 5));
      messages.add(Message(
        id: 'sample_fire_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🔥:${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarMarkerType: SarMarkerType.fire,
        sarGpsCoordinates: LatLng(lat, lon),
        senderName: 'Sample Scout',
      ));
      messageId++;
    }

    // Generate staging area markers
    for (int i = 0; i < stagingCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 30 + i * 5));
      messages.add(Message(
        id: 'sample_staging_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🏕️:${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarMarkerType: SarMarkerType.stagingArea,
        sarGpsCoordinates: LatLng(lat, lon),
        senderName: 'Sample Base',
      ));
      messageId++;
    }

    // Generate object markers
    for (int i = 0; i < objectCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 40 + i * 5));
      final notes = [
        ' Backpack found - blue color',
        ' Vehicle abandoned - check for owner',
        ' Camping equipment discovered',
        ' Trail marker found off-path',
      ];

      messages.add(Message(
        id: 'sample_object_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:📦:${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}${notes[i % notes.length]}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarMarkerType: SarMarkerType.object,
        sarGpsCoordinates: LatLng(lat, lon),
        senderName: 'Sample Searcher',
      ));
      messageId++;
    }

    return messages;
  }

  /// Generate sample channel messages for public channels
  static List<Message> generateChannelMessages({
    LatLng? centerLocation,
    int generalChannelMessages = 8,
    int emergencyChannelMessages = 5,
  }) {
    // Use provided location or default to Ljubljana, Slovenia
    final center = centerLocation ?? const LatLng(46.0569, 14.5058);
    final messages = <Message>[];
    final now = DateTime.now();
    int messageId = 1000; // Start with high ID to avoid conflicts

    // Sample messages for General channel (index 0)
    final generalMessages = [
      'All teams check in',
      'Weather update: Clear skies, temp 18°C',
      'Base camp established at staging area',
      'Team Alpha moving to sector 2',
      'Radio check - all stations respond',
      'Water supply available at checkpoint 3',
      'Team Bravo reporting: sector 1 clear',
      'ETA to rally point: 15 minutes',
      'Supply drop confirmed for 14:00',
      'Drone survey completed - no findings',
      'Team Charlie requesting backup',
      'All units: maintain radio discipline',
    ];

    // Sample messages for Emergency channel (index 1)
    // Mix regular messages and SAR markers
    final emergencyMessages = [
      'URGENT: Medical assistance needed at sector 4',
      'S:🧑:${center.latitude.toStringAsFixed(4)},${(center.longitude + 0.005).toStringAsFixed(4)} Adult male, conscious',
      'Fire spotted - coordinates incoming',
      'S:🔥:${(center.latitude + 0.008).toStringAsFixed(4)},${(center.longitude + 0.003).toStringAsFixed(4)} Spreading rapidly!',
      'PRIORITY: Need helicopter support',
      'Medical team en route to your location',
      'Evac helicopter ETA 10 minutes',
      'Emergency resolved - all clear',
      'S:🏕️:${(center.latitude - 0.002).toStringAsFixed(4)},${(center.longitude - 0.004).toStringAsFixed(4)} Emergency staging area',
      'Emergency services notified and responding',
    ];

    final teamNames = [
      'Alpha Team Lead',
      'Bravo Scout',
      'Charlie Medic',
      'Delta Navigator',
      'Echo Support',
      'Base Command',
      'Field Coordinator',
      'Medical Team',
    ];

    // Generate General channel messages
    for (int i = 0; i < generalChannelMessages && i < generalMessages.length; i++) {
      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Messages spread over the last 2 hours
      final minutesAgo = 120 - (i * 15) - _random.nextInt(10);
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      messages.add(Message(
        id: 'sample_general_$messageId',
        messageType: MessageType.channel,
        channelIdx: 0, // General channel
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: generalMessages[i],
        receivedAt: timestamp,
        senderName: teamNames[_random.nextInt(teamNames.length)],
      ));
      messageId++;
    }

    // Generate Emergency channel messages
    for (int i = 0; i < emergencyChannelMessages && i < emergencyMessages.length; i++) {
      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Emergency messages more recent (last hour)
      final minutesAgo = 60 - (i * 10) - _random.nextInt(5);
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      messages.add(Message(
        id: 'sample_emergency_$messageId',
        messageType: MessageType.channel,
        channelIdx: 1, // Emergency channel
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: emergencyMessages[i],
        receivedAt: timestamp,
        senderName: teamNames[_random.nextInt(teamNames.length)],
      ));
      messageId++;
    }

    return messages;
  }
}
