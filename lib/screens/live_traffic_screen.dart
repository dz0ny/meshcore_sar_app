import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ble_packet_log.dart';
import '../models/contact.dart';
import '../providers/channels_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/connection_provider.dart';
import '../services/live_traffic_summary.dart';
import '../services/location_tracking_service.dart';
import '../services/route_hash_preferences.dart';
import '../services/traffic_stats_reporting_service.dart';
import '../utils/log_rx_route_decoder.dart';
import '../widgets/compact_signal_indicator.dart';
import '../widgets/messages/message_trace_sheet.dart';
import 'packet_log_screen.dart';
import '../l10n/app_localizations.dart';

T? _maybeProvider<T>(BuildContext context) {
  try {
    return Provider.of<T>(context, listen: false);
  } catch (_) {
    return null;
  }
}

class LiveTrafficScreen extends StatefulWidget {
  final List<BlePacketLog> Function() logReader;
  final Listenable? refreshListenable;
  final DateTime Function() now;
  final VoidCallback? openPacketLogs;

  const LiveTrafficScreen({
    super.key,
    required this.logReader,
    this.refreshListenable,
    DateTime Function()? now,
    this.openPacketLogs,
  }) : now = now ?? DateTime.now;

  factory LiveTrafficScreen.fromProvider(
    ConnectionProvider provider, {
    Key? key,
    VoidCallback? openPacketLogs,
  }) {
    return LiveTrafficScreen(
      key: key,
      logReader: () => provider.bleService.packetLogs,
      refreshListenable: provider,
      openPacketLogs: openPacketLogs,
    );
  }

  @override
  State<LiveTrafficScreen> createState() => _LiveTrafficScreenState();
}

class _LiveTrafficScreenState extends State<LiveTrafficScreen> {
  static const List<Duration> _windowOptions = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  Timer? _ticker;
  DateTime? _clearedAt;
  int _preferredHashSize = RouteHashPreferences.defaultHashSize;
  Duration _selectedWindow = const Duration(minutes: 1);
  String? _selectedPacketType;

  @override
  void initState() {
    super.initState();
    _loadPreferredHashSize();
    widget.refreshListenable?.addListener(_handleRefresh);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant LiveTrafficScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_handleRefresh);
      widget.refreshListenable?.addListener(_handleRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_handleRefresh);
    _ticker?.cancel();
    super.dispose();
  }

  void _handleRefresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadPreferredHashSize() async {
    final hashSize = await RouteHashPreferences.getHashSize();
    if (!mounted) return;
    setState(() {
      _preferredHashSize = hashSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logReader();
    final totalRxDataCount = LiveTrafficSummary.countRxDataLogs(logs);
    final unfilteredSnapshot = LiveTrafficSummary.fromLogs(
      logs,
      now: widget.now(),
      clearedAt: _clearedAt,
      preferredHashSize: _preferredHashSize,
      window: _selectedWindow,
    );
    final snapshot = LiveTrafficSummary.fromLogs(
      logs,
      now: widget.now(),
      clearedAt: _clearedAt,
      preferredHashSize: _preferredHashSize,
      window: _selectedWindow,
      packetTypeFilter: _selectedPacketType,
    );
    final theme = Theme.of(context);
    final contactsProvider = _maybeProvider<ContactsProvider>(context);
    final routeHashCounts = _RouteHashCounts.fromContacts(
      contactsProvider?.contacts ?? const <Contact>[],
    );
    final packetTypes =
        unfilteredSnapshot.visibleEntries
            .map((entry) => entry.payloadLabel)
            .toSet()
            .toList()
          ..sort();
    final filteredEntries = snapshot.visibleEntries;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.liveTraffic),
        actions: [
          if (widget.openPacketLogs != null)
            IconButton(
              onPressed: widget.openPacketLogs,
              tooltip: AppLocalizations.of(context)!.openPacketLogs,
              icon: const Icon(Icons.list_alt_rounded),
            ),
          IconButton(
            onPressed: _openStatsDashboard,
            tooltip: AppLocalizations.of(context)!.viewPublicStats,
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            onPressed: () => _showPacketTypeHelpSheet(context),
            tooltip: AppLocalizations.of(context)!.packetTypeHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _clearedAt = widget.now();
              });
            },
            tooltip: AppLocalizations.of(context)!.clearLiveView,
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryPanel(
                    snapshot: snapshot,
                    totalRxCount: totalRxDataCount,
                    routeHashCounts: routeHashCounts,
                    onWindowTap: () => _showWindowPicker(context),
                  ),
                  const SizedBox(height: 10),
                  _PacketTypeFilterBar(
                    packetTypes: packetTypes,
                    selectedType: _selectedPacketType,
                    onSelected: (value) {
                      setState(() {
                        _selectedPacketType = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (filteredEntries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No packets for this filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        unfilteredSnapshot.visibleEntries.isEmpty
                            ? 'This view only shows in-memory traffic while it is active.'
                            : 'Try a different packet type or switch back to All.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final entry = filteredEntries[index];
                  return _LiveTrafficCard(entry: entry, now: widget.now());
                },
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: filteredEntries.length,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openStatsDashboard() async {
    final url = TrafficStatsReportingService.dashboardUri;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showWindowPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in _windowOptions)
                ListTile(
                  title: Text(_windowLabel(option)),
                  trailing: option == _selectedWindow
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedWindow = selected;
    });
  }

  Future<void> _showPacketTypeHelpSheet(BuildContext context) {
    final packetTypes = LiveTrafficEntry.knownPayloadTypes;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Packet Types',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Descriptions below follow the current MeshCore payload definitions.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                for (final packetType in packetTypes) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packetType.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          packetType.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final LiveTrafficSnapshot snapshot;
  final int? totalRxCount;
  final _RouteHashCounts routeHashCounts;
  final VoidCallback onWindowTap;

  const _SummaryPanel({
    required this.snapshot,
    required this.totalRxCount,
    required this.routeHashCounts,
    required this.onWindowTap,
  });

  @override
  Widget build(BuildContext context) {
    final busynessColor = switch (snapshot.busyness) {
      LiveTrafficBusyness.quiet => Colors.blueGrey,
      LiveTrafficBusyness.active => Colors.orange,
      LiveTrafficBusyness.busy => Colors.redAccent,
    };
    final busynessLabel = switch (snapshot.busyness) {
      LiveTrafficBusyness.quiet => 'Quiet',
      LiveTrafficBusyness.active => 'Active',
      LiveTrafficBusyness.busy => 'Busy',
    };
    final metrics = [
      _MetricTile(
        tileKey: const ValueKey('liveTrafficMetric:rxPackets'),
        label: AppLocalizations.of(context)!.rxPackets,
        value: '${snapshot.rxCount}',
        subtitle: totalRxCount == null
            ? _windowSummaryLabel(snapshot.windowDuration)
            : 'Device total $totalRxCount',
      ),
      _MetricTile(
        tileKey: const ValueKey('liveTrafficMetric:rssi'),
        label: AppLocalizations.of(context)!.rssi,
        value: snapshot.latestRssiDbm == null
            ? 'No RX data'
            : '${snapshot.latestRssiDbm} dBm',
        subtitle: snapshot.avgRssiDbm == null
            ? 'No average yet'
            : 'Avg ${snapshot.avgRssiDbm!.toStringAsFixed(1)} dBm',
      ),
      _MetricTile(
        tileKey: const ValueKey('liveTrafficMetric:snr'),
        label: AppLocalizations.of(context)!.snr,
        value: snapshot.latestSnrDb == null
            ? 'No RX data'
            : '${snapshot.latestSnrDb!.toStringAsFixed(1)} dB',
        subtitle: snapshot.avgSnrDb == null
            ? 'No average yet'
            : 'Avg ${snapshot.avgSnrDb!.toStringAsFixed(1)} dB',
      ),
      _MetricTile(
        tileKey: const ValueKey('liveTrafficMetric:multihop'),
        label: AppLocalizations.of(context)!.multihop,
        value: '${snapshot.multiHopCount}',
        subtitle: routeHashCounts.summaryLabel,
        footer: snapshot.avgHopCount == null
            ? 'No routes yet'
            : 'Avg ${snapshot.avgHopCount!.toStringAsFixed(1)} hops',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            busynessColor.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SummaryBadge(
                label: AppLocalizations.of(context)!.mesh,
                value: busynessLabel,
                color: busynessColor,
              ),
              _SummaryBadge(
                label: AppLocalizations.of(context)!.rate,
                value: '${snapshot.packetsPerMinute} pkt/min',
                color: Theme.of(context).colorScheme.primary,
              ),
              _SummaryBadge(
                label: AppLocalizations.of(context)!.window,
                value: _windowLabel(snapshot.windowDuration),
                color: Theme.of(context).colorScheme.secondary,
                onTap: onWindowTap,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              const minTileWidth = 150.0;
              final columns =
                  ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                      .floor()
                      .clamp(1, metrics.length);
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(width: tileWidth, child: metric),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PacketTypeFilterBar extends StatelessWidget {
  final List<String> packetTypes;
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const _PacketTypeFilterBar({
    required this.packetTypes,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: AppLocalizations.of(context)!.all,
            selected: selectedType == null,
            onTap: () => onSelected(null),
          ),
          for (final type in packetTypes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: type,
              selected: selectedType == type,
              onTap: () => onSelected(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.45 : 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

String _windowLabel(Duration duration) {
  return '${duration.inMinutes} min';
}

String _windowSummaryLabel(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes == 1) return 'Last 1 min';
  return 'Last $minutes min';
}

class _MetricTile extends StatelessWidget {
  final Key? tileKey;
  final String label;
  final String value;
  final String subtitle;
  final String? footer;

  const _MetricTile({
    this.tileKey,
    required this.label,
    required this.value,
    required this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      height: 136,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    footer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteHashCounts {
  final int oneByte;
  final int twoByte;
  final int threeByte;

  const _RouteHashCounts({
    required this.oneByte,
    required this.twoByte,
    required this.threeByte,
  });

  factory _RouteHashCounts.fromContacts(List<Contact> contacts) {
    var oneByte = 0;
    var twoByte = 0;
    var threeByte = 0;

    for (final contact in contacts) {
      if (!contact.routeHasPath || contact.routeHopCount <= 0) continue;
      switch (contact.routeHashSize) {
        case 1:
          oneByte += 1;
          break;
        case 2:
          twoByte += 1;
          break;
        case 3:
          threeByte += 1;
          break;
      }
    }

    return _RouteHashCounts(
      oneByte: oneByte,
      twoByte: twoByte,
      threeByte: threeByte,
    );
  }

  String get summaryLabel => '1b:$oneByte  2b:$twoByte  3b:$threeByte';
}

class _LiveTrafficCard extends StatelessWidget {
  final LiveTrafficEntry entry;
  final DateTime now;

  const _LiveTrafficCard({required this.entry, required this.now});

  @override
  Widget build(BuildContext context) {
    final log = entry.log;
    final isRx = log.direction == PacketDirection.rx;
    final accent = isRx ? Colors.green : Colors.blue;
    final rxInfo = log.logRxDataInfo;
    final originDistance = _originDistanceLabel(context, entry);
    final channelsProvider = _maybeProvider<ChannelsProvider>(context);
    final packetDetails = _LiveTrafficPacketDetails.fromEntry(
      entry,
      channelsProvider: channelsProvider,
    );
    final signalMetric = SignalMetric.fromRxInfo(rxInfo);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPacketBytesSheet(context, log.rawData),
        onLongPress: () => _showTraceSheet(context, entry),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isRx ? 'RX' : 'TX',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packetDetails.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (entry.payloadMeaning != null)
                          Text(
                            entry.payloadMeaning!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (signalMetric != null) ...[
                    const SizedBox(width: 12),
                    CompactSignalIndicator(metric: signalMetric),
                  ] else
                    Text(
                      _timeAgo(log.timestamp, now),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _PacketInfoLine(
                text:
                    '${_formatClock(log.timestamp)} • Size: ${log.rawData.length} bytes',
              ),
              _PacketInfoLine(text: 'Hash: ${packetDetails.packetHashHex}'),
              if (packetDetails.pathLine != null)
                _PacketInfoLine(text: packetDetails.pathLine!),
              if (packetDetails.pathHashLine != null)
                _PacketInfoLine(text: packetDetails.pathHashLine!),
              if (packetDetails.endpointLine != null)
                _PacketInfoLine(text: packetDetails.endpointLine!),
              if (originDistance != null)
                _PacketInfoLine(text: 'Origin: $originDistance'),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime timestamp, DateTime now) {
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  static String _formatClock(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  static String? _originDistanceLabel(
    BuildContext context,
    LiveTrafficEntry entry,
  ) {
    final route = entry.route;
    if (route == null || route.hopHashes.isEmpty) {
      return null;
    }

    final contactsProvider = _maybeProvider<ContactsProvider>(context);
    final connectionProvider = _maybeProvider<ConnectionProvider>(context);
    final ownLatLng = _ownLatLng(connectionProvider);
    final resolved = LogRxRouteDecoder.resolveHash(
      route.hopHashes.first,
      contacts: contactsProvider?.contacts ?? const <Contact>[],
      ownPublicKey: connectionProvider?.deviceInfo.publicKey,
      ownName:
          connectionProvider?.deviceInfo.selfName ??
          connectionProvider?.deviceInfo.displayName,
      ownLatitude: ownLatLng?.latitude,
      ownLongitude: ownLatLng?.longitude,
    );
    if (resolved.latitude == null || resolved.longitude == null) {
      return null;
    }

    final currentPosition = LocationTrackingService().currentPosition;
    final originDistanceMeters = currentPosition != null
        ? Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            resolved.latitude!,
            resolved.longitude!,
          )
        : ownLatLng != null
        ? Geolocator.distanceBetween(
            ownLatLng.latitude,
            ownLatLng.longitude,
            resolved.latitude!,
            resolved.longitude!,
          )
        : null;
    if (originDistanceMeters == null) {
      return null;
    }
    return _formatDistance(originDistanceMeters);
  }

  static _GeoPoint? _ownLatLng(ConnectionProvider? connectionProvider) {
    final advLat = connectionProvider?.deviceInfo.advLat;
    final advLon = connectionProvider?.deviceInfo.advLon;
    if (advLat == null || advLon == null || (advLat == 0 && advLon == 0)) {
      return null;
    }
    return _GeoPoint(advLat / 1e6, advLon / 1e6);
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  static Future<void> _showPacketBytesSheet(
    BuildContext context,
    List<int> bytes,
  ) {
    final data = bytes.toList(growable: false);
    final hexLines = <String>[];
    const bytesPerLine = 16;
    for (var offset = 0; offset < data.length; offset += bytesPerLine) {
      final chunk = data.skip(offset).take(bytesPerLine).toList();
      final hex = chunk
          .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      hexLines.add(
        '${offset.toRadixString(16).padLeft(4, '0').toUpperCase()}: $hex',
      );
    }

    final ascii = data
        .map(
          (byte) =>
              (byte >= 32 && byte <= 126) ? String.fromCharCode(byte) : '.',
        )
        .join();

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packet Bytes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.length} bytes',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.hex, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      hexLines.join('\n'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontFamily: 'monospace',
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.ascii, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      ascii.isEmpty ? '(empty)' : ascii,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontFamily: 'monospace',
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showTraceSheet(
    BuildContext context,
    LiveTrafficEntry entry,
  ) {
    final route = entry.route;
    if (route == null || route.pathBytes.isEmpty) {
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MessageTraceSheet.packetPath(
        packetPath: route.pathBytes,
        descriptionOverride:
            'Relay path from packet path bytes (${route.hopHashes.length} hop${route.hopHashes.length == 1 ? '' : 's'})',
        noRelayMatchTextOverride:
            'No named nodes could be matched for this packet path.',
      ),
    );
  }
}

class _LiveTrafficPacketDetails {
  final String title;
  final String packetHashHex;
  final String? pathLine;
  final String? pathHashLine;
  final String? endpointLine;

  const _LiveTrafficPacketDetails({
    required this.title,
    required this.packetHashHex,
    required this.pathLine,
    required this.pathHashLine,
    required this.endpointLine,
  });

  factory _LiveTrafficPacketDetails.fromEntry(
    LiveTrafficEntry entry, {
    ChannelsProvider? channelsProvider,
  }) {
    final route = entry.route;
    final payloadType = route?.payloadType;
    final parsedPayload = _ParsedTrafficPayload.tryParse(
      entry.log.rawData,
      route,
      channelsProvider: channelsProvider,
    );
    final title = switch (payloadType) {
      0x05 => parsedPayload?.channelDisplayName ?? LiveTrafficEntry.payloadTypeTitle(0x05),
      0x06 => parsedPayload?.channelDisplayName ?? LiveTrafficEntry.payloadTypeTitle(0x06),
      null => entry.payloadLabel.toUpperCase(),
      _ => LiveTrafficEntry.payloadTypeTitle(payloadType),
    };

    final hopHashes = route?.hopHashes ?? const <String>[];
    final pathLine = hopHashes.isEmpty
        ? null
        : 'Path: ${hopHashes.length} hop${hopHashes.length == 1 ? '' : 's'} [${hopHashes.join(',')}]';
    final pathHashLine = route == null
        ? null
        : 'Path Hashes: ${route.hashSize}-byte per hop';

    return _LiveTrafficPacketDetails(
      title: title,
      packetHashHex: _packetHash(entry.log.rawData),
      pathLine: pathLine,
      pathHashLine: pathHashLine,
      endpointLine: parsedPayload?.endpointLine,
    );
  }

  static String _packetHash(List<int> bytes) {
    final digest = md5.convert(bytes).bytes;
    return digest
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}

class _ParsedTrafficPayload {
  final String? endpointLine;
  final String? channelDisplayName;

  const _ParsedTrafficPayload({this.endpointLine, this.channelDisplayName});

  static _ParsedTrafficPayload? tryParse(
    List<int> rawData,
    DecodedLogRxRoute? route, {
    ChannelsProvider? channelsProvider,
  }) {
    if (rawData.length < 5 ||
        rawData.first != LiveTrafficSummary.logRxDataResponseCode) {
      return null;
    }

    final rawPacketData = rawData.sublist(3);
    if (rawPacketData.length < 2) return null;

    final header = rawPacketData[0];
    final routeType = header & 0x03;
    final payloadType = (header >> 2) & 0x0F;

    var index = 1;
    if (routeType == 0x00 || routeType == 0x03) {
      if (rawPacketData.length < index + 5) return null;
      index += 4;
    }

    if (rawPacketData.length <= index) return null;
    final pathDescriptor = rawPacketData[index++];
    final pathByteLen =
        LogRxRouteDecoder.descriptorByteLength(pathDescriptor) ??
        (pathDescriptor == 0xFF ? 0 : null);
    if (pathByteLen == null || rawPacketData.length < index + pathByteLen) {
      return null;
    }
    index += pathByteLen;
    final payload = rawPacketData.sublist(index);
    final senderHash = route?.hopHashes.isNotEmpty == true
        ? route!.hopHashes.first
        : null;

    switch (payloadType) {
      case 0x05:
      case 0x06:
        if (payload.isEmpty) return const _ParsedTrafficPayload();
        final channelHash = payload.first;
        final channelHashHex = channelHash
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
        final channelDisplayName = channelsProvider
            ?.getUniqueChannelDisplayNameByHashByte(channelHash);
        return _ParsedTrafficPayload(
          channelDisplayName: channelDisplayName,
          endpointLine: channelDisplayName == null
              ? 'Channel Hash: $channelHashHex'
              : 'Channel: $channelDisplayName ($channelHashHex)',
        );
      case 0x00:
      case 0x01:
      case 0x07:
        if (payload.isEmpty) return const _ParsedTrafficPayload();
        final destinationHash = payload.first
            .toRadixString(16)
            .padLeft(2, '0')
            .toUpperCase();
        return _ParsedTrafficPayload(
          endpointLine: senderHash == null
              ? 'To: <$destinationHash>'
              : 'From: <${senderHash.toUpperCase()}> To: <$destinationHash>',
        );
      default:
        return const _ParsedTrafficPayload();
    }
  }
}

class _PacketInfoLine extends StatelessWidget {
  final String text;

  const _PacketInfoLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _GeoPoint {
  final double latitude;
  final double longitude;

  const _GeoPoint(this.latitude, this.longitude);
}

void openLiveTrafficScreen(BuildContext context, ConnectionProvider provider) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LiveTrafficScreen.fromProvider(
        provider,
        openPacketLogs: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PacketLogScreen(bleService: provider.bleService),
            ),
          );
        },
      ),
    ),
  );
}
