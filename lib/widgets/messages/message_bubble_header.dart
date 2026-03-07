import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../models/message.dart';
import '../../utils/avatar_label_helper.dart';
import '../../utils/message_extensions.dart';
import '../common/contact_avatar.dart';

Widget buildMessageHeaderAvatar(
  BuildContext context, {
  required bool isOwnMessage,
  required bool isChannelMessage,
  required dynamic senderContact,
  required String displayName,
}) {
  if (isOwnMessage) {
    return CircleAvatar(
      radius: 10.5,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.account_circle,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  if (senderContact is Contact) {
    return ContactAvatar(
      contact: senderContact,
      radius: 10.5,
      displayName: displayName,
    );
  }

  final background = isChannelMessage
      ? Colors.teal.withValues(alpha: 0.16)
      : Theme.of(context).colorScheme.surfaceContainerHighest;
  final foreground = isChannelMessage
      ? Colors.teal.shade800
      : Theme.of(context).colorScheme.onSurfaceVariant;

  return CircleAvatar(
    radius: 10.5,
    backgroundColor: background,
    child: Text(
      AvatarLabelHelper.buildLabel(displayName),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: foreground,
        letterSpacing: -0.2,
      ),
    ),
  );
}

Widget buildBubbleMetaFooter(
  BuildContext context, {
  required Message message,
  required bool isSarMarker,
}) {
  final metaColor = Theme.of(
    context,
  ).textTheme.labelSmall?.color?.withValues(alpha: 0.68);

  final items = <Widget>[];
  final sentEchoLabel = message.isSentMessage && message.echoCount > 0
      ? '${message.echoCount} echo${message.echoCount == 1 ? '' : 'es'}'
      : null;

  if (!isSarMarker && sentEchoLabel != null) {
    items.addAll([
      Icon(Icons.hub_outlined, size: 11, color: metaColor),
      const SizedBox(width: 3),
      Text(
        sentEchoLabel,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: metaColor),
      ),
      Text(
        ' • ',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: metaColor),
      ),
    ]);
  } else if (!isSarMarker && message.pathLen < 255) {
    items.addAll([
      Icon(Icons.alt_route, size: 11, color: metaColor),
      const SizedBox(width: 3),
      Text(
        message.pathLen == 0 ? 'direct' : '${message.pathLen}hop',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: metaColor),
      ),
      Text(
        ' • ',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: metaColor),
      ),
    ]);
  }

  items.add(
    Text(
      message.getLocalizedTimeAgo(context),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: metaColor,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  return Padding(
    padding: const EdgeInsets.only(left: 6, right: 6, top: 1, bottom: 18),
    child: Align(
      alignment: Alignment.centerRight,
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    ),
  );
}

Widget buildChannelHeaderPill(
  BuildContext context, {
  required String label,
  IconData icon = Icons.campaign_outlined,
}) {
  final labelColor = Theme.of(
    context,
  ).textTheme.labelSmall?.color?.withValues(alpha: 0.82);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: Theme.of(
            context,
          ).textTheme.labelSmall?.color?.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget buildDirectHeaderCounterpart(
  BuildContext context, {
  required String label,
}) {
  return buildChannelHeaderPill(
    context,
    label: label,
    icon: Icons.alternate_email,
  );
}
