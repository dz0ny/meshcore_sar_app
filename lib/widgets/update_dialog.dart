import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_info.dart';
import '../l10n/app_localizations.dart';

/// Dialog widget that displays when a new app version is available
/// Shows current vs latest commit hash and provides download button
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// Show the update dialog
  static Future<void> show(BuildContext context, UpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      icon: const Icon(
        Icons.system_update,
        size: 48,
        color: Colors.blue,
      ),
      title: Text(loc.updateAvailable),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current version
          _buildInfoRow(
            context,
            label: loc.currentVersion,
            value: updateInfo.currentCommitHash,
          ),
          const SizedBox(height: 12),

          // Latest version
          _buildInfoRow(
            context,
            label: loc.latestVersion,
            value: updateInfo.latestCommitHash ?? 'unknown',
          ),

          // Optional: Build timestamp
          if (updateInfo.timestamp != null) ...[
            SizedBox(height: 12),
            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.buildTime,
              value: _formatTimestamp(updateInfo.timestamp!),
            ),
          ],
        ],
      ),
      actions: [
        // Later button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.updateLater),
        ),

        // Download button
        FilledButton.icon(
          onPressed: () => _launchDownloadUrl(context),
          icon: const Icon(Icons.download),
          label: Text(loc.downloadUpdate),
        ),
      ],
    );
  }

  /// Build a labeled info row
  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
          ),
        ),
      ],
    );
  }

  /// Format timestamp from YYYYMMDD-HHMMSS to readable format
  String _formatTimestamp(String timestamp) {
    try {
      // Parse YYYYMMDD-HHMMSS format
      if (timestamp.length >= 15) {
        final year = timestamp.substring(0, 4);
        final month = timestamp.substring(4, 6);
        final day = timestamp.substring(6, 8);
        final hour = timestamp.substring(9, 11);
        final minute = timestamp.substring(11, 13);
        return '$year-$month-$day $hour:$minute UTC';
      }
      return timestamp;
    } catch (e) {
      return timestamp;
    }
  }

  /// Launch download URL in browser
  Future<void> _launchDownloadUrl(BuildContext context) async {
    if (updateInfo.downloadUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.downloadUrlNotAvailable),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(updateInfo.downloadUrl!);
      final canLaunch = await canLaunchUrl(url);

      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.cannotOpenDownloadUrl),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      // Close dialog after launching download
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[UpdateDialog] Error launching download URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOpeningDownload(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
