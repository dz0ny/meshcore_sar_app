import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/config_profile.dart';
import '../services/profile_manager.dart';
import '../services/profile_workspace_coordinator.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileManager>(
      builder: (context, profileManager, child) {
        final profiles = profileManager.visibleProfiles;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profiles'),
            actions: [
              IconButton(
                onPressed: () async {
                  await context
                      .read<ProfileWorkspaceCoordinator>()
                      .importProfileFromFile();
                },
                icon: const Icon(Icons.file_open),
                tooltip: 'Import profile',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createProfile(context),
            icon: const Icon(Icons.add),
            label: const Text('New Profile'),
          ),
          body: profiles.isEmpty
              ? const Center(
                  child: Text('Enable profiles to start managing them.'),
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
                                    child: const Text('Active'),
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
                                  child: const Text('Open'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    await context
                                        .read<ProfileWorkspaceCoordinator>()
                                        .applyProfile(profile.id);
                                  },
                                  child: const Text('Apply'),
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
                                  child: const Text('Share'),
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
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text('Duplicate'),
                                    ),
                                    if (!profile.isDefault)
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Text('Rename'),
                                      ),
                                    if (!profile.isDefault)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
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
        title: const Text('Create Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
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
        title: const Text('Rename Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
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
