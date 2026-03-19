import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../providers/contacts_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/map_provider.dart';
import '../providers/messages_provider.dart';
import '../services/message_destination_preferences.dart';
import '../utils/contact_grouping.dart';
import '../utils/avatar_label_helper.dart';
import '../widgets/common/contact_avatar.dart';
import '../widgets/contacts/contact_tile.dart';
import '../widgets/contacts/add_channel_dialog.dart';
import 'add_contact_screen.dart';

class ContactsTab extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const ContactsTab({
    super.key,
    this.onNavigateToMap,
    this.onNavigateToMessages,
  });

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Position? _currentPosition;
  final Map<ContactSection, String> _sectionFilters = {
    ContactSection.teamMembers: '',
    ContactSection.repeaters: '',
    ContactSection.sensors: '',
    ContactSection.rooms: '',
    ContactSection.channels: '',
  };
  late final Map<ContactSection, TextEditingController> _filterControllers;
  final Map<ContactSection, ContactSortMode> _sortModes = {
    ContactSection.teamMembers: ContactSortMode.lastSeen,
    ContactSection.repeaters: ContactSortMode.lastSeen,
    ContactSection.sensors: ContactSortMode.lastSeen,
    ContactSection.rooms: ContactSortMode.lastSeen,
    ContactSection.channels: ContactSortMode.alphabetical,
  };

  @override
  void initState() {
    super.initState();
    _filterControllers = {
      for (final section in ContactSection.values)
        section: TextEditingController(text: _sectionFilters[section] ?? ''),
    };
    _getCurrentLocation();
    // Mark all contacts as viewed when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().markAllAsViewed();
    });
  }

  @override
  void dispose() {
    for (final controller in _filterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Silently fail if location not available
      debugPrint('Failed to get location: $e');
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    await appProvider.refresh();
    // Also refresh location
    if (!mounted) return;
    await _getCurrentLocation();
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else if (meters < 10000) {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  List<Contact> _filterContactsForSection(
    List<Contact> contacts,
    ContactSection section,
  ) {
    final query = (_sectionFilters[section] ?? '').trim().toLowerCase();
    if (query.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final advertisedName = contact.advName.toLowerCase();
      return name.contains(query) ||
          advertisedName.contains(query) ||
          ContactGrouping.contactMatchesInferredGroupLabel(contact, query);
    }).toList();
  }

  bool _contactMatchesFilter(Contact contact, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final name = contact.displayName.toLowerCase();
    final advertisedName = contact.advName.toLowerCase();
    return name.contains(normalizedQuery) ||
        advertisedName.contains(normalizedQuery) ||
        ContactGrouping.contactMatchesInferredGroupLabel(
          contact,
          normalizedQuery,
        );
  }

  bool _sectionHasActiveFilter(ContactSection section) {
    return (_sectionFilters[section] ?? '').trim().isNotEmpty;
  }

  bool _showSavedGroupsForSection(ContactSection section) {
    return !_sectionHasActiveFilter(section);
  }

  List<_RenderedSavedGroup> _buildSavedGroupsForSection(
    ContactsProvider contactsProvider,
    List<Contact> contacts,
    ContactSection section,
  ) {
    return contactsProvider
        .savedGroupsForSection(section.name)
        .map((group) {
          final matches = contacts
              .where((contact) => _contactMatchesSavedGroup(contact, group))
              .toList();
          return _RenderedSavedGroup(group: group, contacts: matches);
        })
        .where((group) => group.contacts.isNotEmpty)
        .toList()
      ..sort(
        (a, b) => b.contacts.first.lastSeenTime.compareTo(
          a.contacts.first.lastSeenTime,
        ),
      );
  }

  bool _contactMatchesSavedGroup(Contact contact, SavedContactGroup group) {
    final matchPrefixes = group.matchPrefixes;
    if (matchPrefixes != null && matchPrefixes.isNotEmpty) {
      final inferredLabel = ContactGrouping.inferredGroupLabelForContact(
        contact,
      )?.toLowerCase();
      if (inferredLabel == null) {
        return false;
      }
      return matchPrefixes.any(
        (prefix) => prefix.toLowerCase() == inferredLabel,
      );
    }

    return _contactMatchesFilter(contact, group.query);
  }

  Future<void> _toggleSavedGroupForSection(
    BuildContext context,
    ContactsProvider contactsProvider,
    ContactSection section,
  ) async {
    final filter = (_sectionFilters[section] ?? '').trim();
    if (filter.isEmpty) {
      return;
    }

    final alreadySaved = contactsProvider.hasSavedGroupForFilter(
      section.name,
      filter,
    );

    if (alreadySaved) {
      await contactsProvider.removeSavedGroupForFilter(section.name, filter);
    } else {
      await contactsProvider.addSavedGroupForFilter(
        section.name,
        filter,
        label: filter,
      );
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alreadySaved
              ? 'Removed saved group "$filter"'
              : 'Saved group "$filter"',
        ),
      ),
    );
  }

  Future<void> _createAutoGroupsForSection(
    BuildContext context,
    ContactsProvider contactsProvider,
    ContactSection section,
    List<Contact> contacts, {
    int? maxNamedGroups,
    String? overflowGroupLabel,
    String emptyMessage = 'No auto groups available',
    String successMessage = 'Updated auto groups',
  }) async {
    final inferredGroups = ContactGrouping.inferGroups(
      contacts,
      maxNamedGroups: maxNamedGroups,
      overflowGroupLabel: overflowGroupLabel,
    );

    final now = DateTime.now();
    final groups = inferredGroups
        .map(
          (group) => SavedContactGroup(
            id: '${ContactsProvider.autoGroupIdPrefix}${section.name}_${group.key}',
            sectionKey: section.name,
            label: group.label,
            query: group.label,
            createdAt: now,
            matchPrefixes: group.matchPrefixes,
            isAutoGroup: true,
          ),
        )
        .toList();

    await contactsProvider.replaceAutoGroupsForSection(section.name, groups);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(groups.isEmpty ? emptyMessage : successMessage)),
    );
  }

  List<Contact> _sortContacts(List<Contact> contacts, ContactSection section) {
    final sorted = List<Contact>.from(contacts);
    final sortMode =
        _sortModes[section] ??
        (section == ContactSection.channels
            ? ContactSortMode.alphabetical
            : ContactSortMode.lastSeen);

    sorted.sort((a, b) {
      if (sortMode == ContactSortMode.alphabetical) {
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      }

      if (sortMode == ContactSortMode.distance) {
        final distanceA = _distanceFromCurrentPosition(a);
        final distanceB = _distanceFromCurrentPosition(b);

        if (distanceA != null && distanceB != null) {
          final distanceCompare = distanceA.compareTo(distanceB);
          if (distanceCompare != 0) return distanceCompare;
        } else if (distanceA != null) {
          return -1;
        } else if (distanceB != null) {
          return 1;
        }
      }

      final lastSeenCompare = b.lastSeenTime.compareTo(a.lastSeenTime);
      if (lastSeenCompare != 0) {
        return lastSeenCompare;
      }

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return sorted;
  }

  double? _distanceFromCurrentPosition(Contact contact) {
    final currentPosition = _currentPosition;
    final contactLocation = contact.displayLocation;
    if (currentPosition == null || contactLocation == null) {
      return null;
    }

    return _calculateDistanceInMeters(
      currentPosition.latitude,
      currentPosition.longitude,
      contactLocation.latitude,
      contactLocation.longitude,
    );
  }

  /// Show the add channel sheet
  Future<void> _showAddChannelDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddChannelSheet(
            onCreateChannel: (name, secret) async {
              final connectionProvider = context.read<ConnectionProvider>();
              try {
                await connectionProvider.createChannel(
                  channelName: name,
                  channelSecret: secret,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.channelCreatedSuccessfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.channelCreationFailed(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                rethrow; // Re-throw to let dialog handle the error state
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openAddContactScreen(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddContactScreen()));
  }

  Future<void> _showDeleteChannelDialog(
    BuildContext context,
    Contact channel,
  ) async {
    if (channel.isPublicChannel) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteChannel),
        content: Text(l10n.deleteChannelConfirmation(channel.advName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final channelIdx = channel.publicKey.length > 1
          ? channel.publicKey[1]
          : 0;
      await context.read<ConnectionProvider>().deleteChannel(channelIdx);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.channelDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.channelDeletionFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMessagesForChannel(
    BuildContext context,
    Contact channel,
  ) async {
    final messagesProvider = context.read<MessagesProvider>();
    await MessageDestinationPreferences.setDestination(
      MessageDestinationPreferences.destinationTypeChannel,
      recipientPublicKey: channel.publicKeyHex,
    );
    messagesProvider.navigateToDestination(
      MessageDestinationPreferences.destinationTypeChannel,
      recipientPublicKeyHex: channel.publicKeyHex,
    );
    widget.onNavigateToMessages?.call();
  }

  void _showChannelOnMap(BuildContext context, Contact channel) {
    final location = channel.displayLocation;
    if (location == null) {
      return;
    }

    context.read<MapProvider>().navigateToLocation(
      location: LatLng(location.latitude, location.longitude),
    );
    widget.onNavigateToMap?.call();
  }

  Future<void> _exportHashChannelPskBase64(
    BuildContext context,
    Contact channel,
  ) async {
    final channelName = channel.advName.trim();
    if (!Channel.isHashChannelName(channelName)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final copiedMessage = AppLocalizations.of(
      context,
    )!.copiedToClipboard('psk_base64');

    await Clipboard.setData(
      ClipboardData(text: Channel.pskBase64ForHashChannelName(channelName)),
    );
    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(copiedMessage)));
  }

  void _showChannelActionSheet(BuildContext context, Contact channel) {
    final l10n = AppLocalizations.of(context)!;
    final canExportHashChannelPsk = Channel.isHashChannelName(
      channel.advName.trim(),
    );

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
              leading: Icon(Icons.message_outlined),
              title: Text(l10n.messages),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _openMessagesForChannel(context, channel);
              },
            ),
            if (channel.displayLocation != null)
              ListTile(
                leading: Icon(Icons.map_outlined),
                title: Text(l10n.viewOnMap),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showChannelOnMap(context, channel);
                },
              ),
            if (canExportHashChannelPsk)
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: Text('${l10n.exportToClipboard} psk_base64'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _exportHashChannelPskBase64(context, channel);
                },
              ),
            if (!channel.isPublicChannel)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n.deleteChannel,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future<void>.delayed(Duration.zero);
                  if (!context.mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    _showDeleteChannelDialog(context, channel);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _sectionAccentColor(BuildContext context, ContactSection section) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (section) {
      case ContactSection.teamMembers:
        return colorScheme.primary;
      case ContactSection.repeaters:
        return colorScheme.tertiary;
      case ContactSection.sensors:
        return colorScheme.secondary;
      case ContactSection.rooms:
        return colorScheme.primary;
      case ContactSection.channels:
        return Color.alphaBlend(
          colorScheme.tertiary.withValues(alpha: 0.65),
          colorScheme.primary.withValues(alpha: 0.35),
        );
    }
  }

  IconData _sortModeIcon(ContactSortMode mode) {
    switch (mode) {
      case ContactSortMode.lastSeen:
        return Icons.schedule_rounded;
      case ContactSortMode.distance:
        return Icons.near_me_rounded;
      case ContactSortMode.alphabetical:
        return Icons.sort_by_alpha_rounded;
    }
  }

  String _sortModeLabel(AppLocalizations l10n, ContactSortMode mode) {
    switch (mode) {
      case ContactSortMode.lastSeen:
        return l10n.lastSeen;
      case ContactSortMode.distance:
        return l10n.distance;
      case ContactSortMode.alphabetical:
        return 'A-Z';
    }
  }

  List<ContactSortMode> _availableSortModes(ContactSection section) {
    switch (section) {
      case ContactSection.channels:
        return const [ContactSortMode.alphabetical, ContactSortMode.lastSeen];
      default:
        return const [
          ContactSortMode.lastSeen,
          ContactSortMode.distance,
          ContactSortMode.alphabetical,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          final colorScheme = Theme.of(context).colorScheme;
          final appProvider = context.watch<AppProvider>();
          final messagesProvider = context.watch<MessagesProvider>();
          final connectionProvider = context.watch<ConnectionProvider>();
          final allChatContacts = _sortContacts(
            contactsProvider.chatContacts,
            ContactSection.teamMembers,
          );
          final allRepeaters = _sortContacts(
            contactsProvider.repeaters,
            ContactSection.repeaters,
          );
          final allSensors = _sortContacts(
            contactsProvider.sensorContacts,
            ContactSection.sensors,
          );
          final allRooms = _sortContacts(
            contactsProvider.rooms,
            ContactSection.rooms,
          );
          final allChannels = _sortContacts(
            contactsProvider.channels,
            ContactSection.channels,
          );
          final chatContacts = _filterContactsForSection(
            allChatContacts,
            ContactSection.teamMembers,
          );
          final savedTeamGroups = _buildSavedGroupsForSection(
            contactsProvider,
            allChatContacts,
            ContactSection.teamMembers,
          );
          final visibleSavedTeamGroups =
              _showSavedGroupsForSection(ContactSection.teamMembers)
              ? savedTeamGroups
              : const <_RenderedSavedGroup>[];
          final repeaters = _filterContactsForSection(
            allRepeaters,
            ContactSection.repeaters,
          );
          final savedRepeaterGroups = _buildSavedGroupsForSection(
            contactsProvider,
            allRepeaters,
            ContactSection.repeaters,
          );
          final visibleSavedRepeaterGroups =
              _showSavedGroupsForSection(ContactSection.repeaters)
              ? savedRepeaterGroups
              : const <_RenderedSavedGroup>[];
          final ungroupedRepeaters = _excludeGroupedContacts(
            repeaters,
            visibleSavedRepeaterGroups,
          );
          final showRepeatersOthersGroup =
              visibleSavedRepeaterGroups.length > 1 &&
              ungroupedRepeaters.isNotEmpty;
          final sensors = _filterContactsForSection(
            allSensors,
            ContactSection.sensors,
          );
          final savedSensorGroups = _buildSavedGroupsForSection(
            contactsProvider,
            allSensors,
            ContactSection.sensors,
          );
          final visibleSavedSensorGroups =
              _showSavedGroupsForSection(ContactSection.sensors)
              ? savedSensorGroups
              : const <_RenderedSavedGroup>[];
          final rooms = _filterContactsForSection(
            allRooms,
            ContactSection.rooms,
          );
          final savedRoomGroups = _buildSavedGroupsForSection(
            contactsProvider,
            allRooms,
            ContactSection.rooms,
          );
          final visibleSavedRoomGroups =
              _showSavedGroupsForSection(ContactSection.rooms)
              ? savedRoomGroups
              : const <_RenderedSavedGroup>[];
          final filteredChannels = _filterContactsForSection(
            allChannels,
            ContactSection.channels,
          );
          final savedChannelGroups = _buildSavedGroupsForSection(
            contactsProvider,
            allChannels,
            ContactSection.channels,
          );
          final visibleSavedChannelGroups =
              _showSavedGroupsForSection(ContactSection.channels)
              ? savedChannelGroups
              : const <_RenderedSavedGroup>[];
          final showFavouritesSection =
              appProvider.isContactsSectionEnabled(
                ContactsTabSection.favourites,
              ) &&
              contactsProvider.favouriteContacts.isNotEmpty;
          final showTeamMembersSection =
              appProvider.isContactsSectionEnabled(
                ContactsTabSection.teamMembers,
              ) &&
              allChatContacts.isNotEmpty;
          final showRepeatersSection =
              appProvider.isContactsSectionEnabled(
                ContactsTabSection.repeaters,
              ) &&
              allRepeaters.isNotEmpty;
          final showSensorsSection =
              appProvider.isContactsSectionEnabled(
                ContactsTabSection.sensors,
              ) &&
              allSensors.isNotEmpty;
          final showRoomsSection =
              appProvider.isContactsSectionEnabled(ContactsTabSection.rooms) &&
              allRooms.isNotEmpty;
          final showChannelsSection =
              appProvider.isContactsSectionEnabled(
                ContactsTabSection.channels,
              ) &&
              allChannels.isNotEmpty;
          final hasAnyContactData =
              allChatContacts.isNotEmpty ||
              allRepeaters.isNotEmpty ||
              allSensors.isNotEmpty ||
              allRooms.isNotEmpty ||
              allChannels.isNotEmpty;
          final hasAnyVisibleSection =
              showFavouritesSection ||
              showTeamMembersSection ||
              showRepeatersSection ||
              showSensorsSection ||
              showRoomsSection ||
              showChannelsSection;

          if (!hasAnyContactData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.noContactsYet,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.connectToDeviceToLoadContacts,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (connectionProvider.deviceInfo.isConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddContactScreen(context),
                        icon: Icon(Icons.person_add_alt_1_outlined),
                        label: Text(l10n.addContact),
                      ),
                    ),
                ],
              ),
            );
          }

          if (!hasAnyVisibleSection) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 56,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All contacts sections are hidden',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable one or more sections in Settings to show contacts here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                if (showFavouritesSection)
                  _SectionCard(
                    accentColor: Colors.amber,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.favourites,
                          count: contactsProvider.favouriteContacts.length,
                          icon: Icons.star_rounded,
                          accentColor: Colors.amber,
                        ),
                        ..._buildContactSectionItems(
                          contactsProvider.favouriteContacts,
                        ),
                      ],
                    ),
                  ),

                if (showTeamMembersSection)
                  _SectionCard(
                    accentColor: _sectionAccentColor(
                      context,
                      ContactSection.teamMembers,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.teamMembers,
                          count: chatContacts.length,
                          icon: Icons.people_alt_rounded,
                          accentColor: _sectionAccentColor(
                            context,
                            ContactSection.teamMembers,
                          ),
                        ),
                        _buildSectionFilterField(
                          context,
                          ContactSection.teamMembers,
                          contactsProvider,
                          onSecondaryAction: () => _createAutoGroupsForSection(
                            context,
                            contactsProvider,
                            ContactSection.teamMembers,
                            allChatContacts,
                            emptyMessage: 'No contact auto groups available',
                            successMessage: 'Updated contact auto groups',
                          ),
                          secondaryActionIcon: Icons.auto_awesome_outlined,
                          secondaryActionTooltip: 'Auto group',
                        ),
                        ..._buildSavedGroupCards(
                          visibleSavedTeamGroups,
                          ContactSection.teamMembers,
                        ),
                        if (chatContacts.isEmpty &&
                            _sectionHasActiveFilter(ContactSection.teamMembers))
                          _buildNoFilterResults(context)
                        else
                          ..._buildContactSectionItems(
                            _excludeGroupedContacts(
                              chatContacts,
                              visibleSavedTeamGroups,
                            ),
                          ),
                      ],
                    ),
                  ),

                if (showRepeatersSection)
                  _SectionCard(
                    accentColor: _sectionAccentColor(
                      context,
                      ContactSection.repeaters,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.repeaters,
                          count: repeaters.length,
                          icon: Icons.router_rounded,
                          accentColor: _sectionAccentColor(
                            context,
                            ContactSection.repeaters,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (connectionProvider.deviceInfo.isConnected)
                                IconButton(
                                  icon: const Icon(Icons.radar, size: 20),
                                  tooltip: 'Discover repeaters',
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    foregroundColor: _sectionAccentColor(
                                      context,
                                      ContactSection.repeaters,
                                    ),
                                    backgroundColor: _sectionAccentColor(
                                      context,
                                      ContactSection.repeaters,
                                    ).withValues(alpha: 0.10),
                                  ),
                                  onPressed: () {
                                    context
                                        .read<ConnectionProvider>()
                                        .discoverNodeType(advertType: 2);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.repeaterDiscoverySent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        _buildSectionFilterField(
                          context,
                          ContactSection.repeaters,
                          contactsProvider,
                          onSecondaryAction: () => _createAutoGroupsForSection(
                            context,
                            contactsProvider,
                            ContactSection.repeaters,
                            allRepeaters,
                            maxNamedGroups: 2,
                            overflowGroupLabel: 'Others',
                            emptyMessage: 'No repeater auto groups available',
                            successMessage: 'Updated repeater auto groups',
                          ),
                          secondaryActionIcon: Icons.auto_awesome_outlined,
                          secondaryActionTooltip: 'Auto group',
                        ),
                        ..._buildSavedGroupCards(
                          visibleSavedRepeaterGroups,
                          ContactSection.repeaters,
                        ),
                        if (repeaters.isEmpty &&
                            _sectionHasActiveFilter(ContactSection.repeaters))
                          _buildNoFilterResults(context)
                        else if (showRepeatersOthersGroup)
                          _InferredContactGroupCard(
                            label: l10n.others,
                            contacts: ungroupedRepeaters,
                            compactContacts: true,
                            currentPosition: _currentPosition,
                            calculateDistance: _calculateDistanceInMeters,
                            formatDistance: _formatDistance,
                            onNavigateToMap: widget.onNavigateToMap,
                            onNavigateToMessages: widget.onNavigateToMessages,
                          )
                        else
                          ..._buildContactSectionItems(
                            ungroupedRepeaters,
                            compact: true,
                          ),
                      ],
                    ),
                  ),

                if (showSensorsSection)
                  _SectionCard(
                    accentColor: _sectionAccentColor(
                      context,
                      ContactSection.sensors,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.sensors,
                          count: sensors.length,
                          icon: Icons.sensors_rounded,
                          accentColor: _sectionAccentColor(
                            context,
                            ContactSection.sensors,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (connectionProvider.deviceInfo.isConnected)
                                IconButton(
                                  icon: const Icon(Icons.radar, size: 20),
                                  tooltip: 'Discover sensors',
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    foregroundColor: _sectionAccentColor(
                                      context,
                                      ContactSection.sensors,
                                    ),
                                    backgroundColor: _sectionAccentColor(
                                      context,
                                      ContactSection.sensors,
                                    ).withValues(alpha: 0.10),
                                  ),
                                  onPressed: () {
                                    context
                                        .read<ConnectionProvider>()
                                        .discoverNodeType(advertType: 4);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.sensorDiscoverySent),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        _buildSectionFilterField(
                          context,
                          ContactSection.sensors,
                          contactsProvider,
                        ),
                        ..._buildSavedGroupCards(
                          visibleSavedSensorGroups,
                          ContactSection.sensors,
                        ),
                        if (sensors.isEmpty &&
                            _sectionHasActiveFilter(ContactSection.sensors))
                          _buildNoFilterResults(context)
                        else
                          ..._buildContactSectionItems(
                            _excludeGroupedContacts(
                              sensors,
                              visibleSavedSensorGroups,
                            ),
                          ),
                      ],
                    ),
                  ),

                if (showRoomsSection)
                  _SectionCard(
                    accentColor: _sectionAccentColor(
                      context,
                      ContactSection.rooms,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.rooms,
                          count: rooms.length,
                          icon: Icons.meeting_room_outlined,
                          accentColor: _sectionAccentColor(
                            context,
                            ContactSection.rooms,
                          ),
                        ),
                        _buildSectionFilterField(
                          context,
                          ContactSection.rooms,
                          contactsProvider,
                        ),
                        ..._buildSavedGroupCards(
                          visibleSavedRoomGroups,
                          ContactSection.rooms,
                        ),
                        if (rooms.isEmpty &&
                            _sectionHasActiveFilter(ContactSection.rooms))
                          _buildNoFilterResults(context)
                        else
                          ..._buildContactSectionItems(
                            _excludeGroupedContacts(
                              rooms,
                              visibleSavedRoomGroups,
                            ),
                          ),
                      ],
                    ),
                  ),

                if (showChannelsSection)
                  _SectionCard(
                    accentColor: _sectionAccentColor(
                      context,
                      ContactSection.channels,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.channels,
                          count: filteredChannels.length,
                          icon: Icons.broadcast_on_personal_rounded,
                          accentColor: _sectionAccentColor(
                            context,
                            ContactSection.channels,
                          ),
                        ),
                        _buildSectionFilterField(
                          context,
                          ContactSection.channels,
                          contactsProvider,
                        ),
                        ..._buildSavedGroupCards(
                          visibleSavedChannelGroups,
                          ContactSection.channels,
                        ),
                        if (filteredChannels.isEmpty &&
                            _sectionHasActiveFilter(ContactSection.channels))
                          _buildNoFilterResults(context)
                        else
                          ..._excludeGroupedContacts(
                            filteredChannels,
                            visibleSavedChannelGroups,
                          ).map(
                            (channel) => _ChannelActivityCard(
                              channel: channel,
                              messagesProvider: messagesProvider,
                              contactsProvider: contactsProvider,
                              onTap: () =>
                                  _showChannelActionSheet(context, channel),
                            ),
                          ),
                      ],
                    ),
                  ),

                if (connectionProvider.deviceInfo.isConnected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _openAddContactScreen(context),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: Text(l10n.addContact),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _showAddChannelDialog(context),
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(l10n.addChannel),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: _sectionAccentColor(
                                context,
                                ContactSection.channels,
                              ).withValues(alpha: 0.14),
                              foregroundColor: _sectionAccentColor(
                                context,
                                ContactSection.channels,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoFilterResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Text(
        'No matches',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _buildContactSectionItems(
    List<Contact> contacts, {
    bool compact = false,
  }) {
    return contacts
        .map(
          (contact) => ContactTile(
            contact: contact,
            compact: compact,
            currentPosition: _currentPosition,
            calculateDistance: _calculateDistanceInMeters,
            formatDistance: _formatDistance,
            onNavigateToMap: widget.onNavigateToMap,
            onNavigateToMessages: widget.onNavigateToMessages,
          ),
        )
        .toList();
  }

  List<Contact> _excludeGroupedContacts(
    List<Contact> contacts,
    List<_RenderedSavedGroup> savedGroups,
  ) {
    final groupedKeys = savedGroups
        .expand(
          (group) => group.contacts.map((contact) => contact.publicKeyHex),
        )
        .toSet();
    return contacts
        .where((contact) => !groupedKeys.contains(contact.publicKeyHex))
        .toList();
  }

  List<Widget> _buildSavedGroupCards(
    List<_RenderedSavedGroup> groups,
    ContactSection section,
  ) {
    return groups
        .map(
          (group) => _InferredContactGroupCard(
            label: group.group.label,
            contacts: group.contacts,
            compactContacts: section == ContactSection.repeaters,
            currentPosition: _currentPosition,
            calculateDistance: _calculateDistanceInMeters,
            formatDistance: _formatDistance,
            onNavigateToMap: widget.onNavigateToMap,
            onNavigateToMessages: widget.onNavigateToMessages,
            onDelete: () => context
                .read<ContactsProvider>()
                .removeSavedGroupById(group.group.id),
          ),
        )
        .toList();
  }

  Widget _buildSectionFilterField(
    BuildContext context,
    ContactSection section,
    ContactsProvider contactsProvider, {
    VoidCallback? onSecondaryAction,
    IconData? secondaryActionIcon,
    String? secondaryActionTooltip,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = _filterControllers[section]!;
    final hasFilter = (_sectionFilters[section] ?? '').isNotEmpty;
    final isSavedFilter = hasFilter
        ? contactsProvider.hasSavedGroupForFilter(
            section.name,
            _sectionFilters[section] ?? '',
          )
        : false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasFilter
                  ? colorScheme.primary.withValues(alpha: 0.38)
                  : colorScheme.outline.withValues(alpha: 0.32),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 42,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: hasFilter
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      onChanged: (value) {
                        setState(() {
                          _sectionFilters[section] = value;
                        });
                      },
                      cursorColor: colorScheme.primary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search this section',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildSortMenu(context, section, compact: true),
                  ),
                  if (hasFilter) ...[
                    if (onSecondaryAction != null &&
                        secondaryActionIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: secondaryActionTooltip ?? '',
                          child: Material(
                            color: colorScheme.tertiary.withValues(alpha: 0.10),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onSecondaryAction,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  secondaryActionIcon,
                                  size: 16,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Material(
                        color:
                            (isSavedFilter
                                    ? colorScheme.error
                                    : colorScheme.primary)
                                .withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _toggleSavedGroupForSection(
                            context,
                            contactsProvider,
                            section,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isSavedFilter
                                  ? Icons.delete_outline_rounded
                                  : Icons.bookmark_add_outlined,
                              size: 16,
                              color: isSavedFilter
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            controller.clear();
                            setState(() {
                              _sectionFilters[section] = '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        if (onSecondaryAction != null &&
                            secondaryActionIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Tooltip(
                              message: secondaryActionTooltip ?? '',
                              child: Material(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.10,
                                ),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: onSecondaryAction,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      secondaryActionIcon,
                                      size: 16,
                                      color: colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortMenu(
    BuildContext context,
    ContactSection section, {
    bool compact = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMode =
        _sortModes[section] ??
        (section == ContactSection.channels
            ? ContactSortMode.alphabetical
            : ContactSortMode.lastSeen);
    final colorScheme = Theme.of(context).colorScheme;
    final availableModes = _availableSortModes(section);

    return PopupMenuButton<ContactSortMode>(
      tooltip: 'Sort',
      initialValue: selectedMode,
      onSelected: (sortMode) {
        setState(() {
          _sortModes[section] = sortMode;
        });
      },
      itemBuilder: (context) => availableModes
          .map(
            (mode) => PopupMenuItem<ContactSortMode>(
              value: mode,
              child: Row(
                children: [
                  Icon(
                    _sortModeIcon(mode),
                    size: 18,
                    color: selectedMode == mode ? colorScheme.primary : null,
                  ),
                  const SizedBox(width: 8),
                  Text(_sortModeLabel(l10n, mode)),
                ],
              ),
            ),
          )
          .toList(),
      child: compact
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _sortModeIcon(selectedMode),
                size: 18,
                color: colorScheme.primary,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.38),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortModeIcon(selectedMode),
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _sortModeLabel(l10n, selectedMode),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
    );
  }
}

enum ContactSortMode { lastSeen, distance, alphabetical }

enum ContactSection { teamMembers, repeaters, sensors, rooms, channels }

class _RenderedSavedGroup {
  final SavedContactGroup group;
  final List<Contact> contacts;

  const _RenderedSavedGroup({required this.group, required this.contacts});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleBlock = Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accentColor.withValues(alpha: 0.18)),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = trailing != null && constraints.maxWidth < 430;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.18),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: titleBlock),
                  if (!useStackedLayout && trailing != null) ...[
                    const SizedBox(width: 12),
                    Flexible(child: trailing!),
                  ],
                ],
              ),
              if (useStackedLayout) ...[
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Color accentColor;
  final Widget child;

  const _SectionCard({required this.accentColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            accentColor.withValues(alpha: 0.04),
            colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InferredContactGroupCard extends StatelessWidget {
  final String label;
  final List<Contact> contacts;
  final bool compactContacts;
  final Position? currentPosition;
  final double Function(double, double, double, double) calculateDistance;
  final String Function(double) formatDistance;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;
  final VoidCallback? onDelete;

  const _InferredContactGroupCard({
    required this.label,
    required this.contacts,
    this.compactContacts = false,
    required this.currentPosition,
    required this.calculateDistance,
    required this.formatDistance,
    required this.onNavigateToMap,
    required this.onNavigateToMessages,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          minTileHeight: 44,
          initiallyExpanded: false,
          leading: Icon(
            Icons.folder_copy_outlined,
            size: 16,
            color: colorScheme.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contacts.length.toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Delete group',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          children: [
            ...contacts.map(
              (contact) => ContactTile(
                contact: contact,
                compact: compactContacts,
                currentPosition: currentPosition,
                calculateDistance: calculateDistance,
                formatDistance: formatDistance,
                onNavigateToMap: onNavigateToMap,
                onNavigateToMessages: onNavigateToMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelActivityCard extends StatelessWidget {
  final Contact channel;
  final MessagesProvider messagesProvider;
  final ContactsProvider contactsProvider;
  final VoidCallback? onTap;

  const _ChannelActivityCard({
    required this.channel,
    required this.messagesProvider,
    required this.contactsProvider,
    this.onTap,
  });

  String _formatRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    );
    final channelIdx = channel.publicKey.length > 1 ? channel.publicKey[1] : 0;
    final channelMessages = messagesProvider.getMessagesForChannel(channelIdx)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final lastActivityAt = messagesProvider.getLastActivityForDestination(
      channel,
    );
    final activityLabel = lastActivityAt == null
        ? null
        : _formatRelativeTime(context, lastActivityAt);
    final participantNames = <String>[];
    for (final message in channelMessages) {
      final senderName = message.senderName?.trim();
      if (senderName == null || senderName.isEmpty) continue;
      if (!participantNames.contains(senderName)) {
        participantNames.add(senderName);
      }
    }
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ContactAvatar(contact: channel, radius: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              channel.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (activityLabel != null)
                            Text(
                              activityLabel,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (participantNames.isNotEmpty)
                        _ExpandableParticipantStack(
                          names: participantNames,
                          contactForName: _findParticipantContact,
                        )
                      else
                        Text(
                          'No recent chatters',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetricChip(
                            icon: Icons.forum_outlined,
                            label: '${channelMessages.length}',
                            helper: 'messages',
                          ),
                          _MetricChip(
                            icon: Icons.group_outlined,
                            label: '${participantNames.length}',
                            helper: 'active',
                          ),
                        ],
                      ),
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

  Contact? _findParticipantContact(String name) {
    for (final contact in contactsProvider.contacts) {
      if (!contact.isChannel && contact.advName == name) {
        return contact;
      }
    }
    return null;
  }
}

class _ExpandableParticipantStack extends StatefulWidget {
  final List<String> names;
  final Contact? Function(String name) contactForName;

  const _ExpandableParticipantStack({
    required this.names,
    required this.contactForName,
  });

  @override
  State<_ExpandableParticipantStack> createState() =>
      _ExpandableParticipantStackState();
}

class _ExpandableParticipantStackState
    extends State<_ExpandableParticipantStack> {
  bool _expanded = false;
  static const int _collapsedVisibleCount = 4;

  @override
  Widget build(BuildContext context) {
    final hasOverflow = widget.names.length > _collapsedVisibleCount;
    final visibleNames = _expanded
        ? widget.names
        : widget.names.take(_collapsedVisibleCount).toList();
    final overflowCount = _expanded
        ? 0
        : widget.names.length - visibleNames.length;
    final spacing = _expanded ? 20.0 : 16.0;
    const avatarSize = 24.0;
    final itemCount = visibleNames.length + (overflowCount > 0 ? 1 : 0);
    final width = itemCount == 0 ? 0.0 : avatarSize + (itemCount - 1) * spacing;

    return GestureDetector(
      onTap: hasOverflow
          ? () {
              setState(() {
                _expanded = !_expanded;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < visibleNames.length; i++)
              Positioned(
                left: i * spacing,
                top: 0,
                child: _ParticipantAvatar(
                  name: visibleNames[i],
                  contact: widget.contactForName(visibleNames[i]),
                ),
              ),
            if (overflowCount > 0)
              Positioned(
                left: visibleNames.length * spacing,
                top: 0,
                child: _OverflowAvatar(count: overflowCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  final int count;

  const _OverflowAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final String name;
  final Contact? contact;
  static const double _size = 24;

  const _ParticipantAvatar({required this.name, required this.contact});

  @override
  Widget build(BuildContext context) {
    if (contact != null) {
      final surfaceColor = Theme.of(context).colorScheme.surface;
      return SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(child: ContactAvatar(contact: contact!, radius: 8)),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        AvatarLabelHelper.buildLabel(name),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onTertiaryContainer,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helper;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            helper,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
