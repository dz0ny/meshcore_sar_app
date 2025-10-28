import 'package:flutter/material.dart';
import '../models/contact.dart';

/// Service for assigning consistent colors to contact trails
/// Uses emoji-based semantic mapping with deterministic hash fallback
class TrailColorService {
  // 64-color palette optimized for visibility on maps
  // Organized by hue families for better distribution
  // Avoids pure blue (#2196F3) which is reserved for user trail
  static final List<Color> _colorPalette = [
    // Reds (8)
    const Color(0xFFE53935),
    const Color(0xFFD32F2F),
    const Color(0xFFC62828),
    const Color(0xFFB71C1C),
    const Color(0xFFFF5252),
    const Color(0xFFFF1744),
    const Color(0xFFD50000),
    const Color(0xFFC51162),

    // Pinks (4)
    const Color(0xFFEC407A),
    const Color(0xFFE91E63),
    const Color(0xFFC2185B),
    const Color(0xFFAD1457),

    // Purples (8)
    const Color(0xFF9C27B0),
    const Color(0xFF8E24AA),
    const Color(0xFF7B1FA2),
    const Color(0xFF6A1B9A),
    const Color(0xFFAB47BC),
    const Color(0xFF9C27B0),
    const Color(0xFF8E24AA),
    const Color(0xFF7B1FA2),

    // Deep Purples (4)
    const Color(0xFF673AB7),
    const Color(0xFF5E35B1),
    const Color(0xFF512DA8),
    const Color(0xFF4527A0),

    // Indigos (4)
    const Color(0xFF3F51B5),
    const Color(0xFF3949AB),
    const Color(0xFF303F9F),
    const Color(0xFF283593),

    // Blues (4) - Dark blues only, avoid user trail blue
    const Color(0xFF1E88E5),
    const Color(0xFF1976D2),
    const Color(0xFF1565C0),
    const Color(0xFF0D47A1),

    // Cyans (4)
    const Color(0xFF00ACC1),
    const Color(0xFF0097A7),
    const Color(0xFF00838F),
    const Color(0xFF006064),

    // Teals (4)
    const Color(0xFF00897B),
    const Color(0xFF00796B),
    const Color(0xFF00695C),
    const Color(0xFF004D40),

    // Greens (8)
    const Color(0xFF43A047),
    const Color(0xFF388E3C),
    const Color(0xFF2E7D32),
    const Color(0xFF1B5E20),
    const Color(0xFF66BB6A),
    const Color(0xFF4CAF50),
    const Color(0xFF388E3C),
    const Color(0xFF2E7D32),

    // Limes (4)
    const Color(0xFF9E9D24),
    const Color(0xFF827717),
    const Color(0xFFC0CA33),
    const Color(0xFFAFB42B),

    // Ambers (4)
    const Color(0xFFFFA726),
    const Color(0xFFFF9800),
    const Color(0xFFFB8C00),
    const Color(0xFFF57C00),

    // Oranges (4)
    const Color(0xFFFF7043),
    const Color(0xFFFF5722),
    const Color(0xFFF4511E),
    const Color(0xFFE64A19),

    // Browns (4)
    const Color(0xFF6D4C41),
    const Color(0xFF5D4037),
    const Color(0xFF4E342E),
    const Color(0xFF3E2723),
  ];

  // Emoji to color mapping for SAR roles
  // Uses semantic colors that match emergency service conventions
  static final Map<String, Color> _emojiColorMap = {
    // Emergency Services - Firefighters
    '🚒': Color(0xFFD32F2F), // Fire engine → Red
    '🧑‍🚒': Color(0xFFD32F2F), // Firefighter → Red
    '👨‍🚒': Color(0xFFD32F2F), // Firefighter → Red
    '👩‍🚒': Color(0xFFD32F2F), // Firefighter → Red
    '🔥': Color(0xFFFF5722), // Fire → Orange-Red

    // Emergency Services - Medical
    '🚑': Color(0xFF43A047), // Ambulance → Green (medical cross)
    '👨‍⚕️': Color(0xFF43A047), // Health worker → Green
    '👩‍⚕️': Color(0xFF43A047), // Health worker → Green
    '🧑‍⚕️': Color(0xFF43A047), // Health worker → Green
    '⚕️': Color(0xFF43A047), // Medical symbol → Green

    // Emergency Services - Police
    '👮': Color(0xFF1976D2), // Police → Blue
    '👮‍♂️': Color(0xFF1976D2), // Police → Blue
    '👮‍♀️': Color(0xFF1976D2), // Police → Blue
    '🚔': Color(0xFF1976D2), // Police car → Blue

    // Emergency Services - Aviation
    '🧑‍✈️': Color(0xFF1565C0), // Pilot → Dark Blue
    '👨‍✈️': Color(0xFF1565C0), // Pilot → Dark Blue
    '👩‍✈️': Color(0xFF1565C0), // Pilot → Dark Blue
    '🚁': Color(0xFF8E24AA), // Helicopter → Purple

    // SAR Roles - Mountain/Alpine
    '🏔️': Color(0xFF6D4C41), // Mountain → Brown
    '⛰️': Color(0xFF6D4C41), // Mountain → Brown
    '🧗': Color(0xFF6D4C41), // Climber → Brown
    '🧗‍♂️': Color(0xFF6D4C41), // Climber → Brown
    '🧗‍♀️': Color(0xFF6D4C41), // Climber → Brown
    '🥾': Color(0xFF5D4037), // Hiking boot → Dark Brown

    // SAR Roles - K9 Unit
    '🐕': Color(0xFFFFA726), // Dog → Orange
    '🐶': Color(0xFFFFA726), // Dog → Orange
    '🦮': Color(0xFFFFA726), // Service dog → Orange

    // SAR Roles - Water Rescue
    '🚤': Color(0xFF00ACC1), // Speedboat → Cyan
    '⛵': Color(0xFF00ACC1), // Sailboat → Cyan
    '🏊': Color(0xFF00897B), // Swimmer → Teal
    '🏊‍♂️': Color(0xFF00897B), // Swimmer → Teal
    '🏊‍♀️': Color(0xFF00897B), // Swimmer → Teal

    // Team Roles - Leadership
    '🎯': Color(0xFFE64A19), // Target → Deep Orange (team leader)
    '⭐': Color(0xFFFDD835), // Star → Yellow (coordinator)
    '👑': Color(0xFFFDD835), // Crown → Yellow (leader)

    // Team Roles - Communication
    '📡': Color(0xFF00897B), // Satellite → Teal (radio/comms)
    '📻': Color(0xFF00897B), // Radio → Teal
    '📞': Color(0xFF00897B), // Phone → Teal

    // Team Roles - Navigation
    '🗺️': Color(0xFF00ACC1), // Map → Cyan (navigator)
    '🧭': Color(0xFF00ACC1), // Compass → Cyan
    '📍': Color(0xFFE53935), // Pin → Red (location marker)

    // Team Roles - Documentation
    '📷': Color(0xFFAB47BC), // Camera → Light Purple
    '📹': Color(0xFFAB47BC), // Video camera → Light Purple
    '📝': Color(0xFF9E9D24), // Note → Lime (scribe)

    // Equipment
    '🔦': Color(0xFFFB8C00), // Flashlight → Amber
    '⚡': Color(0xFFFDD835), // Lightning → Yellow (power/energy)
    '🔋': Color(0xFF43A047), // Battery → Green
    '🎒': Color(0xFF5D4037), // Backpack → Brown

    // Generic Person Icons
    '👤': Color(0xFF9E9E9E), // Silhouette → Gray
    '🧑': Color(0xFF9E9E9E), // Person → Gray
    '👨': Color(0xFF9E9E9E), // Man → Gray
    '👩': Color(0xFF9E9E9E), // Woman → Gray
    '👥': Color(0xFF757575), // People → Dark Gray
  };

  /// Get trail color for a contact
  /// Priority: Emoji mapping > Name hash > Default
  static Color getTrailColor(Contact contact) {
    // 1. Try emoji-based color mapping
    if (contact.roleEmoji != null) {
      final emojiColor = _emojiColorMap[contact.roleEmoji];
      if (emojiColor != null) {
        // Return with slight transparency for better map visibility
        return emojiColor.withValues(alpha: 0.75);
      }
    }

    // 2. Deterministic color based on display name
    // Use display name (without emoji) for consistent hashing
    final name = contact.displayName.isNotEmpty
        ? contact.displayName
        : contact.publicKeyHex;

    final hash = _hashString(name);
    final colorIndex = hash % _colorPalette.length; // 0-63

    return _colorPalette[colorIndex].withValues(alpha: 0.75);
  }

  /// Simple string hash function (DJB2 algorithm)
  /// Same algorithm used for echo detection in the app
  static int _hashString(String str) {
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Keep 32-bit
    }
    return hash.abs();
  }

  /// Get all unique colors currently in use by contacts with trails
  static List<Color> getActiveColors(List<Contact> contacts) {
    final colors = <Color>{};
    for (final contact in contacts) {
      if (contact.advertHistory.length >= 2) {
        colors.add(getTrailColor(contact));
      }
    }
    return colors.toList();
  }

  /// Check if a color is from emoji mapping (semantic) vs hash-based
  static bool isSemanticColor(Contact contact) {
    if (contact.roleEmoji == null) return false;
    return _emojiColorMap.containsKey(contact.roleEmoji);
  }
}
