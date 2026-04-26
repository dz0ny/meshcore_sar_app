import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hr'),
    Locale('it'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('sl'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'MeshCore SAR'**
  String get appTitle;

  /// Messages tab label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Contacts tab label
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Map tab label
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Connect button label
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Disconnect button label
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Text shown when no BLE devices are found
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// Button to restart BLE scanning
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// Error message when device is not connected
  ///
  /// In en, this message translates to:
  /// **'Device not connected'**
  String get deviceNotConnected;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Error when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable in Settings.'**
  String get locationPermissionPermanentlyDenied;

  /// Message when location permission is needed
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for GPS tracking and team coordination. You can enable it later in Settings.'**
  String get locationPermissionRequired;

  /// Error when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in Settings.'**
  String get locationServicesDisabled;

  /// Error when GPS location cannot be obtained
  ///
  /// In en, this message translates to:
  /// **'Failed to get GPS location'**
  String get failedToGetGpsLocation;

  /// Error message for failed advertisement
  ///
  /// In en, this message translates to:
  /// **'Failed to advertise: {error}'**
  String failedToAdvertise(String error);

  /// Tooltip for cancel reconnection button
  ///
  /// In en, this message translates to:
  /// **'Cancel reconnection'**
  String get cancelReconnection;

  /// General settings section header
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Theme selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Description for blue light theme
  ///
  /// In en, this message translates to:
  /// **'Blue light theme'**
  String get blueLightTheme;

  /// Description for blue dark theme
  ///
  /// In en, this message translates to:
  /// **'Blue dark theme'**
  String get blueDarkTheme;

  /// SAR Red theme option
  ///
  /// In en, this message translates to:
  /// **'SAR Red'**
  String get sarRed;

  /// Description for SAR Red theme
  ///
  /// In en, this message translates to:
  /// **'Alert/Emergency mode'**
  String get alertEmergencyMode;

  /// SAR Green theme option
  ///
  /// In en, this message translates to:
  /// **'SAR Green'**
  String get sarGreen;

  /// Description for SAR Green theme
  ///
  /// In en, this message translates to:
  /// **'Safe/All Clear mode'**
  String get safeAllClearMode;

  /// Auto/System theme option
  ///
  /// In en, this message translates to:
  /// **'Auto (System)'**
  String get autoSystem;

  /// Description for system theme
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get followSystemTheme;

  /// Setting to show RX/TX indicators
  ///
  /// In en, this message translates to:
  /// **'Show RX/TX Indicators'**
  String get showRxTxIndicators;

  /// Setting to disable the map tab
  ///
  /// In en, this message translates to:
  /// **'Disable Map'**
  String get disableMap;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// About section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// About dialog title
  ///
  /// In en, this message translates to:
  /// **'About MeshCore SAR'**
  String get aboutMeshCoreSar;

  /// About dialog description
  ///
  /// In en, this message translates to:
  /// **'A Search & Rescue application designed for emergency response teams. Features include:\n\n• BLE mesh networking for device-to-device communication\n• Offline maps with multiple layer options\n• Real-time team member tracking\n• SAR tactical markers (found person, fire, staging)\n• Contact management and messaging\n• GPS tracking with compass heading\n• Map tile caching for offline use'**
  String get aboutDescription;

  /// Technologies used section title
  ///
  /// In en, this message translates to:
  /// **'Technologies Used:'**
  String get technologiesUsed;

  /// List of technologies used
  ///
  /// In en, this message translates to:
  /// **'• Flutter for cross-platform development\n• BLE (Bluetooth Low Energy) for mesh networking\n• OpenStreetMap for mapping\n• Provider for state management\n• SharedPreferences for local storage'**
  String get technologiesList;

  /// More info button label
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get moreInfo;

  /// Package name label
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get packageName;

  /// Sample data section header
  ///
  /// In en, this message translates to:
  /// **'Sample Data'**
  String get sampleData;

  /// Sample data section description
  ///
  /// In en, this message translates to:
  /// **'Load or clear sample contacts, channel messages, and SAR markers for testing'**
  String get sampleDataDescription;

  /// Load sample data button
  ///
  /// In en, this message translates to:
  /// **'Load Sample Data'**
  String get loadSampleData;

  /// Clear all data button
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// Clear data confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllDataConfirmTitle;

  /// Clear data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will clear all contacts and SAR markers. Are you sure?'**
  String get clearAllDataConfirmMessage;

  /// Clear button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Success message after loading sample data
  ///
  /// In en, this message translates to:
  /// **'Loaded {teamCount} team members, {channelCount} channels, {sarCount} SAR markers, {messageCount} messages'**
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  );

  /// Error message when sample data fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load sample data: {error}'**
  String failedToLoadSampleData(String error);

  /// Success message after clearing all data
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get allDataCleared;

  /// Error message when background tracking fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start background tracking. Check permissions and BLE connection.'**
  String get failedToStartBackgroundTracking;

  /// Success message for location broadcast
  ///
  /// In en, this message translates to:
  /// **'Location broadcast: {latitude}, {longitude}'**
  String locationBroadcast(String latitude, String longitude);

  /// Information about default PIN for pairing
  ///
  /// In en, this message translates to:
  /// **'The default pin for devices without a screen is 123456. Trouble pairing? Forget the bluetooth device in system settings.'**
  String get defaultPinInfo;

  /// Empty state message when there are no messages
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Instruction to pull down to refresh messages
  ///
  /// In en, this message translates to:
  /// **'Pull down to sync messages'**
  String get pullDownToSync;

  /// Delete contact action label
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get deleteContact;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Action to view contact location on map
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// Refresh button label
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Action to reset contact path for re-routing
  ///
  /// In en, this message translates to:
  /// **'Reset Path (Re-route)'**
  String get resetPath;

  /// Success message when a value is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String copiedToClipboard(String label);

  /// Validation message for empty password field
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// Error message when contact sync fails
  ///
  /// In en, this message translates to:
  /// **'Failed to sync contacts: {error}'**
  String failedToSyncContacts(String error);

  /// Success message after successful room login
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully! Waiting for room messages...'**
  String get loggedInSuccessfully;

  /// Error message when room login fails
  ///
  /// In en, this message translates to:
  /// **'Login failed - incorrect password'**
  String get loginFailed;

  /// Status message during room login process
  ///
  /// In en, this message translates to:
  /// **'Logging in to {roomName}...'**
  String loggingIn(String roomName);

  /// Error message when login command fails to send
  ///
  /// In en, this message translates to:
  /// **'Failed to send login: {error}'**
  String failedToSendLogin(String error);

  /// Warning title for low GPS accuracy
  ///
  /// In en, this message translates to:
  /// **'Low Location Accuracy'**
  String get lowLocationAccuracy;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// Action to send SAR marker
  ///
  /// In en, this message translates to:
  /// **'Send SAR marker'**
  String get sendSarMarker;

  /// Action to delete a map drawing
  ///
  /// In en, this message translates to:
  /// **'Delete Drawing'**
  String get deleteDrawing;

  /// Drawing tools section or menu title
  ///
  /// In en, this message translates to:
  /// **'Drawing Tools'**
  String get drawingTools;

  /// Map drawing mode: line
  ///
  /// In en, this message translates to:
  /// **'Draw Line'**
  String get drawLine;

  /// Description for line drawing mode
  ///
  /// In en, this message translates to:
  /// **'Draw a freehand line on the map'**
  String get drawLineDesc;

  /// Map drawing mode: rectangle
  ///
  /// In en, this message translates to:
  /// **'Draw Rectangle'**
  String get drawRectangle;

  /// Description for rectangle drawing mode
  ///
  /// In en, this message translates to:
  /// **'Draw a rectangular area on the map'**
  String get drawRectangleDesc;

  /// Map drawing mode: measure distance
  ///
  /// In en, this message translates to:
  /// **'Measure Distance'**
  String get measureDistance;

  /// Description for distance measurement mode
  ///
  /// In en, this message translates to:
  /// **'Long press two points to measure'**
  String get measureDistanceDesc;

  /// Tooltip to clear measurement
  ///
  /// In en, this message translates to:
  /// **'Clear Measurement'**
  String get clearMeasurement;

  /// Label showing measured distance
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String distanceLabel(String distance);

  /// Instruction when first measurement point is set
  ///
  /// In en, this message translates to:
  /// **'Long press for second point'**
  String get longPressForSecondPoint;

  /// Instruction to start measurement
  ///
  /// In en, this message translates to:
  /// **'Long press to set first point'**
  String get longPressToStartMeasurement;

  /// Instruction to restart measurement after completion
  ///
  /// In en, this message translates to:
  /// **'Long press to start new measurement'**
  String get longPressToStartNewMeasurement;

  /// Action to share drawings to network
  ///
  /// In en, this message translates to:
  /// **'Share Drawings'**
  String get shareDrawings;

  /// Action to clear all local drawings
  ///
  /// In en, this message translates to:
  /// **'Clear All Drawings'**
  String get clearAllDrawings;

  /// Tooltip to complete drawing a line
  ///
  /// In en, this message translates to:
  /// **'Complete Line'**
  String get completeLine;

  /// Subtitle showing how many drawings will be broadcast
  ///
  /// In en, this message translates to:
  /// **'Broadcast {count} drawing{plural} to team'**
  String broadcastDrawingsToTeam(int count, String plural);

  /// Subtitle for remove all drawings action
  ///
  /// In en, this message translates to:
  /// **'Remove all {count} drawing{plural}'**
  String removeAllDrawings(int count, String plural);

  /// Confirmation dialog message for deleting all drawings
  ///
  /// In en, this message translates to:
  /// **'Delete all {count} drawing{plural} from the map?'**
  String deleteAllDrawingsConfirm(int count, String plural);

  /// Generic drawing label
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get drawing;

  /// Title for share drawings dialog
  ///
  /// In en, this message translates to:
  /// **'Share {count} Drawing{plural}'**
  String shareDrawingsCount(int count, String plural);

  /// Toggle to show/hide received drawings from other team members
  ///
  /// In en, this message translates to:
  /// **'Show Received Drawings'**
  String get showReceivedDrawings;

  /// Subtitle when received drawings are visible
  ///
  /// In en, this message translates to:
  /// **'Showing all drawings'**
  String get showingAllDrawings;

  /// Subtitle when received drawings are hidden
  ///
  /// In en, this message translates to:
  /// **'Showing only your drawings'**
  String get showingOnlyYourDrawings;

  /// Toggle to show/hide SAR markers on map
  ///
  /// In en, this message translates to:
  /// **'Show SAR Markers'**
  String get showSarMarkers;

  /// Subtitle when SAR markers are visible
  ///
  /// In en, this message translates to:
  /// **'Showing SAR markers'**
  String get showingSarMarkers;

  /// Subtitle when SAR markers are hidden
  ///
  /// In en, this message translates to:
  /// **'Hiding SAR markers'**
  String get hidingSarMarkers;

  /// Clear all button label
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Public channel option for sharing
  ///
  /// In en, this message translates to:
  /// **'Public Channel'**
  String get publicChannel;

  /// Description for public channel broadcast
  ///
  /// In en, this message translates to:
  /// **'Broadcast to all nearby nodes (ephemeral)'**
  String get broadcastToAll;

  /// Description for room storage permanence
  ///
  /// In en, this message translates to:
  /// **'Stored permanently in room'**
  String get storedPermanently;

  /// Error message when device is not connected for direct messaging
  ///
  /// In en, this message translates to:
  /// **'Not connected to device'**
  String get notConnectedToDevice;

  /// Placeholder text for message input field
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// Subtitle for SAR marker sheet header
  ///
  /// In en, this message translates to:
  /// **'Quick location marker'**
  String get quickLocationMarker;

  /// Label for marker type selection section
  ///
  /// In en, this message translates to:
  /// **'Marker Type'**
  String get markerType;

  /// Label for destination selection section
  ///
  /// In en, this message translates to:
  /// **'Send To'**
  String get sendTo;

  /// Warning when no rooms or channels exist
  ///
  /// In en, this message translates to:
  /// **'No destinations available.'**
  String get noDestinationsAvailable;

  /// Placeholder for destination dropdown
  ///
  /// In en, this message translates to:
  /// **'Select destination...'**
  String get selectDestination;

  /// Information about ephemeral channel broadcasts
  ///
  /// In en, this message translates to:
  /// **'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.'**
  String get ephemeralBroadcastInfo;

  /// Information about persistent room storage
  ///
  /// In en, this message translates to:
  /// **'Persistent: Stored immutably in room. Synced automatically and preserved offline.'**
  String get persistentRoomInfo;

  /// Label for location section
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Badge showing location is from map tap
  ///
  /// In en, this message translates to:
  /// **'From Map'**
  String get fromMap;

  /// Loading message while fetching GPS location
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// Title for location error messages
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationError;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Tooltip for refresh location button
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get refreshLocation;

  /// Display of GPS accuracy in meters
  ///
  /// In en, this message translates to:
  /// **'Accuracy: ±{accuracy}m'**
  String accuracyMeters(int accuracy);

  /// Label for optional notes field
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// Placeholder for notes field
  ///
  /// In en, this message translates to:
  /// **'Add additional information...'**
  String get addAdditionalInformation;

  /// Warning dialog content for low GPS accuracy
  ///
  /// In en, this message translates to:
  /// **'Location accuracy is ±{accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?'**
  String lowAccuracyWarning(int accuracy);

  /// Title for room login dialog
  ///
  /// In en, this message translates to:
  /// **'Login to Room'**
  String get loginToRoom;

  /// Information about room password
  ///
  /// In en, this message translates to:
  /// **'Enter the password to access this room. The password will be saved for future use.'**
  String get enterPasswordInfo;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter room password'**
  String get enterRoomPassword;

  /// Button text while logging in
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingInDots;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Error message when adding room fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add room to device: {error}\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.'**
  String failedToAddRoom(String error);

  /// Direct routing indicator
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// Flood routing indicator
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get flood;

  /// Auto send mode - uses current path
  ///
  /// In en, this message translates to:
  /// **'Auto Send'**
  String get autoSend;

  /// Description for auto send mode
  ///
  /// In en, this message translates to:
  /// **'Send via current path.'**
  String get autoSendDescription;

  /// Send direct mode - zero-hop to contact
  ///
  /// In en, this message translates to:
  /// **'Send Direct'**
  String get sendDirect;

  /// Description for send direct mode
  ///
  /// In en, this message translates to:
  /// **'Send directly to this contact.'**
  String get sendDirectDescription;

  /// Send flood mode - via all repeaters
  ///
  /// In en, this message translates to:
  /// **'Send Flood'**
  String get sendFlood;

  /// Description for send flood mode
  ///
  /// In en, this message translates to:
  /// **'Send via all repeaters.'**
  String get sendFloodDescription;

  /// Logged in status badge
  ///
  /// In en, this message translates to:
  /// **'Logged In'**
  String get loggedIn;

  /// Message when GPS data is not available
  ///
  /// In en, this message translates to:
  /// **'No GPS data'**
  String get noGpsData;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Warning when direct ping times out
  ///
  /// In en, this message translates to:
  /// **'Direct ping timeout - retrying {name} with flooding...'**
  String directPingTimeout(String name);

  /// Error message when ping fails
  ///
  /// In en, this message translates to:
  /// **'Ping failed to {name} - no response received'**
  String pingFailed(String name);

  /// Confirmation message for deleting contact
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\n\nThis will remove the contact from both the app and the companion radio device.'**
  String deleteContactConfirmation(String name);

  /// Error message when contact removal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove contact: {error}'**
  String failedToRemoveContact(String error);

  /// Contact type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Public key label
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get publicKey;

  /// Last seen label
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get lastSeen;

  /// Yes answer
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No answer
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Permissions label
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Telemetry section header
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get telemetry;

  /// Voltage label
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get voltage;

  /// Battery label
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// Temperature label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Humidity label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Pressure label
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// GPS from telemetry label
  ///
  /// In en, this message translates to:
  /// **'GPS (Telemetry)'**
  String get gpsTelemetry;

  /// Button to re-login to room
  ///
  /// In en, this message translates to:
  /// **'Re-Login to Room'**
  String get reLoginToRoom;

  /// Compass heading label
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get heading;

  /// Elevation/altitude label
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// GPS accuracy label
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// Bearing label in compass
  ///
  /// In en, this message translates to:
  /// **'Bearing'**
  String get bearing;

  /// Direction label in compass
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// Title for filter markers dialog
  ///
  /// In en, this message translates to:
  /// **'Filter Markers'**
  String get filterMarkers;

  /// Tooltip for filter button
  ///
  /// In en, this message translates to:
  /// **'Filter markers'**
  String get filterMarkersTooltip;

  /// Filter option for contacts
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsFilter;

  /// Filter option for repeaters
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get repeatersFilter;

  /// SAR markers section header
  ///
  /// In en, this message translates to:
  /// **'SAR Markers'**
  String get sarMarkers;

  /// Found person SAR marker type
  ///
  /// In en, this message translates to:
  /// **'Found Person'**
  String get foundPerson;

  /// Fire SAR marker type
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get fire;

  /// Staging area SAR marker type
  ///
  /// In en, this message translates to:
  /// **'Staging Area'**
  String get stagingArea;

  /// Button to show all filters
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// Message when GPS location is unavailable
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// Relative bearing direction - ahead
  ///
  /// In en, this message translates to:
  /// **'ahead'**
  String get ahead;

  /// Relative bearing direction - right
  ///
  /// In en, this message translates to:
  /// **'{degrees}° right'**
  String degreesRight(int degrees);

  /// Relative bearing direction - left
  ///
  /// In en, this message translates to:
  /// **'{degrees}° left'**
  String degreesLeft(int degrees);

  /// Latitude and longitude display format
  ///
  /// In en, this message translates to:
  /// **'Lat: {latitude} Lon: {longitude}'**
  String latLonFormat(String latitude, String longitude);

  /// Empty state message when there are no contacts
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// Instruction to connect device to load contacts
  ///
  /// In en, this message translates to:
  /// **'Connect to a device to load contacts'**
  String get connectToDeviceToLoadContacts;

  /// Section header for team members (chat contacts)
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// Section header for repeater nodes
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get repeaters;

  /// Section header for rooms
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// Section header for broadcast channels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// Title for map layer selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Map Layer'**
  String get selectMapLayer;

  /// OpenStreetMap layer name
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap'**
  String get openStreetMap;

  /// OpenTopoMap layer name
  ///
  /// In en, this message translates to:
  /// **'OpenTopoMap'**
  String get openTopoMap;

  /// ESRI Satellite imagery layer name
  ///
  /// In en, this message translates to:
  /// **'ESRI Satellite'**
  String get esriSatellite;

  /// Google Hybrid layer name (satellite + labels)
  ///
  /// In en, this message translates to:
  /// **'Google Hybrid'**
  String get googleHybrid;

  /// Google Roadmap layer name (street map)
  ///
  /// In en, this message translates to:
  /// **'Google Roadmap'**
  String get googleRoadmap;

  /// Google Terrain layer name (topographic)
  ///
  /// In en, this message translates to:
  /// **'Google Terrain'**
  String get googleTerrain;

  /// Label when dragging a pin on map
  ///
  /// In en, this message translates to:
  /// **'Drag to Position'**
  String get dragToPosition;

  /// Label for creating SAR marker from pin
  ///
  /// In en, this message translates to:
  /// **'Create SAR Marker'**
  String get createSarMarker;

  /// Compass title in detailed compass dialog
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get compass;

  /// Subtitle for compass dialog
  ///
  /// In en, this message translates to:
  /// **'Navigation & Contacts'**
  String get navigationAndContacts;

  /// Label for SAR alert badge on messages
  ///
  /// In en, this message translates to:
  /// **'SAR ALERT'**
  String get sarAlert;

  /// Success message when text is copied
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopiedToClipboard;

  /// Error when sender info is missing for reply
  ///
  /// In en, this message translates to:
  /// **'Cannot reply: sender information missing'**
  String get cannotReplySenderMissing;

  /// Error when contact not found for reply
  ///
  /// In en, this message translates to:
  /// **'Cannot reply: contact not found'**
  String get cannotReplyContactNotFound;

  /// Option to copy message text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// Option to save SAR message as a reusable template
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get saveAsTemplate;

  /// Success message when SAR template is saved
  ///
  /// In en, this message translates to:
  /// **'Template saved successfully'**
  String get templateSaved;

  /// Error message when trying to save duplicate template
  ///
  /// In en, this message translates to:
  /// **'Template with this emoji already exists'**
  String get templateAlreadyExists;

  /// Dialog title for deleting a message
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// Confirmation text for message deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirmation;

  /// Option to share SAR marker location
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// Formatted text for sharing SAR marker location
  ///
  /// In en, this message translates to:
  /// **'{markerInfo}\n\nCoordinates: {lat}, {lon}\n\nGoogle Maps: {url}'**
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  );

  /// Subject line when sharing SAR marker location
  ///
  /// In en, this message translates to:
  /// **'SAR Location'**
  String get sarLocationShare;

  /// Time indicator for very recent activity
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Time indicator for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Time indicator for hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Time indicator for days ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// Time indicator for seconds ago
  ///
  /// In en, this message translates to:
  /// **'{seconds}s ago'**
  String secondsAgo(int seconds);

  /// Delivery status: sending
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// Delivery status: sent
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// Delivery status: delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Delivery status with round-trip time
  ///
  /// In en, this message translates to:
  /// **'Delivered ({time}ms)'**
  String deliveredWithTime(int time);

  /// Delivery status: failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Delivery status for channel messages (no echoes yet)
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// Grouped message delivery count
  ///
  /// In en, this message translates to:
  /// **'Delivered to {delivered}/{total} contacts'**
  String deliveredToContacts(int delivered, int total);

  /// Status when all recipients received the message
  ///
  /// In en, this message translates to:
  /// **'All delivered'**
  String get allDelivered;

  /// Header for expandable recipient list
  ///
  /// In en, this message translates to:
  /// **'Recipient Details'**
  String get recipientDetails;

  /// Delivery status: pending/waiting
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// SAR marker type: found person
  ///
  /// In en, this message translates to:
  /// **'Found Person'**
  String get sarMarkerFoundPerson;

  /// SAR marker type: fire
  ///
  /// In en, this message translates to:
  /// **'Fire Location'**
  String get sarMarkerFire;

  /// SAR marker type: staging area
  ///
  /// In en, this message translates to:
  /// **'Staging Area'**
  String get sarMarkerStagingArea;

  /// SAR marker type: object
  ///
  /// In en, this message translates to:
  /// **'Object Found'**
  String get sarMarkerObject;

  /// Sender label in notifications
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// Coordinates label
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// Notification action text
  ///
  /// In en, this message translates to:
  /// **'Tap to view on map'**
  String get tapToViewOnMap;

  /// Section title for radio settings
  ///
  /// In en, this message translates to:
  /// **'Radio Settings'**
  String get radioSettings;

  /// Label for radio frequency field
  ///
  /// In en, this message translates to:
  /// **'Frequency (MHz)'**
  String get frequencyMHz;

  /// Label for bandwidth dropdown
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get bandwidth;

  /// Label for spreading factor dropdown
  ///
  /// In en, this message translates to:
  /// **'Spreading Factor'**
  String get spreadingFactor;

  /// Label for coding rate dropdown
  ///
  /// In en, this message translates to:
  /// **'Coding Rate'**
  String get codingRate;

  /// Label for TX power field
  ///
  /// In en, this message translates to:
  /// **'TX Power (dBm)'**
  String get txPowerDbm;

  /// Helper text showing maximum TX power
  ///
  /// In en, this message translates to:
  /// **'Max: {power} dBm'**
  String maxPowerDbm(int power);

  /// Label for the current user in message bubbles
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Error message when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// Error message when import fails
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// Unknown value label
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Section header for online map layers
  ///
  /// In en, this message translates to:
  /// **'Online Layers'**
  String get onlineLayers;

  /// Location trail title
  ///
  /// In en, this message translates to:
  /// **'Location Trail'**
  String get locationTrail;

  /// Toggle to show/hide trail on map
  ///
  /// In en, this message translates to:
  /// **'Show Trail on Map'**
  String get showTrailOnMap;

  /// Trail visibility status - visible
  ///
  /// In en, this message translates to:
  /// **'Trail is visible on the map'**
  String get trailVisible;

  /// Trail visibility status - hidden but recording
  ///
  /// In en, this message translates to:
  /// **'Trail is hidden (still recording)'**
  String get trailHiddenRecording;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Trail points count label
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// Button to clear location trail
  ///
  /// In en, this message translates to:
  /// **'Clear Trail'**
  String get clearTrail;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Trail?'**
  String get clearTrailQuestion;

  /// Confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the current location trail? This action cannot be undone.'**
  String get clearTrailConfirmation;

  /// Message when no trail exists
  ///
  /// In en, this message translates to:
  /// **'No trail recorded yet'**
  String get noTrailRecorded;

  /// Instructions to start trail recording
  ///
  /// In en, this message translates to:
  /// **'Start location tracking to record your trail'**
  String get startTrackingToRecord;

  /// Trail controls tooltip
  ///
  /// In en, this message translates to:
  /// **'Trail Controls'**
  String get trailControls;

  /// Device model label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Maximum contacts capacity label
  ///
  /// In en, this message translates to:
  /// **'Max Contacts'**
  String get maxContacts;

  /// Maximum channels capacity label
  ///
  /// In en, this message translates to:
  /// **'Max Channels'**
  String get maxChannels;

  /// Public information section header
  ///
  /// In en, this message translates to:
  /// **'Public Info'**
  String get publicInfo;

  /// Tooltip for use current location button
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// Device type: none or unknown
  ///
  /// In en, this message translates to:
  /// **'None/Unknown'**
  String get noneUnknown;

  /// Device type: chat node
  ///
  /// In en, this message translates to:
  /// **'Chat Node'**
  String get chatNode;

  /// Device type: repeater
  ///
  /// In en, this message translates to:
  /// **'Repeater'**
  String get repeater;

  /// Device type: room or channel
  ///
  /// In en, this message translates to:
  /// **'Room/Channel'**
  String get roomChannel;

  /// Generic device type with number
  ///
  /// In en, this message translates to:
  /// **'Type {number}'**
  String typeNumber(int number);

  /// Generic error message for save failures
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// Error message when getting location fails
  ///
  /// In en, this message translates to:
  /// **'Failed to get location: {error}'**
  String failedToGetLocation(String error);

  /// SAR templates menu title
  ///
  /// In en, this message translates to:
  /// **'SAR Templates'**
  String get sarTemplates;

  /// Button to add new SAR template
  ///
  /// In en, this message translates to:
  /// **'Add Template'**
  String get addTemplate;

  /// Dialog title for editing template
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// Action to delete template
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// Label for template name field
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// Hint text for template name
  ///
  /// In en, this message translates to:
  /// **'e.g. Found Person'**
  String get templateNameHint;

  /// Label for template emoji field
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get templateEmoji;

  /// Validation error when emoji field is empty
  ///
  /// In en, this message translates to:
  /// **'Emoji is required'**
  String get emojiRequired;

  /// Validation error when name field is empty
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Label for template description field
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get templateDescription;

  /// Hint text for template description
  ///
  /// In en, this message translates to:
  /// **'Add additional context...'**
  String get templateDescriptionHint;

  /// Label for template color picker
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get templateColor;

  /// Label for format preview
  ///
  /// In en, this message translates to:
  /// **'Preview (SAR Message Format)'**
  String get previewFormat;

  /// Button to import templates from clipboard
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importFromClipboard;

  /// Button to export templates to clipboard
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportToClipboard;

  /// Confirmation message for template deletion
  ///
  /// In en, this message translates to:
  /// **'Delete template \'{name}\'?'**
  String deleteTemplateConfirmation(String name);

  /// Success message when template is added
  ///
  /// In en, this message translates to:
  /// **'Template added'**
  String get templateAdded;

  /// Success message when template is updated
  ///
  /// In en, this message translates to:
  /// **'Template updated'**
  String get templateUpdated;

  /// Success message when template is deleted
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templateDeleted;

  /// Success message after importing templates
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No templates imported} =1{Imported 1 template} other{Imported {count} templates}}'**
  String templatesImported(int count);

  /// Success message after exporting templates
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Exported 1 template to clipboard} other{Exported {count} templates to clipboard}}'**
  String templatesExported(int count);

  /// Action to reset templates to defaults
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// Confirmation message for reset to defaults
  ///
  /// In en, this message translates to:
  /// **'This will delete all custom templates and restore the 4 default templates. Continue?'**
  String get resetToDefaultsConfirmation;

  /// Reset button label
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Success message after reset
  ///
  /// In en, this message translates to:
  /// **'Templates reset to defaults'**
  String get resetComplete;

  /// Message when no templates exist
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplates;

  /// Helper text when no templates exist
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first template'**
  String get tapAddToCreate;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Location permission label
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermission;

  /// Loading state indicator
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// Location permission status: granted always
  ///
  /// In en, this message translates to:
  /// **'Granted (Always)'**
  String get locationPermissionGrantedAlways;

  /// Location permission status: granted while in use
  ///
  /// In en, this message translates to:
  /// **'Granted (While In Use)'**
  String get locationPermissionGrantedWhileInUse;

  /// Location permission status: denied, user can request
  ///
  /// In en, this message translates to:
  /// **'Denied - Tap to request'**
  String get locationPermissionDeniedTapToRequest;

  /// Location permission status: permanently denied
  ///
  /// In en, this message translates to:
  /// **'Permanently Denied - Open Settings'**
  String get locationPermissionPermanentlyDeniedOpenSettings;

  /// Content for location permission dialog when permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it in your device settings to use GPS tracking and location sharing features.'**
  String get locationPermissionDialogContent;

  /// Button to open device settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Success message when location permission is granted
  ///
  /// In en, this message translates to:
  /// **'Location permission granted!'**
  String get locationPermissionGranted;

  /// Info message about location permission requirement
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for GPS tracking and location sharing.'**
  String get locationPermissionRequiredForGps;

  /// Info message when permission is already granted
  ///
  /// In en, this message translates to:
  /// **'Location permission is already granted.'**
  String get locationPermissionAlreadyGranted;

  /// SAR Navy Blue theme name
  ///
  /// In en, this message translates to:
  /// **'SAR Navy Blue'**
  String get sarNavyBlue;

  /// Description for SAR Navy Blue theme
  ///
  /// In en, this message translates to:
  /// **'Professional/Operations Mode'**
  String get sarNavyBlueDescription;

  /// Title for recipient selector sheet
  ///
  /// In en, this message translates to:
  /// **'Select Recipient'**
  String get selectRecipient;

  /// Subtitle for public channel option
  ///
  /// In en, this message translates to:
  /// **'Broadcast to all nearby'**
  String get broadcastToAllNearby;

  /// Placeholder text for recipient search field
  ///
  /// In en, this message translates to:
  /// **'Search recipients...'**
  String get searchRecipients;

  /// Message when no contacts match search
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// Message when no rooms match search
  ///
  /// In en, this message translates to:
  /// **'No rooms found'**
  String get noRoomsFound;

  /// Message when no recipients exist (contacts, rooms, or channels)
  ///
  /// In en, this message translates to:
  /// **'No recipients available'**
  String get noRecipientsAvailable;

  /// Message when no channels match the search
  ///
  /// In en, this message translates to:
  /// **'No channels found'**
  String get noChannelsFound;

  /// Notification title for new message
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// Channel label in notifications
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Police Lead'**
  String get samplePoliceLead;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Drone Operator'**
  String get sampleDroneOperator;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Firefighter'**
  String get sampleFirefighterAlpha;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Medic'**
  String get sampleMedicCharlie;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get sampleCommandDelta;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Fire Engine'**
  String get sampleFireEngine;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Air Support'**
  String get sampleAirSupport;

  /// Sample team member name
  ///
  /// In en, this message translates to:
  /// **'Base Coordinator'**
  String get sampleBaseCoordinator;

  /// Emergency channel name
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get channelEmergency;

  /// Coordination channel name
  ///
  /// In en, this message translates to:
  /// **'Coordination'**
  String get channelCoordination;

  /// Updates channel name
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get channelUpdates;

  /// Sample sender name
  ///
  /// In en, this message translates to:
  /// **'Sample Team Member'**
  String get sampleTeamMember;

  /// Sample sender name
  ///
  /// In en, this message translates to:
  /// **'Sample Scout'**
  String get sampleScout;

  /// Sample sender name
  ///
  /// In en, this message translates to:
  /// **'Sample Base'**
  String get sampleBase;

  /// Sample sender name
  ///
  /// In en, this message translates to:
  /// **'Sample Searcher'**
  String get sampleSearcher;

  /// Sample object note
  ///
  /// In en, this message translates to:
  /// **' Backpack found - blue color'**
  String get sampleObjectBackpack;

  /// Sample object note
  ///
  /// In en, this message translates to:
  /// **' Vehicle abandoned - check for owner'**
  String get sampleObjectVehicle;

  /// Sample object note
  ///
  /// In en, this message translates to:
  /// **' Camping equipment discovered'**
  String get sampleObjectCamping;

  /// Sample object note
  ///
  /// In en, this message translates to:
  /// **' Trail marker found off-path'**
  String get sampleObjectTrailMarker;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'All teams check in'**
  String get sampleMsgAllTeamsCheckIn;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Weather update: Clear skies, temp 18°C'**
  String get sampleMsgWeatherUpdate;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Base camp established at staging area'**
  String get sampleMsgBaseCamp;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Team moving to sector 2'**
  String get sampleMsgTeamAlpha;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Radio check - all stations respond'**
  String get sampleMsgRadioCheck;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Water supply available at checkpoint 3'**
  String get sampleMsgWaterSupply;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Team reporting: sector 1 clear'**
  String get sampleMsgTeamBravo;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'ETA to rally point: 15 minutes'**
  String get sampleMsgEtaRallyPoint;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Supply drop confirmed for 14:00'**
  String get sampleMsgSupplyDrop;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Drone survey completed - no findings'**
  String get sampleMsgDroneSurvey;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'Team requesting backup'**
  String get sampleMsgTeamCharlie;

  /// Sample channel message
  ///
  /// In en, this message translates to:
  /// **'All units: maintain radio discipline'**
  String get sampleMsgRadioDiscipline;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'URGENT: Medical assistance needed at sector 4'**
  String get sampleMsgUrgentMedical;

  /// Sample emergency message note
  ///
  /// In en, this message translates to:
  /// **' Adult male, conscious'**
  String get sampleMsgAdultMale;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'Fire spotted - coordinates incoming'**
  String get sampleMsgFireSpotted;

  /// Sample emergency message note
  ///
  /// In en, this message translates to:
  /// **' Spreading rapidly!'**
  String get sampleMsgSpreadingRapidly;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'PRIORITY: Need helicopter support'**
  String get sampleMsgPriorityHelicopter;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'Medical team en route to your location'**
  String get sampleMsgMedicalTeamEnRoute;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'Evac helicopter ETA 10 minutes'**
  String get sampleMsgEvacHelicopter;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'Emergency resolved - all clear'**
  String get sampleMsgEmergencyResolved;

  /// Sample emergency message note
  ///
  /// In en, this message translates to:
  /// **' Emergency staging area'**
  String get sampleMsgEmergencyStagingArea;

  /// Sample emergency message
  ///
  /// In en, this message translates to:
  /// **'Emergency services notified and responding'**
  String get sampleMsgEmergencyServices;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Team Lead'**
  String get sampleAlphaTeamLead;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Scout'**
  String get sampleBravoScout;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Medic'**
  String get sampleCharlieMedic;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Navigator'**
  String get sampleDeltaNavigator;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sampleEchoSupport;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Base Command'**
  String get sampleBaseCommand;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Field Coordinator'**
  String get sampleFieldCoordinator;

  /// Sample team name
  ///
  /// In en, this message translates to:
  /// **'Medical Team'**
  String get sampleMedicalTeam;

  /// Label for map drawing messages
  ///
  /// In en, this message translates to:
  /// **'Map Drawing'**
  String get mapDrawing;

  /// Option to navigate to drawing on map
  ///
  /// In en, this message translates to:
  /// **'Navigate to Drawing'**
  String get navigateToDrawing;

  /// Option to copy coordinates to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy Coordinates'**
  String get copyCoordinates;

  /// Option to hide drawing from map
  ///
  /// In en, this message translates to:
  /// **'Hide from Map'**
  String get hideFromMap;

  /// Label for line type drawings
  ///
  /// In en, this message translates to:
  /// **'Line Drawing'**
  String get lineDrawing;

  /// Label for rectangle type drawings
  ///
  /// In en, this message translates to:
  /// **'Rectangle Drawing'**
  String get rectangleDrawing;

  /// Label for manual coordinate input toggle
  ///
  /// In en, this message translates to:
  /// **'Manual Coordinates'**
  String get manualCoordinates;

  /// Description for manual coordinate input option
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get enterCoordinatesManually;

  /// Label for latitude input field
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// Label for longitude input field
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// Example coordinate format hint
  ///
  /// In en, this message translates to:
  /// **'Example: 46.0569, 14.5058'**
  String get exampleCoordinates;

  /// Title for share single drawing dialog
  ///
  /// In en, this message translates to:
  /// **'Share Drawing'**
  String get shareDrawing;

  /// Subtitle for public channel sharing option
  ///
  /// In en, this message translates to:
  /// **'Share with all nearby devices'**
  String get shareWithAllNearbyDevices;

  /// Header for room sharing section
  ///
  /// In en, this message translates to:
  /// **'Share to Room'**
  String get shareToRoom;

  /// Subtitle for room sharing option
  ///
  /// In en, this message translates to:
  /// **'Send to persistent room storage'**
  String get sendToPersistentStorage;

  /// Confirmation message for deleting a single drawing
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this drawing?'**
  String get deleteDrawingConfirm;

  /// Success message after deleting a drawing
  ///
  /// In en, this message translates to:
  /// **'Drawing deleted'**
  String get drawingDeleted;

  /// Header showing count of user's drawings
  ///
  /// In en, this message translates to:
  /// **'Your Drawings ({count})'**
  String yourDrawingsCount(int count);

  /// Status label for shared drawings
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// Line drawing type label
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// Rectangle drawing type label
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// Title for update dialog when new version is available
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// Label for current app version
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentVersion;

  /// Label for latest available app version
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestVersion;

  /// Button to download app update
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadUpdate;

  /// Button to dismiss update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// Label for cadastral parcels WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Cadastral Parcels'**
  String get cadastralParcels;

  /// Label for forest roads WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Forest Roads'**
  String get forestRoads;

  /// Section header for WMS overlay layers in layer selector
  ///
  /// In en, this message translates to:
  /// **'WMS Overlays'**
  String get wmsOverlays;

  /// Label for hiking/mountain trails WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Hiking Trails'**
  String get hikingTrails;

  /// Label for main roads WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Main Roads'**
  String get mainRoads;

  /// Label for house numbers WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'House Numbers'**
  String get houseNumbers;

  /// Label for fire hazard risk zones WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Fire Hazard Zones'**
  String get fireHazardZones;

  /// Label for historical forest fires WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Historical Fires'**
  String get historicalFires;

  /// Label for firebreaks WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Firebreaks'**
  String get firebreaks;

  /// Label for Kras fire zones WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Kras Fire Zones'**
  String get krasFireZones;

  /// Label for geographic place names WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Place Names'**
  String get placeNames;

  /// Label for municipality borders WMS overlay layer
  ///
  /// In en, this message translates to:
  /// **'Municipality Borders'**
  String get municipalityBorders;

  /// Label for DTK25 topographic base map layer
  ///
  /// In en, this message translates to:
  /// **'Topographic Map 1:25000'**
  String get topographicMap;

  /// Header for recent messages overlay on map in fullscreen mode
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get recentMessages;

  /// Button to add a new channel
  ///
  /// In en, this message translates to:
  /// **'Add Channel'**
  String get addChannel;

  /// Label for channel name field
  ///
  /// In en, this message translates to:
  /// **'Channel Name'**
  String get channelName;

  /// Hint for channel name field
  ///
  /// In en, this message translates to:
  /// **'e.g., Rescue Team Alpha'**
  String get channelNameHint;

  /// Label for channel secret field
  ///
  /// In en, this message translates to:
  /// **'Channel Secret'**
  String get channelSecret;

  /// Hint for channel secret field
  ///
  /// In en, this message translates to:
  /// **'Shared password for this channel'**
  String get channelSecretHint;

  /// Help text explaining channel secret
  ///
  /// In en, this message translates to:
  /// **'This secret must be shared with all team members who need access to this channel'**
  String get channelSecretHelp;

  /// Information banner explaining hash and private channel types
  ///
  /// In en, this message translates to:
  /// **'Hash channels (#team): Secret auto-generated from name. Same name = same channel across devices.\n\nPrivate channels: Use explicit secret. Only those with the secret can join.'**
  String get channelTypesInfo;

  /// Help text for hash channels (# prefix)
  ///
  /// In en, this message translates to:
  /// **'Hash channel: Secret will be auto-generated from the channel name. Anyone using the same name will join the same channel.'**
  String get hashChannelInfo;

  /// Validation error for empty channel name
  ///
  /// In en, this message translates to:
  /// **'Channel name is required'**
  String get channelNameRequired;

  /// Validation error for channel name too long
  ///
  /// In en, this message translates to:
  /// **'Channel name must be 31 characters or less'**
  String get channelNameTooLong;

  /// Validation error for empty channel secret
  ///
  /// In en, this message translates to:
  /// **'Channel secret is required'**
  String get channelSecretRequired;

  /// Validation error for channel secret too long
  ///
  /// In en, this message translates to:
  /// **'Channel secret must be 32 characters or less'**
  String get channelSecretTooLong;

  /// Validation error for non-ASCII characters
  ///
  /// In en, this message translates to:
  /// **'Only ASCII characters are allowed'**
  String get invalidAsciiCharacters;

  /// Success message after creating channel
  ///
  /// In en, this message translates to:
  /// **'Channel created successfully'**
  String get channelCreatedSuccessfully;

  /// Error message when channel creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create channel: {error}'**
  String channelCreationFailed(String error);

  /// Delete channel button/menu item
  ///
  /// In en, this message translates to:
  /// **'Delete Channel'**
  String get deleteChannel;

  /// Confirmation dialog when deleting a channel
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete channel \"{channelName}\"? This action cannot be undone.'**
  String deleteChannelConfirmation(String channelName);

  /// Success message after deleting channel
  ///
  /// In en, this message translates to:
  /// **'Channel deleted successfully'**
  String get channelDeletedSuccessfully;

  /// Error message when channel deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete channel: {error}'**
  String channelDeletionFailed(String error);

  /// Button text for creating a channel
  ///
  /// In en, this message translates to:
  /// **'Create Channel'**
  String get createChannel;

  /// Wizard back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wizardBack;

  /// Wizard skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get wizardSkip;

  /// Wizard next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get wizardNext;

  /// Wizard final button text to complete onboarding
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get wizardGetStarted;

  /// Welcome wizard first page title
  ///
  /// In en, this message translates to:
  /// **'Welcome to MeshCore SAR'**
  String get wizardWelcomeTitle;

  /// Settings option to re-show welcome wizard
  ///
  /// In en, this message translates to:
  /// **'View Welcome Tutorial'**
  String get viewWelcomeTutorial;

  /// Destination option to send SAR marker to all team contacts
  ///
  /// In en, this message translates to:
  /// **'All Team Contacts'**
  String get allTeamContacts;

  /// Information about sending to all contacts
  ///
  /// In en, this message translates to:
  /// **'Direct messages with ACKs. Sent to {count} team members.'**
  String directMessagesInfo(int count);

  /// Success message after sending SAR marker to all contacts
  ///
  /// In en, this message translates to:
  /// **'SAR marker sent to {count} contacts'**
  String sarMarkerSentToContacts(int count);

  /// Message when there are no chat contacts to send to
  ///
  /// In en, this message translates to:
  /// **'No team contacts available'**
  String get noContactsAvailable;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get technicalDetails;

  /// No description provided for @messageTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Message details'**
  String get messageTechnicalDetails;

  /// No description provided for @linkQuality.
  ///
  /// In en, this message translates to:
  /// **'Link quality'**
  String get linkQuality;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @expectedAckTag.
  ///
  /// In en, this message translates to:
  /// **'Expected ACK tag'**
  String get expectedAckTag;

  /// No description provided for @roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round-trip'**
  String get roundTrip;

  /// No description provided for @retryAttempt.
  ///
  /// In en, this message translates to:
  /// **'Retry attempt'**
  String get retryAttempt;

  /// No description provided for @floodFallback.
  ///
  /// In en, this message translates to:
  /// **'Flood fallback'**
  String get floodFallback;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @messageId.
  ///
  /// In en, this message translates to:
  /// **'Message ID'**
  String get messageId;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @senderKey.
  ///
  /// In en, this message translates to:
  /// **'Sender key'**
  String get senderKey;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @recipientKey.
  ///
  /// In en, this message translates to:
  /// **'Recipient key'**
  String get recipientKey;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @voiceId.
  ///
  /// In en, this message translates to:
  /// **'Voice ID'**
  String get voiceId;

  /// No description provided for @envelope.
  ///
  /// In en, this message translates to:
  /// **'Envelope'**
  String get envelope;

  /// No description provided for @sessionProgress.
  ///
  /// In en, this message translates to:
  /// **'Session progress'**
  String get sessionProgress;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @rawDump.
  ///
  /// In en, this message translates to:
  /// **'Raw dump'**
  String get rawDump;

  /// No description provided for @cannotRetryMissingRecipient.
  ///
  /// In en, this message translates to:
  /// **'Cannot retry: recipient information missing'**
  String get cannotRetryMissingRecipient;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice unavailable right now'**
  String get voiceUnavailable;

  /// No description provided for @requestingVoice.
  ///
  /// In en, this message translates to:
  /// **'Requesting voice'**
  String get requestingVoice;

  /// Generic device label
  ///
  /// In en, this message translates to:
  /// **'device'**
  String get device;

  /// Generic change action
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Updated onboarding overview description
  ///
  /// In en, this message translates to:
  /// **'This app combines MeshCore messaging, SAR field updates, discovery, mapping, and device tools in one place.'**
  String get wizardOverviewDescription;

  /// Updated onboarding overview feature 1
  ///
  /// In en, this message translates to:
  /// **'Send direct, room, and channel messages from the main Messages tab.'**
  String get wizardOverviewFeature1;

  /// Updated onboarding overview feature 2
  ///
  /// In en, this message translates to:
  /// **'Share live location to a private channel, plus SAR markers, map drawings, voice clips, and images over the mesh.'**
  String get wizardOverviewFeature2;

  /// Updated onboarding overview feature 3
  ///
  /// In en, this message translates to:
  /// **'Connect over BLE, WiFi, or Serial, then manage the companion radio from inside the app.'**
  String get wizardOverviewFeature3;

  /// Updated onboarding messaging page title
  ///
  /// In en, this message translates to:
  /// **'Messaging and Field Reports'**
  String get wizardMessagingTitle;

  /// Updated onboarding messaging page description
  ///
  /// In en, this message translates to:
  /// **'Messages are more than plain text here. The app already supports several operational payloads and transfer workflows.'**
  String get wizardMessagingDescription;

  /// Updated onboarding messaging feature 1
  ///
  /// In en, this message translates to:
  /// **'Send direct messages, room posts, and channel traffic from one composer.'**
  String get wizardMessagingFeature1;

  /// Updated onboarding messaging feature 2
  ///
  /// In en, this message translates to:
  /// **'Create SAR updates and reusable SAR templates for common field reports.'**
  String get wizardMessagingFeature2;

  /// Updated onboarding messaging feature 3
  ///
  /// In en, this message translates to:
  /// **'Transfer voice sessions and images, with progress and airtime estimates in the UI.'**
  String get wizardMessagingFeature3;

  /// Onboarding connect device page title
  ///
  /// In en, this message translates to:
  /// **'Connect device'**
  String get wizardConnectDeviceTitle;

  /// Onboarding connect device page description
  ///
  /// In en, this message translates to:
  /// **'Connect your MeshCore radio, choose a name, and apply a radio preset before continuing.'**
  String get wizardConnectDeviceDescription;

  /// Onboarding setup badge label
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get wizardSetupBadge;

  /// Onboarding overview badge label
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get wizardOverviewBadge;

  /// Onboarding connection status when connected
  ///
  /// In en, this message translates to:
  /// **'Connected to {deviceName}'**
  String wizardConnectedToDevice(String deviceName);

  /// Onboarding connection status when disconnected
  ///
  /// In en, this message translates to:
  /// **'No device connected yet'**
  String get wizardNoDeviceConnected;

  /// Onboarding skip current setup step action
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get wizardSkipForNow;

  /// Onboarding device name field label
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get wizardDeviceNameLabel;

  /// Onboarding device name field helper text
  ///
  /// In en, this message translates to:
  /// **'This name is advertised to other MeshCore users.'**
  String get wizardDeviceNameHelp;

  /// Onboarding config region field label
  ///
  /// In en, this message translates to:
  /// **'Config region'**
  String get wizardConfigRegionLabel;

  /// Onboarding config region helper text
  ///
  /// In en, this message translates to:
  /// **'Uses the full official MeshCore preset list. Default is EU/UK (Narrow).'**
  String get wizardConfigRegionHelp;

  /// Onboarding preset note 1
  ///
  /// In en, this message translates to:
  /// **'Make sure the selected preset matches your local radio regulations.'**
  String get wizardPresetNote1;

  /// Onboarding preset note 2
  ///
  /// In en, this message translates to:
  /// **'The list matches the official MeshCore config tool preset feed.'**
  String get wizardPresetNote2;

  /// Onboarding preset note 3
  ///
  /// In en, this message translates to:
  /// **'EU/UK (Narrow) stays selected by default for onboarding.'**
  String get wizardPresetNote3;

  /// Onboarding saving button label
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get wizardSaving;

  /// Onboarding save and continue button label
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get wizardSaveAndContinue;

  /// Onboarding validation when device name is missing
  ///
  /// In en, this message translates to:
  /// **'Enter a device name before continuing.'**
  String get wizardEnterDeviceName;

  /// Onboarding success message after saving device setup
  ///
  /// In en, this message translates to:
  /// **'Saved {deviceName} with {presetName}.'**
  String wizardDeviceSetupSaved(String deviceName, String presetName);

  /// Updated onboarding network page title
  ///
  /// In en, this message translates to:
  /// **'Contacts, Rooms, and Repeaters'**
  String get wizardNetworkTitle;

  /// Updated onboarding network page description
  ///
  /// In en, this message translates to:
  /// **'The Contacts and Discovery flows help you find nearby nodes, store repeaters, and manage the routes you learn over time.'**
  String get wizardNetworkDescription;

  /// Updated onboarding network feature 1
  ///
  /// In en, this message translates to:
  /// **'Discover repeaters and sensors, then review team members, rooms, channels, and pending adverts in one list.'**
  String get wizardNetworkFeature1;

  /// Updated onboarding network feature 2
  ///
  /// In en, this message translates to:
  /// **'Use smart ping, room login, learned paths, and route reset tools when connectivity gets messy.'**
  String get wizardNetworkFeature2;

  /// Updated onboarding network feature 3
  ///
  /// In en, this message translates to:
  /// **'Add new repeaters right after you connect, then create channels and manage network destinations without leaving the app.'**
  String get wizardNetworkFeature3;

  /// Updated onboarding map page title
  ///
  /// In en, this message translates to:
  /// **'Map, Trails, and Shared Geometry'**
  String get wizardMapOpsTitle;

  /// Updated onboarding map page description
  ///
  /// In en, this message translates to:
  /// **'The app map is tied directly into messaging, tracking, and SAR overlays instead of being a separate viewer.'**
  String get wizardMapOpsDescription;

  /// Updated onboarding map feature 1
  ///
  /// In en, this message translates to:
  /// **'Track your own position, teammate locations, and share live location to a private channel from the channel menu.'**
  String get wizardMapOpsFeature1;

  /// Updated onboarding map feature 2
  ///
  /// In en, this message translates to:
  /// **'Open drawings from messages, preview them inline, and remove them from the map when needed.'**
  String get wizardMapOpsFeature2;

  /// Updated onboarding map feature 3
  ///
  /// In en, this message translates to:
  /// **'Use repeater map views and shared overlays to understand network reach in the field.'**
  String get wizardMapOpsFeature3;

  /// Updated onboarding tools page title
  ///
  /// In en, this message translates to:
  /// **'Tools Beyond Messaging'**
  String get wizardToolsTitle;

  /// Updated onboarding tools page description
  ///
  /// In en, this message translates to:
  /// **'There is more here than the four main tabs. The app also includes configuration, diagnostics, and optional sensor workflows.'**
  String get wizardToolsDescription;

  /// Updated onboarding tools feature 1
  ///
  /// In en, this message translates to:
  /// **'Open device config to change radio settings, telemetry, TX power, and companion details.'**
  String get wizardToolsFeature1;

  /// Updated onboarding tools feature 2
  ///
  /// In en, this message translates to:
  /// **'Enable the Sensors tab when you want watched sensor dashboards and quick refresh actions.'**
  String get wizardToolsFeature2;

  /// Updated onboarding tools feature 3
  ///
  /// In en, this message translates to:
  /// **'Use live traffic, packet logs, spectrum scan, and developer diagnostics when troubleshooting the mesh.'**
  String get wizardToolsFeature3;

  /// Title for the prompt shown after a successful device connection
  ///
  /// In en, this message translates to:
  /// **'Discover repeaters now?'**
  String get postConnectDiscoveryTitle;

  /// Body text for the prompt shown after a successful device connection
  ///
  /// In en, this message translates to:
  /// **'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.'**
  String get postConnectDiscoveryDescription;

  /// Contact actions label when already in sensors
  ///
  /// In en, this message translates to:
  /// **'In Sensors'**
  String get contactInSensors;

  /// Contact actions label to add to sensors
  ///
  /// In en, this message translates to:
  /// **'Add to Sensors'**
  String get contactAddToSensors;

  /// Contact actions label to set route path
  ///
  /// In en, this message translates to:
  /// **'Set path'**
  String get contactSetPath;

  /// Snackbar after adding contact to sensors
  ///
  /// In en, this message translates to:
  /// **'{contactName} added to Sensors'**
  String contactAddedToSensors(String contactName);

  /// Error when clearing a contact route fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear route: {error}'**
  String contactFailedToClearRoute(String error);

  /// Snackbar after route is cleared
  ///
  /// In en, this message translates to:
  /// **'Route cleared'**
  String get contactRouteCleared;

  /// Snackbar after route is set
  ///
  /// In en, this message translates to:
  /// **'Route set: {route}'**
  String contactRouteSet(String route);

  /// Error when setting a contact route fails
  ///
  /// In en, this message translates to:
  /// **'Failed to set route: {error}'**
  String contactFailedToSetRoute(String error);

  /// Received signal strength indicator
  ///
  /// In en, this message translates to:
  /// **'RSSI'**
  String get rssi;

  /// Signal-to-noise ratio
  ///
  /// In en, this message translates to:
  /// **'SNR'**
  String get snr;

  /// No description provided for @ackTimeout.
  ///
  /// In en, this message translates to:
  /// **'ACK timeout'**
  String get ackTimeout;

  /// No description provided for @opcode.
  ///
  /// In en, this message translates to:
  /// **'Opcode'**
  String get opcode;

  /// No description provided for @payload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get payload;

  /// No description provided for @hops.
  ///
  /// In en, this message translates to:
  /// **'Hops'**
  String get hops;

  /// No description provided for @hashSize.
  ///
  /// In en, this message translates to:
  /// **'Hash size'**
  String get hashSize;

  /// No description provided for @pathBytes.
  ///
  /// In en, this message translates to:
  /// **'Path bytes'**
  String get pathBytes;

  /// No description provided for @selectedPath.
  ///
  /// In en, this message translates to:
  /// **'Selected path'**
  String get selectedPath;

  /// No description provided for @estimatedTx.
  ///
  /// In en, this message translates to:
  /// **'Estimated tx'**
  String get estimatedTx;

  /// No description provided for @senderToReceipt.
  ///
  /// In en, this message translates to:
  /// **'Sender to receipt'**
  String get senderToReceipt;

  /// No description provided for @receivedCopies.
  ///
  /// In en, this message translates to:
  /// **'Received copies'**
  String get receivedCopies;

  /// No description provided for @retryCause.
  ///
  /// In en, this message translates to:
  /// **'Retry cause'**
  String get retryCause;

  /// No description provided for @retryMode.
  ///
  /// In en, this message translates to:
  /// **'Retry mode'**
  String get retryMode;

  /// No description provided for @retryResult.
  ///
  /// In en, this message translates to:
  /// **'Retry result'**
  String get retryResult;

  /// No description provided for @lastRetry.
  ///
  /// In en, this message translates to:
  /// **'Last retry'**
  String get lastRetry;

  /// No description provided for @rxPackets.
  ///
  /// In en, this message translates to:
  /// **'RX packets'**
  String get rxPackets;

  /// No description provided for @mesh.
  ///
  /// In en, this message translates to:
  /// **'Mesh'**
  String get mesh;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @posttxDelay.
  ///
  /// In en, this message translates to:
  /// **'Post-tx delay'**
  String get posttxDelay;

  /// No description provided for @bandpass.
  ///
  /// In en, this message translates to:
  /// **'Band-pass'**
  String get bandpass;

  /// No description provided for @bandpassFilterVoice.
  ///
  /// In en, this message translates to:
  /// **'Band-pass filter voice'**
  String get bandpassFilterVoice;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clearAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllLabel;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @clearRoute.
  ///
  /// In en, this message translates to:
  /// **'Clear Route'**
  String get clearRoute;

  /// No description provided for @clearMessages.
  ///
  /// In en, this message translates to:
  /// **'Clear Messages'**
  String get clearMessages;

  /// No description provided for @clearScale.
  ///
  /// In en, this message translates to:
  /// **'Clear scale'**
  String get clearScale;

  /// No description provided for @clearDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'Clear discoveries'**
  String get clearDiscoveries;

  /// No description provided for @clearOnlineTraceDatabase.
  ///
  /// In en, this message translates to:
  /// **'Clear online trace database'**
  String get clearOnlineTraceDatabase;

  /// No description provided for @clearAllChannels.
  ///
  /// In en, this message translates to:
  /// **'Clear all channels'**
  String get clearAllChannels;

  /// No description provided for @clearAllContacts.
  ///
  /// In en, this message translates to:
  /// **'Clear all contacts'**
  String get clearAllContacts;

  /// No description provided for @clearChannels.
  ///
  /// In en, this message translates to:
  /// **'Clear channels'**
  String get clearChannels;

  /// No description provided for @clearContacts.
  ///
  /// In en, this message translates to:
  /// **'Clear contacts'**
  String get clearContacts;

  /// No description provided for @clearPathOnMaxRetry.
  ///
  /// In en, this message translates to:
  /// **'Clear path on max retry'**
  String get clearPathOnMaxRetry;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @defaultValue.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultValue;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @resolveAll.
  ///
  /// In en, this message translates to:
  /// **'Resolve all'**
  String get resolveAll;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendAnyway.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get sendAnyway;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @trace.
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get trace;

  /// No description provided for @discovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discovery;

  /// No description provided for @discoverRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Discover repeaters'**
  String get discoverRepeaters;

  /// No description provided for @discoverSensors.
  ///
  /// In en, this message translates to:
  /// **'Discover sensors'**
  String get discoverSensors;

  /// No description provided for @repeaterDiscoverySent.
  ///
  /// In en, this message translates to:
  /// **'Repeater discovery sent'**
  String get repeaterDiscoverySent;

  /// No description provided for @sensorDiscoverySent.
  ///
  /// In en, this message translates to:
  /// **'Sensor discovery sent'**
  String get sensorDiscoverySent;

  /// No description provided for @clearedPendingDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'Cleared pending discoveries.'**
  String get clearedPendingDiscoveries;

  /// No description provided for @autoDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Auto discovery'**
  String get autoDiscovery;

  /// No description provided for @enableAutomaticAdding.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic adding'**
  String get enableAutomaticAdding;

  /// No description provided for @autoaddRepeaters.
  ///
  /// In en, this message translates to:
  /// **'Auto-add repeaters'**
  String get autoaddRepeaters;

  /// No description provided for @autoaddRoomServers.
  ///
  /// In en, this message translates to:
  /// **'Auto-add room servers'**
  String get autoaddRoomServers;

  /// No description provided for @autoaddSensors.
  ///
  /// In en, this message translates to:
  /// **'Auto-add sensors'**
  String get autoaddSensors;

  /// No description provided for @autoaddUsers.
  ///
  /// In en, this message translates to:
  /// **'Auto-add users'**
  String get autoaddUsers;

  /// No description provided for @overwriteOldestWhenFull.
  ///
  /// In en, this message translates to:
  /// **'Overwrite oldest when full'**
  String get overwriteOldestWhenFull;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensors;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @gpsModule.
  ///
  /// In en, this message translates to:
  /// **'GPS Module'**
  String get gpsModule;

  /// No description provided for @liveTraffic.
  ///
  /// In en, this message translates to:
  /// **'Live Traffic'**
  String get liveTraffic;

  /// No description provided for @repeatersMap.
  ///
  /// In en, this message translates to:
  /// **'Repeaters Map'**
  String get repeatersMap;

  /// No description provided for @blePacketLogs.
  ///
  /// In en, this message translates to:
  /// **'BLE Packet Logs'**
  String get blePacketLogs;

  /// No description provided for @onlineTraceDatabase.
  ///
  /// In en, this message translates to:
  /// **'Online trace database'**
  String get onlineTraceDatabase;

  /// No description provided for @routePathByteSize.
  ///
  /// In en, this message translates to:
  /// **'Route path byte size'**
  String get routePathByteSize;

  /// No description provided for @messageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Message notifications'**
  String get messageNotifications;

  /// No description provided for @sarAlerts.
  ///
  /// In en, this message translates to:
  /// **'SAR alerts'**
  String get sarAlerts;

  /// No description provided for @discoveryNotifications.
  ///
  /// In en, this message translates to:
  /// **'Discovery notifications'**
  String get discoveryNotifications;

  /// No description provided for @updateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Update notifications'**
  String get updateNotifications;

  /// No description provided for @muteWhileAppIsOpen.
  ///
  /// In en, this message translates to:
  /// **'Mute while app is open'**
  String get muteWhileAppIsOpen;

  /// No description provided for @disableContacts.
  ///
  /// In en, this message translates to:
  /// **'Disable Contacts'**
  String get disableContacts;

  /// No description provided for @enableSensorsTab.
  ///
  /// In en, this message translates to:
  /// **'Enable Sensors tab'**
  String get enableSensorsTab;

  /// No description provided for @enableProfiles.
  ///
  /// In en, this message translates to:
  /// **'Enable Profiles'**
  String get enableProfiles;

  /// No description provided for @nearestRepeaterFallback.
  ///
  /// In en, this message translates to:
  /// **'Nearest repeater fallback'**
  String get nearestRepeaterFallback;

  /// No description provided for @deleteAllStoredMessageHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete all stored message history'**
  String get deleteAllStoredMessageHistory;

  /// No description provided for @messageFontSize.
  ///
  /// In en, this message translates to:
  /// **'Message font size'**
  String get messageFontSize;

  /// No description provided for @rotateMapWithHeading.
  ///
  /// In en, this message translates to:
  /// **'Rotate map with heading'**
  String get rotateMapWithHeading;

  /// No description provided for @showMapDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'Show map debug info'**
  String get showMapDebugInfo;

  /// No description provided for @openMapInFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Open map in fullscreen'**
  String get openMapInFullscreen;

  /// No description provided for @showSarMarkersLabel.
  ///
  /// In en, this message translates to:
  /// **'Show SAR markers'**
  String get showSarMarkersLabel;

  /// No description provided for @hideRepeatersOnMap.
  ///
  /// In en, this message translates to:
  /// **'Hide repeaters on map'**
  String get hideRepeatersOnMap;

  /// No description provided for @setMapScale.
  ///
  /// In en, this message translates to:
  /// **'Set map scale'**
  String get setMapScale;

  /// No description provided for @customMapScaleSaved.
  ///
  /// In en, this message translates to:
  /// **'Custom map scale saved'**
  String get customMapScaleSaved;

  /// No description provided for @voiceBitrate.
  ///
  /// In en, this message translates to:
  /// **'Voice bitrate'**
  String get voiceBitrate;

  /// No description provided for @voiceCompressor.
  ///
  /// In en, this message translates to:
  /// **'Voice compressor'**
  String get voiceCompressor;

  /// No description provided for @voiceLimiter.
  ///
  /// In en, this message translates to:
  /// **'Voice limiter'**
  String get voiceLimiter;

  /// No description provided for @micAutoGain.
  ///
  /// In en, this message translates to:
  /// **'Mic auto gain'**
  String get micAutoGain;

  /// No description provided for @echoCancellation.
  ///
  /// In en, this message translates to:
  /// **'Echo cancellation'**
  String get echoCancellation;

  /// No description provided for @noiseSuppression.
  ///
  /// In en, this message translates to:
  /// **'Noise suppression'**
  String get noiseSuppression;

  /// No description provided for @trimSilenceInVoiceMessages.
  ///
  /// In en, this message translates to:
  /// **'Trim silence in voice messages'**
  String get trimSilenceInVoiceMessages;

  /// No description provided for @compressor.
  ///
  /// In en, this message translates to:
  /// **'Compressor'**
  String get compressor;

  /// No description provided for @limiter.
  ///
  /// In en, this message translates to:
  /// **'Limiter'**
  String get limiter;

  /// No description provided for @autoGain.
  ///
  /// In en, this message translates to:
  /// **'Auto gain'**
  String get autoGain;

  /// No description provided for @echoCancel.
  ///
  /// In en, this message translates to:
  /// **'Echo cancel'**
  String get echoCancel;

  /// No description provided for @noiseSuppress.
  ///
  /// In en, this message translates to:
  /// **'Noise suppress'**
  String get noiseSuppress;

  /// No description provided for @silenceTrim.
  ///
  /// In en, this message translates to:
  /// **'Silence trim'**
  String get silenceTrim;

  /// No description provided for @maxImageSize.
  ///
  /// In en, this message translates to:
  /// **'Max image size'**
  String get maxImageSize;

  /// No description provided for @imageCompression.
  ///
  /// In en, this message translates to:
  /// **'Image compression'**
  String get imageCompression;

  /// No description provided for @grayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get grayscale;

  /// No description provided for @ultraMode.
  ///
  /// In en, this message translates to:
  /// **'Ultra mode'**
  String get ultraMode;

  /// No description provided for @fastPrivateGpsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Fast private GPS updates'**
  String get fastPrivateGpsUpdates;

  /// No description provided for @movementThreshold.
  ///
  /// In en, this message translates to:
  /// **'Movement threshold'**
  String get movementThreshold;

  /// No description provided for @fastGpsMovementThreshold.
  ///
  /// In en, this message translates to:
  /// **'Fast GPS movement threshold'**
  String get fastGpsMovementThreshold;

  /// No description provided for @fastGpsActiveuseInterval.
  ///
  /// In en, this message translates to:
  /// **'Fast GPS active-use interval'**
  String get fastGpsActiveuseInterval;

  /// No description provided for @activeuseUpdateInterval.
  ///
  /// In en, this message translates to:
  /// **'Active-use update interval'**
  String get activeuseUpdateInterval;

  /// No description provided for @repeatNearbyTraffic.
  ///
  /// In en, this message translates to:
  /// **'Repeat nearby traffic'**
  String get repeatNearbyTraffic;

  /// No description provided for @relayThroughRepeatersAcrossTheMesh.
  ///
  /// In en, this message translates to:
  /// **'Relay through repeaters across the mesh'**
  String get relayThroughRepeatersAcrossTheMesh;

  /// No description provided for @nearbyOnlyWithoutRepeaterFlooding.
  ///
  /// In en, this message translates to:
  /// **'Nearby only, without repeater flooding'**
  String get nearbyOnlyWithoutRepeaterFlooding;

  /// No description provided for @multihop.
  ///
  /// In en, this message translates to:
  /// **'Multi-hop'**
  String get multihop;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @renameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename Profile'**
  String get renameProfile;

  /// No description provided for @newProfile.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get newProfile;

  /// No description provided for @manageProfiles.
  ///
  /// In en, this message translates to:
  /// **'Manage profiles'**
  String get manageProfiles;

  /// No description provided for @enableProfilesToStartManagingThem.
  ///
  /// In en, this message translates to:
  /// **'Enable profiles to start managing them.'**
  String get enableProfilesToStartManagingThem;

  /// No description provided for @openMessage.
  ///
  /// In en, this message translates to:
  /// **'Open message'**
  String get openMessage;

  /// No description provided for @jumpToTheRelatedSarMessage.
  ///
  /// In en, this message translates to:
  /// **'Jump to the related SAR message'**
  String get jumpToTheRelatedSarMessage;

  /// No description provided for @removeSarMarker.
  ///
  /// In en, this message translates to:
  /// **'Remove SAR marker'**
  String get removeSarMarker;

  /// No description provided for @pleaseSelectADestinationToSendSarMarker.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination to send SAR marker'**
  String get pleaseSelectADestinationToSendSarMarker;

  /// No description provided for @sarMarkerBroadcastToPublicChannel.
  ///
  /// In en, this message translates to:
  /// **'SAR marker broadcast to public channel'**
  String get sarMarkerBroadcastToPublicChannel;

  /// No description provided for @sarMarkerSentToRoom.
  ///
  /// In en, this message translates to:
  /// **'SAR marker sent to room'**
  String get sarMarkerSentToRoom;

  /// No description provided for @loadFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Load from gallery'**
  String get loadFromGallery;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get replaceImage;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @staging.
  ///
  /// In en, this message translates to:
  /// **'Staging'**
  String get staging;

  /// No description provided for @object.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get object;

  /// No description provided for @quiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get quiet;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessages;

  /// No description provided for @sendImageFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Send image from gallery'**
  String get sendImageFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @allMessages.
  ///
  /// In en, this message translates to:
  /// **'All messages'**
  String get allMessages;

  /// No description provided for @sendToPublicChannel.
  ///
  /// In en, this message translates to:
  /// **'Send to Public Channel?'**
  String get sendToPublicChannel;

  /// No description provided for @selectMarkerTypeAndDestination.
  ///
  /// In en, this message translates to:
  /// **'Select marker type and destination'**
  String get selectMarkerTypeAndDestination;

  /// No description provided for @noDestinationsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'No destinations available'**
  String get noDestinationsAvailableLabel;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @segments.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get segments;

  /// No description provided for @transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfers;

  /// No description provided for @downloadedBy.
  ///
  /// In en, this message translates to:
  /// **'Downloaded by'**
  String get downloadedBy;

  /// No description provided for @saveDiscoverySettings.
  ///
  /// In en, this message translates to:
  /// **'Save discovery settings'**
  String get saveDiscoverySettings;

  /// No description provided for @savePublicInfo.
  ///
  /// In en, this message translates to:
  /// **'Save public info'**
  String get savePublicInfo;

  /// No description provided for @saveRadioSettings.
  ///
  /// In en, this message translates to:
  /// **'Save radio settings'**
  String get saveRadioSettings;

  /// No description provided for @savePath.
  ///
  /// In en, this message translates to:
  /// **'Save Path'**
  String get savePath;

  /// No description provided for @wipeDeviceData.
  ///
  /// In en, this message translates to:
  /// **'Wipe device data'**
  String get wipeDeviceData;

  /// No description provided for @wipeDevice.
  ///
  /// In en, this message translates to:
  /// **'Wipe device'**
  String get wipeDevice;

  /// No description provided for @destructiveDeviceActions.
  ///
  /// In en, this message translates to:
  /// **'Destructive device actions.'**
  String get destructiveDeviceActions;

  /// No description provided for @chooseAPresetOrFinetuneCustomRadioSettings.
  ///
  /// In en, this message translates to:
  /// **'Choose a preset or fine-tune custom radio settings.'**
  String get chooseAPresetOrFinetuneCustomRadioSettings;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @renameValue.
  ///
  /// In en, this message translates to:
  /// **'Rename value'**
  String get renameValue;

  /// No description provided for @customizeFields.
  ///
  /// In en, this message translates to:
  /// **'Customize fields'**
  String get customizeFields;

  /// No description provided for @livePreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get livePreview;

  /// No description provided for @refreshSchedule.
  ///
  /// In en, this message translates to:
  /// **'Refresh schedule'**
  String get refreshSchedule;

  /// No description provided for @noResponse.
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get noResponse;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get refreshing;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @pickARelayOrNodeToWatchInSensors.
  ///
  /// In en, this message translates to:
  /// **'Pick a relay or node to watch in Sensors.'**
  String get pickARelayOrNodeToWatchInSensors;

  /// No description provided for @publicKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKeyLabel;

  /// No description provided for @alreadyInContacts.
  ///
  /// In en, this message translates to:
  /// **'Already in contacts'**
  String get alreadyInContacts;

  /// No description provided for @connectToADeviceBeforeAddingContacts.
  ///
  /// In en, this message translates to:
  /// **'Connect to a device before adding contacts'**
  String get connectToADeviceBeforeAddingContacts;

  /// No description provided for @fromContacts.
  ///
  /// In en, this message translates to:
  /// **'From contacts'**
  String get fromContacts;

  /// No description provided for @onlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get onlineOnly;

  /// No description provided for @inBoth.
  ///
  /// In en, this message translates to:
  /// **'In both'**
  String get inBoth;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @allMessagesCleared.
  ///
  /// In en, this message translates to:
  /// **'All messages cleared'**
  String get allMessagesCleared;

  /// No description provided for @onlineTraceDatabaseCleared.
  ///
  /// In en, this message translates to:
  /// **'Online trace database cleared'**
  String get onlineTraceDatabaseCleared;

  /// No description provided for @packetLogsCleared.
  ///
  /// In en, this message translates to:
  /// **'Packet logs cleared'**
  String get packetLogsCleared;

  /// No description provided for @hexDataCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Hex data copied to clipboard'**
  String get hexDataCopiedToClipboard;

  /// No description provided for @developerModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Developer mode enabled'**
  String get developerModeEnabled;

  /// No description provided for @developerModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Developer mode disabled'**
  String get developerModeDisabled;

  /// No description provided for @clipboardIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardIsEmpty;

  /// No description provided for @contactImported.
  ///
  /// In en, this message translates to:
  /// **'Contact imported'**
  String get contactImported;

  /// No description provided for @contactLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Contact link copied to clipboard'**
  String get contactLinkCopiedToClipboard;

  /// No description provided for @failedToExportContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to export contact'**
  String get failedToExportContact;

  /// No description provided for @noLogsToExport.
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get noLogsToExport;

  /// No description provided for @exportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// No description provided for @exportAsText.
  ///
  /// In en, this message translates to:
  /// **'Export as Text'**
  String get exportAsText;

  /// No description provided for @receivedRfc3339.
  ///
  /// In en, this message translates to:
  /// **'Received (RFC3339)'**
  String get receivedRfc3339;

  /// No description provided for @buildTime.
  ///
  /// In en, this message translates to:
  /// **'Build Time'**
  String get buildTime;

  /// No description provided for @downloadUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Download URL not available'**
  String get downloadUrlNotAvailable;

  /// No description provided for @cannotOpenDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot open download URL'**
  String get cannotOpenDownloadUrl;

  /// No description provided for @updateCheckIsOnlyAvailableOnAndroid.
  ///
  /// In en, this message translates to:
  /// **'Update check is only available on Android'**
  String get updateCheckIsOnlyAvailableOnAndroid;

  /// No description provided for @youAreRunningTheLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You are running the latest version'**
  String get youAreRunningTheLatestVersion;

  /// No description provided for @updateAvailableButDownloadUrlNotFound.
  ///
  /// In en, this message translates to:
  /// **'Update available but download URL not found'**
  String get updateAvailableButDownloadUrlNotFound;

  /// No description provided for @startTictactoe.
  ///
  /// In en, this message translates to:
  /// **'Start Tic-Tac-Toe'**
  String get startTictactoe;

  /// No description provided for @tictactoeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tic-Tac-Toe unavailable'**
  String get tictactoeUnavailable;

  /// No description provided for @tictactoeOpponentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Tic-Tac-Toe: opponent unknown'**
  String get tictactoeOpponentUnknown;

  /// No description provided for @tictactoeWaitingForStart.
  ///
  /// In en, this message translates to:
  /// **'Tic-Tac-Toe: waiting for start'**
  String get tictactoeWaitingForStart;

  /// No description provided for @acceptsShareLinks.
  ///
  /// In en, this message translates to:
  /// **'Accepts share links'**
  String get acceptsShareLinks;

  /// No description provided for @supportsRawHex.
  ///
  /// In en, this message translates to:
  /// **'Supports raw hex'**
  String get supportsRawHex;

  /// No description provided for @clipboardfriendly.
  ///
  /// In en, this message translates to:
  /// **'Clipboard-friendly'**
  String get clipboardfriendly;

  /// No description provided for @captured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get captured;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @noCustomChannelsToClear.
  ///
  /// In en, this message translates to:
  /// **'No custom channels to clear.'**
  String get noCustomChannelsToClear;

  /// No description provided for @noDeviceContactsToClear.
  ///
  /// In en, this message translates to:
  /// **'No device contacts to clear.'**
  String get noDeviceContactsToClear;

  /// No description provided for @aToZ.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get aToZ;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Add additional details'**
  String get addAdditionalDetails;

  /// No description provided for @addPeer.
  ///
  /// In en, this message translates to:
  /// **'Add Peer'**
  String get addPeer;

  /// No description provided for @addPeerManually.
  ///
  /// In en, this message translates to:
  /// **'Add peer manually'**
  String get addPeerManually;

  /// No description provided for @addedToContacts.
  ///
  /// In en, this message translates to:
  /// **'{name} added to contacts'**
  String addedToContacts(String name);

  /// No description provided for @addedToSensors.
  ///
  /// In en, this message translates to:
  /// **'{name} added to Sensors'**
  String addedToSensors(String name);

  /// No description provided for @allowAll.
  ///
  /// In en, this message translates to:
  /// **'Allow all'**
  String get allowAll;

  /// No description provided for @anonymousRxStats.
  ///
  /// In en, this message translates to:
  /// **'Anonymous RX stats'**
  String get anonymousRxStats;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @ascii.
  ///
  /// In en, this message translates to:
  /// **'ASCII'**
  String get ascii;

  /// No description provided for @baseTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Base telemetry'**
  String get baseTelemetry;

  /// No description provided for @blePin.
  ///
  /// In en, this message translates to:
  /// **'BLE PIN'**
  String get blePin;

  /// No description provided for @buzzerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Buzzer alerts'**
  String get buzzerAlerts;

  /// No description provided for @cancelImageReceive.
  ///
  /// In en, this message translates to:
  /// **'Cancel image receive'**
  String get cancelImageReceive;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @chooseWhichTabsAndContactSectionsToShow.
  ///
  /// In en, this message translates to:
  /// **'Choose which tabs and contact sections to show'**
  String get chooseWhichTabsAndContactSectionsToShow;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearLiveView.
  ///
  /// In en, this message translates to:
  /// **'Clear live view'**
  String get clearLiveView;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @clearOfflineCache.
  ///
  /// In en, this message translates to:
  /// **'Clear offline cache?'**
  String get clearOfflineCache;

  /// No description provided for @clearOverlay.
  ///
  /// In en, this message translates to:
  /// **'Clear overlay'**
  String get clearOverlay;

  /// No description provided for @clearRouteOnlyAfterAllRetriesFail.
  ///
  /// In en, this message translates to:
  /// **'Clear route only after all retries fail'**
  String get clearRouteOnlyAfterAllRetriesFail;

  /// No description provided for @codecBitrateAndAudioProcessing.
  ///
  /// In en, this message translates to:
  /// **'Codec, bitrate, and audio processing'**
  String get codecBitrateAndAudioProcessing;

  /// No description provided for @connectByIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Connect by IP address'**
  String get connectByIpAddress;

  /// No description provided for @controlWhichAlertsYouReceive.
  ///
  /// In en, this message translates to:
  /// **'Control which alerts you receive'**
  String get controlWhichAlertsYouReceive;

  /// No description provided for @copyFullHex.
  ///
  /// In en, this message translates to:
  /// **'Copy full hex'**
  String get copyFullHex;

  /// No description provided for @copyRawResponse.
  ///
  /// In en, this message translates to:
  /// **'Copy raw response'**
  String get copyRawResponse;

  /// No description provided for @couldNotLoadMetHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load MET history'**
  String get couldNotLoadMetHistory;

  /// No description provided for @customizeSensor.
  ///
  /// In en, this message translates to:
  /// **'Customize {name}'**
  String customizeSensor(String name);

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteStyleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteStyleConfirm(String name);

  /// No description provided for @deleteThisDrawing.
  ///
  /// In en, this message translates to:
  /// **'Delete this {type}?'**
  String deleteThisDrawing(String type);

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfo;

  /// No description provided for @deviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get deviceSettings;

  /// No description provided for @deviceTimeSynced.
  ///
  /// In en, this message translates to:
  /// **'Device time synced to this phone.'**
  String get deviceTimeSynced;

  /// No description provided for @disableFastGpsPublishing.
  ///
  /// In en, this message translates to:
  /// **'Disable fast GPS publishing'**
  String get disableFastGpsPublishing;

  /// No description provided for @displayMarkersAndTraceDatabase.
  ///
  /// In en, this message translates to:
  /// **'Display, markers, and trace database'**
  String get displayMarkersAndTraceDatabase;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @environmentalTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Environmental telemetry'**
  String get environmentalTelemetry;

  /// No description provided for @errorCheckingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Error checking for updates: {error}'**
  String errorCheckingForUpdates(String error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @errorOpeningDownload.
  ///
  /// In en, this message translates to:
  /// **'Error opening download: {error}'**
  String errorOpeningDownload(String error);

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogs;

  /// No description provided for @extraAggressiveAvifCompression.
  ///
  /// In en, this message translates to:
  /// **'Extra-aggressive AVIF compression'**
  String get extraAggressiveAvifCompression;

  /// No description provided for @failedToAddContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to add contact: {error}'**
  String failedToAddContact(String error);

  /// No description provided for @failedToAddName.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {name}: {error}'**
  String failedToAddName(String name, String error);

  /// No description provided for @failedToClearChannels.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear channels: {error}'**
  String failedToClearChannels(String error);

  /// No description provided for @failedToClearContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear contacts: {error}'**
  String failedToClearContacts(String error);

  /// No description provided for @failedToConnectViaSerial.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect via serial'**
  String get failedToConnectViaSerial;

  /// No description provided for @failedToLoadPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preview image: {error}'**
  String failedToLoadPreviewImage(String error);

  /// No description provided for @failedToLoadTrace.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trace: {error}'**
  String failedToLoadTrace(String error);

  /// No description provided for @failedToSendSarMarker.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SAR marker: {error}'**
  String failedToSendSarMarker(String error);

  /// No description provided for @failedToSetBuzzerMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to set buzzer mode: {error}'**
  String failedToSetBuzzerMode(String error);

  /// No description provided for @failedToSetGpsMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to set GPS mode: {error}'**
  String failedToSetGpsMode(String error);

  /// No description provided for @failedToSyncDeviceTime.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync device time: {error}'**
  String failedToSyncDeviceTime(String error);

  /// No description provided for @failedToWipeDeviceData.
  ///
  /// In en, this message translates to:
  /// **'Failed to wipe device data: {error}'**
  String failedToWipeDeviceData(String error);

  /// No description provided for @fastGpsTargetChannel.
  ///
  /// In en, this message translates to:
  /// **'Fast GPS target channel'**
  String get fastGpsTargetChannel;

  /// No description provided for @fastUpdatesThresholdsAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Fast updates, thresholds, and permissions'**
  String get fastUpdatesThresholdsAndPermissions;

  /// No description provided for @fetchingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Fetching catalog...'**
  String get fetchingCatalog;

  /// No description provided for @fifteenMinutes.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get fifteenMinutes;

  /// No description provided for @fifteenSeconds.
  ///
  /// In en, this message translates to:
  /// **'15 seconds'**
  String get fifteenSeconds;

  /// No description provided for @filterByDirection.
  ///
  /// In en, this message translates to:
  /// **'Filter by direction'**
  String get filterByDirection;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get fiveMinutes;

  /// No description provided for @fiveSeconds.
  ///
  /// In en, this message translates to:
  /// **'5 seconds'**
  String get fiveSeconds;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @gpsAdvertPolicy.
  ///
  /// In en, this message translates to:
  /// **'GPS advert policy'**
  String get gpsAdvertPolicy;

  /// No description provided for @gpsAndLocation.
  ///
  /// In en, this message translates to:
  /// **'GPS & Location'**
  String get gpsAndLocation;

  /// No description provided for @gpsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'GPS diagnostics'**
  String get gpsDiagnostics;

  /// No description provided for @gpsSection.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gpsSection;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @hex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get hex;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @howTheRadioAutoAddsDiscoveredNodes.
  ///
  /// In en, this message translates to:
  /// **'How the radio auto-adds discovered nodes.'**
  String get howTheRadioAutoAddsDiscoveredNodes;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @importProfile.
  ///
  /// In en, this message translates to:
  /// **'Import profile'**
  String get importProfile;

  /// No description provided for @lastFix.
  ///
  /// In en, this message translates to:
  /// **'Last fix'**
  String get lastFix;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @loadASavedRegion.
  ///
  /// In en, this message translates to:
  /// **'Load a saved region'**
  String get loadASavedRegion;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @locationSharingHardwareAndUpdateInterval.
  ///
  /// In en, this message translates to:
  /// **'Location sharing, hardware, and update interval.'**
  String get locationSharingHardwareAndUpdateInterval;

  /// No description provided for @locationTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Location telemetry'**
  String get locationTelemetry;

  /// No description provided for @lockDestination.
  ///
  /// In en, this message translates to:
  /// **'Lock destination'**
  String get lockDestination;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map Style'**
  String get mapStyle;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @maxZoom.
  ///
  /// In en, this message translates to:
  /// **'Max Zoom'**
  String get maxZoom;

  /// No description provided for @messaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get messaging;

  /// No description provided for @metHistory.
  ///
  /// In en, this message translates to:
  /// **'MET history'**
  String get metHistory;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @minZoom.
  ///
  /// In en, this message translates to:
  /// **'Min Zoom'**
  String get minZoom;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @multiAckMode.
  ///
  /// In en, this message translates to:
  /// **'Multi-ACK mode'**
  String get multiAckMode;

  /// No description provided for @multiDeviceWorkspaceManagement.
  ///
  /// In en, this message translates to:
  /// **'Multi-device workspace management'**
  String get multiDeviceWorkspaceManagement;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @nameAndTelemetryShared.
  ///
  /// In en, this message translates to:
  /// **'Name and telemetry shared with other devices.'**
  String get nameAndTelemetryShared;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version: {version}'**
  String newVersionAvailable(String version);

  /// No description provided for @newer.
  ///
  /// In en, this message translates to:
  /// **'Newer'**
  String get newer;

  /// No description provided for @noNeighboursFound.
  ///
  /// In en, this message translates to:
  /// **'No neighbours found'**
  String get noNeighboursFound;

  /// No description provided for @noServersFound.
  ///
  /// In en, this message translates to:
  /// **'No servers found'**
  String get noServersFound;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @offZeroSeconds.
  ///
  /// In en, this message translates to:
  /// **'Off (0 s)'**
  String get offZeroSeconds;

  /// No description provided for @offlineMaps.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get offlineMaps;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @oneByteMode0.
  ///
  /// In en, this message translates to:
  /// **'1 byte (mode 0)'**
  String get oneByteMode0;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @oneMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get oneMinute;

  /// No description provided for @openPacketLogs.
  ///
  /// In en, this message translates to:
  /// **'Open packet logs'**
  String get openPacketLogs;

  /// No description provided for @packetTypeHelp.
  ///
  /// In en, this message translates to:
  /// **'Packet type help'**
  String get packetTypeHelp;

  /// No description provided for @pasteShareLinkOrHexAdvert.
  ///
  /// In en, this message translates to:
  /// **'Paste a share link or hex advert'**
  String get pasteShareLinkOrHexAdvert;

  /// No description provided for @pathHash.
  ///
  /// In en, this message translates to:
  /// **'Path hash'**
  String get pathHash;

  /// No description provided for @pathSize.
  ///
  /// In en, this message translates to:
  /// **'Path size'**
  String get pathSize;

  /// No description provided for @ping.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get ping;

  /// No description provided for @polygon.
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get polygon;

  /// No description provided for @rawResponseCopied.
  ///
  /// In en, this message translates to:
  /// **'Raw response copied'**
  String get rawResponseCopied;

  /// No description provided for @resendThroughNearestRepeaterOnFailure.
  ///
  /// In en, this message translates to:
  /// **'Resend through nearest repeater on failure'**
  String get resendThroughNearestRepeaterOnFailure;

  /// No description provided for @resolveContact.
  ///
  /// In en, this message translates to:
  /// **'Resolve contact'**
  String get resolveContact;

  /// No description provided for @routingRetriesAndDestinationLock.
  ///
  /// In en, this message translates to:
  /// **'Routing, retries, and destination lock'**
  String get routingRetriesAndDestinationLock;

  /// No description provided for @samples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get samples;

  /// No description provided for @satellites.
  ///
  /// In en, this message translates to:
  /// **'Satellites'**
  String get satellites;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchByNameOrToken.
  ///
  /// In en, this message translates to:
  /// **'Search by name or token'**
  String get searchByNameOrToken;

  /// No description provided for @searchDiscoveredNodes.
  ///
  /// In en, this message translates to:
  /// **'Search discovered nodes'**
  String get searchDiscoveredNodes;

  /// No description provided for @searchInCurrentFilter.
  ///
  /// In en, this message translates to:
  /// **'Search in current filter'**
  String get searchInCurrentFilter;

  /// No description provided for @searchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get searchLogs;

  /// No description provided for @searchSensors.
  ///
  /// In en, this message translates to:
  /// **'Search sensors'**
  String get searchSensors;

  /// No description provided for @searchThisSection.
  ///
  /// In en, this message translates to:
  /// **'Search this section'**
  String get searchThisSection;

  /// No description provided for @selectedRelays.
  ///
  /// In en, this message translates to:
  /// **'Selected relays'**
  String get selectedRelays;

  /// No description provided for @sensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get sensor;

  /// No description provided for @serialError.
  ///
  /// In en, this message translates to:
  /// **'Serial error: {error}'**
  String serialError(String error);

  /// No description provided for @setPathForContact.
  ///
  /// In en, this message translates to:
  /// **'Set Path for {name}'**
  String setPathForContact(String name);

  /// No description provided for @shareLiveGps.
  ///
  /// In en, this message translates to:
  /// **'Share live GPS'**
  String get shareLiveGps;

  /// No description provided for @shareMyTiles.
  ///
  /// In en, this message translates to:
  /// **'Share my tiles'**
  String get shareMyTiles;

  /// No description provided for @sharingLocationFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Sharing location on this channel from the phone.'**
  String get sharingLocationFromPhone;

  /// No description provided for @sharingLocationFromRadio.
  ///
  /// In en, this message translates to:
  /// **'Sharing location on this channel from the radio.'**
  String get sharingLocationFromRadio;

  /// No description provided for @signalDbm.
  ///
  /// In en, this message translates to:
  /// **'Signal {rssi} dBm'**
  String signalDbm(String rssi);

  /// No description provided for @sizeCompressionAndPreview.
  ///
  /// In en, this message translates to:
  /// **'Size, compression, and preview'**
  String get sizeCompressionAndPreview;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @smallerFileSize.
  ///
  /// In en, this message translates to:
  /// **'Smaller file size'**
  String get smallerFileSize;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @stoppedSharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Stopped sharing location on this channel.'**
  String get stoppedSharingLocation;

  /// No description provided for @suppressNotificationsWhileInForeground.
  ///
  /// In en, this message translates to:
  /// **'Suppress notifications while in foreground'**
  String get suppressNotificationsWhileInForeground;

  /// No description provided for @tabsAndNavigation.
  ///
  /// In en, this message translates to:
  /// **'Tabs & Navigation'**
  String get tabsAndNavigation;

  /// No description provided for @templatesAndTutorials.
  ///
  /// In en, this message translates to:
  /// **'Templates and tutorials'**
  String get templatesAndTutorials;

  /// No description provided for @tenMinutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get tenMinutes;

  /// No description provided for @tenSeconds.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get tenSeconds;

  /// No description provided for @testSendUpdate.
  ///
  /// In en, this message translates to:
  /// **'Test send update'**
  String get testSendUpdate;

  /// No description provided for @themeLanguageAndDisplayPreferences.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, and display preferences'**
  String get themeLanguageAndDisplayPreferences;

  /// No description provided for @thirtyMinutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get thirtyMinutes;

  /// No description provided for @thirtySeconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get thirtySeconds;

  /// No description provided for @threeBytesMode2.
  ///
  /// In en, this message translates to:
  /// **'3 bytes (mode 2)'**
  String get threeBytesMode2;

  /// No description provided for @trafficStatsMessageHistoryAndDeveloperTools.
  ///
  /// In en, this message translates to:
  /// **'Traffic stats, message history, and developer tools'**
  String get trafficStatsMessageHistoryAndDeveloperTools;

  /// No description provided for @twoBytesMode1.
  ///
  /// In en, this message translates to:
  /// **'2 bytes (mode 1)'**
  String get twoBytesMode1;

  /// No description provided for @twoMinutes.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get twoMinutes;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @useContactFlags.
  ///
  /// In en, this message translates to:
  /// **'Use contact flags'**
  String get useContactFlags;

  /// No description provided for @useSavedCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Use saved coordinates'**
  String get useSavedCoordinates;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewNeighbours.
  ///
  /// In en, this message translates to:
  /// **'View Neighbours'**
  String get viewNeighbours;

  /// No description provided for @viewPublicStats.
  ///
  /// In en, this message translates to:
  /// **'View public stats'**
  String get viewPublicStats;

  /// No description provided for @setRegionScope.
  ///
  /// In en, this message translates to:
  /// **'Set region scope'**
  String get setRegionScope;

  /// No description provided for @regionScope.
  ///
  /// In en, this message translates to:
  /// **'Region scope'**
  String get regionScope;

  /// No description provided for @regionScopeNone.
  ///
  /// In en, this message translates to:
  /// **'None (global)'**
  String get regionScopeNone;

  /// No description provided for @clearRegionScope.
  ///
  /// In en, this message translates to:
  /// **'Clear scope'**
  String get clearRegionScope;

  /// No description provided for @regionScopeWarning.
  ///
  /// In en, this message translates to:
  /// **'Only repeaters allowing this region will forward.'**
  String get regionScopeWarning;

  /// No description provided for @discoverRegions.
  ///
  /// In en, this message translates to:
  /// **'Discover from repeaters'**
  String get discoverRegions;

  /// No description provided for @discoveringRegions.
  ///
  /// In en, this message translates to:
  /// **'Discovering regions...'**
  String get discoveringRegions;

  /// No description provided for @enterRegionName.
  ///
  /// In en, this message translates to:
  /// **'Region name (e.g. auckland)'**
  String get enterRegionName;

  /// No description provided for @noRegionsFound.
  ///
  /// In en, this message translates to:
  /// **'No regions found on this repeater.'**
  String get noRegionsFound;

  /// No description provided for @regionScopeSet.
  ///
  /// In en, this message translates to:
  /// **'Region scope set to {name}'**
  String regionScopeSet(String name);

  /// No description provided for @regionScopeCleared.
  ///
  /// In en, this message translates to:
  /// **'Region scope cleared'**
  String get regionScopeCleared;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'el',
    'en',
    'es',
    'fr',
    'hr',
    'it',
    'pl',
    'pt',
    'ru',
    'sl',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hr':
      return AppLocalizationsHr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'sl':
      return AppLocalizationsSl();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
