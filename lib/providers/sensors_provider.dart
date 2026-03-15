import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';

enum SensorRefreshState { idle, refreshing, success, timeout, unavailable }

class SensorsProvider with ChangeNotifier {
  static const Duration _successStateRetention = Duration(minutes: 1);
  static const String _watchedSensorsKey = 'watched_sensor_keys';
  static const String _visibleSensorMetricsKey = 'visible_sensor_metrics';
  static const String _fieldSpanKey = 'sensor_field_spans';
  static const String _metricLabelKey = 'sensor_metric_labels';
  static const String _metricOrderKey = 'sensor_metric_order';
  static const String _autoRefreshMinutesKey = 'sensor_auto_refresh_minutes';
  static const List<int> supportedAutoRefreshIntervals = <int>[0, 1, 5, 15];
  static const Set<String> _defaultVisibleFields = <String>{
    'voltage',
    'battery',
    'temperature',
    'humidity',
    'pressure',
    'gps',
  };
  static const List<String> _defaultMetricOrder = <String>[
    'voltage',
    'battery',
    'temperature',
    'humidity',
    'pressure',
    'gps',
  ];

  final List<String> _watchedSensorKeys = <String>[];
  final Map<String, SensorRefreshState> _refreshStates =
      <String, SensorRefreshState>{};
  final Map<String, DateTime> _refreshStateUpdatedAt = <String, DateTime>{};
  final Map<String, Set<String>> _visibleFieldsBySensor =
      <String, Set<String>>{};
  final Map<String, Map<String, int>> _fieldSpansBySensor =
      <String, Map<String, int>>{};
  final Map<String, Map<String, String>> _metricLabelsBySensor =
      <String, Map<String, String>>{};
  final Map<String, List<String>> _metricOrderBySensor =
      <String, List<String>>{};
  final Map<String, int> _autoRefreshMinutesBySensor = <String, int>{};
  final Map<String, DateTime> _lastRefreshAttemptAt = <String, DateTime>{};
  bool _isLoaded = false;
  bool _isRefreshingAll = false;
  bool _isRunningAutoRefreshTick = false;

  SensorsProvider() {
    unawaited(_loadWatchedSensors());
  }

  List<String> get watchedSensorKeys => List.unmodifiable(_watchedSensorKeys);
  bool get isLoaded => _isLoaded;
  bool get isRefreshingAll => _isRefreshingAll;

  SensorRefreshState stateFor(String publicKeyHex) =>
      _refreshStates[publicKeyHex] ?? SensorRefreshState.idle;

  Future<void> _loadWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_watchedSensorsKey) ?? <String>[];
      final storedMetricsJson = prefs.getString(_visibleSensorMetricsKey);
      final storedSpansJson = prefs.getString(_fieldSpanKey);
      final storedLabelsJson = prefs.getString(_metricLabelKey);
      final storedOrderJson = prefs.getString(_metricOrderKey);
      final storedAutoRefreshJson = prefs.getString(_autoRefreshMinutesKey);
      _watchedSensorKeys
        ..clear()
        ..addAll(stored);
      _visibleFieldsBySensor.clear();
      _fieldSpansBySensor.clear();
      _metricLabelsBySensor.clear();
      _metricOrderBySensor.clear();
      _autoRefreshMinutesBySensor.clear();
      if (storedMetricsJson != null && storedMetricsJson.isNotEmpty) {
        final decoded = jsonDecode(storedMetricsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _visibleFieldsBySensor[entry.key] = (entry.value as List<dynamic>)
              .cast<String>()
              .toSet();
        }
      }
      if (storedSpansJson != null && storedSpansJson.isNotEmpty) {
        final decoded = jsonDecode(storedSpansJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _fieldSpansBySensor[entry.key] = (entry.value as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value as int));
        }
      }
      if (storedLabelsJson != null && storedLabelsJson.isNotEmpty) {
        final decoded = jsonDecode(storedLabelsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _metricLabelsBySensor[entry.key] =
              (entry.value as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value as String),
              );
        }
      }
      if (storedOrderJson != null && storedOrderJson.isNotEmpty) {
        final decoded = jsonDecode(storedOrderJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _metricOrderBySensor[entry.key] = (entry.value as List<dynamic>)
              .cast<String>()
              .toList();
        }
      }
      if (storedAutoRefreshJson != null && storedAutoRefreshJson.isNotEmpty) {
        final decoded =
            jsonDecode(storedAutoRefreshJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final minutes = (entry.value as num).toInt();
          if (minutes > 0) {
            _autoRefreshMinutesBySensor[entry.key] = minutes;
          }
        }
      }
      _autoRefreshMinutesBySensor.removeWhere(
        (key, _) => !_watchedSensorKeys.contains(key),
      );
      for (final key in _watchedSensorKeys) {
        _visibleFieldsBySensor.putIfAbsent(
          key,
          () => Set<String>.from(_defaultVisibleFields),
        );
        _fieldSpansBySensor.putIfAbsent(key, () => <String, int>{});
        _metricLabelsBySensor.putIfAbsent(key, () => <String, String>{});
        _metricOrderBySensor.putIfAbsent(
          key,
          () => List<String>.from(_defaultMetricOrder),
        );
      }
    } catch (e) {
      debugPrint('Error loading watched sensors: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchedSensorsKey, _watchedSensorKeys);
    } catch (e) {
      debugPrint('Error saving watched sensors: $e');
    }
  }

  Future<void> _persistVisibleMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, List<String>>{};
      for (final entry in _visibleFieldsBySensor.entries) {
        encoded[entry.key] = entry.value.toList();
      }
      await prefs.setString(_visibleSensorMetricsKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving visible sensor metrics: $e');
    }
  }

  Future<void> _persistFieldSpans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fieldSpanKey, jsonEncode(_fieldSpansBySensor));
    } catch (e) {
      debugPrint('Error saving sensor field spans: $e');
    }
  }

  Future<void> _persistMetricLabels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_metricLabelKey, jsonEncode(_metricLabelsBySensor));
    } catch (e) {
      debugPrint('Error saving sensor metric labels: $e');
    }
  }

  Future<void> _persistMetricOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_metricOrderKey, jsonEncode(_metricOrderBySensor));
    } catch (e) {
      debugPrint('Error saving sensor metric order: $e');
    }
  }

  Future<void> _persistAutoRefreshMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _autoRefreshMinutesKey,
        jsonEncode(_autoRefreshMinutesBySensor),
      );
    } catch (e) {
      debugPrint('Error saving sensor auto refresh minutes: $e');
    }
  }

  Set<String> visibleFieldsFor(String publicKeyHex) => Set<String>.unmodifiable(
    _visibleFieldsBySensor[publicKeyHex] ?? _defaultVisibleFields,
  );

  bool showsField(String publicKeyHex, String fieldKey) =>
      visibleFieldsFor(publicKeyHex).contains(fieldKey);

  int fieldSpanFor(String publicKeyHex, String fieldKey) {
    final sensorSpans = _fieldSpansBySensor[publicKeyHex];
    final span = sensorSpans?[fieldKey] ?? 1;
    return span == 2 ? 2 : 1;
  }

  List<String> metricOrderFor(
    String publicKeyHex,
    Iterable<String> availableFieldKeys,
  ) {
    final available = availableFieldKeys.toList();
    final availableSet = available.toSet();
    final ordered = <String>[];
    final seen = <String>{};
    final stored =
        _metricOrderBySensor[publicKeyHex] ??
        List<String>.from(_defaultMetricOrder);

    for (final fieldKey in stored) {
      if (availableSet.contains(fieldKey) && seen.add(fieldKey)) {
        ordered.add(fieldKey);
      }
    }
    for (final fieldKey in available) {
      if (seen.add(fieldKey)) {
        ordered.add(fieldKey);
      }
    }
    return List<String>.unmodifiable(ordered);
  }

  Map<String, String> labelOverridesFor(String publicKeyHex) =>
      Map<String, String>.unmodifiable(
        _metricLabelsBySensor[publicKeyHex] ?? const <String, String>{},
      );

  String? labelOverrideFor(String publicKeyHex, String fieldKey) =>
      _metricLabelsBySensor[publicKeyHex]?[fieldKey];

  int autoRefreshMinutesFor(String publicKeyHex) =>
      _autoRefreshMinutesBySensor[publicKeyHex] ?? 0;

  Future<void> setAutoRefreshMinutes(String publicKeyHex, int minutes) async {
    final normalizedMinutes = minutes <= 0 ? 0 : minutes;
    final currentMinutes = autoRefreshMinutesFor(publicKeyHex);
    if (currentMinutes == normalizedMinutes) {
      return;
    }

    if (normalizedMinutes == 0) {
      _autoRefreshMinutesBySensor.remove(publicKeyHex);
    } else {
      _autoRefreshMinutesBySensor[publicKeyHex] = normalizedMinutes;
    }
    await _persistAutoRefreshMinutes();
    notifyListeners();
  }

  List<String> dueAutoRefreshSensorKeys({DateTime? now}) {
    final refreshTime = now ?? DateTime.now();
    final dueKeys = <String>[];

    for (final key in _watchedSensorKeys) {
      final minutes = autoRefreshMinutesFor(key);
      if (minutes <= 0) {
        continue;
      }

      final lastRefreshAt = _lastRefreshAttemptAt[key];
      if (lastRefreshAt == null ||
          refreshTime.difference(lastRefreshAt) >= Duration(minutes: minutes)) {
        dueKeys.add(key);
      }
    }

    return List<String>.unmodifiable(dueKeys);
  }

  Future<void> toggleMetric(
    String publicKeyHex,
    String fieldKey,
    bool visible,
  ) async {
    final visibleFields = _visibleFieldsBySensor.putIfAbsent(
      publicKeyHex,
      () => Set<String>.from(_defaultVisibleFields),
    );
    final metricOrder = _metricOrderBySensor.putIfAbsent(
      publicKeyHex,
      () => List<String>.from(_defaultMetricOrder),
    );
    var shouldPersistOrder = false;
    if (visible) {
      visibleFields.add(fieldKey);
      if (!metricOrder.contains(fieldKey)) {
        metricOrder.add(fieldKey);
        shouldPersistOrder = true;
      }
    } else {
      if (visibleFields.length == 1 && visibleFields.contains(fieldKey)) {
        return;
      }
      visibleFields.remove(fieldKey);
    }
    await _persistVisibleMetrics();
    if (shouldPersistOrder) {
      await _persistMetricOrder();
    }
    notifyListeners();
  }

  Future<void> setFieldSpan(
    String publicKeyHex,
    String fieldKey,
    int span,
  ) async {
    final sensorSpans = _fieldSpansBySensor.putIfAbsent(
      publicKeyHex,
      () => <String, int>{},
    );
    sensorSpans[fieldKey] = span == 2 ? 2 : 1;
    await _persistFieldSpans();
    notifyListeners();
  }

  Future<void> setMetricLabel(
    String publicKeyHex,
    String fieldKey,
    String? label,
  ) async {
    final sensorLabels = _metricLabelsBySensor.putIfAbsent(
      publicKeyHex,
      () => <String, String>{},
    );
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      sensorLabels.remove(fieldKey);
    } else {
      sensorLabels[fieldKey] = trimmed;
    }
    if (sensorLabels.isEmpty) {
      _metricLabelsBySensor.remove(publicKeyHex);
    }
    await _persistMetricLabels();
    notifyListeners();
  }

  Future<void> moveMetric(
    String publicKeyHex, {
    required List<String> availableFieldKeys,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= availableFieldKeys.length ||
        newIndex >= availableFieldKeys.length ||
        oldIndex == newIndex) {
      return;
    }

    final reordered = List<String>.from(
      metricOrderFor(publicKeyHex, availableFieldKeys),
    );
    final fieldKey = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, fieldKey);

    final storedTail =
        (_metricOrderBySensor[publicKeyHex] ?? _defaultMetricOrder).where(
          (key) => !reordered.contains(key),
        );
    _metricOrderBySensor[publicKeyHex] = <String>[...reordered, ...storedTail];
    await _persistMetricOrder();
    notifyListeners();
  }

  bool isWatched(String publicKeyHex) =>
      _watchedSensorKeys.contains(publicKeyHex);

  Future<void> addSensor(Contact contact) async {
    if (!contact.isChat && !contact.isRepeater && !contact.isSensor) {
      return;
    }
    if (_watchedSensorKeys.contains(contact.publicKeyHex)) {
      return;
    }

    _watchedSensorKeys.add(contact.publicKeyHex);
    await _persistWatchedSensors();
    _visibleFieldsBySensor[contact.publicKeyHex] = Set<String>.from(
      _defaultVisibleFields,
    );
    _fieldSpansBySensor[contact.publicKeyHex] = <String, int>{'gps': 2};
    _metricLabelsBySensor[contact.publicKeyHex] = <String, String>{};
    _metricOrderBySensor[contact.publicKeyHex] = List<String>.from(
      _defaultMetricOrder,
    );
    await _persistVisibleMetrics();
    await _persistFieldSpans();
    await _persistMetricLabels();
    await _persistMetricOrder();
    notifyListeners();
  }

  Future<void> removeSensor(String publicKeyHex) async {
    _watchedSensorKeys.remove(publicKeyHex);
    _refreshStates.remove(publicKeyHex);
    _refreshStateUpdatedAt.remove(publicKeyHex);
    _visibleFieldsBySensor.remove(publicKeyHex);
    _fieldSpansBySensor.remove(publicKeyHex);
    _metricLabelsBySensor.remove(publicKeyHex);
    _metricOrderBySensor.remove(publicKeyHex);
    _autoRefreshMinutesBySensor.remove(publicKeyHex);
    _lastRefreshAttemptAt.remove(publicKeyHex);
    await _persistWatchedSensors();
    await _persistVisibleMetrics();
    await _persistFieldSpans();
    await _persistMetricLabels();
    await _persistMetricOrder();
    await _persistAutoRefreshMinutes();
    notifyListeners();
  }

  List<Contact> availableCandidates(ContactsProvider contactsProvider) {
    final candidates = <Contact>[
      ...contactsProvider.chatContacts,
      ...contactsProvider.repeaters,
      ...contactsProvider.sensorContacts,
    ];
    candidates.removeWhere((contact) => isWatched(contact.publicKeyHex));
    candidates.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return candidates;
  }

  Future<void> refreshAll({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) async {
    if (_isRefreshingAll || _watchedSensorKeys.isEmpty) {
      return;
    }

    _isRefreshingAll = true;
    notifyListeners();

    try {
      for (final key in _watchedSensorKeys) {
        await refreshSensor(
          publicKeyHex: key,
          contactsProvider: contactsProvider,
          connectionProvider: connectionProvider,
        );
      }
    } finally {
      _isRefreshingAll = false;
      notifyListeners();
    }
  }

  Future<void> refreshSensor({
    required String publicKeyHex,
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
    DateTime? requestedAt,
  }) async {
    if (stateFor(publicKeyHex) == SensorRefreshState.refreshing) {
      return;
    }

    _lastRefreshAttemptAt[publicKeyHex] = requestedAt ?? DateTime.now();

    Contact? contact;
    for (final entry in contactsProvider.contacts) {
      if (entry.publicKeyHex == publicKeyHex) {
        contact = entry;
        break;
      }
    }

    if (contact == null) {
      _setRefreshState(publicKeyHex, SensorRefreshState.unavailable);
      return;
    }

    _setRefreshState(publicKeyHex, SensorRefreshState.refreshing);

    final result = await connectionProvider.smartPing(
      contactPublicKey: contact.publicKey,
      hasPath: contact.hasPath,
    );

    _setRefreshState(
      publicKeyHex,
      result.success ? SensorRefreshState.success : SensorRefreshState.timeout,
    );
  }

  Future<void> refreshDueSensors({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
    DateTime? now,
  }) async {
    if (!connectionProvider.deviceInfo.isConnected ||
        _isRefreshingAll ||
        _isRunningAutoRefreshTick) {
      return;
    }

    final refreshTime = now ?? DateTime.now();
    final dueKeys = dueAutoRefreshSensorKeys(now: refreshTime);
    if (dueKeys.isEmpty) {
      return;
    }

    _isRunningAutoRefreshTick = true;
    try {
      for (final key in dueKeys) {
        await refreshSensor(
          publicKeyHex: key,
          contactsProvider: contactsProvider,
          connectionProvider: connectionProvider,
          requestedAt: refreshTime,
        );
      }
    } finally {
      _isRunningAutoRefreshTick = false;
    }
  }

  void clearExpiredRefreshStates({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(_successStateRetention);
    final keysToClear = <String>[];

    for (final entry in _refreshStates.entries) {
      if (entry.value != SensorRefreshState.success) {
        continue;
      }

      final updatedAt = _refreshStateUpdatedAt[entry.key];
      if (updatedAt == null || !updatedAt.isAfter(cutoff)) {
        keysToClear.add(entry.key);
      }
    }

    if (keysToClear.isEmpty) {
      return;
    }

    for (final key in keysToClear) {
      _refreshStates.remove(key);
      _refreshStateUpdatedAt.remove(key);
    }
    notifyListeners();
  }

  void _setRefreshState(String publicKeyHex, SensorRefreshState state) {
    _refreshStates[publicKeyHex] = state;
    _refreshStateUpdatedAt[publicKeyHex] = DateTime.now();
    notifyListeners();
  }
}
