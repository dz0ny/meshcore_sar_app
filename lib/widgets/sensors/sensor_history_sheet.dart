import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/sensors_provider.dart';
import 'sensor_telemetry_card.dart';

enum SensorHistoryRange { day, week, month, all }

Future<void> showSensorHistorySheet(
  BuildContext context, {
  required String publicKeyHex,
  String? initialFieldKey,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (pageContext) => SensorHistoryScreen(
        publicKeyHex: publicKeyHex,
        initialFieldKey: initialFieldKey,
      ),
    ),
  );
}

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({
    super.key,
    required this.publicKeyHex,
    this.initialFieldKey,
  });

  final String publicKeyHex;
  final String? initialFieldKey;

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  late SensorHistoryRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = SensorHistoryRange.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SensorsProvider, ContactsProvider, ConnectionProvider>(
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
                final aIndex = options.indexWhere((option) => option.key == a);
                final bIndex = options.indexWhere((option) => option.key == b);
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

            final selectedFieldKey = resolveInitialSensorHistoryField(
              requestedFieldKey: widget.initialFieldKey,
              availableFieldKeys: availableFieldKeys,
            );
            final selectedOption = selectedFieldKey == null
                ? null
                : optionByKey[selectedFieldKey];
            final selectedCardData = selectedOption?.previewCardData;
            final selectedSamples = selectedFieldKey == null
                ? const <SensorHistorySample>[]
                : history
                      .where(
                        (sample) =>
                            sample.values.containsKey(selectedFieldKey),
                      )
                      .toList(growable: false);
            final rangeSamples = filterSensorHistorySamples(
              samples: selectedSamples,
              range: _selectedRange,
            );
            final title =
                selectedCardData?.label ??
                selectedOption?.defaultLabel ??
                'Sensor history';

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      Text(
                        contact?.displayName ?? 'Unavailable node',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Graph'),
                      Tab(text: 'Values'),
                    ],
                  ),
                ),
                body: selectedFieldKey == null
                    ? _SensorHistoryEmptyState(
                        message:
                            'No history recorded yet. Enable auto refresh for this sensor and leave the app running to collect samples.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: SensorHistoryRange.values
                                  .map(
                                    (range) => ChoiceChip(
                                      label: Text(
                                        sensorHistoryRangeLabel(range),
                                      ),
                                      selected: _selectedRange == range,
                                      onSelected: (selected) {
                                        if (!selected) {
                                          return;
                                        }
                                        setState(() {
                                          _selectedRange = range;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _SensorHistoryGraphTab(
                                  samples: rangeSamples,
                                  fieldKey: selectedFieldKey,
                                  cardData: selectedCardData,
                                  totalCount: selectedSamples.length,
                                  range: _selectedRange,
                                ),
                                _SensorHistoryValuesTab(
                                  samples: rangeSamples,
                                  fieldKey: selectedFieldKey,
                                  cardData: selectedCardData,
                                  range: _selectedRange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
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

List<SensorHistorySample> filterSensorHistorySamples({
  required List<SensorHistorySample> samples,
  required SensorHistoryRange range,
}) {
  if (samples.isEmpty || range == SensorHistoryRange.all) {
    return List<SensorHistorySample>.from(samples);
  }

  final latestTimestamp = samples.last.timestamp;
  final cutoff = switch (range) {
    SensorHistoryRange.day => latestTimestamp.subtract(const Duration(days: 1)),
    SensorHistoryRange.week => latestTimestamp.subtract(const Duration(days: 7)),
    SensorHistoryRange.month => latestTimestamp.subtract(
      const Duration(days: 30),
    ),
    SensorHistoryRange.all => DateTime.fromMillisecondsSinceEpoch(0),
  };

  return samples
      .where((sample) => !sample.timestamp.isBefore(cutoff))
      .toList(growable: false);
}

String sensorHistoryRangeLabel(SensorHistoryRange range) {
  return switch (range) {
    SensorHistoryRange.day => '24h',
    SensorHistoryRange.week => '7d',
    SensorHistoryRange.month => '30d',
    SensorHistoryRange.all => 'All',
  };
}

class _SensorHistoryGraphTab extends StatelessWidget {
  const _SensorHistoryGraphTab({
    required this.samples,
    required this.fieldKey,
    required this.cardData,
    required this.totalCount,
    required this.range,
  });

  final List<SensorHistorySample> samples;
  final String fieldKey;
  final SensorMetricCardData? cardData;
  final int totalCount;
  final SensorHistoryRange range;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return _SensorHistoryEmptyState(
        message:
            'No samples are available for ${sensorHistoryRangeLabel(range)}.',
      );
    }

    final latestValue = samples.last.values[fieldKey]!;
    final minValue = samples
        .map((sample) => sample.values[fieldKey]!)
        .reduce(math.min);
    final maxValue = samples
        .map((sample) => sample.values[fieldKey]!)
        .reduce(math.max);
    final accent = cardData?.accent ?? Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _SensorHistoryStatTile(
                label: 'Visible',
                value: samples.length.toString(),
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SensorHistoryStatTile(
                label: 'Latest',
                value: _formatHistoryValue(cardData, latestValue),
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SensorHistoryStatTile(
                label: 'Min',
                value: _formatHistoryValue(cardData, minValue),
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SensorHistoryStatTile(
                label: 'Max',
                value: _formatHistoryValue(cardData, maxValue),
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$totalCount total readings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: SizedBox(
            height: 280,
            child: LineChart(
              _historyLineChartData(
                context,
                samples: samples,
                fieldKey: fieldKey,
                color: accent,
              ),
              duration: Duration.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _SensorHistoryValuesTab extends StatelessWidget {
  const _SensorHistoryValuesTab({
    required this.samples,
    required this.fieldKey,
    required this.cardData,
    required this.range,
  });

  final List<SensorHistorySample> samples;
  final String fieldKey;
  final SensorMetricCardData? cardData;
  final SensorHistoryRange range;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return _SensorHistoryEmptyState(
        message:
            'No values are available for ${sensorHistoryRangeLabel(range)}.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: samples.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sample = samples[samples.length - index - 1];
        final value = sample.values[fieldKey]!;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatSampleTimestamp(sample.timestamp),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatHistoryValue(cardData, value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      cardData?.accent ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorHistoryEmptyState extends StatelessWidget {
  const _SensorHistoryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
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
  final padding = spread == 0
      ? math.max(maxValue.abs() * 0.1, 1.0)
      : spread * 0.15;
  final minY = minValue - padding;
  final maxY = maxValue + padding;
  final interval = spread <= 0
      ? math.max(maxValue.abs() / 3, 1.0)
      : spread / 3;

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
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$month/$day';
}
