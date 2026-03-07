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
import '../../providers/app_provider.dart';
import 'contact_route_dialog.dart';
import 'room_login_sheet.dart';
import '../../utils/location_formats.dart';
import '../../utils/toast_logger.dart';
import '../../utils/battery_display_helper.dart';
import '../../l10n/app_localizations.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final Position? currentPosition;
  final double Function(double, double, double, double)? calculateDistance;
  final String Function(double)? formatDistance;
  final VoidCallback? onNavigateToMap;

  const ContactTile({
    super.key,
    required this.contact,
    this.currentPosition,
    this.calculateDistance,
    this.formatDistance,
    this.onNavigateToMap,
  });

  /// Get localized time since last seen
  String _getLocalizedTimeSinceLastSeen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(contact.lastSeenTime);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isSimpleMode = appProvider.isSimpleMode;

    final hasTelemetry =
        contact.telemetry != null && contact.telemetry!.isRecent;
    final battery = contact.displayBattery;
    final location = contact.displayLocation;
    // Calculate distance if both positions are available
    String? distanceText;
    if (location != null &&
        currentPosition != null &&
        calculateDistance != null &&
        formatDistance != null) {
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
    final isPingInProgress = connectionProvider.isPingInProgress(
      contact.publicKey,
    );
    final roomLoginState = contact.type == ContactType.room
        ? connectionProvider.getRoomLoginState(contact.publicKeyPrefix)
        : null;
    final trailing = contact.isChannel && !contact.isPublicChannel
        ? PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteChannelDialog(context, contact);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.deleteChannel,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          )
        : null;
    void handleTap() {
      if (isSimpleMode && contact.type == ContactType.chat) {
        _showSetRouteDialog(context, contact);
      } else if (isSimpleMode && contact.type == ContactType.repeater) {
        _jumpToMapForRepeater(context, contact);
      } else if (isSimpleMode &&
          contact.type == ContactType.room &&
          !contact.isPublicChannel) {
        _showRoomLoginDialog(context, contact);
      } else {
        _showContactDetails(context, contact);
      }
    }

    final onLongPress = isPingInProgress
        ? null
        : () async {
            final connectionProvider = context.read<ConnectionProvider>();
            final hasPath = contact.routeHasPath;

            final result = await connectionProvider.smartPing(
              contactPublicKey: contact.publicKey,
              hasPath: hasPath,
              onRetryWithFlooding: () {
                if (context.mounted) {
                  ToastLogger.warning(
                    context,
                    AppLocalizations.of(
                      context,
                    )!.directPingTimeout(contact.displayName),
                  );
                }
              },
            );

            if (context.mounted && !result.success) {
              ToastLogger.error(
                context,
                AppLocalizations.of(context)!.pingFailed(contact.displayName),
              );
            }
          };
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    );
    final subtitleWidget = isSimpleMode
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: contact.isRecentlySeen ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.lastSeen}: ${_getLocalizedTimeSinceLastSeen(context)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'GPS: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (contact.type != ContactType.channel ||
                    distanceText != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (contact.type != ContactType.channel)
                        _buildRoutePill(context, contact),
                      if (distanceText != null)
                        _buildDistancePill(context, distanceText),
                    ],
                  ),
                ],
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    AppLocalizations.of(context)!.noGpsData,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              if (roomLoginState != null && roomLoginState.isLoggedIn) ...[
                Row(
                  children: [
                    if (roomLoginState.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              size: 10,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              AppLocalizations.of(context)!.admin,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            AppLocalizations.of(context)!.loggedIn,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: contact.isRecentlySeen ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLocalizedTimeSinceLastSeen(context),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (location != null) ...[
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    if (hasTelemetry)
                      const Icon(Icons.sensors, size: 12, color: Colors.green)
                    else
                      const Icon(
                        Icons.sensors_off,
                        size: 12,
                        color: Colors.grey,
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'GPS: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
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
              if (contact.type != ContactType.channel ||
                  distanceText != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (contact.type != ContactType.channel)
                      _buildRoutePill(context, contact),
                    if (distanceText != null)
                      _buildDistancePill(context, distanceText),
                  ],
                ),
              ],
            ],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: handleTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getTypeColor(contact.type, context),
                            _getTypeColor(
                              contact.type,
                              context,
                            ).withValues(alpha: 0.72),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getTypeColor(
                              contact.type,
                              context,
                            ).withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: contact.roleEmoji != null
                            ? Text(
                                contact.roleEmoji!,
                                style: const TextStyle(fontSize: 22),
                              )
                            : Icon(
                                _getTypeIcon(contact.type),
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                    if (contact.isNew)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    if (contact.type == ContactType.room &&
                        roomLoginState != null)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _getRoomStatusColor(roomLoginState),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _getRoomStatusIcon(roomLoginState),
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              contact.type.displayName,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ),
                          if (!isSimpleMode && battery != null) ...[
                            const SizedBox(width: 6),
                            _buildBatteryBadge(context, battery),
                          ],
                          if (isPingInProgress) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                          if (trailing != null) ...[
                            const SizedBox(width: 2),
                            trailing,
                          ],
                        ],
                      ),
                      subtitleWidget,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  void _jumpToMapForRepeater(BuildContext context, Contact contact) {
    final location = contact.displayLocation;
    if (location != null) {
      final mapProvider = context.read<MapProvider>();

      // Navigate to map location
      mapProvider.navigateToLocation(
        location: LatLng(location.latitude, location.longitude),
        zoom: 15.0,
        animate: true,
      );

      // Switch to map tab using callback
      onNavigateToMap?.call();
    }
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteContact),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteContactConfirmation(contact.displayName),
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
      // Remove contact from provider (which will also remove from device)
      await contactsProvider.removeContact(
        contact.publicKeyHex,
        onRemoveFromDevice: (publicKey) async {
          if (connectionProvider.deviceInfo.isConnected) {
            await connectionProvider.removeContact(publicKey);
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.failedToRemoveContact(e.toString()),
        );
      }
    }
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    final l10n = AppLocalizations.of(context)!;

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
        builder: (context, scrollController) {
          final contactsProvider = context.watch<ContactsProvider>();
          final currentContact =
              contactsProvider.findContactByKey(contact.publicKey) ?? contact;
          final isPingInProgress = context
              .watch<ConnectionProvider>()
              .isPingInProgress(contact.publicKey);
          return Column(
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
                    _detailRow(l10n.type, contact.type.displayName),
                    if (contact.isChannel) ...[
                      _detailRow(
                        l10n.channel,
                        contact.getLocalizedDisplayName(context),
                      ),
                      if (!contact.isPublicChannel)
                        _detailRow(
                          'Slot',
                          '${l10n.channel} ${contact.publicKey.length > 1 ? contact.publicKey[1] : '-'}',
                        ),
                    ] else
                      // Public Key with copy button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                '${l10n.publicKey}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Text(contact.publicKeyShort)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: contact.publicKeyHex),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.publicKeyCopied),
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
                    _detailRow(
                      l10n.lastSeen,
                      _getLocalizedTimeSinceLastSeen(context),
                    ),
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
                      _detailRow(
                        AppLocalizations.of(context)!.loginStatus,
                        roomLoginState.isLoggedIn
                            ? AppLocalizations.of(context)!.loggedIn
                            : AppLocalizations.of(context)!.notLoggedIn,
                      ),
                      if (roomLoginState.isLoggedIn) ...[
                        _detailRow(
                          AppLocalizations.of(context)!.adminAccess,
                          roomLoginState.isAdmin
                              ? AppLocalizations.of(context)!.yes
                              : AppLocalizations.of(context)!.no,
                        ),
                        _detailRow(
                          AppLocalizations.of(context)!.permissions,
                          roomLoginState.permissions.toString(),
                        ),
                        if (roomLoginState.loginDurationFormatted != null)
                          _detailRow(
                            AppLocalizations.of(context)!.loggedIn,
                            roomLoginState.loginDurationFormatted!,
                          ),
                      ],
                      _detailRow(
                        AppLocalizations.of(context)!.passwordSaved,
                        roomLoginState.hasPassword
                            ? AppLocalizations.of(context)!.yes
                            : AppLocalizations.of(context)!.no,
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

                              // Switch to map tab using callback
                              onNavigateToMap?.call();
                            },
                            icon: const Icon(Icons.map, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.viewOnMap,
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Decimal Degrees (DD)
                      _detailRowWithCopy(
                        context,
                        'DD',
                        '${contact.displayLocation!.latitude.toStringAsFixed(6)}, ${contact.displayLocation!.longitude.toStringAsFixed(6)}',
                      ),
                      // Degrees Minutes Seconds (DMS)
                      _detailRowWithCopy(
                        context,
                        'DMS',
                        _convertToDMS(
                          contact.displayLocation!.latitude,
                          contact.displayLocation!.longitude,
                        ),
                      ),
                      // Degrees Decimal Minutes (DDM)
                      _detailRowWithCopy(
                        context,
                        'DDM',
                        _convertToDDM(
                          contact.displayLocation!.latitude,
                          contact.displayLocation!.longitude,
                        ),
                      ),
                      // MGRS (Military Grid Reference System)
                      _detailRowWithCopy(
                        context,
                        'MGRS',
                        _convertToMGRS(
                          contact.displayLocation!.latitude,
                          contact.displayLocation!.longitude,
                        ),
                      ),
                      // Google Plus Code
                      _detailRowWithCopy(
                        context,
                        'Plus Code',
                        formatPlusCode(
                          contact.displayLocation!.latitude,
                          contact.displayLocation!.longitude,
                        ),
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
                            onPressed: isPingInProgress
                                ? null
                                : () async {
                                    final connectionProvider = context
                                        .read<ConnectionProvider>();
                                    final result = await connectionProvider
                                        .smartPing(
                                          contactPublicKey: contact.publicKey,
                                          hasPath: contact.routeHasPath,
                                        );

                                    if (!context.mounted || result.success) {
                                      return;
                                    }

                                    ToastLogger.error(
                                      context,
                                      AppLocalizations.of(
                                        context,
                                      )!.pingFailed(contact.displayName),
                                    );
                                  },
                            icon: isPingInProgress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            label: Text(AppLocalizations.of(context)!.refresh),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (contact.telemetry!.batteryMilliVolts != null)
                        _detailRow(
                          AppLocalizations.of(context)!.voltage,
                          '${(contact.telemetry!.batteryMilliVolts! / 1000).toStringAsFixed(3)}V'
                          '${contact.telemetry!.batteryPercentage != null ? ' (${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%)' : ''}',
                        )
                      else if (contact.telemetry!.batteryPercentage != null)
                        _detailRow(
                          AppLocalizations.of(context)!.battery,
                          '${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%',
                        ),
                      if (contact.telemetry!.temperature != null)
                        _detailRow(
                          AppLocalizations.of(context)!.temperature,
                          '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C',
                        ),
                      if (contact.telemetry!.humidity != null)
                        _detailRow(
                          AppLocalizations.of(context)!.humidity,
                          '${contact.telemetry!.humidity!.toStringAsFixed(1)}%',
                        ),
                      if (contact.telemetry!.pressure != null)
                        _detailRow(
                          AppLocalizations.of(context)!.pressure,
                          '${contact.telemetry!.pressure!.toStringAsFixed(1)} hPa',
                        ),
                      if (contact.telemetry!.gpsLocation != null)
                        _detailRow(
                          AppLocalizations.of(context)!.gpsTelemetry,
                          '${contact.telemetry!.gpsLocation!.latitude.toStringAsFixed(6)}, ${contact.telemetry!.gpsLocation!.longitude.toStringAsFixed(6)}',
                        ),
                      _detailRow(
                        AppLocalizations.of(context)!.updated,
                        '${_formatTimestamp(contact.telemetry!.timestamp)} (${_formatTimeAgo(contact.telemetry!.timestamp)})',
                      ),
                    ],
                    if (!currentContact.isChannel) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Route',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _detailRow('Mode', currentContact.routeSummary),
                      if (currentContact.routeHopCount > 0)
                        _detailRow('Route', currentContact.routeCanonicalText),
                      if (currentContact.routeHopCount > 0)
                        _detailRow(
                          'Descriptor',
                          '0x${currentContact.routeEncodedPathLen.toRadixString(16).padLeft(2, '0').toUpperCase()}',
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showSetRouteDialog(context, currentContact),
                              icon: const Icon(Icons.route),
                              label: const Text('Set Route'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: currentContact.isPublicChannel
                                  ? null
                                  : () async {
                                      contactsProvider.resetContactRouteLocal(
                                        currentContact.publicKey,
                                      );
                                      try {
                                        await connectionProvider.resetPath(
                                          currentContact.publicKey,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.pathResetInfo(
                                                  currentContact.displayName,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (_) {
                                        contactsProvider.setContactRouteLocal(
                                          currentContact.publicKey,
                                          signedEncodedPathLen:
                                              currentContact.routeSignedPathLen,
                                          paddedPathBytes:
                                              currentContact.outPath,
                                        );
                                        if (context.mounted) {
                                          ToastLogger.error(
                                            context,
                                            'Failed to reset route.',
                                          );
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppLocalizations.of(context)!.resetPath,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Room Login button for room contacts (except Public Channel)
                    if (contact.type == ContactType.room &&
                        !contact.isPublicChannel) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close details first
                            _showRoomLoginDialog(context, contact);
                          },
                          icon: const Icon(Icons.login),
                          label: Text(
                            roomLoginState?.isLoggedIn == true
                                ? AppLocalizations.of(context)!.reLoginToRoom
                                : AppLocalizations.of(context)!.loginToRoom,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _getTypeColor(
                              contact.type,
                              context,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    // Delete Contact button (for all contact types except Public Channel)
                    if (!contact.isPublicChannel) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showDeleteConfirmation(context, contact),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            AppLocalizations.of(context)!.deleteContact,
                          ),
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
          );
        },
      ),
    );
  }

  Future<void> _showSetRouteDialog(
    BuildContext context,
    Contact contact,
  ) async {
    final contactsProvider = context.read<ContactsProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    final availableContacts = contactsProvider.contacts
        .where((candidate) => candidate.publicKeyHex != contact.publicKeyHex)
        .toList();

    final parsedRoute = await ContactRouteDialog.show(
      context,
      contact: contact,
      availableContacts: availableContacts,
    );
    if (parsedRoute == null || !context.mounted) {
      return;
    }

    final previousSignedPathLen = contact.routeSignedPathLen;
    final previousPathBytes = Uint8List.fromList(contact.outPath);
    contactsProvider.setContactRouteLocal(
      contact.publicKey,
      signedEncodedPathLen: parsedRoute.signedEncodedPathLen,
      paddedPathBytes: parsedRoute.paddedPathBytes,
    );

    try {
      await connectionProvider.setContactRoute(
        contact,
        signedEncodedPathLen: parsedRoute.signedEncodedPathLen,
        paddedPathBytes: parsedRoute.paddedPathBytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route set: ${parsedRoute.canonicalText}')),
        );
      }
    } catch (error) {
      contactsProvider.setContactRouteLocal(
        contact.publicKey,
        signedEncodedPathLen: previousSignedPathLen,
        paddedPathBytes: previousPathBytes,
      );
      if (context.mounted) {
        ToastLogger.error(context, 'Failed to set route: $error');
      }
    }
  }

  Widget _detailRow(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _detailRowWithCopy(BuildContext context, String label, String value) {
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
          Expanded(child: Text(value)),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.copiedToClipboard(label),
                  ),
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

    return '$latDeg°$latMin\'${latSec.toStringAsFixed(2)}"$latDir, $lonDeg°$lonMin\'${lonSec.toStringAsFixed(2)}"$lonDir';
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
    return '$zone$letter (approximate)';
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
    final timestampDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

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

  /// Show delete channel confirmation dialog
  void _showDeleteChannelDialog(BuildContext context, Contact contact) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteChannel),
        content: Text(l10n.deleteChannelConfirmation(contact.advName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              try {
                // Extract channel index from pseudo public key
                // publicKey format: [0xFF, channelIdx, ...]
                final channelIdx = contact.publicKey[1];

                final connectionProvider = context.read<ConnectionProvider>();
                await connectionProvider.deleteChannel(channelIdx);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.channelDeletedSuccessfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.channelDeletionFailed(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePill(BuildContext context, Contact contact) {
    final hasPath = contact.routeHasPath;
    final scheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(
      context,
    ).textTheme.labelSmall?.color?.withValues(alpha: 0.82);
    final iconColor = Theme.of(
      context,
    ).textTheme.labelSmall?.color?.withValues(alpha: 0.7);
    final label = !hasPath
        ? AppLocalizations.of(context)!.flood
        : contact.routeHopCount <= 0
        ? AppLocalizations.of(context)!.direct
        : contact.routeCanonicalText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPath ? Icons.alt_route : Icons.waves,
            size: 11,
            color: iconColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontFamily: hasPath && contact.routeHopCount > 0
                    ? 'monospace'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistancePill(BuildContext context, String distanceText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.straighten,
            size: 11,
            color: Theme.of(
              context,
            ).textTheme.labelSmall?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(
            '${AppLocalizations.of(context)!.distance}: $distanceText',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.labelSmall?.color?.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryBadge(BuildContext context, double battery) {
    final color = BatteryDisplayHelper.getBatteryColor(battery);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            BatteryDisplayHelper.getBatteryIcon(battery),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${battery.round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
