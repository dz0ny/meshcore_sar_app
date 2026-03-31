import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing message destination preferences
/// Stores the last selected recipient (channel, contact, or room) for sending messages
class MessageDestinationPreferences {
  static const String _destinationTypeKey = 'message_destination_type';
  static const String _recipientPublicKeyKey = 'message_recipient_public_key';
  static const String _lockedDestinationEnabledKey =
      'message_locked_destination_enabled';
  static const String _lockedDestinationTypeKey =
      'message_locked_destination_type';
  static const String _lockedRecipientPublicKeyKey =
      'message_locked_recipient_public_key';

  /// Destination types
  static const String destinationTypeAll = 'all';
  static const String destinationTypeChannel = 'channel';
  static const String destinationTypeContact = 'contact';
  static const String destinationTypeRoom = 'room';

  static bool isLockableDestinationType(String type) {
    return type == destinationTypeChannel || type == destinationTypeRoom;
  }

  /// Get the saved destination configuration
  /// Returns a map with 'type' and optional 'publicKey'
  /// Returns null if no preference is saved (defaults to public channel)
  static Future<Map<String, String>?> getDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_destinationTypeKey);

    if (type == null) {
      return null; // Use default (public channel)
    }

    final publicKey = prefs.getString(_recipientPublicKeyKey);

    return {'type': type, 'publicKey': ?publicKey};
  }

  /// Save the selected destination
  /// [type] - one of: destinationTypeAll, destinationTypeChannel, destinationTypeContact, destinationTypeRoom
  /// [recipientPublicKey] - hex string of recipient's public key (required for contact/room)
  static Future<void> setDestination(
    String type, {
    String? recipientPublicKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_destinationTypeKey, type);

    if (recipientPublicKey != null) {
      await prefs.setString(_recipientPublicKeyKey, recipientPublicKey);
    } else {
      await prefs.remove(_recipientPublicKeyKey);
    }
  }

  /// Clear the saved destination (resets to default public channel)
  static Future<void> clearDestination() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_destinationTypeKey);
    await prefs.remove(_recipientPublicKeyKey);
  }

  /// Get the saved locked destination configuration.
  /// Returns null when the lock is disabled.
  static Future<Map<String, String>?> getLockedDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_lockedDestinationEnabledKey) ?? false;

    if (!isEnabled) {
      return null;
    }

    final savedType =
        prefs.getString(_lockedDestinationTypeKey) ?? destinationTypeChannel;
    final type = isLockableDestinationType(savedType)
        ? savedType
        : destinationTypeChannel;
    final publicKey = prefs.getString(_lockedRecipientPublicKeyKey);

    return {'type': type, 'publicKey': ?publicKey};
  }

  static Future<void> setLockedDestination({
    required bool enabled,
    String type = destinationTypeChannel,
    String? recipientPublicKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_lockedDestinationEnabledKey, enabled);

    if (!enabled) {
      await prefs.remove(_lockedDestinationTypeKey);
      await prefs.remove(_lockedRecipientPublicKeyKey);
      return;
    }

    final sanitizedType = isLockableDestinationType(type)
        ? type
        : destinationTypeChannel;
    await prefs.setString(_lockedDestinationTypeKey, sanitizedType);

    if (recipientPublicKey != null) {
      await prefs.setString(_lockedRecipientPublicKeyKey, recipientPublicKey);
    } else {
      await prefs.remove(_lockedRecipientPublicKeyKey);
    }
  }

  /// Get display name for destination type
  static String getDestinationTypeName(String type) {
    switch (type) {
      case destinationTypeAll:
        return 'All';
      case destinationTypeChannel:
        return 'Channel';
      case destinationTypeContact:
        return 'Contact';
      case destinationTypeRoom:
        return 'Room';
      default:
        return 'Unknown';
    }
  }
}
