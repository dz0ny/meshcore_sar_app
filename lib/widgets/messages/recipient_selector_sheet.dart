import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../common/contact_avatar.dart';

enum _RecipientSortMode { activity, alphabetical }

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

      if (_sortMode == _RecipientSortMode.activity) {
        final unreadCompare = _unreadFor(b).compareTo(_unreadFor(a));
        if (unreadCompare != 0) {
          return unreadCompare;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                const SizedBox(height: 16),
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
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.showAllOption)
                                _SummaryChip(
                                  icon: Icons.all_inbox_rounded,
                                  label: l10n.showAll,
                                  count: widget.unreadCount,
                                  accentColor: colorScheme.primary,
                                ),
                              if (hasChannels)
                                _SummaryChip(
                                  icon: Icons.broadcast_on_personal_rounded,
                                  label: l10n.channels,
                                  count: filteredChannels.length,
                                  accentColor: _sectionColor(
                                    context,
                                    'channel',
                                  ),
                                ),
                              if (hasContacts)
                                _SummaryChip(
                                  icon: Icons.person_rounded,
                                  label: l10n.contacts,
                                  count: filteredContacts.length,
                                  accentColor: _sectionColor(
                                    context,
                                    'contact',
                                  ),
                                ),
                              if (hasRooms)
                                _SummaryChip(
                                  icon: Icons.meeting_room_outlined,
                                  label: l10n.rooms,
                                  count: filteredRooms.length,
                                  accentColor: _sectionColor(context, 'room'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
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
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SortChip(
                        icon: Icons.flash_on_rounded,
                        label: l10n.active,
                        selected: _sortMode == _RecipientSortMode.activity,
                        onTap: () {
                          setState(() {
                            _sortMode = _RecipientSortMode.activity;
                          });
                        },
                      ),
                      _SortChip(
                        icon: Icons.sort_by_alpha_rounded,
                        label: 'A-Z',
                        selected: _sortMode == _RecipientSortMode.alphabetical,
                        onTap: () {
                          setState(() {
                            _sortMode = _RecipientSortMode.alphabetical;
                          });
                        },
                      ),
                    ],
                  ),
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
                        _buildRecipientCard(
                          context: context,
                          type: 'channel',
                          contact: channel,
                          title: channel.getLocalizedDisplayName(context),
                          subtitle: channel.isPublicChannel
                              ? l10n.broadcastToAllNearby
                              : '${l10n.channel} ${channel.publicKey[1]}',
                          unreadCount: _unreadFor(channel),
                          isSelected: _isSelected('channel', channel),
                          onTap: () {
                            widget.onSelect('channel', channel);
                            Navigator.pop(context);
                          },
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
                          subtitle: contact.publicKeyShort,
                          unreadCount: _unreadFor(contact),
                          isSelected: _isSelected('contact', contact),
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
                          subtitle: room.publicKeyShort,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            accentColor.withValues(alpha: 0.05),
            colorScheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
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
          const SizedBox(height: 12),
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
              if (i != children.length - 1) const SizedBox(height: 8),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.surfaceContainerHigh,
          ],
        ),
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
    required String subtitle,
    required int unreadCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _sectionColor(context, type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.24)
                  : colorScheme.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ContactAvatar(
                      contact: contact,
                      radius: 22,
                      displayName: title,
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _typeIcon(contact),
                          size: 10,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: contact.isChannel ? null : 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color accentColor;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: selected
            ? colorScheme.onSecondaryContainer
            : colorScheme.primary,
      ),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.secondaryContainer
            : colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
      backgroundColor: colorScheme.surfaceContainerLow,
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurface,
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
