import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// SAR Template - Customizable template for SAR (Cursor on Target) messages
class SarTemplate {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final String colorHex;
  final bool isDefault;

  /// Standard color palette for SAR markers (index 0-7)
  /// This palette is used for transmission to ensure consistent colors across devices
  static const List<String> colorPalette = [
    '#F44336', // 0 - Red
    '#2196F3', // 1 - Blue
    '#4CAF50', // 2 - Green
    '#FFC107', // 3 - Yellow
    '#FF9800', // 4 - Orange
    '#9C27B0', // 5 - Purple
    '#E91E63', // 6 - Pink
    '#00BCD4', // 7 - Cyan
  ];

  SarTemplate({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.colorHex,
    this.isDefault = false,
  });

  /// Get color from hex string
  Color get color {
    final hexCode = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Get localized display name for this template
  /// Returns localized name for default templates, or the stored name for custom templates
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return name;

    // Return localized names for default templates
    switch (id) {
      case 'default_found_person':
        return l10n.sarMarkerFoundPerson;
      case 'default_fire':
        return l10n.sarMarkerFire;
      case 'default_staging_area':
        return l10n.sarMarkerStagingArea;
      case 'default_object':
        return l10n.sarMarkerObject;
      default:
        // For custom templates, return the stored name
        return name;
    }
  }

  /// Get the closest color index from the standard palette
  /// Returns 0-7 for standard colors, or the closest match
  int getColorIndex() {
    // Normalize both colors to uppercase for comparison
    final normalizedColorHex = colorHex.toUpperCase();

    // Check for exact match first
    for (int i = 0; i < colorPalette.length; i++) {
      if (colorPalette[i].toUpperCase() == normalizedColorHex) {
        return i;
      }
    }

    // If no exact match, find closest color by calculating distance
    // Parse RGB values
    final hexCode = colorHex.replaceAll('#', '');
    final r = int.parse(hexCode.substring(0, 2), radix: 16);
    final g = int.parse(hexCode.substring(2, 4), radix: 16);
    final b = int.parse(hexCode.substring(4, 6), radix: 16);

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < colorPalette.length; i++) {
      final paletteHex = colorPalette[i].replaceAll('#', '');
      final pr = int.parse(paletteHex.substring(0, 2), radix: 16);
      final pg = int.parse(paletteHex.substring(2, 4), radix: 16);
      final pb = int.parse(paletteHex.substring(4, 6), radix: 16);

      // Calculate Euclidean distance in RGB space
      final distance = ((r - pr) * (r - pr) + (g - pg) * (g - pg) + (b - pb) * (b - pb)).toDouble();

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Get color hex from palette index
  static String getColorFromIndex(int index) {
    if (index < 0 || index >= colorPalette.length) {
      return '#9E9E9E'; // Gray for invalid index
    }
    return colorPalette[index];
  }

  /// Create from JSON
  factory SarTemplate.fromJson(Map<String, dynamic> json) {
    return SarTemplate(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      colorHex: json['colorHex'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'description': description,
      'colorHex': colorHex,
      'isDefault': isDefault,
    };
  }

  /// Create from SAR message format (S:emoji:0,0:description)
  /// Example: S:🧑:0,0:Person found
  factory SarTemplate.fromSarMessage(String message) {
    final trimmed = message.trim();
    if (!trimmed.startsWith('S:')) {
      throw FormatException('SAR message must start with "S:"');
    }

    // Parse format: S:emoji:lat,lon:description
    final parts = trimmed.split(':');
    if (parts.length < 3) {
      throw FormatException('Invalid SAR message format');
    }

    final emoji = parts[1].trim();
    if (emoji.isEmpty) {
      throw FormatException('Emoji cannot be empty');
    }

    // Extract description (everything after the third colon)
    String description = '';
    if (parts.length > 3) {
      description = parts.sublist(3).join(':').trim();
    }

    // Generate ID from emoji + description
    final id = '${emoji}_${DateTime.now().millisecondsSinceEpoch}';

    // Auto-assign color based on emoji
    String colorHex = _getColorForEmoji(emoji);

    return SarTemplate(
      id: id,
      emoji: emoji,
      name: description.isNotEmpty ? description : emoji,
      description: description,
      colorHex: colorHex,
      isDefault: false,
    );
  }

  /// Convert to SAR message format with placeholder coordinates
  /// New format: S:emoji:colorIndex:0,0:description
  /// Example: S:🧑:2:0,0:Person found (2 = Green)
  String toSarMessage() {
    final colorIndex = getColorIndex();
    if (description.isNotEmpty) {
      return 'S:$emoji:$colorIndex:0,0:$description';
    }
    return 'S:$emoji:$colorIndex:0,0';
  }

  /// Auto-assign color based on emoji (uses standard color palette)
  static String _getColorForEmoji(String emoji) {
    // Default emoji to color mapping using standard palette
    final colorMap = {
      // Green (index 2) - Person, Safe, Nature
      '🧑': colorPalette[2],
      '👤': colorPalette[2],
      '✅': colorPalette[2],
      '🌲': colorPalette[2],

      // Red (index 0) - Fire, Hazard, Medical, Emergency
      '🔥': colorPalette[0],
      '🚒': colorPalette[0],
      '🚑': colorPalette[0],
      '❌': colorPalette[0],
      '🏥': colorPalette[0],

      // Orange (index 4) - Staging, Assembly
      '🏕️': colorPalette[4],
      '⛺': colorPalette[4],

      // Purple (index 5) - Objects
      '📦': colorPalette[5],

      // Blue (index 1) - Water, Air support
      '🚁': colorPalette[1],
      '💧': colorPalette[1],

      // Yellow (index 3) - Warning, Caution
      '⚠️': colorPalette[3],
    };

    return colorMap[emoji] ?? '#9E9E9E'; // Default gray for unknown emojis
  }

  /// Copy with modifications
  SarTemplate copyWith({
    String? id,
    String? emoji,
    String? name,
    String? description,
    String? colorHex,
    bool? isDefault,
  }) {
    return SarTemplate(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'SarTemplate(id: $id, emoji: $emoji, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SarTemplate && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Default templates (uses standard color palette)
  /// Colors reference:
  /// - 0 Red (#F44336) - Fire, Hazard, Medical
  /// - 1 Blue (#2196F3) - Water, Helicopter
  /// - 2 Green (#4CAF50) - Found Person, Safe
  /// - 3 Yellow (#FFC107) - Warning
  /// - 4 Orange (#FF9800) - Staging Area
  /// - 5 Purple (#9C27B0) - Object
  /// - 6 Pink (#E91E63) - Reserved
  /// - 7 Cyan (#00BCD4) - Reserved
  static List<SarTemplate> get defaults {
    return [
      SarTemplate(
        id: 'default_found_person',
        emoji: '🧑',
        name: 'Found Person',
        description: '',
        colorHex: colorPalette[2], // Green
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_fire',
        emoji: '🔥',
        name: 'Fire',
        description: '',
        colorHex: colorPalette[0], // Red
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_staging_area',
        emoji: '🏕️',
        name: 'Staging Area',
        description: '',
        colorHex: colorPalette[4], // Orange
        isDefault: true,
      ),
      SarTemplate(
        id: 'default_object',
        emoji: '📦',
        name: 'Object',
        description: '',
        colorHex: colorPalette[5], // Purple
        isDefault: true,
      ),
    ];
  }
}
