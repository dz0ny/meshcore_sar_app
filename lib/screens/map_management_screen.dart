import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import '../services/tile_cache_service.dart';
import '../services/validation_service.dart';
import '../services/mbtiles_service.dart';
import '../models/map_layer.dart';
import '../l10n/app_localizations.dart';

class MapManagementScreen extends StatefulWidget {
  final TileCacheService tileCacheService;
  final MapLayer? initialLayer;
  final LatLngBounds? initialBounds;
  final int? initialZoom;

  const MapManagementScreen({
    super.key,
    required this.tileCacheService,
    this.initialLayer,
    this.initialBounds,
    this.initialZoom,
  });

  @override
  State<MapManagementScreen> createState() => _MapManagementScreenState();
}

class _MapManagementScreenState extends State<MapManagementScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _cacheStats;
  final MbtilesService _mbtilesService = MbtilesService();
  List<MbtilesMetadata> _mbtilesFiles = [];

  // Download parameters
  late MapLayer _selectedLayer;
  late TextEditingController _northController;
  late TextEditingController _southController;
  late TextEditingController _eastController;
  late TextEditingController _westController;
  late int _minZoom;
  late int _maxZoom;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with provided values or defaults
    _selectedLayer = widget.initialLayer ?? MapLayer.openStreetMap;

    if (widget.initialBounds != null) {
      _northController = TextEditingController(
        text: widget.initialBounds!.north.toStringAsFixed(4),
      );
      _southController = TextEditingController(
        text: widget.initialBounds!.south.toStringAsFixed(4),
      );
      _eastController = TextEditingController(
        text: widget.initialBounds!.east.toStringAsFixed(4),
      );
      _westController = TextEditingController(
        text: widget.initialBounds!.west.toStringAsFixed(4),
      );
    } else {
      _northController = TextEditingController(text: '46.1');
      _southController = TextEditingController(text: '46.0');
      _eastController = TextEditingController(text: '14.6');
      _westController = TextEditingController(text: '14.4');
    }

    // Set zoom levels
    if (widget.initialZoom != null) {
      _minZoom = (widget.initialZoom! - 2).clamp(1, 19);
      _maxZoom = (widget.initialZoom! + 2).clamp(1, 19);
    } else {
      _minZoom = 10;
      _maxZoom = 16;
    }

    _loadCacheStats();
    _loadMbtilesFiles();
  }

  @override
  void dispose() {
    _northController.dispose();
    _southController.dispose();
    _eastController.dispose();
    _westController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await widget.tileCacheService.getStoreStats();
      if (!mounted) return;
      setState(() {
        _cacheStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = AppLocalizations.of(context)!.errorLoadingStats(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMbtilesFiles() async {
    if (!mounted) return;
    try {
      final files = await _mbtilesService.getAllMetadata();
      if (!mounted) return;
      setState(() {
        _mbtilesFiles = files;
      });
    } catch (e) {
      debugPrint('Error loading MBTiles files: $e');
    }
  }

  Future<void> _importMbtilesFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mbtiles'],
      );

      if (result == null || result.files.isEmpty) return;

      final sourcePath = result.files.first.path;
      if (sourcePath == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);

      final importedFile = await _mbtilesService.importMbtilesFile(sourcePath);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (importedFile != null) {
        await _loadMbtilesFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mbtilesImportedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError(AppLocalizations.of(context)!.failedToImportMbtiles);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('${AppLocalizations.of(context)!.failedToImportMbtiles}: $e');
    }
  }

  Future<void> _deleteMbtilesFile(MbtilesMetadata metadata) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMbtilesConfirmTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteMbtilesConfirmMessage(metadata.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final success = await _mbtilesService.deleteMbtilesFile(metadata.file);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        await _loadMbtilesFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mbtilesDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError(AppLocalizations.of(context)!.failedToDeleteMbtiles);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('${AppLocalizations.of(context)!.failedToDeleteMbtiles}: $e');
    }
  }

  Future<void> _downloadRegion() async {
    final validator = ValidationService();

    try {
      // Parse coordinates
      final north = double.tryParse(_northController.text);
      final south = double.tryParse(_southController.text);
      final east = double.tryParse(_eastController.text);
      final west = double.tryParse(_westController.text);

      // Validate bounds
      final boundsResult = validator.validateBounds(
        north: north,
        south: south,
        east: east,
        west: west,
      );

      if (!boundsResult.isValid) {
        _showError(boundsResult.errorMessage!);
        return;
      }

      // Validate zoom levels
      final minZoomResult = validator.validateZoomLevel(_minZoom);
      if (!minZoomResult.isValid) {
        _showError(AppLocalizations.of(context)!.minZoomError(minZoomResult.errorMessage!));
        return;
      }

      final maxZoomResult = validator.validateZoomLevel(_maxZoom);
      if (!maxZoomResult.isValid) {
        _showError(AppLocalizations.of(context)!.maxZoomError(maxZoomResult.errorMessage!));
        return;
      }

      if (_minZoom > _maxZoom) {
        _showError(AppLocalizations.of(context)!.minZoomGreaterThanMax);
        return;
      }

      final bounds = LatLngBounds(
        LatLng(south!, west!),
        LatLng(north!, east!),
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _statusMessage = AppLocalizations.of(context)!.startingDownload;
      });

      await widget.tileCacheService.downloadRegion(
        layer: _selectedLayer,
        bounds: bounds,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onProgress: (progress) {
          debugPrint('UI received progress update: $progress%');
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
            _statusMessage = AppLocalizations.of(context)!.downloadingMapTiles;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = AppLocalizations.of(context)!.downloadCompletedSuccessfully;
      });

      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mapDownloadCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = AppLocalizations.of(context)!.downloadFailed(e.toString());
      });
      _showError(AppLocalizations.of(context)!.downloadFailed(e.toString()));
    }
  }

  Future<void> _cancelDownload() async {
    try {
      if (!mounted) return;
      setState(() => _statusMessage = AppLocalizations.of(context)!.cancellingDownload);

      await widget.tileCacheService.cancelDownload();

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = AppLocalizations.of(context)!.downloadCancelled;
      });

      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cancel),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = AppLocalizations.of(context)!.cancelFailed(e.toString());
      });
      _showError(AppLocalizations.of(context)!.cancelFailed(e.toString()));
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearMapsConfirmTitle),
        content: Text(
          AppLocalizations.of(context)!.clearMapsConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.clear),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await widget.tileCacheService.clearCache();
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cacheClearedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(AppLocalizations.of(context)!.clearCacheFailed(e.toString()));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mapManagement),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cache Statistics
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),

                  // Offline Vector Maps (MBTiles)
                  _buildMbtilesCard(),
                  const SizedBox(height: 16),

                  // Download Region
                  _buildDownloadCard(),
                  const SizedBox(height: 16),

                  // Clear Cache
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.cacheStatistics,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadCacheStats,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cacheStats != null) ...[
              _buildStatRow(
                AppLocalizations.of(context)!.totalTiles,
                '${_cacheStats!['tileCount'] ?? 0}',
                Icons.grid_on,
              ),
              _buildStatRow(
                AppLocalizations.of(context)!.cacheSize,
                '${(_cacheStats!['sizeMB'] ?? 0.0).toStringAsFixed(2)} MB',
                Icons.storage,
              ),
              _buildStatRow(
                AppLocalizations.of(context)!.storeName,
                _cacheStats!['storeName'] ?? 'Unknown',
                Icons.folder,
              ),
            ] else
              Text(AppLocalizations.of(context)!.noCacheStatistics),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMbtilesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.offlineVectorMaps,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMbtilesFiles,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.offlineVectorMapsDescription,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // List of MBTiles files
            if (_mbtilesFiles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.noMbtilesFiles,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._mbtilesFiles.map((metadata) => Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: Icon(
                        metadata.isVector ? Icons.layers : Icons.image,
                        color: metadata.isVector ? Colors.blue : Colors.orange,
                      ),
                      title: Text(
                        metadata.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${metadata.fileSizeFormatted} • ${metadata.format?.toUpperCase() ?? "Unknown"}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (metadata.description != null) ...[
                                Text(
                                  metadata.description!,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildInfoRow(
                                AppLocalizations.of(context)!.zoomLevels,
                                '${metadata.minZoom ?? "?"} - ${metadata.maxZoom ?? "?"}',
                              ),
                              if (metadata.bounds != null)
                                _buildInfoRow(
                                  AppLocalizations.of(context)!.bounds,
                                  metadata.bounds!,
                                ),
                              if (metadata.isVector) ...[
                                _buildInfoRow(
                                  AppLocalizations.of(context)!.type,
                                  AppLocalizations.of(context)!.vectorTiles,
                                ),
                                _buildInfoRow(
                                  AppLocalizations.of(context)!.schema,
                                  _mbtilesService.getVectorSchema(metadata) ??
                                    AppLocalizations.of(context)!.unknown,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _deleteMbtilesFile(metadata),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: Text(
                                      AppLocalizations.of(context)!.delete,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 16),

            // Import button
            ElevatedButton.icon(
              onPressed: _importMbtilesFile,
              icon: const Icon(Icons.file_upload),
              label: Text(AppLocalizations.of(context)!.importMbtiles),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.importMbtilesNote,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.downloadRegion,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Map Layer Selection
            DropdownButtonFormField<MapLayer>(
              value: _selectedLayer,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.mapLayer,
                border: const OutlineInputBorder(),
              ),
              items: MapLayer.allLayers.map((layer) {
                return DropdownMenuItem(
                  value: layer,
                  child: Text(layer.getLocalizedName(context)),
                );
              }).toList(),
              onChanged: _isDownloading ? null : (layer) {
                if (layer != null) {
                  setState(() => _selectedLayer = layer);
                }
              },
            ),
            const SizedBox(height: 16),

            // Coordinates
            Text(
              AppLocalizations.of(context)!.regionBounds,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _northController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.north,
                      border: const OutlineInputBorder(),
                      hintText: '46.1',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _southController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.south,
                      border: const OutlineInputBorder(),
                      hintText: '46.0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _eastController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.east,
                      border: const OutlineInputBorder(),
                      hintText: '14.6',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _westController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.west,
                      border: const OutlineInputBorder(),
                      hintText: '14.4',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Zoom Levels
            Text(
              AppLocalizations.of(context)!.zoomLevels,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.minZoom(_minZoom)),
                      Slider(
                        value: _minZoom.toDouble(),
                        min: 1,
                        max: 19,
                        divisions: 18,
                        label: '$_minZoom',
                        onChanged: _isDownloading ? null : (value) {
                          setState(() {
                            _minZoom = value.toInt();
                            if (_minZoom > _maxZoom) {
                              _maxZoom = _minZoom;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.maxZoom(_maxZoom)),
                      Slider(
                        value: _maxZoom.toDouble(),
                        min: 1,
                        max: 19,
                        divisions: 18,
                        label: '$_maxZoom',
                        onChanged: _isDownloading ? null : (value) {
                          setState(() {
                            _maxZoom = value.toInt();
                            if (_maxZoom < _minZoom) {
                              _minZoom = _maxZoom;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Download Progress
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _statusMessage ?? AppLocalizations.of(context)!.downloadingDots,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_downloadProgress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadProgress / 100,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Download/Cancel Button
            if (_isDownloading)
              ElevatedButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(Icons.cancel),
                label: Text(AppLocalizations.of(context)!.cancelDownload),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _downloadRegion,
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.of(context)!.downloadRegionButton),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.downloadNote,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.cacheManagement,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Clear Cache Button
            OutlinedButton.icon(
              onPressed: _isDownloading ? null : _clearCache,
              icon: const Icon(Icons.delete_forever),
              label: Text(AppLocalizations.of(context)!.clearAllMaps),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
