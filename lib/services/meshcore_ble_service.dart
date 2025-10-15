import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import 'ble/ble_connection_manager.dart';
import 'ble/ble_command_sender.dart';
import 'ble/ble_response_handler.dart';
import 'protocol/frame_builder.dart';

/// Callback types for MeshCore events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback = void Function(Uint8List publicKey, Uint8List lppData);
typedef OnSelfInfoCallback = void Function(Map<String, dynamic> selfInfo);
typedef OnDeviceInfoCallback = void Function(Map<String, dynamic> deviceInfo);
typedef OnNoMoreMessagesCallback = void Function();
typedef OnMessageWaitingCallback = void Function();
typedef OnLoginSuccessCallback = void Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag);
typedef OnLoginFailCallback = void Function(Uint8List publicKeyPrefix);
typedef OnAdvertReceivedCallback = void Function(Uint8List publicKey);
typedef OnPathUpdatedCallback = void Function(Uint8List publicKey);
typedef OnMessageSentCallback = void Function(int expectedAckTag, int suggestedTimeoutMs, bool isFloodMode);
typedef OnMessageDeliveredCallback = void Function(int ackCode, int roundTripTimeMs);
typedef OnStatusResponseCallback = void Function(Uint8List publicKeyPrefix, Uint8List statusData);
typedef OnBinaryResponseCallback = void Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData);
typedef OnBatteryAndStorageCallback = void Function(int millivolts, int? usedKb, int? totalKb);
typedef OnErrorCallback = void Function(String error);
typedef OnConnectionStateCallback = void Function(bool isConnected);
typedef OnReconnectionAttemptCallback = void Function(int attemptNumber, int maxAttempts);

/// MeshCore BLE Service - coordinates BLE communication components
class MeshCoreBleService {
  // Component instances
  final BleConnectionManager _connectionManager = BleConnectionManager();
  final BleCommandSender _commandSender = BleCommandSender();
  final BleResponseHandler _responseHandler = BleResponseHandler();

  // Event callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnReconnectionAttemptCallback? onReconnectionAttempt;
  OnContactCallback? onContactReceived;
  OnContactsCompleteCallback? onContactsComplete;
  OnMessageCallback? onMessageReceived;
  OnTelemetryCallback? onTelemetryReceived;
  OnSelfInfoCallback? onSelfInfoReceived;
  OnDeviceInfoCallback? onDeviceInfoReceived;
  OnNoMoreMessagesCallback? onNoMoreMessages;
  OnMessageWaitingCallback? onMessageWaiting;
  OnLoginSuccessCallback? onLoginSuccess;
  OnLoginFailCallback? onLoginFail;
  OnAdvertReceivedCallback? onAdvertReceived;
  OnPathUpdatedCallback? onPathUpdated;
  OnMessageSentCallback? onMessageSent;
  OnMessageDeliveredCallback? onMessageDelivered;
  OnStatusResponseCallback? onStatusResponse;
  OnBinaryResponseCallback? onBinaryResponse;
  OnBatteryAndStorageCallback? onBatteryAndStorage;
  OnErrorCallback? onError;

  // Activity callbacks (for blinking indicators)
  VoidCallback? onRxActivity;
  VoidCallback? onTxActivity;

  // Constructor
  MeshCoreBleService() {
    _setupCallbacks();
  }

  // Setup callbacks between components
  void _setupCallbacks() {
    // Connection manager callbacks
    _connectionManager.onConnectionStateChanged = (isConnected) {
      onConnectionStateChanged?.call(isConnected);
    };
    _connectionManager.onError = (error) {
      onError?.call(error);
    };
    _connectionManager.onReconnectionAttempt = (attemptNumber, maxAttempts) {
      print('🔄 [Service] Reconnection attempt $attemptNumber/$maxAttempts');
      onReconnectionAttempt?.call(attemptNumber, maxAttempts);
    };

    // Command sender callbacks
    _commandSender.onError = (error) {
      onError?.call(error);
    };
    _commandSender.onTxActivity = () {
      onTxActivity?.call();
    };

    // Response handler callbacks
    _responseHandler.onContactReceived = (contact) {
      onContactReceived?.call(contact);
    };
    _responseHandler.onContactsComplete = (contacts) {
      onContactsComplete?.call(contacts);
    };
    _responseHandler.onMessageReceived = (message) {
      onMessageReceived?.call(message);
    };
    _responseHandler.onTelemetryReceived = (publicKey, lppData) {
      onTelemetryReceived?.call(publicKey, lppData);
    };
    _responseHandler.onSelfInfoReceived = (selfInfo) {
      onSelfInfoReceived?.call(selfInfo);
    };
    _responseHandler.onDeviceInfoReceived = (deviceInfo) {
      onDeviceInfoReceived?.call(deviceInfo);
    };
    _responseHandler.onNoMoreMessages = () {
      onNoMoreMessages?.call();
    };
    _responseHandler.onMessageWaiting = () {
      onMessageWaiting?.call();
    };
    _responseHandler.onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) {
      onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
    };
    _responseHandler.onLoginFail = (publicKeyPrefix) {
      onLoginFail?.call(publicKeyPrefix);
    };
    _responseHandler.onAdvertReceived = (publicKey) {
      onAdvertReceived?.call(publicKey);
    };
    _responseHandler.onPathUpdated = (publicKey) {
      onPathUpdated?.call(publicKey);
    };
    _responseHandler.onMessageSent = (expectedAckTag, suggestedTimeoutMs, isFloodMode) {
      onMessageSent?.call(expectedAckTag, suggestedTimeoutMs, isFloodMode);
    };
    _responseHandler.onMessageDelivered = (ackCode, roundTripTimeMs) {
      onMessageDelivered?.call(ackCode, roundTripTimeMs);
    };
    _responseHandler.onStatusResponse = (publicKeyPrefix, statusData) {
      onStatusResponse?.call(publicKeyPrefix, statusData);
    };
    _responseHandler.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      onBinaryResponse?.call(publicKeyPrefix, tag, responseData);
    };
    _responseHandler.onBatteryAndStorage = (millivolts, usedKb, totalKb) {
      onBatteryAndStorage?.call(millivolts, usedKb, totalKb);
    };
    _responseHandler.onError = (error) {
      onError?.call(error);
    };
    _responseHandler.onRxActivity = () {
      onRxActivity?.call();
    };
  }

  // Getters
  bool get isConnected => _connectionManager.isConnected;
  bool get isReconnecting => _connectionManager.isReconnecting;
  int get reconnectionAttempt => _connectionManager.reconnectionAttempt;
  int get maxReconnectionAttempts => _connectionManager.maxReconnectionAttempts;
  int get rxPacketCount => _responseHandler.rxPacketCount;
  int get txPacketCount => _commandSender.txPacketCount;
  List<BlePacketLog> get packetLogs {
    // Merge logs from both sender and handler
    final allLogs = [..._commandSender.packetLogs, ..._responseHandler.packetLogs];
    allLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allLogs;
  }

  /// Scan for MeshCore devices
  Stream<BluetoothDevice> scanForDevices({Duration timeout = const Duration(seconds: 10)}) {
    return _connectionManager.scanForDevices(timeout: timeout);
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    final success = await _connectionManager.connect(device);
    if (success) {
      // Setup command sender with RX characteristic
      _commandSender.setRxCharacteristic(_connectionManager.rxCharacteristic);

      // Setup response handler with TX characteristic
      if (_connectionManager.txCharacteristic != null) {
        _responseHandler.subscribeToNotifications(_connectionManager.txCharacteristic!);
      }

      // Send initial device query
      await _sendDeviceQuery();
    }
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _connectionManager.disconnect();
  }

  /// Send initial device query
  Future<void> _sendDeviceQuery() async {
    await _commandSender.writeData(FrameBuilder.buildDeviceQuery());
    await _commandSender.writeData(FrameBuilder.buildAppStart());
  }

  /// Refresh device info (public method)
  Future<void> refreshDeviceInfo() async {
    await _sendDeviceQuery();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    await _commandSender.writeData(FrameBuilder.buildGetContacts());
  }

  /// Manually add or update a contact on the companion radio
  Future<void> addOrUpdateContact(Contact contact) async {
    print('📝 [BLE] Adding/updating contact on companion radio:');
    print('    Name: ${contact.advName}');
    print('    Public key prefix: ${contact.publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('    Type: ${contact.type} (${contact.type.value})');

    await _commandSender.writeData(FrameBuilder.buildAddUpdateContact(contact));

    print('✅ [BLE] CMD_ADD_UPDATE_CONTACT sent');
  }

  /// Send text message to contact (DM)
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    int textType = 0,
    int attempt = 0,
  }) async {
    if (text.length > 160) {
      throw ArgumentError('Text message exceeds 160 character limit');
    }

    await _commandSender.writeData(FrameBuilder.buildSendTxtMsg(
      contactPublicKey: contactPublicKey,
      text: text,
      textType: textType,
      attempt: attempt,
    ));
  }

  /// Send flood-mode text message to channel
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    int textType = 0,
  }) async {
    if (text.length > 160) {
      throw ArgumentError('Channel message too long (max ~160 characters)');
    }

    await _commandSender.writeData(FrameBuilder.buildSendChannelTxtMsg(
      channelIdx: channelIdx,
      text: text,
      textType: textType,
    ));
  }

  /// Request telemetry from contact (deprecated)
  @Deprecated('Use sendBinaryRequest() instead for better functionality')
  Future<void> requestTelemetry(Uint8List contactPublicKey, {bool zeroHop = false}) async {
    await _commandSender.writeData(FrameBuilder.buildSendTelemetryReq(
      contactPublicKey,
      zeroHop: zeroHop,
    ));
  }

  /// Send binary request to contact
  Future<void> sendBinaryRequest({
    required Uint8List contactPublicKey,
    required Uint8List requestData,
  }) async {
    await _commandSender.writeData(FrameBuilder.buildSendBinaryReq(
      contactPublicKey: contactPublicKey,
      requestData: requestData,
    ));
  }

  /// Get battery voltage and storage information
  Future<void> getBatteryAndStorage() async {
    await _commandSender.writeData(FrameBuilder.buildGetBatteryAndStorage());
  }

  /// Legacy method name for backward compatibility
  @Deprecated('Use getBatteryAndStorage() instead')
  Future<void> getBatteryVoltage() async {
    await getBatteryAndStorage();
  }

  /// Sync next message from device queue
  Future<void> syncNextMessage() async {
    await _commandSender.writeData(FrameBuilder.buildSyncNextMessage());
  }

  /// Get device time from companion radio
  Future<void> getDeviceTime() async {
    await _commandSender.writeData(FrameBuilder.buildGetDeviceTime());
  }

  /// Set device time
  Future<void> setDeviceTime() async {
    await _commandSender.writeData(FrameBuilder.buildSetDeviceTime());
  }

  /// Send self advertisement packet to mesh network
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    await _commandSender.writeData(FrameBuilder.buildSendSelfAdvert(floodMode: floodMode));
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    await _commandSender.writeData(FrameBuilder.buildSetAdvertName(name));
  }

  /// Set advertised latitude and longitude
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    await _commandSender.writeData(FrameBuilder.buildSetAdvertLatLon(
      latitude: latitude,
      longitude: longitude,
    ));
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency,
    required int bandwidth,
    required int spreadingFactor,
    required int codingRate,
  }) async {
    await _commandSender.writeData(FrameBuilder.buildSetRadioParams(
      frequency: frequency,
      bandwidth: bandwidth,
      spreadingFactor: spreadingFactor,
      codingRate: codingRate,
    ));
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    await _commandSender.writeData(FrameBuilder.buildSetTxPower(powerDbm));
  }

  /// Set other parameters
  Future<void> setOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocationPolicy,
    int multiAcks = 0,
  }) async {
    await _commandSender.writeData(FrameBuilder.buildSetOtherParams(
      manualAddContacts: manualAddContacts,
      telemetryModes: telemetryModes,
      advertLocationPolicy: advertLocationPolicy,
      multiAcks: multiAcks,
    ));
  }

  /// Send login request to room or repeater
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (password.length > 15) {
      throw ArgumentError('Password exceeds 15 character limit');
    }

    print('🔐 [BLE] Preparing login request:');
    print('    Room public key prefix: ${roomPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('    Password: ${"*" * password.length} (${password.length} chars)');

    await _commandSender.writeData(FrameBuilder.buildSendLogin(
      roomPublicKey: roomPublicKey,
      password: password,
    ));
  }

  /// Send status request to repeater or sensor node
  Future<void> sendStatusRequest(Uint8List contactPublicKey) async {
    print('📊 [BLE] Preparing status request:');
    print('    Target node public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

    await _commandSender.writeData(FrameBuilder.buildSendStatusReq(contactPublicKey));
  }

  /// Reset path for a contact - forces next message to flood and re-learn route
  Future<void> resetPath(Uint8List contactPublicKey) async {
    print('🔄 [BLE] Resetting path for contact:');
    print('    Contact public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

    await _commandSender.writeData(FrameBuilder.buildResetPath(contactPublicKey));
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _commandSender.clearPacketLogs();
    _responseHandler.clearPacketLogs();
  }

  /// Reset packet counters
  void resetCounters() {
    _commandSender.resetCounter();
    _responseHandler.resetCounter();
  }

  /// Dispose resources
  void dispose() {
    _connectionManager.dispose();
    _commandSender.dispose();
    _responseHandler.dispose();
  }
}
