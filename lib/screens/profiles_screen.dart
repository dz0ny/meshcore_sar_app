import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/config_profile.dart';
import '../services/profile_manager.dart';
import '../services/profile_workspace_coordinator.dart';
import '../l10n/app_localizations.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileManager>(
      builder: (context, profileManager, child) {
        final profiles = profileManager.visibleProfiles;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.profiles),
            actions: [
              IconButton(
                onPressed: () async {
                  await context
                      .read<ProfileWorkspaceCoordinator>()
                      .importProfileFromFile();
                },
                icon: const Icon(Icons.file_open),
                tooltip: AppLocalizations.of(context)!.importProfile,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createProfile(context),
            icon: Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.newProfile),
          ),
          body: profiles.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context)!.enableProfilesToStartManagingThem),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    final isActive =
                        profileManager.activeProfileId == profile.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(AppLocalizations.of(context)!.active),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_summary(profile)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    await context
                                        .read<ProfileWorkspaceCoordinator>()
                                        .openProfile(profile.id);
                                  },
                                  child: Text(AppLocalizations.of(context)!.open),
                                ),
                                OutlinedButton(
                                  onPressed: () async {
                                    final resolved =
                                        profile.id ==
                                            ConfigProfile.defaultProfileId
                                        ? await context
                                              .read<
                                                ProfileWorkspaceCoordinator
                                              >()
                                              .snapshotCurrentProfile(
                                                id: profile.id,
                                                name: profile.name,
                                              )
                                        : profile;
                                    if (!context.mounted) return;
                                    await context
                                        .read<ProfileWorkspaceCoordinator>()
                                        .exportProfile(resolved);
                                  },
                                  child: Text(AppLocalizations.of(context)!.share),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'duplicate':
                                        await context
                                            .read<ProfileWorkspaceCoordinator>()
                                            .duplicateProfile(profile);
                                        break;
                                      case 'rename':
                                        await _renameProfile(context, profile);
                                        break;
                                      case 'delete':
                                        await context
                                            .read<ProfileWorkspaceCoordinator>()
                                            .deleteProfile(profile);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text(AppLocalizations.of(context)!.duplicate),
                                    ),
                                    if (!profile.isDefault)
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text(AppLocalizations.of(context)!.rename),
                                      ),
                                    if (!profile.isDefault)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(AppLocalizations.of(context)!.delete),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _summary(ConfigProfile profile) {
    if (profile.isDefault) {
      return 'Current app state and history.';
    }

    final sections = <String>[];
    if (profile.sections.deviceConfig?.isEmpty == false) {
      sections.add('Device');
    }
    if (profile.sections.channels.isNotEmpty) {
      sections.add('${profile.sections.channels.length} channels');
    }
    if (profile.sections.appSettings?.isEmpty == false) {
      sections.add('App settings');
    }
    if (profile.sections.mapWorkspace?.isEmpty == false) {
      sections.add('Map workspace');
    }
    return sections.isEmpty ? 'Empty profile' : sections.join(' | ');
  }

  Future<void> _createProfile(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }
    await context.read<ProfileWorkspaceCoordinator>().createProfileFromCurrent(
      name: name,
    );
  }

  Future<void> _renameProfile(
    BuildContext context,
    ConfigProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.renameProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }
    await context.read<ProfileWorkspaceCoordinator>().renameProfile(
      profile,
      name,
    );
  }
}
