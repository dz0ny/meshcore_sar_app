import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/sensors_provider.dart';
import '../widgets/contacts/ping_contact_sheet.dart';
import '../widgets/sensors/bthome_met_history_sheet.dart';
import '../widgets/sensors/sensor_history_sheet.dart';
import '../widgets/sensors/sensor_telemetry_card.dart';
import '../l10n/app_localizations.dart';

class SensorsTab extends StatefulWidget {
  final bool isActive;

  const SensorsTab({super.key, this.isActive = true});

  @override
  State<SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<SensorsTab> {
  final Map<String, DateTime> _lastCenteredTelemetryAtBySensor =
      <String, DateTime>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showAddSensorSheet(BuildContext context) async {
    final sensorsProvider = context.read<SensorsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final candidates = sensorsProvider.availableCandidates(
      contactsProvider,
      connectionProvider: context.read<ConnectionProvider>(),
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => AddSensorSheet(
        candidates: candidates,
        onClose: () => Navigator.of(sheetContext).pop(),
        onSelect: (contact) async {
          await sensorsProvider.addSensor(contact);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.addedToSensors(contact.displayName))),
          );
        },
      ),
    );
  }

  Future<void> _showMetricSelector(
    BuildContext context,
    String publicKeyHex,
    Contact? contact,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) => SensorCustomizeView(
          publicKeyHex: publicKeyHex,
          initialContact: contact,
          onRenameMetric:
              ({
                required BuildContext context,
                required String publicKeyHex,
                required SensorMetricOption option,
                required SensorsProvider sensorsProvider,
              }) {
                return _showMetricRenameDialog(
                  context,
                  publicKeyHex: publicKeyHex,
                  option: option,
                  sensorsProvider: sensorsProvider,
                );
              },
        ),
      ),
    );
  }

  Future<void> _showMetricRenameDialog(
    BuildContext context, {
    required String publicKeyHex,
    required SensorMetricOption option,
    required SensorsProvider sensorsProvider,
  }) async {
    final controller = TextEditingController(
      text:
          sensorsProvider.labelOverrideFor(publicKeyHex, option.key) ??
          option.defaultLabel,
    );
    final didSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renameValue),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set a custom label for ${option.label}.',
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: option.defaultLabel,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
        actions: [
          if (sensorsProvider.labelOverrideFor(publicKeyHex, option.key) !=
              null)
            TextButton(onPressed: controller.clear, child: Text(AppLocalizations.of(dialogContext)!.reset)),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(dialogContext)!.save),
          ),
        ],
      ),
    );
    if (didSave != true) {
      controller.dispose();
      return;
    }

    final nextLabel = controller.text.trim();
    await sensorsProvider.setMetricLabel(
      publicKeyHex,
      option.key,
      nextLabel == option.defaultLabel ? null : nextLabel,
    );
    controller.dispose();
  }

  Future<void> _refreshAll(BuildContext context) async {
    await context.read<SensorsProvider>().refreshAll(
      contactsProvider: context.read<ContactsProvider>(),
      connectionProvider: context.read<ConnectionProvider>(),
    );
  }

  void _maybeCenterMapOnTelemetryUpdate(
    Iterable<String> sensorKeys, {
    required SensorsProvider sensorsProvider,
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) {
    if (!widget.isActive) {
      return;
    }

    Contact? latestContact;
    DateTime? latestTimestamp;

    for (final key in sensorKeys) {
      final contact = sensorsProvider.contactForDisplay(
        key,
        contactsProvider: contactsProvider,
        connectionProvider: connectionProvider,
      );
      final timestamp = contact?.telemetry?.timestamp;
      final location = contact?.displayLocation;
      if (contact == null || timestamp == null || location == null) {
        continue;
      }

      final previousTimestamp = _lastCenteredTelemetryAtBySensor[key];
      if (previousTimestamp != null && !timestamp.isAfter(previousTimestamp)) {
        continue;
      }

      if (latestTimestamp == null || timestamp.isAfter(latestTimestamp)) {
        latestContact = contact;
        latestTimestamp = timestamp;
      }
    }

    if (latestContact == null || latestTimestamp == null) {
      return;
    }

    _lastCenteredTelemetryAtBySensor[latestContact.publicKeyHex] =
        latestTimestamp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) {
        return;
      }

      final location = latestContact!.displayLocation;
      if (location == null) {
        return;
      }

      context.read<MapProvider>().navigateToLocation(
        location: location,
        zoom: 15.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSensorSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer3<SensorsProvider, ContactsProvider, ConnectionProvider>(
        builder:
            (
              context,
              sensorsProvider,
              contactsProvider,
              connectionProvider,
              child,
            ) {
              final watchedKeys = sensorsProvider.watchedSensorKeys;
              final hasPersistedSensors = watchedKeys.isNotEmpty;
              final selfDisplayKey = sensorsProvider.displaySelfKey(
                contactsProvider: contactsProvider,
                connectionProvider: connectionProvider,
              );
              final displayKeys = <String>[
                ...?selfDisplayKey == null ? null : <String>[selfDisplayKey],
                ...watchedKeys,
              ];
              _maybeCenterMapOnTelemetryUpdate(
                displayKeys,
                sensorsProvider: sensorsProvider,
                contactsProvider: contactsProvider,
                connectionProvider: connectionProvider,
              );
              final hasAnyCards =
                  selfDisplayKey != null || watchedKeys.isNotEmpty;

              Widget buildSensorCard(
                String key, {
                required int index,
                required int totalCount,
                required bool isWatchedCard,
              }) {
                final contact = sensorsProvider.contactForDisplay(
                  key,
                  contactsProvider: contactsProvider,
                  connectionProvider: connectionProvider,
                );
                final availableFieldKeys = sensorMetricKeysFor(contact);
                final visibleFields = sensorsProvider.effectiveVisibleFieldsFor(
                  key,
                  availableFieldKeys,
                );

                return Padding(
                  key: ValueKey<String>('sensor_card_$key'),
                  padding: EdgeInsets.only(
                    bottom: index == totalCount - 1 ? 0 : 12,
                  ),
                  child: ReorderableDelayedDragStartListener(
                    enabled: isWatchedCard,
                    index: index,
                    child: SensorTelemetryCard(
                      contact: contact,
                      state: sensorsProvider.stateFor(key),
                      showActionSheetOnTap: true,
                      visibleFields: visibleFields,
                      fieldOrder: sensorsProvider.metricOrderFor(
                        key,
                        availableFieldKeys,
                      ),
                      labelOverrides: sensorsProvider.labelOverridesFor(key),
                      fieldSpans: {
                        for (final field in visibleFields)
                          field: sensorsProvider.fieldSpanFor(key, field),
                      },
                      onRemove: isWatchedCard
                          ? () async {
                              await sensorsProvider.removeSensor(key);
                            }
                          : null,
                      onCustomize: () =>
                          _showMetricSelector(context, key, contact),
                      onMetricTap: (fieldKey) async {
                        final history = sensorsProvider.historyFor(key);
                        final hasHistoryForField = history.any(
                          (sample) => sample.values.containsKey(fieldKey),
                        );
                        if (!hasHistoryForField) {
                          return;
                        }
                        await showSensorHistorySheet(
                          context,
                          publicKeyHex: key,
                          initialFieldKey: fieldKey,
                        );
                      },
                      onShowMetHistory: (contact) =>
                          showBTHomeMetHistorySheet(context, contact: contact),
                      onMoveUp: isWatchedCard && index > 0
                          ? () =>
                                sensorsProvider.reorderSensors(index, index - 1)
                          : null,
                      onMoveDown: isWatchedCard && index < totalCount - 1
                          ? () =>
                                sensorsProvider.reorderSensors(index, index + 2)
                          : null,
                      onRefresh: () => sensorsProvider.refreshSensor(
                        publicKeyHex: key,
                        contactsProvider: contactsProvider,
                        connectionProvider: connectionProvider,
                      ),
                      onPing: contact == null
                          ? null
                          : () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                builder: (context) =>
                                    PingContactSheet(contact: contact),
                              );
                            },
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _refreshAll(context),
                child: !hasAnyCards
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: const [_EmptySensorsState()],
                      )
                    : hasPersistedSensors && selfDisplayKey == null
                    ? ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: watchedKeys.length,
                        onReorder: (oldIndex, newIndex) =>
                            sensorsProvider.reorderSensors(oldIndex, newIndex),
                        itemBuilder: (context, index) => buildSensorCard(
                          watchedKeys[index],
                          index: index,
                          totalCount: watchedKeys.length,
                          isWatchedCard: true,
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          if (selfDisplayKey != null)
                            buildSensorCard(
                              selfDisplayKey,
                              index: 0,
                              totalCount: watchedKeys.isEmpty ? 1 : 2,
                              isWatchedCard: false,
                            ),
                          if (selfDisplayKey != null && watchedKeys.isEmpty)
                            _SelfOnlySensorsCta(
                              onAddSensor: () => _showAddSensorSheet(context),
                            ),
                          if (watchedKeys.isNotEmpty)
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              buildDefaultDragHandles: false,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: watchedKeys.length,
                              onReorder: (oldIndex, newIndex) => sensorsProvider
                                  .reorderSensors(oldIndex, newIndex),
                              itemBuilder: (context, index) => buildSensorCard(
                                watchedKeys[index],
                                index: index,
                                totalCount: watchedKeys.length,
                                isWatchedCard: true,
                              ),
                            ),
                        ],
                      ),
              );
            },
      ),
    );
  }
}

class AddSensorSheet extends StatefulWidget {
  final List<Contact> candidates;
  final Future<void> Function(Contact contact) onSelect;
  final VoidCallback onClose;

  const AddSensorSheet({
    super.key,
    required this.candidates,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<AddSensorSheet> createState() => _AddSensorSheetState();
}

class _AddSensorSheetState extends State<AddSensorSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No eligible nodes available. Discover a relay or node first.',
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();
    final filteredCandidates = widget.candidates.where((contact) {
      if (query.isEmpty) {
        return true;
      }
      return contact.displayName.toLowerCase().contains(query) ||
          contact.publicKeyHex.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add sensor node',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(l10n.pickARelayOrNodeToWatchInSensors),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: AppLocalizations.of(context)!.searchSensors,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: filteredCandidates.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'No sensor candidates match your search.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: filteredCandidates.length,
                        itemBuilder: (context, index) {
                          final contact = filteredCandidates[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFDDEAF8),
                              child: Icon(
                                _typeIcon(contact),
                                color: const Color(0xFF1E4F7A),
                              ),
                            ),
                            title: Text(contact.displayName),
                            subtitle: _SensorCandidatePreview(contact: contact),
                            isThreeLine: true,
                            onTap: () => widget.onSelect(contact),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorCustomizeView extends StatelessWidget {
  final String publicKeyHex;
  final Contact? initialContact;
  final bool showLivePreview;
  final Future<void> Function({
    required BuildContext context,
    required String publicKeyHex,
    required SensorMetricOption option,
    required SensorsProvider sensorsProvider,
  })
  onRenameMetric;

  const SensorCustomizeView({
    super.key,
    required this.publicKeyHex,
    required this.initialContact,
    required this.onRenameMetric,
    this.showLivePreview = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SensorsProvider, ContactsProvider>(
      builder: (context, sensorsProvider, contactsProvider, child) {
        Contact? contact = initialContact;
        for (final entry in contactsProvider.contacts) {
          if (entry.publicKeyHex == publicKeyHex) {
            contact = entry;
            break;
          }
        }

        final options = sensorMetricOptionsFor(
          contact,
          labelOverrides: sensorsProvider.labelOverridesFor(publicKeyHex),
        );
        final visibleFields = sensorsProvider.effectiveVisibleFieldsFor(
          publicKeyHex,
          options.map((option) => option.key),
        );
        final autoRefreshMinutes = sensorsProvider.autoRefreshMinutesFor(
          publicKeyHex,
        );
        final orderedFieldKeys = sensorsProvider.metricOrderFor(
          publicKeyHex,
          options.map((option) => option.key),
        );
        final optionByKey = <String, SensorMetricOption>{
          for (final option in options) option.key: option,
        };
        final orderedOptions = orderedFieldKeys
            .map((fieldKey) => optionByKey[fieldKey])
            .whereType<SensorMetricOption>()
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.customizeSensor(contact?.displayName ?? AppLocalizations.of(context)!.sensor)),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (showLivePreview)
                _SensorCustomizeSectionCard(
                  title: AppLocalizations.of(context)!.livePreview,
                  subtitle:
                      'Changes apply immediately. This card matches the current dashboard layout for this sensor.',
                  child: SensorTelemetryCard(
                    contact: contact,
                    state: sensorsProvider.stateFor(publicKeyHex),
                    visibleFields: visibleFields,
                    fieldOrder: sensorsProvider.metricOrderFor(
                      publicKeyHex,
                      visibleFields,
                    ),
                    labelOverrides: sensorsProvider.labelOverridesFor(
                      publicKeyHex,
                    ),
                    onShowMetHistory: contact == null
                        ? null
                        : (contact) => showBTHomeMetHistorySheet(
                            context,
                            contact: contact,
                          ),
                    fieldSpans: {
                      for (final field in visibleFields)
                        field: sensorsProvider.fieldSpanFor(
                          publicKeyHex,
                          field,
                        ),
                    },
                    margin: EdgeInsets.zero,
                    emptyMetricsMessage: 'No telemetry fields available yet.',
                  ),
                ),
              _SensorCustomizeSectionCard(
                title: AppLocalizations.of(context)!.refreshSchedule,
                subtitle:
                    'Choose how often this sensor should refresh while your device stays connected.',
                child: SensorAutoRefreshOptions(
                  selectedMinutes: autoRefreshMinutes,
                  onSelected: (minutes) {
                    sensorsProvider.setAutoRefreshMinutes(
                      publicKeyHex,
                      minutes,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field layout',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use the same value-card previews shown on the dashboard to control visibility, labels, width, and order.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              ...orderedOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final visible = visibleFields.contains(option.key);
                final span = sensorsProvider.fieldSpanFor(
                  publicKeyHex,
                  option.key,
                );
                return SensorMetricSelectorItem(
                  option: option,
                  visible: visible,
                  span: span,
                  canMoveUp: index > 0,
                  canMoveDown: index < orderedOptions.length - 1,
                  onToggle: (value) {
                    sensorsProvider.toggleMetric(
                      publicKeyHex,
                      option.key,
                      value,
                    );
                  },
                  onRename: () => onRenameMetric(
                    context: context,
                    publicKeyHex: publicKeyHex,
                    option: option,
                    sensorsProvider: sensorsProvider,
                  ),
                  onMoveUp: index > 0
                      ? () => sensorsProvider.moveMetric(
                          publicKeyHex,
                          availableFieldKeys: orderedFieldKeys,
                          oldIndex: index,
                          newIndex: index - 1,
                        )
                      : null,
                  onMoveDown: index < orderedOptions.length - 1
                      ? () => sensorsProvider.moveMetric(
                          publicKeyHex,
                          availableFieldKeys: orderedFieldKeys,
                          oldIndex: index,
                          newIndex: index + 1,
                        )
                      : null,
                  onSpanChanged: (selection) {
                    sensorsProvider.setFieldSpan(
                      publicKeyHex,
                      option.key,
                      selection,
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SensorCustomizeSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SensorCustomizeSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class SensorAutoRefreshOptions extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  const SensorAutoRefreshOptions({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SensorsProvider.supportedAutoRefreshIntervals
          .map(
            (minutes) => ChoiceChip(
              label: Text(_formatAutoRefreshIntervalLabel(minutes)),
              selected: selectedMinutes == minutes,
              onSelected: (_) => onSelected(minutes),
            ),
          )
          .toList(growable: false),
    );
  }
}

String _formatAutoRefreshIntervalLabel(int minutes) {
  if (minutes <= 0) {
    return 'Off';
  }
  if (minutes >= 360 && minutes % 60 == 0) {
    return '${minutes ~/ 60}h';
  }
  return '${minutes}m';
}

class SensorMetricSelectorItem extends StatelessWidget {
  final SensorMetricOption option;
  final bool visible;
  final int span;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRename;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final ValueChanged<int> onSpanChanged;

  const SensorMetricSelectorItem({
    super.key,
    required this.option,
    required this.visible,
    required this.span,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onRename,
    this.onMoveUp,
    this.onMoveDown,
    required this.onSpanChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showChannelChip = option.channel != null && option.channel != 1;
    final previewCardData =
        option.previewCardData ??
        SensorMetricCardData(
          fieldKey: option.key,
          icon: Icons.sensors,
          label: option.defaultLabel,
          value: option.valuePreview ?? 'No telemetry yet',
          accent: colorScheme.primary,
          channel: option.channel,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        option.defaultLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: onRename,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              foregroundColor: colorScheme.primary,
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: Icon(Icons.edit_outlined, size: 18),
                            label: Text(AppLocalizations.of(context)!.rename),
                          ),
                          if (showChannelChip)
                            Container(
                              key: ValueKey(
                                'sensor_selector_channel_${option.key}',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: previewCardData.accent.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Channel ${option.channel}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: previewCardData.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: visible
                        ? const Color(0xFF218B63).withValues(alpha: 0.12)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    visible ? 'Visible' : 'Hidden',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: visible
                          ? const Color(0xFF218B63)
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: visible ? 1 : 0.55,
              child: SensorMetricTile(
                data: previewCardData,
                width: double.infinity,
                keyPrefix: 'sensor_selector_metric',
                allowMapPreview: false,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Show on sensor card',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(value: visible, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Card width',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 1, label: Text('1x')),
                    ButtonSegment<int>(value: 2, label: Text('2x')),
                  ],
                  selected: <int>{span},
                  onSelectionChanged: (selection) {
                    onSpanChanged(selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Order',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.moveUp,
                  onPressed: canMoveUp ? onMoveUp : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.moveDown,
                  onPressed: canMoveDown ? onMoveDown : null,
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCandidatePreview extends StatelessWidget {
  final Contact contact;

  const _SensorCandidatePreview({required this.contact});

  @override
  Widget build(BuildContext context) {
    final telemetry = contact.telemetry;
    final previewLines = <String>[
      '${contact.type.displayName} • ${contact.publicKeyShort}',
      if (telemetry?.batteryPercentage != null)
        'Battery ${telemetry!.batteryPercentage!.toStringAsFixed(0)}% • '
            'Temp ${telemetry.temperature?.toStringAsFixed(1) ?? '--'}°C',
      if (telemetry?.gpsLocation != null)
        'GPS ${telemetry!.gpsLocation!.latitude.toStringAsFixed(3)}, '
            '${telemetry.gpsLocation!.longitude.toStringAsFixed(3)}',
    ];

    if (previewLines.length == 1) {
      previewLines.add('No telemetry preview available yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: previewLines
          .take(3)
          .map(
            (line) => Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
          .toList(),
    );
  }
}

class _EmptySensorsState extends StatefulWidget {
  const _EmptySensorsState();

  @override
  State<_EmptySensorsState> createState() => _EmptySensorsStateState();
}

class _EmptySensorsStateState extends State<_EmptySensorsState> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEAF8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors_outlined,
              size: 40,
              color: Color(0xFF1E4F7A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No sensor nodes added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Use + to add discovered relays or nodes. Your device will appear here automatically when available.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfOnlySensorsCta extends StatelessWidget {
  final VoidCallback onAddSensor;

  const _SelfOnlySensorsCta({required this.onAddSensor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_chart_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add another device',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bring in weather stations, repeaters, or other devices to watch them here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onAddSensor,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.choose),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _typeIcon(Contact contact) {
  if (contact.isSensor) {
    return Icons.sensors;
  }
  if (contact.isRepeater) {
    return Icons.router;
  }
  if (contact.isChat) {
    return Icons.person;
  }
  return Icons.device_hub;
}
