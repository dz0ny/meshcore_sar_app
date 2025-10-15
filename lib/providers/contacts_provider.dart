import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/cayenne_lpp_parser.dart';
import '../services/contact_storage_service.dart';

/// Contacts Provider - manages contact list and telemetry
class ContactsProvider with ChangeNotifier {
  final Map<String, Contact> _contacts = {};
  final ContactStorageService _storageService = ContactStorageService();
  bool _isInitialized = false;

  // Add default public channel on initialization
  ContactsProvider() {
    _ensurePublicChannelExists();
  }

  bool get isInitialized => _isInitialized;

  /// Initialize and load persisted contacts
  /// [devicePublicKey] - device's own public key to exclude from loaded contacts
  Future<void> initialize({Uint8List? devicePublicKey}) async {
    if (_isInitialized) return;

    try {
      print('📦 [ContactsProvider] Loading persisted contacts...');
      final storedContacts = await _storageService.loadContacts(
        excludePublicKey: devicePublicKey,
      );

      // Add stored contacts
      for (final contact in storedContacts) {
        _contacts[contact.publicKeyHex] = contact;
      }

      _isInitialized = true;
      print('✅ [ContactsProvider] Loaded ${storedContacts.length} persisted contacts');

      // Ensure public channel exists after loading
      _ensurePublicChannelExists();

      notifyListeners();
    } catch (e) {
      print('❌ [ContactsProvider] Error initializing: $e');
      _isInitialized = true; // Mark as initialized even on error
      _ensurePublicChannelExists();
    }
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

  /// Persist contacts to storage (async, non-blocking)
  Future<void> _persistContacts() async {
    try {
      // Don't persist the public channel pseudo-contact
      final contactsToSave = _contacts.values
          .where((c) => c.publicKeyHex != 'public_channel_0')
          .toList();
      await _storageService.saveContacts(contactsToSave);
    } catch (e) {
      print('❌ [ContactsProvider] Error persisting contacts: $e');
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
  /// Excludes contacts that match the device's own public key
  void addOrUpdateContact(Contact contact, {Uint8List? devicePublicKey}) {
    // Don't add contacts that match our device's public key
    if (devicePublicKey != null && _publicKeysMatch(contact.publicKey, devicePublicKey)) {
      print('ℹ️ [ContactsProvider] Ignoring contact with device\'s own public key: ${contact.advName}');
      return;
    }

    // Check if this is a new contact
    final isNewContact = !_contacts.containsKey(contact.publicKeyHex);

    // If it's a new contact, mark it as new
    if (isNewContact) {
      _contacts[contact.publicKeyHex] = contact.copyWith(isNew: true);
    } else {
      // Keep existing isNew status when updating
      final existingContact = _contacts[contact.publicKeyHex]!;
      _contacts[contact.publicKeyHex] = contact.copyWith(isNew: existingContact.isNew);
    }

    _persistContacts();
    notifyListeners();
  }

  /// Compare two public keys for equality
  bool _publicKeysMatch(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
  }

  /// Add multiple contacts
  /// Excludes contacts that match the device's own public key
  void addContacts(List<Contact> contacts, {Uint8List? devicePublicKey}) {
    int excluded = 0;
    for (final contact in contacts) {
      // Don't add contacts that match our device's public key
      if (devicePublicKey != null && _publicKeysMatch(contact.publicKey, devicePublicKey)) {
        print('ℹ️ [ContactsProvider] Ignoring contact with device\'s own public key: ${contact.advName}');
        excluded++;
        continue;
      }
      _contacts[contact.publicKeyHex] = contact;
    }
    if (excluded > 0) {
      print('ℹ️ [ContactsProvider] Excluded $excluded contact(s) matching device public key');
    }
    _persistContacts();
    notifyListeners();
  }

  /// Update contact telemetry
  void updateTelemetry(Uint8List publicKeyPrefix, Uint8List lppData) {
    print('📊 [ContactsProvider] updateTelemetry() called');
    print('  Public key prefix (hex): ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('  LPP data size: ${lppData.length} bytes');

    // Find contact by public key prefix
    final contact = _findContactByPrefix(publicKeyPrefix);
    if (contact == null) {
      print('  ❌ Contact not found for this prefix');
      return;
    }

    print('  ✅ Found contact: ${contact.advName}');
    print('  Old telemetry timestamp: ${contact.telemetry?.timestamp}');

    try {
      // Parse Cayenne LPP data
      final telemetry = CayenneLppParser.parse(lppData);
      print('  ✅ Parsed new telemetry');
      print('  New telemetry timestamp: ${telemetry.timestamp}');

      // Update contact with new telemetry
      final updatedContact = contact.copyWith(telemetry: telemetry);
      _contacts[contact.publicKeyHex] = updatedContact;
      print('  ✅ Updated contact in map');

      _persistContacts();
      print('  ✅ Persisted contacts to storage');

      notifyListeners();
      print('  ✅ Notified listeners - UI should update');
    } catch (e) {
      print('  ❌ Failed to parse telemetry: $e');
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

  /// Get count of new contacts (not yet viewed)
  int get newContactsCount =>
      contacts.where((c) => c.isNew && !c.isChannel).length;

  /// Mark all contacts as viewed (not new)
  void markAllAsViewed() {
    bool hasChanges = false;
    _contacts.forEach((key, contact) {
      if (contact.isNew && !contact.isChannel) {
        _contacts[key] = contact.copyWith(isNew: false);
        hasChanges = true;
      }
    });
    if (hasChanges) {
      _persistContacts();
      notifyListeners();
    }
  }

  /// Mark a specific contact as viewed (not new)
  void markAsViewed(String publicKeyHex) {
    final contact = _contacts[publicKeyHex];
    if (contact != null && contact.isNew) {
      _contacts[publicKeyHex] = contact.copyWith(isNew: false);
      _persistContacts();
      notifyListeners();
    }
  }

  /// Clear all contacts
  void clearContacts() {
    _contacts.clear();
    _persistContacts();
    notifyListeners();
  }

  /// Remove a contact
  /// [onRemoveFromDevice] - Optional callback to remove contact from BLE device
  Future<void> removeContact(
    String publicKeyHex, {
    Future<void> Function(Uint8List)? onRemoveFromDevice,
  }) async {
    // Get the contact before removing
    final contact = _contacts[publicKeyHex];
    if (contact == null) return;

    // Remove from device first if callback provided
    if (onRemoveFromDevice != null) {
      await onRemoveFromDevice(contact.publicKey);
    }

    // Then remove from local storage
    _contacts.remove(publicKeyHex);
    _persistContacts();
    notifyListeners();
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats();
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
