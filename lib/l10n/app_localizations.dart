import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_sl.dart';

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
    Locale('en'),
    Locale('hr'),
    Locale('sl'),
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

  /// Text shown when scanning for BLE devices
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get scanningForDevices;

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

  /// Subtitle text for device in scan list
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get tapToConnect;

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

  /// Success message showing advertised location
  ///
  /// In en, this message translates to:
  /// **'Advertised at {latitude}, {longitude}'**
  String advertisedAtLocation(String latitude, String longitude);

  /// Error message for failed advertisement
  ///
  /// In en, this message translates to:
  /// **'Failed to advertise: {error}'**
  String failedToAdvertise(String error);

  /// Text shown during reconnection attempts
  ///
  /// In en, this message translates to:
  /// **'Reconnecting... ({attempt}/{max})'**
  String reconnecting(int attempt, int max);

  /// Tooltip for cancel reconnection button
  ///
  /// In en, this message translates to:
  /// **'Cancel reconnection'**
  String get cancelReconnection;

  /// Menu item for map management
  ///
  /// In en, this message translates to:
  /// **'Map Management'**
  String get mapManagement;

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

  /// Description for RX/TX indicators setting
  ///
  /// In en, this message translates to:
  /// **'Display packet activity indicators in top bar'**
  String get displayPacketActivity;

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

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Slovenian language option
  ///
  /// In en, this message translates to:
  /// **'Slovenian'**
  String get slovenian;

  /// Croatian language option
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get croatian;

  /// Location settings section header
  ///
  /// In en, this message translates to:
  /// **'Location Broadcasting'**
  String get locationBroadcasting;

  /// Auto location tracking setting
  ///
  /// In en, this message translates to:
  /// **'Auto Location Tracking'**
  String get autoLocationTracking;

  /// Description for auto location tracking
  ///
  /// In en, this message translates to:
  /// **'Automatically broadcast position updates'**
  String get automaticallyBroadcastPosition;

  /// Configure tracking button label
  ///
  /// In en, this message translates to:
  /// **'Configure Tracking'**
  String get configureTracking;

  /// Description for tracking configuration
  ///
  /// In en, this message translates to:
  /// **'Distance and time thresholds'**
  String get distanceAndTimeThresholds;

  /// Tracking configuration dialog title
  ///
  /// In en, this message translates to:
  /// **'Location Tracking Configuration'**
  String get locationTrackingConfiguration;

  /// Description for tracking configuration dialog
  ///
  /// In en, this message translates to:
  /// **'Configure when location broadcasts are sent to the mesh network'**
  String get configureWhenLocationBroadcasts;

  /// Minimum distance setting label
  ///
  /// In en, this message translates to:
  /// **'Minimum Distance'**
  String get minimumDistance;

  /// Description for minimum distance
  ///
  /// In en, this message translates to:
  /// **'Broadcast only after moving {distance} meters'**
  String broadcastAfterMoving(String distance);

  /// Maximum distance setting label
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get maximumDistance;

  /// Description for maximum distance
  ///
  /// In en, this message translates to:
  /// **'Always broadcast after moving {distance} meters'**
  String alwaysBroadcastAfterMoving(String distance);

  /// Minimum time interval setting label
  ///
  /// In en, this message translates to:
  /// **'Minimum Time Interval'**
  String get minimumTimeInterval;

  /// Description for time interval
  ///
  /// In en, this message translates to:
  /// **'Always broadcast every {duration}'**
  String alwaysBroadcastEvery(String duration);

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

  /// App name label
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

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

  /// Developer section header
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

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

  /// Action to send direct message to contact
  ///
  /// In en, this message translates to:
  /// **'Send Direct Message'**
  String get sendDirectMessage;

  /// Action to reset contact path for re-routing
  ///
  /// In en, this message translates to:
  /// **'Reset Path (Re-route)'**
  String get resetPath;

  /// Success message when public key is copied
  ///
  /// In en, this message translates to:
  /// **'Public key copied to clipboard'**
  String get publicKeyCopied;

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

  /// Clear all button label
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Message when there are no drawings to share
  ///
  /// In en, this message translates to:
  /// **'No local drawings to share'**
  String get noLocalDrawings;

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

  /// Title for direct message sheet
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessage;

  /// Success message after sending direct message
  ///
  /// In en, this message translates to:
  /// **'Direct message sent to {contactName}'**
  String directMessageSentTo(String contactName);

  /// Error message when sending direct message fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String failedToSend(String error);

  /// Information about direct messaging behavior
  ///
  /// In en, this message translates to:
  /// **'This message will be sent directly to {contactName}. It will also appear in the main messages feed.'**
  String directMessageInfo(String contactName);

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

  /// Admin badge label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

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

  /// Status message for direct ping
  ///
  /// In en, this message translates to:
  /// **'Pinging {name} (direct via path)...'**
  String pingingDirect(String name);

  /// Status message for flood ping
  ///
  /// In en, this message translates to:
  /// **'Pinging {name} (flooding - no path)...'**
  String pingingFlood(String name);

  /// Warning when direct ping times out
  ///
  /// In en, this message translates to:
  /// **'Direct ping timeout - retrying {name} with flooding...'**
  String directPingTimeout(String name);

  /// Success message for ping
  ///
  /// In en, this message translates to:
  /// **'Ping successful to {name}{fallback}'**
  String pingSuccessful(String name, String fallback);

  /// Suffix for ping success with fallback
  ///
  /// In en, this message translates to:
  /// **' (via flooding fallback)'**
  String get viaFloodingFallback;

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

  /// Status message while removing contact
  ///
  /// In en, this message translates to:
  /// **'Removing {name}...'**
  String removingContact(String name);

  /// Success message after removing contact
  ///
  /// In en, this message translates to:
  /// **'Contact \"{name}\" removed'**
  String contactRemoved(String name);

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

  /// Room status section header
  ///
  /// In en, this message translates to:
  /// **'Room Status'**
  String get roomStatus;

  /// Login status label
  ///
  /// In en, this message translates to:
  /// **'Login Status'**
  String get loginStatus;

  /// Not logged in status
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// Admin access label
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

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

  /// Password saved label
  ///
  /// In en, this message translates to:
  /// **'Password Saved'**
  String get passwordSaved;

  /// Location section header
  ///
  /// In en, this message translates to:
  /// **'Location:'**
  String get locationColon;

  /// Telemetry section header
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get telemetry;

  /// Status message while requesting telemetry
  ///
  /// In en, this message translates to:
  /// **'Requesting telemetry from {name}...'**
  String requestingTelemetry(String name);

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

  /// Updated timestamp label
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// Info message after path reset
  ///
  /// In en, this message translates to:
  /// **'Path reset for {name}. Next message will find a new route.'**
  String pathResetInfo(String name);

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

  /// Title for nearby contacts list in compass
  ///
  /// In en, this message translates to:
  /// **'Nearby Contacts'**
  String get nearbyContacts;

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

  /// Section header for rooms/channels
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// Title for cache statistics section
  ///
  /// In en, this message translates to:
  /// **'Cache Statistics'**
  String get cacheStatistics;

  /// Label for total number of cached tiles
  ///
  /// In en, this message translates to:
  /// **'Total Tiles'**
  String get totalTiles;

  /// Label for cache size in MB
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSize;

  /// Label for cache store name
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// Message when cache statistics are unavailable
  ///
  /// In en, this message translates to:
  /// **'No cache statistics available'**
  String get noCacheStatistics;

  /// Title for download region section
  ///
  /// In en, this message translates to:
  /// **'Download Region'**
  String get downloadRegion;

  /// Label for map layer selection
  ///
  /// In en, this message translates to:
  /// **'Map Layer'**
  String get mapLayer;

  /// Title for region bounds input section
  ///
  /// In en, this message translates to:
  /// **'Region Bounds'**
  String get regionBounds;

  /// Label for north coordinate
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get north;

  /// Label for south coordinate
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get south;

  /// Label for east coordinate
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get east;

  /// Label for west coordinate
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get west;

  /// Title for zoom levels section
  ///
  /// In en, this message translates to:
  /// **'Zoom Levels'**
  String get zoomLevels;

  /// Label for minimum zoom level
  ///
  /// In en, this message translates to:
  /// **'Min: {zoom}'**
  String minZoom(int zoom);

  /// Label for maximum zoom level
  ///
  /// In en, this message translates to:
  /// **'Max: {zoom}'**
  String maxZoom(int zoom);

  /// Status message during download
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloadingDots;

  /// Button to cancel download
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownload;

  /// Button to start region download
  ///
  /// In en, this message translates to:
  /// **'Download Region'**
  String get downloadRegionButton;

  /// Warning about download size and time
  ///
  /// In en, this message translates to:
  /// **'Note: Large regions or high zoom levels may take significant time and storage.'**
  String get downloadNote;

  /// Title for cache management section
  ///
  /// In en, this message translates to:
  /// **'Cache Management'**
  String get cacheManagement;

  /// Button to clear all cached maps
  ///
  /// In en, this message translates to:
  /// **'Clear All Maps'**
  String get clearAllMaps;

  /// Title for clear maps confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear All Maps'**
  String get clearMapsConfirmTitle;

  /// Confirmation message for clearing maps
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all downloaded maps? This action cannot be undone.'**
  String get clearMapsConfirmMessage;

  /// Success message after map download
  ///
  /// In en, this message translates to:
  /// **'Map download completed!'**
  String get mapDownloadCompleted;

  /// Success message after clearing cache
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully!'**
  String get cacheClearedSuccessfully;

  /// Message when download is cancelled
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// Initial status when download begins
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get startingDownload;

  /// Status during tile download
  ///
  /// In en, this message translates to:
  /// **'Downloading map tiles...'**
  String get downloadingMapTiles;

  /// Status after successful download
  ///
  /// In en, this message translates to:
  /// **'Download completed successfully!'**
  String get downloadCompletedSuccessfully;

  /// Status while cancelling download
  ///
  /// In en, this message translates to:
  /// **'Cancelling download...'**
  String get cancellingDownload;

  /// Error message when loading cache stats fails
  ///
  /// In en, this message translates to:
  /// **'Error loading stats: {error}'**
  String errorLoadingStats(String error);

  /// Error message when download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// Error message when cancel fails
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {error}'**
  String cancelFailed(String error);

  /// Error message when clearing cache fails
  ///
  /// In en, this message translates to:
  /// **'Clear cache failed: {error}'**
  String clearCacheFailed(String error);

  /// Validation error for minimum zoom
  ///
  /// In en, this message translates to:
  /// **'Min zoom: {error}'**
  String minZoomError(String error);

  /// Validation error for maximum zoom
  ///
  /// In en, this message translates to:
  /// **'Max zoom: {error}'**
  String maxZoomError(String error);

  /// Validation error when min zoom > max zoom
  ///
  /// In en, this message translates to:
  /// **'Minimum zoom must be less than or equal to maximum zoom'**
  String get minZoomGreaterThanMax;

  /// Title for map layer selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Map Layer'**
  String get selectMapLayer;

  /// Title for map options dialog
  ///
  /// In en, this message translates to:
  /// **'Map Options'**
  String get mapOptions;

  /// Toggle for showing map legend
  ///
  /// In en, this message translates to:
  /// **'Show Legend'**
  String get showLegend;

  /// Description for show legend toggle
  ///
  /// In en, this message translates to:
  /// **'Display marker type counts'**
  String get displayMarkerTypeCounts;

  /// Toggle for rotating map with compass heading
  ///
  /// In en, this message translates to:
  /// **'Rotate Map with Heading'**
  String get rotateMapWithHeading;

  /// Description for rotate map toggle
  ///
  /// In en, this message translates to:
  /// **'Map follows your direction when moving'**
  String get mapFollowsDirection;

  /// Toggle for showing map debug information
  ///
  /// In en, this message translates to:
  /// **'Show Map Debug Info'**
  String get showMapDebugInfo;

  /// Description for debug info toggle
  ///
  /// In en, this message translates to:
  /// **'Display zoom level and bounds'**
  String get displayZoomLevelBounds;

  /// Toggle for fullscreen map mode
  ///
  /// In en, this message translates to:
  /// **'Fullscreen Mode'**
  String get fullscreenMode;

  /// Description for fullscreen mode toggle
  ///
  /// In en, this message translates to:
  /// **'Hide all UI controls for full map view'**
  String get hideUiFullMapView;

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

  /// Tooltip for download visible area button
  ///
  /// In en, this message translates to:
  /// **'Download visible area'**
  String get downloadVisibleArea;

  /// Loading message for map initialization
  ///
  /// In en, this message translates to:
  /// **'Initializing map...'**
  String get initializingMap;

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

  /// Success message when message is sent to public channel
  ///
  /// In en, this message translates to:
  /// **'Message sent to public channel'**
  String get messageSentToPublicChannel;

  /// Error when no room is selected for SAR marker
  ///
  /// In en, this message translates to:
  /// **'Please select a room to send SAR marker'**
  String get pleaseSelectRoomToSendSar;

  /// Error message when SAR marker fails to send
  ///
  /// In en, this message translates to:
  /// **'Failed to send SAR marker: {error}'**
  String failedToSendSarMarker(String error);

  /// Success message when SAR marker is sent to room
  ///
  /// In en, this message translates to:
  /// **'SAR marker sent to {roomName}'**
  String sarMarkerSentTo(String roomName);

  /// Warning when trying to sync messages while not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected - cannot sync messages'**
  String get notConnectedCannotSync;

  /// Success message showing number of synced messages
  ///
  /// In en, this message translates to:
  /// **'Synced {count} message(s)'**
  String syncedMessageCount(int count);

  /// Info message when no new messages to sync
  ///
  /// In en, this message translates to:
  /// **'No new messages'**
  String get noNewMessages;

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(String error);

  /// Error when message retry fails
  ///
  /// In en, this message translates to:
  /// **'Failed to resend message'**
  String get failedToResendMessage;

  /// Info message when retrying a failed message
  ///
  /// In en, this message translates to:
  /// **'Retrying message...'**
  String get retryingMessage;

  /// Error message when retry fails
  ///
  /// In en, this message translates to:
  /// **'Retry failed: {error}'**
  String retryFailed(String error);

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

  /// Info message when message is deleted
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// Success message when contacts are refreshed
  ///
  /// In en, this message translates to:
  /// **'Refreshed contacts'**
  String get refreshedContacts;

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

  /// Helper text example for frequency
  ///
  /// In en, this message translates to:
  /// **'e.g., 869.618'**
  String get frequencyExample;

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

  /// Title for offline vector maps section
  ///
  /// In en, this message translates to:
  /// **'Offline Vector Maps'**
  String get offlineVectorMaps;

  /// Description for offline vector maps section
  ///
  /// In en, this message translates to:
  /// **'Import and manage offline vector map tiles (MBTiles format) for use without internet connection'**
  String get offlineVectorMapsDescription;

  /// Button to import MBTiles file
  ///
  /// In en, this message translates to:
  /// **'Import MBTiles File'**
  String get importMbtiles;

  /// Note about supported MBTiles file types
  ///
  /// In en, this message translates to:
  /// **'Supports MBTiles files with vector tiles (PBF/MVT format). Geofabrik extracts work great!'**
  String get importMbtilesNote;

  /// Message when no MBTiles files are available
  ///
  /// In en, this message translates to:
  /// **'No offline vector maps found'**
  String get noMbtilesFiles;

  /// Success message after importing MBTiles file
  ///
  /// In en, this message translates to:
  /// **'MBTiles file imported successfully'**
  String get mbtilesImportedSuccessfully;

  /// Error message when MBTiles import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import MBTiles file'**
  String get failedToImportMbtiles;

  /// Title for delete MBTiles confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Offline Map'**
  String get deleteMbtilesConfirmTitle;

  /// Confirmation message for deleting MBTiles file
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This will permanently remove the offline map.'**
  String deleteMbtilesConfirmMessage(String name);

  /// Success message after deleting MBTiles file
  ///
  /// In en, this message translates to:
  /// **'Offline map deleted successfully'**
  String get mbtilesDeletedSuccessfully;

  /// Error message when MBTiles deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete offline map'**
  String get failedToDeleteMbtiles;

  /// Label for vector tile type
  ///
  /// In en, this message translates to:
  /// **'Vector Tiles'**
  String get vectorTiles;

  /// Label for vector tile schema
  ///
  /// In en, this message translates to:
  /// **'Schema'**
  String get schema;

  /// Unknown value label
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Label for geographic bounds
  ///
  /// In en, this message translates to:
  /// **'Bounds'**
  String get bounds;

  /// Section header for online map layers
  ///
  /// In en, this message translates to:
  /// **'Online Layers'**
  String get onlineLayers;

  /// Section header for offline map layers (MBTiles)
  ///
  /// In en, this message translates to:
  /// **'Offline Layers'**
  String get offlineLayers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr', 'sl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
    case 'sl':
      return AppLocalizationsSl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
