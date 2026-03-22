import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/contact.dart';
import '../models/device_info.dart';
import '../models/room_login_state.dart';
import 'package:meshcore_client/meshcore_client.dart' hide Contact;
import '../utils/sar_message_parser.dart';
import 'helpers/room_login_manager.dart';
import 'helpers/message_delivery_tracker.dart';
import 'helpers/ping_tracker.dart';

/// Pending send operation for auto-recovery
class _PendingSendOperation {
  final Uint8List contactPublicKey;
  final String text;
  final String? messageId;
  final Contact? contact;
  final int retryAttempt;

  _PendingSendOperation({
    required this.contactPublicKey,
    required this.text,
    this.messageId,
    this.contact,
    this.retryAttempt = 0,
  });
}

/// Result of a ping (telemetry request) operation
class PingResult {
  final bool success;
  final bool usedFlooding;
  final bool timedOut;
  final bool retriedWithFlooding;

  const PingResult({
    required this.success,
    required this.usedFlooding,
    required this.timedOut,
    this.retriedWithFlooding = false,
  });
}

/// Scanned device with RSSI information
class ScannedDevice {
  final BluetoothDevice device;
  final int rssi;

  ScannedDevice({required this.device, required this.rssi});
}

enum ContactReceiveSource { sync, requestedSingle, preview, advert }

class _PendingContactRequest {
  final ContactReceiveSource source;
  final DateTime requestedAt;

  const _PendingContactRequest({
    required this.source,
    required this.requestedAt,
  });
}

/// Connection Provider - manages MeshCore device connection (BLE or TCP/WiFi)
class ConnectionProvider with ChangeNotifier {
  static const int _controlTypeNodeDiscoverReq = 0x80;
  final MeshCoreBleService _bleService = MeshCoreBleService();
  MeshCoreTcpService? _tcpService;
  MeshCoreSerialService? _serialService;
  Future<void> Function()? _serialDisconnectTransport;

  /// Expose BLE service for background location tracking
  MeshCoreBleService get bleService => _bleService;

  /// Active service — BLE, TCP, or USB depending on current mode
  MeshCoreServiceBase get _activeService {
    if (_connectionMode == ConnectionMode.tcp && _tcpService != null) {
      return _tcpService!;
    }
    if (_connectionMode == ConnectionMode.usb && _serialService != null) {
      return _serialService!;
    }
    return _bleService;
  }

  /// Current connection mode
  ConnectionMode _connectionMode = ConnectionMode.ble;
  ConnectionMode get connectionMode => _connectionMode;

  /// TCP host last connected to (for display / reconnection info)
  String? _tcpHost;
  String? get tcpHost => _tcpHost;

  DeviceInfo _deviceInfo = DeviceInfo();
  DeviceInfo get deviceInfo => _deviceInfo;

  final List<ScannedDevice> _scannedDevices = [];
  List<ScannedDevice> get scannedDevices => _scannedDevices;

  bool _isScanning = false;
  bool get isScanning => _isScanning;
  final Set<int> _pendingDeletedChannelIndices = <int>{};

  String? _error;
  String? get error => _error;

  // Activity indicators (for blinking)
  bool _rxActivity = false;
  bool _txActivity = false;
  bool get rxActivity => _rxActivity;
  bool get txActivity => _txActivity;

  Timer? _rxActivityTimer;
  Timer? _txActivityTimer;

  // Periodic cleanup timer for stale ACK mappings
  Timer? _ackCleanupTimer;

  // Packet counters
  int get rxPacketCount => _activeService.rxPacketCount;
  int get txPacketCount => _activeService.txPacketCount;

  // Reconnection state
  bool get isReconnecting => _activeService.isReconnecting;
  int get reconnectionAttempt => _activeService.reconnectionAttempt;
  int get maxReconnectionAttempts => _activeService.maxReconnectionAttempts;

  // Message sync state
  bool _noMoreMessages = false;
  // Prevent overlapping/too-frequent sync requests
  bool _isSyncingMessages = false;
  // If MSG_WAITING arrives while a sync loop is active, queue one more pass.
  bool _syncRequestedWhileBusy = false;
  DateTime? _lastSyncNextRequestedAt;
  static const Duration _minSyncNextInterval = Duration(milliseconds: 150);

  // Completer to wait for response before sending next sync request
  Completer<bool>? _syncResponseCompleter;

  // Completer to wait for contacts sync to finish
  Completer<void>? _contactsSyncCompleter;

  // Lightweight guards for other commands that can be double-tapped
  bool _isLoginInProgress = false;
  DateTime? _lastLoginRequestedAt;
  static const Duration _minLoginInterval = Duration(seconds: 1);

  bool _isStatusRequestInProgress = false;
  DateTime? _lastStatusRequestedAt;
  static const Duration _minStatusInterval = Duration(milliseconds: 200);

  bool _isAdvertInProgress = false;
  DateTime? _lastAdvertRequestedAt;
  static const Duration _minAdvertInterval = Duration(milliseconds: 500);
  bool _isContactsSyncInProgress = false;
  final Map<String, _PendingContactRequest> _pendingSingleContactRequests = {};
  final Map<String, DateTime> _previewContactMisses = {};
  static const Duration _singleContactRequestWindow = Duration(seconds: 10);
  static const Duration _previewContactMissTtl = Duration(minutes: 10);
  bool _suppressNextPreviewNotFoundError = false;
  bool? _supportsAutoaddConfig;

  // Helper instances
  final RoomLoginManager _roomLoginManager = RoomLoginManager();
  final MessageDeliveryTracker _messageDeliveryTracker =
      MessageDeliveryTracker();
  final PingTracker _pingTracker = PingTracker();
  final Map<String, Future<PingResult>> _pendingSmartPings = {};

  // Expose room login states
  Map<String, RoomLoginState> get roomLoginStates =>
      _roomLoginManager.roomLoginStates;

  bool isPingInProgress(Uint8List publicKey) =>
      _pendingSmartPings.containsKey(_publicKeyToHex(publicKey));

  // Callbacks for other providers
  Function(Contact)? onContactReceived;
  Function(Contact, ContactReceiveSource)? onContactReceivedDetailed;
  Function(List<Contact>)? onContactsComplete;
  Function(Message)? onMessageReceived;
  Function(Uint8List publicKey, Uint8List lppData)? onTelemetryReceived;
  Function(int channelIdx, String channelName, Uint8List secret, int? flags)?
  onChannelInfoReceived;
  Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData)?
  onBinaryResponse;
  Function(Uint8List publicKey)? onContactDeleted;
  VoidCallback? onContactsFull;
  Function(Uint8List publicKey)? onAdvertReceived;
  Function(Uint8List publicKey)? onPathUpdated;
  Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag)?
  onLoginSuccess;
  Function(Uint8List publicKeyPrefix)? onLoginFail;
  Function(String messageId, int expectedAckTag, int suggestedTimeoutMs)?
  onMessageSent;
  Function(int ackCode, int roundTripTimeMs)? onMessageDelivered;
  Future<Contact?> Function({
    required String messageId,
    required Contact contact,
    required int retryAttempt,
  })?
  prepareDirectMessageSendCallback;
  Function(String messageId, int echoCount, int snrRaw, int rssiDbm)?
  onMessageEchoDetected;
  Function(Uint8List publicKeyPrefix, Uint8List statusData)? onStatusResponse;
  Function(Uint8List payload, int snrRaw, int rssiDbm)? onRawDataReceived;
  Function(
    int channelIdx,
    int pathLen,
    int dataType,
    Uint8List payload,
    int snrRaw,
    int? rssiDbm,
  )?
  onChannelDataReceived;
  Function(Uint8List payload, int snrRaw, int rssiDbm, int pathLen)?
  onControlDataReceived;
  Contact? Function(Uint8List contactPublicKey)? resolveContactForDmCallback;
  bool Function()? canStartAutomaticMessageSyncCallback;

  // Track pending send operations for auto-recovery
  final Map<String, _PendingSendOperation> _pendingSendOperations = {};
  bool _pendingAutomaticMessageSync = false;

  ConnectionProvider() {
    _wireServiceCallbacks(_bleService);
  }

  Future<void> _prepareForConnectionSwitch(ConnectionMode nextMode) async {
    if (_isScanning) {
      debugPrint('🔵 [Provider] Stopping active scan before connect()');
      await stopScan();
    }

    await _disconnectInactiveTransports(nextMode);
    _error = null;
    _supportsAutoaddConfig = null;
    _resetSyncState();
  }

  Future<void> _disconnectInactiveTransports(ConnectionMode activeMode) async {
    if (activeMode != ConnectionMode.ble && _bleService.isConnected) {
      await _bleService.disconnect();
    }

    if (activeMode != ConnectionMode.tcp && _tcpService != null) {
      await _disposeTcpService();
    }

    if (activeMode != ConnectionMode.usb && _serialService != null) {
      await _disposeSerialService();
    }
  }

  Future<void> _disposeTcpService() async {
    final service = _tcpService;
    if (service == null) {
      return;
    }
    _tcpService = null;
    await service.disconnect();
    service.dispose();
  }

  Future<void> _disposeSerialService() async {
    final service = _serialService;
    final disconnectTransport = _serialDisconnectTransport;
    _serialService = null;
    _serialDisconnectTransport = null;
    if (service == null) {
      return;
    }
    service.markDisconnected();
    service.writeRaw = null;
    if (disconnectTransport != null) {
      await disconnectTransport();
    }
    service.dispose();
  }

  void _beginConnectionAttempt({
    required ConnectionMode mode,
    required String deviceId,
    required String deviceName,
    String? tcpHost,
  }) {
    _connectionMode = mode;
    _tcpHost = mode == ConnectionMode.tcp ? tcpHost : null;
    _deviceInfo = _deviceInfo.copyWith(
      deviceId: deviceId,
      deviceName: deviceName,
      connectionState: ConnectionState.connecting,
    );
    notifyListeners();
  }

  void _resetConnectionSession({ConnectionMode nextMode = ConnectionMode.ble}) {
    _tcpHost = nextMode == ConnectionMode.tcp ? _tcpHost : null;
    _connectionMode = nextMode;
    _supportsAutoaddConfig = null;
    _resetSyncState();
    _deviceInfo = DeviceInfo(connectionState: ConnectionState.disconnected);
    _roomLoginManager.clearRoomLoginStates();
    _pingTracker.clearAll();
    _pendingSendOperations.clear();
    _messageDeliveryTracker.clearTracking();
    notifyListeners();
  }

  /// Wire all shared event callbacks onto [service].
  /// Called for both BLE and TCP services so the provider handles events
  /// identically regardless of transport.
  void _wireServiceCallbacks(MeshCoreServiceBase service) {
    service.onConnectionStateChanged = (isConnected) {
      debugPrint('🔔 [Provider] Connection state callback fired: $isConnected');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: isConnected
            ? ConnectionState.connected
            : (service.isReconnecting
                  ? ConnectionState.connecting
                  : ConnectionState.disconnected),
        lastUpdate: DateTime.now(),
      );
      debugPrint(
        '  Updated deviceInfo.connectionState: ${_deviceInfo.connectionState}',
      );
      debugPrint(
        '  Updated deviceInfo.isConnected: ${_deviceInfo.isConnected}',
      );
      debugPrint('  isReconnecting: ${service.isReconnecting}');

      // Start/stop ACK cleanup timer based on connection state
      if (isConnected) {
        _startAckCleanupTimer();
      } else {
        _stopAckCleanupTimer();
      }

      notifyListeners();
      debugPrint('  Notified listeners');
    };

    service.onReconnectionAttempt = (attemptNumber, maxAttempts) {
      debugPrint(
        '🔄 [Provider] Reconnection attempt $attemptNumber/$maxAttempts',
      );
      notifyListeners();
    };

    service.onError = (error, {int? errorCode}) {
      if (errorCode == 2 && _suppressNextPreviewNotFoundError) {
        _suppressNextPreviewNotFoundError = false;
        return;
      }
      debugPrint('⚠️ [Provider] Error received: $error');
      _error = error;
      if (_deviceInfo.connectionState != ConnectionState.connected) {
        _deviceInfo = _deviceInfo.copyWith(
          connectionState: ConnectionState.error,
        );
      }
      notifyListeners();
    };

    service.onContactNotFound = (contactPublicKey) async {
      if (contactPublicKey == null) return;

      final keyHex = _publicKeyToHex(contactPublicKey);
      final request = _pendingSingleContactRequests.remove(keyHex);
      if (request?.source == ContactReceiveSource.preview) {
        _previewContactMisses[keyHex] = DateTime.now();
        _suppressNextPreviewNotFoundError = true;
        debugPrint(
          '🔧 [Provider] Preview contact not found, suppressing retries for $keyHex',
        );
        return;
      }

      debugPrint('🔧 [Provider] Contact not found - initiating auto-recovery');

      final operationId = contactPublicKey
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':');
      final pendingOp = _pendingSendOperations[operationId];
      if (pendingOp == null || pendingOp.contact == null) return;

      try {
        await _activeService.addOrUpdateContact(pendingOp.contact!);

        if (pendingOp.messageId != null) {
          _messageDeliveryTracker.trackPendingDirectMessage(
            pendingOp.messageId!,
            pendingOp.contactPublicKey,
          );
        }

        await _activeService.sendTextMessage(
          contactPublicKey: pendingOp.contactPublicKey,
          text: pendingOp.text,
          attempt: pendingOp.retryAttempt,
        );
        _pendingSendOperations.remove(operationId);
      } catch (e) {
        debugPrint('  ❌ Auto-recovery failed: $e');
        _error = 'Auto-recovery failed: $e';
        notifyListeners();
        _pendingSendOperations.remove(operationId);
      }
    };

    service.onContactReceived = (contact) {
      debugPrint('📥 [Provider] Contact received: "${contact.advName}"');
      final source = _classifyContactReceiveSource(contact.publicKey);
      onContactReceivedDetailed?.call(contact, source);
      onContactReceived?.call(contact);
    };

    service.onContactsComplete = (contacts) {
      debugPrint('📥 [Provider] Contacts sync complete: ${contacts.length}');
      _isContactsSyncInProgress = false;
      if (_contactsSyncCompleter != null &&
          !_contactsSyncCompleter!.isCompleted) {
        _contactsSyncCompleter!.complete();
      }
      onContactsComplete?.call(contacts);
    };

    service.onChannelInfoReceived =
        (int channelIdx, String channelName, Uint8List secret, int? flags) {
          onChannelInfoReceived?.call(channelIdx, channelName, secret, flags);
        };

    service.onContactDeleted = (publicKey) => onContactDeleted?.call(publicKey);
    service.onContactsFull = () => onContactsFull?.call();

    service.onMessageReceived = (message) {
      final enhancedMessage = SarMessageParser.enhanceMessage(message);
      onMessageReceived?.call(enhancedMessage);
      if (_syncResponseCompleter != null &&
          !_syncResponseCompleter!.isCompleted) {
        _syncResponseCompleter!.complete(true);
      }
    };

    service.onTelemetryReceived = (publicKey, lppData) {
      debugPrint('📥 [Provider] Telemetry received');
      _pingTracker.markPingSuccessful(publicKey);
      onTelemetryReceived?.call(publicKey, lppData);
    };

    service.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      debugPrint('📥 [Provider] Binary response received');
      _pingTracker.markPingSuccessful(publicKeyPrefix);
      onBinaryResponse?.call(publicKeyPrefix, tag, responseData);
    };

    service.onNoMoreMessages = () {
      _noMoreMessages = true;
      if (_syncResponseCompleter != null &&
          !_syncResponseCompleter!.isCompleted) {
        _syncResponseCompleter!.complete(false);
      }
    };

    service.onMessageWaiting = () {
      if (!(canStartAutomaticMessageSyncCallback?.call() ?? true)) {
        _pendingAutomaticMessageSync = true;
        debugPrint(
          '📥 [Provider] MSG_WAITING deferred until connection bootstrap completes',
        );
        return;
      }
      debugPrint('📥 [Provider] MSG_WAITING - auto-syncing');
      if (_isSyncingMessages) {
        _syncRequestedWhileBusy = true;
        debugPrint(
          '  ↪️ [Provider] Sync already running; queued follow-up sync',
        );
        return;
      }
      unawaited(syncAllMessages());
    };

    service.onLoginSuccess =
        (publicKeyPrefix, permissions, isAdmin, tag) async {
          await _roomLoginManager.handleLoginSuccess(
            publicKeyPrefix: publicKeyPrefix,
            permissions: permissions,
            isAdmin: isAdmin,
            tag: tag,
          );
          notifyListeners();
          onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
        };

    service.onLoginFail = (publicKeyPrefix) {
      _roomLoginManager.handleLoginFail(publicKeyPrefix: publicKeyPrefix);
      notifyListeners();
      onLoginFail?.call(publicKeyPrefix);
    };

    service.onAdvertReceived = (publicKey) => onAdvertReceived?.call(publicKey);
    service.onPathUpdated = (publicKey) => onPathUpdated?.call(publicKey);

    service.onMessageSent =
        (expectedAckTag, suggestedTimeoutMs, isFloodMode, contactPublicKey) {
          final messageId = contactPublicKey != null
              ? _messageDeliveryTracker.popPendingDirectMessageId(
                  contactPublicKey,
                )
              : _messageDeliveryTracker.popPendingMessageId();
          if (messageId != null) {
            _messageDeliveryTracker.mapAckTagToMessageId(
              expectedAckTag,
              messageId,
            );
            onMessageSent?.call(messageId, expectedAckTag, suggestedTimeoutMs);
          }
        };

    service.onMessageDelivered = (ackCode, roundTripTimeMs) =>
        onMessageDelivered?.call(ackCode, roundTripTimeMs);

    service.onMessageEchoDetected = (messageId, echoCount, snrRaw, rssiDbm) =>
        onMessageEchoDetected?.call(messageId, echoCount, snrRaw, rssiDbm);

    service.onStatusResponse = (publicKeyPrefix, statusData) =>
        onStatusResponse?.call(publicKeyPrefix, statusData);

    service.onRawDataReceived = (payload, snrRaw, rssiDbm) =>
        onRawDataReceived?.call(payload, snrRaw, rssiDbm);
    service.onChannelDataReceived =
        (channelIdx, pathLen, dataType, payload, snrRaw, rssiDbm) =>
            onChannelDataReceived?.call(
              channelIdx,
              pathLen,
              dataType,
              payload,
              snrRaw,
              rssiDbm,
            );
    service.onControlDataReceived = (payload, snrRaw, rssiDbm, pathLen) =>
        onControlDataReceived?.call(payload, snrRaw, rssiDbm, pathLen);

    service.onDeviceInfoReceived = (deviceInfo) {
      debugPrint('📥 [Provider] DeviceInfo received');
      _deviceInfo = _deviceInfo.copyWith(
        firmwareVersion: deviceInfo['firmwareVersion'] as int?,
        maxContacts: deviceInfo['maxContacts'] as int?,
        maxChannels: deviceInfo['maxChannels'] as int?,
        blePin: deviceInfo['blePin'] as int?,
        firmwareBuildDate: deviceInfo['firmwareBuildDate'] as String?,
        manufacturerModel: deviceInfo['manufacturerModel'] as String?,
        semanticVersion: deviceInfo['semanticVersion'] as String?,
        clientRepeat: deviceInfo['clientRepeat'] as bool?,
        pathHashMode: deviceInfo['pathHashMode'] as int?,
      );
      notifyListeners();
    };

    service.onSelfInfoReceived = (selfInfo) {
      debugPrint('📥 [Provider] SelfInfo received');
      _deviceInfo = _deviceInfo.copyWith(
        deviceType: selfInfo['deviceType'] as int?,
        txPower: selfInfo['txPower'] as int?,
        maxTxPower: selfInfo['maxTxPower'] as int?,
        publicKey: selfInfo['publicKey'] as Uint8List?,
        advLat: selfInfo['advLat'] as int?,
        advLon: selfInfo['advLon'] as int?,
        multiAcks: selfInfo['multiAcks'] as int?,
        advertLocPolicy: selfInfo['advertLocPolicy'] as int?,
        telemetryModes: selfInfo['telemetryModes'] as int?,
        manualAddContacts: selfInfo['manualAddContacts'] as bool?,
        radioFreq: selfInfo['radioFreq'] as int?,
        radioBw: selfInfo['radioBw'] as int?,
        radioSf: selfInfo['radioSf'] as int?,
        radioCr: selfInfo['radioCr'] as int?,
        selfName: selfInfo['selfName'] as String?,
      );
      notifyListeners();
    };

    service.onBatteryAndStorage = (millivolts, usedKb, totalKb) {
      _deviceInfo = _deviceInfo.copyWith(
        batteryMilliVolts: millivolts,
        storageUsedKb: usedKb,
        storageTotalKb: totalKb,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
    };

    service.onRxActivity = () {
      _rxActivity = true;
      notifyListeners();
      _rxActivityTimer?.cancel();
      _rxActivityTimer = Timer(const Duration(milliseconds: 100), () {
        _rxActivity = false;
        notifyListeners();
      });
    };

    service.onAllowedRepeatFreqReceived = (ranges) {
      _deviceInfo = _deviceInfo.copyWith(allowedRepeatFreqRanges: ranges);
      notifyListeners();
    };

    service.onAutoaddConfigReceived = (config) {
      _deviceInfo = _deviceInfo.copyWith(
        autoAddUsers: config['autoAddUsers'] as bool?,
        autoAddRepeaters: config['autoAddRepeaters'] as bool?,
        autoAddRoomServers: config['autoAddRoomServers'] as bool?,
        autoAddSensors: config['autoAddSensors'] as bool?,
        autoAddOverwriteOldest: config['autoAddOverwriteOldest'] as bool?,
        autoAddMaxHops: config['autoAddMaxHops'] as int?,
      );
      notifyListeners();
    };

    service.onTxActivity = () {
      _txActivity = true;
      notifyListeners();
      _txActivityTimer?.cancel();
      _txActivityTimer = Timer(const Duration(milliseconds: 100), () {
        _txActivity = false;
        notifyListeners();
      });
    };

    service.onRssiUpdate = (rssi) {
      _deviceInfo = _deviceInfo.copyWith(
        signalRssi: rssi,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
    };
  }

  /// Start scanning for MeshCore devices
  Future<void> startScan() async {
    debugPrint('🔍 [Provider] startScan() called');
    if (_deviceInfo.connectionState == ConnectionState.connecting ||
        _deviceInfo.connectionState == ConnectionState.connected) {
      debugPrint(
        '⏭️ [Provider] Ignoring scan request while connection is active: ${_deviceInfo.connectionState}',
      );
      return;
    }

    _isScanning = true;
    _scannedDevices.clear();
    _error = null;
    _notifyListenersSafely();
    debugPrint('✅ [Provider] Scan state initialized, notifying listeners');

    try {
      final adapterError = await _awaitBleAdapterReady();
      if (adapterError != null) {
        debugPrint('⚠️ [Provider] BLE adapter not ready: $adapterError');
        _error = adapterError;
        return;
      }

      await for (final scanResult in _bleService.scanForDevices(
        timeout: const Duration(seconds: 10),
      )) {
        debugPrint('📱 [Provider] Scan result received from scan stream');
        final device = scanResult.device;
        final rssi = scanResult.rssi;

        if (!_scannedDevices.any((d) => d.device.remoteId == device.remoteId)) {
          _scannedDevices.add(ScannedDevice(device: device, rssi: rssi));
          debugPrint(
            '✅ [Provider] Added device to list: ${device.platformName} (RSSI: $rssi dBm), total: ${_scannedDevices.length}',
          );
          _notifyListenersSafely();
        } else {
          // Update RSSI if device already exists
          final index = _scannedDevices.indexWhere(
            (d) => d.device.remoteId == device.remoteId,
          );
          if (index != -1 && _scannedDevices[index].rssi != rssi) {
            _scannedDevices[index] = ScannedDevice(device: device, rssi: rssi);
            debugPrint(
              '  🔄 [Provider] Updated RSSI for ${device.platformName}: $rssi dBm',
            );
            _notifyListenersSafely();
          } else {
            debugPrint(
              '  ⏭️ [Provider] Device already in list with same RSSI, skipping',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Provider] Scan error: $e');
      _error = 'Scan error: $e';
    } finally {
      debugPrint('🏁 [Provider] Scan completed');
      _isScanning = false;
      _notifyListenersSafely();
    }
  }

  Future<String?> _awaitBleAdapterReady({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!await FlutterBluePlus.isSupported) {
      return 'Bluetooth is not supported on this device.';
    }

    var state = await FlutterBluePlus.adapterState.first;
    debugPrint('🔵 [Provider] Initial BLE adapter state: $state');

    if (state == BluetoothAdapterState.unknown ||
        state == BluetoothAdapterState.turningOn) {
      debugPrint('⏳ [Provider] Waiting for BLE adapter to finish initializing');
      try {
        state = await FlutterBluePlus.adapterState
            .where(
              (candidate) =>
                  candidate != BluetoothAdapterState.unknown &&
                  candidate != BluetoothAdapterState.turningOn,
            )
            .first
            .timeout(timeout);
      } on TimeoutException {
        state = FlutterBluePlus.adapterStateNow;
      }
      debugPrint('🔵 [Provider] BLE adapter state after wait: $state');
    }

    if (state == BluetoothAdapterState.on) {
      return null;
    }

    return switch (state) {
      BluetoothAdapterState.off =>
        'Bluetooth is turned off. Turn it on and try again.',
      BluetoothAdapterState.turningOff =>
        'Bluetooth is turning off. Turn it back on and try again.',
      BluetoothAdapterState.unauthorized =>
        'Bluetooth access is not allowed. Check app permissions in System Settings and try again.',
      BluetoothAdapterState.unavailable =>
        'Bluetooth hardware is unavailable. On macOS, verify Bluetooth access is enabled for this app target.',
      BluetoothAdapterState.unknown || BluetoothAdapterState.turningOn =>
        'Bluetooth is still initializing. Please try again in a moment.',
      BluetoothAdapterState.on => null,
    };
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  /// Connect to a device
  Future<bool> connect(BluetoothDevice device) async {
    debugPrint(
      '🔵 [Provider] connect() called for device: ${device.platformName}',
    );
    await _prepareForConnectionSwitch(ConnectionMode.ble);
    _beginConnectionAttempt(
      mode: ConnectionMode.ble,
      deviceId: device.remoteId.toString(),
      deviceName: device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown',
    );
    debugPrint('✅ [Provider] Device info updated to connecting state');

    debugPrint('🔵 [Provider] Calling BLE service connect()...');
    final success = await _bleService.connect(device);

    if (success) {
      debugPrint('✅ [Provider] BLE service connect() returned success');
    } else {
      debugPrint('❌ [Provider] BLE service connect() returned failure');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: ConnectionState.error,
      );
      notifyListeners();
    }
    return success;
  }

  /// Connect to a MeshCore device over TCP/WiFi (port 5000)
  Future<bool> connectTcp(String host, int port) async {
    debugPrint('🌐 [Provider] connectTcp() $host:$port');
    await _prepareForConnectionSwitch(ConnectionMode.tcp);

    // Create fresh TCP service and wire its callbacks
    await _disposeTcpService();
    _tcpService = MeshCoreTcpService();
    _wireServiceCallbacks(_tcpService!);
    _beginConnectionAttempt(
      mode: ConnectionMode.tcp,
      deviceId: '$host:$port',
      deviceName: host,
      tcpHost: host,
    );

    final success = await _tcpService!.connect(host, port);
    if (!success) {
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: ConnectionState.error,
      );
      notifyListeners();
    }
    return success;
  }

  /// Disconnect from TCP/WiFi device
  Future<void> disconnectTcp() async {
    await _disposeTcpService();
    _resetConnectionSession();
  }

  /// Connect via USB serial using a pre-configured [MeshCoreSerialService].
  ///
  /// The caller is responsible for opening the serial port and wiring
  /// [service.writeRaw] + [service.feedRawBytes] before calling this.
  /// After this call succeeds, [service.markConnected()] has already run.
  Future<bool> connectSerial({
    required MeshCoreSerialService service,
    required Future<void> Function() disconnectTransport,
    required String deviceId,
    required String deviceName,
  }) async {
    debugPrint('🔌 [Provider] connectSerial()');
    await _prepareForConnectionSwitch(ConnectionMode.usb);
    await _disposeSerialService();
    _serialService = service;
    _serialDisconnectTransport = disconnectTransport;
    _wireServiceCallbacks(_serialService!);
    _beginConnectionAttempt(
      mode: ConnectionMode.usb,
      deviceId: deviceId,
      deviceName: deviceName,
    );

    // markConnected() should already have been called by the transport.
    // If it hasn't, the service won't be connected yet.
    if (!service.isConnected) {
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: ConnectionState.error,
      );
      await _disposeSerialService();
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Disconnect from USB serial device.
  Future<void> disconnectSerial() async {
    await _disposeSerialService();
    _resetConnectionSession();
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _deviceInfo = _deviceInfo.copyWith(
      connectionState: ConnectionState.disconnecting,
    );
    notifyListeners();

    if (_connectionMode == ConnectionMode.tcp) {
      await disconnectTcp();
      return;
    }
    if (_connectionMode == ConnectionMode.usb) {
      await disconnectSerial();
      return;
    }

    await _bleService.disconnect();
    _resetConnectionSession();
  }

  /// Reset message sync state so the next connect/reconnect can sync cleanly.
  void _resetSyncState() {
    if (_syncResponseCompleter != null &&
        !_syncResponseCompleter!.isCompleted) {
      _syncResponseCompleter!.complete(false);
    }
    _syncResponseCompleter = null;
    if (_contactsSyncCompleter != null &&
        !_contactsSyncCompleter!.isCompleted) {
      _contactsSyncCompleter!.complete();
    }
    _contactsSyncCompleter = null;
    _isSyncingMessages = false;
    _syncRequestedWhileBusy = false;
    _noMoreMessages = false;
    _pendingAutomaticMessageSync = false;
  }

  /// Cancel ongoing reconnection attempts
  /// This is useful when the user wants to manually disconnect during reconnection
  void cancelReconnection() {
    debugPrint('🔴 [Provider] User requested cancellation of reconnection');
    disconnect();
  }

  /// Start periodic cleanup of stale ACK mappings
  ///
  /// Runs every minute to clean up ACK tags that haven't received
  /// delivery confirmation within 5 minutes.
  void _startAckCleanupTimer() {
    _stopAckCleanupTimer(); // Cancel any existing timer first

    debugPrint(
      '🧹 [ConnectionProvider] Starting ACK cleanup timer (1 minute interval)',
    );
    _ackCleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final cleanedCount = _messageDeliveryTracker.cleanupStaleAcks();
      if (cleanedCount > 0) {
        debugPrint(
          '🧹 [ConnectionProvider] Cleaned up $cleanedCount stale ACK mappings',
        );
      }
    });
  }

  /// Stop periodic cleanup timer
  void _stopAckCleanupTimer() {
    _ackCleanupTimer?.cancel();
    _ackCleanupTimer = null;
  }

  /// Get ACK tracking diagnostics
  ///
  /// Returns diagnostic information about pending ACKs for debugging.
  /// Useful for troubleshooting message delivery issues.
  Map<String, dynamic> getAckTrackingDiagnostics() {
    return _messageDeliveryTracker.getDiagnostics();
  }

  /// Get contacts from device.
  ///
  /// Waits for the device to finish sending all contacts (up to 5 s timeout)
  /// so callers don't need an arbitrary delay.
  Future<void> getContacts() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _isContactsSyncInProgress = true;
      _contactsSyncCompleter = Completer<void>();
      await _activeService.getContacts();
      await _contactsSyncCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            '⚠️ [Provider] Contacts sync timeout - proceeding without full list',
          );
        },
      );
    } catch (e) {
      _isContactsSyncInProgress = false;
      _error = 'Failed to get contacts: $e';
      notifyListeners();
    } finally {
      _isContactsSyncInProgress = false;
      _contactsSyncCompleter = null;
    }
  }

  /// Get a single contact by public key from device
  ///
  /// This is more efficient than getContacts() when you only need to refresh
  /// one specific contact (e.g., after receiving an advertisement or path update).
  ///
  /// The contact will be delivered via the onContactReceived callback.
  Future<void> getContact(Uint8List publicKey) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      _markSingleContactRequested(
        publicKey,
        source: ContactReceiveSource.requestedSingle,
      );
      await _activeService.getContactByKey(publicKey);
    } catch (e) {
      final errorText = e.toString();
      if (_error == 'Not found' || errorText.contains('Not found')) {
        _error = 'Not found';
        notifyListeners();
        return;
      }
      _error = 'Failed to get contact: $e';
      debugPrint(
        '⚠️ [Provider] Failed to get contact by key, falling back to full contact sync',
      );
      // Fallback to full contact sync if command not supported
      _isContactsSyncInProgress = true;
      await _activeService.getContacts();
      notifyListeners();
    }
  }

  /// Import a received advert by public key, then fetch the full contact.
  ///
  /// This tells the firmware to store the advert it received, making the
  /// contact available for [getContact]/[previewContact] with full details
  /// (name, type, location, etc.).
  Future<void> importReceivedAdvert(Uint8List publicKey) async {
    if (!_activeService.isConnected) return;

    try {
      await _activeService.importReceivedAdvert(publicKey);
    } catch (e) {
      debugPrint(
        '⚠️ [Provider] importReceivedAdvert failed for ${_publicKeyToHex(publicKey)}: $e',
      );
    }
  }

  Future<void> previewContact(Uint8List publicKey) async {
    if (!_activeService.isConnected) {
      return;
    }
    _prunePreviewContactMisses();
    final keyHex = _publicKeyToHex(publicKey);
    if (_previewContactMisses.containsKey(keyHex)) {
      return;
    }

    try {
      _markSingleContactRequested(
        publicKey,
        source: ContactReceiveSource.preview,
      );
      await _activeService.getContactByKey(publicKey);
    } catch (e) {
      debugPrint(
        '⚠️ [Provider] Preview contact fetch failed for ${_publicKeyToHex(publicKey)}: $e',
      );
    }
  }

  ContactReceiveSource _classifyContactReceiveSource(Uint8List publicKey) {
    _prunePendingSingleContactRequests();
    final keyHex = _publicKeyToHex(publicKey);
    if (_isContactsSyncInProgress) {
      return ContactReceiveSource.sync;
    }
    final request = _pendingSingleContactRequests.remove(keyHex);
    if (request != null &&
        DateTime.now().difference(request.requestedAt) <=
            _singleContactRequestWindow) {
      return request.source;
    }
    return ContactReceiveSource.advert;
  }

  void _markSingleContactRequested(
    Uint8List publicKey, {
    required ContactReceiveSource source,
  }) {
    _prunePendingSingleContactRequests();
    _pendingSingleContactRequests[_publicKeyToHex(publicKey)] =
        _PendingContactRequest(source: source, requestedAt: DateTime.now());
  }

  void _prunePendingSingleContactRequests() {
    if (_pendingSingleContactRequests.isEmpty) {
      return;
    }

    final now = DateTime.now();
    _pendingSingleContactRequests.removeWhere(
      (_, request) =>
          now.difference(request.requestedAt) > _singleContactRequestWindow,
    );
  }

  void _prunePreviewContactMisses() {
    if (_previewContactMisses.isEmpty) {
      return;
    }
    final now = DateTime.now();
    _previewContactMisses.removeWhere(
      (_, timestamp) => now.difference(timestamp) > _previewContactMissTtl,
    );
  }

  /// Sync all channels from device
  Future<void> syncChannels({int? maxChannels}) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // Use maxChannels from device info if available, otherwise default to 40
      final channelCount = maxChannels ?? _deviceInfo.maxChannels ?? 40;
      debugPrint(
        '📻 [Provider] Syncing channels with tolerant per-slot reads (1-${channelCount - 1})...',
      );

      for (int i = 1; i < channelCount; i++) {
        try {
          await _activeService.getChannel(i);
        } catch (e) {
          debugPrint(
            '⚠️ [Provider] Channel sync skipped slot $i after read failure: $e',
          );
        }
      }

      debugPrint('✅ [Provider] Channel sync complete');
    } catch (e) {
      _error = 'Failed to sync channels: $e';
      notifyListeners();
    }
  }

  /// Configure the default public channel (channel 0) with the well-known secret
  ///
  /// This MUST be called after connecting to the device and before sending any
  /// channel messages. Without this configuration, channel messages will fail
  /// with ERR_CODE_NOT_FOUND.
  ///
  /// The public channel uses a well-known pre-shared key that all MeshCore
  /// devices use for the default public channel.
  Future<void> configureDefaultPublicChannel() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      debugPrint(
        '📻 [Provider] Configuring default public channel (channel 0)',
      );
      debugPrint(
        '  Using secret: ${MeshCoreConstants.defaultPublicChannelSecret.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}',
      );
      await _activeService.setChannel(
        channelIdx: 0,
        channelName: 'Public Channel',
        secret: MeshCoreConstants.defaultPublicChannelSecret,
      );
      debugPrint('✅ [Provider] Public channel configured successfully');
    } catch (e) {
      _error = 'Failed to configure public channel: $e';
      debugPrint('❌ [Provider] Public channel configuration failed: $e');
      debugPrint(
        '  This may be normal if the channel is pre-configured in firmware',
      );
      notifyListeners();
      rethrow; // Re-throw to notify caller of failure
    }
  }

  /// Find next available empty channel slot (1-39)
  ///
  /// Returns the channel index of the first empty slot, or null if all slots are in use.
  /// Skips slot 0 (reserved for Public Channel).
  /// Callback to get channel info for empty slot detection
  /// This should be set by AppProvider to query ChannelsProvider
  Function(int channelIdx)? getChannelInfo;

  @visibleForTesting
  static bool channelHasConfiguredSecret(Uint8List secret) {
    return secret.any((byte) => byte != 0);
  }

  @visibleForTesting
  static bool isDuplicateChannelName({
    required String requestedName,
    required String existingName,
  }) {
    return requestedName.startsWith('#') && existingName == requestedName;
  }

  @visibleForTesting
  static int? firstAvailableChannelSlot({
    required Set<int> occupiedIndices,
    required int maxChannels,
  }) {
    for (int i = 1; i < maxChannels; i++) {
      if (!occupiedIndices.contains(i)) {
        return i;
      }
    }
    return null;
  }

  bool _channelSlotIsOccupied(Object channel) {
    final channelName = (channel as dynamic).name as String?;
    final secret = (channel as dynamic).secret;
    final hasConfiguredSecret =
        secret is Uint8List && channelHasConfiguredSecret(secret);
    return (channelName != null && channelName.isNotEmpty) ||
        hasConfiguredSecret;
  }

  /// Check if a specific channel slot is empty
  Future<bool> isChannelSlotEmpty(int channelIdx) async {
    if (!_activeService.isConnected) {
      return false;
    }

    try {
      // First check if we already have info about this channel
      if (getChannelInfo != null) {
        final channel = getChannelInfo!(channelIdx);
        if (channel != null) {
          return !_channelSlotIsOccupied(channel);
        }
      }

      // If not cached, query the device (awaits the BLE response)
      await _activeService.getChannel(channelIdx);

      // Check again after query
      if (getChannelInfo != null) {
        final channel = getChannelInfo!(channelIdx);
        if (channel != null) {
          return !_channelSlotIsOccupied(channel);
        }
      }

      // If we still have no authoritative answer after an on-device query,
      // treat the slot as occupied/unknown so we never overwrite a channel
      // because of stale or delayed state propagation.
      debugPrint(
        '   ⚠️  Slot $channelIdx state is still unknown after query; refusing to treat it as empty',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [Provider] Failed to check slot $channelIdx: $e');
      if (_isEmptyChannelQueryError(e)) {
        debugPrint(
          '   ℹ️  Treating slot $channelIdx as empty because the device reported it was not found',
        );
        return true;
      }
      return false;
    }
  }

  bool _isEmptyChannelQueryError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('not found');
  }

  bool _isChannelRefreshTimeoutError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('0x1f') && message.contains('timed out');
  }

  bool shouldTreatChannelInfoAsDeleted(
    int channelIdx,
    String channelName,
    Uint8List secret,
  ) {
    final isEmptyInfo =
        channelIdx != 0 &&
        channelName.isEmpty &&
        secret.every((byte) => byte == 0);
    if (!isEmptyInfo) {
      return false;
    }

    return _pendingDeletedChannelIndices.remove(channelIdx);
  }

  Set<int> _syncedOccupiedChannelIndices({required int maxChannels}) {
    if (getChannelInfo == null) {
      throw Exception('Channel state is unavailable');
    }

    final occupiedIndices = <int>{};
    for (int i = 1; i < maxChannels; i++) {
      final channel = getChannelInfo!(i);
      if (channel != null && _channelSlotIsOccupied(channel)) {
        occupiedIndices.add(i);
      }
    }
    return occupiedIndices;
  }

  Future<int?> findNextEmptyChannelSlot() async {
    if (!_activeService.isConnected) {
      throw Exception('Not connected to device');
    }

    try {
      debugPrint('🔍 [Provider] Finding next empty channel slot...');

      // maxChannels from device info, or default to 40
      final maxChannels = _deviceInfo.maxChannels ?? 40;
      final maxCustomChannels = maxChannels > 0 ? maxChannels - 1 : 0;

      final occupiedIndices = _syncedOccupiedChannelIndices(
        maxChannels: maxChannels,
      );
      final emptySlot = firstAvailableChannelSlot(
        occupiedIndices: occupiedIndices,
        maxChannels: maxChannels,
      );
      if (emptySlot != null) {
        debugPrint('   ✅ Found empty slot from synced channels: $emptySlot');
        return emptySlot;
      }

      debugPrint(
        '   ❌ Synced channels report all custom slots occupied ($maxCustomChannels total)',
      );
      return null;
    } catch (e) {
      debugPrint('❌ [Provider] Failed to find empty channel slot: $e');
      rethrow;
    }
  }

  /// Create a new channel with automatic slot assignment
  ///
  /// Finds the next available empty channel slot and configures it with the
  /// provided name and secret. The secret is converted from an ASCII string
  /// to a 16-byte key using MD5 hashing.
  ///
  /// [channelName] - Name for the channel (max 31 characters)
  /// [channelSecret] - ASCII password for the channel (will be hashed to 16 bytes)
  ///
  /// Throws an exception if all slots are in use or if the channel configuration fails.
  Future<void> createChannel({
    required String channelName,
    required String channelSecret,
  }) async {
    if (!_activeService.isConnected) {
      throw Exception('Not connected to device');
    }

    try {
      debugPrint('📻 [Provider] Creating new channel...');
      debugPrint('  Name: $channelName');

      final bool isHashChannel = channelName.startsWith('#');
      final secretBytes = isHashChannel
          ? _generateHashChannelSecret(channelName)
          : _convertSecretToBytes(channelSecret);

      await _createChannelWithSecretBytes(
        channelName: channelName,
        secretBytes: secretBytes,
        isHashChannel: isHashChannel,
      );
    } catch (e) {
      _error = 'Failed to create channel: $e';
      debugPrint('❌ [Provider] Channel creation failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _createChannelWithSecretBytes({
    required String channelName,
    required List<int> secretBytes,
    required bool isHashChannel,
  }) async {
    final maxChannels = _deviceInfo.maxChannels ?? 40;

    if (getChannelInfo != null) {
      for (int i = 1; i < maxChannels; i++) {
        final channel = getChannelInfo!(i);
        if (channel == null) {
          continue;
        }

        final existingName = (channel as dynamic).name as String?;
        if (existingName != null &&
            existingName.isNotEmpty &&
            isDuplicateChannelName(
              requestedName: channelName,
              existingName: existingName,
            )) {
          debugPrint(
            '  ⚠️  Hash channel "$channelName" already exists in slot $i',
          );
          throw Exception(
            'Channel "$channelName" already exists. Hash channels cannot be duplicated.',
          );
        }
      }
    }

    final maxCustomChannels = maxChannels > 0 ? maxChannels - 1 : 0;
    final slotIdx = await findNextEmptyChannelSlot();
    if (slotIdx == null) {
      throw Exception(
        'All channel slots are in use (maximum $maxCustomChannels custom channels)',
      );
    }

    debugPrint(
      '  Channel type: ${isHashChannel ? "Hash channel (#)" : "Private channel"}',
    );
    debugPrint('  Using empty slot: $slotIdx');

    try {
      await _activeService.setChannel(
        channelIdx: slotIdx,
        channelName: channelName,
        secret: secretBytes,
      );

      // Reconcile local state from the device after the write completes,
      // matching the delete flow so channel/contact lists refresh immediately.
      await _activeService.getChannel(slotIdx);
    } catch (e) {
      if (_isChannelRefreshTimeoutError(e)) {
        debugPrint(
          '⚠️ [Provider] CMD_GET_CHANNEL verification timed out after SET_CHANNEL; assuming the channel write succeeded',
        );
        onChannelInfoReceived?.call(
          slotIdx,
          channelName,
          Uint8List.fromList(secretBytes),
          null,
        );
      } else {
        rethrow;
      }
    }

    debugPrint('✅ [Provider] Channel created successfully in slot $slotIdx');
  }

  /// Delete a channel and remove it from the UI
  ///
  /// Clears the channel slot on the device and removes it from both
  /// ChannelsProvider and ContactsProvider. The slot becomes available for reuse.
  ///
  /// [channelIdx] - Channel slot index (1-39). Channel 0 (public) cannot be deleted.
  ///
  /// Throws an exception if the channel cannot be deleted or if channel 0 is specified.
  Future<void> deleteChannel(int channelIdx) async {
    if (!_activeService.isConnected) {
      throw Exception('Not connected to device');
    }

    if (channelIdx == 0) {
      throw Exception('Cannot delete the public channel');
    }

    try {
      debugPrint('🗑️  [Provider] Deleting channel in slot $channelIdx...');
      _pendingDeletedChannelIndices.add(channelIdx);

      // Delete channel on device (sets empty name and zeroed secret)
      await _activeService.deleteChannel(channelIdx);

      debugPrint(
        '✅ [Provider] Channel deleted successfully from slot $channelIdx',
      );

      // Soft-reset local UI state immediately, matching meshcore-open's
      // behavior, then reconcile with an on-device refresh below.
      onChannelInfoReceived?.call(channelIdx, '', Uint8List(16), null);

      // Refresh channel from device to reconcile UI state.
      // BLE commands are processed in order by firmware, so the
      // getChannel response reflects the completed deletion.
      await _activeService.getChannel(channelIdx);
    } catch (e) {
      _pendingDeletedChannelIndices.remove(channelIdx);
      _error = 'Failed to delete channel: $e';
      debugPrint('❌ [Provider] Channel deletion failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setChannelSlot({
    required int channelIdx,
    required String channelName,
    required Uint8List secret,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setChannel(
        channelIdx: channelIdx,
        channelName: channelName,
        secret: secret,
      );
      await _activeService.getChannel(channelIdx);
    } catch (e) {
      _error = 'Failed to set channel: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Generate secret for hash channel using SHA256
  /// Same algorithm as Channel model for consistency
  /// Python equivalent: hashlib.sha256(channel_name.encode()).digest()[0:16]
  List<int> _generateHashChannelSecret(String channelName) {
    final bytes = utf8.encode(channelName);
    final digest = sha256.convert(bytes);
    return digest.bytes.sublist(0, 16);
  }

  /// Convert ASCII secret string to 16-byte key using MD5 hash
  /// Used for private channels with explicit secrets
  List<int> _convertSecretToBytes(String asciiSecret) {
    // Use MD5 hash to convert any length ASCII string to exactly 16 bytes
    // This provides a deterministic and secure way to generate channel keys
    return md5.convert(utf8.encode(asciiSecret)).bytes;
  }

  /// Add or update a contact on the companion radio
  ///
  /// This manually adds a contact to the radio's internal contact table.
  /// Useful when a room contact was deleted or never advertised yet.
  Future<void> addOrUpdateContact(Contact contact) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _activeService.addOrUpdateContact(contact);
    } catch (e) {
      _error = 'Failed to add/update contact: $e';
      notifyListeners();
    }
  }

  Future<void> importContactAdvert(Uint8List contactAdvertFrame) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _activeService.importContact(contactAdvertFrame);
    } catch (e) {
      _error = 'Failed to import contact: $e';
      notifyListeners();
    }
  }

  /// Send text message to contact
  ///
  /// Returns true if the message was successfully sent to the BLE service.
  /// Note: This doesn't mean the message was delivered over the mesh network,
  /// only that it was queued on the companion radio.
  ///
  /// [messageId] - optional message ID to track delivery status
  /// [contact] - optional contact object for path status logging
  /// [retryAttempt] - retry attempt number (0 = first send, >0 = retries)
  Future<bool> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    String? messageId,
    Contact? contact,
    int retryAttempt = 0,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    var effectiveContact = contact;
    effectiveContact ??= resolveContactForDmCallback?.call(contactPublicKey);
    if (messageId != null &&
        effectiveContact != null &&
        prepareDirectMessageSendCallback != null) {
      effectiveContact = await prepareDirectMessageSendCallback!(
        messageId: messageId,
        contact: effectiveContact,
        retryAttempt: retryAttempt,
      );
    }

    // CRITICAL: Check firmware ACK limit (8 max in circular buffer)
    // Rate limit at 7 to stay under the limit
    if (_messageDeliveryTracker.shouldRateLimit) {
      final pendingCount = _messageDeliveryTracker.pendingCount;
      debugPrint(
        '⚠️ [ConnectionProvider] Rate limit hit: $pendingCount pending ACKs (max 7)',
      );
      debugPrint(
        '⚠️ Firmware only tracks 8 ACKs - waiting for delivery confirmation...',
      );

      // Wait for a slot to free up (delivery/timeout), max 500ms
      await _messageDeliveryTracker.waitForSlot();

      if (_messageDeliveryTracker.shouldRateLimit) {
        debugPrint(
          '⚠️ Still at limit after wait - proceeding anyway (may lose ACK tracking)',
        );
      }
    }

    try {
      // Log path status and retry info
      if (effectiveContact != null) {
        if (retryAttempt > 0) {
          debugPrint(
            '🔄 [ConnectionProvider] Sending message to ${effectiveContact.advName} (retry $retryAttempt)',
          );
        } else {
          debugPrint(
            '📤 [ConnectionProvider] Sending message to ${effectiveContact.advName}',
          );
        }
        debugPrint('   Type: ${effectiveContact.type.displayName}');
        debugPrint('   Path status: ${effectiveContact.routeSummary}');
        if (effectiveContact.routeHasPath) {
          debugPrint(
            '   ✅ Using learned path (${effectiveContact.routeHopCount} hop(s), ${effectiveContact.routeHashSize}-byte hashes)',
          );
        } else {
          debugPrint('   ⚠️ No path available - will use flood mode');
        }
      } else if (retryAttempt > 0) {
        debugPrint(
          '🔄 [ConnectionProvider] Sending message (retry $retryAttempt)',
        );
      }

      // Track pending operation for auto-recovery (if contact not found in radio)
      if (effectiveContact != null) {
        final operationId = contactPublicKey
            .sublist(0, 6)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':');
        _pendingSendOperations[operationId] = _PendingSendOperation(
          contactPublicKey: contactPublicKey,
          text: text,
          messageId: messageId,
          contact: effectiveContact,
          retryAttempt: retryAttempt,
        );
        debugPrint(
          '  📝 Tracked pending operation for auto-recovery: $operationId',
        );
      }

      // IMPORTANT: Track pending message BEFORE sending to avoid race condition
      // The SENT response can arrive so quickly that if we track after sending,
      // the callback will fire before we add the message ID to the queue.
      //
      // NOTE: For grouped messages, we no longer need complex contact-keyed tracking.
      // The MessagesProvider now uses simple ACK tag → recipientPublicKey mapping.
      // We still track here for the SENT response callback to work.
      if (messageId != null) {
        _messageDeliveryTracker.trackPendingDirectMessage(
          messageId,
          contactPublicKey,
        );
        debugPrint('  📝 Tracked pending message: $messageId');
      }

      // Send the message with retry attempt info
      await _activeService.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
        attempt: retryAttempt,
      );

      // Clear pending operation — any ERR_CODE_NOT_FOUND has already been
      // handled synchronously by onContactNotFound before sendTextMessage returns.
      if (effectiveContact != null) {
        final operationId = contactPublicKey
            .sublist(0, 6)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':');
        _pendingSendOperations.remove(operationId);
      }

      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Send channel message
  ///
  /// [messageId] - optional message ID to track delivery status
  /// Note: Channel messages are ephemeral (not persisted), so they're marked
  /// as "sent" immediately upon receiving OK response from the device.
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    String? messageId,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      debugPrint('📨 [ConnectionProvider] sendChannelMessage called:');
      debugPrint('  Channel: $channelIdx');
      debugPrint('  Text: $text');
      debugPrint('  MessageID: $messageId');

      await _activeService.sendChannelMessage(
        channelIdx: channelIdx,
        text: text,
      );

      debugPrint('✅ [ConnectionProvider] BLE send completed');
      debugPrint(
        '  Checking messageId: ${messageId != null ? "Present ($messageId)" : "NULL"}',
      );

      // Channel messages are ephemeral (not persisted) - mark as "sent" immediately
      // They don't have ACK/TAG mechanism like direct messages
      if (messageId != null) {
        debugPrint('✅ [ConnectionProvider] Channel message sent successfully');
        debugPrint('  Message ID: $messageId');
        debugPrint('  onMessageSent callback exists: ${onMessageSent != null}');

        // Track for echo detection
        // The BLE handler will capture the packet via LOG_RX_DATA and associate it
        debugPrint('  Calling trackSentChannelMessage...');
        _activeService.trackSentChannelMessage(
          messageId,
          channelIdx: channelIdx,
          plainText: text,
        );
        debugPrint('  trackSentChannelMessage completed');

        // Use a dummy ACK tag (0) and timeout (0) for channel messages
        // This will trigger the callback to mark the message as "sent"
        debugPrint('  Calling onMessageSent callback...');
        onMessageSent?.call(messageId, 0, 0);
        debugPrint('  onMessageSent callback completed');
      }
    } catch (e) {
      _error = 'Failed to send channel message: $e';
      notifyListeners();
    }
  }

  /// Send a raw binary voice packet directly to a contact (cmdSendRawData, code 25).
  /// Only works for contacts with a known direct route (outPathLen >= 0).
  Future<void> sendRawVoicePacket({
    required Uint8List contactPath,
    required int contactPathLen,
    required Uint8List payload,
  }) async {
    if (!_activeService.isConnected) return;
    await _activeService.sendRawVoicePacket(
      contactPathLen: contactPathLen,
      contactPath: contactPath,
      payload: payload,
    );
  }

  /// Send a raw private zero-hop payload.
  ///
  /// This wraps the raw custom transport using an empty path to match the
  /// firmware's private multicast behavior.
  Future<void> sendRawPrivateMulticast(Uint8List payload) async {
    if (!_activeService.isConnected) return;
    await _activeService.sendRawVoicePacket(
      contactPathLen: 0,
      contactPath: Uint8List(0),
      payload: payload,
    );
  }

  Future<void> sendChannelData({
    required int channelIdx,
    required int dataType,
    required Uint8List payload,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.sendChannelData(
        channelIdx: channelIdx,
        dataType: dataType,
        payload: payload,
      );
    } catch (e) {
      _error = 'Failed to send channel data: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Request telemetry from contact
  ///
  /// COMPATIBILITY NOTE: This method sends CMD_SEND_TELEMETRY_REQ (39).
  /// Depending on device firmware version, the response will be either:
  /// - PUSH_CODE_TELEMETRY_RESPONSE (0x8B) - older firmware
  /// - PUSH_CODE_BINARY_RESPONSE (0x8C) - newer firmware
  ///
  /// Both response types are handled via callbacks:
  /// - onTelemetryReceived (for 0x8B)
  /// - onBinaryResponse (for 0x8C)
  ///
  /// The app properly handles BOTH response types, so this method is NOT
  /// deprecated and should continue to be used for telemetry requests.
  ///
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  Future<void> requestTelemetry(
    Uint8List contactPublicKey, {
    bool zeroHop = false,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.requestTelemetry(contactPublicKey, zeroHop: zeroHop);
    } catch (e) {
      _error = 'Failed to request telemetry: $e';
      notifyListeners();
    }
  }

  /// Smart ping with automatic fallback to flooding
  ///
  /// Sends a telemetry request (ping) to a contact, and if no response is
  /// received within timeout, automatically retries with flooding mode.
  ///
  /// Returns a PingResult with information about the response.
  ///
  /// [contact] - the contact to ping (used to determine if path exists)
  /// [onRetryWithFlooding] - optional callback when fallback to flooding occurs
  Future<PingResult> smartPing({
    required Uint8List contactPublicKey,
    required bool hasPath,
    Function()? onRetryWithFlooding,
  }) async {
    final pingKey = _publicKeyToHex(contactPublicKey);
    final pendingPing = _pendingSmartPings[pingKey];
    if (pendingPing != null) {
      debugPrint('ℹ️ [Provider] Joining in-flight ping for $pingKey');
      return pendingPing;
    }

    final future = _isSelfPublicKey(contactPublicKey)
        ? _runSelfTelemetryPing(contactPublicKey)
        : _runSmartPing(
            contactPublicKey: contactPublicKey,
            hasPath: hasPath,
            onRetryWithFlooding: onRetryWithFlooding,
          );
    _pendingSmartPings[pingKey] = future;
    notifyListeners();

    try {
      return await future;
    } finally {
      _pendingSmartPings.remove(pingKey);
      notifyListeners();
    }
  }

  Future<PingResult> _runSmartPing({
    required Uint8List contactPublicKey,
    required bool hasPath,
    Function()? onRetryWithFlooding,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }

    // First attempt: Use zeroHop (direct) if we have a path, otherwise use flooding
    final bool firstAttemptDirect = hasPath;

    try {
      // Track the ping request
      final pingFuture = _pingTracker.trackPing(
        publicKey: contactPublicKey,
        wasDirectAttempt: firstAttemptDirect,
      );

      // Send the ping
      await _activeService.requestTelemetry(
        contactPublicKey,
        zeroHop: firstAttemptDirect,
      );

      // Wait for response or timeout
      final bool gotResponse = await pingFuture;

      if (gotResponse) {
        // Success on first attempt
        return PingResult(
          success: true,
          usedFlooding: !firstAttemptDirect,
          timedOut: false,
        );
      }

      // First attempt timed out - retry with flooding if first was direct
      if (firstAttemptDirect) {
        debugPrint(
          '⚠️ [Provider] Ping timeout on direct attempt, retrying with flooding...',
        );
        onRetryWithFlooding?.call();

        // Track the retry
        final retryFuture = _pingTracker.trackPing(
          publicKey: contactPublicKey,
          wasDirectAttempt: false,
        );

        // Retry with flooding.
        await _activeService.requestTelemetry(contactPublicKey, zeroHop: false);

        // Wait for response or timeout
        final bool gotRetryResponse = await retryFuture;

        return PingResult(
          success: gotRetryResponse,
          usedFlooding: true,
          timedOut: !gotRetryResponse,
          retriedWithFlooding: true,
        );
      }

      // First attempt was already flooding and it timed out
      return PingResult(success: false, usedFlooding: true, timedOut: true);
    } catch (e) {
      _error = 'Failed to ping contact: $e';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }
  }

  Future<PingResult> _runSelfTelemetryPing(Uint8List devicePublicKey) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }

    try {
      final pingFuture = _pingTracker.trackPing(
        publicKey: devicePublicKey,
        wasDirectAttempt: true,
      );

      // Firmware treats a 4-byte telemetry request as "self telemetry".
      await _activeService.requestTelemetry(Uint8List(0), zeroHop: true);

      final gotResponse = await pingFuture;
      return PingResult(
        success: gotResponse,
        usedFlooding: false,
        timedOut: !gotResponse,
      );
    } catch (e) {
      _error = 'Failed to request self telemetry: $e';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }
  }

  String _publicKeyToHex(Uint8List publicKey) {
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  bool _isSelfPublicKey(Uint8List publicKey) {
    final selfKey = _deviceInfo.publicKey;
    if (selfKey == null || selfKey.length != publicKey.length) {
      return false;
    }

    for (var i = 0; i < publicKey.length; i++) {
      if (selfKey[i] != publicKey[i]) {
        return false;
      }
    }
    return true;
  }

  /// Send binary request to contact (modern replacement for requestTelemetry)
  ///
  /// Supports multiple request types:
  /// - Telemetry data (use MeshCoreConstants.binaryReqGetTelemetryData)
  /// - Average/min/max telemetry (use MeshCoreConstants.binaryReqGetAvgMinMax)
  /// - Access list (use MeshCoreConstants.binaryReqGetAccessList)
  /// - Neighbors list (use MeshCoreConstants.binaryReqGetNeighbours)
  ///
  /// Response arrives via onBinaryResponse callback with matching tag.
  ///
  /// Example - request telemetry:
  /// ```dart
  /// connectionProvider.onBinaryResponse = (prefix, tag, data) {
  ///   // Parse telemetry data (Cayenne LPP format)
  ///   final telemetry = CayenneLppParser.parse(data);
  /// };
  /// await connectionProvider.requestBinary(
  ///   contactPublicKey: contact.publicKey,
  ///   requestType: MeshCoreConstants.binaryReqGetTelemetryData,
  /// );
  /// ```
  Future<void> requestBinary({
    required Uint8List contactPublicKey,
    required int requestType,
    Uint8List? additionalParams,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // Build request data: request type byte + optional params
      final requestData = Uint8List.fromList([
        requestType,
        if (additionalParams != null) ...additionalParams,
      ]);

      await _activeService.sendBinaryRequest(
        contactPublicKey: contactPublicKey,
        requestData: requestData,
      );
    } catch (e) {
      _error = 'Failed to send binary request: $e';
      notifyListeners();
    }
  }

  Future<void> discoverNodeType({
    required int advertType,
    bool prefixOnly = false,
    int since = 0,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    final random = Random.secure();
    final tagBytes = Uint8List.fromList(
      List<int>.generate(4, (_) => random.nextInt(256)),
    );
    final payload = BytesBuilder(copy: false)
      ..addByte(_controlTypeNodeDiscoverReq | (prefixOnly ? 0x01 : 0x00))
      ..addByte(1 << advertType)
      ..add(tagBytes)
      ..add([
        since & 0xFF,
        (since >> 8) & 0xFF,
        (since >> 16) & 0xFF,
        (since >> 24) & 0xFF,
      ]);

    try {
      await _activeService.sendControlData(payload.toBytes());
    } catch (e) {
      _error = 'Failed to send node discovery request: $e';
      notifyListeners();
    }
  }

  /// Get device time from companion radio to detect clock drift
  Future<void> getDeviceTime() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.getDeviceTime();
    } catch (e) {
      _error = 'Failed to get device time: $e';
      notifyListeners();
    }
  }

  /// Set device time to current time
  Future<void> syncDeviceTime() async {
    if (!_activeService.isConnected) return;

    try {
      await _activeService.setDeviceTime();
    } catch (e) {
      _error = 'Failed to sync time: $e';
      notifyListeners();
    }
  }

  Future<void> factoryResetDevice() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _activeService.factoryReset();
    } catch (e) {
      _error = 'Failed to wipe device data: $e';
      notifyListeners();
    }
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setAdvertName(name);
    } catch (e) {
      _error = 'Failed to set name: $e';
      notifyListeners();
    }
  }

  /// Set advertised position
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setAdvertLatLon(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      _error = 'Failed to set position: $e';
      notifyListeners();
    }
  }

  /// Send self advertisement to mesh network
  ///
  /// Broadcasts the device's current advertisement data (name, location, etc.)
  /// to the mesh network. Use this after updating position or name to notify
  /// other nodes of the change.
  ///
  /// [floodMode] - if true, broadcast to entire mesh (default for SAR ops)
  ///               if false, only send to direct neighbors (zero-hop)
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isAdvertInProgress) return;
      // Throttle rapid advert requests
      final now = DateTime.now();
      if (_lastAdvertRequestedAt != null) {
        final elapsed = now.difference(_lastAdvertRequestedAt!);
        if (elapsed < _minAdvertInterval) {
          final wait = _minAdvertInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isAdvertInProgress = true;
      await _activeService.sendSelfAdvert(floodMode: floodMode);
      _lastAdvertRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send advertisement: $e';
      notifyListeners();
    } finally {
      _isAdvertInProgress = false;
    }
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency,
    required int bandwidth,
    required int spreadingFactor,
    required int codingRate,
    bool? repeat,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setRadioParams(
        frequency: frequency,
        bandwidth: bandwidth,
        spreadingFactor: spreadingFactor,
        codingRate: codingRate,
        repeat: repeat,
      );
    } catch (e) {
      _error = 'Failed to set radio params: $e';
      notifyListeners();
    }
  }

  /// Request the list of allowed repeat frequency ranges from the device (firmware v9+)
  Future<void> getAllowedRepeatFreq() async {
    if (!_activeService.isConnected) return;
    try {
      await _activeService.getAllowedRepeatFreq();
    } catch (e) {
      debugPrint('Failed to get allowed repeat freq: $e');
    }
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setTxPower(powerDbm);
    } catch (e) {
      _error = 'Failed to set TX power: $e';
      notifyListeners();
    }
  }

  /// Set other parameters (telemetry modes, advert location policy)
  Future<void> setOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocationPolicy,
    int multiAcks = 0,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setOtherParams(
        manualAddContacts: manualAddContacts,
        telemetryModes: telemetryModes,
        advertLocationPolicy: advertLocationPolicy,
        multiAcks: multiAcks,
      );
      _deviceInfo = _deviceInfo.copyWith(
        telemetryModes: telemetryModes,
        advertLocPolicy: advertLocationPolicy,
        multiAcks: multiAcks,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set other params: $e';
      notifyListeners();
    }
  }

  Future<void> getAutoaddConfig() async {
    if (_supportsAutoaddConfig == false) {
      return;
    }
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      final config = await _activeService.getAutoaddConfig();
      _supportsAutoaddConfig = true;
      _deviceInfo = _deviceInfo.copyWith(
        autoAddUsers: config['autoAddUsers'] as bool?,
        autoAddRepeaters: config['autoAddRepeaters'] as bool?,
        autoAddRoomServers: config['autoAddRoomServers'] as bool?,
        autoAddSensors: config['autoAddSensors'] as bool?,
        autoAddOverwriteOldest: config['autoAddOverwriteOldest'] as bool?,
        autoAddMaxHops: config['autoAddMaxHops'] as int?,
      );
      notifyListeners();
    } catch (e) {
      if (_isUnsupportedAutoaddConfigError(e)) {
        _supportsAutoaddConfig = false;
        _deviceInfo = _deviceInfo.copyWith(
          autoAddUsers: null,
          autoAddRepeaters: null,
          autoAddRoomServers: null,
          autoAddSensors: null,
          autoAddOverwriteOldest: null,
          autoAddMaxHops: null,
        );
        notifyListeners();
        return;
      }
      if (_isTransientAutoaddConfigError(e)) {
        debugPrint('Ignoring transient auto-add config error: $e');
        return;
      }
      _error = 'Failed to get auto-add config: $e';
      notifyListeners();
    }
  }

  Future<void> setAutoaddConfig({
    required bool autoAddUsers,
    required bool autoAddRepeaters,
    required bool autoAddRoomServers,
    required bool autoAddSensors,
    required bool overwriteOldest,
    int maxHops = 0,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setAutoaddConfig(
        autoAddUsers: autoAddUsers,
        autoAddRepeaters: autoAddRepeaters,
        autoAddRoomServers: autoAddRoomServers,
        autoAddSensors: autoAddSensors,
        overwriteOldest: overwriteOldest,
        maxHops: maxHops,
      );
      _deviceInfo = _deviceInfo.copyWith(
        autoAddUsers: autoAddUsers,
        autoAddRepeaters: autoAddRepeaters,
        autoAddRoomServers: autoAddRoomServers,
        autoAddSensors: autoAddSensors,
        autoAddOverwriteOldest: overwriteOldest,
        autoAddMaxHops: maxHops,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set auto-add config: $e';
      notifyListeners();
    }
  }

  Future<void> setPathHashMode(int mode) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.setPathHashMode(mode);
      _deviceInfo = _deviceInfo.copyWith(pathHashMode: mode);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set path hash mode: $e';
      notifyListeners();
    }
  }

  /// Export a contact as a meshcore:// share URL.
  /// Pass null to export self.
  Future<String?> exportContactUrl(Uint8List? publicKey) async {
    if (!_activeService.isConnected) return null;
    try {
      final frame = await _activeService.exportContact(publicKey);
      final hex = frame.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return 'meshcore://$hex';
    } catch (e) {
      debugPrint('⚠️ [Provider] exportContact failed: $e');
      _error = 'Failed to export contact: $e';
      notifyListeners();
      return null;
    }
  }

  /// Read custom variables from device (GPS mode, sensor settings, etc.)
  Future<Map<String, String>> getCustomVars() async {
    if (!_activeService.isConnected) {
      return {};
    }
    try {
      return await _activeService.getCustomVars();
    } catch (e) {
      debugPrint('⚠️ [Provider] getCustomVars failed: $e');
      return {};
    }
  }

  /// Set a custom variable on the device
  Future<void> setCustomVar(String key, String value) async {
    if (!_activeService.isConnected) return;
    try {
      await _activeService.setCustomVar(key, value);
    } catch (e) {
      _error = 'Failed to set $key: $e';
      notifyListeners();
    }
  }

  Future<void> refreshDeviceInfo() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // The device query command triggers a SelfInfo response
      await _activeService.refreshDeviceInfo();
      if (_supportsAutoaddConfig != false) {
        unawaited(getAutoaddConfig());
      }
      try {
        await _activeService.getAllowedRepeatFreq();
      } catch (_) {
        // Older firmware may not expose repeat frequency ranges.
      }
    } catch (e) {
      _error = 'Failed to refresh device info: $e';
      notifyListeners();
    }
  }

  bool _isUnsupportedAutoaddConfigError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unsupported command') ||
        message.contains('unsupported');
  }

  bool _isTransientAutoaddConfigError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('illegal argument');
  }

  /// Request battery and storage information
  ///
  /// Queries the companion radio for:
  /// - Battery voltage in millivolts
  /// - Used storage in KB (if available)
  /// - Total storage in KB (if available)
  ///
  /// Results arrive via onBatteryAndStorage callback and update deviceInfo.
  /// Request the companion device's own telemetry (GPS, temp, sensors).
  /// The response arrives via onTelemetryReceived with the device's own key.
  Future<void> requestSelfTelemetry() async {
    if (!_activeService.isConnected) return;
    try {
      // Firmware expects a 4-byte CMD_SEND_TELEMETRY_REQ frame for "self".
      await _activeService.requestTelemetry(Uint8List(0), zeroHop: true);
    } catch (e) {
      debugPrint('⚠️ [Provider] requestSelfTelemetry failed: $e');
    }
  }

  Future<void> getBatteryAndStorage() async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _activeService.getBatteryAndStorage();
    } catch (e) {
      _error = 'Failed to get battery and storage: $e';
      notifyListeners();
    }
  }

  /// Sync messages from device queue
  /// Call this repeatedly until no more messages are available
  Future<bool> syncNextMessage() async {
    // Prevent re-entrancy and too-fast triggers
    if (_isSyncingMessages) {
      // Another sync (single or loop) is in progress
      return false;
    }

    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    try {
      // Enforce a small gap between consecutive requests
      final now = DateTime.now();
      if (_lastSyncNextRequestedAt != null) {
        final elapsed = now.difference(_lastSyncNextRequestedAt!);
        if (elapsed < _minSyncNextInterval) {
          final remaining = _minSyncNextInterval - elapsed;
          await Future.delayed(remaining);
        }
      }

      _isSyncingMessages = true;
      await _activeService.syncNextMessage();
      _lastSyncNextRequestedAt = DateTime.now();
      return true;
    } catch (e) {
      _error = 'Failed to sync message: $e';
      notifyListeners();
      return false;
    } finally {
      _isSyncingMessages = false;
    }
  }

  /// Sync all waiting messages from device
  Future<int> syncAllMessages({bool force = false}) async {
    if (!force && !(canStartAutomaticMessageSyncCallback?.call() ?? true)) {
      _pendingAutomaticMessageSync = true;
      debugPrint(
        '⏸️ [Provider] Message sync deferred until connection bootstrap completes',
      );
      return 0;
    }
    if (_isSyncingMessages) {
      // Already syncing; avoid overlapping loops
      _syncRequestedWhileBusy = true;
      return 0;
    }

    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return 0;
    }

    int totalCount = 0;

    try {
      _pendingAutomaticMessageSync = false;
      _isSyncingMessages = true;
      do {
        _syncRequestedWhileBusy = false;
        _noMoreMessages = false; // Reset flag per pass
        int passCount = 0;
        debugPrint('🔄 [Provider] Starting message sync loop...');
        debugPrint('  Initial _noMoreMessages state: $_noMoreMessages');

        // Keep syncing until we get NoMoreMessages response
        // The device will send ContactMsgRecv or ChannelMsgRecv responses
        // until it sends NoMoreMessages
        for (int i = 0; i < 100; i++) {
          // Safety limit
          // Check flag BEFORE sending (not after)
          if (_noMoreMessages) {
            debugPrint(
              '✅ [Provider] Message sync complete - NoMoreMessages flag set after $passCount requests',
            );
            break;
          }

          debugPrint(
            '📤 [Provider] Sync iteration ${i + 1}: Sending CMD_SYNC_NEXT_MESSAGE',
          );

          // Create new completer for this request
          _syncResponseCompleter = Completer<bool>();

          // Respect the minimum interval between requests
          final now = DateTime.now();
          if (_lastSyncNextRequestedAt != null) {
            final elapsed = now.difference(_lastSyncNextRequestedAt!);
            if (elapsed < _minSyncNextInterval) {
              final remaining = _minSyncNextInterval - elapsed;
              await Future.delayed(remaining);
            }
          }

          await _activeService.syncNextMessage();
          _lastSyncNextRequestedAt = DateTime.now();
          passCount++;
          totalCount++;

          // Wait for response (true = message received, false = no more messages)
          // Timeout after 2 seconds to prevent hanging
          final hasMore = await _syncResponseCompleter!.future.timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ [Provider] Sync timeout - no response after 2s');
              return false;
            },
          );

          debugPrint(
            '  After iteration ${i + 1}: hasMore=$hasMore, _noMoreMessages=$_noMoreMessages',
          );

          if (!hasMore) {
            debugPrint('  ✅ No more messages available, stopping sync');
            break;
          }
        }

        if (!_noMoreMessages && passCount >= 100) {
          debugPrint(
            '⚠️ [Provider] Message sync stopped - reached safety limit of 100 requests without NoMoreMessages',
          );
        }

        if (_syncRequestedWhileBusy) {
          debugPrint(
            '↻ [Provider] MSG_WAITING received during sync; running another pass',
          );
        }
      } while (_syncRequestedWhileBusy && _activeService.isConnected);

      debugPrint(
        '🏁 [Provider] Message sync finished: sent $totalCount sync requests, _noMoreMessages=$_noMoreMessages',
      );
      return totalCount;
    } catch (e) {
      debugPrint('❌ [Provider] Failed to sync messages: $e');
      _error = 'Failed to sync messages: $e';
      notifyListeners();
      return totalCount;
    } finally {
      _isSyncingMessages = false;
      _syncResponseCompleter = null;
    }
  }

  bool get hasPendingAutomaticMessageSync => _pendingAutomaticMessageSync;

  void clearPendingAutomaticMessageSync() {
    _pendingAutomaticMessageSync = false;
  }

  /// Login to a room or repeater
  ///
  /// Sends login request with password. Results will be delivered via
  /// onLoginSuccess or onLoginFail callbacks.
  ///
  /// Example usage:
  /// ```dart
  /// connectionProvider.onLoginSuccess = (pkPrefix, perms, isAdmin, tag) {
  ///   debugPrint('Successfully logged in to room!');
  /// };
  /// connectionProvider.onLoginFail = (pkPrefix) {
  ///   debugPrint('Login failed - incorrect password');
  /// };
  /// await connectionProvider.loginToRoom(
  ///   roomPublicKey: contact.publicKey,
  ///   password: 'secret123',
  /// );
  /// ```
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isLoginInProgress) return;
      // Throttle rapid login attempts
      final now = DateTime.now();
      if (_lastLoginRequestedAt != null) {
        final elapsed = now.difference(_lastLoginRequestedAt!);
        if (elapsed < _minLoginInterval) {
          final wait = _minLoginInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isLoginInProgress = true;
      await _activeService.loginToRoom(
        roomPublicKey: roomPublicKey,
        password: password,
      );
      _lastLoginRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send login request: $e';
      notifyListeners();
    } finally {
      _isLoginInProgress = false;
    }
  }

  /// Request status from repeater or sensor node
  ///
  /// Sends a status request to query operational status of a node.
  /// Results will be delivered via onStatusResponse callback.
  ///
  /// Example usage:
  /// ```dart
  /// connectionProvider.onStatusResponse = (publicKeyPrefix, statusData) {
  ///   debugPrint('Status from node: ${utf8.decode(statusData)}');
  /// };
  /// await connectionProvider.requestStatus(repeaterContact.publicKey);
  /// ```
  Future<void> requestStatus(Uint8List contactPublicKey) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isStatusRequestInProgress) return;
      // Throttle rapid status requests
      final now = DateTime.now();
      if (_lastStatusRequestedAt != null) {
        final elapsed = now.difference(_lastStatusRequestedAt!);
        if (elapsed < _minStatusInterval) {
          final wait = _minStatusInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isStatusRequestInProgress = true;
      await _activeService.sendStatusRequest(contactPublicKey);
      _lastStatusRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send status request: $e';
      notifyListeners();
    } finally {
      _isStatusRequestInProgress = false;
    }
  }

  Future<({int tag, int suggestedTimeoutMs})?> sendAnonRequest({
    required Uint8List contactPublicKey,
    required Uint8List requestData,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return null;
    }

    try {
      return await _activeService.sendAnonRequest(
        contactPublicKey: contactPublicKey,
        requestData: requestData,
      );
    } catch (e) {
      _error = 'Failed to send anonymous request: $e';
      notifyListeners();
      return null;
    }
  }

  /// Reset routing path for a contact
  ///
  /// Clears the learned path to a contact, forcing the next message to use
  /// flood routing to discover a new route. Useful when:
  /// - A mobile repeater has moved and the path is broken
  /// - You want to find a better/shorter route
  /// - Direct messages are timing out due to path issues
  ///
  /// After calling this, the device will automatically fall back to flood mode
  /// for the next message to this contact, and learn a new path from the response.
  Future<void> resetPath(Uint8List contactPublicKey) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      await _activeService.resetPath(contactPublicKey);
    } catch (e) {
      _error = 'Failed to reset path: $e';
      notifyListeners();
    }
  }

  Future<void> setContactRoute(
    Contact contact, {
    required int signedEncodedPathLen,
    required Uint8List paddedPathBytes,
  }) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      _error = null;
      final updatedContact = contact.copyWith(
        outPathLen: signedEncodedPathLen,
        outPath: Uint8List.fromList(paddedPathBytes),
      );
      await _activeService.addOrUpdateContact(updatedContact);
    } catch (e) {
      _error = 'Failed to set route: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Remove a contact from the companion radio
  ///
  /// Deletes the contact from the device's internal contact table.
  /// The contact will no longer appear in the contact list and all
  /// routing information will be cleared.
  Future<void> removeContact(Uint8List contactPublicKey) async {
    if (!_activeService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      throw Exception(_error);
    }

    try {
      await _activeService.removeContact(contactPublicKey);
    } catch (e) {
      _error = 'Failed to remove contact: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get login state for a room by public key prefix
  RoomLoginState? getRoomLoginState(Uint8List publicKeyPrefix) {
    return _roomLoginManager.getRoomLoginState(publicKeyPrefix);
  }

  /// Check if logged into a specific room
  bool isLoggedIntoRoom(Uint8List publicKeyPrefix) {
    return _roomLoginManager.isLoggedIntoRoom(publicKeyPrefix);
  }

  @override
  void dispose() {
    _rxActivityTimer?.cancel();
    _txActivityTimer?.cancel();
    _stopAckCleanupTimer();
    final disconnectTransport = _serialDisconnectTransport;
    if (disconnectTransport != null) {
      unawaited(disconnectTransport());
      _serialDisconnectTransport = null;
    }
    _serialService?.dispose();
    _bleService.dispose();
    _tcpService?.dispose();
    super.dispose();
  }
}
