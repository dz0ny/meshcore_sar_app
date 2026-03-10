import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:meshcore_client/meshcore_client.dart';
import '../l10n/app_localizations.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../services/mesh_map_nodes_service.dart';
import '../services/route_hash_preferences.dart';
import '../utils/log_rx_route_decoder.dart';

class PacketLogScreen extends StatefulWidget {
  final MeshCoreBleService bleService;

  const PacketLogScreen({super.key, required this.bleService});

  @override
  State<PacketLogScreen> createState() => _PacketLogScreenState();
}

class _PacketLogScreenState extends State<PacketLogScreen> {
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  PacketDirection? _filterDirection;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<BlePacketLog> get _filteredLogs {
    var logs = widget.bleService.packetLogs;

    // Filter by direction
    if (_filterDirection != null) {
      logs = logs.where((log) => log.direction == _filterDirection).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) {
        return log.hexData.toLowerCase().contains(query) ||
            (log.description?.toLowerCase().contains(query) ?? false) ||
            log.summary.toLowerCase().contains(query);
      }).toList();
    }

    return logs;
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      final logs = _filteredLogs;
      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No logs to export')));
        }
        return;
      }

      // Create CSV content
      final buffer = StringBuffer();
      buffer.writeln(
        'Timestamp,Direction,Size (bytes),Opcode Name,Code,Hex Data,Description',
      );
      for (final log in logs) {
        buffer.writeln(log.toCsvRow());
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      if (!context.mounted) return;
      final file = File(
        '${tempDir.path}/ble_packets_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(buffer.toString());

      // Share the file
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'MeshCore BLE Packet Logs',
          text: 'Exported ${logs.length} BLE packets from MeshCore SAR app',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportAsText(BuildContext context) async {
    try {
      final logs = _filteredLogs;
      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No logs to export')));
        }
        return;
      }

      // Create text content
      final buffer = StringBuffer();
      buffer.writeln('MeshCore BLE Packet Logs');
      buffer.writeln('=' * 80);
      buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total packets: ${logs.length}');
      buffer.writeln('=' * 80);
      buffer.writeln();

      for (final log in logs) {
        buffer.writeln(log.toLogString());
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      if (!context.mounted) return;
      final file = File(
        '${tempDir.path}/ble_packets_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(buffer.toString());

      // Share the file
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'MeshCore BLE Packet Logs',
          text: 'Exported ${logs.length} BLE packets from MeshCore SAR app',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _copyToClipboard(BuildContext context, BlePacketLog log) {
    Clipboard.setData(ClipboardData(text: log.hexData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hex data copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearLogs(BuildContext context) {
    final parentContext = context; // Store parent context for setState
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.clearAllData),
        content: const Text(
          'Are you sure you want to clear all packet logs? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () {
              widget.bleService.clearPacketLogs();
              Navigator.pop(dialogContext);
              if (!mounted) return;
              setState(() {});
              if (parentContext.mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Packet logs cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(dialogContext)!.clear),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BLE Packet Logs'),
            Text(
              '${logs.length} packets',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          // Direction filter
          PopupMenuButton<PacketDirection?>(
            icon: Icon(
              _filterDirection == null
                  ? Icons.filter_list
                  : _filterDirection == PacketDirection.rx
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            tooltip: 'Filter by direction',
            onSelected: (direction) {
              setState(() {
                _filterDirection = direction;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: _filterDirection == null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All',
                      style: TextStyle(
                        fontWeight: _filterDirection == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PacketDirection.rx,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _filterDirection == PacketDirection.rx
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RX (Received)',
                      style: TextStyle(
                        fontWeight: _filterDirection == PacketDirection.rx
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PacketDirection.tx,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: _filterDirection == PacketDirection.tx
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TX (Sent)',
                      style: TextStyle(
                        fontWeight: _filterDirection == PacketDirection.tx
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Auto-scroll toggle
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
            ),
            tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          // Export menu
          PopupMenuButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export logs',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'txt',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet),
                    SizedBox(width: 8),
                    Text('Export as Text'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'csv') {
                _exportLogs(context);
              } else if (value == 'txt') {
                _exportAsText(context);
              }
            },
          ),
          // Clear logs
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () => _clearLogs(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Logs list
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterDirection != null
                              ? 'No matching packets found'
                              : 'No packets logged yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _filterDirection != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _filterDirection = null;
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];

                      // Auto-scroll to bottom
                      if (_autoScroll && index == logs.length - 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }

                      return _PacketLogCard(
                        log: log,
                        onCopy: () => _copyToClipboard(context, log),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PacketLogCard extends StatelessWidget {
  final BlePacketLog log;
  final VoidCallback onCopy;

  const _PacketLogCard({required this.log, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isRx = log.direction == PacketDirection.rx;
    final directionColor = isRx ? Colors.green : Colors.blue;
    final rxInfo = log.logRxDataInfo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: directionColor.withValues(alpha: 0.2),
          child: Icon(
            isRx ? Icons.arrow_downward : Icons.arrow_upward,
            color: directionColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              isRx ? 'RX' : 'TX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: directionColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                log.responseCode != null ? log.opcodeName : 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${log.rawData.length} bytes • ${_formatTimestamp(log.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FactCard(
                      icon: isRx ? Icons.call_received : Icons.call_made,
                      label: 'Direction',
                      value: isRx ? 'RX' : 'TX',
                      accent: directionColor,
                    ),
                    _FactCard(
                      icon: Icons.data_object,
                      label: 'Size',
                      value: '${log.rawData.length} bytes',
                    ),
                    _FactCard(
                      icon: Icons.schedule,
                      label: 'Captured',
                      value: _formatTimestamp(log.timestamp),
                    ),
                    if (log.responseCode != null)
                      _FactCard(
                        icon: Icons.sell,
                        label: 'Opcode',
                        value: log.opcodeName,
                      ),
                  ],
                ),
                if (rxInfo?.rssiDbm != null || rxInfo?.snrDb != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Link Quality',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (rxInfo?.rssiDbm != null)
                          _SignalMeter(
                            label: 'RSSI',
                            valueLabel: '${rxInfo!.rssiDbm} dBm',
                            normalized: _normalizeRssi(
                              rxInfo.rssiDbm!.toDouble(),
                            ),
                            color: _rssiColor(rxInfo.rssiDbm!.toDouble()),
                          ),
                        if (rxInfo?.snrDb != null) ...[
                          const SizedBox(height: 8),
                          _SignalMeter(
                            label: 'SNR',
                            valueLabel:
                                '${rxInfo!.snrDb!.toStringAsFixed(1)} dB',
                            normalized: _normalizeSnr(rxInfo.snrDb!),
                            color: _snrColor(rxInfo.snrDb!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (isRx) ...[
                  const SizedBox(height: 12),
                  _DecodedRouteSection(log: log),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grid_view_rounded, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Hex Explorer',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onCopy,
                            tooltip: 'Copy full hex',
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var i = 0; i < log.rawData.length; i++)
                            _HexByteChip(
                              index: i,
                              value: log.rawData[i],
                              onTap: () {
                                _copyText(
                                  context,
                                  log.rawData[i]
                                      .toRadixString(16)
                                      .padLeft(2, '0')
                                      .toUpperCase(),
                                  'Byte ${i.toString().padLeft(2, '0')} copied',
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: const Text(
                          'Raw stream',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              log.hexData,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    }
  }

  static void _copyText(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  static double _normalizeRssi(double rssi) {
    return ((rssi + 120.0) / 70.0).clamp(0.0, 1.0);
  }

  static double _normalizeSnr(double snr) {
    return ((snr + 20.0) / 40.0).clamp(0.0, 1.0);
  }

  static Color _rssiColor(double rssi) {
    if (rssi >= -80) return Colors.green;
    if (rssi >= -95) return Colors.amber;
    return Colors.redAccent;
  }

  static Color _snrColor(double snr) {
    if (snr >= 10) return Colors.green;
    if (snr >= 0) return Colors.amber;
    return Colors.redAccent;
  }
}

class _DecodedRouteSection extends StatelessWidget {
  final BlePacketLog log;

  const _DecodedRouteSection({required this.log});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsProvider>().contacts;
    final connectionProvider = context.watch<ConnectionProvider>();
    final ownPublicKey = connectionProvider.deviceInfo.publicKey;
    final ownName =
        connectionProvider.deviceInfo.selfName ??
        connectionProvider.deviceInfo.displayName;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        RouteHashPreferences.getHashSize(),
        MeshMapNodesService.loadCachedNodes(
          cacheTtl: MeshMapNodesService.traceCacheTtl,
        ),
      ]),
      builder: (context, snapshot) {
        final decodedRoute = LogRxRouteDecoder.decode(
          log.rawData,
          preferredHashSize: snapshot.data?.first as int?,
        );
        if (decodedRoute == null) {
          return const SizedBox.shrink();
        }

        final cachedNodes = snapshot.hasData
            ? snapshot.data![1] as List<MeshMapNode>
            : const <MeshMapNode>[];
        final resolvedPath = decodedRoute.hopHashes
            .map(
              (hashHex) => _resolveHashWithFallback(
                hashHex,
                contacts: contacts,
                cachedNodes: cachedNodes,
                ownPublicKey: ownPublicKey,
                ownName: ownName,
              ),
            )
            .toList();
        final originalSender = resolvedPath.isEmpty ? null : resolvedPath.first;

        return _RouteSection(
          route: decodedRoute,
          path: resolvedPath,
          originalSender: originalSender,
        );
      },
    );
  }

  ResolvedNodeHash _resolveHashWithFallback(
    String hashHex, {
    required List<Contact> contacts,
    required List<MeshMapNode> cachedNodes,
    required Uint8List? ownPublicKey,
    required String? ownName,
  }) {
    final localResolved = LogRxRouteDecoder.resolveHash(
      hashHex,
      contacts: contacts,
      ownPublicKey: ownPublicKey,
      ownName: ownName,
    );
    if (localResolved.matchCount > 0 || localResolved.isOwnNode) {
      return localResolved;
    }

    final normalizedHashHex = hashHex.toLowerCase();
    final matches = cachedNodes
        .where((node) => node.publicKey.startsWith(normalizedHashHex))
        .toList();
    if (matches.isEmpty) {
      return localResolved;
    }

    matches.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return ResolvedNodeHash(
      hashHex: normalizedHashHex,
      label: matches.first.name,
      isOwnNode: false,
      isUniqueMatch: matches.length == 1,
      matchCount: matches.length,
    );
  }
}

class _RouteSection extends StatelessWidget {
  final DecodedLogRxRoute route;
  final List<ResolvedNodeHash> path;
  final ResolvedNodeHash? originalSender;

  const _RouteSection({
    required this.route,
    required this.path,
    required this.originalSender,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route, size: 16),
              SizedBox(width: 6),
              Text(
                'Mesh Route',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FactCard(
                icon: Icons.route,
                label: 'Payload',
                value: _payloadTypeLabel(route.payloadType),
              ),
              _FactCard(
                icon: Icons.hub,
                label: 'Hops',
                value: '${route.hopCount}',
              ),
              _FactCard(
                icon: Icons.tag,
                label: 'Hash size',
                value:
                    '${route.hashSize} byte${route.hashSize == 1 ? '' : 's'}',
              ),
              if (originalSender != null)
                _FactCard(
                  icon: Icons.person_pin_circle,
                  label: 'Original sender',
                  value: _nodeLabel(originalSender!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (path.isEmpty)
            Text(
              'Direct packet, no hop path attached.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < path.length; i++) ...[
                  _RouteHopChip(index: i + 1, node: path[i]),
                  if (i < path.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.arrow_right_alt, size: 16),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static String _payloadTypeLabel(int payloadType) {
    switch (payloadType) {
      case 0x00:
        return 'REQ';
      case 0x01:
        return 'RESP';
      case 0x02:
        return 'TXT';
      case 0x03:
        return 'ACK';
      case 0x04:
        return 'ADVERT';
      case 0x05:
        return 'GRP_TXT';
      case 0x06:
        return 'GRP_DATA';
      case 0x07:
        return 'ANON_REQ';
      case 0x08:
        return 'PATH';
      case 0x09:
        return 'TRACE';
      case 0x0A:
        return 'MULTIPART';
      case 0x0B:
        return 'CONTROL';
      default:
        return '0x${payloadType.toRadixString(16).padLeft(2, '0')}';
    }
  }

  static String _nodeLabel(ResolvedNodeHash node) {
    if (node.isOwnNode) {
      return '${node.label} (${node.hexLabel})';
    }
    if (node.matchCount == 0) {
      return node.hexLabel;
    }
    if (node.isUniqueMatch) {
      return '${node.label} (${node.hexLabel})';
    }
    return '${node.label} (${node.hexLabel}, ${node.matchCount} matches)';
  }
}

class _RouteHopChip extends StatelessWidget {
  final int index;
  final ResolvedNodeHash node;

  const _RouteHopChip({required this.index, required this.node});

  @override
  Widget build(BuildContext context) {
    final color = node.isOwnNode
        ? Colors.blue
        : node.isUniqueMatch
        ? Colors.green
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$index. ${_RouteSection._nodeLabel(node)}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tileColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tileColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalMeter extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double normalized;
  final Color color;

  const _SignalMeter({
    required this.label,
    required this.valueLabel,
    required this.normalized,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: normalized,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HexByteChip extends StatelessWidget {
  final int index;
  final int value;
  final VoidCallback onTap;

  const _HexByteChip({
    required this.index,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value.toRadixString(16).padLeft(2, '0').toUpperCase();
    return Tooltip(
      message: 'Byte $index',
      waitDuration: const Duration(milliseconds: 250),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
