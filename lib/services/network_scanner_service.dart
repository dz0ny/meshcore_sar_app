import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

/// Discovered MeshCore device on the network (TCP/WiFi)
class DiscoveredServer {
  final String name;
  final String ipAddress;
  final int port;
  final int responseTime; // milliseconds

  const DiscoveredServer({
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.responseTime,
  });

  String get displayName => name.trim().isNotEmpty ? name.trim() : ipAddress;

  @override
  String toString() =>
      'DiscoveredServer($displayName @ $ipAddress:$port, ${responseTime}ms)';

  @override
  bool operator ==(Object other) =>
      other is DiscoveredServer &&
      other.ipAddress == ipAddress &&
      other.port == port;

  @override
  int get hashCode => Object.hash(ipAddress, port);
}

/// Discovers MeshCore devices running the TCP/WiFi server (port 5000).
///
/// First tries mDNS/Bonjour (_meshcore._tcp), then falls back to a parallel
/// TCP-connect port scan of the local /24 subnet.
class NetworkScannerService {
  static const int defaultPort = 5000;
  static const String serviceType = '_meshcore._tcp';
  static const int parallelScans = 20;
  static const Duration connectTimeout = Duration(seconds: 2);
  static const Duration bonjourTimeout = Duration(seconds: 5);

  Discovery? _activeDiscovery;

  Function(DiscoveredServer)? onServerDiscovered;
  Function(int scanned, int total)? onProgressUpdate;

  bool _isScanning = false;
  bool get isScanning => _isScanning;
  int _scanSession = 0;

  List<DiscoveredServer> _cachedServers = [];
  List<DiscoveredServer> get cachedServers => List.unmodifiable(_cachedServers);
  bool get hasCachedResults => _cachedServers.isNotEmpty;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Set<String>> _getLocalIpAddresses() async {
    final ips = <String>{};
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4) ips.add(addr.address);
        }
      }
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Error getting local IPs: $e');
    }
    return ips;
  }

  Future<List<String>> _getLocalNetworkRange() async {
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              debugPrint('📡 [NetworkScanner] Scanning subnet $subnet.0/24');
              return [for (int i = 1; i <= 254; i++) '$subnet.$i'];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Error getting network range: $e');
    }
    return [];
  }

  /// Try a raw TCP connect to check if the MeshCore TCP server is listening.
  Future<DiscoveredServer?> _checkDevice(
    String ip,
    int port, {
    String? name,
  }) async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        ip,
        port,
        timeout: connectTimeout,
      );
      sw.stop();
      debugPrint(
          '✅ [NetworkScanner] Found device at $ip:$port (${sw.elapsedMilliseconds}ms)');
      return DiscoveredServer(
        name: (name ?? ip).trim(),
        ipAddress: ip,
        port: port,
        responseTime: sw.elapsedMilliseconds,
      );
    } on SocketException {
      // Connection refused or timed out — no device here
    } catch (e) {
      debugPrint('⚠️ [NetworkScanner] Error checking $ip:$port — $e');
    } finally {
      socket?.destroy();
    }
    return null;
  }

  // ── mDNS discovery ─────────────────────────────────────────────────────────

  Future<List<DiscoveredServer>> _discoverViaMdns({
    int? port,
    required int scanSession,
  }) async {
    final scanPort = port ?? defaultPort;
    final found = <DiscoveredServer>[];

    try {
      debugPrint('🔍 [NetworkScanner] mDNS discovery for $serviceType...');
      final localIps = await _getLocalIpAddresses();

      _activeDiscovery = await startDiscovery(
        serviceType,
        ipLookupType: IpLookupType.any,
      );

      await Future.delayed(bonjourTimeout);
      if (!_isScanSessionActive(scanSession)) {
        return found;
      }

      for (final service in _activeDiscovery?.services ?? []) {
        if (!_isScanSessionActive(scanSession)) {
          break;
        }
        for (final addr in service.addresses ?? []) {
          if (!_isScanSessionActive(scanSession)) {
            break;
          }
          if (localIps.contains(addr.address)) continue;
          final result =
              await _checkDevice(
                addr.address,
                service.port ?? scanPort,
                name: service.name,
              );
          if (result != null) {
            found.add(result);
            onServerDiscovered?.call(result);
          }
        }
      }

      await stopDiscovery(_activeDiscovery!);
      _activeDiscovery = null;
      debugPrint(
          '✅ [NetworkScanner] mDNS done. Found ${found.length} devices.');
    } catch (e) {
      debugPrint('⚠️ [NetworkScanner] mDNS failed: $e');
      if (_activeDiscovery != null) {
        try {
          await stopDiscovery(_activeDiscovery!);
        } catch (_) {}
        _activeDiscovery = null;
      }
    }

    return found;
  }

  // ── Port scan fallback ─────────────────────────────────────────────────────

  Future<List<DiscoveredServer>> _scanByPort({
    int? port,
    required int scanSession,
  }) async {
    final scanPort = port ?? defaultPort;
    final found = <DiscoveredServer>[];

    final localIps = await _getLocalIpAddresses();
    final ips = await _getLocalNetworkRange();
    if (ips.isEmpty) return [];

    debugPrint(
        '🔍 [NetworkScanner] Port scan: ${ips.length} IPs, port $scanPort');

    int scanned = 0;
    for (int i = 0; i < ips.length && _isScanSessionActive(scanSession); i += parallelScans) {
      final batch = ips.skip(i).take(parallelScans).toList();
      final results =
          await Future.wait(
            batch.map((ip) => _checkDevice(ip, scanPort, name: ip)),
          );

      for (final result in results) {
        if (result != null && !localIps.contains(result.ipAddress)) {
          found.add(result);
          onServerDiscovered?.call(result);
        }
      }

      scanned += batch.length;
      onProgressUpdate?.call(scanned, ips.length);
    }

    return found;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Scan for MeshCore WiFi devices. Tries mDNS first, falls back to port scan.
  Future<List<DiscoveredServer>> scan({int? port}) async {
    if (_isScanning) return [];
    _isScanning = true;
    final scanSession = ++_scanSession;

    try {
      var found = await _discoverViaMdns(port: port, scanSession: scanSession);
      if (_isScanSessionActive(scanSession) && found.isEmpty) {
        debugPrint(
            '🔍 [NetworkScanner] mDNS found nothing, falling back to port scan');
        found = await _scanByPort(port: port, scanSession: scanSession);
      }
      if (_isScanSessionActive(scanSession)) {
        _cachedServers = found;
      }
      return found;
    } finally {
      if (_scanSession == scanSession) {
        _isScanning = false;
      }
    }
  }

  /// Verify a previously discovered device is still reachable.
  Future<bool> verifyServer(DiscoveredServer server) async {
    final result = await _checkDevice(
      server.ipAddress,
      server.port,
      name: server.name,
    );
    return result != null;
  }

  void clearCache() => _cachedServers = [];

  bool _isScanSessionActive(int session) => _isScanning && _scanSession == session;

  void stopScan() {
    _scanSession += 1;
    _isScanning = false;
    final activeDiscovery = _activeDiscovery;
    _activeDiscovery = null;
    if (activeDiscovery != null) {
      unawaited(
        stopDiscovery(activeDiscovery).catchError((Object error) {
          debugPrint('⚠️ [NetworkScanner] Failed to stop mDNS discovery: $error');
        }),
      );
    }
  }
}
