import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/services/offline_map_caching_provider.dart';

void main() {
  test('parses query-style tile URLs used by Google layers', () {
    final coords = OfflineMapCachingProvider.parseTileUrlForTesting(
      'http://mt0.google.com/vt/lyrs=m&hl=en&x=4312&y=2810&z=13',
    );

    expect(coords, isNotNull);
    expect(coords!.z, 13);
    expect(coords.x, 4312);
    expect(coords.y, 2810);
    expect(
      OfflineMapCachingProvider.extractUrlTemplateForTesting(
        'http://mt0.google.com/vt/lyrs=m&hl=en&x=4312&y=2810&z=13',
      ),
      'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
    );
  });

  test('parses Esri tile URLs and preserves y/x order in template', () {
    final coords = OfflineMapCachingProvider.parseTileUrlForTesting(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/9/173/267',
    );

    expect(coords, isNotNull);
    expect(coords!.z, 9);
    expect(coords.x, 267);
    expect(coords.y, 173);
    expect(
      OfflineMapCachingProvider.extractUrlTemplateForTesting(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/9/173/267',
      ),
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    );
  });
}
