// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Μηνύματα';

  @override
  String get contacts => 'Επαφές';

  @override
  String get map => 'Χάρτης';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get connect => 'Σύνδεση';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get noDevicesFound => 'Δεν βρέθηκαν συσκευές';

  @override
  String get scanAgain => 'Σάρωση ξανά';

  @override
  String get deviceNotConnected => 'Η συσκευή δεν είναι συνδεδεμένη';

  @override
  String get locationPermissionDenied => 'Η άδεια τοποθεσίας απορρίφθηκε';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Η άδεια τοποθεσίας απορρίφθηκε μόνιμα. Ενεργοποιήστε την στις Ρυθμίσεις.';

  @override
  String get locationPermissionRequired =>
      'Απαιτείται άδεια τοποθεσίας για παρακολούθηση GPS και συντονισμό ομάδας. Μπορείτε να την ενεργοποιήσετε αργότερα στις Ρυθμίσεις.';

  @override
  String get locationServicesDisabled =>
      'Οι υπηρεσίες τοποθεσίας είναι απενεργοποιημένες. Ενεργοποιήστε τις στις Ρυθμίσεις.';

  @override
  String get failedToGetGpsLocation => 'Αποτυχία λήψης τοποθεσίας GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Αποτυχία μετάδοσης: $error';
  }

  @override
  String get cancelReconnection => 'Ακύρωση επανασύνδεσης';

  @override
  String get general => 'Γενικά';

  @override
  String get theme => 'Θέμα';

  @override
  String get chooseTheme => 'Επιλογή θέματος';

  @override
  String get light => 'Φωτεινό';

  @override
  String get dark => 'Σκούρο';

  @override
  String get blueLightTheme => 'Μπλε φωτεινό θέμα';

  @override
  String get blueDarkTheme => 'Μπλε σκούρο θέμα';

  @override
  String get sarRed => 'SAR Κόκκινο';

  @override
  String get alertEmergencyMode => 'Λειτουργία συναγερμού/έκτακτης ανάγκης';

  @override
  String get sarGreen => 'SAR Πράσινο';

  @override
  String get safeAllClearMode => 'Λειτουργία ασφαλείας/όλα καθαρά';

  @override
  String get autoSystem => 'Αυτόματο (σύστημα)';

  @override
  String get followSystemTheme => 'Ακολουθεί το θέμα συστήματος';

  @override
  String get showRxTxIndicators => 'Εμφάνιση ενδείξεων RX/TX';

  @override
  String get disableMap => 'Απενεργοποίηση χάρτη';

  @override
  String get language => 'Γλώσσα';

  @override
  String get chooseLanguage => 'Επιλογή γλώσσας';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get about => 'Σχετικά';

  @override
  String get appVersion => 'Έκδοση εφαρμογής';

  @override
  String get aboutMeshCoreSar => 'Σχετικά με το MeshCore SAR';

  @override
  String get aboutDescription =>
      'Εφαρμογή Έρευνας και Διάσωσης σχεδιασμένη για ομάδες απόκρισης έκτακτης ανάγκης. Περιλαμβάνει:\n\n• Δικτύωση BLE mesh για επικοινωνία συσκευή με συσκευή\n• Χάρτες εκτός σύνδεσης με πολλαπλά επίπεδα\n• Παρακολούθηση μελών ομάδας σε πραγματικό χρόνο\n• Τακτικούς δείκτες SAR (εντοπισμένο άτομο, φωτιά, σημείο συγκέντρωσης)\n• Διαχείριση επαφών και μηνυμάτων\n• Παρακολούθηση GPS με πυξίδα κατεύθυνσης\n• Cache πλακιδίων χάρτη για χρήση εκτός σύνδεσης';

  @override
  String get technologiesUsed => 'Χρησιμοποιούμενες τεχνολογίες:';

  @override
  String get technologiesList =>
      '• Flutter για ανάπτυξη πολλαπλών πλατφορμών\n• BLE (Bluetooth Low Energy) για δικτύωση mesh\n• OpenStreetMap για χαρτογράφηση\n• Provider για διαχείριση κατάστασης\n• SharedPreferences για τοπική αποθήκευση';

  @override
  String get moreInfo => 'Περισσότερες πληροφορίες';

  @override
  String get packageName => 'Όνομα πακέτου';

  @override
  String get sampleData => 'Δείγματα δεδομένων';

  @override
  String get sampleDataDescription =>
      'Φόρτωση ή εκκαθάριση δοκιμαστικών επαφών, μηνυμάτων καναλιού και δεικτών SAR για έλεγχο';

  @override
  String get loadSampleData => 'Φόρτωση δειγμάτων δεδομένων';

  @override
  String get clearAllData => 'Εκκαθάριση όλων των δεδομένων';

  @override
  String get clearAllDataConfirmTitle => 'Εκκαθάριση όλων των δεδομένων';

  @override
  String get clearAllDataConfirmMessage =>
      'Αυτό θα διαγράψει όλες τις επαφές και τους δείκτες SAR. Είστε βέβαιοι;';

  @override
  String get clear => 'Εκκαθάριση';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Φορτώθηκαν $teamCount μέλη ομάδας, $channelCount κανάλια, $sarCount δείκτες SAR, $messageCount μηνύματα';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Αποτυχία φόρτωσης δειγμάτων δεδομένων: $error';
  }

  @override
  String get allDataCleared => 'Όλα τα δεδομένα διαγράφηκαν';

  @override
  String get failedToStartBackgroundTracking =>
      'Αποτυχία εκκίνησης παρακολούθησης στο παρασκήνιο. Ελέγξτε τα δικαιώματα και τη σύνδεση BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Μετάδοση τοποθεσίας: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Το προεπιλεγμένο PIN για συσκευές χωρίς οθόνη είναι 123456. Πρόβλημα στη σύζευξη; Ξεχάστε τη συσκευή Bluetooth από τις ρυθμίσεις συστήματος.';

  @override
  String get noMessagesYet => 'Δεν υπάρχουν ακόμη μηνύματα';

  @override
  String get pullDownToSync =>
      'Τραβήξτε προς τα κάτω για συγχρονισμό μηνυμάτων';

  @override
  String get deleteContact => 'Διαγραφή επαφής';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get viewOnMap => 'Προβολή στον χάρτη';

  @override
  String get refresh => 'Ανανέωση';

  @override
  String get resetPath => 'Επαναφορά διαδρομής (νέα δρομολόγηση)';

  @override
  String copiedToClipboard(String label) {
    return 'Το $label αντιγράφηκε στο πρόχειρο';
  }

  @override
  String get pleaseEnterPassword => 'Παρακαλώ εισαγάγετε κωδικό';

  @override
  String failedToSyncContacts(String error) {
    return 'Αποτυχία συγχρονισμού επαφών: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Η σύνδεση ολοκληρώθηκε με επιτυχία! Αναμονή για μηνύματα δωματίου...';

  @override
  String get loginFailed => 'Αποτυχία σύνδεσης - λανθασμένος κωδικός';

  @override
  String loggingIn(String roomName) {
    return 'Σύνδεση στο $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Αποτυχία αποστολής σύνδεσης: $error';
  }

  @override
  String get lowLocationAccuracy => 'Χαμηλή ακρίβεια τοποθεσίας';

  @override
  String get continue_ => 'Συνέχεια';

  @override
  String get sendSarMarker => 'Αποστολή δείκτη SAR';

  @override
  String get deleteDrawing => 'Διαγραφή σχεδίου';

  @override
  String get drawingTools => 'Εργαλεία σχεδίασης';

  @override
  String get drawLine => 'Σχεδίαση γραμμής';

  @override
  String get drawLineDesc => 'Σχεδίαση ελεύθερης γραμμής στον χάρτη';

  @override
  String get drawRectangle => 'Σχεδίαση ορθογωνίου';

  @override
  String get drawRectangleDesc => 'Σχεδίαση ορθογώνιας περιοχής στον χάρτη';

  @override
  String get measureDistance => 'Μέτρηση απόστασης';

  @override
  String get measureDistanceDesc =>
      'Παρατεταμένο πάτημα σε δύο σημεία για μέτρηση';

  @override
  String get clearMeasurement => 'Εκκαθάριση μέτρησης';

  @override
  String distanceLabel(String distance) {
    return 'Απόσταση: $distance';
  }

  @override
  String get longPressForSecondPoint =>
      'Παρατεταμένο πάτημα για δεύτερο σημείο';

  @override
  String get longPressToStartMeasurement =>
      'Παρατεταμένο πάτημα για ορισμό πρώτου σημείου';

  @override
  String get longPressToStartNewMeasurement =>
      'Παρατεταμένο πάτημα για νέα μέτρηση';

  @override
  String get shareDrawings => 'Κοινοποίηση σχεδίων';

  @override
  String get clearAllDrawings => 'Εκκαθάριση όλων των σχεδίων';

  @override
  String get completeLine => 'Ολοκλήρωση γραμμής';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Μετάδοση $count σχεδίου$plural στην ομάδα';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Αφαίρεση όλων των $count σχεδίων$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Διαγραφή όλων των $count σχεδίων$plural από τον χάρτη;';
  }

  @override
  String get drawing => 'Σχέδιο';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Κοινοποίηση $count σχεδίου$plural';
  }

  @override
  String get showReceivedDrawings => 'Εμφάνιση ληφθέντων σχεδίων';

  @override
  String get showingAllDrawings => 'Εμφανίζονται όλα τα σχέδια';

  @override
  String get showingOnlyYourDrawings => 'Εμφανίζονται μόνο τα δικά σας σχέδια';

  @override
  String get showSarMarkers => 'Εμφάνιση δεικτών SAR';

  @override
  String get showingSarMarkers => 'Εμφανίζονται δείκτες SAR';

  @override
  String get hidingSarMarkers => 'Απόκρυψη δεικτών SAR';

  @override
  String get clearAll => 'Εκκαθάριση όλων';

  @override
  String get publicChannel => 'Δημόσιο κανάλι';

  @override
  String get broadcastToAll =>
      'Μετάδοση σε όλους τους κοντινούς κόμβους (προσωρινό)';

  @override
  String get storedPermanently => 'Αποθηκευμένο μόνιμα στο δωμάτιο';

  @override
  String get notConnectedToDevice => 'Δεν υπάρχει σύνδεση με συσκευή';

  @override
  String get typeYourMessage => 'Πληκτρολογήστε το μήνυμά σας...';

  @override
  String get quickLocationMarker => 'Γρήγορος δείκτης τοποθεσίας';

  @override
  String get markerType => 'Τύπος δείκτη';

  @override
  String get sendTo => 'Αποστολή σε';

  @override
  String get noDestinationsAvailable => 'Δεν υπάρχουν διαθέσιμοι προορισμοί.';

  @override
  String get selectDestination => 'Επιλέξτε προορισμό...';

  @override
  String get ephemeralBroadcastInfo =>
      'Προσωρινό: Μετάδοση μόνο ασύρματα. Δεν αποθηκεύεται - οι κόμβοι πρέπει να είναι συνδεδεμένοι.';

  @override
  String get persistentRoomInfo =>
      'Μόνιμο: Αποθηκεύεται αμετάβλητα στο δωμάτιο. Συγχρονίζεται αυτόματα και διατηρείται εκτός σύνδεσης.';

  @override
  String get location => 'Τοποθεσία';

  @override
  String get fromMap => 'Από χάρτη';

  @override
  String get gettingLocation => 'Λήψη τοποθεσίας...';

  @override
  String get locationError => 'Σφάλμα τοποθεσίας';

  @override
  String get retry => 'Επανάληψη';

  @override
  String get refreshLocation => 'Ανανέωση τοποθεσίας';

  @override
  String accuracyMeters(int accuracy) {
    return 'Ακρίβεια: ±$accuracyμ';
  }

  @override
  String get notesOptional => 'Σημειώσεις (προαιρετικό)';

  @override
  String get addAdditionalInformation => 'Προσθέστε επιπλέον πληροφορίες...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Η ακρίβεια τοποθεσίας είναι ±$accuracyμ. Αυτό ίσως δεν είναι αρκετά ακριβές για επιχειρήσεις SAR.\n\nΣυνέχεια ούτως ή άλλως;';
  }

  @override
  String get loginToRoom => 'Σύνδεση στο δωμάτιο';

  @override
  String get enterPasswordInfo =>
      'Εισαγάγετε τον κωδικό για πρόσβαση σε αυτό το δωμάτιο. Ο κωδικός θα αποθηκευτεί για μελλοντική χρήση.';

  @override
  String get password => 'Κωδικός πρόσβασης';

  @override
  String get enterRoomPassword => 'Εισαγάγετε κωδικό δωματίου';

  @override
  String get loggingInDots => 'Σύνδεση...';

  @override
  String get login => 'Σύνδεση';

  @override
  String failedToAddRoom(String error) {
    return 'Αποτυχία προσθήκης δωματίου στη συσκευή: $error\n\nΤο δωμάτιο ίσως δεν έχει μεταδοθεί ακόμη.\nΠεριμένετε να αρχίσει να εκπέμπει.';
  }

  @override
  String get direct => 'Άμεσο';

  @override
  String get flood => 'Πλημμυρικό';

  @override
  String get autoSend => 'Αυτόματη αποστολή';

  @override
  String get autoSendDescription => 'Αποστολή μέσω τρέχουσας διαδρομής.';

  @override
  String get sendDirect => 'Άμεση αποστολή';

  @override
  String get sendDirectDescription => 'Αποστολή απευθείας σε αυτήν την επαφή.';

  @override
  String get sendFlood => 'Αποστολή πλημμύρας';

  @override
  String get sendFloodDescription => 'Αποστολή μέσω όλων των αναμεταδοτών.';

  @override
  String get loggedIn => 'Συνδεδεμένος';

  @override
  String get noGpsData => 'Δεν υπάρχουν δεδομένα GPS';

  @override
  String get distance => 'Απόσταση';

  @override
  String directPingTimeout(String name) {
    return 'Λήξη χρόνου άμεσου ping - επανάληψη προς $name με flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Αποτυχία ping προς $name - δεν ελήφθη απάντηση';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Είστε βέβαιοι ότι θέλετε να διαγράψετε το \"$name\";\n\nΑυτό θα αφαιρέσει την επαφή τόσο από την εφαρμογή όσο και από τη συνοδευτική συσκευή radio.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Αποτυχία αφαίρεσης επαφής: $error';
  }

  @override
  String get type => 'Τύπος';

  @override
  String get publicKey => 'Δημόσιο κλειδί';

  @override
  String get lastSeen => 'Τελευταία εμφάνιση';

  @override
  String get yes => 'Ναι';

  @override
  String get no => 'Όχι';

  @override
  String get permissions => 'Δικαιώματα';

  @override
  String get telemetry => 'Τηλεμετρία';

  @override
  String get voltage => 'Τάση';

  @override
  String get battery => 'Μπαταρία';

  @override
  String get temperature => 'Θερμοκρασία';

  @override
  String get humidity => 'Υγρασία';

  @override
  String get pressure => 'Πίεση';

  @override
  String get gpsTelemetry => 'GPS (τηλεμετρία)';

  @override
  String get reLoginToRoom => 'Επανασύνδεση στο δωμάτιο';

  @override
  String get heading => 'Κατεύθυνση';

  @override
  String get elevation => 'Υψόμετρο';

  @override
  String get accuracy => 'Ακρίβεια';

  @override
  String get bearing => 'Πορεία';

  @override
  String get direction => 'Κατεύθυνση';

  @override
  String get filterMarkers => 'Φιλτράρισμα δεικτών';

  @override
  String get filterMarkersTooltip => 'Φιλτράρισμα δεικτών';

  @override
  String get contactsFilter => 'Επαφές';

  @override
  String get repeatersFilter => 'Αναμεταδότες';

  @override
  String get sarMarkers => 'Δείκτες SAR';

  @override
  String get foundPerson => 'Εντοπισμένο άτομο';

  @override
  String get fire => 'Φωτιά';

  @override
  String get stagingArea => 'Σημείο συγκέντρωσης';

  @override
  String get showAll => 'Εμφάνιση όλων';

  @override
  String get locationUnavailable => 'Η τοποθεσία δεν είναι διαθέσιμη';

  @override
  String get ahead => 'μπροστά';

  @override
  String degreesRight(int degrees) {
    return '$degrees° δεξιά';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° αριστερά';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Γεωγρ. πλάτος: $latitude Γεωγρ. μήκος: $longitude';
  }

  @override
  String get noContactsYet => 'Δεν υπάρχουν ακόμη επαφές';

  @override
  String get connectToDeviceToLoadContacts =>
      'Συνδεθείτε σε συσκευή για φόρτωση επαφών';

  @override
  String get teamMembers => 'Μέλη ομάδας';

  @override
  String get repeaters => 'Αναμεταδότες';

  @override
  String get rooms => 'Δωμάτια';

  @override
  String get channels => 'Κανάλια';

  @override
  String get selectMapLayer => 'Επιλογή επιπέδου χάρτη';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Δορυφορικός ESRI';

  @override
  String get googleHybrid => 'Υβριδικός Google';

  @override
  String get googleRoadmap => 'Οδικός χάρτης Google';

  @override
  String get googleTerrain => 'Ανάγλυφο Google';

  @override
  String get dragToPosition => 'Σύρετε στη θέση';

  @override
  String get createSarMarker => 'Δημιουργία δείκτη SAR';

  @override
  String get compass => 'Πυξίδα';

  @override
  String get navigationAndContacts => 'Πλοήγηση και επαφές';

  @override
  String get sarAlert => 'ΣΥΝΑΓΕΡΜΟΣ SAR';

  @override
  String get textCopiedToClipboard => 'Το κείμενο αντιγράφηκε στο πρόχειρο';

  @override
  String get cannotReplySenderMissing =>
      'Αδυναμία απάντησης: λείπουν πληροφορίες αποστολέα';

  @override
  String get cannotReplyContactNotFound =>
      'Αδυναμία απάντησης: η επαφή δεν βρέθηκε';

  @override
  String get copyText => 'Αντιγραφή κειμένου';

  @override
  String get saveAsTemplate => 'Αποθήκευση ως πρότυπο';

  @override
  String get templateSaved => 'Το πρότυπο αποθηκεύτηκε επιτυχώς';

  @override
  String get templateAlreadyExists => 'Υπάρχει ήδη πρότυπο με αυτό το emoji';

  @override
  String get deleteMessage => 'Διαγραφή μηνύματος';

  @override
  String get deleteMessageConfirmation =>
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε αυτό το μήνυμα;';

  @override
  String get shareLocation => 'Κοινοποίηση τοποθεσίας';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nΣυντεταγμένες: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Τοποθεσία SAR';

  @override
  String get justNow => 'Μόλις τώρα';

  @override
  String minutesAgo(int minutes) {
    return 'πριν από $minutesλ';
  }

  @override
  String hoursAgo(int hours) {
    return 'πριν από $hoursω';
  }

  @override
  String daysAgo(int days) {
    return 'πριν από $daysη';
  }

  @override
  String secondsAgo(int seconds) {
    return 'πριν από $secondsδ';
  }

  @override
  String get sending => 'Αποστολή...';

  @override
  String get sent => 'Στάλθηκε';

  @override
  String get delivered => 'Παραδόθηκε';

  @override
  String deliveredWithTime(int time) {
    return 'Παραδόθηκε (${time}ms)';
  }

  @override
  String get failed => 'Απέτυχε';

  @override
  String get broadcast => 'Μετάδοση';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Παραδόθηκε σε $delivered/$total επαφές';
  }

  @override
  String get allDelivered => 'Όλα παραδόθηκαν';

  @override
  String get recipientDetails => 'Λεπτομέρειες παραλήπτη';

  @override
  String get pending => 'Σε εκκρεμότητα';

  @override
  String get sarMarkerFoundPerson => 'Εντοπισμένο άτομο';

  @override
  String get sarMarkerFire => 'Σημείο φωτιάς';

  @override
  String get sarMarkerStagingArea => 'Σημείο συγκέντρωσης';

  @override
  String get sarMarkerObject => 'Εντοπισμένο αντικείμενο';

  @override
  String get from => 'Από';

  @override
  String get coordinates => 'Συντεταγμένες';

  @override
  String get tapToViewOnMap => 'Πατήστε για προβολή στον χάρτη';

  @override
  String get radioSettings => 'Ρυθμίσεις radio';

  @override
  String get frequencyMHz => 'Συχνότητα (MHz)';

  @override
  String get bandwidth => 'Εύρος ζώνης';

  @override
  String get spreadingFactor => 'Συντελεστής εξάπλωσης';

  @override
  String get codingRate => 'Ρυθμός κωδικοποίησης';

  @override
  String get txPowerDbm => 'Ισχύς TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Μέγ.: $power dBm';
  }

  @override
  String get you => 'Εσείς';

  @override
  String exportFailed(String error) {
    return 'Η εξαγωγή απέτυχε: $error';
  }

  @override
  String importFailed(String error) {
    return 'Η εισαγωγή απέτυχε: $error';
  }

  @override
  String get unknown => 'Άγνωστο';

  @override
  String get onlineLayers => 'Επίπεδα online';

  @override
  String get locationTrail => 'Ίχνος τοποθεσίας';

  @override
  String get showTrailOnMap => 'Εμφάνιση ίχνους στον χάρτη';

  @override
  String get trailVisible => 'Το ίχνος είναι ορατό στον χάρτη';

  @override
  String get trailHiddenRecording =>
      'Το ίχνος είναι κρυφό (συνεχίζεται η καταγραφή)';

  @override
  String get duration => 'Διάρκεια';

  @override
  String get points => 'Σημεία';

  @override
  String get clearTrail => 'Εκκαθάριση ίχνους';

  @override
  String get clearTrailQuestion => 'Εκκαθάριση ίχνους;';

  @override
  String get clearTrailConfirmation =>
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε το τρέχον ίχνος τοποθεσίας; Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String get noTrailRecorded => 'Δεν έχει καταγραφεί ακόμη ίχνος';

  @override
  String get startTrackingToRecord =>
      'Ξεκινήστε παρακολούθηση τοποθεσίας για καταγραφή ίχνους';

  @override
  String get trailControls => 'Στοιχεία ελέγχου ίχνους';

  @override
  String get model => 'Μοντέλο';

  @override
  String get version => 'Έκδοση';

  @override
  String get maxContacts => 'Μέγιστες επαφές';

  @override
  String get maxChannels => 'Μέγιστα κανάλια';

  @override
  String get publicInfo => 'Δημόσιες πληροφορίες';

  @override
  String get useCurrentLocation => 'Χρήση τρέχουσας τοποθεσίας';

  @override
  String get noneUnknown => 'Κανένα/Άγνωστο';

  @override
  String get chatNode => 'Κόμβος συνομιλίας';

  @override
  String get repeater => 'Αναμεταδότης';

  @override
  String get roomChannel => 'Δωμάτιο/Κανάλι';

  @override
  String typeNumber(int number) {
    return 'Τύπος $number';
  }

  @override
  String failedToSave(String error) {
    return 'Αποτυχία αποθήκευσης: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Αποτυχία λήψης τοποθεσίας: $error';
  }

  @override
  String get sarTemplates => 'Πρότυπα SAR';

  @override
  String get addTemplate => 'Προσθήκη προτύπου';

  @override
  String get editTemplate => 'Επεξεργασία προτύπου';

  @override
  String get deleteTemplate => 'Διαγραφή προτύπου';

  @override
  String get templateName => 'Όνομα προτύπου';

  @override
  String get templateNameHint => 'π.χ. Εντοπισμένο άτομο';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Το emoji είναι υποχρεωτικό';

  @override
  String get nameRequired => 'Το όνομα είναι υποχρεωτικό';

  @override
  String get templateDescription => 'Περιγραφή (προαιρετική)';

  @override
  String get templateDescriptionHint => 'Προσθέστε επιπλέον πληροφορίες...';

  @override
  String get templateColor => 'Χρώμα';

  @override
  String get previewFormat => 'Προεπισκόπηση (μορφή μηνύματος SAR)';

  @override
  String get importFromClipboard => 'Εισαγωγή';

  @override
  String get exportToClipboard => 'Εξαγωγή';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Διαγραφή προτύπου «$name»;';
  }

  @override
  String get templateAdded => 'Το πρότυπο προστέθηκε';

  @override
  String get templateUpdated => 'Το πρότυπο ενημερώθηκε';

  @override
  String get templateDeleted => 'Το πρότυπο διαγράφηκε';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εισήχθησαν $count πρότυπα',
      one: 'Εισήχθη 1 πρότυπο',
      zero: 'Δεν εισήχθησαν πρότυπα',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εξήχθησαν $count πρότυπα στο πρόχειρο',
      one: 'Εξήχθη 1 πρότυπο στο πρόχειρο',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Επαναφορά προεπιλογών';

  @override
  String get resetToDefaultsConfirmation =>
      'Αυτό θα διαγράψει όλα τα προσαρμοσμένα πρότυπα και θα επαναφέρει τα 4 προεπιλεγμένα πρότυπα. Συνέχεια;';

  @override
  String get reset => 'Επαναφορά';

  @override
  String get resetComplete => 'Τα πρότυπα επανήλθαν στις προεπιλογές';

  @override
  String get noTemplates => 'Δεν υπάρχουν διαθέσιμα πρότυπα';

  @override
  String get tapAddToCreate =>
      'Πατήστε + για να δημιουργήσετε το πρώτο σας πρότυπο';

  @override
  String get ok => 'ΟΚ';

  @override
  String get locationPermission => 'Άδεια τοποθεσίας';

  @override
  String get checking => 'Έλεγχος...';

  @override
  String get locationPermissionGrantedAlways => 'Δόθηκε (πάντα)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Δόθηκε (κατά τη χρήση)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Απορρίφθηκε - πατήστε για αίτημα';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Μόνιμα απορριφθείσα - άνοιγμα ρυθμίσεων';

  @override
  String get locationPermissionDialogContent =>
      'Η άδεια τοποθεσίας έχει απορριφθεί μόνιμα. Ενεργοποιήστε την από τις ρυθμίσεις της συσκευής σας για να χρησιμοποιήσετε παρακολούθηση GPS και κοινοποίηση τοποθεσίας.';

  @override
  String get openSettings => 'Άνοιγμα ρυθμίσεων';

  @override
  String get locationPermissionGranted => 'Η άδεια τοποθεσίας δόθηκε!';

  @override
  String get locationPermissionRequiredForGps =>
      'Απαιτείται άδεια τοποθεσίας για παρακολούθηση GPS και κοινοποίηση τοποθεσίας.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Η άδεια τοποθεσίας έχει ήδη δοθεί.';

  @override
  String get sarNavyBlue => 'SAR Ναυτικό μπλε';

  @override
  String get sarNavyBlueDescription => 'Επαγγελματική/Επιχειρησιακή λειτουργία';

  @override
  String get selectRecipient => 'Επιλογή παραλήπτη';

  @override
  String get broadcastToAllNearby => 'Μετάδοση σε όλους τους κοντινούς';

  @override
  String get searchRecipients => 'Αναζήτηση παραληπτών...';

  @override
  String get noContactsFound => 'Δεν βρέθηκαν επαφές';

  @override
  String get noRoomsFound => 'Δεν βρέθηκαν δωμάτια';

  @override
  String get noRecipientsAvailable => 'Δεν υπάρχουν διαθέσιμοι παραλήπτες';

  @override
  String get noChannelsFound => 'Δεν βρέθηκαν κανάλια';

  @override
  String get newMessage => 'Νέο μήνυμα';

  @override
  String get channel => 'Κανάλι';

  @override
  String get samplePoliceLead => 'Επικεφαλής αστυνομίας';

  @override
  String get sampleDroneOperator => 'Χειριστής drone';

  @override
  String get sampleFirefighterAlpha => 'Πυροσβέστης';

  @override
  String get sampleMedicCharlie => 'Διασώστης';

  @override
  String get sampleCommandDelta => 'Διοίκηση';

  @override
  String get sampleFireEngine => 'Πυροσβεστικό όχημα';

  @override
  String get sampleAirSupport => 'Εναέρια υποστήριξη';

  @override
  String get sampleBaseCoordinator => 'Συντονιστής βάσης';

  @override
  String get channelEmergency => 'Έκτακτη ανάγκη';

  @override
  String get channelCoordination => 'Συντονισμός';

  @override
  String get channelUpdates => 'Ενημερώσεις';

  @override
  String get sampleTeamMember => 'Δοκιμαστικό μέλος ομάδας';

  @override
  String get sampleScout => 'Δοκιμαστικός ανιχνευτής';

  @override
  String get sampleBase => 'Δοκιμαστική βάση';

  @override
  String get sampleSearcher => 'Δοκιμαστικός ερευνητής';

  @override
  String get sampleObjectBackpack => ' Βρέθηκε σακίδιο - μπλε χρώμα';

  @override
  String get sampleObjectVehicle =>
      ' Εγκαταλελειμμένο όχημα - έλεγχος για ιδιοκτήτη';

  @override
  String get sampleObjectCamping => ' Εντοπίστηκε εξοπλισμός κατασκήνωσης';

  @override
  String get sampleObjectTrailMarker =>
      ' Βρέθηκε σημάδι μονοπατιού εκτός διαδρομής';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Όλες οι ομάδες, κάντε check-in';

  @override
  String get sampleMsgWeatherUpdate =>
      'Ενημέρωση καιρού: Αίθριος ουρανός, θερμ. 18°C';

  @override
  String get sampleMsgBaseCamp =>
      'Η βάση εγκαταστάθηκε στο σημείο συγκέντρωσης';

  @override
  String get sampleMsgTeamAlpha => 'Η ομάδα κινείται προς τον τομέα 2';

  @override
  String get sampleMsgRadioCheck =>
      'Έλεγχος ασυρμάτου - όλοι οι σταθμοί να απαντήσουν';

  @override
  String get sampleMsgWaterSupply => 'Διαθέσιμο νερό στο σημείο ελέγχου 3';

  @override
  String get sampleMsgTeamBravo => 'Αναφορά ομάδας: ο τομέας 1 είναι καθαρός';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Εκτιμώμενη άφιξη στο σημείο συγκέντρωσης: 15 λεπτά';

  @override
  String get sampleMsgSupplyDrop =>
      'Η ρίψη εφοδίων επιβεβαιώθηκε για τις 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Η έρευνα με drone ολοκληρώθηκε - δεν βρέθηκε κάτι';

  @override
  String get sampleMsgTeamCharlie => 'Η ομάδα ζητά ενισχύσεις';

  @override
  String get sampleMsgRadioDiscipline =>
      'Όλες οι μονάδες: τηρείτε πειθαρχία ασυρμάτου';

  @override
  String get sampleMsgUrgentMedical =>
      'ΕΠΕΙΓΟΝ: Απαιτείται ιατρική βοήθεια στον τομέα 4';

  @override
  String get sampleMsgAdultMale => ' Ενήλικος άνδρας, σε συνείδηση';

  @override
  String get sampleMsgFireSpotted =>
      'Εντοπίστηκε φωτιά - ακολουθούν συντεταγμένες';

  @override
  String get sampleMsgSpreadingRapidly => ' Εξαπλώνεται γρήγορα!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'ΠΡΟΤΕΡΑΙΟΤΗΤΑ: Απαιτείται υποστήριξη ελικοπτέρου';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Η ιατρική ομάδα κατευθύνεται στη θέση σας';

  @override
  String get sampleMsgEvacHelicopter => 'Ελικόπτερο εκκένωσης σε 10 λεπτά';

  @override
  String get sampleMsgEmergencyResolved =>
      'Το περιστατικό επιλύθηκε - όλα καθαρά';

  @override
  String get sampleMsgEmergencyStagingArea =>
      ' Χώρος συγκέντρωσης έκτακτης ανάγκης';

  @override
  String get sampleMsgEmergencyServices =>
      'Οι υπηρεσίες έκτακτης ανάγκης ειδοποιήθηκαν και ανταποκρίνονται';

  @override
  String get sampleAlphaTeamLead => 'Αρχηγός ομάδας';

  @override
  String get sampleBravoScout => 'Ανιχνευτής';

  @override
  String get sampleCharlieMedic => 'Διασώστης';

  @override
  String get sampleDeltaNavigator => 'Πλοηγός';

  @override
  String get sampleEchoSupport => 'Υποστήριξη';

  @override
  String get sampleBaseCommand => 'Διοίκηση βάσης';

  @override
  String get sampleFieldCoordinator => 'Συντονιστής πεδίου';

  @override
  String get sampleMedicalTeam => 'Ιατρική ομάδα';

  @override
  String get mapDrawing => 'Σχέδιο χάρτη';

  @override
  String get navigateToDrawing => 'Πλοήγηση προς το σχέδιο';

  @override
  String get copyCoordinates => 'Αντιγραφή συντεταγμένων';

  @override
  String get hideFromMap => 'Απόκρυψη από χάρτη';

  @override
  String get lineDrawing => 'Σχέδιο γραμμής';

  @override
  String get rectangleDrawing => 'Σχέδιο ορθογωνίου';

  @override
  String get manualCoordinates => 'Χειροκίνητες συντεταγμένες';

  @override
  String get enterCoordinatesManually => 'Εισαγωγή συντεταγμένων χειροκίνητα';

  @override
  String get latitudeLabel => 'Γεωγραφικό πλάτος';

  @override
  String get longitudeLabel => 'Γεωγραφικό μήκος';

  @override
  String get exampleCoordinates => 'Παράδειγμα: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Κοινοποίηση σχεδίου';

  @override
  String get shareWithAllNearbyDevices =>
      'Κοινοποίηση σε όλες τις κοντινές συσκευές';

  @override
  String get shareToRoom => 'Κοινοποίηση στο δωμάτιο';

  @override
  String get sendToPersistentStorage =>
      'Αποστολή σε μόνιμη αποθήκευση δωματίου';

  @override
  String get deleteDrawingConfirm =>
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε αυτό το σχέδιο;';

  @override
  String get drawingDeleted => 'Το σχέδιο διαγράφηκε';

  @override
  String yourDrawingsCount(int count) {
    return 'Τα σχέδιά σας ($count)';
  }

  @override
  String get shared => 'Κοινοποιημένο';

  @override
  String get line => 'Γραμμή';

  @override
  String get rectangle => 'Ορθογώνιο';

  @override
  String get updateAvailable => 'Διαθέσιμη ενημέρωση';

  @override
  String get currentVersion => 'Τρέχουσα';

  @override
  String get latestVersion => 'Τελευταία';

  @override
  String get downloadUpdate => 'Λήψη';

  @override
  String get updateLater => 'Αργότερα';

  @override
  String get cadastralParcels => 'Κτηματολογικά τεμάχια';

  @override
  String get forestRoads => 'Δασικοί δρόμοι';

  @override
  String get wmsOverlays => 'Επικαλύψεις WMS';

  @override
  String get hikingTrails => 'Πεζοπορικά μονοπάτια';

  @override
  String get mainRoads => 'Κύριοι δρόμοι';

  @override
  String get houseNumbers => 'Αριθμοί κτιρίων';

  @override
  String get fireHazardZones => 'Ζώνες κινδύνου πυρκαγιάς';

  @override
  String get historicalFires => 'Ιστορικές πυρκαγιές';

  @override
  String get firebreaks => 'Αντιπυρικές ζώνες';

  @override
  String get krasFireZones => 'Ζώνες πυρκαγιάς Κρας';

  @override
  String get placeNames => 'Τοπωνύμια';

  @override
  String get municipalityBorders => 'Όρια δήμων';

  @override
  String get topographicMap => 'Τοπογραφικός χάρτης 1:25000';

  @override
  String get recentMessages => 'Πρόσφατα μηνύματα';

  @override
  String get addChannel => 'Προσθήκη καναλιού';

  @override
  String get channelName => 'Όνομα καναλιού';

  @override
  String get channelNameHint => 'π.χ. Ομάδα Διάσωσης Άλφα';

  @override
  String get channelSecret => 'Μυστικό καναλιού';

  @override
  String get channelSecretHint => 'Κοινός κωδικός για αυτό το κανάλι';

  @override
  String get channelSecretHelp =>
      'Αυτό το μυστικό πρέπει να είναι κοινό σε όλα τα μέλη της ομάδας που χρειάζονται πρόσβαση σε αυτό το κανάλι';

  @override
  String get channelTypesInfo =>
      'Κανάλια hash (#team): Το μυστικό δημιουργείται αυτόματα από το όνομα. Ίδιο όνομα = ίδιο κανάλι σε όλες τις συσκευές.\n\nΙδιωτικά κανάλια: Χρησιμοποιήστε ρητό μυστικό. Μόνο όσοι το γνωρίζουν μπορούν να συμμετάσχουν.';

  @override
  String get hashChannelInfo =>
      'Κανάλι hash: Το μυστικό θα δημιουργηθεί αυτόματα από το όνομα του καναλιού. Όποιος χρησιμοποιεί το ίδιο όνομα θα μπει στο ίδιο κανάλι.';

  @override
  String get channelNameRequired => 'Το όνομα καναλιού είναι υποχρεωτικό';

  @override
  String get channelNameTooLong =>
      'Το όνομα καναλιού πρέπει να έχει έως 31 χαρακτήρες';

  @override
  String get channelSecretRequired => 'Το μυστικό καναλιού είναι υποχρεωτικό';

  @override
  String get channelSecretTooLong =>
      'Το μυστικό καναλιού πρέπει να έχει έως 32 χαρακτήρες';

  @override
  String get invalidAsciiCharacters => 'Επιτρέπονται μόνο χαρακτήρες ASCII';

  @override
  String get channelCreatedSuccessfully => 'Το κανάλι δημιουργήθηκε επιτυχώς';

  @override
  String channelCreationFailed(String error) {
    return 'Αποτυχία δημιουργίας καναλιού: $error';
  }

  @override
  String get deleteChannel => 'Διαγραφή καναλιού';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Είστε βέβαιοι ότι θέλετε να διαγράψετε το κανάλι \"$channelName\"; Αυτή η ενέργεια δεν αναιρείται.';
  }

  @override
  String get channelDeletedSuccessfully => 'Το κανάλι διαγράφηκε επιτυχώς';

  @override
  String channelDeletionFailed(String error) {
    return 'Αποτυχία διαγραφής καναλιού: $error';
  }

  @override
  String get createChannel => 'Δημιουργία καναλιού';

  @override
  String get wizardBack => 'Πίσω';

  @override
  String get wizardSkip => 'Παράλειψη';

  @override
  String get wizardNext => 'Επόμενο';

  @override
  String get wizardGetStarted => 'Ξεκινήστε';

  @override
  String get wizardWelcomeTitle => 'Καλώς ήρθατε στο MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Προβολή οδηγού καλωσορίσματος';

  @override
  String get allTeamContacts => 'Όλες οι επαφές ομάδας';

  @override
  String directMessagesInfo(int count) {
    return 'Άμεσα μηνύματα με ACK. Στάλθηκαν σε $count μέλη ομάδας.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Ο δείκτης SAR στάλθηκε σε $count επαφές';
  }

  @override
  String get noContactsAvailable => 'Δεν υπάρχουν διαθέσιμες επαφές ομάδας';

  @override
  String get reply => 'Απάντηση';

  @override
  String get technicalDetails => 'Τεχνικές λεπτομέρειες';

  @override
  String get messageTechnicalDetails => 'Τεχνικές λεπτομέρειες μηνύματος';

  @override
  String get linkQuality => 'Ποιότητα σύνδεσης';

  @override
  String get delivery => 'Παράδοση';

  @override
  String get status => 'Κατάσταση';

  @override
  String get expectedAckTag => 'Αναμενόμενη ετικέτα ACK';

  @override
  String get roundTrip => 'Χρόνος μετ\' επιστροφής';

  @override
  String get retryAttempt => 'Απόπειρα επανάληψης';

  @override
  String get floodFallback => 'Εφεδρική πλημμύρα';

  @override
  String get identity => 'Ταυτότητα';

  @override
  String get messageId => 'Αναγνωριστικό μηνύματος';

  @override
  String get sender => 'Αποστολέας';

  @override
  String get senderKey => 'Κλειδί αποστολέα';

  @override
  String get recipient => 'Παραλήπτης';

  @override
  String get recipientKey => 'Κλειδί παραλήπτη';

  @override
  String get voice => 'Φωνή';

  @override
  String get voiceId => 'Αναγνωριστικό φωνής';

  @override
  String get envelope => 'Φάκελος';

  @override
  String get sessionProgress => 'Πρόοδος συνεδρίας';

  @override
  String get complete => 'Ολοκληρώθηκε';

  @override
  String get rawDump => 'Ακατέργαστα δεδομένα';

  @override
  String get cannotRetryMissingRecipient =>
      'Δεν είναι δυνατή η επανάληψη: λείπουν πληροφορίες παραλήπτη';

  @override
  String get voiceUnavailable => 'Η φωνή δεν είναι διαθέσιμη αυτή τη στιγμή';

  @override
  String get requestingVoice => 'Αίτηση φωνής';

  @override
  String get device => 'συσκευή';

  @override
  String get change => 'Αλλαγή';

  @override
  String get wizardOverviewDescription =>
      'Αυτή η εφαρμογή συνδυάζει μηνύματα MeshCore, ενημερώσεις πεδίου SAR, χαρτογράφηση και εργαλεία συσκευής σε ένα σημείο.';

  @override
  String get wizardOverviewFeature1 =>
      'Στείλτε άμεσα μηνύματα, δημοσιεύσεις δωματίου και μηνύματα καναλιού από την κύρια καρτέλα Μηνύματα.';

  @override
  String get wizardOverviewFeature2 =>
      'Μοιραστείτε δείκτες SAR, σχεδιάσεις χάρτη, ηχητικά αποσπάσματα και εικόνες μέσω του mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Συνδεθείτε μέσω BLE ή TCP και στη συνέχεια διαχειριστείτε το συνοδευτικό ραδιόφωνο μέσα από την εφαρμογή.';

  @override
  String get wizardMessagingTitle => 'Μηνύματα και αναφορές πεδίου';

  @override
  String get wizardMessagingDescription =>
      'Τα μηνύματα εδώ είναι κάτι περισσότερο από απλό κείμενο. Η εφαρμογή υποστηρίζει ήδη πολλαπλά επιχειρησιακά φορτία και ροές μεταφοράς.';

  @override
  String get wizardMessagingFeature1 =>
      'Στείλτε άμεσα μηνύματα, δημοσιεύσεις δωματίου και κίνηση καναλιού από έναν μόνο συντάκτη.';

  @override
  String get wizardMessagingFeature2 =>
      'Δημιουργήστε ενημερώσεις SAR και επαναχρησιμοποιήσιμα πρότυπα SAR για συνηθισμένες αναφορές πεδίου.';

  @override
  String get wizardMessagingFeature3 =>
      'Μεταφέρετε φωνητικές συνεδρίες και εικόνες, με ένδειξη προόδου και εκτιμήσεις χρόνου εκπομπής στο περιβάλλον.';

  @override
  String get wizardConnectDeviceTitle => 'Σύνδεση συσκευής';

  @override
  String get wizardConnectDeviceDescription =>
      'Συνδέστε το ραδιόφωνο MeshCore, επιλέξτε όνομα και εφαρμόστε μια προρύθμιση ραδιοφώνου πριν συνεχίσετε.';

  @override
  String get wizardSetupBadge => 'Ρύθμιση';

  @override
  String get wizardOverviewBadge => 'Επισκόπηση';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Συνδέθηκε με το $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Δεν έχει συνδεθεί ακόμη συσκευή';

  @override
  String get wizardSkipForNow => 'Παράλειψη προς το παρόν';

  @override
  String get wizardDeviceNameLabel => 'Όνομα συσκευής';

  @override
  String get wizardDeviceNameHelp =>
      'Αυτό το όνομα ανακοινώνεται σε άλλους χρήστες του MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Περιοχή ρύθμισης';

  @override
  String get wizardConfigRegionHelp =>
      'Χρησιμοποιεί την πλήρη επίσημη λίστα προρυθμίσεων MeshCore. Η προεπιλογή είναι EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Βεβαιωθείτε ότι η επιλεγμένη προρύθμιση ταιριάζει με τους τοπικούς ραδιοφωνικούς κανονισμούς.';

  @override
  String get wizardPresetNote2 =>
      'Η λίστα αντιστοιχεί στην επίσημη ροή προρυθμίσεων του εργαλείου ρύθμισης MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'Το EU/UK (Narrow) παραμένει επιλεγμένο από προεπιλογή κατά την αρχική ρύθμιση.';

  @override
  String get wizardSaving => 'Αποθήκευση...';

  @override
  String get wizardSaveAndContinue => 'Αποθήκευση και συνέχεια';

  @override
  String get wizardEnterDeviceName =>
      'Εισαγάγετε όνομα συσκευής πριν συνεχίσετε.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Αποθηκεύτηκε το $deviceName με $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Επαφές, δωμάτια και αναμεταδότες';

  @override
  String get wizardNetworkDescription =>
      'Η καρτέλα Επαφές οργανώνει το δίκτυο που ανακαλύπτετε και τις διαδρομές που μαθαίνετε με τον χρόνο.';

  @override
  String get wizardNetworkFeature1 =>
      'Ελέγξτε μέλη ομάδας, αναμεταδότες, δωμάτια, κανάλια και εκκρεμείς ανακοινώσεις σε μία λίστα.';

  @override
  String get wizardNetworkFeature2 =>
      'Χρησιμοποιήστε smart ping, σύνδεση σε δωμάτια, μαθημένες διαδρομές και εργαλεία επαναφοράς διαδρομών όταν η συνδεσιμότητα γίνεται χαοτική.';

  @override
  String get wizardNetworkFeature3 =>
      'Δημιουργήστε κανάλια και διαχειριστείτε προορισμούς δικτύου χωρίς να φύγετε από την εφαρμογή.';

  @override
  String get wizardMapOpsTitle => 'Χάρτης, ίχνη και κοινόχρηστη γεωμετρία';

  @override
  String get wizardMapOpsDescription =>
      'Ο χάρτης της εφαρμογής συνδέεται άμεσα με τα μηνύματα, την παρακολούθηση και τα επικαλύμματα SAR αντί να είναι ξεχωριστός προβολέας.';

  @override
  String get wizardMapOpsFeature1 =>
      'Παρακολουθήστε τη θέση σας, τις τοποθεσίες της ομάδας και τα ίχνη κίνησης στον χάρτη.';

  @override
  String get wizardMapOpsFeature2 =>
      'Ανοίξτε σχεδιάσεις από μηνύματα, προεπισκοπήστε τες επιτόπου και αφαιρέστε τες από τον χάρτη όταν χρειάζεται.';

  @override
  String get wizardMapOpsFeature3 =>
      'Χρησιμοποιήστε προβολές χάρτη αναμεταδοτών και κοινόχρηστα επικαλύμματα για να κατανοήσετε την εμβέλεια του δικτύου στο πεδίο.';

  @override
  String get wizardToolsTitle => 'Εργαλεία πέρα από τα μηνύματα';

  @override
  String get wizardToolsDescription =>
      'Υπάρχουν περισσότερα εδώ από τις τέσσερις κύριες καρτέλες. Η εφαρμογή περιλαμβάνει επίσης ρυθμίσεις, διαγνωστικά και προαιρετικές ροές αισθητήρων.';

  @override
  String get wizardToolsFeature1 =>
      'Ανοίξτε τη ρύθμιση συσκευής για να αλλάξετε παραμέτρους ραδιοφώνου, τηλεμετρία, ισχύ TX και στοιχεία συνοδευτικής συσκευής.';

  @override
  String get wizardToolsFeature2 =>
      'Ενεργοποιήστε την καρτέλα Αισθητήρες όταν θέλετε πίνακες παρακολούθησης και γρήγορες ενέργειες ανανέωσης.';

  @override
  String get wizardToolsFeature3 =>
      'Χρησιμοποιήστε καταγραφές πακέτων, σάρωση φάσματος και διαγνωστικά προγραμματιστή κατά την αντιμετώπιση προβλημάτων του mesh.';

  @override
  String get postConnectDiscoveryTitle => 'Ανακάλυψη αναμεταδοτών τώρα;';

  @override
  String get postConnectDiscoveryDescription =>
      'Εκτελέστε ανακάλυψη αναμεταδοτών αμέσως μετά τη σύνδεση, ώστε να μπορείτε να δείτε κοντινούς κόμβους MeshCore και να τους προσθέσετε στο δίκτυό σας πιο γρήγορα.';

  @override
  String get contactInSensors => 'Στους αισθητήρες';

  @override
  String get contactAddToSensors => 'Προσθήκη στους αισθητήρες';

  @override
  String get contactSetPath => 'Ορισμός διαδρομής';

  @override
  String contactAddedToSensors(String contactName) {
    return 'Το $contactName προστέθηκε στους Αισθητήρες';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Αποτυχία εκκαθάρισης διαδρομής: $error';
  }

  @override
  String get contactRouteCleared => 'Η διαδρομή εκκαθαρίστηκε';

  @override
  String contactRouteSet(String route) {
    return 'Ορίστηκε διαδρομή: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Αποτυχία ορισμού διαδρομής: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Λήξη χρόνου ACK';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Ωφέλιμο φορτίο';

  @override
  String get hops => 'Αναπηδήσεις';

  @override
  String get hashSize => 'Μέγεθος hash';

  @override
  String get pathBytes => 'Bytes διαδρομής';

  @override
  String get selectedPath => 'Επιλεγμένη διαδρομή';

  @override
  String get estimatedTx => 'Εκτιμώμενη εκπομπή';

  @override
  String get senderToReceipt => 'Αποστολέας σε απόδειξη';

  @override
  String get receivedCopies => 'Ληφθέντα αντίγραφα';

  @override
  String get retryCause => 'Αιτία επανάληψης';

  @override
  String get retryMode => 'Λειτουργία επανάληψης';

  @override
  String get retryResult => 'Αποτέλεσμα επανάληψης';

  @override
  String get lastRetry => 'Τελευταία επανάληψη';

  @override
  String get rxPackets => 'Πακέτα RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Ρυθμός';

  @override
  String get window => 'Παράθυρο';

  @override
  String get posttxDelay => 'Καθυστέρηση μετά-tx';

  @override
  String get bandpass => 'Ζωνοπερατό';

  @override
  String get bandpassFilterVoice => 'Ζωνοπερατό φίλτρο φωνής';

  @override
  String get active => 'Ενεργό';

  @override
  String get addContact => 'Προσθήκη επαφής';

  @override
  String get all => 'Όλα';

  @override
  String get clearAllLabel => 'Εκκαθάριση όλων';

  @override
  String get clearFilters => 'Εκκαθάριση φίλτρων';

  @override
  String get clearRoute => 'Εκκαθάριση διαδρομής';

  @override
  String get clearMessages => 'Εκκαθάριση μηνυμάτων';

  @override
  String get clearScale => 'Εκκαθάριση κλίμακας';

  @override
  String get clearDiscoveries => 'Εκκαθάριση ανακαλύψεων';

  @override
  String get clearOnlineTraceDatabase => 'Εκκαθάριση βάσης ιχνών';

  @override
  String get clearAllChannels => 'Εκκαθάριση όλων των καναλιών';

  @override
  String get clearAllContacts => 'Εκκαθάριση όλων των επαφών';

  @override
  String get clearChannels => 'Εκκαθάριση καναλιών';

  @override
  String get clearContacts => 'Εκκαθάριση επαφών';

  @override
  String get clearPathOnMaxRetry => 'Εκκαθάριση μονοπατιού στο μέγιστο';

  @override
  String get create => 'Δημιουργία';

  @override
  String get custom => 'Προσαρμοσμένο';

  @override
  String get defaultValue => 'Προεπιλογή';

  @override
  String get duplicate => 'Αντιγραφή';

  @override
  String get editName => 'Επεξεργασία ονόματος';

  @override
  String get open => 'Άνοιγμα';

  @override
  String get paste => 'Επικόλληση';

  @override
  String get preview => 'Προεπισκόπηση';

  @override
  String get remove => 'Αφαίρεση';

  @override
  String get rename => 'Μετονομασία';

  @override
  String get resolveAll => 'Επίλυση όλων';

  @override
  String get send => 'Αποστολή';

  @override
  String get sendAnyway => 'Αποστολή ούτως ή άλλως';

  @override
  String get share => 'Κοινοποίηση';

  @override
  String get trace => 'Ίχνος';

  @override
  String get discovery => 'Ανακάλυψη';

  @override
  String get discoverRepeaters => 'Ανακάλυψη αναμεταδοτών';

  @override
  String get discoverSensors => 'Ανακάλυψη αισθητήρων';

  @override
  String get repeaterDiscoverySent => 'Αποστολή ανακάλυψης αναμεταδοτών';

  @override
  String get sensorDiscoverySent => 'Αποστολή ανακάλυψης αισθητήρων';

  @override
  String get clearedPendingDiscoveries => 'Εκκαθάριση εκκρεμών ανακαλύψεων.';

  @override
  String get autoDiscovery => 'Αυτόματη ανακάλυψη';

  @override
  String get enableAutomaticAdding => 'Ενεργοποίηση αυτόματης προσθήκης';

  @override
  String get autoaddRepeaters => 'Αυτόματη προσθήκη αναμεταδοτών';

  @override
  String get autoaddRoomServers => 'Αυτόματη προσθήκη διακομιστών δωματίου';

  @override
  String get autoaddSensors => 'Αυτόματη προσθήκη αισθητήρων';

  @override
  String get autoaddUsers => 'Αυτόματη προσθήκη χρηστών';

  @override
  String get overwriteOldestWhenFull =>
      'Αντικατάσταση παλαιότερων όταν γεμίσει';

  @override
  String get storage => 'Αποθήκευση';

  @override
  String get dangerZone => 'Ζώνη κινδύνου';

  @override
  String get profiles => 'Προφίλ';

  @override
  String get favourites => 'Αγαπημένα';

  @override
  String get sensors => 'Αισθητήρες';

  @override
  String get others => 'Άλλοι';

  @override
  String get gpsModule => 'Μονάδα GPS';

  @override
  String get liveTraffic => 'Ζωντανή κίνηση';

  @override
  String get repeatersMap => 'Χάρτης αναμεταδοτών';

  @override
  String get blePacketLogs => 'Αρχεία πακέτων BLE';

  @override
  String get onlineTraceDatabase => 'Βάση δεδομένων ιχνών';

  @override
  String get routePathByteSize => 'Μέγεθος διαδρομής σε bytes';

  @override
  String get messageNotifications => 'Ειδοποιήσεις μηνυμάτων';

  @override
  String get sarAlerts => 'Ειδοποιήσεις SAR';

  @override
  String get discoveryNotifications => 'Ειδοποιήσεις ανακάλυψης';

  @override
  String get updateNotifications => 'Ειδοποιήσεις ενημερώσεων';

  @override
  String get muteWhileAppIsOpen => 'Σίγαση με ανοιχτή εφαρμογή';

  @override
  String get disableContacts => 'Απενεργοποίηση επαφών';

  @override
  String get enableSensorsTab => 'Ενεργοποίηση καρτέλας Αισθητήρων';

  @override
  String get enableProfiles => 'Ενεργοποίηση προφίλ';

  @override
  String get nearestRepeaterFallback => 'Πλησιέστερος αναμεταδότης ως εφεδρεία';

  @override
  String get deleteAllStoredMessageHistory => 'Διαγραφή όλου του ιστορικού';

  @override
  String get messageFontSize => 'Μέγεθος γραμματοσειράς μηνυμάτων';

  @override
  String get rotateMapWithHeading => 'Περιστροφή χάρτη με κατεύθυνση';

  @override
  String get showMapDebugInfo => 'Εμφάνιση πληροφοριών αποσφαλμάτωσης';

  @override
  String get openMapInFullscreen => 'Άνοιγμα χάρτη σε πλήρη οθόνη';

  @override
  String get showSarMarkersLabel => 'Εμφάνιση δεικτών SAR';

  @override
  String get hideRepeatersOnMap => 'Απόκρυψη αναμεταδοτών στον χάρτη';

  @override
  String get setMapScale => 'Ρύθμιση κλίμακας χάρτη';

  @override
  String get customMapScaleSaved => 'Προσαρμοσμένη κλίμακα χάρτη αποθηκεύτηκε';

  @override
  String get voiceBitrate => 'Ρυθμός bit φωνής';

  @override
  String get voiceCompressor => 'Συμπιεστής φωνής';

  @override
  String get voiceLimiter => 'Περιοριστής φωνής';

  @override
  String get micAutoGain => 'Αυτόματη ενίσχυση μικροφώνου';

  @override
  String get echoCancellation => 'Ακύρωση ηχούς';

  @override
  String get noiseSuppression => 'Καταστολή θορύβου';

  @override
  String get trimSilenceInVoiceMessages =>
      'Περικοπή σιωπής σε φωνητικά μηνύματα';

  @override
  String get compressor => 'Συμπιεστής';

  @override
  String get limiter => 'Περιοριστής';

  @override
  String get autoGain => 'Αυτόματη ενίσχυση';

  @override
  String get echoCancel => 'Ηχώ';

  @override
  String get noiseSuppress => 'Θόρυβος';

  @override
  String get silenceTrim => 'Σιωπή';

  @override
  String get maxImageSize => 'Μέγιστο μέγεθος εικόνας';

  @override
  String get imageCompression => 'Συμπίεση εικόνας';

  @override
  String get grayscale => 'Κλίμακα του γκρι';

  @override
  String get ultraMode => 'Λειτουργία ultra';

  @override
  String get fastPrivateGpsUpdates => 'Γρήγορες ιδιωτικές ενημερώσεις GPS';

  @override
  String get movementThreshold => 'Κατώφλι κίνησης';

  @override
  String get fastGpsMovementThreshold => 'Κατώφλι κίνησης γρήγορου GPS';

  @override
  String get fastGpsActiveuseInterval => 'Διάστημα ενεργής χρήσης γρήγορου GPS';

  @override
  String get activeuseUpdateInterval => 'Διάστημα ενημέρωσης ενεργής χρήσης';

  @override
  String get repeatNearbyTraffic => 'Επανάληψη κοντινής κίνησης';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Αναμετάδοση μέσω αναμεταδοτών στο δίκτυο';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Μόνο κοντά, χωρίς πλημμυρισμό';

  @override
  String get multihop => 'Πολλαπλών αναπηδήσεων';

  @override
  String get createProfile => 'Δημιουργία προφίλ';

  @override
  String get renameProfile => 'Μετονομασία προφίλ';

  @override
  String get newProfile => 'Νέο προφίλ';

  @override
  String get manageProfiles => 'Διαχείριση προφίλ';

  @override
  String get enableProfilesToStartManagingThem =>
      'Ενεργοποιήστε τα προφίλ για να τα διαχειριστείτε.';

  @override
  String get openMessage => 'Άνοιγμα μηνύματος';

  @override
  String get jumpToTheRelatedSarMessage => 'Μετάβαση στο σχετικό μήνυμα SAR';

  @override
  String get removeSarMarker => 'Αφαίρεση δείκτη SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Επιλέξτε προορισμό για αποστολή δείκτη SAR';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Δείκτης SAR εκπεμπόμενος στο δημόσιο κανάλι';

  @override
  String get sarMarkerSentToRoom => 'Δείκτης SAR εστάλη στο δωμάτιο';

  @override
  String get loadFromGallery => 'Φόρτωση από τη γκαλερί';

  @override
  String get replaceImage => 'Αντικατάσταση εικόνας';

  @override
  String get selectFromGallery => 'Επιλογή από τη γκαλερί';

  @override
  String get team => 'Ομάδα';

  @override
  String get found => 'Βρέθηκε';

  @override
  String get staging => 'Χώρος συγκέντρωσης';

  @override
  String get object => 'Αντικείμενο';

  @override
  String get quiet => 'Ήσυχο';

  @override
  String get busy => 'Απασχολημένο';

  @override
  String get searchMessages => 'Αναζήτηση μηνυμάτων';

  @override
  String get sendImageFromGallery => 'Αποστολή εικόνας από τη γκαλερί';

  @override
  String get takePhoto => 'Λήψη φωτογραφίας';

  @override
  String get allMessages => 'Όλα τα μηνύματα';

  @override
  String get sendToPublicChannel => 'Αποστολή στο δημόσιο κανάλι;';

  @override
  String get selectMarkerTypeAndDestination =>
      'Επιλέξτε τύπο δείκτη και προορισμό';

  @override
  String get noDestinationsAvailableLabel =>
      'Δεν υπάρχουν διαθέσιμοι προορισμοί';

  @override
  String get image => 'Εικόνα';

  @override
  String get format => 'Μορφή';

  @override
  String get dimensions => 'Διαστάσεις';

  @override
  String get segments => 'Τμήματα';

  @override
  String get transfers => 'Μεταφορές';

  @override
  String get downloadedBy => 'Λήφθηκε από';

  @override
  String get saveDiscoverySettings => 'Αποθήκευση ρυθμίσεων ανακάλυψης';

  @override
  String get savePublicInfo => 'Αποθήκευση δημόσιων πληροφοριών';

  @override
  String get saveRadioSettings => 'Αποθήκευση ρυθμίσεων ραδιοφώνου';

  @override
  String get savePath => 'Αποθήκευση διαδρομής';

  @override
  String get wipeDeviceData => 'Διαγραφή δεδομένων συσκευής';

  @override
  String get wipeDevice => 'Διαγραφή συσκευής';

  @override
  String get destructiveDeviceActions => 'Καταστροφικές ενέργειες συσκευής.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Επιλέξτε μια προεπιλογή ή ρυθμίστε τις ρυθμίσεις ραδιοφώνου.';

  @override
  String get used => 'Χρησιμοποιήθηκε';

  @override
  String get total => 'Σύνολο';

  @override
  String get renameValue => 'Μετονομασία τιμής';

  @override
  String get customizeFields => 'Προσαρμογή πεδίων';

  @override
  String get livePreview => 'Ζωντανή προεπισκόπηση';

  @override
  String get refreshSchedule => 'Χρονοδιάγραμμα ανανέωσης';

  @override
  String get noResponse => 'Χωρίς απάντηση';

  @override
  String get refreshing => 'Ανανέωση';

  @override
  String get unavailable => 'Μη διαθέσιμο';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Επιλέξτε ένα relay ή κόμβο για παρακολούθηση.';

  @override
  String get publicKeyLabel => 'Δημόσιο κλειδί';

  @override
  String get alreadyInContacts => 'Ήδη στις επαφές';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Συνδεθείτε σε μια συσκευή πριν προσθέσετε επαφές';

  @override
  String get fromContacts => 'Από τις επαφές';

  @override
  String get onlineOnly => 'Μόνο συνδεδεμένοι';

  @override
  String get inBoth => 'Σε αμφότερα';

  @override
  String get source => 'Πηγή';

  @override
  String get allMessagesCleared => 'Όλα τα μηνύματα διαγράφηκαν';

  @override
  String get onlineTraceDatabaseCleared => 'Βάση δεδομένων ιχνών εκκαθαρίστηκε';

  @override
  String get packetLogsCleared => 'Τα αρχεία πακέτων εκκαθαρίστηκαν';

  @override
  String get hexDataCopiedToClipboard => 'Τα δεδομένα hex αντιγράφηκαν';

  @override
  String get developerModeEnabled => 'Λειτουργία προγραμματιστή ενεργοποιήθηκε';

  @override
  String get developerModeDisabled =>
      'Λειτουργία προγραμματιστή απενεργοποιήθηκε';

  @override
  String get clipboardIsEmpty => 'Το πρόχειρο είναι κενό';

  @override
  String get contactImported => 'Επαφή εισήχθη';

  @override
  String get contactLinkCopiedToClipboard => 'Ο σύνδεσμος επαφής αντιγράφηκε';

  @override
  String get failedToExportContact => 'Αποτυχία εξαγωγής επαφής';

  @override
  String get noLogsToExport => 'Δεν υπάρχουν αρχεία για εξαγωγή';

  @override
  String get exportAsCsv => 'Εξαγωγή ως CSV';

  @override
  String get exportAsText => 'Εξαγωγή ως κείμενο';

  @override
  String get receivedRfc3339 => 'Ελήφθη (RFC3339)';

  @override
  String get buildTime => 'Ώρα κατασκευής';

  @override
  String get downloadUrlNotAvailable => 'Η URL λήψης δεν είναι διαθέσιμη';

  @override
  String get cannotOpenDownloadUrl => 'Αδυναμία ανοίγματος URL λήψης';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Ο έλεγχος ενημερώσεων είναι διαθέσιμος μόνο σε Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Χρησιμοποιείτε την πιο πρόσφατη έκδοση';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Διαθέσιμη ενημέρωση αλλά η URL λήψης δεν βρέθηκε';

  @override
  String get startTictactoe => 'Εκκίνηση Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe μη διαθέσιμο';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: άγνωστος αντίπαλος';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: αναμονή για εκκίνηση';

  @override
  String get acceptsShareLinks => 'Αποδέχεται κοινόχρηστους συνδέσμους';

  @override
  String get supportsRawHex => 'Υποστηρίζει ακατέργαστο hex';

  @override
  String get clipboardfriendly => 'Φιλικό προς πρόχειρο';

  @override
  String get captured => 'Καταγράφηκε';

  @override
  String get size => 'Μέγεθος';

  @override
  String get noCustomChannelsToClear => 'Δεν υπάρχουν προσαρμοσμένα κανάλια.';

  @override
  String get noDeviceContactsToClear => 'Δεν υπάρχουν επαφές συσκευής.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Προσθήκη';

  @override
  String get addAdditionalDetails => 'Προσθήκη επιπλέον λεπτομερειών';

  @override
  String get addPeer => 'Προσθήκη κόμβου';

  @override
  String get addPeerManually => 'Χειροκίνητη προσθήκη κόμβου';

  @override
  String addedToContacts(String name) {
    return 'Ο/Η $name προστέθηκε στις επαφές';
  }

  @override
  String addedToSensors(String name) {
    return 'Ο/Η $name προστέθηκε στους αισθητήρες';
  }

  @override
  String get allowAll => 'Επιτρέπονται όλα';

  @override
  String get anonymousRxStats => 'Ανώνυμα στατιστικά λήψης';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Βασική τηλεμετρία';

  @override
  String get blePin => 'BLE PIN';

  @override
  String get buzzerAlerts => 'Ειδοποιήσεις βομβητή';

  @override
  String get cancelImageReceive => 'Ακύρωση λήψης εικόνας';

  @override
  String get choose => 'Επιλογή';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Επιλέξτε ποιες καρτέλες και ενότητες επαφών θα εμφανίζονται';

  @override
  String get clearCache => 'Εκκαθάριση προσωρινής μνήμης';

  @override
  String get clearHistory => 'Εκκαθάριση ιστορικού';

  @override
  String get clearLiveView => 'Εκκαθάριση ζωντανής προβολής';

  @override
  String get clearLogs => 'Εκκαθάριση αρχείων καταγραφής';

  @override
  String get clearOfflineCache =>
      'Εκκαθάριση προσωρινής μνήμης εκτός σύνδεσης;';

  @override
  String get clearOverlay => 'Εκκαθάριση επικάλυψης';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Εκκαθάριση διαδρομής μόνο μετά την αποτυχία όλων των επαναπροσπαθειών';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Κωδικοποιητής, ρυθμός bit και επεξεργασία ήχου';

  @override
  String get connectByIpAddress => 'Σύνδεση μέσω διεύθυνσης IP';

  @override
  String get controlWhichAlertsYouReceive =>
      'Ελέγξτε ποιες ειδοποιήσεις λαμβάνετε';

  @override
  String get copyFullHex => 'Αντιγραφή πλήρους Hex';

  @override
  String get copyRawResponse => 'Αντιγραφή ακατέργαστης απόκρισης';

  @override
  String get couldNotLoadMetHistory => 'Αδυναμία φόρτωσης ιστορικού MET';

  @override
  String customizeSensor(String name) {
    return 'Προσαρμογή $name';
  }

  @override
  String get data => 'Δεδομένα';

  @override
  String get deleteGroup => 'Διαγραφή ομάδας';

  @override
  String deleteStyleConfirm(String name) {
    return 'Διαγραφή $name;';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Διαγραφή αυτού του $type;';
  }

  @override
  String get deny => 'Απόρριψη';

  @override
  String get deviceInfo => 'Πληροφορίες συσκευής';

  @override
  String get deviceSettings => 'Ρυθμίσεις συσκευής';

  @override
  String get deviceTimeSynced =>
      'Ο χρόνος της συσκευής συγχρονίστηκε με αυτό το τηλέφωνο.';

  @override
  String get disableFastGpsPublishing =>
      'Απενεργοποίηση γρήγορης δημοσίευσης GPS';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Εμφάνιση, δείκτες και βάση δεδομένων ιχνών';

  @override
  String get download => 'Λήψη';

  @override
  String get environmentalTelemetry => 'Περιβαλλοντική τηλεμετρία';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Σφάλμα ελέγχου ενημερώσεων: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Σφάλμα: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Σφάλμα ανοίγματος λήψης: $error';
  }

  @override
  String get exportLogs => 'Εξαγωγή αρχείων καταγραφής';

  @override
  String get extraAggressiveAvifCompression =>
      'Εξαιρετικά επιθετική συμπίεση AVIF';

  @override
  String failedToAddContact(String error) {
    return 'Αποτυχία προσθήκης επαφής: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Αποτυχία προσθήκης $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Αποτυχία εκκαθάρισης καναλιών: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Αποτυχία εκκαθάρισης επαφών: $error';
  }

  @override
  String get failedToConnectViaSerial =>
      'Αποτυχία σύνδεσης μέσω σειριακής θύρας';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Αποτυχία φόρτωσης εικόνας προεπισκόπησης: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Αποτυχία φόρτωσης ίχνους: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Αποτυχία αποστολής δείκτη SAR: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Αποτυχία ρύθμισης λειτουργίας βομβητή: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Αποτυχία ρύθμισης λειτουργίας GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Αποτυχία συγχρονισμού χρόνου συσκευής: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Αποτυχία διαγραφής δεδομένων συσκευής: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Κανάλι-στόχος γρήγορου GPS';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Γρήγορες ενημερώσεις, όρια και δικαιώματα';

  @override
  String get fetchingCatalog => 'Ανάκτηση καταλόγου...';

  @override
  String get fifteenMinutes => '15 λεπτά';

  @override
  String get fifteenSeconds => '15 δευτερόλεπτα';

  @override
  String get filterByDirection => 'Φιλτράρισμα κατά κατεύθυνση';

  @override
  String get finish => 'Τέλος';

  @override
  String get fiveMinutes => '5 λεπτά';

  @override
  String get fiveSeconds => '5 δευτερόλεπτα';

  @override
  String get fix => 'Στίξη';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Πολιτική διαφήμισης GPS';

  @override
  String get gpsAndLocation => 'GPS & Τοποθεσία';

  @override
  String get gpsDiagnostics => 'Διαγνωστικά GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Βοήθεια';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Κρυφό';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Πώς το ραδιόφωνο προσθέτει αυτόματα ανακαλυφθέντες κόμβους.';

  @override
  String get images => 'Εικόνες';

  @override
  String get importProfile => 'Εισαγωγή προφίλ';

  @override
  String get lastFix => 'Τελευταία στίξη';

  @override
  String get latest => 'Πιο πρόσφατο';

  @override
  String get latitude => 'Γεωγραφικό πλάτος';

  @override
  String get loadASavedRegion => 'Φόρτωση αποθηκευμένης περιοχής';

  @override
  String get loading => 'Φόρτωση';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Κοινοποίηση τοποθεσίας, υλικό και διάστημα ενημέρωσης.';

  @override
  String get locationTelemetry => 'Τηλεμετρία τοποθεσίας';

  @override
  String get lockDestination => 'Κλείδωμα προορισμού';

  @override
  String get longitude => 'Γεωγραφικό μήκος';

  @override
  String get mapStyle => 'Στυλ χάρτη';

  @override
  String get max => 'Μέγ.';

  @override
  String get maxZoom => 'Μέγ. ζουμ';

  @override
  String get messaging => 'Μηνύματα';

  @override
  String get metHistory => 'Ιστορικό MET';

  @override
  String get min => 'Ελάχ.';

  @override
  String get minZoom => 'Ελάχ. ζουμ';

  @override
  String get moveDown => 'Μετακίνηση κάτω';

  @override
  String get moveUp => 'Μετακίνηση πάνω';

  @override
  String get multiAckMode => 'Λειτουργία πολλαπλού ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Διαχείριση χώρου εργασίας πολλαπλών συσκευών';

  @override
  String get myLocation => 'Η τοποθεσία μου';

  @override
  String get nameAndTelemetryShared =>
      'Το όνομα και η τηλεμετρία κοινοποιούνται σε άλλες συσκευές.';

  @override
  String newVersionAvailable(String version) {
    return 'Νέα έκδοση: $version';
  }

  @override
  String get newer => 'Νεότερο';

  @override
  String get noNeighboursFound => 'Δεν βρέθηκαν γείτονες';

  @override
  String get noServersFound => 'Δεν βρέθηκαν διακομιστές';

  @override
  String get notSet => 'Δεν έχει οριστεί';

  @override
  String get notifications => 'Ειδοποιήσεις';

  @override
  String get offZeroSeconds => 'Ανενεργό (0 δ)';

  @override
  String get offlineMaps => 'Χάρτες εκτός σύνδεσης';

  @override
  String get older => 'Παλαιότερο';

  @override
  String get oneByteMode0 => '1 byte (mode 0)';

  @override
  String get oneHour => '1 ώρα';

  @override
  String get oneMinute => '1 λεπτό';

  @override
  String get openPacketLogs => 'Άνοιγμα αρχείων πακέτων';

  @override
  String get packetTypeHelp => 'Βοήθεια τύπων πακέτων';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Επικολλήστε σύνδεσμο κοινοποίησης ή hex διαφήμιση';

  @override
  String get pathHash => 'Hash διαδρομής';

  @override
  String get pathSize => 'Μέγεθος διαδρομής';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Πολύγωνο';

  @override
  String get rawResponseCopied => 'Η ακατέργαστη απόκριση αντιγράφηκε';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Επαναποστολή μέσω πλησιέστερου αναμεταδότη σε αποτυχία';

  @override
  String get resolveContact => 'Επίλυση επαφής';

  @override
  String get routingRetriesAndDestinationLock =>
      'Δρομολόγηση, επαναπροσπάθειες και κλείδωμα προορισμού';

  @override
  String get samples => 'Δείγματα';

  @override
  String get satellites => 'Δορυφόροι';

  @override
  String get saving => 'Αποθήκευση...';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get searchByNameOrToken => 'Αναζήτηση με όνομα ή token';

  @override
  String get searchDiscoveredNodes => 'Αναζήτηση ανακαλυφθέντων κόμβων';

  @override
  String get searchInCurrentFilter => 'Αναζήτηση στο τρέχον φίλτρο';

  @override
  String get searchLogs => 'Αναζήτηση αρχείων καταγραφής...';

  @override
  String get searchSensors => 'Αναζήτηση αισθητήρων';

  @override
  String get searchThisSection => 'Αναζήτηση σε αυτήν την ενότητα';

  @override
  String get selectedRelays => 'Επιλεγμένοι αναμεταδότες';

  @override
  String get sensor => 'Αισθητήρας';

  @override
  String serialError(String error) {
    return 'Σφάλμα σειριακής: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Ορισμός διαδρομής για $name';
  }

  @override
  String get shareLiveGps => 'Κοινοποίηση ζωντανού GPS';

  @override
  String get shareMyTiles => 'Κοινοποίηση πλακιδίων μου';

  @override
  String get sharingLocationFromPhone =>
      'Κοινοποίηση τοποθεσίας σε αυτό το κανάλι από το τηλέφωνο.';

  @override
  String get sharingLocationFromRadio =>
      'Κοινοποίηση τοποθεσίας σε αυτό το κανάλι από το ραδιόφωνο.';

  @override
  String signalDbm(String rssi) {
    return 'Σήμα $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview => 'Μέγεθος, συμπίεση και προεπισκόπηση';

  @override
  String get skip => 'Παράλειψη';

  @override
  String get smallerFileSize => 'Μικρότερο μέγεθος αρχείου';

  @override
  String get sort => 'Ταξινόμηση';

  @override
  String get stoppedSharingLocation =>
      'Σταμάτησε η κοινοποίηση τοποθεσίας σε αυτό το κανάλι.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Αποσιώπηση ειδοποιήσεων όταν η εφαρμογή είναι στο προσκήνιο';

  @override
  String get tabsAndNavigation => 'Καρτέλες & Πλοήγηση';

  @override
  String get templatesAndTutorials => 'Πρότυπα και οδηγίες';

  @override
  String get tenMinutes => '10 λεπτά';

  @override
  String get tenSeconds => '10 δευτερόλεπτα';

  @override
  String get testSendUpdate => 'Δοκιμαστική αποστολή ενημέρωσης';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Θέμα, γλώσσα και προτιμήσεις εμφάνισης';

  @override
  String get thirtyMinutes => '30 λεπτά';

  @override
  String get thirtySeconds => '30 δευτερόλεπτα';

  @override
  String get threeBytesMode2 => '3 bytes (mode 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Στατιστικά κίνησης, ιστορικό μηνυμάτων και εργαλεία προγραμματιστή';

  @override
  String get twoBytesMode1 => '2 bytes (mode 1)';

  @override
  String get twoMinutes => '2 λεπτά';

  @override
  String get undo => 'Αναίρεση';

  @override
  String get updated => 'Ενημερώθηκε';

  @override
  String get useContactFlags => 'Χρήση σημαιών επαφής';

  @override
  String get useSavedCoordinates => 'Χρήση αποθηκευμένων συντεταγμένων';

  @override
  String get view => 'Προβολή';

  @override
  String get viewNeighbours => 'Προβολή γειτόνων';

  @override
  String get viewPublicStats => 'Προβολή δημόσιων στατιστικών';

  @override
  String get setRegionScope => 'Ορισμός εύρους περιοχής';

  @override
  String get regionScope => 'Εύρος περιοχής';

  @override
  String get regionScopeNone => 'Κανένα (καθολικό)';

  @override
  String get clearRegionScope => 'Εκκαθάριση εύρους';

  @override
  String get regionScopeWarning =>
      'Μόνο οι αναμεταδότες που επιτρέπουν αυτή την περιοχή θα προωθήσουν.';

  @override
  String get discoverRegions => 'Ανακάλυψη από αναμεταδότες';

  @override
  String get discoveringRegions => 'Ανακάλυψη περιοχών...';

  @override
  String get enterRegionName => 'Όνομα περιοχής (π.χ. auckland)';

  @override
  String get noRegionsFound =>
      'Δεν βρέθηκαν περιοχές σε αυτόν τον αναμεταδότη.';

  @override
  String regionScopeSet(String name) {
    return 'Εύρος περιοχής ορίστηκε σε $name';
  }

  @override
  String get regionScopeCleared => 'Εύρος περιοχής εκκαθαρίστηκε';
}
