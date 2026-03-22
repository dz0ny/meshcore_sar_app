import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/services/location_tracking_service.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';

void main() {
  final service = LocationTrackingService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: 'default',
    );
    service.fastLocationUpdatesEnabled = false;
    service.fastLocationMovementThresholdMeters = 10.0;
    service.fastLocationActiveCadenceSeconds = 10;
    service.fastLocationChannelIdx = null;
  });

  test('persists and restores fast location channel idx', () async {
    await service.updateFastLocationChannelIdx(3);

    service.fastLocationChannelIdx = null;
    await service.loadSettings();

    expect(service.fastLocationChannelIdx, 3);
  });

  test('clears persisted fast location channel idx when unset', () async {
    await service.updateFastLocationChannelIdx(7);
    await service.updateFastLocationChannelIdx(null);

    service.fastLocationChannelIdx = 99;
    await service.loadSettings();

    expect(service.fastLocationChannelIdx, isNull);
  });
}
