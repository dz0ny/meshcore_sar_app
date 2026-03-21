import 'package:flutter/foundation.dart';
import '../models/channel.dart';

/// Manages channel information from the MeshCore device
class ChannelsProvider with ChangeNotifier {
  final Map<int, Channel> _channels = {};
  int _selectedChannelIndex = 0; // Default to public channel

  /// Get all channels
  List<Channel> get channels =>
      _channels.values.toList()..sort((a, b) => a.index.compareTo(b.index));

  /// Get a specific channel by index
  Channel? getChannel(int index) => _channels[index];

  /// Get the currently selected channel
  Channel? get selectedChannel => _channels[_selectedChannelIndex];

  /// Get the selected channel index
  int get selectedChannelIndex => _selectedChannelIndex;

  /// Get the display name for a channel
  String getChannelDisplayName(int index) {
    final channel = _channels[index];
    if (channel != null) {
      return channel.displayName;
    }
    // Fallback if channel hasn't been synced yet
    return index == 0 ? 'Public' : 'Channel $index';
  }

  /// Add or update a channel
  void addOrUpdateChannel({
    required int index,
    required String name,
    required Uint8List secret,
    int? flags,
  }) {
    _channels[index] = Channel(
      index: index,
      name: name,
      secret: secret,
      flags: flags,
    );
    notifyListeners();
  }

  /// Add or update a channel using Channel object
  void addOrUpdateChannelObject(Channel channel) {
    _channels[channel.index] = channel;
    notifyListeners();
  }

  /// Remove a channel by index
  void removeChannel(int index) {
    if (_channels.containsKey(index)) {
      _channels.remove(index);

      // If the deleted channel was selected, switch to public channel
      if (_selectedChannelIndex == index) {
        _selectedChannelIndex = 0;
      }

      notifyListeners();
    }
  }

  /// Select a channel for sending messages
  void selectChannel(int index) {
    if (_channels.containsKey(index) || index == 0) {
      _selectedChannelIndex = index;
      notifyListeners();
    }
  }

  /// Get channels by type (hash-based vs normal)
  List<Channel> getHashChannels() {
    return channels.where((c) => c.isHashChannel).toList();
  }

  List<Channel> getNormalChannels() {
    return channels.where((c) => !c.isHashChannel).toList();
  }

  /// Initialize default public channel
  void initializePublicChannel() {
    if (!_channels.containsKey(0)) {
      _channels[0] = Channel.publicChannel();
      notifyListeners();
    }
  }

  /// Clear all channels
  void clear() {
    _channels.clear();
    _selectedChannelIndex = 0;
    notifyListeners();
  }

  /// Clear runtime channel state before a live device sync begins.
  void prepareForDeviceSync() {
    _channels.clear();
    _selectedChannelIndex = 0;
    notifyListeners();
  }

  /// Check if channels have been loaded
  bool get hasChannels => _channels.isNotEmpty;

  /// Get the number of channels
  int get channelCount => _channels.length;

  @override
  void dispose() {
    _channels.clear();
    super.dispose();
  }
}
