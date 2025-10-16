import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mbtiles/mbtiles.dart';

/// Metadata information extracted from an MBTiles file
class MbtilesMetadata {
  final String name;
  final String? description;
  final String? version;
  final String? attribution;
  final String? bounds; // "minLon,minLat,maxLon,maxLat"
  final String? center; // "lon,lat,zoom"
  final int? minZoom;
  final int? maxZoom;
  final String? format; // "pbf", "png", "jpg", etc.
  final String? type; // "overlay", "baselayer"
  final String? json; // Additional metadata JSON
  final File file;
  final int fileSize;

  const MbtilesMetadata({
    required this.name,
    this.description,
    this.version,
    this.attribution,
    this.bounds,
    this.center,
    this.minZoom,
    this.maxZoom,
    this.format,
    this.type,
    this.json,
    required this.file,
    required this.fileSize,
  });

  /// Check if this is a vector tile MBTiles file
  bool get isVector => format == 'pbf' || format == 'mvt';

  /// Parse bounds string into [minLon, minLat, maxLon, maxLat]
  List<double>? get boundsCoordinates {
    if (bounds == null) return null;
    try {
      final parts = bounds!.split(',');
      if (parts.length != 4) return null;
      return parts.map((s) => double.parse(s.trim())).toList();
    } catch (e) {
      debugPrint('Error parsing bounds: $e');
      return null;
    }
  }

  /// Parse center string into [lon, lat, zoom]
  List<double>? get centerCoordinates {
    if (center == null) return null;
    try {
      final parts = center!.split(',');
      if (parts.length < 2) return null;
      return parts.map((s) => double.parse(s.trim())).toList();
    } catch (e) {
      debugPrint('Error parsing center: $e');
      return null;
    }
  }

  /// Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// Service for managing MBTiles files for offline vector maps
class MbtilesService {
  static const String _mbtilesDirectory = 'offline_maps';

  /// Get the directory where MBTiles files are stored
  Future<Directory> getMbtilesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final mbtilesDir = Directory('${appDocDir.path}/$_mbtilesDirectory');

    // Create directory if it doesn't exist
    if (!await mbtilesDir.exists()) {
      await mbtilesDir.create(recursive: true);
    }

    return mbtilesDir;
  }

  /// List all MBTiles files in the offline maps directory
  Future<List<File>> listMbtilesFiles() async {
    final dir = await getMbtilesDirectory();

    try {
      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.mbtiles'))
          .map((entity) => entity as File)
          .toList();

      return files;
    } catch (e) {
      debugPrint('Error listing MBTiles files: $e');
      return [];
    }
  }

  /// Get metadata from an MBTiles file
  Future<MbtilesMetadata?> getMetadata(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('MBTiles file does not exist: ${file.path}');
        return null;
      }

      // Get file size
      final fileSize = await file.length();

      // Open MBTiles file
      final mbtiles = MbTiles(mbtilesPath: file.path);

      // Get metadata from MBTiles
      final metadata = await mbtiles.getMetadata();

      // Convert bounds object to string if available
      String? boundsStr;
      if (metadata.bounds != null) {
        boundsStr = metadata.bounds.toString();
      }

      return MbtilesMetadata(
        name: metadata.name ?? _getFileNameWithoutExtension(file),
        description: metadata.description,
        version: metadata.version?.toString(),
        attribution: null, // Not available in new API
        bounds: boundsStr,
        center: null, // Not available in new API
        minZoom: metadata.minZoom?.toInt(),
        maxZoom: metadata.maxZoom?.toInt(),
        format: metadata.format,
        type: metadata.type?.name,
        json: null, // Not available in new API
        file: file,
        fileSize: fileSize,
      );
    } catch (e) {
      debugPrint('Error reading MBTiles metadata from ${file.path}: $e');
      return null;
    }
  }

  /// Get metadata for all MBTiles files
  Future<List<MbtilesMetadata>> getAllMetadata() async {
    final files = await listMbtilesFiles();
    final metadataList = <MbtilesMetadata>[];

    for (final file in files) {
      final metadata = await getMetadata(file);
      if (metadata != null) {
        metadataList.add(metadata);
      }
    }

    return metadataList;
  }

  /// Import an MBTiles file from an external location
  Future<File?> importMbtilesFile(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);

      // Verify source file exists
      if (!await sourceFile.exists()) {
        debugPrint('Source file does not exist: $sourcePath');
        return null;
      }

      // Get destination directory
      final destDir = await getMbtilesDirectory();
      final fileName = _getFileName(sourceFile);
      final destPath = '${destDir.path}/$fileName';

      // Copy file to destination
      final destFile = await sourceFile.copy(destPath);
      debugPrint('Imported MBTiles file to: $destPath');

      return destFile;
    } catch (e) {
      debugPrint('Error importing MBTiles file: $e');
      return null;
    }
  }

  /// Delete an MBTiles file
  Future<bool> deleteMbtilesFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted MBTiles file: ${file.path}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting MBTiles file: $e');
      return false;
    }
  }

  /// Check if data in MBTiles is gzip compressed
  Future<bool> isGzipCompressed(File file) async {
    try {
      // Open MBTiles and check a sample tile
      final mbtiles = MbTiles(mbtilesPath: file.path);

      // Try to get metadata to check for compression hints
      final metadata = await mbtiles.getMetadata();
      final format = metadata.format;

      // For Geofabrik files, format is 'pbf' and data is gzipped
      // We can infer this from common patterns, but ideally we'd check actual tile data
      if (format == 'pbf') {
        // Geofabrik MBTiles are typically gzipped
        // Could also check tile data headers, but this is a reasonable heuristic
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking gzip compression: $e');
      return false;
    }
  }

  /// Determine the vector tile schema from metadata
  String? getVectorSchema(MbtilesMetadata metadata) {
    // Try to infer schema from metadata
    final json = metadata.json;
    if (json != null) {
      if (json.contains('shortbread')) {
        return 'shortbread';
      } else if (json.contains('openmaptiles')) {
        return 'openmaptiles';
      }
    }

    // Check description
    final description = metadata.description?.toLowerCase();
    if (description != null) {
      if (description.contains('shortbread')) {
        return 'shortbread';
      } else if (description.contains('openmaptiles')) {
        return 'openmaptiles';
      }
    }

    // Default to unknown
    return null;
  }

  /// Helper: Get file name without extension
  String _getFileNameWithoutExtension(File file) {
    final name = _getFileName(file);
    final lastDot = name.lastIndexOf('.');
    return lastDot > 0 ? name.substring(0, lastDot) : name;
  }

  /// Helper: Get file name from path
  String _getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }
}
