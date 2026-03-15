import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/sensors_provider.dart';
import '../widgets/sensors/sensor_telemetry_card.dart';

class SensorsTab extends StatefulWidget {
  final bool isActive;

  const SensorsTab({super.key, this.isActive = true});

  @override
  State<SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<SensorsTab> {
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      unawaited(_handleMinuteTick());
      _scheduleMinuteTicker();
    }
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SensorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) {
      return;
    }

    if (widget.isActive) {
      unawaited(_handleMinuteTick());
      _scheduleMinuteTicker();
      return;
    }

    _minuteTicker?.cancel();
    _minuteTicker = null;
  }

  void _scheduleMinuteTicker() {
    _minuteTicker?.cancel();
    if (!widget.isActive) {
      return;
    }

    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    final delay = nextMinute.difference(now);

    _minuteTicker = Timer(delay, () {
      if (!mounted) return;
      unawaited(_handleMinuteTick());
      _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
        unawaited(_handleMinuteTick());
      });
    });
  }

  Future<void> _handleMinuteTick() async {
    if (!mounted || !widget.isActive) {
      return;
    }

    final sensorsProvider = context.read<SensorsProvider>();
    sensorsProvider.clearExpiredRefreshStates();
    await sensorsProvider.refreshDueSensors(
      contactsProvider: context.read<ContactsProvider>(),
      connectionProvider: context.read<ConnectionProvider>(),
      now: DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _showAddSensorSheet(BuildContext context) async {
    final sensorsProvider = context.read<SensorsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final candidates = sensorsProvider.availableCandidates(contactsProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (candidates.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No eligible nodes available. Discover a relay or node first.',
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const ListTile(
                title: Text(
                  'Add sensor node',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Pick a relay or node to watch in Sensors.'),
              ),
              ...candidates.map(
                (contact) => ListTile(
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
                  onTap: () async {
                    await sensorsProvider.addSensor(contact);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${contact.displayName} added to Sensors',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMetricSelector(
    BuildContext context,
    String publicKeyHex,
    Contact? contact,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer<SensorsProvider>(
        builder: (context, sensorsProvider, child) {
          final visibleFields = sensorsProvider.visibleFieldsFor(publicKeyHex);
          final autoRefreshMinutes = sensorsProvider.autoRefreshMinutesFor(
            publicKeyHex,
          );
          final options = sensorMetricOptionsFor(
            contact,
            labelOverrides: sensorsProvider.labelOverridesFor(publicKeyHex),
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
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  'Auto refresh telemetry',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Refresh this contact automatically while the device is connected.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SensorsProvider.supportedAutoRefreshIntervals
                      .map(
                        (minutes) => ChoiceChip(
                          label: Text(minutes == 0 ? 'Off' : '${minutes}m'),
                          selected: autoRefreshMinutes == minutes,
                          onSelected: (_) {
                            sensorsProvider.setAutoRefreshMinutes(
                              publicKeyHex,
                              minutes,
                            );
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                Text(
                  'Visible fields',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which values appear on sensor cards and rename them.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the arrows to change card order.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                ...orderedOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final visible = visibleFields.contains(option.key);
                  final span = sensorsProvider.fieldSpanFor(
                    publicKeyHex,
                    option.key,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FilterChip(
                                selected: visible,
                                label: Text(option.label),
                                onSelected: (value) {
                                  sensorsProvider.toggleMetric(
                                    publicKeyHex,
                                    option.key,
                                    value,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Rename',
                              onPressed: () => _showMetricRenameDialog(
                                context,
                                publicKeyHex: publicKeyHex,
                                option: option,
                                sensorsProvider: sensorsProvider,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                        if (option.valuePreview != null ||
                            option.channel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (option.valuePreview != null)
                                  Text(
                                    option.valuePreview!,
                                    key: ValueKey(
                                      'sensor_selector_value_${option.key}',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                if (option.channel != null)
                                  Container(
                                    key: ValueKey(
                                      'sensor_selector_channel_${option.key}',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'ch${option.channel}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Move up',
                                onPressed: index > 0
                                    ? () => sensorsProvider.moveMetric(
                                        publicKeyHex,
                                        availableFieldKeys: orderedFieldKeys,
                                        oldIndex: index,
                                        newIndex: index - 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: 'Move down',
                                onPressed: index < orderedOptions.length - 1
                                    ? () => sensorsProvider.moveMetric(
                                        publicKeyHex,
                                        availableFieldKeys: orderedFieldKeys,
                                        oldIndex: index,
                                        newIndex: index + 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment<int>(
                                    value: 1,
                                    label: Text('1x'),
                                  ),
                                  ButtonSegment<int>(
                                    value: 2,
                                    label: Text('2x'),
                                  ),
                                ],
                                selected: <int>{span},
                                onSelectionChanged: (selection) {
                                  sensorsProvider.setFieldSpan(
                                    publicKeyHex,
                                    option.key,
                                    selection.first,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
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
        title: const Text('Rename value'),
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
            TextButton(onPressed: controller.clear, child: const Text('Reset')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSensorSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer2<SensorsProvider, ContactsProvider>(
        builder: (context, sensorsProvider, contactsProvider, child) {
          final watchedKeys = sensorsProvider.watchedSensorKeys;

          return RefreshIndicator(
            onRefresh: () => _refreshAll(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (watchedKeys.isEmpty)
                  const _EmptySensorsState()
                else
                  ...watchedKeys.map((key) {
                    Contact? contact;
                    for (final entry in contactsProvider.contacts) {
                      if (entry.publicKeyHex == key) {
                        contact = entry;
                        break;
                      }
                    }
                    return SensorTelemetryCard(
                      contact: contact,
                      state: sensorsProvider.stateFor(key),
                      visibleFields: sensorsProvider.visibleFieldsFor(key),
                      fieldOrder: sensorsProvider.metricOrderFor(
                        key,
                        sensorsProvider.visibleFieldsFor(key),
                      ),
                      labelOverrides: sensorsProvider.labelOverridesFor(key),
                      fieldSpans: {
                        for (final field in sensorsProvider.visibleFieldsFor(
                          key,
                        ))
                          field: sensorsProvider.fieldSpanFor(key, field),
                      },
                      onRemove: () async {
                        await sensorsProvider.removeSensor(key);
                      },
                      onCustomize: () =>
                          _showMetricSelector(context, key, contact),
                      onRefresh: () => sensorsProvider.refreshSensor(
                        publicKeyHex: key,
                        contactsProvider: contactsProvider,
                        connectionProvider: context.read<ConnectionProvider>(),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
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

class _EmptySensorsState extends StatelessWidget {
  const _EmptySensorsState();

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
              'Use + to add discovered relays or nodes. Pull down to refresh telemetry after adding them.',
              textAlign: TextAlign.center,
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
