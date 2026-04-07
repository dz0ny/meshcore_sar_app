import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/connection_provider.dart';
import '../l10n/app_localizations.dart';

class AddContactScreen extends StatefulWidget {
  final String? initialAdvert;

  const AddContactScreen({super.key, this.initialAdvert});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _advertController = TextEditingController();
  bool _isImporting = false;
  bool _importSucceeded = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialAdvert != null &&
        widget.initialAdvert!.trim().isNotEmpty) {
      _advertController.text = widget.initialAdvert!.trim();
    } else {
      _loadClipboardIfPresent();
    }
  }

  @override
  void dispose() {
    _advertController.dispose();
    super.dispose();
  }

  Future<void> _loadClipboardIfPresent() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();
    if (!mounted || text == null || text.isEmpty) {
      return;
    }
    if (_normalizeAdvertText(text) == null) {
      return;
    }
    _advertController.text = text;
  }

  String? _normalizeAdvertText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed;
    if (normalized.startsWith('meshcore://')) {
      normalized = normalized.substring('meshcore://'.length);
    }

    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized);
    if (!isHex || normalized.length.isOdd) {
      return null;
    }

    return normalized.toLowerCase();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.clipboardIsEmpty)),
      );
      return;
    }

    setState(() {
      _advertController.text = text.trim();
      _importSucceeded = false;
      _validationError = null;
    });
  }

  Future<void> _importContact() async {
    final normalized = _normalizeAdvertText(_advertController.text);
    if (normalized == null) {
      setState(() {
        _validationError =
            'Enter a valid meshcore:// advert or raw hexadecimal contact advert.';
      });
      return;
    }

    final advertBytes = _hexToBytes(normalized);
    if (advertBytes.length < 98) {
      setState(() {
        _validationError =
            'Advert is too short. Expected exported contact data.';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _importSucceeded = false;
      _validationError = null;
    });

    final connectionProvider = context.read<ConnectionProvider>();
    await connectionProvider.importContactAdvert(advertBytes);
    final importError = connectionProvider.error;

    if (importError == null) {
      await connectionProvider.getContacts();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isImporting = false;
    });

    if (importError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(importError)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.contactImported)),
    );
    setState(() {
      _importSucceeded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = _normalizeAdvertText(_advertController.text);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.addContact)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Import a shared contact advert',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Paste a `meshcore://...` link or raw hexadecimal advert. The app will validate it and import the contact into the connected device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ImportHintChip(
                      icon: Icons.link_outlined,
                      label: AppLocalizations.of(context)!.acceptsShareLinks,
                    ),
                    _ImportHintChip(
                      icon: Icons.code_outlined,
                      label: AppLocalizations.of(context)!.supportsRawHex,
                    ),
                    _ImportHintChip(
                      icon: Icons.content_paste_go_outlined,
                      label: AppLocalizations.of(context)!.clipboardfriendly,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advert payload',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can paste the full share link or only the hex payload.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _advertController,
                  minLines: 5,
                  maxLines: 9,
                  onChanged: (_) {
                    if (_validationError != null || _importSucceeded) {
                      setState(() {
                        _importSucceeded = false;
                        _validationError = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Contact advert',
                    hintText: AppLocalizations.of(context)!.pasteShareLinkOrHexAdvert,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    errorText: _validationError,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        normalized == null
                            ? 'No valid advert detected yet'
                            : 'Advert size: ${normalized.length ~/ 2} bytes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isImporting ? null : _pasteFromClipboard,
                      icon: Icon(Icons.content_paste_go_outlined),
                      label: Text(AppLocalizations.of(context)!.paste),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_isImporting || _importSucceeded)
                ? null
                : _importContact,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _isImporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _importSucceeded
                ? const Icon(Icons.check_circle_outline)
                : const Icon(Icons.person_add_alt_1_outlined),
            label: Text(
              _isImporting
                  ? 'Importing...'
                  : _importSucceeded
                  ? 'Imported'
                  : 'Add Contact',
            ),
          ),
          const SizedBox(height: 12),
          if (_importSucceeded)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Contact imported. Paste another advert or edit the current one to import again.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportHintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImportHintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
