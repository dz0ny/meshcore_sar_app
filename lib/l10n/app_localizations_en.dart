// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Messages';

  @override
  String get contacts => 'Contacts';

  @override
  String get map => 'Map';

  @override
  String get settings => 'Settings';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get scanningForDevices => 'Scanning for devices...';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get tapToConnect => 'Tap to connect';

  @override
  String get deviceNotConnected => 'Device not connected';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable in Settings.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for GPS tracking and team coordination. You can enable it later in Settings.';

  @override
  String get locationServicesDisabled =>
      'Location services are disabled. Please enable them in Settings.';

  @override
  String get failedToGetGpsLocation => 'Failed to get GPS location';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Advertised at $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Failed to advertise: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Reconnecting... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Cancel reconnection';

  @override
  String get mapManagement => 'Map Management';

  @override
  String get general => 'General';

  @override
  String get theme => 'Theme';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get blueLightTheme => 'Blue light theme';

  @override
  String get blueDarkTheme => 'Blue dark theme';

  @override
  String get sarRed => 'SAR Red';

  @override
  String get alertEmergencyMode => 'Alert/Emergency mode';

  @override
  String get sarGreen => 'SAR Green';

  @override
  String get safeAllClearMode => 'Safe/All Clear mode';

  @override
  String get autoSystem => 'Auto (System)';

  @override
  String get followSystemTheme => 'Follow system theme';

  @override
  String get showRxTxIndicators => 'Show RX/TX Indicators';

  @override
  String get displayPacketActivity =>
      'Display packet activity indicators in top bar';

  @override
  String get simpleMode => 'Simple Mode';

  @override
  String get simpleModeDescription =>
      'Hide non-essential information in messages and contacts';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get english => 'English';

  @override
  String get slovenian => 'Slovenian';

  @override
  String get croatian => 'Croatian';

  @override
  String get german => 'German';

  @override
  String get spanish => 'Spanish';

  @override
  String get french => 'French';

  @override
  String get italian => 'Italian';

  @override
  String get locationBroadcasting => 'Location Broadcasting';

  @override
  String get autoLocationTracking => 'Auto Location Tracking';

  @override
  String get automaticallyBroadcastPosition =>
      'Automatically broadcast position updates';

  @override
  String get configureTracking => 'Configure Tracking';

  @override
  String get distanceAndTimeThresholds => 'Distance and time thresholds';

  @override
  String get locationTrackingConfiguration => 'Location Tracking Configuration';

  @override
  String get configureWhenLocationBroadcasts =>
      'Configure when location broadcasts are sent to the mesh network';

  @override
  String get minimumDistance => 'Minimum Distance';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Broadcast only after moving $distance meters';
  }

  @override
  String get maximumDistance => 'Maximum Distance';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Always broadcast after moving $distance meters';
  }

  @override
  String get minimumTimeInterval => 'Minimum Time Interval';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Always broadcast every $duration';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get appName => 'App Name';

  @override
  String get aboutMeshCoreSar => 'About MeshCore SAR';

  @override
  String get aboutDescription =>
      'A Search & Rescue application designed for emergency response teams. Features include:\n\n• BLE mesh networking for device-to-device communication\n• Offline maps with multiple layer options\n• Real-time team member tracking\n• SAR tactical markers (found person, fire, staging)\n• Contact management and messaging\n• GPS tracking with compass heading\n• Map tile caching for offline use';

  @override
  String get technologiesUsed => 'Technologies Used:';

  @override
  String get technologiesList =>
      '• Flutter for cross-platform development\n• BLE (Bluetooth Low Energy) for mesh networking\n• OpenStreetMap for mapping\n• Provider for state management\n• SharedPreferences for local storage';

  @override
  String get moreInfo => 'More Info';

  @override
  String get learnMoreAbout => 'Learn more about MeshCore SAR';

  @override
  String get developer => 'Developer';

  @override
  String get packageName => 'Package Name';

  @override
  String get sampleData => 'Sample Data';

  @override
  String get sampleDataDescription =>
      'Load or clear sample contacts, channel messages, and SAR markers for testing';

  @override
  String get loadSampleData => 'Load Sample Data';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataConfirmTitle => 'Clear All Data';

  @override
  String get clearAllDataConfirmMessage =>
      'This will clear all contacts and SAR markers. Are you sure?';

  @override
  String get clear => 'Clear';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Loaded $teamCount team members, $channelCount channels, $sarCount SAR markers, $messageCount messages';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Failed to load sample data: $error';
  }

  @override
  String get allDataCleared => 'All data cleared';

  @override
  String get failedToStartBackgroundTracking =>
      'Failed to start background tracking. Check permissions and BLE connection.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Location broadcast: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'The default pin for devices without a screen is 123456. Trouble pairing? Forget the bluetooth device in system settings.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get pullDownToSync => 'Pull down to sync messages';

  @override
  String get deleteContact => 'Delete Contact';

  @override
  String get delete => 'Delete';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get refresh => 'Refresh';

  @override
  String get sendDirectMessage => 'Send';

  @override
  String get resetPath => 'Reset Path (Re-route)';

  @override
  String get publicKeyCopied => 'Public key copied to clipboard';

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String failedToSyncContacts(String error) {
    return 'Failed to sync contacts: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Logged in successfully! Waiting for room messages...';

  @override
  String get loginFailed => 'Login failed - incorrect password';

  @override
  String loggingIn(String roomName) {
    return 'Logging in to $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Failed to send login: $error';
  }

  @override
  String get lowLocationAccuracy => 'Low Location Accuracy';

  @override
  String get continue_ => 'Continue';

  @override
  String get sendSarMarker => 'Send SAR marker';

  @override
  String get deleteDrawing => 'Delete Drawing';

  @override
  String get drawingTools => 'Drawing Tools';

  @override
  String get drawLine => 'Draw Line';

  @override
  String get drawLineDesc => 'Draw a freehand line on the map';

  @override
  String get drawRectangle => 'Draw Rectangle';

  @override
  String get drawRectangleDesc => 'Draw a rectangular area on the map';

  @override
  String get measureDistance => 'Measure Distance';

  @override
  String get measureDistanceDesc => 'Long press two points to measure';

  @override
  String get clearMeasurement => 'Clear Measurement';

  @override
  String distanceLabel(String distance) {
    return 'Distance: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Long press for second point';

  @override
  String get longPressToStartMeasurement => 'Long press to set first point';

  @override
  String get longPressToStartNewMeasurement =>
      'Long press to start new measurement';

  @override
  String get shareDrawings => 'Share Drawings';

  @override
  String get clearAllDrawings => 'Clear All Drawings';

  @override
  String get completeLine => 'Complete Line';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Broadcast $count drawing$plural to team';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Remove all $count drawing$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Delete all $count drawing$plural from the map?';
  }

  @override
  String get drawing => 'Drawing';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Share $count Drawing$plural';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return 'Sent $count map drawing$plural to $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return 'Shared $success/$total drawing$plural to $roomName';
  }

  @override
  String get showReceivedDrawings => 'Show Received Drawings';

  @override
  String get showingAllDrawings => 'Showing all drawings';

  @override
  String get showingOnlyYourDrawings => 'Showing only your drawings';

  @override
  String get showSarMarkers => 'Show SAR Markers';

  @override
  String get showingSarMarkers => 'Showing SAR markers';

  @override
  String get hidingSarMarkers => 'Hiding SAR markers';

  @override
  String get clearAll => 'Clear All';

  @override
  String get noLocalDrawings => 'No local drawings to share';

  @override
  String get publicChannel => 'Public Channel';

  @override
  String get broadcastToAll => 'Broadcast to all nearby nodes (ephemeral)';

  @override
  String get storedPermanently => 'Stored permanently in room';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return 'Sent $count map drawing$plural to Public Channel';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return 'Shared $success/$total drawings to Public Channel';
  }

  @override
  String get notConnectedToDevice => 'Not connected to device';

  @override
  String get directMessage => 'Direct Message';

  @override
  String directMessageSentTo(String contactName) {
    return 'Direct message sent to $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Failed to send: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'This message will be sent directly to $contactName. It will also appear in the main messages feed.';
  }

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get quickLocationMarker => 'Quick location marker';

  @override
  String get markerType => 'Marker Type';

  @override
  String get sendTo => 'Send To';

  @override
  String get noDestinationsAvailable => 'No destinations available.';

  @override
  String get selectDestination => 'Select destination...';

  @override
  String get ephemeralBroadcastInfo =>
      'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.';

  @override
  String get persistentRoomInfo =>
      'Persistent: Stored immutably in room. Synced automatically and preserved offline.';

  @override
  String get location => 'Location';

  @override
  String get myLocation => 'My Location';

  @override
  String get fromMap => 'From Map';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get locationError => 'Location Error';

  @override
  String get retry => 'Retry';

  @override
  String get refreshLocation => 'Refresh location';

  @override
  String accuracyMeters(int accuracy) {
    return 'Accuracy: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get addAdditionalInformation => 'Add additional information...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Location accuracy is ±${accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?';
  }

  @override
  String get loginToRoom => 'Login to Room';

  @override
  String get enterPasswordInfo =>
      'Enter the password to access this room. The password will be saved for future use.';

  @override
  String get password => 'Password';

  @override
  String get enterRoomPassword => 'Enter room password';

  @override
  String get loggingInDots => 'Logging in...';

  @override
  String get login => 'Login';

  @override
  String failedToAddRoom(String error) {
    return 'Failed to add room to device: $error\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.';
  }

  @override
  String get direct => 'Direct';

  @override
  String get flood => 'Flood';

  @override
  String get admin => 'Admin';

  @override
  String get loggedIn => 'Logged In';

  @override
  String get noGpsData => 'No GPS data';

  @override
  String get distance => 'Distance';

  @override
  String pingingDirect(String name) {
    return 'Pinging $name (direct via path)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Pinging $name (flooding - no path)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Direct ping timeout - retrying $name with flooding...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping successful to $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (via flooding fallback)';

  @override
  String pingFailed(String name) {
    return 'Ping failed to $name - no response received';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis will remove the contact from both the app and the companion radio device.';
  }

  @override
  String removingContact(String name) {
    return 'Removing $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Contact \"$name\" removed';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Failed to remove contact: $error';
  }

  @override
  String get type => 'Type';

  @override
  String get publicKey => 'Public Key';

  @override
  String get lastSeen => 'Last Seen';

  @override
  String get roomStatus => 'Room Status';

  @override
  String get loginStatus => 'Login Status';

  @override
  String get notLoggedIn => 'Not Logged In';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permissions';

  @override
  String get passwordSaved => 'Password Saved';

  @override
  String get locationColon => 'Location:';

  @override
  String get telemetry => 'Telemetry';

  @override
  String requestingTelemetry(String name) {
    return 'Requesting telemetry from $name...';
  }

  @override
  String get voltage => 'Voltage';

  @override
  String get battery => 'Battery';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get pressure => 'Pressure';

  @override
  String get gpsTelemetry => 'GPS (Telemetry)';

  @override
  String get updated => 'Updated';

  @override
  String pathResetInfo(String name) {
    return 'Path reset for $name. Next message will find a new route.';
  }

  @override
  String get reLoginToRoom => 'Re-Login to Room';

  @override
  String get heading => 'Heading';

  @override
  String get elevation => 'Elevation';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get bearing => 'Bearing';

  @override
  String get direction => 'Direction';

  @override
  String get filterMarkers => 'Filter Markers';

  @override
  String get filterMarkersTooltip => 'Filter markers';

  @override
  String get contactsFilter => 'Contacts';

  @override
  String get repeatersFilter => 'Repeaters';

  @override
  String get sarMarkers => 'SAR Markers';

  @override
  String get foundPerson => 'Found Person';

  @override
  String get fire => 'Fire';

  @override
  String get stagingArea => 'Staging Area';

  @override
  String get showAll => 'Show All';

  @override
  String get nearbyContacts => 'Nearby Contacts';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get ahead => 'ahead';

  @override
  String degreesRight(int degrees) {
    return '$degrees° right';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° left';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'No contacts yet';

  @override
  String get connectToDeviceToLoadContacts =>
      'Connect to a device to load contacts';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get repeaters => 'Repeaters';

  @override
  String get rooms => 'Rooms';

  @override
  String get channels => 'Channels';

  @override
  String get cacheStatistics => 'Cache Statistics';

  @override
  String get totalTiles => 'Total Tiles';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get storeName => 'Store Name';

  @override
  String get noCacheStatistics => 'No cache statistics available';

  @override
  String get downloadRegion => 'Download Region';

  @override
  String get mapLayer => 'Map Layer';

  @override
  String get regionBounds => 'Region Bounds';

  @override
  String get north => 'North';

  @override
  String get south => 'South';

  @override
  String get east => 'East';

  @override
  String get west => 'West';

  @override
  String get zoomLevels => 'Zoom Levels';

  @override
  String minZoom(int zoom) {
    return 'Min: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Max: $zoom';
  }

  @override
  String get downloadingDots => 'Downloading...';

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String get downloadRegionButton => 'Download Region';

  @override
  String get downloadNote =>
      'Note: Large regions or high zoom levels may take significant time and storage.';

  @override
  String get cacheManagement => 'Cache Management';

  @override
  String get clearAllMaps => 'Clear All Maps';

  @override
  String get clearMapsConfirmTitle => 'Clear All Maps';

  @override
  String get clearMapsConfirmMessage =>
      'Are you sure you want to delete all downloaded maps? This action cannot be undone.';

  @override
  String get mapDownloadCompleted => 'Map download completed!';

  @override
  String get cacheClearedSuccessfully => 'Cache cleared successfully!';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get startingDownload => 'Starting download...';

  @override
  String get downloadingMapTiles => 'Downloading map tiles...';

  @override
  String get downloadCompletedSuccessfully =>
      'Download completed successfully!';

  @override
  String get cancellingDownload => 'Cancelling download...';

  @override
  String errorLoadingStats(String error) {
    return 'Error loading stats: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Cancel failed: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Clear cache failed: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Min zoom: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Max zoom: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Minimum zoom must be less than or equal to maximum zoom';

  @override
  String get selectMapLayer => 'Select Map Layer';

  @override
  String get mapOptions => 'Map Options';

  @override
  String get showLegend => 'Show Legend';

  @override
  String get displayMarkerTypeCounts => 'Display marker type counts';

  @override
  String get rotateMapWithHeading => 'Rotate Map with Heading';

  @override
  String get mapFollowsDirection => 'Map follows your direction when moving';

  @override
  String get resetMapRotation => 'Reset Rotation';

  @override
  String get resetMapRotationTooltip => 'Reset map to north';

  @override
  String get showMapDebugInfo => 'Show Map Debug Info';

  @override
  String get displayZoomLevelBounds => 'Display zoom level and bounds';

  @override
  String get fullscreenMode => 'Fullscreen Mode';

  @override
  String get hideUiFullMapView => 'Hide all UI controls for full map view';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Satellite';

  @override
  String get googleHybrid => 'Google Hybrid';

  @override
  String get googleRoadmap => 'Google Roadmap';

  @override
  String get googleTerrain => 'Google Terrain';

  @override
  String get downloadVisibleArea => 'Download visible area';

  @override
  String get initializingMap => 'Initializing map...';

  @override
  String get dragToPosition => 'Drag to Position';

  @override
  String get createSarMarker => 'Create SAR Marker';

  @override
  String get compass => 'Compass';

  @override
  String get navigationAndContacts => 'Navigation & Contacts';

  @override
  String get sarAlert => 'SAR ALERT';

  @override
  String get messageSentToPublicChannel => 'Message sent to public channel';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Please select a room to send SAR marker';

  @override
  String failedToSendSarMarker(String error) {
    return 'Failed to send SAR marker: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'SAR marker sent to $roomName';
  }

  @override
  String get notConnectedCannotSync => 'Not connected - cannot sync messages';

  @override
  String syncedMessageCount(int count) {
    return 'Synced $count message(s)';
  }

  @override
  String get noNewMessages => 'No new messages';

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get failedToResendMessage => 'Failed to resend message';

  @override
  String get retryingMessage => 'Retrying message...';

  @override
  String retryFailed(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get copyText => 'Copy text';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deleteMessageConfirmation =>
      'Are you sure you want to delete this message?';

  @override
  String get shareLocation => 'Share location';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nCoordinates: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR Location';

  @override
  String get locationShared => 'Location shared';

  @override
  String get refreshedContacts => 'Refreshed contacts';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String secondsAgo(int seconds) {
    return '${seconds}s ago';
  }

  @override
  String get sending => 'Sending...';

  @override
  String get sent => 'Sent';

  @override
  String get delivered => 'Delivered';

  @override
  String deliveredWithTime(int time) {
    return 'Delivered (${time}ms)';
  }

  @override
  String get failed => 'Failed';

  @override
  String get broadcast => 'Broadcast';

  @override
  String get sarMarkerFoundPerson => 'Found Person';

  @override
  String get sarMarkerFire => 'Fire Location';

  @override
  String get sarMarkerStagingArea => 'Staging Area';

  @override
  String get sarMarkerObject => 'Object Found';

  @override
  String get from => 'From';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get tapToViewOnMap => 'Tap to view on map';

  @override
  String get radioSettings => 'Radio Settings';

  @override
  String get frequencyMHz => 'Frequency (MHz)';

  @override
  String get frequencyExample => 'e.g., 869.618';

  @override
  String get bandwidth => 'Bandwidth';

  @override
  String get spreadingFactor => 'Spreading Factor';

  @override
  String get codingRate => 'Coding Rate';

  @override
  String get txPowerDbm => 'TX Power (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Max: $power dBm';
  }

  @override
  String get you => 'You';

  @override
  String get offlineVectorMaps => 'Offline Vector Maps';

  @override
  String get offlineVectorMapsDescription =>
      'Import and manage offline vector map tiles (MBTiles format) for use without internet connection';

  @override
  String get importMbtiles => 'Import MBTiles File';

  @override
  String get importMbtilesNote =>
      'Supports MBTiles files with vector tiles (PBF/MVT format). Geofabrik extracts work great!';

  @override
  String get noMbtilesFiles => 'No offline vector maps found';

  @override
  String get mbtilesImportedSuccessfully =>
      'MBTiles file imported successfully';

  @override
  String get failedToImportMbtiles => 'Failed to import MBTiles file';

  @override
  String get deleteMbtilesConfirmTitle => 'Delete Offline Map';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This will permanently remove the offline map.';
  }

  @override
  String get mbtilesDeletedSuccessfully => 'Offline map deleted successfully';

  @override
  String get failedToDeleteMbtiles => 'Failed to delete offline map';

  @override
  String get importExportCachedTiles => 'Import/Export Cached Tiles';

  @override
  String get importExportDescription =>
      'Backup, share, and restore downloaded map tiles between devices';

  @override
  String get exportTilesToFile => 'Export Tiles to File';

  @override
  String get importTilesFromFile => 'Import Tiles from File';

  @override
  String get selectExportLocation => 'Select Export Location';

  @override
  String get selectImportFile => 'Select Tile Archive';

  @override
  String get exportingTiles => 'Exporting tiles...';

  @override
  String get importingTiles => 'Importing tiles...';

  @override
  String exportSuccess(int count) {
    return 'Exported $count tiles successfully';
  }

  @override
  String importSuccess(int count) {
    return 'Imported $count stores successfully';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get exportNote =>
      'Creates a compressed archive (.fmtc) file that can be shared and imported on other devices.';

  @override
  String get importNote =>
      'Imports map tiles from a previously exported archive file. Tiles will be merged with existing cache.';

  @override
  String get noTilesToExport => 'No tiles available to export';

  @override
  String archiveContainsStores(int count) {
    return 'Archive contains $count stores';
  }

  @override
  String get vectorTiles => 'Vector Tiles';

  @override
  String get schema => 'Schema';

  @override
  String get unknown => 'Unknown';

  @override
  String get bounds => 'Bounds';

  @override
  String get onlineLayers => 'Online Layers';

  @override
  String get offlineLayers => 'Offline Layers';

  @override
  String get locationTrail => 'Location Trail';

  @override
  String get showTrailOnMap => 'Show Trail on Map';

  @override
  String get trailVisible => 'Trail is visible on the map';

  @override
  String get trailHiddenRecording => 'Trail is hidden (still recording)';

  @override
  String get duration => 'Duration';

  @override
  String get points => 'Points';

  @override
  String get clearTrail => 'Clear Trail';

  @override
  String get clearTrailQuestion => 'Clear Trail?';

  @override
  String get clearTrailConfirmation =>
      'Are you sure you want to clear the current location trail? This action cannot be undone.';

  @override
  String get noTrailRecorded => 'No trail recorded yet';

  @override
  String get startTrackingToRecord =>
      'Start location tracking to record your trail';

  @override
  String get trailControls => 'Trail Controls';

  @override
  String get exportTrailToGpx => 'Export Trail to GPX';

  @override
  String get importTrailFromGpx => 'Import Trail from GPX';

  @override
  String get trailExportedSuccessfully => 'Trail exported successfully!';

  @override
  String get failedToExportTrail => 'Failed to export trail';

  @override
  String failedToImportTrail(String error) {
    return 'Failed to import trail: $error';
  }

  @override
  String get importTrail => 'Import Trail';

  @override
  String importTrailQuestion(int pointCount) {
    return 'Import trail with $pointCount points?\n\nYou can replace your current trail or view it alongside.';
  }

  @override
  String get viewAlongside => 'View Alongside';

  @override
  String get replaceCurrent => 'Replace Current';

  @override
  String trailImported(int pointCount) {
    return 'Trail imported! ($pointCount points)';
  }

  @override
  String trailReplaced(int pointCount) {
    return 'Trail replaced! ($pointCount points)';
  }

  @override
  String get contactTrails => 'Contact Trails';

  @override
  String get showAllContactTrails => 'Show All Contact Trails';

  @override
  String get noContactsWithLocationHistory =>
      'No contacts with location history';

  @override
  String showingTrailsForContacts(int count) {
    return 'Showing trails for $count contacts';
  }

  @override
  String get individualContactTrails => 'Individual Contact Trails';

  @override
  String get deviceInformation => 'Device Information';

  @override
  String get bleName => 'BLE Name';

  @override
  String get meshName => 'Mesh Name';

  @override
  String get notSet => 'Not set';

  @override
  String get model => 'Model';

  @override
  String get version => 'Version';

  @override
  String get buildDate => 'Build Date';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Max Contacts';

  @override
  String get maxChannels => 'Max Channels';

  @override
  String get publicInfo => 'Public Info';

  @override
  String get meshNetworkName => 'Mesh Network Name';

  @override
  String get nameBroadcastInMesh => 'Name broadcast in mesh advertisements';

  @override
  String get telemetryAndLocationSharing => 'Telemetry & Location Sharing';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get noneUnknown => 'None/Unknown';

  @override
  String get chatNode => 'Chat Node';

  @override
  String get repeater => 'Repeater';

  @override
  String get roomChannel => 'Room/Channel';

  @override
  String typeNumber(int number) {
    return 'Type $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Copied $label to clipboard';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get sarTemplates => 'SAR Templates';

  @override
  String get manageSarTemplates => 'Manage cursor on target templates';

  @override
  String get addTemplate => 'Add Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get templateName => 'Template Name';

  @override
  String get templateNameHint => 'e.g. Found Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Import';

  @override
  String get exportToClipboard => 'Export';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Delete template \'$name\'?';
  }

  @override
  String get templateAdded => 'Template added';

  @override
  String get templateUpdated => 'Template updated';

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count templates',
      one: 'Imported 1 template',
      zero: 'No templates imported',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count templates to clipboard',
      one: 'Exported 1 template to clipboard',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetToDefaultsConfirmation =>
      'This will delete all custom templates and restore the 4 default templates. Continue?';

  @override
  String get reset => 'Reset';

  @override
  String get resetComplete => 'Templates reset to defaults';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Permissions';

  @override
  String get locationPermission => 'Location Permission';

  @override
  String get checking => 'Checking...';

  @override
  String get locationPermissionGrantedAlways => 'Granted (Always)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Granted (While In Use)';

  @override
  String get locationPermissionDeniedTapToRequest => 'Denied - Tap to request';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Permanently Denied - Open Settings';

  @override
  String get locationPermissionDialogContent =>
      'Location permission is permanently denied. Please enable it in your device settings to use GPS tracking and location sharing features.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get locationPermissionGranted => 'Location permission granted!';

  @override
  String get locationPermissionRequiredForGps =>
      'Location permission is required for GPS tracking and location sharing.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Location permission is already granted.';

  @override
  String get sarNavyBlue => 'SAR Navy Blue';

  @override
  String get sarNavyBlueDescription => 'Professional/Operations Mode';

  @override
  String get selectRecipient => 'Select Recipient';

  @override
  String get broadcastToAllNearby => 'Broadcast to all nearby';

  @override
  String get searchRecipients => 'Search recipients...';

  @override
  String get noContactsFound => 'No contacts found';

  @override
  String get noRoomsFound => 'No rooms found';

  @override
  String get noContactsOrRoomsAvailable => 'No contacts or rooms available';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'Messages will be sent to public channel';

  @override
  String get newMessage => 'New message';

  @override
  String get channel => 'Channel';

  @override
  String get samplePoliceLead => 'Police Lead';

  @override
  String get sampleDroneOperator => 'Drone Operator';

  @override
  String get sampleFirefighterAlpha => 'Firefighter';

  @override
  String get sampleMedicCharlie => 'Medic';

  @override
  String get sampleCommandDelta => 'Command';

  @override
  String get sampleFireEngine => 'Fire Engine';

  @override
  String get sampleAirSupport => 'Air Support';

  @override
  String get sampleBaseCoordinator => 'Base Coordinator';

  @override
  String get channelEmergency => 'Emergency';

  @override
  String get channelCoordination => 'Coordination';

  @override
  String get channelUpdates => 'Updates';

  @override
  String get sampleTeamMember => 'Sample Team Member';

  @override
  String get sampleScout => 'Sample Scout';

  @override
  String get sampleBase => 'Sample Base';

  @override
  String get sampleSearcher => 'Sample Searcher';

  @override
  String get sampleObjectBackpack => ' Backpack found - blue color';

  @override
  String get sampleObjectVehicle => ' Vehicle abandoned - check for owner';

  @override
  String get sampleObjectCamping => ' Camping equipment discovered';

  @override
  String get sampleObjectTrailMarker => ' Trail marker found off-path';

  @override
  String get sampleMsgAllTeamsCheckIn => 'All teams check in';

  @override
  String get sampleMsgWeatherUpdate => 'Weather update: Clear skies, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Base camp established at staging area';

  @override
  String get sampleMsgTeamAlpha => 'Team moving to sector 2';

  @override
  String get sampleMsgRadioCheck => 'Radio check - all stations respond';

  @override
  String get sampleMsgWaterSupply => 'Water supply available at checkpoint 3';

  @override
  String get sampleMsgTeamBravo => 'Team reporting: sector 1 clear';

  @override
  String get sampleMsgEtaRallyPoint => 'ETA to rally point: 15 minutes';

  @override
  String get sampleMsgSupplyDrop => 'Supply drop confirmed for 14:00';

  @override
  String get sampleMsgDroneSurvey => 'Drone survey completed - no findings';

  @override
  String get sampleMsgTeamCharlie => 'Team requesting backup';

  @override
  String get sampleMsgRadioDiscipline => 'All units: maintain radio discipline';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENT: Medical assistance needed at sector 4';

  @override
  String get sampleMsgAdultMale => ' Adult male, conscious';

  @override
  String get sampleMsgFireSpotted => 'Fire spotted - coordinates incoming';

  @override
  String get sampleMsgSpreadingRapidly => ' Spreading rapidly!';

  @override
  String get sampleMsgPriorityHelicopter => 'PRIORITY: Need helicopter support';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medical team en route to your location';

  @override
  String get sampleMsgEvacHelicopter => 'Evac helicopter ETA 10 minutes';

  @override
  String get sampleMsgEmergencyResolved => 'Emergency resolved - all clear';

  @override
  String get sampleMsgEmergencyStagingArea => ' Emergency staging area';

  @override
  String get sampleMsgEmergencyServices =>
      'Emergency services notified and responding';

  @override
  String get sampleAlphaTeamLead => 'Team Lead';

  @override
  String get sampleBravoScout => 'Scout';

  @override
  String get sampleCharlieMedic => 'Medic';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Support';

  @override
  String get sampleBaseCommand => 'Base Command';

  @override
  String get sampleFieldCoordinator => 'Field Coordinator';

  @override
  String get sampleMedicalTeam => 'Medical Team';

  @override
  String get mapDrawing => 'Map Drawing';

  @override
  String get navigateToDrawing => 'Navigate to Drawing';

  @override
  String get copyCoordinates => 'Copy Coordinates';

  @override
  String get hideFromMap => 'Hide from Map';

  @override
  String get lineDrawing => 'Line Drawing';

  @override
  String get rectangleDrawing => 'Rectangle Drawing';

  @override
  String get coordinatesCopiedToClipboard => 'Coordinates copied to clipboard';

  @override
  String get drawingShared => 'Map Drawing';

  @override
  String get drawingHidden => 'Drawing hidden from map';

  @override
  String alreadyShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already shared',
      one: '1 already shared',
    );
    return '$_temp0';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return 'Shared $count new drawing$plural';
  }

  @override
  String get shareDrawing => 'Share Drawing';

  @override
  String get shareWithAllNearbyDevices => 'Share with all nearby devices';

  @override
  String get shareToRoom => 'Share to Room';

  @override
  String get sendToPersistentStorage => 'Send to persistent room storage';

  @override
  String get deleteDrawingConfirm =>
      'Are you sure you want to delete this drawing?';

  @override
  String get drawingDeleted => 'Drawing deleted';

  @override
  String yourDrawingsCount(int count) {
    return 'Your Drawings ($count)';
  }

  @override
  String get shared => 'Shared';

  @override
  String get line => 'Line';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get currentVersion => 'Current';

  @override
  String get latestVersion => 'Latest';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get cadastralParcels => 'Cadastral Parcels';

  @override
  String get forestRoads => 'Forest Roads';

  @override
  String get showCadastralParcels => 'Show Cadastral Parcels';

  @override
  String get showForestRoads => 'Show Forest Roads';

  @override
  String get wmsOverlays => 'WMS Overlays';

  @override
  String get recentMessages => 'Recent Messages';

  @override
  String get addChannel => 'Add Channel';

  @override
  String get channelName => 'Channel Name';

  @override
  String get channelNameHint => 'e.g., Rescue Team Alpha';

  @override
  String get channelSecret => 'Channel Secret';

  @override
  String get channelSecretHint => 'Shared password for this channel';

  @override
  String get channelSecretHelp =>
      'This secret must be shared with all team members who need access to this channel';

  @override
  String get channelNameRequired => 'Channel name is required';

  @override
  String get channelNameTooLong => 'Channel name must be 31 characters or less';

  @override
  String get channelSecretRequired => 'Channel secret is required';

  @override
  String get channelSecretTooLong =>
      'Channel secret must be 32 characters or less';

  @override
  String get invalidAsciiCharacters => 'Only ASCII characters are allowed';

  @override
  String get channelCreatedSuccessfully => 'Channel created successfully';

  @override
  String channelCreationFailed(String error) {
    return 'Failed to create channel: $error';
  }

  @override
  String get allChannelSlotsInUse =>
      'All channel slots are in use (maximum 39 custom channels)';

  @override
  String get createChannel => 'Create Channel';
}
