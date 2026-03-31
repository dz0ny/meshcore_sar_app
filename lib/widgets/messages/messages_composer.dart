import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../providers/app_provider.dart';
import '../common/contact_avatar.dart';

class MessagesComposer extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final TextInputFormatter messageByteLimiter;
  final int messageByteCount;
  final int maxMessageBytes;
  final bool isRecording;
  final bool isSendingVoice;
  final bool voiceSupported;
  final double bottomPadding;
  final String destinationLabel;
  final Widget destinationAvatar;
  final bool destinationLocked;
  final List<Contact> mentionSuggestions;
  final String mentionQuery;
  final ValueChanged<Contact> onMentionSelected;
  final VoidCallback onShowComposerActions;
  final VoidCallback onShowRecipientSelector;
  final Future<void> Function() onStartVoiceRecording;
  final Future<void> Function() onStopAndSendVoice;
  final Future<void> Function() onSendMessage;
  final VoidCallback? onLongPressSend;
  final String? regionScopeName;
  final VoidCallback? onRegionScopeTap;

  const MessagesComposer({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.messageByteLimiter,
    required this.messageByteCount,
    required this.maxMessageBytes,
    required this.isRecording,
    required this.isSendingVoice,
    required this.voiceSupported,
    required this.bottomPadding,
    required this.destinationLabel,
    required this.destinationAvatar,
    required this.destinationLocked,
    required this.mentionSuggestions,
    required this.mentionQuery,
    required this.onMentionSelected,
    required this.onShowComposerActions,
    required this.onShowRecipientSelector,
    required this.onStartVoiceRecording,
    required this.onStopAndSendVoice,
    required this.onSendMessage,
    this.onLongPressSend,
    this.regionScopeName,
    this.onRegionScopeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mentionSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: _MentionSuggestionsCard(
                suggestions: mentionSuggestions,
                query: mentionQuery,
                onSelected: onMentionSelected,
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 4, 10, bottomPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _ComposerActionButton(
                            isRecording: isRecording,
                            onPressed: isRecording
                                ? onStopAndSendVoice
                                : onShowComposerActions,
                          ),
                          if (regionScopeName != null &&
                              onRegionScopeTap != null) ...[
                            const SizedBox(width: 6),
                            _RegionScopeChip(
                              name: regionScopeName!,
                              onTap: onRegionScopeTap!,
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DestinationPill(
                              destinationLabel: destinationLabel,
                              destinationAvatar: destinationAvatar,
                              isLocked: destinationLocked,
                              onTap: destinationLocked
                                  ? null
                                  : onShowRecipientSelector,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          textController,
                          focusNode,
                        ]),
                        builder: (context, _) {
                          final canSendText =
                              !isRecording &&
                              !isSendingVoice &&
                              textController.text.trim().isNotEmpty;
                          final semanticsLabel = isRecording
                              ? 'Recording... release to send voice'
                              : (isSendingVoice
                                    ? 'Sending voice...'
                                    : voiceSupported
                                    ? 'Send (long press to record voice)'
                                    : 'Send');

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _MessageInput(
                                  textController: textController,
                                  focusNode: focusNode,
                                  messageByteLimiter: messageByteLimiter,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _SendButton(
                                canSendText: canSendText,
                                isRecording: isRecording,
                                isSendingVoice: isSendingVoice,
                                voiceSupported: voiceSupported,
                                semanticsLabel: semanticsLabel,
                                messageByteCount: messageByteCount,
                                maxMessageBytes: maxMessageBytes,
                                onSendMessage: onSendMessage,
                                onLongPressSend: onLongPressSend,
                                onStartVoiceRecording: onStartVoiceRecording,
                                onStopAndSendVoice: onStopAndSendVoice,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestionsCard extends StatelessWidget {
  final List<Contact> suggestions;
  final String query;
  final ValueChanged<Contact> onSelected;

  const _MentionSuggestionsCard({
    required this.suggestions,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = suggestions.length.clamp(1, 4);
    final maxHeight = visibleCount * 54.0;

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final contact = suggestions[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelected(contact),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            ContactAvatar(contact: contact, radius: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                contact.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const _ComposerActionButton({
    required this.isRecording,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: IconButton(
        icon: Icon(isRecording ? Icons.stop : Icons.add, size: 20),
        tooltip: isRecording ? 'Stop recording' : 'More actions',
        onPressed: onPressed,
        color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DestinationPill extends StatelessWidget {
  final String destinationLabel;
  final Widget destinationAvatar;
  final bool isLocked;
  final VoidCallback? onTap;

  const _DestinationPill({
    required this.destinationLabel,
    required this.destinationAvatar,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Ink(
      key: ValueKey(
        isLocked
            ? 'messages_composer_destination_locked'
            : 'messages_composer_destination_selector',
      ),
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            destinationAvatar,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destinationLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (!isLocked)
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return Material(color: Colors.transparent, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final TextInputFormatter messageByteLimiter;

  const _MessageInput({
    required this.textController,
    required this.focusNode,
    required this.messageByteLimiter,
  });

  @override
  Widget build(BuildContext context) {
    final messageFontScale = context.watch<AppProvider>().messageFontScale;
    const baseFontSize = 15.0;
    final resolvedFontSize = baseFontSize * messageFontScale;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 42, maxHeight: 116),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: focusNode.hasFocus
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.35),
          width: focusNode.hasFocus ? 1.4 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: TextField(
          controller: textController,
          focusNode: focusNode,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          inputFormatters: [messageByteLimiter],
          style: TextStyle(fontSize: resolvedFontSize),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.typeYourMessage,
            hintStyle: TextStyle(
              fontSize: resolvedFontSize,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
            filled: false,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            isCollapsed: true,
          ),
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool canSendText;
  final bool isRecording;
  final bool isSendingVoice;
  final bool voiceSupported;
  final String semanticsLabel;
  final int messageByteCount;
  final int maxMessageBytes;
  final Future<void> Function() onSendMessage;
  final VoidCallback? onLongPressSend;
  final Future<void> Function() onStartVoiceRecording;
  final Future<void> Function() onStopAndSendVoice;

  const _SendButton({
    required this.canSendText,
    required this.isRecording,
    required this.isSendingVoice,
    required this.voiceSupported,
    required this.semanticsLabel,
    required this.messageByteCount,
    required this.maxMessageBytes,
    required this.onSendMessage,
    this.onLongPressSend,
    required this.onStartVoiceRecording,
    required this.onStopAndSendVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: canSendText || (voiceSupported && !isSendingVoice),
      label: semanticsLabel,
      onTap: canSendText ? onSendMessage : null,
      onLongPress: canSendText && onLongPressSend != null
          ? onLongPressSend
          : (voiceSupported && !isSendingVoice)
              ? () {
                  if (isRecording) {
                    onStopAndSendVoice();
                    return;
                  }
                  onStartVoiceRecording();
                }
              : null,
      child: Tooltip(
        message: semanticsLabel,
        excludeFromSemantics: true,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: canSendText ? onSendMessage : null,
          onLongPressStart: canSendText && onLongPressSend != null
              ? (_) => onLongPressSend!()
              : (voiceSupported && !isSendingVoice)
                  ? (_) => onStartVoiceRecording()
                  : null,
          onLongPressEnd: (!canSendText && voiceSupported && isRecording)
              ? (_) => onStopAndSendVoice()
              : null,
          onLongPressCancel: (!canSendText && voiceSupported && isRecording)
              ? onStopAndSendVoice
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: canSendText || isRecording
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: canSendText || isRecording
                        ? Colors.transparent
                        : Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                  ),
                  boxShadow: canSendText || isRecording
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: isSendingVoice
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        isRecording ? Icons.mic_rounded : Icons.send_rounded,
                        size: 20,
                        color: canSendText || isRecording
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                '$messageByteCount/$maxMessageBytes',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: messageByteCount > maxMessageBytes * 0.9
                      ? Colors.orange.shade800
                      : Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionScopeChip extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _RegionScopeChip({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 16,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onTertiaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
