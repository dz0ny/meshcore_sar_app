import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_sar_app/main.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/drawing_provider.dart';
import 'package:meshcore_sar_app/providers/map_provider.dart';

import 'helpers/screenshot_helper.dart';
import 'helpers/mock_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Screenshots', () {
    late ScreenshotHelper screenshotHelper;

    testWidgets('Capture all app screens with mock data', (tester) async {
      // Initialize screenshot helper
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      screenshotHelper = ScreenshotHelper(binding);

      // Pump the app
      await tester.pumpWidget(const MeshCoreSarApp());
      await tester.pumpAndSettle();

      // ===================================================================
      // 1. DISCONNECTED STATE - Home Screen
      // ===================================================================
      await screenshotHelper.takeScreenshot(
        tester,
        'home_disconnected',
        wait: const Duration(seconds: 1),
      );

      // ===================================================================
      // 2. SIMULATED CONNECTED STATE (inject mock data into providers)
      // ===================================================================
      // Note: Since we can't actually connect to a BLE device in tests,
      // we'll need to manually inject mock data into the providers.
      // This requires accessing the providers through the context.

      final context = tester.element(find.byType(MaterialApp));
      final contactsProvider = context.read<ContactsProvider>();
      final messagesProvider = context.read<MessagesProvider>();

      // Inject mock contacts
      final mockContacts = MockData.getMockContacts();
      for (final contact in mockContacts) {
        contactsProvider.addOrUpdateContact(contact);
      }

      // Inject mock messages
      final mockMessages = MockData.getMockMessages();
      for (final message in mockMessages) {
        messagesProvider.receiveMessage(message);
      }

      // Inject mock SAR markers
      final mockSarMarkers = MockData.getMockSarMarkers();
      for (final marker in mockSarMarkers) {
        messagesProvider.addSarMarker(marker);
      }

      await tester.pumpAndSettle();

      // ===================================================================
      // 3. MESSAGES TAB WITH DATA
      // ===================================================================
      // The app should default to Messages tab (index 0)
      await screenshotHelper.takeScreenshot(
        tester,
        'messages_list_with_sar_markers',
      );

      // Try to find and tap a SAR marker to show detail
      final sarMarkerFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().contains('SarMarker'),
      );
      if (sarMarkerFinder.hasFound) {
        await tester.tapAndSettle(sarMarkerFinder.first);
        await screenshotHelper.takeScreenshot(
          tester,
          'messages_sar_marker_detail',
        );
        // Go back
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // ===================================================================
      // 4. CONTACTS TAB
      // ===================================================================
      // Find and tap the Contacts tab
      final contactsTab = find.text('Contacts');
      if (contactsTab.hasFound) {
        await tester.tapAndSettle(contactsTab);
      } else {
        // Try icon-based navigation
        final tabBar = find.byType(TabBar);
        if (tabBar.hasFound) {
          final contactsIcon = find.descendant(
            of: tabBar,
            matching: find.byIcon(Icons.contacts),
          );
          await tester.tapAndSettle(contactsIcon);
        }
      }

      await screenshotHelper.takeScreenshot(
        tester,
        'contacts_list_with_teams',
      );

      // Try to find and tap a contact to show detail
      final contactListTile = find.byType(ListTile).first;
      if (contactListTile.hasFound) {
        await tester.tapAndSettle(contactListTile);
        await screenshotHelper.takeScreenshot(
          tester,
          'contacts_detail_dialog',
        );
        // Close dialog (tap outside or back button)
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // ===================================================================
      // 5. MAP TAB
      // ===================================================================
      // Find and tap the Map tab
      final mapTab = find.text('Map');
      if (mapTab.hasFound) {
        await tester.tapAndSettle(mapTab);
      } else {
        // Try icon-based navigation
        final tabBar = find.byType(TabBar);
        if (tabBar.hasFound) {
          final mapIcon = find.descendant(
            of: tabBar,
            matching: find.byIcon(Icons.map),
          );
          await tester.tapAndSettle(mapIcon);
        }
      }

      // Wait for map to load
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await screenshotHelper.takeScreenshot(
        tester,
        'map_with_markers_and_sar',
      );

      // Try to find and open the map legend
      final legendFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().contains('Legend'),
      );
      if (legendFinder.hasFound) {
        await tester.tapAndSettle(legendFinder.first);
        await screenshotHelper.takeScreenshot(
          tester,
          'map_legend_expanded',
        );
      }

      // ===================================================================
      // 6. SETTINGS SCREEN (via menu)
      // ===================================================================
      // Go back to Messages tab
      final messagesTab = find.text('Messages');
      if (messagesTab.hasFound) {
        await tester.tapAndSettle(messagesTab);
      }

      // Find and tap the menu button
      final menuButton = find.byIcon(Icons.more_vert);
      if (menuButton.hasFound) {
        await tester.tapAndSettle(menuButton);

        // Find and tap Settings in the popup menu
        final settingsMenuItem = find.text('Settings');
        if (settingsMenuItem.hasFound) {
          await tester.tapAndSettle(settingsMenuItem);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          await screenshotHelper.takeScreenshot(
            tester,
            'settings_screen',
          );

          // Go back
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }

      // ===================================================================
      // 7. SIMULATED DEVICE CONNECTION DIALOG
      // ===================================================================
      // NOTE: This is challenging without actual BLE, but we can try to
      // trigger the connection dialog
      // For now, we'll skip this as it requires disconnecting first

      // ===================================================================
      // SUMMARY
      // ===================================================================
      print('\n✅ Screenshot capture complete!');
      print('📸 Total screenshots taken: ${screenshotHelper.screenshotCount}');
      print('\nScreenshots are saved in the default integration test output directory.');
      print('To view them, check your flutter drive output folder.\n');
    });
  });
}
