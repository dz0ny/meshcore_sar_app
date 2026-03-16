import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import 'profiles_feature_service.dart';
import '../utils/key_comparison.dart';
import 'package:latlong2/latlong.dart';

/// Service for persisting contacts to local storage
class ContactStorageService {
  static const String _contactsKey = 'stored_contacts';
  static const String _contactGroupsKey = 'stored_contact_groups';
  static const String _pendingAdvertsKey = 'stored_pending_adverts';
  static const int _maxStoredContacts = 500; // Store up to 500 contacts
  static const int _maxStoredPendingAdverts = 500;

  String _key(String baseKey, {String? namespace}) {
    return ProfileStorageScope.scopedKey(baseKey, namespace: namespace);
  }

  /// Save contacts to persistent storage
  Future<void> saveContacts(List<Contact> contacts, {String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert contacts to JSON
      final jsonList = contacts
          .map((contact) => _contactToJson(contact))
          .toList();

      // Limit to max stored contacts (keep most recent)
      final limitedList = jsonList.length > _maxStoredContacts
          ? jsonList.sublist(jsonList.length - _maxStoredContacts)
          : jsonList;

      final jsonString = jsonEncode(limitedList);
      await prefs.setString(
        _key(_contactsKey, namespace: namespace),
        jsonString,
      );

      debugPrint(
        '✅ [ContactStorage] Saved ${limitedList.length} contacts to storage',
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error saving contacts: $e');
    }
  }

  /// Load contacts from persistent storage
  /// [excludePublicKey] - optional public key to exclude (e.g., device's own key)
  Future<List<Contact>> loadContacts({
    Uint8List? excludePublicKey,
    String? namespace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(
        _key(_contactsKey, namespace: namespace),
      );

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('ℹ️ [ContactStorage] No stored contacts found');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final contacts = jsonList
          .map((json) => _contactFromJson(json as Map<String, dynamic>))
          .where((contact) => contact != null)
          .cast<Contact>()
          .toList();

      // Filter out contacts with the excluded public key
      final filteredContacts = excludePublicKey != null
          ? contacts.where((contact) {
              final matches = contact.publicKey.matches(excludePublicKey);
              if (matches) {
                debugPrint(
                  'ℹ️ [ContactStorage] Excluding contact with matching public key: ${contact.advName}',
                );
              }
              return !matches;
            }).toList()
          : contacts;

      debugPrint(
        '✅ [ContactStorage] Loaded ${filteredContacts.length} contacts from storage'
        '${excludePublicKey != null ? ' (${contacts.length - filteredContacts.length} excluded)' : ''}',
      );
      return filteredContacts;
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error loading contacts: $e');
      return [];
    }
  }

  /// Clear all stored contacts
  Future<void> clearContacts({String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(_contactsKey, namespace: namespace));
      debugPrint('✅ [ContactStorage] Cleared all stored contacts');
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error clearing contacts: $e');
    }
  }

  Future<void> saveContactGroups(
    List<SavedContactGroup> groups, {
    String? namespace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        groups.map((group) => _contactGroupToJson(group)).toList(),
      );
      await prefs.setString(
        _key(_contactGroupsKey, namespace: namespace),
        jsonString,
      );
      debugPrint(
        '✅ [ContactStorage] Saved ${groups.length} contact groups to storage',
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error saving contact groups: $e');
    }
  }

  Future<List<SavedContactGroup>> loadContactGroups({String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(
        _key(_contactGroupsKey, namespace: namespace),
      );
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => _contactGroupFromJson(json as Map<String, dynamic>))
          .whereType<SavedContactGroup>()
          .toList();
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error loading contact groups: $e');
      return [];
    }
  }

  Future<void> clearContactGroups({String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(_contactGroupsKey, namespace: namespace));
      debugPrint('✅ [ContactStorage] Cleared all contact groups');
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error clearing contact groups: $e');
    }
  }

  Future<void> savePendingAdverts(
    List<Map<String, dynamic>> adverts, {
    String? namespace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limitedList = adverts.length > _maxStoredPendingAdverts
          ? adverts.sublist(adverts.length - _maxStoredPendingAdverts)
          : adverts;
      await prefs.setString(
        _key(_pendingAdvertsKey, namespace: namespace),
        jsonEncode(limitedList),
      );
      debugPrint(
        '✅ [ContactStorage] Saved ${limitedList.length} pending adverts to storage',
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error saving pending adverts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadPendingAdverts({
    String? namespace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(
        _key(_pendingAdvertsKey, namespace: namespace),
      );
      if (jsonString == null || jsonString.isEmpty) {
        return const [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error loading pending adverts: $e');
      return const [];
    }
  }

  Future<void> clearPendingAdverts({String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(_pendingAdvertsKey, namespace: namespace));
      debugPrint('✅ [ContactStorage] Cleared all stored pending adverts');
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error clearing pending adverts: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats({String? namespace}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(
        _key(_contactsKey, namespace: namespace),
      );

      if (jsonString == null || jsonString.isEmpty) {
        return {'contactCount': 0, 'storageSizeBytes': 0, 'storageSizeKB': 0};
      }

      final sizeBytes = jsonString.length;
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      return {
        'contactCount': jsonList.length,
        'storageSizeBytes': sizeBytes,
        'storageSizeKB': (sizeBytes / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error getting storage stats: $e');
      return {'contactCount': 0, 'storageSizeBytes': 0, 'storageSizeKB': 0};
    }
  }

  /// Convert Contact to JSON
  Map<String, dynamic> _contactToJson(Contact contact) {
    return {
      'publicKey': base64Encode(contact.publicKey),
      'type': contact.type.value,
      'flags': contact.flags,
      'outPathLen': contact.outPathLen,
      'outPath': base64Encode(contact.outPath),
      'advName': contact.advName,
      'nameOverride': contact.nameOverride,
      'lastAdvert': contact.lastAdvert,
      'advLat': contact.advLat,
      'advLon': contact.advLon,
      'lastMod': contact.lastMod,
      'telemetry': contact.telemetry != null
          ? _telemetryToJson(contact.telemetry!)
          : null,
      'advertHistory': contact.advertHistory
          .map(
            (point) => {
              'lat': point.location.latitude,
              'lon': point.location.longitude,
              'tsMillis': point.timestamp.millisecondsSinceEpoch,
            },
          )
          .toList(),
    };
  }

  /// Convert JSON to Contact
  Contact? _contactFromJson(Map<String, dynamic> json) {
    try {
      return Contact(
        publicKey: Uint8List.fromList(
          base64Decode(json['publicKey'] as String),
        ),
        type: ContactType.fromValue(json['type'] as int),
        flags: json['flags'] as int,
        outPathLen: json['outPathLen'] as int,
        outPath: Uint8List.fromList(base64Decode(json['outPath'] as String)),
        advName: json['advName'] as String,
        nameOverride: json['nameOverride'] as String?,
        lastAdvert: json['lastAdvert'] as int,
        advLat: json['advLat'] as int,
        advLon: json['advLon'] as int,
        lastMod: json['lastMod'] as int,
        telemetry: json['telemetry'] != null
            ? _telemetryFromJson(json['telemetry'] as Map<String, dynamic>)
            : null,
        advertHistory: _advertHistoryFromJson(json['advertHistory']),
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error parsing contact from JSON: $e');
      return null;
    }
  }

  /// Convert ContactTelemetry to JSON
  Map<String, dynamic> _telemetryToJson(ContactTelemetry telemetry) {
    return {
      'gpsLocation': telemetry.gpsLocation != null
          ? {
              'latitude': telemetry.gpsLocation!.latitude,
              'longitude': telemetry.gpsLocation!.longitude,
            }
          : null,
      'batteryPercentage': telemetry.batteryPercentage,
      'batteryMilliVolts': telemetry.batteryMilliVolts,
      'temperature': telemetry.temperature,
      'humidity': telemetry.humidity,
      'pressure': telemetry.pressure,
      'timestampMillis': telemetry.timestamp.millisecondsSinceEpoch,
      'extraSensorData': telemetry.extraSensorData,
    };
  }

  /// Convert JSON to ContactTelemetry
  ContactTelemetry? _telemetryFromJson(Map<String, dynamic> json) {
    try {
      return ContactTelemetry(
        gpsLocation: json['gpsLocation'] != null
            ? LatLng(
                json['gpsLocation']['latitude'] as double,
                json['gpsLocation']['longitude'] as double,
              )
            : null,
        batteryPercentage: json['batteryPercentage'] as double?,
        batteryMilliVolts: json['batteryMilliVolts'] as double?,
        temperature: json['temperature'] as double?,
        humidity: json['humidity'] as double?,
        pressure: json['pressure'] as double?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestampMillis'] as int,
        ),
        extraSensorData: json['extraSensorData'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error parsing telemetry from JSON: $e');
      return null;
    }
  }

  List<AdvertLocation> _advertHistoryFromJson(dynamic json) {
    if (json is! List) return [];
    final result = <AdvertLocation>[];
    for (final item in json) {
      if (item is! Map<String, dynamic>) continue;
      final lat = item['lat'];
      final lon = item['lon'];
      final tsMillis = item['tsMillis'];
      if (lat is! num || lon is! num || tsMillis is! int) continue;
      result.add(
        AdvertLocation(
          location: LatLng(lat.toDouble(), lon.toDouble()),
          timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
        ),
      );
    }
    return result;
  }

  Map<String, dynamic> _contactGroupToJson(SavedContactGroup group) {
    return {
      'id': group.id,
      'sectionKey': group.sectionKey,
      'label': group.label,
      'query': group.query,
      'createdAtMillis': group.createdAt.millisecondsSinceEpoch,
      'matchPrefixes': group.matchPrefixes,
      'isAutoGroup': group.isAutoGroup,
    };
  }

  SavedContactGroup? _contactGroupFromJson(Map<String, dynamic> json) {
    try {
      return SavedContactGroup(
        id: json['id'] as String,
        sectionKey: json['sectionKey'] as String,
        label: json['label'] as String,
        query: json['query'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAtMillis'] as int,
        ),
        matchPrefixes: (json['matchPrefixes'] as List<dynamic>?)
            ?.map((value) => value as String)
            .toList(),
        isAutoGroup: json['isAutoGroup'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error parsing contact group: $e');
      return null;
    }
  }
}
