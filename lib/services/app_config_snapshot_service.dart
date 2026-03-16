import 'package:shared_preferences/shared_preferences.dart';

import '../models/config_profile.dart';
import '../providers/app_provider.dart';
import 'image_preferences.dart';
import 'profiles_feature_service.dart';
import 'route_hash_preferences.dart';
import 'voice_bitrate_preferences.dart';

class AppConfigSnapshotService {
  Future<AppSettingsProfileSection> capture(AppProvider appProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final locationTracking = appProvider.locationTrackingService;
    return AppSettingsProfileSection(
      mapEnabled: appProvider.isMapEnabled,
      contactsEnabled: appProvider.isContactsEnabled,
      sensorsEnabled: appProvider.isSensorsEnabled,
      voiceSilenceTrimmingEnabled: appProvider.isVoiceSilenceTrimmingEnabled,
      voiceBandPassFilterEnabled: appProvider.isVoiceBandPassFilterEnabled,
      voiceCompressorEnabled: appProvider.isVoiceCompressorEnabled,
      voiceLimiterEnabled: appProvider.isVoiceLimiterEnabled,
      voiceAutoGainEnabled: appProvider.isVoiceAutoGainEnabled,
      voiceEchoCancellationEnabled: appProvider.isVoiceEchoCancellationEnabled,
      voiceNoiseSuppressionEnabled: appProvider.isVoiceNoiseSuppressionEnabled,
      messageFontScale: appProvider.messageFontScale,
      autoRouteRotationEnabled: appProvider.autoRouteRotationEnabled,
      clearPathOnMaxRetry: appProvider.clearPathOnMaxRetry,
      nearestRelayFallbackEnabled: appProvider.nearestRelayFallbackEnabled,
      voiceBitrate: await VoiceBitratePreferences.getBitrate(),
      routeHashSize: await RouteHashPreferences.getHashSize(),
      imageMaxSize: await ImagePreferences.getMaxSize(),
      imageCompression: await ImagePreferences.getCompression(),
      imageGrayscale: await ImagePreferences.getGrayscale(),
      imageUltraMode: await ImagePreferences.getUltraMode(),
      showRxTxIndicators:
          prefs.getBool(
            ProfileStorageScope.scopedKey('show_rx_tx_indicators'),
          ) ??
          true,
      fastLocationUpdatesEnabled: locationTracking.fastLocationUpdatesEnabled,
      fastLocationMovementThresholdMeters:
          locationTracking.fastLocationMovementThresholdMeters,
      fastLocationActiveCadenceSeconds:
          locationTracking.fastLocationActiveCadenceSeconds,
    );
  }

  Future<void> apply(
    AppSettingsProfileSection? section,
    AppProvider appProvider,
  ) async {
    if (section == null || section.isEmpty) {
      return;
    }

    if (section.mapEnabled != null) {
      await appProvider.toggleMapEnabled(section.mapEnabled!);
    }
    if (section.contactsEnabled != null) {
      await appProvider.toggleContactsEnabled(section.contactsEnabled!);
    }
    if (section.sensorsEnabled != null) {
      await appProvider.toggleSensorsEnabled(section.sensorsEnabled!);
    }
    if (section.voiceSilenceTrimmingEnabled != null) {
      await appProvider.toggleVoiceSilenceTrimmingEnabled(
        section.voiceSilenceTrimmingEnabled!,
      );
    }
    if (section.voiceBandPassFilterEnabled != null) {
      await appProvider.toggleVoiceBandPassFilterEnabled(
        section.voiceBandPassFilterEnabled!,
      );
    }
    if (section.voiceCompressorEnabled != null) {
      await appProvider.toggleVoiceCompressorEnabled(
        section.voiceCompressorEnabled!,
      );
    }
    if (section.voiceLimiterEnabled != null) {
      await appProvider.toggleVoiceLimiterEnabled(section.voiceLimiterEnabled!);
    }
    if (section.voiceAutoGainEnabled != null) {
      await appProvider.toggleVoiceAutoGainEnabled(
        section.voiceAutoGainEnabled!,
      );
    }
    if (section.voiceEchoCancellationEnabled != null) {
      await appProvider.toggleVoiceEchoCancellationEnabled(
        section.voiceEchoCancellationEnabled!,
      );
    }
    if (section.voiceNoiseSuppressionEnabled != null) {
      await appProvider.toggleVoiceNoiseSuppressionEnabled(
        section.voiceNoiseSuppressionEnabled!,
      );
    }
    if (section.messageFontScale != null) {
      await appProvider.setMessageFontScale(section.messageFontScale!);
    }
    if (section.autoRouteRotationEnabled != null) {
      await appProvider.toggleAutoRouteRotationEnabled(
        section.autoRouteRotationEnabled!,
      );
    }
    if (section.clearPathOnMaxRetry != null) {
      await appProvider.toggleClearPathOnMaxRetry(section.clearPathOnMaxRetry!);
    }
    if (section.nearestRelayFallbackEnabled != null) {
      await appProvider.toggleNearestRelayFallbackEnabled(
        section.nearestRelayFallbackEnabled!,
      );
    }
    if (section.voiceBitrate != null) {
      await VoiceBitratePreferences.setBitrate(section.voiceBitrate!);
    }
    if (section.routeHashSize != null) {
      await RouteHashPreferences.setHashSize(section.routeHashSize!);
    }
    if (section.imageMaxSize != null) {
      await ImagePreferences.setMaxSize(section.imageMaxSize!);
    }
    if (section.imageCompression != null) {
      await ImagePreferences.setCompression(section.imageCompression!);
    }
    if (section.imageGrayscale != null) {
      await ImagePreferences.setGrayscale(section.imageGrayscale!);
    }
    if (section.imageUltraMode != null) {
      await ImagePreferences.setUltraMode(section.imageUltraMode!);
    }
    if (section.showRxTxIndicators != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        ProfileStorageScope.scopedKey('show_rx_tx_indicators'),
        section.showRxTxIndicators!,
      );
    }

    final locationTracking = appProvider.locationTrackingService;
    if (section.fastLocationUpdatesEnabled != null) {
      locationTracking.fastLocationUpdatesEnabled =
          section.fastLocationUpdatesEnabled!;
    }
    if (section.fastLocationMovementThresholdMeters != null) {
      locationTracking.fastLocationMovementThresholdMeters =
          section.fastLocationMovementThresholdMeters!;
    }
    if (section.fastLocationActiveCadenceSeconds != null) {
      locationTracking.fastLocationActiveCadenceSeconds =
          section.fastLocationActiveCadenceSeconds!;
    }
    await locationTracking.saveSettings();
    await appProvider.reloadProfileScopedSettings();
  }
}
