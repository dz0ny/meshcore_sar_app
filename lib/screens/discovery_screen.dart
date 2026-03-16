import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../services/mesh_map_nodes_service.dart';
import '../widgets/compact_signal_indicator.dart' show SignalMetric;

enum _DiscoveryMenuAction { repeaters, sensors }

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const int _repeaterAdvertType = 2;
  static const int _sensorAdvertType = 4;
  final Set<String> _resolvingAdvertKeys = <String>{};
  final Set<int> _runningDiscoveryTypes = <int>{};
  bool _isResolvingAll = false;
  late final Future<List<MeshMapNode>> _cachedNodesFuture;

  @override
  void initState() {
    super.initState();
    _cachedNodesFuture = MeshMapNodesService.loadCachedNodes(
      cacheTtl: MeshMapNodesService.traceCacheTtl,
    );
  }

  Future<void> _handleMenuAction(_DiscoveryMenuAction action) async {
    switch (action) {
      case _DiscoveryMenuAction.repeaters:
        await _discoverNodeType(_repeaterAdvertType);
        break;
      case _DiscoveryMenuAction.sensors:
        await _discoverNodeType(_sensorAdvertType);
        break;
    }
  }

  Future<void> _clearAllDiscoveries() async {
    final pendingCount = context.read<ContactsProvider>().pendingAdverts.length;
    if (pendingCount == 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear discoveries'),
        content: Text(
          'Remove all $pendingCount pending discover${pendingCount == 1 ? 'y' : 'ies'} from this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<ContactsProvider>().clearPendingAdverts();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared pending discoveries.')),
    );
  }

  Future<void> _discoverNodeType(int advertType) async {
    if (_runningDiscoveryTypes.contains(advertType)) return;

    setState(() {
      _runningDiscoveryTypes.add(advertType);
    });

    try {
      await context.read<ConnectionProvider>().discoverNodeType(
        advertType: advertType,
      );
      if (!mounted) return;
      final label = switch (advertType) {
        _repeaterAdvertType => 'Repeater discovery sent',
        _sensorAdvertType => 'Sensor discovery sent',
        _ => 'Discovery sent',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(label)));
    } finally {
      if (mounted) {
        setState(() {
          _runningDiscoveryTypes.remove(advertType);
        });
      }
    }
  }

  Future<void> _resolveAdvert(PendingAdvert advert) async {
    final keyHex = advert.publicKeyHex;
    if (_resolvingAdvertKeys.contains(keyHex)) return;

    setState(() {
      _resolvingAdvertKeys.add(keyHex);
    });

    try {
      final connectionProvider = context.read<ConnectionProvider>();
      final contactsProvider = context.read<ContactsProvider>();

      final canAddDirectly = _canAddPendingAdvertDirectly(advert);
      if (canAddDirectly) {
        final added = await _addPendingAdvertToRadio(
          advert,
          connectionProvider: connectionProvider,
          contactsProvider: contactsProvider,
        );
        if (!added) {
          return;
        }
      } else {
        await connectionProvider.getContact(advert.publicKey);
        if (connectionProvider.error == 'Not found') {
          connectionProvider.clearError();
          final added = await _addPendingAdvertToRadio(
            advert,
            connectionProvider: connectionProvider,
            contactsProvider: contactsProvider,
          );
          if (!added) {
            return;
          }
        }
      }
      if ((advert.typeValue ?? 0) == _sensorAdvertType) {
        await connectionProvider.requestTelemetry(advert.publicKey);
      }
    } finally {
      if (mounted) {
        setState(() {
          _resolvingAdvertKeys.remove(keyHex);
        });
      }
    }
  }

  Future<void> _resolveAll(List<PendingAdvert> adverts) async {
    if (_isResolvingAll || adverts.isEmpty) return;

    setState(() {
      _isResolvingAll = true;
    });

    try {
      for (final advert in adverts) {
        if (!mounted) break;
        await _resolveAdvert(advert);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAll = false;
        });
      }
    }
  }

  String _formatRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  Contact _contactFromPendingAdvert(PendingAdvert advert) {
    final lastAdvert =
        advert.lastAdvert ?? (advert.receivedAt.millisecondsSinceEpoch ~/ 1000);
    final advName = advert.advName?.trim().isNotEmpty == true
        ? advert.advName!.trim()
        : advert.shortDisplayKey;

    return Contact(
      publicKey: Uint8List.fromList(advert.publicKey),
      type: ContactType.fromValue(advert.typeValue ?? 0),
      flags: advert.flags ?? 0,
      outPathLen: advert.signedEncodedPathLen ?? -1,
      outPath: advert.paddedPathBytes == null
          ? Uint8List(64)
          : Uint8List.fromList(advert.paddedPathBytes!),
      advName: advName,
      lastAdvert: lastAdvert,
      advLat: advert.advLat ?? 0,
      advLon: advert.advLon ?? 0,
      lastMod: lastAdvert,
    );
  }

  bool _canAddPendingAdvertDirectly(PendingAdvert advert) {
    return advert.publicKey.length == 32 &&
        advert.typeValue != null &&
        advert.typeValue != 0;
  }

  Future<bool> _addPendingAdvertToRadio(
    PendingAdvert advert, {
    required ConnectionProvider connectionProvider,
    required ContactsProvider contactsProvider,
  }) async {
    final contact = _contactFromPendingAdvert(advert);
    await connectionProvider.addOrUpdateContact(contact);

    final addError = connectionProvider.error;
    if (addError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add contact: $addError')),
        );
      }
      return false;
    }

    contactsProvider.addOrUpdateContact(
      contact,
      devicePublicKey: connectionProvider.deviceInfo.publicKey,
    );
    return true;
  }

  String _displayNameForAdvert(
    PendingAdvert advert,
    ContactsProvider contactsProvider,
    List<MeshMapNode> cachedNodes,
  ) {
    final advertisedName = advert.advName?.trim();
    if (advertisedName != null && advertisedName.isNotEmpty) {
      return advertisedName;
    }

    Contact? existingMatch;
    for (final contact in contactsProvider.contacts) {
      if (contact.publicKeyHex == advert.publicKeyHex) {
        existingMatch = contact;
        break;
      }
    }
    if (existingMatch != null && existingMatch.displayName.trim().isNotEmpty) {
      return existingMatch.displayName;
    }

    MeshMapNode? cachedMatch;
    for (final node in cachedNodes) {
      if (node.publicKey == advert.publicKeyHex.toLowerCase()) {
        cachedMatch = node;
        break;
      }
    }
    if (cachedMatch != null && cachedMatch.name.trim().isNotEmpty) {
      return cachedMatch.name;
    }

    return advert.shortDisplayKey;
  }

  IconData _iconForAdvert(PendingAdvert advert) {
    return switch (advert.typeValue) {
      _repeaterAdvertType => Icons.router_outlined,
      _sensorAdvertType => Icons.sensors_outlined,
      _ => Icons.campaign_outlined,
    };
  }

  String? _typeLabelForAdvert(PendingAdvert advert) {
    return switch (advert.typeValue) {
      _repeaterAdvertType => 'Repeater',
      _sensorAdvertType => 'Sensor',
      3 => 'Room',
      1 => 'Chat',
      _ => null,
    };
  }

  String? _resolvedTypeLabelForAdvert(
    PendingAdvert advert,
    List<MeshMapNode> cachedNodes,
  ) {
    final directType = _typeLabelForAdvert(advert);
    if (directType != null) {
      return directType;
    }

    for (final node in cachedNodes) {
      if (node.publicKey == advert.publicKeyHex.toLowerCase()) {
        return switch (node.type) {
          1 => 'Repeater',
          4 => 'Sensor',
          3 => 'Room',
          2 => 'Chat',
          _ => null,
        };
      }
    }

    return null;
  }

  Widget _buildAdvertTitle(
    BuildContext context, {
    required String displayName,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery'),
        actions: [
          Consumer<ConnectionProvider>(
            builder: (context, connectionProvider, child) {
              final isConnected = connectionProvider.deviceInfo.isConnected;
              final repeatersBusy = _runningDiscoveryTypes.contains(
                _repeaterAdvertType,
              );
              final sensorsBusy = _runningDiscoveryTypes.contains(
                _sensorAdvertType,
              );

              return PopupMenuButton<_DiscoveryMenuAction>(
                tooltip: 'Discovery tools',
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem<_DiscoveryMenuAction>(
                    value: _DiscoveryMenuAction.repeaters,
                    enabled: isConnected && !repeatersBusy,
                    child: Row(
                      children: [
                        repeatersBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.router_outlined),
                        const SizedBox(width: 12),
                        const Text('Discover repeaters'),
                      ],
                    ),
                  ),
                  PopupMenuItem<_DiscoveryMenuAction>(
                    value: _DiscoveryMenuAction.sensors,
                    enabled: isConnected && !sensorsBusy,
                    child: Row(
                      children: [
                        sensorsBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sensors_outlined),
                        const SizedBox(width: 12),
                        const Text('Discover sensors'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MeshMapNode>>(
        future: _cachedNodesFuture,
        builder: (context, nodesSnapshot) => Consumer2<ContactsProvider, ConnectionProvider>(
          builder: (context, contactsProvider, connectionProvider, child) {
            final pendingAdverts = contactsProvider.pendingAdverts;
            final isConnected = connectionProvider.deviceInfo.isConnected;
            final cachedNodes = nodesSnapshot.data ?? const <MeshMapNode>[];

            // Track which pending adverts are already in the contacts list
            final resolvedKeySet = <String>{};
            for (final advert in pendingAdverts) {
              if (contactsProvider.findContactByKey(advert.publicKey) != null) {
                resolvedKeySet.add(advert.publicKeyHex);
              }
            }

            final totalCount = pendingAdverts.length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_search),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Discovered nodes ($totalCount)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Resolve entries manually so they do not auto-populate contacts.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    isConnected &&
                                        pendingAdverts.isNotEmpty &&
                                        !_isResolvingAll
                                    ? () => _resolveAll(pendingAdverts)
                                    : null,
                                icon: _isResolvingAll
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_for_offline_outlined,
                                      ),
                                label: const Text('Resolve all'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: pendingAdverts.isNotEmpty
                                    ? _clearAllDiscoveries
                                    : null,
                                icon: const Icon(Icons.clear_all_rounded),
                                label: const Text('Clear all'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (totalCount == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No discovered nodes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use the menu to discover repeaters and sensors on the mesh.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ...pendingAdverts.map((advert) =>
                  _buildPendingAdvertCard(
                    context,
                    advert: advert,
                    contactsProvider: contactsProvider,
                    isConnected: isConnected,
                    isResolved: resolvedKeySet.contains(advert.publicKeyHex),
                    cachedNodes: cachedNodes,
                    l10n: l10n,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPendingAdvertCard(
    BuildContext context, {
    required PendingAdvert advert,
    required ContactsProvider contactsProvider,
    required bool isConnected,
    required bool isResolved,
    required List<MeshMapNode> cachedNodes,
    required AppLocalizations l10n,
  }) {
    final isResolving = _resolvingAdvertKeys.contains(advert.publicKeyHex);
    final displayName = _displayNameForAdvert(advert, contactsProvider, cachedNodes);
    final typeLabel = _resolvedTypeLabelForAdvert(advert, cachedNodes);
    final downMetric = SignalMetric.fromValues(
      rssiDbm: advert.rxRssiDbm,
      snrDb: advert.rxSnr,
    );
    final upMetric = SignalMetric.fromValues(
      rssiDbm: advert.repeaterLastRssi,
      snrDb: advert.repeaterLastSnr,
    );
    final detailLines = <String>[
      '${l10n.publicKey}: ${advert.shortDisplayKey}',
    ];
    final summaryParts = <String>[];
    final battery = advert.repeaterBatteryPercent;
    if (battery != null) {
      summaryParts.add('Battery ${battery.round()}%');
    }
    if (advert.repeaterQueueLen != null) {
      summaryParts.add('Queue ${advert.repeaterQueueLen}');
    }
    if (summaryParts.isNotEmpty) {
      detailLines.add(summaryParts.join(' • '));
    }
    detailLines.add(
      '${l10n.lastSeen}: ${_formatRelativeTime(context, advert.receivedAt)}',
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(child: Icon(_iconForAdvert(advert))),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAdvertTitle(
                    context,
                    displayName: displayName,
                    subtitle: typeLabel,
                  ),
                ),
                if (downMetric != null || upMetric != null) ...[
                  const SizedBox(width: 12),
                  _buildSignalSummary(
                    context,
                    downMetric: downMetric,
                    upMetric: upMetric,
                  ),
                ],
                const SizedBox(width: 8),
                if (isResolved)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  )
                else if (isResolving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.person_add_alt_1),
                    tooltip: 'Resolve contact',
                    onPressed: isConnected
                        ? () => _resolveAdvert(advert)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              detailLines.join('\n'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalSummary(
    BuildContext context, {
    SignalMetric? downMetric,
    SignalMetric? upMetric,
  }) {
    if (downMetric == null && upMetric == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (downMetric != null)
          _buildDirectionalSignal(
            context,
            icon: Icons.south_west_rounded,
            metric: downMetric,
          ),
        if (downMetric != null && upMetric != null) const SizedBox(height: 6),
        if (upMetric != null)
          _buildDirectionalSignal(
            context,
            icon: Icons.north_east_rounded,
            metric: upMetric,
          ),
      ],
    );
  }

  Widget _buildDirectionalSignal(
    BuildContext context, {
    required IconData icon,
    required SignalMetric metric,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        _buildMiniSignalBars(context, metric),
        const SizedBox(width: 4),
        Text(
          metric.valueLabel,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMiniSignalBars(BuildContext context, SignalMetric metric) {
    final inactive = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(width: 2),
          Container(
            width: 3,
            height: 6.0 + (index * 4),
            decoration: BoxDecoration(
              color: index < metric.activeBars ? metric.color : inactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}
