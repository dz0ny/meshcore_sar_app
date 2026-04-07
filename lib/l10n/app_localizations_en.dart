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
  String get noDevicesFound => 'No devices found';

  @override
  String get scanAgain => 'Scan Again';

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
  String failedToAdvertise(String error) {
    return 'Failed to advertise: $error';
  }

  @override
  String get cancelReconnection => 'Cancel reconnection';

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
  String get disableMap => 'Disable Map';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

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
  String get resetPath => 'Reset Path (Re-route)';

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
  String get publicChannel => 'Public Channel';

  @override
  String get broadcastToAll => 'Broadcast to all nearby nodes (ephemeral)';

  @override
  String get storedPermanently => 'Stored permanently in room';

  @override
  String get notConnectedToDevice => 'Not connected to device';

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
  String get autoSend => 'Auto Send';

  @override
  String get autoSendDescription => 'Send via current path.';

  @override
  String get sendDirect => 'Send Direct';

  @override
  String get sendDirectDescription => 'Send directly to this contact.';

  @override
  String get sendFlood => 'Send Flood';

  @override
  String get sendFloodDescription => 'Send via all repeaters.';

  @override
  String get loggedIn => 'Logged In';

  @override
  String get noGpsData => 'No GPS data';

  @override
  String get distance => 'Distance';

  @override
  String directPingTimeout(String name) {
    return 'Direct ping timeout - retrying $name with flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping failed to $name - no response received';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis will remove the contact from both the app and the companion radio device.';
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
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permissions';

  @override
  String get telemetry => 'Telemetry';

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
  String get selectMapLayer => 'Select Map Layer';

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
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

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
  String deliveredToContacts(int delivered, int total) {
    return 'Delivered to $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'All delivered';

  @override
  String get recipientDetails => 'Recipient Details';

  @override
  String get pending => 'Pending';

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
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get onlineLayers => 'Online Layers';

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
  String get model => 'Model';

  @override
  String get version => 'Version';

  @override
  String get maxContacts => 'Max Contacts';

  @override
  String get maxChannels => 'Max Channels';

  @override
  String get publicInfo => 'Public Info';

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
  String get noRecipientsAvailable => 'No recipients available';

  @override
  String get noChannelsFound => 'No channels found';

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
  String get manualCoordinates => 'Manual Coordinates';

  @override
  String get enterCoordinatesManually => 'Enter coordinates manually';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get exampleCoordinates => 'Example: 46.0569, 14.5058';

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
  String get wmsOverlays => 'WMS Overlays';

  @override
  String get hikingTrails => 'Hiking Trails';

  @override
  String get mainRoads => 'Main Roads';

  @override
  String get houseNumbers => 'House Numbers';

  @override
  String get fireHazardZones => 'Fire Hazard Zones';

  @override
  String get historicalFires => 'Historical Fires';

  @override
  String get firebreaks => 'Firebreaks';

  @override
  String get krasFireZones => 'Kras Fire Zones';

  @override
  String get placeNames => 'Place Names';

  @override
  String get municipalityBorders => 'Municipality Borders';

  @override
  String get topographicMap => 'Topographic Map 1:25000';

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
  String get channelTypesInfo =>
      'Hash channels (#team): Secret auto-generated from name. Same name = same channel across devices.\n\nPrivate channels: Use explicit secret. Only those with the secret can join.';

  @override
  String get hashChannelInfo =>
      'Hash channel: Secret will be auto-generated from the channel name. Anyone using the same name will join the same channel.';

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
  String get deleteChannel => 'Delete Channel';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Are you sure you want to delete channel \"$channelName\"? This action cannot be undone.';
  }

  @override
  String get channelDeletedSuccessfully => 'Channel deleted successfully';

  @override
  String channelDeletionFailed(String error) {
    return 'Failed to delete channel: $error';
  }

  @override
  String get createChannel => 'Create Channel';

  @override
  String get wizardBack => 'Back';

  @override
  String get wizardSkip => 'Skip';

  @override
  String get wizardNext => 'Next';

  @override
  String get wizardGetStarted => 'Get Started';

  @override
  String get wizardWelcomeTitle => 'Welcome to MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'View Welcome Tutorial';

  @override
  String get allTeamContacts => 'All Team Contacts';

  @override
  String directMessagesInfo(int count) {
    return 'Direct messages with ACKs. Sent to $count team members.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR marker sent to $count contacts';
  }

  @override
  String get noContactsAvailable => 'No team contacts available';

  @override
  String get reply => 'Reply';

  @override
  String get technicalDetails => 'Technical details';

  @override
  String get messageTechnicalDetails => 'Message technical details';

  @override
  String get linkQuality => 'Link quality';

  @override
  String get delivery => 'Delivery';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Expected ACK tag';

  @override
  String get roundTrip => 'Round-trip';

  @override
  String get retryAttempt => 'Retry attempt';

  @override
  String get floodFallback => 'Flood fallback';

  @override
  String get identity => 'Identity';

  @override
  String get messageId => 'Message ID';

  @override
  String get sender => 'Sender';

  @override
  String get senderKey => 'Sender key';

  @override
  String get recipient => 'Recipient';

  @override
  String get recipientKey => 'Recipient key';

  @override
  String get voice => 'Voice';

  @override
  String get voiceId => 'Voice ID';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String get complete => 'Complete';

  @override
  String get rawDump => 'Raw dump';

  @override
  String get cannotRetryMissingRecipient =>
      'Cannot retry: recipient information missing';

  @override
  String get voiceUnavailable => 'Voice unavailable right now';

  @override
  String get requestingVoice => 'Requesting voice';

  @override
  String get device => 'device';

  @override
  String get change => 'Change';

  @override
  String get wizardOverviewDescription =>
      'This app combines MeshCore messaging, SAR field updates, discovery, mapping, and device tools in one place.';

  @override
  String get wizardOverviewFeature1 =>
      'Send direct, room, and channel messages from the main Messages tab.';

  @override
  String get wizardOverviewFeature2 =>
      'Share live location to a private channel, plus SAR markers, map drawings, voice clips, and images over the mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Connect over BLE, WiFi, or Serial, then manage the companion radio from inside the app.';

  @override
  String get wizardMessagingTitle => 'Messaging and Field Reports';

  @override
  String get wizardMessagingDescription =>
      'Messages are more than plain text here. The app already supports several operational payloads and transfer workflows.';

  @override
  String get wizardMessagingFeature1 =>
      'Send direct messages, room posts, and channel traffic from one composer.';

  @override
  String get wizardMessagingFeature2 =>
      'Create SAR updates and reusable SAR templates for common field reports.';

  @override
  String get wizardMessagingFeature3 =>
      'Transfer voice sessions and images, with progress and airtime estimates in the UI.';

  @override
  String get wizardConnectDeviceTitle => 'Connect device';

  @override
  String get wizardConnectDeviceDescription =>
      'Connect your MeshCore radio, choose a name, and apply a radio preset before continuing.';

  @override
  String get wizardSetupBadge => 'Setup';

  @override
  String get wizardOverviewBadge => 'Overview';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Connected to $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'No device connected yet';

  @override
  String get wizardSkipForNow => 'Skip for now';

  @override
  String get wizardDeviceNameLabel => 'Device name';

  @override
  String get wizardDeviceNameHelp =>
      'This name is advertised to other MeshCore users.';

  @override
  String get wizardConfigRegionLabel => 'Config region';

  @override
  String get wizardConfigRegionHelp =>
      'Uses the full official MeshCore preset list. Default is EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Make sure the selected preset matches your local radio regulations.';

  @override
  String get wizardPresetNote2 =>
      'The list matches the official MeshCore config tool preset feed.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) stays selected by default for onboarding.';

  @override
  String get wizardSaving => 'Saving...';

  @override
  String get wizardSaveAndContinue => 'Save and continue';

  @override
  String get wizardEnterDeviceName => 'Enter a device name before continuing.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Saved $deviceName with $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contacts, Rooms, and Repeaters';

  @override
  String get wizardNetworkDescription =>
      'The Contacts and Discovery flows help you find nearby nodes, store repeaters, and manage the routes you learn over time.';

  @override
  String get wizardNetworkFeature1 =>
      'Discover repeaters and sensors, then review team members, rooms, channels, and pending adverts in one list.';

  @override
  String get wizardNetworkFeature2 =>
      'Use smart ping, room login, learned paths, and route reset tools when connectivity gets messy.';

  @override
  String get wizardNetworkFeature3 =>
      'Add new repeaters right after you connect, then create channels and manage network destinations without leaving the app.';

  @override
  String get wizardMapOpsTitle => 'Map, Trails, and Shared Geometry';

  @override
  String get wizardMapOpsDescription =>
      'The app map is tied directly into messaging, tracking, and SAR overlays instead of being a separate viewer.';

  @override
  String get wizardMapOpsFeature1 =>
      'Track your own position, teammate locations, and share live location to a private channel from the channel menu.';

  @override
  String get wizardMapOpsFeature2 =>
      'Open drawings from messages, preview them inline, and remove them from the map when needed.';

  @override
  String get wizardMapOpsFeature3 =>
      'Use repeater map views and shared overlays to understand network reach in the field.';

  @override
  String get wizardToolsTitle => 'Tools Beyond Messaging';

  @override
  String get wizardToolsDescription =>
      'There is more here than the four main tabs. The app also includes configuration, diagnostics, and optional sensor workflows.';

  @override
  String get wizardToolsFeature1 =>
      'Open device config to change radio settings, telemetry, TX power, and companion details.';

  @override
  String get wizardToolsFeature2 =>
      'Enable the Sensors tab when you want watched sensor dashboards and quick refresh actions.';

  @override
  String get wizardToolsFeature3 =>
      'Use live traffic, packet logs, spectrum scan, and developer diagnostics when troubleshooting the mesh.';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => 'In Sensors';

  @override
  String get contactAddToSensors => 'Add to Sensors';

  @override
  String get contactSetPath => 'Set path';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName added to Sensors';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Failed to clear route: $error';
  }

  @override
  String get contactRouteCleared => 'Route cleared';

  @override
  String contactRouteSet(String route) {
    return 'Route set: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Failed to set route: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'ACK timeout';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Payload';

  @override
  String get hops => 'Hops';

  @override
  String get hashSize => 'Hash size';

  @override
  String get pathBytes => 'Path bytes';

  @override
  String get selectedPath => 'Selected path';

  @override
  String get estimatedTx => 'Estimated tx';

  @override
  String get senderToReceipt => 'Sender to receipt';

  @override
  String get receivedCopies => 'Received copies';

  @override
  String get retryCause => 'Retry cause';

  @override
  String get retryMode => 'Retry mode';

  @override
  String get retryResult => 'Retry result';

  @override
  String get lastRetry => 'Last retry';

  @override
  String get rxPackets => 'RX packets';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Rate';

  @override
  String get window => 'Window';

  @override
  String get posttxDelay => 'Post-tx delay';

  @override
  String get bandpass => 'Band-pass';

  @override
  String get bandpassFilterVoice => 'Band-pass filter voice';

  @override
  String get active => 'Active';

  @override
  String get addContact => 'Add Contact';

  @override
  String get all => 'All';

  @override
  String get clearAllLabel => 'Clear all';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get clearRoute => 'Clear Route';

  @override
  String get clearMessages => 'Clear Messages';

  @override
  String get clearScale => 'Clear scale';

  @override
  String get clearDiscoveries => 'Clear discoveries';

  @override
  String get clearOnlineTraceDatabase => 'Clear online trace database';

  @override
  String get clearAllChannels => 'Clear all channels';

  @override
  String get clearAllContacts => 'Clear all contacts';

  @override
  String get clearChannels => 'Clear channels';

  @override
  String get clearContacts => 'Clear contacts';

  @override
  String get clearPathOnMaxRetry => 'Clear path on max retry';

  @override
  String get create => 'Create';

  @override
  String get custom => 'Custom';

  @override
  String get defaultValue => 'Default';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get editName => 'Edit name';

  @override
  String get open => 'Open';

  @override
  String get paste => 'Paste';

  @override
  String get preview => 'Preview';

  @override
  String get remove => 'Remove';

  @override
  String get rename => 'Rename';

  @override
  String get resolveAll => 'Resolve all';

  @override
  String get send => 'Send';

  @override
  String get sendAnyway => 'Send anyway';

  @override
  String get share => 'Share';

  @override
  String get trace => 'Trace';

  @override
  String get discovery => 'Discovery';

  @override
  String get discoverRepeaters => 'Discover repeaters';

  @override
  String get discoverSensors => 'Discover sensors';

  @override
  String get repeaterDiscoverySent => 'Repeater discovery sent';

  @override
  String get sensorDiscoverySent => 'Sensor discovery sent';

  @override
  String get clearedPendingDiscoveries => 'Cleared pending discoveries.';

  @override
  String get autoDiscovery => 'Auto discovery';

  @override
  String get enableAutomaticAdding => 'Enable automatic adding';

  @override
  String get autoaddRepeaters => 'Auto-add repeaters';

  @override
  String get autoaddRoomServers => 'Auto-add room servers';

  @override
  String get autoaddSensors => 'Auto-add sensors';

  @override
  String get autoaddUsers => 'Auto-add users';

  @override
  String get overwriteOldestWhenFull => 'Overwrite oldest when full';

  @override
  String get storage => 'Storage';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get profiles => 'Profiles';

  @override
  String get favourites => 'Favourites';

  @override
  String get sensors => 'Sensors';

  @override
  String get others => 'Others';

  @override
  String get gpsModule => 'GPS Module';

  @override
  String get liveTraffic => 'Live Traffic';

  @override
  String get repeatersMap => 'Repeaters Map';

  @override
  String get blePacketLogs => 'BLE Packet Logs';

  @override
  String get onlineTraceDatabase => 'Online trace database';

  @override
  String get routePathByteSize => 'Route path byte size';

  @override
  String get messageNotifications => 'Message notifications';

  @override
  String get sarAlerts => 'SAR alerts';

  @override
  String get discoveryNotifications => 'Discovery notifications';

  @override
  String get updateNotifications => 'Update notifications';

  @override
  String get muteWhileAppIsOpen => 'Mute while app is open';

  @override
  String get disableContacts => 'Disable Contacts';

  @override
  String get enableSensorsTab => 'Enable Sensors tab';

  @override
  String get enableProfiles => 'Enable Profiles';

  @override
  String get nearestRepeaterFallback => 'Nearest repeater fallback';

  @override
  String get deleteAllStoredMessageHistory =>
      'Delete all stored message history';

  @override
  String get messageFontSize => 'Message font size';

  @override
  String get rotateMapWithHeading => 'Rotate map with heading';

  @override
  String get showMapDebugInfo => 'Show map debug info';

  @override
  String get openMapInFullscreen => 'Open map in fullscreen';

  @override
  String get showSarMarkersLabel => 'Show SAR markers';

  @override
  String get hideRepeatersOnMap => 'Hide repeaters on map';

  @override
  String get setMapScale => 'Set map scale';

  @override
  String get customMapScaleSaved => 'Custom map scale saved';

  @override
  String get voiceBitrate => 'Voice bitrate';

  @override
  String get voiceCompressor => 'Voice compressor';

  @override
  String get voiceLimiter => 'Voice limiter';

  @override
  String get micAutoGain => 'Mic auto gain';

  @override
  String get echoCancellation => 'Echo cancellation';

  @override
  String get noiseSuppression => 'Noise suppression';

  @override
  String get trimSilenceInVoiceMessages => 'Trim silence in voice messages';

  @override
  String get compressor => 'Compressor';

  @override
  String get limiter => 'Limiter';

  @override
  String get autoGain => 'Auto gain';

  @override
  String get echoCancel => 'Echo cancel';

  @override
  String get noiseSuppress => 'Noise suppress';

  @override
  String get silenceTrim => 'Silence trim';

  @override
  String get maxImageSize => 'Max image size';

  @override
  String get imageCompression => 'Image compression';

  @override
  String get grayscale => 'Grayscale';

  @override
  String get ultraMode => 'Ultra mode';

  @override
  String get fastPrivateGpsUpdates => 'Fast private GPS updates';

  @override
  String get movementThreshold => 'Movement threshold';

  @override
  String get fastGpsMovementThreshold => 'Fast GPS movement threshold';

  @override
  String get fastGpsActiveuseInterval => 'Fast GPS active-use interval';

  @override
  String get activeuseUpdateInterval => 'Active-use update interval';

  @override
  String get repeatNearbyTraffic => 'Repeat nearby traffic';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Relay through repeaters across the mesh';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Nearby only, without repeater flooding';

  @override
  String get multihop => 'Multi-hop';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get renameProfile => 'Rename Profile';

  @override
  String get newProfile => 'New Profile';

  @override
  String get manageProfiles => 'Manage profiles';

  @override
  String get enableProfilesToStartManagingThem =>
      'Enable profiles to start managing them.';

  @override
  String get openMessage => 'Open message';

  @override
  String get jumpToTheRelatedSarMessage => 'Jump to the related SAR message';

  @override
  String get removeSarMarker => 'Remove SAR marker';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Please select a destination to send SAR marker';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR marker broadcast to public channel';

  @override
  String get sarMarkerSentToRoom => 'SAR marker sent to room';

  @override
  String get loadFromGallery => 'Load from gallery';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get team => 'Team';

  @override
  String get found => 'Found';

  @override
  String get staging => 'Staging';

  @override
  String get object => 'Object';

  @override
  String get quiet => 'Quiet';

  @override
  String get busy => 'Busy';

  @override
  String get searchMessages => 'Search messages';

  @override
  String get sendImageFromGallery => 'Send image from gallery';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get allMessages => 'All messages';

  @override
  String get sendToPublicChannel => 'Send to Public Channel?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Select marker type and destination';

  @override
  String get noDestinationsAvailableLabel => 'No destinations available';

  @override
  String get image => 'Image';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get segments => 'Segments';

  @override
  String get transfers => 'Transfers';

  @override
  String get downloadedBy => 'Downloaded by';

  @override
  String get saveDiscoverySettings => 'Save discovery settings';

  @override
  String get savePublicInfo => 'Save public info';

  @override
  String get saveRadioSettings => 'Save radio settings';

  @override
  String get savePath => 'Save Path';

  @override
  String get wipeDeviceData => 'Wipe device data';

  @override
  String get wipeDevice => 'Wipe device';

  @override
  String get destructiveDeviceActions => 'Destructive device actions.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Choose a preset or fine-tune custom radio settings.';

  @override
  String get used => 'Used';

  @override
  String get total => 'Total';

  @override
  String get renameValue => 'Rename value';

  @override
  String get customizeFields => 'Customize fields';

  @override
  String get livePreview => 'Live preview';

  @override
  String get refreshSchedule => 'Refresh schedule';

  @override
  String get noResponse => 'No response';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Pick a relay or node to watch in Sensors.';

  @override
  String get publicKeyLabel => 'Public key';

  @override
  String get alreadyInContacts => 'Already in contacts';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Connect to a device before adding contacts';

  @override
  String get fromContacts => 'From contacts';

  @override
  String get onlineOnly => 'Online only';

  @override
  String get inBoth => 'In both';

  @override
  String get source => 'Source';

  @override
  String get allMessagesCleared => 'All messages cleared';

  @override
  String get onlineTraceDatabaseCleared => 'Online trace database cleared';

  @override
  String get packetLogsCleared => 'Packet logs cleared';

  @override
  String get hexDataCopiedToClipboard => 'Hex data copied to clipboard';

  @override
  String get developerModeEnabled => 'Developer mode enabled';

  @override
  String get developerModeDisabled => 'Developer mode disabled';

  @override
  String get clipboardIsEmpty => 'Clipboard is empty';

  @override
  String get contactImported => 'Contact imported';

  @override
  String get contactLinkCopiedToClipboard => 'Contact link copied to clipboard';

  @override
  String get failedToExportContact => 'Failed to export contact';

  @override
  String get noLogsToExport => 'No logs to export';

  @override
  String get exportAsCsv => 'Export as CSV';

  @override
  String get exportAsText => 'Export as Text';

  @override
  String get receivedRfc3339 => 'Received (RFC3339)';

  @override
  String get buildTime => 'Build Time';

  @override
  String get downloadUrlNotAvailable => 'Download URL not available';

  @override
  String get cannotOpenDownloadUrl => 'Cannot open download URL';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Update check is only available on Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'You are running the latest version';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Update available but download URL not found';

  @override
  String get startTictactoe => 'Start Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe unavailable';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: opponent unknown';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: waiting for start';

  @override
  String get acceptsShareLinks => 'Accepts share links';

  @override
  String get supportsRawHex => 'Supports raw hex';

  @override
  String get clipboardfriendly => 'Clipboard-friendly';

  @override
  String get captured => 'Captured';

  @override
  String get size => 'Size';

  @override
  String get noCustomChannelsToClear => 'No custom channels to clear.';

  @override
  String get noDeviceContactsToClear => 'No device contacts to clear.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Add';

  @override
  String get addAdditionalDetails => 'Add additional details';

  @override
  String get addPeer => 'Add Peer';

  @override
  String get addPeerManually => 'Add peer manually';

  @override
  String addedToContacts(String name) {
    return '$name added to contacts';
  }

  @override
  String addedToSensors(String name) {
    return '$name added to Sensors';
  }

  @override
  String get allowAll => 'Allow all';

  @override
  String get anonymousRxStats => 'Anonymous RX stats';

  @override
  String get appearance => 'Appearance';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Base telemetry';

  @override
  String get blePin => 'BLE PIN';

  @override
  String get buzzerAlerts => 'Buzzer alerts';

  @override
  String get cancelImageReceive => 'Cancel image receive';

  @override
  String get choose => 'Choose';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Choose which tabs and contact sections to show';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearLiveView => 'Clear live view';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get clearOfflineCache => 'Clear offline cache?';

  @override
  String get clearOverlay => 'Clear overlay';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Clear route only after all retries fail';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Codec, bitrate, and audio processing';

  @override
  String get connectByIpAddress => 'Connect by IP address';

  @override
  String get controlWhichAlertsYouReceive => 'Control which alerts you receive';

  @override
  String get copyFullHex => 'Copy full hex';

  @override
  String get copyRawResponse => 'Copy raw response';

  @override
  String get couldNotLoadMetHistory => 'Could not load MET history';

  @override
  String customizeSensor(String name) {
    return 'Customize $name';
  }

  @override
  String get data => 'Data';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String deleteStyleConfirm(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Delete this $type?';
  }

  @override
  String get deny => 'Deny';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get deviceSettings => 'Device Settings';

  @override
  String get deviceTimeSynced => 'Device time synced to this phone.';

  @override
  String get disableFastGpsPublishing => 'Disable fast GPS publishing';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Display, markers, and trace database';

  @override
  String get download => 'Download';

  @override
  String get environmentalTelemetry => 'Environmental telemetry';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Error checking for updates: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Error opening download: $error';
  }

  @override
  String get exportLogs => 'Export logs';

  @override
  String get extraAggressiveAvifCompression =>
      'Extra-aggressive AVIF compression';

  @override
  String failedToAddContact(String error) {
    return 'Failed to add contact: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Failed to add $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Failed to clear channels: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Failed to clear contacts: $error';
  }

  @override
  String get failedToConnectViaSerial => 'Failed to connect via serial';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Failed to load preview image: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Failed to load trace: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Failed to send SAR marker: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Failed to set buzzer mode: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Failed to set GPS mode: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Failed to sync device time: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Failed to wipe device data: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Fast GPS target channel';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Fast updates, thresholds, and permissions';

  @override
  String get fetchingCatalog => 'Fetching catalog...';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get fifteenSeconds => '15 seconds';

  @override
  String get filterByDirection => 'Filter by direction';

  @override
  String get finish => 'Finish';

  @override
  String get fiveMinutes => '5 minutes';

  @override
  String get fiveSeconds => '5 seconds';

  @override
  String get fix => 'Fix';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'GPS advert policy';

  @override
  String get gpsAndLocation => 'GPS & Location';

  @override
  String get gpsDiagnostics => 'GPS diagnostics';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Help';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Hidden';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'How the radio auto-adds discovered nodes.';

  @override
  String get images => 'Images';

  @override
  String get importProfile => 'Import profile';

  @override
  String get lastFix => 'Last fix';

  @override
  String get latest => 'Latest';

  @override
  String get latitude => 'Latitude';

  @override
  String get loadASavedRegion => 'Load a saved region';

  @override
  String get loading => 'Loading';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Location sharing, hardware, and update interval.';

  @override
  String get locationTelemetry => 'Location telemetry';

  @override
  String get lockDestination => 'Lock destination';

  @override
  String get longitude => 'Longitude';

  @override
  String get mapStyle => 'Map Style';

  @override
  String get max => 'Max';

  @override
  String get maxZoom => 'Max Zoom';

  @override
  String get messaging => 'Messaging';

  @override
  String get metHistory => 'MET history';

  @override
  String get min => 'Min';

  @override
  String get minZoom => 'Min Zoom';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveUp => 'Move up';

  @override
  String get multiAckMode => 'Multi-ACK mode';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Multi-device workspace management';

  @override
  String get myLocation => 'My location';

  @override
  String get nameAndTelemetryShared =>
      'Name and telemetry shared with other devices.';

  @override
  String newVersionAvailable(String version) {
    return 'New version: $version';
  }

  @override
  String get newer => 'Newer';

  @override
  String get noNeighboursFound => 'No neighbours found';

  @override
  String get noServersFound => 'No servers found';

  @override
  String get notSet => 'Not set';

  @override
  String get notifications => 'Notifications';

  @override
  String get offZeroSeconds => 'Off (0 s)';

  @override
  String get offlineMaps => 'Offline Maps';

  @override
  String get older => 'Older';

  @override
  String get oneByteMode0 => '1 byte (mode 0)';

  @override
  String get oneHour => '1 hour';

  @override
  String get oneMinute => '1 minute';

  @override
  String get openPacketLogs => 'Open packet logs';

  @override
  String get packetTypeHelp => 'Packet type help';

  @override
  String get pasteShareLinkOrHexAdvert => 'Paste a share link or hex advert';

  @override
  String get pathHash => 'Path hash';

  @override
  String get pathSize => 'Path size';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Polygon';

  @override
  String get rawResponseCopied => 'Raw response copied';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Resend through nearest repeater on failure';

  @override
  String get resolveContact => 'Resolve contact';

  @override
  String get routingRetriesAndDestinationLock =>
      'Routing, retries, and destination lock';

  @override
  String get samples => 'Samples';

  @override
  String get satellites => 'Satellites';

  @override
  String get saving => 'Saving...';

  @override
  String get search => 'Search';

  @override
  String get searchByNameOrToken => 'Search by name or token';

  @override
  String get searchDiscoveredNodes => 'Search discovered nodes';

  @override
  String get searchInCurrentFilter => 'Search in current filter';

  @override
  String get searchLogs => 'Search logs...';

  @override
  String get searchSensors => 'Search sensors';

  @override
  String get searchThisSection => 'Search this section';

  @override
  String get selectedRelays => 'Selected relays';

  @override
  String get sensor => 'Sensor';

  @override
  String serialError(String error) {
    return 'Serial error: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Set Path for $name';
  }

  @override
  String get shareLiveGps => 'Share live GPS';

  @override
  String get shareMyTiles => 'Share my tiles';

  @override
  String get sharingLocationFromPhone =>
      'Sharing location on this channel from the phone.';

  @override
  String get sharingLocationFromRadio =>
      'Sharing location on this channel from the radio.';

  @override
  String signalDbm(String rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview => 'Size, compression, and preview';

  @override
  String get skip => 'Skip';

  @override
  String get smallerFileSize => 'Smaller file size';

  @override
  String get sort => 'Sort';

  @override
  String get stoppedSharingLocation =>
      'Stopped sharing location on this channel.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Suppress notifications while in foreground';

  @override
  String get tabsAndNavigation => 'Tabs & Navigation';

  @override
  String get templatesAndTutorials => 'Templates and tutorials';

  @override
  String get tenMinutes => '10 minutes';

  @override
  String get tenSeconds => '10 seconds';

  @override
  String get testSendUpdate => 'Test send update';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Theme, language, and display preferences';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get thirtySeconds => '30 seconds';

  @override
  String get threeBytesMode2 => '3 bytes (mode 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Traffic stats, message history, and developer tools';

  @override
  String get twoBytesMode1 => '2 bytes (mode 1)';

  @override
  String get twoMinutes => '2 minutes';

  @override
  String get undo => 'Undo';

  @override
  String get updated => 'Updated';

  @override
  String get useContactFlags => 'Use contact flags';

  @override
  String get useSavedCoordinates => 'Use saved coordinates';

  @override
  String get view => 'View';

  @override
  String get viewNeighbours => 'View Neighbours';

  @override
  String get viewPublicStats => 'View public stats';

  @override
  String get setRegionScope => 'Set region scope';

  @override
  String get regionScope => 'Region scope';

  @override
  String get regionScopeNone => 'None (global)';

  @override
  String get clearRegionScope => 'Clear scope';

  @override
  String get regionScopeWarning =>
      'Only repeaters allowing this region will forward.';

  @override
  String get discoverRegions => 'Discover from repeaters';

  @override
  String get discoveringRegions => 'Discovering regions...';

  @override
  String get enterRegionName => 'Region name (e.g. auckland)';

  @override
  String get noRegionsFound => 'No regions found on this repeater.';

  @override
  String regionScopeSet(String name) {
    return 'Region scope set to $name';
  }

  @override
  String get regionScopeCleared => 'Region scope cleared';
}
