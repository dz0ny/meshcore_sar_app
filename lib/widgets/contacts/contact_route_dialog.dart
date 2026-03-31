import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../models/path_history.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/connection_provider.dart';
import '../../services/path_history_service.dart';
import '../../services/relay_candidate_sorter.dart';
import '../../services/route_hash_preferences.dart';

class ContactRouteDialogResult {
  final ParsedContactRoute? route;
  final bool shouldClear;
  final LatLng? inferredFallbackLocation;

  const ContactRouteDialogResult._({
    this.route,
    required this.shouldClear,
    this.inferredFallbackLocation,
  });

  const ContactRouteDialogResult.set(ParsedContactRoute route)
    : this._(route: route, shouldClear: false);

  const ContactRouteDialogResult.setWithFallback(
    ParsedContactRoute route, {
    LatLng? inferredFallbackLocation,
  }) : this._(
         route: route,
         shouldClear: false,
         inferredFallbackLocation: inferredFallbackLocation,
       );

  const ContactRouteDialogResult.clear() : this._(shouldClear: true);
}

class ContactRouteDialog extends StatefulWidget {
  final Contact contact;
  final List<Contact> availableContacts;

  const ContactRouteDialog({
    super.key,
    required this.contact,
    required this.availableContacts,
  });

  static Future<ContactRouteDialogResult?> show(
    BuildContext context, {
    required Contact contact,
    required List<Contact> availableContacts,
  }) {
    return Navigator.of(context).push<ContactRouteDialogResult>(
      MaterialPageRoute(
        builder: (context) => ContactRouteDialog(
          contact: contact,
          availableContacts: availableContacts,
        ),
      ),
    );
  }

  @override
  State<ContactRouteDialog> createState() => _ContactRouteDialogState();
}

class _ContactRouteDialogState extends State<ContactRouteDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _relaySearchController;
  final PathHistoryService _pathHistoryService = PathHistoryService();
  final RelayCandidateSorter _relayCandidateSorter =
      const RelayCandidateSorter();
  int _selectedHashSize = RouteHashPreferences.defaultHashSize;
  ParsedContactRoute? _parsedRoute;
  String? _errorText;
  bool _showRoutingInfo = false;
  List<Contact> _selectedMapHops = const [];
  ContactPathHistory? _pathHistory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.contact.routeCanonicalText,
    );
    _relaySearchController = TextEditingController();
    _controller.addListener(_reparse);
    _loadHashSizePreference();
    _loadPathHistory();
    _reparse();
  }

  @override
  void dispose() {
    _relaySearchController.dispose();
    _controller
      ..removeListener(_reparse)
      ..dispose();
    super.dispose();
  }

  void _reparse() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _parsedRoute = null;
        _errorText = null;
        _selectedMapHops = const [];
      });
      return;
    }

    try {
      final parsed = ContactRouteCodec.parse(
        input,
        expectedHashSize: _selectedHashSize,
      );
      final selectedMapHops = _mapSelectionForText(input);
      setState(() {
        _parsedRoute = parsed;
        _errorText = null;
        _selectedMapHops = selectedMapHops;
      });
    } on ContactRouteFormatException catch (error) {
      setState(() {
        _parsedRoute = null;
        _errorText = error.message;
      });
    }
  }

  List<Contact> _routeCandidates({required LatLng? selfPoint}) =>
      _relayCandidateSorter.sortByDistanceFromSelf(
        widget.availableContacts
            .where(
              (contact) =>
                  contact.isRepeater && contact.displayLocation != null,
            )
            .toList(),
        selfPoint: selfPoint,
      );

  List<Contact> _mapSelectionForText(String text) {
    final tokens = text
        .trim()
        .split(',')
        .map((token) => token.trim().toUpperCase())
        .where((token) => token.isNotEmpty)
        .toList();
    final selected = <Contact>[];
    final seen = <String>{};
    for (final token in tokens) {
      final match = _routeCandidates(selfPoint: null)
          .where(
            (contact) => contact.publicKeyHex.toUpperCase().startsWith(token),
          )
          .firstOrNull;
      if (match != null && seen.add(match.publicKeyHex)) {
        selected.add(match);
      }
    }
    return selected;
  }

  Future<void> _loadHashSizePreference() async {
    // Use the contact's current path hash size if it has a path,
    // otherwise fall back to the global preference.
    final contactHashSize = widget.contact.hasPath
        ? widget.contact.pathHashSize
        : null;
    final hashSize =
        contactHashSize ?? await RouteHashPreferences.getHashSize();
    if (!mounted) return;
    setState(() {
      _selectedHashSize = hashSize;
    });
    _reparse();
  }

  Future<void> _loadPathHistory() async {
    await _pathHistoryService.initialize();
    if (!mounted) return;
    setState(() {
      _pathHistory = _pathHistoryService.historyFor(
        widget.contact.publicKeyHex,
      );
    });
  }

  String _tokenFor(Contact contact, int hashSize) {
    final hex = contact.publicKeyHex.toUpperCase();
    final length = hashSize * 2;
    if (hex.length < length) {
      return hex;
    }
    return hex.substring(0, length);
  }

  void _syncControllerFromSelectedHops() {
    final tokens = _selectedMapHops
        .map((contact) => _tokenFor(contact, _selectedHashSize))
        .toList();
    _controller.text = tokens.join(',');
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  ParsedContactRoute? get _effectiveRoute {
    if (_parsedRoute != null) {
      return _parsedRoute;
    }
    if (_errorText != null || _controller.text.trim().isNotEmpty) {
      return null;
    }
    return ContactRouteCodec.direct(hashSize: _selectedHashSize);
  }

  void _toggleHop(Contact contact) {
    setState(() {
      if (_selectedMapHops.any(
        (item) => item.publicKeyHex == contact.publicKeyHex,
      )) {
        _selectedMapHops = _selectedMapHops
            .where((item) => item.publicKeyHex != contact.publicKeyHex)
            .toList();
      } else {
        _selectedMapHops = [..._selectedMapHops, contact];
      }
      _syncControllerFromSelectedHops();
      _reparse();
    });
  }

  void _applyHistoryRecord(PathRecord record) {
    final canonicalText = _canonicalRouteFromBytes(
      record.pathBytes,
      hashSize: record.hashSize,
    );
    setState(() {
      _controller.text = canonicalText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _errorText = null;
    });
    _reparse();
  }

  LatLng? _resolveLastHopLocation() {
    if (_selectedMapHops.isNotEmpty) {
      return _selectedMapHops.last.displayLocation == null
          ? null
          : LatLng(
              _selectedMapHops.last.displayLocation!.latitude,
              _selectedMapHops.last.displayLocation!.longitude,
            );
    }

    final tokens = _controller.text
        .trim()
        .split(',')
        .map((token) => token.trim().toUpperCase())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    final lastToken = tokens.last;
    final match = _routeCandidates(selfPoint: null)
        .where(
          (contact) => contact.publicKeyHex.toUpperCase().startsWith(lastToken),
        )
        .firstOrNull;
    final location = match?.displayLocation;
    if (location == null) return null;
    return LatLng(location.latitude, location.longitude);
  }

  LatLng? _buildSyntheticFallbackLocation() {
    final lastHopLocation = _resolveLastHopLocation();
    if (lastHopLocation == null) return null;

    final seed = widget.contact.publicKey.fold<int>(
      _controller.text.codeUnits.fold<int>(0, (sum, unit) => sum + unit),
      (sum, byte) => sum + byte,
    );
    final angle = (seed % 360) * (math.pi / 180.0);
    const radiusMeters = 500.0;
    final latOffset = (radiusMeters / 111320.0) * math.cos(angle);
    final lonDenominator =
        111320.0 * math.cos(lastHopLocation.latitude * (math.pi / 180.0));
    final lonOffset = lonDenominator.abs() < 1e-6
        ? 0.0
        : (radiusMeters / lonDenominator) * math.sin(angle);
    return LatLng(
      lastHopLocation.latitude + latOffset,
      lastHopLocation.longitude + lonOffset,
    );
  }

  String _canonicalRouteFromBytes(
    List<int> pathBytes, {
    required int hashSize,
  }) {
    final hops = <String>[];
    for (var i = 0; i < pathBytes.length; i += hashSize) {
      final hop = pathBytes.sublist(i, i + hashSize);
      hops.add(
        hop
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
      );
    }
    return hops.join(',');
  }

  String _historySubtitle(PathRecord record) {
    final attempts = record.successCount + record.failureCount;
    final lastSeen = MaterialLocalizations.of(
      context,
    ).formatShortDate(record.lastUsedAt);
    final sourceLabel = switch (record.source) {
      PathRecordSource.observed => 'Observed on mesh',
      PathRecordSource.learned => 'Learned route',
    };
    final successRate = attempts == 0
        ? 'No send stats yet'
        : '${(record.successRate * 100).round()}% success over $attempts send${attempts == 1 ? '' : 's'}';
    final latency = record.lastRoundTripTimeMs > 0
        ? ' • ${record.lastRoundTripTimeMs} ms'
        : '';
    return '$sourceLabel • $successRate • Last used $lastSeen$latency';
  }

  Widget _buildHistoryRecordTile(PathRecord record, {String? title}) {
    final canonicalText = _canonicalRouteFromBytes(
      record.pathBytes,
      hashSize: record.hashSize,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: title == null ? null : const Icon(Icons.alt_route),
        title: title == null
            ? Text(
                canonicalText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    canonicalText,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_historySubtitle(record)),
        ),
        trailing: FilledButton.tonal(
          onPressed: () => _applyHistoryRecord(record),
          child: Text(AppLocalizations.of(context)!.use),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    final previewRoute = _effectiveRoute;
    if (previewRoute == null) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            previewRoute.summary,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            '${previewRoute.byteLength}B • 0x${previewRoute.encodedPathLen.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (previewRoute.canonicalText.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              previewRoute.canonicalText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedHopSection() {
    if (_selectedMapHops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected relays', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedMapHops.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return InputChip(
              label: Text('${index + 1}. ${contact.displayName}'),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () => _toggleHop(contact),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelayPicker(List<Contact> routeCandidates) {
    final query = _relaySearchController.text.trim().toLowerCase();
    final filteredCandidates = routeCandidates.where((contact) {
      if (query.isEmpty) return true;
      return contact.displayName.toLowerCase().contains(query) ||
          _tokenFor(contact, _selectedHashSize).toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _relaySearchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Find relay',
            hintText: 'Search by name or token',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredCandidates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              'No visible relays match this search.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...filteredCandidates.map((candidate) {
            final isSelected = _selectedMapHops.any(
              (item) => item.publicKeyHex == candidate.publicKeyHex,
            );
            final location = candidate.displayLocation;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(candidate.displayName),
                subtitle: Text(
                  [
                    _tokenFor(candidate, _selectedHashSize),
                    if (location != null)
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  ].join(' • '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
                trailing: TextButton(
                  onPressed: () => _toggleHop(candidate),
                  child: Text(isSelected ? 'Remove' : 'Add'),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMapPreview({
    required List<Contact> routeCandidates,
    required List<LatLng> mapPoints,
    required List<LatLng> routePoints,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: mapPoints.length < 2
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Map preview needs your advertised location, the contact location, and visible repeater locations.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : flutter_map.FlutterMap(
                options: flutter_map.MapOptions(
                  initialCameraFit: flutter_map.CameraFit.bounds(
                    bounds: flutter_map.LatLngBounds.fromPoints(mapPoints),
                    padding: const EdgeInsets.all(32),
                  ),
                ),
                children: [
                  flutter_map.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.meshcore.sar',
                  ),
                  if (routePoints.length >= 2)
                    flutter_map.PolylineLayer(
                      polylines: [
                        flutter_map.Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  flutter_map.MarkerLayer(
                    markers: [
                      ...routeCandidates.map((candidate) {
                        final isSelected = _selectedMapHops.any(
                          (item) => item.publicKeyHex == candidate.publicKeyHex,
                        );
                        return flutter_map.Marker(
                          point: LatLng(
                            candidate.displayLocation!.latitude,
                            candidate.displayLocation!.longitude,
                          ),
                          width: 64,
                          height: 70,
                          child: GestureDetector(
                            onTap: () => _toggleHop(candidate),
                            child: _RouteMarkerDot(
                              label: _tokenFor(candidate, _selectedHashSize),
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.blueGrey,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBuilderTab({
    required List<Contact> routeCandidates,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Path size', style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            SegmentedButton<int>(
              segments: [
                for (final size in RouteHashPreferences.supportedSizes)
                  ButtonSegment<int>(value: size, label: Text('${size}B')),
              ],
              selected: {_selectedHashSize},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedHashSize = selection.first;
                  _syncControllerFromSelectedHops();
                });
              },
            ),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_selectedMapHops.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedHopSection(),
        ],
        const SizedBox(height: 12),
        _buildRelayPicker(routeCandidates),
      ],
    );
  }

  Widget _buildInfoTab({
    required AppProvider appProvider,
    required List<Contact> routeCandidates,
    required List<LatLng> mapPoints,
    required List<LatLng> routePoints,
  }) {
    return ListView(
      children: [
        _buildPreviewSection(),
        const SizedBox(height: 16),
        _buildMapPreview(
          routeCandidates: routeCandidates,
          mapPoints: mapPoints,
          routePoints: routePoints,
        ),
        const SizedBox(height: 16),
        _AutomationRoutingInfo(
          isExpanded: _showRoutingInfo,
          onToggle: () {
            setState(() {
              _showRoutingInfo = !_showRoutingInfo;
            });
          },
          autoRouteRotationEnabled: appProvider.autoRouteRotationEnabled,
          nearestRelayFallbackEnabled: appProvider.nearestRelayFallbackEnabled,
          clearPathOnMaxRetry: appProvider.clearPathOnMaxRetry,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final records = List<PathRecord>.from(_pathHistory?.directPaths ?? const [])
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No historical paths for this contact yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    PathRecord? observedRecord;
    for (final record in records) {
      if (record.source == PathRecordSource.observed) {
        observedRecord = record;
        break;
      }
    }
    final remainingRecords = observedRecord == null
        ? records
        : records
              .where((record) => !identical(record, observedRecord))
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              await _pathHistoryService.clearHistoryFor(
                widget.contact.publicKeyHex,
              );
              if (!mounted) return;
              setState(() {
                _pathHistory = _pathHistoryService.historyFor(
                  widget.contact.publicKeyHex,
                );
              });
            },
            child: const Text('Clear history'),
          ),
        ),
        const SizedBox(height: 8),
        if (observedRecord != null) ...[
          _buildHistoryRecordTile(observedRecord, title: AppLocalizations.of(context)!.observedMeshRoute),
          const SizedBox(height: 16),
        ],
        if (remainingRecords.isEmpty)
          Text(
            observedRecord == null
                ? 'No additional route history yet.'
                : 'Observed routes you start using will continue to build history here.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ListView.separated(
            itemCount: remainingRecords.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildHistoryRecordTile(remainingRecords[index]);
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRoute = _effectiveRoute;
    final appProvider = context.watch<AppProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();
    final selfPoint =
        connectionProvider.deviceInfo.advLat != null &&
            connectionProvider.deviceInfo.advLon != null &&
            !(connectionProvider.deviceInfo.advLat == 0 &&
                connectionProvider.deviceInfo.advLon == 0)
        ? LatLng(
            connectionProvider.deviceInfo.advLat! / 1e6,
            connectionProvider.deviceInfo.advLon! / 1e6,
          )
        : null;
    final routeCandidates = _routeCandidates(selfPoint: selfPoint);
    final recipientLocation = widget.contact.displayLocation;
    final recipientPoint = recipientLocation == null
        ? null
        : LatLng(recipientLocation.latitude, recipientLocation.longitude);
    final routePoints = <LatLng>[
      ...?selfPoint == null ? null : [selfPoint],
      ..._selectedMapHops
          .where((contact) => contact.displayLocation != null)
          .map(
            (contact) => LatLng(
              contact.displayLocation!.latitude,
              contact.displayLocation!.longitude,
            ),
          ),
      ...?recipientPoint == null ? null : [recipientPoint],
    ];
    final mapPoints = <LatLng>[
      ...?selfPoint == null ? null : [selfPoint],
      ...?recipientPoint == null ? null : [recipientPoint],
      ...routeCandidates.map(
        (contact) => LatLng(
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        ),
      ),
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Set Path for ${widget.contact.displayName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Build'),
              Tab(text: 'History'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TabBarView(
              children: [
                ListView(
                  children: [
                    _buildBuilderTab(
                      routeCandidates: routeCandidates,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                ListView(
                  children: [
                    _buildHistoryTab(),
                    const SizedBox(height: 24),
                  ],
                ),
                _buildInfoTab(
                  appProvider: appProvider,
                  routeCandidates: routeCandidates,
                  mapPoints: mapPoints,
                  routePoints: routePoints,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              overflowSpacing: 8,
              children: [
                if (widget.contact.routeHasPath)
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(ContactRouteDialogResult.clear()),
                    child: Text(
                      '${AppLocalizations.of(context)!.clearRoute} (${AppLocalizations.of(context)!.flood})',
                    ),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: effectiveRoute == null
                      ? null
                      : () => Navigator.of(context).pop(
                          ContactRouteDialogResult.setWithFallback(
                            effectiveRoute,
                            inferredFallbackLocation:
                                _buildSyntheticFallbackLocation(),
                          ),
                        ),
                  child: Text(AppLocalizations.of(context)!.savePath),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteMarkerDot extends StatelessWidget {
  final String label;
  final Color color;

  const _RouteMarkerDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _AutomationRoutingInfo extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool autoRouteRotationEnabled;
  final bool nearestRelayFallbackEnabled;
  final bool clearPathOnMaxRetry;

  const _AutomationRoutingInfo({
    required this.isExpanded,
    required this.onToggle,
    required this.autoRouteRotationEnabled,
    required this.nearestRelayFallbackEnabled,
    required this.clearPathOnMaxRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatic direct-send routing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Text(
              'Room/contact sends keep one selected path for the whole send chain, retry up to 5 total attempts with 1s, 2s, 4s, and 8s backoff, then try one final nearest repeater if everything else fails.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Public and channel broadcasts are not affected by this automation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: autoRouteRotationEnabled
                      ? 'Auto route rotation on'
                      : 'Auto route rotation off',
                  icon: Icons.swap_horiz,
                ),
                _InfoChip(
                  label: nearestRelayFallbackEnabled
                      ? 'Nearest repeater fallback on'
                      : 'Nearest repeater fallback off',
                  icon: Icons.router,
                ),
                _InfoChip(
                  label: clearPathOnMaxRetry
                      ? 'Clear path on max retry on'
                      : 'Clear path on max retry off',
                  icon: Icons.route,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Shows retry, rotation, and final repeater fallback behavior.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
