import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../models/map_drawing.dart';
import '../services/message_storage_service.dart';
import '../services/notification_service.dart';
import '../utils/sar_message_parser.dart';
import '../utils/drawing_message_parser.dart';
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

  // Track pending sent messages by expected ACK/TAG
  final Map<int, Message> _pendingSentMessages = {};

  // Track timeout timers for pending messages
  final Map<int, Timer> _timeoutTimers = {};

  // Retry management
  final MessageRetryManager _retryManager = MessageRetryManager();

  // Track which contact each sent message was sent to (for retry logic)
  final Map<String, Contact> _messageContactMap = {};

  // Navigation state for message highlighting/scrolling
  String? _targetMessageId;

  // Callback to connection provider for sending messages (set by AppProvider)
  Future<bool> Function({
    required Uint8List contactPublicKey,
    required String text,
    required String messageId,
    required Contact contact,
    int retryAttempt,
  })?
  sendMessageCallback;

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
    debugPrint('🔄 [MessagesProvider] Syncing drawings with DrawingProvider...');
    int restoredCount = 0;

    for (final message in _messages) {
      if (!message.isDrawing || message.drawingId == null) continue;

      // Check if drawing exists in DrawingProvider
      final existingDrawing = drawingProvider.getDrawingById(message.drawingId!);
      if (existingDrawing != null) {
        continue; // Drawing already exists
      }

      // Drawing is missing, reconstruct from message text
      debugPrint('🔧 [MessagesProvider] Restoring missing drawing: ${message.drawingId}');
      final drawing = DrawingMessageParser.parseDrawingMessage(
        message.text,
        senderName: message.senderName,
        messageId: message.id,
      );

      if (drawing == null) {
        debugPrint('⚠️ [MessagesProvider] Failed to parse drawing from message ${message.id}');
        continue;
      }

      // The parsed drawing has a new generated ID, but we need to use the original ID
      // Create a copy with the correct ID from the message
      final restoredDrawing = _createDrawingWithId(drawing, message.drawingId!);

      if (restoredDrawing != null) {
        drawingProvider.addReceivedDrawing(restoredDrawing);
        restoredCount++;
        debugPrint('✅ [MessagesProvider] Restored drawing ${message.drawingId}');
      }
    }

    debugPrint('✅ [MessagesProvider] Sync complete: restored $restoredCount drawings');
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
      return; // Skip duplicate
    }

    _messages.add(finalMessage);

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
      // Get sender name from message
      final senderName =
          message.senderName ?? message.senderKeyShort ?? 'Unknown';

      // Determine if it's a channel message
      final isChannelMessage = message.isChannelMessage;

      // Get channel name if available
      String? channelName;
      if (isChannelMessage) {
        // You could map channelIdx to channel name here if needed
        // For now, use "Public" for channel 0
        channelName = message.channelIdx == 0
            ? 'Public'
            : 'Channel ${message.channelIdx}';
      }

      debugPrint('🔔 [MessagesProvider] Triggering message notification');
      debugPrint('   Sender: $senderName');
      debugPrint('   Type: ${isChannelMessage ? "Channel" : "Direct"}');
      debugPrint(
        '   Message: ${message.text.substring(0, message.text.length > 50 ? 50 : message.text.length)}...',
      );

      await _notificationService.showMessageNotification(
        senderName: senderName,
        messageText: message.text,
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

  /// Persist messages to storage (async, non-blocking)
  Future<void> _persistMessages() async {
    try {
      await _storageService.saveMessages(_messages);
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
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      debugPrint('🗑️ [MessagesProvider] Message $messageId deleted');

      _persistMessages();
      notifyListeners();
    }
  }

  /// Delete a drawing message and its linked drawing
  void deleteDrawingMessage(String messageId, dynamic drawingProvider) {
    final message = _messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );

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
    _persistMessages();
    notifyListeners();
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

    final index = _messages.indexWhere((m) => m.id == messageId);
    debugPrint('  Message index in list: $index');

    if (index != -1) {
      final message = _messages[index];
      debugPrint('  Current status: ${message.deliveryStatus}');
      debugPrint('  Message type: ${message.messageType}');
      debugPrint(
        '  Message text preview: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...',
      );

      final updatedMessage = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.sent,
        expectedAckTag: expectedAckTag > 0 ? expectedAckTag : null,
        suggestedTimeoutMs: suggestedTimeoutMs > 0 ? suggestedTimeoutMs : null,
      );
      _messages[index] = updatedMessage;

      // Only track and set timeout for direct messages (channel messages have expectedAckTag=0)
      if (expectedAckTag > 0 && suggestedTimeoutMs > 0) {
        // Track by ACK tag for matching with delivery confirmation
        _pendingSentMessages[expectedAckTag] = updatedMessage;
        debugPrint(
          '  ✅ Added to pending messages map with ACK: $expectedAckTag',
        );
        debugPrint('  Total pending messages: ${_pendingSentMessages.length}');
        debugPrint(
          '  Pending ACKs after adding: ${_pendingSentMessages.keys.toList()}',
        );

        // Start timeout timer
        _timeoutTimers[expectedAckTag] = Timer(
          Duration(milliseconds: suggestedTimeoutMs),
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
          '⏱️ [MessagesProvider] Started ${suggestedTimeoutMs}ms timeout timer for message $messageId (ACK $expectedAckTag)',
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

  /// Update message status to delivered with RTT
  void markMessageDelivered(int ackCode, int roundTripTimeMs) {
    debugPrint(
      '🔍 [MessagesProvider] markMessageDelivered called with ACK: $ackCode, RTT: ${roundTripTimeMs}ms',
    );
    debugPrint(
      '  Current pending messages: ${_pendingSentMessages.keys.toList()}',
    );
    debugPrint('  Total messages in list: ${_messages.length}');
    debugPrint('  Looking for ACK: $ackCode');

    // Find message by ACK code
    final message = _pendingSentMessages[ackCode];
    if (message != null) {
      debugPrint('  ✅ Found message in pending map: ${message.id}');
      final index = _messages.indexWhere((m) => m.id == message.id);
      debugPrint('  Message index in list: $index');

      if (index != -1) {
        final updatedMessage = message.copyWith(
          deliveryStatus: MessageDeliveryStatus.delivered,
          roundTripTimeMs: roundTripTimeMs,
          deliveredAt: DateTime.now(),
        );
        _messages[index] = updatedMessage;

        // Cancel timeout timer
        _timeoutTimers[ackCode]?.cancel();
        _timeoutTimers.remove(ackCode);

        // Remove from pending
        _pendingSentMessages.remove(ackCode);

        // Clear retry tracking on successful delivery
        _retryManager.clearRetry(message.id);

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
    debugPrint('   Contact has path: ${contact?.hasPath ?? false}');
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
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
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
        if (sendMessageCallback != null) {
          await sendMessageCallback!(
            contactPublicKey: contact.publicKey,
            text: message.text,
            messageId: messageId,
            contact: contact,
            retryAttempt: nextAttempt,
          );
        } else {
          debugPrint(
            '⚠️ [MessagesProvider] sendMessageCallback not set, cannot retry',
          );
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
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      notifyListeners();

      // Send with flood mode (no retry after this)
      if (sendMessageCallback != null) {
        await sendMessageCallback!(
          contactPublicKey: contact.publicKey,
          text: message.text,
          messageId: messageId,
          contact: contact,
          retryAttempt: 0, // Reset attempt for flood
        );
      } else {
        debugPrint(
          '⚠️ [MessagesProvider] sendMessageCallback not set, cannot send flood',
        );
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
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      // Clear retry tracking
      _retryManager.clearRetry(messageId);

      _persistMessages();
      notifyListeners();
    }
  }

  /// Resend a failed message
  Future<void> resendMessage(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      debugPrint(
        '⚠️ [MessagesProvider] resendMessage: Message not found: $messageId',
      );
      return;
    }

    final message = _messages[index];
    final contact = _messageContactMap[messageId];

    if (contact == null) {
      debugPrint(
        '⚠️ [MessagesProvider] Cannot resend: Contact not found for message $messageId',
      );
      return;
    }

    debugPrint('🔁 [MessagesProvider] Resending message $messageId');

    // Reset retry state
    _messages[index] = message.copyWith(
      retryAttempt: 0,
      usedFloodFallback: false,
      deliveryStatus: MessageDeliveryStatus.sending,
      lastRetryAt: DateTime.now(),
    );

    // Clear retry tracking
    _retryManager.clearRetry(messageId);

    notifyListeners();

    // Send again
    if (sendMessageCallback != null) {
      await sendMessageCallback!(
        contactPublicKey: contact.publicKey,
        text: message.text,
        messageId: messageId,
        contact: contact,
        retryAttempt: 0,
      );
    } else {
      debugPrint(
        '⚠️ [MessagesProvider] sendMessageCallback not set, cannot resend',
      );
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

    // Clear retry manager
    _retryManager.clearAll();

    super.dispose();
  }
}
