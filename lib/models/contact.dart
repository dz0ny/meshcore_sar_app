import 'dart:math';
import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'contact_telemetry.dart';
import 'advert_location.dart';
import '../l10n/app_localizations.dart';

/// MeshCore contact types
enum ContactType {
  none(0),
  chat(1),
  repeater(2),
  room(3),
  channel(99); // Virtual type for public channel (not from protocol)

  const ContactType(this.value);
  final int value;

  static ContactType fromValue(int value) {
    return ContactType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContactType.none,
    );
  }

  String get displayName {
    switch (this) {
      case ContactType.chat:
        return 'Chat';
      case ContactType.repeater:
        return 'Repeater';
      case ContactType.room:
        return 'Room';
      case ContactType.channel:
        return 'Channel';
      default:
        return 'Unknown';
    }
  }
}

/// MeshCore contact model
class Contact {
  final Uint8List publicKey;
  final ContactType type;
  final int flags;
  final int outPathLen;
  final Uint8List outPath;
  final String advName;
  final int lastAdvert; // Unix timestamp
  final int advLat; // Latitude as int32
  final int advLon; // Longitude as int32
  final int lastMod; // Unix timestamp

  // Telemetry data (updated separately)
  ContactTelemetry? telemetry;

  // Advertisement location history (most recent first)
  final List<AdvertLocation> advertHistory;

  // UI state tracking
  final bool isNew; // Whether contact is newly added and not yet viewed

  Contact({
    required this.publicKey,
    required this.type,
    required this.flags,
    required this.outPathLen,
    required this.outPath,
    required this.advName,
    required this.lastAdvert,
    required this.advLat,
    required this.advLon,
    required this.lastMod,
    this.telemetry,
    List<AdvertLocation>? advertHistory,
    this.isNew = false,
  }) : advertHistory = advertHistory ?? [];

  /// Get public key as hex string (first 8 bytes)
  String get publicKeyShort {
    if (publicKey.length < 8) return '';
    return publicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Get full public key as hex string
  String get publicKeyHex {
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Get public key prefix (first 6 bytes) for room login matching
  Uint8List get publicKeyPrefix {
    if (publicKey.length < 6) return publicKey;
    return publicKey.sublist(0, 6);
  }

  /// Convert advLat/advLon to LatLng
  LatLng? get advertLocation {
    if (advLat == 0 && advLon == 0) return null;
    // Convert from int32 to double (degrees)
    final lat = advLat / 1e6;
    final lon = advLon / 1e6;
    return LatLng(lat, lon);
  }

  /// Get display location (prefer telemetry over advert)
  LatLng? get displayLocation {
    if (telemetry?.gpsLocation != null && telemetry!.isRecent) {
      return telemetry!.gpsLocation;
    }
    return advertLocation;
  }

  /// Get display battery (from telemetry or null)
  double? get displayBattery {
    return telemetry?.batteryPercentage;
  }

  /// Check if contact is a chat type (team member)
  bool get isChat => type == ContactType.chat;

  /// Check if contact is a repeater
  bool get isRepeater => type == ContactType.repeater;

  /// Check if contact is a room (persistent storage)
  bool get isRoom => type == ContactType.room;

  /// Check if contact is a channel (ephemeral broadcast)
  bool get isChannel => type == ContactType.channel;

  /// Get last seen time
  DateTime get lastSeenTime {
    return DateTime.fromMillisecondsSinceEpoch(lastAdvert * 1000);
  }

  /// Get last modified time
  DateTime get lastModifiedTime {
    return DateTime.fromMillisecondsSinceEpoch(lastMod * 1000);
  }

  /// Check if contact was seen recently (within last 10 minutes)
  bool get isRecentlySeen {
    return DateTime.now().difference(lastSeenTime).inMinutes < 10;
  }

  /// Get friendly time since last seen
  String get timeSinceLastSeen {
    final diff = DateTime.now().difference(lastSeenTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get time when location was last updated
  DateTime? get locationUpdateTime {
    // Prefer telemetry timestamp if available
    if (telemetry?.gpsLocation != null) {
      return telemetry!.timestamp;
    }
    // Fall back to lastAdvert time if using advertised location
    if (advertLocation != null) {
      return lastSeenTime;
    }
    return null;
  }

  /// Get friendly time since location was last updated
  String get timeSinceLocationUpdate {
    final updateTime = locationUpdateTime;
    if (updateTime == null) return 'Unknown';

    final diff = DateTime.now().difference(updateTime);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  /// Extract role emoji from name (e.g., "🧑🏻‍🚒Janez" → "🧑🏻‍🚒")
  /// Returns null if no emoji at start of name
  String? get roleEmoji {
    if (advName.isEmpty) return null;

    // Get the first character/grapheme cluster (which could be a complex emoji)
    final firstChar = advName.characters.first;

    // Check if it's an emoji (basic check - emojis are typically in certain Unicode ranges)
    final firstCodeUnit = firstChar.runes.first;

    // Emoji ranges (simplified check):
    // 0x1F300-0x1F9FF: Misc Symbols and Pictographs, Emoticons, Transport, etc.
    // 0x2600-0x26FF: Misc symbols
    // 0x2700-0x27BF: Dingbats
    // 0xFE00-0xFE0F: Variation Selectors
    // 0x1F900-0x1F9FF: Supplemental Symbols and Pictographs
    if ((firstCodeUnit >= 0x1F300 && firstCodeUnit <= 0x1F9FF) ||
        (firstCodeUnit >= 0x2600 && firstCodeUnit <= 0x27BF) ||
        (firstCodeUnit >= 0x1F600 && firstCodeUnit <= 0x1F64F)) {
      return firstChar;
    }

    return null;
  }

  /// Get display name without role emoji (e.g., "🧑🏻‍🚒Janez" → "Janez")
  /// If no emoji, returns full advName
  String get displayName {
    final emoji = roleEmoji;
    if (emoji == null) return advName;

    // Remove the emoji from the beginning
    return advName.substring(emoji.length).trim();
  }

  /// Check if this contact is the Public Channel (all-zeros public key)
  bool get isPublicChannel =>
      publicKeyHex == '0000000000000000000000000000000000000000000000000000000000000000';

  /// Get localized display name (for Public Channel and other special contacts)
  String getLocalizedDisplayName(BuildContext context) {
    // Check if this is the Public Channel (all-zeros public key)
    if (isPublicChannel) {
      return AppLocalizations.of(context)!.publicChannel;
    }
    // For all other contacts, use the regular display name
    return displayName;
  }

  /// Check if contact has a learned routing path
  /// When true, messages will use direct routing. When false, messages will use flood mode.
  /// outPathLen: -1 = unknown/not learned, 0 = direct (zero hops), 1+ = multi-hop path
  bool get hasPath => outPathLen >= 0 && outPathLen <= 64;

  /// Get path description for UI display
  String get pathDescription {
    if (!hasPath) {
      // -1 (0xFF) indicates path not learned yet
      return 'No path (flood mode)';
    }

    // outPathLen = 0 means direct connection with zero hops
    // outPathLen >= 1 means path with N hops
    if (outPathLen == 0) {
      return 'Direct (0 hops)';
    } else if (outPathLen == 1) {
      return 'Direct (1 hop)';
    } else if (outPathLen <= 3) {
      return 'Good path ($outPathLen hops)';
    } else if (outPathLen <= 5) {
      return 'Medium path ($outPathLen hops)';
    } else {
      return 'Long path ($outPathLen hops)';
    }
  }

  /// Get path quality indicator (0-5 scale, higher is better)
  /// -1 means no path (will use flood mode)
  int get pathQuality {
    if (!hasPath) return -1;
    if (outPathLen == 0) return 5; // Direct connection (0 hops)
    if (outPathLen == 1) return 4; // 1 hop
    if (outPathLen <= 2) return 3; // 2 hops
    if (outPathLen <= 3) return 2; // 3 hops
    if (outPathLen <= 4) return 1; // 4 hops
    return 0; // 5+ hops
  }

  /// Add a new advertisement location to history (maintains max 1000 points)
  ///
  /// Implements location dithering to avoid storing redundant points:
  /// - Only stores points that are ≥1 meter apart (max meter accuracy)
  /// - Prevents trail clutter when contact is stationary or moving slowly
  /// - Maintains chronological order (most recent first)
  Contact addAdvertLocation(LatLng location, DateTime timestamp) {
    final newPoint = AdvertLocation(location: location, timestamp: timestamp);

    // Dithering: Skip points within 1 meter of the last recorded position
    // This provides max meter accuracy while avoiding redundant data
    if (advertHistory.isNotEmpty) {
      final lastPoint = advertHistory.first;
      final distance = _calculateDistance(lastPoint.location, location);

      // If less than 1 meter apart, skip this point (location dithering)
      if (distance < 1.0) {
        return this;
      }
    }

    // Add new point at the beginning (most recent first)
    final updatedHistory = [newPoint, ...advertHistory];

    // Keep only the most recent 1000 points to limit memory usage
    final trimmedHistory = updatedHistory.length > 1000
        ? updatedHistory.sublist(0, 1000)
        : updatedHistory;

    return copyWith(advertHistory: trimmedHistory);
  }

  /// Calculate distance between two points in meters (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final lat1 = point1.latitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final dLat = (point2.latitude - point1.latitude) * (pi / 180);
    final dLon = (point2.longitude - point1.longitude) * (pi / 180);

    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1) * cos(lat2) *
              sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  Contact copyWith({
    Uint8List? publicKey,
    ContactType? type,
    int? flags,
    int? outPathLen,
    Uint8List? outPath,
    String? advName,
    int? lastAdvert,
    int? advLat,
    int? advLon,
    int? lastMod,
    ContactTelemetry? telemetry,
    List<AdvertLocation>? advertHistory,
    bool? isNew,
  }) {
    return Contact(
      publicKey: publicKey ?? this.publicKey,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      outPathLen: outPathLen ?? this.outPathLen,
      outPath: outPath ?? this.outPath,
      advName: advName ?? this.advName,
      lastAdvert: lastAdvert ?? this.lastAdvert,
      advLat: advLat ?? this.advLat,
      advLon: advLon ?? this.advLon,
      lastMod: lastMod ?? this.lastMod,
      telemetry: telemetry ?? this.telemetry,
      advertHistory: advertHistory ?? this.advertHistory,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  String toString() {
    return 'Contact(name: $advName, type: ${type.displayName}, key: $publicKeyShort)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
           publicKeyHex == other.publicKeyHex;
  }

  @override
  int get hashCode => publicKeyHex.hashCode;
}
