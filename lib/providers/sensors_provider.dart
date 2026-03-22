import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../services/profiles_feature_service.dart';
import '../widgets/sensors/sensor_telemetry_card.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';

enum SensorRefreshState { idle, refreshing, success, timeout, unavailable }

class SensorsProvider with ChangeNotifier {
  static const Duration _successStateRetention = Duration(minutes: 1);
  static const int selfAutoRefreshMinutes = 1;
  static const String _watchedSensorsKey = 'watched_sensor_keys';
  static const String _visibleSensorMetricsKey = 'visible_sensor_metrics';
  static const String _fieldSpanKey = 'sensor_field_spans';
  static const String _metricLabelKey = 'sensor_metric_labels';
  static const String _metricOrderKey = 'sensor_metric_order';
  static const String _autoRefreshMinutesKey = 'sensor_auto_refresh_minutes';
  static const List<int> supportedAutoRefreshIntervals = <int>[
    0,
    5,
    15,
    30,
    60,
    360,
    720,
    1440,
  ];
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

  String _key(String baseKey) => ProfileStorageScope.scopedKey(baseKey);

  List<String> get watchedSensorKeys => List.unmodifiable(_watchedSensorKeys);
  bool get isLoaded => _isLoaded;
  bool get isRefreshingAll => _isRefreshingAll;

  SensorRefreshState stateFor(String publicKeyHex) =>
      _refreshStates[publicKeyHex] ?? SensorRefreshState.idle;

  Future<void> _loadWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored =
          prefs.getStringList(_key(_watchedSensorsKey)) ?? <String>[];
      final storedMetricsJson = prefs.getString(_key(_visibleSensorMetricsKey));
      final storedSpansJson = prefs.getString(_key(_fieldSpanKey));
      final storedLabelsJson = prefs.getString(_key(_metricLabelKey));
      final storedOrderJson = prefs.getString(_key(_metricOrderKey));
      final storedAutoRefreshJson = prefs.getString(
        _key(_autoRefreshMinutesKey),
      );
      _watchedSensorKeys
        ..clear()
        ..addAll(stored);
      _refreshStates.clear();
      _refreshStateUpdatedAt.clear();
      _visibleFieldsBySensor.clear();
      _fieldSpansBySensor.clear();
      _metricLabelsBySensor.clear();
      _metricOrderBySensor.clear();
      _autoRefreshMinutesBySensor.clear();
      _lastRefreshAttemptAt.clear();
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
          final minutes = _normalizeAutoRefreshMinutes(
            (entry.value as num).toInt(),
          );
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

  Future<void> reloadProfileScopedState() async {
    _isLoaded = false;
    await _loadWatchedSensors();
  }

  Future<void> _persistWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(_watchedSensorsKey), _watchedSensorKeys);
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
      await prefs.setString(
        _key(_visibleSensorMetricsKey),
        jsonEncode(encoded),
      );
    } catch (e) {
      debugPrint('Error saving visible sensor metrics: $e');
    }
  }

  Future<void> _persistFieldSpans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(_fieldSpanKey),
        jsonEncode(_fieldSpansBySensor),
      );
    } catch (e) {
      debugPrint('Error saving sensor field spans: $e');
    }
  }

  Future<void> _persistMetricLabels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(_metricLabelKey),
        jsonEncode(_metricLabelsBySensor),
      );
    } catch (e) {
      debugPrint('Error saving sensor metric labels: $e');
    }
  }

  Future<void> _persistMetricOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(_metricOrderKey),
        jsonEncode(_metricOrderBySensor),
      );
    } catch (e) {
      debugPrint('Error saving sensor metric order: $e');
    }
  }

  Future<void> _persistAutoRefreshMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(_autoRefreshMinutesKey),
        jsonEncode(_autoRefreshMinutesBySensor),
      );
    } catch (e) {
      debugPrint('Error saving sensor auto refresh minutes: $e');
    }
  }

  Set<String> visibleFieldsFor(String publicKeyHex) => Set<String>.unmodifiable(
    _visibleFieldsBySensor[publicKeyHex] ?? _defaultVisibleFields,
  );

  Set<String> effectiveVisibleFieldsFor(
    String publicKeyHex,
    Iterable<String> availableFieldKeys,
  ) {
    final storedVisibleFields =
        _visibleFieldsBySensor[publicKeyHex] ?? _defaultVisibleFields;
    if (!_shouldAutoIncludeAvailableFields(publicKeyHex, storedVisibleFields)) {
      return Set<String>.unmodifiable(storedVisibleFields);
    }

    return Set<String>.unmodifiable(<String>{
      ...storedVisibleFields,
      ...availableFieldKeys,
    });
  }

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
    final normalizedMinutes = _normalizeAutoRefreshMinutes(minutes);
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

  static int _normalizeAutoRefreshMinutes(int minutes) {
    if (minutes <= 0) {
      return 0;
    }

    if (supportedAutoRefreshIntervals.contains(minutes)) {
      return minutes;
    }

    final positiveIntervals = supportedAutoRefreshIntervals.where(
      (value) => value > 0,
    );
    var bestMatch = positiveIntervals.first;
    var bestDistance = (minutes - bestMatch).abs();

    for (final interval in positiveIntervals.skip(1)) {
      final distance = (minutes - interval).abs();
      if (distance < bestDistance) {
        bestMatch = interval;
        bestDistance = distance;
      }
    }

    return bestMatch;
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

  bool _isRefreshDue(
    String publicKeyHex, {
    required int minutes,
    required DateTime refreshTime,
  }) {
    if (minutes <= 0) {
      return false;
    }

    final lastRefreshAt = _lastRefreshAttemptAt[publicKeyHex];
    return lastRefreshAt == null ||
        refreshTime.difference(lastRefreshAt) >= Duration(minutes: minutes);
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

  Contact? selfContact(
    ContactsProvider contactsProvider,
    ConnectionProvider connectionProvider,
  ) {
    final selfKey = connectionProvider.deviceInfo.publicKey;
    if (selfKey == null || selfKey.isEmpty) {
      return null;
    }

    final existing = contactsProvider.findContactByKey(
      Uint8List.fromList(selfKey),
    );
    final selfTelemetry = contactsProvider.selfTelemetry;
    if (existing != null) {
      return selfTelemetry == null
          ? existing
          : existing.copyWith(telemetry: selfTelemetry);
    }

    return _buildSelfCandidate(connectionProvider, telemetry: selfTelemetry);
  }

  Future<void> addSensor(Contact contact) async {
    if (!contact.isChat && !contact.isRepeater && !contact.isSensor) {
      return;
    }
    if (_watchedSensorKeys.contains(contact.publicKeyHex)) {
      return;
    }

    _watchedSensorKeys.add(contact.publicKeyHex);
    final initialVisibleFields = _initialVisibleFieldsForContact(contact);
    await _persistWatchedSensors();
    _visibleFieldsBySensor[contact.publicKeyHex] = initialVisibleFields;
    _fieldSpansBySensor[contact.publicKeyHex] = <String, int>{'gps': 2};
    _metricLabelsBySensor[contact.publicKeyHex] = <String, String>{};
    _metricOrderBySensor[contact.publicKeyHex] = metricOrderFor(
      contact.publicKeyHex,
      initialVisibleFields,
    );
    await _persistVisibleMetrics();
    await _persistFieldSpans();
    await _persistMetricLabels();
    await _persistMetricOrder();
    notifyListeners();
  }

  bool _shouldAutoIncludeAvailableFields(
    String publicKeyHex,
    Set<String> storedVisibleFields,
  ) {
    if (!setEquals(storedVisibleFields, _defaultVisibleFields)) {
      return false;
    }

    final storedOrder = _metricOrderBySensor[publicKeyHex];
    if (storedOrder != null && !listEquals(storedOrder, _defaultMetricOrder)) {
      return false;
    }

    final storedLabels = _metricLabelsBySensor[publicKeyHex];
    if (storedLabels != null && storedLabels.isNotEmpty) {
      return false;
    }

    final storedSpans = _fieldSpansBySensor[publicKeyHex];
    if (storedSpans != null &&
        !(storedSpans.length == 1 && storedSpans['gps'] == 2)) {
      return false;
    }

    return true;
  }

  Set<String> _initialVisibleFieldsForContact(Contact contact) {
    return <String>{..._defaultVisibleFields, ...sensorMetricKeysFor(contact)};
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

  Future<void> reorderSensors(int oldIndex, int newIndex) async {
    if (_watchedSensorKeys.length < 2) {
      return;
    }
    if (oldIndex < 0 ||
        oldIndex >= _watchedSensorKeys.length ||
        newIndex < 0 ||
        newIndex > _watchedSensorKeys.length) {
      return;
    }

    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (oldIndex == targetIndex) {
      return;
    }

    final movedKey = _watchedSensorKeys.removeAt(oldIndex);
    _watchedSensorKeys.insert(targetIndex, movedKey);
    await _persistWatchedSensors();
    notifyListeners();
  }

  List<Contact> availableCandidates(
    ContactsProvider contactsProvider, {
    ConnectionProvider? connectionProvider,
  }) {
    final candidates = <Contact>[
      ...contactsProvider.chatContacts,
      ...contactsProvider.repeaters,
      ...contactsProvider.sensorContacts,
    ];

    // Add "myself" (own device) as a candidate if it has a public key
    if (connectionProvider != null) {
      final self = selfContact(contactsProvider, connectionProvider);
      if (self != null &&
          !candidates.any((c) => c.publicKeyHex == self.publicKeyHex)) {
        candidates.insert(0, self);
      }
    }

    candidates.removeWhere((contact) => isWatched(contact.publicKeyHex));
    candidates.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return candidates;
  }

  List<String> displaySensorKeys({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) {
    if (_watchedSensorKeys.isNotEmpty) {
      return List<String>.unmodifiable(_watchedSensorKeys);
    }

    final self = selfContact(contactsProvider, connectionProvider);
    if (self == null) {
      return const <String>[];
    }

    return <String>[self.publicKeyHex];
  }

  String? displaySelfKey({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) {
    final self = selfContact(contactsProvider, connectionProvider);
    if (self == null || _watchedSensorKeys.contains(self.publicKeyHex)) {
      return null;
    }
    return self.publicKeyHex;
  }

  Contact? contactForDisplay(
    String publicKeyHex, {
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) {
    for (final entry in contactsProvider.contacts) {
      if (entry.publicKeyHex == publicKeyHex) {
        return entry;
      }
    }

    final self = selfContact(contactsProvider, connectionProvider);
    if (self?.publicKeyHex == publicKeyHex) {
      return self;
    }

    return null;
  }

  Future<void> refreshAll({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) async {
    if (_isRefreshingAll) {
      return;
    }

    final self = selfContact(contactsProvider, connectionProvider);
    final keysToRefresh = <String>[
      if (self != null) self.publicKeyHex,
      ..._watchedSensorKeys.where(
        (key) => self == null || key != self.publicKeyHex,
      ),
    ];
    if (keysToRefresh.isEmpty) {
      return;
    }

    _isRefreshingAll = true;
    notifyListeners();

    try {
      for (final key in keysToRefresh) {
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

    final contact = contactForDisplay(
      publicKeyHex,
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
    );

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
    final dueKeys = dueAutoRefreshSensorKeys(now: refreshTime).toList();
    final self = selfContact(contactsProvider, connectionProvider);
    if (self != null &&
        !dueKeys.contains(self.publicKeyHex) &&
        _isRefreshDue(
          self.publicKeyHex,
          minutes: selfAutoRefreshMinutes,
          refreshTime: refreshTime,
        )) {
      dueKeys.insert(0, self.publicKeyHex);
    }
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

  Contact? _buildSelfCandidate(
    ConnectionProvider connectionProvider, {
    ContactTelemetry? telemetry,
  }) {
    final deviceInfo = connectionProvider.deviceInfo;
    final selfKey = deviceInfo.publicKey;
    if (selfKey == null || selfKey.isEmpty) {
      return null;
    }

    return Contact(
      publicKey: Uint8List.fromList(selfKey),
      type: ContactType.chat,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: deviceInfo.selfName ?? 'My Device',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: deviceInfo.advLat ?? 0,
      advLon: deviceInfo.advLon ?? 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      telemetry: telemetry,
    );
  }
}
