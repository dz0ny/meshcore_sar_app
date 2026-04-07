import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../services/mesh_map_nodes_service.dart';
import '../../utils/trace_node_resolver.dart';

class ContactTraceSheet extends StatefulWidget {
  final Contact contact;

  const ContactTraceSheet({super.key, required this.contact});

  @override
  State<ContactTraceSheet> createState() => _ContactTraceSheetState();
}

class _ContactTraceSheetState extends State<ContactTraceSheet> {
  late final Future<_ContactTraceResult> _future;
  _ContactTraceResult? _traceOverride;

  @override
  void initState() {
    super.initState();
    _future = _loadTrace();
  }

  Future<_ContactTraceResult> _loadTrace() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final localNodes = _localNodesFromContacts(
      contactsProvider,
      connectionProvider: connectionProvider,
    );
    final localPublicKeys = localNodes.map((node) => node.publicKey).toSet();

    var trace = _buildTraceResult(
      nodes: localNodes,
      localPublicKeys: localPublicKeys,
      selfPublicKey: connectionProvider.deviceInfo.publicKey,
    );
    if (_isCompleteTrace(trace)) {
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
      selfPublicKey: connectionProvider.deviceInfo.publicKey,
    );
    return trace;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_ContactTraceResult>(
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
          final concreteNodes = routeEntries
              .where((entry) => entry.resolved.node != null)
              .map((entry) => entry.resolved.node!)
              .where((node) => node.hasValidCoordinates)
              .toList();
          final mapPoints = concreteNodes
              .map((node) => LatLng(node.latitude, node.longitude))
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
                    trace.routeHashes.isEmpty
                        ? 'No relay path saved for ${widget.contact.displayName}'
                        : 'Route from saved contact path (${trace.routeHashes.length} hop${trace.routeHashes.length == 1 ? '' : 's'})',
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
                                          markers: concreteNodes
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
                      const SizedBox(height: 16),
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

  List<_RouteDisplayEntry> _displayRouteEntries(_ContactTraceResult trace) {
    return trace.matchedRelayNodes.asMap().entries.map((entry) {
      final resolved = entry.value;
      final node = resolved.node;
      final hashHex = trace.routeHashes[entry.key].toUpperCase();
      return _RouteDisplayEntry(
        resolved: resolved,
        label: node?.name ?? 'Unknown',
        keyLabel: node != null ? _prefixKeyLabel(node.publicKey) : hashHex,
        matchSummary: resolved.matchSummary,
        target: _RouteEntryTarget.relayNode(entry.key),
      );
    }).toList();
  }

  String _prefixKeyLabel(String publicKey) =>
      publicKey.substring(0, math.min(12, publicKey.length));

  bool _isCompleteTrace(_ContactTraceResult trace) {
    if (trace.sender.node == null || trace.recipient.node == null) {
      return false;
    }
    if (trace.routeHashes.isEmpty) {
      return true;
    }
    return trace.matchedRelayNodes.every((node) => node.node != null);
  }

  _ContactTraceResult _buildTraceResult({
    required List<MeshMapNode> nodes,
    required Set<String> localPublicKeys,
    required List<int>? selfPublicKey,
  }) {
    final senderNode = TraceNodeResolver.resolveBest(
      nodes: nodes,
      localPublicKeys: localPublicKeys,
      prefixHex: _toPrefixHex(selfPublicKey),
    );
    final recipientNode = TraceNodeResolver.resolveBest(
      nodes: nodes,
      localPublicKeys: localPublicKeys,
      prefixHex: _toPrefixHex(widget.contact.publicKey),
    );
    final senderLatLng = senderNode.node == null
        ? null
        : LatLng(senderNode.node!.latitude, senderNode.node!.longitude);
    final recipientLatLng = recipientNode.node == null
        ? null
        : LatLng(recipientNode.node!.latitude, recipientNode.node!.longitude);
    final routeHashes =
        widget.contact.routeHasPath && widget.contact.routeHopCount > 0
        ? widget.contact.routeCanonicalText
              .split(',')
              .where((token) => token.isNotEmpty)
              .map((token) => token.toLowerCase())
              .toList()
        : const <String>[];

    final matchedRelayNodes = routeHashes
        .map(
          (hash) => TraceNodeResolver.resolveBest(
            nodes: nodes,
            localPublicKeys: localPublicKeys,
            prefixHex: hash,
            referenceA: senderLatLng,
            referenceB: recipientLatLng,
          ),
        )
        .toList();
    final alignedRelayNodes = TraceNodeResolver.alignPathSelections(
      nodes: matchedRelayNodes,
      startNode: senderNode.node,
      endNode: recipientNode.node,
    );

    return _ContactTraceResult(
      sender: senderNode,
      recipient: recipientNode,
      routeHashes: routeHashes,
      matchedRelayNodes: alignedRelayNodes,
    );
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

  List<MeshMapNode> _localNodesFromContacts(
    ContactsProvider contactsProvider, {
    required ConnectionProvider connectionProvider,
  }) {
    final nodes = contactsProvider.contactsWithLocation
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

    final selfNode = _selfNode(connectionProvider);
    if (selfNode != null) {
      nodes.add(selfNode);
    }
    return nodes;
  }

  MeshMapNode? _selfNode(ConnectionProvider connectionProvider) {
    final publicKey = connectionProvider.deviceInfo.publicKey;
    final advLat = connectionProvider.deviceInfo.advLat;
    final advLon = connectionProvider.deviceInfo.advLon;
    if (publicKey == null || advLat == null || advLon == null) {
      return null;
    }
    if (advLat == 0 && advLon == 0) {
      return null;
    }

    final node = MeshMapNode(
      type: -1,
      name: connectionProvider.deviceInfo.selfName?.trim().isNotEmpty == true
          ? connectionProvider.deviceInfo.selfName!.trim()
          : 'You',
      publicKey: publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase(),
      latitude: advLat / 1e6,
      longitude: advLon / 1e6,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    return node.hasValidCoordinates ? node : null;
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
}

class _ContactTraceResult {
  final ResolvedTraceNode sender;
  final ResolvedTraceNode recipient;
  final List<String> routeHashes;
  final List<ResolvedTraceNode> matchedRelayNodes;

  const _ContactTraceResult({
    required this.sender,
    required this.recipient,
    required this.routeHashes,
    required this.matchedRelayNodes,
  });

  _ContactTraceResult cycleEntry(_RouteEntryTarget target) {
    switch (target.kind) {
      case _RouteEntryKind.relayNode:
        final updated = matchedRelayNodes.toList();
        updated[target.index] = updated[target.index].cycle();
        return _ContactTraceResult(
          sender: sender,
          recipient: recipient,
          routeHashes: routeHashes,
          matchedRelayNodes: updated,
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
}

enum _RouteEntryKind { relayNode }

class _RouteEntryTarget {
  final _RouteEntryKind kind;
  final int index;

  const _RouteEntryTarget._(this.kind, [this.index = 0]);

  const _RouteEntryTarget.relayNode(int index)
    : this._(_RouteEntryKind.relayNode, index);
}
