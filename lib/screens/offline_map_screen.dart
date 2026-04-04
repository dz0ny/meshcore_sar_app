import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/map_layer.dart';
import '../providers/offline_tiles_provider.dart';
import '../widgets/map/polygon_draw_handler.dart';

/// Screen for downloading offline map tiles.
///
/// Allows drawing polygons/rectangles to select areas, choosing zoom levels,
/// and downloading tiles with real-time progress visualization.
class OfflineMapScreen extends StatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final MapController _mapController = MapController();
  late OfflineTilesProvider _provider;
  double _currentZoom = 8;

  @override
  void initState() {
    super.initState();
    _provider = context.read<OfflineTilesProvider>();
    _provider.refreshCacheSize();
    _provider.refreshLocalStyles();
    _provider.startPeerDiscovery();
  }

  @override
  void dispose() {
    _provider.stopPeerDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
        actions: [
          Consumer<OfflineTilesProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: provider.discoveredPeers.isNotEmpty,
                  label: Text('${provider.discoveredPeers.length}'),
                  child: Icon(
                    provider.isServerRunning
                        ? Icons.wifi_tethering
                        : Icons.wifi_tethering_off,
                  ),
                ),
                tooltip: provider.isServerRunning
                    ? 'Sharing tiles'
                    : 'Tile sharing off',
                onPressed: () => _showSharingSheet(context, provider),
              );
            },
          ),
          Consumer<OfflineTilesProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<MapLayer>(
                icon: const Icon(Icons.layers),
                tooltip: 'Map Style',
                onSelected: (layer) => provider.setSelectedLayer(layer),
                itemBuilder: (_) => [
                  for (final layer in MapLayer.allLayers)
                    PopupMenuItem(
                      value: layer,
                      child: Row(
                        children: [
                          if (layer.type == provider.selectedLayer.type)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(layer.name),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<OfflineTilesProvider>(
            builder: (context, provider, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(46.05, 14.5), // Slovenia
                  initialZoom: 8,
                  onPositionChanged: (camera, hasGesture) {
                    if (camera.zoom != _currentZoom) {
                      setState(() => _currentZoom = camera.zoom);
                    }
                  },
                  onTap: (tapPosition, point) {
                    if (provider.drawingMode != DrawingMode.none) {
                      provider.addVertex(point);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: provider.selectedLayer.urlTemplate,
                    userAgentPackageName: 'com.meshcore.sar',
                    maxZoom: provider.selectedLayer.maxZoom,
                  ),
                  CoverageLayer(currentZoom: _currentZoom),
                  const PolygonDrawLayer(),
                  const DownloadProgressLayer(),
                ],
              );
            },
          ),
          const DrawingToolbar(),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Z ${_currentZoom.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Consumer<OfflineTilesProvider>(
        builder: (context, provider, _) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saved region presets dropdown
                    if (!provider.isDownloading &&
                        provider.localStyles
                            .any((s) => s.region != null)) ...[
                      DropdownButtonFormField<StyleInfo>(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.bookmark, size: 20),
                          labelText: 'Saved regions',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        hint: const Text('Load a saved region'),
                        items: provider.localStyles
                            .where((s) => s.region != null)
                            .map((style) => DropdownMenuItem(
                                  value: style,
                                  child: Text(
                                    '${style.displayName} '
                                    '(z${style.region!.minZoom}-${style.region!.maxZoom}, '
                                    '${_formatNumber(style.tileCount)} tiles)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (style) {
                          if (style != null) {
                            provider.loadPreset(style);
                            _fitMapToPolygons(provider);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Zoom range
                    if (!provider.isDownloading) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ZoomSelector(
                              label: 'Min Zoom',
                              value: provider.minZoom,
                              onChanged: provider.setMinZoom,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ZoomSelector(
                              label: 'Max Zoom',
                              value: provider.maxZoom,
                              onChanged: provider.setMaxZoom,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tile estimate
                      Text(
                        provider.hasPolygons
                            ? '~${_formatNumber(provider.estimatedTileCount)} tiles'
                            : 'Draw an area to download',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cache: ${_formatBytes(provider.cacheSizeBytes)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Progress
                    if (provider.isDownloading) ...[
                      LinearProgressIndicator(
                        value: provider.progress.percent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(provider.progress.percent * 100).toStringAsFixed(1)}% — '
                        'Downloaded: ${provider.progress.downloaded}, '
                        'Cached: ${provider.progress.skipped}, '
                        'Failed: ${provider.progress.failed} / '
                        '${provider.progress.total}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Download complete summary
                    if (!provider.isDownloading &&
                        provider.progress.isComplete) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Done! ${provider.progress.downloaded} downloaded, '
                        '${provider.progress.skipped} cached, '
                        '${provider.progress.failed} failed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        if (!provider.isDownloading) ...[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: provider.hasPolygons
                                  ? () => provider.startDownload()
                                  : null,
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                            ),
                          ),
                          if (provider.tileOverlays.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: provider.clearOverlays,
                              icon: const Icon(Icons.layers_clear),
                              tooltip: 'Clear overlay',
                            ),
                          ],
                          if (provider.cacheSizeBytes > 0) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmClearCache(provider),
                              icon: const Icon(Icons.delete_forever),
                              tooltip: 'Clear cache',
                            ),
                          ],
                        ],
                        if (provider.isDownloading) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => provider.cancelDownload(),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSharingSheet(BuildContext context, OfflineTilesProvider provider) {
    // Refresh catalogs and local styles when opening
    provider.refreshPeerCatalogs();
    provider.refreshLocalStyles();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<OfflineTilesProvider>(
              builder: (context, provider, _) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Tile Sharing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),

                    // Server toggle
                    SwitchListTile(
                      title: const Text('Share my tiles'),
                      subtitle: Text(
                        provider.isServerRunning
                            ? 'Other devices can fetch tiles from this device'
                            : 'Start serving cached tiles to nearby devices',
                      ),
                      secondary: Icon(
                        provider.isServerRunning
                            ? Icons.wifi_tethering
                            : Icons.wifi_tethering_off,
                      ),
                      value: provider.isServerRunning,
                      onChanged: (_) => provider.toggleServer(),
                    ),

                    // My cached maps
                    if (provider.localStyles.isNotEmpty) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'My Cached Maps',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...provider.localStyles.map((style) {
                        final isShowing =
                            provider.coverageStyle?.hash == style.hash;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.map, size: 20),
                          title: Text(style.displayName),
                          subtitle: Text(
                            '${_formatNumber(style.tileCount)} tiles, '
                            '${_formatBytes(style.sizeBytes)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isShowing
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 20,
                                  color: isShowing
                                      ? Colors.blue
                                      : null,
                                ),
                                tooltip: isShowing
                                    ? 'Hide on map'
                                    : 'Show on map',
                                onPressed: () {
                                  provider.showCoverage(style);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDeleteStyle(
                                    context, provider, style),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Peers section
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nearby Devices',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (provider.isFetchingCatalogs)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: 'Refresh',
                              onPressed: () =>
                                  provider.refreshPeerCatalogs(),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            tooltip: 'Add peer manually',
                            onPressed: () =>
                                _showAddPeerDialog(context, provider),
                          ),
                        ],
                      ),
                    ),

                    if (provider.discoveredPeers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No peers found on the local network.\n'
                          'Make sure other devices have tile sharing enabled.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ),

                    // Peer catalogs — show each peer and their available styles
                    ...provider.peerCatalogs.map((catalog) => _buildPeerCard(
                          context, provider, catalog)),

                    // Peers without catalogs yet (just discovered, not queried)
                    ...provider.discoveredPeers
                        .where((peer) => !provider.peerCatalogs
                            .any((c) => c.peer == peer))
                        .map((peer) => ListTile(
                              leading: const Icon(Icons.devices),
                              title: Text(peer.ipAddress),
                              subtitle: const Text('Fetching catalog...'),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: () =>
                                    provider.removePeer(peer),
                              ),
                            )),

                    // Sync progress
                    if (provider.isSyncing || provider.syncStatus.isNotEmpty) ...[
                      const Divider(),
                      if (provider.isSyncing)
                        LinearProgressIndicator(
                          value: provider.syncProgress > 0
                              ? provider.syncProgress
                              : null,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.syncStatus,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (provider.isSyncing)
                              TextButton(
                                onPressed: () => provider.cancelSync(),
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPeerCard(
    BuildContext context,
    OfflineTilesProvider provider,
    PeerCatalog catalog,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    catalog.peer.ipAddress,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  onPressed: () => provider.removePeer(catalog.peer),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (catalog.styles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No cached tiles on this device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ),
            ...catalog.styles.map((style) {
              // Check if we already have this style locally
              final localMatch = provider.localStyles
                  .where((s) => s.hash == style.hash);
              final localCount =
                  localMatch.isNotEmpty ? localMatch.first.tileCount : 0;
              final missingTiles = style.tileCount - localCount;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.map_outlined, size: 20),
                title: Text(style.displayName),
                subtitle: Text(
                  '${_formatNumber(style.tileCount)} tiles, '
                  '${_formatBytes(style.sizeBytes)}'
                  '${localCount > 0 ? ' (you have ${_formatNumberInline(localCount)})' : ''}',
                ),
                trailing: missingTiles > 0
                    ? TextButton.icon(
                        onPressed: provider.isSyncing
                            ? null
                            : () => provider.syncStyleFromPeers(style),
                        icon: const Icon(Icons.download, size: 16),
                        label: Text(
                          missingTiles == style.tileCount
                              ? 'Get all'
                              : '+${_formatNumber(missingTiles)}',
                        ),
                      )
                    : const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatNumberInline(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  void _fitMapToPolygons(OfflineTilesProvider provider) {
    if (provider.polygons.isEmpty) return;

    var minLat = 90.0, maxLat = -90.0;
    var minLng = 180.0, maxLng = -180.0;
    for (final poly in provider.polygons) {
      for (final p in poly) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _showAddPeerDialog(
      BuildContext context, OfflineTilesProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Peer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'IP Address',
            hintText: '192.168.1.100',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addManualPeer(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                provider.addManualPeer(ip);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStyle(
    BuildContext context,
    OfflineTilesProvider provider,
    StyleInfo style,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${style.displayName}?'),
        content: Text(
          '${_formatNumber(style.tileCount)} tiles, '
          '${_formatBytes(style.sizeBytes)} will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteStyle(style);
              Navigator.pop(dialogContext);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache(OfflineTilesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear offline cache?'),
        content: Text(
            'This will delete ${_formatBytes(provider.cacheSizeBytes)} of cached tiles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearCache();
              Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}

class _ZoomSelector extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _ZoomSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 19,
            divisions: 19,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
