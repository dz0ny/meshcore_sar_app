import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:meshcore_client/meshcore_client.dart'
    show BufferReader, MeshCoreConstants;
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';
import 'messages_provider.dart';
import 'drawing_provider.dart';
import 'channels_provider.dart';
import 'voice_provider.dart';
import 'image_provider.dart' as ip;
import 'helpers/fragment_ack_wait_registry.dart';
import 'helpers/session_metadata_restore.dart';
import '../services/location_tracking_service.dart';
import '../services/messaging_route_preferences.dart';
import '../services/nearest_router_selector.dart';
import '../services/packet_capture_storage_service.dart';
import '../services/path_history_service.dart';
import '../utils/rssi_location_estimator.dart';
import '../services/profiles_feature_service.dart';
import '../services/route_hash_preferences.dart';
import '../services/notification_service.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import '../models/path_selection.dart';
import '../models/message_reception_details.dart';
import '../utils/drawing_message_parser.dart';
import '../utils/raw_route_probe.dart';
import '../utils/voice_message_parser.dart';
import '../utils/image_message_parser.dart';
import '../utils/media_swarm_protocol.dart';
import '../utils/message_airtime_estimator.dart';
import '../utils/fast_gps_packet.dart';
import '../utils/log_rx_route_decoder.dart';

class _DirectMessageRouteSession {
  final PathSelection currentSelection;
  final ParsedContactRoute? originalRoute;
  final bool routerFallbackAttempted;

  const _DirectMessageRouteSession({
    required this.currentSelection,
    required this.originalRoute,
    required this.routerFallbackAttempted,
  });

  _DirectMessageRouteSession copyWith({
    PathSelection? currentSelection,
    ParsedContactRoute? originalRoute,
    bool? routerFallbackAttempted,
  }) {
    return _DirectMessageRouteSession(
      currentSelection: currentSelection ?? this.currentSelection,
      originalRoute: originalRoute ?? this.originalRoute,
      routerFallbackAttempted:
          routerFallbackAttempted ?? this.routerFallbackAttempted,
    );
  }
}

class _ParsedRawAdvert {
  final Uint8List publicKey;
  final String? advName;
  final int typeValue;
  final int flags;
  final int lastAdvert;
  final int? advLat;
  final int? advLon;
  final int? signedEncodedPathLen;
  final Uint8List? paddedPathBytes;

  const _ParsedRawAdvert({
    required this.publicKey,
    required this.advName,
    required this.typeValue,
    required this.flags,
    required this.lastAdvert,
    required this.advLat,
    required this.advLon,
    required this.signedEncodedPathLen,
    required this.paddedPathBytes,
  });
}

class _ParsedRepeaterStatus {
  final int batteryMv;
  final int queueLen;
  final int lastRssi;
  final int lastSnrRaw;
  final int uptimeSecs;

  const _ParsedRepeaterStatus({
    required this.batteryMv,
    required this.queueLen,
    required this.lastRssi,
    required this.lastSnrRaw,
    required this.uptimeSecs,
  });
}

class _PendingRepeaterOwnerRequest {
  final Uint8List publicKey;

  const _PendingRepeaterOwnerRequest({required this.publicKey});
}

enum ContactsTabSection {
  favourites,
  teamMembers,
  repeaters,
  sensors,
  rooms,
  channels,
}

/// Main App Provider - coordinates all other providers
class AppProvider with ChangeNotifier {
  static const int _maxDirectPayloadHops = 3;
  static const int _rawPayloadTypeAdvert = 0x04;
  static const int _routeTransportFlood = 0x00;
  static const int _routeTransportDirect = 0x03;
  static const int _anonReqTypeOwner = 0x02;
  static const double _lowBatteryThresholdPercent = 30.0;
  static const double _lowBatteryResetThresholdPercent = 35.0;
  static const Duration _lowBatteryCheckInterval = Duration(minutes: 5);
  static const Duration _repeaterOwnerInfoRequestCooldown = Duration(
    minutes: 10,
  );
  @visibleForTesting
  static bool isDeletedChannelInfo(
    int channelIdx,
    String channelName,
    Uint8List secret,
  ) {
    return channelIdx != 0 &&
        channelName.isEmpty &&
        secret.every((byte) => byte == 0);
  }

  @visibleForTesting
  static String channelContactName(int channelIdx, String channelName) {
    return channelName.isEmpty && channelIdx != 0
        ? 'Channel $channelIdx'
        : channelName;
  }

  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final DrawingProvider drawingProvider;
  final ChannelsProvider channelsProvider;
  final VoiceProvider voiceProvider;
  final ip.ImageProvider imageProvider;
  final LocationTrackingService locationTrackingService =
      LocationTrackingService();
  final PacketCaptureStorageService packetCaptureStorageService =
      PacketCaptureStorageService();
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isSimpleMode => true;

  bool _isMapEnabled = true;
  bool get isMapEnabled => _isMapEnabled;
  bool _isContactsEnabled = true;
  bool get isContactsEnabled => _isContactsEnabled;
  bool _isSensorsEnabled = true;
  bool get isSensorsEnabled => _isSensorsEnabled;
  final Map<ContactsTabSection, bool> _contactsSectionVisibility = {
    for (final section in ContactsTabSection.values) section: true,
  };

  bool _isVoiceSilenceTrimmingEnabled = true;
  bool get isVoiceSilenceTrimmingEnabled => _isVoiceSilenceTrimmingEnabled;
  bool _isVoiceBandPassFilterEnabled = true;
  bool get isVoiceBandPassFilterEnabled => _isVoiceBandPassFilterEnabled;
  bool _isVoiceCompressorEnabled = true;
  bool get isVoiceCompressorEnabled => _isVoiceCompressorEnabled;
  bool _isVoiceLimiterEnabled = true;
  bool get isVoiceLimiterEnabled => _isVoiceLimiterEnabled;
  bool _isVoiceAutoGainEnabled = false;
  bool get isVoiceAutoGainEnabled => _isVoiceAutoGainEnabled;
  bool _isVoiceEchoCancellationEnabled = false;
  bool get isVoiceEchoCancellationEnabled => _isVoiceEchoCancellationEnabled;
  bool _isVoiceNoiseSuppressionEnabled = false;
  bool get isVoiceNoiseSuppressionEnabled => _isVoiceNoiseSuppressionEnabled;
  double _messageFontScale = 1.0;
  double get messageFontScale => _messageFontScale;
  bool _autoRouteRotationEnabled =
      MessagingRoutePreferences.defaultAutoRouteRotationEnabled;
  bool get autoRouteRotationEnabled => _autoRouteRotationEnabled;
  bool _clearPathOnMaxRetry =
      MessagingRoutePreferences.defaultClearPathOnMaxRetry;
  bool get clearPathOnMaxRetry => _clearPathOnMaxRetry;
  bool _nearestRelayFallbackEnabled =
      MessagingRoutePreferences.defaultNearestRelayFallbackEnabled;
  bool get nearestRelayFallbackEnabled => _nearestRelayFallbackEnabled;
  final PathHistoryService _pathHistoryService = PathHistoryService();
  final NearestRouterSelector _nearestRouterSelector =
      const NearestRouterSelector();
  final Map<String, _DirectMessageRouteSession> _directMessageRouteSessions =
      {};

  static const Duration _packetRetryDelay = Duration(milliseconds: 1200);
  static const Duration _mediaSwarmResponseWindow = Duration(seconds: 10);
  static const int _maxPacketRetryAttempts = 4;
  final Map<String, String> _voiceSessionSenderKey6 = {};
  final Map<String, String> _imageSessionSenderKey6 = {};
  final Map<String, Map<int, VoicePacket>> _pendingChannelVoicePackets = {};
  final Map<String, Map<int, ImagePacket>> _pendingChannelImageFragments = {};
  final Map<String, Timer> _voiceMissingRetryTimers = {};
  final Map<String, int> _voiceMissingRetryAttempts = {};
  final Map<String, Timer> _imageMissingRetryTimers = {};
  final Map<String, int> _imageMissingRetryAttempts = {};
  final FragmentAckWaitRegistry _rawProbeWaiters = FragmentAckWaitRegistry();
  final Map<String, Future<bool>> _pendingRawRouteProbes = {};
  final Map<String, Future<bool>> _pendingMediaSwarmFetches = {};
  final Map<String, Map<String, MediaSwarmAvailability>>
  _pendingMediaSwarmResponses = {};
  final Map<String, DateTime> _recentRepeaterStatusRequests = {};
  final Map<String, DateTime> _recentRepeaterOwnerInfoRequests = {};
  final Map<int, _PendingRepeaterOwnerRequest> _pendingRepeaterOwnerRequests =
      {};
  bool _fastLocationScreenActive = false;
  Timer? _packetCaptureFlushTimer;
  Timer? _lowBatteryCheckTimer;
  String? _lastPersistedPacketSignature;
  bool _isPersistingPacketCapture = false;
  bool _wasDeviceConnected = false;
  bool _hasCompletedConnectionBootstrap = false;
  bool _isReconnectSyncInProgress = false;
  final Set<String> _lowBatteryNotifiedNodeIds = <String>{};

  AppProvider({
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.drawingProvider,
    required this.channelsProvider,
    required this.voiceProvider,
    required this.imageProvider,
  }) {
    _setupCallbacks();
    connectionProvider.canStartAutomaticMessageSyncCallback =
        _canStartAutomaticMessageSync;
    _wasDeviceConnected = connectionProvider.deviceInfo.isConnected;
    _initializeLocationTracking();
    _loadMapEnabled();
    _loadContactsEnabled();
    _loadContactsSectionVisibility();
    _loadSensorsEnabled();
    _loadVoiceSilenceTrimmingEnabled();
    _loadVoiceBandPassFilterEnabled();
    _loadVoiceCompressorEnabled();
    _loadVoiceLimiterEnabled();
    _loadVoiceAutoGainEnabled();
    _loadVoiceEchoCancellationEnabled();
    _loadVoiceNoiseSuppressionEnabled();
    _loadMessageFontScale();
    _loadMessagingRouteSettings();
    unawaited(_pathHistoryService.initialize());
    _startPacketCapturePersistence();
    _startLowBatteryWatcher();
    _syncDrawingsOnStartup(); // Sync drawings immediately after providers load
    _isInitialized = true;
  }

  String _scopedKey(String baseKey) {
    return ProfileStorageScope.scopedKey(baseKey);
  }

  bool isContactsSectionEnabled(ContactsTabSection section) {
    return _contactsSectionVisibility[section] ?? true;
  }

  String _contactsSectionVisibilityKey(ContactsTabSection section) {
    switch (section) {
      case ContactsTabSection.favourites:
        return 'contacts_section_favourites_enabled';
      case ContactsTabSection.teamMembers:
        return 'contacts_section_team_members_enabled';
      case ContactsTabSection.repeaters:
        return 'contacts_section_repeaters_enabled';
      case ContactsTabSection.sensors:
        return 'contacts_section_sensors_enabled';
      case ContactsTabSection.rooms:
        return 'contacts_section_rooms_enabled';
      case ContactsTabSection.channels:
        return 'contacts_section_channels_enabled';
    }
  }

  void _startPacketCapturePersistence() {
    _packetCaptureFlushTimer?.cancel();
    _packetCaptureFlushTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_flushPacketCaptureLogs());
    });
    unawaited(_flushPacketCaptureLogs());
  }

  void _startLowBatteryWatcher() {
    _lowBatteryCheckTimer?.cancel();
    _lowBatteryCheckTimer = Timer.periodic(_lowBatteryCheckInterval, (_) {
      unawaited(_checkLowBatteryAlerts());
    });
    unawaited(_checkLowBatteryAlerts());
  }

  Future<void> _checkLowBatteryAlerts() async {
    final deviceBattery = connectionProvider.deviceInfo.batteryPercent;
    if (deviceBattery != null &&
        deviceBattery > _lowBatteryResetThresholdPercent) {
      _lowBatteryNotifiedNodeIds.remove('device');
    }

    if (connectionProvider.deviceInfo.isConnected && deviceBattery != null) {
      await _notifyLowBatteryIfNeeded(
        nodeId: 'device',
        nodeName:
            connectionProvider.deviceInfo.selfName?.trim().isNotEmpty == true
            ? connectionProvider.deviceInfo.selfName!.trim()
            : (connectionProvider.deviceInfo.displayName ?? 'Connected device'),
        batteryPercent: deviceBattery,
        isCurrentDevice: true,
      );
    }
  }

  Future<void> _notifyLowBatteryIfNeeded({
    required String nodeId,
    required String nodeName,
    required double batteryPercent,
    required bool isCurrentDevice,
  }) async {
    if (batteryPercent >= _lowBatteryThresholdPercent) {
      return;
    }
    if (_lowBatteryNotifiedNodeIds.contains(nodeId)) {
      return;
    }

    final shown = await _notificationService.showLowBatteryNotification(
      nodeId: nodeId,
      nodeName: nodeName,
      batteryPercent: batteryPercent,
      isCurrentDevice: isCurrentDevice,
    );
    if (shown) {
      _lowBatteryNotifiedNodeIds.add(nodeId);
    }
  }

  String _packetLogSignature(BlePacketLog log) {
    final prefix = log.rawData.length <= 12
        ? log.rawData
        : log.rawData.sublist(0, 12);
    final prefixHex = prefix
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${log.timestamp.microsecondsSinceEpoch}|'
        '${log.direction.name}|${log.responseCode ?? -1}|'
        '${log.rawData.length}|$prefixHex';
  }

  Future<void> _flushPacketCaptureLogs() async {
    if (_isPersistingPacketCapture) return;
    _isPersistingPacketCapture = true;
    try {
      final logs = connectionProvider.bleService.packetLogs;
      if (logs.isEmpty) return;

      List<BlePacketLog> toPersist = const [];
      if (_lastPersistedPacketSignature == null) {
        toPersist = logs;
      } else {
        final lastSig = _lastPersistedPacketSignature!;
        var lastIndex = -1;
        for (var i = logs.length - 1; i >= 0; i--) {
          if (_packetLogSignature(logs[i]) == lastSig) {
            lastIndex = i;
            break;
          }
        }
        if (lastIndex == -1) {
          // In-memory log rotated or cleared; persist current window to avoid gaps.
          toPersist = logs;
        } else if (lastIndex < logs.length - 1) {
          toPersist = logs.sublist(lastIndex + 1);
        }
      }

      if (toPersist.isNotEmpty) {
        await packetCaptureStorageService.appendLogs(toPersist);
      }
      _lastPersistedPacketSignature = _packetLogSignature(logs.last);
    } catch (e) {
      debugPrint('❌ [AppProvider] Packet capture flush failed: $e');
    } finally {
      _isPersistingPacketCapture = false;
    }
  }

  /// Sync drawings from messages on app startup (before BLE connection)
  Future<void> _syncDrawingsOnStartup() async {
    // Wait for both MessagesProvider and DrawingProvider to finish initializing
    int attempts = 0;
    while ((!messagesProvider.isInitialized ||
            !drawingProvider.isInitialized) &&
        attempts < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    _restoreSessionMetadataFromMessages();

    debugPrint(
      '🔄 [AppProvider] Early sync: syncing drawings from messages...',
    );
    messagesProvider.syncDrawingsWithProvider(drawingProvider);
  }

  void _restoreSessionMetadataFromMessages() {
    final restored = restoreSessionMetadataFromMessages(
      messagesProvider.messages,
    );

    _voiceSessionSenderKey6.addAll(restored.voiceSenderKeyBySession);
    _imageSessionSenderKey6.addAll(restored.imageSenderKeyBySession);
    for (final entry in restored.imageEnvelopeBySession.entries) {
      imageProvider.registerEnvelope(entry.value);
    }

    final restoredVoice = restored.voiceSenderKeyBySession.length;
    final restoredImage = restored.imageEnvelopeBySession.length;
    if (restoredVoice > 0 || restoredImage > 0) {
      debugPrint(
        '🔄 [AppProvider] Restored session metadata from messages: '
        '$restoredVoice voice, $restoredImage image',
      );
    }
  }

  String? _resolveContactNameForNotification(Uint8List? publicKey) {
    if (publicKey == null || publicKey.isEmpty) return null;

    final ownPublicKey = connectionProvider.deviceInfo.publicKey;
    final ownName = _preferredSelfDisplayName(
      deviceName: connectionProvider.deviceInfo.deviceName,
      selfName: connectionProvider.deviceInfo.selfName,
    );
    if (_matchesPublicKeyPrefix(publicKey, ownPublicKey) &&
        ownName != null &&
        ownName.trim().isNotEmpty) {
      return ownName;
    }

    Contact? contact;
    if (publicKey.length >= 32) {
      contact = contactsProvider.findContactByKey(publicKey);
    }
    contact ??= publicKey.length >= 6
        ? contactsProvider.findContactByPrefix(
            Uint8List.fromList(publicKey.sublist(0, 6)),
          )
        : null;
    return contact?.advName;
  }

  static bool shouldIgnoreSelfReplay({
    required Message message,
    required Uint8List? ownPublicKey,
    required String? ownName,
  }) {
    if ((!message.isContactMessage && !message.isChannelMessage) ||
        message.pathLen > 0) {
      return false;
    }

    if (_matchesPublicKeyPrefix(message.senderPublicKeyPrefix, ownPublicKey)) {
      return true;
    }

    final trimmedSenderName = message.senderName?.trim();
    final trimmedOwnName = ownName?.trim();
    if (trimmedSenderName == null ||
        trimmedSenderName.isEmpty ||
        trimmedOwnName == null ||
        trimmedOwnName.isEmpty) {
      return false;
    }

    return trimmedSenderName == trimmedOwnName;
  }

  static String? preferredSelfDisplayName({
    required String? deviceName,
    required String? selfName,
  }) => _preferredSelfDisplayName(deviceName: deviceName, selfName: selfName);

  static String? _preferredSelfDisplayName({
    required String? deviceName,
    required String? selfName,
  }) {
    final trimmedSelfName = selfName?.trim();
    if (trimmedSelfName != null && trimmedSelfName.isNotEmpty) {
      return trimmedSelfName;
    }

    final trimmedDeviceName = deviceName?.trim();
    if (trimmedDeviceName == null || trimmedDeviceName.isEmpty) {
      return null;
    }

    if (trimmedDeviceName.toLowerCase().startsWith('meshcore-')) {
      final stripped = trimmedDeviceName.substring('meshcore-'.length).trim();
      if (stripped.isNotEmpty) {
        return stripped;
      }
    }

    return trimmedDeviceName;
  }

  static bool _matchesPublicKeyPrefix(
    Uint8List? candidateKey,
    Uint8List? ownPublicKey,
  ) {
    if (candidateKey == null ||
        candidateKey.isEmpty ||
        ownPublicKey == null ||
        ownPublicKey.isEmpty) {
      return false;
    }

    final compareLength = candidateKey.length >= 6 && ownPublicKey.length >= 6
        ? 6
        : (candidateKey.length < ownPublicKey.length
              ? candidateKey.length
              : ownPublicKey.length);
    if (compareLength <= 0) {
      return false;
    }

    for (var index = 0; index < compareLength; index++) {
      if (candidateKey[index] != ownPublicKey[index]) {
        return false;
      }
    }
    return true;
  }

  /// Load map enabled setting from shared preferences
  Future<void> _loadMapEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMapEnabled = prefs.getBool(_scopedKey('map_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading map enabled setting: $e');
    }
  }

  /// Toggle map on/off
  Future<void> toggleMapEnabled(bool enabled) async {
    try {
      _isMapEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('map_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving map enabled setting: $e');
    }
  }

  /// Load contacts enabled setting from shared preferences
  Future<void> _loadContactsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isContactsEnabled =
          prefs.getBool(_scopedKey('contacts_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts enabled setting: $e');
    }
  }

  /// Toggle contacts tab on/off
  Future<void> toggleContactsEnabled(bool enabled) async {
    try {
      _isContactsEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('contacts_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving contacts enabled setting: $e');
    }
  }

  Future<void> _loadContactsSectionVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final section in ContactsTabSection.values) {
        _contactsSectionVisibility[section] =
            prefs.getBool(_scopedKey(_contactsSectionVisibilityKey(section))) ??
            true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading contacts section visibility settings: $e');
    }
  }

  Future<void> setContactsSectionEnabled(
    ContactsTabSection section,
    bool enabled,
  ) async {
    try {
      _contactsSectionVisibility[section] = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _scopedKey(_contactsSectionVisibilityKey(section)),
        enabled,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving contacts section visibility setting: $e');
    }
  }

  /// Load sensors enabled setting from shared preferences
  Future<void> _loadSensorsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSensorsEnabled = prefs.getBool(_scopedKey('sensors_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sensors enabled setting: $e');
    }
  }

  /// Toggle sensors tab on/off
  Future<void> toggleSensorsEnabled(bool enabled) async {
    try {
      _isSensorsEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('sensors_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving sensors enabled setting: $e');
    }
  }

  /// Load voice silence trimming setting from shared preferences.
  Future<void> _loadVoiceSilenceTrimmingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceSilenceTrimmingEnabled =
          prefs.getBool(_scopedKey('voice_silence_trimming_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice silence trimming setting: $e');
    }
  }

  /// Toggle voice silence trimming on/off.
  Future<void> toggleVoiceSilenceTrimmingEnabled(bool enabled) async {
    try {
      _isVoiceSilenceTrimmingEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _scopedKey('voice_silence_trimming_enabled'),
        enabled,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice silence trimming setting: $e');
    }
  }

  /// Load voice band-pass filter setting from shared preferences.
  Future<void> _loadVoiceBandPassFilterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceBandPassFilterEnabled =
          prefs.getBool(_scopedKey('voice_band_pass_filter_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice band-pass filter setting: $e');
    }
  }

  /// Toggle voice band-pass filter on/off.
  Future<void> toggleVoiceBandPassFilterEnabled(bool enabled) async {
    try {
      _isVoiceBandPassFilterEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _scopedKey('voice_band_pass_filter_enabled'),
        enabled,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice band-pass filter setting: $e');
    }
  }

  /// Load voice compressor setting from shared preferences.
  Future<void> _loadVoiceCompressorEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceCompressorEnabled =
          prefs.getBool(_scopedKey('voice_compressor_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice compressor setting: $e');
    }
  }

  /// Toggle voice compressor on/off.
  Future<void> toggleVoiceCompressorEnabled(bool enabled) async {
    try {
      _isVoiceCompressorEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('voice_compressor_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice compressor setting: $e');
    }
  }

  /// Load voice limiter setting from shared preferences.
  Future<void> _loadVoiceLimiterEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceLimiterEnabled =
          prefs.getBool(_scopedKey('voice_limiter_enabled')) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice limiter setting: $e');
    }
  }

  /// Toggle voice limiter on/off.
  Future<void> toggleVoiceLimiterEnabled(bool enabled) async {
    try {
      _isVoiceLimiterEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('voice_limiter_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice limiter setting: $e');
    }
  }

  Future<void> _loadVoiceAutoGainEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceAutoGainEnabled =
          prefs.getBool(_scopedKey('voice_auto_gain_enabled')) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice auto gain setting: $e');
    }
  }

  Future<void> toggleVoiceAutoGainEnabled(bool enabled) async {
    try {
      _isVoiceAutoGainEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey('voice_auto_gain_enabled'), enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice auto gain setting: $e');
    }
  }

  Future<void> _loadVoiceEchoCancellationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceEchoCancellationEnabled =
          prefs.getBool(_scopedKey('voice_echo_cancellation_enabled')) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice echo cancellation setting: $e');
    }
  }

  Future<void> toggleVoiceEchoCancellationEnabled(bool enabled) async {
    try {
      _isVoiceEchoCancellationEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _scopedKey('voice_echo_cancellation_enabled'),
        enabled,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice echo cancellation setting: $e');
    }
  }

  Future<void> _loadVoiceNoiseSuppressionEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceNoiseSuppressionEnabled =
          prefs.getBool(_scopedKey('voice_noise_suppression_enabled')) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading voice noise suppression setting: $e');
    }
  }

  Future<void> toggleVoiceNoiseSuppressionEnabled(bool enabled) async {
    try {
      _isVoiceNoiseSuppressionEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _scopedKey('voice_noise_suppression_enabled'),
        enabled,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving voice noise suppression setting: $e');
    }
  }

  Future<void> _loadMessageFontScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _messageFontScale =
          (prefs.getDouble(_scopedKey('message_font_scale')) ?? 1.0).clamp(
            0.85,
            1.4,
          );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading message font scale setting: $e');
    }
  }

  Future<void> setMessageFontScale(double scale) async {
    try {
      _messageFontScale = scale.clamp(0.85, 1.4);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        _scopedKey('message_font_scale'),
        _messageFontScale,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving message font scale setting: $e');
    }
  }

  Future<void> _loadMessagingRouteSettings() async {
    try {
      _autoRouteRotationEnabled =
          await MessagingRoutePreferences.getAutoRouteRotationEnabled();
      _clearPathOnMaxRetry =
          await MessagingRoutePreferences.getClearPathOnMaxRetry();
      _nearestRelayFallbackEnabled =
          await MessagingRoutePreferences.getNearestRelayFallbackEnabled();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messaging route settings: $e');
    }
  }

  Future<void> toggleAutoRouteRotationEnabled(bool enabled) async {
    try {
      _autoRouteRotationEnabled = enabled;
      await MessagingRoutePreferences.setAutoRouteRotationEnabled(enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving auto route rotation setting: $e');
    }
  }

  Future<void> toggleClearPathOnMaxRetry(bool enabled) async {
    try {
      _clearPathOnMaxRetry = enabled;
      await MessagingRoutePreferences.setClearPathOnMaxRetry(enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving clear path on max retry setting: $e');
    }
  }

  Future<void> toggleNearestRelayFallbackEnabled(bool enabled) async {
    try {
      _nearestRelayFallbackEnabled = enabled;
      await MessagingRoutePreferences.setNearestRelayFallbackEnabled(enabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving nearest relay fallback setting: $e');
    }
  }

  /// Initialize location tracking service
  Future<void> _initializeLocationTracking() async {
    try {
      // Initialize location tracking with BLE service
      await locationTrackingService.initialize(connectionProvider.bleService);

      // Setup callbacks
      locationTrackingService.onPositionUpdate = (position) {
        debugPrint(
          '📍 [AppProvider] Position updated: ${position.latitude}, ${position.longitude}',
        );
      };

      locationTrackingService.onBroadcastSent = (position) {
        debugPrint('📡 [AppProvider] Position broadcast to mesh network');
      };

      locationTrackingService.onError = (error) {
        debugPrint('❌ [AppProvider] Location tracking error: $error');
      };

      locationTrackingService.onTrackingStateChanged = (isTracking) {
        debugPrint(
          '🔄 [AppProvider] Location tracking state: ${isTracking ? "started" : "stopped"}',
        );
      };

      locationTrackingService.onFastLocationUpdate = (position, reason) {
        unawaited(_sendFastLocationUpdate(position, reason: reason));
      };

      debugPrint('✅ [AppProvider] Location tracking service initialized');
    } catch (e) {
      debugPrint('❌ [AppProvider] Error initializing location tracking: $e');
    }
  }

  /// Setup callbacks between providers
  void _setupCallbacks() {
    // Monitor connection state changes to start/stop location tracking
    connectionProvider.addListener(_handleConnectionStateChange);
    messagesProvider.resolveContactNameCallback =
        _resolveContactNameForNotification;
    messagesProvider.resolveChannelNameCallback = (channelIdx) {
      if (channelIdx == 0) {
        return 'Public';
      }

      for (final channel in contactsProvider.channels) {
        if (channel.publicKey.length > 1 &&
            channel.publicKey[1] == channelIdx) {
          return channel.displayName;
        }
      }

      return channelsProvider.getChannelDisplayName(channelIdx);
    };

    voiceProvider.sendRawPacketCallback =
        ({
          required Uint8List contactPath,
          required int contactPathLen,
          required Uint8List payload,
        }) async {
          await connectionProvider.sendRawVoicePacket(
            contactPath: contactPath,
            contactPathLen: contactPathLen,
            payload: payload,
          );
        };

    // Image raw-packet serving reuses the same BLE raw-data path as voice.
    imageProvider.sendRawPacketCallback =
        ({
          required Uint8List contactPath,
          required int contactPathLen,
          required Uint8List payload,
        }) async {
          await connectionProvider.sendRawVoicePacket(
            contactPath: contactPath,
            contactPathLen: contactPathLen,
            payload: payload,
          );
        };
    // When a contact is received from BLE
    connectionProvider.onContactReceivedDetailed = (contact, source) {
      final devicePublicKey = connectionProvider.deviceInfo.publicKey;
      final existingContact = contactsProvider.findContactByKey(
        contact.publicKey,
      );
      final isAdvertSource =
          source == ContactReceiveSource.advert ||
          source == ContactReceiveSource.preview;

      if (isAdvertSource) {
        // For pushNewAdvert (0x8A): contact data is already in the push, but
        // we also import into firmware so subsequent getContact calls work.
        // Matches the official app which calls cmdGetAdvertPath for all adverts.
        if (source == ContactReceiveSource.advert) {
          unawaited(connectionProvider.importReceivedAdvert(contact.publicKey));
        }
        final isNewPendingAdvert = contactsProvider
            .addOrUpdatePendingAdvertContact(
              contact,
              devicePublicKey: devicePublicKey,
            );
        if (isNewPendingAdvert) {
          unawaited(
            _notificationService.showContactDiscoveredNotification(
              contactKey: contact.publicKey
                  .take(6)
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(),
              contactName: contact.advName.trim().isEmpty
                  ? null
                  : contact.advName,
            ),
          );
        }
        if (contact.type == ContactType.repeater &&
            contact.advName.trim().isEmpty) {
          unawaited(_maybeRequestRepeaterOwnerInfo(contact.publicKey));
        }
        if (existingContact == null) {
          return;
        }
      }

      // Pass device public key to filter out our own contact
      contactsProvider.addOrUpdateContact(
        contact,
        devicePublicKey: devicePublicKey,
      );
      unawaited(_pathHistoryService.recordLearnedPath(contact));
    };

    // When all contacts are received
    connectionProvider.onContactsComplete = (contacts) {
      // Pass device public key to filter out our own contact
      contactsProvider.addContacts(
        contacts,
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
      for (final contact in contacts) {
        unawaited(_pathHistoryService.recordLearnedPath(contact));
      }
      debugPrint('Received ${contacts.length} contacts');
    };

    // Setup callback for ConnectionProvider to query channel info
    connectionProvider.getChannelInfo = (int channelIdx) {
      return channelsProvider.getChannel(channelIdx);
    };

    // When channel info is received
    connectionProvider.onChannelInfoReceived =
        (int channelIdx, String channelName, Uint8List secret, int? flags) {
          try {
            debugPrint(
              '🔔 [AppProvider] onChannelInfoReceived called: idx=$channelIdx, name="$channelName"',
            );

            final isDeletedChannel = connectionProvider
                .shouldTreatChannelInfoAsDeleted(
                  channelIdx,
                  channelName,
                  secret,
                );
            final isEmptyChannelInfo = AppProvider.isDeletedChannelInfo(
              channelIdx,
              channelName,
              secret,
            );
            final contactChannelName = AppProvider.channelContactName(
              channelIdx,
              channelName,
            );

            // Only treat the slot as deleted when firmware returns an empty
            // name and a zeroed secret. Protected channels may still have an
            // empty display name but remain fully configured.
            if (isDeletedChannel) {
              debugPrint(
                '   🗑️  Channel $channelIdx deleted - removing from providers',
              );

              messagesProvider.clearChannelMessages(channelIdx);
              debugPrint('   ✅ Cleared channel messages');

              // Remove from ChannelsProvider
              channelsProvider.removeChannel(channelIdx);
              debugPrint('   ✅ Removed from ChannelsProvider');

              // Remove from ContactsProvider using pseudo public key
              final publicKeyBytes = Uint8List(32);
              publicKeyBytes[0] = 0xFF; // Special marker for channels
              publicKeyBytes[1] = channelIdx; // Channel index
              final publicKeyHex = publicKeyBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join('');

              contactsProvider.removeContact(publicKeyHex);
              debugPrint('   ✅ Removed from ContactsProvider');

              return;
            }

            if (isEmptyChannelInfo) {
              debugPrint(
                '   ⏭️  Ignoring empty channel slot $channelIdx during sync',
              );
              return;
            }

            // Add/update in ChannelsProvider
            channelsProvider.addOrUpdateChannel(
              index: channelIdx,
              name: channelName,
              secret: secret,
              flags: flags,
            );
            debugPrint('   ✅ Added to ChannelsProvider');

            // Also add as Contact to ContactsProvider (for UI display)
            // Skip if it's public channel (already exists)
            debugPrint(
              '📻 [AppProvider] Channel $channelIdx: "$contactChannelName" (rawNameEmpty: ${channelName.isEmpty}, isHashChannel: ${channelName.startsWith('#')})',
            );

            if (channelIdx != 0) {
              debugPrint(
                '   ✅ Adding channel $channelIdx to ContactsProvider as Contact',
              );

              // Create a pseudo public key for the channel based on its index
              // Use channel index as a unique identifier (pad to 32 bytes)
              final publicKeyBytes = Uint8List(32);
              publicKeyBytes[0] = 0xFF; // Special marker for channels
              publicKeyBytes[1] = channelIdx; // Channel index

              final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

              contactsProvider.addOrUpdateContact(
                Contact(
                  publicKey: publicKeyBytes,
                  type: ContactType.channel,
                  flags: flags ?? 0,
                  outPathLen: -1, // Flood mode for channels
                  outPath: Uint8List(0), // Empty path for channels
                  advName: contactChannelName,
                  lastAdvert: now,
                  advLat: 0, // Channels don't have location
                  advLon: 0,
                  lastMod: now,
                  isNew: false, // Don't mark channels as new
                ),
              );

              debugPrint(
                '   ✅ Channel contact added. Total channels in ContactsProvider: ${contactsProvider.channels.length}',
              );
            } else {
              debugPrint(
                '   ⏭️  Skipping channel $channelIdx (isPublic: ${channelIdx == 0})',
              );
            }
          } catch (e, stackTrace) {
            debugPrint('❌ [AppProvider] Error in onChannelInfoReceived: $e');
            debugPrint('   Stack trace: $stackTrace');
          }
        };

    // When a message is received
    connectionProvider.onMessageReceived = (message) {
      if (message.isChannelMessage) {
        debugPrint(
          '📥 [AppProvider] Channel message received: '
          'id=${message.id}, '
          'senderName=${message.senderName ?? "-"}, '
          'senderKey=${message.senderKeyShort ?? "-"}, '
          'pathLen=${message.pathLen}, '
          'ts=${message.senderTimestamp}, '
          'text=${message.text}',
        );
      }

      if (AppProvider.shouldIgnoreSelfReplay(
        message: message,
        ownPublicKey: connectionProvider.deviceInfo.publicKey,
        ownName: _preferredSelfDisplayName(
          deviceName: connectionProvider.deviceInfo.deviceName,
          selfName: connectionProvider.deviceInfo.selfName,
        ),
      )) {
        debugPrint('⏭️ [AppProvider] Ignoring self replay: ${message.id}');
        return;
      }

      // Enrich message with sender name from contacts.
      // For room-forwarded messages, resolve the original poster's name
      // from roomPostAuthorPrefix instead of the room server's key.
      Message enrichedMessage = message;
      Contact? senderContact;
      if (message.senderName == null) {
        // Try room post author first (the actual person who posted)
        if (message.roomPostAuthorPrefix != null) {
          final author = contactsProvider.findContactByPrefix(
            message.roomPostAuthorPrefix!,
          );
          if (author != null) {
            senderContact = author;
            enrichedMessage = message.copyWith(senderName: author.advName);
          }
        }
        // Fall back to sender key (direct messages, or room with unknown author)
        if (senderContact == null && message.senderPublicKeyPrefix != null) {
          final contact = contactsProvider.findContactByKey(
            message.senderPublicKeyPrefix!,
          );
          if (contact != null) {
            senderContact = contact;
            enrichedMessage = message.copyWith(senderName: contact.advName);
          }
        }
      }
      senderContact ??= message.senderPublicKeyPrefix != null
          ? contactsProvider.findContactByKey(message.senderPublicKeyPrefix!)
          : null;
      senderContact ??= enrichedMessage.senderName != null
          ? contactsProvider.contacts
                .where((c) => c.advName == enrichedMessage.senderName)
                .firstOrNull
          : null;
      final contactLocationSnapshot = senderContact != null
          ? contactsProvider.buildMessageContactLocationSnapshot(
              senderContact,
              capturedAt: enrichedMessage.receivedAt,
            )
          : null;
      final receptionDetailsSnapshot = _buildReceptionDetailsSnapshot(
        enrichedMessage,
      );
      final receivedPathBytes = receptionDetailsSnapshot?.pathBytes;
      if (senderContact != null &&
          enrichedMessage.isChannelMessage &&
          receivedPathBytes != null &&
          receivedPathBytes.isNotEmpty) {
        unawaited(
          _learnPathFromPublicMessage(
            contact: senderContact,
            pathBytes: receivedPathBytes,
          ),
        );
      }

      // Estimate location for contacts without GPS using received path
      if (senderContact != null &&
          senderContact.displayLocation == null &&
          receivedPathBytes != null &&
          receivedPathBytes.isNotEmpty) {
        _estimateContactLocationFromReceivedPath(
          contact: senderContact,
          receivedPathBytes: receivedPathBytes,
        );
      }

      // Check if message is a drawing broadcast
      if (DrawingMessageParser.isDrawingMessage(enrichedMessage.text)) {
        debugPrint('🎨 [AppProvider] Drawing message received, parsing...');
        // Extract sender name from message packet metadata
        final senderName = enrichedMessage.senderName ?? 'unknown';
        final drawing = DrawingMessageParser.parseDrawingMessage(
          enrichedMessage.text,
          senderName: senderName,
          messageId:
              enrichedMessage.id, // Pass message ID for navigation linking
        );
        if (drawing != null) {
          debugPrint(
            '🎨 [AppProvider] Drawing parsed successfully: ${drawing.type.name} from ${drawing.senderName ?? "unknown"}',
          );
          debugPrint('   Drawing linked to message ID: ${enrichedMessage.id}');
          drawingProvider.addReceivedDrawing(drawing);

          // Update message to mark as drawing and link to drawing ID
          final updatedMessage = enrichedMessage.copyWith(
            isDrawing: true,
            drawingId: drawing.id,
          );

          // Add the drawing message to chat with drawing metadata
          // This allows users to click on the drawing message to navigate to it
          messagesProvider.addMessage(
            updatedMessage,
            contactLookup: (name) => '',
            contactLocationSnapshot: contactLocationSnapshot,
            receptionDetailsSnapshot: receptionDetailsSnapshot,
          );
        } else {
          debugPrint('⚠️ [AppProvider] Failed to parse drawing message');
        }
        return;
      }

      // Voice envelope message (new public/direct on-demand format).
      final voiceEnvelope = VoiceEnvelope.tryParseText(enrichedMessage.text);
      if (voiceEnvelope != null) {
        final senderPrefix = enrichedMessage.senderPublicKeyPrefix;
        if (senderPrefix != null && senderPrefix.length >= 6) {
          _voiceSessionSenderKey6[voiceEnvelope.sessionId] = senderPrefix
              .sublist(0, 6)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toLowerCase();
        }
        voiceProvider.registerEnvelope(voiceEnvelope);
        _replayPendingChannelVoicePackets(voiceEnvelope.sessionId);
        enrichedMessage = enrichedMessage.copyWith(
          isVoice: true,
          voiceId: voiceEnvelope.sessionId,
        );
        messagesProvider.addMessage(
          enrichedMessage,
          contactLookup: (name) {
            try {
              final contact = contactsProvider.contacts.firstWhere(
                (c) => c.advName == name,
              );
              return contact.publicKeyHex.isNotEmpty &&
                      contact.publicKeyHex.length >= 12
                  ? contact.publicKeyHex.substring(0, 12)
                  : '';
            } catch (_) {
              return '';
            }
          },
          contactLocationSnapshot: contactLocationSnapshot,
          receptionDetailsSnapshot: receptionDetailsSnapshot,
        );
        return;
      }

      // Image envelope (IE1): announce image availability.
      final imageEnvelope = ImageEnvelope.tryParse(enrichedMessage.text);
      if (imageEnvelope != null) {
        final senderPrefix = enrichedMessage.senderPublicKeyPrefix;
        if (senderPrefix != null && senderPrefix.length >= 6) {
          _imageSessionSenderKey6[imageEnvelope.sessionId] = senderPrefix
              .sublist(0, 6)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toLowerCase();
        }
        imageProvider.registerEnvelope(imageEnvelope);
        _replayPendingChannelImageFragments(imageEnvelope.sessionId);
        messagesProvider.addMessage(
          enrichedMessage,
          contactLookup: (name) {
            try {
              final contact = contactsProvider.contacts.firstWhere(
                (c) => c.advName == name,
              );
              return contact.publicKeyHex.isNotEmpty &&
                      contact.publicKeyHex.length >= 12
                  ? contact.publicKeyHex.substring(0, 12)
                  : '';
            } catch (_) {
              return '';
            }
          },
          contactLocationSnapshot: contactLocationSnapshot,
          receptionDetailsSnapshot: receptionDetailsSnapshot,
        );
        return;
      }

      // Pass contact lookup function to link channel messages with contacts
      messagesProvider.addMessage(
        enrichedMessage,
        contactLookup: (name) {
          // Find contact by name and return their public key hex (first 12 chars for 6 bytes)
          try {
            final contact = contactsProvider.contacts.firstWhere(
              (c) => c.advName == name,
            );
            return contact.publicKeyHex.isNotEmpty &&
                    contact.publicKeyHex.length >= 12
                ? contact.publicKeyHex.substring(0, 12)
                : '';
          } catch (e) {
            // No matching contact found
            return '';
          }
        },
        contactLocationSnapshot: contactLocationSnapshot,
        receptionDetailsSnapshot: receptionDetailsSnapshot,
      );
    };

    // Keep a compact receive-time snapshot because packet logs roll over.
    // This lets the UI still show timing/link details after app restarts.

    // When telemetry is received via PUSH_CODE_TELEMETRY_RESPONSE (0x8B)
    // Used by older firmware versions for telemetry responses
    connectionProvider.onTelemetryReceived = (publicKey, lppData) {
      debugPrint(
        '📊 [AppProvider] Telemetry response (0x8B) received - updating contact',
      );
      contactsProvider.updateTelemetry(publicKey, lppData);
    };

    // When binary response is received via PUSH_CODE_BINARY_RESPONSE (0x8C)
    // Used by newer firmware versions for telemetry and other binary data
    // BOTH callbacks (0x8B and 0x8C) must be handled for device compatibility
    connectionProvider.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      if (_handlePendingRepeaterOwnerResponse(tag, responseData)) {
        return;
      }
      debugPrint('📊 [AppProvider] Binary response (0x8C tag=$tag) received');
      // Binary responses carry Cayenne LPP telemetry data.
      // The data starts with a channel byte — valid LPP always has at least
      // 3 bytes (channel + type + value). Skip clearly non-telemetry payloads.
      if (responseData.length >= 3) {
        contactsProvider.updateTelemetry(publicKeyPrefix, responseData);
      }
    };

    // When raw binary data is received (PUSH_CODE_RAW_DATA 0x84)
    // Magic 0x6d 'm' = swarm control; 0x72 'r' = voice fetch request.
    // Magic 0x69 'i' = image fetch request; 0x56 'V' = voice packet.
    // Magic 0x49 'I' = image packet.
    connectionProvider.onRawDataReceived = (payload, snrRaw, rssiDbm) {
      final parsedAdvert = _tryParseRawAdvert(payload);
      if (parsedAdvert != null) {
        final isNewPendingAdvert = contactsProvider
            .addOrUpdatePendingAdvertMetadata(
              publicKey: parsedAdvert.publicKey,
              typeValue: parsedAdvert.typeValue,
              devicePublicKey: connectionProvider.deviceInfo.publicKey,
              flags: parsedAdvert.flags,
              advName: parsedAdvert.advName,
              lastAdvert: parsedAdvert.lastAdvert,
              advLat: parsedAdvert.advLat,
              advLon: parsedAdvert.advLon,
              signedEncodedPathLen: parsedAdvert.signedEncodedPathLen,
              paddedPathBytes: parsedAdvert.paddedPathBytes,
              rxRssiDbm: rssiDbm,
              rxSnrRaw: snrRaw,
            );
        if (isNewPendingAdvert) {
          final contactKey = parsedAdvert.publicKey
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          unawaited(
            _notificationService.showContactDiscoveredNotification(
              contactKey: contactKey,
              contactName: parsedAdvert.advName,
            ),
          );
        }
        if (parsedAdvert.typeValue == ContactType.repeater.value) {
          unawaited(_requestRepeaterStatus(parsedAdvert.publicKey));
          unawaited(_maybeRequestRepeaterOwnerInfo(parsedAdvert.publicKey));
        }
        if (contactsProvider.shouldEnrichPendingAdvert(
          parsedAdvert.publicKey,
        )) {
          unawaited(connectionProvider.previewContact(parsedAdvert.publicKey));
        }
        return;
      }

      if (_handleFastGpsPayload(payload)) {
        return;
      }

      final rawProbeRequest = RawRouteProbeRequest.tryParseBinary(payload);
      if (rawProbeRequest != null) {
        debugPrint(
          '📡 [AppProvider] Incoming raw route probe: nonce=${rawProbeRequest.nonce.toRadixString(16)} requester=${rawProbeRequest.requesterKey6}',
        );
        _handleRawRouteProbeRequest(rawProbeRequest);
        return;
      }

      final rawProbeAck = RawRouteProbeAck.tryParseBinary(payload);
      if (rawProbeAck != null) {
        debugPrint(
          '📡 [AppProvider] Incoming raw route probe ACK: nonce=${rawProbeAck.nonce.toRadixString(16)}',
        );
        _completeRawRouteProbeAck(rawProbeAck.nonce);
        return;
      }

      final mediaSwarmRequest = MediaSwarmRequest.tryParseBinary(payload);
      if (mediaSwarmRequest != null) {
        _handleIncomingMediaSwarmRequest(mediaSwarmRequest);
        return;
      }

      final mediaSwarmAvailability = MediaSwarmAvailability.tryParseBinary(
        payload,
      );
      if (mediaSwarmAvailability != null) {
        _handleIncomingMediaSwarmAvailability(mediaSwarmAvailability);
        return;
      }

      final voiceFetchRequest = VoiceFetchRequest.tryParseBinary(payload);
      if (voiceFetchRequest != null) {
        debugPrint(
          '🎙️ [AppProvider] Incoming voice fetch request: session=${voiceFetchRequest.sessionId} want=${voiceFetchRequest.want} requester=${voiceFetchRequest.requesterKey6}',
        );
        final requester = _resolveVoiceFetchRequester(voiceFetchRequest);
        if (requester == null) {
          debugPrint(
            '⚠️ [AppProvider] Voice fetch requester contact not found (binary)',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch voice: requester contact is unknown. Add/sync contacts first.',
            level: 'warning',
          );
          return;
        }
        if (requester.routeHopCount > _maxDirectPayloadHops) {
          debugPrint(
            '⚠️ [AppProvider] Voice fetch requester too far: ${requester.routeHopCount} hops',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch voice for ${requester.advName}: message is too far (${requester.routeHopCount} hops, max $_maxDirectPayloadHops).',
            level: 'warning',
          );
          return;
        }
        unawaited(() async {
          final served = await voiceProvider.serveSessionTo(
            sessionId: voiceFetchRequest.sessionId,
            requester: requester,
            requestedIndices: voiceFetchRequest.want == 'missing'
                ? voiceFetchRequest.missingIndices.toSet()
                : null,
          );
          if (served) {
            messagesProvider.recordMediaTransfer(
              sessionId: voiceFetchRequest.sessionId,
              mediaType: 'voice',
              requesterKey6: voiceFetchRequest.requesterKey6,
              requesterName: requester.advName,
            );
          }
        }());
        return;
      }

      final imageFetchRequest = ImageFetchRequest.tryParseBinary(payload);
      if (imageFetchRequest != null) {
        final requester = _resolveImageFetchRequester(imageFetchRequest);
        if (requester == null) {
          debugPrint(
            '⚠️ [AppProvider] Image fetch requester contact not found (binary) '
            'for session ${imageFetchRequest.sessionId} / '
            '${imageFetchRequest.requesterKey6}',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch image: requester contact is unknown. Add/sync contacts first.',
            level: 'warning',
          );
          return;
        }
        if (requester.routeHopCount > _maxDirectPayloadHops) {
          debugPrint(
            '⚠️ [AppProvider] Image fetch requester too far: '
            '${requester.routeHopCount} hops for session '
            '${imageFetchRequest.sessionId}',
          );
          messagesProvider.logSystemMessage(
            text:
                'Cannot fetch image for ${requester.advName}: message is too far (${requester.routeHopCount} hops, max $_maxDirectPayloadHops).',
            level: 'warning',
          );
          return;
        }
        debugPrint(
          '📷 [AppProvider] Serving image session ${imageFetchRequest.sessionId} '
          'to ${requester.advName} via ${requester.routeHopCount} hop(s)',
        );
        unawaited(() async {
          final served = await imageProvider.serveSessionTo(
            sessionId: imageFetchRequest.sessionId,
            requester: requester,
            requestedIndices: imageFetchRequest.want == 'missing'
                ? imageFetchRequest.missingIndices.toSet()
                : null,
          );
          if (served) {
            messagesProvider.recordMediaTransfer(
              sessionId: imageFetchRequest.sessionId,
              mediaType: 'image',
              requesterKey6: imageFetchRequest.requesterKey6,
              requesterName: requester.advName,
            );
          }
        }());
        return;
      }

      if (_handleIncomingImageBinaryPayload(payload)) {
        return;
      }
      _handleIncomingVoiceBinaryPayload(payload);
    };

    connectionProvider.onChannelDataReceived =
        (channelIdx, pathLen, dataType, payload, snrRaw, rssiDbm) {
          if (dataType != MeshCoreConstants.dataTypeDev) {
            debugPrint(
              '📦 [AppProvider] Ignoring channel datagram type '
              '0x${dataType.toRadixString(16).padLeft(4, '0')} on channel $channelIdx',
            );
            return;
          }

          if (_handleFastGpsPayload(payload)) {
            return;
          }
          if (_handleIncomingImageBinaryPayload(
            payload,
            allowPreEnvelopeBuffer: true,
          )) {
            return;
          }
          if (_handleIncomingVoiceBinaryPayload(
            payload,
            allowPreEnvelopeBuffer: true,
          )) {
            return;
          }

          debugPrint(
            '📦 [AppProvider] Unknown developer channel payload on channel '
            '$channelIdx: ${payload.isNotEmpty ? payload.first : -1}',
          );
        };

    connectionProvider.onControlDataReceived =
        (payload, snrRaw, rssiDbm, pathLen) {
          _handleControlDataDiscovery(
            payload: payload,
            snrRaw: snrRaw,
            rssiDbm: rssiDbm,
            pathLen: pathLen,
          );
        };

    connectionProvider.onStatusResponse = (publicKeyPrefix, statusData) {
      final parsed = _tryParseRepeaterStatus(statusData);
      if (parsed == null) {
        return;
      }
      contactsProvider.updatePendingAdvertStatusByPrefix(
        publicKeyPrefix,
        batteryMv: parsed.batteryMv,
        queueLen: parsed.queueLen,
        lastRssi: parsed.lastRssi,
        lastSnrRaw: parsed.lastSnrRaw,
        uptimeSecs: parsed.uptimeSecs,
      );
    };

    // When a contact's routing path is updated in the mesh network
    connectionProvider.onPathUpdated = (publicKey) {
      debugPrint(
        '🔄 [AppProvider] Path updated for contact: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      if (connectionProvider.deviceInfo.isConnected) {
        unawaited(connectionProvider.getContact(publicKey));
      }
    };

    // When an advertisement is received (PUSH_CODE_ADVERT 0x80)
    //
    // Official app flow:
    // 1. importReceivedAdvert(key) — import advert into firmware contact table
    // 2. getContact(key) — check if contact existed before (for new-notification)
    // 3. syncContact(key) — fetch from device + upsert into DB
    // 4. getContact(key) — get fresh contact with name/type
    // 5. upsert into discovered_contacts
    // 6. if was new → notify with name + type
    connectionProvider.onAdvertReceived = (publicKey) {
      debugPrint(
        '📡 [AppProvider] Advertisement received: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      unawaited(_retainAdvertRxPath(publicKey));
      unawaited(_handlePushAdvert(publicKey));
    };

    // When firmware deletes a contact due to contacts table overflow (PUSH_CODE_CONTACT_DELETED 0x8F)
    connectionProvider.onContactDeleted = (publicKey) {
      final keyHex = publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      final contact = contactsProvider.findContactByKey(publicKey);
      final name = contact?.advName ?? keyHex.substring(0, 12);
      debugPrint('⚠️ [AppProvider] Contact deleted by firmware: $name');
      contactsProvider.removeContact(keyHex);
      messagesProvider.logSystemMessage(
        text: 'Contact "$name" was removed — device contacts table is full',
        level: 'warning',
      );
    };

    // When firmware reports contacts storage is full (PUSH_CODE_CONTACTS_FULL 0x90)
    connectionProvider.onContactsFull = () {
      debugPrint('⚠️ [AppProvider] Contacts storage full');
      messagesProvider.logSystemMessage(
        text:
            'Device contacts storage is full. New contacts will overwrite old ones.',
        level: 'warning',
      );
    };

    // When a message is sent (RESP_CODE_SENT received)
    connectionProvider
        .onMessageSent = (messageId, expectedAckTag, suggestedTimeoutMs) {
      debugPrint(
        '📤 [AppProvider] Message sent - Message ID: $messageId, ACK tag: $expectedAckTag',
      );
      messagesProvider.markMessageSent(
        messageId,
        expectedAckTag,
        suggestedTimeoutMs,
      );
    };

    // When a message is delivered (PUSH_CODE_SEND_CONFIRMED received)
    connectionProvider.onMessageDelivered = (ackCode, roundTripTimeMs) {
      debugPrint(
        '✅ [AppProvider] Message delivered - ACK: $ackCode, RTT: ${roundTripTimeMs}ms',
      );
      messagesProvider.markMessageDelivered(ackCode, roundTripTimeMs);
    };

    // When an echo is detected for a public channel message (PUSH_CODE_LOG_RX_DATA matched)
    connectionProvider
        .onMessageEchoDetected = (messageId, echoCount, snrRaw, rssiDbm) {
      debugPrint(
        '🔊 [AppProvider] Echo detected - Message: $messageId, Count: $echoCount',
      );
      messagesProvider.handleMessageEcho(messageId, echoCount, snrRaw, rssiDbm);
    };

    connectionProvider.prepareDirectMessageSendCallback =
        ({required messageId, required contact, required retryAttempt}) async {
          return _prepareDirectMessageSend(
            messageId: messageId,
            contact: contact,
          );
        };

    // Wire up MessagesProvider's sendMessageCallback for retry logic
    messagesProvider.sendMessageCallback =
        ({
          required contactPublicKey,
          required text,
          required messageId,
          required contact,
          retryAttempt = 0,
        }) async {
          return await connectionProvider.sendTextMessage(
            contactPublicKey: contactPublicKey,
            text: text,
            messageId: messageId,
            contact: contact,
            retryAttempt: retryAttempt,
          );
        };
    connectionProvider.resolveContactForDmCallback = (contactPublicKey) {
      return contactsProvider.findContactByKey(contactPublicKey);
    };
    // Reset path before the last retry attempt to force flood mode
    messagesProvider.resetPathBeforeLastRetryCallback = (contact) async {
      if (connectionProvider.deviceInfo.isConnected) {
        debugPrint(
          '🔄 [AppProvider] Resetting path for ${contact.advName} before last retry (flood fallback)',
        );
        await connectionProvider.resetPath(contact.publicKey);
      }
    };

    messagesProvider.onFinalRouterFallbackCallback =
        ({required messageId, required contact, required message}) async {
          return _sendWithFinalNearestRouterFallback(
            messageId: messageId,
            contact: contact,
            message: message,
          );
        };
    messagesProvider.onFinalDirectMessageFailureCallback =
        ({required messageId, required contact, required message}) async {
          await _handleDirectMessageFinalFailure(
            messageId: messageId,
            contact: contact,
          );
        };
    messagesProvider.onDirectMessageDeliveredCallback =
        ({
          required messageId,
          required contact,
          required message,
          required roundTripTimeMs,
        }) {
          _handleDirectMessageDelivered(
            messageId: messageId,
            contact: contact,
            roundTripTimeMs: roundTripTimeMs,
          );
        };
    messagesProvider.onManualRetryPreparedCallback = (messageId) {
      _directMessageRouteSessions.remove(messageId);
    };
  }

  Future<Contact> _prepareDirectMessageSend({
    required String messageId,
    required Contact contact,
  }) async {
    final latestContact =
        contactsProvider.findContactByKey(contact.publicKey) ?? contact;
    var session = _directMessageRouteSessions[messageId];
    if (session == null) {
      final selection = await _pathHistoryService.getSelectionForContact(
        latestContact,
        autoRouteRotationEnabled: _autoRouteRotationEnabled,
      );
      session = _DirectMessageRouteSession(
        currentSelection: selection,
        originalRoute: ContactRouteCodec.fromContact(latestContact),
        routerFallbackAttempted: false,
      );
      _directMessageRouteSessions[messageId] = session;
    }

    await _applyPathSelection(
      latestContact,
      session.currentSelection,
      messageId: messageId,
      routerFallbackAttempted: session.routerFallbackAttempted,
    );
    return contactsProvider.findContactByKey(contact.publicKey) ??
        latestContact;
  }

  Future<void> _applyPathSelection(
    Contact contact,
    PathSelection selection, {
    required String messageId,
    required bool routerFallbackAttempted,
  }) async {
    final previousRoute = ContactRouteCodec.fromContact(contact);

    try {
      if (selection.usesFlood) {
        contactsProvider.resetContactRouteLocal(contact.publicKey);
        if (connectionProvider.deviceInfo.isConnected) {
          await connectionProvider.resetPath(contact.publicKey);
        }
      } else {
        final pathDescriptor =
            ((selection.hashSize - 1) << 6) | (selection.hopCount & 0x3F);
        final signedDescriptor = ContactRouteCodec.toSignedDescriptor(
          pathDescriptor,
        );
        final paddedPathBytes = Uint8List(ContactRouteCodec.maxPathBytes)
          ..setRange(0, selection.pathBytes.length, selection.pathBytes);

        contactsProvider.setContactRouteLocal(
          contact.publicKey,
          signedEncodedPathLen: signedDescriptor,
          paddedPathBytes: paddedPathBytes,
        );
        if (connectionProvider.deviceInfo.isConnected) {
          await connectionProvider.setContactRoute(
            contact,
            signedEncodedPathLen: signedDescriptor,
            paddedPathBytes: paddedPathBytes,
          );
        }
      }
    } catch (error) {
      _restoreRouteLocal(contact.publicKey, previousRoute);
      rethrow;
    }

    messagesProvider.updateMessageRouteSelection(
      messageId,
      selection,
      routerFallbackAttempted: routerFallbackAttempted,
    );
  }

  void _restoreRouteLocal(Uint8List publicKey, ParsedContactRoute? route) {
    if (route == null) {
      contactsProvider.resetContactRouteLocal(publicKey);
      return;
    }

    contactsProvider.setContactRouteLocal(
      publicKey,
      signedEncodedPathLen: route.signedEncodedPathLen,
      paddedPathBytes: route.paddedPathBytes,
    );
  }

  Future<void> _restoreRouteOnDevice(
    Contact contact,
    ParsedContactRoute? route,
  ) async {
    _restoreRouteLocal(contact.publicKey, route);
    if (!connectionProvider.deviceInfo.isConnected) {
      return;
    }

    if (route == null) {
      await connectionProvider.resetPath(contact.publicKey);
      return;
    }

    await connectionProvider.setContactRoute(
      contact,
      signedEncodedPathLen: route.signedEncodedPathLen,
      paddedPathBytes: route.paddedPathBytes,
    );
  }

  PathSelection _buildNearestRouterSelection(Contact repeater, int hashSize) {
    return PathSelection(
      mode: PathSelectionMode.nearestRouter,
      pathBytes: Uint8List.fromList(repeater.publicKey.sublist(0, hashSize)),
      hopCount: 1,
      hashSize: hashSize,
      relayName: repeater.advName,
      relayKey6: _key6(repeater.publicKey),
    );
  }

  Future<bool> _sendWithFinalNearestRouterFallback({
    required String messageId,
    required Contact contact,
    required Message message,
  }) async {
    if (!_nearestRelayFallbackEnabled) {
      return false;
    }

    final latestContact =
        contactsProvider.findContactByKey(contact.publicKey) ?? contact;
    final session =
        _directMessageRouteSessions[messageId] ??
        _DirectMessageRouteSession(
          currentSelection: latestContact.routeHasPath
              ? PathSelection(
                  mode: PathSelectionMode.directCurrent,
                  pathBytes: Uint8List.fromList(latestContact.routePathBytes),
                  hopCount: latestContact.routeHopCount,
                  hashSize: latestContact.routeHashSize,
                )
              : PathSelection.flood(),
          originalRoute: ContactRouteCodec.fromContact(latestContact),
          routerFallbackAttempted: false,
        );

    await _pathHistoryService.recordPathResult(
      latestContact.publicKeyHex,
      session.currentSelection,
      success: false,
    );

    final repeater = _nearestRouterSelector.select(
      senderPosition: locationTrackingService.currentPosition,
      repeaters: contactsProvider.repeaters,
      recipient: latestContact,
    );
    if (repeater == null) {
      return false;
    }

    final routeHashSize = await RouteHashPreferences.getHashSize();
    final fallbackSelection = _buildNearestRouterSelection(
      repeater,
      routeHashSize,
    );
    _directMessageRouteSessions[messageId] = session.copyWith(
      currentSelection: fallbackSelection,
      routerFallbackAttempted: true,
    );
    messagesProvider.updateMessageRouteSelection(
      messageId,
      fallbackSelection,
      routerFallbackAttempted: true,
    );

    return connectionProvider.sendTextMessage(
      contactPublicKey: latestContact.publicKey,
      text: message.text,
      messageId: messageId,
      contact: latestContact,
      retryAttempt: message.retryAttempt + 1,
    );
  }

  void _handleDirectMessageDelivered({
    required String messageId,
    required Contact contact,
    required int roundTripTimeMs,
  }) {
    final session = _directMessageRouteSessions.remove(messageId);
    if (session == null) {
      return;
    }

    unawaited(
      _pathHistoryService.recordPathResult(
        contact.publicKeyHex,
        session.currentSelection,
        success: true,
        roundTripTimeMs: roundTripTimeMs,
      ),
    );
  }

  Future<void> _handleDirectMessageFinalFailure({
    required String messageId,
    required Contact contact,
  }) async {
    final latestContact =
        contactsProvider.findContactByKey(contact.publicKey) ?? contact;
    final session = _directMessageRouteSessions.remove(messageId);
    if (session != null) {
      await _pathHistoryService.recordPathResult(
        latestContact.publicKeyHex,
        session.currentSelection,
        success: false,
      );
      if (session.routerFallbackAttempted) {
        await _restoreRouteOnDevice(latestContact, session.originalRoute);
      }
    }

    if (_clearPathOnMaxRetry) {
      contactsProvider.resetContactRouteLocal(latestContact.publicKey);
      if (connectionProvider.deviceInfo.isConnected) {
        await connectionProvider.resetPath(latestContact.publicKey);
        if (connectionProvider.deviceInfo.isConnected) {
          await connectionProvider.getContact(latestContact.publicKey);
        }
      }
    }
  }

  String _key6(Uint8List publicKey) {
    final bytes = publicKey.sublist(0, math.min(6, publicKey.length));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Estimate contact location from the received message path.
  ///
  /// When we receive a message, the path bytes describe how it traveled:
  ///   Sender → first_hop (near sender) → ... → last_hop (near us) → Us
  ///
  /// The FIRST hop in the received path is the repeater nearest to the sender.
  /// We don't have the actual RSSI between sender and that repeater, so we
  /// use a conservative estimate to place them within typical LoRa range.
  void _estimateContactLocationFromReceivedPath({
    required Contact contact,
    required List<int> receivedPathBytes,
  }) {
    if (receivedPathBytes.isEmpty) return;

    // Infer hash size from the contact's known path encoding, or default to 1
    final hashSize = contact.routeHasPath ? contact.routeHashSize : 1;
    if (receivedPathBytes.length < hashSize) return;

    // First hop in received path = repeater nearest to sender
    final firstHopHash = receivedPathBytes
        .sublist(0, hashSize)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();

    Contact? nearSenderRepeater;
    for (final c in contactsProvider.contacts) {
      if (c.publicKeyHex.toLowerCase().startsWith(firstHopHash) &&
          c.displayLocation != null) {
        nearSenderRepeater = c;
        break;
      }
    }
    if (nearSenderRepeater == null) return;

    // We don't have the RSSI between sender and their repeater.
    // Use -70 dBm as conservative estimate (~300m in open terrain).
    const int estimatedRssi = -70;

    contactsProvider.addRssiObservation(
      contactPublicKeyHex: contact.publicKeyHex,
      contactPublicKey: contact.publicKey,
      observation: RssiObservation(
        repeaterLocation: nearSenderRepeater.displayLocation!,
        rssiDbm: estimatedRssi,
        observedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _learnPathFromPublicMessage({
    required Contact contact,
    required List<int> pathBytes,
  }) async {
    final preferred = await RouteHashPreferences.getHashSize();
    final inferredHashSize = _inferReceivedPathHashSize(
      pathBytes,
      preferredHashSize: preferred,
    );
    await _pathHistoryService.recordReceivedBytePath(
      contact.publicKeyHex,
      pathBytes,
      inferredHashSize,
    );
  }

  Future<void> _retainAdvertRxPath(Uint8List publicKey) async {
    final decoded = _findBestMatchingAdvertRxRoute(publicKey);
    if (decoded == null || decoded.pathBytes.isEmpty) {
      return;
    }

    final reversedPathBytes = LogRxRouteDecoder.reverseHopBytes(
      decoded.pathBytes,
      hashSize: decoded.hashSize,
    );
    final reversedHopHashes = LogRxRouteDecoder.splitHopHashes(
      reversedPathBytes,
      hashSize: decoded.hashSize,
    );

    final parsedRoute = ContactRouteCodec.parse(
      reversedHopHashes.join(','),
      expectedHashSize: decoded.hashSize,
    );
    contactsProvider.retainReceivedRoute(
      publicKey,
      signedEncodedPathLen: parsedRoute.signedEncodedPathLen,
      paddedPathBytes: parsedRoute.paddedPathBytes,
      devicePublicKey: connectionProvider.deviceInfo.publicKey,
    );
    await _pathHistoryService.recordReceivedBytePath(
      publicKey.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      decoded.pathBytes,
      decoded.hashSize,
    );
  }

  /// Handle pushAdvert (0x80) — matches the official MeshCore app flow:
  ///
  /// 1. importReceivedAdvert(key) — import advert into firmware contact table
  /// 2. Check if contact was already known locally (for new-notification)
  /// 3. getContact(key) — fetch full contact from device (now stored after import)
  ///    → flows through onContactReceivedDetailed which upserts + notifies
  Future<void> _handlePushAdvert(Uint8List publicKey) async {
    // Step 1: Import the advert into firmware's contact table.
    // This tells the firmware to store the contact from its received-advert
    // buffer, making subsequent getContact return name/type/location.
    await connectionProvider.importReceivedAdvert(publicKey);

    // Step 2: Check if this was an already-known contact before sync
    final wasKnown = contactsProvider.findContactByKey(publicKey) != null;

    // Step 3: Fetch the full contact from device (import made it available).
    // This flows through onContactReceivedDetailed, which handles:
    // - upserting into contacts or pending adverts
    // - showing discovery notification for new contacts
    if (connectionProvider.deviceInfo.isConnected) {
      await connectionProvider.getContact(publicKey);
    }

    // For existing contacts, the getContact above already updated them.
    // For new contacts from adverts, onContactReceivedDetailed (source=advert)
    // already added to pending adverts and showed notification.
    // Nothing else to do — the callback pipeline handles everything.
    if (wasKnown) {
      debugPrint('   [pushAdvert] Existing contact refreshed');
    }
  }

  Future<void> _requestRepeaterStatus(Uint8List publicKey) async {
    if (!connectionProvider.deviceInfo.isConnected) {
      return;
    }
    final keyHex = publicKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final now = DateTime.now();
    final lastRequestAt = _recentRepeaterStatusRequests[keyHex];
    if (lastRequestAt != null &&
        now.difference(lastRequestAt) < const Duration(minutes: 2)) {
      return;
    }
    _recentRepeaterStatusRequests[keyHex] = now;
    try {
      await connectionProvider.requestStatus(publicKey);
    } catch (_) {
      // Ignore unsupported or unreachable repeaters.
    }
  }

  Future<void> _maybeRequestRepeaterOwnerInfo(Uint8List publicKey) async {
    final pendingAdvert = contactsProvider.pendingAdvertByKey(publicKey);
    if (pendingAdvert == null ||
        pendingAdvert.typeValue != ContactType.repeater.value ||
        pendingAdvert.advName?.trim().isNotEmpty == true ||
        !connectionProvider.deviceInfo.isConnected) {
      return;
    }

    final keyHex = pendingAdvert.publicKeyHex;
    final now = DateTime.now();
    final lastRequestAt = _recentRepeaterOwnerInfoRequests[keyHex];
    if (lastRequestAt != null &&
        now.difference(lastRequestAt) < _repeaterOwnerInfoRequestCooldown) {
      return;
    }

    Contact? existingContact;
    for (final contact in contactsProvider.contacts) {
      if (contact.publicKeyHex == keyHex) {
        existingContact = contact;
        break;
      }
    }

    var temporaryContactAdded = false;
    final requestContact =
        existingContact ?? _temporaryRepeaterContactForOwnerInfo(pendingAdvert);
    if (requestContact == null || !requestContact.routeHasPath) {
      return;
    }

    _recentRepeaterOwnerInfoRequests[keyHex] = now;

    if (existingContact == null) {
      connectionProvider.clearError();
      await connectionProvider.addOrUpdateContact(requestContact);
      if (connectionProvider.error != null) {
        return;
      }
      connectionProvider.clearError();
      temporaryContactAdded = true;
    }

    try {
      final ticket = await connectionProvider.sendAnonRequest(
        contactPublicKey: publicKey,
        requestData: _buildRepeaterOwnerRequest(requestContact),
      );
      if (ticket == null) {
        return;
      }
      _pendingRepeaterOwnerRequests[ticket.tag] = _PendingRepeaterOwnerRequest(
        publicKey: Uint8List.fromList(publicKey),
      );
      Future.delayed(
        Duration(milliseconds: ticket.suggestedTimeoutMs + 1500),
        () => _pendingRepeaterOwnerRequests.remove(ticket.tag),
      );
    } catch (_) {
      // Ignore unsupported or unreachable repeaters.
    } finally {
      if (temporaryContactAdded) {
        Future.delayed(const Duration(milliseconds: 250), () async {
          await connectionProvider.removeContact(publicKey);
          connectionProvider.clearError();
        });
      }
    }
  }

  Contact? _temporaryRepeaterContactForOwnerInfo(PendingAdvert advert) {
    final signedEncodedPathLen = advert.signedEncodedPathLen;
    if (signedEncodedPathLen == null) {
      return null;
    }

    final advName = advert.advName?.trim();
    final lastAdvert =
        advert.lastAdvert ?? (advert.receivedAt.millisecondsSinceEpoch ~/ 1000);
    return Contact(
      publicKey: Uint8List.fromList(advert.publicKey),
      type: ContactType.repeater,
      flags: advert.flags ?? 0,
      outPathLen: signedEncodedPathLen,
      outPath: advert.paddedPathBytes == null
          ? Uint8List(ContactRouteCodec.maxPathBytes)
          : Uint8List.fromList(advert.paddedPathBytes!),
      advName: advName?.isNotEmpty == true ? advName! : advert.shortDisplayKey,
      lastAdvert: lastAdvert,
      advLat: advert.advLat ?? 0,
      advLon: advert.advLon ?? 0,
      lastMod: lastAdvert,
    );
  }

  Uint8List _buildRepeaterOwnerRequest(Contact contact) {
    final replyPathDescriptor = contact.routeEncodedPathLen;
    final replyPathBytes = contact.routeHopCount > 0
        ? Uint8List.fromList(
            LogRxRouteDecoder.reverseHopBytes(
              contact.routePathBytes,
              hashSize: contact.routeHashSize,
            ),
          )
        : Uint8List(0);
    return Uint8List.fromList([
      _anonReqTypeOwner,
      replyPathDescriptor,
      ...replyPathBytes,
    ]);
  }

  bool _handlePendingRepeaterOwnerResponse(int tag, Uint8List responseData) {
    final request = _pendingRepeaterOwnerRequests.remove(tag);
    if (request == null) {
      return false;
    }

    final ownerName = _tryParseRepeaterOwnerName(responseData);
    if (ownerName == null || ownerName.isEmpty) {
      return true;
    }

    final existing = contactsProvider.pendingAdvertByKey(request.publicKey);
    contactsProvider.addOrUpdatePendingAdvertMetadata(
      publicKey: request.publicKey,
      typeValue: existing?.typeValue ?? ContactType.repeater.value,
      devicePublicKey: connectionProvider.deviceInfo.publicKey,
      advName: ownerName,
    );
    return true;
  }

  String? _tryParseRepeaterOwnerName(Uint8List responseData) {
    if (responseData.length <= 4) {
      return null;
    }

    try {
      final payload = utf8
          .decode(responseData.sublist(4), allowMalformed: true)
          .trim();
      if (payload.isEmpty) {
        return null;
      }
      final firstLine = payload.split(RegExp(r'[\r\n]+')).first.trim();
      return firstLine.isEmpty ? null : firstLine;
    } catch (_) {
      return null;
    }
  }

  _ParsedRepeaterStatus? _tryParseRepeaterStatus(Uint8List statusData) {
    if (statusData.length < 52) {
      return null;
    }

    try {
      final data = ByteData.sublistView(statusData);
      var offset = 0;
      final batteryMv = data.getUint16(offset, Endian.little);
      offset += 2;
      final queueLen = data.getUint16(offset, Endian.little);
      offset += 2;
      offset += 2; // noiseFloor
      final lastRssi = data.getInt16(offset, Endian.little);
      offset += 2;
      offset += 4; // packetsRecv
      offset += 4; // packetsSent
      offset += 4; // txAirSecs
      final uptimeSecs = data.getUint32(offset, Endian.little);
      offset += 4;
      offset += 4; // floodTx
      offset += 4; // directTx
      offset += 4; // floodRx
      offset += 4; // directRx
      offset += 2; // errEvents
      final lastSnrRaw = data.getInt16(offset, Endian.little);

      return _ParsedRepeaterStatus(
        batteryMv: batteryMv,
        queueLen: queueLen,
        lastRssi: lastRssi,
        lastSnrRaw: lastSnrRaw,
        uptimeSecs: uptimeSecs,
      );
    } catch (_) {
      return null;
    }
  }

  _ParsedRawAdvert? _tryParseRawAdvert(Uint8List rawPayload) {
    if (rawPayload.length < 103) {
      return null;
    }

    try {
      final reader = BufferReader(rawPayload);
      final header = reader.readByte();
      final routeType = header & 0x03;
      final payloadType = (header >> 2) & 0x0F;
      if (payloadType != _rawPayloadTypeAdvert) {
        return null;
      }

      if (routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect) {
        if (reader.remainingBytesCount < 4) {
          return null;
        }
        reader.skip(4);
      }

      if (reader.remainingBytesCount < 1) {
        return null;
      }
      final pathByteLen = reader.readByte();
      if (reader.remainingBytesCount < pathByteLen + 101) {
        return null;
      }
      final pathBytes = reader.readBytes(pathByteLen);
      final publicKey = reader.readBytes(32);
      final timestamp = reader.readInt32LE();
      reader.skip(64);
      final flags = reader.readByte();
      final typeValue = flags & 0x0F;
      final hasLocation = (flags & 0x10) != 0;
      final hasName = (flags & 0x80) != 0;

      int? advLat;
      int? advLon;
      if (hasLocation) {
        if (reader.remainingBytesCount < 8) {
          return null;
        }
        advLat = reader.readInt32LE();
        advLon = reader.readInt32LE();
      }

      String? advName;
      if (hasName && reader.remainingBytesCount > 0) {
        final decodedName = utf8
            .decode(reader.readRemainingBytes(), allowMalformed: true)
            .trim();
        if (decodedName.isNotEmpty) {
          advName = decodedName;
        }
      }

      int? signedEncodedPathLen;
      Uint8List? paddedPathBytes;
      if (pathBytes.isNotEmpty) {
        final hashSize = LogRxRouteDecoder.inferHashSize(pathBytes);
        final reversedPathBytes = LogRxRouteDecoder.reverseHopBytes(
          pathBytes,
          hashSize: hashSize,
        );
        final padded = Uint8List(ContactRouteCodec.maxPathBytes)
          ..setRange(0, reversedPathBytes.length, reversedPathBytes);
        final encodedPathLen =
            ((hashSize - 1) << 6) |
            ((reversedPathBytes.length ~/ hashSize) & 0x3F);
        signedEncodedPathLen = ContactRouteCodec.toSignedDescriptor(
          encodedPathLen,
        );
        paddedPathBytes = padded;
      }

      return _ParsedRawAdvert(
        publicKey: publicKey,
        advName: advName,
        typeValue: typeValue,
        flags: flags,
        lastAdvert: timestamp,
        advLat: advLat,
        advLon: advLon,
        signedEncodedPathLen: signedEncodedPathLen,
        paddedPathBytes: paddedPathBytes,
      );
    } catch (_) {
      return null;
    }
  }

  int _inferReceivedPathHashSize(
    List<int> pathBytes, {
    required int preferredHashSize,
  }) {
    final preferred = preferredHashSize;
    final candidates = {preferred, 3, 2, 1}.toList();
    for (final candidate in candidates) {
      if (candidate >= 1 &&
          candidate <= 3 &&
          pathBytes.length % candidate == 0) {
        return candidate;
      }
    }
    return 1;
  }

  /// Initialize the app (load contacts, sync time, etc.)
  Future<void> initialize() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      _isReconnectSyncInProgress = true;
      _hasCompletedConnectionBootstrap = false;
      await contactsProvider.prepareForDeviceContactSync(
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
      channelsProvider.prepareForDeviceSync();

      // Note: Device clock is automatically synced during connection in MeshCoreBleService
      // No need to sync it again here

      // Get battery and storage information
      await connectionProvider.getBatteryAndStorage();

      // Load contacts (waits for device to finish sending all contacts)
      await connectionProvider.getContacts();

      // Sync all channels so slot assignment and channel state mirror the device.
      final channelsToSync = connectionProvider.deviceInfo.maxChannels;
      debugPrint(
        '📻 [AppProvider] Syncing channels (max: ${channelsToSync ?? 40})...',
      );
      await connectionProvider.syncChannels(maxChannels: channelsToSync);
      debugPrint('✅ [AppProvider] Channel sync complete');

      // Automatically login to all saved rooms
      await _autoLoginToRooms();

      // FALLBACK: Sync messages once after connection to catch any missed push notifications
      // This handles the case where messages arrived while the app was disconnected
      debugPrint(
        '🔄 [AppProvider] Performing initial message sync (fallback for missed pushes)',
      );
      final initialMessageCount = await connectionProvider.syncAllMessages(
        force: true,
      );
      debugPrint(
        '📥 [AppProvider] Initial sync retrieved $initialMessageCount message(s)',
      );

      // Note: Future messages are synced automatically via PUSH_CODE_MSG_WAITING events

      // Start location tracking AFTER all initialization is complete
      debugPrint(
        '📍 [AppProvider] Starting location tracking after successful initialization',
      );
      await _startLocationTracking();

      // Sync drawing messages with DrawingProvider
      // This restores any drawings that may be missing from storage
      debugPrint(
        '🎨 [AppProvider] Syncing drawing messages with DrawingProvider...',
      );
      messagesProvider.syncDrawingsWithProvider(drawingProvider);

      _hasCompletedConnectionBootstrap = true;
      _wasDeviceConnected = connectionProvider.deviceInfo.isConnected;
      await _flushDeferredAutomaticMessageSync();
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      _isReconnectSyncInProgress = false;
    }
  }

  Future<void> _syncAfterReconnect({bool started = false}) async {
    if (!connectionProvider.deviceInfo.isConnected) {
      return;
    }

    if (!started) {
      if (_isReconnectSyncInProgress) {
        return;
      }
      _isReconnectSyncInProgress = true;
    }
    try {
      debugPrint(
        '🔄 [AppProvider] Device reconnected - syncing contacts and missed messages',
      );

      await contactsProvider.prepareForDeviceContactSync(
        devicePublicKey: connectionProvider.deviceInfo.publicKey,
      );
      channelsProvider.prepareForDeviceSync();
      await connectionProvider.getContacts();
      await connectionProvider.syncChannels(
        maxChannels: connectionProvider.deviceInfo.maxChannels,
      );

      final messageCount = await connectionProvider.syncAllMessages(
        force: true,
      );
      debugPrint(
        '📥 [AppProvider] Reconnect sync retrieved $messageCount message(s)',
      );
    } catch (e) {
      debugPrint('❌ [AppProvider] Reconnect sync error: $e');
    } finally {
      _hasCompletedConnectionBootstrap =
          connectionProvider.deviceInfo.isConnected;
      _isReconnectSyncInProgress = false;
      await _flushDeferredAutomaticMessageSync();
    }
  }

  /// Automatically login to all rooms with saved passwords on cold connect
  Future<void> _autoLoginToRooms() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Get all room contacts (excluding Public Channel)
      final rooms = contactsProvider.rooms
          .where((room) => !room.isPublicChannel)
          .toList();

      if (rooms.isEmpty) {
        debugPrint('📂 [AppProvider] No rooms found to auto-login');
        return;
      }

      debugPrint(
        '📂 [AppProvider] Found ${rooms.length} room(s), attempting auto-login...',
      );

      final prefs = await SharedPreferences.getInstance();

      for (final room in rooms) {
        try {
          // Load saved password for this room
          final roomKey = 'room_password_${room.publicKeyHex}';
          final savedPassword = prefs.getString(roomKey) ?? 'hello';

          debugPrint(
            '🔑 [AppProvider] Auto-logging into room: ${room.advName}',
          );

          // Set up one-time callbacks for this room login
          await _loginToRoomWithCallback(room, savedPassword);

          // Small delay between logins to avoid overwhelming the device
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint(
            '❌ [AppProvider] Failed to auto-login to ${room.advName}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AppProvider] Auto-login error: $e');
    }
  }

  /// Login to a specific room with callback handling
  Future<void> _loginToRoomWithCallback(Contact room, String password) async {
    // Create a completer to wait for login result
    final completer = Completer<bool>();

    // Store original callbacks
    final originalOnSuccess = connectionProvider.onLoginSuccess;
    final originalOnFail = connectionProvider.onLoginFail;

    // Set up temporary callbacks
    connectionProvider
        .onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint('✅ [AppProvider] Auto-login successful for ${room.advName}');
      debugPrint(
        '📡 [AppProvider] Room server will push messages automatically via PUSH_CODE_MSG_WAITING',
      );

      completer.complete(true);
    };

    connectionProvider.onLoginFail = (publicKeyPrefix) {
      // Restore original callbacks
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      debugPrint(
        '❌ [AppProvider] Auto-login failed for ${room.advName} (incorrect password)',
      );
      completer.complete(false);
    };

    try {
      // Send login request
      await connectionProvider.loginToRoom(
        roomPublicKey: room.publicKey,
        password: password,
      );

      // Wait for login result with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Restore callbacks on timeout
          connectionProvider.onLoginSuccess = originalOnSuccess;
          connectionProvider.onLoginFail = originalOnFail;
          debugPrint('⏱️ [AppProvider] Auto-login timeout for ${room.advName}');
          return false;
        },
      );
    } catch (e) {
      // Restore callbacks on error
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;
      debugPrint(
        '❌ [AppProvider] Error during auto-login to ${room.advName}: $e',
      );
    }
  }

  Contact? _resolveContactByPrefixHex(String prefixHex) {
    if (prefixHex.length != 12) return null;
    return contactsProvider.findContactByPrefixHex(prefixHex.toLowerCase());
  }

  void setFastLocationUiActive(bool isActive) {
    if (_fastLocationScreenActive == isActive) return;
    _fastLocationScreenActive = isActive;
    locationTrackingService.setFastLocationActiveUse(isActive);
  }

  Future<void> reloadProfileScopedSettings() async {
    await Future.wait([
      _loadMapEnabled(),
      _loadContactsEnabled(),
      _loadContactsSectionVisibility(),
      _loadSensorsEnabled(),
      _loadVoiceSilenceTrimmingEnabled(),
      _loadVoiceBandPassFilterEnabled(),
      _loadVoiceCompressorEnabled(),
      _loadVoiceLimiterEnabled(),
      _loadVoiceAutoGainEnabled(),
      _loadVoiceEchoCancellationEnabled(),
      _loadVoiceNoiseSuppressionEnabled(),
      _loadMessageFontScale(),
      _loadMessagingRouteSettings(),
      locationTrackingService.loadSettings(),
    ]);
  }

  Future<void> _sendFastLocationUpdate(
    dynamic position, {
    required String reason,
  }) async {
    if (!connectionProvider.deviceInfo.isConnected) {
      return;
    }

    final channelIdx = locationTrackingService.fastLocationChannelIdx;
    if (channelIdx == null) {
      return;
    }

    final hasTargetChannel = contactsProvider.channels.any(
      (channel) =>
          (channel.publicKey.length > 1 ? channel.publicKey[1] : 0) ==
          channelIdx,
    );
    if (!hasTargetChannel) {
      debugPrint(
        '⚠️ [AppProvider] Fast GPS target channel $channelIdx is unavailable',
      );
      return;
    }

    final publicKey = connectionProvider.deviceInfo.publicKey;
    if (publicKey == null || publicKey.length < 6) {
      return;
    }

    final senderKey6 = publicKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final packet = FastGpsPacket(
      senderKey6: senderKey6,
      latitude: position.latitude as double,
      longitude: position.longitude as double,
      timestampSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    debugPrint(
      '📍 [AppProvider] Sending fast GPS update ($reason): '
      '${position.latitude}, ${position.longitude} via channel $channelIdx',
    );
    try {
      await connectionProvider.sendChannelData(
        channelIdx: channelIdx,
        dataType: MeshCoreConstants.dataTypeDev,
        payload: packet.encodeBinary(),
      );
    } catch (e) {
      debugPrint('⚠️ [AppProvider] Fast GPS send failed: $e');
    }
  }

  Contact? _resolveVoiceFetchRequester(VoiceFetchRequest request) {
    final liveContact = _resolveContactByPrefixHex(request.requesterKey6);
    if (liveContact != null) {
      return liveContact;
    }

    return _resolveRequesterFromSentMessages(
      sessionId: request.sessionId,
      requesterKey6: request.requesterKey6,
      tryParseEnvelope: VoiceEnvelope.tryParseText,
      mediaLabel: 'voice',
    );
  }

  Contact? _resolveImageFetchRequester(ImageFetchRequest request) {
    final liveContact = _resolveContactByPrefixHex(request.requesterKey6);
    if (liveContact != null) {
      return liveContact;
    }

    return _resolveRequesterFromSentMessages(
      sessionId: request.sessionId,
      requesterKey6: request.requesterKey6,
      tryParseEnvelope: ImageEnvelope.tryParse,
      mediaLabel: 'image',
    );
  }

  Contact? _resolveRequesterFromSentMessages<T>({
    required String sessionId,
    required String requesterKey6,
    required T? Function(String text) tryParseEnvelope,
    required String mediaLabel,
  }) {
    for (final message in messagesProvider.messages.reversed) {
      final envelope = tryParseEnvelope(message.text);
      if (envelope == null) {
        continue;
      }
      final envelopeSessionId = switch (envelope) {
        VoiceEnvelope voiceEnvelope => voiceEnvelope.sessionId,
        ImageEnvelope imageEnvelope => imageEnvelope.sessionId,
        _ => null,
      };
      if (envelopeSessionId != sessionId) {
        continue;
      }
      final recipientKey = message.recipientPublicKey;
      if (recipientKey == null || recipientKey.isEmpty) {
        continue;
      }
      final recipient = contactsProvider.findContactByKey(recipientKey);
      if (recipient == null) {
        continue;
      }
      final recipientKey6 = recipient.publicKey
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (recipientKey6 != requesterKey6) {
        continue;
      }
      debugPrint(
        '${mediaLabel == 'voice' ? '🎙️' : '📷'} [AppProvider] Resolved '
        '$mediaLabel requester from sent message metadata for session '
        '$sessionId: ${recipient.advName}',
      );
      return recipient;
    }

    return null;
  }

  String _mediaSwarmKey(String mediaType, String sessionId) =>
      '$mediaType:$sessionId';

  String? _deviceKey6Hex() {
    final deviceKey = connectionProvider.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      return null;
    }
    return deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  List<int> _availableIndicesForSession(String mediaType, String sessionId) {
    return switch (mediaType) {
      'voice' => voiceProvider.availablePacketIndices(sessionId),
      'image' => imageProvider.availableFragmentIndices(sessionId),
      _ => const <int>[],
    };
  }

  List<int> _matchingAvailableIndices(MediaSwarmRequest request) {
    final available = _availableIndicesForSession(
      request.mediaType,
      request.sessionId,
    );
    if (available.isEmpty) return const [];
    if (request.requestsAll) return available;
    final requested = request.missingIndices.toSet();
    return available.where(requested.contains).toList()..sort();
  }

  List<Contact> _eligibleSwarmPeers({String? excludeKey6}) {
    final ownKey6 = _deviceKey6Hex();
    return contactsProvider.contacts.where((contact) {
      if (!contact.routeHasPath ||
          contact.routeHopCount > _maxDirectPayloadHops ||
          !contact.routeSupportsLegacyRawTransport ||
          contact.outPath.isEmpty ||
          contact.publicKey.length < 6) {
        return false;
      }
      final key6 = contact.publicKey
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      if (key6 == ownKey6 || key6 == excludeKey6) {
        return false;
      }
      return true;
    }).toList();
  }

  void _handleIncomingMediaSwarmRequest(MediaSwarmRequest request) {
    final ownKey6 = _deviceKey6Hex();
    if (ownKey6 == null || request.requesterKey6 == ownKey6) {
      return;
    }

    final available = _matchingAvailableIndices(request);
    if (available.isEmpty) {
      return;
    }

    final availability = MediaSwarmAvailability(
      mediaType: request.mediaType,
      sessionId: request.sessionId,
      requesterKey6: request.requesterKey6,
      responderKey6: ownKey6,
      availableIndices: available,
    );

    debugPrint(
      '🌐 [AppProvider] Media swarm availability for ${request.mediaType} '
      '${request.sessionId}: ${available.length} fragment(s)',
    );
    final requester = _resolveContactByPrefixHex(request.requesterKey6);
    if (requester == null ||
        !requester.routeHasPath ||
        requester.routeHopCount > _maxDirectPayloadHops ||
        requester.outPath.isEmpty) {
      return;
    }
    unawaited(
      connectionProvider.sendRawVoicePacket(
        contactPath: requester.outPath,
        contactPathLen: requester.routeEncodedPathLen,
        payload: availability.encodeBinary(),
      ),
    );
  }

  void _handleIncomingMediaSwarmAvailability(
    MediaSwarmAvailability availability,
  ) {
    final ownKey6 = _deviceKey6Hex();
    if (ownKey6 == null || availability.requesterKey6 != ownKey6) {
      return;
    }

    final key = _mediaSwarmKey(availability.mediaType, availability.sessionId);
    final responses = _pendingMediaSwarmResponses[key];
    if (responses == null) {
      return;
    }
    responses[availability.responderKey6] = availability;
    debugPrint(
      '🌐 [AppProvider] Media swarm response for ${availability.mediaType} '
      '${availability.sessionId} from ${availability.responderKey6} '
      '(${availability.servesAll ? 'all' : availability.availableIndices.length})',
    );
  }

  Future<bool> _requestMissingMediaViaSwarm({
    required String mediaType,
    required String sessionId,
    required List<int> missingIndices,
    required String? originalSenderKey6,
  }) async {
    if (!connectionProvider.deviceInfo.isConnected || missingIndices.isEmpty) {
      return false;
    }

    final key = _mediaSwarmKey(mediaType, sessionId);
    final pending = _pendingMediaSwarmFetches[key];
    if (pending != null) {
      return pending;
    }

    final requesterKey6 = _deviceKey6Hex();
    if (requesterKey6 == null) {
      return false;
    }

    final future = () async {
      final responses = <String, MediaSwarmAvailability>{};
      _pendingMediaSwarmResponses[key] = responses;

      try {
        final request = MediaSwarmRequest(
          mediaType: mediaType,
          sessionId: sessionId,
          requesterKey6: requesterKey6,
          missingIndices: missingIndices,
        );
        final peers = _eligibleSwarmPeers(excludeKey6: originalSenderKey6);
        if (peers.isEmpty) {
          return false;
        }
        debugPrint(
          '🌐 [AppProvider] Media swarm request for $mediaType $sessionId '
          '(${missingIndices.length} needed fragment(s), ${peers.length} peer(s))',
        );
        for (final peer in peers) {
          await connectionProvider.sendRawVoicePacket(
            contactPath: peer.outPath,
            contactPathLen: peer.routeEncodedPathLen,
            payload: request.encodeBinary(),
          );
        }

        await Future<void>.delayed(_mediaSwarmResponseWindow);
        final orderedResponses =
            responses.values
                .where(
                  (response) => response.responderKey6 != originalSenderKey6,
                )
                .toList()
              ..sort((a, b) {
                final aScore = _swarmResponseScore(a, missingIndices);
                final bScore = _swarmResponseScore(b, missingIndices);
                return bScore.compareTo(aScore);
              });

        for (final response in orderedResponses) {
          final responder = _resolveContactByPrefixHex(response.responderKey6);
          if (responder == null ||
              !responder.routeHasPath ||
              responder.routeHopCount > _maxDirectPayloadHops ||
              responder.outPath.isEmpty) {
            continue;
          }

          final requestedSubset = response.servesAll
              ? missingIndices
              : missingIndices
                    .where(response.availableIndices.toSet().contains)
                    .toList();
          if (requestedSubset.isEmpty) {
            continue;
          }

          final requestedSet = requestedSubset.toSet();
          final sent = await _sendDirectMediaFetchRequest(
            mediaType: mediaType,
            sessionId: sessionId,
            target: responder,
            requesterKey6: requesterKey6,
            missingIndices: requestedSet,
          );
          if (sent) {
            debugPrint(
              '🌐 [AppProvider] Requested $mediaType $sessionId '
              'from swarm peer ${responder.advName} '
              '(${requestedSubset.length} fragment(s))',
            );
            return true;
          }
        }

        return false;
      } catch (e) {
        debugPrint(
          '⚠️ [AppProvider] Media swarm request failed for $mediaType '
          '$sessionId: $e',
        );
        return false;
      } finally {
        _pendingMediaSwarmResponses.remove(key);
      }
    }();

    _pendingMediaSwarmFetches[key] = future;
    try {
      return await future;
    } finally {
      _pendingMediaSwarmFetches.remove(key);
    }
  }

  int _swarmResponseScore(
    MediaSwarmAvailability response,
    List<int> missingIndices,
  ) {
    if (response.servesAll) {
      return missingIndices.length;
    }
    final needed = missingIndices.toSet();
    return response.availableIndices.where(needed.contains).length;
  }

  Future<bool> _sendDirectMediaFetchRequest({
    required String mediaType,
    required String sessionId,
    required Contact target,
    required String requesterKey6,
    required Set<int> missingIndices,
  }) async {
    try {
      final payload = switch (mediaType) {
        'voice' => VoiceFetchRequest(
          sessionId: sessionId,
          want: missingIndices.isEmpty ? 'all' : 'missing',
          missingIndices: missingIndices.toList()..sort(),
          requesterKey6: requesterKey6,
        ).encodeBinary(),
        'image' => ImageFetchRequest(
          sessionId: sessionId,
          want: missingIndices.isEmpty ? 'all' : 'missing',
          missingIndices: missingIndices.toList()..sort(),
          requesterKey6: requesterKey6,
        ).encodeBinary(),
        _ => null,
      };
      if (payload == null) {
        return false;
      }

      await connectionProvider.sendRawVoicePacket(
        contactPath: target.outPath,
        contactPathLen: target.routeEncodedPathLen,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint(
        '⚠️ [AppProvider] Direct $mediaType fetch via ${target.advName} failed: $e',
      );
      return false;
    }
  }

  void _scheduleVoiceMissingRetry(
    String sessionId, {
    required bool justComplete,
  }) {
    if (voiceProvider.isReceiveCanceled(sessionId)) {
      _clearVoiceMissingRetry(sessionId);
      return;
    }
    if (justComplete || voiceProvider.isComplete(sessionId)) {
      _clearVoiceMissingRetry(sessionId);
      return;
    }

    _voiceMissingRetryAttempts[sessionId] = 0;
    _voiceMissingRetryTimers[sessionId]?.cancel();
    _voiceMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingVoicePackets(sessionId));
    });
  }

  void _scheduleImageMissingRetry(
    String sessionId, {
    required bool justComplete,
  }) {
    if (imageProvider.isReceiveCanceled(sessionId)) {
      _clearImageMissingRetry(sessionId);
      return;
    }
    if (justComplete || imageProvider.isComplete(sessionId)) {
      _clearImageMissingRetry(sessionId);
      return;
    }

    _imageMissingRetryAttempts[sessionId] = 0;
    _imageMissingRetryTimers[sessionId]?.cancel();
    _imageMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingImageFragments(sessionId));
    });
  }

  void _clearVoiceMissingRetry(String sessionId) {
    _voiceMissingRetryTimers.remove(sessionId)?.cancel();
    _voiceMissingRetryAttempts.remove(sessionId);
  }

  void _clearImageMissingRetry(String sessionId) {
    _imageMissingRetryTimers.remove(sessionId)?.cancel();
    _imageMissingRetryAttempts.remove(sessionId);
  }

  Future<void> _requestMissingVoicePackets(String sessionId) async {
    if (voiceProvider.isReceiveCanceled(sessionId)) {
      _clearVoiceMissingRetry(sessionId);
      return;
    }
    if (voiceProvider.isComplete(sessionId)) {
      _clearVoiceMissingRetry(sessionId);
      return;
    }

    final attempt = _voiceMissingRetryAttempts[sessionId] ?? 0;
    if (attempt >= _maxPacketRetryAttempts) {
      debugPrint(
        '⚠️ [AppProvider] Voice re-request limit reached for $sessionId',
      );
      _clearVoiceMissingRetry(sessionId);
      return;
    }

    final senderKey6 = _voiceSessionSenderKey6[sessionId];
    if (senderKey6 == null) return;
    final sender = _resolveContactByPrefixHex(senderKey6);
    final requesterKey6 = _deviceKey6Hex();
    if (requesterKey6 == null) return;

    final missing = voiceProvider.missingPacketIndices(sessionId);
    if (missing.isEmpty) {
      _clearVoiceMissingRetry(sessionId);
      return;
    }

    var sent = false;
    if (sender != null) {
      final routeOk = await verifyRawTransportRoute(sender);
      if (routeOk) {
        sent = await _sendDirectMediaFetchRequest(
          mediaType: 'voice',
          sessionId: sessionId,
          target: sender,
          requesterKey6: requesterKey6,
          missingIndices: missing.toSet(),
        );
      }
    }
    if (!sent) {
      sent = await _requestMissingMediaViaSwarm(
        mediaType: 'voice',
        sessionId: sessionId,
        missingIndices: missing,
        originalSenderKey6: senderKey6,
      );
    }
    if (!sent) {
      return;
    }

    _voiceMissingRetryAttempts[sessionId] = attempt + 1;
    _voiceMissingRetryTimers[sessionId]?.cancel();
    _voiceMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingVoicePackets(sessionId));
    });
  }

  Future<void> _requestMissingImageFragments(String sessionId) async {
    if (imageProvider.isReceiveCanceled(sessionId)) {
      _clearImageMissingRetry(sessionId);
      return;
    }
    if (imageProvider.isComplete(sessionId)) {
      _clearImageMissingRetry(sessionId);
      return;
    }

    final attempt = _imageMissingRetryAttempts[sessionId] ?? 0;
    if (attempt >= _maxPacketRetryAttempts) {
      debugPrint(
        '⚠️ [AppProvider] Image re-request limit reached for $sessionId',
      );
      _clearImageMissingRetry(sessionId);
      return;
    }

    final senderKey6 = _imageSessionSenderKey6[sessionId];
    if (senderKey6 == null) return;
    final sender = _resolveContactByPrefixHex(senderKey6);
    final requesterKey6 = _deviceKey6Hex();
    if (requesterKey6 == null) return;

    final missing = imageProvider.missingFragmentIndices(sessionId);
    if (missing.isEmpty) {
      _clearImageMissingRetry(sessionId);
      return;
    }

    var sent = false;
    if (sender != null) {
      final routeOk = await verifyRawTransportRoute(sender);
      if (routeOk) {
        sent = await _sendDirectMediaFetchRequest(
          mediaType: 'image',
          sessionId: sessionId,
          target: sender,
          requesterKey6: requesterKey6,
          missingIndices: missing.toSet(),
        );
      }
    }
    if (!sent) {
      sent = await _requestMissingMediaViaSwarm(
        mediaType: 'image',
        sessionId: sessionId,
        missingIndices: missing,
        originalSenderKey6: senderKey6,
      );
    }
    if (!sent) {
      return;
    }

    _imageMissingRetryAttempts[sessionId] = attempt + 1;
    _imageMissingRetryTimers[sessionId]?.cancel();
    _imageMissingRetryTimers[sessionId] = Timer(_packetRetryDelay, () {
      unawaited(_requestMissingImageFragments(sessionId));
    });
  }

  bool _handleFastGpsPayload(Uint8List payload) {
    final fastGpsPacket = FastGpsPacket.tryParseBinary(payload);
    if (fastGpsPacket == null) {
      return false;
    }

    final sender = _resolveContactByPrefixHex(fastGpsPacket.senderKey6);
    if (sender != null) {
      contactsProvider.updateFastGps(
        sender.publicKey.sublist(0, 6),
        fastGpsPacket,
      );
    }
    return true;
  }

  bool _handleIncomingImageBinaryPayload(
    Uint8List payload, {
    bool allowPreEnvelopeBuffer = false,
  }) {
    if (!ImagePacket.isImageBinary(payload)) {
      return false;
    }
    final frag = ImagePacket.tryParseBinary(payload);
    if (frag == null) {
      return true;
    }
    debugPrint('📷 [AppProvider] Binary image fragment received: $frag');
    final session = imageProvider.session(frag.sessionId);
    if (session == null && frag.total < 1) {
      if (allowPreEnvelopeBuffer) {
        _pendingChannelImageFragments.putIfAbsent(
          frag.sessionId,
          () => <int, ImagePacket>{},
        )[frag.index] = frag;
        debugPrint(
          '📷 [AppProvider] Buffered compact image fragment before envelope '
          'for session ${frag.sessionId} index=${frag.index}',
        );
      } else {
        debugPrint(
          '⚠️ [AppProvider] Dropping compact image fragment without envelope '
          'for session ${frag.sessionId}',
        );
      }
      return true;
    }

    imageProvider.addFragment(
      session == null
          ? frag
          : ImagePacket(
              sessionId: frag.sessionId,
              format: session.format,
              index: frag.index,
              total: session.total,
              data: frag.data,
            ),
      width: session?.width ?? 0,
      height: session?.height ?? 0,
    );
    _scheduleImageMissingRetry(
      frag.sessionId,
      justComplete: imageProvider.isComplete(frag.sessionId),
    );
    return true;
  }

  bool _handleIncomingVoiceBinaryPayload(
    Uint8List payload, {
    bool allowPreEnvelopeBuffer = false,
  }) {
    if (!VoicePacket.isVoiceBinary(payload)) {
      return false;
    }
    final pkt = VoicePacket.tryParseBinary(payload);
    if (pkt == null) {
      return true;
    }
    debugPrint('🎙️ [AppProvider] Binary voice packet received: $pkt');
    final session = voiceProvider.session(pkt.sessionId);
    if (session == null && pkt.total < 1) {
      if (allowPreEnvelopeBuffer) {
        _pendingChannelVoicePackets.putIfAbsent(
          pkt.sessionId,
          () => <int, VoicePacket>{},
        )[pkt.index] = pkt;
        debugPrint(
          '🎙️ [AppProvider] Buffered compact voice packet before envelope '
          'for session ${pkt.sessionId} index=${pkt.index}',
        );
      } else {
        debugPrint(
          '⚠️ [AppProvider] Dropping compact voice packet without envelope '
          'for session ${pkt.sessionId}',
        );
      }
      return true;
    }

    final normalizedPacket = session == null
        ? pkt
        : VoicePacket(
            sessionId: pkt.sessionId,
            mode: session.mode,
            index: pkt.index,
            total: session.total,
            codec2Data: pkt.codec2Data,
          );
    final justComplete = voiceProvider.addPacket(normalizedPacket);
    _scheduleVoiceMissingRetry(pkt.sessionId, justComplete: justComplete);
    _handleIncomingVoicePacket(normalizedPacket, justComplete: justComplete);
    return true;
  }

  void _replayPendingChannelVoicePackets(String sessionId) {
    final pending = _pendingChannelVoicePackets.remove(sessionId);
    final session = voiceProvider.session(sessionId);
    if (pending == null || pending.isEmpty || session == null) {
      return;
    }

    final indices = pending.keys.toList()..sort();
    for (final index in indices) {
      final packet = pending[index]!;
      final normalizedPacket = VoicePacket(
        sessionId: packet.sessionId,
        mode: session.mode,
        index: packet.index,
        total: session.total,
        codec2Data: packet.codec2Data,
      );
      final justComplete = voiceProvider.addPacket(normalizedPacket);
      _scheduleVoiceMissingRetry(sessionId, justComplete: justComplete);
      _handleIncomingVoicePacket(normalizedPacket, justComplete: justComplete);
    }
  }

  void _replayPendingChannelImageFragments(String sessionId) {
    final pending = _pendingChannelImageFragments.remove(sessionId);
    final session = imageProvider.session(sessionId);
    if (pending == null || pending.isEmpty || session == null) {
      return;
    }

    final indices = pending.keys.toList()..sort();
    for (final index in indices) {
      final fragment = pending[index]!;
      final normalizedFragment = ImagePacket(
        sessionId: fragment.sessionId,
        format: session.format,
        index: fragment.index,
        total: session.total,
        data: fragment.data,
      );
      imageProvider.addFragment(
        normalizedFragment,
        width: session.width,
        height: session.height,
      );
      _scheduleImageMissingRetry(
        sessionId,
        justComplete: imageProvider.isComplete(sessionId),
      );
    }
  }

  /// Insert or update a voice placeholder message for binary raw-data packets.
  ///
  /// Binary voice packets arrive without a chat message, so we synthesise one
  /// to give the user a playable bubble in the message list.
  void _handleIncomingVoicePacket(
    VoicePacket pkt, {
    required bool justComplete,
  }) {
    final sessionId = pkt.sessionId;

    // Check if a placeholder for this session already exists
    final existing = messagesProvider.messages
        .where((m) => m.isVoice && m.voiceId == sessionId)
        .firstOrNull;

    if (existing != null) {
      // Already have a placeholder — no need to add another
      return;
    }

    // First packet of a new session: insert placeholder message
    final msgId = 'voice_$sessionId';
    final placeholder = Message(
      id: msgId,
      messageType: MessageType.contact, // direct contact (binary only)
      senderPublicKeyPrefix: null,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      // Persist the first real packet in legacy V: text form so UI/debug paths
      // can reconstruct packet metadata from actual data.
      text: pkt.encodeText(),
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.received,
      isVoice: true,
      voiceId: sessionId,
    );
    messagesProvider.addMessage(placeholder, contactLookup: (_) => '');
  }

  String _rawProbeKey(int nonce) =>
      nonce.toRadixString(16).padLeft(8, '0').toLowerCase();

  Future<bool> verifyRawTransportRoute(
    Contact target, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!connectionProvider.deviceInfo.isConnected) {
      return false;
    }
    if (!target.routeHasPath || target.routeHopCount > _maxDirectPayloadHops) {
      return false;
    }
    if (target.outPath.isEmpty) {
      return false;
    }

    final probeKey = _routeProbeTargetKey(target);
    final pendingProbe = _pendingRawRouteProbes[probeKey];
    if (pendingProbe != null) {
      return pendingProbe;
    }

    final deviceKey = connectionProvider.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      return false;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final future = () async {
      final nonce = math.Random.secure().nextInt(0x100000000);
      final ackFuture = _rawProbeWaiters.waitFor(
        _rawProbeKey(nonce),
        timeout: timeout,
      );

      try {
        debugPrint(
          '📡 [AppProvider] Outgoing raw route probe: target=${target.advName} hops=${target.routeHopCount} nonce=${nonce.toRadixString(16)}',
        );
        await connectionProvider.sendRawVoicePacket(
          contactPath: target.outPath,
          contactPathLen: target.routeEncodedPathLen,
          payload: RawRouteProbeRequest(
            nonce: nonce,
            requesterKey6: requesterKey6,
          ).encodeBinary(),
        );
        return await ackFuture;
      } catch (e) {
        debugPrint(
          '⚠️ [AppProvider] Raw route probe failed for ${target.advName}: $e',
        );
        _rawProbeWaiters.complete(_rawProbeKey(nonce));
        return false;
      }
    }();

    _pendingRawRouteProbes[probeKey] = future;
    try {
      return await future;
    } finally {
      _pendingRawRouteProbes.remove(probeKey);
    }
  }

  String _routeProbeTargetKey(Contact target) {
    if (target.publicKeyHex.isNotEmpty) {
      return 'pk:${target.publicKeyHex}';
    }
    return 'name:${target.advName}:${target.routeEncodedPathLen}:${target.outPath.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  void _handleRawRouteProbeRequest(RawRouteProbeRequest request) {
    final requester = _resolveContactByPrefixHex(request.requesterKey6);
    if (requester == null) {
      debugPrint(
        '⚠️ [AppProvider] Raw route probe requester not found: ${request.requesterKey6}',
      );
      return;
    }
    if (!requester.routeHasPath ||
        requester.routeHopCount > _maxDirectPayloadHops) {
      debugPrint(
        '⚠️ [AppProvider] Raw route probe requester out of range: ${requester.routeHopCount}',
      );
      return;
    }
    if (requester.outPath.isEmpty) {
      return;
    }
    debugPrint(
      '📡 [AppProvider] Outgoing raw route probe ACK: requester=${requester.advName} hops=${requester.routeHopCount} nonce=${request.nonce.toRadixString(16)}',
    );
    unawaited(
      connectionProvider.sendRawVoicePacket(
        contactPath: requester.outPath,
        contactPathLen: requester.routeEncodedPathLen,
        payload: RawRouteProbeAck(nonce: request.nonce).encodeBinary(),
      ),
    );
  }

  void _completeRawRouteProbeAck(int nonce) {
    _rawProbeWaiters.complete(_rawProbeKey(nonce));
  }

  MessageReceptionDetails? _buildReceptionDetailsSnapshot(Message message) {
    final matchedRxLog = _findBestMatchingRxLog(message);
    final estimatedTx = estimateMessageTransmitDuration(
      message,
      radioBw: connectionProvider.deviceInfo.radioBw,
      radioSf: connectionProvider.deviceInfo.radioSf,
      radioCr: connectionProvider.deviceInfo.radioCr,
    );
    final senderToReceiptMs = _senderToReceiptMs(message);
    final estimatedTransmitMs = sanitizeEstimatedTransmitMs(
      estimatedTransmitMs: estimatedTx > Duration.zero
          ? estimatedTx.inMilliseconds
          : null,
      senderToReceiptMs: senderToReceiptMs,
    );
    final postTransmitDelayMs =
        senderToReceiptMs != null && estimatedTransmitMs != null
        ? (senderToReceiptMs - estimatedTransmitMs).clamp(0, 86400000).toInt()
        : null;

    if (matchedRxLog == null &&
        senderToReceiptMs == null &&
        estimatedTransmitMs == null) {
      return null;
    }

    return MessageReceptionDetails(
      capturedAt: DateTime.now(),
      packetLoggedAt: matchedRxLog?.timestamp,
      rssiDbm: matchedRxLog?.logRxDataInfo?.rssiDbm,
      snrDb: matchedRxLog?.logRxDataInfo?.snrDb,
      pathBytes: _extractPathBytesFromLog(matchedRxLog),
      senderToReceiptMs: senderToReceiptMs,
      estimatedTransmitMs: estimatedTransmitMs,
      postTransmitDelayMs: postTransmitDelayMs,
    );
  }

  int? _senderToReceiptMs(Message message) {
    if (message.senderTimestamp <= 0) return null;
    final senderAt = DateTime.fromMillisecondsSinceEpoch(
      message.senderTimestamp * 1000,
      isUtc: true,
    );
    final deltaMs = message.receivedAt
        .toUtc()
        .difference(senderAt)
        .inMilliseconds;
    if (deltaMs < 0 || deltaMs > 86400000) return null;
    return deltaMs;
  }

  BlePacketLog? _findBestMatchingRxLog(Message message) {
    if (message.pathLen < 0 || message.pathLen >= 255) return null;
    final expectedPayloadType = message.messageType == MessageType.channel
        ? 0x05
        : 0x02;
    BlePacketLog? bestLog;
    var bestDeltaMs = 999999999;

    for (final log in connectionProvider.bleService.packetLogs) {
      if (log.responseCode != 0x88) continue;
      if (log.rawData.length < 6) continue;

      final decoded = LogRxRouteDecoder.decode(log.rawData);
      if (decoded == null) continue;
      if (decoded.payloadType != expectedPayloadType) continue;
      if (decoded.hopCount != message.pathLen) continue;

      final deltaMs =
          (log.timestamp.difference(message.receivedAt).inMilliseconds).abs();
      if (deltaMs < bestDeltaMs) {
        bestDeltaMs = deltaMs;
        bestLog = log;
      }
    }

    if (bestDeltaMs > 30000) return null;
    return bestLog;
  }

  DecodedLogRxRoute? _findBestMatchingAdvertRxRoute(Uint8List publicKey) {
    final publicKeyHex = publicKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();

    DecodedLogRxRoute? bestRoute;
    var bestDeltaMs = 999999999;
    final now = DateTime.now();

    for (final log in connectionProvider.bleService.packetLogs) {
      if (log.responseCode != 0x88) continue;
      if (log.rawData.length < 6) continue;

      final decoded = LogRxRouteDecoder.decode(log.rawData);
      if (decoded == null) continue;
      if (decoded.payloadType != 0x04) continue;
      final senderHash = decoded.originalSenderHashHex;
      if (senderHash == null || !publicKeyHex.startsWith(senderHash)) continue;

      final deltaMs = (log.timestamp.difference(now).inMilliseconds).abs();
      if (deltaMs < bestDeltaMs) {
        bestDeltaMs = deltaMs;
        bestRoute = decoded;
      }
    }

    if (bestDeltaMs > 30000) return null;
    return bestRoute;
  }

  List<int>? _extractPathBytesFromLog(BlePacketLog? log) {
    if (log == null) return null;
    final decoded = LogRxRouteDecoder.decode(log.rawData);
    if (decoded == null || decoded.pathBytes.isEmpty) return null;
    return decoded.pathBytes;
  }

  // Removed _syncMessages() - messages are automatically synced via PUSH_CODE_MSG_WAITING events
  // The ConnectionProvider's onMessageWaiting callback handles automatic message fetching

  /// Refresh data (contacts and channels - messages are handled via events)
  Future<void> refresh() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Sync contacts
      await connectionProvider.getContacts();

      // Sync all channels so refresh reflects the full device state.
      channelsProvider.prepareForDeviceSync();
      await connectionProvider.syncChannels(
        maxChannels: connectionProvider.deviceInfo.maxChannels,
      );

      // Messages are automatically synced via PUSH_CODE_MSG_WAITING events
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  /// Manually sync messages (only for explicit user pull-to-refresh)
  /// Note: Messages are automatically synced via PUSH_CODE_MSG_WAITING events
  /// This method should ONLY be called when the user explicitly pulls to refresh
  Future<int> syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return 0;

    try {
      debugPrint(
        '🔄 [AppProvider] Manual message sync requested (user initiated)',
      );
      final messageCount = await connectionProvider.syncAllMessages(
        force: true,
      );
      debugPrint(
        '✅ [AppProvider] Manual sync completed: $messageCount messages',
      );
      notifyListeners();
      return messageCount;
    } catch (e) {
      debugPrint('❌ [AppProvider] Message sync error: $e');
      return 0;
    }
  }

  /// Handle connection state changes to manage location tracking
  void _handleConnectionStateChange() {
    final isConnected = connectionProvider.deviceInfo.isConnected;
    final wasConnected = _wasDeviceConnected;
    _wasDeviceConnected = isConnected;
    final wasTracking = locationTrackingService.isTracking;

    // Only stop tracking on disconnect - DON'T start on connect
    // Location tracking will be started AFTER initialization completes
    if (!isConnected && wasTracking) {
      // Connection lost - stop location tracking
      debugPrint(
        '🔴 [AppProvider] BLE disconnected - stopping location tracking',
      );
      _stopLocationTracking();
    }

    if (!isConnected) {
      connectionProvider.clearPendingAutomaticMessageSync();
    }

    if (isConnected && !wasConnected && _hasCompletedConnectionBootstrap) {
      _isReconnectSyncInProgress = true;
      unawaited(_syncAfterReconnect(started: true));
    }
  }

  bool _canStartAutomaticMessageSync() {
    return connectionProvider.deviceInfo.isConnected &&
        _hasCompletedConnectionBootstrap &&
        !_isReconnectSyncInProgress;
  }

  Future<void> _flushDeferredAutomaticMessageSync() async {
    if (!connectionProvider.hasPendingAutomaticMessageSync ||
        !_canStartAutomaticMessageSync()) {
      return;
    }

    debugPrint(
      '🔄 [AppProvider] Running deferred automatic message sync after bootstrap',
    );
    await connectionProvider.syncAllMessages(force: true);
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      final started = await locationTrackingService.startTracking();
      if (started) {
        debugPrint('✅ [AppProvider] Location tracking started successfully');
      } else {
        debugPrint('⚠️ [AppProvider] Failed to start location tracking');
      }
    } catch (e) {
      debugPrint('❌ [AppProvider] Error starting location tracking: $e');
    }
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    try {
      await locationTrackingService.stopTracking();
      debugPrint('✅ [AppProvider] Location tracking stopped');
    } catch (e) {
      debugPrint('❌ [AppProvider] Error stopping location tracking: $e');
    }
  }

  /// Clear all data
  void clearAllData() {
    contactsProvider.clearContacts();
    messagesProvider.clearAll();
    unawaited(voiceProvider.clearStoredVoiceData());
    unawaited(imageProvider.clearAll());
    for (final timer in _voiceMissingRetryTimers.values) {
      timer.cancel();
    }
    for (final timer in _imageMissingRetryTimers.values) {
      timer.cancel();
    }
    _voiceMissingRetryTimers.clear();
    _voiceMissingRetryAttempts.clear();
    _imageMissingRetryTimers.clear();
    _imageMissingRetryAttempts.clear();
    _voiceSessionSenderKey6.clear();
    _imageSessionSenderKey6.clear();
    _pendingChannelVoicePackets.clear();
    _pendingChannelImageFragments.clear();
    _lowBatteryNotifiedNodeIds.clear();
    notifyListeners();
  }

  void _handleControlDataDiscovery({
    required Uint8List payload,
    required int snrRaw,
    required int rssiDbm,
    required int pathLen,
  }) {
    const int controlTypeMask = 0xF0;
    const int controlTypeNodeDiscoverResp = 0x90;
    const int minFullDiscoverResponseLength = 6 + 32;

    if (payload.length < minFullDiscoverResponseLength) {
      return;
    }

    final controlType = payload[0] & controlTypeMask;
    if (controlType != controlTypeNodeDiscoverResp) {
      return;
    }

    final nodeType = payload[0] & 0x0F;
    final publicKey = Uint8List.fromList(payload.sublist(6, 38));
    final isNewPendingAdvert = contactsProvider
        .addOrUpdatePendingAdvertMetadata(
          publicKey: publicKey,
          typeValue: nodeType,
          devicePublicKey: connectionProvider.deviceInfo.publicKey,
          rxRssiDbm: rssiDbm,
          rxSnrRaw: snrRaw,
          signedEncodedPathLen: pathLen == 0 ? 0 : null,
          paddedPathBytes: pathLen == 0
              ? Uint8List(ContactRouteCodec.maxPathBytes)
              : null,
        );

    debugPrint(
      '🛰️ [AppProvider] Control discovery response: type=$nodeType '
      'pathLen=$pathLen snr=$snrRaw rssi=$rssiDbm new=$isNewPendingAdvert',
    );

    // Official app flow for controlData discovery:
    // - Try getContact from firmware. If not found → skip.
    // - If found → update path, request region names for repeaters.
    // - Discovery list shows generic labels ("Repeater XX:YY") for unknown nodes.
    // - Names appear later when the node's advert arrives via pushAdvert/pushNewAdvert.

    if (isNewPendingAdvert) {
      final keyHex = publicKey
          .take(6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      unawaited(
        _notificationService.showContactDiscoveredNotification(
          contactKey: keyHex,
          contactName: contactsProvider.pendingAdvertByKey(publicKey)?.advName,
        ),
      );
    }

    if (nodeType == ContactType.repeater.value) {
      unawaited(_requestRepeaterStatus(publicKey));
      unawaited(_maybeRequestRepeaterOwnerInfo(publicKey));
    }

    // Try to enrich from firmware's existing contacts (no import — the
    // controlData discovery response doesn't store an advert in firmware).
    if (contactsProvider.shouldEnrichPendingAdvert(publicKey)) {
      unawaited(connectionProvider.previewContact(publicKey));
    }
  }

  /// Get app statistics
  Map<String, dynamic> get statistics {
    return {
      'connection': {
        'isConnected': connectionProvider.deviceInfo.isConnected,
        'deviceName': connectionProvider.deviceInfo.deviceName,
        'battery': connectionProvider.deviceInfo.batteryPercent,
      },
      'contacts': contactsProvider.contactCounts,
      'messages': messagesProvider.messageStats,
      'sarMarkers': messagesProvider.sarMarkerStats,
    };
  }

  @override
  void dispose() {
    _packetCaptureFlushTimer?.cancel();
    _lowBatteryCheckTimer?.cancel();
    unawaited(_flushPacketCaptureLogs());
    // Remove connection state listener
    connectionProvider.removeListener(_handleConnectionStateChange);
    // Clear location service callbacks
    locationTrackingService.onPositionUpdate = null;
    locationTrackingService.onBroadcastSent = null;
    locationTrackingService.onError = null;
    locationTrackingService.onTrackingStateChanged = null;
    locationTrackingService.onFastLocationUpdate = null;
    // Dispose the location tracking service to stop GPS stream and clean up resources
    locationTrackingService.dispose();
    for (final timer in _voiceMissingRetryTimers.values) {
      timer.cancel();
    }
    for (final timer in _imageMissingRetryTimers.values) {
      timer.cancel();
    }
    _pendingChannelVoicePackets.clear();
    _pendingChannelImageFragments.clear();
    super.dispose();
  }
}
