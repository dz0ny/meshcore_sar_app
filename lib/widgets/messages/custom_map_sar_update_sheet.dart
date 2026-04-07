import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../models/sar_template.dart';
import '../../providers/contacts_provider.dart';
import '../../services/sar_template_service.dart';
import 'sar_update_sheet.dart' show TemplateChip;

class CustomMapSarUpdateSheet extends StatefulWidget {
  final String mapName;
  final String mapId;
  final String pointLabel;
  final Future<void> Function(
    String emoji,
    String name,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    bool sendToAllContacts,
    int colorIndex,
  )
  onSend;

  const CustomMapSarUpdateSheet({
    super.key,
    required this.mapName,
    required this.mapId,
    required this.pointLabel,
    required this.onSend,
  });

  @override
  State<CustomMapSarUpdateSheet> createState() =>
      _CustomMapSarUpdateSheetState();
}

class _CustomMapSarUpdateSheetState extends State<CustomMapSarUpdateSheet> {
  final SarTemplateService _templateService = SarTemplateService();
  final TextEditingController _notesController = TextEditingController();

  List<SarTemplate> _templates = [];
  SarTemplate? _selectedTemplate;
  Contact? _selectedContact;
  bool _sendToAllContacts = false;

  @override
  void initState() {
    super.initState();
    _initializeTemplates();
    _setDefaultDestination();
  }

  Future<void> _initializeTemplates() async {
    if (!_templateService.isInitialized) {
      await _templateService.initialize();
    }
    if (!mounted) return;
    setState(() {
      _templates = _templateService.templates;
      if (_templates.isNotEmpty) {
        _selectedTemplate = _templates.first;
      }
    });
  }

  void _setDefaultDestination() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contactsProvider = context.read<ContactsProvider>();
      final roomsAndChannels = contactsProvider.roomsAndChannels;
      final teamContacts = contactsProvider.chatContacts;

      if (teamContacts.length > 1) {
        setState(() {
          _sendToAllContacts = true;
          _selectedContact = null;
        });
        return;
      }

      if (teamContacts.length == 1) {
        setState(() {
          _sendToAllContacts = false;
          _selectedContact = teamContacts.first;
        });
        return;
      }

      if (roomsAndChannels.any((c) => c.isRoom)) {
        setState(() {
          _sendToAllContacts = false;
          _selectedContact = roomsAndChannels.firstWhere((c) => c.isRoom);
        });
        return;
      }

      if (roomsAndChannels.isNotEmpty) {
        setState(() {
          _sendToAllContacts = false;
          _selectedContact = roomsAndChannels.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Send SAR marker',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Custom cave map point',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80 + bottomSafeArea,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.markerType,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._templates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TemplateChip(
                          template: template,
                          isSelected: _selectedTemplate?.id == template.id,
                          onTap: () =>
                              setState(() => _selectedTemplate = template),
                        ),
                      );
                    }),
                    SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.sendTo,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<ContactsProvider>(
                      builder: (context, contactsProvider, child) {
                        final teamContacts = contactsProvider.chatContacts;
                        final roomsAndChannels =
                            contactsProvider.roomsAndChannels;
                        final destinations = <Contact>[
                          ...teamContacts,
                          ...roomsAndChannels.where((c) => c.isRoom),
                          ...roomsAndChannels.where((c) => c.isChannel),
                        ];

                        if (destinations.isEmpty && teamContacts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context)!.noDestinationsAvailableLabel),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sendToAllContacts
                                  ? 'all_contacts'
                                  : _selectedContact?.publicKeyHex,
                              hint: Text(
                                AppLocalizations.of(context)!.selectDestination,
                              ),
                              dropdownColor:
                                  colorScheme.surfaceContainerHighest,
                              isExpanded: true,
                              items: [
                                if (teamContacts.isNotEmpty)
                                  DropdownMenuItem<String>(
                                    value: 'all_contacts',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.group, size: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.allTeamContacts,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ...destinations.map((contact) {
                                  final icon = contact.isChat
                                      ? Icons.person
                                      : contact.isRoom
                                      ? Icons.storage
                                      : Icons.public;
                                  return DropdownMenuItem<String>(
                                    value: contact.publicKeyHex,
                                    child: Row(
                                      children: [
                                        Icon(icon, size: 18),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            contact.getLocalizedDisplayName(
                                              context,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (value == 'all_contacts') {
                                    _sendToAllContacts = true;
                                    _selectedContact = null;
                                  } else {
                                    _sendToAllContacts = false;
                                    _selectedContact = destinations.firstWhere(
                                      (c) => c.publicKeyHex == value,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Map point',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 20,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.mapName,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.pointLabel,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Map ID: ${widget.mapId}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Additional notes (optional)',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addAdditionalDetails,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomSafeArea),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_selectedTemplate == null ||
                        (!_sendToAllContacts && _selectedContact == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.selectMarkerTypeAndDestination),
                        ),
                      );
                      return;
                    }

                    await widget.onSend(
                      _selectedTemplate!.emoji,
                      _notesController.text.trim().isEmpty
                          ? _selectedTemplate!.name
                          : _notesController.text.trim(),
                      _selectedContact?.isChannel == true
                          ? null
                          : _selectedContact?.publicKey,
                      _selectedContact?.isChannel == true,
                      _sendToAllContacts,
                      _templates.indexOf(_selectedTemplate!),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.send),
                  label: Text(AppLocalizations.of(context)!.send),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
