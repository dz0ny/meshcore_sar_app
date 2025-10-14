import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';
import 'messages_provider.dart';
import '../services/tile_cache_service.dart';
import '../models/contact.dart';

/// Main App Provider - coordinates all other providers
class AppProvider with ChangeNotifier {
  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final TileCacheService tileCacheService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppProvider({
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.tileCacheService,
  }) {
    _setupCallbacks();
    _initializeTileCache();
    _isInitialized = true;
  }

  /// Initialize tile cache service
  Future<void> _initializeTileCache() async {
    try {
      await tileCacheService.initialize();
      debugPrint('Tile cache initialized');
    } catch (e) {
      debugPrint('Error initializing tile cache: $e');
    }
  }

  /// Setup callbacks between providers
  void _setupCallbacks() {
    // When a contact is received from BLE
    connectionProvider.onContactReceived = (contact) {
      contactsProvider.addOrUpdateContact(contact);
    };

    // When all contacts are received
    connectionProvider.onContactsComplete = (contacts) {
      contactsProvider.addContacts(contacts);
      debugPrint('Received ${contacts.length} contacts');
    };

    // When a message is received
    connectionProvider.onMessageReceived = (message) {
      messagesProvider.addMessage(message);

      // Optionally update sender name from contacts
      if (message.senderPublicKeyPrefix != null) {
        final contact = contactsProvider
            .findContactByKey(message.senderPublicKeyPrefix!);
        if (contact != null) {
          final updatedMessage = message.copyWith(senderName: contact.advName);
          // Note: You might want to update the message in the list
        }
      }
    };

    // When telemetry is received
    connectionProvider.onTelemetryReceived = (publicKey, lppData) {
      contactsProvider.updateTelemetry(publicKey, lppData);
    };
  }

  /// Initialize the app (load contacts, sync time, etc.)
  Future<void> initialize() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Sync device time
      await connectionProvider.syncDeviceTime();

      // Load contacts
      await connectionProvider.getContacts();

      // Small delay to ensure contacts are fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Automatically login to all saved rooms
      await _autoLoginToRooms();

      // Sync any waiting messages from device queue
      await _syncMessages();

      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  /// Automatically login to all rooms with saved passwords on cold connect
  Future<void> _autoLoginToRooms() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Get all room contacts (excluding Public Channel)
      final rooms = contactsProvider.rooms
          .where((room) => room.advName != 'Public Channel')
          .toList();

      if (rooms.isEmpty) {
        debugPrint('📂 [AppProvider] No rooms found to auto-login');
        return;
      }

      debugPrint('📂 [AppProvider] Found ${rooms.length} room(s), attempting auto-login...');

      final prefs = await SharedPreferences.getInstance();

      for (final room in rooms) {
        try {
          // Load saved password for this room
          final roomKey = 'room_password_${room.publicKeyHex}';
          final savedPassword = prefs.getString(roomKey) ?? 'hello';

          debugPrint('🔑 [AppProvider] Auto-logging into room: ${room.advName}');

          // Set up one-time callbacks for this room login
          await _loginToRoomWithCallback(room, savedPassword);

          // Small delay between logins to avoid overwhelming the device
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('❌ [AppProvider] Failed to auto-login to ${room.advName}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [AppProvider] Auto-login error: $e');
    }
  }

  /// Login to a specific room with callback handling
  Future<void> _loginToRoomWithCallback(Contact room, String password) async {
    // Create a completer to wait for login result
    final completer = Completer<bool>();

    // Store original callbacks
    final originalOnSuccess = connectionProvider.onLoginSuccess;
    final originalOnFail = connectionProvider.onLoginFail;

    // Set up temporary callbacks
    connectionProvider.onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint('✅ [AppProvider] Auto-login successful for ${room.advName}');
      debugPrint('📡 [AppProvider] Room server will push messages automatically via PUSH_CODE_MSG_WAITING');

      completer.complete(true);
    };

    connectionProvider.onLoginFail = (publicKeyPrefix) {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint('❌ [AppProvider] Auto-login failed for ${room.advName} (incorrect password)');
      completer.complete(false);
    };

    try {
      // Send login request
      await connectionProvider.loginToRoom(
        roomPublicKey: room.publicKey,
        password: password,
      );

      // Wait for login result with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Restore callbacks on timeout
          connectionProvider.onLoginSuccess = originalOnSuccess;
          connectionProvider.onLoginFail = originalOnFail;
          debugPrint('⏱️ [AppProvider] Auto-login timeout for ${room.advName}');
          return false;
        },
      );
    } catch (e) {
      // Restore callbacks on error
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;
      debugPrint('❌ [AppProvider] Error during auto-login to ${room.advName}: $e');
    }
  }

  /// Sync messages from device queue
  Future<void> _syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      debugPrint('🔄 [AppProvider] Starting message sync...');
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint('✅ [AppProvider] Synced $messageCount messages');
    } catch (e) {
      debugPrint('❌ [AppProvider] Message sync error: $e');
    }
  }

  /// Refresh data (contacts, messages)
  Future<void> refresh() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      await connectionProvider.getContacts();
      await _syncMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  /// Manually sync messages (useful for pull-to-refresh)
  Future<int> syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return 0;

    try {
      debugPrint('🔄 [AppProvider] Manual message sync requested');
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint('✅ [AppProvider] Synced $messageCount messages');
      notifyListeners();
      return messageCount;
    } catch (e) {
      debugPrint('❌ [AppProvider] Message sync error: $e');
      return 0;
    }
  }

  /// Clear all data
  void clearAllData() {
    contactsProvider.clearContacts();
    messagesProvider.clearAll();
    notifyListeners();
  }

  /// Get app statistics
  Map<String, dynamic> get statistics {
    return {
      'connection': {
        'isConnected': connectionProvider.deviceInfo.isConnected,
        'deviceName': connectionProvider.deviceInfo.deviceName,
        'battery': connectionProvider.deviceInfo.batteryPercent,
      },
      'contacts': contactsProvider.contactCounts,
      'messages': messagesProvider.messageStats,
      'sarMarkers': messagesProvider.sarMarkerStats,
    };
  }
}
