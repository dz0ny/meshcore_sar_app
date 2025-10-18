#!/bin/bash

# MeshCore SAR App Screenshot Script
# Captures screenshots on multiple devices for App Store submission

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OUTPUT_DIR="screenshots"
INTEGRATION_TEST="integration_test/app_screenshots_test.dart"

# Device configurations for App Store screenshots
# iOS devices (required sizes: 6.7", 6.5", 5.5")
IOS_DEVICES=(
  "iPhone Air"         # 6.3" - 1206x2622 (newer large format)
)

# Android devices (phone + tablet recommended)
ANDROID_DEVICES=(
  "pixel_7_pro"        # Phone - 1440x3120
  "pixel_tablet"       # Tablet - 2560x1600
)

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  MeshCore SAR Screenshot Generator       ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo ""

# Check if integration test exists
if [ ! -f "$INTEGRATION_TEST" ]; then
  echo -e "${RED}❌ Error: Integration test not found at $INTEGRATION_TEST${NC}"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to list available devices
list_devices() {
  echo -e "${YELLOW}📱 Available iOS Simulators:${NC}"
  xcrun simctl list devices available | grep "iPhone" | grep -v "unavailable"
  echo ""
  echo -e "${YELLOW}🤖 Available Android Emulators:${NC}"
  emulator -list-avds
  echo ""
}

# Function to take screenshots on iOS
take_ios_screenshots() {
  local device_name="$1"
  echo -e "${GREEN}📸 Taking screenshots on iOS: $device_name${NC}"

  # Get device ID (UUID is the first parenthesized value)
  local device_line=$(xcrun simctl list devices available | grep "$device_name" | grep -v "unavailable" | head -1)
  local device_id=$(echo "$device_line" | sed -n 's/.*(\([0-9A-F-]*\)).*/\1/p')

  if [ -z "$device_id" ]; then
    echo -e "${RED}❌ Device not found: $device_name${NC}"
    echo -e "${YELLOW}💡 Creating simulator: $device_name${NC}"
    # Try to create the device (this might fail if device type doesn't exist)
    device_id=$(xcrun simctl create "$device_name" "$device_name" 2>&1)
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Failed to create simulator. Skipping...${NC}"
      return 1
    fi
  fi

  echo -e "${BLUE}   Device ID: $device_id${NC}"

  # Boot the simulator if not already booted
  xcrun simctl boot "$device_id" 2>/dev/null || true
  sleep 3

  # Create device-specific output directory
  local device_dir="$OUTPUT_DIR/ios/${device_name// /_}"
  mkdir -p "$device_dir"

  # Run the integration test
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$INTEGRATION_TEST" \
    -d "$device_id" \
    --screenshot="$device_dir" || {
    echo -e "${YELLOW}⚠️  Warning: Screenshot capture had issues on $device_name${NC}"
  }

  echo -e "${GREEN}✅ Completed: $device_name${NC}"
  echo ""
}

# Function to take screenshots on Android
take_android_screenshots() {
  local device_name="$1"
  echo -e "${GREEN}📸 Taking screenshots on Android: $device_name${NC}"

  # Check if emulator exists
  if ! emulator -list-avds | grep -q "^$device_name$"; then
    echo -e "${RED}❌ Emulator not found: $device_name${NC}"
    echo -e "${YELLOW}💡 Please create the emulator first using Android Studio${NC}"
    return 1
  fi

  # Start emulator in background
  echo -e "${BLUE}   Starting emulator...${NC}"
  emulator -avd "$device_name" -no-audio -no-boot-anim &
  EMULATOR_PID=$!

  # Wait for emulator to boot
  echo -e "${BLUE}   Waiting for emulator to boot...${NC}"
  adb wait-for-device
  sleep 10

  # Wait for boot to complete
  while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    echo -e "${BLUE}   Still booting...${NC}"
    sleep 3
  done
  echo -e "${GREEN}   Emulator booted${NC}"

  # Create device-specific output directory
  local device_dir="$OUTPUT_DIR/android/${device_name}"
  mkdir -p "$device_dir"

  # Run the integration test
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$INTEGRATION_TEST" \
    -d emulator-5554 \
    --screenshot="$device_dir" || {
    echo -e "${YELLOW}⚠️  Warning: Screenshot capture had issues on $device_name${NC}"
  }

  # Kill emulator
  kill $EMULATOR_PID 2>/dev/null || true

  echo -e "${GREEN}✅ Completed: $device_name${NC}"
  echo ""
}

# Parse command line arguments
PLATFORM="all"
DEVICE_FILTER=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --ios)
      PLATFORM="ios"
      shift
      ;;
    --android)
      PLATFORM="android"
      shift
      ;;
    --device)
      DEVICE_FILTER="$2"
      shift 2
      ;;
    --list)
      list_devices
      exit 0
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --ios              Take screenshots on iOS devices only"
      echo "  --android          Take screenshots on Android devices only"
      echo "  --device <name>    Take screenshots on specific device only"
      echo "  --list             List available devices"
      echo "  --help             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                    # All devices"
      echo "  $0 --ios                              # iOS only"
      echo "  $0 --android                          # Android only"
      echo "  $0 --device 'iPhone 15 Pro Max'      # Specific device"
      echo "  $0 --list                             # List available devices"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Create test driver if it doesn't exist
DRIVER_FILE="test_driver/integration_test.dart"
mkdir -p test_driver
if [ ! -f "$DRIVER_FILE" ]; then
  echo -e "${YELLOW}📝 Creating integration test driver...${NC}"
  cat > "$DRIVER_FILE" << 'EOF'
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
EOF
fi

# Take screenshots
if [ -n "$DEVICE_FILTER" ]; then
  # Specific device
  echo -e "${BLUE}🎯 Taking screenshots on: $DEVICE_FILTER${NC}"
  echo ""

  # Determine if iOS or Android based on device name
  if [[ "$DEVICE_FILTER" == *"iPhone"* ]] || [[ "$DEVICE_FILTER" == *"iPad"* ]]; then
    take_ios_screenshots "$DEVICE_FILTER"
  else
    take_android_screenshots "$DEVICE_FILTER"
  fi
else
  # Multiple devices based on platform
  if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    echo -e "${BLUE}🍎 Taking iOS screenshots...${NC}"
    echo ""
    for device in "${IOS_DEVICES[@]}"; do
      take_ios_screenshots "$device"
    done
  fi

  if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    echo -e "${BLUE}🤖 Taking Android screenshots...${NC}"
    echo ""
    for device in "${ANDROID_DEVICES[@]}"; do
      take_android_screenshots "$device"
    done
  fi
fi

echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Screenshot Capture Complete!         ║${NC}"
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}📁 Screenshots saved to: $OUTPUT_DIR${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review screenshots in $OUTPUT_DIR"
echo -e "  2. Organize by device size for App Store"
echo -e "  3. Add captions and localization if needed"
echo ""
