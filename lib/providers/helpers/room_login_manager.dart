import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/room_login_state.dart';

/// Room login state management helper
///
/// Manages login state tracking for room contacts, including:
/// - Room login state per contact (Map of String to RoomLoginState)
/// - Password checking logic
/// - Login success/fail state updates
class RoomLoginManager {
  /// Map of room public key prefix (hex string) to login state
  final Map<String, RoomLoginState> _roomLoginStates = {};

  /// Get all room login states (unmodifiable view)
  Map<String, RoomLoginState> get roomLoginStates => Map.unmodifiable(_roomLoginStates);

  /// Get login state for a room by public key prefix
  RoomLoginState? getRoomLoginState(Uint8List publicKeyPrefix) {
    final prefixHex = _publicKeyPrefixToHex(publicKeyPrefix);
    return _roomLoginStates[prefixHex];
  }

  /// Check if logged into a specific room
  bool isLoggedIntoRoom(Uint8List publicKeyPrefix) {
    final state = getRoomLoginState(publicKeyPrefix);
    return state?.isLoggedIn ?? false;
  }

  /// Update room login state after successful login
  Future<void> handleLoginSuccess({
    required Uint8List publicKeyPrefix,
    required int permissions,
    required bool isAdmin,
    required int tag,
  }) async {
    final prefixHex = _publicKeyPrefixToHex(publicKeyPrefix);
    final hasPassword = await _hasPasswordForRoom(publicKeyPrefix);

    _roomLoginStates[prefixHex] = RoomLoginState.loggedIn(
      publicKeyPrefix: publicKeyPrefix,
      permissions: permissions,
      isAdmin: isAdmin,
      tag: tag,
      hasPassword: hasPassword,
    );
  }

  /// Update room login state after failed login
  void handleLoginFail({
    required Uint8List publicKeyPrefix,
  }) {
    final prefixHex = _publicKeyPrefixToHex(publicKeyPrefix);

    _roomLoginStates[prefixHex] = RoomLoginState.loggedOut(
      publicKeyPrefix: publicKeyPrefix,
      hasPassword: false, // Password was incorrect
    );
  }

  /// Clear all room login states (call on disconnect)
  void clearRoomLoginStates() {
    _roomLoginStates.clear();
  }

  /// Check if a password exists for a room (by public key prefix)
  Future<bool> _hasPasswordForRoom(Uint8List publicKeyPrefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert prefix to hex string for storage key
      final prefixHex = _publicKeyPrefixToHex(publicKeyPrefix);
      final roomKey = 'room_password_$prefixHex';
      return prefs.getString(roomKey) != null;
    } catch (e) {
      debugPrint('Error checking password for room: $e');
      return false;
    }
  }

  /// Convert public key prefix to hex string (colon-separated)
  String _publicKeyPrefixToHex(Uint8List publicKeyPrefix) {
    return publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }
}
