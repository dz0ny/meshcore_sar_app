import 'package:flutter/foundation.dart';
import 'channel.dart';

@immutable
class DeviceConfigProfileSection {
  final int? frequencyKhz;
  final int? bandwidth;
  final int? spreadingFactor;
  final int? codingRate;
  final bool? repeatEnabled;
  final int? txPower;
  final int? telemetryModes;
  final int? advertLocationPolicy;
  final int? multiAcks;
  final bool? manualAddContacts;
  final bool? autoAddUsers;
  final bool? autoAddRepeaters;
  final bool? autoAddRoomServers;
  final bool? autoAddSensors;
  final bool? autoAddOverwriteOldest;
  final double? publicLatitude;
  final double? publicLongitude;

  const DeviceConfigProfileSection({
    this.frequencyKhz,
    this.bandwidth,
    this.spreadingFactor,
    this.codingRate,
    this.repeatEnabled,
    this.txPower,
    this.telemetryModes,
    this.advertLocationPolicy,
    this.multiAcks,
    this.manualAddContacts,
    this.autoAddUsers,
    this.autoAddRepeaters,
    this.autoAddRoomServers,
    this.autoAddSensors,
    this.autoAddOverwriteOldest,
    this.publicLatitude,
    this.publicLongitude,
  });

  bool get isEmpty =>
      frequencyKhz == null &&
      bandwidth == null &&
      spreadingFactor == null &&
      codingRate == null &&
      repeatEnabled == null &&
      txPower == null &&
      telemetryModes == null &&
      advertLocationPolicy == null &&
      multiAcks == null &&
      manualAddContacts == null &&
      autoAddUsers == null &&
      autoAddRepeaters == null &&
      autoAddRoomServers == null &&
      autoAddSensors == null &&
      autoAddOverwriteOldest == null &&
      publicLatitude == null &&
      publicLongitude == null;

  Map<String, dynamic> toJson() => {
    'frequencyKhz': frequencyKhz,
    'bandwidth': bandwidth,
    'spreadingFactor': spreadingFactor,
    'codingRate': codingRate,
    'repeatEnabled': repeatEnabled,
    'txPower': txPower,
    'telemetryModes': telemetryModes,
    'advertLocationPolicy': advertLocationPolicy,
    'multiAcks': multiAcks,
    'manualAddContacts': manualAddContacts,
    'autoAddUsers': autoAddUsers,
    'autoAddRepeaters': autoAddRepeaters,
    'autoAddRoomServers': autoAddRoomServers,
    'autoAddSensors': autoAddSensors,
    'autoAddOverwriteOldest': autoAddOverwriteOldest,
    'publicLatitude': publicLatitude,
    'publicLongitude': publicLongitude,
  };

  factory DeviceConfigProfileSection.fromJson(Map<String, dynamic> json) {
    return DeviceConfigProfileSection(
      frequencyKhz: json['frequencyKhz'] as int?,
      bandwidth: json['bandwidth'] as int?,
      spreadingFactor: json['spreadingFactor'] as int?,
      codingRate: json['codingRate'] as int?,
      repeatEnabled: json['repeatEnabled'] as bool?,
      txPower: json['txPower'] as int?,
      telemetryModes: json['telemetryModes'] as int?,
      advertLocationPolicy: json['advertLocationPolicy'] as int?,
      multiAcks: json['multiAcks'] as int?,
      manualAddContacts: json['manualAddContacts'] as bool?,
      autoAddUsers: json['autoAddUsers'] as bool?,
      autoAddRepeaters: json['autoAddRepeaters'] as bool?,
      autoAddRoomServers: json['autoAddRoomServers'] as bool?,
      autoAddSensors: json['autoAddSensors'] as bool?,
      autoAddOverwriteOldest: json['autoAddOverwriteOldest'] as bool?,
      publicLatitude: (json['publicLatitude'] as num?)?.toDouble(),
      publicLongitude: (json['publicLongitude'] as num?)?.toDouble(),
    );
  }
}

@immutable
class AppSettingsProfileSection {
  final bool? mapEnabled;
  final bool? contactsEnabled;
  final bool? sensorsEnabled;
  final bool? voiceSilenceTrimmingEnabled;
  final bool? voiceBandPassFilterEnabled;
  final bool? voiceCompressorEnabled;
  final bool? voiceLimiterEnabled;
  final bool? voiceAutoGainEnabled;
  final bool? voiceEchoCancellationEnabled;
  final bool? voiceNoiseSuppressionEnabled;
  final double? messageFontScale;
  final bool? autoRouteRotationEnabled;
  final bool? clearPathOnMaxRetry;
  final bool? nearestRelayFallbackEnabled;
  final int? voiceBitrate;
  final int? routeHashSize;
  final int? imageMaxSize;
  final int? imageCompression;
  final bool? imageGrayscale;
  final bool? imageUltraMode;
  final bool? showRxTxIndicators;
  final bool? fastLocationUpdatesEnabled;
  final double? fastLocationMovementThresholdMeters;
  final int? fastLocationActiveCadenceSeconds;

  const AppSettingsProfileSection({
    this.mapEnabled,
    this.contactsEnabled,
    this.sensorsEnabled,
    this.voiceSilenceTrimmingEnabled,
    this.voiceBandPassFilterEnabled,
    this.voiceCompressorEnabled,
    this.voiceLimiterEnabled,
    this.voiceAutoGainEnabled,
    this.voiceEchoCancellationEnabled,
    this.voiceNoiseSuppressionEnabled,
    this.messageFontScale,
    this.autoRouteRotationEnabled,
    this.clearPathOnMaxRetry,
    this.nearestRelayFallbackEnabled,
    this.voiceBitrate,
    this.routeHashSize,
    this.imageMaxSize,
    this.imageCompression,
    this.imageGrayscale,
    this.imageUltraMode,
    this.showRxTxIndicators,
    this.fastLocationUpdatesEnabled,
    this.fastLocationMovementThresholdMeters,
    this.fastLocationActiveCadenceSeconds,
  });

  bool get isEmpty =>
      mapEnabled == null &&
      contactsEnabled == null &&
      sensorsEnabled == null &&
      voiceSilenceTrimmingEnabled == null &&
      voiceBandPassFilterEnabled == null &&
      voiceCompressorEnabled == null &&
      voiceLimiterEnabled == null &&
      voiceAutoGainEnabled == null &&
      voiceEchoCancellationEnabled == null &&
      voiceNoiseSuppressionEnabled == null &&
      messageFontScale == null &&
      autoRouteRotationEnabled == null &&
      clearPathOnMaxRetry == null &&
      nearestRelayFallbackEnabled == null &&
      voiceBitrate == null &&
      routeHashSize == null &&
      imageMaxSize == null &&
      imageCompression == null &&
      imageGrayscale == null &&
      imageUltraMode == null &&
      showRxTxIndicators == null &&
      fastLocationUpdatesEnabled == null &&
      fastLocationMovementThresholdMeters == null &&
      fastLocationActiveCadenceSeconds == null;

  Map<String, dynamic> toJson() => {
    'mapEnabled': mapEnabled,
    'contactsEnabled': contactsEnabled,
    'sensorsEnabled': sensorsEnabled,
    'voiceSilenceTrimmingEnabled': voiceSilenceTrimmingEnabled,
    'voiceBandPassFilterEnabled': voiceBandPassFilterEnabled,
    'voiceCompressorEnabled': voiceCompressorEnabled,
    'voiceLimiterEnabled': voiceLimiterEnabled,
    'voiceAutoGainEnabled': voiceAutoGainEnabled,
    'voiceEchoCancellationEnabled': voiceEchoCancellationEnabled,
    'voiceNoiseSuppressionEnabled': voiceNoiseSuppressionEnabled,
    'messageFontScale': messageFontScale,
    'autoRouteRotationEnabled': autoRouteRotationEnabled,
    'clearPathOnMaxRetry': clearPathOnMaxRetry,
    'nearestRelayFallbackEnabled': nearestRelayFallbackEnabled,
    'voiceBitrate': voiceBitrate,
    'routeHashSize': routeHashSize,
    'imageMaxSize': imageMaxSize,
    'imageCompression': imageCompression,
    'imageGrayscale': imageGrayscale,
    'imageUltraMode': imageUltraMode,
    'showRxTxIndicators': showRxTxIndicators,
    'fastLocationUpdatesEnabled': fastLocationUpdatesEnabled,
    'fastLocationMovementThresholdMeters': fastLocationMovementThresholdMeters,
    'fastLocationActiveCadenceSeconds': fastLocationActiveCadenceSeconds,
  };

  factory AppSettingsProfileSection.fromJson(Map<String, dynamic> json) {
    return AppSettingsProfileSection(
      mapEnabled: json['mapEnabled'] as bool?,
      contactsEnabled: json['contactsEnabled'] as bool?,
      sensorsEnabled: json['sensorsEnabled'] as bool?,
      voiceSilenceTrimmingEnabled: json['voiceSilenceTrimmingEnabled'] as bool?,
      voiceBandPassFilterEnabled: json['voiceBandPassFilterEnabled'] as bool?,
      voiceCompressorEnabled: json['voiceCompressorEnabled'] as bool?,
      voiceLimiterEnabled: json['voiceLimiterEnabled'] as bool?,
      voiceAutoGainEnabled: json['voiceAutoGainEnabled'] as bool?,
      voiceEchoCancellationEnabled:
          json['voiceEchoCancellationEnabled'] as bool?,
      voiceNoiseSuppressionEnabled:
          json['voiceNoiseSuppressionEnabled'] as bool?,
      messageFontScale: (json['messageFontScale'] as num?)?.toDouble(),
      autoRouteRotationEnabled: json['autoRouteRotationEnabled'] as bool?,
      clearPathOnMaxRetry: json['clearPathOnMaxRetry'] as bool?,
      nearestRelayFallbackEnabled: json['nearestRelayFallbackEnabled'] as bool?,
      voiceBitrate: json['voiceBitrate'] as int?,
      routeHashSize: json['routeHashSize'] as int?,
      imageMaxSize: json['imageMaxSize'] as int?,
      imageCompression: json['imageCompression'] as int?,
      imageGrayscale: json['imageGrayscale'] as bool?,
      imageUltraMode: json['imageUltraMode'] as bool?,
      showRxTxIndicators: json['showRxTxIndicators'] as bool?,
      fastLocationUpdatesEnabled: json['fastLocationUpdatesEnabled'] as bool?,
      fastLocationMovementThresholdMeters:
          (json['fastLocationMovementThresholdMeters'] as num?)?.toDouble(),
      fastLocationActiveCadenceSeconds:
          json['fastLocationActiveCadenceSeconds'] as int?,
    );
  }
}

@immutable
class MapWorkspaceProfileSection {
  final Map<String, dynamic>? mapPrefs;
  final List<Map<String, dynamic>> drawings;
  final Map<String, dynamic>? currentTrail;
  final List<Map<String, dynamic>> trailHistory;
  final Map<String, dynamic>? importedTrail;
  final bool? isTrailVisible;
  final bool? showCadastralOverlay;
  final bool? showForestRoadsOverlay;
  final bool? showHikingTrailsOverlay;
  final bool? showMainRoadsOverlay;
  final bool? showHouseNumbersOverlay;
  final bool? showFireHazardZonesOverlay;
  final bool? showHistoricalFiresOverlay;
  final bool? showFirebreaksOverlay;
  final bool? showKrasFireZonesOverlay;
  final bool? showPlaceNamesOverlay;
  final bool? showMunicipalityBordersOverlay;
  final bool? showAllContactTrails;
  final bool? hideRepeatersOnMap;

  const MapWorkspaceProfileSection({
    this.mapPrefs,
    this.drawings = const [],
    this.currentTrail,
    this.trailHistory = const [],
    this.importedTrail,
    this.isTrailVisible,
    this.showCadastralOverlay,
    this.showForestRoadsOverlay,
    this.showHikingTrailsOverlay,
    this.showMainRoadsOverlay,
    this.showHouseNumbersOverlay,
    this.showFireHazardZonesOverlay,
    this.showHistoricalFiresOverlay,
    this.showFirebreaksOverlay,
    this.showKrasFireZonesOverlay,
    this.showPlaceNamesOverlay,
    this.showMunicipalityBordersOverlay,
    this.showAllContactTrails,
    this.hideRepeatersOnMap,
  });

  bool get isEmpty =>
      mapPrefs == null &&
      drawings.isEmpty &&
      currentTrail == null &&
      trailHistory.isEmpty &&
      importedTrail == null &&
      isTrailVisible == null &&
      showCadastralOverlay == null &&
      showForestRoadsOverlay == null &&
      showHikingTrailsOverlay == null &&
      showMainRoadsOverlay == null &&
      showHouseNumbersOverlay == null &&
      showFireHazardZonesOverlay == null &&
      showHistoricalFiresOverlay == null &&
      showFirebreaksOverlay == null &&
      showKrasFireZonesOverlay == null &&
      showPlaceNamesOverlay == null &&
      showMunicipalityBordersOverlay == null &&
      showAllContactTrails == null &&
      hideRepeatersOnMap == null;

  Map<String, dynamic> toJson() => {
    'mapPrefs': mapPrefs,
    'drawings': drawings,
    'currentTrail': currentTrail,
    'trailHistory': trailHistory,
    'importedTrail': importedTrail,
    'isTrailVisible': isTrailVisible,
    'showCadastralOverlay': showCadastralOverlay,
    'showForestRoadsOverlay': showForestRoadsOverlay,
    'showHikingTrailsOverlay': showHikingTrailsOverlay,
    'showMainRoadsOverlay': showMainRoadsOverlay,
    'showHouseNumbersOverlay': showHouseNumbersOverlay,
    'showFireHazardZonesOverlay': showFireHazardZonesOverlay,
    'showHistoricalFiresOverlay': showHistoricalFiresOverlay,
    'showFirebreaksOverlay': showFirebreaksOverlay,
    'showKrasFireZonesOverlay': showKrasFireZonesOverlay,
    'showPlaceNamesOverlay': showPlaceNamesOverlay,
    'showMunicipalityBordersOverlay': showMunicipalityBordersOverlay,
    'showAllContactTrails': showAllContactTrails,
    'hideRepeatersOnMap': hideRepeatersOnMap,
  };

  factory MapWorkspaceProfileSection.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> decodeList(String key) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.whereType<Map<String, dynamic>>().toList();
    }

    return MapWorkspaceProfileSection(
      mapPrefs: json['mapPrefs'] as Map<String, dynamic>?,
      drawings: decodeList('drawings'),
      currentTrail: json['currentTrail'] as Map<String, dynamic>?,
      trailHistory: decodeList('trailHistory'),
      importedTrail: json['importedTrail'] as Map<String, dynamic>?,
      isTrailVisible: json['isTrailVisible'] as bool?,
      showCadastralOverlay: json['showCadastralOverlay'] as bool?,
      showForestRoadsOverlay: json['showForestRoadsOverlay'] as bool?,
      showHikingTrailsOverlay: json['showHikingTrailsOverlay'] as bool?,
      showMainRoadsOverlay: json['showMainRoadsOverlay'] as bool?,
      showHouseNumbersOverlay: json['showHouseNumbersOverlay'] as bool?,
      showFireHazardZonesOverlay: json['showFireHazardZonesOverlay'] as bool?,
      showHistoricalFiresOverlay: json['showHistoricalFiresOverlay'] as bool?,
      showFirebreaksOverlay: json['showFirebreaksOverlay'] as bool?,
      showKrasFireZonesOverlay: json['showKrasFireZonesOverlay'] as bool?,
      showPlaceNamesOverlay: json['showPlaceNamesOverlay'] as bool?,
      showMunicipalityBordersOverlay:
          json['showMunicipalityBordersOverlay'] as bool?,
      showAllContactTrails: json['showAllContactTrails'] as bool?,
      hideRepeatersOnMap: json['hideRepeatersOnMap'] as bool?,
    );
  }
}

@immutable
class ConfigProfileSections {
  final DeviceConfigProfileSection? deviceConfig;
  final AppSettingsProfileSection? appSettings;
  final MapWorkspaceProfileSection? mapWorkspace;
  final List<Channel> channels;

  const ConfigProfileSections({
    this.deviceConfig,
    this.appSettings,
    this.mapWorkspace,
    this.channels = const [],
  });

  bool get isEmpty =>
      (deviceConfig == null || deviceConfig!.isEmpty) &&
      (appSettings == null || appSettings!.isEmpty) &&
      (mapWorkspace == null || mapWorkspace!.isEmpty) &&
      channels.isEmpty;

  Map<String, dynamic> toJson() => {
    'deviceConfig': deviceConfig?.toJson(),
    'appSettings': appSettings?.toJson(),
    'mapWorkspace': mapWorkspace?.toJson(),
    'channels': channels.map((channel) => channel.toJson()).toList(),
  };

  factory ConfigProfileSections.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channels'] as List<dynamic>? ?? const [];
    return ConfigProfileSections(
      deviceConfig: json['deviceConfig'] is Map<String, dynamic>
          ? DeviceConfigProfileSection.fromJson(
              json['deviceConfig'] as Map<String, dynamic>,
            )
          : null,
      appSettings: json['appSettings'] is Map<String, dynamic>
          ? AppSettingsProfileSection.fromJson(
              json['appSettings'] as Map<String, dynamic>,
            )
          : null,
      mapWorkspace: json['mapWorkspace'] is Map<String, dynamic>
          ? MapWorkspaceProfileSection.fromJson(
              json['mapWorkspace'] as Map<String, dynamic>,
            )
          : null,
      channels: rawChannels
          .whereType<Map<String, dynamic>>()
          .map(Channel.fromJson)
          .toList(),
    );
  }
}

@immutable
class ConfigProfile {
  static const String defaultProfileId = 'default';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final ConfigProfileSections sections;

  const ConfigProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sections,
    this.notes,
  });

  bool get isDefault => id == defaultProfileId;

  factory ConfigProfile.defaultProfile() {
    final now = DateTime.now();
    return ConfigProfile(
      id: defaultProfileId,
      name: 'Default',
      createdAt: now,
      updatedAt: now,
      sections: const ConfigProfileSections(),
    );
  }

  ConfigProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    ConfigProfileSections? sections,
  }) {
    return ConfigProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      sections: sections ?? this.sections,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
    'sections': sections.toJson(),
  };

  factory ConfigProfile.fromJson(Map<String, dynamic> json) {
    return ConfigProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      sections: ConfigProfileSections.fromJson(
        json['sections'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

@immutable
class ProfileDiff {
  final List<String> changedSections;

  const ProfileDiff({required this.changedSections});
}

@immutable
class ProfileTransferRecord {
  final String profileId;
  final String direction;
  final DateTime timestamp;
  final String detail;

  const ProfileTransferRecord({
    required this.profileId,
    required this.direction,
    required this.timestamp,
    required this.detail,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'direction': direction,
    'timestamp': timestamp.toIso8601String(),
    'detail': detail,
  };

  factory ProfileTransferRecord.fromJson(Map<String, dynamic> json) {
    return ProfileTransferRecord(
      profileId: json['profileId'] as String,
      direction: json['direction'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      detail: json['detail'] as String,
    );
  }
}
