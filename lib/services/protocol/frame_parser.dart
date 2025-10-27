import 'dart:convert';
import 'dart:typed_data';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../buffer_reader.dart';
import '../meshcore_constants.dart';

/// Parses incoming BLE frames from the MeshCore device
class FrameParser {
  /// Parse ContactsStart response
  static int parseContactsStart(BufferReader reader) {
    return reader.readUInt32LE();
  }

  /// Parse Contact response
  static Contact parseContact(BufferReader reader) {
    final publicKey = reader.readBytes(32);
    final typeByte = reader.readByte();
    final type = ContactType.fromValue(typeByte);
    final flags = reader.readByte();
    final outPathLen = reader.readInt8();
    final outPath = reader.readBytes(64);
    final advName = reader.readCString(32);
    final lastAdvert = reader.readUInt32LE();
    final advLat = reader.readInt32LE();
    final advLon = reader.readInt32LE();
    final lastMod = reader.readUInt32LE();

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: flags,
      outPathLen: outPathLen,
      outPath: outPath,
      advName: advName,
      lastAdvert: lastAdvert,
      advLat: advLat,
      advLon: advLon,
      lastMod: lastMod,
    );
  }

  /// Parse Sent confirmation response
  static Map<String, dynamic> parseSentConfirmation(BufferReader reader) {
    if (reader.remainingBytesCount >= 9) {
      final sendType = reader.readByte();
      final isFloodMode = sendType == 1;
      final expectedAckOrTagBytes = reader.readBytes(4);
      final expectedAckTag = ByteData.sublistView(Uint8List.fromList(expectedAckOrTagBytes))
          .getUint32(0, Endian.little);
      final suggestedTimeout = reader.readUInt32LE();

      return {
        'expectedAckTag': expectedAckTag,
        'suggestedTimeout': suggestedTimeout,
        'isFloodMode': isFloodMode,
      };
    }
    return {};
  }

  /// Parse ContactMessage response
  static Message parseContactMessage(BufferReader reader) {
    final pubKeyPrefix = reader.readBytes(6);
    final pathLen = reader.readByte();
    final txtTypeByte = reader.readByte();
    final txtType = MessageTextType.fromValue(txtTypeByte);
    final senderTimestamp = reader.readUInt32LE();

    String text;
    if (txtType == MessageTextType.signedPlain) {
      // Signed message format: [4-byte sender prefix][UTF-8 text]
      if (reader.remainingBytesCount >= 4) {
        reader.readBytes(4); // Skip extra sender prefix
        text = reader.hasRemaining ? reader.readString() : '';
      } else {
        text = reader.readString();
      }
    } else {
      text = reader.readString();
    }

    return Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_${pubKeyPrefix.map((b) => b.toRadixString(16)).join()}',
      messageType: MessageType.contact,
      senderPublicKeyPrefix: pubKeyPrefix,
      pathLen: pathLen,
      textType: txtType,
      senderTimestamp: senderTimestamp,
      text: text,
      receivedAt: DateTime.now(),
    );
  }

  /// Parse ChannelMessage response
  static Message parseChannelMessage(BufferReader reader) {
    final channelIdx = reader.readInt8();
    final pathLen = reader.readByte();
    final txtTypeByte = reader.readByte();
    final txtType = MessageTextType.fromValue(txtTypeByte);
    final senderTimestamp = reader.readUInt32LE();

    String text;
    if (txtType == MessageTextType.signedPlain) {
      if (reader.remainingBytesCount >= 4) {
        reader.readBytes(4); // Skip extra sender prefix
        text = reader.hasRemaining ? reader.readString() : '';
      } else {
        text = reader.readString();
      }
    } else {
      text = reader.readString();
    }

    // Parse sender name from channel message format: "<sender_name>: <actual_message>"
    String? senderName;
    String actualMessage = text;

    if (text.contains(': ')) {
      final colonIndex = text.indexOf(': ');
      senderName = text.substring(0, colonIndex);
      actualMessage = text.substring(colonIndex + 2); // Skip ": "
    }

    return Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_ch$channelIdx',
      messageType: MessageType.channel,
      channelIdx: channelIdx,
      pathLen: pathLen,
      textType: txtType,
      senderTimestamp: senderTimestamp,
      text: actualMessage, // Store the actual message without sender prefix
      senderName: senderName, // Store extracted sender name
      receivedAt: DateTime.now(),
    );
  }

  /// Parse TelemetryResponse push
  static Map<String, dynamic> parseTelemetryResponse(BufferReader reader) {
    reader.readByte(); // reserved
    final pubKeyPrefix = reader.readBytes(6);
    final lppSensorData = reader.readRemainingBytes();

    return {
      'publicKeyPrefix': pubKeyPrefix,
      'lppSensorData': lppSensorData,
    };
  }

  /// Parse BinaryResponse push
  static Map<String, dynamic> parseBinaryResponse(BufferReader reader) {
    reader.readByte(); // reserved
    final tag = reader.readUInt32LE();
    final responseData = reader.readRemainingBytes();

    return {
      'publicKeyPrefix': Uint8List(6), // Empty prefix
      'tag': tag,
      'responseData': responseData,
    };
  }

  /// Parse DeviceInfo response
  static Map<String, dynamic> parseDeviceInfo(BufferReader reader) {
    if (reader.remainingBytesCount < 1) {
      return {};
    }

    final firmwareVersion = reader.readByte();

    int? maxContacts;
    int? maxChannels;
    int? blePin;
    if (reader.remainingBytesCount >= 6) {
      final maxContactsDiv2 = reader.readByte();
      maxContacts = maxContactsDiv2 * 2;
      maxChannels = reader.readByte();
      blePin = reader.readUInt32LE();
    }

    String? firmwareBuildDate;
    if (reader.remainingBytesCount >= 12) {
      final buildDateBytes = reader.readBytes(12);
      firmwareBuildDate =
          String.fromCharCodes(buildDateBytes.takeWhile((b) => b != 0));
    }

    String? manufacturerModel;
    if (reader.remainingBytesCount >= 40) {
      final modelBytes = reader.readBytes(40);
      manufacturerModel =
          String.fromCharCodes(modelBytes.takeWhile((b) => b != 0));
    }

    String? semanticVersion;
    if (reader.remainingBytesCount >= 20) {
      final versionBytes = reader.readBytes(20);
      semanticVersion =
          String.fromCharCodes(versionBytes.takeWhile((b) => b != 0));
    }

    return {
      'firmwareVersion': firmwareVersion,
      'maxContacts': maxContacts,
      'maxChannels': maxChannels,
      'blePin': blePin,
      'firmwareBuildDate': firmwareBuildDate,
      'manufacturerModel': manufacturerModel,
      'semanticVersion': semanticVersion,
    };
  }

  /// Parse SelfInfo response
  static Map<String, dynamic> parseSelfInfo(BufferReader reader) {
    if (reader.remainingBytesCount < 54) {
      reader.readRemainingBytes();
      return {};
    }

    final deviceType = reader.readByte();
    final txPower = reader.readByte();
    final maxTxPower = reader.readByte();
    final publicKey = reader.readBytes(32);

    final advLatBytes = reader.readBytes(4);
    final advLat = ByteData.sublistView(Uint8List.fromList(advLatBytes))
        .getInt32(0, Endian.little);

    final advLonBytes = reader.readBytes(4);
    final advLon = ByteData.sublistView(Uint8List.fromList(advLonBytes))
        .getInt32(0, Endian.little);

    reader.readByte(); // multiAcks (reserved for future use)
    reader.readByte(); // advertLocPolicy (reserved for future use)
    reader.readByte(); // telemetryModes (reserved for future use)
    final manualAddContacts = reader.readByte();

    final radioFreqBytes = reader.readBytes(4);
    final radioFreq = ByteData.sublistView(Uint8List.fromList(radioFreqBytes))
        .getUint32(0, Endian.little);

    final radioBwBytes = reader.readBytes(4);
    final radioBw = ByteData.sublistView(Uint8List.fromList(radioBwBytes))
        .getUint32(0, Endian.little);

    final radioSf = reader.readByte();
    final radioCr = reader.readByte();

    String? selfName;
    if (reader.hasRemaining) {
      final nameBytes = reader.readRemainingBytes();
      selfName = utf8.decode(nameBytes.takeWhile((b) => b != 0).toList());
    }

    return {
      'deviceType': deviceType,
      'txPower': txPower,
      'maxTxPower': maxTxPower,
      'publicKey': publicKey,
      'advLat': advLat,
      'advLon': advLon,
      'manualAddContacts': manualAddContacts == 1,
      'radioFreq': radioFreq,
      'radioBw': radioBw,
      'radioSf': radioSf,
      'radioCr': radioCr,
      'selfName': selfName,
    };
  }

  /// Parse Advert push
  static Uint8List? parseAdvert(BufferReader reader) {
    if (reader.remainingBytesCount >= 32) {
      return reader.readBytes(32);
    }
    return null;
  }

  /// Parse PathUpdated push
  static Uint8List? parsePathUpdated(BufferReader reader) {
    if (reader.remainingBytesCount >= 32) {
      return reader.readBytes(32);
    }
    return null;
  }

  /// Parse SendConfirmed push
  static Map<String, dynamic> parseSendConfirmed(BufferReader reader) {
    if (reader.remainingBytesCount >= 8) {
      final ackCodeBytes = reader.readBytes(4);
      final ackCode = ByteData.sublistView(Uint8List.fromList(ackCodeBytes))
          .getUint32(0, Endian.little);
      final roundTripTime = reader.readUInt32LE();

      return {
        'ackCode': ackCode,
        'roundTripTime': roundTripTime,
      };
    }
    return {};
  }

  /// Parse LoginSuccess push
  static Map<String, dynamic> parseLoginSuccess(BufferReader reader) {
    if (reader.remainingBytesCount >= 11) {
      final permissions = reader.readByte();
      final isAdmin = (permissions & 0x01) != 0;
      final publicKeyPrefix = reader.readBytes(6);
      final tag = reader.readInt32LE();

      int? newPermissions;
      if (reader.hasRemaining) {
        newPermissions = reader.readByte();
      }

      return {
        'publicKeyPrefix': publicKeyPrefix,
        'permissions': permissions,
        'isAdmin': isAdmin,
        'tag': tag,
        'newPermissions': newPermissions,
      };
    }
    return {};
  }

  /// Parse LoginFail push
  static Uint8List? parseLoginFail(BufferReader reader) {
    if (reader.remainingBytesCount >= 7) {
      reader.readByte(); // reserved
      return reader.readBytes(6);
    }
    return null;
  }

  /// Parse StatusResponse push
  static Map<String, dynamic> parseStatusResponse(BufferReader reader) {
    if (reader.remainingBytesCount >= 7) {
      reader.readByte(); // reserved
      final publicKeyPrefix = reader.readBytes(6);
      final statusData = reader.readRemainingBytes();

      return {
        'publicKeyPrefix': publicKeyPrefix,
        'statusData': statusData,
      };
    }
    return {};
  }

  /// Parse CurrentTime response
  static int? parseCurrentTime(BufferReader reader) {
    if (reader.remainingBytesCount >= 4) {
      return reader.readUInt32LE();
    }
    return null;
  }

  /// Parse BatteryAndStorage response
  static Map<String, dynamic> parseBatteryAndStorage(BufferReader reader) {
    if (reader.remainingBytesCount >= 2) {
      final millivolts = reader.readUInt16LE();

      int? usedKb;
      int? totalKb;

      if (reader.remainingBytesCount >= 8) {
        usedKb = reader.readUInt32LE();
        totalKb = reader.readUInt32LE();
      } else if (reader.remainingBytesCount >= 4) {
        usedKb = reader.readUInt32LE();
      }

      return {
        'millivolts': millivolts,
        'usedKb': usedKb,
        'totalKb': totalKb,
      };
    }
    return {};
  }

  /// Parse Error response
  static int? parseError(BufferReader reader) {
    if (reader.hasRemaining) {
      return reader.readByte();
    }
    return null;
  }

  /// Parse ChannelInfo response
  static Map<String, dynamic> parseChannelInfo(BufferReader reader) {
    if (reader.remainingBytesCount < 33) {
      return {};
    }

    final channelIdx = reader.readByte();
    final channelName = reader.readCString(32);

    // Additional fields if present in protocol
    int? flags;
    if (reader.hasRemaining) {
      flags = reader.readByte();
    }

    return {
      'channelIdx': channelIdx,
      'channelName': channelName,
      'flags': flags,
    };
  }

  /// Get error message from error code
  static String getErrorMessage(int errorCode) {
    switch (errorCode) {
      case MeshCoreConstants.errUnsupportedCmd:
        return 'Unsupported command';
      case MeshCoreConstants.errNotFound:
        return 'Not found';
      case MeshCoreConstants.errTableFull:
        return 'Table full';
      case MeshCoreConstants.errBadState:
        return 'Bad state';
      case MeshCoreConstants.errFileIoError:
        return 'File I/O error';
      case MeshCoreConstants.errIllegalArg:
        return 'Illegal argument';
      default:
        return 'Error code: $errorCode';
    }
  }
}
