import 'dart:typed_data';

/// Represents the login state for a room
class RoomLoginState {
  final Uint8List publicKeyPrefix;
  final bool isLoggedIn;
  final bool isAdmin;
  final int permissions;
  final int? tag;
  final DateTime? loginTime;
  final bool hasPassword; // Whether we have a saved password

  const RoomLoginState({
    required this.publicKeyPrefix,
    this.isLoggedIn = false,
    this.isAdmin = false,
    this.permissions = 0,
    this.tag,
    this.loginTime,
    this.hasPassword = false,
  });

  /// Create a logged-in state
  factory RoomLoginState.loggedIn({
    required Uint8List publicKeyPrefix,
    required int permissions,
    required bool isAdmin,
    required int tag,
    required bool hasPassword,
  }) {
    return RoomLoginState(
      publicKeyPrefix: publicKeyPrefix,
      isLoggedIn: true,
      isAdmin: isAdmin,
      permissions: permissions,
      tag: tag,
      loginTime: DateTime.now(),
      hasPassword: hasPassword,
    );
  }

  /// Create a logged-out state
  factory RoomLoginState.loggedOut({
    required Uint8List publicKeyPrefix,
    bool hasPassword = false,
  }) {
    return RoomLoginState(
      publicKeyPrefix: publicKeyPrefix,
      isLoggedIn: false,
      hasPassword: hasPassword,
    );
  }

  /// Copy with modified fields
  RoomLoginState copyWith({
    Uint8List? publicKeyPrefix,
    bool? isLoggedIn,
    bool? isAdmin,
    int? permissions,
    int? tag,
    DateTime? loginTime,
    bool? hasPassword,
  }) {
    return RoomLoginState(
      publicKeyPrefix: publicKeyPrefix ?? this.publicKeyPrefix,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
      tag: tag ?? this.tag,
      loginTime: loginTime ?? this.loginTime,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  /// Get formatted public key prefix (e.g., "15:59:89:54:b4:d4")
  String get publicKeyPrefixHex {
    return publicKeyPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  /// Get login duration if logged in
  Duration? get loginDuration {
    if (!isLoggedIn || loginTime == null) return null;
    return DateTime.now().difference(loginTime!);
  }

  /// Get formatted login duration (e.g., "2h 15m ago")
  String? get loginDurationFormatted {
    final duration = loginDuration;
    if (duration == null) return null;

    if (duration.inMinutes < 1) {
      return 'just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m ago' : '${hours}h ago';
    } else {
      final days = duration.inDays;
      return '${days}d ago';
    }
  }

  @override
  String toString() {
    return 'RoomLoginState(prefix: $publicKeyPrefixHex, loggedIn: $isLoggedIn, admin: $isAdmin, hasPassword: $hasPassword)';
  }
}
