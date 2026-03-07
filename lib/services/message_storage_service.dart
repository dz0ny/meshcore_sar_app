import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/message_contact_location.dart';
import '../models/message_reception_details.dart';
import '../models/message_transfer_details.dart';
import 'package:latlong2/latlong.dart';

/// Service for persisting messages to local storage
class MessageStorageService {
  static const String _messagesKey = 'stored_messages';
  static const String _messageContactLocationsKey =
      'stored_message_contact_locations';
  static const String _messageReceptionDetailsKey =
      'stored_message_reception_details';
  static const String _messageTransferDetailsKey =
      'stored_message_transfer_details';
  static const int _maxStoredMessages = 1000; // Store up to 1000 messages

  /// Save messages to persistent storage
  Future<void> saveMessages(
    List<Message> messages, {
    Map<String, MessageContactLocation> messageContactLocations = const {},
    Map<String, MessageReceptionDetails> messageReceptionDetails = const {},
    Map<String, MessageTransferDetails> messageTransferDetails = const {},
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert messages to JSON
      final jsonList = messages.map((msg) => _messageToJson(msg)).toList();

      // Limit to max stored messages (keep most recent)
      final limitedList = jsonList.length > _maxStoredMessages
          ? jsonList.sublist(jsonList.length - _maxStoredMessages)
          : jsonList;

      final jsonString = jsonEncode(limitedList);
      await prefs.setString(_messagesKey, jsonString);
      final retainedMessageIds = limitedList
          .map((entry) => entry['id'] as String)
          .toSet();
      final locationJson = <String, dynamic>{};
      final receptionJson = <String, dynamic>{};
      final transferJson = <String, dynamic>{};
      for (final entry in messageContactLocations.entries) {
        if (retainedMessageIds.contains(entry.key)) {
          locationJson[entry.key] = entry.value.toJson();
        }
      }
      for (final entry in messageReceptionDetails.entries) {
        if (retainedMessageIds.contains(entry.key)) {
          receptionJson[entry.key] = entry.value.toJson();
        }
      }
      for (final entry in messageTransferDetails.entries) {
        if (retainedMessageIds.contains(entry.key)) {
          transferJson[entry.key] = entry.value.toJson();
        }
      }
      await prefs.setString(
        _messageContactLocationsKey,
        jsonEncode(locationJson),
      );
      await prefs.setString(
        _messageReceptionDetailsKey,
        jsonEncode(receptionJson),
      );
      await prefs.setString(
        _messageTransferDetailsKey,
        jsonEncode(transferJson),
      );

      debugPrint(
        '✅ [MessageStorage] Saved ${limitedList.length} messages to storage',
      );
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error saving messages: $e');
    }
  }

  Future<Map<String, MessageContactLocation>>
  loadMessageContactLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messageContactLocationsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }

      final result = <String, MessageContactLocation>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final snapshot = MessageContactLocation.fromJson(value);
        if (snapshot != null) {
          result[entry.key] = snapshot;
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading contact locations: $e');
      return const {};
    }
  }

  Future<Map<String, MessageReceptionDetails>>
  loadMessageReceptionDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messageReceptionDetailsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }

      final result = <String, MessageReceptionDetails>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final snapshot = MessageReceptionDetails.fromJson(value);
        if (snapshot != null) {
          result[entry.key] = snapshot;
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading reception details: $e');
      return const {};
    }
  }

  Future<Map<String, MessageTransferDetails>>
  loadMessageTransferDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messageTransferDetailsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }

      final result = <String, MessageTransferDetails>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final details = MessageTransferDetails.fromJson(value);
        if (details != null) {
          result[entry.key] = details;
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading transfer details: $e');
      return const {};
    }
  }

  /// Load messages from persistent storage
  Future<List<Message>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messagesKey);

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('ℹ️ [MessageStorage] No stored messages found');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final messages = jsonList
          .map((json) => _messageFromJson(json as Map<String, dynamic>))
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();

      debugPrint(
        '✅ [MessageStorage] Loaded ${messages.length} messages from storage',
      );
      return messages;
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading messages: $e');
      return [];
    }
  }

  /// Clear all stored messages
  Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
      await prefs.remove(_messageContactLocationsKey);
      await prefs.remove(_messageReceptionDetailsKey);
      await prefs.remove(_messageTransferDetailsKey);
      debugPrint('✅ [MessageStorage] Cleared all stored messages');
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error clearing messages: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messagesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {'messageCount': 0, 'storageSizeBytes': 0, 'storageSizeKB': 0};
      }

      final sizeBytes = jsonString.length;
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      return {
        'messageCount': jsonList.length,
        'storageSizeBytes': sizeBytes,
        'storageSizeKB': (sizeBytes / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error getting storage stats: $e');
      return {'messageCount': 0, 'storageSizeBytes': 0, 'storageSizeKB': 0};
    }
  }

  /// Convert Message to JSON
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'messageType': message.messageType.name,
      'senderPublicKeyPrefix': message.senderPublicKeyPrefix != null
          ? base64Encode(message.senderPublicKeyPrefix!)
          : null,
      'channelIdx': message.channelIdx,
      'pathLen': message.pathLen,
      'textType': message.textType.value,
      'senderTimestamp': message.senderTimestamp,
      'text': message.text,
      'isSarMarker': message.isSarMarker,
      'sarGpsLat': message.sarGpsCoordinates?.latitude,
      'sarGpsLon': message.sarGpsCoordinates?.longitude,
      'sarNotes': message.sarNotes,
      'sarCustomEmoji': message.sarCustomEmoji,
      'sarColorIndex': message.sarColorIndex,
      'receivedAtMillis': message.receivedAt.millisecondsSinceEpoch,
      'senderName': message.senderName,
      'deliveryStatus': message.deliveryStatus.name,
      'expectedAckTag': message.expectedAckTag,
      'suggestedTimeoutMs': message.suggestedTimeoutMs,
      'roundTripTimeMs': message.roundTripTimeMs,
      'deliveredAtMillis': message.deliveredAt?.millisecondsSinceEpoch,
      'recipientPublicKey': message.recipientPublicKey != null
          ? base64Encode(message.recipientPublicKey!)
          : null,
      'isRead': message.isRead,
      // Retry state tracking (IMPORTANT for preserving state across app restarts)
      'retryAttempt': message.retryAttempt,
      'lastRetryAtMillis': message.lastRetryAt?.millisecondsSinceEpoch,
      'usedFloodFallback': message.usedFloodFallback,
      // Echo detection for channel messages
      'echoCount': message.echoCount,
      'firstEchoAtMillis': message.firstEchoAt?.millisecondsSinceEpoch,
      'lastEchoSnrRaw': message.lastEchoSnrRaw,
      'lastEchoRssiDbm': message.lastEchoRssiDbm,
      'lastEchoAtMillis': message.lastEchoAt?.millisecondsSinceEpoch,
      // Drawing message tracking
      'isDrawing': message.isDrawing,
      'drawingId': message.drawingId,
      // Voice message tracking
      'isVoice': message.isVoice,
      'voiceId': message.voiceId,
      // Message grouping (for bulk sends)
      'groupId': message.groupId,
      'recipients': message.recipients
          ?.map(
            (r) => {
              'publicKey': base64Encode(r.publicKey),
              'displayName': r.displayName,
              'deliveryStatus': r.deliveryStatus.name,
              'expectedAckTag': r.expectedAckTag,
              'roundTripTimeMs': r.roundTripTimeMs,
              'deliveredAtMillis': r.deliveredAt?.millisecondsSinceEpoch,
              'sentAtMillis': r.sentAt.millisecondsSinceEpoch,
            },
          )
          .toList(),
    };
  }

  /// Convert JSON to Message
  Message? _messageFromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id'] as String,
        messageType: MessageType.values.firstWhere(
          (e) => e.name == json['messageType'],
          orElse: () => MessageType.contact,
        ),
        senderPublicKeyPrefix: json['senderPublicKeyPrefix'] != null
            ? Uint8List.fromList(
                base64Decode(json['senderPublicKeyPrefix'] as String),
              )
            : null,
        channelIdx: json['channelIdx'] as int?,
        pathLen: json['pathLen'] as int,
        textType: MessageTextType.fromValue(json['textType'] as int),
        senderTimestamp: json['senderTimestamp'] as int,
        text: json['text'] as String,
        isSarMarker: json['isSarMarker'] as bool? ?? false,
        sarGpsCoordinates:
            json['sarGpsLat'] != null && json['sarGpsLon'] != null
            ? LatLng(json['sarGpsLat'] as double, json['sarGpsLon'] as double)
            : null,
        sarNotes: json['sarNotes'] as String?,
        sarCustomEmoji: json['sarCustomEmoji'] as String?,
        sarColorIndex: json['sarColorIndex'] as int?,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          json['receivedAtMillis'] as int,
        ),
        senderName: json['senderName'] as String?,
        deliveryStatus: json['deliveryStatus'] != null
            ? MessageDeliveryStatus.values.firstWhere(
                (e) => e.name == json['deliveryStatus'],
                orElse: () => MessageDeliveryStatus.received,
              )
            : MessageDeliveryStatus.received,
        expectedAckTag: json['expectedAckTag'] as int?,
        suggestedTimeoutMs: json['suggestedTimeoutMs'] as int?,
        roundTripTimeMs: json['roundTripTimeMs'] as int?,
        deliveredAt: json['deliveredAtMillis'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['deliveredAtMillis'] as int,
              )
            : null,
        recipientPublicKey: json['recipientPublicKey'] != null
            ? Uint8List.fromList(
                base64Decode(json['recipientPublicKey'] as String),
              )
            : null,
        isRead: json['isRead'] as bool? ?? false,
        // Retry state tracking (preserves retry/flood state across restarts)
        retryAttempt: json['retryAttempt'] as int? ?? 0,
        lastRetryAt: json['lastRetryAtMillis'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['lastRetryAtMillis'] as int,
              )
            : null,
        usedFloodFallback: json['usedFloodFallback'] as bool? ?? false,
        // Echo detection
        echoCount: json['echoCount'] as int? ?? 0,
        firstEchoAt: json['firstEchoAtMillis'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['firstEchoAtMillis'] as int,
              )
            : null,
        lastEchoSnrRaw: json['lastEchoSnrRaw'] as int?,
        lastEchoRssiDbm: json['lastEchoRssiDbm'] as int?,
        lastEchoAt: json['lastEchoAtMillis'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                json['lastEchoAtMillis'] as int,
              )
            : null,
        // Drawing message tracking
        isDrawing: json['isDrawing'] as bool? ?? false,
        drawingId: json['drawingId'] as String?,
        // Voice message tracking
        isVoice: json['isVoice'] as bool? ?? false,
        voiceId: json['voiceId'] as String?,
        // Message grouping
        groupId: json['groupId'] as String?,
        recipients: json['recipients'] != null
            ? (json['recipients'] as List<dynamic>)
                  .map(
                    (r) => MessageRecipient(
                      publicKey: Uint8List.fromList(
                        base64Decode(r['publicKey'] as String),
                      ),
                      displayName: r['displayName'] as String,
                      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
                        (e) => e.name == r['deliveryStatus'],
                        orElse: () => MessageDeliveryStatus.sending,
                      ),
                      expectedAckTag: r['expectedAckTag'] as int?,
                      roundTripTimeMs: r['roundTripTimeMs'] as int?,
                      deliveredAt: r['deliveredAtMillis'] != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              r['deliveredAtMillis'] as int,
                            )
                          : null,
                      sentAt: DateTime.fromMillisecondsSinceEpoch(
                        r['sentAtMillis'] as int,
                      ),
                    ),
                  )
                  .toList()
            : null,
      );
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error parsing message from JSON: $e');
      return null;
    }
  }
}
