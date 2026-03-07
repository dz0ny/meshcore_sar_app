import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../models/message_reception_details.dart';

IconData getDeliveryStatusIcon(MessageDeliveryStatus status) {
  switch (status) {
    case MessageDeliveryStatus.sending:
      return Icons.schedule;
    case MessageDeliveryStatus.sent:
      return Icons.done;
    case MessageDeliveryStatus.delivered:
      return Icons.done_all;
    case MessageDeliveryStatus.failed:
      return Icons.error_outline;
    case MessageDeliveryStatus.received:
      return Icons.inbox;
  }
}

Color getDeliveryStatusColor(MessageDeliveryStatus status) {
  switch (status) {
    case MessageDeliveryStatus.sending:
      return Colors.orange;
    case MessageDeliveryStatus.sent:
      return Colors.blue;
    case MessageDeliveryStatus.delivered:
      return Colors.green;
    case MessageDeliveryStatus.failed:
      return Colors.red;
    case MessageDeliveryStatus.received:
      return Colors.grey;
  }
}

Widget buildChannelEchoStatus(BuildContext context, Message message) {
  final hasEcho = message.echoCount > 0;

  if (!hasEcho) {
    return const SizedBox.shrink();
  }

  final statusColor = getDeliveryStatusColor(message.deliveryStatus);
  final rssi = message.lastEchoRssiDbm;
  final snr = message.lastEchoSnrRaw != null
      ? message.lastEchoSnrRaw!.toSigned(8) / 4.0
      : null;
  final quality = linkQualityLabel(rssi, snr);
  final qualityColor = linkQualityColor(quality);

  return Wrap(
    spacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _techChip(
        context,
        icon: Icons.hub_outlined,
        label: 'x${message.echoCount}',
        color: statusColor,
      ),
      if (message.expectedAckTag != null)
        _techChip(
          context,
          icon: Icons.tag,
          label:
              'ACK ${message.expectedAckTag!.toRadixString(16).toUpperCase()}',
          color: Colors.indigo,
        ),
      _techChip(context, icon: Icons.bolt, label: quality, color: qualityColor),
      if (message.lastEchoRssiDbm != null)
        _signalCapsule(
          context,
          icon: Icons.network_cell,
          label: message.lastEchoRssiDbm!.toString(),
          filled: rssiScore(message.lastEchoRssiDbm!),
          color: Colors.blueGrey,
        ),
      if (message.lastEchoSnrRaw != null)
        _signalCapsule(
          context,
          icon: Icons.graphic_eq,
          label: (message.lastEchoSnrRaw!.toSigned(8) / 4.0).toStringAsFixed(1),
          filled: snrScore(message.lastEchoSnrRaw!.toSigned(8) / 4.0),
          color: Colors.teal,
        ),
    ],
  );
}

bool shouldShowSentChannelStats(
  Message message, {
  required bool showReceivedStats,
}) {
  if (!message.isSentMessage || !message.isChannelMessage) {
    return false;
  }

  final hasSignalData =
      message.echoCount > 0 ||
      message.lastEchoRssiDbm != null ||
      message.lastEchoSnrRaw != null ||
      message.expectedAckTag != null;
  return showReceivedStats && hasSignalData;
}

Widget buildReceivedSignalStatus(
  BuildContext context,
  Message message, {
  MessageReceptionDetails? receptionDetails,
  required int? rssiDbm,
  required double? snrDb,
}) {
  final hopLabel = hopDisplayLabel(message);

  return Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _techChip(
        context,
        icon: Icons.alt_route,
        label: hopLabel,
        color: Colors.indigo,
      ),
      if (receptionDetails?.senderToReceiptMs != null)
        _techChip(
          context,
          icon: Icons.schedule,
          label: _formatMs(receptionDetails!.senderToReceiptMs!),
          color: Colors.deepPurple,
        ),
      if (receptionDetails?.estimatedTransmitMs != null)
        _techChip(
          context,
          icon: Icons.timelapse,
          label: '~${_formatMs(receptionDetails!.estimatedTransmitMs!)} tx',
          color: Colors.blue,
        ),
      if (receptionDetails?.postTransmitDelayMs != null)
        _techChip(
          context,
          icon: Icons.hourglass_bottom,
          label: '+${_formatMs(receptionDetails!.postTransmitDelayMs!)} lag',
          color: Colors.orange,
        ),
      if (receptionDetails?.pathBytesHex != null)
        _techChip(
          context,
          icon: Icons.route,
          label: receptionDetails!.pathBytesHex!,
          color: Colors.brown,
        ),
      if (rssiDbm != null || snrDb != null) ...[
        _techChip(
          context,
          icon: Icons.bolt,
          label: linkQualityLabel(rssiDbm, snrDb),
          color: linkQualityColor(linkQualityLabel(rssiDbm, snrDb)),
        ),
        if (rssiDbm != null)
          _signalCapsule(
            context,
            icon: Icons.network_cell,
            label: '$rssiDbm',
            filled: rssiScore(rssiDbm),
            color: Colors.blueGrey,
          ),
        if (snrDb != null)
          _signalCapsule(
            context,
            icon: Icons.graphic_eq,
            label: snrDb.toStringAsFixed(1),
            filled: snrScore(snrDb),
            color: Colors.teal,
          ),
      ],
    ],
  );
}

Widget buildSentDirectSignalStatus(
  BuildContext context,
  Message message, {
  required int roundTripTimeMs,
  required Duration txEstimate,
}) {
  final estimatedTransmitMs = sanitizeEstimatedTransmitMs(
    estimatedTransmitMs: txEstimate > Duration.zero
        ? txEstimate.inMilliseconds
        : null,
    senderToReceiptMs: roundTripTimeMs,
  );
  final postTransmitDelayMs = estimatedTransmitMs != null
      ? (roundTripTimeMs - estimatedTransmitMs).clamp(0, 86400000).toInt()
      : null;

  return Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _techChip(
        context,
        icon: Icons.alt_route,
        label: hopDisplayLabel(message),
        color: Colors.indigo,
      ),
      _techChip(
        context,
        icon: Icons.schedule,
        label: _formatMs(roundTripTimeMs),
        color: Colors.deepPurple,
      ),
      if (estimatedTransmitMs != null)
        _techChip(
          context,
          icon: Icons.timelapse,
          label: '~${_formatMs(estimatedTransmitMs)} tx',
          color: Colors.blue,
        ),
      if (postTransmitDelayMs != null)
        _techChip(
          context,
          icon: Icons.hourglass_bottom,
          label: '+${_formatMs(postTransmitDelayMs)} lag',
          color: Colors.orange,
        ),
      if (message.retryAttempt > 0)
        _techChip(
          context,
          icon: Icons.refresh,
          label: 'retry ${message.retryAttempt}/3',
          color: Colors.redAccent,
        ),
      if (message.suggestedTimeoutMs != null)
        _techChip(
          context,
          icon: Icons.timer_outlined,
          label: 'timeout ${_formatMs(message.suggestedTimeoutMs!)}',
          color: Colors.blueGrey,
        ),
      if (message.usedFloodFallback)
        _techChip(
          context,
          icon: Icons.waves,
          label: 'flood fallback',
          color: Colors.teal,
        )
      else if (message.expectedAckTag != null)
        _techChip(
          context,
          icon: Icons.route,
          label: 'direct ACK',
          color: Colors.indigo,
        ),
    ],
  );
}

String _formatMs(int value) {
  if (value >= 60000) {
    final minutes = value ~/ 60000;
    final seconds = (value % 60000) ~/ 1000;
    return '${minutes}m ${seconds}s';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}s';
  }
  return '${value}ms';
}

String hopDisplayLabel(Message message) {
  if (message.pathLen == 0) return 'Direct';
  if (message.pathLen >= 255 && message.isContactMessage) return 'Direct';
  if (message.pathLen >= 255) return 'Unknown';
  return '${message.pathLen} hop${message.pathLen == 1 ? '' : 's'}';
}

Widget _techChip(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

Widget _signalCapsule(
  BuildContext context, {
  required IconData icon,
  required String label,
  required int filled,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final active = i < filled;
            return Container(
              width: 3,
              height: (4 + i).toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: active ? color : color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

int rssiScore(int rssiDbm) => ((rssiDbm + 120) / 10).round().clamp(0, 5);

int snrScore(double snrDb) => ((snrDb + 5.0) / 5.0).round().clamp(0, 5);

String linkQualityLabel(int? rssiDbm, double? snrDb) {
  var score = 0;
  if (rssiDbm != null) score += rssiScore(rssiDbm);
  if (snrDb != null) score += snrScore(snrDb);
  if (score >= 8) return 'Excellent';
  if (score >= 6) return 'Good';
  if (score >= 4) return 'Fair';
  return 'Weak';
}

Color linkQualityColor(String quality) {
  switch (quality) {
    case 'Excellent':
      return Colors.green;
    case 'Good':
      return Colors.lightGreen;
    case 'Fair':
      return Colors.orange;
    default:
      return Colors.redAccent;
  }
}
