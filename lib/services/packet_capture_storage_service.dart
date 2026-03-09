import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ble_packet_log.dart';

class StoredPacketCapture {
  final DateTime timestamp;
  final String direction;
  final int? responseCode;
  final String? description;
  final String rawBase64;
  final int rawSize;
  final double? snrDb;
  final int? rssiDbm;

  const StoredPacketCapture({
    required this.timestamp,
    required this.direction,
    required this.responseCode,
    required this.description,
    required this.rawBase64,
    required this.rawSize,
    required this.snrDb,
    required this.rssiDbm,
  });

  Map<String, dynamic> toJson() {
    return {
      'ts': timestamp.millisecondsSinceEpoch,
      'dir': direction,
      'code': responseCode,
      'desc': description,
      'raw': rawBase64,
      'size': rawSize,
      'snr': snrDb,
      'rssi': rssiDbm,
    };
  }

  static StoredPacketCapture fromJson(Map<String, dynamic> json) {
    return StoredPacketCapture(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['ts'] as num).toInt()),
      direction: (json['dir'] as String?) ?? 'rx',
      responseCode: (json['code'] as num?)?.toInt(),
      description: json['desc'] as String?,
      rawBase64: (json['raw'] as String?) ?? '',
      rawSize: (json['size'] as num?)?.toInt() ?? 0,
      snrDb: (json['snr'] as num?)?.toDouble(),
      rssiDbm: (json['rssi'] as num?)?.toInt(),
    );
  }
}

/// Durable storage for raw BLE packets so future features can consume
/// historical packet bytes across app restarts.
class PacketCaptureStorageService {
  static const String _fileName = 'packet_captures.jsonl';
  static const int _maxStoredPackets = 20000;

  File? _file;

  Future<File> _resolveFile() async {
    if (kIsWeb) {
      throw UnsupportedError('Packet capture file storage is not supported on web');
    }
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    _file = file;
    return file;
  }

  Future<void> appendLogs(List<BlePacketLog> logs) async {
    if (logs.isEmpty) return;
    if (kIsWeb) return;
    try {
      final file = await _resolveFile();
      final sink = file.openWrite(mode: FileMode.append);
      for (final log in logs) {
        final row = StoredPacketCapture(
          timestamp: log.timestamp,
          direction: log.direction.name,
          responseCode: log.responseCode,
          description: log.description,
          rawBase64: base64Encode(log.rawData),
          rawSize: log.rawData.length,
          snrDb: log.logRxDataInfo?.snrDb,
          rssiDbm: log.logRxDataInfo?.rssiDbm,
        );
        sink.writeln(jsonEncode(row.toJson()));
      }
      await sink.flush();
      await sink.close();
      await _pruneIfNeeded(file);
    } catch (e) {
      debugPrint('❌ [PacketCaptureStorage] Failed to append logs: $e');
    }
  }

  Future<List<StoredPacketCapture>> loadRecent({int limit = 500}) async {
    if (kIsWeb) return const [];
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return const [];
      final lines = await file.readAsLines();
      if (lines.isEmpty) return const [];
      final start = lines.length > limit ? lines.length - limit : 0;
      return lines
          .sublist(start)
          .where((l) => l.trim().isNotEmpty)
          .map((l) => StoredPacketCapture.fromJson(jsonDecode(l) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [PacketCaptureStorage] Failed to load recent logs: $e');
      return const [];
    }
  }

  Future<int> count() async {
    if (kIsWeb) return 0;
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return 0;
      final lines = await file.readAsLines();
      return lines.where((l) => l.trim().isNotEmpty).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    try {
      final file = await _resolveFile();
      if (await file.exists()) {
        await file.writeAsString('');
      }
    } catch (e) {
      debugPrint('❌ [PacketCaptureStorage] Failed to clear logs: $e');
    }
  }

  Future<void> _pruneIfNeeded(File file) async {
    final lines = await file.readAsLines();
    if (lines.length <= _maxStoredPackets) return;
    final keep = lines.sublist(lines.length - _maxStoredPackets);
    await file.writeAsString('${keep.join('\n')}\n');
  }
}
