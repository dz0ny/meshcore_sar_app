import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../widgets/messages/sar_update_sheet.dart';
import '../widgets/messages/recipient_selector_sheet.dart';
import '../widgets/messages/message_bubble.dart';
import '../services/message_destination_preferences.dart';
import '../services/voice_bitrate_preferences.dart';
import '../services/voice_recorder_service.dart';
import '../services/voice_codec_service.dart';
import '../utils/toast_logger.dart';
import '../utils/key_comparison.dart';
import '../utils/voice_message_parser.dart';
import '../utils/image_message_parser.dart';
import '../providers/image_provider.dart' as ip;
import '../services/image_codec_service.dart';
import '../services/image_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';

class MessagesTab extends StatefulWidget {
  final VoidCallback? onNavigateToMap;

  const MessagesTab({super.key, this.onNavigateToMap});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _characterCount = 0;
  static const int _maxCharacters = 160;
  String? _highlightedMessageId;
  Timer? _highlightTimer; // Timer for clearing message highlight

  // Message destination state
  String _destinationType =
      MessageDestinationPreferences.destinationTypeChannel;
  Contact? _selectedRecipient;

  // Image sending state
  bool _isSendingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Voice recording state
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  bool _isRecording = false;
  bool _isSendingVoice = false;
  static const int _maxVoicePackets = 10;
  static const double _silenceRmsThreshold = 500.0;
  static const double _silencePeakThreshold = 1400.0;
  static const int _maxInteriorSilentChunks = 2;
  bool get _voiceSupported => Platform.isIOS || Platform.isAndroid;
  StreamSubscription<Int16List>? _voiceStreamSub;
  String? _currentVoiceSessionId;
  final List<Int16List> _recordedChunks = [];
  VoicePacketMode? _activeVoiceMode;
  int _selectedVoiceBitrate = VoiceBitratePreferences.defaultBitrate;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCharacterCount);
    // Load saved message destination
    _loadSavedDestination();
    _loadVoiceBitrate();
    // Mark all messages as read when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().markAllAsRead();
      _checkForNavigationRequest();
    });
  }

  Future<void> _loadVoiceBitrate() async {
    final bitrate = await VoiceBitratePreferences.getBitrate();
    if (!mounted) return;
    setState(() {
      _selectedVoiceBitrate = bitrate;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload saved destination and check for navigation request whenever dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedDestination();
      _checkForNavigationRequest();
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _voiceStreamSub?.cancel();
    _voiceRecorder.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForNavigationRequest() {
    final messagesProvider = context.read<MessagesProvider>();
    final targetMessageId = messagesProvider.targetMessageId;

    if (targetMessageId != null) {
      _scrollToMessage(targetMessageId);
      messagesProvider.clearMessageNavigation();
    }
  }

  void _scrollToMessage(String messageId) {
    final messagesProvider = context.read<MessagesProvider>();
    final messages = _getFilteredMessages(messagesProvider);

    final messageIndex = messages.indexWhere((m) => m.id == messageId);

    if (messageIndex != -1 && _scrollController.hasClients) {
      // Calculate position - accounting for reverse list
      final itemHeight = 80.0; // Approximate height of a message bubble
      final targetOffset = messageIndex * itemHeight;

      // Scroll to the message
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Highlight the message briefly
      setState(() {
        _highlightedMessageId = messageId;
      });

      // Clear highlight after 2 seconds using a properly managed Timer
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _textController.text.length;
    });
  }

  /// Load saved message destination from preferences
  Future<void> _loadSavedDestination() async {
    final savedDestination =
        await MessageDestinationPreferences.getDestination();

    if (savedDestination == null || !mounted) {
      // Default to public channel
      return;
    }

    final type = savedDestination['type']!;
    final publicKey = savedDestination['publicKey'];

    setState(() {
      _destinationType = type;
    });

    // If it's a contact or room, try to find it in the contacts list
    if (publicKey != null && mounted) {
      final contactsProvider = context.read<ContactsProvider>();
      final contact = contactsProvider.contacts.where((c) {
        return c.publicKeyHex == publicKey;
      }).firstOrNull;

      if (contact != null) {
        setState(() {
          _selectedRecipient = contact;
        });
      } else {
        // Contact/room not found, fallback to public channel
        debugPrint(
          '⚠️ [MessagesTab] Saved recipient not found, falling back to public channel',
        );
        setState(() {
          _destinationType =
              MessageDestinationPreferences.destinationTypeChannel;
          _selectedRecipient = null;
        });
        await MessageDestinationPreferences.clearDestination();
      }
    }
  }

  /// Show recipient selector bottom sheet
  void _showRecipientSelector() {
    final contactsProvider = context.read<ContactsProvider>();

    // Filter contacts by type
    final contacts = contactsProvider.contacts
        .where((c) => c.type == ContactType.chat)
        .toList();
    final rooms = contactsProvider.contacts
        .where((c) => c.type == ContactType.room)
        .toList();
    final channels = contactsProvider.contacts
        .where((c) => c.type == ContactType.channel)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipientSelectorSheet(
        contacts: contacts,
        rooms: rooms,
        channels: channels,
        currentDestinationType: _destinationType,
        currentRecipientPublicKey: _selectedRecipient?.publicKeyHex,
        onSelect: _onRecipientSelected,
      ),
    );
  }

  /// Handle recipient selection
  Future<void> _onRecipientSelected(String type, Contact? recipient) async {
    setState(() {
      _destinationType = type;
      _selectedRecipient = recipient;
    });

    // Save to preferences
    await MessageDestinationPreferences.setDestination(
      type,
      recipientPublicKey: recipient?.publicKeyHex,
    );

    // Show confirmation toast
    if (!mounted) return;
  }

  /// Get icon for current destination type
  IconData _getDestinationIcon() {
    if (_destinationType ==
        MessageDestinationPreferences.destinationTypeChannel) {
      return Icons.public;
    } else if (_destinationType ==
        MessageDestinationPreferences.destinationTypeRoom) {
      return Icons.meeting_room;
    } else {
      return Icons.person;
    }
  }

  /// Get tooltip for destination button
  String _getDestinationTooltip() {
    if (_destinationType ==
            MessageDestinationPreferences.destinationTypeChannel &&
        _selectedRecipient != null) {
      final channelName = _selectedRecipient!.getLocalizedDisplayName(context);
      return '$channelName (tap to change)';
    } else if (_selectedRecipient != null) {
      final recipientName = _selectedRecipient!.displayName;
      return '$recipientName (tap to change)';
    }
    return 'Select recipient';
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final contactsProvider = context.read<ContactsProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    try {
      // Check destination type and send accordingly
      if (_destinationType ==
          MessageDestinationPreferences.destinationTypeChannel) {
        // Send to selected channel (or public channel if none selected)
        final channelIdx =
            _selectedRecipient?.publicKey[1] ??
            0; // Extract channel index from pseudo public key
        await _sendToChannel(
          text,
          connectionProvider,
          messagesProvider,
          channelIdx,
        );
      } else if (_selectedRecipient != null) {
        // Send to contact or room
        await _sendToRecipient(
          text,
          connectionProvider,
          messagesProvider,
          contactsProvider,
        );
      } else {
        // Fallback to public channel if no recipient selected
        debugPrint(
          '⚠️ [MessagesTab] No recipient selected, falling back to public channel',
        );
        await _sendToChannel(text, connectionProvider, messagesProvider, 0);
      }

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send: $e');
    }
  }

  /// Send message to channel
  Future<void> _sendToChannel(
    String text,
    ConnectionProvider connectionProvider,
    MessagesProvider messagesProvider,
    int channelIdx,
  ) async {
    // Create message ID
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_channel_sent';
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Get current device's public key (first 6 bytes)
    final devicePublicKey = connectionProvider.deviceInfo.publicKey;
    final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

    // Create sent message object
    final sentMessage = Message(
      id: messageId,
      messageType: MessageType.channel,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: timestamp,
      text: text,
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      channelIdx: channelIdx,
    );

    // Add to messages list with "sending" status
    messagesProvider.addSentMessage(sentMessage);

    // Send to selected channel
    await connectionProvider.sendChannelMessage(
      channelIdx: channelIdx,
      text: text,
      messageId: messageId,
    );
  }

  /// Send message to contact or room
  Future<void> _sendToRecipient(
    String text,
    ConnectionProvider connectionProvider,
    MessagesProvider messagesProvider,
    ContactsProvider contactsProvider,
  ) async {
    if (_selectedRecipient == null) return;

    // Create message ID
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_sent';
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Get current device's public key (first 6 bytes)
    final devicePublicKey = connectionProvider.deviceInfo.publicKey;
    final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

    // Create sent message object with recipient public key for retry support
    final sentMessage = Message(
      id: messageId,
      messageType: MessageType.contact,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: timestamp,
      text: text,
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      recipientPublicKey: _selectedRecipient!.publicKey,
    );

    // Add to messages list with "sending" status
    messagesProvider.addSentMessage(sentMessage);

    // Send message to selected recipient
    final sentSuccessfully = await connectionProvider.sendTextMessage(
      contactPublicKey: _selectedRecipient!.publicKey,
      text: text,
      messageId: messageId,
      contact: _selectedRecipient,
    );

    if (!sentSuccessfully) {
      // Mark message as failed if sending failed
      messagesProvider.markMessageFailed(messageId);
    }
  }

  // ── Image sending ───────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_isSendingImage) return;
    final connectionProvider = context.read<ConnectionProvider>();
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    // Pick image.
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;
    final rawBytes = await picked.readAsBytes();

    setState(() => _isSendingImage = true);
    try {
      // Compress AVIF using user-selected size, compression and color mode.
      final maxSize = await ImagePreferences.getMaxSize();
      final compression = await ImagePreferences.getCompression();
      final grayscale = await ImagePreferences.getGrayscale();
      final ultraMode = await ImagePreferences.getUltraMode();
      final effectiveMaxSize = ImagePreferences.effectiveMaxSize(
        maxSize,
        ultraMode: ultraMode,
      );
      final result = await ImageCodecService.compress(
        rawBytes,
        maxDimension: effectiveMaxSize,
        compression: compression,
        grayscale: grayscale,
        ultraMode: ultraMode,
      );
      if (result == null) {
        if (!mounted) return;
        ToastLogger.error(context, 'Image compression failed');
        return;
      }
      final compressed = result.bytes;

      // Generate session ID (4 random bytes → 8 hex chars).
      final sessionId = List.generate(
        8,
        (_) => math.Random().nextInt(16).toRadixString(16),
      ).join();

      // Fragment.
      var imageDataBytesPerFragment = ImagePacket.maxDataBytes;
      if (_destinationType ==
              MessageDestinationPreferences.destinationTypeContact &&
          _selectedRecipient != null &&
          _selectedRecipient!.outPathLen >= 0) {
        imageDataBytesPerFragment = safeImageDataBytesForPath(
          _selectedRecipient!.outPathLen,
        );
      }

      final fragments = fragmentImage(
        sessionId: sessionId,
        format: ImageFormat.avif,
        bytes: compressed,
        maxDataBytes: imageDataBytesPerFragment,
      );

      if (fragments.isEmpty) {
        if (!mounted) return;
        ToastLogger.error(context, 'Image fragmentation failed');
        return;
      }

      // Build envelope.
      final deviceKey = connectionProvider.deviceInfo.publicKey;
      if (deviceKey == null || deviceKey.length < 6) {
        if (!mounted) return;
        ToastLogger.error(context, 'Device key unavailable');
        return;
      }
      final senderKey6 = deviceKey
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      final envelope = ImageEnvelope(
        sessionId: sessionId,
        format: ImageFormat.avif,
        total: fragments.length,
        width: result.width,
        height: result.height,
        sizeBytes: compressed.length,
        senderKey6: senderKey6,
        timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      if (!mounted) return;

      // Cache for deferred serving.
      final imageProvider = context.read<ip.ImageProvider>();
      imageProvider.cacheOutgoingSession(sessionId, fragments, envelope);

      // Add local placeholder message.
      final messagesProvider = context.read<MessagesProvider>();
      final msgId = 'img_${sessionId}_sent';
      final isChannel =
          _destinationType ==
          MessageDestinationPreferences.destinationTypeChannel;
      final placeholder = Message(
        id: msgId,
        messageType: isChannel ? MessageType.channel : MessageType.contact,
        channelIdx: isChannel ? 0 : null,
        senderPublicKeyPrefix: deviceKey.sublist(0, 6),
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        text: envelope.encode(),
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
      );
      messagesProvider.addSentMessage(placeholder);

      // Send IE1 envelope via normal message path.
      final envelopeText = envelope.encode();
      if (_destinationType ==
          MessageDestinationPreferences.destinationTypeChannel) {
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: envelopeText,
          messageId: msgId,
        );
      } else if (_selectedRecipient != null) {
        final sent = await connectionProvider.sendTextMessage(
          contactPublicKey: _selectedRecipient!.publicKey,
          text: envelopeText,
          messageId: msgId,
          contact: _selectedRecipient!,
        );
        if (!sent) {
          messagesProvider.markMessageFailed(msgId);
          if (!mounted) return;
          ToastLogger.error(context, 'Failed to announce image');
        }
      }

      debugPrint(
        '📷 [Image] Sent IE1 for session $sessionId: '
        '${fragments.length} fragments, ${compressed.length}B, '
        'chunk=${imageDataBytesPerFragment}B',
      );
    } catch (e, st) {
      debugPrint('❌ [Image] _pickAndSendImage: $e\n$st');
      if (!mounted) return;
      ToastLogger.error(context, 'Image send failed');
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  // ── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startVoiceRecording() async {
    if (_isSendingVoice || _isRecording) return;
    debugPrint('🎙️ [Voice] _startVoiceRecording called');
    // Read fresh bitrate preference so settings changes apply immediately.
    final selectedBitrate = await VoiceBitratePreferences.getBitrate();
    if (mounted) {
      setState(() {
        _selectedVoiceBitrate = selectedBitrate;
      });
    } else {
      _selectedVoiceBitrate = selectedBitrate;
    }
    final hasPermission = await _voiceRecorder.requestPermission();
    debugPrint('🎙️ [Voice] hasPermission=$hasPermission');
    if (!hasPermission) {
      if (!mounted) return;
      ToastLogger.error(context, 'Microphone permission required for voice');
      return;
    }

    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    debugPrint(
      '🎙️ [Voice] isConnected=${connectionProvider.deviceInfo.isConnected}',
    );
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    // Generate a new session ID (4 random bytes → 8 hex chars)
    final rng = math.Random.secure();
    _currentVoiceSessionId = List.generate(
      4,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    _activeVoiceMode = VoiceBitratePreferences.toVoiceMode(
      _selectedVoiceBitrate,
    );
    final packetDuration = Duration(
      milliseconds: codec2ModeFor(_activeVoiceMode!).packetDurationMs,
    );

    debugPrint(
      '🎙️ [Voice] session=$_currentVoiceSessionId mode=$_activeVoiceMode chunkDuration=${packetDuration.inMilliseconds}ms',
    );

    _recordedChunks.clear();
    setState(() => _isRecording = true);

    try {
      final stream = _voiceRecorder.startCapture(
        chunkDuration: packetDuration,
        enableBandPassFilter: appProvider.isVoiceBandPassFilterEnabled,
        enableCompressor: appProvider.isVoiceCompressorEnabled,
        enableLimiter: appProvider.isVoiceLimiterEnabled,
      );
      debugPrint('🎙️ [Voice] capture started, listening for chunks...');
      _voiceStreamSub = stream.listen(
        (pcmChunk) {
          if (!_isRecording) return;
          _recordedChunks.add(pcmChunk);
          debugPrint(
            '🎙️ [Voice] chunk #${_recordedChunks.length} received: ${pcmChunk.length} samples',
          );
          setState(() {});
          if (_recordedChunks.length >= _maxVoicePackets) {
            debugPrint('🎙️ [Voice] max packets reached, stopping');
            _stopAndSendVoice();
          }
        },
        onError: (e) {
          debugPrint('❌ [Voice] stream error: $e');
          _stopAndSendVoice();
        },
        onDone: () => debugPrint('🎙️ [Voice] stream done'),
      );
    } catch (e) {
      debugPrint('❌ [Voice] startCapture threw: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopAndSendVoice() async {
    if (!_isRecording) return;
    final trimSilenceEnabled = context
        .read<AppProvider>()
        .isVoiceSilenceTrimmingEnabled;
    debugPrint(
      '🎙️ [Voice] _stopAndSendVoice: ${_recordedChunks.length} chunks buffered',
    );

    await _voiceStreamSub?.cancel();
    _voiceStreamSub = null;
    await _voiceRecorder.stopCapture();

    final rawChunks = List<Int16List>.from(_recordedChunks);
    final chunks = trimSilenceEnabled ? _trimSilence(rawChunks) : rawChunks;
    final sessionId = _currentVoiceSessionId;
    final mode = _activeVoiceMode;
    _recordedChunks.clear();

    debugPrint(
      '🎙️ [Voice] silence trim enabled=$trimSilenceEnabled: raw=${rawChunks.length} chunks -> kept=${chunks.length} chunks',
    );

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isSendingVoice = chunks.isNotEmpty && sessionId != null;
      });
    }

    if (chunks.isEmpty || sessionId == null || mode == null || !mounted) {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _currentVoiceSessionId = null;
        });
      }
      return;
    }

    try {
      await _encodeAndSendAllPackets(
        chunks: chunks,
        sessionId: sessionId,
        mode: mode,
      );
    } catch (e, st) {
      debugPrint('❌ [Voice] _encodeAndSendAllPackets threw: $e\n$st');
    } finally {
      debugPrint(
        '🎙️ [Voice] _stopAndSendVoice finally: resetting _isSendingVoice',
      );
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _currentVoiceSessionId = null;
        });
      }
    }
  }

  Future<void> _encodeAndSendAllPackets({
    required List<Int16List> chunks,
    required String sessionId,
    required VoicePacketMode mode,
  }) async {
    final total = chunks.length;
    final codec = VoiceCodecService();
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final voiceProvider = context.read<VoiceProvider>();

    // Insert the chat placeholder before sending (so it appears immediately).
    final msgId = 'voice_${sessionId}_sent';
    final devicePublicKey = connectionProvider.deviceInfo.publicKey;
    final senderPublicKeyPrefix =
        devicePublicKey != null && devicePublicKey.length >= 6
        ? devicePublicKey.sublist(0, 6)
        : null;
    final isChannel =
        _destinationType ==
        MessageDestinationPreferences.destinationTypeChannel;
    final sentMsg = Message(
      id: msgId,
      messageType: (!isChannel && _selectedRecipient != null)
          ? MessageType.contact
          : MessageType.channel,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      text: '',
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sent,
      isVoice: true,
      voiceId: sessionId,
      channelIdx: isChannel ? (_selectedRecipient?.publicKey[1] ?? 0) : null,
      recipientPublicKey: _selectedRecipient?.publicKey,
    );
    messagesProvider.addSentMessage(sentMsg);

    final encodedPackets = <VoicePacket>[];
    debugPrint(
      '🎙️ [Voice] encoding $total packets for deferred voice fetch, mode=${mode.label}, session=$sessionId',
    );
    for (var i = 0; i < total; i++) {
      if (!mounted) return;
      try {
        final codec2Data = await codec.encode(chunks[i], mode);
        debugPrint(
          '🎙️ [Voice] packet $i/$total encoded: ${codec2Data.length} bytes',
        );
        final packet = VoicePacket(
          sessionId: sessionId,
          mode: mode,
          index: i,
          total: total,
          codec2Data: codec2Data,
        );

        encodedPackets.add(packet);
        voiceProvider.addPacket(packet);
      } catch (e, st) {
        debugPrint('❌ [Voice] packet $i encode error: $e\n$st');
      }
    }

    if (encodedPackets.isEmpty) {
      debugPrint('❌ [Voice] No packets encoded for session $sessionId');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    voiceProvider.cacheOutgoingSession(sessionId, encodedPackets);

    if (senderPublicKeyPrefix == null || senderPublicKeyPrefix.length < 6) {
      debugPrint('❌ [Voice] Missing device public key prefix for envelope');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    final senderKey6 = senderPublicKeyPrefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final durationMs = encodedPackets.fold<int>(
      0,
      (sum, p) => sum + p.durationMs,
    );
    final envelope = VoiceEnvelope(
      sessionId: sessionId,
      mode: mode,
      total: encodedPackets.length,
      durationMs: durationMs,
      senderKey6: senderKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      version: 1,
    );
    final envelopeText = envelope.encodeText();

    try {
      if (isChannel) {
        final channelIdx = _selectedRecipient?.publicKey[1] ?? 0;
        await connectionProvider.sendChannelMessage(
          channelIdx: channelIdx,
          text: envelopeText,
          messageId: msgId,
        );
      } else if (_selectedRecipient != null) {
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: _selectedRecipient!.publicKey,
          text: envelopeText,
          messageId: msgId,
          contact: _selectedRecipient,
        );
        if (!sentSuccessfully) {
          messagesProvider.markMessageFailed(msgId);
          return;
        }
      } else {
        // Fallback to public channel if destination cannot be resolved.
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: envelopeText,
          messageId: msgId,
        );
      }
    } catch (e, st) {
      debugPrint('❌ [Voice] envelope send error: $e\n$st');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    debugPrint('🎙️ [Voice] envelope sent for session $sessionId');
    // Mark the placeholder message as "sent" (ackTag=0, timeout=0 = no ACK tracking).
    // addSentMessage() forces deliveryStatus.sending; we upgrade it here so the
    // bubble shows "Sent" instead of "Sending" once all packets are on the wire.
    // For channels this is also set by the onMessageSent callback, but this is harmless.
    messagesProvider.markMessageSent(msgId, 0, 0);
  }

  List<Int16List> _trimSilence(List<Int16List> chunks) {
    if (chunks.isEmpty) return chunks;

    final isSilent = chunks.map(_isSilentChunk).toList();
    final firstVoice = isSilent.indexWhere((silent) => !silent);
    if (firstVoice == -1) return const [];

    final lastVoice = isSilent.lastIndexWhere((silent) => !silent);
    if (lastVoice < firstVoice) return const [];

    final trimmed = <Int16List>[];
    var interiorSilentRun = 0;
    for (var i = firstVoice; i <= lastVoice; i++) {
      if (isSilent[i]) {
        interiorSilentRun++;
        if (interiorSilentRun <= _maxInteriorSilentChunks) {
          trimmed.add(chunks[i]);
        }
      } else {
        interiorSilentRun = 0;
        trimmed.add(chunks[i]);
      }
    }
    return trimmed;
  }

  bool _isSilentChunk(Int16List chunk) {
    if (chunk.isEmpty) return true;

    var sumSquares = 0.0;
    var peak = 0;
    for (final sample in chunk) {
      final absSample = sample.abs();
      if (absSample > peak) peak = absSample;
      sumSquares += sample * sample;
    }

    final rms = math.sqrt(sumSquares / chunk.length);
    return rms < _silenceRmsThreshold && peak < _silencePeakThreshold;
  }

  // ── SAR dialog ─────────────────────────────────────────────────────────────

  void _showSarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarUpdateSheet(
        onSend:
            (
              emoji,
              name,
              position,
              roomPublicKey,
              sendToChannel,
              sendToAllContacts,
              colorIndex,
            ) async {
              await _sendSarMessage(
                emoji,
                name,
                position,
                roomPublicKey,
                sendToChannel,
                sendToAllContacts,
                colorIndex,
              );
            },
      ),
    );
  }

  void _showComposerActions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_location_alt),
                title: Text(AppLocalizations.of(context)!.sendSarMarker),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSarDialog();
                },
              ),
              if (_voiceSupported)
                ListTile(
                  enabled: !_isSendingVoice,
                  leading: Icon(_isRecording ? Icons.stop : Icons.mic),
                  title: Text(_isRecording ? 'Stop recording' : 'Record voice'),
                  onTap: _isSendingVoice
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          if (_isRecording) {
                            _stopAndSendVoice();
                          } else {
                            _startVoiceRecording();
                          }
                        },
                ),
              ListTile(
                enabled: !_isSendingImage,
                leading: const Icon(Icons.photo_library),
                title: const Text('Send image from gallery'),
                onTap: _isSendingImage
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _pickAndSendImage(source: ImageSource.gallery);
                      },
              ),
              ListTile(
                enabled: !_isSendingImage,
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take photo'),
                onTap: _isSendingImage
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        _pickAndSendImage(source: ImageSource.camera);
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendSarMessage(
    String emoji,
    String name,
    Position position,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    bool sendToAllContacts,
    int colorIndex,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    if (!sendToChannel && !sendToAllContacts && roomPublicKey == null) {
      if (!mounted) return;
      ToastLogger.error(
        context,
        'Please select a destination to send SAR marker',
      );
      return;
    }

    try {
      // New format: S:<emoji>:<colorIndex>:<latitude>,<longitude>:<name>
      // Round coordinates to 5 decimal places (~1m accuracy) since most GPS is only that accurate
      final sarMessage =
          'S:$emoji:${colorIndex.toString()}:${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)}:$name';

      if (sendToAllContacts) {
        // Send to all chat contacts (ContactType.chat)
        final contactsProvider = context.read<ContactsProvider>();
        final chatContacts = contactsProvider.chatContacts;

        if (chatContacts.isEmpty) {
          if (!mounted) return;
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.noContactsAvailable,
          );
          return;
        }

        // Create a single grouped message instead of multiple individual messages
        final groupId = '${DateTime.now().millisecondsSinceEpoch}_group';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create recipient list
        final recipients = chatContacts.map((contact) {
          return MessageRecipient(
            publicKey: contact.publicKey,
            displayName: contact.displayName,
            deliveryStatus: MessageDeliveryStatus.sending,
            sentAt: DateTime.now(),
          );
        }).toList();

        // Create single grouped message
        final groupedMessage = Message(
          id: groupId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          groupId: groupId,
          recipients: recipients,
        );

        // Add the grouped message to the list
        messagesProvider.addSentMessage(groupedMessage);

        // Send to each contact and track status
        int successCount = 0;
        for (final contact in chatContacts) {
          final individualMessageId = '${groupId}_${contact.publicKeyShort}';

          // Register this individual send as part of the grouped message
          messagesProvider.registerGroupedMessageSend(
            individualMessageId,
            groupId,
            contact.publicKey,
          );

          // Send SAR message to contact (with ACK tracking)
          final sentSuccessfully = await connectionProvider.sendTextMessage(
            contactPublicKey: contact.publicKey,
            text: sarMessage,
            messageId: individualMessageId,
            contact: contact,
          );

          if (sentSuccessfully) {
            successCount++;
          } else {
            // Update recipient status in grouped message
            messagesProvider.updateGroupedMessageRecipientStatus(
              groupId,
              contact.publicKey,
              MessageDeliveryStatus.failed,
            );
          }

          // Add 1 second delay between sends to ensure:
          // 1. Different timestamps (messages sent in different seconds)
          // 2. Radio has time to fully process previous message and assign ACK tag
          // This ensures each message gets a unique ACK tag from the radio
          if (contact != chatContacts.last) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!mounted) return;
        ToastLogger.success(
          context,
          AppLocalizations.of(context)!.sarMarkerSentToContacts(successCount),
        );
      } else if (sendToChannel) {
        // Create message ID
        final messageId =
            '${DateTime.now().millisecondsSinceEpoch}_channel_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Get current device's public key (first 6 bytes)
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create sent message object
        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.channel,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          channelIdx: 0,
          // SAR marker data is automatically added by SarMessageParser.enhanceMessage in MessagesProvider
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        // Send to public channel (ephemeral, over-the-air only)
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: sarMessage,
          messageId: messageId,
        );

        if (!mounted) return;
      } else {
        // Create message ID
        final messageId = '${DateTime.now().millisecondsSinceEpoch}_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Get current device's public key (first 6 bytes)
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create sent message object with recipient public key for retry support
        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          recipientPublicKey: roomPublicKey, // Store recipient for retry
          // SAR marker data is automatically added by SarMessageParser.enhanceMessage in MessagesProvider
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >= roomPublicKey!.length &&
              c.publicKey.matches(roomPublicKey);
        }).firstOrNull;

        // Send SAR message to selected room (persisted and immutable)
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: roomPublicKey!,
          text: sarMessage,
          messageId: messageId, // Pass message ID so it can be tracked
          contact: roomContact, // Include contact for path status logging
        );

        if (!sentSuccessfully) {
          // Mark message as failed if sending failed
          messagesProvider.markMessageFailed(messageId);
        }

        if (!mounted) return;
        ToastLogger.success(context, 'SAR marker sent to room');
      }
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send SAR marker: $e');
    }
  }

  /// Handle pull-to-refresh for manual message sync
  /// This is a FALLBACK mechanism - messages are normally synced automatically via PUSH_CODE_MSG_WAITING
  Future<void> _handleRefresh() async {
    final connectionProvider = context.read<ConnectionProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.warning(context, 'Not connected - cannot sync messages');
      return;
    }

    try {
      debugPrint(
        '🔄 [MessagesTab] Manual refresh triggered - syncing messages',
      );
      if (!mounted) return;
    } catch (e) {
      debugPrint('❌ [MessagesTab] Sync error: $e');
      if (!mounted) return;
      ToastLogger.error(context, 'Sync failed: $e');
    }
  }

  List<Message> _getFilteredMessages(MessagesProvider messagesProvider) {
    // Get all recent messages
    final allMessages = messagesProvider.getRecentMessages(count: 100);

    // Get simple mode setting from AppProvider
    final appProvider = context.read<AppProvider>();
    final isSimpleMode = appProvider.isSimpleMode;

    List<Message> filteredMessages;

    // If public channel is selected, show ALL messages
    if (_destinationType ==
            MessageDestinationPreferences.destinationTypeChannel &&
        _selectedRecipient == null) {
      filteredMessages = allMessages;
    }
    // If a contact or room is selected, filter by recipient
    else if ((_destinationType ==
                MessageDestinationPreferences.destinationTypeContact ||
            _destinationType ==
                MessageDestinationPreferences.destinationTypeRoom) &&
        _selectedRecipient != null) {
      filteredMessages = allMessages.where((message) {
        // Include messages sent TO this recipient
        if (message.recipientPublicKey != null &&
            message.recipientPublicKey!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          // Compare first 6 bytes (public key prefix)
          final recipientPrefix = message.recipientPublicKey!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (recipientPrefix.matches(selectedPrefix)) {
            return true;
          }
        }

        // Include messages received FROM this recipient
        if (message.senderPublicKeyPrefix != null &&
            message.senderPublicKeyPrefix!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          final senderPrefix = message.senderPublicKeyPrefix!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (senderPrefix.matches(selectedPrefix)) {
            return true;
          }
        }

        return false;
      }).toList();
    } else {
      // Default: show all messages (fallback case)
      filteredMessages = allMessages;
    }

    // In simple mode, filter out system messages (toast logs)
    if (isSimpleMode) {
      filteredMessages = filteredMessages
          .where((message) => !message.isSystemMessage)
          .toList();
    }

    return filteredMessages;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, child) {
        final messages = _getFilteredMessages(messagesProvider);

        return Column(
          children: [
            // Messages list with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: messages.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.message_outlined,
                                        size: 64,
                                        color: Theme.of(context).disabledColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.noMessagesYet,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.pullDownToSync,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isHighlighted =
                              message.id == _highlightedMessageId;

                          return MessageBubble(
                            key: ValueKey(message.id),
                            message: message,
                            isHighlighted: isHighlighted,
                            onNavigateToMap: widget.onNavigateToMap,
                            onTap:
                                widget.onNavigateToMap != null &&
                                    message.isSarMarker &&
                                    message.sarGpsCoordinates != null
                                ? () {
                                    final mapProvider = context
                                        .read<MapProvider>();
                                    mapProvider.navigateToLocation(
                                      location: message.sarGpsCoordinates!,
                                      zoom: 15.0,
                                    );
                                    widget.onNavigateToMap?.call();
                                  }
                                : widget.onNavigateToMap != null &&
                                      message.isDrawing &&
                                      message.drawingId != null
                                ? () {
                                    debugPrint(
                                      '🗺️ [MessagesTab] Drawing tapped! ID: ${message.drawingId}',
                                    );
                                    final mapProvider = context
                                        .read<MapProvider>();
                                    final drawingProvider = context
                                        .read<DrawingProvider>();
                                    mapProvider.navigateToDrawing(
                                      message.drawingId!,
                                      drawingProvider,
                                    );
                                    widget.onNavigateToMap?.call();
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ),

            // Message input area
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quick actions (+) button
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.add),
                    tooltip: _isRecording ? 'Stop recording' : 'More actions',
                    onPressed: _isRecording
                        ? _stopAndSendVoice
                        : _showComposerActions,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: _isRecording
                          ? Colors.red
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Destination switcher button
                  IconButton(
                    icon: Icon(_getDestinationIcon()),
                    tooltip: _getDestinationTooltip(),
                    onPressed: _showRecipientSelector,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _destinationType ==
                              MessageDestinationPreferences
                                  .destinationTypeChannel
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          _destinationType ==
                              MessageDestinationPreferences
                                  .destinationTypeChannel
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Text field with embedded send button
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLength: _maxCharacters,
                      maxLines: null,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeYourMessage,
                        hintStyle: const TextStyle(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                        counterText: _characterCount >= 150
                            ? '$_characterCount/$_maxCharacters'
                            : '',
                        counterStyle: TextStyle(
                          fontSize: 10,
                          color: _characterCount > _maxCharacters * 0.9
                              ? Colors.orange
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        suffixIcon: GestureDetector(
                          onLongPressStart:
                              (_voiceSupported && !_isSendingVoice)
                              ? (_) => _startVoiceRecording()
                              : null,
                          onLongPressEnd: (_voiceSupported && _isRecording)
                              ? (_) => _stopAndSendVoice()
                              : null,
                          onLongPressCancel: (_voiceSupported && _isRecording)
                              ? () => _stopAndSendVoice()
                              : null,
                          child: IconButton(
                            icon: _isSendingVoice
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _isRecording
                                        ? Icons.mic
                                        : Icons.send_rounded,
                                    size: 22,
                                    color: _isRecording
                                        ? Colors.red
                                        : (_textController.text.trim().isEmpty
                                              ? Theme.of(context).disabledColor
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary),
                                  ),
                            onPressed:
                                _isRecording ||
                                    _isSendingVoice ||
                                    _textController.text.trim().isEmpty
                                ? null
                                : _sendMessage,
                            tooltip: _isRecording
                                ? 'Recording... release to send voice'
                                : (_isSendingVoice
                                      ? 'Sending voice...'
                                      : _voiceSupported
                                      ? 'Send (long press to record voice)'
                                      : 'Send'),
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
