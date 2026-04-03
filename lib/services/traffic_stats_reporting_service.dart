import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ble_packet_log.dart';
import '../utils/log_rx_route_decoder.dart';
import 'live_traffic_summary.dart';

class TrafficStatsCounts {
  static const List<String> packetTypeKeys = <String>[
    'pt_00',
    'pt_01',
    'pt_02',
    'pt_03',
    'pt_04',
    'pt_05',
    'pt_06',
    'pt_07',
    'pt_08',
    'pt_09',
    'pt_0a',
    'pt_0b',
    'pt_0c',
    'pt_0d',
    'pt_0e',
    'pt_0f',
  ];
  static const List<String> pathModeKeys = <String>[
    'path_mode_1b',
    'path_mode_2b',
    'path_mode_3b',
    'path_mode_none',
    'path_mode_unknown',
  ];
  static const String decodeFailKey = 'decode_fail';
  static const List<String> allKeys = <String>[
    ...packetTypeKeys,
    decodeFailKey,
    ...pathModeKeys,
  ];

  final Map<String, int> _values;

  TrafficStatsCounts._(this._values);

  factory TrafficStatsCounts.empty() {
    return TrafficStatsCounts._(
      <String, int>{for (final key in allKeys) key: 0},
    );
  }

  factory TrafficStatsCounts.fromJson(Map<String, dynamic>? json) {
    final counts = TrafficStatsCounts.empty();
    if (json == null) {
      return counts;
    }
    for (final key in allKeys) {
      counts._values[key] = (json[key] as num?)?.toInt() ?? 0;
    }
    return counts;
  }

  int operator [](String key) => _values[key] ?? 0;

  bool get isEmpty => _values.values.every((value) => value == 0);

  Map<String, int> toJson() {
    return <String, int>{
      for (final key in allKeys) key: _values[key] ?? 0,
    };
  }

  void increment(String key, [int amount = 1]) {
    _values[key] = (_values[key] ?? 0) + amount;
  }

  void incrementPacketType(int payloadType) {
    if (payloadType < 0 || payloadType > 0x0F) {
      increment(decodeFailKey);
      return;
    }
    increment('pt_${payloadType.toRadixString(16).padLeft(2, '0')}');
  }

  void mergeFrom(TrafficStatsCounts other) {
    for (final key in allKeys) {
      increment(key, other[key]);
    }
  }
}

class TrafficStatsQueuedReport {
  final String reportId;
  final String deviceKey6;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String appVersion;
  final TrafficStatsCounts counts;

  const TrafficStatsQueuedReport({
    required this.reportId,
    required this.deviceKey6,
    required this.windowStart,
    required this.windowEnd,
    required this.appVersion,
    required this.counts,
  });

  factory TrafficStatsQueuedReport.fromJson(Map<String, dynamic> json) {
    return TrafficStatsQueuedReport(
      reportId: (json['reportId'] as String?) ?? '',
      deviceKey6: (json['deviceKey6'] as String?) ?? '',
      windowStart: DateTime.parse(json['windowStart'] as String).toUtc(),
      windowEnd: DateTime.parse(json['windowEnd'] as String).toUtc(),
      appVersion: (json['appVersion'] as String?) ?? 'unknown',
      counts: TrafficStatsCounts.fromJson(
        json['counts'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reportId': reportId,
      'deviceKey6': deviceKey6,
      'windowStart': windowStart.toIso8601String(),
      'windowEnd': windowEnd.toIso8601String(),
      'appVersion': appVersion,
      'counts': counts.toJson(),
    };
  }
}

class TrafficStatsReportingService extends ChangeNotifier {
  static const String workerBaseUrl = 'https://mcstats.dz0ny.dev';
  static final Uri dashboardUri = Uri.parse(workerBaseUrl);
  static final Uri ingestUri = Uri.parse('$workerBaseUrl/api/ingest');

  static const bool defaultEnabled = true;
  static const int defaultIntervalMinutes = 5;
  static const String _enabledKey = 'traffic_stats_reporting_enabled';
  static const String _legacyIntervalKey =
      'traffic_stats_reporting_interval_minutes';
  static const String _queueKey = 'traffic_stats_reporting_queue';
  static const String _lastSuccessAtKey =
      'traffic_stats_reporting_last_success_at';
  static const String _lastErrorKey = 'traffic_stats_reporting_last_error';
  static const Duration _retryInterval = Duration(seconds: 30);

  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _now;
  final Future<SharedPreferences> Function() _prefsProvider;
  final Future<String> Function() _appVersionProvider;
  final Map<int, TrafficStatsCounts> _openWindows =
      <int, TrafficStatsCounts>{};
  final List<TrafficStatsQueuedReport> _queue = <TrafficStatsQueuedReport>[];

  String? Function()? _deviceKey6Provider;
  Timer? _retryTimer;
  String? _appVersion;
  bool _enabled = defaultEnabled;
  DateTime? _lastSuccessAt;
  String? _lastError;
  bool _isInitialized = false;
  bool _isFlushingQueue = false;

  TrafficStatsReportingService({
    http.Client? client,
    DateTime Function()? now,
    Future<SharedPreferences> Function()? prefsProvider,
    Future<String> Function()? appVersionProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _now = now ?? DateTime.now,
       _prefsProvider = prefsProvider ?? SharedPreferences.getInstance,
       _appVersionProvider = appVersionProvider ?? _defaultAppVersionProvider;

  bool get isEnabled => _enabled;
  int get intervalMinutes => defaultIntervalMinutes;
  DateTime? get lastSuccessAt => _lastSuccessAt;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isFlushingQueue => _isFlushingQueue;
  int get pendingUploadCount => _queue.length;

  Future<void> initialize({
    required String? Function() deviceKey6Provider,
  }) async {
    _deviceKey6Provider = deviceKey6Provider;
    final prefs = await _prefsProvider();
    _enabled = prefs.getBool(_enabledKey) ?? defaultEnabled;
    if (prefs.containsKey(_legacyIntervalKey)) {
      await prefs.remove(_legacyIntervalKey);
    }
    final queueJson = prefs.getString(_queueKey);
    if (queueJson != null && queueJson.isNotEmpty) {
      final decoded = jsonDecode(queueJson);
      if (decoded is List) {
        _queue
          ..clear()
          ..addAll(
            decoded.whereType<Map<String, dynamic>>().map(
              TrafficStatsQueuedReport.fromJson,
            ),
          );
      }
    }
    final lastSuccessAt = prefs.getString(_lastSuccessAtKey);
    if (lastSuccessAt != null && lastSuccessAt.isNotEmpty) {
      _lastSuccessAt = DateTime.tryParse(lastSuccessAt)?.toUtc();
    }
    final lastError = prefs.getString(_lastErrorKey);
    if (lastError != null && lastError.isNotEmpty) {
      _lastError = lastError;
    }
    try {
      _appVersion = await _appVersionProvider();
    } catch (_) {
      _appVersion = 'unknown';
    }
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      unawaited(flushPendingUploads());
    });
    _isInitialized = true;
    notifyListeners();
    await flushPendingUploads();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;
    _lastError = null;
    if (!enabled) {
      _openWindows.clear();
    }
    await _saveState();
    notifyListeners();
    if (enabled) {
      unawaited(flushPendingUploads());
    }
  }

  Future<void> processLogs(List<BlePacketLog> logs) async {
    if (!_enabled || logs.isEmpty) {
      if (_enabled) {
        await flushPendingUploads();
      }
      return;
    }

    var changed = false;
    for (final log in logs) {
      if (!LiveTrafficSummary.isRxDataLog(log)) {
        continue;
      }
      final counts = _openWindows.putIfAbsent(
        _windowStartFor(log.timestamp).millisecondsSinceEpoch,
        TrafficStatsCounts.empty,
      );
      final route = LogRxRouteDecoder.decode(log.rawData);
      if (route == null) {
        counts.increment(TrafficStatsCounts.decodeFailKey);
      } else {
        counts.incrementPacketType(route.payloadType);
      }
      counts.increment(_pathModeKeyFor(log.rawData, route));
      changed = true;
    }

    if (!changed) {
      await flushPendingUploads();
      return;
    }

    final queuedReports = _queueClosedWindows();
    if (queuedReports > 0) {
      await _saveState();
    }
    notifyListeners();
    await flushPendingUploads();
  }

  Future<void> flushPendingUploads() async {
    if (!_enabled || _queue.isEmpty || _isFlushingQueue) {
      return;
    }
    final deviceKey6 = _deviceKey6Provider?.call();
    if (deviceKey6 == null || deviceKey6.isEmpty) {
      return;
    }

    _isFlushingQueue = true;
    notifyListeners();
    try {
      while (_queue.isNotEmpty && _enabled) {
        final report = _queue.first;
        final response = await _client.post(
          ingestUri,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
          body: jsonEncode(report.toJson()),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          _lastError = 'Upload failed (${response.statusCode})';
          await _saveState();
          notifyListeners();
          return;
        }

        _queue.removeAt(0);
        _lastError = null;
        _lastSuccessAt = _now().toUtc();
        await _saveState();
        notifyListeners();
      }
    } catch (error) {
      _lastError = 'Upload failed: $error';
      await _saveState();
      notifyListeners();
    } finally {
      _isFlushingQueue = false;
      notifyListeners();
    }
  }

  int _queueClosedWindows() {
    final deviceKey6 = _deviceKey6Provider?.call();
    if (deviceKey6 == null || deviceKey6.isEmpty) {
      return 0;
    }

    final now = _now().toUtc();
    final closable = _openWindows.keys
        .where((windowStartMs) {
          final windowStart = DateTime.fromMillisecondsSinceEpoch(
            windowStartMs,
            isUtc: true,
          );
          final windowEnd = windowStart.add(
            Duration(minutes: defaultIntervalMinutes),
          );
          return !windowEnd.isAfter(now);
        })
        .toList()
      ..sort();

    for (final windowStartMs in closable) {
      final windowStart = DateTime.fromMillisecondsSinceEpoch(
        windowStartMs,
        isUtc: true,
      );
      final counts = _openWindows.remove(windowStartMs);
      if (counts == null || counts.isEmpty) {
        continue;
      }
      final reportId = '$deviceKey6:${windowStart.toIso8601String()}';
      final existingIndex = _queue.indexWhere(
        (report) => report.reportId == reportId,
      );
      if (existingIndex != -1) {
        _queue[existingIndex].counts.mergeFrom(counts);
        continue;
      }
      _queue.add(
        TrafficStatsQueuedReport(
          reportId: reportId,
          deviceKey6: deviceKey6,
          windowStart: windowStart,
          windowEnd: windowStart.add(
            Duration(minutes: defaultIntervalMinutes),
          ),
          appVersion: _appVersion ?? 'unknown',
          counts: counts,
        ),
      );
    }
    return closable.length;
  }

  DateTime _windowStartFor(DateTime timestamp) {
    final utc = timestamp.toUtc();
    final alignedMinute =
        utc.minute - (utc.minute % defaultIntervalMinutes);
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      alignedMinute,
    );
  }

  String _pathModeKeyFor(Uint8List rawData, DecodedLogRxRoute? route) {
    if (route != null) {
      if (route.pathBytes.isEmpty) {
        return 'path_mode_none';
      }
      switch (route.hashSize) {
        case 1:
          return 'path_mode_1b';
        case 2:
          return 'path_mode_2b';
        case 3:
          return 'path_mode_3b';
      }
      return 'path_mode_unknown';
    }
    return _pathModeKeyFromRawData(rawData);
  }

  String _pathModeKeyFromRawData(Uint8List rawData) {
    if (rawData.length < 5 ||
        rawData.first != LiveTrafficSummary.logRxDataResponseCode) {
      return 'path_mode_unknown';
    }

    final rawPacketData = rawData.sublist(3);
    if (rawPacketData.length < 2) {
      return 'path_mode_unknown';
    }

    final header = rawPacketData[0];
    final routeType = header & 0x03;
    var index = 1;
    if (routeType == 0x00 || routeType == 0x03) {
      if (rawPacketData.length < index + 5) {
        return 'path_mode_unknown';
      }
      index += 4;
    }

    if (rawPacketData.length <= index) {
      return 'path_mode_unknown';
    }

    final pathDescriptor = rawPacketData[index];
    final pathByteLen = LogRxRouteDecoder.descriptorByteLength(pathDescriptor);
    if (pathByteLen == null) {
      return 'path_mode_unknown';
    }
    if (rawPacketData.length < index + 1 + pathByteLen) {
      return 'path_mode_unknown';
    }
    if (pathByteLen == 0) {
      return 'path_mode_none';
    }

    final hashSize = LogRxRouteDecoder.descriptorHashSize(pathDescriptor);
    switch (hashSize) {
      case 1:
        return 'path_mode_1b';
      case 2:
        return 'path_mode_2b';
      case 3:
        return 'path_mode_3b';
    }
    return 'path_mode_unknown';
  }

  Future<void> _saveState() async {
    final prefs = await _prefsProvider();
    await prefs.setBool(_enabledKey, _enabled);
    await prefs.remove(_legacyIntervalKey);
    await prefs.setString(
      _queueKey,
      jsonEncode(_queue.map((report) => report.toJson()).toList()),
    );
    if (_lastSuccessAt == null) {
      await prefs.remove(_lastSuccessAtKey);
    } else {
      await prefs.setString(
        _lastSuccessAtKey,
        _lastSuccessAt!.toIso8601String(),
      );
    }
    if (_lastError == null || _lastError!.isEmpty) {
      await prefs.remove(_lastErrorKey);
    } else {
      await prefs.setString(_lastErrorKey, _lastError!);
    }
  }

  static Future<String> _defaultAppVersionProvider() async {
    final info = await PackageInfo.fromPlatform();
    if (info.buildNumber.isEmpty || info.buildNumber == '0') {
      return info.version;
    }
    return '${info.version}+${info.buildNumber}';
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    if (_ownsClient) {
      _client.close();
    }
    super.dispose();
  }
}
