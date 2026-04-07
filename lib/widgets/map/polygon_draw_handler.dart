import 'dart:math' show log, ln2;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/offline_tiles_provider.dart';

/// Renders polygon/rectangle drawing interaction on the map.
///
/// Shows completed polygons, in-progress vertices, and handles tap events.
class PolygonDrawLayer extends StatelessWidget {
  const PolygonDrawLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineTilesProvider>(
      builder: (context, provider, _) {
        final polygons = <Polygon>[];
        final markers = <Marker>[];

        // Completed polygons
        for (int i = 0; i < provider.polygons.length; i++) {
          final poly = provider.polygons[i];
          polygons.add(Polygon(
            points: poly,
            color: Colors.blue.withValues(alpha: 0.2),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
          ));
        }

        // In-progress polygon vertices
        if (provider.drawingMode == DrawingMode.polygon &&
            provider.currentVertices.isNotEmpty) {
          final verts = provider.currentVertices;

          // Draw lines between vertices
          if (verts.length >= 2) {
            polygons.add(Polygon(
              points: verts,
              color: Colors.orange.withValues(alpha: 0.1),
              borderColor: Colors.orange,
              borderStrokeWidth: 2,
            ));
          }

          // Draw vertex markers
          for (final v in verts) {
            markers.add(Marker(
              point: v,
              width: 12,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ));
          }
        }

        // Rectangle first corner marker
        if (provider.drawingMode == DrawingMode.rectangle &&
            provider.rectangleFirstCorner != null) {
          markers.add(Marker(
            point: provider.rectangleFirstCorner!,
            width: 14,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.rectangle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ));
        }

        return Stack(
          children: [
            if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }
}

/// Renders the download progress overlay tiles.
class DownloadProgressLayer extends StatelessWidget {
  const DownloadProgressLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineTilesProvider>(
      builder: (context, provider, _) {
        if (provider.tileOverlays.isEmpty) return const SizedBox.shrink();

        final polygons = provider.tileOverlays.map((overlay) {
          return Polygon(
            points: [
              LatLng(overlay.north, overlay.west),
              LatLng(overlay.north, overlay.east),
              LatLng(overlay.south, overlay.east),
              LatLng(overlay.south, overlay.west),
            ],
            color: overlay.isSkipped
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.15),
            borderColor:
                overlay.isSkipped ? Colors.green : Colors.orange,
            borderStrokeWidth: 1,
          );
        }).toList();

        return PolygonLayer(polygons: polygons);
      },
    );
  }
}

/// Renders the coverage overlay for a cached style.
///
/// Only renders tiles at the zoom level closest to the current map zoom
/// to avoid drawing thousands of rectangles at once.
class CoverageLayer extends StatelessWidget {
  final double currentZoom;

  const CoverageLayer({super.key, required this.currentZoom});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineTilesProvider>(
      builder: (context, provider, _) {
        if (provider.coverageOverlays.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter to tiles near the current zoom level to keep rendering fast.
        // Show the zoom level that's <= current map zoom (best visual match).
        final targetZoom = currentZoom.floor();

        // Group overlays by approximate zoom level based on tile size.
        // A tile at zoom z covers roughly (360/2^z) degrees of longitude.
        // We filter by checking if the tile width matches the target zoom.
        final filtered = <Polygon>[];
        for (final overlay in provider.coverageOverlays) {
          // Estimate the zoom level from the tile's longitude span
          final lonSpan = (overlay.east - overlay.west).abs();
          if (lonSpan <= 0) continue;
          final estimatedZoom = (log(360.0 / lonSpan) / ln2).round();

          if (estimatedZoom == targetZoom ||
              estimatedZoom == targetZoom - 1 ||
              estimatedZoom == targetZoom + 1) {
            filtered.add(Polygon(
              points: [
                LatLng(overlay.north, overlay.west),
                LatLng(overlay.north, overlay.east),
                LatLng(overlay.south, overlay.east),
                LatLng(overlay.south, overlay.west),
              ],
              color: Colors.blue.withValues(alpha: 0.1),
              borderColor: Colors.blue.withValues(alpha: 0.4),
              borderStrokeWidth: 1,
            ));
          }

          // Cap at 1000 visible tiles to avoid jank
          if (filtered.length >= 1000) break;
        }

        if (filtered.isEmpty) return const SizedBox.shrink();
        return PolygonLayer(polygons: filtered);
      },
    );
  }
}

/// Toolbar for drawing controls.
class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineTilesProvider>(
      builder: (context, provider, _) {
        if (provider.isDownloading) return const SizedBox.shrink();

        return Positioned(
          right: 16,
          top: 100,
          child: Column(
            children: [
              _ToolButton(
                icon: Icons.crop_square,
                label: AppLocalizations.of(context)!.rectangle,
                isActive: provider.drawingMode == DrawingMode.rectangle,
                onTap: () => provider.setDrawingMode(
                  provider.drawingMode == DrawingMode.rectangle
                      ? DrawingMode.none
                      : DrawingMode.rectangle,
                ),
              ),
              const SizedBox(height: 8),
              _ToolButton(
                icon: Icons.pentagon_outlined,
                label: AppLocalizations.of(context)!.polygon,
                isActive: provider.drawingMode == DrawingMode.polygon,
                onTap: () => provider.setDrawingMode(
                  provider.drawingMode == DrawingMode.polygon
                      ? DrawingMode.none
                      : DrawingMode.polygon,
                ),
              ),
              if (provider.drawingMode == DrawingMode.polygon &&
                  provider.currentVertices.length >= 3) ...[
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.check,
                  label: AppLocalizations.of(context)!.finish,
                  isActive: false,
                  color: Colors.green,
                  onTap: () => provider.finishPolygon(),
                ),
              ],
              if (provider.drawingMode == DrawingMode.polygon &&
                  provider.currentVertices.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.undo,
                  label: AppLocalizations.of(context)!.undo,
                  isActive: false,
                  onTap: () => provider.undoLastVertex(),
                ),
              ],
              if (provider.hasPolygons) ...[
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context)!.clear,
                  isActive: false,
                  color: Colors.red,
                  onTap: () => provider.clearPolygons(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.primary;

    return Tooltip(
      message: label,
      child: Material(
        elevation: 2,
        shape: const CircleBorder(),
        color: isActive ? activeColor : theme.colorScheme.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : (color ?? theme.colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
