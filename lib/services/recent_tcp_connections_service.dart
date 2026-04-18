import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentTcpConnection {
  final String name;
  final String host;
  final int port;
  final DateTime lastUsedAt;

  const RecentTcpConnection({
    required this.name,
    required this.host,
    required this.port,
    required this.lastUsedAt,
  });

  Map<String, Object> toJson() => <String, Object>{
    'name': name,
    'host': host,
    'port': port,
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory RecentTcpConnection.fromJson(Map<String, dynamic> json) {
    return RecentTcpConnection(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : ((json['host'] as String?) ?? '').trim(),
      host: ((json['host'] as String?) ?? '').trim(),
      port: (json['port'] as num?)?.toInt() ?? 0,
      lastUsedAt:
          DateTime.tryParse((json['lastUsedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RecentTcpConnectionsService {
  static const String _prefsKey = 'recent_tcp_connections_v1';
  static const int _maxEntries = 5;

  static Future<List<RecentTcpConnection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEntries = prefs.getStringList(_prefsKey) ?? const <String>[];

    final connections = <RecentTcpConnection>[];
    for (final entry in storedEntries) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final connection = RecentTcpConnection.fromJson(decoded);
        if (connection.host.isEmpty || connection.port <= 0) {
          continue;
        }
        connections.add(connection);
      } catch (_) {
        continue;
      }
    }

    connections.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return connections.take(_maxEntries).toList(growable: false);
  }

  static Future<List<RecentTcpConnection>> remember({
    required String name,
    required String host,
    required int port,
  }) async {
    final trimmedHost = host.trim();
    if (trimmedHost.isEmpty || port <= 0) {
      return load();
    }

    final normalizedName = name.trim().isNotEmpty ? name.trim() : trimmedHost;
    final existing = await load();
    final updated = <RecentTcpConnection>[
      RecentTcpConnection(
        name: normalizedName,
        host: trimmedHost,
        port: port,
        lastUsedAt: DateTime.now(),
      ),
      ...existing.where(
        (connection) =>
            connection.host != trimmedHost || connection.port != port,
      ),
    ].take(_maxEntries).toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      updated
          .map((connection) => jsonEncode(connection.toJson()))
          .toList(growable: false),
    );
    return updated;
  }
}
