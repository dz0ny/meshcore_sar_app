import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import 'package:latlong2/latlong.dart';

/// Service for persisting contacts to local storage
class ContactStorageService {
  static const String _contactsKey = 'stored_contacts';
  static const int _maxStoredContacts = 500; // Store up to 500 contacts

  /// Save contacts to persistent storage
  Future<void> saveContacts(List<Contact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert contacts to JSON
      final jsonList = contacts.map((contact) => _contactToJson(contact)).toList();

      // Limit to max stored contacts (keep most recent)
      final limitedList = jsonList.length > _maxStoredContacts
          ? jsonList.sublist(jsonList.length - _maxStoredContacts)
          : jsonList;

      final jsonString = jsonEncode(limitedList);
      await prefs.setString(_contactsKey, jsonString);

      debugPrint('✅ [ContactStorage] Saved ${limitedList.length} contacts to storage');
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error saving contacts: $e');
    }
  }

  /// Load contacts from persistent storage
  /// [excludePublicKey] - optional public key to exclude (e.g., device's own key)
  Future<List<Contact>> loadContacts({Uint8List? excludePublicKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_contactsKey);

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
              final matches = _publicKeysMatch(contact.publicKey, excludePublicKey);
              if (matches) {
                debugPrint('ℹ️ [ContactStorage] Excluding contact with matching public key: ${contact.advName}');
              }
              return !matches;
            }).toList()
          : contacts;

      debugPrint('✅ [ContactStorage] Loaded ${filteredContacts.length} contacts from storage'
          '${excludePublicKey != null ? ' (${contacts.length - filteredContacts.length} excluded)' : ''}');
      return filteredContacts;
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error loading contacts: $e');
      return [];
    }
  }

  /// Compare two public keys for equality
  bool _publicKeysMatch(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
  }

  /// Clear all stored contacts
  Future<void> clearContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contactsKey);
      debugPrint('✅ [ContactStorage] Cleared all stored contacts');
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error clearing contacts: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_contactsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {
          'contactCount': 0,
          'storageSizeBytes': 0,
          'storageSizeKB': 0,
        };
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
      return {
        'contactCount': 0,
        'storageSizeBytes': 0,
        'storageSizeKB': 0,
      };
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
      'lastAdvert': contact.lastAdvert,
      'advLat': contact.advLat,
      'advLon': contact.advLon,
      'lastMod': contact.lastMod,
      'telemetry': contact.telemetry != null ? _telemetryToJson(contact.telemetry!) : null,
    };
  }

  /// Convert JSON to Contact
  Contact? _contactFromJson(Map<String, dynamic> json) {
    try {
      return Contact(
        publicKey: Uint8List.fromList(base64Decode(json['publicKey'] as String)),
        type: ContactType.fromValue(json['type'] as int),
        flags: json['flags'] as int,
        outPathLen: json['outPathLen'] as int,
        outPath: Uint8List.fromList(base64Decode(json['outPath'] as String)),
        advName: json['advName'] as String,
        lastAdvert: json['lastAdvert'] as int,
        advLat: json['advLat'] as int,
        advLon: json['advLon'] as int,
        lastMod: json['lastMod'] as int,
        telemetry: json['telemetry'] != null
            ? _telemetryFromJson(json['telemetry'] as Map<String, dynamic>)
            : null,
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
            json['timestampMillis'] as int),
        extraSensorData: json['extraSensorData'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('❌ [ContactStorage] Error parsing telemetry from JSON: $e');
      return null;
    }
  }
}
