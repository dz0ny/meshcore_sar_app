# Screenshot Automation Guide

Comprehensive guide for capturing App Store screenshots for MeshCore SAR app using Flutter integration tests.

## Overview

This project includes automated screenshot capture for:
- **App Store submission** (iOS + Android)
- **Documentation and training materials**
- **Marketing assets**
- **Multiple devices and screen sizes**
- **Multiple locales** (English, Croatian, Slovenian)

## Quick Start

### Prerequisites

1. **Flutter SDK** installed and configured
2. **iOS**: Xcode with simulators installed
3. **Android**: Android Studio with emulators configured
4. **Dependencies installed**:
   ```bash
   flutter pub get
   ```

### Take Screenshots (All Devices)

```bash
./scripts/take_screenshots.sh
```

Screenshots will be saved to `screenshots/` directory.

## Detailed Usage

### Command Line Options

```bash
# All devices (iOS + Android)
./scripts/take_screenshots.sh

# iOS devices only
./scripts/take_screenshots.sh --ios

# Android devices only
./scripts/take_screenshots.sh --android

# Specific device
./scripts/take_screenshots.sh --device "iPhone 15 Pro Max"

# List available devices
./scripts/take_screenshots.sh --list

# Show help
./scripts/take_screenshots.sh --help
```

### Manual Test Execution

You can also run the integration test manually:

```bash
# iOS
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  -d "iPhone 15 Pro Max"

# Android (start emulator first)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_screenshots_test.dart \
  -d emulator-5554
```

## Screenshot Coverage

The automated test captures the following screens:

1. **Home Screen (Disconnected)** - Initial state showing connect button
2. **Messages List** - Messages with SAR markers displayed
3. **SAR Marker Detail** - Detailed view of a SAR event
4. **Contacts List** - Team members and repeaters
5. **Contact Detail** - Individual contact information
6. **Map View** - Map with team markers and SAR markers
7. **Map Legend** - Legend showing marker types
8. **Settings Screen** - App settings and preferences

## Device Configurations

### iOS Devices (App Store Requirements)

The script is configured for App Store screenshot requirements:

| Device | Screen Size | Resolution | Required for App Store |
|--------|-------------|------------|----------------------|
| iPhone 15 Pro Max | 6.7" | 1290x2796 | ✅ Yes (primary) |
| iPhone 14 Pro Max | 6.7" | 1290x2796 | ✅ Yes (backup) |
| iPhone 8 Plus | 5.5" | 1242x2208 | ✅ Yes (smaller size) |

**App Store Notes:**
- 6.7" display is **required** as of 2024
- 5.5" display provides compatibility with older devices
- Screenshots must be in PNG or JPEG format
- Maximum 10 screenshots per device size

### Android Devices (Google Play Requirements)

| Device | Type | Resolution | Required for Play Store |
|--------|------|------------|------------------------|
| Pixel 7 Pro | Phone | 1440x3120 | ✅ Recommended |
| Pixel Tablet | Tablet | 2560x1600 | ✅ Recommended |

**Google Play Notes:**
- Phone screenshots: 16:9 or 9:16 ratio recommended
- Tablet screenshots: Optional but recommended
- Minimum 2 screenshots, maximum 8 per device type
- PNG or JPEG format accepted

## Project Structure

```
meshcore_sar_app/
├── integration_test/
│   ├── app_screenshots_test.dart        # Main screenshot test
│   └── helpers/
│       ├── mock_data.dart               # Mock contacts, messages, markers
│       └── screenshot_helper.dart       # Screenshot utilities
├── test_driver/
│   └── integration_test.dart            # Integration test driver
├── scripts/
│   └── take_screenshots.sh              # Automated screenshot script
└── screenshots/                          # Output directory
    ├── ios/
    │   ├── iPhone_15_Pro_Max/
    │   ├── iPhone_14_Pro_Max/
    │   └── iPhone_8_Plus/
    └── android/
        ├── pixel_7_pro/
        └── pixel_tablet/
```

## Mock Data

The test uses predictable mock data for consistent screenshots:

### Contacts (6 total)
- **Alpha Team Lead** - Battery: 3850mV, 1 hop, -45 dBm
- **Bravo Scout** - Battery: 3700mV, 2 hops, -68 dBm
- **Charlie Base** - Battery: 4100mV, 0 hops, -35 dBm
- **Delta Medic** - Battery: 3600mV, 3 hops, -75 dBm
- **Mountain Repeater 1** - Repeater type
- **SAR Command Room** - Room type

### Messages (8 total)
- Team communications
- SAR marker messages
- Public channel broadcasts

### SAR Markers (3 total)
- 🧑 **Found Person** at 46.0589, 14.5078 (Bravo Scout)
- 🏕️ **Staging Area** at 46.0549, 14.5038 (Charlie Base)
- 🔥 **Fire Location** at 46.0620, 14.5120 (Alpha Team Lead)

All mock data is defined in `integration_test/helpers/mock_data.dart`.

## Customization

### Adding More Screens

Edit `integration_test/app_screenshots_test.dart`:

```dart
// Navigate to your screen
await tester.tapAndSettle(find.text('Your Screen'));

// Take screenshot
await screenshotHelper.takeScreenshot(
  tester,
  'your_screen_name',
);
```

### Changing Mock Data

Edit `integration_test/helpers/mock_data.dart`:

```dart
static List<Contact> getMockContacts() {
  return [
    Contact(
      publicKey: '0x...',
      name: 'Your Contact Name',
      // ... more fields
    ),
  ];
}
```

### Adding Devices

Edit `scripts/take_screenshots.sh`:

```bash
# iOS
IOS_DEVICES=(
  "iPhone 15 Pro Max"
  "Your Device Name"
)

# Android
ANDROID_DEVICES=(
  "pixel_7_pro"
  "your_emulator_name"
)
```

## Localization

To capture screenshots in different languages:

1. **Set system language** on simulator/emulator
2. **Run the screenshot script**
3. **Organize by locale** in output directory

Example for Croatian screenshots:

```bash
# 1. Set iOS simulator to Croatian
xcrun simctl spawn booted defaults write "Apple Global Domain" AppleLanguages -array hr

# 2. Run screenshots
./scripts/take_screenshots.sh --ios

# 3. Move to locale-specific folder
mkdir -p screenshots/ios/hr-HR
mv screenshots/ios/iPhone_15_Pro_Max/* screenshots/ios/hr-HR/
```

For automation, you can modify the script to handle locale switching.

## Troubleshooting

### Simulator Not Found

```bash
# List available simulators
xcrun simctl list devices available

# Create new simulator
xcrun simctl create "iPhone 15 Pro Max" "iPhone 15 Pro Max"
```

### Emulator Issues

```bash
# List available emulators
emulator -list-avds

# Create new emulator (use Android Studio AVD Manager)
# Or via command line:
avdmanager create avd -n pixel_7_pro -k "system-images;android-33;google_apis;x86_64"
```

### Screenshots Not Appearing

1. Check test output for errors
2. Verify `integration_test/app_screenshots_test.dart` runs successfully
3. Check `ScreenshotHelper` is calling `binding.takeScreenshot()`
4. Ensure output directory has write permissions

### Test Times Out

```bash
# Increase timeout in test
await tester.pumpAndSettle(const Duration(seconds: 10));

# Or modify flutter drive timeout
flutter drive --timeout=120s ...
```

### BLE/Permissions Errors in Tests

Integration tests run in a sandboxed environment. The test uses **mock data** instead of real BLE connections, so:

- ✅ No actual BLE device needed
- ✅ No location permissions required
- ✅ Predictable, repeatable screenshots
- ❌ Cannot test actual BLE connectivity (use manual testing for that)

## Best Practices

### For App Store Screenshots

1. **Use the largest device first** (iPhone 15 Pro Max, Pixel 7 Pro)
2. **Highlight key features** in each screenshot
3. **Add localization** for target markets
4. **Keep consistent ordering** across all devices
5. **Review before submission** - ensure no sensitive data visible

### For Quality Screenshots

1. **Clean state** - Use mock data for predictable content
2. **Good lighting** - Ensure sufficient contrast in UI
3. **Meaningful content** - Show realistic usage scenarios
4. **No debug info** - Disable debug banners/overlays
5. **Proper timing** - Wait for animations to complete

### File Organization

Recommended structure for App Store submission:

```
screenshots/
├── en-US/                    # English (default)
│   ├── 6.7-inch/            # iPhone 15 Pro Max
│   │   ├── 01_home.png
│   │   ├── 02_messages.png
│   │   └── ...
│   ├── 5.5-inch/            # iPhone 8 Plus
│   └── android-phone/       # Pixel 7 Pro
├── hr-HR/                   # Croatian
│   └── ...
└── sl-SI/                   # Slovenian
    └── ...
```

## Advanced: CI/CD Integration

For automated screenshot generation in CI/CD pipelines:

```yaml
# .github/workflows/screenshots.yml
name: Generate Screenshots
on:
  workflow_dispatch:  # Manual trigger

jobs:
  screenshots:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Install dependencies
        run: flutter pub get
      - name: Take screenshots
        run: ./scripts/take_screenshots.sh --ios
      - name: Upload screenshots
        uses: actions/upload-artifact@v3
        with:
          name: screenshots
          path: screenshots/
```

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [App Store Screenshot Requirements](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
- [Google Play Screenshot Requirements](https://support.google.com/googleplay/android-developer/answer/9866151)
- [MeshCore SAR Documentation](./CLAUDE.md)

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Flutter integration test docs
3. Open an issue in the project repository
