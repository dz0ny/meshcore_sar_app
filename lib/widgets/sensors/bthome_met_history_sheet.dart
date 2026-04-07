import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:meshcore_client/meshcore_client.dart' show Message;
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../providers/connection_provider.dart';
import '../../services/bthome_met_history.dart';

Future<void> showBTHomeMetHistorySheet(
  BuildContext context, {
  required Contact contact,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _BTHomeMetHistorySheet(contact: contact),
  );
}

class _BTHomeMetHistorySheet extends StatefulWidget {
  const _BTHomeMetHistorySheet({required this.contact});

  final Contact contact;

  @override
  State<_BTHomeMetHistorySheet> createState() => _BTHomeMetHistorySheetState();
}

class _BTHomeMetHistorySheetState extends State<_BTHomeMetHistorySheet> {
  late final List<BTHomeMetMeasurement> _availableMeasurements;
  late BTHomeMetMeasurement _selectedMeasurement;
  BTHomeMetHistoryPage? _history;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _availableMeasurements = bTHomeMetMeasurementsForContact(widget.contact);
    _selectedMeasurement = _availableMeasurements.isEmpty
        ? BTHomeMetMeasurement.temperature
        : _availableMeasurements.first;
    if (_availableMeasurements.isEmpty) {
      _loading = false;
      _error = 'No BTHome MET-compatible telemetry is available for this node.';
      return;
    }
    unawaited(_loadHistory(measurement: _selectedMeasurement, page: 0));
  }

  Future<void> _loadHistory({
    required BTHomeMetMeasurement measurement,
    required int page,
  }) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final previousOnMessageReceived = connectionProvider.onMessageReceived;
    String? responseText;

    void onMessage(Message message) {
      previousOnMessageReceived?.call(message);
      if (_matchesContact(message)) {
        responseText = message.text;
      }
    }

    connectionProvider.onMessageReceived = onMessage;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final sent = await connectionProvider.sendTextMessage(
        contactPublicKey: widget.contact.publicKey,
        text: 'bthome met history ${measurement.id} $page',
      );
      if (!sent) {
        throw Exception('Failed to send MET history request.');
      }

      for (var i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (responseText != null) {
          break;
        }
      }

      final text = responseText?.trim();
      if (text == null || text.isEmpty) {
        throw TimeoutException('No response from sensor.');
      }
      if (_looksLikeError(text)) {
        throw Exception(text);
      }

      final history = BTHomeMetHistoryParser.parse(text);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedMeasurement = measurement;
        _history = history;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedMeasurement = measurement;
        _history = null;
        _loading = false;
        _error = _formatError(error);
      });
    } finally {
      if (identical(connectionProvider.onMessageReceived, onMessage)) {
        connectionProvider.onMessageReceived = previousOnMessageReceived;
      }
    }
  }

  bool _matchesContact(Message message) {
    final prefix = message.senderPublicKeyPrefix;
    if (prefix == null ||
        prefix.length < 6 ||
        widget.contact.publicKey.length < 6) {
      return false;
    }
    for (var i = 0; i < 6; i++) {
      if (prefix[i] != widget.contact.publicKey[i]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeError(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('err') ||
        lower.contains('unknown') ||
        lower.contains('unsupported');
  }

  String _formatError(Object error) {
    if (error is TimeoutException) {
      return error.message ?? 'Timed out waiting for MET history.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height * 0.8;
    final history = _history;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
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
                          'MET history',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.contact.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableMeasurements
                    .map(
                      (measurement) => ChoiceChip(
                        label: Text(measurement.label),
                        selected: measurement == _selectedMeasurement,
                        onSelected: (selected) {
                          if (!selected || _loading) {
                            return;
                          }
                          unawaited(
                            _loadHistory(measurement: measurement, page: 0),
                          );
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading || (history?.page ?? 0) == 0
                        ? null
                        : () => unawaited(
                            _loadHistory(
                              measurement: _selectedMeasurement,
                              page: history!.page - 1,
                            ),
                          ),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(AppLocalizations.of(context)!.newer),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _loading ||
                            history == null ||
                            history.values.length < 12
                        ? null
                        : () => unawaited(
                            _loadHistory(
                              measurement: _selectedMeasurement,
                              page: history.page + 1,
                            ),
                          ),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(AppLocalizations.of(context)!.older),
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      'Page ${history?.page ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        _HistoryMessageCard(
                          icon: Icons.error_outline,
                          title: AppLocalizations.of(context)!.couldNotLoadMetHistory,
                          body: _error!,
                        )
                      else if (_loading && history == null)
                        _HistoryMessageCard(
                          icon: Icons.hourglass_top,
                          title: AppLocalizations.of(context)!.loading,
                          body: 'Waiting for the sensor to reply.',
                        )
                      else if (history != null) ...[
                        _HistoryChartCard(history: history),
                        const SizedBox(height: 12),
                        _HistoryStatsGrid(history: history),
                        const SizedBox(height: 12),
                        _HistorySamplesCard(history: history),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryChartCard extends StatelessWidget {
  const _HistoryChartCard({required this.history});

  final BTHomeMetHistoryPage history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            history.measurement.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Samples are shown oldest to newest. Firmware replies do not include timestamps.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(_historyLineChartData(context, history: history)),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatsGrid extends StatelessWidget {
  const _HistoryStatsGrid({required this.history});

  final BTHomeMetHistoryPage history;

  @override
  Widget build(BuildContext context) {
    final measurement = history.measurement;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final tiles = <Widget>[
          _HistoryStatTile(
            label: AppLocalizations.of(context)!.latest,
            value: _formatMeasurementValue(measurement, history.latest),
          ),
          _HistoryStatTile(
            label: AppLocalizations.of(context)!.min,
            value: _formatMeasurementValue(measurement, history.minimum),
          ),
          _HistoryStatTile(
            label: AppLocalizations.of(context)!.max,
            value: _formatMeasurementValue(measurement, history.maximum),
          ),
          _HistoryStatTile(
            label: AppLocalizations.of(context)!.samples,
            value: history.values.length.toString(),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 8),
            Expanded(child: tiles[1]),
            const SizedBox(width: 8),
            Expanded(child: tiles[2]),
            const SizedBox(width: 8),
            Expanded(child: tiles[3]),
          ],
        );
      },
    );
  }
}

class _HistoryStatTile extends StatelessWidget {
  const _HistoryStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySamplesCard extends StatelessWidget {
  const _HistorySamplesCard({required this.history});

  final BTHomeMetHistoryPage history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Samples',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.values
                .asMap()
                .entries
                .map((entry) {
                  final sampleIndex = entry.key + 1;
                  final isLatest = entry.key == history.values.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? _historyColor(
                              history.measurement,
                            ).withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$sampleIndex. ${_formatMeasurementValue(history.measurement, entry.value)}${isLatest ? ' latest' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isLatest
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessageCard extends StatelessWidget {
  const _HistoryMessageCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _historyColor(BTHomeMetMeasurement measurement) {
  switch (measurement) {
    case BTHomeMetMeasurement.temperature:
      return const Color(0xFFC76821);
    case BTHomeMetMeasurement.humidity:
      return const Color(0xFF246BB2);
    case BTHomeMetMeasurement.windSpeed:
      return const Color(0xFF2B78A0);
    case BTHomeMetMeasurement.gust:
      return const Color(0xFF1E88A8);
    case BTHomeMetMeasurement.rain:
      return const Color(0xFF2C6BA0);
  }
}

String _formatMeasurementValue(BTHomeMetMeasurement measurement, num? value) {
  if (value == null) {
    return '--';
  }

  final digits = switch (measurement) {
    BTHomeMetMeasurement.humidity => 0,
    BTHomeMetMeasurement.temperature => 1,
    BTHomeMetMeasurement.windSpeed => 1,
    BTHomeMetMeasurement.gust => 1,
    BTHomeMetMeasurement.rain => 1,
  };

  final text = value
      .toStringAsFixed(digits)
      .replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text${measurement.unit}';
}

LineChartData _historyLineChartData(
  BuildContext context, {
  required BTHomeMetHistoryPage history,
}) {
  final theme = Theme.of(context);
  final color = _historyColor(history.measurement);
  final values = history.values;
  final spots = values
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
      .toList(growable: false);
  final chartMinY = _historyChartMinY(history);
  final chartMaxY = _historyChartMaxY(history);
  final yInterval = _historyYAxisInterval(
    measurement: history.measurement,
    minY: chartMinY,
    maxY: chartMaxY,
  );

  return LineChartData(
    minX: 0,
    maxX: values.length <= 1 ? 1.0 : (values.length - 1).toDouble(),
    minY: chartMinY,
    maxY: chartMaxY,
    clipData: const FlClipData.all(),
    lineTouchData: const LineTouchData(enabled: false),
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: yInterval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
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
          reservedSize: 42,
          interval: yInterval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            space: 8,
            child: Text(
              _formatHistoryAxisValue(history.measurement, value),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (value != index.toDouble() ||
                !_shouldShowBottomSampleLabel(index, values.length)) {
              return const SizedBox.shrink();
            }

            return SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) =>
              barData.spots.length <= 10 || spot == barData.spots.last,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: spot == barData.spots.last ? 4 : 2.5,
            color: color,
            strokeColor: theme.colorScheme.surface,
            strokeWidth: 1.6,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.03),
            ],
          ),
        ),
      ),
    ],
  );
}

double _historyChartMinY(BTHomeMetHistoryPage history) {
  final minValue = history.minimum ?? 0;
  final maxValue = history.maximum ?? 0;
  final spread = maxValue - minValue;
  final padding = spread == 0
      ? _historyMinimumPadding(history.measurement, minValue)
      : math.max(
          spread * 0.18,
          _historyMinimumPadding(history.measurement, minValue),
        );
  return minValue - padding;
}

double _historyChartMaxY(BTHomeMetHistoryPage history) {
  final minValue = history.minimum ?? 0;
  final maxValue = history.maximum ?? 0;
  final spread = maxValue - minValue;
  final padding = spread == 0
      ? _historyMinimumPadding(history.measurement, maxValue)
      : math.max(
          spread * 0.18,
          _historyMinimumPadding(history.measurement, maxValue),
        );
  return maxValue + padding;
}

double _historyMinimumPadding(
  BTHomeMetMeasurement measurement,
  double reference,
) {
  final scaled = math.max(reference.abs() * 0.05, 0.1);
  return switch (measurement) {
    BTHomeMetMeasurement.temperature => math.max(0.4, scaled),
    BTHomeMetMeasurement.humidity => math.max(2.0, scaled),
    BTHomeMetMeasurement.windSpeed => math.max(0.4, scaled),
    BTHomeMetMeasurement.gust => math.max(0.4, scaled),
    BTHomeMetMeasurement.rain => math.max(0.4, scaled),
  };
}

double _historyYAxisInterval({
  required BTHomeMetMeasurement measurement,
  required double minY,
  required double maxY,
}) {
  final span = maxY - minY;
  if (span <= 0) {
    return 1;
  }

  final rough = span / 3;
  return switch (measurement) {
    BTHomeMetMeasurement.humidity => math.max(1, rough.round()).toDouble(),
    BTHomeMetMeasurement.temperature => _niceStep(rough, minStep: 0.5),
    BTHomeMetMeasurement.windSpeed => _niceStep(rough, minStep: 0.5),
    BTHomeMetMeasurement.gust => _niceStep(rough, minStep: 0.5),
    BTHomeMetMeasurement.rain => _niceStep(rough, minStep: 0.5),
  };
}

double _niceStep(double value, {required double minStep}) {
  if (value <= minStep) {
    return minStep;
  }

  final exponent = math
      .pow(10.0, (math.log(value) / math.ln10).floor())
      .toDouble();
  final normalized = value / exponent;
  final stepped = switch (normalized) {
    < 1.5 => 1.0,
    < 3.0 => 2.0,
    < 7.0 => 5.0,
    _ => 10.0,
  };
  return math.max(minStep, stepped * exponent);
}

String _formatHistoryAxisValue(BTHomeMetMeasurement measurement, double value) {
  final digits = measurement == BTHomeMetMeasurement.humidity ? 0 : 1;
  return value.toStringAsFixed(digits).replaceFirst(RegExp(r'\.?0+$'), '');
}

bool _shouldShowBottomSampleLabel(int index, int sampleCount) {
  if (index < 0 || index >= sampleCount) {
    return false;
  }
  if (sampleCount <= 3) {
    return true;
  }

  final middle = (sampleCount - 1) ~/ 2;
  return index == 0 || index == middle || index == sampleCount - 1;
}
