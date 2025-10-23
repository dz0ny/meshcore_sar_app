import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../services/sar_template_service.dart';

/// SAR (Search & Rescue) marker types
enum SarMarkerType {
  foundPerson('🧑', 'Found Person'),
  fire('🔥', 'Fire'),
  stagingArea('🏕️', 'Staging Area'),
  object('📦', 'Object'),
  unknown('❓', 'Unknown');

  const SarMarkerType(this.emoji, this.displayName);
  final String emoji;
  final String displayName;

  /// Get localized display name
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SarMarkerType.foundPerson:
        return l10n.sarMarkerFoundPerson;
      case SarMarkerType.fire:
        return l10n.sarMarkerFire;
      case SarMarkerType.stagingArea:
        return l10n.sarMarkerStagingArea;
      case SarMarkerType.object:
        return l10n.sarMarkerObject;
      case SarMarkerType.unknown:
        return 'Unknown';
    }
  }

  static SarMarkerType fromEmoji(String emoji) {
    switch (emoji) {
      case '🧑':
      case '👤':
        return SarMarkerType.foundPerson;
      case '🔥':
        return SarMarkerType.fire;
      case '🏕️':
      case '⛺':
        return SarMarkerType.stagingArea;
      case '📦':
        return SarMarkerType.object;
      default:
        return SarMarkerType.unknown;
    }
  }

  /// Get map marker color
  String get markerColor {
    switch (this) {
      case SarMarkerType.foundPerson:
        return '#4CAF50'; // Green
      case SarMarkerType.fire:
        return '#F44336'; // Red
      case SarMarkerType.stagingArea:
        return '#2196F3'; // Blue
      case SarMarkerType.object:
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Gray
    }
  }
}

/// SAR marker from special messages
class SarMarker {
  final String id;
  final SarMarkerType type;
  final LatLng location;
  final DateTime timestamp;
  final Uint8List? senderPublicKey;
  final String? senderName;
  final String? notes;
  final String? customEmoji; // For custom SAR markers not in predefined types
  final int? colorIndex; // Color index (0-7) from standard palette

  SarMarker({
    required this.id,
    required this.type,
    required this.location,
    required this.timestamp,
    this.senderPublicKey,
    this.senderName,
    this.notes,
    this.customEmoji,
    this.colorIndex,
  });

  /// Get sender public key as hex string (short)
  String? get senderKeyShort {
    if (senderPublicKey == null || senderPublicKey!.length < 8) return null;
    return senderPublicKey!
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// Get friendly time since marker was created
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Check if marker is recent (within last hour)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 1;
  }

  /// Get the emoji to display (custom emoji if available, otherwise type emoji)
  String get emoji {
    return customEmoji ?? type.emoji;
  }

  /// Get display name - uses notes if available, otherwise looks up template by emoji, otherwise type name
  String get displayName {
    if (notes != null && notes!.isNotEmpty) {
      return notes!;
    }

    // If no notes and we have a custom emoji, try to look up the template
    if (customEmoji != null) {
      // Import the service here to avoid circular dependencies
      // We'll use a static lookup method
      return _lookupTemplateNameByEmoji(customEmoji!) ?? type.displayName;
    }

    return type.displayName;
  }

  /// Look up template name by emoji from SarTemplateService
  static String? _lookupTemplateNameByEmoji(String emoji) {
    try {
      // Use the singleton instance
      final service = SarTemplateService();
      if (!service.isInitialized) {
        return null;
      }

      // Find template with matching emoji
      final template = service.templates.firstWhere(
        (t) => t.emoji == emoji,
        orElse: () => throw StateError('No template found'),
      );

      return template.name;
    } catch (e) {
      // Template not found or service not initialized
      return null;
    }
  }

  SarMarker copyWith({
    String? id,
    SarMarkerType? type,
    LatLng? location,
    DateTime? timestamp,
    Uint8List? senderPublicKey,
    String? senderName,
    String? notes,
    String? customEmoji,
    int? colorIndex,
  }) {
    return SarMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      senderPublicKey: senderPublicKey ?? this.senderPublicKey,
      senderName: senderName ?? this.senderName,
      notes: notes ?? this.notes,
      customEmoji: customEmoji ?? this.customEmoji,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  String toString() {
    return 'SarMarker(type: ${type.displayName}, location: $location, sender: $senderName, time: $timeAgo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SarMarker && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
