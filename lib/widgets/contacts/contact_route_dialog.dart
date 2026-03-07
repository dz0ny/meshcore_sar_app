import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../services/route_hash_preferences.dart';

class ContactRouteDialog extends StatefulWidget {
  final Contact contact;
  final List<Contact> availableContacts;

  const ContactRouteDialog({
    super.key,
    required this.contact,
    required this.availableContacts,
  });

  static Future<ParsedContactRoute?> show(
    BuildContext context, {
    required Contact contact,
    required List<Contact> availableContacts,
  }) {
    return showModalBottomSheet<ParsedContactRoute>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ContactRouteDialog(
            contact: contact,
            availableContacts: availableContacts,
          ),
        ),
      ),
    );
  }

  @override
  State<ContactRouteDialog> createState() => _ContactRouteDialogState();
}

class _ContactRouteDialogState extends State<ContactRouteDialog> {
  late final TextEditingController _controller;
  int _selectedHashSize = RouteHashPreferences.defaultHashSize;
  ParsedContactRoute? _parsedRoute;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.contact.routeCanonicalText,
    );
    _controller.addListener(_reparse);
    _loadHashSizePreference();
    _reparse();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_reparse)
      ..dispose();
    super.dispose();
  }

  void _reparse() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _parsedRoute = null;
        _errorText = null;
      });
      return;
    }

    try {
      final parsed = ContactRouteCodec.parse(
        input,
        expectedHashSize: _selectedHashSize,
      );
      setState(() {
        _parsedRoute = parsed;
        _errorText = null;
      });
    } on ContactRouteFormatException catch (error) {
      setState(() {
        _parsedRoute = null;
        _errorText = error.message;
      });
    }
  }

  Future<void> _loadHashSizePreference() async {
    final hashSize = await RouteHashPreferences.getHashSize();
    if (!mounted) return;
    setState(() {
      _selectedHashSize = hashSize;
    });
    _reparse();
  }

  String _tokenFor(Contact contact, int hashSize) {
    final hex = contact.publicKeyHex.toUpperCase();
    final length = hashSize * 2;
    if (hex.length < length) {
      return hex;
    }
    return hex.substring(0, length);
  }

  void _appendHop(Contact contact) {
    final token = _tokenFor(contact, _selectedHashSize);
    final current = _controller.text.trim();
    _controller.text = current.isEmpty ? token : '$current,$token';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeCandidates =
        widget.availableContacts
            .where((contact) => contact.isRepeater || contact.isRoom)
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Route for ${widget.contact.displayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Route',
                hintText: _selectedHashSize == 1
                    ? 'AA,BB,CC'
                    : _selectedHashSize == 2
                    ? 'AABB,CCDD'
                    : 'AABBCC,DDEEFF',
                helperText:
                    'Use comma-separated hops. Path byte size comes from global Settings. Colon form like AA:BB is also accepted.',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _parsedRoute == null
                  ? 'Preview: enter a route to validate it.'
                  : 'Preview: ${_parsedRoute!.summary} • ${_parsedRoute!.byteLength} bytes • descriptor 0x${_parsedRoute!.encodedPathLen.toRadixString(16).padLeft(2, '0').toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_parsedRoute != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                _parsedRoute!.canonicalText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Pick hops from contacts',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            if (routeCandidates.isEmpty)
              const Text(
                'No repeater or room contacts are available for route building.',
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: routeCandidates.length,
                  itemBuilder: (context, index) {
                    final candidate = routeCandidates[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(candidate.displayName),
                      subtitle: Text(
                        '1B ${_tokenFor(candidate, 1)} • 2B ${_tokenFor(candidate, 2)} • 3B ${_tokenFor(candidate, 3)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: TextButton(
                        onPressed: () => _appendHop(candidate),
                        child: Text(
                          'Use ${_tokenFor(candidate, _selectedHashSize)}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _parsedRoute == null
                      ? null
                      : () => Navigator.of(context).pop(_parsedRoute),
                  child: const Text('Set Route'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
