import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';
import 'messages_provider.dart';
import 'drawing_provider.dart';
import 'channels_provider.dart';
import '../services/tile_cache_service.dart';
import '../services/location_tracking_service.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../utils/drawing_message_parser.dart';

/// Main App Provider - coordinates all other providers
class AppProvider with ChangeNotifier {
  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final DrawingProvider drawingProvider;
  final ChannelsProvider channelsProvider;
  final TileCacheService tileCacheService;
  final LocationTrackingService locationTrackingService = LocationTrackingService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isSimpleMode = true;
  bool get isSimpleMode => _isSimpleMode;

  bool _isMapEnabled = true;
  bool get isMapEnabled => _isMapEnabled;

  AppProvider({
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.drawingProvider,
    required this.channelsProvider,
    required this.tileCacheService,
  }) {
    _setupCallbacks();
    _initializeTileCache();
    _initializeLocationTracking();
    _loadSimpleMode();
    _loadMapEnabled();
    _syncDrawingsOnStartup(); // Sync drawings immediately after providers load
    _isInitialized = true;
  }

  /// Sync drawings from messages on app startup (before BLE connection)
  Future<void> _syncDrawingsOnStartup() async {
    // Wait for MessagesProvider to finish initializing
    // DrawingProvider loads around the same time
    int attempts = 0;
    while (!messagesProvider.isInitialized && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    // Give DrawingProvider a moment to finish loading too
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('🔄 [AppProvider] Early sync: syncing drawings from messages...');
    messagesProvider.syncDrawingsWithProvider(drawingProvider);
  }

  /// Load simple mode setting from shared preferences
  Future<void> _loadSimpleMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSimpleMode = prefs.getBool('simple_mode') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading simple mode setting: $e');
    }
  }

  /// Toggle simple mode on/off
  Future<void> toggleSimpleMode(bool enabled) async {
    try {
      _isSimpleMode = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('simple_mode', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving simple mode setting: $e');
    }
  }

  /// Load map enabled setting from shared preferences
  Future<void> _loadMapEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMapEnabled = prefs.getBool('map_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading map enabled setting: $e');
    }
  }

  /// Toggle map on/off
  Future<void> toggleMapEnabled(bool enabled) async {
    try {
      _isMapEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('map_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving map enabled setting: $e');
    }
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

  /// Initialize location tracking service
  Future<void> _initializeLocationTracking() async {
    try {
      // Initialize location tracking with BLE service
      await locationTrackingService.initialize(connectionProvider.bleService);

      // Setup callbacks
      locationTrackingService.onPositionUpdate = (position) {
        debugPrint('📍 [AppProvider] Position updated: ${position.latitude}, ${position.longitude}');
      };

      locationTrackingService.onBroadcastSent = (position) {
        debugPrint('📡 [AppProvider] Position broadcast to mesh network');
      };

      locationTrackingService.onError = (error) {
        debugPrint('❌ [AppProvider] Location tracking error: $error');
      };

      locationTrackingService.onTrackingStateChanged = (isTracking) {
        debugPrint('🔄 [AppProvider] Location tracking state: ${isTracking ? "started" : "stopped"}');
      };

      debugPrint('✅ [AppProvider] Location tracking service initialized');
    } catch (e) {
      debugPrint('❌ [AppProvider] Error initializing location tracking: $e');
    }
  }

  /// Setup callbacks between providers
  void _setupCallbacks() {
    // Monitor connection state changes to start/stop location tracking
    connectionProvider.addListener(_handleConnectionStateChange);
    // When a contact is received from BLE
    connectionProvider.onContactReceived = (contact) {
      // Pass device public key to filter out our own contact
      contactsProvider.addOrUpdateContact(
        contact,
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );

      // Broadcast to SSE clients if server is running
      connectionProvider.broadcastContactToSseClients(contact);
    };

    // When all contacts are received
    connectionProvider.onContactsComplete = (contacts) {
      // Pass device public key to filter out our own contact
      contactsProvider.addContacts(
        contacts,
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
      debugPrint('Received ${contacts.length} contacts');

      // Broadcast all contacts to SSE clients if server is running
      for (final contact in contacts) {
        connectionProvider.broadcastContactToSseClients(contact);
      }
    };

    // Setup callback for ConnectionProvider to query channel info
    connectionProvider.getChannelInfo = (int channelIdx) {
      return channelsProvider.getChannel(channelIdx);
    };

    // When channel info is received
    connectionProvider.onChannelInfoReceived = (int channelIdx, String channelName, Uint8List secret, int? flags) {
      try {
        debugPrint('🔔 [AppProvider] onChannelInfoReceived called: idx=$channelIdx, name="$channelName"');
        
        // Check if this is a channel deletion (empty name)
        if (channelName.isEmpty && channelIdx != 0) {
          debugPrint('   🗑️  Channel $channelIdx deleted - removing from providers');
          
          // Remove from ChannelsProvider
          channelsProvider.removeChannel(channelIdx);
          debugPrint('   ✅ Removed from ChannelsProvider');
          
          // Remove from ContactsProvider using pseudo public key
          final publicKeyBytes = Uint8List(32);
          publicKeyBytes[0] = 0xFF; // Special marker for channels
          publicKeyBytes[1] = channelIdx; // Channel index
          final publicKeyHex = publicKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
          
          contactsProvider.removeContact(publicKeyHex);
          debugPrint('   ✅ Removed from ContactsProvider');
          
          return;
        }
        
        // Add/update in ChannelsProvider
        channelsProvider.addOrUpdateChannel(
          index: channelIdx,
          name: channelName,
          secret: secret,
          flags: flags,
        );
        debugPrint('   ✅ Added to ChannelsProvider');
        
        // Also add as Contact to ContactsProvider (for UI display)
        // Skip if it's public channel (already exists)
        debugPrint('📻 [AppProvider] Channel $channelIdx: "$channelName" (isEmpty: ${channelName.isEmpty}, isHashChannel: ${channelName.startsWith('#')})');
        
        if (channelName.isNotEmpty && channelIdx != 0) {
          debugPrint('   ✅ Adding channel $channelIdx to ContactsProvider as Contact');
          
          // Create a pseudo public key for the channel based on its index
          // Use channel index as a unique identifier (pad to 32 bytes)
          final publicKeyBytes = Uint8List(32);
          publicKeyBytes[0] = 0xFF; // Special marker for channels
          publicKeyBytes[1] = channelIdx; // Channel index
          
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          
          contactsProvider.addOrUpdateContact(
            Contact(
              publicKey: publicKeyBytes,
              type: ContactType.channel,
              flags: flags ?? 0,
              outPathLen: -1, // Flood mode for channels
              outPath: Uint8List(0), // Empty path for channels
              advName: channelName,
              lastAdvert: now,
              advLat: 0, // Channels don't have location
              advLon: 0,
              lastMod: now,
              isNew: false, // Don't mark channels as new
            ),
          );
          
          debugPrint('   ✅ Channel contact added. Total channels in ContactsProvider: ${contactsProvider.channels.length}');
        } else {
          debugPrint('   ⏭️  Skipping channel $channelIdx (empty: ${channelName.isEmpty}, isPublic: ${channelIdx == 0})');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ [AppProvider] Error in onChannelInfoReceived: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    };

    // When a message is received
    connectionProvider.onMessageReceived = (message) {
      // Enrich message with sender name from contacts first
      Message enrichedMessage = message;
      if (message.senderPublicKeyPrefix != null && message.senderName == null) {
        final contact = contactsProvider
            .findContactByKey(message.senderPublicKeyPrefix!);
        if (contact != null) {
          enrichedMessage = message.copyWith(senderName: contact.advName);
        }
      }

      // Check if message is a drawing broadcast
      if (DrawingMessageParser.isDrawingMessage(enrichedMessage.text)) {
        debugPrint('🎨 [AppProvider] Drawing message received, parsing...');
        // Extract sender name from message packet metadata
        final senderName = enrichedMessage.senderName ?? 'unknown';
        final drawing = DrawingMessageParser.parseDrawingMessage(
          enrichedMessage.text,
          senderName: senderName,
          messageId: enrichedMessage.id, // Pass message ID for navigation linking
        );
        if (drawing != null) {
          debugPrint('🎨 [AppProvider] Drawing parsed successfully: ${drawing.type.name} from ${drawing.senderName ?? "unknown"}');
          debugPrint('   Drawing linked to message ID: ${enrichedMessage.id}');
          drawingProvider.addReceivedDrawing(drawing);

          // Update message to mark as drawing and link to drawing ID
          final updatedMessage = enrichedMessage.copyWith(
            isDrawing: true,
            drawingId: drawing.id,
          );

          // Add the drawing message to chat with drawing metadata
          // This allows users to click on the drawing message to navigate to it
          messagesProvider.addMessage(
            updatedMessage,
            contactLookup: (name) => '',
          );

          // Broadcast drawing message to SSE clients if server is running
          connectionProvider.broadcastMessageToSseClients(updatedMessage);
        } else {
          debugPrint('⚠️ [AppProvider] Failed to parse drawing message');
        }
        return;
      }

      // Pass contact lookup function to link channel messages with contacts
      messagesProvider.addMessage(
        enrichedMessage,
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

      // Broadcast message to SSE clients if server is running
      connectionProvider.broadcastMessageToSseClients(enrichedMessage);
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
      // Trigger a single contact fetch to get the updated path information
      // This is much more efficient than fetching all contacts
      // This happens asynchronously to avoid blocking the event handler
      Future.delayed(const Duration(milliseconds: 100), () {
        if (connectionProvider.deviceInfo.isConnected) {
          connectionProvider.getContact(publicKey);
        }
      });
    };

    // When an advertisement is received (PUSH_CODE_ADVERT 0x80)
    // This may be sent by the radio for existing contacts instead of PUSH_CODE_NEW_ADVERT (0x8A)
    connectionProvider.onAdvertReceived = (publicKey) {
      debugPrint('📡 [AppProvider] Advertisement received: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');
      // Check if this is an existing contact that might have updated location
      final contact = contactsProvider.findContactByKey(publicKey);
      if (contact != null) {
        debugPrint('   Existing contact "${contact.advName}" - fetching updated contact info (optimized)');
        // Trigger a single contact fetch to get the updated contact information
        // This is much more efficient than fetching all contacts
        Future.delayed(const Duration(milliseconds: 100), () {
          if (connectionProvider.deviceInfo.isConnected) {
            connectionProvider.getContact(publicKey);
          }
        });
      } else {
        debugPrint('   New contact - waiting for PUSH_CODE_NEW_ADVERT (0x8A) with full details');
      }
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

    // When an echo is detected for a public channel message (PUSH_CODE_LOG_RX_DATA matched)
    connectionProvider.onMessageEchoDetected = (messageId, echoCount, snrRaw, rssiDbm) {
      debugPrint('🔊 [AppProvider] Echo detected - Message: $messageId, Count: $echoCount');
      messagesProvider.handleMessageEcho(messageId, echoCount, snrRaw, rssiDbm);
    };

    // Wire up MessagesProvider's sendMessageCallback for retry logic
    messagesProvider.sendMessageCallback = ({
      required contactPublicKey,
      required text,
      required messageId,
      required contact,
      retryAttempt = 0,
    }) async {
      return await connectionProvider.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
        messageId: messageId,
        contact: contact,
        retryAttempt: retryAttempt,
      );
    };
  }

  /// Initialize the app (load contacts, sync time, etc.)
  Future<void> initialize() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Initialize contacts provider with device public key to exclude self
      // If already initialized (from early load), this will just filter out self-contact
      // This must happen before getContacts to ensure proper filtering
      await contactsProvider.initialize(
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );

      // Note: Device clock is automatically synced during connection in MeshCoreBleService
      // No need to sync it again here

      // Get battery and storage information
      await connectionProvider.getBatteryAndStorage();

      // Load contacts
      await connectionProvider.getContacts();

      // Small delay to ensure contacts are fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Sync channels to get channel names
      // In simple mode: only sync first 5 channels for faster startup
      // In normal mode: sync all channels (up to device max)
      final channelsToSync = _isSimpleMode ? 5 : null;
      debugPrint('📻 [AppProvider] Syncing channels${_isSimpleMode ? ' (simple mode: max 5)' : ''}...');
      await connectionProvider.syncChannels(maxChannels: channelsToSync);
      debugPrint('✅ [AppProvider] Channel sync complete');

      // Configure the default public channel (channel 0)
      // This must be done before sending any channel messages
      // Note: Some firmware versions may have this pre-configured
      debugPrint('📻 [AppProvider] Configuring default public channel (channel 0)...');
      try {
        await connectionProvider.configureDefaultPublicChannel();
        debugPrint('✅ [AppProvider] Public channel configured successfully');
      } catch (e) {
        debugPrint('⚠️ [AppProvider] Public channel configuration failed (may already be configured): $e');
        // Continue anyway - channel might already be configured in firmware
      }

      // Automatically login to all saved rooms
      await _autoLoginToRooms();

      // FALLBACK: Sync messages once after connection to catch any missed push notifications
      // This handles the case where messages arrived while the app was disconnected
      debugPrint('🔄 [AppProvider] Performing initial message sync (fallback for missed pushes)');
      final initialMessageCount = await connectionProvider.syncAllMessages();
      debugPrint('📥 [AppProvider] Initial sync retrieved $initialMessageCount message(s)');

      // Note: Future messages are synced automatically via PUSH_CODE_MSG_WAITING events

      // Start location tracking AFTER all initialization is complete
      debugPrint('📍 [AppProvider] Starting location tracking after successful initialization');
      await _startLocationTracking();

      // Sync drawing messages with DrawingProvider
      // This restores any drawings that may be missing from storage
      debugPrint('🎨 [AppProvider] Syncing drawing messages with DrawingProvider...');
      messagesProvider.syncDrawingsWithProvider(drawingProvider);

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
          .where((room) => !room.isPublicChannel)
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

  /// Refresh data (contacts and channels - messages are handled via events)
  Future<void> refresh() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Sync contacts
      await connectionProvider.getContacts();
      
      // Sync channels (respect simple mode settings)
      final channelsToSync = _isSimpleMode ? 5 : null;
      await connectionProvider.syncChannels(maxChannels: channelsToSync);
      
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

  /// Handle connection state changes to manage location tracking
  void _handleConnectionStateChange() {
    final isConnected = connectionProvider.deviceInfo.isConnected;
    final wasTracking = locationTrackingService.isTracking;

    // Only stop tracking on disconnect - DON'T start on connect
    // Location tracking will be started AFTER initialization completes
    if (!isConnected && wasTracking) {
      // Connection lost - stop location tracking
      debugPrint('🔴 [AppProvider] BLE disconnected - stopping location tracking');
      _stopLocationTracking();
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      final started = await locationTrackingService.startTracking();
      if (started) {
        debugPrint('✅ [AppProvider] Location tracking started successfully');
      } else {
        debugPrint('⚠️ [AppProvider] Failed to start location tracking');
      }
    } catch (e) {
      debugPrint('❌ [AppProvider] Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    try {
      await locationTrackingService.stopTracking();
      debugPrint('✅ [AppProvider] Location tracking stopped');
    } catch (e) {
      debugPrint('❌ [AppProvider] Error stopping location tracking: $e');
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
