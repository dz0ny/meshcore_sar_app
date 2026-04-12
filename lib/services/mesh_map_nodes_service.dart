import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MeshMapNode {
  final int type;
  final String name;
  final String publicKey;
  final double latitude;
  final double longitude;
  final int updatedAtMs;

  const MeshMapNode({
    required this.type,
    required this.name,
    required this.publicKey,
    required this.latitude,
    required this.longitude,
    required this.updatedAtMs,
  });

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      latitude != 0 &&
      longitude != 0;

  factory MeshMapNode.fromJson(Map<String, dynamic> json) {
    return MeshMapNode(
      type: (json['type'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? 'Unknown',
      publicKey: ((json['public_key'] as String?) ?? '').toLowerCase(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAtMs: (json['updated_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class MeshMapNodesService {
  static const String _nodesEndpoint =
      'https://api.meshcore.nz/api/v1/map/nodes';
  static const int repeaterType = 1;
  static const Duration _cacheTtl = Duration(hours: 24);
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _cacheKey = 'mesh_map_nodes_cache_v1';
  static const String _cacheTimestampKey = 'mesh_map_nodes_cache_timestamp_v1';
  static List<MeshMapNode>? _cachedNodes;
  static DateTime? _cachedAt;
  static Future<void>? _ongoingSync;

  static Future<List<MeshMapNode>> fetchNodes({
    bool forceRefresh = false,
    Duration cacheTtl = _cacheTtl,
    bool allowNetwork = true,
    http.Client? client,
  }) async {
    final now = DateTime.now();
    final cached = await loadCachedNodes(cacheTtl: cacheTtl);
    if (!forceRefresh &&
        cached.isNotEmpty &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < cacheTtl) {
      return cached;
    }

    if (!allowNetwork) {
      return cached;
    }

    final response = await (client ?? http.Client())
        .get(Uri.parse(_nodesEndpoint))
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Map nodes API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final nodesRaw = decoded['nodes'] as List<dynamic>? ?? const [];

    final nodes = nodesRaw
        .whereType<Map<String, dynamic>>()
        .map(MeshMapNode.fromJson)
        .where((n) => n.publicKey.isNotEmpty && n.hasValidCoordinates)
        .toList();

    await _storeCache(nodes, cachedAt: now);
    return nodes;
  }

  static Future<List<MeshMapNode>> loadCachedNodes({
    Duration cacheTtl = _cacheTtl,
  }) async {
    final now = DateTime.now();
    if (_cachedNodes != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < cacheTtl) {
      return _cachedNodes!;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedAtMs = prefs.getInt(_cacheTimestampKey);
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedAtMs == null || cachedJson == null) {
      _cachedNodes = null;
      _cachedAt = null;
      return const [];
    }

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (now.difference(cachedAt) >= cacheTtl) {
      _cachedNodes = null;
      _cachedAt = cachedAt;
      return const [];
    }

    final decoded = jsonDecode(cachedJson) as List<dynamic>;
    final nodes = decoded
        .whereType<Map<String, dynamic>>()
        .map(MeshMapNode.fromJson)
        .where((n) => n.publicKey.isNotEmpty && n.hasValidCoordinates)
        .toList();
    _cachedNodes = nodes;
    _cachedAt = cachedAt;
    return nodes;
  }

  static Future<bool> hasFreshCache({Duration cacheTtl = _cacheTtl}) async {
    final nodes = await loadCachedNodes(cacheTtl: cacheTtl);
    return nodes.isNotEmpty;
  }

  static Future<void> syncInBackgroundIfStale({
    Duration cacheTtl = _cacheTtl,
    http.Client? client,
  }) async {
    final now = DateTime.now();
    if (_cachedAt != null && now.difference(_cachedAt!) < cacheTtl) {
      return;
    }

    final cached = await loadCachedNodes(cacheTtl: cacheTtl);
    if (cached.isNotEmpty && _cachedAt != null) {
      return;
    }

    if (_ongoingSync != null) {
      return _ongoingSync!;
    }

    _ongoingSync = () async {
      try {
        await fetchNodes(
          forceRefresh: true,
          cacheTtl: cacheTtl,
          allowNetwork: true,
          client: client,
        );
      } catch (_) {
        // Background refresh is best-effort only.
      } finally {
        _ongoingSync = null;
      }
    }();

    return _ongoingSync!;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    _cachedNodes = null;
    _cachedAt = null;
  }

  static Future<DateTime?> cachedAt() async {
    if (_cachedAt != null) return _cachedAt;
    final prefs = await SharedPreferences.getInstance();
    final cachedAtMs = prefs.getInt(_cacheTimestampKey);
    if (cachedAtMs == null) return null;
    _cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    return _cachedAt;
  }

  static bool isRepeater(MeshMapNode node) => node.type == repeaterType;

  static Future<void> _storeCache(
    List<MeshMapNode> nodes, {
    required DateTime cachedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(
        nodes
            .map(
              (node) => {
                'type': node.type,
                'name': node.name,
                'public_key': node.publicKey,
                'latitude': node.latitude,
                'longitude': node.longitude,
                'updated_at': node.updatedAtMs,
              },
            )
            .toList(),
      ),
    );
    await prefs.setInt(_cacheTimestampKey, cachedAt.millisecondsSinceEpoch);
    _cachedNodes = nodes;
    _cachedAt = cachedAt;
  }
}
