# Google Play Release Runbook

## Purpose

This runbook prepares and ships the Android release build for `com.meshcore.sar.meshcore_sar_app`.

## Distribution Modes

- GitHub release: signed APK for direct install or manual distribution.
- Google Play: signed AAB uploaded through Fastlane to Play internal testing and, for non-prerelease GitHub releases, production.

## Required Secrets and Local Files

GitHub Actions secrets for `dz0ny/meshcore-sar`:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

Local files used to seed the secrets:

- `android/key.properties`
- release keystore referenced by `android/key.properties`
- `/Users/dz0ny/android-keystores/fastlane-480919-0cb30c62db50.json`

The Play Console service account must have release access for `com.meshcore.sar.meshcore_sar_app`.

## CI Release Flow

The release flow runs from `.github/workflows/build-artifacts.yml` when a GitHub release is published.

Android release steps:

1. Validate all Android signing and Google Play secrets.
2. Recreate `android/release-keystore.jks` and `android/key.properties` from GitHub secrets.
3. Build the signed APK with `flutter build apk --release`.
4. Build the signed Play AAB with `flutter build appbundle --release`.
5. Upload the APK and AAB as GitHub release assets.
6. Upload the AAB to Play internal testing with `bundle exec fastlane android internal`.
7. Upload the AAB to Play production when the GitHub release is not marked as prerelease.

The same workflow also builds Linux, macOS, Windows, iOS unsigned, and web artifacts.

## Versioning Rules

- Version source of truth: `pubspec.yaml`.
- Android `versionCode` is the number after `+`.
- `versionCode` must always increase for Play uploads.
- `make bump`, `make build`, and `make bundle` increment the version.
- Use `make build-no-bump` or `make bundle-no-bump` only when intentionally rebuilding the same version locally.

## Manual Build Commands

Run commands from the repo root.

```bash
flutter build apk --release
flutter build appbundle --release
```

Repo shortcuts:

```bash
make build
make bundle
make build-no-bump
make bundle-no-bump
```

## Fastlane Lanes

Run commands from `android/`.

```bash
bundle exec fastlane android direct_apk
bundle exec fastlane android internal
bundle exec fastlane android production
```

Set `SKIP_ANDROID_BUILD=1` when an AAB has already been built and Fastlane should only upload it.

```bash
SKIP_ANDROID_BUILD=1 GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(cat /Users/dz0ny/android-keystores/fastlane-480919-0cb30c62db50.json)" bundle exec fastlane android internal
```

## Expected Artifacts

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- Release APK asset: `meshcore-sar-<tag>-android.apk`
- Release AAB asset: `meshcore-sar-<tag>-play.aab`

## Internal Testing Release Checklist

1. Confirm `pubspec.yaml` version is correct and `versionCode` increased.
2. Confirm `android/key.properties` points to the release keystore for local builds.
3. Confirm all five GitHub Actions secrets exist.
4. Publish a prerelease in GitHub to build assets and upload Play internal testing without production promotion.
5. Install from the internal testing track on a real Android device.
6. Smoke test startup, permissions, map, messaging, telemetry, and offline map behavior.

## Production Release Checklist

1. Complete internal testing validation first.
2. Confirm Play Console forms are current:
   - App content
   - Data safety
   - App access
   - Ads declaration
   - Content rating
3. Confirm store assets are current:
   - app icon
   - feature graphic
   - phone screenshots
   - tablet screenshots if used
   - support URL
   - privacy policy URL
4. Publish a non-prerelease GitHub release.
5. Confirm the GitHub release has the APK and AAB assets.
6. Confirm Play Console has the new internal and production release entries.

## Rollback Rules

- Never reuse or lower an Android `versionCode`.
- If a Play release is bad, halt rollout in Play Console and ship a new higher-version fix.
- Keep GitHub direct APK and Play AAB artifacts separate; do not upload APKs to Play.
