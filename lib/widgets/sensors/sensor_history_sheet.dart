import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/sensors_provider.dart';
import 'sensor_telemetry_card.dart';

Future<void> showSensorHistorySheet(
  BuildContext context, {
  required String publicKeyHex,
  String? initialFieldKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _SensorHistorySheet(
      publicKeyHex: publicKeyHex,
      initialFieldKey: initialFieldKey,
    ),
  );
}

class _SensorHistorySheet extends StatefulWidget {
  const _SensorHistorySheet({
    required this.publicKeyHex,
    this.initialFieldKey,
  });

  final String publicKeyHex;
  final String? initialFieldKey;

  @override
  State<_SensorHistorySheet> createState() => _SensorHistorySheetState();
}

class _SensorHistorySheetState extends State<_SensorHistorySheet> {
  String? _selectedFieldKey;

  @override
  void initState() {
    super.initState();
    _selectedFieldKey = widget.initialFieldKey;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.84;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Consumer3<SensorsProvider, ContactsProvider, ConnectionProvider>(
          builder:
              (
                context,
                sensorsProvider,
                contactsProvider,
                connectionProvider,
                child,
              ) {
                final contact = sensorsProvider.contactForDisplay(
                  widget.publicKeyHex,
                  contactsProvider: contactsProvider,
                  connectionProvider: connectionProvider,
                );
                final history = sensorsProvider.historyFor(widget.publicKeyHex);
                final options = sensorMetricOptionsFor(
                  contact,
                  labelOverrides: sensorsProvider.labelOverridesFor(
                    widget.publicKeyHex,
                  ),
                );
                final optionByKey = <String, SensorMetricOption>{
                  for (final option in options) option.key: option,
                };
                final availableFieldKeys = <String>{
                  for (final sample in history) ...sample.values.keys,
                }.toList()
                  ..sort((a, b) {
                    final aIndex = options.indexWhere(
                      (option) => option.key == a,
                    );
                    final bIndex = options.indexWhere(
                      (option) => option.key == b,
                    );
                    if (aIndex == -1 && bIndex == -1) {
                      return a.compareTo(b);
                    }
                    if (aIndex == -1) {
                      return 1;
                    }
                    if (bIndex == -1) {
                      return -1;
                    }
                    return aIndex.compareTo(bIndex);
                  });

                _selectedFieldKey = resolveInitialSensorHistoryField(
                  requestedFieldKey: _selectedFieldKey,
                  availableFieldKeys: availableFieldKeys,
                );

                final selectedFieldKey = _selectedFieldKey;
                final selectedSamples = selectedFieldKey == null
                    ? const <SensorHistorySample>[]
                    : history
                          .where(
                            (sample) =>
                                sample.values.containsKey(selectedFieldKey),
                          )
                          .toList(growable: false);
                final selectedOption = selectedFieldKey == null
                    ? null
                    : optionByKey[selectedFieldKey];
                final selectedCardData = selectedOption?.previewCardData;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sensor history',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact?.displayName ?? 'Unavailable node',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (availableFieldKeys.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              'No history recorded yet. Enable auto refresh for this sensor and leave the app running to collect samples.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableFieldKeys
                              .map((fieldKey) {
                                final option = optionByKey[fieldKey];
                                return ChoiceChip(
                                  label: Text(
                                    option?.defaultLabel ?? fieldKey,
                                  ),
                                  selected: fieldKey == selectedFieldKey,
                                  onSelected: (selected) {
                                    if (!selected) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedFieldKey = fieldKey;
                                    });
                                  },
                                );
                              })
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 16),
                        _SensorHistorySummaryCard(
                          historyCount: history.length,
                          samples: selectedSamples,
                          cardData: selectedCardData,
                          fieldKey: selectedFieldKey!,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCardData?.label ??
                                    selectedOption?.defaultLabel ??
                                    selectedFieldKey,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: LineChart(
                                  _historyLineChartData(
                                    context,
                                    samples: selectedSamples,
                                    fieldKey: selectedFieldKey,
                                    color:
                                        selectedCardData?.accent ??
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  duration: Duration.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _SensorHistoryLogList(
                            history: history.reversed.toList(growable: false),
                            selectedFieldKey: selectedFieldKey,
                            optionByKey: optionByKey,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }
}

String? resolveInitialSensorHistoryField({
  required String? requestedFieldKey,
  required List<String> availableFieldKeys,
}) {
  if (requestedFieldKey != null &&
      availableFieldKeys.contains(requestedFieldKey)) {
    return requestedFieldKey;
  }
  if (availableFieldKeys.isEmpty) {
    return null;
  }
  return availableFieldKeys.first;
}

class _SensorHistorySummaryCard extends StatelessWidget {
  const _SensorHistorySummaryCard({
    required this.historyCount,
    required this.samples,
    required this.cardData,
    required this.fieldKey,
  });

  final int historyCount;
  final List<SensorHistorySample> samples;
  final SensorMetricCardData? cardData;
  final String fieldKey;

  @override
  Widget build(BuildContext context) {
    final latestValue = samples.isEmpty ? null : samples.last.values[fieldKey];
    final minValue = samples.isEmpty
        ? null
        : samples
              .map((sample) => sample.values[fieldKey]!)
              .reduce(math.min);
    final maxValue = samples.isEmpty
        ? null
        : samples
              .map((sample) => sample.values[fieldKey]!)
              .reduce(math.max);

    final theme = Theme.of(context);
    final accent = cardData?.accent ?? theme.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _SensorHistoryStatTile(
            label: 'Total',
            value: historyCount.toString(),
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorHistoryStatTile(
            label: 'Latest',
            value: latestValue == null
                ? '--'
                : _formatHistoryValue(cardData, latestValue),
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorHistoryStatTile(
            label: 'Min',
            value: minValue == null ? '--' : _formatHistoryValue(cardData, minValue),
            accent: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorHistoryStatTile(
            label: 'Max',
            value: maxValue == null ? '--' : _formatHistoryValue(cardData, maxValue),
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _SensorHistoryStatTile extends StatelessWidget {
  const _SensorHistoryStatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SensorHistoryLogList extends StatelessWidget {
  const _SensorHistoryLogList({
    required this.history,
    required this.selectedFieldKey,
    required this.optionByKey,
  });

  final List<SensorHistorySample> history;
  final String selectedFieldKey;
  final Map<String, SensorMetricOption> optionByKey;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sample = history[index];
        final selectedValue = sample.values[selectedFieldKey];
        final selectedOption = optionByKey[selectedFieldKey];

        final secondaryMetrics = sample.values.entries
            .where((entry) => entry.key != selectedFieldKey)
            .take(3)
            .map((entry) {
              final option = optionByKey[entry.key];
              final cardData = option?.previewCardData;
              return TextSpan(
                text:
                    '${option?.defaultLabel ?? entry.key} ${_formatHistoryValue(cardData, entry.value)}  ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cardData?.accent ?? Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              );
            })
            .toList(growable: false);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatSampleTimestamp(sample.timestamp),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${selectedOption?.defaultLabel ?? selectedFieldKey} ${selectedValue == null ? '--' : _formatHistoryValue(selectedOption?.previewCardData, selectedValue)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      selectedOption?.previewCardData?.accent ??
                      Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (secondaryMetrics.isNotEmpty) ...[
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(children: secondaryMetrics),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

LineChartData _historyLineChartData(
  BuildContext context, {
  required List<SensorHistorySample> samples,
  required String fieldKey,
  required Color color,
}) {
  final theme = Theme.of(context);
  final values = samples
      .map((sample) => sample.values[fieldKey]!)
      .toList(growable: false);
  final spots = values
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
      .toList(growable: false);
  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  final spread = maxValue - minValue;
  final padding = spread == 0 ? math.max(maxValue.abs() * 0.1, 1.0) : spread * 0.15;
  final minY = minValue - padding;
  final maxY = maxValue + padding;
  final interval = spread <= 0 ? math.max(maxValue.abs() / 3, 1.0) : spread / 3;

  return LineChartData(
    minX: 0,
    maxX: values.length <= 1 ? 1.0 : (values.length - 1).toDouble(),
    minY: minY,
    maxY: maxY,
    clipData: const FlClipData.all(),
    lineTouchData: const LineTouchData(enabled: false),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
        strokeWidth: 1,
      ),
    ),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: interval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            space: 8,
            child: Text(
              value.toStringAsFixed(value.abs() >= 10 ? 0 : 1),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: math.max((values.length / 4).floorToDouble(), 1),
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= samples.length || value != index.toDouble()) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text(
                _formatChartTimestamp(samples[index].timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    ),
    lineBarsData: [
      LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 2.8,
        isCurved: false,
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) =>
              barData.spots.length <= 10 || spot == barData.spots.last,
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.20),
              color.withValues(alpha: 0.03),
            ],
          ),
        ),
      ),
    ],
  );
}

String _formatHistoryValue(SensorMetricCardData? cardData, double value) {
  final template = cardData?.value;
  if (template == null || template.isEmpty) {
    return value.toStringAsFixed(value.abs() >= 10 ? 0 : 1);
  }

  if (template.endsWith('%')) {
    return '${value.toStringAsFixed(1)}%';
  }
  if (template.endsWith('V')) {
    return '${value.toStringAsFixed(3)}V';
  }
  if (template.contains(' hPa')) {
    return '${value.toStringAsFixed(1)} hPa';
  }
  if (template.contains('°C')) {
    return '${value.toStringAsFixed(1)}°C';
  }
  if (template.contains(' mph')) {
    return '${value.toStringAsFixed(2)} mph';
  }
  if (template.contains(' km/h')) {
    return '${value.toStringAsFixed(2)} km/h';
  }
  return value.toStringAsFixed(value.abs() >= 10 ? 0 : 1);
}

String _formatSampleTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final year = local.year.toString().substring(2);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day/$year $hour:$minute';
}

String _formatChartTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
