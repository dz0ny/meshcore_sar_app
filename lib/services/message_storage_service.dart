import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/message_contact_location.dart';
import '../models/message_reception_details.dart';
import '../models/message_transfer_details.dart';
import '../models/message_route_metadata.dart';
import 'package:latlong2/latlong.dart';

/// Service for persisting messages to local storage
class MessageStorageService {
  static const String _messagesKey = 'stored_messages';
  static const String _removedSarMarkerIdsKey = 'removed_sar_marker_ids';
  static const String _messageContactLocationsKey =
      'stored_message_contact_locations';
  static const String _messageReceptionDetailsKey =
      'stored_message_reception_details';
  static const String _messageTransferDetailsKey =
      'stored_message_transfer_details';
  static const String _messageRouteMetadataKey =
      'stored_message_route_metadata';
  static const String _embeddedReceptionDetailsKey = 'storedReceptionDetails';
  static const String _legacyPathBytesKey = 'storedPathBytes';
  static const int _maxStoredMessages = 1000; // Store up to 1000 messages

  /// Save messages to persistent storage
  Future<void> saveMessages(
    List<Message> messages, {
    Map<String, MessageContactLocation> messageContactLocations = const {},
    Map<String, MessageReceptionDetails> messageReceptionDetails = const {},
    Map<String, MessageTransferDetails> messageTransferDetails = const {},
    Map<String, MessageRouteMetadata> messageRouteMetadata = const {},
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert messages to JSON and embed path bytes as a fallback so they
      // survive restore even if the sidecar reception-details entry is absent.
      final jsonList = messages
          .map(
            (msg) => _messageToJson(
              msg,
              receptionDetails: messageReceptionDetails[msg.id],
            ),
          )
          .toList();

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
      final routeMetadataJson = <String, dynamic>{};
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
      for (final entry in messageRouteMetadata.entries) {
        if (retainedMessageIds.contains(entry.key)) {
          routeMetadataJson[entry.key] = entry.value.toJson();
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
      await prefs.setString(
        _messageRouteMetadataKey,
        jsonEncode(routeMetadataJson),
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
      final result = <String, MessageReceptionDetails>{};
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is! Map<String, dynamic>) continue;
            final snapshot = MessageReceptionDetails.fromJson(value);
            if (snapshot != null) {
              result[entry.key] = snapshot;
            }
          }
        }
      }

      final embeddedReceptionDetails = await _loadEmbeddedReceptionDetails();
      embeddedReceptionDetails.forEach((messageId, snapshot) {
        result.putIfAbsent(messageId, () => snapshot);
      });

      final fallbackPathBytes = await _loadLegacyPathBytesFromMessages();
      fallbackPathBytes.forEach((messageId, pathBytes) {
        result.putIfAbsent(
          messageId,
          () => MessageReceptionDetails(
            capturedAt: DateTime.fromMillisecondsSinceEpoch(0),
            pathBytes: pathBytes,
          ),
        );
      });
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

  Future<Map<String, MessageRouteMetadata>> loadMessageRouteMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_messageRouteMetadataKey);
      if (jsonString == null || jsonString.isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const {};
      }

      final result = <String, MessageRouteMetadata>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        result[entry.key] = MessageRouteMetadata.fromJson(value);
      }
      return result;
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading route metadata: $e');
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
      await prefs.remove(_messageRouteMetadataKey);
      await prefs.remove(_removedSarMarkerIdsKey);
      debugPrint('✅ [MessageStorage] Cleared all stored messages');
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error clearing messages: $e');
    }
  }

  Future<Set<String>> loadRemovedSarMarkerIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_removedSarMarkerIdsKey) ?? const [];
      return ids.toSet();
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error loading removed SAR marker IDs: $e');
      return const <String>{};
    }
  }

  Future<void> saveRemovedSarMarkerIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_removedSarMarkerIdsKey, ids.toList()..sort());
      debugPrint(
        '✅ [MessageStorage] Saved ${ids.length} removed SAR marker IDs',
      );
    } catch (e) {
      debugPrint('❌ [MessageStorage] Error saving removed SAR marker IDs: $e');
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
  Map<String, dynamic> _messageToJson(
    Message message, {
    MessageReceptionDetails? receptionDetails,
  }) {
    final persistedPathBytes =
        message.pathBytes ?? _pathBytesFromSnapshot(receptionDetails);
    return {
      'id': message.id,
      'messageType': message.messageType.name,
      'senderPublicKeyPrefix': message.senderPublicKeyPrefix != null
          ? base64Encode(message.senderPublicKeyPrefix!)
          : null,
      'channelIdx': message.channelIdx,
      'pathLen': message.pathLen,
      'pathBytes': persistedPathBytes?.toList(),
      'textType': message.textType.value,
      'senderTimestamp': message.senderTimestamp,
      'text': message.text,
      'isSarMarker': message.isSarMarker,
      'sarGpsLat': message.sarGpsCoordinates?.latitude,
      'sarGpsLon': message.sarGpsCoordinates?.longitude,
      'sarCustomMapLat': message.sarCustomMapPoint?.latitude,
      'sarCustomMapLon': message.sarCustomMapPoint?.longitude,
      'sarCustomMapId': message.sarCustomMapId,
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
      if (receptionDetails != null)
        _embeddedReceptionDetailsKey: receptionDetails.toJson(),
      if (receptionDetails?.pathBytes case final pathBytes?)
        _legacyPathBytesKey: List<int>.from(pathBytes),
    };
  }

  Future<Map<String, MessageReceptionDetails>>
  _loadEmbeddedReceptionDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_messagesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      return const {};
    }

    final result = <String, MessageReceptionDetails>{};
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final messageId = entry['id'];
      final embedded = entry[_embeddedReceptionDetailsKey];
      if (messageId is! String || embedded is! Map<String, dynamic>) continue;
      final snapshot = MessageReceptionDetails.fromJson(embedded);
      if (snapshot == null) continue;
      result[messageId] = snapshot;
    }
    return result;
  }

  Future<Map<String, List<int>>> _loadLegacyPathBytesFromMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_messagesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      return const {};
    }

    final result = <String, List<int>>{};
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final messageId = entry['id'];
      final pathBytes = entry[_legacyPathBytesKey];
      if (messageId is! String || pathBytes is! List) continue;
      final normalized = pathBytes
          .whereType<num>()
          .map((b) => b.toInt())
          .toList();
      if (normalized.isEmpty) continue;
      result[messageId] = normalized;
    }
    return result;
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
        pathBytes: json['pathBytes'] is List
            ? Uint8List.fromList(
                (json['pathBytes'] as List<dynamic>)
                    .whereType<num>()
                    .map((b) => b.toInt())
                    .toList(),
              )
            : null,
        textType: MessageTextType.fromValue(json['textType'] as int),
        senderTimestamp: json['senderTimestamp'] as int,
        text: json['text'] as String,
        isSarMarker: json['isSarMarker'] as bool? ?? false,
        sarGpsCoordinates:
            json['sarGpsLat'] != null && json['sarGpsLon'] != null
            ? LatLng(
                (json['sarGpsLat'] as num).toDouble(),
                (json['sarGpsLon'] as num).toDouble(),
              )
            : null,
        sarCustomMapPoint:
            json['sarCustomMapLat'] != null && json['sarCustomMapLon'] != null
            ? LatLng(
                (json['sarCustomMapLat'] as num).toDouble(),
                (json['sarCustomMapLon'] as num).toDouble(),
              )
            : null,
        sarCustomMapId: json['sarCustomMapId'] as String?,
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

  Uint8List? _pathBytesFromSnapshot(MessageReceptionDetails? receptionDetails) {
    final pathBytes = receptionDetails?.pathBytes;
    if (pathBytes == null || pathBytes.isEmpty) {
      return null;
    }
    return Uint8List.fromList(pathBytes);
  }
}
