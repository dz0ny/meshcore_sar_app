import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../providers/app_provider.dart';
import '../../services/route_hash_preferences.dart';

class ContactRouteDialogResult {
  final ParsedContactRoute? route;
  final bool shouldClear;

  const ContactRouteDialogResult._({this.route, required this.shouldClear});

  const ContactRouteDialogResult.set(ParsedContactRoute route)
    : this._(route: route, shouldClear: false);

  const ContactRouteDialogResult.clear() : this._(shouldClear: true);
}

class ContactRouteDialog extends StatefulWidget {
  final Contact contact;
  final List<Contact> availableContacts;

  const ContactRouteDialog({
    super.key,
    required this.contact,
    required this.availableContacts,
  });

  static Future<ContactRouteDialogResult?> show(
    BuildContext context, {
    required Contact contact,
    required List<Contact> availableContacts,
  }) {
    return showModalBottomSheet<ContactRouteDialogResult>(
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
  bool _showRoutingInfo = false;

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
    final appProvider = context.watch<AppProvider>();
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
            _AutomationRoutingInfo(
              isExpanded: _showRoutingInfo,
              onToggle: () {
                setState(() {
                  _showRoutingInfo = !_showRoutingInfo;
                });
              },
              autoRouteRotationEnabled: appProvider.autoRouteRotationEnabled,
              clearPathOnMaxRetry: appProvider.clearPathOnMaxRetry,
            ),
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
                if (widget.contact.routeHasPath)
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const ContactRouteDialogResult.clear()),
                    child: const Text('Clear Route'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _parsedRoute == null
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pop(ContactRouteDialogResult.set(_parsedRoute!)),
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

class _AutomationRoutingInfo extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool autoRouteRotationEnabled;
  final bool clearPathOnMaxRetry;

  const _AutomationRoutingInfo({
    required this.isExpanded,
    required this.onToggle,
    required this.autoRouteRotationEnabled,
    required this.clearPathOnMaxRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatic direct-send routing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Text(
              'Room/contact sends keep one selected path for the whole send chain, retry up to 5 total attempts with 1s, 2s, 4s, and 8s backoff, then try one final nearest repeater if everything else fails.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Public and channel broadcasts are not affected by this automation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: autoRouteRotationEnabled
                      ? 'Auto route rotation on'
                      : 'Auto route rotation off',
                  icon: Icons.swap_horiz,
                ),
                _InfoChip(
                  label: clearPathOnMaxRetry
                      ? 'Clear path on max retry on'
                      : 'Clear path on max retry off',
                  icon: Icons.route,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Shows retry, rotation, and final repeater fallback behavior.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
