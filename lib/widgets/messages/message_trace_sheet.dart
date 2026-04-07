// ignore_for_file: use_null_aware_elements

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ble_packet_log.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../services/mesh_map_nodes_service.dart';
import '../../services/route_hash_preferences.dart';
import '../../utils/log_rx_route_decoder.dart';
import '../../utils/trace_node_resolver.dart';

class MessageTraceSheet extends StatefulWidget {
  final Message? message;
  final List<int>? packetPathOverride;
  final String? descriptionOverride;
  final String? noRelayMatchTextOverride;

  const MessageTraceSheet({super.key, required this.message})
    : assert(message != null),
      packetPathOverride = null,
      descriptionOverride = null,
      noRelayMatchTextOverride = null;

  const MessageTraceSheet.packetPath({
    super.key,
    required List<int> packetPath,
    this.descriptionOverride,
    this.noRelayMatchTextOverride,
  }) : message = null,
       packetPathOverride = packetPath;

  @override
  State<MessageTraceSheet> createState() => _MessageTraceSheetState();
}

class _MessageTraceSheetState extends State<MessageTraceSheet> {
  late final Future<_TraceResult> _future;
  _TraceResult? _traceOverride;

  @override
  void initState() {
    super.initState();
    _future = _loadTrace();
  }

  Future<_TraceResult> _loadTrace() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final preferredHashSize = await RouteHashPreferences.getHashSize();
    List<int>? packetPath = widget.packetPathOverride;
    String? senderPrefix;
    String? recipientPrefix;

    if (widget.message case final message?) {
      final storedPath = messagesProvider
          .getMessageReceptionDetails(message.id)
          ?.pathBytes;
      packetPath = (storedPath != null && storedPath.isNotEmpty)
          ? storedPath
          : _extractPathFromPacketLogs(
              logs: connectionProvider.bleService.packetLogs,
              message: message,
            );

      senderPrefix = _toPrefixHex(message.senderPublicKeyPrefix);
      recipientPrefix = message.recipientPublicKey != null
          ? _toPrefixHex(message.recipientPublicKey)
          : _toPrefixHex(connectionProvider.deviceInfo.publicKey);
    }

    final localNodes = _localNodesFromContacts(contactsProvider);
    final localPublicKeys = localNodes.map((node) => node.publicKey).toSet();
    var trace = _buildTraceResult(
      nodes: localNodes,
      localPublicKeys: localPublicKeys,
      packetPath: packetPath,
      preferredHashSize: preferredHashSize,
      senderPrefix: senderPrefix,
      recipientPrefix: recipientPrefix,
    );
    if (_isCompleteTrace(
      trace,
      expectedRelayCount: widget.message == null
          ? 0
          : math.max(0, widget.message!.pathLen),
    )) {
      return trace;
    }

    unawaited(
      MeshMapNodesService.syncInBackgroundIfStale(
        cacheTtl: MeshMapNodesService.traceCacheTtl,
      ),
    );

    final remoteNodes = await MeshMapNodesService.loadCachedNodes(
      cacheTtl: MeshMapNodesService.traceCacheTtl,
    );
    trace = _buildTraceResult(
      nodes: _mergeNodes(localNodes, remoteNodes),
      localPublicKeys: localPublicKeys,
      packetPath: packetPath,
      preferredHashSize: preferredHashSize,
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
                  child: Text(AppLocalizations.of(context)!.failedToLoadTrace(snapshot.error.toString())),
                ),
              ),
            );
          }

          final trace = _traceOverride ?? snapshot.data!;
          final routeEntries = _displayRouteEntries(trace);
          final concretePathNodes = routeEntries
              .where((entry) => entry.resolved.node != null)
              .map((entry) => entry.resolved.node!)
              .where((node) => node.hasValidCoordinates)
              .toList();
          final mapPoints = concretePathNodes
              .map((n) => LatLng(n.latitude, n.longitude))
              .toList();
          final hasMapPath = mapPoints.length >= 2;
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
                    widget.descriptionOverride ??
                        (trace.mode == TraceMode.packetPath
                            ? 'Relay path from packet path bytes'
                            : 'Relay path inferred from hop count (${widget.message!.pathLen})'),
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
                                                        Colors.blue,
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
                          'Relay path',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (routeEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            widget.noRelayMatchTextOverride ??
                                'No named nodes could be matched for this trace.',
                          ),
                        ),
                      ...routeEntries.asMap().entries.map(
                        (entry) => ListTile(
                          onTap: entry.value.resolved.canCycle
                              ? () => setState(() {
                                  final baseTrace =
                                      _traceOverride ?? snapshot.data!;
                                  _traceOverride = baseTrace.cycleEntry(
                                    entry.value.target,
                                  );
                                })
                              : null,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue,
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
                            'Path node${entry.value.keyLabel == null ? '' : ' • ${entry.value.keyLabel}'}${entry.value.matchSummary == null ? '' : ' • ${entry.value.matchSummary}'}${entry.value.resolved.cycleSummary == null ? '' : ' • ${entry.value.resolved.cycleSummary}'}',
                          ),
                          trailing: entry.value.resolved.canCycle
                              ? const Icon(Icons.sync_alt)
                              : null,
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

  List<_RouteDisplayEntry> _displayRouteEntries(_TraceResult trace) {
    if (trace.mode == TraceMode.packetPath) {
      return trace.matchedPathNodes.asMap().entries.map((entry) {
        final hashHex = trace.pathHashes[entry.key].toUpperCase();
        return _RouteDisplayEntry(
          resolved: entry.value,
          label: entry.value.node?.name ?? 'Unknown',
          keyLabel: entry.value.node != null
              ? _prefixKeyLabel(entry.value.node!.publicKey)
              : hashHex,
          matchSummary: entry.value.matchSummary,
          target: _RouteEntryTarget.pathNode(entry.key),
        );
      }).toList();
    }

    return trace.matchedPathNodes
        .asMap()
        .entries
        .where((entry) => entry.value.node != null)
        .map(
          (entry) => _RouteDisplayEntry.fromResolved(
            entry.value,
            target: _RouteEntryTarget.pathNode(entry.key),
          ),
        )
        .toList();
  }

  String _prefixKeyLabel(String publicKey) =>
      publicKey.substring(0, math.min(12, publicKey.length));

  String? _toPrefixHex(List<int>? key) {
    if (key == null || key.isEmpty) return null;
    final take = key.length < 6 ? key.length : 6;
    return key
        .take(take)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();
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
        .where((node) => node.hasValidCoordinates)
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
    required Set<String> localPublicKeys,
    required List<int>? packetPath,
    required int preferredHashSize,
    required String? senderPrefix,
    required String? recipientPrefix,
  }) {
    final senderNode = TraceNodeResolver.resolveBest(
      nodes: nodes,
      localPublicKeys: localPublicKeys,
      prefixHex: senderPrefix,
    );
    final recipientNode = TraceNodeResolver.resolveBest(
      nodes: nodes,
      localPublicKeys: localPublicKeys,
      prefixHex: recipientPrefix,
    );
    final senderLatLng = senderNode.node == null
        ? null
        : LatLng(senderNode.node!.latitude, senderNode.node!.longitude);
    final recipientLatLng = recipientNode.node == null
        ? null
        : LatLng(recipientNode.node!.latitude, recipientNode.node!.longitude);

    if (packetPath != null && packetPath.isNotEmpty) {
      final hashSize = LogRxRouteDecoder.inferHashSize(
        packetPath,
        preferredHashSize: preferredHashSize,
      );
      final hopHashes = LogRxRouteDecoder.splitHopHashes(
        packetPath,
        hashSize: hashSize,
      );
      final matched = _matchNodesFromPathHashes(
        nodes: nodes,
        localPublicKeys: localPublicKeys,
        pathHashes: hopHashes,
        senderPrefix: senderPrefix,
        recipientPrefix: recipientPrefix,
        senderLatLng: senderLatLng,
        recipientLatLng: recipientLatLng,
      );
      final alignedMatched = TraceNodeResolver.alignPathSelections(
        nodes: matched,
        startNode: senderNode.node,
        endNode: recipientNode.node,
      );
      return _TraceResult(
        mode: TraceMode.packetPath,
        sender: senderNode,
        recipient: recipientNode,
        pathHashes: hopHashes,
        matchedPathNodes: alignedMatched,
      );
    }

    final inferred = _inferRelaysFromHopCount(
      nodes: nodes,
      sender: senderNode.node,
      recipient: recipientNode.node,
      relayCount: math.max(0, widget.message!.pathLen),
    );
    final matchedPathNodes = <ResolvedTraceNode>[
      if (senderNode.node != null) senderNode,
      ...inferred.map(
        (node) => ResolvedTraceNode(
          candidates: [node],
          matchCount: 1,
          usedOnlineFallback: false,
        ),
      ),
      if (recipientNode.node != null) recipientNode,
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
    if (trace.sender.node == null || trace.recipient.node == null) {
      return false;
    }

    if (trace.mode == TraceMode.packetPath) {
      return trace.matchedPathNodes.length == trace.pathHashes.length &&
          trace.matchedPathNodes.every((node) => node.node != null);
    }

    final concreteCount = trace.matchedPathNodes
        .map((entry) => entry.node)
        .whereType<MeshMapNode>()
        .length;
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
      final decoded = LogRxRouteDecoder.decode(log.rawData);
      if (decoded == null) continue;
      if (decoded.payloadType != expectedPayloadType) continue;
      if (decoded.hopCount != message.pathLen) continue;

      final deltaMs =
          (log.timestamp.difference(message.receivedAt).inMilliseconds).abs();
      if (deltaMs < bestDeltaMs) {
        bestDeltaMs = deltaMs;
        bestLog = log;
      }
    }

    if (bestLog == null || bestDeltaMs > 30000) return null;
    final decoded = LogRxRouteDecoder.decode(bestLog.rawData);
    if (decoded == null || decoded.pathBytes.isEmpty) {
      return null;
    }
    return decoded.pathBytes;
  }

  List<ResolvedTraceNode> _matchNodesFromPathHashes({
    required List<MeshMapNode> nodes,
    required Set<String> localPublicKeys,
    required List<String> pathHashes,
    required String? senderPrefix,
    required String? recipientPrefix,
    required LatLng? senderLatLng,
    required LatLng? recipientLatLng,
  }) {
    final result = <ResolvedTraceNode>[];
    for (var i = 0; i < pathHashes.length; i++) {
      final hashHex = pathHashes[i].toLowerCase();
      result.add(
        TraceNodeResolver.resolveBest(
          nodes: nodes,
          localPublicKeys: localPublicKeys,
          prefixHex: hashHex,
          preferredPrefix: i == 0
              ? senderPrefix
              : (i == pathHashes.length - 1 ? recipientPrefix : null),
          referenceA: senderLatLng,
          referenceB: recipientLatLng,
        ),
      );
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
  final ResolvedTraceNode sender;
  final ResolvedTraceNode recipient;
  final List<String> pathHashes;
  final List<ResolvedTraceNode> matchedPathNodes;

  const _TraceResult({
    required this.mode,
    required this.sender,
    required this.recipient,
    required this.pathHashes,
    required this.matchedPathNodes,
  });

  _TraceResult cycleEntry(_RouteEntryTarget target) {
    switch (target.kind) {
      case _RouteEntryKind.pathNode:
        final updated = matchedPathNodes.toList();
        updated[target.index] = updated[target.index].cycle();
        return _TraceResult(
          mode: mode,
          sender: sender,
          recipient: recipient,
          pathHashes: pathHashes,
          matchedPathNodes: updated,
        );
    }
  }
}

class _RouteDisplayEntry {
  final ResolvedTraceNode resolved;
  final String label;
  final String? keyLabel;
  final String? matchSummary;
  final _RouteEntryTarget target;

  const _RouteDisplayEntry({
    required this.resolved,
    required this.label,
    required this.keyLabel,
    required this.matchSummary,
    required this.target,
  });

  MeshMapNode? get node => resolved.node;

  factory _RouteDisplayEntry.fromResolved(
    ResolvedTraceNode resolved, {
    required _RouteEntryTarget target,
  }) {
    final node = resolved.node!;
    return _RouteDisplayEntry(
      resolved: resolved,
      label: node.name,
      keyLabel: node.publicKey.substring(
        0,
        math.min(12, node.publicKey.length),
      ),
      matchSummary: resolved.matchSummary,
      target: target,
    );
  }
}

enum _RouteEntryKind { pathNode }

class _RouteEntryTarget {
  final _RouteEntryKind kind;
  final int index;

  const _RouteEntryTarget._(this.kind, [this.index = 0]);

  const _RouteEntryTarget.pathNode(int index)
    : this._(_RouteEntryKind.pathNode, index);
}
