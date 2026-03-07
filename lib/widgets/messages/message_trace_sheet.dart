// ignore_for_file: use_null_aware_elements

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/ble_packet_log.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../services/mesh_map_nodes_service.dart';

class MessageTraceSheet extends StatefulWidget {
  final Message message;

  const MessageTraceSheet({super.key, required this.message});

  @override
  State<MessageTraceSheet> createState() => _MessageTraceSheetState();
}

class _MessageTraceSheetState extends State<MessageTraceSheet> {
  late final Future<_TraceResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTrace();
  }

  Future<_TraceResult> _loadTrace() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final packetPath = _extractPathFromPacketLogs(
      logs: connectionProvider.bleService.packetLogs,
      message: widget.message,
    );

    final senderPrefix = _toPrefixHex(widget.message.senderPublicKeyPrefix);
    final recipientPrefix = widget.message.recipientPublicKey != null
        ? _toPrefixHex(widget.message.recipientPublicKey)
        : _toPrefixHex(connectionProvider.deviceInfo.publicKey);

    final localNodes = _localNodesFromContacts(contactsProvider);
    var trace = _buildTraceResult(
      nodes: localNodes,
      packetPath: packetPath,
      senderPrefix: senderPrefix,
      recipientPrefix: recipientPrefix,
    );
    if (_isCompleteTrace(trace, expectedRelayCount: math.max(0, widget.message.pathLen))) {
      return trace;
    }

    final remoteNodes = await MeshMapNodesService.fetchNodes(
      cacheTtl: MeshMapNodesService.traceCacheTtl,
    );
    trace = _buildTraceResult(
      nodes: _mergeNodes(localNodes, remoteNodes),
      packetPath: packetPath,
      senderPrefix: senderPrefix,
      recipientPrefix: recipientPrefix,
    );
    return trace;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_TraceResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 360,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load trace: ${snapshot.error}'),
                ),
              ),
            );
          }

          final trace = snapshot.data!;
          final routeEntries = _displayRouteEntries(trace);
          final concretePathNodes = routeEntries
              .where((entry) => entry.node != null)
              .map((entry) => entry.node!)
              .toList();
          final mapPoints = concretePathNodes
              .map((n) => LatLng(n.latitude, n.longitude))
              .toList();
          final hasMapPath = mapPoints.length >= 2;
          final relayNodes = _relayNodes(trace);

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Trace',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    trace.mode == TraceMode.packetPath
                        ? 'Route from packet path bytes'
                        : 'Route inferred from hop count (${widget.message.pathLen})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 240,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: hasMapPath
                                  ? flutter_map.FlutterMap(
                                      options: flutter_map.MapOptions(
                                        initialCameraFit:
                                            flutter_map.CameraFit.bounds(
                                              bounds:
                                                  flutter_map
                                                      .LatLngBounds.fromPoints(
                                                    mapPoints,
                                                  ),
                                              padding: const EdgeInsets.all(28),
                                            ),
                                      ),
                                      children: [
                                        flutter_map.TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.meshcore.sar',
                                        ),
                                        flutter_map.PolylineLayer(
                                          polylines: [
                                            flutter_map.Polyline(
                                              points: mapPoints,
                                              strokeWidth: 4,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                        flutter_map.MarkerLayer(
                                          markers: concretePathNodes
                                              .asMap()
                                              .entries
                                              .map(
                                                (entry) => flutter_map.Marker(
                                                  point: LatLng(
                                                    entry.value.latitude,
                                                    entry.value.longitude,
                                                  ),
                                                  width: 34,
                                                  height: 34,
                                                  child: CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        entry.key == 0
                                                        ? Colors.green
                                                        : (entry.key ==
                                                                  concretePathNodes
                                                                          .length -
                                                                      1
                                                              ? Colors.red
                                                              : Colors.blue),
                                                    child: Text(
                                                      '${entry.key + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    )
                                  : const Center(
                                      child: Text(
                                        'Not enough geolocated nodes to draw path',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Route',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (routeEntries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'No named nodes could be matched for this trace.',
                          ),
                        ),
                      ...routeEntries.asMap().entries.map(
                        (entry) => ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: entry.key == 0
                                ? Colors.green
                                : (entry.key == routeEntries.length - 1
                                      ? Colors.red
                                      : Colors.blue),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          title: Text(entry.value.label),
                          subtitle: Text(
                            '${_routeRoleLabel(entry.key, routeEntries.length)}${entry.value.keyLabel == null ? '' : ' • ${entry.value.keyLabel}'}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Relays (${relayNodes.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (relayNodes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'No relay nodes could be matched for this message.',
                          ),
                        ),
                      ...relayNodes.map(
                        (node) => ListTile(
                          leading: const Icon(Icons.router),
                          title: Text(node.name),
                          subtitle: Text(
                            '${node.publicKey.substring(0, math.min(12, node.publicKey.length))} • '
                            '${node.latitude.toStringAsFixed(5)}, ${node.longitude.toStringAsFixed(5)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<MeshMapNode> _relayNodes(_TraceResult trace) {
    final concrete = trace.matchedPathNodes.whereType<MeshMapNode>().toList();
    if (concrete.isEmpty) return const [];

    if (trace.mode == TraceMode.packetPath) {
      if (concrete.length <= 1) return const [];
      return concrete.sublist(1);
    }

    if (concrete.length <= 2) return const [];
    return concrete.sublist(1, concrete.length - 1);
  }

  List<_RouteDisplayEntry> _displayRouteEntries(_TraceResult trace) {
    final pathNodes = trace.matchedPathNodes.whereType<MeshMapNode>().toList();
    if (pathNodes.isEmpty) {
      return [
        if (trace.sender != null) _RouteDisplayEntry.fromNode(trace.sender!),
        if (trace.recipient != null &&
            trace.recipient!.publicKey != trace.sender?.publicKey)
          _RouteDisplayEntry.fromNode(trace.recipient!),
      ];
    }

    if (trace.mode == TraceMode.packetPath) {
      final entries = trace.matchedPathNodes.asMap().entries.map((entry) {
        final hashHex = trace.pathHashes[entry.key]
            .toRadixString(16)
            .padLeft(2, '0');
        return _RouteDisplayEntry(
          node: entry.value,
          label: entry.value?.name ?? 'Unknown',
          keyLabel: entry.value != null
              ? _prefixKeyLabel(entry.value!.publicKey)
              : hashHex,
        );
      }).toList();
      final lastKey = pathNodes.last.publicKey;
      return [
        ...entries,
        if (trace.recipient != null && trace.recipient!.publicKey != lastKey)
          _RouteDisplayEntry.fromNode(trace.recipient!),
      ];
    }

    final firstKey = pathNodes.first.publicKey;
    final lastKey = pathNodes.last.publicKey;
    return [
      if (trace.sender != null && trace.sender!.publicKey != firstKey)
        _RouteDisplayEntry.fromNode(trace.sender!),
      ...pathNodes.map(_RouteDisplayEntry.fromNode),
      if (trace.recipient != null && trace.recipient!.publicKey != lastKey)
        _RouteDisplayEntry.fromNode(trace.recipient!),
    ];
  }

  String _prefixKeyLabel(String publicKey) =>
      publicKey.substring(0, math.min(12, publicKey.length));

  String _routeRoleLabel(int index, int total) {
    if (index == 0) return 'Sender';
    if (index == total - 1) return 'Recipient';
    return 'Relay';
  }

  String? _toPrefixHex(List<int>? key) {
    if (key == null || key.isEmpty) return null;
    final take = key.length < 6 ? key.length : 6;
    return key
        .take(take)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();
  }

  MeshMapNode? _bestNodeForPrefix(List<MeshMapNode> nodes, String? prefixHex) {
    if (prefixHex == null || prefixHex.isEmpty) return null;
    final matches =
        nodes.where((n) => n.publicKey.startsWith(prefixHex)).toList()
          ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return matches.isEmpty ? null : matches.first;
  }

  List<MeshMapNode> _localNodesFromContacts(ContactsProvider contactsProvider) {
    return contactsProvider.contactsWithLocation
        .map((contact) {
          final location = contact.displayLocation;
          if (location == null) return null;
          return MeshMapNode(
            type: contact.type.index,
            name: contact.displayName,
            publicKey: contact.publicKeyHex.toLowerCase(),
            latitude: location.latitude,
            longitude: location.longitude,
            updatedAtMs: contact.lastAdvert * 1000,
          );
        })
        .whereType<MeshMapNode>()
        .toList();
  }

  List<MeshMapNode> _mergeNodes(
    List<MeshMapNode> preferred,
    List<MeshMapNode> fallback,
  ) {
    final merged = <String, MeshMapNode>{};
    for (final node in fallback) {
      merged[node.publicKey] = node;
    }
    for (final node in preferred) {
      merged[node.publicKey] = node;
    }
    return merged.values.toList();
  }

  _TraceResult _buildTraceResult({
    required List<MeshMapNode> nodes,
    required List<int>? packetPath,
    required String? senderPrefix,
    required String? recipientPrefix,
  }) {
    final senderNode = _bestNodeForPrefix(nodes, senderPrefix);
    final recipientNode = _bestNodeForPrefix(nodes, recipientPrefix);

    if (packetPath != null && packetPath.isNotEmpty) {
      final matched = _matchNodesFromPathHashes(
        nodes: nodes,
        pathHashes: packetPath,
        senderPrefix: senderPrefix,
        recipientPrefix: recipientPrefix,
      );
      return _TraceResult(
        mode: TraceMode.packetPath,
        sender: senderNode,
        recipient: recipientNode,
        pathHashes: packetPath,
        matchedPathNodes: matched,
      );
    }

    final inferred = _inferRelaysFromHopCount(
      nodes: nodes,
      sender: senderNode,
      recipient: recipientNode,
      relayCount: math.max(0, widget.message.pathLen),
    );
    final matchedPathNodes = <MeshMapNode?>[
      if (senderNode != null) senderNode,
      ...inferred,
      if (recipientNode != null) recipientNode,
    ];

    return _TraceResult(
      mode: TraceMode.hopCountInference,
      sender: senderNode,
      recipient: recipientNode,
      pathHashes: const [],
      matchedPathNodes: matchedPathNodes,
    );
  }

  bool _isCompleteTrace(_TraceResult trace, {required int expectedRelayCount}) {
    if (trace.sender == null || trace.recipient == null) {
      return false;
    }

    if (trace.mode == TraceMode.packetPath) {
      return trace.matchedPathNodes.length == trace.pathHashes.length &&
          trace.matchedPathNodes.every((node) => node != null);
    }

    final concreteCount = trace.matchedPathNodes.whereType<MeshMapNode>().length;
    return concreteCount >= expectedRelayCount + 2;
  }

  List<int>? _extractPathFromPacketLogs({
    required List<BlePacketLog> logs,
    required Message message,
  }) {
    if (message.pathLen <= 0 || message.pathLen >= 255) return null;
    final expectedPayloadType = message.messageType == MessageType.channel
        ? 0x05
        : 0x02;
    BlePacketLog? bestLog;
    var bestDeltaMs = 999999999;

    for (final log in logs) {
      if (log.responseCode != 0x88) continue; // pushLogRxData
      if (log.rawData.length < 6) continue;
      final raw = log.rawData;
      final header = raw[3];
      final payloadType = (header >> 2) & 0x0F;
      final pathLen = raw[4];
      if (payloadType != expectedPayloadType) continue;
      if (pathLen != message.pathLen) continue;
      if (raw.length < 5 + pathLen) continue;

      final deltaMs =
          (log.timestamp.difference(message.receivedAt).inMilliseconds).abs();
      if (deltaMs < bestDeltaMs) {
        bestDeltaMs = deltaMs;
        bestLog = log;
      }
    }

    if (bestLog == null || bestDeltaMs > 30000) return null;
    final raw = bestLog.rawData;
    final pathLen = raw[4];
    return raw.sublist(5, 5 + pathLen);
  }

  List<MeshMapNode?> _matchNodesFromPathHashes({
    required List<MeshMapNode> nodes,
    required List<int> pathHashes,
    required String? senderPrefix,
    required String? recipientPrefix,
  }) {
    final result = <MeshMapNode?>[];
    for (var i = 0; i < pathHashes.length; i++) {
      final hashHex = pathHashes[i].toRadixString(16).padLeft(2, '0');
      final candidates = nodes
          .where((n) => n.publicKey.startsWith(hashHex))
          .toList();
      if (candidates.isEmpty) {
        result.add(null);
        continue;
      }

      List<MeshMapNode> filtered = candidates;
      if (i == 0 && senderPrefix != null) {
        final senderMatches = filtered
            .where((n) => n.publicKey.startsWith(senderPrefix))
            .toList();
        if (senderMatches.isNotEmpty) filtered = senderMatches;
      }

      filtered.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      result.add(filtered.first);
    }
    return result;
  }

  List<MeshMapNode> _inferRelaysFromHopCount({
    required List<MeshMapNode> nodes,
    required MeshMapNode? sender,
    required MeshMapNode? recipient,
    required int relayCount,
  }) {
    if (relayCount <= 0 || sender == null || recipient == null) return const [];
    final candidates = nodes.where((n) {
      if (sender.publicKey == n.publicKey ||
          recipient.publicKey == n.publicKey) {
        return false;
      }
      return true;
    }).toList();

    final ranked = candidates
      ..sort((a, b) {
        final da = _distanceToSegmentMeters(
          p: LatLng(a.latitude, a.longitude),
          a: LatLng(sender.latitude, sender.longitude),
          b: LatLng(recipient.latitude, recipient.longitude),
        );
        final db = _distanceToSegmentMeters(
          p: LatLng(b.latitude, b.longitude),
          a: LatLng(sender.latitude, sender.longitude),
          b: LatLng(recipient.latitude, recipient.longitude),
        );
        return da.compareTo(db);
      });

    return ranked.take(relayCount).toList();
  }

  double _distanceToSegmentMeters({
    required LatLng p,
    required LatLng a,
    required LatLng b,
  }) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;
    final ab2 = abx * abx + aby * aby;
    if (ab2 == 0) {
      return const Distance().as(LengthUnit.Meter, a, p);
    }
    var t = (apx * abx + apy * aby) / ab2;
    t = t.clamp(0.0, 1.0);
    final closest = LatLng(ay + aby * t, ax + abx * t);
    return const Distance().as(LengthUnit.Meter, closest, p);
  }
}

enum TraceMode { packetPath, hopCountInference }

class _TraceResult {
  final TraceMode mode;
  final MeshMapNode? sender;
  final MeshMapNode? recipient;
  final List<int> pathHashes;
  final List<MeshMapNode?> matchedPathNodes;

  const _TraceResult({
    required this.mode,
    required this.sender,
    required this.recipient,
    required this.pathHashes,
    required this.matchedPathNodes,
  });
}

class _RouteDisplayEntry {
  final MeshMapNode? node;
  final String label;
  final String? keyLabel;

  const _RouteDisplayEntry({
    required this.node,
    required this.label,
    required this.keyLabel,
  });

  factory _RouteDisplayEntry.fromNode(MeshMapNode node) {
    return _RouteDisplayEntry(
      node: node,
      label: node.name,
      keyLabel: node.publicKey.substring(0, math.min(12, node.publicKey.length)),
    );
  }
}
