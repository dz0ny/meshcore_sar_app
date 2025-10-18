import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Helper class for taking screenshots during integration tests
class ScreenshotHelper {
  final IntegrationTestWidgetsFlutterBinding binding;
  final String outputDir;
  int _screenshotCounter = 0;

  ScreenshotHelper(this.binding, {this.outputDir = 'screenshots'});

  /// Take a screenshot with automatic numbering and description
  Future<void> takeScreenshot(
    WidgetTester tester,
    String description, {
    Duration? wait,
  }) async {
    // Wait for UI to settle
    await tester.pumpAndSettle(wait ?? const Duration(milliseconds: 500));

    // Add extra delay for animations
    await Future.delayed(const Duration(milliseconds: 300));

    // Increment counter
    _screenshotCounter++;

    // Format filename: 01_description.png
    final filename =
        '${_screenshotCounter.toString().padLeft(2, '0')}_${_sanitizeFilename(description)}.png';

    if (kDebugMode) {
      print('📸 Taking screenshot: $filename');
    }

    // Take screenshot
    await binding.takeScreenshot(filename);
  }

  /// Sanitize filename by removing special characters
  String _sanitizeFilename(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '_')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Reset counter (useful for multiple test runs)
  void resetCounter() {
    _screenshotCounter = 0;
  }

  /// Get current screenshot count
  int get screenshotCount => _screenshotCounter;

  /// Create output directory if it doesn't exist
  static Future<void> ensureOutputDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}

/// Extension methods for easier screenshot taking
extension ScreenshotTestExtension on WidgetTester {
  /// Wait for a specific widget to appear
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump();
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw Exception('Widget not found: $finder');
  }

  /// Tap and wait for navigation
  Future<void> tapAndSettle(Finder finder, {Duration? settleDuration}) async {
    await tap(finder);
    await pumpAndSettle(settleDuration ?? const Duration(milliseconds: 500));
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder,
    Finder scrollable, {
    double delta = 100,
    int maxScrolls = 50,
  }) async {
    int scrollCount = 0;
    while (finder.evaluate().isEmpty && scrollCount < maxScrolls) {
      await drag(scrollable, Offset(0, -delta));
      await pump(const Duration(milliseconds: 100));
      scrollCount++;
    }
    if (finder.evaluate().isEmpty) {
      throw Exception('Could not scroll to widget: $finder');
    }
  }

  /// Fill text field and dismiss keyboard
  Future<void> enterTextAndDismiss(Finder finder, String text) async {
    await enterText(finder, text);
    await pump();
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
  }
}
