import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';
import 'package:latlong2/latlong.dart';

/// Service for persisting messages to local storage
class MessageStorageService {
  static const String _messagesKey = 'stored_messages';
  static const int _maxStoredMessages = 1000; // Store up to 1000 messages

  /// Save messages to persistent storage
  Future<void> saveMessages(List<Message> messages) async {
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

      debugPrint('✅ [MessageStorage] Saved ${limitedList.length} messages to storage');
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error saving messages: $e');
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

      debugPrint('✅ [MessageStorage] Loaded ${messages.length} messages from storage');
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
        return {
          'messageCount': 0,
          'storageSizeBytes': 0,
          'storageSizeKB': 0,
        };
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
      return {
        'messageCount': 0,
        'storageSizeBytes': 0,
        'storageSizeKB': 0,
      };
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
      'sarMarkerType': message.sarMarkerType?.name,
      'sarGpsLat': message.sarGpsCoordinates?.latitude,
      'sarGpsLon': message.sarGpsCoordinates?.longitude,
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
                base64Decode(json['senderPublicKeyPrefix'] as String))
            : null,
        channelIdx: json['channelIdx'] as int?,
        pathLen: json['pathLen'] as int,
        textType: MessageTextType.fromValue(json['textType'] as int),
        senderTimestamp: json['senderTimestamp'] as int,
        text: json['text'] as String,
        isSarMarker: json['isSarMarker'] as bool? ?? false,
        sarMarkerType: json['sarMarkerType'] != null
            ? SarMarkerType.values.firstWhere(
                (e) => e.name == json['sarMarkerType'],
                orElse: () => SarMarkerType.unknown,
              )
            : null,
        sarGpsCoordinates: json['sarGpsLat'] != null &&
                json['sarGpsLon'] != null
            ? LatLng(json['sarGpsLat'] as double, json['sarGpsLon'] as double)
            : null,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
            json['receivedAtMillis'] as int),
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
                json['deliveredAtMillis'] as int)
            : null,
        recipientPublicKey: json['recipientPublicKey'] != null
            ? Uint8List.fromList(
                base64Decode(json['recipientPublicKey'] as String))
            : null,
        isRead: json['isRead'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error parsing message from JSON: $e');
      return null;
    }
  }
}
