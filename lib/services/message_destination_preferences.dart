import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing message destination preferences
/// Stores the last selected recipient (channel, contact, or room) for sending messages
class MessageDestinationPreferences {
  static const String _destinationTypeKey = 'message_destination_type';
  static const String _recipientPublicKeyKey = 'message_recipient_public_key';

  /// Destination types
  static const String destinationTypeAll = 'all';
  static const String destinationTypeChannel = 'channel';
  static const String destinationTypeContact = 'contact';
  static const String destinationTypeRoom = 'room';

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
