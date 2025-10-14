import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import '../services/cayenne_lpp_parser.dart';

/// Contacts Provider - manages contact list and telemetry
class ContactsProvider with ChangeNotifier {
  final Map<String, Contact> _contacts = {};

  // Add default public channel on initialization
  ContactsProvider() {
    _ensurePublicChannelExists();
  }

  /// Ensure public channel always exists in the list
  void _ensurePublicChannelExists() {
    const publicChannelKey = 'public_channel_0';
    if (!_contacts.containsKey(publicChannelKey)) {
      // Create a pseudo-contact for the public channel (ephemeral broadcast)
      _contacts[publicChannelKey] = Contact(
        publicKey: Uint8List.fromList(List.filled(32, 0)), // Zero key for public
        type: ContactType.channel, // Channel type (not room!)
        flags: 0,
        outPathLen: 0,
        outPath: Uint8List(64),
        advName: 'Public Channel',
        lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        advLat: 0,
        advLon: 0,
        lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }
  }

  List<Contact> get contacts => _contacts.values.toList();

  List<Contact> get chatContacts =>
      contacts.where((c) => c.isChat).toList()..sort(_sortByLastSeen);

  List<Contact> get repeaters =>
      contacts.where((c) => c.isRepeater).toList()..sort(_sortByLastSeen);

  List<Contact> get rooms =>
      contacts.where((c) => c.isRoom).toList()..sort(_sortByLastSeen);

  List<Contact> get channels {
    // Always ensure public channel exists when getting channels
    _ensurePublicChannelExists();
    return contacts.where((c) => c.isChannel).toList()..sort(_sortByLastSeen);
  }

  /// Get both rooms and channels (destinations for SAR markers)
  List<Contact> get roomsAndChannels {
    _ensurePublicChannelExists();
    return contacts.where((c) => c.isRoom || c.isChannel).toList()..sort(_sortByLastSeen);
  }

  /// Get contacts with location (for map display)
  List<Contact> get contactsWithLocation =>
      contacts.where((c) => c.displayLocation != null).toList();

  /// Get chat contacts with location (team members on map)
  List<Contact> get chatContactsWithLocation =>
      chatContacts.where((c) => c.displayLocation != null).toList();

  /// Sort contacts by last seen (most recent first)
  int _sortByLastSeen(Contact a, Contact b) {
    return b.lastSeenTime.compareTo(a.lastSeenTime);
  }

  /// Add or update a contact
  void addOrUpdateContact(Contact contact) {
    _contacts[contact.publicKeyHex] = contact;
    notifyListeners();
  }

  /// Add multiple contacts
  void addContacts(List<Contact> contacts) {
    for (final contact in contacts) {
      _contacts[contact.publicKeyHex] = contact;
    }
    notifyListeners();
  }

  /// Update contact telemetry
  void updateTelemetry(Uint8List publicKeyPrefix, Uint8List lppData) {
    // Find contact by public key prefix
    final contact = _findContactByPrefix(publicKeyPrefix);
    if (contact == null) return;

    try {
      // Parse Cayenne LPP data
      final telemetry = CayenneLppParser.parse(lppData);

      // Update contact with new telemetry
      final updatedContact = contact.copyWith(telemetry: telemetry);
      _contacts[contact.publicKeyHex] = updatedContact;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to parse telemetry: $e');
    }
  }

  /// Find contact by public key prefix (6 bytes)
  Contact? _findContactByPrefix(Uint8List prefix) {
    if (prefix.length < 6) return null;

    final prefixHex = prefix
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    for (final contact in contacts) {
      if (contact.publicKeyHex.startsWith(prefixHex)) {
        return contact;
      }
    }
    return null;
  }

  /// Find contact by public key
  Contact? findContactByKey(Uint8List publicKey) {
    final keyHex =
        publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return _contacts[keyHex];
  }

  /// Find contact by name
  Contact? findContactByName(String name) {
    return contacts.firstWhere(
      (c) => c.advName == name,
      orElse: () => contacts.first,
    );
  }

  /// Get contacts with low battery
  List<Contact> get lowBatteryContacts {
    return contacts.where((c) {
      final battery = c.displayBattery;
      return battery != null && battery < 20.0;
    }).toList();
  }

  /// Get recently seen contacts (within last 10 minutes)
  List<Contact> get recentlySeenContacts {
    return contacts.where((c) => c.isRecentlySeen).toList();
  }

  /// Clear all contacts
  void clearContacts() {
    _contacts.clear();
    notifyListeners();
  }

  /// Remove a contact
  void removeContact(String publicKeyHex) {
    _contacts.remove(publicKeyHex);
    notifyListeners();
  }

  /// Get contact count by type
  Map<String, int> get contactCounts {
    return {
      'chat': chatContacts.length,
      'repeater': repeaters.length,
      'room': rooms.length,
      'total': contacts.length,
    };
  }
}
