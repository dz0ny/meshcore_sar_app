import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../models/path_history.dart';
import '../models/path_selection.dart';

class PathHistoryService {
  static const String _storageKey = 'contact_path_history_v1';
  static const int _maxDirectPaths = 20;
  static const int _topRotationCount = 3;

  final Map<String, ContactPathHistory> _cache = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _isLoaded = true;
      return;
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
    _isLoaded = true;
  }

  Future<void> recordLearnedPath(Contact contact) async {
    await initialize();
    if (!contact.routeHasPath || contact.routeHopCount <= 0) {
      return;
    }

    final history = _historyFor(contact.publicKeyHex);
    final signature = _signature(contact.routePathBytes);
    final existing = _findDirectPath(history.directPaths, signature);
    final updated = PathRecord(
      pathBytes: contact.routePathBytes.toList(),
      hopCount: contact.routeHopCount,
      hashSize: contact.routeHashSize,
      successCount: existing?.successCount ?? 0,
      failureCount: existing?.failureCount ?? 0,
      lastRoundTripTimeMs: existing?.lastRoundTripTimeMs ?? 0,
      lastUsedAt: DateTime.now(),
    );

    await _saveHistory(
      contact.publicKeyHex,
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
    await recordLearnedPath(contact);

    if (!autoRouteRotationEnabled) {
      if (contact.routeHasPath && contact.routeHopCount > 0) {
        return PathSelection(
          mode: PathSelectionMode.directCurrent,
          pathBytes: Uint8List.fromList(contact.routePathBytes),
          hopCount: contact.routeHopCount,
          hashSize: contact.routeHashSize,
        );
      }
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
      successCount: (existing?.successCount ?? 0) + (success ? 1 : 0),
      failureCount: (existing?.failureCount ?? 0) + (success ? 0 : 1),
      lastRoundTripTimeMs: success
          ? (roundTripTimeMs ?? existing?.lastRoundTripTimeMs ?? 0)
          : (existing?.lastRoundTripTimeMs ?? 0),
      lastUsedAt: DateTime.now(),
    );
    await _saveHistory(
      contactPublicKeyHex,
      history.copyWith(
        directPaths: _upsertDirectPath(history.directPaths, updated),
      ),
    );
  }

  ContactPathHistory historyFor(String contactPublicKeyHex) {
    return _cache[contactPublicKeyHex] ??
        ContactPathHistory.empty(contactPublicKeyHex);
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
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    for (final entry in _cache.entries) {
      payload[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_storageKey, jsonEncode(payload));
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
}
