import 'dart:convert';
import 'package:http/http.dart' as http;

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
  static const Duration _cacheTtl = Duration(minutes: 2);
  static const Duration traceCacheTtl = Duration(minutes: 10);
  static const Duration traceTimeout = Duration(seconds: 30);
  static List<MeshMapNode>? _cachedNodes;
  static DateTime? _cachedAt;

  static Future<List<MeshMapNode>> fetchNodes({
    bool forceRefresh = false,
    Duration cacheTtl = _cacheTtl,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedNodes != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < cacheTtl) {
      return _cachedNodes!;
    }

    final response = await http
        .get(Uri.parse(_nodesEndpoint))
        .timeout(traceTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Map nodes API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final nodesRaw = decoded['nodes'] as List<dynamic>? ?? const [];

    final nodes = nodesRaw
        .whereType<Map<String, dynamic>>()
        .map(MeshMapNode.fromJson)
        .where(
          (n) => n.publicKey.isNotEmpty && n.latitude != 0 && n.longitude != 0,
        )
        .toList();

    _cachedNodes = nodes;
    _cachedAt = now;
    return nodes;
  }
}
