import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/traffic_stats_reporting_service.dart';

class TrafficStatsReportingSection extends StatelessWidget {
  final TrafficStatsReportingService service;

  const TrafficStatsReportingSection({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          dense: true,
          secondary: const Icon(Icons.cloud_upload_outlined, size: 20),
          title: const Text('Anonymous RX stats'),
          subtitle: const Text(
            'Upload packet totals every 5 min',
          ),
          value: service.isEnabled,
          onChanged: (value) async {
            await service.setEnabled(value);
          },
        ),
        if (service.isEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _statusText(service),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openStatsDashboard,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Future<void> _openStatsDashboard() async {
    final url = TrafficStatsReportingService.dashboardUri;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static String _statusText(TrafficStatsReportingService service) {
    final parts = <String>[];
    parts.add('Pending: ${service.pendingUploadCount}');
    if (service.lastSuccessAt != null) {
      parts.add('Sent: ${_formatDateTime(service.lastSuccessAt!.toLocal())}');
    }
    if (service.lastError != null && service.lastError!.isNotEmpty) {
      parts.add('Error: ${service.lastError}');
    }
    return parts.join(' · ');
  }

  static String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}
