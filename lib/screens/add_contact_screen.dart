import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/connection_provider.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _advertController = TextEditingController();
  bool _isImporting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadClipboardIfPresent();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }

    setState(() {
      _advertController.text = text.trim();
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contact imported')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = _normalizeAdvertText(_advertController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Import an exported contact advert, like meshcore-open.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a `meshcore://...` link or raw hex advert from the clipboard.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _advertController,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) {
              if (_validationError != null) {
                setState(() {
                  _validationError = null;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Contact advert',
              hintText: 'meshcore://...',
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              errorText: _validationError,
            ),
          ),
          const SizedBox(height: 12),
          if (normalized != null)
            Text(
              'Advert size: ${normalized.length ~/ 2} bytes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isImporting ? null : _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_go_outlined),
                  label: const Text('Paste'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isImporting ? null : _importContact,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(_isImporting ? 'Importing...' : 'Add Contact'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
