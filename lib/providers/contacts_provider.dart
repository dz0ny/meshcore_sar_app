import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/contact.dart';
import '../models/message_contact_location.dart';
import '../services/cayenne_lpp_parser.dart';
import '../services/contact_storage_service.dart';
import '../utils/key_comparison.dart';

class PendingAdvert {
  final Uint8List publicKey;
  final DateTime receivedAt;

  const PendingAdvert({required this.publicKey, required this.receivedAt});

  String get publicKeyHex =>
      publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

  String get shortDisplayKey {
    final prefix = publicKey.length >= 6 ? publicKey.sublist(0, 6) : publicKey;
    return prefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  PendingAdvert copyWith({Uint8List? publicKey, DateTime? receivedAt}) {
    return PendingAdvert(
      publicKey: publicKey ?? this.publicKey,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

/// Contacts Provider - manages contact list and telemetry
class ContactsProvider with ChangeNotifier {
  final Map<String, Contact> _contacts = {};
  final Map<String, PendingAdvert> _pendingAdverts = {};
  final ContactStorageService _storageService = ContactStorageService();
  bool _isInitialized = false;

  // Add default public channel on initialization
  ContactsProvider() {
    _ensurePublicChannelExists();
  }

  bool get isInitialized => _isInitialized;

  /// Initialize and load persisted contacts at app startup
  /// This loads contacts without filtering, allowing offline viewing
  Future<void> initializeEarly() async {
    if (_isInitialized) return;

    try {
      debugPrint(
        '📦 [ContactsProvider] Early loading persisted contacts (no filtering)...',
      );
      final storedContacts = await _storageService.loadContacts();

      // Add stored contacts (excluding any with all-zeros public key)
      const publicChannelKey =
          '0000000000000000000000000000000000000000000000000000000000000000';
      for (final contact in storedContacts) {
        // Skip any contacts with all-zeros public key (shouldn't happen, but safety check)
        if (contact.publicKeyHex == publicChannelKey) {
          continue;
        }
        _contacts[contact.publicKeyHex] = contact;
      }

      _isInitialized = true;
      debugPrint(
        '✅ [ContactsProvider] Early loaded ${storedContacts.length} persisted contacts',
      );

      // Ensure public channel exists after loading
      _ensurePublicChannelExists();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error in early initialization: $e');
      _isInitialized = true; // Mark as initialized even on error
      _ensurePublicChannelExists();
    }
  }

  /// Initialize and load persisted contacts
  /// [devicePublicKey] - device's own public key to exclude from loaded contacts
  Future<void> initialize({Uint8List? devicePublicKey}) async {
    if (_isInitialized) {
      // If already initialized (from early load), just filter out self-contact
      if (devicePublicKey != null) {
        _removeSelfContact(devicePublicKey);
      }
      return;
    }

    try {
      debugPrint('📦 [ContactsProvider] Loading persisted contacts...');
      final storedContacts = await _storageService.loadContacts(
        excludePublicKey: devicePublicKey,
      );

      // Add stored contacts (excluding any with all-zeros public key)
      const publicChannelKey =
          '0000000000000000000000000000000000000000000000000000000000000000';
      for (final contact in storedContacts) {
        // Skip any contacts with all-zeros public key (shouldn't happen, but safety check)
        if (contact.publicKeyHex == publicChannelKey) {
          continue;
        }
        _contacts[contact.publicKeyHex] = contact;
      }

      _isInitialized = true;
      debugPrint(
        '✅ [ContactsProvider] Loaded ${storedContacts.length} persisted contacts',
      );

      // Ensure public channel exists after loading
      _ensurePublicChannelExists();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error initializing: $e');
      _isInitialized = true; // Mark as initialized even on error
      _ensurePublicChannelExists();
    }
  }

  /// Remove self-contact from loaded contacts (called after BLE connection established)
  void _removeSelfContact(Uint8List devicePublicKey) {
    final selfKeyHex = devicePublicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    if (_contacts.containsKey(selfKeyHex)) {
      final selfContact = _contacts[selfKeyHex]!;
      debugPrint(
        '🗑️ [ContactsProvider] Removing self-contact: ${selfContact.advName}',
      );
      _contacts.remove(selfKeyHex);
      _persistContacts();
      notifyListeners();
    }
  }

  /// Ensure public channel always exists in the list
  void _ensurePublicChannelExists() {
    // Public channel has all-zeros public key (32 bytes = 64 hex chars)
    const publicChannelKey =
        '0000000000000000000000000000000000000000000000000000000000000000';
    if (!_contacts.containsKey(publicChannelKey)) {
      // Create a pseudo-contact for the public channel (ephemeral broadcast)
      _contacts[publicChannelKey] = Contact(
        publicKey: Uint8List.fromList(
          List.filled(32, 0),
        ), // Zero key for public
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
      // Don't persist the public channel pseudo-contact (all zeros key)
      const publicChannelKey =
          '0000000000000000000000000000000000000000000000000000000000000000';
      final contactsToSave = _contacts.entries
          .where((entry) => entry.key != publicChannelKey)
          .map((entry) => entry.value)
          .toList();
      await _storageService.saveContacts(contactsToSave);
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error persisting contacts: $e');
    }
  }

  List<Contact> get contacts => _contacts.values.toList();
  List<PendingAdvert> get pendingAdverts =>
      _pendingAdverts.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

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
    return contacts.where((c) => c.isRoom || c.isChannel).toList()
      ..sort(_sortByLastSeen);
  }

  /// Get contacts with location (for map display)
  List<Contact> get contactsWithLocation =>
      contacts.where((c) => c.displayLocation != null).toList();

  /// Get chat contacts with location (team members on map)
  List<Contact> get chatContactsWithLocation =>
      chatContacts.where((c) => c.displayLocation != null).toList();

  MessageContactLocation? buildMessageContactLocationSnapshot(
    Contact contact, {
    DateTime? capturedAt,
  }) {
    final snapshotTime = capturedAt ?? DateTime.now();
    final telemetryGps = _getValidGpsOrNull(contact.telemetry?.gpsLocation);
    final telemetryTimestamp = contact.telemetry?.timestamp;

    AdvertLocation? advertLocation;
    for (final point in contact.advertHistory) {
      if (!point.timestamp.isAfter(snapshotTime)) {
        advertLocation = point;
        break;
      }
    }
    advertLocation ??= contact.advertHistory.isNotEmpty
        ? contact.advertHistory.first
        : null;

    if (telemetryGps != null) {
      final shouldUseTelemetry =
          telemetryTimestamp == null ||
          advertLocation == null ||
          !telemetryTimestamp.isBefore(advertLocation.timestamp);
      if (shouldUseTelemetry) {
        return MessageContactLocation(
          location: telemetryGps,
          source: 'telemetry',
          capturedAt: snapshotTime,
          sourceTimestamp: telemetryTimestamp,
        );
      }
    }

    if (advertLocation != null) {
      return MessageContactLocation(
        location: advertLocation.location,
        source: 'advert',
        capturedAt: snapshotTime,
        sourceTimestamp: advertLocation.timestamp,
      );
    }

    return null;
  }

  /// Sort contacts by last seen (most recent first)
  int _sortByLastSeen(Contact a, Contact b) {
    return b.lastSeenTime.compareTo(a.lastSeenTime);
  }

  /// Add or update a contact
  /// Excludes contacts that match the device's own public key
  void addOrUpdateContact(Contact contact, {Uint8List? devicePublicKey}) {
    debugPrint(
      '📝 [ContactsProvider] addOrUpdateContact called: ${contact.advName} (type: ${contact.type.displayName}, key: ${contact.publicKeyHex.substring(0, 8)}...)',
    );

    // Don't add contacts that match our device's public key
    if (devicePublicKey != null && contact.publicKey.matches(devicePublicKey)) {
      debugPrint(
        'ℹ️ [ContactsProvider] Ignoring contact with device\'s own public key: ${contact.advName}',
      );
      return;
    }

    // Check if this is a new contact
    final isNewContact = !_contacts.containsKey(contact.publicKeyHex);
    debugPrint(
      '   isNew: $isNewContact, total contacts before: ${_contacts.length}',
    );

    Contact updatedContact;
    if (isNewContact) {
      // New contact - add initial location to history if available
      updatedContact = contact.copyWith(isNew: true);
      if (contact.advertLocation != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          contact.lastAdvert * 1000,
        );
        updatedContact = updatedContact.addAdvertLocation(
          contact.advertLocation!,
          timestamp,
        );
      }
    } else {
      // Existing contact - preserve history and isNew status
      final existingContact = _contacts[contact.publicKeyHex]!;

      // Start with existing contact
      updatedContact = contact.copyWith(
        isNew: existingContact.isNew,
        advertHistory: existingContact.advertHistory,
      );

      // Add new location to history if location has changed
      if (contact.advertLocation != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          contact.lastAdvert * 1000,
        );
        updatedContact = updatedContact.addAdvertLocation(
          contact.advertLocation!,
          timestamp,
        );
      }
    }

    _contacts[contact.publicKeyHex] = updatedContact;
    _pendingAdverts.remove(contact.publicKeyHex);
    debugPrint(
      '   ✅ Contact added/updated. Total contacts: ${_contacts.length}, channels: ${channels.length}',
    );
    _persistContacts();
    notifyListeners();
    debugPrint('   🔔 notifyListeners() called');
  }

  /// Add multiple contacts
  /// Excludes contacts that match the device's own public key
  void addContacts(List<Contact> contacts, {Uint8List? devicePublicKey}) {
    int excluded = 0;
    for (final contact in contacts) {
      // Don't add contacts that match our device's public key
      if (devicePublicKey != null &&
          contact.publicKey.matches(devicePublicKey)) {
        debugPrint(
          'ℹ️ [ContactsProvider] Ignoring contact with device\'s own public key: ${contact.advName}',
        );
        excluded++;
        continue;
      }
      _contacts[contact.publicKeyHex] = contact;
      _pendingAdverts.remove(contact.publicKeyHex);
    }
    if (excluded > 0) {
      debugPrint(
        'ℹ️ [ContactsProvider] Excluded $excluded contact(s) matching device public key',
      );
    }
    _persistContacts();
    notifyListeners();
  }

  /// Update contact telemetry
  void updateTelemetry(Uint8List publicKeyPrefix, Uint8List lppData) {
    debugPrint('📊 [ContactsProvider] updateTelemetry() called');
    debugPrint(
      '  Public key prefix (hex): ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );
    debugPrint('  LPP data size: ${lppData.length} bytes');

    // Find contact by public key prefix
    final contact = _findContactByPrefix(publicKeyPrefix);
    if (contact == null) {
      debugPrint('  ❌ Contact not found for this prefix');
      return;
    }

    debugPrint('  ✅ Found contact: ${contact.advName}');
    debugPrint('  Old telemetry timestamp: ${contact.telemetry?.timestamp}');

    try {
      // Parse Cayenne LPP data
      var telemetry = CayenneLppParser.parse(lppData);
      debugPrint('  ✅ Parsed new telemetry');
      debugPrint('  New telemetry timestamp: ${telemetry.timestamp}');

      final incomingGps = telemetry.gpsLocation;
      if (_isInvalidTelemetryGps(incomingGps)) {
        // Always sanitize invalid placeholder GPS to null first.
        telemetry = ContactTelemetry(
          gpsLocation: null,
          batteryPercentage: telemetry.batteryPercentage,
          batteryMilliVolts: telemetry.batteryMilliVolts,
          temperature: telemetry.temperature,
          timestamp: telemetry.timestamp,
          humidity: telemetry.humidity,
          pressure: telemetry.pressure,
          extraSensorData: telemetry.extraSensorData,
        );
      }

      // Keep last valid GPS for router/chat/room contacts when current
      // telemetry does not provide a valid GPS fix.
      if (_shouldRetainLastValidGps(contact, telemetry.gpsLocation)) {
        debugPrint(
          '  ⚠️ Retaining last valid GPS. Incoming telemetry GPS is invalid/missing: $incomingGps',
        );
        final previousGps = _getValidGpsOrNull(contact.telemetry?.gpsLocation);
        telemetry = ContactTelemetry(
          gpsLocation: previousGps,
          batteryPercentage: telemetry.batteryPercentage,
          batteryMilliVolts: telemetry.batteryMilliVolts,
          temperature: telemetry.temperature,
          timestamp: telemetry.timestamp,
          humidity: telemetry.humidity,
          pressure: telemetry.pressure,
          extraSensorData: telemetry.extraSensorData,
        );
      }

      // Update contact with new telemetry AND last seen time
      // lastAdvert is Unix timestamp in seconds
      final currentTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000)
          .round();
      debugPrint('  Old lastAdvert: ${contact.lastAdvert}');
      debugPrint('  New lastAdvert: $currentTimestamp');

      final updatedContact = contact.copyWith(
        telemetry: telemetry,
        lastAdvert: currentTimestamp, // Update last seen time
      );
      _contacts[contact.publicKeyHex] = updatedContact;
      debugPrint('  ✅ Updated contact in map (with new lastAdvert)');

      _persistContacts();
      debugPrint('  ✅ Persisted contacts to storage');

      notifyListeners();
      debugPrint('  ✅ Notified listeners - UI should update');
    } catch (e) {
      debugPrint('  ❌ Failed to parse telemetry: $e');
      debugPrint('Failed to parse telemetry: $e');
    }
  }

  bool _isInvalidTelemetryGps(LatLng? location) {
    if (location == null) return false;
    final lat = location.latitude;
    final lon = location.longitude;

    if (!lat.isFinite || !lon.isFinite) return true;

    // Many devices report "0000" placeholder GPS as (0.0, 0.0).
    const epsilon = 1e-7;
    return lat.abs() < epsilon && lon.abs() < epsilon;
  }

  LatLng? _getValidGpsOrNull(LatLng? location) {
    if (location == null || _isInvalidTelemetryGps(location)) {
      return null;
    }
    return location;
  }

  bool _shouldRetainLastValidGps(Contact contact, LatLng? incomingGps) {
    final isSupportedType =
        contact.isChat || contact.isRepeater || contact.isRoom;
    if (!isSupportedType) {
      return false;
    }

    final hasPreviousValidGps =
        _getValidGpsOrNull(contact.telemetry?.gpsLocation) != null;
    if (!hasPreviousValidGps) {
      return false;
    }

    return incomingGps == null;
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

  /// Find contact by first 6-byte public key prefix.
  Contact? findContactByPrefix(Uint8List prefix) {
    return _findContactByPrefix(prefix);
  }

  /// Find contact by 12-hex-char public key prefix.
  Contact? findContactByPrefixHex(String prefixHex) {
    if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(prefixHex)) return null;
    final bytes = Uint8List(6);
    for (var i = 0; i < 6; i++) {
      final start = i * 2;
      bytes[i] = int.parse(prefixHex.substring(start, start + 2), radix: 16);
    }
    return _findContactByPrefix(bytes);
  }

  /// Find contact by public key
  Contact? findContactByKey(Uint8List publicKey) {
    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    return _contacts[keyHex];
  }

  /// Clear a contact's learned path locally so the UI and next send both
  /// prefer flood routing until the radio reports a fresh route.
  void markPathUnhealthy(Uint8List publicKey) {
    final contact = findContactByKey(publicKey);
    if (contact == null || !contact.hasPath) {
      return;
    }

    _contacts[contact.publicKeyHex] = contact.copyWith(
      outPathLen: -1,
      outPath: Uint8List(0),
    );
    _persistContacts();
    notifyListeners();
  }

  /// Add or refresh a pending advert entry from PUSH_CODE_ADVERT (0x80).
  /// Excludes self key and existing contacts.
  void addPendingAdvert(Uint8List publicKey, {Uint8List? devicePublicKey}) {
    if (devicePublicKey != null && publicKey.matches(devicePublicKey)) {
      return;
    }

    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    if (_contacts.containsKey(keyHex)) {
      _pendingAdverts.remove(keyHex);
      return;
    }

    final existing = _pendingAdverts[keyHex];
    final now = DateTime.now();
    if (existing != null) {
      _pendingAdverts[keyHex] = existing.copyWith(receivedAt: now);
    } else {
      _pendingAdverts[keyHex] = PendingAdvert(
        publicKey: Uint8List.fromList(publicKey),
        receivedAt: now,
      );
    }
    notifyListeners();
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
    _pendingAdverts.clear();
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
    _pendingAdverts.remove(publicKeyHex);
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
