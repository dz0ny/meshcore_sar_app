import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contact.dart';
import '../../models/room_login_state.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/map_provider.dart';
import 'direct_message_sheet.dart';
import 'room_login_sheet.dart';
import '../../utils/toast_logger.dart';
import '../../l10n/app_localizations.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final Position? currentPosition;
  final double Function(double, double, double, double)? calculateDistance;
  final String Function(double)? formatDistance;

  const ContactTile({
    super.key,
    required this.contact,
    this.currentPosition,
    this.calculateDistance,
    this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final hasTelemetry = contact.telemetry != null && contact.telemetry!.isRecent;
    final battery = contact.displayBattery;
    final location = contact.displayLocation;

    // Calculate distance if both positions are available
    String? distanceText;
    if (location != null && currentPosition != null && calculateDistance != null && formatDistance != null) {
      final distanceMeters = calculateDistance!(
        currentPosition!.latitude,
        currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );
      distanceText = formatDistance!(distanceMeters);
    }

    // Get room login state if this is a room
    final connectionProvider = context.watch<ConnectionProvider>();
    final roomLoginState = contact.type == ContactType.room
        ? connectionProvider.getRoomLoginState(contact.publicKeyPrefix)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getTypeColor(contact.type, context),
              child: contact.roleEmoji != null
                  ? Text(
                      contact.roleEmoji!,
                      style: const TextStyle(fontSize: 24),
                    )
                  : Icon(
                      _getTypeIcon(contact.type),
                      color: Colors.white,
                    ),
            ),
            // New contact indicator badge (top-right)
            if (contact.isNew)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            // Room login status indicator badge (bottom-right)
            if (contact.type == ContactType.room && roomLoginState != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getRoomStatusColor(roomLoginState),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getRoomStatusIcon(roomLoginState),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Battery indicator
            if (battery != null) ...[
              Icon(
                _getBatteryIcon(battery),
                size: 16,
                color: _getBatteryColor(battery),
              ),
              const SizedBox(width: 4),
              Text(
                '${battery.round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _getBatteryColor(battery),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Connection type indicator (direct/flood) - shown for all contact types
            if (contact.type != ContactType.channel) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: contact.hasPath
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: contact.hasPath ? Colors.green : Colors.orange,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      contact.hasPath ? Icons.route : Icons.waves,
                      size: 10,
                      color: contact.hasPath ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      contact.hasPath ? AppLocalizations.of(context)!.direct : AppLocalizations.of(context)!.flood,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: contact.hasPath ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Room login status badges
            if (roomLoginState != null && roomLoginState.isLoggedIn) ...[
              Row(
                children: [
                  if (roomLoginState.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 10, color: Colors.red),
                          const SizedBox(width: 2),
                          Text(
                            AppLocalizations.of(context)!.admin,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (roomLoginState.isAdmin) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 10, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(context)!.loggedIn,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // Last seen + GPS info combined
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: contact.isRecentlySeen ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  contact.timeSinceLastSeen,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (location != null) ...[
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  if (hasTelemetry)
                    const Icon(Icons.sensors, size: 12, color: Colors.green)
                  else
                    const Icon(Icons.sensors_off, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  const Icon(Icons.sensors_off, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.noGpsData,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            // Distance info (new row)
            if (distanceText != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.distance}: $distanceText',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: null,
        onTap: () => _showContactDetails(context, contact),
        onLongPress: () async {
          final connectionProvider = context.read<ConnectionProvider>();

          // Determine if we should use flooding (no path) or direct (has path)
          final hasPath = contact.hasPath;

          // Show initial notification reflecting the method being used
          ToastLogger.info(
            context,
            hasPath
                ? AppLocalizations.of(context)!.pingingDirect(contact.displayName)
                : AppLocalizations.of(context)!.pingingFlood(contact.displayName),
          );

          // Use smart ping with automatic fallback
          final result = await connectionProvider.smartPing(
            contactPublicKey: contact.publicKey,
            hasPath: hasPath,
            onRetryWithFlooding: () {
              // Called when retrying with flooding after direct timeout
              if (context.mounted) {
                ToastLogger.warning(
                  context,
                  AppLocalizations.of(context)!.directPingTimeout(contact.displayName),
                );
              }
            },
          );

          // Show final result
          if (context.mounted) {
            if (result.success) {
              ToastLogger.success(
                context,
                AppLocalizations.of(context)!.pingSuccessful(
                  contact.displayName,
                  result.retriedWithFlooding ? AppLocalizations.of(context)!.viaFloodingFallback : '',
                ),
              );
            } else {
              ToastLogger.error(
                context,
                AppLocalizations.of(context)!.pingFailed(contact.displayName),
              );
            }
          }
        },
      ),
    );
  }

  void _showDirectMessageDialog(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DirectMessageSheet(contact: contact),
    );
  }

  void _showRoomLoginDialog(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomLoginSheet(contact: contact),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteContact),
        content: Text(
          AppLocalizations.of(context)!.deleteContactConfirmation(contact.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close contact details sheet
              await _deleteContact(context, contact);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(BuildContext context, Contact contact) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();

    try {
      // Show loading toast
      ToastLogger.info(context, AppLocalizations.of(context)!.removingContact(contact.displayName));

      // Remove contact from provider (which will also remove from device)
      await contactsProvider.removeContact(
        contact.publicKeyHex,
        onRemoveFromDevice: (publicKey) async {
          if (connectionProvider.deviceInfo.isConnected) {
            await connectionProvider.removeContact(publicKey);
          }
        },
      );

      if (context.mounted) {
        ToastLogger.success(context, AppLocalizations.of(context)!.contactRemoved(contact.displayName));
      }
    } catch (e) {
      if (context.mounted) {
        ToastLogger.error(context, AppLocalizations.of(context)!.failedToRemoveContact(e.toString()));
      }
    }
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    // Get room login state
    final connectionProvider = context.read<ConnectionProvider>();
    final roomLoginState = contact.type == ContactType.room
        ? connectionProvider.getRoomLoginState(contact.publicKeyPrefix)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor(contact.type, context),
                    child: contact.roleEmoji != null
                        ? Text(
                            contact.roleEmoji!,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Icon(
                            _getTypeIcon(contact.type),
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailRow(AppLocalizations.of(context)!.type, contact.type.displayName),
                  // Public Key with copy button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${AppLocalizations.of(context)!.publicKey}:',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          child: Text(contact.publicKeyShort),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: contact.publicKeyHex));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.publicKeyCopied),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DetailRow(AppLocalizations.of(context)!.lastSeen, contact.timeSinceLastSeen),
                  const SizedBox(height: 16),
                  // Room Login Status
                  if (roomLoginState != null) ...[
                    Text(
                      '${AppLocalizations.of(context)!.roomStatus}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      AppLocalizations.of(context)!.loginStatus,
                      roomLoginState.isLoggedIn ? AppLocalizations.of(context)!.loggedIn : AppLocalizations.of(context)!.notLoggedIn,
                    ),
                    if (roomLoginState.isLoggedIn) ...[
                      _DetailRow(
                        AppLocalizations.of(context)!.adminAccess,
                        roomLoginState.isAdmin ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no,
                      ),
                      _DetailRow(
                        AppLocalizations.of(context)!.permissions,
                        roomLoginState.permissions.toString(),
                      ),
                      if (roomLoginState.loginDurationFormatted != null)
                        _DetailRow(
                          AppLocalizations.of(context)!.loggedIn,
                          roomLoginState.loginDurationFormatted!,
                        ),
                    ],
                    _DetailRow(
                      AppLocalizations.of(context)!.passwordSaved,
                      roomLoginState.hasPassword ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (contact.displayLocation != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.locationColon,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to map and close modal
                            final mapProvider = context.read<MapProvider>();
                            mapProvider.navigateToLocation(
                              location: LatLng(
                                contact.displayLocation!.latitude,
                                contact.displayLocation!.longitude,
                              ),
                            );
                            Navigator.pop(context);

                            // Switch to map tab (assuming it's index 2)
                            DefaultTabController.of(context).animateTo(2);
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(AppLocalizations.of(context)!.viewOnMap),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Decimal Degrees (DD)
                    _DetailRowWithCopy(
                      context,
                      'DD',
                      '${contact.displayLocation!.latitude.toStringAsFixed(6)}, ${contact.displayLocation!.longitude.toStringAsFixed(6)}',
                    ),
                    // Degrees Minutes Seconds (DMS)
                    _DetailRowWithCopy(
                      context,
                      'DMS',
                      _convertToDMS(contact.displayLocation!.latitude, contact.displayLocation!.longitude),
                    ),
                    // Degrees Decimal Minutes (DDM)
                    _DetailRowWithCopy(
                      context,
                      'DDM',
                      _convertToDDM(contact.displayLocation!.latitude, contact.displayLocation!.longitude),
                    ),
                    // MGRS (Military Grid Reference System)
                    _DetailRowWithCopy(
                      context,
                      'MGRS',
                      _convertToMGRS(contact.displayLocation!.latitude, contact.displayLocation!.longitude),
                    ),
                    // Google Plus Code
                    _DetailRowWithCopy(
                      context,
                      'Plus Code',
                      _convertToPlusCode(contact.displayLocation!.latitude, contact.displayLocation!.longitude),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (contact.telemetry != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.telemetry}:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final connectionProvider = context.read<ConnectionProvider>();
                            connectionProvider.requestTelemetry(contact.publicKey, zeroHop: true);
                            ToastLogger.info(context, AppLocalizations.of(context)!.requestingTelemetry(contact.displayName));
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(AppLocalizations.of(context)!.refresh),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (contact.telemetry!.batteryMilliVolts != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.voltage,
                        '${(contact.telemetry!.batteryMilliVolts! / 1000).toStringAsFixed(3)}V'
                        '${contact.telemetry!.batteryPercentage != null ? ' (${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%)' : ''}',
                      )
                    else if (contact.telemetry!.batteryPercentage != null)
                      _DetailRow(AppLocalizations.of(context)!.battery, '${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%'),
                    if (contact.telemetry!.temperature != null)
                      _DetailRow(AppLocalizations.of(context)!.temperature, '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C'),
                    if (contact.telemetry!.humidity != null)
                      _DetailRow(AppLocalizations.of(context)!.humidity, '${contact.telemetry!.humidity!.toStringAsFixed(1)}%'),
                    if (contact.telemetry!.pressure != null)
                      _DetailRow(AppLocalizations.of(context)!.pressure, '${contact.telemetry!.pressure!.toStringAsFixed(1)} hPa'),
                    if (contact.telemetry!.gpsLocation != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.gpsTelemetry,
                        '${contact.telemetry!.gpsLocation!.latitude.toStringAsFixed(6)}, ${contact.telemetry!.gpsLocation!.longitude.toStringAsFixed(6)}',
                      ),
                    _DetailRow(
                      AppLocalizations.of(context)!.updated,
                      '${_formatTimestamp(contact.telemetry!.timestamp)} (${_formatTimeAgo(contact.telemetry!.timestamp)})',
                    ),
                  ],
                  // Direct Message button for chat contacts
                  if (contact.type == ContactType.chat) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details first
                          _showDirectMessageDialog(context, contact);
                        },
                        icon: const Icon(Icons.message),
                        label: Text(AppLocalizations.of(context)!.sendDirectMessage),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _getTypeColor(contact.type, context),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          connectionProvider.resetPath(contact.publicKey);
                          ToastLogger.info(context, AppLocalizations.of(context)!.pathResetInfo(contact.displayName));
                        },
                        icon: const Icon(Icons.route),
                        label: Text(AppLocalizations.of(context)!.resetPath),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: _getTypeColor(contact.type, context)),
                          foregroundColor: _getTypeColor(contact.type, context),
                        ),
                      ),
                    ),
                  ],
                  // Room Login button for room contacts (except Public Channel)
                  if (contact.type == ContactType.room && contact.advName != 'Public Channel') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details first
                          _showRoomLoginDialog(context, contact);
                        },
                        icon: const Icon(Icons.login),
                        label: Text(roomLoginState?.isLoggedIn == true ? AppLocalizations.of(context)!.reLoginToRoom : AppLocalizations.of(context)!.loginToRoom),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _getTypeColor(contact.type, context),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  // Delete Contact button (for all contact types except Public Channel)
                  if (contact.advName != 'Public Channel') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, contact),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppLocalizations.of(context)!.deleteContact),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _DetailRowWithCopy(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.copiedToClipboard(label)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert to Degrees Minutes Seconds (DMS) format
  String _convertToDMS(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';

    lat = lat.abs();
    lon = lon.abs();

    int latDeg = lat.floor();
    double latMinDec = (lat - latDeg) * 60;
    int latMin = latMinDec.floor();
    double latSec = (latMinDec - latMin) * 60;

    int lonDeg = lon.floor();
    double lonMinDec = (lon - lonDeg) * 60;
    int lonMin = lonMinDec.floor();
    double lonSec = (lonMinDec - lonMin) * 60;

    return '$latDeg°${latMin}\'${latSec.toStringAsFixed(2)}"$latDir, $lonDeg°${lonMin}\'${lonSec.toStringAsFixed(2)}"$lonDir';
  }

  /// Convert to Degrees Decimal Minutes (DDM) format
  String _convertToDDM(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';

    lat = lat.abs();
    lon = lon.abs();

    int latDeg = lat.floor();
    double latMin = (lat - latDeg) * 60;

    int lonDeg = lon.floor();
    double lonMin = (lon - lonDeg) * 60;

    return '$latDeg° ${latMin.toStringAsFixed(4)}\'$latDir, $lonDeg° ${lonMin.toStringAsFixed(4)}\'$lonDir';
  }

  /// Convert to MGRS (Military Grid Reference System) format
  /// Simplified implementation - returns approximate grid zone
  String _convertToMGRS(double lat, double lon) {
    // Zone number (1-60)
    int zone = ((lon + 180) / 6).floor() + 1;

    // Zone letter (C-X, excluding I and O)
    const letters = 'CDEFGHJKLMNPQRSTUVWX';
    int letterIndex = ((lat + 80) / 8).floor();
    if (letterIndex < 0) letterIndex = 0;
    if (letterIndex >= letters.length) letterIndex = letters.length - 1;
    String letter = letters[letterIndex];

    // Simplified - just show zone designation
    // Full MGRS would require UTM conversion library
    return '${zone}$letter (approximate)';
  }

  /// Convert to Google Plus Code format
  /// Simplified implementation - returns approximate code
  String _convertToPlusCode(double lat, double lon) {
    // This is a simplified version - full Plus Code requires the open_location_code package
    // For now, return a placeholder that shows it's not fully implemented
    const base = '23456789CFGHJMPQRVWX';

    // Normalize coordinates
    lat = (lat + 90) / 180; // 0 to 1
    lon = (lon + 180) / 360; // 0 to 1

    String code = '';
    for (int i = 0; i < 8; i++) {
      if (i == 4) code += '+';

      int latDigit = (lat * 20).floor() % 20;
      int lonDigit = (lon * 20).floor() % 20;

      code += base[latDigit];
      code += base[lonDigit];

      lat = (lat * 20) % 1;
      lon = (lon * 20) % 1;
    }

    return code;
  }

  IconData _getTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.chat:
        return Icons.person;
      case ContactType.repeater:
        return Icons.router;
      case ContactType.room:
        return Icons.tag;
      default:
        return Icons.help;
    }
  }

  Color _getTypeColor(ContactType type, BuildContext context) {
    switch (type) {
      case ContactType.chat:
        return Theme.of(context).colorScheme.primary;
      case ContactType.repeater:
        return Colors.green;
      case ContactType.room:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getBatteryIcon(double percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 50) return Icons.battery_5_bar;
    if (percentage > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }

  /// Get room login status color
  Color _getRoomStatusColor(RoomLoginState state) {
    if (!state.isLoggedIn) {
      return Colors.grey; // Grey for not logged in
    }
    if (state.isAdmin) {
      return Colors.red; // Red for admin
    }
    return Colors.green; // Green for logged in (non-admin)
  }

  /// Get room login status icon
  IconData _getRoomStatusIcon(RoomLoginState state) {
    if (!state.isLoggedIn) {
      return Icons.lock; // Lock for not logged in
    }
    if (state.isAdmin) {
      return Icons.admin_panel_settings; // Admin icon for admin
    }
    return Icons.check; // Check for logged in (non-admin)
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (timestampDate == today) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    } else {
      // Another day - show date and time
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
