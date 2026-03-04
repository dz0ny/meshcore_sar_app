# MeshCore SAR Makefile
# Version format: YYYY.MMDD.N+build (Flutter-compatible semver with date)
# Example: 2025.1205.1+1

# Configuration
APP_NAME := meshcore-sar
PUBSPEC := pubspec.yaml
BUILD_DIR := build/app/outputs/flutter-apk

# Get current date parts
YEAR := $(shell date +%Y)
MMDD := $(shell date +%m%d)

# Get current version info from pubspec.yaml
CURRENT_VERSION := $(shell grep '^version:' $(PUBSPEC) | sed 's/version: //')
CURRENT_BUILD_NUMBER := $(shell echo $(CURRENT_VERSION) | cut -d'+' -f2)

# Extract current MMDD from version (middle part)
CURRENT_MMDD := $(shell echo $(CURRENT_VERSION) | cut -d'.' -f2)

# Calculate new build number
# IMPORTANT: Build number (version code) must ALWAYS increment for Android updates
# Never reset to 1, even on date changes
NEW_BUILD_NUMBER := $(shell echo $$(($(CURRENT_BUILD_NUMBER) + 1)))

# Calculate daily sequence number (resets each day for version name readability)
DAILY_BUILD := $(shell \
	if [ "$(CURRENT_MMDD)" = "$(MMDD)" ]; then \
		echo $(CURRENT_VERSION) | cut -d'.' -f3 | cut -d'+' -f1 | awk '{print $$1 + 1}'; \
	else \
		echo 1; \
	fi)

# Version format: YYYY.MMDD.DAILY+BUILD
# DAILY resets each day (for readability), BUILD always increments (for Android)
NEW_VERSION := $(YEAR).$(MMDD).$(DAILY_BUILD)+$(NEW_BUILD_NUMBER)
NEW_BUILD_NAME := $(shell echo $(NEW_VERSION) | cut -d'+' -f1)

.PHONY: help version bump make-bump sync-ios-version build release release-android release-ios clean deps analyze test icon bundle bundle-no-bump

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

version: ## Show current and next version
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Current build:   $(CURRENT_BUILD_NUMBER)"
	@echo "---"
	@echo "Next version:    $(NEW_VERSION)"

bump: ## Bump version in pubspec.yaml
	@echo "Bumping version to $(NEW_VERSION)..."
	@sed -i '' 's/^version: .*/version: $(NEW_VERSION)/' $(PUBSPEC)
	@$(MAKE) sync-ios-version BUILD_NAME=$(NEW_BUILD_NAME) BUILD_NUMBER=$(NEW_BUILD_NUMBER)
	@echo "Version bumped to $(NEW_VERSION)"

make-bump: bump ## Alias for bump

sync-ios-version: ## Sync iOS FLUTTER_BUILD_NAME/NUMBER from pubspec or provided BUILD_NAME/BUILD_NUMBER
	@$(eval IOS_VERSION := $(shell grep '^version:' $(PUBSPEC) | sed 's/version: //'))
	@$(eval IOS_BUILD_NAME := $(if $(BUILD_NAME),$(BUILD_NAME),$(shell echo $(IOS_VERSION) | cut -d'+' -f1)))
	@$(eval IOS_BUILD_NUMBER := $(if $(BUILD_NUMBER),$(BUILD_NUMBER),$(shell echo $(IOS_VERSION) | cut -d'+' -f2)))
	@echo "Syncing iOS version to $(IOS_BUILD_NAME)+$(IOS_BUILD_NUMBER)..."
	@flutter build ios --config-only --build-name "$(IOS_BUILD_NAME)" --build-number "$(IOS_BUILD_NUMBER)" > /dev/null
	@echo "iOS version synced"

deps: ## Install dependencies
	flutter pub get

analyze: ## Run Flutter analyze
	flutter analyze

test: ## Run tests
	flutter test

icon: ## Generate app icons from icon.png
	dart run flutter_launcher_icons

build: bump ## Build release APK (auto-bumps version)
	@echo "Building release APK..."
	flutter build apk --release
	@echo "APK built: $(BUILD_DIR)/app-release.apk"
	@ls -lh $(BUILD_DIR)/app-release.apk

build-no-bump: ## Build release APK without bumping version
	flutter build apk --release
	@ls -lh $(BUILD_DIR)/app-release.apk

bundle: bump ## Build release App Bundle (auto-bumps version)
	@echo "Building release App Bundle..."
	flutter build appbundle --release
	@echo "App Bundle built: build/app/outputs/bundle/release/app-release.aab"
	@ls -lh build/app/outputs/bundle/release/app-release.aab

bundle-no-bump: ## Build release App Bundle without bumping version
	flutter build appbundle --release
	@ls -lh build/app/outputs/bundle/release/app-release.aab

release: build release-ios ## Build APK, create GitHub release, and upload iOS to TestFlight
	$(eval VERSION := $(shell grep '^version:' $(PUBSPEC) | sed 's/version: //' | cut -d'+' -f1))
	@echo "Creating GitHub release v$(VERSION)..."
	@if ! command -v gh &> /dev/null; then \
		echo "Error: GitHub CLI (gh) not installed. Install with: brew install gh"; \
		exit 1; \
	fi
	@cp $(BUILD_DIR)/app-release.apk $(BUILD_DIR)/$(APP_NAME)-$(VERSION).apk
	gh release create "v$(VERSION)" \
		"$(BUILD_DIR)/$(APP_NAME)-$(VERSION).apk#MeshCore SAR $(VERSION) APK" \
		--title "MeshCore SAR v$(VERSION)" \
		--notes "Release $(VERSION)" \
		--latest
	@echo "Release v$(VERSION) created!"

release-android: build ## Build APK and create GitHub release (Android only)
	$(eval VERSION := $(shell grep '^version:' $(PUBSPEC) | sed 's/version: //' | cut -d'+' -f1))
	@echo "Creating GitHub release v$(VERSION)..."
	@if ! command -v gh &> /dev/null; then \
		echo "Error: GitHub CLI (gh) not installed. Install with: brew install gh"; \
		exit 1; \
	fi
	@cp $(BUILD_DIR)/app-release.apk $(BUILD_DIR)/$(APP_NAME)-$(VERSION).apk
	gh release create "v$(VERSION)" \
		"$(BUILD_DIR)/$(APP_NAME)-$(VERSION).apk#MeshCore SAR $(VERSION) APK" \
		--title "MeshCore SAR v$(VERSION)" \
		--notes "Release $(VERSION)" \
		--latest
	@echo "Release v$(VERSION) created!"

release-ios: ## Build iOS and upload to TestFlight
	@echo "Building iOS and uploading to TestFlight..."
	@$(MAKE) sync-ios-version
	cd ios && fastlane release
	@echo "iOS release uploaded!"

clean: ## Clean build artifacts
	flutter clean
	rm -rf $(BUILD_DIR)

# Build for all platforms
build-all: bump ## Build for Android and iOS
	flutter build apk --release
	flutter build ios --release --no-codesign
