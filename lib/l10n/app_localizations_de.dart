// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Nachrichten';

  @override
  String get contacts => 'Kontakte';

  @override
  String get map => 'Karte';

  @override
  String get settings => 'Einstellungen';

  @override
  String get connect => 'Verbinden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get scanningForDevices => 'Suche nach Geräten...';

  @override
  String get noDevicesFound => 'Keine Geräte gefunden';

  @override
  String get scanAgain => 'Erneut scannen';

  @override
  String get tapToConnect => 'Zum Verbinden tippen';

  @override
  String get deviceNotConnected => 'Gerät nicht verbunden';

  @override
  String get locationPermissionDenied => 'Standortberechtigung verweigert';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String get locationPermissionRequired =>
      'Die Standortberechtigung ist für GPS-Tracking und Teamkoordination erforderlich. Sie können sie später in den Einstellungen aktivieren.';

  @override
  String get locationServicesDisabled =>
      'Standortdienste sind deaktiviert. Bitte aktivieren Sie sie in den Einstellungen.';

  @override
  String get failedToGetGpsLocation =>
      'GPS-Position konnte nicht abgerufen werden';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Position gesendet bei $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Wiederverbindung... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Wiederverbindung abbrechen';

  @override
  String get mapManagement => 'Kartenverwaltung';

  @override
  String get general => 'Allgemein';

  @override
  String get theme => 'Design';

  @override
  String get chooseTheme => 'Design auswählen';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get blueLightTheme => 'Blaues helles Design';

  @override
  String get blueDarkTheme => 'Blaues dunkles Design';

  @override
  String get sarRed => 'SAR Rot';

  @override
  String get alertEmergencyMode => 'Alarm-/Notfallmodus';

  @override
  String get sarGreen => 'SAR Grün';

  @override
  String get safeAllClearMode => 'Sicher/Entwarnung-Modus';

  @override
  String get autoSystem => 'Automatisch (System)';

  @override
  String get followSystemTheme => 'System-Design folgen';

  @override
  String get showRxTxIndicators => 'RX/TX-Indikatoren anzeigen';

  @override
  String get displayPacketActivity =>
      'Paketaktivitätsindikatoren in der oberen Leiste anzeigen';

  @override
  String get simpleMode => 'Einfacher Modus';

  @override
  String get simpleModeDescription =>
      'Nicht wesentliche Informationen in Nachrichten und Kontakten ausblenden';

  @override
  String get language => 'Sprache';

  @override
  String get chooseLanguage => 'Sprache auswählen';

  @override
  String get english => 'Englisch';

  @override
  String get slovenian => 'Slowenisch';

  @override
  String get croatian => 'Kroatisch';

  @override
  String get german => 'Deutsch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get french => 'Französisch';

  @override
  String get italian => 'Italienisch';

  @override
  String get locationBroadcasting => 'Standortübertragung';

  @override
  String get autoLocationTracking => 'Automatisches Standort-Tracking';

  @override
  String get automaticallyBroadcastPosition =>
      'Positionsaktualisierungen automatisch übertragen';

  @override
  String get configureTracking => 'Tracking konfigurieren';

  @override
  String get distanceAndTimeThresholds => 'Entfernungs- und Zeitschwellenwerte';

  @override
  String get locationTrackingConfiguration => 'Standort-Tracking-Konfiguration';

  @override
  String get configureWhenLocationBroadcasts =>
      'Konfigurieren Sie, wann Standortübertragungen an das Mesh-Netzwerk gesendet werden';

  @override
  String get minimumDistance => 'Mindestentfernung';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Nur nach Bewegung von $distance Metern übertragen';
  }

  @override
  String get maximumDistance => 'Maximale Entfernung';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Immer nach Bewegung von $distance Metern übertragen';
  }

  @override
  String get minimumTimeInterval => 'Minimales Zeitintervall';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Immer alle $duration übertragen';
  }

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get about => 'Über';

  @override
  String get appVersion => 'App-Version';

  @override
  String get appName => 'App-Name';

  @override
  String get aboutMeshCoreSar => 'Über MeshCore SAR';

  @override
  String get aboutDescription =>
      'Eine Such- und Rettungsanwendung für Notfallteams. Funktionen umfassen:\n\n• BLE-Mesh-Netzwerk für Gerät-zu-Gerät-Kommunikation\n• Offline-Karten mit mehreren Ebenenoptionen\n• Echtzeit-Teammitgliederverfolgung\n• SAR-Taktikmarkierungen (Person gefunden, Feuer, Sammelpunkt)\n• Kontaktverwaltung und Nachrichtenübermittlung\n• GPS-Tracking mit Kompass-Kurs\n• Karten-Tile-Caching für Offline-Nutzung';

  @override
  String get technologiesUsed => 'Verwendete Technologien:';

  @override
  String get technologiesList =>
      '• Flutter für plattformübergreifende Entwicklung\n• BLE (Bluetooth Low Energy) für Mesh-Netzwerk\n• OpenStreetMap für Kartendarstellung\n• Provider für Zustandsverwaltung\n• SharedPreferences für lokale Speicherung';

  @override
  String get moreInfo => 'Mehr Info';

  @override
  String get learnMoreAbout => 'Erfahren Sie mehr über MeshCore SAR';

  @override
  String get developer => 'Entwickler';

  @override
  String get packageName => 'Paketname';

  @override
  String get sampleData => 'Beispieldaten';

  @override
  String get sampleDataDescription =>
      'Laden oder löschen Sie Beispielkontakte, Kanalnachrichten und SAR-Markierungen zum Testen';

  @override
  String get loadSampleData => 'Beispieldaten laden';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get clearAllDataConfirmTitle => 'Alle Daten löschen';

  @override
  String get clearAllDataConfirmMessage =>
      'Dadurch werden alle Kontakte und SAR-Markierungen gelöscht. Sind Sie sicher?';

  @override
  String get clear => 'Löschen';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return '$teamCount Teammitglieder, $channelCount Kanäle, $sarCount SAR-Markierungen, $messageCount Nachrichten geladen';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Fehler beim Laden der Beispieldaten: $error';
  }

  @override
  String get allDataCleared => 'Alle Daten gelöscht';

  @override
  String get failedToStartBackgroundTracking =>
      'Hintergrund-Tracking konnte nicht gestartet werden. Überprüfen Sie Berechtigungen und BLE-Verbindung.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Standortübertragung: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Die Standard-PIN für Geräte ohne Bildschirm ist 123456. Probleme beim Koppeln? Vergessen Sie das Bluetooth-Gerät in den Systemeinstellungen.';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get pullDownToSync =>
      'Nach unten ziehen, um Nachrichten zu synchronisieren';

  @override
  String get deleteContact => 'Kontakt löschen';

  @override
  String get delete => 'Löschen';

  @override
  String get viewOnMap => 'Auf Karte anzeigen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get sendDirectMessage => 'Senden';

  @override
  String get resetPath => 'Pfad zurücksetzen (Umleitung)';

  @override
  String get publicKeyCopied =>
      'Öffentlicher Schlüssel in die Zwischenablage kopiert';

  @override
  String copiedToClipboard(String label) {
    return '$label in die Zwischenablage kopiert';
  }

  @override
  String get pleaseEnterPassword => 'Bitte geben Sie ein Passwort ein';

  @override
  String failedToSyncContacts(String error) {
    return 'Kontaktsynchronisation fehlgeschlagen: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Erfolgreich angemeldet! Warte auf Raumnachrichten...';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen - falsches Passwort';

  @override
  String loggingIn(String roomName) {
    return 'Anmeldung bei $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Anmeldung senden fehlgeschlagen: $error';
  }

  @override
  String get lowLocationAccuracy => 'Niedrige Standortgenauigkeit';

  @override
  String get continue_ => 'Fortfahren';

  @override
  String get sendSarMarker => 'SAR-Markierung senden';

  @override
  String get deleteDrawing => 'Zeichnung löschen';

  @override
  String get drawingTools => 'Zeichenwerkzeuge';

  @override
  String get drawLine => 'Linie zeichnen';

  @override
  String get drawLineDesc => 'Freihandlinie auf der Karte zeichnen';

  @override
  String get drawRectangle => 'Rechteck zeichnen';

  @override
  String get drawRectangleDesc => 'Rechteckigen Bereich auf der Karte zeichnen';

  @override
  String get measureDistance => 'Entfernung messen';

  @override
  String get measureDistanceDesc => 'Zwei Punkte lang drücken zum Messen';

  @override
  String get clearMeasurement => 'Messung löschen';

  @override
  String distanceLabel(String distance) {
    return 'Entfernung: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Langer Druck für zweiten Punkt';

  @override
  String get longPressToStartMeasurement => 'Langer Druck für ersten Punkt';

  @override
  String get longPressToStartNewMeasurement => 'Langer Druck für neue Messung';

  @override
  String get shareDrawings => 'Zeichnungen teilen';

  @override
  String get clearAllDrawings => 'Alle Zeichnungen löschen';

  @override
  String get completeLine => 'Linie fertigstellen';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return '$count Zeichnung$plural an Team senden';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Alle $count Zeichnung$plural entfernen';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Alle $count Zeichnung$plural von der Karte löschen?';
  }

  @override
  String get drawing => 'Zeichnung';

  @override
  String shareDrawingsCount(int count, String plural) {
    return '$count Zeichnung$plural teilen';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return '$count Kartenzeichnung$plural an $roomName gesendet';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return '$success/$total Zeichnung$plural mit $roomName geteilt';
  }

  @override
  String get showReceivedDrawings => 'Empfangene Zeichnungen anzeigen';

  @override
  String get showingAllDrawings => 'Alle Zeichnungen werden angezeigt';

  @override
  String get showingOnlyYourDrawings => 'Nur Ihre Zeichnungen werden angezeigt';

  @override
  String get showSarMarkers => 'SAR-Markierungen anzeigen';

  @override
  String get showingSarMarkers => 'SAR-Markierungen werden angezeigt';

  @override
  String get hidingSarMarkers => 'SAR-Markierungen ausgeblendet';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get noLocalDrawings => 'Keine lokalen Zeichnungen zum Teilen';

  @override
  String get publicChannel => 'Öffentlicher Kanal';

  @override
  String get broadcastToAll => 'An alle Knoten in der Nähe senden (temporär)';

  @override
  String get storedPermanently => 'Dauerhaft im Raum gespeichert';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return '$count Kartenzeichnung$plural an öffentlichen Kanal gesendet';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return '$success/$total Zeichnungen mit öffentlichem Kanal geteilt';
  }

  @override
  String get notConnectedToDevice => 'Nicht mit Gerät verbunden';

  @override
  String get directMessage => 'Direktnachricht';

  @override
  String directMessageSentTo(String contactName) {
    return 'Direktnachricht an $contactName gesendet';
  }

  @override
  String failedToSend(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'Diese Nachricht wird direkt an $contactName gesendet. Sie erscheint auch im Hauptnachrichten-Feed.';
  }

  @override
  String get typeYourMessage => 'Geben Sie Ihre Nachricht ein...';

  @override
  String get quickLocationMarker => 'Schnelle Standortmarkierung';

  @override
  String get markerType => 'Markierungstyp';

  @override
  String get sendTo => 'Senden an';

  @override
  String get noDestinationsAvailable => 'Keine Ziele verfügbar.';

  @override
  String get selectDestination => 'Ziel auswählen...';

  @override
  String get ephemeralBroadcastInfo =>
      'Temporär: Nur Over-the-Air-Übertragung. Nicht gespeichert - Knoten müssen online sein.';

  @override
  String get persistentRoomInfo =>
      'Dauerhaft: Unveränderlich im Raum gespeichert. Automatisch synchronisiert und offline gespeichert.';

  @override
  String get location => 'Standort';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get fromMap => 'Von Karte';

  @override
  String get gettingLocation => 'Standort wird abgerufen...';

  @override
  String get locationError => 'Standortfehler';

  @override
  String get retry => 'Wiederholen';

  @override
  String get refreshLocation => 'Standort aktualisieren';

  @override
  String accuracyMeters(int accuracy) {
    return 'Genauigkeit: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get addAdditionalInformation =>
      'Zusätzliche Informationen hinzufügen...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Standortgenauigkeit beträgt ±${accuracy}m. Dies ist möglicherweise nicht genau genug für SAR-Operationen.\n\nTrotzdem fortfahren?';
  }

  @override
  String get loginToRoom => 'Bei Raum anmelden';

  @override
  String get enterPasswordInfo =>
      'Geben Sie das Passwort ein, um auf diesen Raum zuzugreifen. Das Passwort wird für die zukünftige Verwendung gespeichert.';

  @override
  String get password => 'Passwort';

  @override
  String get enterRoomPassword => 'Raumpasswort eingeben';

  @override
  String get loggingInDots => 'Anmeldung läuft...';

  @override
  String get login => 'Anmelden';

  @override
  String failedToAddRoom(String error) {
    return 'Fehler beim Hinzufügen des Raums zum Gerät: $error\n\nDer Raum hat möglicherweise noch nicht gesendet.\nVersuchen Sie zu warten, bis der Raum sendet.';
  }

  @override
  String get direct => 'Direkt';

  @override
  String get flood => 'Flut';

  @override
  String get admin => 'Admin';

  @override
  String get loggedIn => 'Angemeldet';

  @override
  String get noGpsData => 'Keine GPS-Daten';

  @override
  String get distance => 'Entfernung';

  @override
  String pingingDirect(String name) {
    return 'Pinge $name (direkt über Pfad)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Pinge $name (Flutung - kein Pfad)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Direkter Ping-Timeout - wiederhole $name mit Flutung...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping erfolgreich an $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (über Flutungs-Fallback)';

  @override
  String pingFailed(String name) {
    return 'Ping fehlgeschlagen an $name - keine Antwort erhalten';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten?\n\nDies entfernt den Kontakt sowohl aus der App als auch vom Begleitfunkgerät.';
  }

  @override
  String removingContact(String name) {
    return 'Entferne $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Kontakt \"$name\" entfernt';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Fehler beim Entfernen des Kontakts: $error';
  }

  @override
  String get type => 'Typ';

  @override
  String get publicKey => 'Öffentlicher Schlüssel';

  @override
  String get lastSeen => 'Zuletzt gesehen';

  @override
  String get roomStatus => 'Raumstatus';

  @override
  String get loginStatus => 'Anmeldestatus';

  @override
  String get notLoggedIn => 'Nicht angemeldet';

  @override
  String get adminAccess => 'Admin-Zugriff';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get passwordSaved => 'Passwort gespeichert';

  @override
  String get locationColon => 'Standort:';

  @override
  String get telemetry => 'Telemetrie';

  @override
  String requestingTelemetry(String name) {
    return 'Fordere Telemetrie von $name an...';
  }

  @override
  String get voltage => 'Spannung';

  @override
  String get battery => 'Batterie';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get pressure => 'Druck';

  @override
  String get gpsTelemetry => 'GPS (Telemetrie)';

  @override
  String get updated => 'Aktualisiert';

  @override
  String pathResetInfo(String name) {
    return 'Pfad zurückgesetzt für $name. Nächste Nachricht findet eine neue Route.';
  }

  @override
  String get reLoginToRoom => 'Erneut bei Raum anmelden';

  @override
  String get heading => 'Kurs';

  @override
  String get elevation => 'Höhe';

  @override
  String get accuracy => 'Genauigkeit';

  @override
  String get bearing => 'Peilung';

  @override
  String get direction => 'Richtung';

  @override
  String get filterMarkers => 'Markierungen filtern';

  @override
  String get filterMarkersTooltip => 'Markierungen filtern';

  @override
  String get contactsFilter => 'Kontakte';

  @override
  String get repeatersFilter => 'Repeater';

  @override
  String get sarMarkers => 'SAR-Markierungen';

  @override
  String get foundPerson => 'Person gefunden';

  @override
  String get fire => 'Feuer';

  @override
  String get stagingArea => 'Sammelpunkt';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get nearbyContacts => 'Kontakte in der Nähe';

  @override
  String get locationUnavailable => 'Standort nicht verfügbar';

  @override
  String get ahead => 'voraus';

  @override
  String degreesRight(int degrees) {
    return '$degrees° rechts';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° links';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Noch keine Kontakte';

  @override
  String get connectToDeviceToLoadContacts =>
      'Mit einem Gerät verbinden, um Kontakte zu laden';

  @override
  String get teamMembers => 'Teammitglieder';

  @override
  String get repeaters => 'Repeater';

  @override
  String get rooms => 'Räume';

  @override
  String get channels => 'Kanäle';

  @override
  String get cacheStatistics => 'Cache-Statistiken';

  @override
  String get totalTiles => 'Gesamte Tiles';

  @override
  String get cacheSize => 'Cache-Größe';

  @override
  String get storeName => 'Speichername';

  @override
  String get noCacheStatistics => 'Keine Cache-Statistiken verfügbar';

  @override
  String get downloadRegion => 'Region herunterladen';

  @override
  String get mapLayer => 'Kartenebene';

  @override
  String get regionBounds => 'Regionsgrenzen';

  @override
  String get north => 'Nord';

  @override
  String get south => 'Süd';

  @override
  String get east => 'Ost';

  @override
  String get west => 'West';

  @override
  String get zoomLevels => 'Zoom-Stufen';

  @override
  String minZoom(int zoom) {
    return 'Min: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Max: $zoom';
  }

  @override
  String get downloadingDots => 'Lädt herunter...';

  @override
  String get cancelDownload => 'Download abbrechen';

  @override
  String get downloadRegionButton => 'Region herunterladen';

  @override
  String get downloadNote =>
      'Hinweis: Große Regionen oder hohe Zoom-Stufen können erhebliche Zeit und Speicherplatz benötigen.';

  @override
  String get cacheManagement => 'Cache-Verwaltung';

  @override
  String get clearAllMaps => 'Alle Karten löschen';

  @override
  String get clearMapsConfirmTitle => 'Alle Karten löschen';

  @override
  String get clearMapsConfirmMessage =>
      'Sind Sie sicher, dass Sie alle heruntergeladenen Karten löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get mapDownloadCompleted => 'Karten-Download abgeschlossen!';

  @override
  String get cacheClearedSuccessfully => 'Cache erfolgreich gelöscht!';

  @override
  String get downloadCancelled => 'Download abgebrochen';

  @override
  String get startingDownload => 'Starte Download...';

  @override
  String get downloadingMapTiles => 'Lade Karten-Tiles herunter...';

  @override
  String get downloadCompletedSuccessfully =>
      'Download erfolgreich abgeschlossen!';

  @override
  String get cancellingDownload => 'Breche Download ab...';

  @override
  String errorLoadingStats(String error) {
    return 'Fehler beim Laden der Statistiken: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Abbruch fehlgeschlagen: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Löschen des Caches fehlgeschlagen: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Min-Zoom: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Max-Zoom: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Minimaler Zoom muss kleiner oder gleich dem maximalen Zoom sein';

  @override
  String get selectMapLayer => 'Kartenebene auswählen';

  @override
  String get mapOptions => 'Kartenoptionen';

  @override
  String get showLegend => 'Legende anzeigen';

  @override
  String get displayMarkerTypeCounts => 'Markierungstypen-Anzahl anzeigen';

  @override
  String get rotateMapWithHeading => 'Karte mit Kurs drehen';

  @override
  String get mapFollowsDirection =>
      'Karte folgt Ihrer Richtung während der Bewegung';

  @override
  String get resetMapRotation => 'Drehung zurücksetzen';

  @override
  String get resetMapRotationTooltip => 'Karte nach Norden zurücksetzen';

  @override
  String get showMapDebugInfo => 'Karten-Debug-Info anzeigen';

  @override
  String get displayZoomLevelBounds => 'Zoom-Stufe und Grenzen anzeigen';

  @override
  String get fullscreenMode => 'Vollbildmodus';

  @override
  String get hideUiFullMapView =>
      'Alle UI-Steuerelemente für volle Kartenansicht ausblenden';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI-Satellit';

  @override
  String get googleHybrid => 'Google Hybrid';

  @override
  String get googleRoadmap => 'Google Straßenkarte';

  @override
  String get googleTerrain => 'Google Gelände';

  @override
  String get downloadVisibleArea => 'Sichtbaren Bereich herunterladen';

  @override
  String get initializingMap => 'Initialisiere Karte...';

  @override
  String get dragToPosition => 'Zur Position ziehen';

  @override
  String get createSarMarker => 'SAR-Markierung erstellen';

  @override
  String get compass => 'Kompass';

  @override
  String get navigationAndContacts => 'Navigation & Kontakte';

  @override
  String get sarAlert => 'SAR-ALARM';

  @override
  String get messageSentToPublicChannel =>
      'Nachricht an öffentlichen Kanal gesendet';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Bitte wählen Sie einen Raum zum Senden der SAR-Markierung';

  @override
  String failedToSendSarMarker(String error) {
    return 'Fehler beim Senden der SAR-Markierung: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'SAR-Markierung an $roomName gesendet';
  }

  @override
  String get notConnectedCannotSync =>
      'Nicht verbunden - Nachrichten können nicht synchronisiert werden';

  @override
  String syncedMessageCount(int count) {
    return '$count Nachricht(en) synchronisiert';
  }

  @override
  String get noNewMessages => 'Keine neuen Nachrichten';

  @override
  String syncFailed(String error) {
    return 'Synchronisation fehlgeschlagen: $error';
  }

  @override
  String get failedToResendMessage =>
      'Fehler beim erneuten Senden der Nachricht';

  @override
  String get retryingMessage => 'Wiederhole Nachricht...';

  @override
  String retryFailed(String error) {
    return 'Wiederholen fehlgeschlagen: $error';
  }

  @override
  String get textCopiedToClipboard => 'Text in Zwischenablage kopiert';

  @override
  String get cannotReplySenderMissing =>
      'Antwort nicht möglich: Absenderinformationen fehlen';

  @override
  String get cannotReplyContactNotFound =>
      'Antwort nicht möglich: Kontakt nicht gefunden';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get saveAsTemplate => 'Als Vorlage speichern';

  @override
  String get templateSaved => 'Vorlage erfolgreich gespeichert';

  @override
  String get templateAlreadyExists =>
      'Vorlage mit diesem Emoji existiert bereits';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageConfirmation =>
      'Möchten Sie diese Nachricht wirklich löschen?';

  @override
  String get shareLocation => 'Standort teilen';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nKoordinaten: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR Standort';

  @override
  String get locationShared => 'Standort geteilt';

  @override
  String get refreshedContacts => 'Kontakte aktualisiert';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int minutes) {
    return 'vor ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'vor ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'vor ${days}d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'vor ${seconds}s';
  }

  @override
  String get sending => 'Wird gesendet...';

  @override
  String get sent => 'Gesendet';

  @override
  String get delivered => 'Zugestellt';

  @override
  String deliveredWithTime(int time) {
    return 'Zugestellt (${time}ms)';
  }

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get broadcast => 'Broadcast';

  @override
  String get sarMarkerFoundPerson => 'Person gefunden';

  @override
  String get sarMarkerFire => 'Feuerstandort';

  @override
  String get sarMarkerStagingArea => 'Sammelpunkt';

  @override
  String get sarMarkerObject => 'Objekt gefunden';

  @override
  String get from => 'Von';

  @override
  String get coordinates => 'Koordinaten';

  @override
  String get tapToViewOnMap => 'Tippen, um auf der Karte anzuzeigen';

  @override
  String get radioSettings => 'Funkeinstellungen';

  @override
  String get frequencyMHz => 'Frequenz (MHz)';

  @override
  String get frequencyExample => 'z.B. 869.618';

  @override
  String get bandwidth => 'Bandbreite';

  @override
  String get spreadingFactor => 'Spreading-Faktor';

  @override
  String get codingRate => 'Codierungsrate';

  @override
  String get txPowerDbm => 'TX-Leistung (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Max: $power dBm';
  }

  @override
  String get you => 'Du';

  @override
  String get offlineVectorMaps => 'Offline-Vektorkarten';

  @override
  String get offlineVectorMapsDescription =>
      'Importieren und verwalten Sie Offline-Vektorkarten-Tiles (MBTiles-Format) zur Verwendung ohne Internetverbindung';

  @override
  String get importMbtiles => 'MBTiles-Datei importieren';

  @override
  String get importMbtilesNote =>
      'Unterstützt MBTiles-Dateien mit Vektor-Tiles (PBF/MVT-Format). Geofabrik-Auszüge funktionieren hervorragend!';

  @override
  String get noMbtilesFiles => 'Keine Offline-Vektorkarten gefunden';

  @override
  String get mbtilesImportedSuccessfully =>
      'MBTiles-Datei erfolgreich importiert';

  @override
  String get failedToImportMbtiles =>
      'Fehler beim Importieren der MBTiles-Datei';

  @override
  String get deleteMbtilesConfirmTitle => 'Offline-Karte löschen';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten? Dies entfernt die Offline-Karte dauerhaft.';
  }

  @override
  String get mbtilesDeletedSuccessfully => 'Offline-Karte erfolgreich gelöscht';

  @override
  String get failedToDeleteMbtiles => 'Fehler beim Löschen der Offline-Karte';

  @override
  String get importExportCachedTiles => 'Import/Export gecachter Kacheln';

  @override
  String get importExportDescription =>
      'Sichern, teilen und wiederherstellen Sie heruntergeladene Kartenkacheln zwischen Geräten';

  @override
  String get exportTilesToFile => 'Kacheln in Datei exportieren';

  @override
  String get importTilesFromFile => 'Kacheln aus Datei importieren';

  @override
  String get selectExportLocation => 'Exportspeicherort wählen';

  @override
  String get selectImportFile => 'Kachel-Archiv auswählen';

  @override
  String get exportingTiles => 'Exportiere Kacheln...';

  @override
  String get importingTiles => 'Importiere Kacheln...';

  @override
  String exportSuccess(int count) {
    return '$count Kacheln erfolgreich exportiert';
  }

  @override
  String importSuccess(int count) {
    return '$count Speicher erfolgreich importiert';
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
      'Erstellt eine komprimierte Archivdatei (.fmtc), die auf anderen Geräten geteilt und importiert werden kann.';

  @override
  String get importNote =>
      'Importiert Kartenkacheln aus einer zuvor exportierten Archivdatei. Kacheln werden mit dem vorhandenen Cache zusammengeführt.';

  @override
  String get noTilesToExport => 'Keine Kacheln zum Exportieren verfügbar';

  @override
  String archiveContainsStores(int count) {
    return 'Archiv enthält $count Speicher';
  }

  @override
  String get vectorTiles => 'Vektor-Tiles';

  @override
  String get schema => 'Schema';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get bounds => 'Grenzen';

  @override
  String get onlineLayers => 'Online-Ebenen';

  @override
  String get offlineLayers => 'Offline-Ebenen';

  @override
  String get locationTrail => 'Standortverlauf';

  @override
  String get showTrailOnMap => 'Verlauf auf Karte anzeigen';

  @override
  String get trailVisible => 'Verlauf ist auf der Karte sichtbar';

  @override
  String get trailHiddenRecording =>
      'Verlauf ist ausgeblendet (Aufzeichnung läuft noch)';

  @override
  String get duration => 'Dauer';

  @override
  String get points => 'Punkte';

  @override
  String get clearTrail => 'Verlauf löschen';

  @override
  String get clearTrailQuestion => 'Verlauf löschen?';

  @override
  String get clearTrailConfirmation =>
      'Sind Sie sicher, dass Sie den aktuellen Standortverlauf löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get noTrailRecorded => 'Noch kein Verlauf aufgezeichnet';

  @override
  String get startTrackingToRecord =>
      'Standort-Tracking starten, um Ihren Verlauf aufzuzeichnen';

  @override
  String get trailControls => 'Verlaufssteuerung';

  @override
  String get deviceInformation => 'Geräteinformationen';

  @override
  String get bleName => 'BLE-Name';

  @override
  String get meshName => 'Mesh-Name';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get model => 'Modell';

  @override
  String get version => 'Version';

  @override
  String get buildDate => 'Build-Datum';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Max. Kontakte';

  @override
  String get maxChannels => 'Max. Kanäle';

  @override
  String get publicInfo => 'Öffentliche Informationen';

  @override
  String get meshNetworkName => 'Mesh-Netzwerkname';

  @override
  String get nameBroadcastInMesh =>
      'Name, der in Mesh-Sendungen übertragen wird';

  @override
  String get telemetryAndLocationSharing => 'Telemetrie & Standortfreigabe';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get noneUnknown => 'Keine/Unbekannt';

  @override
  String get chatNode => 'Chat-Knoten';

  @override
  String get repeater => 'Repeater';

  @override
  String get roomChannel => 'Raum/Kanal';

  @override
  String typeNumber(int number) {
    return 'Typ $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label in Zwischenablage kopiert';
  }

  @override
  String failedToSave(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Fehler beim Abrufen des Standorts: $error';
  }

  @override
  String get sarTemplates => 'SAR-Vorlagen';

  @override
  String get manageSarTemplates => 'SAR-Vorlagen verwalten';

  @override
  String get addTemplate => 'Vorlage hinzufügen';

  @override
  String get editTemplate => 'Vorlage bearbeiten';

  @override
  String get deleteTemplate => 'Vorlage löschen';

  @override
  String get templateName => 'Vorlagenname';

  @override
  String get templateNameHint => 'e.g. Found Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji ist erforderlich';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Importieren';

  @override
  String get exportToClipboard => 'Exportieren';

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
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get resetToDefaultsConfirmation =>
      'Dadurch werden alle benutzerdefinierten Vorlagen gelöscht und die 4 Standardvorlagen wiederhergestellt. Fortfahren?';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetComplete => 'Vorlagen auf Standard zurückgesetzt';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Berechtigungen';

  @override
  String get locationPermission => 'Standortberechtigung';

  @override
  String get checking => 'Überprüfen...';

  @override
  String get locationPermissionGrantedAlways => 'Erteilt (Immer)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Erteilt (Während der Nutzung)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Verweigert - Tippen zum Anfragen';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Dauerhaft verweigert - Einstellungen öffnen';

  @override
  String get locationPermissionDialogContent =>
      'Die Standortberechtigung wurde dauerhaft verweigert. Bitte aktivieren Sie sie in Ihren Geräteeinstellungen, um GPS-Tracking und Standortfreigabe zu nutzen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get locationPermissionGranted => 'Standortberechtigung erteilt!';

  @override
  String get locationPermissionRequiredForGps =>
      'Die Standortberechtigung ist erforderlich für GPS-Tracking und Standortfreigabe.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Die Standortberechtigung wurde bereits erteilt.';

  @override
  String get sarNavyBlue => 'SAR Navy Blau';

  @override
  String get sarNavyBlueDescription => 'Professionell/Einsatzmodus';

  @override
  String get selectRecipient => 'Empfänger auswählen';

  @override
  String get broadcastToAllNearby => 'An alle in der Nähe senden';

  @override
  String get searchRecipients => 'Empfänger suchen...';

  @override
  String get noContactsFound => 'Keine Kontakte gefunden';

  @override
  String get noRoomsFound => 'Keine Räume gefunden';

  @override
  String get noContactsOrRoomsAvailable =>
      'Keine Kontakte oder Räume verfügbar';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'Nachrichten werden an öffentlichen Kanal gesendet';

  @override
  String get newMessage => 'Neue Nachricht';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Polizeiführer';

  @override
  String get sampleDroneOperator => 'Drohnenbediener';

  @override
  String get sampleFirefighterAlpha => 'Feuerwehrmann';

  @override
  String get sampleMedicCharlie => 'Sanitäter';

  @override
  String get sampleCommandDelta => 'Kommando';

  @override
  String get sampleFireEngine => 'Feuerwehrfahrzeug';

  @override
  String get sampleAirSupport => 'Luftunterstützung';

  @override
  String get sampleBaseCoordinator => 'Basiskoordinator';

  @override
  String get channelEmergency => 'Notfall';

  @override
  String get channelCoordination => 'Koordination';

  @override
  String get channelUpdates => 'Aktualisierungen';

  @override
  String get sampleTeamMember => 'Beispiel-Teammitglied';

  @override
  String get sampleScout => 'Beispiel-Späher';

  @override
  String get sampleBase => 'Beispiel-Basis';

  @override
  String get sampleSearcher => 'Beispiel-Sucher';

  @override
  String get sampleObjectBackpack => ' Rucksack gefunden - blaue Farbe';

  @override
  String get sampleObjectVehicle => ' Fahrzeug verlassen - Besitzer prüfen';

  @override
  String get sampleObjectCamping => ' Campingausrüstung entdeckt';

  @override
  String get sampleObjectTrailMarker =>
      ' Wegmarkierung abseits des Pfades gefunden';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Alle Teams melden';

  @override
  String get sampleMsgWeatherUpdate =>
      'Wetterupdate: Klarer Himmel, Temp. 18°C';

  @override
  String get sampleMsgBaseCamp => 'Basislager am Sammelplatz eingerichtet';

  @override
  String get sampleMsgTeamAlpha => 'Team bewegt sich zu Sektor 2';

  @override
  String get sampleMsgRadioCheck => 'Funkcheck - alle Stationen antworten';

  @override
  String get sampleMsgWaterSupply =>
      'Wasserversorgung verfügbar an Kontrollpunkt 3';

  @override
  String get sampleMsgTeamBravo => 'Team meldet: Sektor 1 frei';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Ankunftszeit am Sammelpunkt: 15 Minuten';

  @override
  String get sampleMsgSupplyDrop => 'Versorgungsabwurf bestätigt für 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Drohnenüberwachung abgeschlossen - keine Funde';

  @override
  String get sampleMsgTeamCharlie => 'Team fordert Unterstützung an';

  @override
  String get sampleMsgRadioDiscipline =>
      'An alle Einheiten: Funkdisziplin wahren';

  @override
  String get sampleMsgUrgentMedical =>
      'DRINGEND: Medizinische Hilfe benötigt in Sektor 4';

  @override
  String get sampleMsgAdultMale => ' Erwachsener Mann, bei Bewusstsein';

  @override
  String get sampleMsgFireSpotted => 'Feuer gesichtet - Koordinaten folgen';

  @override
  String get sampleMsgSpreadingRapidly => ' Breitet sich schnell aus!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITÄT: Brauche Hubschrauberunterstützung';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medizinisches Team auf dem Weg zu Ihrem Standort';

  @override
  String get sampleMsgEvacHelicopter =>
      'Evakuierungshubschrauber ETA 10 Minuten';

  @override
  String get sampleMsgEmergencyResolved => 'Notfall behoben - alles klar';

  @override
  String get sampleMsgEmergencyStagingArea => ' Notfall-Sammelplatz';

  @override
  String get sampleMsgEmergencyServices =>
      'Rettungsdienste benachrichtigt und auf dem Weg';

  @override
  String get sampleAlphaTeamLead => 'Team-Leiter';

  @override
  String get sampleBravoScout => 'Späher';

  @override
  String get sampleCharlieMedic => 'Sanitäter';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Unterstützung';

  @override
  String get sampleBaseCommand => 'Basis-Kommando';

  @override
  String get sampleFieldCoordinator => 'Feldkoordinator';

  @override
  String get sampleMedicalTeam => 'Medizinisches Team';

  @override
  String get mapDrawing => 'Kartenzeichnung';

  @override
  String get navigateToDrawing => 'Zur Zeichnung navigieren';

  @override
  String get copyCoordinates => 'Koordinaten kopieren';

  @override
  String get hideFromMap => 'Von Karte ausblenden';

  @override
  String get lineDrawing => 'Linie';

  @override
  String get rectangleDrawing => 'Rechteck';

  @override
  String get coordinatesCopiedToClipboard =>
      'Koordinaten in Zwischenablage kopiert';

  @override
  String get drawingShared => 'Kartenzeichnung';

  @override
  String get drawingHidden => 'Zeichnung von Karte ausgeblendet';

  @override
  String alreadyShared(int count) {
    return '$count bereits geteilt';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return '$count neue Zeichnung(en) geteilt';
  }

  @override
  String get shareDrawing => 'Zeichnung teilen';

  @override
  String get shareWithAllNearbyDevices =>
      'Mit allen Geräten in der Nähe teilen';

  @override
  String get shareToRoom => 'In Raum teilen';

  @override
  String get sendToPersistentStorage => 'An persistenten Raum-Speicher senden';

  @override
  String get deleteDrawingConfirm =>
      'Möchten Sie diese Zeichnung wirklich löschen?';

  @override
  String get drawingDeleted => 'Zeichnung gelöscht';

  @override
  String yourDrawingsCount(int count) {
    return 'Ihre Zeichnungen ($count)';
  }

  @override
  String get shared => 'Geteilt';

  @override
  String get line => 'Linie';

  @override
  String get rectangle => 'Rechteck';

  @override
  String get updateAvailable => 'Update Verfügbar';

  @override
  String get currentVersion => 'Aktuell';

  @override
  String get latestVersion => 'Neueste';

  @override
  String get downloadUpdate => 'Herunterladen';

  @override
  String get updateLater => 'Später';

  @override
  String get cadastralParcels => 'Katasterparzellen';

  @override
  String get forestRoads => 'Waldwege';

  @override
  String get showCadastralParcels => 'Katasterparzellen anzeigen';

  @override
  String get showForestRoads => 'Waldwege anzeigen';

  @override
  String get wmsOverlays => 'WMS Überlagerungen';

  @override
  String get recentMessages => 'Aktuelle Nachrichten';
}
