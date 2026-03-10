import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contact.dart';
import '../../models/room_login_state.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/sensors_provider.dart';
import '../../services/message_destination_preferences.dart';
import 'contact_route_dialog.dart';
import 'room_login_sheet.dart';
import '../common/contact_avatar.dart';
import '../../utils/toast_logger.dart';
import '../../l10n/app_localizations.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final Position? currentPosition;
  final double Function(double, double, double, double)? calculateDistance;
  final String Function(double)? formatDistance;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const ContactTile({
    super.key,
    required this.contact,
    this.currentPosition,
    this.calculateDistance,
    this.formatDistance,
    this.onNavigateToMap,
    this.onNavigateToMessages,
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
    final isChannel = contact.type == ContactType.channel;
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
    void handleTap() => _handlePrimaryTap(context, contact);

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
    final timeAgoText = _getLocalizedTimeSinceLastSeen(context);
    final timeAgoStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: contact.isRecentlySeen
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final Widget? subtitleWidget = isChannel
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location != null) ...[
                const SizedBox(height: 2),
                _buildLocationLine(
                  context,
                  latitude: location.latitude,
                  longitude: location.longitude,
                  distanceText: distanceText,
                ),
                const SizedBox(height: 6),
                Row(children: [_buildRoutePill(context, contact)]),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ContactAvatar(contact: contact, radius: 24),
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
                          if (!isChannel)
                            Text(timeAgoText, style: timeAgoStyle),
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
                        ],
                      ),
                      ?subtitleWidget,
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

  void _handlePrimaryTap(BuildContext context, Contact contact) {
    _showContactActionSheet(context, contact);
  }

  void _showContactActionSheet(BuildContext context, Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    final canMessage =
        contact.type == ContactType.chat ||
        contact.type == ContactType.room ||
        contact.type == ContactType.channel;
    final canSetPath =
        contact.type == ContactType.chat || contact.type == ContactType.room;
    final canAddToSensors =
        contact.type == ContactType.chat ||
        contact.type == ContactType.repeater;
    final sensorsProvider = context.read<SensorsProvider>();
    final isInSensors = sensorsProvider.isWatched(contact.publicKeyHex);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: Text(l10n.messages),
              enabled: canMessage,
              onTap: !canMessage
                  ? null
                  : () async {
                      Navigator.pop(sheetContext);
                      await _openMessagesForContact(context, contact);
                    },
            ),
            if (contact.displayLocation != null)
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(l10n.viewOnMap),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showContactOnMap(context, contact);
                },
              ),
            if (contact.type == ContactType.room && !contact.isPublicChannel)
              ListTile(
                leading: const Icon(Icons.login),
                title: Text(
                  context
                              .read<ConnectionProvider>()
                              .getRoomLoginState(contact.publicKeyPrefix)
                              ?.isLoggedIn ==
                          true
                      ? AppLocalizations.of(context)!.reLoginToRoom
                      : AppLocalizations.of(context)!.loginToRoom,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomLoginDialog(context, contact);
                },
              ),
            if (canAddToSensors)
              ListTile(
                leading: Icon(
                  isInSensors ? Icons.sensors : Icons.sensors_outlined,
                ),
                title: Text(isInSensors ? 'In Sensors' : 'Add to Sensors'),
                enabled: !isInSensors,
                onTap: isInSensors
                    ? null
                    : () async {
                        Navigator.pop(sheetContext);
                        await _addContactToSensors(context, contact);
                      },
              ),
            if (canSetPath)
              ListTile(
                leading: const Icon(Icons.alt_route),
                title: const Text('Set path'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSetRouteDialog(context, contact);
                },
              ),
            if (!contact.isPublicChannel)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  contact.isChannel ? l10n.deleteChannel : l10n.deleteContact,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (contact.isChannel) {
                    _showDeleteChannelDialog(context, contact);
                  } else {
                    _showDeleteConfirmation(context, contact);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showContactOnMap(BuildContext context, Contact contact) {
    final location = contact.displayLocation;
    if (location == null) {
      return;
    }

    context.read<MapProvider>().navigateToLocation(
      location: LatLng(location.latitude, location.longitude),
    );
    onNavigateToMap?.call();
  }

  Future<void> _addContactToSensors(
    BuildContext context,
    Contact contact,
  ) async {
    await context.read<SensorsProvider>().addSensor(contact);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${contact.displayName} added to Sensors')),
    );
  }

  Future<void> _openMessagesForContact(
    BuildContext context,
    Contact contact,
  ) async {
    final messagesProvider = context.read<MessagesProvider>();
    final destinationType = contact.type == ContactType.channel
        ? MessageDestinationPreferences.destinationTypeChannel
        : contact.type == ContactType.room
        ? MessageDestinationPreferences.destinationTypeRoom
        : MessageDestinationPreferences.destinationTypeContact;

    await MessageDestinationPreferences.setDestination(
      destinationType,
      recipientPublicKey: contact.publicKeyHex,
    );
    messagesProvider.navigateToDestination(
      destinationType,
      recipientPublicKeyHex: contact.publicKeyHex,
    );
    onNavigateToMessages?.call();
  }

  void _showRoomLoginDialog(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomLoginSheet(contact: contact),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Contact contact, {
    bool closeDetailsSheetOnDelete = false,
  }) {
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
              if (closeDetailsSheetOnDelete) {
                Navigator.pop(context); // Close contact details sheet
              }
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

  Future<void> _showSetRouteDialog(
    BuildContext context,
    Contact contact,
  ) async {
    final contactsProvider = context.read<ContactsProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    final availableContacts = contactsProvider.contacts
        .where((candidate) => candidate.publicKeyHex != contact.publicKeyHex)
        .toList();

    final routeResult = await ContactRouteDialog.show(
      context,
      contact: contact,
      availableContacts: availableContacts,
    );
    if (routeResult == null || !context.mounted) {
      return;
    }

    final previousSignedPathLen = contact.routeSignedPathLen;
    final previousPathBytes = Uint8List.fromList(contact.outPath);
    if (routeResult.shouldClear) {
      contactsProvider.resetContactRouteLocal(contact.publicKey);
      await connectionProvider.resetPath(contact.publicKey);
      final error = connectionProvider.error;
      if (error != null) {
        contactsProvider.setContactRouteLocal(
          contact.publicKey,
          signedEncodedPathLen: previousSignedPathLen,
          paddedPathBytes: previousPathBytes,
        );
        if (context.mounted) {
          ToastLogger.error(context, 'Failed to clear route: $error');
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Route cleared')));
      }
      return;
    }

    final parsedRoute = routeResult.route!;
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

  Widget _buildLocationMeta(
    BuildContext context,
    double latitude,
    double longitude, {
    bool telemetryActive = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: telemetryActive
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            telemetryActive
                ? Icons.navigation_rounded
                : Icons.location_searching,
            size: 11,
            color: telemetryActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLocationLine(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? distanceText,
    bool telemetryActive = true,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildLocationMeta(
          context,
          latitude,
          longitude,
          telemetryActive: telemetryActive,
        ),
        if (distanceText != null) _buildDistancePill(context, distanceText),
      ],
    );
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

  /// Show delete channel confirmation dialog
  void _showDeleteChannelDialog(
    BuildContext context,
    Contact contact, {
    bool closeDetailsSheetOnDelete = false,
  }) {
    if (contact.isPublicChannel) {
      return;
    }

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
              if (closeDetailsSheetOnDelete) {
                Navigator.of(context).pop();
              }

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
    final isDirect = !hasPath || contact.routeHopCount <= 0;
    final scheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(
      context,
    ).textTheme.labelSmall?.color?.withValues(alpha: 0.82);
    final iconColor = Theme.of(
      context,
    ).textTheme.labelSmall?.color?.withValues(alpha: 0.7);
    final label = isDirect
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
            isDirect ? Icons.north_east_rounded : Icons.alt_route,
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
                fontFamily: !isDirect ? 'monospace' : null,
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
            distanceText,
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
}
