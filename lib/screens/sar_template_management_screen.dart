import 'package:flutter/material.dart';
import '../models/sar_template.dart';
import '../services/sar_template_service.dart';
import '../widgets/sar/sar_template_edit_dialog.dart';
import '../l10n/app_localizations.dart';

/// Screen for managing SAR templates
class SarTemplateManagementScreen extends StatefulWidget {
  const SarTemplateManagementScreen({super.key});

  @override
  State<SarTemplateManagementScreen> createState() => _SarTemplateManagementScreenState();
}

class _SarTemplateManagementScreenState extends State<SarTemplateManagementScreen> {
  final SarTemplateService _templateService = SarTemplateService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    if (!_templateService.isInitialized) {
      setState(() => _isLoading = true);
      await _templateService.initialize();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTemplate() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarTemplateEditDialog(
        onSave: (template) async {
          await _templateService.addTemplate(template);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.templateAdded),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _editTemplate(SarTemplate template) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarTemplateEditDialog(
        template: template,
        onSave: (updatedTemplate) async {
          await _templateService.updateTemplate(template.id, updatedTemplate);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.templateUpdated),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteTemplate(SarTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTemplate),
        content: Text(
          AppLocalizations.of(context)!.deleteTemplateConfirmation(template.getLocalizedName(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _templateService.deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.templateDeleted),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _importFromClipboard() async {
    setState(() => _isLoading = true);

    try {
      final importedCount = await _templateService.importFromClipboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.templatesImported(importedCount)),
            backgroundColor: importedCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportToClipboard() async {
    try {
      await _templateService.exportToClipboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.templatesExported(_templateService.templateCount),
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.ok,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetToDefaults),
        content: Text(AppLocalizations.of(context)!.resetToDefaultsConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.reset),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _templateService.resetToDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.resetComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sarTemplates),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importFromClipboard();
                  break;
                case 'export':
                  _exportToClipboard();
                  break;
                case 'reset':
                  _resetToDefaults();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.importFromClipboard),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.upload),
                  title: Text(l10n.exportToClipboard),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: Text(l10n.resetToDefaults),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _templateService,
              builder: (context, child) {
                final templates = _templateService.templates;

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_searching,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTemplates,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tapAddToCreate,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _TemplateListItem(
                      template: template,
                      onTap: () => _editTemplate(template),
                      onDelete: () => _deleteTemplate(template),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTemplate,
        icon: const Icon(Icons.add),
        label: Text(l10n.addTemplate),
      ),
    );
  }
}

/// Template list item widget
class _TemplateListItem extends StatelessWidget {
  final SarTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateListItem({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteTemplate),
            content: Text(
              AppLocalizations.of(context)!.deleteTemplateConfirmation(template.getLocalizedName(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: template.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: template.color.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              template.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              template.getLocalizedName(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (template.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: template.description.isNotEmpty
            ? Text(
                template.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            : Text(
                template.toSarMessage(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
