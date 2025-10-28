import 'meshcore_constants.dart';

/// Maps MeshCore protocol opcodes to human-readable names
class MeshCoreOpcodeNames {
  /// Get command name from opcode
  static String getCommandName(int opcode) {
    switch (opcode) {
      case MeshCoreConstants.cmdAppStart:
        return 'APP_START';
      case MeshCoreConstants.cmdSendTxtMsg:
        return 'SEND_TXT_MSG';
      case MeshCoreConstants.cmdSendChannelTxtMsg:
        return 'SEND_CHANNEL_TXT_MSG';
      case MeshCoreConstants.cmdGetContacts:
        return 'GET_CONTACTS';
      case MeshCoreConstants.cmdGetDeviceTime:
        return 'GET_DEVICE_TIME';
      case MeshCoreConstants.cmdSetDeviceTime:
        return 'SET_DEVICE_TIME';
      case MeshCoreConstants.cmdSendSelfAdvert:
        return 'SEND_SELF_ADVERT';
      case MeshCoreConstants.cmdSetAdvertName:
        return 'SET_ADVERT_NAME';
      case MeshCoreConstants.cmdAddUpdateContact:
        return 'ADD_UPDATE_CONTACT';
      case MeshCoreConstants.cmdSyncNextMessage:
        return 'SYNC_NEXT_MESSAGE';
      case MeshCoreConstants.cmdSetRadioParams:
        return 'SET_RADIO_PARAMS';
      case MeshCoreConstants.cmdSetTxPower:
        return 'SET_TX_POWER';
      case MeshCoreConstants.cmdResetPath:
        return 'RESET_PATH';
      case MeshCoreConstants.cmdSetAdvertLatLon:
        return 'SET_ADVERT_LAT_LON';
      case MeshCoreConstants.cmdRemoveContact:
        return 'REMOVE_CONTACT';
      case MeshCoreConstants.cmdShareContact:
        return 'SHARE_CONTACT';
      case MeshCoreConstants.cmdExportContact:
        return 'EXPORT_CONTACT';
      case MeshCoreConstants.cmdImportContact:
        return 'IMPORT_CONTACT';
      case MeshCoreConstants.cmdReboot:
        return 'REBOOT';
      case MeshCoreConstants.cmdGetBatteryVoltage:
        return 'GET_BATTERY_VOLTAGE';
      case MeshCoreConstants.cmdSetTuningParams:
        return 'SET_TUNING_PARAMS';
      case MeshCoreConstants.cmdDeviceQuery:
        return 'DEVICE_QUERY';
      case MeshCoreConstants.cmdExportPrivateKey:
        return 'EXPORT_PRIVATE_KEY';
      case MeshCoreConstants.cmdImportPrivateKey:
        return 'IMPORT_PRIVATE_KEY';
      case MeshCoreConstants.cmdSendRawData:
        return 'SEND_RAW_DATA';
      case MeshCoreConstants.cmdSendLogin:
        return 'SEND_LOGIN';
      case MeshCoreConstants.cmdSendStatusReq:
        return 'SEND_STATUS_REQ';
      case MeshCoreConstants.cmdGetContactByKey:
        return 'GET_CONTACT_BY_KEY';
      case MeshCoreConstants.cmdGetChannel:
        return 'GET_CHANNEL';
      case MeshCoreConstants.cmdSetChannel:
        return 'SET_CHANNEL';
      case MeshCoreConstants.cmdSignStart:
        return 'SIGN_START';
      case MeshCoreConstants.cmdSignData:
        return 'SIGN_DATA';
      case MeshCoreConstants.cmdSignFinish:
        return 'SIGN_FINISH';
      case MeshCoreConstants.cmdSendTracePath:
        return 'SEND_TRACE_PATH';
      case MeshCoreConstants.cmdSetOtherParams:
        return 'SET_OTHER_PARAMS';
      case MeshCoreConstants.cmdSendTelemetryReq:
        return 'SEND_TELEMETRY_REQ';
      case MeshCoreConstants.cmdSendBinaryReq:
        return 'SEND_BINARY_REQ';
      default:
        return 'CMD_UNKNOWN';
    }
  }

  /// Get response name from opcode
  static String getResponseName(int opcode) {
    switch (opcode) {
      case MeshCoreConstants.respOk:
        return 'OK';
      case MeshCoreConstants.respErr:
        return 'ERROR';
      case MeshCoreConstants.respContactsStart:
        return 'CONTACTS_START';
      case MeshCoreConstants.respContact:
        return 'CONTACT';
      case MeshCoreConstants.respEndOfContacts:
        return 'END_OF_CONTACTS';
      case MeshCoreConstants.respSelfInfo:
        return 'SELF_INFO';
      case MeshCoreConstants.respSent:
        return 'SENT';
      case MeshCoreConstants.respContactMsgRecv:
        return 'CONTACT_MSG_RECV';
      case MeshCoreConstants.respChannelMsgRecv:
        return 'CHANNEL_MSG_RECV';
      case MeshCoreConstants.respCurrTime:
        return 'CURR_TIME';
      case MeshCoreConstants.respNoMoreMessages:
        return 'NO_MORE_MESSAGES';
      case MeshCoreConstants.respExportContact:
        return 'EXPORT_CONTACT';
      case MeshCoreConstants.respBatteryVoltage:
        return 'BATTERY_VOLTAGE';
      case MeshCoreConstants.respDeviceInfo:
        return 'DEVICE_INFO';
      case MeshCoreConstants.respPrivateKey:
        return 'PRIVATE_KEY';
      case MeshCoreConstants.respDisabled:
        return 'DISABLED';
      case MeshCoreConstants.respChannelInfo:
        return 'CHANNEL_INFO';
      case MeshCoreConstants.respSignStart:
        return 'SIGN_START';
      case MeshCoreConstants.respSignature:
        return 'SIGNATURE';
      default:
        return 'RESP_UNKNOWN';
    }
  }

  /// Get push notification name from opcode
  static String getPushName(int opcode) {
    switch (opcode) {
      case MeshCoreConstants.pushAdvert:
        return 'ADVERT';
      case MeshCoreConstants.pushPathUpdated:
        return 'PATH_UPDATED';
      case MeshCoreConstants.pushSendConfirmed:
        return 'SEND_CONFIRMED';
      case MeshCoreConstants.pushMsgWaiting:
        return 'MSG_WAITING';
      case MeshCoreConstants.pushRawData:
        return 'RAW_DATA';
      case MeshCoreConstants.pushLoginSuccess:
        return 'LOGIN_SUCCESS';
      case MeshCoreConstants.pushLoginFail:
        return 'LOGIN_FAIL';
      case MeshCoreConstants.pushStatusResponse:
        return 'STATUS_RESPONSE';
      case MeshCoreConstants.pushLogRxData:
        return 'LOG_RX_DATA';
      case MeshCoreConstants.pushTraceData:
        return 'TRACE_DATA';
      case MeshCoreConstants.pushNewAdvert:
        return 'NEW_ADVERT';
      case MeshCoreConstants.pushTelemetryResponse:
        return 'TELEMETRY_RESPONSE';
      case MeshCoreConstants.pushBinaryResponse:
        return 'BINARY_RESPONSE';
      default:
        return 'PUSH_UNKNOWN';
    }
  }

  /// Get opcode name for any code (tries to determine type automatically)
  static String getOpcodeName(int opcode, {bool isTx = false}) {
    // If TX (sent to device), it's a command
    if (isTx) {
      return getCommandName(opcode);
    }

    // If RX (received from device), determine if it's a push or response
    if (opcode >= 0x80) {
      return getPushName(opcode);
    } else {
      return getResponseName(opcode);
    }
  }

  /// Get full opcode description with code in hex
  static String getOpcodeDescription(int opcode, {bool isTx = false}) {
    final name = getOpcodeName(opcode, isTx: isTx);
    final hex = '0x${opcode.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return '$name ($hex)';
  }

  MeshCoreOpcodeNames._(); // Private constructor to prevent instantiation
}
