import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../providers/app_provider.dart';
import '../../providers/messages_provider.dart';
import '../../utils/avatar_label_helper.dart';
import '../common/contact_avatar.dart';

enum _RecipientSortMode { activity, favorites, alphabetical }

/// Bottom sheet for selecting message recipient (channel, contact, or room)
class RecipientSelectorSheet extends StatefulWidget {
  final List<Contact> contacts;
  final List<Contact> rooms;
  final List<Contact> channels;
  final int unreadCount;
  final Map<String, int> unreadCountsByPublicKey;
  final String? currentDestinationType;
  final String? currentRecipientPublicKey;
  final bool showAllOption;
  final Function(String type, Contact? recipient) onSelect;
  final MessagesProvider? messagesProvider;

  /// Region scope names per channel index (e.g. {0: "#auckland"}).
  final Map<int, String> channelRegionScopes;

  const RecipientSelectorSheet({
    super.key,
    required this.contacts,
    required this.rooms,
    required this.channels,
    required this.unreadCount,
    required this.unreadCountsByPublicKey,
    this.currentDestinationType,
    this.currentRecipientPublicKey,
    this.showAllOption = true,
    required this.onSelect,
    this.messagesProvider,
    this.channelRegionScopes = const {},
  });

  @override
  State<RecipientSelectorSheet> createState() => _RecipientSelectorSheetState();
}

class _RecipientSelectorSheetState extends State<RecipientSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _RecipientSortMode _sortMode = _RecipientSortMode.activity;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _unreadFor(Contact? contact) {
    if (contact == null) {
      return widget.unreadCount;
    }

    return widget.unreadCountsByPublicKey[contact.publicKeyHex] ?? 0;
  }

  List<Contact> _filterAndSortContacts(
    List<Contact> contacts, {
    bool prioritizePublicChannel = false,
  }) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = contacts.where((contact) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      return contact.displayName.toLowerCase().contains(normalizedQuery) ||
          contact.advName.toLowerCase().contains(normalizedQuery) ||
          contact.publicKeyShort.toLowerCase().contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      if (prioritizePublicChannel && a.isPublicChannel != b.isPublicChannel) {
        return a.isPublicChannel ? -1 : 1;
      }

      if (_sortMode == _RecipientSortMode.favorites) {
        if (a.isFavourite != b.isFavourite) {
          return a.isFavourite ? -1 : 1;
        }
        final unreadCompare = _unreadFor(b).compareTo(_unreadFor(a));
        if (unreadCompare != 0) {
          return unreadCompare;
        }
        final lastSeenCompare = b.lastSeenTime.compareTo(a.lastSeenTime);
        if (lastSeenCompare != 0) {
          return lastSeenCompare;
        }
      } else if (_sortMode == _RecipientSortMode.activity) {
        if (a.isFavourite != b.isFavourite) {
          return a.isFavourite ? -1 : 1;
        }
        final unreadCompare = _unreadFor(b).compareTo(_unreadFor(a));
        if (unreadCompare != 0) {
          return unreadCompare;
        }
        final lastSeenCompare = b.lastSeenTime.compareTo(a.lastSeenTime);
        if (lastSeenCompare != 0) {
          return lastSeenCompare;
        }
      }

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return filtered;
  }

  bool _isSelected(String type, Contact? contact) {
    if (widget.currentDestinationType != type) {
      return false;
    }
    if (contact == null) {
      return widget.currentRecipientPublicKey == null;
    }
    return contact.publicKeyHex == widget.currentRecipientPublicKey;
  }

  IconData _typeIcon(Contact contact) {
    switch (contact.type) {
      case ContactType.channel:
        return Icons.broadcast_on_personal_rounded;
      case ContactType.room:
        return Icons.meeting_room_outlined;
      case ContactType.repeater:
        return Icons.router_outlined;
      case ContactType.sensor:
        return Icons.sensors_outlined;
      case ContactType.chat:
        return Icons.person_rounded;
      case ContactType.none:
        return Icons.help_outline_rounded;
    }
  }

  Color _sectionColor(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'channel':
        return Color.alphaBlend(
          colorScheme.tertiary.withValues(alpha: 0.55),
          colorScheme.primary.withValues(alpha: 0.35),
        );
      case 'room':
        return colorScheme.secondary;
      case 'contact':
        return colorScheme.primary;
      default:
        return colorScheme.tertiary;
    }
  }

  String _sectionDescription(AppLocalizations l10n, String type) {
    switch (type) {
      case 'channel':
        return 'Broadcast lanes for nearby mesh traffic';
      case 'room':
        return 'Shared spaces for ongoing team coordination';
      case 'contact':
        return 'Direct people and devices you can reach';
      default:
        return '';
    }
  }

  MessagesProvider? _resolveMessagesProvider(BuildContext context) {
    if (widget.messagesProvider != null) {
      return widget.messagesProvider;
    }

    try {
      return Provider.of<MessagesProvider>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }

  String _formatRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  _ChannelPreviewData _channelPreviewData(
    BuildContext context,
    Contact channel,
    MessagesProvider? messagesProvider,
  ) {
    if (messagesProvider == null) {
      return const _ChannelPreviewData();
    }

    final lastActivityAt = messagesProvider.getLastActivityForDestination(
      channel,
    );
    final channelIdx = channel.publicKey.length > 1 ? channel.publicKey[1] : 0;
    final channelMessages = messagesProvider.getMessagesForChannel(channelIdx)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final participantNames = <String>[];

    for (final message in channelMessages) {
      final senderName = message.senderName?.trim();
      if (senderName == null || senderName.isEmpty) {
        continue;
      }
      if (!participantNames.contains(senderName)) {
        participantNames.add(senderName);
      }
    }

    return _ChannelPreviewData(
      activityLabel: lastActivityAt == null
          ? null
          : _formatRelativeTime(context, lastActivityAt),
      participantNames: participantNames,
    );
  }

  Contact? _findParticipantContact(String name) {
    final normalizedName = name.trim();

    for (final contact in widget.contacts) {
      if (!contact.isChannel && contact.advName.trim() == normalizedName) {
        return contact;
      }
    }

    for (final contact in widget.contacts) {
      if (!contact.isChannel && contact.displayName.trim() == normalizedName) {
        return contact;
      }
    }

    return null;
  }

  String _contactActivityLabel(
    BuildContext context,
    Contact contact,
    MessagesProvider? messagesProvider,
  ) {
    final lastActivityAt =
        messagesProvider?.getLastActivityForDestination(contact) ??
        contact.lastSeenTime;

    return _formatRelativeTime(context, lastActivityAt);
  }

  IconData _channelLocationSharingIcon(ChannelLocationSharingMode mode) {
    switch (mode) {
      case ChannelLocationSharingMode.hardware:
      case ChannelLocationSharingMode.appFallback:
        return Icons.location_pin;
    }
  }

  Color _channelLocationSharingColor(
    BuildContext context,
    ChannelLocationSharingMode mode,
  ) {
    return const Color(0xFF16A34A);
  }

  Widget _buildTextSubtitle(
    BuildContext context,
    Contact contact,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontFamily: contact.isChannel ? null : 'monospace',
      ),
    );
  }

  Widget _buildChannelSubtitle(
    BuildContext context,
    Contact channel,
    _ChannelPreviewData previewData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (previewData.participantNames.isEmpty) {
      return Text(
        'No recent chatters',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      );
    }

    return Row(
      children: [
        _ParticipantAvatarStack(
          key: Key('channel-participants-${channel.publicKeyHex}'),
          names: previewData.participantNames,
          contactForName: _findParticipantContact,
        ),
      ],
    );
  }

  Widget _buildChannelRecipientCard(
    BuildContext context,
    Contact channel,
    MessagesProvider? messagesProvider,
  ) {
    final previewData = _channelPreviewData(context, channel, messagesProvider);
    final sharingMode = context.watch<AppProvider>().channelLocationSharingModeForChannel(
      channel.publicKey.length > 1 ? channel.publicKey[1] : 0,
    );

    return _buildRecipientCard(
      context: context,
      type: 'channel',
      contact: channel,
      title: channel.getLocalizedDisplayName(context),
      subtitle: _buildChannelSubtitle(context, channel, previewData),
      avatarMarkerMode: sharingMode,
      unreadCount: _unreadFor(channel),
      isSelected: _isSelected('channel', channel),
      compact: true,
      activityLabel: previewData.activityLabel,
      onTap: () {
        widget.onSelect('channel', channel);
        Navigator.pop(context);
      },
    );
  }

  bool _isDenseSection(String type) => type == 'channel' || type == 'contact';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final messagesProvider = _resolveMessagesProvider(context);
    final filteredContacts = _filterAndSortContacts(widget.contacts);
    final filteredRooms = _filterAndSortContacts(widget.rooms);
    final filteredChannels = _filterAndSortContacts(
      widget.channels,
      prioritizePublicChannel: true,
    );
    final hasChannels = widget.channels.isNotEmpty;
    final hasContacts = widget.contacts.isNotEmpty;
    final hasRooms = widget.rooms.isNotEmpty;
    final hasAnyRecipients = hasChannels || hasContacts || hasRooms;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.selectRecipient,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a channel, room, or direct contact.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: l10n.close,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchRecipients,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildSortMenuButton(context),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (widget.showAllOption)
                  _buildAllOptionCard(context, l10n, colorScheme),
                if (hasChannels)
                  _buildSectionCard(
                    context,
                    type: 'channel',
                    title: l10n.channels,
                    icon: Icons.broadcast_on_personal_rounded,
                    count: filteredChannels.length,
                    emptyLabel: l10n.noChannelsFound,
                    children: [
                      for (final channel in filteredChannels)
                        _buildChannelRecipientCard(
                          context,
                          channel,
                          messagesProvider,
                        ),
                    ],
                  ),
                if (hasContacts)
                  _buildSectionCard(
                    context,
                    type: 'contact',
                    title: l10n.contacts,
                    icon: Icons.people_alt_rounded,
                    count: filteredContacts.length,
                    emptyLabel: l10n.noContactsFound,
                    children: [
                      for (final contact in filteredContacts)
                        _buildRecipientCard(
                          context: context,
                          type: 'contact',
                          contact: contact,
                          title: contact.displayName,
                          activityLabel: _contactActivityLabel(
                            context,
                            contact,
                            messagesProvider,
                          ),
                          unreadCount: _unreadFor(contact),
                          isSelected: _isSelected('contact', contact),
                          compact: true,
                          onTap: () {
                            widget.onSelect('contact', contact);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                if (hasRooms)
                  _buildSectionCard(
                    context,
                    type: 'room',
                    title: l10n.rooms,
                    icon: Icons.meeting_room_outlined,
                    count: filteredRooms.length,
                    emptyLabel: l10n.noRoomsFound,
                    children: [
                      for (final room in filteredRooms)
                        _buildRecipientCard(
                          context: context,
                          type: 'room',
                          contact: room,
                          title: room.displayName,
                          subtitle: _buildTextSubtitle(
                            context,
                            room,
                            room.publicKeyShort,
                          ),
                          unreadCount: _unreadFor(room),
                          isSelected: _isSelected('room', room),
                          onTap: () {
                            widget.onSelect('room', room);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                if (!hasAnyRecipients)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecipientsAvailable,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenuButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_RecipientSortMode>(
      tooltip: AppLocalizations.of(context)!.sort,
      initialValue: _sortMode,
      onSelected: (sortMode) {
        setState(() {
          _sortMode = sortMode;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem<_RecipientSortMode>(
          value: _RecipientSortMode.activity,
          child: Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 18,
                color: _sortMode == _RecipientSortMode.activity
                    ? colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Text(l10n.active),
            ],
          ),
        ),
        PopupMenuItem<_RecipientSortMode>(
          value: _RecipientSortMode.favorites,
          child: Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 18,
                color: _sortMode == _RecipientSortMode.favorites
                    ? colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Text(l10n.favourites),
            ],
          ),
        ),
        PopupMenuItem<_RecipientSortMode>(
          value: _RecipientSortMode.alphabetical,
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha_rounded, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.aToZ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Icon(
          _sortMode == _RecipientSortMode.activity
              ? Icons.flash_on_rounded
              : _sortMode == _RecipientSortMode.favorites
              ? Icons.star_rounded
              : Icons.sort_by_alpha_rounded,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String type,
    required String title,
    required IconData icon,
    required int count,
    required String emptyLabel,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _sectionColor(context, type);
    final compact = _isDenseSection(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: compact ? 16 : 18, color: accentColor),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 10,
                  vertical: compact ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _sectionDescription(AppLocalizations.of(context)!, type),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) SizedBox(height: compact ? 6 : 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAllOptionCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final isSelected = _isSelected('all', null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.42)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.28)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            widget.onSelect('all', null);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.all_inbox_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.showAll,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.allMessages,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailing(
                  context,
                  unreadCount: widget.unreadCount,
                  isSelected: isSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientCard({
    required BuildContext context,
    required String type,
    required Contact contact,
    required String title,
    Widget? subtitle,
    ChannelLocationSharingMode? avatarMarkerMode,
    required int unreadCount,
    required bool isSelected,
    bool compact = false,
    String? activityLabel,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _sectionColor(context, type);
    final markerColor = avatarMarkerMode == null
        ? accentColor
        : _channelLocationSharingColor(context, avatarMarkerMode);
    final markerIcon = avatarMarkerMode == null
        ? _typeIcon(contact)
        : _channelLocationSharingIcon(avatarMarkerMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(compact ? 18 : 20),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.24)
                  : colorScheme.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ContactAvatar(
                      contact: contact,
                      radius: compact ? 20 : 22,
                      displayName: title,
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: compact ? 16 : 18,
                        height: compact ? 16 : 18,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: markerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          markerIcon,
                          size: compact ? 9 : 10,
                          color: markerColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: compact ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                ),
                                if (contact.isPublicChannel) ...[
                                  SizedBox(width: compact ? 6 : 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compact ? 7 : 8,
                                      vertical: compact ? 2 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Public',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: accentColor,
                                            fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (activityLabel != null) ...[
                            SizedBox(width: compact ? 8 : 10),
                            Text(
                              activityLabel,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: compact ? 2 : 4),
                        subtitle,
                      ],
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 10),
                _buildTrailing(
                  context,
                  unreadCount: unreadCount,
                  isSelected: isSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context, {
    required int unreadCount,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (unreadCount <= 0 && !isSelected) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unreadCount > 0)
          Container(
            key: Key('unread-badge-$unreadCount'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (unreadCount > 0 && isSelected) const SizedBox(width: 8),
        if (isSelected)
          Icon(Icons.check_circle_rounded, color: colorScheme.primary),
      ],
    );
  }
}

class _ChannelPreviewData {
  final String? activityLabel;
  final List<String> participantNames;

  const _ChannelPreviewData({
    this.activityLabel,
    this.participantNames = const <String>[],
  });
}

class _ParticipantAvatarStack extends StatelessWidget {
  final List<String> names;
  final Contact? Function(String name) contactForName;
  static const int _visibleCount = 4;

  const _ParticipantAvatarStack({
    super.key,
    required this.names,
    required this.contactForName,
  });

  @override
  Widget build(BuildContext context) {
    final visibleNames = names.take(_visibleCount).toList();
    final overflowCount = names.length - visibleNames.length;
    const avatarSize = 20.0;
    const spacing = 14.0;
    final itemCount = visibleNames.length + (overflowCount > 0 ? 1 : 0);
    final width = itemCount == 0 ? 0.0 : avatarSize + (itemCount - 1) * spacing;

    return SizedBox(
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
                contact: contactForName(visibleNames[i]),
              ),
            ),
          if (overflowCount > 0)
            Positioned(
              left: visibleNames.length * spacing,
              top: 0,
              child: _ParticipantOverflowAvatar(count: overflowCount),
            ),
        ],
      ),
    );
  }
}

class _ParticipantOverflowAvatar extends StatelessWidget {
  final int count;

  const _ParticipantOverflowAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 20,
      height: 20,
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
          fontSize: 8,
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final String name;
  final Contact? contact;

  const _ParticipantAvatar({required this.name, required this.contact});

  @override
  Widget build(BuildContext context) {
    if (contact != null) {
      final surfaceColor = Theme.of(context).colorScheme.surface;

      return SizedBox(
        width: 20,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(child: ContactAvatar(contact: contact!, radius: 6)),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 20,
      height: 20,
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
          fontSize: 8,
        ),
      ),
    );
  }
}
