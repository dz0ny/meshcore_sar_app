import 'package:shared_preferences/shared_preferences.dart';
import 'profiles_feature_service.dart';
import '../utils/voice_message_parser.dart';

/// Stores user-selected voice bitrate and maps it to supported codec modes.
class VoiceBitratePreferences {
  static const String _bitrateKey = 'voice_bitrate';
  static const int defaultBitrate = 1300;
  static const List<int> supportedBitrates = [
    700,
    1200,
    1300,
    1400,
    1600,
    2400,
    3200,
  ];

  static Future<int> getBitrate() async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        prefs.getInt(ProfileStorageScope.scopedKey(_bitrateKey)) ??
        defaultBitrate;
    return supportedBitrates.contains(value) ? value : defaultBitrate;
  }

  static Future<void> setBitrate(int bitrate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(ProfileStorageScope.scopedKey(_bitrateKey), bitrate);
  }

  static VoicePacketMode toVoiceMode(int bitrate) {
    switch (bitrate) {
      case 1200:
        return VoicePacketMode.mode1200;
      case 1300:
        return VoicePacketMode.mode1300;
      case 1400:
        return VoicePacketMode.mode1400;
      case 1600:
        return VoicePacketMode.mode1600;
      case 2400:
        return VoicePacketMode.mode2400;
      case 3200:
        return VoicePacketMode.mode3200;
      case 700:
        return VoicePacketMode.mode700c;
      default:
        return VoicePacketMode.mode1300;
    }
  }
}
