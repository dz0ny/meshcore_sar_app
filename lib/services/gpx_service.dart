import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/location_trail.dart';

/// Service for importing and exporting location trails in GPX format
class GpxService {
  /// Export a LocationTrail to GPX 1.1 format
  /// Returns the GPX content as a string
  static String exportToGpx(LocationTrail trail, {String? customName}) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('gpx', nest: () {
      // GPX attributes
      builder.attribute('version', '1.1');
      builder.attribute('creator', 'MeshCore SAR');
      builder.attribute(
        'xmlns',
        'http://www.topografix.com/GPX/1/1',
      );
      builder.attribute(
        'xmlns:xsi',
        'http://www.w3.org/2001/XMLSchema-instance',
      );
      builder.attribute(
        'xsi:schemaLocation',
        'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd',
      );

      // Metadata section
      builder.element('metadata', nest: () {
        final name = customName ??
            'MeshCore Trail - ${_formatDateTime(trail.startTime)}';
        builder.element('name', nest: () => builder.text(name));
        builder.element(
          'time',
          nest: () => builder.text(trail.startTime.toIso8601String()),
        );

        // Add trail statistics in description
        final distance = trail.totalDistance;
        final duration = trail.duration;
        final description =
            'Distance: ${_formatDistance(distance)}, '
            'Duration: ${_formatDuration(duration)}, '
            'Points: ${trail.points.length}';
        builder.element('desc', nest: () => builder.text(description));
      });

      // Track section
      builder.element('trk', nest: () {
        final trackName = customName ?? 'MeshCore Trail';
        builder.element('name', nest: () => builder.text(trackName));

        // Track segment with all points
        builder.element('trkseg', nest: () {
          for (final point in trail.points) {
            builder.element('trkpt', nest: () {
              builder.attribute('lat', point.position.latitude.toString());
              builder.attribute('lon', point.position.longitude.toString());

              // Timestamp (required for proper GPX)
              builder.element(
                'time',
                nest: () => builder.text(point.timestamp.toIso8601String()),
              );

              // Elevation (optional, set to 0 if not available)
              builder.element('ele', nest: () => builder.text('0'));

              // Extensions for additional data (accuracy, speed)
              if (point.accuracy != null || point.speed != null) {
                builder.element('extensions', nest: () {
                  if (point.accuracy != null) {
                    builder.element(
                      'accuracy',
                      nest: () => builder.text(point.accuracy.toString()),
                    );
                  }
                  if (point.speed != null) {
                    builder.element(
                      'speed',
                      nest: () => builder.text(point.speed.toString()),
                    );
                  }
                });
              }
            });
          }
        });
      });
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  /// Parse GPX content and return a LocationTrail
  /// Throws FormatException if GPX is invalid
  static LocationTrail importFromGpx(String gpxContent) {
    try {
      final document = XmlDocument.parse(gpxContent);
      final gpxElement = document.findElements('gpx').firstOrNull;

      if (gpxElement == null) {
        throw const FormatException('Invalid GPX file: Missing <gpx> element');
      }

      // Extract track name from metadata or track element (currently unused, kept for future use)
      // String? trackName;
      // final metadataName =
      //     gpxElement.findElements('metadata').firstOrNull?.findElements('name').firstOrNull?.innerText;
      // final trackNameElement = gpxElement
      //     .findElements('trk')
      //     .firstOrNull
      //     ?.findElements('name')
      //     .firstOrNull
      //     ?.innerText;
      // trackName = metadataName ?? trackNameElement ?? 'Imported Trail';

      // Extract track points
      final trackPoints = <TrailPoint>[];
      final tracks = gpxElement.findElements('trk');

      if (tracks.isEmpty) {
        throw const FormatException(
          'Invalid GPX file: No <trk> elements found',
        );
      }

      // Process first track only
      final track = tracks.first;
      final segments = track.findElements('trkseg');

      for (final segment in segments) {
        final trkpts = segment.findElements('trkpt');

        for (final trkpt in trkpts) {
          try {
            // Extract latitude and longitude (required)
            final latStr = trkpt.getAttribute('lat');
            final lonStr = trkpt.getAttribute('lon');

            if (latStr == null || lonStr == null) {
              debugPrint('⚠️ Skipping track point: Missing lat/lon attributes');
              continue;
            }

            final lat = double.parse(latStr);
            final lon = double.parse(lonStr);

            // Extract timestamp (optional)
            final timeStr =
                trkpt.findElements('time').firstOrNull?.innerText;
            final timestamp = timeStr != null
                ? DateTime.parse(timeStr)
                : DateTime.now();

            // Extract elevation (optional, currently unused but parsed for future use)
            // final eleStr = trkpt.findElements('ele').firstOrNull?.innerText;
            // final elevation = eleStr != null ? double.tryParse(eleStr) : null;

            // Extract extensions (accuracy, speed)
            double? accuracy;
            double? speed;
            final extensions =
                trkpt.findElements('extensions').firstOrNull;
            if (extensions != null) {
              final accuracyStr =
                  extensions.findElements('accuracy').firstOrNull?.innerText;
              final speedStr =
                  extensions.findElements('speed').firstOrNull?.innerText;
              accuracy = accuracyStr != null ? double.tryParse(accuracyStr) : null;
              speed = speedStr != null ? double.tryParse(speedStr) : null;
            }

            // Create trail point
            trackPoints.add(
              TrailPoint(
                position: LatLng(lat, lon),
                timestamp: timestamp,
                accuracy: accuracy,
                speed: speed,
              ),
            );
          } catch (e) {
            debugPrint('⚠️ Error parsing track point: $e');
            // Continue with next point
          }
        }
      }

      if (trackPoints.isEmpty) {
        throw const FormatException(
          'Invalid GPX file: No valid track points found',
        );
      }

      // Create LocationTrail from parsed points
      final startTime = trackPoints.first.timestamp;
      final endTime = trackPoints.last.timestamp;

      return LocationTrail(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        points: trackPoints,
        startTime: startTime,
        endTime: endTime,
        isActive: false,
      );
    } on XmlException catch (e) {
      throw FormatException('Invalid GPX XML: ${e.message}');
    } catch (e) {
      throw FormatException('Failed to parse GPX file: $e');
    }
  }

  /// Export trail to file and trigger system share sheet
  /// Returns true if successful
  static Future<bool> exportTrailToFile(
    LocationTrail trail, {
    String? customName,
  }) async {
    try {
      // Generate GPX content
      debugPrint('📤 Generating GPX content...');
      final gpxContent = exportToGpx(trail, customName: customName);

      // Create filename with timestamp
      final timestamp = DateTime.now();
      final filename =
          'meshcore_trail_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.gpx';

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(gpxContent);

      debugPrint('📤 GPX file saved: ${file.path}');
      debugPrint('📤 File size: ${file.lengthSync()} bytes');

      // Share the file using system share sheet
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/gpx+xml')],
        subject: 'MeshCore Trail Export',
        text: 'MeshCore SAR location trail (${trail.points.length} points)',
      );

      debugPrint('📤 Share result: ${result.status}');
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.unavailable; // unavailable = user dismissed, still OK

    } catch (e) {
      debugPrint('❌ Failed to export trail: $e');
      return false;
    }
  }

  /// Import trail from GPX file using file picker
  /// Returns LocationTrail if successful, null if cancelled or failed
  static Future<LocationTrail?> importTrailFromFile() async {
    try {
      // Open file picker for GPX files
      debugPrint('📥 Opening file picker for GPX import...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('📥 Import cancelled by user');
        return null;
      }

      final file = result.files.first;
      debugPrint('📥 Selected file: ${file.name}');
      debugPrint('📥 File size: ${file.size} bytes');

      // Read file content
      String gpxContent;
      if (file.path != null) {
        // File has path (mobile)
        gpxContent = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        // File has bytes (web)
        gpxContent = String.fromCharCodes(file.bytes!);
      } else {
        throw Exception('Unable to read file content');
      }

      // Parse GPX content
      debugPrint('📥 Parsing GPX content...');
      final trail = importFromGpx(gpxContent);
      debugPrint(
        '✅ Successfully imported trail: ${trail.points.length} points',
      );

      return trail;
    } catch (e) {
      debugPrint('❌ Failed to import trail: $e');
      rethrow;
    }
  }

  // Helper: Format distance for display
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  // Helper: Format duration for display
  static String _formatDuration(Duration duration) {
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

  // Helper: Format DateTime for filename
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
