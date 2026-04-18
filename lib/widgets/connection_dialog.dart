import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../screens/discovery_screen.dart';
import '../services/network_scanner_service.dart';
import '../services/profile_workspace_coordinator.dart';
import '../services/recent_tcp_connections_service.dart';
import '../services/serial/serial_transport.dart';

enum _ConnectionDialogResult { connected }

class _ManualTcpEndpoint {
  final String host;
  final int port;

  const _ManualTcpEndpoint({required this.host, required this.port});
}

Future<void> _initializeConnectedWorkspace({
  required ProfileWorkspaceCoordinator profileWorkspaceCoordinator,
  required AppProvider appProvider,
}) async {
  await profileWorkspaceCoordinator.syncActiveProfileForCurrentDevice();
  await appProvider.initialize();
}

String _normalizeConnectionError(Object error) {
  var message = error.toString();
  if (message.startsWith('Exception: ')) {
    message = message.substring('Exception: '.length);
  }
  if (message.startsWith('Connection failed: Exception: ')) {
    return message.substring('Connection failed: Exception: '.length);
  }
  if (message.startsWith('Connection failed: ')) {
    return message.substring('Connection failed: '.length);
  }
  return message;
}

void _showConnectionErrorSnackBar(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_normalizeConnectionError(error)),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ),
  );
}

Future<bool> showConnectionDialogFlow(
  BuildContext context, {
  Color? backgroundColor,
  bool offerPostConnectRepeaterDiscovery = false,
}) async {
  final result = await showModalBottomSheet<_ConnectionDialogResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: backgroundColor,
    builder: (context) => const ConnectionDialog(),
  );

  if (result != _ConnectionDialogResult.connected || !context.mounted) {
    return result == _ConnectionDialogResult.connected;
  }

  try {
    await _initializeConnectedWorkspace(
      profileWorkspaceCoordinator: context.read<ProfileWorkspaceCoordinator>(),
      appProvider: context.read<AppProvider>(),
    );
  } catch (error) {
    if (context.mounted) {
      _showConnectionErrorSnackBar(context, error);
    }
  }

  if (!context.mounted) {
    return true;
  }

  if (!offerPostConnectRepeaterDiscovery) {
    return true;
  }

  final contactsProvider = context.read<ContactsProvider>();
  if (contactsProvider.repeaters.isNotEmpty) {
    return true;
  }

  final l10n = AppLocalizations.of(context)!;
  final openDiscovery = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.postConnectDiscoveryTitle),
      content: Text(l10n.postConnectDiscoveryDescription),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.continue_),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.router_outlined),
          label: Text(l10n.discoverRepeaters),
        ),
      ],
    ),
  );

  if (openDiscovery != true || !context.mounted) {
    return true;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) =>
          const DiscoveryScreen(autoDiscoverRepeatersOnOpen: true),
    ),
  );
  return true;
}

/// Connection Dialog with tabs for BLE devices and Network servers
class ConnectionDialog extends StatefulWidget {
  final NetworkScannerService? networkScanner;

  const ConnectionDialog({super.key, this.networkScanner});

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ConnectionProvider _connectionProvider;
  late final NetworkScannerService _networkScanner;
  final List<DiscoveredServer> _discoveredServers = [];
  List<RecentTcpConnection> _recentServers = const <RecentTcpConnection>[];
  int _scannedCount = 0;
  int _totalToScan = 0;
  int _lastTabIndex = 0;
  bool _hasRequestedBleScan = false;
  String? _connectingToServerKey;
  String? _connectingBleDeviceId;

  void _onTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;

    if (_tabController.index == 1) {
      if (_networkScanner.hasCachedResults && _discoveredServers.isEmpty) {
        setState(() {
          _discoveredServers.addAll(_networkScanner.cachedServers);
        });
      } else if (!_networkScanner.isScanning &&
          !_networkScanner.hasCachedResults) {
        _startNetworkScan();
      }
    }
  }

  Future<void> _loadRecentServers() async {
    final recentServers = await RecentTcpConnectionsService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentServers = recentServers;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _connectionProvider = Provider.of<ConnectionProvider>(
      context,
      listen: false,
    );
    _networkScanner = widget.networkScanner ?? NetworkScannerService();

    _networkScanner.onServerDiscovered = (server) {
      if (!mounted) return;
      setState(() {
        if (!_discoveredServers.contains(server)) {
          _discoveredServers.add(server);
        }
      });
    };

    _networkScanner.onProgressUpdate = (scanned, total) {
      if (!mounted) return;
      setState(() {
        _scannedCount = scanned;
        _totalToScan = total;
      });
    };

    _tabController.addListener(_onTabChanged);
    _loadRecentServers();
  }

  @override
  void dispose() {
    _connectionProvider.stopScan();
    _networkScanner.stopScan();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _startNetworkScan() {
    _networkScanner.stopScan();
    setState(() {
      _discoveredServers.clear();
      _scannedCount = 0;
      _totalToScan = 0;
    });
    _networkScanner.clearCache();
    _networkScanner.scan();
  }

  Future<void> _refreshBleDevices() async {
    if (!_hasRequestedBleScan && mounted) {
      setState(() {
        _hasRequestedBleScan = true;
      });
    } else {
      _hasRequestedBleScan = true;
    }
    await _connectionProvider.stopScan();
    if (!mounted) return;
    await _connectionProvider.startScan();
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return Colors.red;
  }

  void _closeOnSuccessfulConnection() {
    if (!mounted) return;
    Navigator.of(context).pop(_ConnectionDialogResult.connected);
  }

  void _showConnectionError(Object error) {
    if (!mounted) return;
    _showConnectionErrorSnackBar(context, error);
  }

  Future<void> _rememberRecentServer({
    required String name,
    required String host,
    required int port,
  }) async {
    final recentServers = await RecentTcpConnectionsService.remember(
      name: name,
      host: host,
      port: port,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _recentServers = recentServers;
    });
  }

  Future<void> _connectTcpEndpoint({
    required String host,
    required int port,
    required String name,
    required String serverKey,
  }) async {
    final connectionProvider = context.read<ConnectionProvider>();

    setState(() {
      _connectingToServerKey = serverKey;
    });

    try {
      final success = await connectionProvider.connectTcp(host, port);
      if (!success) {
        throw Exception(
          connectionProvider.error ?? 'Failed to connect to $host:$port',
        );
      }
      await _rememberRecentServer(name: name, host: host, port: port);
      _closeOnSuccessfulConnection();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connectingToServerKey = null;
      });
      _showConnectionError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Connect Device',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose Bluetooth, WiFi, or Serial transport',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: theme.colorScheme.onPrimaryContainer,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'BLE', icon: Icon(Icons.bluetooth_rounded)),
                    Tab(text: 'Network', icon: Icon(Icons.wifi_rounded)),
                    Tab(text: 'Serial', icon: Icon(Icons.usb_rounded)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBleDevicesTab(connectionProvider),
                _buildNetworkServersTab(),
                _buildUsbTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBanner({
    required IconData icon,
    required String message,
    required VoidCallback onRefresh,
    IconData? secondaryActionIcon,
    String? secondaryActionTooltip,
    VoidCallback? onSecondaryAction,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryActionIcon != null)
                IconButton(
                  tooltip: secondaryActionTooltip,
                  icon: Icon(
                    secondaryActionIcon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  onPressed: onSecondaryAction,
                ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                onPressed: onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<_ManualTcpEndpoint?> _promptForManualTcpHost() async {
    return showDialog<_ManualTcpEndpoint>(
      context: context,
      builder: (dialogContext) => _ManualTcpHostDialog(
        initialHost: _connectionProvider.tcpHost,
        initialPort: NetworkScannerService.defaultPort,
      ),
    );
  }

  Future<void> _connectManualTcpHost() async {
    if (_networkScanner.isScanning) {
      _networkScanner.stopScan();
      if (mounted) {
        setState(() {});
      }
    }

    final endpoint = await _promptForManualTcpHost();
    if (endpoint == null || !mounted) {
      return;
    }

    await _connectTcpEndpoint(
      host: endpoint.host,
      port: endpoint.port,
      name: endpoint.host,
      serverKey: '${endpoint.host}:${endpoint.port}',
    );
  }

  Widget _buildErrorBanner(String message) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSectionHeader(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBleDevicesTab(ConnectionProvider connectionProvider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildSectionBanner(
          icon: Icons.bluetooth_searching_rounded,
          message: l10n.defaultPinInfo,
          onRefresh: _refreshBleDevices,
        ),
        if (connectionProvider.error != null)
          _buildErrorBanner(connectionProvider.error!),
        Expanded(
          child:
              connectionProvider.isScanning &&
                  connectionProvider.scannedDevices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : connectionProvider.scannedDevices.isEmpty
              ? _buildEmptyState(
                  icon: Icons.bluetooth_searching_rounded,
                  title: _hasRequestedBleScan
                      ? l10n.noDevicesFound
                      : 'Press scan to search for nearby devices',
                  actionLabel: _hasRequestedBleScan ? l10n.scanAgain : 'Scan',
                  onAction: _refreshBleDevices,
                )
              : ListView.builder(
                  itemCount: connectionProvider.scannedDevices.length,
                  itemBuilder: (context, index) {
                    final scannedDevice =
                        connectionProvider.scannedDevices[index];
                    final device = scannedDevice.device;
                    final rssi = scannedDevice.rssi;
                    final signalColor = _getSignalColor(rssi);
                    final deviceId = device.remoteId.toString();
                    final isConnecting = _connectingBleDeviceId == deviceId;

                    Future<void> connectBle() async {
                      setState(() {
                        _connectingBleDeviceId = deviceId;
                      });
                      try {
                        final success = await connectionProvider.connect(
                          device,
                        );
                        if (!success) {
                          final name = device.platformName.isNotEmpty
                              ? device.platformName
                              : 'device';
                          throw Exception(
                            connectionProvider.error ??
                                'Failed to connect to $name',
                          );
                        }
                        _closeOnSuccessfulConnection();
                      } catch (error) {
                        _showConnectionError(error);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _connectingBleDeviceId = null;
                          });
                        }
                      }
                    }

                    return _buildTransportCard(
                      icon: Icons.bluetooth_rounded,
                      iconColor: signalColor,
                      title: device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device',
                      subtitle: AppLocalizations.of(context)!.signalDbm(rssi.toString()),
                      trailing: isConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : FilledButton.tonal(
                              onPressed: connectBle,
                              child: Text(AppLocalizations.of(context)!.connect),
                            ),
                      onTap: isConnecting ? null : connectBle,
                      enabled: !isConnecting,
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
    final bool hasRecentServers = _recentServers.isNotEmpty;
    final bool hasDiscoveredServers = _discoveredServers.isNotEmpty;
    final bool showEmptyState =
        !_networkScanner.isScanning &&
        !hasRecentServers &&
        !hasDiscoveredServers;
    final bool isAnyConnectionInProgress = _connectingToServerKey != null;

    return Column(
      children: [
        _buildSectionBanner(
          icon: showingCachedResults
              ? Icons.cached_rounded
              : Icons.wifi_find_rounded,
          message: showingCachedResults
              ? 'Showing cached results. Tap refresh to rescan.'
              : 'Scanning local network for MeshCore WiFi devices on port 5000',
          secondaryActionIcon: Icons.add_rounded,
          secondaryActionTooltip: _networkScanner.isScanning
              ? 'Cancel scan and add server'
              : 'Add server',
          onSecondaryAction: isAnyConnectionInProgress
              ? null
              : _connectManualTcpHost,
          onRefresh: _startNetworkScan,
        ),
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _connectManualTcpHost,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel and enter manually'),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: showEmptyState
              ? _buildEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'No recent or discovered servers yet',
                  actionLabel: 'Scan Again',
                  onAction: _startNetworkScan,
                )
              : ListView(
                  children: [
                    if (hasRecentServers)
                      _buildNetworkSectionHeader('Recently used'),
                    for (final server in _recentServers)
                      _buildTransportCard(
                        icon: Icons.history_rounded,
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: server.name,
                        subtitle:
                            _connectingToServerKey == '${server.host}:${server.port}'
                            ? 'Connecting...'
                            : '${server.host}:${server.port}',
                        trailing:
                            _connectingToServerKey == '${server.host}:${server.port}'
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : FilledButton.tonal(
                                onPressed: isAnyConnectionInProgress
                                    ? null
                                    : () => _connectTcpEndpoint(
                                        host: server.host,
                                        port: server.port,
                                        name: server.name,
                                        serverKey: '${server.host}:${server.port}',
                                      ),
                                child: Text(AppLocalizations.of(context)!.connect),
                              ),
                        enabled: !isAnyConnectionInProgress,
                        onTap: isAnyConnectionInProgress
                            ? null
                            : () => _connectTcpEndpoint(
                                host: server.host,
                                port: server.port,
                                name: server.name,
                                serverKey: '${server.host}:${server.port}',
                              ),
                      ),
                    if (hasDiscoveredServers)
                      _buildNetworkSectionHeader('Discovered on this network'),
                    for (final server in _discoveredServers)
                      Builder(
                        builder: (context) {
                          final serverKey = '${server.ipAddress}:${server.port}';
                          final isConnectingToThisServer =
                              _connectingToServerKey == serverKey;

                          Future<void> connectServer() async {
                            try {
                              final isAvailable = await _networkScanner.verifyServer(
                                server,
                              );
                              if (!isAvailable) {
                                throw Exception(
                                  'Server at ${server.ipAddress}:${server.port} is no longer available. Please scan again to find active servers.',
                                );
                              }

                              await _connectTcpEndpoint(
                                host: server.ipAddress,
                                port: server.port,
                                name: server.displayName,
                                serverKey: serverKey,
                              );
                            } catch (e) {
                              _showConnectionError(e);
                            }
                          }

                          return _buildTransportCard(
                            icon: Icons.wifi_rounded,
                            iconColor: Colors.green,
                            title: server.displayName,
                            subtitle: isConnectingToThisServer
                                ? 'Connecting...'
                                : '${server.ipAddress}:${server.port} • ${server.responseTime}ms',
                            trailing: isConnectingToThisServer
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : FilledButton.tonal(
                                    onPressed: isAnyConnectionInProgress
                                        ? null
                                        : connectServer,
                                    child: Text(AppLocalizations.of(context)!.connect),
                                  ),
                            enabled: !isAnyConnectionInProgress,
                            onTap: isAnyConnectionInProgress ? null : connectServer,
                          );
                        },
                      ),
                    if (_networkScanner.isScanning && !hasDiscoveredServers)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUsbTab() {
    return _SerialDeviceList(
      buildTransportCard:
          ({
            required icon,
            required iconColor,
            required title,
            required subtitle,
            required trailing,
            onTap,
            enabled = true,
          }) => _buildTransportCard(
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            onTap: onTap,
            enabled: enabled,
          ),
      buildEmptyState:
          ({
            required icon,
            required title,
            required actionLabel,
            required onAction,
          }) => _buildEmptyState(
            icon: icon,
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
      onConnected: (result) {
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      },
    );
  }
}

class _ManualTcpHostDialog extends StatefulWidget {
  final String? initialHost;
  final int initialPort;

  const _ManualTcpHostDialog({
    this.initialHost,
    required this.initialPort,
  });

  @override
  State<_ManualTcpHostDialog> createState() => _ManualTcpHostDialogState();
}

class _ManualTcpHostDialogState extends State<_ManualTcpHostDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  String? _hostErrorText;
  String? _portErrorText;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.initialHost);
    _portController = TextEditingController(text: widget.initialPort.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _submit() {
    final host = _hostController.text.trim();
    final portText = _portController.text.trim();
    final parsedAddress = InternetAddress.tryParse(host);
    final parsedPort = int.tryParse(portText);
    String? hostErrorText;
    String? portErrorText;

    if (parsedAddress == null) {
      hostErrorText = 'Enter a valid IP address';
    }
    if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
      portErrorText = 'Enter a valid TCP port';
    }
    if (hostErrorText != null || portErrorText != null) {
      setState(() {
        _hostErrorText = hostErrorText;
        _portErrorText = portErrorText;
      });
      return;
    }
    Navigator.of(
      context,
    ).pop(_ManualTcpEndpoint(host: parsedAddress!.address, port: parsedPort!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.connectByIpAddress),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _hostController,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'IP address',
              hintText: '192.168.1.42',
              border: const OutlineInputBorder(),
              errorText: _hostErrorText,
            ),
            onChanged: (_) {
              if (_hostErrorText == null) {
                return;
              }
              setState(() {
                _hostErrorText = null;
              });
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'TCP port',
              hintText: NetworkScannerService.defaultPort.toString(),
              helperText: 'Custom server port',
              border: const OutlineInputBorder(),
              errorText: _portErrorText,
            ),
            onChanged: (_) {
              if (_portErrorText == null) {
                return;
              }
              setState(() {
                _portErrorText = null;
              });
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context)!.connect),
        ),
      ],
    );
  }
}

typedef _TransportCardBuilder =
    Widget Function({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required Widget trailing,
      VoidCallback? onTap,
      bool enabled,
    });

typedef _EmptyStateBuilder =
    Widget Function({
      required IconData icon,
      required String title,
      required String actionLabel,
      required VoidCallback onAction,
    });

class _SerialDeviceList extends StatefulWidget {
  final ValueChanged<_ConnectionDialogResult> onConnected;
  final _TransportCardBuilder buildTransportCard;
  final _EmptyStateBuilder buildEmptyState;

  const _SerialDeviceList({
    required this.onConnected,
    required this.buildTransportCard,
    required this.buildEmptyState,
  });

  @override
  State<_SerialDeviceList> createState() => _SerialDeviceListState();
}

class _SerialDeviceListState extends State<_SerialDeviceList> {
  final SerialTransport _transport = createSerialTransport();
  List<SerialDeviceInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    if (_transport.isSupported) {
      _scanDevices();
    }
  }

  @override
  void dispose() {
    _transport.dispose();
    super.dispose();
  }

  Future<void> _scanDevices() async {
    if (!_transport.isSupported) {
      return;
    }
    setState(() => _isScanning = true);
    try {
      final devices = await _transport.listDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _devices = [];
        _isScanning = false;
      });
    }
  }

  Future<void> _requestDevice() async {
    if (!_transport.canRequestDevice) {
      await _scanDevices();
      return;
    }

    setState(() => _isScanning = true);
    try {
      final selectedDevice = await _transport.requestDevice();
      final devices = await _transport.listDevices();
      if (!mounted) return;
      setState(() {
        _devices = selectedDevice == null
            ? devices
            : _mergeDevices(devices, selectedDevice);
        _isScanning = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
    }
  }

  List<SerialDeviceInfo> _mergeDevices(
    List<SerialDeviceInfo> devices,
    SerialDeviceInfo selectedDevice,
  ) {
    final merged = [...devices];
    if (!merged.any((device) => device.id == selectedDevice.id)) {
      merged.insert(0, selectedDevice);
    }
    return merged;
  }

  Future<void> _connectToDevice(SerialDeviceInfo device) async {
    setState(() => _isConnecting = true);
    try {
      final connectionProvider = context.read<ConnectionProvider>();
      final connection = await _transport.connect(device);
      final success = await connectionProvider.connectSerial(
        service: connection.service,
        disconnectTransport: connection.disconnect,
        deviceId: connection.deviceId,
        deviceName: connection.deviceName,
      );
      if (!mounted) return;

      if (success) {
        widget.onConnected(_ConnectionDialogResult.connected);
      } else {
        await connection.disconnect();
        connection.service.dispose();
        if (!mounted) return;
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToConnectViaSerial)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.serialError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_transport.isSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _transport.unsupportedMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: FilledButton.tonalIcon(
            onPressed: _isConnecting
                ? null
                : (_transport.canRequestDevice ? _requestDevice : _scanDevices),
            icon: const Icon(Icons.usb_rounded),
            label: Text(_transport.actionLabel),
          ),
        ),
        if (_devices.isEmpty)
          Expanded(
            child: widget.buildEmptyState(
              icon: Icons.usb_off_rounded,
              title: _transport.emptyStateTitle,
              actionLabel: _transport.actionLabel,
              onAction: _transport.canRequestDevice
                  ? _requestDevice
                  : _scanDevices,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return widget.buildTransportCard(
                  icon: Icons.usb_rounded,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: device.title,
                  subtitle: device.subtitle,
                  trailing: _isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : FilledButton.tonal(
                          onPressed: _isConnecting
                              ? null
                              : () => _connectToDevice(device),
                          child: Text(AppLocalizations.of(context)!.connect),
                        ),
                  enabled: !_isConnecting,
                  onTap: _isConnecting ? null : () => _connectToDevice(device),
                );
              },
            ),
          ),
      ],
    );
  }
}
