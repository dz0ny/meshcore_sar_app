import 'dart:typed_data';

/// BLE connection state
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Connection mode for app operation
enum ConnectionMode {
  /// Direct BLE connection to MeshCore device (default)
  ble,

  /// Act as SSE server - share BLE device with multiple clients
  sseServer,

  /// Direct TCP/WiFi connection to MeshCore device (port 5000)
  tcp,
}

extension ConnectionModeExtension on ConnectionMode {
  String get displayName {
    switch (this) {
      case ConnectionMode.ble:
        return 'Direct (BLE)';
      case ConnectionMode.sseServer:
        return 'Share Device (Server)';
      case ConnectionMode.tcp:
        return 'Direct (WiFi)';
    }
  }

  String get description {
    switch (this) {
      case ConnectionMode.ble:
        return 'Direct BLE connection to MeshCore device';
      case ConnectionMode.sseServer:
        return 'Share BLE device with multiple clients over network';
      case ConnectionMode.tcp:
        return 'Direct WiFi/TCP connection to MeshCore device';
    }
  }
}

/// MeshCore device information
class DeviceInfo {
  final String? deviceId;
  final String? deviceName;
  final ConnectionState connectionState;
  final int? batteryMilliVolts;
  final double? batteryPercentage;
  final int? storageUsedKb;
  final int? storageTotalKb;
  final int? signalRssi;
  final double? signalSnr;
  final DateTime? lastUpdate;

  // Self info from MeshCore device
  final int? deviceType;
  final int? txPower;
  final int? maxTxPower;
  final Uint8List? publicKey;
  final int? advLat;
  final int? advLon;
  final bool? manualAddContacts;
  final int? radioFreq;
  final int? radioBw;
  final int? radioSf;
  final int? radioCr;
  final String? selfName;

  // Additional device capabilities (from RESP_CODE_DEVICE_INFO)
  final int? maxContacts;        // Max contacts device supports
  final int? maxChannels;        // Max channels device supports
  final int? telemetryModes;     // Telemetry permission modes (bits 0-1: Base, bits 2-3: Location)
  final int? blePin;             // BLE PIN code
  final int? multiAcks;          // Extra ACK mode (0=no, 1=yes)
  final int? advertLocPolicy;    // Location sharing policy (0=don't share, 1=share)

  // Firmware info
  final int? firmwareVersion;
  final String? firmwareBuildDate;
  final String? manufacturerModel;
  final String? semanticVersion;

  // Repeat mode (firmware v9+)
  final bool? clientRepeat;
  final List<({int lower, int upper})>? allowedRepeatFreqRanges;

  DeviceInfo({
    this.deviceId,
    this.deviceName,
    this.connectionState = ConnectionState.disconnected,
    this.batteryMilliVolts,
    this.batteryPercentage,
    this.storageUsedKb,
    this.storageTotalKb,
    this.signalRssi,
    this.signalSnr,
    this.lastUpdate,
    this.deviceType,
    this.txPower,
    this.maxTxPower,
    this.publicKey,
    this.advLat,
    this.advLon,
    this.manualAddContacts,
    this.radioFreq,
    this.radioBw,
    this.radioSf,
    this.radioCr,
    this.selfName,
    this.maxContacts,
    this.maxChannels,
    this.telemetryModes,
    this.blePin,
    this.multiAcks,
    this.advertLocPolicy,
    this.firmwareVersion,
    this.firmwareBuildDate,
    this.manufacturerModel,
    this.semanticVersion,
    this.clientRepeat,
    this.allowedRepeatFreqRanges,
  });

  /// Check if device is connected
  bool get isConnected => connectionState == ConnectionState.connected;

  /// Check if device is connecting
  bool get isConnecting => connectionState == ConnectionState.connecting;

  /// Check if device has error
  bool get hasError => connectionState == ConnectionState.error;

  /// Get battery percentage (calculated or provided)
  double? get batteryPercent {
    if (batteryPercentage != null) return batteryPercentage!;
    if (batteryMilliVolts == null) return null;

    // Rough conversion from mV to percentage (3.0V = 0%, 4.2V = 100%)
    final voltage = batteryMilliVolts! / 1000.0;
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  /// Get battery status
  String get batteryStatus {
    final percent = batteryPercent;
    if (percent == null) return 'Unknown';
    if (percent > 80) return 'Excellent';
    if (percent > 50) return 'Good';
    if (percent > 20) return 'Low';
    return 'Critical';
  }

  /// Get storage usage percentage (0-100)
  double? get storageUsedPercent {
    if (storageUsedKb == null || storageTotalKb == null || storageTotalKb == 0) {
      return null;
    }
    return (storageUsedKb! / storageTotalKb!) * 100.0;
  }

  /// Get storage available in KB
  int? get storageAvailableKb {
    if (storageUsedKb == null || storageTotalKb == null) {
      return null;
    }
    return storageTotalKb! - storageUsedKb!;
  }

  /// Get human-readable storage status
  String get storageStatus {
    final percent = storageUsedPercent;
    if (percent == null) return 'Unknown';
    if (percent < 50) return 'Plenty Available';
    if (percent < 80) return 'Moderate Usage';
    if (percent < 95) return 'Low Space';
    return 'Critical - Nearly Full';
  }

  /// Get signal strength category
  String get signalStrength {
    if (signalRssi == null) return 'Unknown';
    if (signalRssi! > -60) return 'Excellent';
    if (signalRssi! > -70) return 'Good';
    if (signalRssi! > -80) return 'Fair';
    return 'Poor';
  }

  /// Get public key as hex string (short)
  String? get publicKeyShort {
    if (publicKey == null || publicKey!.length < 8) return null;
    return publicKey!
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// Get display name with "MeshCore-" prefix removed
  String? get displayName {
    if (deviceName == null) return null;
    if (deviceName!.startsWith('MeshCore-')) {
      return deviceName!.substring(9); // Remove "MeshCore-" (9 characters)
    }
    return deviceName;
  }

  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    ConnectionState? connectionState,
    int? batteryMilliVolts,
    double? batteryPercentage,
    int? storageUsedKb,
    int? storageTotalKb,
    int? signalRssi,
    double? signalSnr,
    DateTime? lastUpdate,
    int? deviceType,
    int? txPower,
    int? maxTxPower,
    Uint8List? publicKey,
    int? advLat,
    int? advLon,
    bool? manualAddContacts,
    int? radioFreq,
    int? radioBw,
    int? radioSf,
    int? radioCr,
    String? selfName,
    int? maxContacts,
    int? maxChannels,
    int? telemetryModes,
    int? blePin,
    int? multiAcks,
    int? advertLocPolicy,
    int? firmwareVersion,
    String? firmwareBuildDate,
    String? manufacturerModel,
    String? semanticVersion,
    bool? clientRepeat,
    List<({int lower, int upper})>? allowedRepeatFreqRanges,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      connectionState: connectionState ?? this.connectionState,
      batteryMilliVolts: batteryMilliVolts ?? this.batteryMilliVolts,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      storageUsedKb: storageUsedKb ?? this.storageUsedKb,
      storageTotalKb: storageTotalKb ?? this.storageTotalKb,
      signalRssi: signalRssi ?? this.signalRssi,
      signalSnr: signalSnr ?? this.signalSnr,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      deviceType: deviceType ?? this.deviceType,
      txPower: txPower ?? this.txPower,
      maxTxPower: maxTxPower ?? this.maxTxPower,
      publicKey: publicKey ?? this.publicKey,
      advLat: advLat ?? this.advLat,
      advLon: advLon ?? this.advLon,
      manualAddContacts: manualAddContacts ?? this.manualAddContacts,
      radioFreq: radioFreq ?? this.radioFreq,
      radioBw: radioBw ?? this.radioBw,
      radioSf: radioSf ?? this.radioSf,
      radioCr: radioCr ?? this.radioCr,
      selfName: selfName ?? this.selfName,
      maxContacts: maxContacts ?? this.maxContacts,
      maxChannels: maxChannels ?? this.maxChannels,
      telemetryModes: telemetryModes ?? this.telemetryModes,
      blePin: blePin ?? this.blePin,
      multiAcks: multiAcks ?? this.multiAcks,
      advertLocPolicy: advertLocPolicy ?? this.advertLocPolicy,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareBuildDate: firmwareBuildDate ?? this.firmwareBuildDate,
      manufacturerModel: manufacturerModel ?? this.manufacturerModel,
      semanticVersion: semanticVersion ?? this.semanticVersion,
      clientRepeat: clientRepeat ?? this.clientRepeat,
      allowedRepeatFreqRanges: allowedRepeatFreqRanges ?? this.allowedRepeatFreqRanges,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(name: $deviceName, state: $connectionState, battery: ${batteryPercent?.toStringAsFixed(0)}%, signal: $signalRssi dBm)';
  }
}
