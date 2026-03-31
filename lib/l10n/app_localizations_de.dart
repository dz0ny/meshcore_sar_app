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
  String failedToAdvertise(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get cancelReconnection => 'Wiederverbindung abbrechen';

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
  String get disableMap => 'Karte deaktivieren';

  @override
  String get disableMapDescription =>
      'Karten-Tab ausblenden, um Akku zu sparen';

  @override
  String get language => 'Sprache';

  @override
  String get chooseLanguage => 'Sprache auswählen';

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
  String get publicChannel => 'Öffentlicher Kanal';

  @override
  String get broadcastToAll => 'An alle Knoten in der Nähe senden (temporär)';

  @override
  String get storedPermanently => 'Dauerhaft im Raum gespeichert';

  @override
  String get notConnectedToDevice => 'Nicht mit Gerät verbunden';

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
  String get loggedIn => 'Angemeldet';

  @override
  String get noGpsData => 'Keine GPS-Daten';

  @override
  String get distance => 'Entfernung';

  @override
  String directPingTimeout(String name) {
    return 'Direkter Ping-Timeout - wiederhole $name mit Flutung...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping fehlgeschlagen an $name - keine Antwort erhalten';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten?\n\nDies entfernt den Kontakt sowohl aus der App als auch vom Begleitfunkgerät.';
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
    return 'Breite: $latitude Lange: $longitude';
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
  String get selectMapLayer => 'Kartenebene auswählen';

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
  String get textCopiedToClipboard => 'Text in Zwischenablage kopiert';

  @override
  String get cannotReplySenderMissing =>
      'Antwort nicht möglich: Absenderinformationen fehlen';

  @override
  String get cannotReplyContactNotFound =>
      'Antwort nicht möglich: Kontakt nicht gefunden';

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
  String get broadcast => 'Rundspruch';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Zugestellt an $delivered/$total Kontakte';
  }

  @override
  String get allDelivered => 'Alle zugestellt';

  @override
  String get recipientDetails => 'Empfängerdetails';

  @override
  String get pending => 'Ausstehend';

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
    return 'Max.: $power dBm';
  }

  @override
  String get you => 'Du';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get unknown => 'Unbekannt';

  @override
  String get onlineLayers => 'Online-Ebenen';

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
  String get contactTrails => 'Kontaktverläufe';

  @override
  String get showAllContactTrails => 'Alle Kontaktverläufe anzeigen';

  @override
  String get noContactsWithLocationHistory =>
      'Keine Kontakte mit Standortverlauf';

  @override
  String showingTrailsForContacts(int count) {
    return 'Verläufe für $count Kontakte anzeigen';
  }

  @override
  String get individualContactTrails => 'Einzelne Kontaktverläufe';

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
  String get lat => 'Breite';

  @override
  String get lon => 'Lange';

  @override
  String get useCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get noneUnknown => 'Keine/Unbekannt';

  @override
  String get chatNode => 'Chat-Knoten';

  @override
  String get repeater => 'Relais';

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
  String get templateNameHint => 'z. B. Gefundene Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji ist erforderlich';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get templateDescription => 'Beschreibung (optional)';

  @override
  String get templateDescriptionHint => 'Zusatzlichen Kontext hinzufugen...';

  @override
  String get templateColor => 'Farbe';

  @override
  String get previewFormat => 'Vorschau (SAR-Nachrichtenformat)';

  @override
  String get importFromClipboard => 'Importieren';

  @override
  String get exportToClipboard => 'Exportieren';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Vorlage \'$name\' loschen?';
  }

  @override
  String get templateAdded => 'Vorlage hinzugefugt';

  @override
  String get templateUpdated => 'Vorlage aktualisiert';

  @override
  String get templateDeleted => 'Vorlage geloscht';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorlagen importiert',
      one: '1 Vorlage importiert',
      zero: 'Keine Vorlagen importiert',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorlagen in die Zwischenablage exportiert',
      one: '1 Vorlage in die Zwischenablage exportiert',
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
  String get noTemplates => 'Keine Vorlagen verfugbar';

  @override
  String get tapAddToCreate =>
      'Tippen Sie auf +, um Ihre erste Vorlage zu erstellen';

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
  String get noRecipientsAvailable => 'Keine Empfänger verfügbar';

  @override
  String get noChannelsFound => 'Keine Kanäle gefunden';

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
  String get manualCoordinates => 'Manuelle Koordinaten';

  @override
  String get enterCoordinatesManually => 'Koordinaten manuell eingeben';

  @override
  String get latitudeLabel => 'Breitengrad';

  @override
  String get longitudeLabel => 'Längengrad';

  @override
  String get exampleCoordinates => 'Beispiel: 46.0569, 14.5058';

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
  String get wmsOverlays => 'WMS Überlagerungen';

  @override
  String get hikingTrails => 'Wanderwege';

  @override
  String get mainRoads => 'Hauptstraßen';

  @override
  String get houseNumbers => 'Hausnummern';

  @override
  String get fireHazardZones => 'Brandgefährdungszonen';

  @override
  String get historicalFires => 'Historische Brände';

  @override
  String get firebreaks => 'Brandschneisen';

  @override
  String get krasFireZones => 'Kras-Brandzonen';

  @override
  String get placeNames => 'Ortsnamen';

  @override
  String get municipalityBorders => 'Gemeindegrenzen';

  @override
  String get topographicMap => 'Topographische Karte 1:25000';

  @override
  String get recentMessages => 'Aktuelle Nachrichten';

  @override
  String get addChannel => 'Kanal hinzufügen';

  @override
  String get channelName => 'Kanalname';

  @override
  String get channelNameHint => 'z.B. Rettungsteam Alpha';

  @override
  String get channelSecret => 'Kanal-Passwort';

  @override
  String get channelSecretHint => 'Gemeinsames Passwort für diesen Kanal';

  @override
  String get channelSecretHelp =>
      'Dieses Passwort muss mit allen Teammitgliedern geteilt werden, die Zugriff auf diesen Kanal benötigen';

  @override
  String get channelTypesInfo =>
      'Hash-Kanäle (#team): Passwort automatisch aus dem Namen generiert. Gleicher Name = gleicher Kanal auf allen Geräten.\n\nPrivate Kanäle: Verwenden Sie ein explizites Passwort. Nur diejenigen mit dem Passwort können beitreten.';

  @override
  String get hashChannelInfo =>
      'Hash-Kanal: Das Passwort wird automatisch aus dem Kanalnamen generiert. Jeder, der denselben Namen verwendet, wird demselben Kanal beitreten.';

  @override
  String get channelNameRequired => 'Kanalname ist erforderlich';

  @override
  String get channelNameTooLong =>
      'Kanalname darf maximal 31 Zeichen lang sein';

  @override
  String get channelSecretRequired => 'Kanal-Passwort ist erforderlich';

  @override
  String get channelSecretTooLong =>
      'Kanal-Passwort darf maximal 32 Zeichen lang sein';

  @override
  String get invalidAsciiCharacters => 'Nur ASCII-Zeichen sind erlaubt';

  @override
  String get channelCreatedSuccessfully => 'Kanal erfolgreich erstellt';

  @override
  String channelCreationFailed(String error) {
    return 'Kanal konnte nicht erstellt werden: $error';
  }

  @override
  String get deleteChannel => 'Kanal löschen';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Sind Sie sicher, dass Sie den Kanal \"$channelName\" löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal erfolgreich gelöscht';

  @override
  String channelDeletionFailed(String error) {
    return 'Kanal konnte nicht gelöscht werden: $error';
  }

  @override
  String get createChannel => 'Kanal erstellen';

  @override
  String get wizardBack => 'Zurück';

  @override
  String get wizardSkip => 'Überspringen';

  @override
  String get wizardNext => 'Weiter';

  @override
  String get wizardGetStarted => 'Loslegen';

  @override
  String get wizardWelcomeTitle => 'Willkommen bei MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'Ein leistungsstarkes Offline-Kommunikationstool für Such- und Rettungseinsätze. Verbinden Sie sich mit Ihrem Team über Mesh-Funktechnologie, wenn herkömmliche Netzwerke nicht verfügbar sind.';

  @override
  String get wizardConnectingTitle => 'Verbindung zum Radio';

  @override
  String get wizardConnectingDescription =>
      'Verbinden Sie Ihr Smartphone über Bluetooth mit einem MeshCore-Funkgerät, um offline zu kommunizieren.';

  @override
  String get wizardConnectingFeature1 =>
      'Nach MeshCore-Geräten in der Nähe suchen';

  @override
  String get wizardConnectingFeature2 =>
      'Mit Ihrem Funkgerät über Bluetooth koppeln';

  @override
  String get wizardConnectingFeature3 =>
      'Funktioniert vollständig offline - kein Internet erforderlich';

  @override
  String get wizardChannelTitle => 'Kanäle';

  @override
  String get wizardChannelDescription =>
      'Senden Sie Nachrichten an alle auf einem Kanal, perfekt für teamweite Ankündigungen und Koordination.';

  @override
  String get wizardChannelFeature1 =>
      'Öffentlicher Kanal für allgemeine Teamkommunikation';

  @override
  String get wizardChannelFeature2 =>
      'Erstellen Sie benutzerdefinierte Kanäle für bestimmte Gruppen';

  @override
  String get wizardChannelFeature3 =>
      'Nachrichten werden automatisch über das Mesh weitergeleitet';

  @override
  String get wizardContactsTitle => 'Kontakte';

  @override
  String get wizardContactsDescription =>
      'Ihre Teammitglieder erscheinen automatisch, wenn sie dem Mesh-Netzwerk beitreten. Senden Sie ihnen direkte Nachrichten oder sehen Sie ihren Standort.';

  @override
  String get wizardContactsFeature1 => 'Kontakte werden automatisch erkannt';

  @override
  String get wizardContactsFeature2 => 'Private Direktnachrichten senden';

  @override
  String get wizardContactsFeature3 =>
      'Batteriestand und letzte Aktivität anzeigen';

  @override
  String get wizardMapTitle => 'Karte & Standort';

  @override
  String get wizardMapDescription =>
      'Verfolgen Sie Ihr Team in Echtzeit und markieren Sie wichtige Standorte für Such- und Rettungseinsätze.';

  @override
  String get wizardMapFeature1 =>
      'SAR-Markierungen für gefundene Personen, Feuer und Sammelstellen';

  @override
  String get wizardMapFeature2 =>
      'GPS-Verfolgung von Teammitgliedern in Echtzeit';

  @override
  String get wizardMapFeature3 =>
      'Offline-Karten für entlegene Gebiete herunterladen';

  @override
  String get wizardMapFeature4 =>
      'Formen zeichnen und taktische Informationen teilen';

  @override
  String get viewWelcomeTutorial => 'Willkommens-Tutorial ansehen';

  @override
  String get allTeamContacts => 'Alle Team-Kontakte';

  @override
  String directMessagesInfo(int count) {
    return 'Direktnachrichten mit Bestätigungen. An $count Teammitglieder gesendet.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR-Marker an $count Kontakte gesendet';
  }

  @override
  String get noContactsAvailable => 'Keine Team-Kontakte verfügbar';

  @override
  String get reply => 'Antworten';

  @override
  String get technicalDetails => 'Technische Details';

  @override
  String get messageTechnicalDetails => 'Technische Nachrichtendetails';

  @override
  String get linkQuality => 'Verbindungsqualität';

  @override
  String get delivery => 'Zustellung';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Erwartetes ACK-Tag';

  @override
  String get roundTrip => 'Roundtrip';

  @override
  String get retryAttempt => 'Wiederholungsversuch';

  @override
  String get floodFallback => 'Flood-Fallback';

  @override
  String get identity => 'Identität';

  @override
  String get messageId => 'Nachrichten-ID';

  @override
  String get sender => 'Absender';

  @override
  String get senderKey => 'Absenderschlüssel';

  @override
  String get recipient => 'Empfänger';

  @override
  String get recipientKey => 'Empfängerschlüssel';

  @override
  String get voice => 'Sprachnachricht';

  @override
  String get voiceId => 'Sprach-ID';

  @override
  String get envelope => 'Umschlag';

  @override
  String get sessionProgress => 'Sitzungsfortschritt';

  @override
  String get complete => 'Vollständig';

  @override
  String get rawDump => 'Rohdaten';

  @override
  String get cannotRetryMissingRecipient =>
      'Wiederholung nicht möglich: Empfängerinformationen fehlen';

  @override
  String get voiceUnavailable => 'Sprachnachricht momentan nicht verfügbar';

  @override
  String get requestingVoice => 'Sprachnachricht wird angefordert';

  @override
  String get device => 'Gerät';

  @override
  String get change => 'Ändern';

  @override
  String get wizardOverviewDescription =>
      'Diese App vereint MeshCore-Nachrichten, SAR-Feldupdates, Karten und Gerätetools an einem Ort.';

  @override
  String get wizardOverviewFeature1 =>
      'Sende Direkt-, Raum- und Kanalnachrichten aus dem Haupttab \"Nachrichten\".';

  @override
  String get wizardOverviewFeature2 =>
      'Teile SAR-Markierungen, Kartenzeichnungen, Sprachclips und Bilder über das Mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Verbinde dich per BLE oder TCP und verwalte dann das Begleitfunkgerät direkt in der App.';

  @override
  String get wizardMessagingTitle => 'Nachrichten und Feldberichte';

  @override
  String get wizardMessagingDescription =>
      'Nachrichten sind hier mehr als nur Klartext. Die App unterstützt bereits mehrere operative Datentypen und Übertragungsabläufe.';

  @override
  String get wizardMessagingFeature1 =>
      'Sende Direktnachrichten, Raumbeiträge und Kanalverkehr aus einem einzigen Editor.';

  @override
  String get wizardMessagingFeature2 =>
      'Erstelle SAR-Updates und wiederverwendbare SAR-Vorlagen für häufige Feldberichte.';

  @override
  String get wizardMessagingFeature3 =>
      'Übertrage Sprachsitzungen und Bilder mit Fortschritts- und Airtime-Anzeigen in der Oberfläche.';

  @override
  String get wizardConnectDeviceTitle => 'Gerät verbinden';

  @override
  String get wizardConnectDeviceDescription =>
      'Verbinde dein MeshCore-Funkgerät, wähle einen Namen und wende ein Funkprofil an, bevor du fortfährst.';

  @override
  String get wizardSetupBadge => 'Einrichtung';

  @override
  String get wizardOverviewBadge => 'Überblick';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Verbunden mit $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Noch kein Gerät verbunden';

  @override
  String get wizardSkipForNow => 'Vorerst überspringen';

  @override
  String get wizardDeviceNameLabel => 'Gerätename';

  @override
  String get wizardDeviceNameHelp =>
      'Dieser Name wird an andere MeshCore-Nutzer ausgesendet.';

  @override
  String get wizardConfigRegionLabel => 'Konfigurationsregion';

  @override
  String get wizardConfigRegionHelp =>
      'Verwendet die vollständige offizielle Liste der MeshCore-Voreinstellungen. Standard ist EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Stelle sicher, dass die ausgewählte Voreinstellung zu deinen lokalen Funkvorschriften passt.';

  @override
  String get wizardPresetNote2 =>
      'Die Liste entspricht dem offiziellen Preset-Feed des MeshCore-Konfigurationstools.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) bleibt standardmäßig für das Onboarding ausgewählt.';

  @override
  String get wizardSaving => 'Wird gespeichert...';

  @override
  String get wizardSaveAndContinue => 'Speichern und fortfahren';

  @override
  String get wizardEnterDeviceName =>
      'Gib vor dem Fortfahren einen Gerätenamen ein.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '$deviceName mit $presetName gespeichert.';
  }

  @override
  String get wizardNetworkTitle => 'Kontakte, Räume und Repeater';

  @override
  String get wizardNetworkDescription =>
      'Der Kontakte-Tab organisiert das Netzwerk, das du entdeckst, und die Routen, die im Laufe der Zeit gelernt werden.';

  @override
  String get wizardNetworkFeature1 =>
      'Prüfe Teammitglieder, Repeater, Räume, Kanäle und ausstehende Adverts in einer Liste.';

  @override
  String get wizardNetworkFeature2 =>
      'Nutze Smart Ping, Raum-Login, gelernte Pfade und Pfad-Reset-Tools, wenn die Verbindung unübersichtlich wird.';

  @override
  String get wizardNetworkFeature3 =>
      'Erstelle Kanäle und verwalte Netzwerkziele, ohne die App zu verlassen.';

  @override
  String get wizardMapOpsTitle => 'Karte, Spuren und geteilte Geometrie';

  @override
  String get wizardMapOpsDescription =>
      'Die Karte der App ist direkt mit Nachrichten, Tracking und SAR-Overlays verbunden, statt nur ein separater Viewer zu sein.';

  @override
  String get wizardMapOpsFeature1 =>
      'Verfolge deine eigene Position, Teamstandorte und Bewegungsspuren auf der Karte.';

  @override
  String get wizardMapOpsFeature2 =>
      'Öffne Zeichnungen aus Nachrichten, prüfe sie inline und entferne sie bei Bedarf von der Karte.';

  @override
  String get wizardMapOpsFeature3 =>
      'Nutze Repeater-Kartenansichten und geteilte Overlays, um die Netzabdeckung im Feld zu verstehen.';

  @override
  String get wizardToolsTitle => 'Werkzeuge jenseits von Nachrichten';

  @override
  String get wizardToolsDescription =>
      'Es gibt hier mehr als nur die vier Haupttabs. Die App enthält außerdem Konfiguration, Diagnose und optionale Sensor-Workflows.';

  @override
  String get wizardToolsFeature1 =>
      'Öffne die Gerätekonfiguration, um Funkparameter, Telemetrie, Sendeleistung und Begleitdetails zu ändern.';

  @override
  String get wizardToolsFeature2 =>
      'Aktiviere den Sensoren-Tab, wenn du überwachte Sensor-Dashboards und schnelle Aktualisierungen möchtest.';

  @override
  String get wizardToolsFeature3 =>
      'Nutze Paketprotokolle, Spektrumsuche und Entwicklerdiagnosen zur Fehlersuche im Mesh.';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => 'In Sensoren';

  @override
  String get contactAddToSensors => 'Zu Sensoren hinzufügen';

  @override
  String get contactSetPath => 'Pfad festlegen';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName zu Sensoren hinzugefügt';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Pfad konnte nicht gelöscht werden: $error';
  }

  @override
  String get contactRouteCleared => 'Pfad gelöscht';

  @override
  String contactRouteSet(String route) {
    return 'Pfad gesetzt: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Pfad konnte nicht gesetzt werden: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'ACK-Zeitüberschreitung';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Nutzlast';

  @override
  String get hops => 'Hops';

  @override
  String get hashSize => 'Hash-Größe';

  @override
  String get pathBytes => 'Pfad-Bytes';

  @override
  String get selectedPath => 'Ausgewählter Pfad';

  @override
  String get estimatedTx => 'Geschätzte Sendung';

  @override
  String get senderToReceipt => 'Sender bis Empfang';

  @override
  String get receivedCopies => 'Empfangene Kopien';

  @override
  String get retryCause => 'Wiederholungsursache';

  @override
  String get retryMode => 'Wiederholungsmodus';

  @override
  String get retryResult => 'Wiederholungsergebnis';

  @override
  String get lastRetry => 'Letzter Versuch';

  @override
  String get rxPackets => 'RX-Pakete';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Rate';

  @override
  String get window => 'Fenster';

  @override
  String get posttxDelay => 'Sendeverzögerung';

  @override
  String get bandpass => 'Bandpass';

  @override
  String get bandpassFilterVoice => 'Bandpassfilter Sprache';

  @override
  String get frequency => 'Frequenz';

  @override
  String get australia => 'Australien';

  @override
  String get australiaNarrow => 'Australien (Schmal)';

  @override
  String get australiaQld => 'Australien: QLD';

  @override
  String get australiaSaWa => 'Australien: SA, WA';

  @override
  String get newZealand => 'Neuseeland';

  @override
  String get newZealandNarrow => 'Neuseeland (Schmal)';

  @override
  String get switzerland => 'Schweiz';

  @override
  String get portugal433 => 'Portugal 433';

  @override
  String get portugal868 => 'Portugal 868';

  @override
  String get czechRepublicNarrow => 'Tschechien (Schmal)';

  @override
  String get eu433mhzLongRange => 'EU 433MHz (Langstrecke)';

  @override
  String get euukDeprecated => 'EU/UK (Veraltet)';

  @override
  String get euukNarrow => 'EU/UK (Schmal)';

  @override
  String get usacanadaRecommended => 'USA/Kanada (Empfohlen)';

  @override
  String get vietnamDeprecated => 'Vietnam (Veraltet)';

  @override
  String get vietnamNarrow => 'Vietnam (Schmal)';

  @override
  String get active => 'Aktiv';

  @override
  String get addContact => 'Kontakt hinzufügen';

  @override
  String get all => 'Alle';

  @override
  String get autoResolve => 'Automatisch auflösen';

  @override
  String get clearAllLabel => 'Alle löschen';

  @override
  String get clearRelays => 'Relais löschen';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get clearRoute => 'Route löschen';

  @override
  String get clearMessages => 'Nachrichten löschen';

  @override
  String get clearScale => 'Maßstab löschen';

  @override
  String get clearDiscoveries => 'Entdeckungen löschen';

  @override
  String get clearOnlineTraceDatabase => 'Online-Trace-Datenbank löschen';

  @override
  String get clearAllChannels => 'Alle Kanäle löschen';

  @override
  String get clearAllContacts => 'Alle Kontakte löschen';

  @override
  String get clearChannels => 'Kanäle löschen';

  @override
  String get clearContacts => 'Kontakte löschen';

  @override
  String get clearPathOnMaxRetry => 'Pfad bei max. Wiederholung löschen';

  @override
  String get create => 'Erstellen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get defaultValue => 'Standard';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get editName => 'Name bearbeiten';

  @override
  String get open => 'Öffnen';

  @override
  String get paste => 'Einfügen';

  @override
  String get preview => 'Vorschau';

  @override
  String get remove => 'Entfernen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get resolveAll => 'Alle auflösen';

  @override
  String get send => 'Senden';

  @override
  String get sendAnyway => 'Trotzdem senden';

  @override
  String get share => 'Teilen';

  @override
  String get shareContact => 'Kontakt teilen';

  @override
  String get trace => 'Trace';

  @override
  String get use => 'Verwenden';

  @override
  String get useSelectedFrequency => 'Ausgewählte Frequenz verwenden';

  @override
  String get discovery => 'Erkennung';

  @override
  String get discoverRepeaters => 'Repeater entdecken';

  @override
  String get discoverSensors => 'Sensoren entdecken';

  @override
  String get repeaterDiscoverySent => 'Repeater-Erkennung gesendet';

  @override
  String get sensorDiscoverySent => 'Sensor-Erkennung gesendet';

  @override
  String get clearedPendingDiscoveries => 'Ausstehende Entdeckungen gelöscht.';

  @override
  String get autoDiscovery => 'Automatische Erkennung';

  @override
  String get enableAutomaticAdding => 'Automatisches Hinzufügen aktivieren';

  @override
  String get autoaddRepeaters => 'Repeater automatisch hinzufügen';

  @override
  String get autoaddRoomServers => 'Raumserver automatisch hinzufügen';

  @override
  String get autoaddSensors => 'Sensoren automatisch hinzufügen';

  @override
  String get autoaddUsers => 'Benutzer automatisch hinzufügen';

  @override
  String get overwriteOldestWhenFull =>
      'Älteste bei vollem Speicher überschreiben';

  @override
  String get storage => 'Speicher';

  @override
  String get dangerZone => 'Gefahrenbereich';

  @override
  String get profiles => 'Profile';

  @override
  String get favourites => 'Favoriten';

  @override
  String get sensors => 'Sensoren';

  @override
  String get others => 'Andere';

  @override
  String get gpsModule => 'GPS-Modul';

  @override
  String get liveTraffic => 'Live-Verkehr';

  @override
  String get repeatersMap => 'Repeater-Karte';

  @override
  String get spectrumScan => 'Spektrum-Scan';

  @override
  String get blePacketLogs => 'BLE-Paketprotokolle';

  @override
  String get onlineTraceDatabase => 'Online-Trace-Datenbank';

  @override
  String get routePathByteSize => 'Pfad-Bytegröße';

  @override
  String get messageNotifications => 'Nachrichtenbenachrichtigungen';

  @override
  String get sarAlerts => 'SAR-Alarme';

  @override
  String get discoveryNotifications => 'Erkennungsbenachrichtigungen';

  @override
  String get updateNotifications => 'Updatebenachrichtigungen';

  @override
  String get muteWhileAppIsOpen => 'Stumm bei geöffneter App';

  @override
  String get disableContacts => 'Kontakte deaktivieren';

  @override
  String get enableSensorsTab => 'Sensoren-Tab aktivieren';

  @override
  String get enableProfiles => 'Profile aktivieren';

  @override
  String get autoRouteRotation => 'Automatische Routenrotation';

  @override
  String get nearestRepeaterFallback => 'Nächster Repeater als Fallback';

  @override
  String get deleteAllStoredMessageHistory =>
      'Gesamten Nachrichtenverlauf löschen';

  @override
  String get messageFontSize => 'Nachrichtenschriftgröße';

  @override
  String get rotateMapWithHeading => 'Karte mit Richtung drehen';

  @override
  String get showMapDebugInfo => 'Karten-Debug-Info anzeigen';

  @override
  String get openMapInFullscreen => 'Karte im Vollbild öffnen';

  @override
  String get showSarMarkersLabel => 'SAR-Markierungen anzeigen';

  @override
  String get displaySarMarkersOnTheMainMap =>
      'SAR-Markierungen auf der Hauptkarte anzeigen';

  @override
  String get showAllContactTrailsLabel => 'Alle Kontaktpfade anzeigen';

  @override
  String get hideRepeatersOnMap => 'Repeater auf Karte ausblenden';

  @override
  String get setMapScale => 'Kartenmaßstab einstellen';

  @override
  String get customMapScaleSaved =>
      'Benutzerdefinierter Kartenmaßstab gespeichert';

  @override
  String get voiceBitrate => 'Sprach-Bitrate';

  @override
  String get voiceCompressor => 'Sprachkompressor';

  @override
  String get balancesQuietAndLoudSpeechLevels =>
      'Gleicht leise und laute Sprache aus';

  @override
  String get voiceLimiter => 'Sprach-Limiter';

  @override
  String get preventsClippingPeaksBeforeEncoding =>
      'Verhindert Clipping-Spitzen vor der Kodierung';

  @override
  String get micAutoGain => 'Mikrofon-Automatik';

  @override
  String get letsTheRecorderAdjustInputLevel =>
      'Lässt den Rekorder den Eingangspegel anpassen';

  @override
  String get echoCancellation => 'Echounterdrückung';

  @override
  String get noiseSuppression => 'Rauschunterdrückung';

  @override
  String get trimSilenceInVoiceMessages =>
      'Stille in Sprachnachrichten trimmen';

  @override
  String get compressor => 'Kompressor';

  @override
  String get limiter => 'Limiter';

  @override
  String get autoGain => 'Automatische Verstärkung';

  @override
  String get echoCancel => 'Echo';

  @override
  String get noiseSuppress => 'Rauschen';

  @override
  String get silenceTrim => 'Stille';

  @override
  String get maxImageSize => 'Maximale Bildgröße';

  @override
  String get imageCompression => 'Bildkomprimierung';

  @override
  String get grayscale => 'Graustufen';

  @override
  String get ultraMode => 'Ultra-Modus';

  @override
  String get fastPrivateGpsUpdates => 'Schnelle private GPS-Updates';

  @override
  String get movementThreshold => 'Bewegungsschwelle';

  @override
  String get fastGpsMovementThreshold => 'Schneller GPS-Bewegungsschwellenwert';

  @override
  String get fastGpsActiveuseInterval =>
      'Schnelles GPS aktive Nutzung Intervall';

  @override
  String get activeuseUpdateInterval => 'Aktive Nutzung Updateintervall';

  @override
  String get repeatNearbyTraffic => 'Nahverkehr wiederholen';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Über Repeater im Mesh weiterleiten';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Nur in der Nähe, ohne Repeater-Flooding';

  @override
  String get multihop => 'Multi-Hop';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String get renameProfile => 'Profil umbenennen';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get manageProfiles => 'Profile verwalten';

  @override
  String get enableProfilesToStartManagingThem =>
      'Aktivieren Sie Profile, um sie zu verwalten.';

  @override
  String get openMessage => 'Nachricht öffnen';

  @override
  String get jumpToTheRelatedSarMessage =>
      'Zur zugehörigen SAR-Nachricht springen';

  @override
  String get removeSarMarker => 'SAR-Markierung entfernen';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Bitte wählen Sie ein Ziel zum Senden der SAR-Markierung';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR-Markierung an öffentlichen Kanal gesendet';

  @override
  String get sarMarkerSentToRoom => 'SAR-Markierung an Raum gesendet';

  @override
  String get loadFromGallery => 'Aus Galerie laden';

  @override
  String get replaceImage => 'Bild ersetzen';

  @override
  String get selectFromGallery => 'Aus Galerie auswählen';

  @override
  String get team => 'Team';

  @override
  String get found => 'Gefunden';

  @override
  String get staging => 'Sammelpunkt';

  @override
  String get object => 'Objekt';

  @override
  String get quiet => 'Ruhig';

  @override
  String get moderate => 'Mäßig';

  @override
  String get busy => 'Beschäftigt';

  @override
  String get spectrumScanReturnedNoCandidateFrequencies =>
      'Spektrum-Scan hat keine Kandidatenfrequenzen gefunden';

  @override
  String get searchMessages => 'Nachrichten suchen';

  @override
  String get sendImageFromGallery => 'Bild aus Galerie senden';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get dmOnly => 'Nur Direktnachricht';

  @override
  String get allMessages => 'Alle Nachrichten';

  @override
  String get sendToPublicChannel => 'An öffentlichen Kanal senden?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Markierungstyp und Ziel auswählen';

  @override
  String get noDestinationsAvailableLabel => 'Keine Ziele verfügbar';

  @override
  String get image => 'Bild';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Abmessungen';

  @override
  String get segments => 'Segmente';

  @override
  String get transfers => 'Übertragungen';

  @override
  String get downloadedBy => 'Heruntergeladen von';

  @override
  String get saveDiscoverySettings => 'Erkennungseinstellungen speichern';

  @override
  String get savePublicInfo => 'Öffentliche Info speichern';

  @override
  String get saveRadioSettings => 'Funkeinstellungen speichern';

  @override
  String get savePath => 'Pfad speichern';

  @override
  String get wipeDeviceData => 'Gerätedaten löschen';

  @override
  String get wipeDevice => 'Gerät löschen';

  @override
  String get destructiveDeviceActions => 'Destruktive Geräteaktionen.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Wählen Sie eine Voreinstellung oder passen Sie die Funkeinstellungen an.';

  @override
  String get chooseTheNameAndLocationThisDeviceShares =>
      'Wählen Sie den Namen und Standort, den dieses Gerät teilt.';

  @override
  String get availableSpaceOnThisDevice =>
      'Verfügbarer Speicherplatz auf diesem Gerät.';

  @override
  String get used => 'Belegt';

  @override
  String get total => 'Gesamt';

  @override
  String get renameValue => 'Wert umbenennen';

  @override
  String get customizeFields => 'Felder anpassen';

  @override
  String get livePreview => 'Live-Vorschau';

  @override
  String get refreshSchedule => 'Aktualisierungsplan';

  @override
  String get noResponse => 'Keine Antwort';

  @override
  String get refreshing => 'Wird aktualisiert';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Wählen Sie einen Relay oder Knoten zur Beobachtung.';

  @override
  String get publicKeyLabel => 'Öffentlicher Schlüssel';

  @override
  String get alreadyInContacts => 'Bereits in Kontakten';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Verbinden Sie sich mit einem Gerät, bevor Sie Kontakte hinzufügen';

  @override
  String get fromContacts => 'Aus Kontakten';

  @override
  String get onlineOnly => 'Nur online';

  @override
  String get inBoth => 'In beiden';

  @override
  String get source => 'Quelle';

  @override
  String get manualRouteEdit => 'Manuelle Routenbearbeitung';

  @override
  String get observedMeshRoute => 'Beobachtete Mesh-Route';

  @override
  String get allMessagesCleared => 'Alle Nachrichten gelöscht';

  @override
  String get onlineTraceDatabaseCleared => 'Online-Trace-Datenbank gelöscht';

  @override
  String get packetLogsCleared => 'Paketprotokolle gelöscht';

  @override
  String get hexDataCopiedToClipboard =>
      'Hex-Daten in die Zwischenablage kopiert';

  @override
  String get developerModeEnabled => 'Entwicklermodus aktiviert';

  @override
  String get developerModeDisabled => 'Entwicklermodus deaktiviert';

  @override
  String get clipboardIsEmpty => 'Zwischenablage ist leer';

  @override
  String get contactImported => 'Kontakt importiert';

  @override
  String get contactLinkCopiedToClipboard =>
      'Kontaktlink in Zwischenablage kopiert';

  @override
  String get failedToExportContact => 'Kontaktexport fehlgeschlagen';

  @override
  String get noLogsToExport => 'Keine Protokolle zum Exportieren';

  @override
  String get exportAsCsv => 'Als CSV exportieren';

  @override
  String get exportAsText => 'Als Text exportieren';

  @override
  String get receivedRfc3339 => 'Empfangen (RFC3339)';

  @override
  String get buildTime => 'Build-Zeit';

  @override
  String get downloadUrlNotAvailable => 'Download-URL nicht verfügbar';

  @override
  String get cannotOpenDownloadUrl => 'Download-URL kann nicht geöffnet werden';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Update-Prüfung nur auf Android verfügbar';

  @override
  String get youAreRunningTheLatestVersion =>
      'Sie verwenden die neueste Version';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Update verfügbar, aber Download-URL nicht gefunden';

  @override
  String get startTictactoe => 'Tic-Tac-Toe starten';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe nicht verfügbar';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: Gegner unbekannt';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: Warten auf Start';

  @override
  String get acceptsShareLinks => 'Akzeptiert freigegebene Links';

  @override
  String get supportsRawHex => 'Unterstützt rohes Hex';

  @override
  String get clipboardfriendly => 'Zwischenablage-freundlich';

  @override
  String get captured => 'Erfasst';

  @override
  String get size => 'Größe';

  @override
  String get noCustomChannelsToClear =>
      'Keine benutzerdefinierten Kanäle zum Löschen.';

  @override
  String get noDeviceContactsToClear => 'Keine Gerätekontakte zum Löschen.';

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
