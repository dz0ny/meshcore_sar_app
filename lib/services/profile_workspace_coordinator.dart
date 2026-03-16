import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/config_profile.dart';
import '../providers/app_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/map_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/sensors_provider.dart';
import 'app_config_snapshot_service.dart';
import 'contact_storage_service.dart';
import 'device_config_applicator.dart';
import 'message_storage_service.dart';
import 'profile_manager.dart';
import 'profiles_feature_service.dart';
import 'map_workspace_snapshot_service.dart';

class ProfileWorkspaceCoordinator {
  ProfileWorkspaceCoordinator({
    required this.profileManager,
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.sensorsProvider,
    required this.mapProvider,
    required this.drawingProvider,
    required this.channelsProvider,
    required this.appProvider,
    AppConfigSnapshotService? appConfigSnapshotService,
    MapWorkspaceSnapshotService? mapWorkspaceSnapshotService,
    DeviceConfigApplicator? deviceConfigApplicator,
    MessageStorageService? messageStorageService,
    ContactStorageService? contactStorageService,
  }) : _appConfigSnapshotService =
           appConfigSnapshotService ?? AppConfigSnapshotService(),
       _mapWorkspaceSnapshotService =
           mapWorkspaceSnapshotService ?? MapWorkspaceSnapshotService(),
       _deviceConfigApplicator =
           deviceConfigApplicator ?? DeviceConfigApplicator(),
       _messageStorageService =
           messageStorageService ?? MessageStorageService(),
       _contactStorageService =
           contactStorageService ?? ContactStorageService();

  final ProfileManager profileManager;
  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final SensorsProvider sensorsProvider;
  final MapProvider mapProvider;
  final DrawingProvider drawingProvider;
  final ChannelsProvider channelsProvider;
  final AppProvider appProvider;
  final AppConfigSnapshotService _appConfigSnapshotService;
  final MapWorkspaceSnapshotService _mapWorkspaceSnapshotService;
  final DeviceConfigApplicator _deviceConfigApplicator;
  final MessageStorageService _messageStorageService;
  final ContactStorageService _contactStorageService;

  Future<void> setProfilesEnabled(bool enabled) async {
    final wasEnabled = profileManager.profilesEnabled;
    if (wasEnabled && !enabled) {
      await _saveActiveCustomProfileSnapshot();
    } else {
      await _persistCurrentState();
    }
    await profileManager.setProfilesEnabled(enabled);
    ProfileStorageScope.setScope(
      profilesEnabled: enabled,
      activeProfileId: enabled ? profileManager.activeProfileId : 'default',
    );
    if (enabled) {
      if (wasEnabled) {
        await openProfile(profileManager.activeProfileId);
      } else {
        await _switchRuntimeScope(profileManager.activeProfileId);
        final profile = await resolveProfile(profileManager.activeProfileId);
        await _appConfigSnapshotService.apply(
          profile.sections.appSettings,
          appProvider,
        );
        await _mapWorkspaceSnapshotService.apply(
          profile.sections.mapWorkspace,
          mapProvider: mapProvider,
          drawingProvider: drawingProvider,
        );
      }
    } else {
      await _switchRuntimeScope('default');
    }
  }

  Future<ConfigProfile> snapshotCurrentProfile({
    required String id,
    required String name,
    String? notes,
  }) async {
    final deviceSections = _deviceConfigApplicator.capture(
      connectionProvider: connectionProvider,
      channelsProvider: channelsProvider,
    );
    final appSettings = await _appConfigSnapshotService.capture(appProvider);
    final mapWorkspace = await _mapWorkspaceSnapshotService.capture(
      mapProvider: mapProvider,
      drawingProvider: drawingProvider,
    );
    final now = DateTime.now();
    return ConfigProfile(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      sections: ConfigProfileSections(
        deviceConfig: deviceSections.deviceConfig,
        channels: deviceSections.channels,
        appSettings: appSettings,
        mapWorkspace: mapWorkspace,
      ),
    );
  }

  Future<ConfigProfile> createProfileFromCurrent({
    required String name,
    String? notes,
  }) async {
    final profileId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final profile = await snapshotCurrentProfile(
      id: profileId,
      name: name,
      notes: notes,
    );
    await _initializeEmptyStorageNamespace(profileId);
    await profileManager.upsertProfile(profile);
    return profile;
  }

  Future<ConfigProfile> duplicateProfile(ConfigProfile source) async {
    final duplicate = await snapshotCurrentProfile(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      name: '${source.name} Copy',
      notes: source.notes,
    );
    final sourceNamespace = source.id == ConfigProfile.defaultProfileId
        ? null
        : source.id;
    await _copyStorageNamespace(sourceNamespace, duplicate.id);
    await profileManager.upsertProfile(
      duplicate.copyWith(
        sections: source.id == profileManager.activeProfileId
            ? duplicate.sections
            : source.sections,
      ),
    );
    return duplicate;
  }

  Future<void> renameProfile(ConfigProfile profile, String name) async {
    await profileManager.upsertProfile(
      profile.copyWith(name: name, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteProfile(ConfigProfile profile) async {
    if (profile.isDefault) return;
    if (profile.id == profileManager.activeProfileId) {
      await openProfile(ConfigProfile.defaultProfileId);
    }
    await _messageStorageService.clearMessages(namespace: profile.id);
    await _contactStorageService.clearContacts(namespace: profile.id);
    await _contactStorageService.clearContactGroups(namespace: profile.id);
    await _contactStorageService.clearPendingAdverts(namespace: profile.id);
    await profileManager.deleteProfile(profile.id);
  }

  Future<void> openProfile(String profileId) async {
    await _saveActiveCustomProfileSnapshot();
    await connectionProvider.disconnect();
    await profileManager.setActiveProfileId(profileId);
    await _switchRuntimeScope(profileId);

    final profile = await resolveProfile(profileId);
    await _appConfigSnapshotService.apply(
      profile.sections.appSettings,
      appProvider,
    );
    await _mapWorkspaceSnapshotService.apply(
      profile.sections.mapWorkspace,
      mapProvider: mapProvider,
      drawingProvider: drawingProvider,
    );
  }

  Future<void> applyProfile(String profileId) async {
    await openProfile(profileId);
    final profile = await resolveProfile(profileId);
    await _deviceConfigApplicator.apply(
      profile,
      connectionProvider: connectionProvider,
      channelsProvider: channelsProvider,
    );
  }

  Future<ConfigProfile> resolveProfile(String profileId) async {
    if (profileId == ConfigProfile.defaultProfileId) {
      return snapshotCurrentProfile(id: profileId, name: 'Default');
    }
    return profileManager.getProfile(profileId) ??
        await snapshotCurrentProfile(id: profileId, name: 'Unknown');
  }

  Future<void> exportProfile(ConfigProfile profile) async {
    final resolved = profile.id == ConfigProfile.defaultProfileId
        ? await snapshotCurrentProfile(id: profile.id, name: profile.name)
        : profile;
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/${resolved.name.replaceAll(' ', '_').toLowerCase()}_${resolved.id}.meshcore_profile.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(resolved.toJson()),
    );
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    await profileManager.recordTransfer(
      ProfileTransferRecord(
        profileId: resolved.id,
        direction: 'export',
        timestamp: DateTime.now(),
        detail: 'Shared as file',
      ),
    );
  }

  Future<ConfigProfile?> importProfileFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.first;
    if (file.bytes == null) return null;

    final decoded = jsonDecode(utf8.decode(file.bytes!));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final imported = ConfigProfile.fromJson(decoded).copyWith(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      updatedAt: DateTime.now(),
    );
    await profileManager.upsertProfile(imported);
    await profileManager.recordTransfer(
      ProfileTransferRecord(
        profileId: imported.id,
        direction: 'import',
        timestamp: DateTime.now(),
        detail: file.name,
      ),
    );
    return imported;
  }

  Future<void> _switchRuntimeScope(String profileId) async {
    final runtimeProfilesEnabled = profileManager.profilesEnabled;
    ProfileStorageScope.setScope(
      profilesEnabled: runtimeProfilesEnabled,
      activeProfileId: profileId,
    );
    await messagesProvider.reloadFromStorage(
      namespace: ProfileStorageScope.effectiveNamespace,
    );
    await contactsProvider.reloadFromStorage(
      namespace: ProfileStorageScope.effectiveNamespace,
      devicePublicKey: connectionProvider.deviceInfo.publicKey,
    );
    await sensorsProvider.reloadProfileScopedState();
    await drawingProvider.reloadProfileScopedState();
    await mapProvider.reloadProfileScopedState();
    await appProvider.reloadProfileScopedSettings();
  }

  Future<void> _persistCurrentState() async {
    await messagesProvider.persistNow();
    await contactsProvider.persistNow();
  }

  Future<void> _saveActiveCustomProfileSnapshot() async {
    if (profileManager.activeProfileId == ConfigProfile.defaultProfileId) {
      await _persistCurrentState();
      return;
    }
    final current = profileManager.getProfile(profileManager.activeProfileId);
    if (current == null) {
      await _persistCurrentState();
      return;
    }
    final snapshot = await snapshotCurrentProfile(
      id: current.id,
      name: current.name,
      notes: current.notes,
    );
    await profileManager.upsertProfile(snapshot);
    await _persistCurrentState();
  }

  Future<void> _copyStorageNamespace(
    String? sourceNamespace,
    String targetNamespace,
  ) async {
    final messages = await _messageStorageService.loadMessages(
      namespace: sourceNamespace,
    );
    final contactLocations = await _messageStorageService
        .loadMessageContactLocations(namespace: sourceNamespace);
    final receptionDetails = await _messageStorageService
        .loadMessageReceptionDetails(namespace: sourceNamespace);
    final transferDetails = await _messageStorageService
        .loadMessageTransferDetails(namespace: sourceNamespace);
    final routeMetadata = await _messageStorageService.loadMessageRouteMetadata(
      namespace: sourceNamespace,
    );
    final removedIds = await _messageStorageService.loadRemovedSarMarkerIds(
      namespace: sourceNamespace,
    );
    await _messageStorageService.saveMessages(
      messages,
      messageContactLocations: contactLocations,
      messageReceptionDetails: receptionDetails,
      messageTransferDetails: transferDetails,
      messageRouteMetadata: routeMetadata,
      namespace: targetNamespace,
    );
    await _messageStorageService.saveRemovedSarMarkerIds(
      removedIds,
      namespace: targetNamespace,
    );

    final contacts = await _contactStorageService.loadContacts(
      namespace: sourceNamespace,
    );
    final groups = await _contactStorageService.loadContactGroups(
      namespace: sourceNamespace,
    );
    final pending = await _contactStorageService.loadPendingAdverts(
      namespace: sourceNamespace,
    );
    await _contactStorageService.saveContacts(
      contacts,
      namespace: targetNamespace,
    );
    await _contactStorageService.saveContactGroups(
      groups,
      namespace: targetNamespace,
    );
    await _contactStorageService.savePendingAdverts(
      pending,
      namespace: targetNamespace,
    );
  }

  Future<void> _initializeEmptyStorageNamespace(String namespace) async {
    await _messageStorageService.clearMessages(namespace: namespace);
    await _contactStorageService.clearContacts(namespace: namespace);
    await _contactStorageService.clearContactGroups(namespace: namespace);
    await _contactStorageService.clearPendingAdverts(namespace: namespace);
  }
}
