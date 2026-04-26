import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location_trail.dart';
import '../../providers/map_provider.dart';
import '../../services/gpx_service.dart';
import '../../l10n/app_localizations.dart';

/// Trail management controls widget
class TrailControls extends StatelessWidget {
  const TrailControls({super.key});

  void _showTrailMenu(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, size: 24),
                    SizedBox(width: 12),
                    Text(
                      l10n.locationTrail,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Trail recording toggle
                SwitchListTile(
                  secondary: Icon(Icons.fiber_manual_record),
                  title: Text('Record location trail'),
                  subtitle: Text(
                    mapProvider.isTrailRecordingEnabled
                        ? 'Trail recording is on'
                        : 'Trail recording is stopped',
                  ),
                  value: mapProvider.isTrailRecordingEnabled,
                  onChanged: (value) {
                    mapProvider.setTrailRecordingEnabled(value);
                    setModalState(() {});
                  },
                ),
                const Divider(),

                // Trail visibility toggle
                SwitchListTile(
                  secondary: Icon(Icons.visibility),
                  title: Text(l10n.showTrailOnMap),
                  subtitle: Text(
                    !mapProvider.isTrailRecordingEnabled
                        ? 'Trail recording is stopped'
                        : (mapProvider.isTrailVisible
                              ? l10n.trailVisible
                              : l10n.trailHiddenRecording),
                  ),
                  value: mapProvider.isTrailVisible,
                  onChanged: (value) {
                    mapProvider.toggleTrailVisibility();
                    setModalState(() {}); // Update modal UI
                  },
                ),
                const Divider(),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _importTrail(context, mapProvider),
                      icon: Icon(Icons.file_upload_outlined),
                      label: Text(l10n.importFromClipboard),
                    ),
                    if (mapProvider.currentTrail != null &&
                        mapProvider.currentTrail!.points.length >= 2)
                      OutlinedButton.icon(
                        onPressed: () => _exportTrail(
                          context,
                          mapProvider.currentTrail!,
                          customName: 'My Trail',
                        ),
                        icon: Icon(Icons.file_download_outlined),
                        label: Text(l10n.exportToClipboard),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Trail stats
                if (mapProvider.currentTrail != null &&
                    mapProvider.currentTrail!.points.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow(
                          icon: Icons.straighten,
                          label: l10n.distance,
                          value: _formatDistance(
                            mapProvider.totalTrailDistance,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildStatRow(
                          icon: Icons.access_time,
                          label: l10n.duration,
                          value: _formatDuration(mapProvider.trailDuration),
                        ),
                        SizedBox(height: 8),
                        _buildStatRow(
                          icon: Icons.place,
                          label: l10n.points,
                          value: '${mapProvider.currentTrail!.points.length}',
                        ),
                      ],
                    ),
                  ),

                // Clear trail button
                if (mapProvider.currentTrail != null &&
                    mapProvider.currentTrail!.points.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showClearConfirmation(context, mapProvider, l10n);
                    },
                    icon: Icon(Icons.delete_outline),
                    label: Text(l10n.clearTrail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                // No trail message
                if (mapProvider.currentTrail == null ||
                    mapProvider.currentTrail!.points.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.timeline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            l10n.noTrailRecorded,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            l10n.startTrackingToRecord,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Close button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importTrail(
    BuildContext context,
    MapProvider mapProvider,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final importedTrail = await GpxService.importTrailFromFile();
      if (importedTrail == null || !context.mounted) {
        return;
      }

      mapProvider.replaceCurrentTrailWithImport(importedTrail);
      mapProvider.clearImportedTrail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.locationTrail}: ${importedTrail.points.length} ${l10n.points.toLowerCase()}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importFailed(error.toString()))),
      );
    }
  }

  Future<void> _exportTrail(
    BuildContext context,
    LocationTrail trail, {
    String? customName,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await GpxService.exportTrailToFile(
        trail,
        customName: customName,
      );
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed('unable to share GPX'))),
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(error.toString()))),
      );
    }
  }

  void _showClearConfirmation(
    BuildContext context,
    MapProvider mapProvider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearTrailQuestion),
        content: Text(l10n.clearTrailConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              mapProvider.clearCurrentTrail();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clearTrail),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.small(
      heroTag: 'trail_controls',
      tooltip: l10n.trailControls,
      onPressed: () => _showTrailMenu(context),
      child: const Icon(Icons.timeline),
    );
  }
}
