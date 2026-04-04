import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../models/path_history.dart';
import '../models/path_selection.dart';
import '../utils/log_rx_route_decoder.dart';

class _ManualPathSelectionRecord {
  final List<int> pathBytes;
  final int hopCount;
  final int hashSize;

  const _ManualPathSelectionRecord({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
  });

  factory _ManualPathSelectionRecord.fromJson(Map<String, dynamic> json) {
    final pathBytes = (json['pathBytes'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<int>()
        .toList();
    return _ManualPathSelectionRecord(
      pathBytes: pathBytes,
      hopCount: json['hopCount'] as int? ?? 0,
      hashSize: json['hashSize'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'pathBytes': pathBytes,
    'hopCount': hopCount,
    'hashSize': hashSize,
  };

  PathSelection toSelection() => PathSelection(
    mode: PathSelectionMode.directCurrent,
    pathBytes: Uint8List.fromList(pathBytes),
    hopCount: hopCount,
    hashSize: hashSize,
  );
}

class PathHistoryService {
  static const String _storageKey = 'contact_path_history_v2';
  static const String _manualRouteStorageKey =
      'contact_manual_path_overrides_v1';
  static const int _maxDirectPaths = 20;
  static const int _topRotationCount = 3;

  final Map<String, ContactPathHistory> _cache = {};
  final Map<String, _ManualPathSelectionRecord> _manualSelections = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final manualRaw = prefs.getString(_manualRouteStorageKey);
    if (raw == null || raw.isEmpty) {
      if (manualRaw == null || manualRaw.isEmpty) {
        _isLoaded = true;
        return;
      }
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is Map<String, dynamic>) {
            _cache[entry.key] = ContactPathHistory.fromJson(entry.key, value);
          }
        }
      }
    } catch (error) {
      debugPrint('⚠️ [PathHistoryService] Failed to load history: $error');
    }
    try {
      if (manualRaw != null && manualRaw.isNotEmpty) {
        final decoded = jsonDecode(manualRaw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is Map<String, dynamic>) {
              _manualSelections[entry.key] =
                  _ManualPathSelectionRecord.fromJson(value);
            }
          }
        }
      }
    } catch (error) {
      debugPrint(
        '⚠️ [PathHistoryService] Failed to load manual routes: $error',
      );
    }
    _isLoaded = true;
  }

  Future<void> recordReceivedBytePath(
    String contactPublicKeyHex,
    List<int> pathBytes,
    int hashSize,
  ) async {
    await initialize();
    if (pathBytes.isEmpty) {
      return;
    }
    if (hashSize < 1 || hashSize > 3) {
      return;
    }
    if (pathBytes.length % hashSize != 0) {
      return;
    }

    final normalizedPathBytes = LogRxRouteDecoder.reverseHopBytes(
      pathBytes,
      hashSize: hashSize,
    );

    final history = _historyFor(contactPublicKeyHex);
    final signature = normalizedPathBytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final existing = _findDirectPath(history.directPaths, signature);
    final updated = PathRecord(
      pathBytes: normalizedPathBytes,
      hopCount: normalizedPathBytes.length ~/ hashSize,
      hashSize: hashSize,
      source: PathRecordSource.observed,
      successCount: existing?.successCount ?? 0,
      failureCount: existing?.failureCount ?? 0,
      lastRoundTripTimeMs: existing?.lastRoundTripTimeMs ?? 0,
      lastUsedAt: DateTime.now(),
      lastSucceededAt: existing?.lastSucceededAt,
      senderLatitude: existing?.senderLatitude,
      senderLongitude: existing?.senderLongitude,
      recipientLatitude: existing?.recipientLatitude,
      recipientLongitude: existing?.recipientLongitude,
    );

    await _saveHistory(
      contactPublicKeyHex,
      history.copyWith(
        directPaths: _upsertDirectPath(history.directPaths, updated),
      ),
    );
  }

  Future<PathSelection> getSelectionForContact(
    Contact contact, {
    required bool autoRouteRotationEnabled,
  }) async {
    await initialize();
    final manualSelection = _manualSelections[contact.publicKeyHex];
    if (manualSelection != null) {
      return manualSelection.toSelection();
    }

    if (!autoRouteRotationEnabled) {
      return PathSelection.flood();
    }

    final history = _historyFor(contact.publicKeyHex);
    final ranked = List<PathRecord>.from(history.directPaths)
      ..sort(_comparePathRecords);
    final topPaths = ranked.take(_topRotationCount).toList();
    if (topPaths.isEmpty) {
      final nextFloodHistory = history.copyWith(
        rotationIndex: history.rotationIndex + 1,
      );
      await _saveHistory(contact.publicKeyHex, nextFloodHistory);
      return PathSelection.flood();
    }

    final selections =
        topPaths
            .map(
              (record) => PathSelection(
                mode: PathSelectionMode.directHistorical,
                pathBytes: Uint8List.fromList(record.pathBytes),
                hopCount: record.hopCount,
                hashSize: record.hashSize,
              ),
            )
            .toList()
          ..add(PathSelection.flood());

    final index = history.rotationIndex % selections.length;
    final updatedHistory = history.copyWith(
      rotationIndex: history.rotationIndex + 1,
    );
    await _saveHistory(contact.publicKeyHex, updatedHistory);
    return selections[index];
  }

  Future<void> recordPathResult(
    String contactPublicKeyHex,
    PathSelection selection, {
    required bool success,
    int? roundTripTimeMs,
    double? senderLatitude,
    double? senderLongitude,
    double? recipientLatitude,
    double? recipientLongitude,
  }) async {
    await initialize();
    final history = _historyFor(contactPublicKeyHex);
    if (selection.usesFlood) {
      final current = history.floodStats;
      await _saveHistory(
        contactPublicKeyHex,
        history.copyWith(
          floodStats: current.copyWith(
            successCount: current.successCount + (success ? 1 : 0),
            failureCount: current.failureCount + (success ? 0 : 1),
            lastRoundTripTimeMs: success
                ? (roundTripTimeMs ?? current.lastRoundTripTimeMs)
                : current.lastRoundTripTimeMs,
            lastUsedAt: DateTime.now(),
          ),
        ),
      );
      return;
    }

    final signature = _signature(selection.pathBytes);
    final existing = _findDirectPath(history.directPaths, signature);
    final updated = PathRecord(
      pathBytes: selection.pathBytes.toList(),
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
      source: success
          ? PathRecordSource.learned
          : existing?.source ?? PathRecordSource.learned,
      successCount: (existing?.successCount ?? 0) + (success ? 1 : 0),
      failureCount: (existing?.failureCount ?? 0) + (success ? 0 : 1),
      lastRoundTripTimeMs: success
          ? (roundTripTimeMs ?? existing?.lastRoundTripTimeMs ?? 0)
          : (existing?.lastRoundTripTimeMs ?? 0),
      lastUsedAt: DateTime.now(),
      lastSucceededAt: success ? DateTime.now() : existing?.lastSucceededAt,
      senderLatitude: success ? senderLatitude : existing?.senderLatitude,
      senderLongitude: success ? senderLongitude : existing?.senderLongitude,
      recipientLatitude:
          success ? recipientLatitude : existing?.recipientLatitude,
      recipientLongitude:
          success ? recipientLongitude : existing?.recipientLongitude,
    );
    await _saveHistory(
      contactPublicKeyHex,
      history.copyWith(
        directPaths: _upsertDirectPath(history.directPaths, updated),
      ),
    );
  }

  Future<PathSelection?> getLastSuccessfulDirectSelection(
    Contact contact, {
    String? excludeSignature,
    double? senderLatitude,
    double? senderLongitude,
    double? recipientLatitude,
    double? recipientLongitude,
  }) async {
    await initialize();
    final history = _historyFor(contact.publicKeyHex);
    final ranked = history.directPaths
        .where(
          (record) =>
              record.successCount > 0 &&
              record.lastSucceededAt != null &&
              record.signature != excludeSignature,
        )
        .toList()
      ..sort((a, b) {
        final locationCompare = _compareLocationFit(
          a,
          b,
          senderLatitude: senderLatitude,
          senderLongitude: senderLongitude,
          recipientLatitude: recipientLatitude,
          recipientLongitude: recipientLongitude,
        );
        if (locationCompare != 0) return locationCompare;
        final succeededCompare = b.lastSucceededAt!.compareTo(
          a.lastSucceededAt!,
        );
        if (succeededCompare != 0) return succeededCompare;
        return _comparePathRecords(a, b);
      });

    if (ranked.isEmpty) {
      return null;
    }

    final record = ranked.first;
    return PathSelection(
      mode: PathSelectionMode.directHistorical,
      pathBytes: Uint8List.fromList(record.pathBytes),
      hopCount: record.hopCount,
      hashSize: record.hashSize,
    );
  }

  ContactPathHistory historyFor(String contactPublicKeyHex) {
    return _cache[contactPublicKeyHex] ??
        ContactPathHistory.empty(contactPublicKeyHex);
  }

  Future<void> setManualRouteForContact(
    Contact contact,
    ParsedContactRoute route,
  ) async {
    await setManualSelectionFor(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directCurrent,
        pathBytes: Uint8List.fromList(route.pathBytes),
        hopCount: route.hopCount,
        hashSize: route.hashSize,
      ),
    );
  }

  Future<void> setManualSelectionFor(
    String contactPublicKeyHex,
    PathSelection selection,
  ) async {
    await initialize();
    _manualSelections[contactPublicKeyHex] = _ManualPathSelectionRecord(
      pathBytes: selection.pathBytes.toList(),
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
    );
    await _persistState();
  }

  Future<PathSelection?> getManualSelectionForContact(Contact contact) async {
    await initialize();
    return _manualSelections[contact.publicKeyHex]?.toSelection();
  }

  Future<void> clearManualRouteFor(String contactPublicKeyHex) async {
    await initialize();
    _manualSelections.remove(contactPublicKeyHex);
    await _persistState();
  }

  Future<void> clearHistoryFor(String contactPublicKeyHex) async {
    await initialize();
    _cache.remove(contactPublicKeyHex);
    await _persistState();
  }

  Future<void> clearHistoryForContact(Contact contact) async {
    await clearHistoryFor(contact.publicKeyHex);
  }

  ContactPathHistory _historyFor(String contactPublicKeyHex) {
    return _cache.putIfAbsent(
      contactPublicKeyHex,
      () => ContactPathHistory.empty(contactPublicKeyHex),
    );
  }

  Future<void> _saveHistory(
    String contactPublicKeyHex,
    ContactPathHistory history,
  ) async {
    _cache[contactPublicKeyHex] = history;
    await _persistState();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    for (final entry in _cache.entries) {
      payload[entry.key] = entry.value.toJson();
    }
    final manualPayload = <String, dynamic>{};
    for (final entry in _manualSelections.entries) {
      manualPayload[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_storageKey, jsonEncode(payload));
    await prefs.setString(_manualRouteStorageKey, jsonEncode(manualPayload));
  }

  List<PathRecord> _upsertDirectPath(
    List<PathRecord> existing,
    PathRecord updatedRecord,
  ) {
    final updated = List<PathRecord>.from(existing)
      ..removeWhere((record) => record.signature == updatedRecord.signature)
      ..insert(0, updatedRecord);
    if (updated.length > _maxDirectPaths) {
      return updated.take(_maxDirectPaths).toList();
    }
    return updated;
  }

  int _comparePathRecords(PathRecord a, PathRecord b) {
    final successRateCompare = b.successRate.compareTo(a.successRate);
    if (successRateCompare != 0) return successRateCompare;

    final successCountCompare = b.successCount.compareTo(a.successCount);
    if (successCountCompare != 0) return successCountCompare;

    final aRtt = a.lastRoundTripTimeMs == 0 ? 1 << 30 : a.lastRoundTripTimeMs;
    final bRtt = b.lastRoundTripTimeMs == 0 ? 1 << 30 : b.lastRoundTripTimeMs;
    final rttCompare = aRtt.compareTo(bRtt);
    if (rttCompare != 0) return rttCompare;

    return b.lastUsedAt.compareTo(a.lastUsedAt);
  }

  PathRecord? _findDirectPath(List<PathRecord> records, String signature) {
    for (final record in records) {
      if (record.signature == signature) {
        return record;
      }
    }
    return null;
  }

  String _signature(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  int _compareLocationFit(
    PathRecord a,
    PathRecord b, {
    required double? senderLatitude,
    required double? senderLongitude,
    required double? recipientLatitude,
    required double? recipientLongitude,
  }) {
    final aDistance = _locationDistanceScore(
      a,
      senderLatitude: senderLatitude,
      senderLongitude: senderLongitude,
      recipientLatitude: recipientLatitude,
      recipientLongitude: recipientLongitude,
    );
    final bDistance = _locationDistanceScore(
      b,
      senderLatitude: senderLatitude,
      senderLongitude: senderLongitude,
      recipientLatitude: recipientLatitude,
      recipientLongitude: recipientLongitude,
    );
    return aDistance.compareTo(bDistance);
  }

  double _locationDistanceScore(
    PathRecord record, {
    required double? senderLatitude,
    required double? senderLongitude,
    required double? recipientLatitude,
    required double? recipientLongitude,
  }) {
    var total = 0.0;
    var matched = false;

    if (senderLatitude != null &&
        senderLongitude != null &&
        record.senderLatitude != null &&
        record.senderLongitude != null) {
      matched = true;
      total += Geolocator.distanceBetween(
        senderLatitude,
        senderLongitude,
        record.senderLatitude!,
        record.senderLongitude!,
      );
    }

    if (recipientLatitude != null &&
        recipientLongitude != null &&
        record.recipientLatitude != null &&
        record.recipientLongitude != null) {
      matched = true;
      total += Geolocator.distanceBetween(
        recipientLatitude,
        recipientLongitude,
        record.recipientLatitude!,
        record.recipientLongitude!,
      );
    }

    return matched ? total : double.infinity;
  }
}
