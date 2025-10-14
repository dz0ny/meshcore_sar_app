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

  List<Message> get messages => List.unmodifiable(_messages);

  List<Message> get contactMessages =>
      _messages.where((m) => m.isContactMessage).toList();

  List<Message> get channelMessages =>
      _messages.where((m) => m.isChannelMessage).toList();

  List<Message> get sarMarkerMessages =>
      _messages.where((m) => m.isSarMarker).toList();

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
  void addMessage(Message message) {
    // Always enhance message with SAR parser to detect SAR markers
    final enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Debug: Check if message is SAR
    if (message.text.startsWith('S:')) {
      print('🔍 [MessagesProvider] Processing SAR message: ${message.text}');
      print('   isSarMarker: ${enhancedMessage.isSarMarker}');
      print('   sarMarkerType: ${enhancedMessage.sarMarkerType}');
    }

    _messages.add(enhancedMessage);

    // If it's a SAR marker message, extract and store the marker
    if (enhancedMessage.isSarMarker) {
      final marker = enhancedMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;
      }
    }

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Add multiple messages
  void addMessages(List<Message> messages) {
    for (final message in messages) {
      // Always enhance message with SAR parser to detect SAR markers
      final enhancedMessage = SarMessageParser.enhanceMessage(message);
      _messages.add(enhancedMessage);

      if (enhancedMessage.isSarMarker) {
        final marker = enhancedMessage.toSarMarker();
        if (marker != null) {
          _sarMarkers[marker.id] = marker;
        }
      }
    }

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
      'sarMarkers': sarMarkers.length,
    };
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
}
