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
import 'contact_trace_sheet.dart';
import 'room_login_sheet.dart';
import '../common/contact_avatar.dart';
import '../sensors/sensor_telemetry_card.dart';
import '../../utils/toast_logger.dart';
import '../../l10n/app_localizations.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final String? groupLabel;
  final bool compact;
  final Position? currentPosition;
  final double Function(double, double, double, double)? calculateDistance;
  final String Function(double)? formatDistance;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const ContactTile({
    super.key,
    required this.contact,
    this.groupLabel,
    this.compact = false,
    this.currentPosition,
    this.calculateDistance,
    this.formatDistance,
    this.onNavigateToMap,
    this.onNavigateToMessages,
  });

  String _getLocalizedRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final isChannel = contact.type == ContactType.channel;
    final isRoom = contact.type == ContactType.room;
    final isRoomOrChannel = isRoom || isChannel;
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
    final messagesProvider = context.watch<MessagesProvider>();
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
    final lastActivityAt = isRoomOrChannel
        ? messagesProvider.getLastActivityForDestination(contact)
        : null;
    final timeAgoText = _getLocalizedRelativeTime(
      context,
      lastActivityAt ?? contact.lastSeenTime,
    );
    final timeAgoStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: contact.isRecentlySeen
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final Widget subtitleWidget = compact
        ? _buildCompactSubtitle(context, distanceText)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (groupLabel case final label?)
                    _buildMetaPill(
                      context,
                      icon: Icons.folder_copy_outlined,
                      label: label,
                    ),
                ],
              ),
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
                          if (!isRoomOrChannel || lastActivityAt != null)
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

  Widget _buildCompactSubtitle(BuildContext context, String? distanceText) {
    final location = contact.displayLocation;
    final compactPills = <Widget>[
      if (groupLabel case final label?)
        _buildMetaPill(context, icon: Icons.folder_copy_outlined, label: label),
      if (distanceText != null) _buildDistancePill(context, distanceText),
      if (contact.routeHasPath && contact.routeHopCount > 0)
        _buildRoutePill(context, contact),
      if (location == null)
        _buildMetaPill(
          context,
          icon: Icons.location_disabled_outlined,
          label: AppLocalizations.of(context)!.noGpsData,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 6, runSpacing: 6, children: compactPills),
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
        contact.type == ContactType.chat ||
        contact.type == ContactType.room ||
        contact.type == ContactType.repeater ||
        contact.type == ContactType.sensor;
    final canAddToSensors =
        contact.type == ContactType.chat ||
        contact.type == ContactType.repeater ||
        contact.type == ContactType.sensor;
    final canPreviewSensor = contact.isSensor;
    final sensorsProvider = context.read<SensorsProvider>();
    final isInSensors = sensorsProvider.isWatched(contact.publicKeyHex);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
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
              if (canPreviewSensor)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Preview'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future<void>.delayed(Duration.zero);
                    if (!context.mounted) return;
                    await _showSensorPreviewView(context, contact);
                  },
                ),
              if (canAddToSensors)
                ListTile(
                  leading: Icon(
                    isInSensors ? Icons.sensors : Icons.sensors_outlined,
                  ),
                  title: Text(
                    isInSensors
                        ? l10n.contactInSensors
                        : l10n.contactAddToSensors,
                  ),
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
                  title: Text(l10n.contactSetPath),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showSetRouteDialog(context, contact);
                  },
                ),
              if (!contact.isChannel)
                ListTile(
                  leading: const Icon(Icons.route),
                  title: const Text('Trace'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showTraceSheet(context, contact);
                  },
                ),
              if (!contact.isPublicChannel)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit name'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showNameOverrideDialog(context, contact);
                  },
                ),
              if (!contact.isPublicChannel)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    contact.isChannel ? l10n.deleteChannel : l10n.deleteContact,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Future<void>.delayed(Duration.zero);
                    if (!context.mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!context.mounted) return;
                      if (contact.isChannel) {
                        _showDeleteChannelDialog(context, contact);
                      } else {
                        _showDeleteConfirmation(context, contact);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSensorPreviewView(
    BuildContext context,
    Contact contact,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (pageContext) => _SensorPreviewView(contact: contact),
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
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.contactAddedToSensors(contact.displayName),
        ),
      ),
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

  void _showTraceSheet(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ContactTraceSheet(contact: contact),
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

  Future<void> _showNameOverrideDialog(
    BuildContext context,
    Contact contact,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: _ContactNameOverrideSheet(
            initialValue: contact.nameOverride ?? '',
            advertisedName: contact.advName,
            cancelLabel: l10n.cancel,
            saveLabel: l10n.save,
          ),
        ),
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    context.read<ContactsProvider>().setContactNameOverride(
      contact.publicKeyHex,
      result,
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
          ToastLogger.error(
            context,
            AppLocalizations.of(
              context,
            )!.contactFailedToClearRoute(error.toString()),
          );
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.contactRouteCleared),
          ),
        );
      }
      return;
    }

    final parsedRoute = routeResult.route!;
    contactsProvider.setContactRouteLocal(
      contact.publicKey,
      signedEncodedPathLen: parsedRoute.signedEncodedPathLen,
      paddedPathBytes: parsedRoute.paddedPathBytes,
      inferredFallbackLocation: routeResult.inferredFallbackLocation,
    );

    try {
      await connectionProvider.setContactRoute(
        contact,
        signedEncodedPathLen: parsedRoute.signedEncodedPathLen,
        paddedPathBytes: parsedRoute.paddedPathBytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.contactRouteSet(parsedRoute.canonicalText),
            ),
          ),
        );
      }
    } catch (error) {
      contactsProvider.setContactRouteLocal(
        contact.publicKey,
        signedEncodedPathLen: previousSignedPathLen,
        paddedPathBytes: previousPathBytes,
      );
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(
            context,
          )!.contactFailedToSetRoute(error.toString()),
        );
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

  Widget _buildMetaPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool monospace = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
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

class _SensorPreviewView extends StatelessWidget {
  final Contact contact;

  const _SensorPreviewView({required this.contact});

  @override
  Widget build(BuildContext context) {
    final publicKeyHex = contact.publicKeyHex;
    return Consumer2<ContactsProvider, SensorsProvider>(
      builder: (context, contactsProvider, sensorsProvider, child) {
        Contact? liveContact;
        for (final entry in contactsProvider.contacts) {
          if (entry.publicKeyHex == publicKeyHex) {
            liveContact = entry;
            break;
          }
        }

        final previewContact = liveContact ?? contact;
        final visibleFields = sensorMetricKeysFor(previewContact);
        final fieldOrder = sensorsProvider.metricOrderFor(
          publicKeyHex,
          visibleFields,
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(previewContact.displayName),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              SensorTelemetryCard(
                contact: previewContact,
                state: sensorsProvider.stateFor(publicKeyHex),
                visibleFields: visibleFields,
                fieldOrder: fieldOrder,
                labelOverrides: sensorsProvider.labelOverridesFor(publicKeyHex),
                fieldSpans: sensorFullWidthFieldSpans(visibleFields),
                margin: EdgeInsets.zero,
                emptyMetricsMessage: 'No telemetry fields available yet.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactNameOverrideSheet extends StatefulWidget {
  final String initialValue;
  final String advertisedName;
  final String cancelLabel;
  final String saveLabel;

  const _ContactNameOverrideSheet({
    required this.initialValue,
    required this.advertisedName,
    required this.cancelLabel,
    required this.saveLabel,
  });

  @override
  State<_ContactNameOverrideSheet> createState() =>
      _ContactNameOverrideSheetState();
}

class _ContactNameOverrideSheetState extends State<_ContactNameOverrideSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit name',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Custom name',
                hintText: widget.advertisedName,
                helperText: 'Leave blank to use the advertised name.',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(widget.saveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
