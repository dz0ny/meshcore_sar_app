import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';
import '../services/message_storage_service.dart';
import '../utils/sar_message_parser.dart';

/// Messages Provider - manages message history and SAR markers
class MessagesProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final Map<String, SarMarker> _sarMarkers = {};
  final MessageStorageService _storageService = MessageStorageService();
  bool _isInitialized = false;

  // Track pending sent messages by expected ACK/TAG
  final Map<int, Message> _pendingSentMessages = {};

  // Track timeout timers for pending messages
  final Map<int, Timer> _timeoutTimers = {};

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

  /// Initialize and load persisted messages
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📦 [MessagesProvider] Loading persisted messages...');
      final storedMessages = await _storageService.loadMessages();

      // Add stored messages with enhancement to ensure SAR detection
      for (final message in storedMessages) {
        // Re-enhance each message to ensure SAR markers are properly detected
        // This handles cases where messages were stored before enhancement logic
        final enhancedMessage = SarMessageParser.enhanceMessage(message);
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
      print('✅ [MessagesProvider] Loaded ${storedMessages.length} persisted messages');
      notifyListeners();
    } catch (e) {
      print('❌ [MessagesProvider] Error initializing: $e');
      _isInitialized = true; // Mark as initialized even on error
    }
  }

  /// Add a message
  /// If [contactLookup] function is provided, it will be used to match channel
  /// message senders with known contacts by name
  void addMessage(Message message, {String Function(String name)? contactLookup}) {
    // Always enhance message with SAR parser to detect SAR markers
    final enhancedMessage = SarMessageParser.enhanceMessage(message);

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
      print('🔍 [MessagesProvider] Processing SAR message: ${message.text}');
      print('   isSarMarker: ${finalMessage.isSarMarker}');
      print('   sarMarkerType: ${finalMessage.sarMarkerType}');
    }

    // Check for duplicates before adding
    // Messages can arrive multiple times due to:
    // - Mesh network retransmissions
    // - Multiple paths in the network
    // - Syncing messages from device queue
    if (_isDuplicate(finalMessage)) {
      print('⚠️ [MessagesProvider] Duplicate message detected, skipping: ${finalMessage.id}');
      print('   Text: ${finalMessage.text.substring(0, finalMessage.text.length > 50 ? 50 : finalMessage.text.length)}...');
      return; // Skip duplicate
    }

    _messages.add(finalMessage);

    // If it's a SAR marker message, extract and store the marker
    if (finalMessage.isSarMarker) {
      final marker = finalMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;
      }
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
  bool _isDuplicate(Message message) {
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

    print('📥 [MessagesProvider] Added $addedCount messages, skipped $duplicateCount duplicates');

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Persist messages to storage (async, non-blocking)
  Future<void> _persistMessages() async {
    try {
      await _storageService.saveMessages(_messages);
    } catch (e) {
      print('❌ [MessagesProvider] Error persisting messages: $e');
    }
  }

  /// Get messages for a specific contact
  List<Message> getMessagesForContact(String senderKeyShort) {
    return _messages
        .where((m) =>
            m.isContactMessage &&
            m.senderKeyShort != null &&
            m.senderKeyShort!.startsWith(senderKeyShort))
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

      print('🗑️ [MessagesProvider] Message $messageId deleted');

      _persistMessages();
      notifyListeners();
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
  void addSentMessage(Message message) {
    print('📝 [MessagesProvider] addSentMessage called');
    print('  Message ID: ${message.id}');
    print('  Message type: ${message.messageType}');
    print('  Initial status: ${message.deliveryStatus}');
    print('  Message text preview: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...');

    // Always enhance message with SAR parser to detect SAR markers
    final enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Check for duplicates (shouldn't happen for sent messages, but be safe)
    if (_isDuplicate(enhancedMessage)) {
      print('⚠️ [MessagesProvider] Duplicate sent message detected, skipping: ${enhancedMessage.id}');
      return;
    }

    // Add message with sending status
    final sendingMessage = enhancedMessage.copyWith(
      deliveryStatus: MessageDeliveryStatus.sending,
    );
    _messages.add(sendingMessage);
    print('  ✅ Message added to list at index ${_messages.length - 1}');
    print('  Total messages in list: ${_messages.length}');

    // If it's a SAR marker message, extract and store the marker
    if (sendingMessage.isSarMarker) {
      final marker = sendingMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;
      }
    }

    _persistMessages();
    notifyListeners();
    print('  ✅ notifyListeners() called - UI should update');
  }

  /// Update message status to sent with ACK tag
  void markMessageSent(String messageId, int expectedAckTag, int suggestedTimeoutMs) {
    print('📤 [MessagesProvider] markMessageSent called');
    print('  Message ID: $messageId');
    print('  Expected ACK tag: $expectedAckTag (0x${expectedAckTag.toRadixString(16).padLeft(8, '0')})');
    print('  Timeout: ${suggestedTimeoutMs}ms');
    print('  Current pending ACKs before adding: ${_pendingSentMessages.keys.toList()}');

    final index = _messages.indexWhere((m) => m.id == messageId);
    print('  Message index in list: $index');

    if (index != -1) {
      final message = _messages[index];
      print('  Current status: ${message.deliveryStatus}');
      print('  Message type: ${message.messageType}');
      print('  Message text preview: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...');

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
        print('  ✅ Added to pending messages map with ACK: $expectedAckTag');
        print('  Total pending messages: ${_pendingSentMessages.length}');
        print('  Pending ACKs after adding: ${_pendingSentMessages.keys.toList()}');

        // Start timeout timer
        _timeoutTimers[expectedAckTag] = Timer(
          Duration(milliseconds: suggestedTimeoutMs),
          () {
            print('⏱️ [MessagesProvider] Timeout for message $messageId (ACK $expectedAckTag)');
            if (_pendingSentMessages.containsKey(expectedAckTag)) {
              markMessageFailed(messageId);
            }
          },
        );

        print('⏱️ [MessagesProvider] Started ${suggestedTimeoutMs}ms timeout timer for message $messageId (ACK $expectedAckTag)');
      } else {
        print('  ℹ️ Channel message (no ACK tracking) - marked as sent immediately');
      }

      print('  Calling notifyListeners() to update UI with "sent" status');

      _persistMessages();
      notifyListeners();

      print('  ✅ markMessageSent completed successfully');
    } else {
      print('⚠️ [MessagesProvider] Message not found in list: $messageId');
      print('  Total messages in list: ${_messages.length}');
      print('  Recent messages:');
      for (final m in _messages.take(5)) {
        print('     - ID: ${m.id}, Status: ${m.deliveryStatus}');
      }
    }
  }

  /// Update message status to delivered with RTT
  void markMessageDelivered(int ackCode, int roundTripTimeMs) {
    print('🔍 [MessagesProvider] markMessageDelivered called with ACK: $ackCode, RTT: ${roundTripTimeMs}ms');
    print('  Current pending messages: ${_pendingSentMessages.keys.toList()}');
    print('  Total messages in list: ${_messages.length}');
    print('  Looking for ACK: $ackCode');

    // Find message by ACK code
    final message = _pendingSentMessages[ackCode];
    if (message != null) {
      print('  ✅ Found message in pending map: ${message.id}');
      final index = _messages.indexWhere((m) => m.id == message.id);
      print('  Message index in list: $index');

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

        print('✅ [MessagesProvider] Message ${message.id} delivered in ${roundTripTimeMs}ms (ACK $ackCode)');
        print('  Updated status to: ${updatedMessage.deliveryStatus}');
        print('  Calling notifyListeners() to update UI');

        _persistMessages();
        notifyListeners();

        print('  ✅ notifyListeners() called successfully');
      } else {
        print('⚠️ [MessagesProvider] Message not found in messages list (index=-1)');
        print('  This should never happen - message was in pending map but not in messages list');
      }
    } else {
      print('⚠️ [MessagesProvider] No pending message found for ACK code: $ackCode');
      print('  Pending ACK codes: ${_pendingSentMessages.keys.toList()}');
      print('  This means either:');
      print('  1. markMessageSent() was never called for this message (ACK tag not stored)');
      print('  2. The ACK code from PUSH_CODE_SEND_CONFIRMED doesn\'t match the expected ACK tag from RESP_CODE_SENT');
      print('  3. The message was already delivered or timed out');
      print('  Searching all messages for debugging...');

      // Debug: Search for any message with this ACK tag
      final matchingMessages = _messages.where((m) => m.expectedAckTag == ackCode).toList();
      if (matchingMessages.isNotEmpty) {
        print('  ⚠️ Found ${matchingMessages.length} message(s) with matching ACK tag but NOT in pending map:');
        for (final m in matchingMessages) {
          print('     - Message ID: ${m.id}, Status: ${m.deliveryStatus}, ACK: ${m.expectedAckTag}');
        }
        print('  This indicates the message was sent but never added to _pendingSentMessages map');
        print('  Likely cause: markMessageSent() was not called with correct message ID');
      } else {
        print('  No messages found with ACK tag $ackCode');
        print('  Recent sent messages:');
        final sentMessages = _messages.where((m) => m.isSentMessage).take(5).toList();
        for (final m in sentMessages) {
          print('     - ID: ${m.id}, Status: ${m.deliveryStatus}, ACK: ${m.expectedAckTag}');
        }
      }
    }
  }

  /// Update message status to failed
  void markMessageFailed(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final updatedMessage = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.failed,
      );
      _messages[index] = updatedMessage;

      // Cancel timeout timer if it exists
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      print('❌ [MessagesProvider] Message $messageId marked as failed');

      _persistMessages();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all pending timeout timers
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    super.dispose();
  }
}
