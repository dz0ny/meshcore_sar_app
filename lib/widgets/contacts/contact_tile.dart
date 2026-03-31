import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter/services.dart';
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
import '../../services/location_tracking_service.dart';
import '../../services/message_destination_preferences.dart';
import 'contact_route_dialog.dart';
import 'contact_trace_sheet.dart';
import 'room_login_sheet.dart';
import '../common/contact_avatar.dart';
import '../sensors/bthome_met_history_sheet.dart';
import '../sensors/sensor_telemetry_card.dart';
import '../../utils/link_quality.dart';
import '../../utils/time_ago_extensions.dart';
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

  String _threeBytePrefix() {
    final bytes = contact.publicKey.take(3);
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
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
                  ..._buildSignalPills(context),
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
                  padding: EdgeInsets.only(top: 4),
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
        color: colorScheme.surfaceContainerLow,
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
                SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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
                      const SizedBox(height: 8),
                      Text(
                        _threeBytePrefix(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
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

  List<Widget> _buildSignalPills(BuildContext context) {
    if (!contact.isRepeater && !contact.isSensor) return [];
    final contactsProvider = context.read<ContactsProvider>();
    final advert = contactsProvider.pendingAdvertByKey(contact.publicKey);
    if (advert == null) return [];

    final pills = <Widget>[];
    if (advert.rxRssiDbm != null) {
      pills.add(
        _buildMetaPill(
          context,
          icon: Icons.arrow_downward_rounded,
          label: '${advert.rxRssiDbm} dBm',
        ),
      );
    }
    if (advert.repeaterLastRssi != null) {
      pills.add(
        _buildMetaPill(
          context,
          icon: Icons.arrow_upward_rounded,
          label: '${advert.repeaterLastRssi} dBm',
        ),
      );
    }
    return pills;
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
      ..._buildSignalPills(context),
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
    final canToggleFavourite = !contact.isChannel;
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

    final primaryActions = <_ContactSheetAction>[
      if (canMessage)
        _ContactSheetAction(
          icon: Icons.message_outlined,
          label: l10n.messages,
          onTap: () async {
            Navigator.pop(context);
            await _openMessagesForContact(context, contact);
          },
        ),
      if (!contact.isChannel)
        _ContactSheetAction(
          icon: Icons.share_outlined,
          label: l10n.share,
          onTap: () async {
            Navigator.pop(context);
            final connectionProvider = context.read<ConnectionProvider>();
            final url = await connectionProvider.exportContactUrl(
              contact.publicKey,
            );
            if (url != null && context.mounted) {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.contactLinkCopiedToClipboard)),
                );
              }
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.failedToExportContact)),
              );
            }
          },
        ),
      if (canSetPath)
        _ContactSheetAction(
          icon: Icons.alt_route,
          label: l10n.contactSetPath,
          onTap: () async {
            Navigator.pop(context);
            await _showSetRouteDialog(context, contact);
          },
        ),
      if (!contact.isPublicChannel)
        _ContactSheetAction(
          icon: Icons.delete_outline_rounded,
          label: l10n.delete,
          destructive: true,
          onTap: () async {
            Navigator.pop(context);
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
    ];

    final secondaryActions = <_ContactSheetAction>[
      if (contact.displayLocation != null)
        _ContactSheetAction(
          icon: Icons.map_outlined,
          label: l10n.viewOnMap,
          onTap: () async {
            Navigator.pop(context);
            _showContactOnMap(context, contact);
          },
        ),
      if (contact.type == ContactType.room && !contact.isPublicChannel)
        _ContactSheetAction(
          icon: Icons.login,
          label:
              context
                      .read<ConnectionProvider>()
                      .getRoomLoginState(contact.publicKeyPrefix)
                      ?.isLoggedIn ==
                  true
              ? l10n.reLoginToRoom
              : l10n.loginToRoom,
          onTap: () async {
            Navigator.pop(context);
            _showRoomLoginDialog(context, contact);
          },
        ),
      if (canPreviewSensor)
        _ContactSheetAction(
          icon: Icons.visibility_outlined,
          label: l10n.preview,
          onTap: () async {
            Navigator.pop(context);
            await Future<void>.delayed(Duration.zero);
            if (!context.mounted) return;
            await _showSensorPreviewView(context, contact);
          },
        ),
      if (canAddToSensors)
        _ContactSheetAction(
          icon: isInSensors ? Icons.sensors : Icons.sensors_outlined,
          label: isInSensors ? l10n.contactInSensors : l10n.contactAddToSensors,
          enabled: !isInSensors,
          onTap: () async {
            Navigator.pop(context);
            await _addContactToSensors(context, contact);
          },
        ),
      if (!contact.isChannel)
        _ContactSheetAction(
          icon: Icons.route,
          label: l10n.trace,
          onTap: () async {
            Navigator.pop(context);
            _showTraceSheet(context, contact);
          },
        ),
      if (contact.type == ContactType.repeater)
        _ContactSheetAction(
          icon: Icons.hub_outlined,
          label: 'View Neighbours',
          onTap: () async {
            Navigator.pop(context);
            _showNeighbours(context, contact);
          },
        ),
      if (contact.type == ContactType.repeater ||
          contact.type == ContactType.room)
        _ContactSheetAction(
          icon: Icons.network_ping,
          label: 'Ping',
          onTap: () async {
            Navigator.pop(context);
            _pingRelay(context, contact);
          },
        ),
      if (!contact.isPublicChannel)
        _ContactSheetAction(
          icon: Icons.edit_outlined,
          label: l10n.editName,
          onTap: () async {
            Navigator.pop(context);
            _showNameOverrideDialog(context, contact);
          },
        ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ContactActionSheet(
        contact: contact,
        primaryActions: primaryActions,
        secondaryActions: secondaryActions,
        showFavouriteButton: canToggleFavourite,
        initialFavourite: contact.isFavourite,
        onClose: () => Navigator.pop(sheetContext),
        onToggleFavourite: !canToggleFavourite
            ? null
            : () async {
                final toggled = contact.toggleFavourite();
                final connectionProvider = context.read<ConnectionProvider>();
                await connectionProvider.addOrUpdateContact(toggled);
                if (context.mounted) {
                  await connectionProvider.getContact(contact.publicKey);
                }
              },
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

  void _showNeighbours(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _NeighboursSheet(contact: contact),
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

  void _pingRelay(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PingRelaySheet(contact: contact),
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
        final routeLabel = parsedRoute.hopCount == 0
            ? AppLocalizations.of(context)!.direct
            : parsedRoute.canonicalText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.contactRouteSet(routeLabel),
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
                onShowMetHistory: (contact) =>
                    showBTHomeMetHistorySheet(context, contact: contact),
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

class _ContactSheetAction {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  final bool destructive;
  final bool enabled;

  const _ContactSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.enabled = true,
  });
}

class _ContactActionSheet extends StatefulWidget {
  final Contact contact;
  final List<_ContactSheetAction> primaryActions;
  final List<_ContactSheetAction> secondaryActions;
  final bool showFavouriteButton;
  final bool initialFavourite;
  final VoidCallback onClose;
  final Future<void> Function()? onToggleFavourite;

  const _ContactActionSheet({
    required this.contact,
    required this.primaryActions,
    required this.secondaryActions,
    required this.showFavouriteButton,
    required this.initialFavourite,
    required this.onClose,
    required this.onToggleFavourite,
  });

  @override
  State<_ContactActionSheet> createState() => _ContactActionSheetState();
}

class _ContactActionSheetState extends State<_ContactActionSheet> {
  late bool _isFavourite;
  bool _isUpdatingFavourite = false;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.initialFavourite;
  }

  Future<void> _toggleFavourite() async {
    final callback = widget.onToggleFavourite;
    if (callback == null || _isUpdatingFavourite) {
      return;
    }

    setState(() {
      _isUpdatingFavourite = true;
    });

    try {
      await callback();
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavourite = !_isFavourite;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavourite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final contact = widget.contact;
    final title = contact.getLocalizedDisplayName(context);
    final routeLabel = !contact.routeHasPath || contact.routeHopCount <= 0
        ? l10n.direct
        : contact.routeCanonicalText;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ContactAvatar(
                      contact: contact,
                      radius: 28,
                      displayName: title,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.45,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.isPublicChannel
                                ? l10n.broadcastToAllNearby
                                : contact.publicKeyShort,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: contact.isPublicChannel
                                  ? null
                                  : 'monospace',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ContactSheetChip(
                                icon:
                                    contact.routeHasPath &&
                                        contact.routeHopCount > 0
                                    ? Icons.alt_route
                                    : Icons.north_east_rounded,
                                label: routeLabel,
                                monospace:
                                    contact.routeHasPath &&
                                    contact.routeHopCount > 0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showFavouriteButton)
                        IconButton.filledTonal(
                          onPressed: _isUpdatingFavourite
                              ? null
                              : _toggleFavourite,
                          tooltip: l10n.favourites,
                          icon: _isUpdatingFavourite
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  _isFavourite
                                      ? Icons.star_rounded
                                      : Icons.star_outline,
                                  color: _isFavourite ? Colors.amber : null,
                                ),
                        ),
                      if (widget.showFavouriteButton) const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onClose,
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.primaryActions.isNotEmpty) ...[
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    const minTileWidth = 104.0;
                    final actionCount = widget.primaryActions.length;
                    final maxColumnsByWidth =
                        ((constraints.maxWidth + spacing) /
                                (minTileWidth + spacing))
                            .floor()
                            .clamp(1, 4);
                    var columnCount = actionCount.clamp(1, maxColumnsByWidth);
                    if (actionCount > 3 &&
                        columnCount > 2 &&
                        actionCount % columnCount == 1) {
                      columnCount -= 1;
                    }
                    final itemWidth =
                        (constraints.maxWidth - (spacing * (columnCount - 1))) /
                        columnCount;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final action in widget.primaryActions)
                          SizedBox(
                            width: itemWidth,
                            child: _ContactPrimaryActionButton(action: action),
                          ),
                      ],
                    );
                  },
                ),
              ],
              if (widget.secondaryActions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.others,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < widget.secondaryActions.length;
                        index++
                      )
                        _ContactSecondaryActionTile(
                          action: widget.secondaryActions[index],
                          showDivider:
                              index != widget.secondaryActions.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactPrimaryActionButton extends StatelessWidget {
  final _ContactSheetAction action;

  const _ContactPrimaryActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = action.destructive ? colorScheme.error : colorScheme.primary;
    final backgroundColor = action.destructive
        ? colorScheme.errorContainer.withValues(alpha: 0.82)
        : Color.alphaBlend(
            accent.withValues(alpha: 0.12),
            colorScheme.surfaceContainerLow,
          );
    final foregroundColor = action.destructive
        ? colorScheme.onErrorContainer
        : accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action.enabled ? action.onTap : null,
        child: Ink(
          height: 80,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: action.destructive
                  ? colorScheme.error.withValues(alpha: 0.18)
                  : accent.withValues(alpha: 0.14),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(action.icon, color: foregroundColor, size: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: action.enabled
                        ? (action.destructive
                              ? colorScheme.onErrorContainer
                              : colorScheme.onSurface)
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactSecondaryActionTile extends StatelessWidget {
  final _ContactSheetAction action;
  final bool showDivider;

  const _ContactSecondaryActionTile({
    required this.action,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = action.enabled
        ? (action.destructive
              ? colorScheme.error
              : colorScheme.onSurfaceVariant)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    final textColor = action.enabled
        ? (action.destructive ? colorScheme.error : colorScheme.onSurface)
        : colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          enabled: action.enabled,
          onTap: action.enabled ? action.onTap : null,
          leading: Icon(action.icon, color: iconColor),
          title: Text(
            action.label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          minLeadingWidth: 18,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
      ],
    );
  }
}

class _ContactSheetChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool monospace;

  const _ContactSheetChip({
    required this.icon,
    required this.label,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
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

/// Bottom sheet that sends "neighbors" text command to a repeater and shows results.
class _NeighboursSheet extends StatefulWidget {
  final Contact contact;

  const _NeighboursSheet({required this.contact});

  @override
  State<_NeighboursSheet> createState() => _NeighboursSheetState();
}

class _NeighboursSheetState extends State<_NeighboursSheet> {
  bool _loading = true;
  String? _error;
  List<_Neighbour> _neighbours = const [];

  @override
  void initState() {
    super.initState();
    _fetchNeighbours();
  }

  Future<void> _fetchNeighbours() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final previousOnMessageReceived = connectionProvider.onMessageReceived;

    String? responseText;
    void onMessage(message) {
      if (message.senderPublicKeyPrefix != null &&
          widget.contact.publicKey
              .sublist(0, 6)
              .every((b) => message.senderPublicKeyPrefix!.contains(b))) {
        responseText = message.text;
      }
    }

    void sheetListener(message) {
      previousOnMessageReceived?.call(message);
      onMessage(message);
    }

    connectionProvider.onMessageReceived = sheetListener;

    try {
      await connectionProvider.sendTextMessage(
        contactPublicKey: widget.contact.publicKey,
        text: 'neighbors',
      );

      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (responseText != null) break;
      }

      if (!mounted) return;

      if (responseText == null) {
        setState(() {
          _loading = false;
          _error = 'No response from repeater (timeout)';
        });
        return;
      }

      final text = responseText!;
      if (text.toLowerCase().contains('unknown')) {
        setState(() {
          _loading = false;
          _error = 'Neighbours feature not supported by this firmware';
        });
        return;
      }
      if (text.toLowerCase().contains('-none-') || text.trim().isEmpty) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final parsed = <_Neighbour>[];
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split(':');
        if (parts.length >= 3) {
          final keyHex = parts[0];
          final timestampOrSeconds = int.tryParse(parts[1]);
          final snrRaw = int.tryParse(parts[2]);
          final isDurationSeconds =
              timestampOrSeconds != null && timestampOrSeconds < 1000000000;
          parsed.add(
            _Neighbour(
              publicKeyHex: keyHex,
              lastSeenAt: !isDurationSeconds && timestampOrSeconds != null
                  ? timestampOrSeconds >= 1000000000000
                        ? DateTime.fromMillisecondsSinceEpoch(
                            timestampOrSeconds,
                          )
                        : DateTime.fromMillisecondsSinceEpoch(
                            timestampOrSeconds * 1000,
                          )
                  : null,
              lastSeenSeconds:
                  isDurationSeconds ? timestampOrSeconds : null,
              snrDb: snrRaw != null ? snrRaw / 4.0 : null,
            ),
          );
        }
      }

      setState(() {
        _loading = false;
        _neighbours = parsed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed: $e';
      });
    } finally {
      if (identical(connectionProvider.onMessageReceived, sheetListener)) {
        connectionProvider.onMessageReceived = previousOnMessageReceived;
      }
    }
  }

  Contact? _resolveNeighbourContact(String keyHex) {
    final contactsProvider = context.read<ContactsProvider>();
    for (final contact in contactsProvider.contacts) {
      if (contact.publicKeyHex.toLowerCase().startsWith(keyHex.toLowerCase())) {
        return contact;
      }
    }
    return null;
  }

  String _resolveNeighbourName(String keyHex) {
    final contact = _resolveNeighbourContact(keyHex);
    if (contact != null) {
      return contact.displayName;
    }
    return keyHex.length > 12 ? '${keyHex.substring(0, 12)}...' : keyHex;
  }

  String _formatAge(BuildContext context, _Neighbour neighbour) {
    if (neighbour.lastSeenAt != null) {
      return DateTime.now()
          .difference(neighbour.lastSeenAt!)
          .toLocalizedTimeAgoWithSeconds(context);
    }
    if (neighbour.lastSeenSeconds != null) {
      if (neighbour.lastSeenSeconds! < 1) {
        return AppLocalizations.of(context)!.justNow;
      }
      return Duration(
        seconds: neighbour.lastSeenSeconds!,
      ).toLocalizedTimeAgoWithSeconds(context);
    }
    return AppLocalizations.of(context)!.justNow;
  }

  List<_MappedNeighbour> _mappedNeighbours() {
    return _neighbours
        .map((neighbour) {
          final contact = _resolveNeighbourContact(neighbour.publicKeyHex);
          final location = contact?.displayLocation;
          if (contact == null || location == null) {
            return null;
          }
          return _MappedNeighbour(
            neighbour: neighbour,
            contact: contact,
            location: LatLng(location.latitude, location.longitude),
          );
        })
        .whereType<_MappedNeighbour>()
        .toList();
  }

  Widget _buildSummaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeaterMarker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 132),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.contact.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.hub_outlined, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildNeighbourMarker(BuildContext context, _MappedNeighbour mapped) {
    final quality = linkQualityLabel(null, mapped.neighbour.snrDb);
    final qualityColor = linkQualityColor(quality);
    final ageLabel = _formatAge(context, mapped.neighbour);
    final signalLabel = mapped.neighbour.snrDb == null
        ? quality
        : '$quality • ${mapped.neighbour.snrDb!.toStringAsFixed(1)} dB';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 146),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: qualityColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            signalLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: qualityColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            mapped.contact.isRepeater
                ? Icons.router_outlined
                : Icons.location_on_outlined,
            color: qualityColor,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 148),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mapped.contact.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ageLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteMap(
    BuildContext context, {
    required LatLng repeaterLocation,
    required List<_MappedNeighbour> mappedNeighbours,
  }) {
    final points = <LatLng>[
      repeaterLocation,
      ...mappedNeighbours.map((mapped) => mapped.location),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: flutter_map.FlutterMap(
          options: flutter_map.MapOptions(
            initialCameraFit: flutter_map.CameraFit.bounds(
              bounds: flutter_map.LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(42),
            ),
          ),
          children: [
            flutter_map.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.meshcore.sar',
            ),
            flutter_map.PolylineLayer(
              polylines: mappedNeighbours.map((mapped) {
                final quality = linkQualityLabel(null, mapped.neighbour.snrDb);
                final qualityColor = linkQualityColor(quality);
                return flutter_map.Polyline(
                  points: [repeaterLocation, mapped.location],
                  color: qualityColor.withValues(alpha: 0.9),
                  strokeWidth: 4,
                  borderColor: Colors.white.withValues(alpha: 0.7),
                  borderStrokeWidth: 1.5,
                );
              }).toList(),
            ),
            flutter_map.MarkerLayer(
              markers: [
                flutter_map.Marker(
                  point: repeaterLocation,
                  width: 150,
                  height: 74,
                  child: _buildRepeaterMarker(context),
                ),
                ...mappedNeighbours.map(
                  (mapped) => flutter_map.Marker(
                    point: mapped.location,
                    width: 164,
                    height: 112,
                    child: _buildNeighbourMarker(context, mapped),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repeaterDisplayLocation = widget.contact.displayLocation;
    final repeaterLocation = repeaterDisplayLocation == null
        ? null
        : LatLng(
            repeaterDisplayLocation.latitude,
            repeaterDisplayLocation.longitude,
          );
    final mappedNeighbours = _mappedNeighbours();
    final missingLocations = _neighbours.length - mappedNeighbours.length;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Neighbours of ${widget.contact.displayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _neighbours.isEmpty
                  ? const Center(child: Text('No neighbours found'))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSummaryChip(
                                context,
                                icon: Icons.route_outlined,
                                label:
                                    '${_neighbours.length} neighbour${_neighbours.length == 1 ? '' : 's'}',
                              ),
                              _buildSummaryChip(
                                context,
                                icon: Icons.map_outlined,
                                label: '${mappedNeighbours.length} on map',
                              ),
                              if (missingLocations > 0)
                                _buildSummaryChip(
                                  context,
                                  icon: Icons.location_off_outlined,
                                  label: '$missingLocations without GPS',
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: repeaterLocation == null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        '${widget.contact.displayName} has no saved location, so neighbour routes cannot be drawn on the map yet.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : mappedNeighbours.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: Text(
                                        'Neighbours responded, but no geolocated contacts matched saved nodes to plot. Recent neighbour: ${_resolveNeighbourName(_neighbours.first.publicKeyHex)} • ${_formatAge(context, _neighbours.first)}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : _buildRouteMap(
                                    context,
                                    repeaterLocation: repeaterLocation,
                                    mappedNeighbours: mappedNeighbours,
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Neighbour {
  final String publicKeyHex;
  final DateTime? lastSeenAt;
  final int? lastSeenSeconds;
  final double? snrDb;

  const _Neighbour({
    required this.publicKeyHex,
    this.lastSeenAt,
    this.lastSeenSeconds,
    this.snrDb,
  });
}

class _MappedNeighbour {
  final _Neighbour neighbour;
  final Contact contact;
  final LatLng location;

  const _MappedNeighbour({
    required this.neighbour,
    required this.contact,
    required this.location,
  });
}

/// Bottom sheet for pinging a relay/repeater with history and distance.
class _PingRelaySheet extends StatefulWidget {
  final Contact contact;

  const _PingRelaySheet({required this.contact});

  @override
  State<_PingRelaySheet> createState() => _PingRelaySheetState();
}

class _PingEntry {
  final RelayPingResult result;
  final DateTime timestamp;
  final String? distance;

  const _PingEntry({
    required this.result,
    required this.timestamp,
    this.distance,
  });
}

class _PingRelaySheetState extends State<_PingRelaySheet> {
  bool _pinging = false;
  final List<_PingEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _doPing();
  }

  Future<void> _doPing() async {
    setState(() => _pinging = true);
    final connectionProvider = context.read<ConnectionProvider>();
    final distance = _distanceText();
    final result = await connectionProvider.pingRelay(widget.contact);
    if (!mounted) return;
    setState(() {
      _pinging = false;
      _history.insert(
        0,
        _PingEntry(
          result: result,
          timestamp: DateTime.now(),
          distance: distance,
        ),
      );
    });
  }

  String? _distanceText() {
    final location = widget.contact.displayLocation;
    if (location == null) return null;
    final currentPosition = LocationTrackingService().currentPosition;
    if (currentPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      location.latitude,
      location.longitude,
    );
    if (meters < 1000) return '${meters.round()} m';
    if (meters < 10000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
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
          Icon(icon, size: 12, color: iconColor ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnrPill(BuildContext context, String direction, double snrDb) {
    final quality = linkQualityLabel(null, snrDb);
    final color = linkQualityColor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            direction == 'there'
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${snrDb.toStringAsFixed(1)} dB',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, _PingEntry entry, int seq) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = entry.result;
    final age = DateTime.now().difference(entry.timestamp);
    final timeAgo = age.toLocalizedTimeAgoWithSeconds(context);

    if (!r.success) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.error.withValues(alpha: 0.15),
              child: Text(
                '$seq',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Timeout',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              timeAgo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Text(
                  '$seq',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildPill(
                context,
                icon: Icons.timer_outlined,
                label: '${r.durationMs} ms',
              ),
              const SizedBox(width: 6),
              _buildSnrPill(context, 'there', r.snrThere),
              const SizedBox(width: 6),
              _buildSnrPill(context, 'back', r.snrBack),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Row(
              children: [
                if (entry.distance != null) ...[
                  Icon(Icons.straighten, size: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(width: 3),
                  Text(
                    entry.distance!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.schedule, size: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(width: 3),
                Text(
                  timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = widget.contact.displayName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ping $displayName',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_history.isNotEmpty)
                  IconButton(
                    onPressed: () => setState(() => _history.clear()),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Clear history',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _pinging ? null : _doPing,
                  icon: _pinging
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.network_ping, size: 18),
                  label: Text(_pinging ? 'Pinging...' : 'Ping Again'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_history.isEmpty && _pinging)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No results yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    final seq = _history.length - index;
                    return _buildResultRow(context, entry, seq);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
