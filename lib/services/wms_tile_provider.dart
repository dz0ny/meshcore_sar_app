import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// Custom tile provider that logs WMS URLs for debugging
class DebugWmsTileProvider extends TileProvider {
  final http.Client httpClient;

  DebugWmsTileProvider() : httpClient = http.Client();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return DebugNetworkTileProvider(
      coordinates: coordinates,
      options: options,
      httpClient: httpClient,
    );
  }

  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }
}

class DebugNetworkTileProvider extends ImageProvider<DebugNetworkTileProvider> {
  final TileCoordinates coordinates;
  final TileLayer options;
  final http.Client httpClient;

  const DebugNetworkTileProvider({
    required this.coordinates,
    required this.options,
    required this.httpClient,
  });

  @override
  ImageStreamCompleter loadImage(DebugNetworkTileProvider key, ImageDecoderCallback decode) {
    // Get the WMS URL from the tile layer options
    final wmsOptions = options.wmsOptions;
    if (wmsOptions == null) {
      throw Exception('WMSTileLayerOptions is required for DebugWmsTileProvider');
    }

    // Build the WMS URL
    final url = wmsOptions.getUrl(coordinates, 256, false);

    // Log the URL for debugging
    debugPrint('🌐 WMS Request URL: $url');

    // Use NetworkImage to load the tile
    return NetworkImage(url, headers: {'User-Agent': 'MeshCore SAR'})
        .loadImage(NetworkImage(url), decode);
  }

  @override
  Future<DebugNetworkTileProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DebugNetworkTileProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebugNetworkTileProvider &&
        other.coordinates == coordinates &&
        other.options == options;
  }

  @override
  int get hashCode => Object.hash(coordinates, options);
}
