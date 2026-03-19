import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Channel model - represents a communication channel
///
/// Supports two types of channels:
/// 1. Hash-based channels: Names starting with '#' (e.g., '#team', '#sar-ops')
///    - Secrets are auto-generated using SHA256(name)
///    - Same name produces same secret on all devices
/// 2. Normal channels: Any name with explicit secret
///    - User provides explicit 16-byte secret
///    - Only known to those who share the secret
class Channel {
  final int index; // 0-255
  final String name;
  final Uint8List secret; // 16 bytes
  final int? flags;

  Channel({
    required this.index,
    required this.name,
    required this.secret,
    this.flags,
  }) {
    if (secret.length != 16) {
      throw ArgumentError('Channel secret must be exactly 16 bytes');
    }
    if (index < 0 || index > 255) {
      throw ArgumentError('Channel index must be 0-255');
    }
  }

  /// Create a channel with auto-generated secret for #channels
  ///
  /// For #channels (name starting with '#'):
  /// - Secret is auto-generated using SHA256(name)[0:16]
  /// - Deterministic: same name = same secret across all devices
  ///
  /// For normal channels:
  /// - Must provide explicit 16-byte secret
  factory Channel.create({
    required int index,
    required String name,
    Uint8List? explicitSecret,
    int? flags,
  }) {
    if (name.startsWith('#')) {
      // Hash-based channel: auto-generate secret from name
      if (explicitSecret != null) {
        throw ArgumentError(
          'Cannot provide explicit secret for #channel. Secret is auto-generated.',
        );
      }
      final secret = _generateHashChannelSecret(name);
      return Channel(index: index, name: name, secret: secret, flags: flags);
    } else {
      // Normal channel: require explicit secret
      if (explicitSecret == null || explicitSecret.length != 16) {
        throw ArgumentError('Normal channels require a 16-byte secret');
      }
      return Channel(
        index: index,
        name: name,
        secret: explicitSecret,
        flags: flags,
      );
    }
  }

  /// Generate secret for #channel using SHA256
  /// Python equivalent: hashlib.sha256(channel_name.encode()).digest()[0:16]
  static Uint8List _generateHashChannelSecret(String channelName) {
    final bytes = utf8.encode(channelName);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }

  static bool isHashChannelName(String channelName) {
    return channelName.trim().startsWith('#');
  }

  static String pskBase64ForHashChannelName(String channelName) {
    final normalized = channelName.trim();
    if (!isHashChannelName(normalized)) {
      throw ArgumentError('Only #channels can export derived psk_base64');
    }
    return base64.encode(_generateHashChannelSecret(normalized));
  }

  /// Create the default public channel (channel 0)
  /// Uses the well-known pre-shared key from MeshCore
  factory Channel.publicChannel() {
    return Channel(
      index: 0,
      name: 'Public Channel',
      secret: Uint8List.fromList([
        0x8b,
        0x33,
        0x87,
        0xe9,
        0xc5,
        0xcd,
        0xea,
        0x6a,
        0xc9,
        0xe5,
        0xed,
        0xba,
        0xa1,
        0x15,
        0xcd,
        0x72,
      ]),
      flags: null,
    );
  }

  /// Check if this is a hash-based channel (name starts with '#')
  bool get isHashChannel => name.startsWith('#');

  /// Base64-encoded PSK for sharing with firmware CLI and related tooling.
  String get pskBase64 => base64.encode(secret);

  /// Display name for the channel
  /// Returns "Public" for channel 0, otherwise returns the custom name or "Channel N"
  String get displayName {
    if (index == 0) {
      return name.isEmpty ? 'Public' : name;
    }
    return name.isEmpty ? 'Channel $index' : name;
  }

  /// Check if channel is the public channel (index 0)
  bool get isPublicChannel => index == 0;

  /// Check if channel has a custom name
  bool get hasCustomName => name.isNotEmpty;

  /// Create from JSON
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      index: json['index'] as int,
      name: json['name'] as String? ?? '',
      secret: base64.decode(json['secret'] as String),
      flags: json['flags'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'name': name,
      'secret': base64.encode(secret),
      'flags': flags,
    };
  }

  /// Create a copy with modified fields
  Channel copyWith({int? index, String? name, Uint8List? secret, int? flags}) {
    return Channel(
      index: index ?? this.index,
      name: name ?? this.name,
      secret: secret ?? this.secret,
      flags: flags ?? this.flags,
    );
  }

  @override
  String toString() {
    return 'Channel(index: $index, name: $name, isHashChannel: $isHashChannel, flags: $flags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Channel &&
        other.index == index &&
        other.name == name &&
        _secretsEqual(other.secret, secret) &&
        other.flags == flags;
  }

  @override
  int get hashCode => Object.hash(index, name, secret, flags);

  bool _secretsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
