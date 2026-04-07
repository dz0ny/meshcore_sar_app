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
import '../services/serial/serial_transport.dart';

enum _ConnectionDialogResult { connected }

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

  Future<String?> _promptForManualTcpHost() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _ManualTcpHostDialog(
        initialHost: _connectionProvider.tcpHost,
      ),
    );
  }

  Future<void> _connectManualTcpHost() async {
    final host = await _promptForManualTcpHost();
    if (host == null || !mounted) {
      return;
    }

    final serverKey = '$host:${NetworkScannerService.defaultPort}';
    final connectionProvider = context.read<ConnectionProvider>();

    setState(() {
      _connectingToServerKey = serverKey;
    });

    try {
      final success = await connectionProvider.connectTcp(
        host,
        NetworkScannerService.defaultPort,
      );
      if (!success) {
        throw Exception(
          connectionProvider.error ??
              'Failed to connect to $host:${NetworkScannerService.defaultPort}',
        );
      }
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
          secondaryActionTooltip: 'Add IP address',
          onSecondaryAction: _connectingToServerKey != null
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
              ],
            ),
          ),
        Expanded(
          child: _networkScanner.isScanning && _discoveredServers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _discoveredServers.isEmpty
              ? _buildEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: AppLocalizations.of(context)!.noServersFound,
                  actionLabel: 'Scan Again',
                  onAction: _startNetworkScan,
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

                    Future<void> connectServer() async {
                      final connectionProvider = context
                          .read<ConnectionProvider>();

                      setState(() {
                        _connectingToServerKey = serverKey;
                      });

                      try {
                        final isAvailable = await _networkScanner.verifyServer(
                          server,
                        );
                        if (!isAvailable) {
                          throw Exception(
                            'Server at ${server.ipAddress}:${server.port} is no longer available. Please scan again to find active servers.',
                          );
                        }

                        final success = await connectionProvider.connectTcp(
                          server.ipAddress,
                          server.port,
                        );
                        if (!success) {
                          throw Exception(
                            connectionProvider.error ??
                                'Failed to connect to ${server.ipAddress}:${server.port}',
                          );
                        }
                        _closeOnSuccessfulConnection();
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _connectingToServerKey = null;
                        });
                        _showConnectionError(e);
                      }
                    }

                    return _buildTransportCard(
                      icon: Icons.wifi_rounded,
                      iconColor: Colors.green,
                      title: server.ipAddress,
                      subtitle: isConnectingToThisServer
                          ? 'Connecting...'
                          : 'Port ${server.port} • ${server.responseTime}ms',
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

  const _ManualTcpHostDialog({this.initialHost});

  @override
  State<_ManualTcpHostDialog> createState() => _ManualTcpHostDialogState();
}

class _ManualTcpHostDialogState extends State<_ManualTcpHostDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHost);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final host = _controller.text.trim();
    final parsedAddress = InternetAddress.tryParse(host);
    if (parsedAddress == null) {
      setState(() {
        _errorText = 'Enter a valid IP address';
      });
      return;
    }
    Navigator.of(context).pop(parsedAddress.address);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.connectByIpAddress),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'IP address',
          hintText: '192.168.1.42',
          helperText: 'Uses TCP port 5000',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText == null) {
            return;
          }
          setState(() {
            _errorText = null;
          });
        },
        onSubmitted: (_) => _submit(),
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
