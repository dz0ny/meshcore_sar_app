import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Dialog for adding a new channel
class AddChannelDialog extends StatefulWidget {
  final Future<void> Function(String name, String secret) onCreateChannel;

  const AddChannelDialog({
    super.key,
    required this.onCreateChannel,
  });

  @override
  State<AddChannelDialog> createState() => _AddChannelDialogState();
}

class _AddChannelDialogState extends State<AddChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _secretController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  /// Validate that a string contains only ASCII characters
  bool _isAscii(String text) {
    return text.codeUnits.every((unit) => unit < 128);
  }

  /// Validate channel name
  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.channelNameRequired;
    }

    if (value.length > 31) {
      return l10n.channelNameTooLong;
    }

    if (!_isAscii(value)) {
      return l10n.invalidAsciiCharacters;
    }

    return null;
  }

  /// Validate channel secret
  String? _validateSecret(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.channelSecretRequired;
    }

    if (value.length > 32) {
      return l10n.channelSecretTooLong;
    }

    if (!_isAscii(value)) {
      return l10n.invalidAsciiCharacters;
    }

    return null;
  }

  /// Handle channel creation
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreateChannel(
        _nameController.text.trim(),
        _secretController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is handled by parent
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.addChannel),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.channelName,
                  hintText: l10n.channelNameHint,
                  border: const OutlineInputBorder(),
                ),
                enabled: !_isCreating,
                maxLength: 31,
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Channel Secret Field
              TextFormField(
                controller: _secretController,
                decoration: InputDecoration(
                  labelText: l10n.channelSecret,
                  hintText: l10n.channelSecretHint,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isCreating,
                maxLength: 32,
                validator: _validateSecret,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleCreate(),
              ),
              const SizedBox(height: 8),

              // Help Text
              Text(
                l10n.channelSecretHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),

        // Create Button
        FilledButton(
          onPressed: _isCreating ? null : _handleCreate,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.createChannel),
        ),
      ],
    );
  }
}
