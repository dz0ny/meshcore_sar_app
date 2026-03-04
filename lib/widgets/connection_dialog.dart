import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../services/network_scanner_service.dart';
import '../l10n/app_localizations.dart';

/// Connection Dialog with tabs for BLE devices and Network servers
class ConnectionDialog extends StatefulWidget {
  const ConnectionDialog({super.key});

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NetworkScannerService _networkScanner = NetworkScannerService();
  final List<DiscoveredServer> _discoveredServers = [];
  int _scannedCount = 0;
  int _totalToScan = 0;
  String? _connectingToServerKey; // Track which server is being connected to (ip:port)

  // Named listener method for proper cleanup
  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Switched to network tab
      if (_networkScanner.hasCachedResults && _discoveredServers.isEmpty) {
        // Load cached results
        setState(() {
          _discoveredServers.addAll(_networkScanner.cachedServers);
        });
        debugPrint(
          '📦 [NetworkScanner] Loaded ${_discoveredServers.length} servers from cache',
        );
      } else if (!_networkScanner.isScanning &&
          !_networkScanner.hasCachedResults) {
        // No cache, start initial scan
        _startNetworkScan();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Start BLE scan by default
    final connectionProvider = Provider.of<ConnectionProvider>(
      context,
      listen: false,
    );
    connectionProvider.startScan();

    // Set up network scanner callbacks
    _networkScanner.onServerDiscovered = (server) {
      if (mounted) {
        setState(() {
          // Only add if not already in the list (deduplicate)
          if (!_discoveredServers.contains(server)) {
            _discoveredServers.add(server);
          }
        });
      }
    };

    _networkScanner.onProgressUpdate = (scanned, total) {
      if (mounted) {
        setState(() {
          _scannedCount = scanned;
          _totalToScan = total;
        });
      }
    };

    // Listen to tab changes using named method for proper cleanup
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    final connectionProvider = Provider.of<ConnectionProvider>(
      context,
      listen: false,
    );
    connectionProvider.stopScan();
    _networkScanner.stopScan();
    // Remove listener before disposing to prevent memory leaks
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _startNetworkScan() {
    setState(() {
      _discoveredServers.clear();
      _scannedCount = 0;
      _totalToScan = 0;
    });
    _networkScanner.clearCache(); // Clear cache before starting new scan
    _networkScanner.scan();
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
                const SizedBox(height: 8),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'BLE Devices', icon: Icon(Icons.bluetooth)),
                    Tab(text: 'Network Servers', icon: Icon(Icons.wifi)),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // BLE Devices Tab
                _buildBleDevicesTab(connectionProvider),

                // Network Servers Tab
                _buildNetworkServersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBleDevicesTab(ConnectionProvider connectionProvider) {
    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.defaultPinInfo,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: () {
                  connectionProvider.stopScan();
                  connectionProvider.startScan();
                },
              ),
            ],
          ),
        ),

        // Device list
        Expanded(
          child:
              connectionProvider.isScanning &&
                  connectionProvider.scannedDevices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : connectionProvider.scannedDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noDevicesFound,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          connectionProvider.stopScan();
                          connectionProvider.startScan();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.scanAgain),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: connectionProvider.scannedDevices.length,
                  itemBuilder: (context, index) {
                    final scannedDevice =
                        connectionProvider.scannedDevices[index];
                    final device = scannedDevice.device;
                    final rssi = scannedDevice.rssi;
                    final signalColor = _getSignalColor(rssi);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.bluetooth,
                          color: signalColor,
                          size: 32,
                        ),
                        title: Text(
                          device.platformName.isNotEmpty
                              ? device.platformName
                              : 'Unknown Device',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.tapToConnect,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$rssi dBm',
                              style: TextStyle(
                                color: signalColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onTap: () async {
                          final appProvider = context.read<AppProvider>();
                          Navigator.pop(context);

                          final success = await connectionProvider.connect(
                            device,
                          );
                          if (success &&
                              connectionProvider.deviceInfo.isConnected) {
                            await appProvider.initialize();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNetworkServersTab() {
    final bool showingCachedResults =
        !_networkScanner.isScanning &&
        _networkScanner.hasCachedResults &&
        _discoveredServers.isNotEmpty;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                showingCachedResults ? Icons.cached : Icons.info_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  showingCachedResults
                      ? 'Showing cached results. Tap refresh to rescan.'
                      : 'Scanning local network for MeshCore WiFi devices on port 5000',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onPressed: _startNetworkScan,
              ),
            ],
          ),
        ),

        // Scan progress
        if (_networkScanner.isScanning)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _totalToScan > 0 ? _scannedCount / _totalToScan : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanning... $_scannedCount/${_totalToScan > 0 ? _totalToScan : "?"} IPs',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

        // Server list
        Expanded(
          child: _networkScanner.isScanning && _discoveredServers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _discoveredServers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No servers found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _startNetworkScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _discoveredServers.length,
                  itemBuilder: (context, index) {
                    final server = _discoveredServers[index];
                    final serverKey = '${server.ipAddress}:${server.port}';
                    final isConnectingToThisServer =
                        _connectingToServerKey == serverKey;
                    final isAnyConnectionInProgress =
                        _connectingToServerKey != null;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConnectingToThisServer
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                          width: isConnectingToThisServer ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: isConnectingToThisServer
                            ? SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : const Icon(
                                Icons.wifi,
                                color: Colors.green,
                                size: 32,
                              ),
                        title: Text(
                          server.ipAddress,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          isConnectingToThisServer
                              ? 'Connecting...'
                              : 'Port ${server.port} • ${server.responseTime}ms',
                          style: TextStyle(
                            color: isConnectingToThisServer
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: isConnectingToThisServer
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isConnectingToThisServer
                            ? null
                            : Icon(
                                Icons.chevron_right,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        enabled: !isAnyConnectionInProgress,
                        onTap: isAnyConnectionInProgress
                            ? null
                            : () async {
                                // Capture context-dependent objects before async operations
                                final connectionProvider = context
                                    .read<ConnectionProvider>();
                                final appProvider = context.read<AppProvider>();
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                // Mark this server as connecting
                                setState(() {
                                  _connectingToServerKey = serverKey;
                                });

                                try {
                                  // Pre-verify server is still available
                                  final isAvailable = await _networkScanner
                                      .verifyServer(server);
                                  if (!isAvailable) {
                                    throw Exception(
                                      'Server at ${server.ipAddress}:${server.port} is no longer available. '
                                      'Please scan again to find active servers.',
                                    );
                                  }

                                  await connectionProvider.connectTcp(
                                    server.ipAddress,
                                    server.port,
                                  );
                                  await appProvider.initialize();

                                  if (mounted) {
                                    navigator.pop();
                                  }
                                } catch (e) {
                                  // Clear connecting state on error
                                  if (mounted) {
                                    setState(() {
                                      _connectingToServerKey = null;
                                    });

                                    // Clean up error message (remove "Exception: " prefix)
                                    String errorMessage = e.toString();
                                    if (errorMessage.startsWith(
                                      'Exception: ',
                                    )) {
                                      errorMessage = errorMessage.substring(
                                        'Exception: '.length,
                                      );
                                    }
                                    if (errorMessage.startsWith(
                                      'Connection failed: Exception: ',
                                    )) {
                                      errorMessage = errorMessage.substring(
                                        'Connection failed: Exception: '.length,
                                      );
                                    } else if (errorMessage.startsWith(
                                      'Connection failed: ',
                                    )) {
                                      errorMessage = errorMessage.substring(
                                        'Connection failed: '.length,
                                      );
                                    }

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
