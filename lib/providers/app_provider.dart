import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';
import 'messages_provider.dart';
import 'drawing_provider.dart';
import 'channels_provider.dart';
import 'voice_provider.dart';
import 'image_provider.dart' as ip;
import 'helpers/fragment_ack_wait_registry.dart';
import 'helpers/session_metadata_restore.dart';
import '../services/tile_cache_service.dart';
import '../services/location_tracking_service.dart';
import '../services/packet_capture_storage_service.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import '../utils/drawing_message_parser.dart';
import '../utils/voice_message_parser.dart';
import '../utils/image_message_parser.dart';

/// Main App Provider - coordinates all other providers
class AppProvider with ChangeNotifier {
  static const int _maxDirectPayloadHops = 3;
  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final DrawingProvider drawingProvider;
  final ChannelsProvider channelsProvider;
  final VoiceProvider voiceProvider;
  final ip.ImageProvider imageProvider;
  final TileCacheService tileCacheService;
  final LocationTrackingService locationTrackingService =
      LocationTrackingService();
  final PacketCaptureStorageService packetCaptureStorageService =
      PacketCaptureStorageService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isSimpleMode = true;
  bool get isSimpleMode => _isSimpleMode;

  bool _isMapEnabled = true;
  bool get isMapEnabled => _isMapEnabled;
  bool _isContactsEnabled = true;
  bool get isContactsEnabled => _isContactsEnabled;

  bool _isVoiceSilenceTrimmingEnabled = true;
  bool get isVoiceSilenceTrimmingEnabled => _isVoiceSilenceTrimmingEnabled;
  bool _isVoiceBandPassFilterEnabled = true;
  bool get isVoiceBandPassFilterEnabled => _isVoiceBandPassFilterEnabled;
  bool _isVoiceCompressorEnabled = true;
  bool get isVoiceCompressorEnabled => _isVoiceCompressorEnabled;
  bool _isVoiceLimiterEnabled = true;
  bool get isVoiceLimiterEnabled => _isVoiceLimiterEnabled;
  bool _autoAddDiscoveredContacts = false;
  bool get autoAddDiscoveredContacts => _autoAddDiscoveredContacts;

  static const Duration _packetRetryDelay = Duration(milliseconds: 1200);
  static const int _maxPacketRetryAttempts = 4;
  final Map<String, String> _voiceSessionSenderKey6 = {};
  final Map<String, String> _imageSessionSenderKey6 = {};
  final Map<String, Timer> _voiceMissingRetryTimers = {};
  final Map<String, int> _voiceMissingRetryAttempts = {};
  final FragmentAckWaitRegistry _voiceFragmentAckWaiters =
      FragmentAckWaitRegistry();
  final FragmentAckWaitRegistry _imageFragmentAckWaiters =
      FragmentAckWaitRegistry();
  Timer? _packetCaptureFlushTimer;
  String? _lastPersistedPacketSignature;
  bool _isPersistingPacketCapture = false;

  AppProvider({
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.drawingProvider,
    required this.channelsProvider,
    required this.voiceProvider,
    required this.imageProvider,
    required this.tileCacheService,
  }) {
    _setupCallbacks();
    _initializeTileCache();
    _initializeLocationTracking();
    _loadSimpleMode();
    _loadMapEnabled();
    _loadContactsEnabled();
    _loadVoiceSilenceTrimmingEnabled();
    _loadVoiceBandPassFilterEnabled();
    _loadVoiceCompressorEnabled();
    _loadVoiceLimiterEnabled();
    _loadAutoAddDiscoveredContacts();
    _startPacketCapturePersistence();
    _syncDrawingsOnStartup(); // Sync drawings immediately after providers load
    _isInitialized = true;
  }

  void _startPacketCapturePersistence() {
    _packetCaptureFlushTimer?.cancel();
    _packetCaptureFlushTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_flushPacketCaptureLogs());
    });
    unawaited(_flushPacketCaptureLogs());
  }

  String _packetLogSignature(BlePacketLog log) {
    final prefix = log.rawData.length <= 12
        ? log.rawData
        : log.rawData.sublist(0, 12);
    final prefixHex = prefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${log.timestamp.microsecondsSinceEpoch}|'
        '${log.direction.name}|${log.responseCode ?? -1}|'
        '${log.rawData.length}|$prefixHex';
  }

  Future<void> _flushPacketCaptureLogs() async {
    if (_isPersistingPacketCapture) return;
    _isPersistingPacketCapture = true;
    try {
      final logs = connectionProvider.bleService.packetLogs;
      if (logs.isEmpty) return;

      List<BlePacketLog> toPersist = const [];
      if (_lastPersistedPacketSignature == null) {
        toPersist = logs;
      } else {
        final lastSig = _lastPersistedPacketSignature!;
        var lastIndex = -1;
        for (var i = logs.length - 1; i >= 0; i--) {
          if (_packetLogSignature(logs[i]) == lastSig) {
            lastIndex = i;
            break;
          }
        }
        if (lastIndex == -1) {
          // In-memory log rotated or cleared; persist current window to avoid gaps.
          toPersist = logs;
        } else if (lastIndex < logs.length - 1) {
          toPersist = logs.sublist(lastIndex + 1);
        }
      }

      if (toPersist.isNotEmpty) {
        await packetCaptureStorageService.appendLogs(toPersist);
      }
      _lastPersistedPacketSignature = _packetLogSignature(logs.last);
    } catch (e) {
      debugPrint('❌ [AppProvider] Packet capture flush failed: $e');
    } finally {
      _isPersistingPacketCapture = false;
    }
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

    _restoreSessionMetadataFromMessages();

    debugPrint(
      '🔄 [AppProvider] Early sync: syncing drawings from messages...',
    );
    messagesProvider.syncDrawingsWithProvider(drawingProvider);
  }

  void _restoreSessionMetadataFromMessages() {
    final restored = restoreSessionMetadataFromMessages(
      messagesProvider.messages.map((message) => message.text),
    );

    _voiceSessionSenderKey6.addAll(restored.voiceSenderKeyBySession);
    for (final entry in restored.imageEnvelopeBySession.entries) {
      _imageSessionSenderKey6[entry.key] = entry.value.senderKey6.toLowerCase();
      imageProvider.registerEnvelope(entry.value);
    }

    final restoredVoice = restored.voiceSenderKeyBySession.length;
    final restoredImage = restored.imageEnvelopeBySession.length;
    if (restoredVoice > 0 || restoredImage > 0) {
      debugPrint(
        '🔄 [AppProvider] Restored session metadata from messages: '
        '$restoredVoice voice, $restoredImage image',
      );
    }
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

  /// Load contacts enabled setting from shared preferences
  Future<void> _loadContactsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isContactsEnabled = prefs.getBool('contacts_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts enabled setting: $e');
    }
  }

  /// Toggle contacts tab on/off
  Future<void> toggleContactsEnabled(bool enabled) async {
    try {
      _isContactsEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('contacts_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving contacts enabled setting: $e');
    }
  }

  /// Load voice silence trimming setting from shared preferences.
  Future<void> _loadVoiceSilenceTrimmingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceSilenceTrimmingEnabled =
          prefs.getBool('voice_silence_trimming_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice silence trimming setting: $e');
    }
  }

  /// Toggle voice silence trimming on/off.
  Future<void> toggleVoiceSilenceTrimmingEnabled(bool enabled) async {
    try {
      _isVoiceSilenceTrimmingEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_silence_trimming_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice silence trimming setting: $e');
    }
  }

  /// Load voice band-pass filter setting from shared preferences.
  Future<void> _loadVoiceBandPassFilterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceBandPassFilterEnabled =
          prefs.getBool('voice_band_pass_filter_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice band-pass filter setting: $e');
    }
  }

  /// Toggle voice band-pass filter on/off.
  Future<void> toggleVoiceBandPassFilterEnabled(bool enabled) async {
    try {
      _isVoiceBandPassFilterEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_band_pass_filter_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice band-pass filter setting: $e');
    }
  }

  /// Load voice compressor setting from shared preferences.
  Future<void> _loadVoiceCompressorEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceCompressorEnabled =
          prefs.getBool('voice_compressor_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice compressor setting: $e');
    }
  }

  /// Toggle voice compressor on/off.
  Future<void> toggleVoiceCompressorEnabled(bool enabled) async {
    try {
      _isVoiceCompressorEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_compressor_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice compressor setting: $e');
    }
  }

  /// Load voice limiter setting from shared preferences.
  Future<void> _loadVoiceLimiterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceLimiterEnabled = prefs.getBool('voice_limiter_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice limiter setting: $e');
    }
  }

  /// Toggle voice limiter on/off.
  Future<void> toggleVoiceLimiterEnabled(bool enabled) async {
    try {
      _isVoiceLimiterEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_limiter_enabled', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice limiter setting: $e');
    }
  }

  /// Load auto-add discovered contacts setting from shared preferences.
  Future<void> _loadAutoAddDiscoveredContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoAddDiscoveredContacts =
          prefs.getBool('auto_add_discovered_contacts') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading auto-add discovered contacts setting: $e');
    }
  }

  /// Toggle auto-add discovered contacts on/off.
  Future<void> toggleAutoAddDiscoveredContacts(bool enabled) async {
    try {
      _autoAddDiscoveredContacts = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_add_discovered_contacts', enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving auto-add discovered contacts setting: $e');
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
        debugPrint(
          '📍 [AppProvider] Position updated: ${position.latitude}, ${position.longitude}',
        );
      };

      locationTrackingService.onBroadcastSent = (position) {
        debugPrint('📡 [AppProvider] Position broadcast to mesh network');
      };

      locationTrackingService.onError = (error) {
        debugPrint('❌ [AppProvider] Location tracking error: $error');
      };

      locationTrackingService.onTrackingStateChanged = (isTracking) {
        debugPrint(
          '🔄 [AppProvider] Location tracking state: ${isTracking ? "started" : "stopped"}',
        );
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

    voiceProvider.sendRawPacketCallback =
        ({
          required Uint8List contactPath,
          required int contactPathLen,
          required Uint8List payload,
        }) async {
          await connectionProvider.sendRawVoicePacket(
            contactPath: contactPath,
            contactPathLen: contactPathLen,
            payload: payload,
          );
        };

    // Image raw-packet serving reuses the same BLE raw-data path as voice.
    imageProvider.sendRawPacketCallback =
        ({
          required Uint8List contactPath,
          required int contactPathLen,
          required Uint8List payload,
        }) async {
          await connectionProvider.sendRawVoicePacket(
            contactPath: contactPath,
            contactPathLen: contactPathLen,
            payload: payload,
          );
        };
    voiceProvider.waitForFragmentAckCallback =
        ({
          required sessionId,
          required index,
          timeout = const Duration(seconds: 8),
        }) => _waitForVoiceFragmentAck(
          sessionId: sessionId,
          index: index,
          timeout: timeout,
        );
    imageProvider.waitForFragmentAckCallback =
        ({
          required sessionId,
          required index,
          timeout = const Duration(seconds: 8),
        }) => _waitForImageFragmentAck(
          sessionId: sessionId,
          index: index,
          timeout: timeout,
        );

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
    connectionProvider.onChannelInfoReceived =
        (int channelIdx, String channelName, Uint8List secret, int? flags) {
          try {
            debugPrint(
              '🔔 [AppProvider] onChannelInfoReceived called: idx=$channelIdx, name="$channelName"',
            );

            // Check if this is a channel deletion (empty name)
            if (channelName.isEmpty && channelIdx != 0) {
              debugPrint(
                '   🗑️  Channel $channelIdx deleted - removing from providers',
              );

              // Remove from ChannelsProvider
              channelsProvider.removeChannel(channelIdx);
              debugPrint('   ✅ Removed from ChannelsProvider');

              // Remove from ContactsProvider using pseudo public key
              final publicKeyBytes = Uint8List(32);
              publicKeyBytes[0] = 0xFF; // Special marker for channels
              publicKeyBytes[1] = channelIdx; // Channel index
              final publicKeyHex = publicKeyBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join('');

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
            debugPrint(
              '📻 [AppProvider] Channel $channelIdx: "$channelName" (isEmpty: ${channelName.isEmpty}, isHashChannel: ${channelName.startsWith('#')})',
            );

            if (channelName.isNotEmpty && channelIdx != 0) {
              debugPrint(
                '   ✅ Adding channel $channelIdx to ContactsProvider as Contact',
              );

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

              debugPrint(
                '   ✅ Channel contact added. Total channels in ContactsProvider: ${contactsProvider.channels.length}',
              );
            } else {
              debugPrint(
                '   ⏭️  Skipping channel $channelIdx (empty: ${channelName.isEmpty}, isPublic: ${channelIdx == 0})',
              );
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
      Contact? senderContact;
      if (message.senderPublicKeyPrefix != null && message.senderName == null) {
        final contact = contactsProvider.findContactByKey(
          message.senderPublicKeyPrefix!,
        );
        if (contact != null) {
          senderContact = contact;
          enrichedMessage = message.copyWith(senderName: contact.advName);
        }
      }
      senderContact ??= message.senderPublicKeyPrefix != null
          ? contactsProvider.findContactByKey(message.senderPublicKeyPrefix!)
          : null;
      senderContact ??= enrichedMessage.senderName != null
          ? contactsProvider.contacts
                .where((c) => c.advName == enrichedMessage.senderName)
                .firstOrNull
          : null;
      final contactLocationSnapshot = senderContact != null
          ? contactsProvider.buildMessageContactLocationSnapshot(
              senderContact,
              capturedAt: enrichedMessage.receivedAt,
            )
          : null;

      // Check if message is a drawing broadcast
      if (DrawingMessageParser.isDrawingMessage(enrichedMessage.text)) {
        debugPrint('🎨 [AppProvider] Drawing message received, parsing...');
        // Extract sender name from message packet metadata
        final senderName = enrichedMessage.senderName ?? 'unknown';
        final drawing = DrawingMessageParser.parseDrawingMessage(
          enrichedMessage.text,
          senderName: senderName,
          messageId:
              enrichedMessage.id, // Pass message ID for navigation linking
        );
        if (drawing != null) {
          debugPrint(
            '🎨 [AppProvider] Drawing parsed successfully: ${drawing.type.name} from ${drawing.senderName ?? "unknown"}',
          );
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
            contactLocationSnapshot: contactLocationSnapshot,
          );

          // Broadcast drawing message to SSE clients if server is running
          connectionProvider.broadcastMessageToSseClients(updatedMessage);
        } else {
          debugPrint('⚠️ [AppProvider] Failed to parse drawing message');
        }
        return;
      }

      // Voice envelope message (new public/direct on-demand format).
      final voiceEnvelope = VoiceEnvelope.tryParseText(enrichedMessage.text);
      if (voiceEnvelope != null) {
        _voiceSessionSenderKey6[voiceEnvelope.sessionId] = voiceEnvelope
            .senderKey6
            .toLowerCase();
        enrichedMessage = enrichedMessage.copyWith(
          isVoice: true,
          voiceId: voiceEnvelope.sessionId,
        );
        messagesProvider.addMessage(
          enrichedMessage,
          contactLookup: (name) {
            try {
              final contact = contactsProvider.contacts.firstWhere(
                (c) => c.advName == name,
              );
              return contact.publicKeyHex.isNotEmpty &&
                      contact.publicKeyHex.length >= 12
                  ? contact.publicKeyHex.substring(0, 12)
                  : '';
            } catch (_) {
              return '';
            }
          },
          contactLocationSnapshot: contactLocationSnapshot,
        );
        connectionProvider.broadcastMessageToSseClients(enrichedMessage);
        return;
      }

      // Image envelope (IE1): announce image availability.
      final imageEnvelope = ImageEnvelope.tryParse(enrichedMessage.text);
      if (imageEnvelope != null) {
        _imageSessionSenderKey6[imageEnvelope.sessionId] = imageEnvelope
            .senderKey6
            .toLowerCase();
        imageProvider.registerEnvelope(imageEnvelope);
        messagesProvider.addMessage(
          enrichedMessage,
          contactLookup: (name) {
            try {
              final contact = contactsProvider.contacts.firstWhere(
                (c) => c.advName == name,
              );
              return contact.publicKeyHex.isNotEmpty &&
                      contact.publicKeyHex.length >= 12
                  ? contact.publicKeyHex.substring(0, 12)
                  : '';
            } catch (_) {
              return '';
            }
          },
          contactLocationSnapshot: contactLocationSnapshot,
        );
        connectionProvider.broadcastMessageToSseClients(enrichedMessage);
        return;
      }

      // If it's a text-format voice packet, feed it to VoiceProvider
      if (VoicePacket.isVoiceText(enrichedMessage.text)) {
        final pkt = VoicePacket.tryParseText(enrichedMessage.text);
        if (pkt != null) {
          voiceProvider.addPacket(pkt);
          // Mark the message with voice metadata before adding to chat
          enrichedMessage = enrichedMessage.copyWith(
            isVoice: true,
            voiceId: pkt.sessionId,
          );
        }
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
            return contact.publicKeyHex.isNotEmpty &&
                    contact.publicKeyHex.length >= 12
                ? contact.publicKeyHex.substring(0, 12)
                : '';
          } catch (e) {
            // No matching contact found
            return '';
          }
        },
        contactLocationSnapshot: contactLocationSnapshot,
      );

      // Broadcast message to SSE clients if server is running
      connectionProvider.broadcastMessageToSseClients(enrichedMessage);
    };

    // When telemetry is received via PUSH_CODE_TELEMETRY_RESPONSE (0x8B)
    // Used by older firmware versions for telemetry responses
    connectionProvider.onTelemetryReceived = (publicKey, lppData) {
      debugPrint(
        '📊 [AppProvider] Telemetry response (0x8B) received - updating contact',
      );
      contactsProvider.updateTelemetry(publicKey, lppData);
    };

    // When binary response is received via PUSH_CODE_BINARY_RESPONSE (0x8C)
    // Used by newer firmware versions for telemetry and other binary data
    // BOTH callbacks (0x8B and 0x8C) must be handled for device compatibility
    connectionProvider.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      debugPrint(
        '📊 [AppProvider] Binary response (0x8C) received - updating contact telemetry',
      );
      // Binary response tag 0 = telemetry data (Cayenne LPP format)
      // Other tags may be used for different data types in the future
      contactsProvider.updateTelemetry(publicKeyPrefix, responseData);
    };

    // When raw binary data is received (PUSH_CODE_RAW_DATA 0x84)
    // Magic 0x72 'r' = voice fetch request; 0x69 'i' = image fetch request.
    // Magic 0x56 'V' = voice packet; magic 0x49 'I' = image packet.
    connectionProvider.onRawDataReceived = (payload, snrRaw, rssiDbm) {
      final voiceFetchRequest = VoiceFetchRequest.tryParseBinary(payload);
      if (voiceFetchRequest != null) {
        final requester = contactsProvider.findContactByPrefixHex(
          voiceFetchRequest.requesterKey6,
        );
        if (requester == null) {
          debugPrint(
            '⚠️ [AppProvider] Voice fetch requester contact not found (binary)',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch voice: requester contact is unknown. Add/sync contacts first.',
            level: 'warning',
          );
          return;
        }
        if (requester.outPathLen > _maxDirectPayloadHops) {
          debugPrint(
            '⚠️ [AppProvider] Voice fetch requester too far: ${requester.outPathLen} hops',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch voice for ${requester.advName}: message is too far (${requester.outPathLen} hops, max $_maxDirectPayloadHops).',
            level: 'warning',
          );
          return;
        }
        unawaited(
          voiceProvider.serveSessionTo(
            sessionId: voiceFetchRequest.sessionId,
            requester: requester,
            requestedIndices: voiceFetchRequest.want == 'missing'
                ? voiceFetchRequest.missingIndices.toSet()
                : null,
          ),
        );
        return;
      }

      final imageFetchRequest = ImageFetchRequest.tryParseBinary(payload);
      if (imageFetchRequest != null) {
        final requester = _resolveImageFetchRequester(imageFetchRequest);
        if (requester == null) {
          debugPrint(
            '⚠️ [AppProvider] Image fetch requester contact not found (binary) '
            'for session ${imageFetchRequest.sessionId} / '
            '${imageFetchRequest.requesterKey6}',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch image: requester contact is unknown. Add/sync contacts first.',
            level: 'warning',
          );
          return;
        }
        if (requester.outPathLen > _maxDirectPayloadHops) {
          debugPrint(
            '⚠️ [AppProvider] Image fetch requester too far: '
            '${requester.outPathLen} hops for session '
            '${imageFetchRequest.sessionId}',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch image for ${requester.advName}: message is too far (${requester.outPathLen} hops, max $_maxDirectPayloadHops).',
            level: 'warning',
          );
          return;
        }
        debugPrint(
          '📷 [AppProvider] Serving image session ${imageFetchRequest.sessionId} '
          'to ${requester.advName} via ${requester.outPathLen} hop(s)',
        );
        unawaited(
          imageProvider.serveSessionTo(
            sessionId: imageFetchRequest.sessionId,
            requester: requester,
            requestedIndices: imageFetchRequest.want == 'missing'
                ? imageFetchRequest.missingIndices.toSet()
                : null,
          ),
        );
        return;
      }

      final voiceAck = VoiceFragmentAck.tryParseBinary(payload);
      if (voiceAck != null) {
        _completeVoiceFragmentAck(voiceAck.sessionId, voiceAck.index);
        return;
      }

      final imageAck = ImageFragmentAck.tryParseBinary(payload);
      if (imageAck != null) {
        _completeImageFragmentAck(imageAck.sessionId, imageAck.index);
        return;
      }

      if (ImagePacket.isImageBinary(payload)) {
        final frag = ImagePacket.tryParseBinary(payload);
        if (frag == null) return;
        debugPrint('📷 [AppProvider] Binary image fragment received: $frag');
        final session = imageProvider.session(frag.sessionId);
        imageProvider.addFragment(
          frag,
          width: session?.width ?? 0,
          height: session?.height ?? 0,
        );
        _sendImageFragmentAck(frag);
        return;
      }

      if (!VoicePacket.isVoiceBinary(payload)) return;
      final pkt = VoicePacket.tryParseBinary(payload);
      if (pkt == null) return;
      debugPrint('🎙️ [AppProvider] Binary voice packet received: $pkt');
      final justComplete = voiceProvider.addPacket(pkt);
      _sendVoiceFragmentAck(pkt);
      _scheduleVoiceMissingRetry(pkt.sessionId, justComplete: justComplete);
      // Insert or update the placeholder message in the chat list
      _handleIncomingVoicePacket(pkt, justComplete: justComplete);
    };

    // When a contact's routing path is updated in the mesh network
    connectionProvider.onPathUpdated = (publicKey) {
      debugPrint(
        '🔄 [AppProvider] Path updated for contact: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
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
      debugPrint(
        '📡 [AppProvider] Advertisement received: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      // Check if this is an existing contact that might have updated location
      final contact = contactsProvider.findContactByKey(publicKey);
      if (contact != null) {
        debugPrint(
          '   Existing contact "${contact.advName}" - fetching updated contact info (optimized)',
        );
        // Trigger a single contact fetch to get the updated contact information
        // This is much more efficient than fetching all contacts
        Future.delayed(const Duration(milliseconds: 100), () {
          if (connectionProvider.deviceInfo.isConnected) {
            connectionProvider.getContact(publicKey);
          }
        });
      } else {
        if (_autoAddDiscoveredContacts) {
          debugPrint('   Unknown contact - auto-add enabled, fetching details');
          Future.delayed(const Duration(milliseconds: 100), () {
            if (connectionProvider.deviceInfo.isConnected) {
              connectionProvider.getContact(publicKey);
            }
          });
        } else {
          contactsProvider.addPendingAdvert(
            publicKey,
            devicePublicKey: connectionProvider.deviceInfo.publicKey,
          );
          debugPrint(
            '   Unknown contact - added to pending adverts list and waiting for details',
          );
        }
      }
    };

    // When firmware deletes a contact due to contacts table overflow (PUSH_CODE_CONTACT_DELETED 0x8F)
    connectionProvider.onContactDeleted = (publicKey) {
      final keyHex = publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      final contact = contactsProvider.findContactByKey(publicKey);
      final name = contact?.advName ?? keyHex.substring(0, 12);
      debugPrint('⚠️ [AppProvider] Contact deleted by firmware: $name');
      contactsProvider.removeContact(keyHex);
      messagesProvider.logSystemMessage(
        text: 'Contact "$name" was removed — device contacts table is full',
        level: 'warning',
      );
    };

    // When firmware reports contacts storage is full (PUSH_CODE_CONTACTS_FULL 0x90)
    connectionProvider.onContactsFull = () {
      debugPrint('⚠️ [AppProvider] Contacts storage full');
      messagesProvider.logSystemMessage(
        text:
            'Device contacts storage is full. New contacts will overwrite old ones.',
        level: 'warning',
      );
    };

    // When a message is sent (RESP_CODE_SENT received)
    connectionProvider
        .onMessageSent = (messageId, expectedAckTag, suggestedTimeoutMs) {
      debugPrint(
        '📤 [AppProvider] Message sent - Message ID: $messageId, ACK tag: $expectedAckTag',
      );
      messagesProvider.markMessageSent(
        messageId,
        expectedAckTag,
        suggestedTimeoutMs,
      );
    };

    // When a message is delivered (PUSH_CODE_SEND_CONFIRMED received)
    connectionProvider.onMessageDelivered = (ackCode, roundTripTimeMs) {
      debugPrint(
        '✅ [AppProvider] Message delivered - ACK: $ackCode, RTT: ${roundTripTimeMs}ms',
      );
      messagesProvider.markMessageDelivered(ackCode, roundTripTimeMs);
    };

    // When an echo is detected for a public channel message (PUSH_CODE_LOG_RX_DATA matched)
    connectionProvider
        .onMessageEchoDetected = (messageId, echoCount, snrRaw, rssiDbm) {
      debugPrint(
        '🔊 [AppProvider] Echo detected - Message: $messageId, Count: $echoCount',
      );
      messagesProvider.handleMessageEcho(messageId, echoCount, snrRaw, rssiDbm);
    };

    // Wire up MessagesProvider's sendMessageCallback for retry logic
    messagesProvider.sendMessageCallback =
        ({
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

    messagesProvider.onDirectPathFailedCallback =
        ({required contact, required failureStreak}) async {
          debugPrint(
            '🧭 [AppProvider] Clearing unhealthy path for ${contact.advName} after $failureStreak failed send chain(s)',
          );

          contactsProvider.markPathUnhealthy(contact.publicKey);

          if (!connectionProvider.deviceInfo.isConnected) {
            return;
          }

          try {
            await connectionProvider.resetPath(contact.publicKey);
            Future.delayed(const Duration(milliseconds: 150), () {
              if (connectionProvider.deviceInfo.isConnected) {
                connectionProvider.getContact(contact.publicKey);
              }
            });
          } catch (e) {
            debugPrint(
              '⚠️ [AppProvider] Failed to reset path for ${contact.advName}: $e',
            );
          }
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
      debugPrint(
        '📻 [AppProvider] Syncing channels${_isSimpleMode ? ' (simple mode: max 5)' : ''}...',
      );
      await connectionProvider.syncChannels(maxChannels: channelsToSync);
      debugPrint('✅ [AppProvider] Channel sync complete');

      // Configure the default public channel (channel 0)
      // This must be done before sending any channel messages
      // Note: Some firmware versions may have this pre-configured
      debugPrint(
        '📻 [AppProvider] Configuring default public channel (channel 0)...',
      );
      try {
        await connectionProvider.configureDefaultPublicChannel();
        debugPrint('✅ [AppProvider] Public channel configured successfully');
      } catch (e) {
        debugPrint(
          '⚠️ [AppProvider] Public channel configuration failed (may already be configured): $e',
        );
        // Continue anyway - channel might already be configured in firmware
      }

      // Automatically login to all saved rooms
      await _autoLoginToRooms();

      // FALLBACK: Sync messages once after connection to catch any missed push notifications
      // This handles the case where messages arrived while the app was disconnected
      debugPrint(
        '🔄 [AppProvider] Performing initial message sync (fallback for missed pushes)',
      );
      final initialMessageCount = await connectionProvider.syncAllMessages();
      debugPrint(
        '📥 [AppProvider] Initial sync retrieved $initialMessageCount message(s)',
      );

      // Note: Future messages are synced automatically via PUSH_CODE_MSG_WAITING events

      // Start location tracking AFTER all initialization is complete
      debugPrint(
        '📍 [AppProvider] Starting location tracking after successful initialization',
      );
      await _startLocationTracking();

      // Sync drawing messages with DrawingProvider
      // This restores any drawings that may be missing from storage
      debugPrint(
        '🎨 [AppProvider] Syncing drawing messages with DrawingProvider...',
      );
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

      debugPrint(
        '📂 [AppProvider] Found ${rooms.length} room(s), attempting auto-login...',
      );

      final prefs = await SharedPreferences.getInstance();

      for (final room in rooms) {
        try {
          // Load saved password for this room
          final roomKey = 'room_password_${room.publicKeyHex}';
          final savedPassword = prefs.getString(roomKey) ?? 'hello';

          debugPrint(
            '🔑 [AppProvider] Auto-logging into room: ${room.advName}',
          );

          // Set up one-time callbacks for this room login
          await _loginToRoomWithCallback(room, savedPassword);

          // Small delay between logins to avoid overwhelming the device
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint(
            '❌ [AppProvider] Failed to auto-login to ${room.advName}: $e',
          );
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
    connectionProvider
        .onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint('✅ [AppProvider] Auto-login successful for ${room.advName}');
      debugPrint(
        '📡 [AppProvider] Room server will push messages automatically via PUSH_CODE_MSG_WAITING',
      );

      completer.complete(true);
    };

    connectionProvider.onLoginFail = (publicKeyPrefix) {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint(
        '❌ [AppProvider] Auto-login failed for ${room.advName} (incorrect password)',
      );
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
      debugPrint(
        '❌ [AppProvider] Error during auto-login to ${room.advName}: $e',
      );
    }
  }

  Contact? _resolveContactByPrefixHex(String prefixHex) {
    if (prefixHex.length != 12) return null;
    return contactsProvider.findContactByPrefixHex(prefixHex.toLowerCase());
  }

  Contact? _resolveImageFetchRequester(ImageFetchRequest request) {
    final liveContact = _resolveContactByPrefixHex(request.requesterKey6);
    if (liveContact != null) {
      return liveContact;
    }

    for (final message in messagesProvider.messages.reversed) {
      final envelope = ImageEnvelope.tryParse(message.text);
      if (envelope == null || envelope.sessionId != request.sessionId) {
        continue;
      }
      final recipientKey = message.recipientPublicKey;
      if (recipientKey == null || recipientKey.isEmpty) {
        continue;
      }
      final recipient = contactsProvider.findContactByKey(recipientKey);
      if (recipient == null) {
        continue;
      }
      final recipientKey6 = recipient.publicKey
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (recipientKey6 != request.requesterKey6) {
        continue;
      }
      debugPrint(
        '📷 [AppProvider] Resolved image requester from sent message metadata '
        'for session ${request.sessionId}: ${recipient.advName}',
      );
      return recipient;
    }

    return null;
  }

  void _scheduleVoiceMissingRetry(
    String sessionId, {
    required bool justComplete,
  }) {
    if (justComplete || voiceProvider.isComplete(sessionId)) {
      _voiceMissingRetryTimers.remove(sessionId)?.cancel();
      _voiceMissingRetryAttempts.remove(sessionId);
      return;
    }

    _voiceMissingRetryAttempts[sessionId] = 0;
    _voiceMissingRetryTimers[sessionId]?.cancel();
    _voiceMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingVoicePackets(sessionId));
    });
  }

  Future<void> _requestMissingVoicePackets(String sessionId) async {
    if (voiceProvider.isComplete(sessionId)) {
      _voiceMissingRetryTimers.remove(sessionId)?.cancel();
      _voiceMissingRetryAttempts.remove(sessionId);
      return;
    }

    final attempt = _voiceMissingRetryAttempts[sessionId] ?? 0;
    if (attempt >= _maxPacketRetryAttempts) {
      debugPrint(
        '⚠️ [AppProvider] Voice re-request limit reached for $sessionId',
      );
      _voiceMissingRetryTimers.remove(sessionId)?.cancel();
      return;
    }

    final senderKey6 = _voiceSessionSenderKey6[sessionId];
    if (senderKey6 == null) return;
    final sender = _resolveContactByPrefixHex(senderKey6);
    final deviceKey = connectionProvider.deviceInfo.publicKey;
    if (sender == null || deviceKey == null || deviceKey.length < 6) return;

    final missing = voiceProvider.missingPacketIndices(sessionId);
    if (missing.isEmpty) {
      _voiceMissingRetryTimers.remove(sessionId)?.cancel();
      _voiceMissingRetryAttempts.remove(sessionId);
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    final request = VoiceFetchRequest(
      sessionId: sessionId,
      want: 'missing',
      missingIndices: missing,
      requesterKey6: requesterKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      version: 2,
    );

    try {
      await connectionProvider.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.outPathLen,
        payload: request.encodeBinary(),
      );
    } catch (_) {
      return;
    }

    _voiceMissingRetryAttempts[sessionId] = attempt + 1;
    _voiceMissingRetryTimers[sessionId]?.cancel();
    _voiceMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingVoicePackets(sessionId));
    });
  }

  /// Insert or update a voice placeholder message for binary raw-data packets.
  ///
  /// Binary voice packets arrive without a chat message, so we synthesise one
  /// to give the user a playable bubble in the message list.
  void _handleIncomingVoicePacket(
    VoicePacket pkt, {
    required bool justComplete,
  }) {
    final sessionId = pkt.sessionId;

    // Check if a placeholder for this session already exists
    final existing = messagesProvider.messages
        .where((m) => m.isVoice && m.voiceId == sessionId)
        .firstOrNull;

    if (existing != null) {
      // Already have a placeholder — no need to add another
      return;
    }

    // First packet of a new session: insert placeholder message
    final msgId = 'voice_$sessionId';
    final placeholder = Message(
      id: msgId,
      messageType: MessageType.contact, // direct contact (binary only)
      senderPublicKeyPrefix: null,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      // Persist the first real packet in legacy V: text form so UI/debug paths
      // can reconstruct packet metadata from actual data.
      text: pkt.encodeText(),
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.received,
      isVoice: true,
      voiceId: sessionId,
    );
    messagesProvider.addMessage(placeholder, contactLookup: (_) => '');
  }

  String _fragmentAckKey(String sessionId, int index) => '$sessionId:$index';

  Future<bool> _waitForVoiceFragmentAck({
    required String sessionId,
    required int index,
    Duration timeout = const Duration(seconds: 8),
  }) => _voiceFragmentAckWaiters.waitFor(
    _fragmentAckKey(sessionId, index),
    timeout: timeout,
  );

  void _completeVoiceFragmentAck(String sessionId, int index) {
    final completed = _voiceFragmentAckWaiters.complete(
      _fragmentAckKey(sessionId, index),
    );
    if (completed == 0) {
      debugPrint(
        'ℹ️ [AppProvider] Voice fragment ACK had no waiter: $sessionId#$index',
      );
      return;
    }
    debugPrint(
      '✅ [AppProvider] Voice fragment ACK received for $sessionId#$index ($completed waiter(s))',
    );
  }

  Future<bool> _waitForImageFragmentAck({
    required String sessionId,
    required int index,
    Duration timeout = const Duration(seconds: 8),
  }) => _imageFragmentAckWaiters.waitFor(
    _fragmentAckKey(sessionId, index),
    timeout: timeout,
  );

  void _completeImageFragmentAck(String sessionId, int index) {
    final completed = _imageFragmentAckWaiters.complete(
      _fragmentAckKey(sessionId, index),
    );
    if (completed == 0) {
      debugPrint(
        'ℹ️ [AppProvider] Image fragment ACK had no waiter: $sessionId#$index',
      );
      return;
    }
    debugPrint(
      '✅ [AppProvider] Image fragment ACK received for $sessionId#$index ($completed waiter(s))',
    );
  }

  void _sendVoiceFragmentAck(VoicePacket packet) {
    final senderKey6 = _voiceSessionSenderKey6[packet.sessionId];
    if (senderKey6 == null) return;
    final sender = _resolveContactByPrefixHex(senderKey6);
    if (sender == null) return;
    if (sender.outPathLen < 0 || sender.outPathLen > _maxDirectPayloadHops) {
      return;
    }
    unawaited(
      connectionProvider.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.outPathLen,
        payload: VoiceFragmentAck(
          sessionId: packet.sessionId,
          index: packet.index,
        ).encodeBinary(),
      ),
    );
  }

  void _sendImageFragmentAck(ImagePacket fragment) {
    final senderKey6 = _imageSessionSenderKey6[fragment.sessionId];
    if (senderKey6 == null) return;
    final sender = _resolveContactByPrefixHex(senderKey6);
    if (sender == null) return;
    if (sender.outPathLen < 0 || sender.outPathLen > _maxDirectPayloadHops) {
      return;
    }
    unawaited(
      connectionProvider.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.outPathLen,
        payload: ImageFragmentAck(
          sessionId: fragment.sessionId,
          index: fragment.index,
        ).encodeBinary(),
      ),
    );
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
      debugPrint(
        '🔄 [AppProvider] Manual message sync requested (user initiated)',
      );
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint(
        '✅ [AppProvider] Manual sync completed: $messageCount messages',
      );
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
      debugPrint(
        '🔴 [AppProvider] BLE disconnected - stopping location tracking',
      );
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
    unawaited(voiceProvider.clearStoredVoiceData());
    unawaited(imageProvider.clearAll());
    for (final timer in _voiceMissingRetryTimers.values) {
      timer.cancel();
    }
    _voiceMissingRetryTimers.clear();
    _voiceMissingRetryAttempts.clear();
    _voiceSessionSenderKey6.clear();
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

  @override
  void dispose() {
    _packetCaptureFlushTimer?.cancel();
    unawaited(_flushPacketCaptureLogs());
    // Remove connection state listener
    connectionProvider.removeListener(_handleConnectionStateChange);
    // Clear location service callbacks
    locationTrackingService.onPositionUpdate = null;
    locationTrackingService.onBroadcastSent = null;
    locationTrackingService.onError = null;
    locationTrackingService.onTrackingStateChanged = null;
    // Dispose the location tracking service to stop GPS stream and clean up resources
    locationTrackingService.dispose();
    for (final timer in _voiceMissingRetryTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
