import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/message_contact_location.dart';
import '../models/message_reception_details.dart';
import '../models/message_transfer_details.dart';
import '../models/sar_marker.dart';
import '../models/map_drawing.dart';
import '../services/message_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/sar_message_parser.dart';
import '../utils/drawing_message_parser.dart';
import '../utils/voice_message_parser.dart';
import '../utils/image_message_parser.dart';
import '../l10n/app_localizations.dart';
import 'helpers/message_retry_manager.dart';

/// Messages Provider - manages message history and SAR markers
class MessagesProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final Map<String, SarMarker> _sarMarkers = {};
  final MessageStorageService _storageService = MessageStorageService();
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  AppLocalizations? _localizations;
  final Map<String, MessageContactLocation> _messageContactLocations = {};
  final Map<String, MessageReceptionDetails> _messageReceptionDetails = {};
  final Map<String, MessageTransferDetails> _messageTransferDetails = {};

  // Track pending sent messages by expected ACK/TAG
  final Map<int, Message> _pendingSentMessages = {};

  // Track timeout timers for pending messages
  // Key: message ID (not ACK tag, since multiple messages can share same ACK)
  final Map<String, Timer> _timeoutTimers = {};

  // Recently completed ACKs are kept briefly to ignore duplicate confirms.
  final Map<int, DateTime> _completedAckHistory = {};

  // Preserve ACK tags assigned to a message across retries.
  final Map<String, Set<int>> _messageAckHistory = {};
  final Map<int, (String, DateTime)> _ackHistoryLookup = {};

  // Retry management
  final MessageRetryManager _retryManager = MessageRetryManager();

  // Track which contact each sent message was sent to (for retry logic)
  final Map<String, Contact> _messageContactMap = {};

  // Track individual message IDs to grouped message mapping
  // Key: individual message ID (e.g., "123_abc"), Value: (groupId, recipientPublicKey)
  final Map<String, (String, Uint8List)> _groupedMessageMapping = {};

  // ACK tag → List of (groupId, recipientPublicKey) mapping for grouped messages
  // Multiple recipients can share the same ACK tag since they're sent in sequence
  // Each ACK delivery removes one recipient from the list
  final Map<int, List<(String, Uint8List)>> _ackTagToRecipients = {};

  // Navigation state for message highlighting/scrolling
  String? _targetMessageId;

  // Helper function to compare Uint8List for equality
  bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Callback to connection provider for sending messages (set by AppProvider)
  Future<bool> Function({
    required Uint8List contactPublicKey,
    required String text,
    required String messageId,
    required Contact contact,
    int retryAttempt,
  })?
  sendMessageCallback;

  Future<void> Function({required Contact contact, required int failureStreak})?
  onDirectPathFailedCallback;

  String? Function(Uint8List? publicKey)? resolveContactNameCallback;
  String Function(int channelIdx)? resolveChannelNameCallback;

  List<Message> get messages => List.unmodifiable(_messages);

  List<Message> get contactMessages =>
      _messages.where((m) => m.isContactMessage).toList();

  List<Message> get channelMessages =>
      _messages.where((m) => m.isChannelMessage).toList();

  List<Message> get sarMarkerMessages =>
      _messages.where((m) => m.isSarMarker).toList();

  List<Message> get systemMessages =>
      _messages.where((m) => m.isSystemMessage).toList();

  List<SarMarker> get sarMarkers => _sarMarkers.values.toList();

  List<SarMarker> get foundPersonMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.foundPerson).toList();

  List<SarMarker> get fireMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.fire).toList();

  List<SarMarker> get stagingAreaMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.stagingArea).toList();

  List<SarMarker> get objectMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.object).toList();

  bool get isInitialized => _isInitialized;

  String? get targetMessageId => _targetMessageId;

  MessageContactLocation? getMessageContactLocation(String messageId) =>
      _messageContactLocations[messageId];

  MessageReceptionDetails? getMessageReceptionDetails(String messageId) =>
      _messageReceptionDetails[messageId];

  MessageTransferDetails? getMessageTransferDetails(String messageId) =>
      _messageTransferDetails[messageId];

  /// Set localizations for notifications
  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }

  /// Navigate to a specific message (scroll and highlight)
  void navigateToMessage(String messageId) {
    _targetMessageId = messageId;
    notifyListeners();
  }

  /// Clear message navigation state
  void clearMessageNavigation() {
    _targetMessageId = null;
  }

  /// Get count of unread messages (excluding sent messages and system messages)
  int get unreadCount => _messages
      .where((m) => !m.isRead && !m.isSentMessage && !m.isSystemMessage)
      .length;

  /// Initialize and load persisted messages
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📦 [MessagesProvider] Loading persisted messages...');
      final storedMessages = await _storageService.loadMessages();
      final storedContactLocations = await _storageService
          .loadMessageContactLocations();
      final storedReceptionDetails = await _storageService
          .loadMessageReceptionDetails();
      final storedTransferDetails = await _storageService
          .loadMessageTransferDetails();
      _messageContactLocations
        ..clear()
        ..addAll(storedContactLocations);
      _messageReceptionDetails
        ..clear()
        ..addAll(storedReceptionDetails);
      _messageTransferDetails
        ..clear()
        ..addAll(storedTransferDetails);

      // Add stored messages with enhancement to ensure SAR detection
      for (final message in storedMessages) {
        // Re-enhance each message to ensure SAR markers are properly detected
        // This handles cases where messages were stored before enhancement logic
        var enhancedMessage = SarMessageParser.enhanceMessage(message);

        // Check if it's a drawing message (D:...) and not already marked
        // This handles cases where messages were stored before drawing detection
        if (DrawingMessageParser.isDrawingMessage(enhancedMessage.text) &&
            !enhancedMessage.isDrawing) {
          debugPrint(
            '🎨 [MessagesProvider] Detected drawing message during initialization: ${enhancedMessage.id}',
          );
          // Parse the drawing to get its ID
          final drawing = DrawingMessageParser.parseDrawingMessage(
            enhancedMessage.text,
            senderName: enhancedMessage.senderName,
            messageId: enhancedMessage.id,
          );

          // Mark message as drawing and link to drawing ID
          enhancedMessage = enhancedMessage.copyWith(
            isDrawing: true,
            drawingId: drawing?.id,
          );
          debugPrint(
            '   Drawing ID: ${enhancedMessage.drawingId}, isDrawing: ${enhancedMessage.isDrawing}',
          );
        }

        // Check if it's a voice envelope/message and not already marked.
        if (!enhancedMessage.isVoice) {
          final envelope = VoiceEnvelope.tryParseText(enhancedMessage.text);
          if (envelope != null) {
            enhancedMessage = enhancedMessage.copyWith(
              isVoice: true,
              voiceId: envelope.sessionId,
            );
          }
        }

        _messages.add(enhancedMessage);

        // Extract SAR markers
        if (enhancedMessage.isSarMarker) {
          final marker = enhancedMessage.toSarMarker();
          if (marker != null) {
            _sarMarkers[marker.id] = marker;
          }
        }
      }

      _isInitialized = true;
      debugPrint(
        '✅ [MessagesProvider] Loaded ${storedMessages.length} persisted messages',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [MessagesProvider] Error initializing: $e');
      _isInitialized = true; // Mark as initialized even on error
    }
  }

  /// Sync drawing messages with DrawingProvider
  /// This restores drawings that may be missing from DrawingProvider storage
  /// Should be called after both providers are initialized
  void syncDrawingsWithProvider(dynamic drawingProvider) {
    debugPrint(
      '🔄 [MessagesProvider] Syncing drawings with DrawingProvider...',
    );
    int restoredCount = 0;

    for (final message in _messages) {
      if (!message.isDrawing || message.drawingId == null) continue;

      // Check if drawing exists in DrawingProvider
      final existingDrawing = drawingProvider.getDrawingById(
        message.drawingId!,
      );
      if (existingDrawing != null) {
        continue; // Drawing already exists
      }

      // Drawing is missing, reconstruct from message text
      debugPrint(
        '🔧 [MessagesProvider] Restoring missing drawing: ${message.drawingId}',
      );
      final drawing = DrawingMessageParser.parseDrawingMessage(
        message.text,
        senderName: message.senderName,
        messageId: message.id,
      );

      if (drawing == null) {
        debugPrint(
          '⚠️ [MessagesProvider] Failed to parse drawing from message ${message.id}',
        );
        continue;
      }

      // The parsed drawing has a new generated ID, but we need to use the original ID
      // Create a copy with the correct ID from the message
      final restoredDrawing = _createDrawingWithId(drawing, message.drawingId!);

      if (restoredDrawing != null) {
        drawingProvider.addReceivedDrawing(restoredDrawing);
        restoredCount++;
        debugPrint(
          '✅ [MessagesProvider] Restored drawing ${message.drawingId}',
        );
      }
    }

    debugPrint(
      '✅ [MessagesProvider] Sync complete: restored $restoredCount drawings',
    );
  }

  /// Create a copy of a drawing with a specific ID
  dynamic _createDrawingWithId(dynamic drawing, String targetId) {
    if (drawing is LineDrawing) {
      return LineDrawing(
        id: targetId,
        color: drawing.color,
        createdAt: drawing.createdAt,
        points: drawing.points,
        senderName: drawing.senderName,
        isReceived: drawing.isReceived,
        messageId: drawing.messageId,
        isShared: drawing.isShared,
      );
    } else if (drawing is RectangleDrawing) {
      return RectangleDrawing(
        id: targetId,
        color: drawing.color,
        createdAt: drawing.createdAt,
        topLeft: drawing.topLeft,
        bottomRight: drawing.bottomRight,
        senderName: drawing.senderName,
        isReceived: drawing.isReceived,
        messageId: drawing.messageId,
        isShared: drawing.isShared,
      );
    }
    return null;
  }

  /// Add a message
  /// If [contactLookup] function is provided, it will be used to match channel
  /// message senders with known contacts by name
  void addMessage(
    Message message, {
    String Function(String name)? contactLookup,
    MessageContactLocation? contactLocationSnapshot,
    MessageReceptionDetails? receptionDetailsSnapshot,
  }) {
    // Always enhance message with SAR parser to detect SAR markers
    var enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Check if it's a drawing message (D:...) and not already marked
    // Don't overwrite if already set by the sender (preserves correct drawing ID)
    if (DrawingMessageParser.isDrawingMessage(enhancedMessage.text) &&
        !enhancedMessage.isDrawing) {
      // Parse the drawing to get its ID
      final drawing = DrawingMessageParser.parseDrawingMessage(
        enhancedMessage.text,
        senderName: enhancedMessage.senderName,
        messageId: enhancedMessage.id,
      );

      // Mark message as drawing and link to drawing ID
      enhancedMessage = enhancedMessage.copyWith(
        isDrawing: true,
        drawingId: drawing?.id,
      );
    }

    // Check if it's a voice message (VE1:/V:) and not already marked.
    if (!enhancedMessage.isVoice) {
      final envelope = VoiceEnvelope.tryParseText(enhancedMessage.text);
      if (envelope != null) {
        enhancedMessage = enhancedMessage.copyWith(
          isVoice: true,
          voiceId: envelope.sessionId,
        );
      }
    }

    // For channel messages with sender name, try to link with contact
    Message finalMessage = enhancedMessage;
    if (enhancedMessage.isChannelMessage &&
        enhancedMessage.senderName != null &&
        contactLookup != null) {
      // Look up contact public key by name
      final publicKeyHex = contactLookup(enhancedMessage.senderName!);
      if (publicKeyHex.isNotEmpty) {
        // Convert hex string to bytes (first 6 bytes)
        final publicKeyBytes = <int>[];
        for (int i = 0; i < 12 && i < publicKeyHex.length; i += 2) {
          final byteString = publicKeyHex.substring(i, i + 2);
          publicKeyBytes.add(int.parse(byteString, radix: 16));
        }

        if (publicKeyBytes.length == 6) {
          // Add public key prefix to message
          finalMessage = enhancedMessage.copyWith(
            senderPublicKeyPrefix: Uint8List.fromList(publicKeyBytes),
          );
        }
      }
    }

    // Debug: Check if message is SAR
    if (message.text.startsWith('S:')) {
      debugPrint(
        '🔍 [MessagesProvider] Processing SAR message: ${message.text}',
      );
      debugPrint('   isSarMarker: ${finalMessage.isSarMarker}');
      debugPrint('   sarMarkerType: ${finalMessage.sarMarkerType}');
    }

    // Check for duplicates before adding
    // Messages can arrive multiple times due to:
    // - Mesh network retransmissions
    // - Multiple paths in the network
    // - Syncing messages from device queue
    if (_isDuplicate(finalMessage)) {
      debugPrint(
        '⚠️ [MessagesProvider] Duplicate message detected, skipping: ${finalMessage.id}',
      );
      debugPrint(
        '   Text: ${finalMessage.text.substring(0, finalMessage.text.length > 50 ? 50 : finalMessage.text.length)}...',
      );
      final existingIndex = _messages.indexWhere(
        (existing) =>
            existing.messageType == finalMessage.messageType &&
            existing.senderTimestamp == finalMessage.senderTimestamp &&
            existing.text == finalMessage.text,
      );
      if (existingIndex != -1) {
        final existingId = _messages[existingIndex].id;
        if (contactLocationSnapshot != null) {
          _messageContactLocations[existingId] = contactLocationSnapshot;
        }
        if (receptionDetailsSnapshot != null) {
          _messageReceptionDetails[existingId] = receptionDetailsSnapshot;
        }
        _persistMessages();
      }
      return; // Skip duplicate
    }

    _messages.add(finalMessage);
    if (contactLocationSnapshot != null) {
      _messageContactLocations[finalMessage.id] = contactLocationSnapshot;
    }
    if (receptionDetailsSnapshot != null) {
      _messageReceptionDetails[finalMessage.id] = receptionDetailsSnapshot;
    }

    // If it's a SAR marker message, extract and store the marker
    if (finalMessage.isSarMarker) {
      final marker = finalMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;

        // Trigger urgent notification for received SAR messages (not sent by user)
        if (!finalMessage.isSentMessage) {
          _triggerSarNotification(finalMessage, marker);
        }
      }
    } else if (!finalMessage.isSentMessage && !finalMessage.isSystemMessage) {
      // Trigger notification for regular messages (not SAR, not sent by user, not system)
      _triggerMessageNotification(finalMessage);
    }

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Check if a message is a duplicate
  ///
  /// Messages are considered duplicates if they have:
  /// 1. Same sender public key prefix (for contact messages)
  /// 2. Same channel index (for channel messages)
  /// 3. Same sender timestamp
  /// 4. Same text content
  ///
  /// Note: Sent messages (isSentMessage=true) are NEVER duplicates
  /// because they can be retried with different message IDs
  bool _isDuplicate(Message message) {
    // Sent messages (our own messages) should never be considered duplicates
    // They can be retried multiple times with different IDs
    if (message.isSentMessage) {
      return false;
    }

    return _messages.any((existing) {
      // Check message type matches
      if (existing.messageType != message.messageType) {
        return false;
      }

      // Check sender matches
      if (message.isContactMessage) {
        // For contact messages, compare sender public key prefix
        if (existing.senderKeyShort != message.senderKeyShort) {
          return false;
        }
      } else if (message.isChannelMessage) {
        // For channel messages, compare channel index
        if (existing.channelIdx != message.channelIdx) {
          return false;
        }
      }

      // Check timestamp matches (sender timestamp is the unique identifier from the sender)
      if (existing.senderTimestamp != message.senderTimestamp) {
        return false;
      }

      // Check text content matches
      if (existing.text != message.text) {
        return false;
      }

      // All criteria match - this is a duplicate
      return true;
    });
  }

  /// Add multiple messages
  void addMessages(List<Message> messages) {
    int addedCount = 0;
    int duplicateCount = 0;

    for (final message in messages) {
      // Always enhance message with SAR parser to detect SAR markers
      final enhancedMessage = SarMessageParser.enhanceMessage(message);

      // Check for duplicates
      if (_isDuplicate(enhancedMessage)) {
        duplicateCount++;
        continue; // Skip duplicate
      }

      _messages.add(enhancedMessage);
      addedCount++;

      if (enhancedMessage.isSarMarker) {
        final marker = enhancedMessage.toSarMarker();
        if (marker != null) {
          _sarMarkers[marker.id] = marker;
        }
      }
    }

    debugPrint(
      '📥 [MessagesProvider] Added $addedCount messages, skipped $duplicateCount duplicates',
    );

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Trigger urgent notification for SAR marker
  Future<void> _triggerSarNotification(
    Message message,
    SarMarker marker,
  ) async {
    try {
      // Format coordinates
      final coords =
          '${marker.location.latitude.toStringAsFixed(5)}, ${marker.location.longitude.toStringAsFixed(5)}';

      // Get sender name from message
      final senderName =
          message.senderName ?? message.senderKeyShort ?? 'Unknown';

      debugPrint(
        '🔔 [MessagesProvider] Triggering SAR notification for ${marker.type.displayName}',
      );
      debugPrint('   Sender: $senderName');
      debugPrint('   Coordinates: $coords');

      await _notificationService.showSarNotification(
        type: marker.type,
        senderName: senderName,
        coordinates: coords,
        notes: marker.notes,
        localizations: _localizations,
      );
    } catch (e) {
      debugPrint('❌ [MessagesProvider] Error triggering SAR notification: $e');
    }
  }

  /// Trigger notification for regular message
  Future<void> _triggerMessageNotification(Message message) async {
    try {
      final senderName = _resolveParticipantName(
        publicKey: message.senderPublicKeyPrefix,
        fallback: message.senderName ?? message.senderKeyShort,
      );
      final isChannelMessage = message.isChannelMessage;
      final channelName = isChannelMessage
          ? _resolveChannelName(message.channelIdx)
          : null;
      final messageText = _buildNotificationMessageText(
        message,
        senderName: senderName,
        isChannelMessage: isChannelMessage,
        channelName: channelName,
      );

      debugPrint('🔔 [MessagesProvider] Triggering message notification');
      debugPrint('   Sender: $senderName');
      debugPrint('   Type: ${isChannelMessage ? "Channel" : "Direct"}');
      debugPrint(
        '   Message: ${messageText.substring(0, messageText.length > 50 ? 50 : messageText.length)}...',
      );

      await _notificationService.showMessageNotification(
        senderName: senderName,
        messageText: messageText,
        isChannelMessage: isChannelMessage,
        channelName: channelName,
        localizations: _localizations,
      );
    } catch (e) {
      debugPrint(
        '❌ [MessagesProvider] Error triggering message notification: $e',
      );
    }
  }

  String _resolveParticipantName({
    required Uint8List? publicKey,
    String? fallback,
  }) {
    final resolved = resolveContactNameCallback?.call(publicKey)?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }
    return 'Unknown';
  }

  String _resolveChannelName(int? channelIdx) {
    final idx = channelIdx ?? 0;
    final resolved = resolveChannelNameCallback?.call(idx).trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    return idx == 0 ? 'Public' : 'Channel $idx';
  }

  String _buildNotificationMessageText(
    Message message, {
    required String senderName,
    required bool isChannelMessage,
    String? channelName,
  }) {
    final voiceEnvelope = VoiceEnvelope.tryParseText(message.text);
    if (voiceEnvelope != null) {
      final seconds = (voiceEnvelope.durationMs / 1000).ceil();
      final summary =
          'Voice message - ${voiceEnvelope.mode.label} - ${seconds}s - ${voiceEnvelope.total} packets';
      return isChannelMessage ? '$senderName\n$summary' : summary;
    }

    final imageEnvelope = ImageEnvelope.tryParse(message.text);
    if (imageEnvelope != null) {
      final summary =
          'Image - ${imageEnvelope.format.label} - ${imageEnvelope.width}x${imageEnvelope.height} - ${_formatBytes(imageEnvelope.sizeBytes)}';
      return isChannelMessage ? '$senderName\n$summary' : summary;
    }

    if (!isChannelMessage && message.recipientPublicKey != null) {
      final recipientName = _resolveParticipantName(
        publicKey: message.recipientPublicKey,
        fallback: null,
      );
      if (recipientName != 'Unknown') {
        return 'To: $recipientName\n${message.text}';
      }
    }

    if (isChannelMessage) {
      return '$senderName\n${message.text}';
    }

    return message.text;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(kib >= 10 ? 0 : 1)} KB';
    final mib = kib / 1024;
    return '${mib.toStringAsFixed(mib >= 10 ? 0 : 1)} MB';
  }

  /// Persist messages to storage (async, non-blocking)
  Future<void> _persistMessages() async {
    try {
      await _storageService.saveMessages(
        _messages,
        messageContactLocations: _messageContactLocations,
        messageReceptionDetails: _messageReceptionDetails,
        messageTransferDetails: _messageTransferDetails,
      );
    } catch (e) {
      debugPrint('❌ [MessagesProvider] Error persisting messages: $e');
    }
  }

  /// Get messages for a specific contact
  List<Message> getMessagesForContact(String senderKeyShort) {
    return _messages
        .where(
          (m) =>
              m.isContactMessage &&
              m.senderKeyShort != null &&
              m.senderKeyShort!.startsWith(senderKeyShort),
        )
        .toList();
  }

  /// Get messages for a specific channel
  List<Message> getMessagesForChannel(int channelIdx) {
    return _messages
        .where((m) => m.isChannelMessage && m.channelIdx == channelIdx)
        .toList();
  }

  /// Get recent messages (last N messages)
  List<Message> getRecentMessages({int count = 50}) {
    final sorted = List<Message>.from(_messages)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted.take(count).toList();
  }

  /// Get messages from last N hours
  List<Message> getMessagesSince(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _messages.where((m) => m.sentAt.isAfter(cutoff)).toList();
  }

  /// Search messages by text
  List<Message> searchMessages(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _messages
        .where((m) => m.text.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get SAR marker by ID
  SarMarker? getSarMarker(String id) {
    return _sarMarkers[id];
  }

  /// Get recent SAR markers (within last hour)
  List<SarMarker> getRecentSarMarkers() {
    return sarMarkers.where((m) => m.isRecent).toList();
  }

  /// Remove a SAR marker
  void removeSarMarker(String id) {
    _sarMarkers.remove(id);
    notifyListeners();
  }

  /// Mark all messages as read
  void markAllAsRead() {
    bool hasChanges = false;
    for (int i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead &&
          !_messages[i].isSentMessage &&
          !_messages[i].isSystemMessage) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _persistMessages();
      notifyListeners();
    }
  }

  /// Mark a specific message as read
  void markAsRead(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && !_messages[index].isRead) {
      _messages[index] = _messages[index].copyWith(isRead: true);
      _persistMessages();
      notifyListeners();
    }
  }

  /// Delete a specific message by ID
  void deleteMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];

      // If it's a SAR marker message, also remove the marker
      if (message.isSarMarker) {
        final marker = message.toSarMarker();
        if (marker != null) {
          _sarMarkers.remove(marker.id);
        }
      }

      // Remove from messages list
      _messages.removeAt(index);

      // Cancel timeout timer if it exists
      _timeoutTimers[message.id]?.cancel();
      _timeoutTimers.remove(message.id);
      if (message.expectedAckTag != null) {
        _pendingSentMessages.remove(message.expectedAckTag);
      }
      _messageContactMap.remove(messageId);
      _groupedMessageMapping.remove(messageId);
      _messageContactLocations.remove(messageId);
      _messageReceptionDetails.remove(messageId);
      _messageTransferDetails.remove(messageId);

      debugPrint('🗑️ [MessagesProvider] Message $messageId deleted');

      _persistMessages();
      notifyListeners();
    }
  }

  /// Delete a drawing message and its linked drawing
  void deleteDrawingMessage(String messageId, dynamic drawingProvider) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final message = _messages[index];

    // If the message has a linked drawing, remove it
    if (message.drawingId != null && drawingProvider != null) {
      // Remove the drawing (DrawingProvider will handle removing this message)
      drawingProvider.removeDrawing(message.drawingId!);
    } else {
      // No linked drawing, just delete the message
      deleteMessage(messageId);
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _sarMarkers.clear();
    _messageContactLocations.clear();
    _messageReceptionDetails.clear();
    _messageTransferDetails.clear();
    _persistMessages();
    notifyListeners();
  }

  /// Clear all SAR markers
  void clearSarMarkers() {
    _sarMarkers.clear();
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _messages.clear();
    _sarMarkers.clear();
    _messageContactLocations.clear();
    _messageReceptionDetails.clear();
    _messageTransferDetails.clear();
    _persistMessages();
    notifyListeners();
  }

  int transferCountForSession({
    String? voiceSessionId,
    String? imageSessionId,
  }) {
    final messageId = _findMessageIdByMediaSession(
      voiceSessionId: voiceSessionId,
      imageSessionId: imageSessionId,
    );
    if (messageId == null) return 0;
    return _messageTransferDetails[messageId]?.totalTransfers ?? 0;
  }

  void recordMediaTransfer({
    required String sessionId,
    required String mediaType,
    required String requesterKey6,
    String? requesterName,
  }) {
    final messageId = _findMessageIdByMediaSession(
      voiceSessionId: mediaType == 'voice' ? sessionId : null,
      imageSessionId: mediaType == 'image' ? sessionId : null,
    );
    if (messageId == null) {
      debugPrint(
        '⚠️ [MessagesProvider] No message found for $mediaType session $sessionId',
      );
      return;
    }

    final current =
        _messageTransferDetails[messageId] ??
        const MessageTransferDetails.empty();
    _messageTransferDetails[messageId] = current.registerTransfer(
      requesterKey6: requesterKey6,
      requesterName: requesterName,
    );
    _persistMessages();
    notifyListeners();
  }

  String? _findMessageIdByMediaSession({
    String? voiceSessionId,
    String? imageSessionId,
  }) {
    for (final message in _messages.reversed) {
      if (voiceSessionId != null && message.voiceId == voiceSessionId) {
        return message.id;
      }
      if (imageSessionId != null) {
        final envelope = ImageEnvelope.tryParse(message.text);
        if (envelope != null && envelope.sessionId == imageSessionId) {
          return message.id;
        }
      }
    }
    return null;
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats();
  }

  /// Get message statistics
  Map<String, int> get messageStats {
    return {
      'total': _messages.length,
      'contact': contactMessages.length,
      'channel': channelMessages.length,
      'sar': sarMarkerMessages.length,
      'system': systemMessages.length,
      'sarMarkers': sarMarkers.length,
    };
  }

  /// Log a system message (replaces toast notifications)
  void logSystemMessage({
    required String text,
    String level = 'info', // 'info', 'success', 'warning', 'error'
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_system_$level';

    final systemMessage = Message(
      id: messageId,
      messageType: MessageType.system,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: timestamp,
      text: text,
      receivedAt: DateTime.now(),
      senderName: level, // Use senderName to store log level
      deliveryStatus: MessageDeliveryStatus.received,
    );

    _messages.add(systemMessage);

    // Don't persist system messages to reduce storage
    // _persistMessages();

    notifyListeners();
  }

  /// Get SAR marker statistics
  Map<String, int> get sarMarkerStats {
    return {
      'total': sarMarkers.length,
      'foundPerson': foundPersonMarkers.length,
      'fire': fireMarkers.length,
      'stagingArea': stagingAreaMarkers.length,
      'object': objectMarkers.length,
    };
  }

  /// Add a sent message with initial status
  void addSentMessage(Message message, {Contact? contact}) {
    debugPrint('📝 [MessagesProvider] addSentMessage called');
    debugPrint('  Message ID: ${message.id}');
    debugPrint('  Message type: ${message.messageType}');
    debugPrint('  Initial status: ${message.deliveryStatus}');
    debugPrint(
      '  Message text preview: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...',
    );

    // Always enhance message with SAR parser to detect SAR markers
    var enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Check if it's a drawing message (D:...) and not already marked
    // Don't overwrite if already set by the sender (preserves correct drawing ID)
    if (DrawingMessageParser.isDrawingMessage(enhancedMessage.text) &&
        !enhancedMessage.isDrawing) {
      // Parse the drawing to get its ID
      final drawing = DrawingMessageParser.parseDrawingMessage(
        enhancedMessage.text,
        senderName: enhancedMessage.senderName,
        messageId: enhancedMessage.id,
      );

      // Mark message as drawing and link to drawing ID
      enhancedMessage = enhancedMessage.copyWith(
        isDrawing: true,
        drawingId: drawing?.id,
      );
    }

    // Check if it's a voice message (VE1:/V:) and not already marked.
    if (!enhancedMessage.isVoice) {
      final envelope = VoiceEnvelope.tryParseText(enhancedMessage.text);
      if (envelope != null) {
        enhancedMessage = enhancedMessage.copyWith(
          isVoice: true,
          voiceId: envelope.sessionId,
        );
      }
    }

    // Check for duplicates (shouldn't happen for sent messages, but be safe)
    if (_isDuplicate(enhancedMessage)) {
      debugPrint(
        '⚠️ [MessagesProvider] Duplicate sent message detected, skipping: ${enhancedMessage.id}',
      );
      return;
    }

    // Add message with sending status and mark as read (sent messages are always read)
    final sendingMessage = enhancedMessage.copyWith(
      deliveryStatus: MessageDeliveryStatus.sending,
      isRead: true, // Sent messages are always marked as read
    );
    _messages.add(sendingMessage);
    debugPrint('  ✅ Message added to list at index ${_messages.length - 1}');
    debugPrint('  Total messages in list: ${_messages.length}');

    // Store contact mapping for retry logic
    if (contact != null) {
      _messageContactMap[message.id] = contact;
      debugPrint('  ✅ Stored contact mapping for retry logic');
    }

    // If it's a SAR marker message, extract and store the marker
    if (sendingMessage.isSarMarker) {
      final marker = sendingMessage.toSarMarker();
      if (marker != null) {
        debugPrint('  ✅ SAR Marker created:');
        debugPrint('     marker.id: ${marker.id}');
        debugPrint('     marker.notes: "${marker.notes}"');
        debugPrint('     marker.type: ${marker.type}');
        debugPrint('     marker.displayName: ${marker.displayName}');
        _sarMarkers[marker.id] = marker;
      }
    }

    _persistMessages();
    notifyListeners();
    debugPrint('  ✅ notifyListeners() called - UI should update');
  }

  /// Register an individual message ID as part of a grouped message
  void registerGroupedMessageSend(
    String individualMessageId,
    String groupId,
    Uint8List recipientPublicKey,
  ) {
    _groupedMessageMapping[individualMessageId] = (groupId, recipientPublicKey);
    debugPrint('📝 [MessagesProvider] Registered grouped message send:');
    debugPrint('  Individual ID: $individualMessageId');
    debugPrint('  Group ID: $groupId');
    debugPrint('  Total mappings: ${_groupedMessageMapping.length}');
  }

  /// Update message status to sent with ACK tag
  void markMessageSent(
    String messageId,
    int expectedAckTag,
    int suggestedTimeoutMs,
  ) {
    debugPrint('📤 [MessagesProvider] markMessageSent called');
    debugPrint('  Message ID: $messageId');
    debugPrint(
      '  Expected ACK tag: $expectedAckTag (0x${expectedAckTag.toRadixString(16).padLeft(8, '0')})',
    );
    debugPrint('  Timeout: ${suggestedTimeoutMs}ms');
    debugPrint(
      '  Current pending ACKs before adding: ${_pendingSentMessages.keys.toList()}',
    );

    // Check if this is an individual message in a grouped send
    final groupMapping = _groupedMessageMapping[messageId];
    if (groupMapping != null) {
      final (groupId, recipientPublicKey) = groupMapping;
      debugPrint('  ✅ This is part of a grouped message: $groupId');

      // ACK-tracked recipients stay pending until the delivery confirm arrives.
      updateGroupedMessageRecipientStatus(
        groupId,
        recipientPublicKey,
        expectedAckTag > 0
            ? MessageDeliveryStatus.sending
            : MessageDeliveryStatus.sent,
      );

      // Track the ACK for this specific recipient
      if (expectedAckTag > 0 && suggestedTimeoutMs > 0) {
        // For grouped messages, multiply timeout by 5x for mesh network propagation
        // Clamp at 20 seconds maximum
        final scaledTimeout = suggestedTimeoutMs * 5;
        final effectiveTimeout = scaledTimeout > 20000 ? 20000 : scaledTimeout;
        debugPrint(
          '  ⏱️ Radio suggested ${suggestedTimeoutMs}ms, using ${effectiveTimeout}ms (5x${scaledTimeout > 20000 ? ', clamped at 20s' : ''}) for grouped message',
        );

        // Store ACK tag → List of (groupId, recipientPublicKey)
        // Multiple recipients can share the same ACK tag
        if (!_ackTagToRecipients.containsKey(expectedAckTag)) {
          _ackTagToRecipients[expectedAckTag] = [];
        }
        _ackTagToRecipients[expectedAckTag]!.add((groupId, recipientPublicKey));
        debugPrint(
          '  ✅ Added recipient to ACK tag $expectedAckTag → group $groupId, recipient ${recipientPublicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
        );
        debugPrint(
          '  📊 Total recipients for ACK $expectedAckTag: ${_ackTagToRecipients[expectedAckTag]!.length}',
        );

        // Store the mapping so we can update the right recipient on delivery
        _pendingSentMessages[expectedAckTag] = Message(
          id: messageId,
          messageType: MessageType.contact,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          text: '',
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sent,
          expectedAckTag: expectedAckTag,
          recipientPublicKey: recipientPublicKey,
        );

        debugPrint('  ✅ Added to pending ACKs with list-based mapping');

        // Start timeout timer for THIS specific recipient using message ID as key
        _timeoutTimers[messageId] = Timer(
          Duration(milliseconds: effectiveTimeout),
          () {
            debugPrint(
              '⏱️ [MessagesProvider] Timeout for grouped message recipient (message $messageId)',
            );
            // Check if this specific recipient is still pending
            final recipients = _ackTagToRecipients[expectedAckTag];
            if (recipients != null && recipients.isNotEmpty) {
              // Find this specific recipient in the list
              final recipientIndex = recipients.indexWhere(
                (r) => _listEquals(r.$2, recipientPublicKey),
              );

              if (recipientIndex >= 0) {
                final (timeoutGroupId, timeoutRecipientKey) =
                    recipients[recipientIndex];
                debugPrint('  ⚠️ Timeout fired - marking recipient as failed');
                debugPrint('     Group: $timeoutGroupId');
                debugPrint(
                  '     Recipient: ${timeoutRecipientKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
                );

                // Mark this specific recipient as failed
                updateGroupedMessageRecipientStatus(
                  timeoutGroupId,
                  timeoutRecipientKey,
                  MessageDeliveryStatus.failed,
                );

                // Remove this recipient from the list
                recipients.removeAt(recipientIndex);

                // Clean up if no more recipients for this ACK
                if (recipients.isEmpty) {
                  _ackTagToRecipients.remove(expectedAckTag);
                  _pendingSentMessages.remove(expectedAckTag);
                }
                _groupedMessageMapping.remove(messageId);
                _timeoutTimers.remove(messageId);
              } else {
                debugPrint(
                  '  ✅ ACK already received for this recipient - ignoring timeout',
                );
              }
            } else {
              debugPrint('  ✅ All ACKs already received - ignoring timeout');
            }
          },
        );
      }

      _persistMessages();
      notifyListeners();
      return;
    }

    final index = _messages.indexWhere((m) => m.id == messageId);
    debugPrint('  Message index in list: $index');

    if (index != -1) {
      final message = _messages[index];
      final contact = _messageContactMap[messageId];
      final effectiveTimeout = _retryManager.calculateAckTimeoutMs(
        text: message.text,
        contact: contact,
        suggestedTimeoutMs: suggestedTimeoutMs > 0 ? suggestedTimeoutMs : null,
      );
      debugPrint('  Current status: ${message.deliveryStatus}');
      debugPrint('  Message type: ${message.messageType}');
      debugPrint(
        '  Message text preview: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...',
      );

      // Once the device accepts a direct message and returns an ACK tag, the
      // send itself succeeded locally even if end-to-end delivery confirmation
      // may still arrive later. Keep ACK tracking, but stop showing "waiting".
      final updatedMessage = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.sent,
        expectedAckTag: expectedAckTag > 0 ? expectedAckTag : null,
        suggestedTimeoutMs: expectedAckTag > 0 ? effectiveTimeout : null,
      );
      _messages[index] = updatedMessage;

      // Only track and set timeout for direct messages (channel messages have expectedAckTag=0)
      if (expectedAckTag > 0) {
        // Track by ACK tag for matching with delivery confirmation
        _pendingSentMessages[expectedAckTag] = updatedMessage;
        _messageAckHistory
            .putIfAbsent(messageId, () => <int>{})
            .add(expectedAckTag);
        _ackHistoryLookup[expectedAckTag] = (messageId, DateTime.now());
        debugPrint(
          '  ✅ Added to pending messages map with ACK: $expectedAckTag',
        );
        debugPrint('  Total pending messages: ${_pendingSentMessages.length}');
        debugPrint(
          '  Pending ACKs after adding: ${_pendingSentMessages.keys.toList()}',
        );

        // Start timeout timer using message ID as key
        _timeoutTimers[messageId] = Timer(
          Duration(milliseconds: effectiveTimeout),
          () {
            debugPrint(
              '⏱️ [MessagesProvider] Timeout for message $messageId (ACK $expectedAckTag)',
            );
            if (_pendingSentMessages.containsKey(expectedAckTag)) {
              markMessageFailed(messageId);
            }
          },
        );

        debugPrint(
          '⏱️ [MessagesProvider] Started ${effectiveTimeout}ms timeout timer for message $messageId (ACK $expectedAckTag)',
        );
      } else {
        debugPrint(
          '  ℹ️ Channel message (no ACK tracking) - marked as sent immediately',
        );
      }

      debugPrint('  Calling notifyListeners() to update UI with "sent" status');

      _persistMessages();
      notifyListeners();

      debugPrint('  ✅ markMessageSent completed successfully');
    } else {
      debugPrint('⚠️ [MessagesProvider] Message not found in list: $messageId');
      debugPrint('  Total messages in list: ${_messages.length}');
      debugPrint('  Recent messages:');
      for (final m in _messages.take(5)) {
        debugPrint('     - ID: ${m.id}, Status: ${m.deliveryStatus}');
      }
    }
  }

  /// Handle echo detection for public channel messages
  void handleMessageEcho(
    String messageId,
    int echoCount,
    int snrRaw,
    int rssiDbm,
  ) {
    debugPrint('🔊 [MessagesProvider] handleMessageEcho called');
    debugPrint('  Message ID: $messageId');
    debugPrint('  Echo count: $echoCount');
    debugPrint('  SNR: ${(snrRaw.toSigned(8) / 4.0).toStringAsFixed(2)} dB');
    debugPrint('  RSSI: ${rssiDbm.toSigned(8)} dBm');

    // Find the message
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      debugPrint(
        '  ✅ Found message: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...',
      );

      // Update echo count
      final updatedMessage = message.copyWith(
        echoCount: echoCount,
        firstEchoAt: message.firstEchoAt ?? DateTime.now(),
        lastEchoSnrRaw: snrRaw.toSigned(8),
        lastEchoRssiDbm: rssiDbm.toSigned(8),
        lastEchoAt: DateTime.now(),
      );
      _messages[index] = updatedMessage;

      debugPrint('  Updated echo count to: $echoCount');
      _persistMessages();
      notifyListeners();
      debugPrint('  ✅ Echo update complete, UI notified');
    } else {
      debugPrint('  ⚠️ Message not found in messages list');
    }
  }

  /// Update a recipient's status in a grouped message
  void updateGroupedMessageRecipientStatus(
    String groupId,
    Uint8List recipientPublicKey,
    MessageDeliveryStatus newStatus, {
    int? roundTripTimeMs,
    DateTime? deliveredAt,
  }) {
    debugPrint(
      '🔄 [MessagesProvider] updateGroupedMessageRecipientStatus called',
    );
    debugPrint('  Group ID: $groupId');
    debugPrint('  New status: $newStatus');
    debugPrint('  RTT: ${roundTripTimeMs}ms');

    final index = _messages.indexWhere((m) => m.id == groupId);
    if (index == -1) {
      debugPrint('⚠️ [MessagesProvider] Grouped message not found: $groupId');
      debugPrint(
        '  Available message IDs: ${_messages.take(5).map((m) => m.id).join(", ")}',
      );
      return;
    }

    final message = _messages[index];
    debugPrint('  ✅ Found grouped message at index $index');

    if (!message.isGroupedMessage) {
      debugPrint(
        '⚠️ [MessagesProvider] Message is not a grouped message: $groupId',
      );
      return;
    }

    debugPrint('  Total recipients: ${message.recipients!.length}');

    // Find and update the recipient
    bool recipientFound = false;
    final updatedRecipients = message.recipients!.map((recipient) {
      // Compare public keys
      if (recipient.publicKey.length == recipientPublicKey.length) {
        bool matches = true;
        for (int i = 0; i < recipient.publicKey.length; i++) {
          if (recipient.publicKey[i] != recipientPublicKey[i]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          recipientFound = true;
          debugPrint('  ✅ Found recipient: ${recipient.displayName}');
          debugPrint('    Old status: ${recipient.deliveryStatus}');
          debugPrint('    New status: $newStatus');
          return recipient.copyWith(
            deliveryStatus: newStatus,
            roundTripTimeMs: roundTripTimeMs,
            deliveredAt:
                deliveredAt ??
                (newStatus == MessageDeliveryStatus.delivered
                    ? DateTime.now()
                    : null),
          );
        }
      }
      return recipient;
    }).toList();

    if (!recipientFound) {
      debugPrint('  ⚠️ Recipient not found in recipients list!');
      debugPrint(
        '  Looking for key: ${recipientPublicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
      );
      debugPrint('  Available recipients:');
      for (final r in message.recipients!) {
        debugPrint(
          '    - ${r.displayName}: ${r.publicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
        );
      }
    }

    // Update the message with new recipient list
    _messages[index] = message.copyWith(recipients: updatedRecipients);

    // Update overall message status based on recipients
    MessageDeliveryStatus overallStatus;
    final allDelivered = updatedRecipients.every(
      (r) => r.deliveryStatus == MessageDeliveryStatus.delivered,
    );
    final anyFailed = updatedRecipients.any(
      (r) => r.deliveryStatus == MessageDeliveryStatus.failed,
    );
    final anySending = updatedRecipients.any(
      (r) => r.deliveryStatus == MessageDeliveryStatus.sending,
    );

    debugPrint('  Status counts:');
    debugPrint(
      '    Delivered: ${updatedRecipients.where((r) => r.deliveryStatus == MessageDeliveryStatus.delivered).length}',
    );
    debugPrint(
      '    Sent/Pending: ${updatedRecipients.where((r) => r.deliveryStatus == MessageDeliveryStatus.sent || r.deliveryStatus == MessageDeliveryStatus.sending).length}',
    );
    debugPrint(
      '    Failed: ${updatedRecipients.where((r) => r.deliveryStatus == MessageDeliveryStatus.failed).length}',
    );

    if (allDelivered) {
      overallStatus = MessageDeliveryStatus.delivered;
    } else if (anyFailed && !anySending) {
      overallStatus = MessageDeliveryStatus.failed;
    } else if (anySending) {
      overallStatus = MessageDeliveryStatus.sending;
    } else {
      overallStatus = MessageDeliveryStatus.sent;
    }

    debugPrint('  Overall status: $overallStatus');

    _messages[index] = _messages[index].copyWith(deliveryStatus: overallStatus);

    debugPrint('  ✅ Message updated, calling notifyListeners()');
    _persistMessages();
    notifyListeners();
  }

  /// Update message status to delivered with RTT
  void markMessageDelivered(int ackCode, int roundTripTimeMs) {
    _cleanupCompletedAckHistory();
    _cleanupAckHistoryLookup();
    debugPrint(
      '🔍 [MessagesProvider] markMessageDelivered called with ACK: $ackCode, RTT: ${roundTripTimeMs}ms',
    );
    debugPrint('  Checking recipient list for ACK $ackCode...');

    // Check if this ACK is for grouped message recipient(s)
    final recipients = _ackTagToRecipients[ackCode];
    if (recipients != null && recipients.isNotEmpty) {
      // Pop the first recipient from the list (FIFO order)
      // This matches the order in which messages were sent
      final (groupId, recipientPublicKey) = recipients.removeAt(0);
      debugPrint(
        '  ✅ Found recipient in list: group $groupId, recipient ${recipientPublicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
      );
      debugPrint(
        '  📊 Remaining recipients for ACK $ackCode: ${recipients.length}',
      );

      // Find the message ID for this recipient to cancel its timeout
      String? messageIdToCancel;
      for (final entry in _groupedMessageMapping.entries) {
        if (entry.value.$1 == groupId &&
            _listEquals(entry.value.$2, recipientPublicKey)) {
          messageIdToCancel = entry.key;
          break;
        }
      }

      if (messageIdToCancel != null) {
        debugPrint('  🧹 Canceling timeout for message $messageIdToCancel');
        _timeoutTimers[messageIdToCancel]?.cancel();
        _timeoutTimers.remove(messageIdToCancel);
        _groupedMessageMapping.remove(messageIdToCancel);
      }

      // Update the specific recipient's status to delivered
      updateGroupedMessageRecipientStatus(
        groupId,
        recipientPublicKey,
        MessageDeliveryStatus.delivered,
        roundTripTimeMs: roundTripTimeMs,
        deliveredAt: DateTime.now(),
      );

      // Clean up if no more recipients for this ACK
      if (recipients.isEmpty) {
        debugPrint(
          '  🧹 All recipients processed for ACK $ackCode, cleaning up',
        );
        _ackTagToRecipients.remove(ackCode);
        _pendingSentMessages.remove(ackCode);
        _rememberCompletedAck(ackCode);
      }

      debugPrint(
        '✅ [MessagesProvider] Grouped message recipient delivered in ${roundTripTimeMs}ms (ACK $ackCode)',
      );

      _persistMessages();
      notifyListeners();

      debugPrint('  ✅ notifyListeners() called successfully');
      return;
    }

    // Not a grouped message, check for single message
    debugPrint('  Not in simple mapping, checking pending messages...');
    debugPrint(
      '  Current pending messages: ${_pendingSentMessages.keys.toList()}',
    );
    debugPrint('  Total messages in list: ${_messages.length}');

    // Find message by ACK code
    final message = _pendingSentMessages[ackCode];
    if (message != null) {
      debugPrint('  ✅ Found message in pending map: ${message.id}');

      // Single message delivery
      final index = _messages.indexWhere((m) => m.id == message.id);
      debugPrint('  Message index in list: $index');

      if (index != -1) {
        final updatedMessage = message.copyWith(
          deliveryStatus: MessageDeliveryStatus.delivered,
          roundTripTimeMs: roundTripTimeMs,
          deliveredAt: DateTime.now(),
        );
        _messages[index] = updatedMessage;

        // Cancel timeout timer using message ID
        _timeoutTimers[message.id]?.cancel();
        _timeoutTimers.remove(message.id);

        // Remove from pending
        _pendingSentMessages.remove(ackCode);
        _rememberCompletedAck(ackCode);
        _clearAckHistoryForMessage(message.id);

        // Clear retry tracking on successful delivery
        _retryManager.clearRetry(message.id);
        final deliveredContact = _messageContactMap[message.id];
        if (deliveredContact != null) {
          _retryManager.recordDeliverySuccess(deliveredContact);
        }

        debugPrint(
          '✅ [MessagesProvider] Message ${message.id} delivered in ${roundTripTimeMs}ms (ACK $ackCode)',
        );
        debugPrint('  Updated status to: ${updatedMessage.deliveryStatus}');
        debugPrint('  Calling notifyListeners() to update UI');

        _persistMessages();
        notifyListeners();

        debugPrint('  ✅ notifyListeners() called successfully');
      } else {
        debugPrint(
          '⚠️ [MessagesProvider] Message not found in messages list (index=-1)',
        );
        debugPrint(
          '  This should never happen - message was in pending map but not in messages list',
        );
      }
    } else {
      final historicalMatch = _ackHistoryLookup[ackCode];
      if (historicalMatch != null) {
        final historicalMessageId = historicalMatch.$1;
        final historicalIndex = _messages.indexWhere(
          (m) => m.id == historicalMessageId,
        );
        if (historicalIndex != -1 &&
            _messages[historicalIndex].deliveryStatus !=
                MessageDeliveryStatus.delivered) {
          _messages[historicalIndex] = _messages[historicalIndex].copyWith(
            deliveryStatus: MessageDeliveryStatus.delivered,
            roundTripTimeMs: roundTripTimeMs,
            deliveredAt: DateTime.now(),
          );
          _timeoutTimers[historicalMessageId]?.cancel();
          _timeoutTimers.remove(historicalMessageId);
          _rememberCompletedAck(ackCode);
          _clearAckHistoryForMessage(historicalMessageId);
          _retryManager.clearRetry(historicalMessageId);
          final deliveredContact = _messageContactMap[historicalMessageId];
          if (deliveredContact != null) {
            _retryManager.recordDeliverySuccess(deliveredContact);
          }
          _persistMessages();
          notifyListeners();
          debugPrint(
            '✅ [MessagesProvider] Historical ACK $ackCode matched message $historicalMessageId',
          );
          return;
        }
      }
      if (_completedAckHistory.containsKey(ackCode)) {
        debugPrint(
          'ℹ️ [MessagesProvider] Duplicate/late ACK $ackCode ignored (already completed)',
        );
        return;
      }
      debugPrint(
        '⚠️ [MessagesProvider] No pending message found for ACK code: $ackCode',
      );
      debugPrint('  Pending ACK codes: ${_pendingSentMessages.keys.toList()}');
      debugPrint('  This means either:');
      debugPrint(
        '  1. markMessageSent() was never called for this message (ACK tag not stored)',
      );
      debugPrint(
        '  2. The ACK code from PUSH_CODE_SEND_CONFIRMED doesn\'t match the expected ACK tag from RESP_CODE_SENT',
      );
      debugPrint('  3. The message was already delivered or timed out');
      debugPrint(
        '  4. Firmware circular buffer overflow (>8 pending ACKs sent too quickly)',
      );
      debugPrint('  Searching all messages for debugging...');

      // Debug: Search for any message with this ACK tag
      final matchingMessages = _messages
          .where((m) => m.expectedAckTag == ackCode)
          .toList();
      if (matchingMessages.isNotEmpty) {
        debugPrint(
          '  ⚠️ Found ${matchingMessages.length} message(s) with matching ACK tag but NOT in pending map:',
        );
        for (final m in matchingMessages) {
          debugPrint(
            '     - Message ID: ${m.id}, Status: ${m.deliveryStatus}, ACK: ${m.expectedAckTag}',
          );
        }
        debugPrint(
          '  This indicates the message was sent but never added to _pendingSentMessages map',
        );
        debugPrint(
          '  Likely cause: markMessageSent() was not called with correct message ID',
        );
      } else {
        debugPrint('  No messages found with ACK tag $ackCode');
        debugPrint('  Recent sent messages:');
        final sentMessages = _messages
            .where((m) => m.isSentMessage)
            .take(5)
            .toList();
        for (final m in sentMessages) {
          debugPrint(
            '     - ID: ${m.id}, Status: ${m.deliveryStatus}, ACK: ${m.expectedAckTag}',
          );
        }
      }
    }
  }

  /// Update message status to failed (with retry logic)
  void markMessageFailed(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      debugPrint(
        '⚠️ [MessagesProvider] markMessageFailed: Message not found: $messageId',
      );
      return;
    }

    final message = _messages[index];
    final contact = _messageContactMap[messageId];

    debugPrint('❌ [MessagesProvider] Message $messageId timeout/failed');
    debugPrint('   Retry attempt: ${message.retryAttempt}');
    debugPrint('   Contact has path: ${contact?.routeHasPath ?? false}');
    debugPrint('   Used flood fallback: ${message.usedFloodFallback}');

    // Decision tree for retry/flood/fail
    if (contact != null && _retryManager.canRetry(message, contact)) {
      // RETRY: Contact has path and retry attempts < 3
      _scheduleRetry(messageId, message, contact);
    } else if (contact != null &&
        _retryManager.shouldUseFloodFallback(message, contact)) {
      // FLOOD FALLBACK: After 3 retries failed, try flood once
      _sendWithFloodMode(messageId, message, contact);
    } else {
      // PERMANENTLY FAILED: No retry possible
      _markAsPermanentlyFailed(messageId, message);
    }
  }

  /// Schedule a retry with progressive timeout
  void _scheduleRetry(String messageId, Message message, Contact contact) {
    final nextAttempt = message.retryAttempt + 1;
    final timeout = _retryManager.getTimeoutForAttempt(message.retryAttempt);

    debugPrint(
      '🔄 [MessagesProvider] Scheduling retry $nextAttempt/3 for message $messageId',
    );
    debugPrint('   Timeout: ${timeout}ms');

    // Update message with new retry attempt
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = message.copyWith(
        retryAttempt: nextAttempt,
        deliveryStatus: MessageDeliveryStatus.sending,
        lastRetryAt: DateTime.now(),
      );

      // Cancel old timeout timer
      _timeoutTimers[message.id]?.cancel();
      _timeoutTimers.remove(message.id);
      if (message.expectedAckTag != null) {
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      // Track retry
      _retryManager.trackRetry(messageId, nextAttempt);

      notifyListeners(); // Update UI to show "Retrying (X/3)..."

      // Schedule actual retry after delay
      Timer(Duration(milliseconds: timeout), () async {
        debugPrint(
          '⏰ [MessagesProvider] Executing retry $nextAttempt for message $messageId',
        );
        final currentIndex = _messages.indexWhere((m) => m.id == messageId);
        if (currentIndex == -1) {
          return;
        }
        final currentMessage = _messages[currentIndex];
        if (currentMessage.deliveryStatus == MessageDeliveryStatus.delivered) {
          return;
        }

        if (sendMessageCallback != null) {
          final queued = await sendMessageCallback!(
            contactPublicKey: contact.publicKey,
            text: message.text,
            messageId: messageId,
            contact: contact,
            retryAttempt: nextAttempt,
          );
          if (!queued) {
            _markAsPermanentlyFailed(messageId, currentMessage);
          }
        } else {
          debugPrint(
            '⚠️ [MessagesProvider] sendMessageCallback not set, cannot retry',
          );
          _markAsPermanentlyFailed(messageId, currentMessage);
        }
      });

      _persistMessages();
    }
  }

  /// Send message with flood mode as last resort
  Future<void> _sendWithFloodMode(
    String messageId,
    Message message,
    Contact contact,
  ) async {
    debugPrint(
      '🌊 [MessagesProvider] Trying flood mode for message $messageId',
    );

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = message.copyWith(
        usedFloodFallback: true,
        deliveryStatus: MessageDeliveryStatus.sending,
      );

      // Cancel old timeout timer
      _timeoutTimers[message.id]?.cancel();
      _timeoutTimers.remove(message.id);
      if (message.expectedAckTag != null) {
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      notifyListeners();

      // Send with flood mode (no retry after this)
      if (sendMessageCallback != null) {
        final queued = await sendMessageCallback!(
          contactPublicKey: contact.publicKey,
          text: message.text,
          messageId: messageId,
          contact: contact,
          retryAttempt: 0, // Reset attempt for flood
        );
        if (!queued) {
          _markAsPermanentlyFailed(messageId, _messages[index]);
        }
      } else {
        debugPrint(
          '⚠️ [MessagesProvider] sendMessageCallback not set, cannot send flood',
        );
        _markAsPermanentlyFailed(messageId, _messages[index]);
      }

      _persistMessages();
    }
  }

  /// Mark message as permanently failed
  void _markAsPermanentlyFailed(String messageId, Message message) {
    debugPrint('❌ [MessagesProvider] Message $messageId permanently failed');

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.failed,
      );

      // Cancel timeout timer if it exists
      _timeoutTimers[message.id]?.cancel();
      _timeoutTimers.remove(message.id);
      if (message.expectedAckTag != null) {
        _pendingSentMessages.remove(message.expectedAckTag);
      }
      _clearAckHistoryForMessage(messageId);

      // Clear retry tracking
      _retryManager.clearRetry(messageId);

      final failedContact = _messageContactMap[messageId];
      if (failedContact != null && failedContact.routeHasPath) {
        final failureStreak = _retryManager.recordPathFailure(failedContact);
        debugPrint(
          '   Path failure streak for ${failedContact.advName}: $failureStreak',
        );
        if (failureStreak >= 2 && onDirectPathFailedCallback != null) {
          unawaited(
            onDirectPathFailedCallback!(
              contact: failedContact,
              failureStreak: failureStreak,
            ),
          );
        }
      }

      _persistMessages();
      notifyListeners();
    }
  }

  /// Reset an existing failed message back into a sending state so a manual
  /// retry can reuse the same record instead of appending a duplicate.
  bool prepareMessageForRetry(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      debugPrint(
        '⚠️ [MessagesProvider] prepareMessageForRetry: Message not found: $messageId',
      );
      return false;
    }

    final message = _messages[index];

    _timeoutTimers[message.id]?.cancel();
    _timeoutTimers.remove(message.id);
    if (message.expectedAckTag != null) {
      _pendingSentMessages.remove(message.expectedAckTag);
    }
    _clearAckHistoryForMessage(messageId);
    _retryManager.clearRetry(messageId);

    _messages[index] = Message(
      id: message.id,
      messageType: message.messageType,
      senderPublicKeyPrefix: message.senderPublicKeyPrefix,
      channelIdx: message.channelIdx,
      pathLen: message.pathLen,
      textType: message.textType,
      senderTimestamp: message.senderTimestamp,
      text: message.text,
      isSarMarker: message.isSarMarker,
      sarGpsCoordinates: message.sarGpsCoordinates,
      sarNotes: message.sarNotes,
      sarCustomEmoji: message.sarCustomEmoji,
      sarColorIndex: message.sarColorIndex,
      receivedAt: message.receivedAt,
      senderName: message.senderName,
      deliveryStatus: MessageDeliveryStatus.sending,
      recipientPublicKey: message.recipientPublicKey,
      retryAttempt: 0,
      lastRetryAt: DateTime.now(),
      usedFloodFallback: false,
      isRead: message.isRead,
      echoCount: message.echoCount,
      firstEchoAt: message.firstEchoAt,
      lastEchoSnrRaw: message.lastEchoSnrRaw,
      lastEchoRssiDbm: message.lastEchoRssiDbm,
      lastEchoAt: message.lastEchoAt,
      isDrawing: message.isDrawing,
      drawingId: message.drawingId,
      groupId: message.groupId,
      recipients: message.recipients,
      isVoice: message.isVoice,
      voiceId: message.voiceId,
    );

    _persistMessages();
    notifyListeners();
    return true;
  }

  /// Resend a failed message
  Future<void> resendMessage(String messageId, {Contact? contact}) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      debugPrint(
        '⚠️ [MessagesProvider] resendMessage: Message not found: $messageId',
      );
      return;
    }

    final message = _messages[index];
    final resolvedContact = contact ?? _messageContactMap[messageId];

    if (resolvedContact == null) {
      debugPrint(
        '⚠️ [MessagesProvider] Cannot resend: Contact not found for message $messageId',
      );
      return;
    }

    debugPrint('🔁 [MessagesProvider] Resending message $messageId');

    _messageContactMap[messageId] = resolvedContact;
    final prepared = prepareMessageForRetry(messageId);
    if (!prepared) {
      return;
    }

    // Send again
    if (sendMessageCallback != null) {
      final queued = await sendMessageCallback!(
        contactPublicKey: resolvedContact.publicKey,
        text: message.text,
        messageId: messageId,
        contact: resolvedContact,
        retryAttempt: 0,
      );
      if (!queued) {
        _markAsPermanentlyFailed(messageId, _messages[index]);
      }
    } else {
      debugPrint(
        '⚠️ [MessagesProvider] sendMessageCallback not set, cannot resend',
      );
      _markAsPermanentlyFailed(messageId, _messages[index]);
    }

    _persistMessages();
  }

  @override
  void dispose() {
    // Cancel all pending timeout timers
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    _completedAckHistory.clear();
    _messageAckHistory.clear();
    _ackHistoryLookup.clear();

    // Clear retry manager
    _retryManager.clearAll();

    super.dispose();
  }

  void _rememberCompletedAck(int ackCode) {
    _completedAckHistory[ackCode] = DateTime.now();
    _cleanupCompletedAckHistory();
  }

  void _cleanupCompletedAckHistory({
    Duration maxAge = const Duration(minutes: 15),
  }) {
    final cutoff = DateTime.now().subtract(maxAge);
    final staleAcks = _completedAckHistory.entries
        .where((entry) => entry.value.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();
    for (final ack in staleAcks) {
      _completedAckHistory.remove(ack);
    }
  }

  void _clearAckHistoryForMessage(String messageId) {
    final ackTags = _messageAckHistory.remove(messageId);
    if (ackTags == null) {
      return;
    }
    for (final ack in ackTags) {
      _ackHistoryLookup.remove(ack);
    }
  }

  void _cleanupAckHistoryLookup({
    Duration maxAge = const Duration(minutes: 15),
  }) {
    final cutoff = DateTime.now().subtract(maxAge);
    final staleAcks = _ackHistoryLookup.entries
        .where((entry) => entry.value.$2.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();
    for (final ack in staleAcks) {
      final messageId = _ackHistoryLookup.remove(ack)?.$1;
      if (messageId == null) {
        continue;
      }
      final history = _messageAckHistory[messageId];
      history?.remove(ack);
      if (history != null && history.isEmpty) {
        _messageAckHistory.remove(messageId);
      }
    }
  }
}
