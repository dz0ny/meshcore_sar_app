import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../services/mesh_map_nodes_service.dart';

class RepeatersMapScreen extends StatefulWidget {
  const RepeatersMapScreen({super.key});

  @override
  State<RepeatersMapScreen> createState() => _RepeatersMapScreenState();
}

class _RepeatersMapScreenState extends State<RepeatersMapScreen> {
  static const LatLng _fallbackCenter = LatLng(46.0569, 14.5058);
  static const double _fallbackZoom = 7;
  static const double _myLocationZoom = 14;

  final flutter_map.MapController _mapController = flutter_map.MapController();

  List<MeshMapNode> _onlineRepeaters = const [];
  bool _isLoading = true;
  bool _didFitCamera = false;
  String? _error;
  double _currentZoom = _fallbackZoom;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _loadRepeaters();
  }

  Future<void> _loadRepeaters({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (forceRefresh) {
        _didFitCamera = false;
      }
    });

    try {
      final nodes = await MeshMapNodesService.fetchNodes(
        forceRefresh: forceRefresh,
      );
      final repeaters = nodes.where(MeshMapNodesService.isRepeater).toList();

      if (!mounted) return;
      setState(() {
        _onlineRepeaters = repeaters;
        _isLoading = false;
      });
      _refreshMyLocation();
    } catch (error) {
      final cached = await MeshMapNodesService.loadCachedNodes();
      final repeaters = cached.where(MeshMapNodesService.isRepeater).toList();

      if (!mounted) return;
      setState(() {
        _onlineRepeaters = repeaters;
        _isLoading = false;
        _error = repeaters.isEmpty
            ? 'Unable to load repeaters right now.'
            : 'Showing cached repeaters. Pull to retry.';
      });
      _refreshMyLocation();
    }
  }

  List<_MapRepeater> _mergeRepeaters({
    required List<MeshMapNode> onlineNodes,
    required List<Contact> contactRepeaters,
  }) {
    final merged = <String, _MapRepeater>{};

    for (final node in onlineNodes) {
      merged[node.publicKey] = _MapRepeater(
        publicKey: node.publicKey,
        name: node.name,
        latitude: node.latitude,
        longitude: node.longitude,
        isFromContacts: false,
        isFromOnline: true,
      );
    }

    for (final contact in contactRepeaters) {
      final location = contact.displayLocation;
      if (location == null) {
        continue;
      }

      final key = contact.publicKeyHex.toLowerCase();
      final existing = merged[key];
      merged[key] = _MapRepeater(
        publicKey: key,
        name: contact.displayName.isNotEmpty
            ? contact.displayName
            : existing?.name ?? 'Unknown repeater',
        latitude: existing?.latitude ?? location.latitude,
        longitude: existing?.longitude ?? location.longitude,
        isFromContacts: true,
        isFromOnline: existing?.isFromOnline ?? false,
      );
    }

    final repeaters = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return repeaters;
  }

  Future<void> _refreshMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Best effort only.
    }
  }

  void _fitCameraIfNeeded(List<_MapRepeater> repeaters) {
    if (_didFitCamera || repeaters.isEmpty || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didFitCamera || repeaters.isEmpty) {
        return;
      }

      if (repeaters.length == 1) {
        final repeater = repeaters.first;
        _mapController.move(LatLng(repeater.latitude, repeater.longitude), 13);
        _currentZoom = 13;
      } else {
        final bounds = flutter_map.LatLngBounds.fromPoints(
          repeaters
              .map((node) => LatLng(node.latitude, node.longitude))
              .toList(),
        );
        _mapController.fitCamera(
          flutter_map.CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ),
        );
      }

      _didFitCamera = true;
    });
  }

  void _showRepeaterDetails(_MapRepeater repeater) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repeater.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _InfoLine(
                label: 'Public key',
                value: repeater.publicKey,
                monospace: true,
              ),
              _InfoLine(
                label: 'Coordinates',
                value:
                    '${repeater.latitude.toStringAsFixed(5)}, ${repeater.longitude.toStringAsFixed(5)}',
              ),
              _InfoLine(label: 'Source', value: repeater.sourceLabel),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final repeaters = _mergeRepeaters(
      onlineNodes: _onlineRepeaters,
      contactRepeaters: contactsProvider.repeaters,
    );
    _fitCameraIfNeeded(repeaters);
    final clusters = _buildClusters(repeaters);
    final markers = clusters.map((cluster) {
      final markerColor = switch (cluster.status) {
        _ClusterStatus.contactsOnly => const Color(0xFF7C3AED),
        _ClusterStatus.onlineOnly => const Color(0xFFE8681D),
        _ClusterStatus.both => const Color(0xFF1B8F4F),
        _ClusterStatus.mixed => const Color(0xFF2563EB),
      };

      if (cluster.members.length == 1) {
        final repeater = cluster.members.first;
        return flutter_map.Marker(
          point: cluster.center,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showRepeaterDetails(repeater),
            child: _RepeaterMarker(color: markerColor),
          ),
        );
      }

      return flutter_map.Marker(
        point: cluster.center,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _zoomToCluster(cluster),
          child: _ClusterMarker(
            color: markerColor,
            count: cluster.members.length,
          ),
        ),
      );
    }).toList();
    final allMarkers = <flutter_map.Marker>[
      ...markers,
      if (_myLocation != null)
        flutter_map.Marker(
          point: _myLocation!,
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repeaters Map'),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : () => _loadRepeaters(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          flutter_map.FlutterMap(
            mapController: _mapController,
            options: flutter_map.MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: _fallbackZoom,
              onPositionChanged: (camera, hasGesture) {
                final nextZoom = camera.zoom;
                if (nextZoom != _currentZoom && mounted) {
                  setState(() {
                    _currentZoom = nextZoom;
                  });
                }
              },
            ),
            children: [
              flutter_map.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.meshcore.sar',
              ),
              flutter_map.MarkerLayer(markers: allMarkers),
            ],
          ),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(_error!),
                ),
              ),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && repeaters.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? 'No repeaters available.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (repeaters.isNotEmpty)
            Positioned(
              left: 16,
              top: _error == null ? 16 : 72,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _LegendRow(
                        color: Color(0xFF7C3AED),
                        label: 'From contacts',
                      ),
                      SizedBox(height: 8),
                      _LegendRow(
                        color: Color(0xFFE8681D),
                        label: 'Online only',
                      ),
                      SizedBox(height: 8),
                      _LegendRow(color: Color(0xFF1B8F4F), label: 'In both'),
                    ],
                  ),
                ),
              ),
            ),
          if (repeaters.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    '${repeaters.length} repeaters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _jumpToMyLocation,
        tooltip: 'My location',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _jumpToMyLocation() async {
    await _refreshMyLocation();
    final myLocation = _myLocation;
    if (!mounted || myLocation == null) {
      return;
    }

    _mapController.move(myLocation, _myLocationZoom);
    setState(() {
      _currentZoom = _myLocationZoom;
    });
  }

  List<_RepeaterCluster> _buildClusters(List<_MapRepeater> repeaters) {
    if (repeaters.isEmpty) {
      return const [];
    }

    if (_currentZoom >= 11.5) {
      return repeaters
          .map(
            (repeater) => _RepeaterCluster(
              members: [repeater],
              center: LatLng(repeater.latitude, repeater.longitude),
              status: repeater.clusterStatus,
            ),
          )
          .toList();
    }

    final cellSize = _gridSizeForZoom(_currentZoom);
    final buckets = <String, List<_MapRepeater>>{};

    for (final repeater in repeaters) {
      final latBucket = (repeater.latitude / cellSize).floor();
      final lonBucket = (repeater.longitude / cellSize).floor();
      final key = '$latBucket:$lonBucket';
      buckets.putIfAbsent(key, () => <_MapRepeater>[]).add(repeater);
    }

    return buckets.values.map((members) {
      final centerLat =
          members.map((node) => node.latitude).reduce((a, b) => a + b) /
          members.length;
      final centerLon =
          members.map((node) => node.longitude).reduce((a, b) => a + b) /
          members.length;
      final statuses = members.map((node) => node.clusterStatus).toSet();
      return _RepeaterCluster(
        members: members,
        center: LatLng(centerLat, centerLon),
        status: statuses.length == 1 ? statuses.first : _ClusterStatus.mixed,
      );
    }).toList();
  }

  double _gridSizeForZoom(double zoom) {
    if (zoom < 5) return 3.0;
    if (zoom < 7) return 1.5;
    if (zoom < 9) return 0.7;
    if (zoom < 10.5) return 0.28;
    return 0.12;
  }

  void _zoomToCluster(_RepeaterCluster cluster) {
    if (cluster.members.isEmpty) {
      return;
    }

    final bounds = flutter_map.LatLngBounds.fromPoints(
      cluster.members
          .map((node) => LatLng(node.latitude, node.longitude))
          .toList(),
    );
    _mapController.fitCamera(
      flutter_map.CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
        maxZoom: (_currentZoom + 2).clamp(8, 14),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _InfoLine({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: monospace
                  ? const TextStyle(fontFamily: 'monospace')
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _RepeaterMarker extends StatelessWidget {
  final Color color;

  const _RepeaterMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.router, color: Colors.white, size: 18),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  final Color color;
  final int count;

  const _ClusterMarker({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

enum _ClusterStatus { contactsOnly, onlineOnly, both, mixed }

class _RepeaterCluster {
  final List<_MapRepeater> members;
  final LatLng center;
  final _ClusterStatus status;

  const _RepeaterCluster({
    required this.members,
    required this.center,
    required this.status,
  });
}

class _MapRepeater {
  final String publicKey;
  final String name;
  final double latitude;
  final double longitude;
  final bool isFromContacts;
  final bool isFromOnline;

  const _MapRepeater({
    required this.publicKey,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isFromContacts,
    required this.isFromOnline,
  });

  String get sourceLabel {
    if (isFromContacts && isFromOnline) return 'Contacts and online';
    if (isFromContacts) return 'Contacts';
    return 'Online';
  }

  _ClusterStatus get clusterStatus {
    if (isFromContacts && isFromOnline) return _ClusterStatus.both;
    if (isFromContacts) return _ClusterStatus.contactsOnly;
    return _ClusterStatus.onlineOnly;
  }
}
