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
      // Pass device public key to filter out our own contact
      contactsProvider.addOrUpdateContact(
        contact,
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
    };

    // When all contacts are received
    connectionProvider.onContactsComplete = (contacts) {
      // Pass device public key to filter out our own contact
      contactsProvider.addContacts(
        contacts,
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
      debugPrint('Received ${contacts.length} contacts');
    };

    // When a message is received
    connectionProvider.onMessageReceived = (message) {
      // Pass contact lookup function to link channel messages with contacts
      messagesProvider.addMessage(
        message,
        contactLookup: (name) {
          // Find contact by name and return their public key hex (first 12 chars for 6 bytes)
          try {
            final contact = contactsProvider.contacts.firstWhere(
              (c) => c.advName == name,
            );
            return contact.publicKeyHex.isNotEmpty && contact.publicKeyHex.length >= 12
                ? contact.publicKeyHex.substring(0, 12)
                : '';
          } catch (e) {
            // No matching contact found
            return '';
          }
        },
      );

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

    // When telemetry is received via PUSH_CODE_TELEMETRY_RESPONSE (0x8B)
    // Used by older firmware versions for telemetry responses
    connectionProvider.onTelemetryReceived = (publicKey, lppData) {
      debugPrint('📊 [AppProvider] Telemetry response (0x8B) received - updating contact');
      contactsProvider.updateTelemetry(publicKey, lppData);
    };

    // When binary response is received via PUSH_CODE_BINARY_RESPONSE (0x8C)
    // Used by newer firmware versions for telemetry and other binary data
    // BOTH callbacks (0x8B and 0x8C) must be handled for device compatibility
    connectionProvider.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      debugPrint('📊 [AppProvider] Binary response (0x8C) received - updating contact telemetry');
      // Binary response tag 0 = telemetry data (Cayenne LPP format)
      // Other tags may be used for different data types in the future
      contactsProvider.updateTelemetry(publicKeyPrefix, responseData);
    };

    // When a contact's routing path is updated in the mesh network
    connectionProvider.onPathUpdated = (publicKey) {
      debugPrint('🔄 [AppProvider] Path updated for contact: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');
      // Trigger a contact sync to get the updated path information
      // This happens asynchronously to avoid blocking the event handler
      Future.delayed(const Duration(milliseconds: 100), () {
        if (connectionProvider.deviceInfo.isConnected) {
          connectionProvider.getContacts();
        }
      });
    };

    // When a message is sent (RESP_CODE_SENT received)
    connectionProvider.onMessageSent = (messageId, expectedAckTag, suggestedTimeoutMs) {
      debugPrint('📤 [AppProvider] Message sent - Message ID: $messageId, ACK tag: $expectedAckTag');
      messagesProvider.markMessageSent(messageId, expectedAckTag, suggestedTimeoutMs);
    };

    // When a message is delivered (PUSH_CODE_SEND_CONFIRMED received)
    connectionProvider.onMessageDelivered = (ackCode, roundTripTimeMs) {
      debugPrint('✅ [AppProvider] Message delivered - ACK: $ackCode, RTT: ${roundTripTimeMs}ms');
      messagesProvider.markMessageDelivered(ackCode, roundTripTimeMs);
    };
  }

  /// Initialize the app (load contacts, sync time, etc.)
  Future<void> initialize() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Initialize contacts provider with device public key to exclude self
      // This must happen before getContacts to ensure proper filtering
      if (!contactsProvider.isInitialized) {
        await contactsProvider.initialize(
          devicePublicKey: connectionProvider.deviceInfo.publicKey,
        );
      }

      // Sync device time
      await connectionProvider.syncDeviceTime();

      // Load contacts
      await connectionProvider.getContacts();

      // Small delay to ensure contacts are fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Automatically login to all saved rooms
      await _autoLoginToRooms();

      // Note: Messages are synced automatically via PUSH_CODE_MSG_WAITING events
      // No need to manually sync here - the BLE service handles this via callbacks

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

  // Removed _syncMessages() - messages are automatically synced via PUSH_CODE_MSG_WAITING events
  // The ConnectionProvider's onMessageWaiting callback handles automatic message fetching

  /// Refresh data (contacts only - messages are handled via events)
  Future<void> refresh() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      await connectionProvider.getContacts();
      // Messages are automatically synced via PUSH_CODE_MSG_WAITING events
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  /// Manually sync messages (only for explicit user pull-to-refresh)
  /// Note: Messages are automatically synced via PUSH_CODE_MSG_WAITING events
  /// This method should ONLY be called when the user explicitly pulls to refresh
  Future<int> syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return 0;

    try {
      debugPrint('🔄 [AppProvider] Manual message sync requested (user initiated)');
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint('✅ [AppProvider] Manual sync completed: $messageCount messages');
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
