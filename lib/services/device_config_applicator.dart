import 'dart:typed_data';

import '../models/channel.dart';
import '../models/config_profile.dart';
import '../providers/channels_provider.dart';
import '../providers/connection_provider.dart';

class DeviceConfigApplicator {
  ConfigProfileSections capture({
    required ConnectionProvider connectionProvider,
    required ChannelsProvider channelsProvider,
  }) {
    final deviceInfo = connectionProvider.deviceInfo;
    return ConfigProfileSections(
      deviceConfig: DeviceConfigProfileSection(
        frequencyKhz: deviceInfo.radioFreq,
        bandwidth: deviceInfo.radioBw,
        spreadingFactor: deviceInfo.radioSf,
        codingRate: deviceInfo.radioCr,
        repeatEnabled: deviceInfo.clientRepeat,
        txPower: deviceInfo.txPower,
        telemetryModes: deviceInfo.telemetryModes,
        advertLocationPolicy: deviceInfo.advertLocPolicy,
        multiAcks: deviceInfo.multiAcks,
        manualAddContacts: deviceInfo.manualAddContacts,
        autoAddUsers: deviceInfo.autoAddUsers,
        autoAddRepeaters: deviceInfo.autoAddRepeaters,
        autoAddRoomServers: deviceInfo.autoAddRoomServers,
        autoAddSensors: deviceInfo.autoAddSensors,
        autoAddOverwriteOldest: deviceInfo.autoAddOverwriteOldest,
        publicLatitude: _decodeAdvertCoordinate(deviceInfo.advLat),
        publicLongitude: _decodeAdvertCoordinate(deviceInfo.advLon),
      ),
      channels: channelsProvider.channels,
    );
  }

  Future<void> apply(
    ConfigProfile profile, {
    required ConnectionProvider connectionProvider,
    required ChannelsProvider channelsProvider,
  }) async {
    if (!connectionProvider.deviceInfo.isConnected) {
      return;
    }

    final deviceConfig = profile.sections.deviceConfig;
    if (deviceConfig != null && !deviceConfig.isEmpty) {
      if (deviceConfig.txPower != null) {
        await connectionProvider.setTxPower(deviceConfig.txPower!);
      }
      if (deviceConfig.telemetryModes != null ||
          deviceConfig.advertLocationPolicy != null ||
          deviceConfig.manualAddContacts != null ||
          deviceConfig.multiAcks != null) {
        await connectionProvider.setOtherParams(
          manualAddContacts: (deviceConfig.manualAddContacts ?? false) ? 1 : 0,
          telemetryModes: deviceConfig.telemetryModes ?? 0,
          advertLocationPolicy: deviceConfig.advertLocationPolicy ?? 0,
          multiAcks: deviceConfig.multiAcks ?? 0,
        );
      }
      if (deviceConfig.autoAddUsers != null &&
          deviceConfig.autoAddRepeaters != null &&
          deviceConfig.autoAddRoomServers != null &&
          deviceConfig.autoAddSensors != null &&
          deviceConfig.autoAddOverwriteOldest != null) {
        await connectionProvider.setAutoaddConfig(
          autoAddUsers: deviceConfig.autoAddUsers!,
          autoAddRepeaters: deviceConfig.autoAddRepeaters!,
          autoAddRoomServers: deviceConfig.autoAddRoomServers!,
          autoAddSensors: deviceConfig.autoAddSensors!,
          overwriteOldest: deviceConfig.autoAddOverwriteOldest!,
        );
      }
      if (deviceConfig.publicLatitude != null &&
          deviceConfig.publicLongitude != null) {
        await connectionProvider.setAdvertLatLon(
          latitude: deviceConfig.publicLatitude!,
          longitude: deviceConfig.publicLongitude!,
        );
      }
      if (deviceConfig.frequencyKhz != null &&
          deviceConfig.bandwidth != null &&
          deviceConfig.spreadingFactor != null &&
          deviceConfig.codingRate != null) {
        await connectionProvider.setRadioParams(
          frequency: deviceConfig.frequencyKhz!,
          bandwidth: deviceConfig.bandwidth!,
          spreadingFactor: deviceConfig.spreadingFactor!,
          codingRate: deviceConfig.codingRate!,
          repeat: deviceConfig.repeatEnabled,
        );
      }
    }

    await _applyChannels(
      channels: profile.sections.channels,
      connectionProvider: connectionProvider,
      channelsProvider: channelsProvider,
    );
    await connectionProvider.refreshDeviceInfo();
  }

  Future<void> _applyChannels({
    required List<Channel> channels,
    required ConnectionProvider connectionProvider,
    required ChannelsProvider channelsProvider,
  }) async {
    if (channels.isEmpty) {
      return;
    }

    final desired = {for (final channel in channels) channel.index: channel};

    for (final channel in channels) {
      await connectionProvider.setChannelSlot(
        channelIdx: channel.index,
        channelName: channel.name,
        secret: Uint8List.fromList(channel.secret),
      );
      channelsProvider.addOrUpdateChannelObject(channel);
    }

    for (final existing in channelsProvider.channels) {
      if (existing.index == 0 || desired.containsKey(existing.index)) {
        continue;
      }
      await connectionProvider.deleteChannel(existing.index);
      channelsProvider.removeChannel(existing.index);
    }
  }

  double? _decodeAdvertCoordinate(int? value) {
    if (value == null || value == 0) {
      return null;
    }
    return value / 1e6;
  }
}
