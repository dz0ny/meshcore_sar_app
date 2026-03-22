import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../models/message_contact_location.dart';
import '../services/cayenne_lpp_parser.dart';
import '../services/contact_storage_service.dart';
import '../services/profiles_feature_service.dart';
import '../utils/fast_gps_packet.dart';
import '../utils/rssi_location_estimator.dart';
import '../utils/key_comparison.dart';

class PendingAdvert {
  final Uint8List publicKey;
  final DateTime receivedAt;
  final String? advName;
  final int? typeValue;
  final int? flags;
  final int? lastAdvert;
  final int? advLat;
  final int? advLon;
  final int? signedEncodedPathLen;
  final Uint8List? paddedPathBytes;
  final int? rxRssiDbm;
  final int? rxSnrRaw;
  final int? repeaterBatteryMv;
  final int? repeaterQueueLen;
  final int? repeaterLastRssi;
  final int? repeaterLastSnrRaw;
  final int? repeaterUptimeSecs;

  const PendingAdvert({
    required this.publicKey,
    required this.receivedAt,
    this.advName,
    this.typeValue,
    this.flags,
    this.lastAdvert,
    this.advLat,
    this.advLon,
    this.signedEncodedPathLen,
    this.paddedPathBytes,
    this.rxRssiDbm,
    this.rxSnrRaw,
    this.repeaterBatteryMv,
    this.repeaterQueueLen,
    this.repeaterLastRssi,
    this.repeaterLastSnrRaw,
    this.repeaterUptimeSecs,
  });

  String get publicKeyHex =>
      publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');

  String get shortDisplayKey {
    final prefix = publicKey.length >= 6 ? publicKey.sublist(0, 6) : publicKey;
    return prefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  PendingAdvert copyWith({
    Uint8List? publicKey,
    DateTime? receivedAt,
    String? advName,
    int? typeValue,
    int? flags,
    int? lastAdvert,
    int? advLat,
    int? advLon,
    int? signedEncodedPathLen,
    Uint8List? paddedPathBytes,
    int? rxRssiDbm,
    int? rxSnrRaw,
    int? repeaterBatteryMv,
    int? repeaterQueueLen,
    int? repeaterLastRssi,
    int? repeaterLastSnrRaw,
    int? repeaterUptimeSecs,
  }) {
    return PendingAdvert(
      publicKey: publicKey ?? this.publicKey,
      receivedAt: receivedAt ?? this.receivedAt,
      advName: advName ?? this.advName,
      typeValue: typeValue ?? this.typeValue,
      flags: flags ?? this.flags,
      lastAdvert: lastAdvert ?? this.lastAdvert,
      advLat: advLat ?? this.advLat,
      advLon: advLon ?? this.advLon,
      signedEncodedPathLen: signedEncodedPathLen ?? this.signedEncodedPathLen,
      paddedPathBytes: paddedPathBytes ?? this.paddedPathBytes,
      rxRssiDbm: rxRssiDbm ?? this.rxRssiDbm,
      rxSnrRaw: rxSnrRaw ?? this.rxSnrRaw,
      repeaterBatteryMv: repeaterBatteryMv ?? this.repeaterBatteryMv,
      repeaterQueueLen: repeaterQueueLen ?? this.repeaterQueueLen,
      repeaterLastRssi: repeaterLastRssi ?? this.repeaterLastRssi,
      repeaterLastSnrRaw: repeaterLastSnrRaw ?? this.repeaterLastSnrRaw,
      repeaterUptimeSecs: repeaterUptimeSecs ?? this.repeaterUptimeSecs,
    );
  }

  double? get repeaterBatteryPercent {
    if (repeaterBatteryMv == null) return null;
    final voltage = repeaterBatteryMv! / 1000.0;
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  double? get repeaterLastSnr =>
      repeaterLastSnrRaw == null ? null : repeaterLastSnrRaw! / 4.0;

  double? get rxSnr => rxSnrRaw == null ? null : rxSnrRaw! / 4.0;
}

class _RetainedRoute {
  final int signedEncodedPathLen;
  final Uint8List paddedPathBytes;

  const _RetainedRoute({
    required this.signedEncodedPathLen,
    required this.paddedPathBytes,
  });
}

/// Contacts Provider - manages contact list and telemetry
class ContactsProvider with ChangeNotifier {
  static const double _firstHopFallbackOffsetMeters = 100.0;
  static const String autoGroupIdPrefix = 'auto_group_';
  static const String _rawTelemetryHexKey = '__raw_lpp_hex';
  final Map<String, Contact> _contacts = {};
  final List<SavedContactGroup> _savedContactGroups = <SavedContactGroup>[];
  final Map<String, PendingAdvert> _pendingAdverts = {};
  final Map<String, LatLng> _estimatedLocations = {};
  final Map<String, List<RssiObservation>> _rssiObservations = {};
  final Map<String, Contact> _retainedContactsForSync = {};
  final ContactStorageService _storageService = ContactStorageService();
  bool _isInitialized = false;
  bool _isPersisting = false;
  bool _persistRequested = false;
  bool _isPersistingPendingAdverts = false;
  bool _persistPendingAdvertsRequested = false;
  String? _storageNamespace;
  String? _selfPublicKeyHex;
  ContactTelemetry? _selfTelemetry;

  // Add default public channel on initialization
  ContactsProvider()
    : _storageNamespace = ProfileStorageScope.effectiveNamespace {
    _ensurePublicChannelExists();
  }

  bool get isInitialized => _isInitialized;
  String? get storageNamespace => _storageNamespace;

  /// Initialize and load persisted contacts at app startup
  /// This loads contacts without filtering, allowing offline viewing
  Future<void> initializeEarly() async {
    if (_isInitialized) return;

    await _loadFromStorage();
  }

  Future<void> reloadFromStorage({
    String? namespace,
    Uint8List? devicePublicKey,
  }) async {
    _storageNamespace = namespace;
    _setSelfDevicePublicKey(devicePublicKey);
    await _loadFromStorage(force: true, devicePublicKey: devicePublicKey);
  }

  Future<void> persistNow() async {
    await _storageService.saveContacts(
      _contactsForStorage(),
      namespace: _storageNamespace,
    );
    await _storageService.saveContactGroups(
      _savedContactGroups,
      namespace: _storageNamespace,
    );
    await _storageService.savePendingAdverts(
      _pendingAdverts.values.map(_pendingAdvertToJson).toList(),
      namespace: _storageNamespace,
    );
  }

  Future<void> cloneCurrentStorageTo(String? namespace) async {
    await _storageService.saveContacts(
      _contactsForStorage(),
      namespace: namespace,
    );
    await _storageService.saveContactGroups(
      _savedContactGroups,
      namespace: namespace,
    );
    await _storageService.savePendingAdverts(
      _pendingAdverts.values.map(_pendingAdvertToJson).toList(),
      namespace: namespace,
    );
  }

  Future<void> _loadFromStorage({
    bool force = false,
    Uint8List? devicePublicKey,
  }) async {
    if (_isInitialized && !force) return;

    try {
      _resetInMemoryState();
      debugPrint(
        '📦 [ContactsProvider] Early loading persisted contacts (no filtering)...',
      );
      final storedContacts = await _storageService.loadContacts(
        namespace: _storageNamespace,
      );
      final storedGroups = await _storageService.loadContactGroups(
        namespace: _storageNamespace,
      );
      final storedPendingAdverts = await _storageService.loadPendingAdverts(
        namespace: _storageNamespace,
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
      _savedContactGroups
        ..clear()
        ..addAll(storedGroups);
      _restorePendingAdverts(
        storedPendingAdverts,
        devicePublicKey: devicePublicKey,
      );
      debugPrint(
        '✅ [ContactsProvider] Early loaded ${storedContacts.length} persisted contacts and ${storedGroups.length} groups',
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
    _setSelfDevicePublicKey(devicePublicKey);
    if (_isInitialized) {
      // If already initialized (from early load), just filter out self-contact
      if (devicePublicKey != null) {
        _removeSelfContact(devicePublicKey);
      }
      return;
    }

    await _loadFromStorage(force: true, devicePublicKey: devicePublicKey);
    if (devicePublicKey != null) {
      _removeSelfContact(devicePublicKey);
    }
  }

  /// Clear runtime contact state before a live device contact sync begins.
  ///
  /// This intentionally does not touch persisted storage. It keeps any saved
  /// contact groups for the active profile, but removes stale in-memory device
  /// contacts and discovery state so a newly connected device starts from an
  /// empty list while sync is in progress.
  Future<void> prepareForDeviceContactSync({Uint8List? devicePublicKey}) async {
    _setSelfDevicePublicKey(devicePublicKey);
    if (!_isInitialized) {
      final storedGroups = await _storageService.loadContactGroups(
        namespace: _storageNamespace,
      );
      _savedContactGroups
        ..clear()
        ..addAll(storedGroups);
      _isInitialized = true;
    }

    debugPrint(
      '🧹 [ContactsProvider] Clearing runtime contacts before device sync',
    );
    _retainedContactsForSync
      ..clear()
      ..addEntries(
        _contactsForStorage().map(
          (contact) => MapEntry(contact.publicKeyHex, contact),
        ),
      );
    _contacts.clear();
    _pendingAdverts.clear();
    _estimatedLocations.clear();
    _rssiObservations.clear();
    _ensurePublicChannelExists();
    notifyListeners();
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

  /// Persist contacts to storage (async, non-blocking, coalescing).
  Future<void> _persistContacts() async {
    _persistRequested = true;
    if (_isPersisting) return;
    _isPersisting = true;
    try {
      while (_persistRequested) {
        _persistRequested = false;
        await _storageService.saveContacts(
          _contactsForStorage(),
          namespace: _storageNamespace,
        );
      }
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error persisting contacts: $e');
    } finally {
      _isPersisting = false;
    }
  }

  Future<void> _persistPendingAdverts() async {
    _persistPendingAdvertsRequested = true;
    if (_isPersistingPendingAdverts) return;
    _isPersistingPendingAdverts = true;
    try {
      while (_persistPendingAdvertsRequested) {
        _persistPendingAdvertsRequested = false;
        await _storageService.savePendingAdverts(
          _pendingAdverts.values.map(_pendingAdvertToJson).toList(),
          namespace: _storageNamespace,
        );
      }
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error persisting pending adverts: $e');
    } finally {
      _isPersistingPendingAdverts = false;
    }
  }

  List<Contact> get contacts => _contacts.values.toList();
  ContactTelemetry? get selfTelemetry => _selfTelemetry;
  List<Contact> get favouriteContacts =>
      _contacts.values.where((c) => c.isFavourite).toList();
  List<SavedContactGroup> get savedContactGroups =>
      List<SavedContactGroup>.from(_savedContactGroups)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<PendingAdvert> get pendingAdverts =>
      _pendingAdverts.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  PendingAdvert? pendingAdvertByKey(Uint8List publicKey) {
    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    return _pendingAdverts[keyHex];
  }

  bool shouldEnrichPendingAdvert(Uint8List publicKey) {
    final advert = pendingAdvertByKey(publicKey);
    if (advert == null) {
      return false;
    }

    final hasName = advert.advName?.trim().isNotEmpty ?? false;
    final hasType = advert.typeValue != null && advert.typeValue != 0;
    final hasLocation =
        advert.advLat != null &&
        advert.advLon != null &&
        (advert.advLat != 0 || advert.advLon != 0);
    return !(hasName && hasType && hasLocation);
  }

  List<SavedContactGroup> savedGroupsForSection(String sectionKey) {
    return savedContactGroups
        .where((group) => group.sectionKey == sectionKey)
        .toList();
  }

  bool hasSavedGroupForFilter(String sectionKey, String query) {
    final normalizedQuery = _normalizeGroupQuery(query);
    if (normalizedQuery.isEmpty) {
      return false;
    }

    return _savedContactGroups.any(
      (group) =>
          group.sectionKey == sectionKey &&
          _normalizeGroupQuery(group.query) == normalizedQuery,
    );
  }

  Future<void> addSavedGroupForFilter(
    String sectionKey,
    String query, {
    String? label,
    List<String>? matchPrefixes,
    bool isAutoGroup = false,
  }) async {
    final normalizedQuery = _normalizeGroupQuery(query);
    if (normalizedQuery.isEmpty ||
        hasSavedGroupForFilter(sectionKey, normalizedQuery)) {
      return;
    }

    _savedContactGroups.add(
      SavedContactGroup(
        id: '${sectionKey}_${DateTime.now().microsecondsSinceEpoch}',
        sectionKey: sectionKey,
        label: (label ?? query).trim(),
        query: query.trim(),
        createdAt: DateTime.now(),
        matchPrefixes: matchPrefixes,
        isAutoGroup: isAutoGroup,
      ),
    );

    await _persistSavedGroups();
    notifyListeners();
  }

  Future<void> removeSavedGroupById(String id) async {
    final beforeCount = _savedContactGroups.length;
    _savedContactGroups.removeWhere((group) => group.id == id);
    if (_savedContactGroups.length == beforeCount) {
      return;
    }

    await _persistSavedGroups();
    notifyListeners();
  }

  Future<void> removeSavedGroupForFilter(
    String sectionKey,
    String query,
  ) async {
    final normalizedQuery = _normalizeGroupQuery(query);
    final beforeCount = _savedContactGroups.length;
    _savedContactGroups.removeWhere(
      (group) =>
          group.sectionKey == sectionKey &&
          _normalizeGroupQuery(group.query) == normalizedQuery,
    );
    if (_savedContactGroups.length == beforeCount) {
      return;
    }

    await _persistSavedGroups();
    notifyListeners();
  }

  Future<void> replaceAutoGroupsForSection(
    String sectionKey,
    List<SavedContactGroup> groups,
  ) async {
    _savedContactGroups.removeWhere(
      (group) => group.sectionKey == sectionKey && group.isAutoGroup,
    );
    _savedContactGroups.addAll(groups);
    await _persistSavedGroups();
    notifyListeners();
  }

  Future<void> _persistSavedGroups() async {
    try {
      await _storageService.saveContactGroups(
        _savedContactGroups,
        namespace: _storageNamespace,
      );
    } catch (e) {
      debugPrint('❌ [ContactsProvider] Error persisting contact groups: $e');
    }
  }

  String _normalizeGroupQuery(String query) => query.trim().toLowerCase();

  List<Contact> get chatContacts =>
      contacts.where((c) => c.isChat).toList()..sort(_sortByLastSeen);

  List<Contact> get repeaters =>
      contacts.where((c) => c.isRepeater).toList()..sort(_sortByLastSeen);

  List<Contact> get sensorContacts =>
      contacts.where((c) => c.isSensor).toList()..sort(_sortByLastSeen);

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

  /// All estimated locations (for passing to map marker service).
  Map<String, LatLng> get estimatedLocations =>
      Map.unmodifiable(_estimatedLocations);

  /// Get estimated location for a contact (RSSI-based, near last-hop repeater).
  LatLng? estimatedLocationFor(String publicKeyHex) =>
      _estimatedLocations[publicKeyHex];

  /// Set an estimated location for a contact that has no GPS.
  void setEstimatedLocation(String publicKeyHex, LatLng location) {
    _estimatedLocations[publicKeyHex] = location;
    notifyListeners();
  }

  /// Record an RSSI observation and re-trilaterate the contact's position.
  ///
  /// Keeps up to 5 observations per unique repeater (latest wins).
  /// With multiple repeaters, trilateration produces a better estimate.
  void addRssiObservation({
    required String contactPublicKeyHex,
    required List<int> contactPublicKey,
    required RssiObservation observation,
  }) {
    final observations = _rssiObservations.putIfAbsent(
      contactPublicKeyHex,
      () => [],
    );

    // Replace existing observation from the same repeater, or add new
    final repeaterKey =
        '${observation.repeaterLocation.latitude},${observation.repeaterLocation.longitude}';
    observations.removeWhere(
      (o) =>
          '${o.repeaterLocation.latitude},${o.repeaterLocation.longitude}' ==
          repeaterKey,
    );
    observations.add(observation);

    // Keep at most 8 observations (most recent per repeater)
    if (observations.length > 8) {
      observations.sort((a, b) => b.observedAt.compareTo(a.observedAt));
      observations.removeRange(8, observations.length);
    }

    final estimated = RssiLocationEstimator.trilaterate(
      observations: observations,
      contactPublicKey: contactPublicKey,
    );
    if (estimated != null) {
      _estimatedLocations[contactPublicKeyHex] = estimated;
      notifyListeners();
    }
  }

  /// Effective location: own GPS/advert > estimated from RSSI.
  LatLng? effectiveLocationFor(Contact contact) {
    return contact.displayLocation ?? _estimatedLocations[contact.publicKeyHex];
  }

  /// Get contacts with location (for map display)
  /// Includes contacts with estimated locations from RSSI.
  List<Contact> get contactsWithLocation =>
      contacts.where((c) => effectiveLocationFor(c) != null).toList();

  /// Get chat contacts with location (team members on map)
  List<Contact> get chatContactsWithLocation =>
      chatContacts.where((c) => effectiveLocationFor(c) != null).toList();

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
    final existingContact =
        _contacts[contact.publicKeyHex] ??
        _retainedContactsForSync[contact.publicKeyHex];
    final isNewContact = existingContact == null;
    debugPrint(
      '   isNew: $isNewContact, total contacts before: ${_contacts.length}',
    );

    final updatedContact = _mergeIncomingContact(
      incomingContact: contact,
      existingContact: existingContact,
    );

    _contacts[contact.publicKeyHex] = updatedContact;
    _retainedContactsForSync.remove(contact.publicKeyHex);
    // Keep repeaters and sensors in pending adverts so they remain visible
    // in the discovery list (with a checkmark). Remove others.
    if (contact.type != ContactType.repeater &&
        contact.type != ContactType.sensor) {
      _pendingAdverts.remove(contact.publicKeyHex);
    }
    debugPrint(
      '   ✅ Contact added/updated. Total contacts: ${_contacts.length}, channels: ${channels.length}',
    );
    _persistContacts();
    _persistPendingAdverts();
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
      final existingContact =
          _contacts[contact.publicKeyHex] ??
          _retainedContactsForSync[contact.publicKeyHex];
      _contacts[contact.publicKeyHex] = _mergeIncomingContact(
        incomingContact: contact,
        existingContact: existingContact,
      );
      _retainedContactsForSync.remove(contact.publicKeyHex);
      if (contact.type != ContactType.repeater &&
          contact.type != ContactType.sensor) {
        _pendingAdverts.remove(contact.publicKeyHex);
      }
    }
    if (excluded > 0) {
      debugPrint(
        'ℹ️ [ContactsProvider] Excluded $excluded contact(s) matching device public key',
      );
    }
    _persistContacts();
    _persistPendingAdverts();
    notifyListeners();
  }

  Contact _mergeIncomingContact({
    required Contact incomingContact,
    Contact? existingContact,
  }) {
    final retainedRoute = _retainedRouteForContact(
      keyHex: incomingContact.publicKeyHex,
      incomingContact: incomingContact,
      existingContact: existingContact,
    );
    final mergedTelemetry = _mergeTelemetryForContact(
      existingTelemetry: existingContact?.telemetry,
      incomingTelemetry: incomingContact.telemetry,
    );
    final inferredFallbackLocation = _inferFirstHopFallbackLocation(
      incomingContact: incomingContact,
      existingContact: existingContact,
      retainedRoute: retainedRoute,
      mergedTelemetry: mergedTelemetry,
    );
    final inferredFallbackAdvLat = inferredFallbackLocation != null
        ? _coordinateToAdvertMicrodegrees(inferredFallbackLocation.latitude)
        : null;
    final inferredFallbackAdvLon = inferredFallbackLocation != null
        ? _coordinateToAdvertMicrodegrees(inferredFallbackLocation.longitude)
        : null;

    if (existingContact == null) {
      var newContact = incomingContact.copyWith(
        isNew: true,
        telemetry: mergedTelemetry,
        outPathLen:
            retainedRoute?.signedEncodedPathLen ?? incomingContact.outPathLen,
        outPath: retainedRoute?.paddedPathBytes ?? incomingContact.outPath,
        advLat: incomingContact.advertLocation != null
            ? incomingContact.advLat
            : inferredFallbackAdvLat ?? incomingContact.advLat,
        advLon: incomingContact.advertLocation != null
            ? incomingContact.advLon
            : inferredFallbackAdvLon ?? incomingContact.advLon,
      );
      if (incomingContact.advertLocation != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          incomingContact.lastAdvert * 1000,
        );
        newContact = newContact.addAdvertLocation(
          incomingContact.advertLocation!,
          timestamp,
        );
      }
      return newContact;
    }

    final incomingAdvertLocation = incomingContact.advertLocation;
    final existingAdvertLocation = existingContact.advertLocation;

    var updatedContact = incomingContact.copyWith(
      isNew: false,
      nameOverride: existingContact.nameOverride,
      advertHistory: existingContact.advertHistory,
      telemetry: mergedTelemetry,
      outPathLen:
          retainedRoute?.signedEncodedPathLen ?? incomingContact.outPathLen,
      outPath: retainedRoute?.paddedPathBytes ?? incomingContact.outPath,
      advLat: incomingAdvertLocation != null
          ? incomingContact.advLat
          : existingAdvertLocation != null
          ? existingContact.advLat
          : inferredFallbackAdvLat ?? incomingContact.advLat,
      advLon: incomingAdvertLocation != null
          ? incomingContact.advLon
          : existingAdvertLocation != null
          ? existingContact.advLon
          : inferredFallbackAdvLon ?? incomingContact.advLon,
    );

    if (incomingAdvertLocation != null) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        incomingContact.lastAdvert * 1000,
      );
      updatedContact = updatedContact.addAdvertLocation(
        incomingAdvertLocation,
        timestamp,
      );
    }

    return updatedContact;
  }

  _RetainedRoute? _retainedRouteForContact({
    required String keyHex,
    required Contact incomingContact,
    required Contact? existingContact,
  }) {
    if (incomingContact.routeHasPath) {
      return null;
    }

    final pendingAdvert = _pendingAdverts[keyHex];
    final pendingPathBytes = pendingAdvert?.paddedPathBytes;
    final pendingPathLen = pendingAdvert?.signedEncodedPathLen;
    if (pendingPathLen != null &&
        pendingPathBytes != null &&
        pendingPathBytes.isNotEmpty) {
      return _RetainedRoute(
        signedEncodedPathLen: pendingPathLen,
        paddedPathBytes: Uint8List.fromList(pendingPathBytes),
      );
    }

    if (existingContact != null && existingContact.routeHasPath) {
      return _RetainedRoute(
        signedEncodedPathLen: existingContact.outPathLen,
        paddedPathBytes: Uint8List.fromList(existingContact.outPath),
      );
    }

    return null;
  }

  LatLng? _inferFirstHopFallbackLocation({
    required Contact incomingContact,
    required Contact? existingContact,
    required _RetainedRoute? retainedRoute,
    required ContactTelemetry? mergedTelemetry,
  }) {
    if (_getValidGpsOrNull(mergedTelemetry?.gpsLocation) != null) {
      return null;
    }
    if (incomingContact.advertLocation != null ||
        existingContact?.advertLocation != null) {
      return null;
    }

    final routeBytes =
        retainedRoute?.paddedPathBytes ??
        (incomingContact.routeHasPath
            ? incomingContact.routePathBytes
            : existingContact?.routeHasPath == true
            ? existingContact!.routePathBytes
            : null);
    final routeHashSize = retainedRoute != null
        ? ((ContactRouteCodec.toUnsignedDescriptor(
                    retainedRoute.signedEncodedPathLen,
                  ) >>
                  6) +
              1)
        : incomingContact.routeHasPath
        ? incomingContact.routeHashSize
        : existingContact?.routeHasPath == true
        ? existingContact!.routeHashSize
        : 0;
    if (routeBytes == null ||
        routeHashSize <= 0 ||
        routeBytes.length < routeHashSize) {
      return null;
    }

    final lastHopHex = routeBytes
        .sublist(routeBytes.length - routeHashSize)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final repeaterCandidates = _contacts.values.where((candidate) {
      if (!candidate.isRepeater ||
          candidate.publicKeyHex == incomingContact.publicKeyHex) {
        return false;
      }
      final location = candidate.displayLocation;
      return location != null && candidate.publicKeyHex.startsWith(lastHopHex);
    }).toList()..sort((a, b) => b.lastAdvert.compareTo(a.lastAdvert));
    if (repeaterCandidates.isEmpty) {
      return null;
    }

    final repeaterLocation = repeaterCandidates.first.displayLocation;
    if (repeaterLocation == null) {
      return null;
    }

    final bearingDegrees = _stableFallbackBearingDegrees(incomingContact);
    return _offsetFromLocation(
      repeaterLocation,
      distanceMeters: _firstHopFallbackOffsetMeters,
      bearingDegrees: bearingDegrees,
    );
  }

  double _stableFallbackBearingDegrees(Contact contact) {
    if (contact.publicKey.length < 2) {
      return 90.0;
    }
    final seed = (contact.publicKey[0] << 8) | contact.publicKey[1];
    return (seed % 360).toDouble();
  }

  LatLng _offsetFromLocation(
    LatLng origin, {
    required double distanceMeters,
    required double bearingDegrees,
  }) {
    const earthRadiusMeters = 6371000.0;
    final angularDistance = distanceMeters / earthRadiusMeters;
    final bearingRadians = bearingDegrees * 3.1415926535897932 / 180.0;
    final lat1 = origin.latitude * 3.1415926535897932 / 180.0;
    final lon1 = origin.longitude * 3.1415926535897932 / 180.0;

    final sinLat1 = sin(lat1);
    final cosLat1 = cos(lat1);
    final sinAngularDistance = sin(angularDistance);
    final cosAngularDistance = cos(angularDistance);

    final lat2 = asin(
      sinLat1 * cosAngularDistance +
          cosLat1 * sinAngularDistance * cos(bearingRadians),
    );
    final lon2 =
        lon1 +
        atan2(
          sin(bearingRadians) * sinAngularDistance * cosLat1,
          cosAngularDistance - sinLat1 * sin(lat2),
        );

    return LatLng(
      lat2 * 180.0 / 3.1415926535897932,
      ((lon2 * 180.0 / 3.1415926535897932 + 540.0) % 360.0) - 180.0,
    );
  }

  /// Update contact telemetry
  // Dedup: track last telemetry data hash per contact to avoid processing
  // the same payload twice (0x8B + 0x8C can both fire for the same data).
  final Map<String, (int, DateTime)> _lastTelemetryHash = {};

  void updateTelemetry(Uint8List publicKeyPrefix, Uint8List lppData) {
    debugPrint('📊 [ContactsProvider] updateTelemetry() called');
    debugPrint(
      '  Public key prefix (hex): ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );
    debugPrint('  LPP data size: ${lppData.length} bytes');

    // Deduplicate: same data for same contact within 2 seconds = skip
    final prefixHex = publicKeyPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final dataHash = lppData.fold<int>(0, (h, b) => h * 31 + b);
    final now = DateTime.now();
    final last = _lastTelemetryHash[prefixHex];
    if (last != null &&
        last.$1 == dataHash &&
        now.difference(last.$2).inSeconds < 2) {
      debugPrint('  ⏭️ Duplicate telemetry payload, skipping');
      return;
    }
    _lastTelemetryHash[prefixHex] = (dataHash, now);

    // Find contact by public key prefix
    final contact = _findContactByPrefix(publicKeyPrefix);
    final isSelfTelemetry =
        contact == null && _matchesSelfPrefix(publicKeyPrefix);
    if (contact == null && !isSelfTelemetry) {
      debugPrint('  ❌ Contact not found for this prefix');
      return;
    }

    if (isSelfTelemetry) {
      debugPrint('  ✅ Matched self telemetry response');
      debugPrint(
        '  Old self telemetry timestamp: ${_selfTelemetry?.timestamp}',
      );
    } else {
      debugPrint('  ✅ Found contact: ${contact!.advName}');
      debugPrint('  Old telemetry timestamp: ${contact.telemetry?.timestamp}');
    }

    try {
      // Parse Cayenne LPP data
      var telemetry = _withRawTelemetryHex(
        CayenneLppParser.parse(lppData),
        lppData,
      );
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

      final previousTelemetry = isSelfTelemetry
          ? _selfTelemetry
          : contact!.telemetry;

      final mergedTelemetry = _mergeTelemetryForContact(
        existingTelemetry: previousTelemetry,
        incomingTelemetry: telemetry,
      );
      if (mergedTelemetry != null) {
        if (_shouldRetainLastValidGps(
          previousTelemetry,
          telemetry.gpsLocation,
        )) {
          debugPrint(
            '  ⚠️ Incoming telemetry GPS is invalid/missing; keeping last known contact location as fallback: $incomingGps',
          );
        }
        telemetry = ContactTelemetry(
          gpsLocation: telemetry.gpsLocation,
          batteryPercentage: mergedTelemetry.batteryPercentage,
          batteryMilliVolts: mergedTelemetry.batteryMilliVolts,
          temperature: mergedTelemetry.temperature,
          timestamp: mergedTelemetry.timestamp,
          humidity: mergedTelemetry.humidity,
          pressure: mergedTelemetry.pressure,
          extraSensorData: mergedTelemetry.extraSensorData,
        );
      }

      if (isSelfTelemetry) {
        _selfTelemetry = telemetry;
        notifyListeners();
        debugPrint('  ✅ Updated self telemetry');
        return;
      }

      final resolvedContact = contact!;

      // Update contact with new telemetry AND last seen time
      // lastAdvert is Unix timestamp in seconds
      final currentTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000)
          .round();
      debugPrint('  Old lastAdvert: ${resolvedContact.lastAdvert}');
      debugPrint('  New lastAdvert: $currentTimestamp');

      final persistedGps = _getValidGpsOrNull(telemetry.gpsLocation);
      final updatedContact = resolvedContact.copyWith(
        telemetry: telemetry,
        lastAdvert: currentTimestamp, // Update last seen time
        advLat: persistedGps != null
            ? _coordinateToAdvertMicrodegrees(persistedGps.latitude)
            : resolvedContact.advLat,
        advLon: persistedGps != null
            ? _coordinateToAdvertMicrodegrees(persistedGps.longitude)
            : resolvedContact.advLon,
      );
      _contacts[resolvedContact.publicKeyHex] = updatedContact;
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

  void updateFastGps(Uint8List publicKeyPrefix, FastGpsPacket packet) {
    final contact = _findContactByPrefix(publicKeyPrefix);
    if (contact == null) {
      debugPrint(
        '⚠️ [ContactsProvider] Fast GPS sender not found: ${packet.senderKey6}',
      );
      return;
    }

    final updatedTelemetry = _mergeTelemetryForContact(
      existingTelemetry: contact.telemetry,
      incomingTelemetry: ContactTelemetry(
        gpsLocation: LatLng(packet.latitude, packet.longitude),
        batteryPercentage: null,
        batteryMilliVolts: null,
        temperature: null,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          packet.timestampSeconds * 1000,
        ),
        humidity: null,
        pressure: null,
        extraSensorData: null,
      ),
    );

    final updatedContact = contact.copyWith(
      telemetry: updatedTelemetry,
      lastAdvert: packet.timestampSeconds,
      advLat: _coordinateToAdvertMicrodegrees(packet.latitude),
      advLon: _coordinateToAdvertMicrodegrees(packet.longitude),
    );
    _contacts[contact.publicKeyHex] = updatedContact;
    _persistContacts();
    notifyListeners();
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

  bool _shouldRetainLastValidGps(
    ContactTelemetry? existingTelemetry,
    LatLng? incomingGps,
  ) {
    final hasPreviousValidGps =
        _getValidGpsOrNull(existingTelemetry?.gpsLocation) != null;
    if (!hasPreviousValidGps) {
      return false;
    }

    return incomingGps == null;
  }

  ContactTelemetry? _mergeTelemetryForContact({
    ContactTelemetry? existingTelemetry,
    ContactTelemetry? incomingTelemetry,
  }) {
    if (incomingTelemetry == null) {
      return existingTelemetry;
    }

    // Telemetry packets and contact refreshes are often sparse. Preserve the
    // last known reading for any field that is omitted in the incoming update.
    final incomingGps = _getValidGpsOrNull(incomingTelemetry.gpsLocation);
    final previousGps = _getValidGpsOrNull(existingTelemetry?.gpsLocation);
    final mergedExtraSensorData = _mergeExtraSensorData(
      existingTelemetry?.extraSensorData,
      incomingTelemetry.extraSensorData,
    );

    return ContactTelemetry(
      gpsLocation: incomingGps ?? previousGps,
      batteryPercentage:
          incomingTelemetry.batteryPercentage ??
          existingTelemetry?.batteryPercentage,
      batteryMilliVolts:
          incomingTelemetry.batteryMilliVolts ??
          existingTelemetry?.batteryMilliVolts,
      temperature:
          incomingTelemetry.temperature ?? existingTelemetry?.temperature,
      timestamp: incomingTelemetry.timestamp,
      humidity: incomingTelemetry.humidity ?? existingTelemetry?.humidity,
      pressure: incomingTelemetry.pressure ?? existingTelemetry?.pressure,
      extraSensorData: mergedExtraSensorData.isEmpty
          ? null
          : mergedExtraSensorData,
    );
  }

  ContactTelemetry _withRawTelemetryHex(
    ContactTelemetry telemetry,
    Uint8List lppData,
  ) {
    final extraSensorData = <String, dynamic>{...?telemetry.extraSensorData};
    extraSensorData[_rawTelemetryHexKey] = _bytesToHex(lppData);
    return ContactTelemetry(
      gpsLocation: telemetry.gpsLocation,
      batteryPercentage: telemetry.batteryPercentage,
      batteryMilliVolts: telemetry.batteryMilliVolts,
      temperature: telemetry.temperature,
      timestamp: telemetry.timestamp,
      humidity: telemetry.humidity,
      pressure: telemetry.pressure,
      extraSensorData: extraSensorData,
    );
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  Map<String, dynamic> _mergeExtraSensorData(
    Map<String, dynamic>? existingExtraSensorData,
    Map<String, dynamic>? incomingExtraSensorData,
  ) {
    final merged = <String, dynamic>{...?existingExtraSensorData};
    if (incomingExtraSensorData == null || incomingExtraSensorData.isEmpty) {
      return merged;
    }

    final incomingMetricFamilies = incomingExtraSensorData.keys
        .map(_telemetryMetricFamilyForKey)
        .whereType<String>()
        .toSet();
    if (incomingMetricFamilies.isNotEmpty) {
      merged.removeWhere((key, _) {
        final family = _telemetryMetricFamilyForKey(key);
        return family != null && incomingMetricFamilies.contains(family);
      });
    }

    merged.addAll(incomingExtraSensorData);
    return merged;
  }

  String? _telemetryMetricFamilyForKey(String key) {
    const sourcePrefix = '__source_channel:';
    if (key.startsWith(sourcePrefix)) {
      return key.substring(sourcePrefix.length);
    }

    final separatorIndex = key.lastIndexOf('_');
    if (separatorIndex <= 0 || separatorIndex == key.length - 1) {
      return key;
    }

    final suffix = key.substring(separatorIndex + 1);
    if (int.tryParse(suffix) == null) {
      return key;
    }

    return key.substring(0, separatorIndex);
  }

  int _coordinateToAdvertMicrodegrees(double coordinate) {
    return (coordinate * 1e6).round();
  }

  /// Find contact by public key prefix (6 bytes)
  Contact? _findContactByPrefix(Uint8List prefix) {
    if (prefix.isEmpty) return null;

    final takeLen = prefix.length < 6 ? prefix.length : 6;
    final prefixHex = prefix
        .sublist(0, takeLen)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    for (final contact in _contacts.values) {
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

  void _setSelfDevicePublicKey(Uint8List? devicePublicKey) {
    final nextKeyHex = _publicKeyHexOrNull(devicePublicKey);
    if (_selfPublicKeyHex != nextKeyHex) {
      _selfTelemetry = null;
    }
    _selfPublicKeyHex = nextKeyHex;
  }

  String? _publicKeyHexOrNull(Uint8List? publicKey) {
    if (publicKey == null || publicKey.isEmpty) {
      return null;
    }

    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  bool _matchesSelfPrefix(Uint8List prefix) {
    final selfKeyHex = _selfPublicKeyHex;
    if (selfKeyHex == null || prefix.isEmpty) {
      return false;
    }

    final takeLen = prefix.length < 6 ? prefix.length : 6;
    final prefixHex = prefix
        .sublist(0, takeLen)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    return selfKeyHex.startsWith(prefixHex);
  }

  /// Clear a contact's learned path locally so the UI and next send both
  /// prefer flood routing until the radio reports a fresh route.
  void markPathUnhealthy(Uint8List publicKey) {
    final contact = findContactByKey(publicKey);
    if (contact == null || !contact.routeHasPath) {
      return;
    }

    _contacts[contact.publicKeyHex] = contact.copyWith(
      outPathLen: -1,
      outPath: Uint8List(0),
    );
    _persistContacts();
    notifyListeners();
  }

  void setContactRouteLocal(
    Uint8List publicKey, {
    required int signedEncodedPathLen,
    required Uint8List paddedPathBytes,
    LatLng? inferredFallbackLocation,
  }) {
    final contact = findContactByKey(publicKey);
    if (contact == null) {
      return;
    }

    var updatedContact = contact.copyWith(
      outPathLen: signedEncodedPathLen,
      outPath: Uint8List.fromList(paddedPathBytes),
    );
    if (inferredFallbackLocation != null) {
      updatedContact = updatedContact
          .copyWith(
            advLat: _coordinateToAdvertMicrodegrees(
              inferredFallbackLocation.latitude,
            ),
            advLon: _coordinateToAdvertMicrodegrees(
              inferredFallbackLocation.longitude,
            ),
          )
          .addAdvertLocation(inferredFallbackLocation, DateTime.now());
    }
    _contacts[contact.publicKeyHex] = updatedContact;
    _persistContacts();
    notifyListeners();
  }

  void retainReceivedRoute(
    Uint8List publicKey, {
    required int signedEncodedPathLen,
    required Uint8List paddedPathBytes,
    Uint8List? devicePublicKey,
  }) {
    if (devicePublicKey != null && publicKey.matches(devicePublicKey)) {
      return;
    }

    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final contact = _contacts[keyHex];
    if (contact != null) {
      _contacts[keyHex] = contact.copyWith(
        outPathLen: signedEncodedPathLen,
        outPath: Uint8List.fromList(paddedPathBytes),
      );
      _persistContacts();
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final existing = _pendingAdverts[keyHex];
    _pendingAdverts[keyHex] =
        (existing ??
                PendingAdvert(
                  publicKey: Uint8List.fromList(publicKey),
                  receivedAt: now,
                ))
            .copyWith(
              receivedAt: now,
              signedEncodedPathLen: signedEncodedPathLen,
              paddedPathBytes: Uint8List.fromList(paddedPathBytes),
            );
    notifyListeners();
  }

  void resetContactRouteLocal(Uint8List publicKey) {
    final contact = findContactByKey(publicKey);
    if (contact == null) {
      return;
    }

    _contacts[contact.publicKeyHex] = contact.copyWith(
      outPathLen: -1,
      outPath: Uint8List(0),
    );
    _persistContacts();
    notifyListeners();
  }

  void setContactNameOverride(String publicKeyHex, String? overrideName) {
    final contact = _contacts[publicKeyHex];
    if (contact == null) {
      return;
    }

    final normalizedOverride = overrideName?.trim();
    final nextOverride =
        (normalizedOverride == null || normalizedOverride.isEmpty)
        ? null
        : normalizedOverride;
    if (contact.nameOverride == nextOverride) {
      return;
    }

    _contacts[publicKeyHex] = contact.copyWith(nameOverride: nextOverride);
    _persistContacts();
    notifyListeners();
  }

  /// Add or refresh a pending advert entry from PUSH_CODE_ADVERT (0x80).
  /// Excludes only self key; known contacts still keep a discovery entry.
  bool addPendingAdvert(Uint8List publicKey, {Uint8List? devicePublicKey}) {
    if (devicePublicKey != null && publicKey.matches(devicePublicKey)) {
      return false;
    }

    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final existing = _pendingAdverts[keyHex];
    final now = DateTime.now();
    if (existing != null) {
      _pendingAdverts[keyHex] = existing.copyWith(receivedAt: now);
      _persistPendingAdverts();
      notifyListeners();
      return false;
    } else {
      _pendingAdverts[keyHex] = PendingAdvert(
        publicKey: Uint8List.fromList(publicKey),
        receivedAt: now,
      );
      _persistPendingAdverts();
      notifyListeners();
      return true;
    }
  }

  bool addOrUpdatePendingAdvertContact(
    Contact contact, {
    Uint8List? devicePublicKey,
  }) {
    if (devicePublicKey != null && contact.publicKey.matches(devicePublicKey)) {
      return false;
    }

    final keyHex = contact.publicKeyHex;
    final route = ContactRouteCodec.fromContact(contact);
    final existing = _pendingAdverts[keyHex];
    final now = DateTime.now();
    final updated =
        (existing ??
                PendingAdvert(
                  publicKey: Uint8List.fromList(contact.publicKey),
                  receivedAt: now,
                ))
            .copyWith(
              receivedAt: now,
              advName: contact.advName.trim().isEmpty ? null : contact.advName,
              typeValue: contact.type.value,
              flags: contact.flags,
              lastAdvert: contact.lastAdvert,
              advLat: contact.advLat,
              advLon: contact.advLon,
              signedEncodedPathLen:
                  route?.signedEncodedPathLen ?? existing?.signedEncodedPathLen,
              paddedPathBytes: route?.paddedPathBytes == null
                  ? existing?.paddedPathBytes
                  : Uint8List.fromList(route!.paddedPathBytes),
            );

    _pendingAdverts[keyHex] = updated;
    _persistPendingAdverts();
    notifyListeners();
    return existing == null;
  }

  bool addOrUpdatePendingAdvertMetadata({
    required Uint8List publicKey,
    required int typeValue,
    Uint8List? devicePublicKey,
    int? flags,
    String? advName,
    int? lastAdvert,
    int? advLat,
    int? advLon,
    int? signedEncodedPathLen,
    Uint8List? paddedPathBytes,
    int? rxRssiDbm,
    int? rxSnrRaw,
    DateTime? receivedAt,
  }) {
    if (devicePublicKey != null && publicKey.matches(devicePublicKey)) {
      return false;
    }

    final keyHex = publicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final existing = _pendingAdverts[keyHex];
    final nextReceivedAt = receivedAt ?? DateTime.now();
    _pendingAdverts[keyHex] =
        (existing ??
                PendingAdvert(
                  publicKey: Uint8List.fromList(publicKey),
                  receivedAt: nextReceivedAt,
                ))
            .copyWith(
              receivedAt: nextReceivedAt,
              typeValue: typeValue,
              advName: advName?.trim().isNotEmpty == true
                  ? advName!.trim()
                  : existing?.advName,
              flags: flags ?? existing?.flags,
              lastAdvert: lastAdvert ?? existing?.lastAdvert,
              advLat: advLat ?? existing?.advLat,
              advLon: advLon ?? existing?.advLon,
              signedEncodedPathLen:
                  signedEncodedPathLen ?? existing?.signedEncodedPathLen,
              paddedPathBytes: paddedPathBytes == null
                  ? existing?.paddedPathBytes
                  : Uint8List.fromList(paddedPathBytes),
              rxRssiDbm: rxRssiDbm ?? existing?.rxRssiDbm,
              rxSnrRaw: rxSnrRaw ?? existing?.rxSnrRaw,
            );

    _persistPendingAdverts();
    notifyListeners();
    return existing == null;
  }

  /// Find contact by name
  Contact? findContactByName(String name) {
    for (final contact in _contacts.values) {
      if (contact.advName == name) return contact;
    }
    return null;
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
    _retainedContactsForSync.clear();
    _ensurePublicChannelExists();
    _persistContacts();
    _persistPendingAdverts();
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
    _retainedContactsForSync.remove(publicKeyHex);
    _persistContacts();
    _persistPendingAdverts();
    notifyListeners();
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats(namespace: _storageNamespace);
  }

  Future<void> clearPendingAdverts() async {
    if (_pendingAdverts.isEmpty) {
      return;
    }
    _pendingAdverts.clear();
    await _storageService.clearPendingAdverts(namespace: _storageNamespace);
    notifyListeners();
  }

  void updatePendingAdvertStatusByPrefix(
    Uint8List publicKeyPrefix, {
    int? batteryMv,
    int? queueLen,
    int? lastRssi,
    int? lastSnrRaw,
    int? uptimeSecs,
  }) {
    final prefixHex = publicKeyPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final match = _pendingAdverts.entries.where(
      (entry) => entry.key.startsWith(prefixHex),
    );
    if (match.isEmpty) {
      return;
    }
    final key = match.first.key;
    final existing = _pendingAdverts[key]!;
    _pendingAdverts[key] = existing.copyWith(
      repeaterBatteryMv: batteryMv,
      repeaterQueueLen: queueLen,
      repeaterLastRssi: lastRssi,
      repeaterLastSnrRaw: lastSnrRaw,
      repeaterUptimeSecs: uptimeSecs,
    );
    _persistPendingAdverts();
    notifyListeners();
  }

  List<Contact> _contactsForStorage() {
    // Don't persist the public channel pseudo-contact (all zeros key)
    const publicChannelKey =
        '0000000000000000000000000000000000000000000000000000000000000000';
    return _contacts.entries
        .where((entry) => entry.key != publicChannelKey)
        .map((entry) => entry.value)
        .toList();
  }

  void _restorePendingAdverts(
    List<Map<String, dynamic>> storedPendingAdverts, {
    Uint8List? devicePublicKey,
  }) {
    _pendingAdverts.clear();
    for (final json in storedPendingAdverts) {
      final advert = _pendingAdvertFromJson(json);
      if (advert == null) continue;
      if (devicePublicKey != null &&
          advert.publicKey.matches(devicePublicKey)) {
        continue;
      }
      if (_contacts.containsKey(advert.publicKeyHex)) {
        continue;
      }
      _pendingAdverts[advert.publicKeyHex] = advert;
    }
  }

  void _resetInMemoryState() {
    _contacts.clear();
    _savedContactGroups.clear();
    _pendingAdverts.clear();
    _estimatedLocations.clear();
    _rssiObservations.clear();
    _retainedContactsForSync.clear();
    _selfTelemetry = null;
  }

  Map<String, dynamic> _pendingAdvertToJson(PendingAdvert advert) {
    return {
      'publicKey': base64Encode(advert.publicKey),
      'receivedAtMillis': advert.receivedAt.millisecondsSinceEpoch,
      'advName': advert.advName,
      'typeValue': advert.typeValue,
      'flags': advert.flags,
      'lastAdvert': advert.lastAdvert,
      'advLat': advert.advLat,
      'advLon': advert.advLon,
      'signedEncodedPathLen': advert.signedEncodedPathLen,
      'paddedPathBytes': advert.paddedPathBytes == null
          ? null
          : base64Encode(advert.paddedPathBytes!),
      'rxRssiDbm': advert.rxRssiDbm,
      'rxSnrRaw': advert.rxSnrRaw,
      'repeaterBatteryMv': advert.repeaterBatteryMv,
      'repeaterQueueLen': advert.repeaterQueueLen,
      'repeaterLastRssi': advert.repeaterLastRssi,
      'repeaterLastSnrRaw': advert.repeaterLastSnrRaw,
      'repeaterUptimeSecs': advert.repeaterUptimeSecs,
    };
  }

  PendingAdvert? _pendingAdvertFromJson(Map<String, dynamic> json) {
    try {
      return PendingAdvert(
        publicKey: Uint8List.fromList(
          base64Decode(json['publicKey'] as String),
        ),
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          json['receivedAtMillis'] as int,
        ),
        advName: json['advName'] as String?,
        typeValue: json['typeValue'] as int?,
        flags: json['flags'] as int?,
        lastAdvert: json['lastAdvert'] as int?,
        advLat: json['advLat'] as int?,
        advLon: json['advLon'] as int?,
        signedEncodedPathLen: json['signedEncodedPathLen'] as int?,
        paddedPathBytes: json['paddedPathBytes'] == null
            ? null
            : Uint8List.fromList(
                base64Decode(json['paddedPathBytes'] as String),
              ),
        rxRssiDbm: json['rxRssiDbm'] as int?,
        rxSnrRaw: json['rxSnrRaw'] as int?,
        repeaterBatteryMv: json['repeaterBatteryMv'] as int?,
        repeaterQueueLen: json['repeaterQueueLen'] as int?,
        repeaterLastRssi: json['repeaterLastRssi'] as int?,
        repeaterLastSnrRaw: json['repeaterLastSnrRaw'] as int?,
        repeaterUptimeSecs: json['repeaterUptimeSecs'] as int?,
      );
    } catch (e) {
      debugPrint(
        '❌ [ContactsProvider] Error parsing pending advert from JSON: $e',
      );
      return null;
    }
  }

  /// Get contact count by type
  Map<String, int> get contactCounts {
    return {
      'chat': chatContacts.length,
      'repeater': repeaters.length,
      'sensor': sensorContacts.length,
      'room': rooms.length,
      'total': contacts.length,
    };
  }
}
