import '../../models/message.dart';
import '../../utils/image_message_parser.dart';
import '../../utils/voice_message_parser.dart';

class RestoredSessionMetadata {
  final Map<String, String> voiceSenderKeyBySession;
  final Map<String, String> imageSenderKeyBySession;
  final Map<String, ImageEnvelope> imageEnvelopeBySession;

  const RestoredSessionMetadata({
    required this.voiceSenderKeyBySession,
    required this.imageSenderKeyBySession,
    required this.imageEnvelopeBySession,
  });
}

RestoredSessionMetadata restoreSessionMetadataFromMessages(
  Iterable<Message> messages,
) {
  final voiceSenderKeyBySession = <String, String>{};
  final imageSenderKeyBySession = <String, String>{};
  final imageEnvelopeBySession = <String, ImageEnvelope>{};

  for (final message in messages) {
    final text = message.text;
    final voiceEnvelope = VoiceEnvelope.tryParseText(text);
    if (voiceEnvelope != null) {
      final senderPrefix = message.senderPublicKeyPrefix;
      if (senderPrefix != null && senderPrefix.length >= 6) {
        voiceSenderKeyBySession[voiceEnvelope.sessionId] = senderPrefix
            .sublist(0, 6)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toLowerCase();
      }
    }

    final imageEnvelope = ImageEnvelope.tryParse(text);
    if (imageEnvelope != null) {
      imageEnvelopeBySession[imageEnvelope.sessionId] = imageEnvelope;
      final senderPrefix = message.senderPublicKeyPrefix;
      if (senderPrefix != null && senderPrefix.length >= 6) {
        imageSenderKeyBySession[imageEnvelope.sessionId] = senderPrefix
            .sublist(0, 6)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toLowerCase();
      }
    }
  }

  return RestoredSessionMetadata(
    voiceSenderKeyBySession: voiceSenderKeyBySession,
    imageSenderKeyBySession: imageSenderKeyBySession,
    imageEnvelopeBySession: imageEnvelopeBySession,
  );
}
