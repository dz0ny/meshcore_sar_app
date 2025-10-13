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
      'Alpha Team Lead',
      'Bravo Scout',
      'Charlie Medic',
      'Delta Navigator',
      'Echo Support',
      'Foxtrot Runner',
      'Golf Comms',
      'Hotel Base',
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
        advLat: (lat * 1e7).toInt(),
        advLon: (lon * 1e7).toInt(),
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

    return messages;
  }
}
