/// MeshCore BLE and Protocol Constants
class MeshCoreConstants {
  // Supported protocol version
  static const int supportedCompanionProtocolVersion = 1;

  // BLE Service and Characteristic UUIDs
  static const String bleServiceUuid =
      '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String bleCharacteristicRxUuid =
      '6E400002-B5A3-F393-E0A9-E50E24DCCA9E'; // Write
  static const String bleCharacteristicTxUuid =
      '6E400003-B5A3-F393-E0A9-E50E24DCCA9E'; // Notify

  // Command Codes (App -> Device)
  static const int cmdAppStart = 1;
  static const int cmdSendTxtMsg = 2;
  static const int cmdSendChannelTxtMsg = 3;
  static const int cmdGetContacts = 4;
  static const int cmdGetDeviceTime = 5;
  static const int cmdSetDeviceTime = 6;
  static const int cmdSendSelfAdvert = 7;
  static const int cmdSetAdvertName = 8;
  static const int cmdAddUpdateContact = 9;
  static const int cmdSyncNextMessage = 10;
  static const int cmdSetRadioParams = 11;
  static const int cmdSetTxPower = 12;
  static const int cmdResetPath = 13;
  static const int cmdSetAdvertLatLon = 14;
  static const int cmdRemoveContact = 15;
  static const int cmdShareContact = 16;
  static const int cmdExportContact = 17;
  static const int cmdImportContact = 18;
  static const int cmdReboot = 19;
  static const int cmdGetBatteryVoltage = 20;
  static const int cmdSetTuningParams = 21;
  static const int cmdDeviceQuery = 22;
  static const int cmdExportPrivateKey = 23;
  static const int cmdImportPrivateKey = 24;
  static const int cmdSendRawData = 25;
  static const int cmdSendLogin = 26;
  static const int cmdSendStatusReq = 27;
  static const int cmdGetContactByKey = 30;
  static const int cmdGetChannel = 31;
  static const int cmdSetChannel = 32;
  static const int cmdSignStart = 33;
  static const int cmdSignData = 34;
  static const int cmdSignFinish = 35;
  static const int cmdSendTracePath = 36;
  static const int cmdSetOtherParams = 38;
  static const int cmdSendTelemetryReq = 39;
  static const int cmdSendBinaryReq = 50;

  // Response Codes (Device -> App)
  static const int respOk = 0;
  static const int respErr = 1;
  static const int respContactsStart = 2;
  static const int respContact = 3;
  static const int respEndOfContacts = 4;
  static const int respSelfInfo = 5;
  static const int respSent = 6;
  static const int respContactMsgRecv = 7;
  static const int respChannelMsgRecv = 8;
  static const int respCurrTime = 9;
  static const int respNoMoreMessages = 10;
  static const int respExportContact = 11;
  static const int respBatteryVoltage = 12;
  static const int respDeviceInfo = 13;
  static const int respPrivateKey = 14;
  static const int respDisabled = 15;
  static const int respChannelInfo = 18;
  static const int respSignStart = 19;
  static const int respSignature = 20;
  static const int respCustomVars = 21;
  static const int respAdvertPath = 22;
  static const int respTuningParams = 21; // Same as respCustomVars per protocol

  // Push Codes (Device -> App, unsolicited)
  static const int pushAdvert = 0x80;
  static const int pushPathUpdated = 0x81;
  static const int pushSendConfirmed = 0x82;
  static const int pushMsgWaiting = 0x83;
  static const int pushRawData = 0x84;
  static const int pushLoginSuccess = 0x85;
  static const int pushLoginFail = 0x86;
  static const int pushStatusResponse = 0x87;
  static const int pushLogRxData = 0x88;
  static const int pushTraceData = 0x89;
  static const int pushNewAdvert = 0x8A;
  static const int pushTelemetryResponse = 0x8B;
  static const int pushBinaryResponse = 0x8C;

  // Error Codes
  static const int errUnsupportedCmd = 1;
  static const int errNotFound = 2;
  static const int errTableFull = 3;
  static const int errBadState = 4;
  static const int errFileIoError = 5;
  static const int errIllegalArg = 6;

  // Advert Types
  static const int advTypeNone = 0;
  static const int advTypeChat = 1;
  static const int advTypeRepeater = 2;
  static const int advTypeRoom = 3;

  // Self Advert Types
  static const int selfAdvertZeroHop = 0;
  static const int selfAdvertFlood = 1;

  // Text Types
  static const int txtTypePlain = 0;
  static const int txtTypeCliData = 1;
  static const int txtTypeSignedPlain = 2;

  // Binary Request Types
  static const int binaryReqGetTelemetryData = 0x03;
  static const int binaryReqGetAvgMinMax = 0x04;
  static const int binaryReqGetAccessList = 0x05;
  static const int binaryReqGetNeighbours = 0x06;

  // Default Public Channel Secret (128-bit)
  // This is the well-known pre-shared key for the public channel (channel 0)
  // Hex: 8b3387e9c5cdea6ac9e5edbaa115cd72
  // Base64: izOH6cXN6mrJ5e26oRXNcg==
  // Source: https://github.com/meshcore-dev/MeshCore/blob/main/docs/faq.md
  static const List<int> defaultPublicChannelSecret = [
    0x8b, 0x33, 0x87, 0xe9, 0xc5, 0xcd, 0xea, 0x6a,
    0xc9, 0xe5, 0xed, 0xba, 0xa1, 0x15, 0xcd, 0x72,
  ];

  // Cayenne LPP Data Types
  static const int lppDigitalInput = 0;
  static const int lppDigitalOutput = 1;
  static const int lppAnalogInput = 2;
  static const int lppAnalogOutput = 3;
  static const int lppIlluminanceSensor = 101;
  static const int lppPresenceSensor = 102;
  static const int lppTemperatureSensor = 103;
  static const int lppHumiditySensor = 104;
  static const int lppAccelerometer = 113;
  static const int lppBarometer = 115;
  static const int lppVoltageSensor = 116;
  static const int lppGyrometer = 134;
  static const int lppGps = 136;

  // MTU and timing
  static const int maxMtuSize = 512;
  static const int defaultTimeout = 5000; // 5 seconds
  static const int reconnectDelay = 2000; // 2 seconds
  static const int telemetryUpdateInterval = 300000; // 5 minutes

  MeshCoreConstants._(); // Private constructor to prevent instantiation
}
