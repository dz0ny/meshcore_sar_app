// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Sporočila';

  @override
  String get contacts => 'Stiki';

  @override
  String get map => 'Zemljevid';

  @override
  String get settings => 'Nastavitve';

  @override
  String get connect => 'Poveži';

  @override
  String get disconnect => 'Prekini';

  @override
  String get scanningForDevices => 'Iskanje naprav...';

  @override
  String get noDevicesFound => 'Ni najdenih naprav';

  @override
  String get scanAgain => 'Ponovi iskanje';

  @override
  String get tapToConnect => 'Tapnite za povezavo';

  @override
  String get deviceNotConnected => 'Naprava ni povezana';

  @override
  String get locationPermissionDenied => 'Dovoljenje za lokacijo zavrnjeno';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Dovoljenje za lokacijo trajno zavrnjeno. Prosimo, omogočite v Nastavitvah.';

  @override
  String get locationPermissionRequired =>
      'Dovoljenje za lokacijo je potrebno za GPS sledenje in usklajevanje ekipe. Lahko ga omogočite kasneje v Nastavitvah.';

  @override
  String get locationServicesDisabled =>
      'Lokacijske storitve so onemogočene. Prosimo, omogočite jih v Nastavitvah.';

  @override
  String get failedToGetGpsLocation => 'Pridobitev GPS lokacije ni uspela';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Objavljeno na $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Objava ni uspela: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Ponovno povezovanje... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Prekliči ponovno povezovanje';

  @override
  String get mapManagement => 'Upravljanje zemljevida';

  @override
  String get general => 'Splošno';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Izberite temo';

  @override
  String get light => 'Svetla';

  @override
  String get dark => 'Temna';

  @override
  String get blueLightTheme => 'Modra svetla tema';

  @override
  String get blueDarkTheme => 'Modra temna tema';

  @override
  String get sarRed => 'SAR rdeča';

  @override
  String get alertEmergencyMode => 'Način opozorila/nujni primer';

  @override
  String get sarGreen => 'SAR zelena';

  @override
  String get safeAllClearMode => 'Način varno/vse jasno';

  @override
  String get autoSystem => 'Samodejno (Sistem)';

  @override
  String get followSystemTheme => 'Sledi sistemski temi';

  @override
  String get showRxTxIndicators => 'Prikaži RX/TX kazalnike';

  @override
  String get displayPacketActivity =>
      'Prikaži kazalnike aktivnosti paketov v zgornji vrstici';

  @override
  String get simpleMode => 'Preprost način';

  @override
  String get simpleModeDescription =>
      'Skrij nepomembne informacije v sporočilih in kontaktih';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Izberite jezik';

  @override
  String get english => 'Angleščina';

  @override
  String get slovenian => 'Slovenščina';

  @override
  String get croatian => 'Hrvaščina';

  @override
  String get german => 'Nemščina';

  @override
  String get spanish => 'Španščina';

  @override
  String get french => 'Francoščina';

  @override
  String get italian => 'Italijanščina';

  @override
  String get locationBroadcasting => 'Oddajanje lokacije';

  @override
  String get autoLocationTracking => 'Samodejno sledenje lokaciji';

  @override
  String get automaticallyBroadcastPosition =>
      'Samodejno oddajaj posodobitve položaja';

  @override
  String get configureTracking => 'Konfiguriraj sledenje';

  @override
  String get distanceAndTimeThresholds => 'Pragovi razdalje in časa';

  @override
  String get locationTrackingConfiguration => 'Konfiguracija sledenja lokaciji';

  @override
  String get configureWhenLocationBroadcasts =>
      'Konfigurirajte, kdaj se oddajanja lokacije pošiljajo v omrežje mesh';

  @override
  String get minimumDistance => 'Minimalna razdalja';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Oddajaj šele po premiku $distance metrov';
  }

  @override
  String get maximumDistance => 'Maksimalna razdalja';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Vedno oddajaj po premiku $distance metrov';
  }

  @override
  String get minimumTimeInterval => 'Minimalni časovni interval';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Vedno oddajaj vsakih $duration';
  }

  @override
  String get save => 'Shrani';

  @override
  String get cancel => 'Prekliči';

  @override
  String get close => 'Zapri';

  @override
  String get about => 'O aplikaciji';

  @override
  String get appVersion => 'Različica aplikacije';

  @override
  String get appName => 'Ime aplikacije';

  @override
  String get aboutMeshCoreSar => 'O MeshCore SAR';

  @override
  String get aboutDescription =>
      'Aplikacija za iskanje in reševanje, zasnovana za ekipe za odzivanje v nujnih primerih. Funkcije vključujejo:\n\n• BLE mesh omrežje za komunikacijo naprava-naprava\n• Brez povezave delujejo zemljevidi z več sloji\n• Sledenje članov ekipe v realnem času\n• SAR taktični označevalci (najdena oseba, ogenj, zbirališče)\n• Upravljanje stikov in sporočanje\n• GPS sledenje s kompasno smerjo\n• Predpomnenje ploščic zemljevida za uporabo brez povezave';

  @override
  String get technologiesUsed => 'Uporabljene tehnologije:';

  @override
  String get technologiesList =>
      '• Flutter za večplatformni razvoj\n• BLE (Bluetooth Low Energy) za mesh omrežje\n• OpenStreetMap za kartografijo\n• Provider za upravljanje stanja\n• SharedPreferences za lokalno shranjevanje';

  @override
  String get moreInfo => 'Več informacij';

  @override
  String get learnMoreAbout => 'Več o MeshCore SAR';

  @override
  String get developer => 'Razvijalec';

  @override
  String get packageName => 'Ime paketa';

  @override
  String get sampleData => 'Vzorčni podatki';

  @override
  String get sampleDataDescription =>
      'Naložite ali počistite vzorčne stike, sporočila kanalov in SAR označevalce za testiranje';

  @override
  String get loadSampleData => 'Naloži vzorec';

  @override
  String get clearAllData => 'Počisti vse podatke';

  @override
  String get clearAllDataConfirmTitle => 'Počisti vse podatke';

  @override
  String get clearAllDataConfirmMessage =>
      'To bo počistilo vse stike in SAR označevalce. Ste prepričani?';

  @override
  String get clear => 'Počisti';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Naloženih $teamCount članov ekipe, $channelCount kanalov, $sarCount SAR označevalcev, $messageCount sporočil';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Nalaganje vzorčnih podatkov ni uspelo: $error';
  }

  @override
  String get allDataCleared => 'Vsi podatki počiščeni';

  @override
  String get failedToStartBackgroundTracking =>
      'Zagon sledenja v ozadju ni uspel. Preverite dovoljenja in BLE povezavo.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Oddajanje lokacije: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Privzeta PIN koda za naprave brez zaslona je 123456. Težave s seznanitvijo? Pozabite napravo bluetooth v sistemskih nastavitvah.';

  @override
  String get noMessagesYet => 'Še ni sporočil';

  @override
  String get pullDownToSync => 'Potegnite navzdol za sinhronizacijo';

  @override
  String get deleteContact => 'Izbriši stik';

  @override
  String get delete => 'Izbriši';

  @override
  String get viewOnMap => 'Poglej na zemljevidu';

  @override
  String get refresh => 'Osveži';

  @override
  String get sendDirectMessage => 'Pošlji';

  @override
  String get resetPath => 'Ponastavi pot (preusmeri)';

  @override
  String get publicKeyCopied => 'Javni ključ kopiran v odložišče';

  @override
  String copiedToClipboard(String label) {
    return '$label kopirano v odložišče';
  }

  @override
  String get pleaseEnterPassword => 'Prosimo, vnesite geslo';

  @override
  String failedToSyncContacts(String error) {
    return 'Sinhronizacija stikov ni uspela: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Uspešno prijavljen! Čakanje na sporočila sobe...';

  @override
  String get loginFailed => 'Prijava ni uspela - nepravilno geslo';

  @override
  String loggingIn(String roomName) {
    return 'Prijavljanje v $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Pošiljanje prijave ni uspelo: $error';
  }

  @override
  String get lowLocationAccuracy => 'Nizka natančnost lokacije';

  @override
  String get continue_ => 'Nadaljuj';

  @override
  String get sendSarMarker => 'Pošlji SAR označevalec';

  @override
  String get deleteDrawing => 'Izbriši risbo';

  @override
  String get drawingTools => 'Orodja za risanje';

  @override
  String get drawLine => 'Nariši črto';

  @override
  String get drawLineDesc => 'Nariši prosto črto na zemljevidu';

  @override
  String get drawRectangle => 'Nariši pravokotnik';

  @override
  String get drawRectangleDesc => 'Nariši pravokotno področje na zemljevidu';

  @override
  String get measureDistance => 'Meri razdaljo';

  @override
  String get measureDistanceDesc => 'Dolg pritisk na dve točki za merjenje';

  @override
  String get clearMeasurement => 'Počisti meritev';

  @override
  String distanceLabel(String distance) {
    return 'Razdalja: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Dolg pritisk za drugo točko';

  @override
  String get longPressToStartMeasurement => 'Dolg pritisk za prvo točko';

  @override
  String get longPressToStartNewMeasurement => 'Dolg pritisk za novo meritev';

  @override
  String get shareDrawings => 'Deli risbe';

  @override
  String get clearAllDrawings => 'Počisti vse risbe';

  @override
  String get completeLine => 'Dokonč črto';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Oddaj $count risb$plural ekipi';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Odstrani vseh $count risb$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Izbriši vseh $count risb$plural z zemljevida?';
  }

  @override
  String get drawing => 'Risanje';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Deli $count risb$plural';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return 'Poslanih $count risb$plural karte v $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return 'Deljeno $success/$total risb$plural v $roomName';
  }

  @override
  String get showReceivedDrawings => 'Prikaži prejete risbe';

  @override
  String get showingAllDrawings => 'Prikazujem vse risbe';

  @override
  String get showingOnlyYourDrawings => 'Prikazujem samo vaše risbe';

  @override
  String get showSarMarkers => 'Prikaži SAR označevalce';

  @override
  String get showingSarMarkers => 'Prikazujem SAR označevalce';

  @override
  String get hidingSarMarkers => 'Skrivam SAR označevalce';

  @override
  String get clearAll => 'Počisti vse';

  @override
  String get noLocalDrawings => 'Ni lokalnih risb za deljenje';

  @override
  String get publicChannel => 'Javni kanal';

  @override
  String get broadcastToAll => 'Oddajaj vsem bližnjim vozliščem (začasno)';

  @override
  String get storedPermanently => 'Trajno shranjeno v sobi';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return 'Poslano $count risb$plural na javni kanal';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return 'Deljeno $success/$total risb na javni kanal';
  }

  @override
  String get notConnectedToDevice => 'Ni povezano z napravo';

  @override
  String get directMessage => 'Neposredno sporočilo';

  @override
  String directMessageSentTo(String contactName) {
    return 'Neposredno sporočilo poslano $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Pošiljanje ni uspelo: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'To sporočilo bo poslano neposredno $contactName. Prikazalo se bo tudi v glavnem viru sporočil.';
  }

  @override
  String get typeYourMessage => 'Vnesite svoje sporočilo...';

  @override
  String get quickLocationMarker => 'Hitri označevalec lokacije';

  @override
  String get markerType => 'Vrsta označevalca';

  @override
  String get sendTo => 'Pošlji na';

  @override
  String get noDestinationsAvailable => 'Ni dostopnih ciljev.';

  @override
  String get selectDestination => 'Izberite cilj...';

  @override
  String get ephemeralBroadcastInfo =>
      'Začasno: Samo oddajanje. Ni shranjeno - vozlišča morajo biti povezana.';

  @override
  String get persistentRoomInfo =>
      'Trajno: Nespremenljivo shranjeno v sobi. Samodejno sinhronizirano in ohranjeno brez povezave.';

  @override
  String get location => 'Lokacija';

  @override
  String get myLocation => 'Moja lokacija';

  @override
  String get fromMap => 'Z zemljevida';

  @override
  String get gettingLocation => 'Pridobivanje lokacije...';

  @override
  String get locationError => 'Napaka lokacije';

  @override
  String get retry => 'Poskusi znova';

  @override
  String get refreshLocation => 'Osveži lokacijo';

  @override
  String accuracyMeters(int accuracy) {
    return 'Natančnost: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Opombe (neobvezno)';

  @override
  String get addAdditionalInformation => 'Dodajte dodatne informacije...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Natančnost lokacije je ±${accuracy}m. To morda ni dovolj natančno za SAR operacije.\n\nVseeno nadaljuj?';
  }

  @override
  String get loginToRoom => 'Prijava v sobo';

  @override
  String get enterPasswordInfo =>
      'Vnesite geslo za dostop do te sobe. Geslo bo shranjeno za prihodnjo uporabo.';

  @override
  String get password => 'Geslo';

  @override
  String get enterRoomPassword => 'Vnesite geslo sobe';

  @override
  String get loggingInDots => 'Prijavljanje...';

  @override
  String get login => 'Prijava';

  @override
  String failedToAddRoom(String error) {
    return 'Dodajanje sobe v napravo ni uspelo: $error\n\nSoba morda še ni oglašena.\nPoskusite počakati, da soba odda.';
  }

  @override
  String get direct => 'Neposredno';

  @override
  String get flood => 'Razpršitev';

  @override
  String get admin => 'Administrator';

  @override
  String get loggedIn => 'Prijavljen';

  @override
  String get noGpsData => 'Ni GPS podatkov';

  @override
  String get distance => 'Razdalja';

  @override
  String pingingDirect(String name) {
    return 'Pinganje $name (neposredno preko poti)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Pinganje $name (razpršitev - brez poti)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Časovna omejitev neposrednega pinga - ponovni poskus $name z razprševanjem...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping uspešen do $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (preko rezervnega razprševanja)';

  @override
  String pingFailed(String name) {
    return 'Ping neuspešen do $name - odgovor ni prejet';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Ste prepričani, da želite izbrisati \"$name\"?\n\nTo bo odstranilo stik iz aplikacije in spremljevalne radijske naprave.';
  }

  @override
  String removingContact(String name) {
    return 'Odstranjevanje $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Stik \"$name\" odstranjen';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Odstranjevanje stika ni uspelo: $error';
  }

  @override
  String get type => 'Vrsta';

  @override
  String get publicKey => 'Javni ključ';

  @override
  String get lastSeen => 'Nazadnje viden';

  @override
  String get roomStatus => 'Status sobe';

  @override
  String get loginStatus => 'Status prijave';

  @override
  String get notLoggedIn => 'Ni prijavljen';

  @override
  String get adminAccess => 'Administratorski dostop';

  @override
  String get yes => 'Da';

  @override
  String get no => 'Ne';

  @override
  String get permissions => 'Dovoljenja';

  @override
  String get passwordSaved => 'Geslo shranjeno';

  @override
  String get locationColon => 'Lokacija:';

  @override
  String get telemetry => 'Telemetrija';

  @override
  String requestingTelemetry(String name) {
    return 'Zahtevanje telemetrije od $name...';
  }

  @override
  String get voltage => 'Napetost';

  @override
  String get battery => 'Baterija';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Vlažnost';

  @override
  String get pressure => 'Tlak';

  @override
  String get gpsTelemetry => 'GPS (Telemetrija)';

  @override
  String get updated => 'Posodobljeno';

  @override
  String pathResetInfo(String name) {
    return 'Pot ponastavljena za $name. Naslednje sporočilo bo našlo novo pot.';
  }

  @override
  String get reLoginToRoom => 'Ponovna prijava v sobo';

  @override
  String get heading => 'Smer';

  @override
  String get elevation => 'Nadmorska višina';

  @override
  String get accuracy => 'Natančnost';

  @override
  String get bearing => 'Azimut';

  @override
  String get direction => 'Smer';

  @override
  String get filterMarkers => 'Filtriraj označevalce';

  @override
  String get filterMarkersTooltip => 'Filtriraj označevalce';

  @override
  String get contactsFilter => 'Stiki';

  @override
  String get repeatersFilter => 'Ponavljalniki';

  @override
  String get sarMarkers => 'SAR označevalci';

  @override
  String get foundPerson => 'Najdena oseba';

  @override
  String get fire => 'Ogenj';

  @override
  String get stagingArea => 'Zbirališče';

  @override
  String get showAll => 'Prikaži vse';

  @override
  String get nearbyContacts => 'Bližnji stiki';

  @override
  String get locationUnavailable => 'Lokacija ni na voljo';

  @override
  String get ahead => 'naravnost';

  @override
  String degreesRight(int degrees) {
    return '$degrees° desno';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° levo';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Šir: $latitude Dolž: $longitude';
  }

  @override
  String get noContactsYet => 'Še ni stikov';

  @override
  String get connectToDeviceToLoadContacts =>
      'Povežite se z napravo za nalaganje stikov';

  @override
  String get teamMembers => 'Člani ekipe';

  @override
  String get repeaters => 'Repetitorji';

  @override
  String get rooms => 'Sobe';

  @override
  String get channels => 'Kanali';

  @override
  String get cacheStatistics => 'Statistika predpomnilnika';

  @override
  String get totalTiles => 'Skupaj ploščic';

  @override
  String get cacheSize => 'Velikost predpomnilnika';

  @override
  String get storeName => 'Ime skladišča';

  @override
  String get noCacheStatistics => 'Statistika predpomnilnika ni na voljo';

  @override
  String get downloadRegion => 'Prenesi regijo';

  @override
  String get mapLayer => 'Sloj zemljevida';

  @override
  String get regionBounds => 'Meje regije';

  @override
  String get north => 'Sever';

  @override
  String get south => 'Jug';

  @override
  String get east => 'Vzhod';

  @override
  String get west => 'Zahod';

  @override
  String get zoomLevels => 'Nivoji povečave';

  @override
  String minZoom(int zoom) {
    return 'Min: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Maks: $zoom';
  }

  @override
  String get downloadingDots => 'Prenašanje...';

  @override
  String get cancelDownload => 'Prekliči prenos';

  @override
  String get downloadRegionButton => 'Prenesi regijo';

  @override
  String get downloadNote =>
      'Opomba: Velike regije ali visoki nivoji povečave lahko zahtevajo veliko časa in prostora za shranjevanje.';

  @override
  String get cacheManagement => 'Upravljanje predpomnilnika';

  @override
  String get clearAllMaps => 'Počisti vse zemljevide';

  @override
  String get clearMapsConfirmTitle => 'Počisti vse zemljevide';

  @override
  String get clearMapsConfirmMessage =>
      'Ste prepričani, da želite izbrisati vse prenesene zemljevide? Tega dejanja ni mogoče razveljaviti.';

  @override
  String get mapDownloadCompleted => 'Prenos zemljevida končan!';

  @override
  String get cacheClearedSuccessfully => 'Predpomnilnik uspešno počiščen!';

  @override
  String get downloadCancelled => 'Prenos preklican';

  @override
  String get startingDownload => 'Začetek prenosa...';

  @override
  String get downloadingMapTiles => 'Prenašanje ploščic zemljevida...';

  @override
  String get downloadCompletedSuccessfully => 'Prenos uspešno končan!';

  @override
  String get cancellingDownload => 'Preklic prenosa...';

  @override
  String errorLoadingStats(String error) {
    return 'Napaka pri nalaganju statistike: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Prenos ni uspel: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Preklic ni uspel: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Čiščenje predpomnilnika ni uspelo: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Min povečava: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Maks povečava: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Minimalna povečava mora biti manjša ali enaka maksimalni povečavi';

  @override
  String get selectMapLayer => 'Izberite sloj zemljevida';

  @override
  String get mapOptions => 'Možnosti zemljevida';

  @override
  String get showLegend => 'Prikaži legendo';

  @override
  String get displayMarkerTypeCounts => 'Prikaži število vrst označevalcev';

  @override
  String get rotateMapWithHeading => 'Rotiraj zemljevid s smerjo';

  @override
  String get mapFollowsDirection => 'Zemljevid sledi vaši smeri pri gibanju';

  @override
  String get showMapDebugInfo => 'Prikaži debug informacije zemljevida';

  @override
  String get displayZoomLevelBounds => 'Prikaži nivo povečave in meje';

  @override
  String get fullscreenMode => 'Način celozaslonskega prikaza';

  @override
  String get hideUiFullMapView =>
      'Skrij vse UI kontrole za poln prikaz zemljevida';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI satelit';

  @override
  String get googleHybrid => 'Google hibridno';

  @override
  String get googleRoadmap => 'Google cestni zemljevid';

  @override
  String get googleTerrain => 'Google teren';

  @override
  String get downloadVisibleArea => 'Prenesi vidno območje';

  @override
  String get initializingMap => 'Inicializacija zemljevida...';

  @override
  String get dragToPosition => 'Povleci na položaj';

  @override
  String get createSarMarker => 'Ustvari SAR označevalec';

  @override
  String get compass => 'Kompas';

  @override
  String get navigationAndContacts => 'Navigacija in stiki';

  @override
  String get sarAlert => 'SAR ALARM';

  @override
  String get messageSentToPublicChannel => 'Sporočilo poslano na javni kanal';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Prosimo, izberite sobo za pošiljanje SAR označevalca';

  @override
  String failedToSendSarMarker(String error) {
    return 'Pošiljanje SAR označevalca ni uspelo: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'SAR označevalec poslan v $roomName';
  }

  @override
  String get notConnectedCannotSync =>
      'Ni povezano - sporočil ni mogoče sinhronizirati';

  @override
  String syncedMessageCount(int count) {
    return 'Sinhronizirano $count sporočil';
  }

  @override
  String get noNewMessages => 'Ni novih sporočil';

  @override
  String syncFailed(String error) {
    return 'Sinhronizacija ni uspela: $error';
  }

  @override
  String get failedToResendMessage => 'Ponovno pošiljanje sporočila ni uspelo';

  @override
  String get retryingMessage => 'Ponovni poskus pošiljanja sporočila...';

  @override
  String retryFailed(String error) {
    return 'Ponovni poskus ni uspel: $error';
  }

  @override
  String get textCopiedToClipboard => 'Besedilo kopirano v odložišče';

  @override
  String get cannotReplySenderMissing =>
      'Ni mogoče odgovoriti: informacije o pošiljatelju manjkajo';

  @override
  String get cannotReplyContactNotFound =>
      'Ni mogoče odgovoriti: stik ni najden';

  @override
  String get messageDeleted => 'Sporočilo izbrisano';

  @override
  String get copyText => 'Kopiraj besedilo';

  @override
  String get saveAsTemplate => 'Shrani kot predlogo';

  @override
  String get templateSaved => 'Predloga uspešno shranjena';

  @override
  String get templateAlreadyExists => 'Predloga s tem emojijem že obstaja';

  @override
  String get deleteMessage => 'Izbriši sporočilo';

  @override
  String get deleteMessageConfirmation =>
      'Ali ste prepričani, da želite izbrisati to sporočilo?';

  @override
  String get shareLocation => 'Deli lokacijo';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nKoordinate: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR Lokacija';

  @override
  String get locationShared => 'Lokacija deljena';

  @override
  String get refreshedContacts => 'Stiki osveženi';

  @override
  String get justNow => 'Pravkar';

  @override
  String minutesAgo(int minutes) {
    return 'pred ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'pred ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'pred ${days}d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'pred ${seconds}s';
  }

  @override
  String get sending => 'Pošiljanje...';

  @override
  String get sent => 'Poslano';

  @override
  String get delivered => 'Dostavljeno';

  @override
  String deliveredWithTime(int time) {
    return 'Dostavljeno (${time}ms)';
  }

  @override
  String get failed => 'Neuspešno';

  @override
  String get broadcast => 'Oddajano';

  @override
  String get sarMarkerFoundPerson => 'Najdena oseba';

  @override
  String get sarMarkerFire => 'Lokacija ognja';

  @override
  String get sarMarkerStagingArea => 'Zbirališče';

  @override
  String get sarMarkerObject => 'Najden predmet';

  @override
  String get from => 'Od';

  @override
  String get coordinates => 'Koordinate';

  @override
  String get tapToViewOnMap => 'Tapnite za prikaz na zemljevidu';

  @override
  String get radioSettings => 'Nastavitve radia';

  @override
  String get frequencyMHz => 'Frekvenca (MHz)';

  @override
  String get frequencyExample => 'npr. 869.618';

  @override
  String get bandwidth => 'Pasovna širina';

  @override
  String get spreadingFactor => 'Faktor razširitve';

  @override
  String get codingRate => 'Razmerje kodiranja';

  @override
  String get txPowerDbm => 'Izhodna moč (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Največ: $power dBm';
  }

  @override
  String get you => 'Ti';

  @override
  String get offlineVectorMaps => 'Brezpovezni vektorski zemljevidi';

  @override
  String get offlineVectorMapsDescription =>
      'Uvozite in upravljajte brezpovezne vektorske ploščice zemljevidov (format MBTiles) za uporabo brez internetne povezave';

  @override
  String get importMbtiles => 'Uvozi MBTiles datoteko';

  @override
  String get importMbtilesNote =>
      'Podpira MBTiles datoteke z vektorskimi ploščicami (format PBF/MVT). Geofabrik izvozi odlično delujejo!';

  @override
  String get noMbtilesFiles =>
      'Ni najdenih brezpoveznih vektorskih zemljevidov';

  @override
  String get mbtilesImportedSuccessfully => 'MBTiles datoteka uspešno uvožena';

  @override
  String get failedToImportMbtiles => 'Uvoz MBTiles datoteke ni uspel';

  @override
  String get deleteMbtilesConfirmTitle => 'Izbriši brezpovezni zemljevid';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Ste prepričani, da želite izbrisati \"$name\"? To bo trajno odstranilo brezpovezni zemljevid.';
  }

  @override
  String get mbtilesDeletedSuccessfully =>
      'Brezpovezni zemljevid uspešno izbrisan';

  @override
  String get failedToDeleteMbtiles =>
      'Brisanje brezpoveznega zemljevida ni uspelo';

  @override
  String get importExportCachedTiles => 'Uvoz/Izvoz predpomnjenih ploščic';

  @override
  String get importExportDescription =>
      'Varnostno kopirajte, delite in obnovite prenesene ploščice zemljevida med napravami';

  @override
  String get exportTilesToFile => 'Izvozi ploščice v datoteko';

  @override
  String get importTilesFromFile => 'Uvozi ploščice iz datoteke';

  @override
  String get selectExportLocation => 'Izberi lokacijo izvoza';

  @override
  String get selectImportFile => 'Izberi arhiv ploščic';

  @override
  String get exportingTiles => 'Izvažanje ploščic...';

  @override
  String get importingTiles => 'Uvažanje ploščic...';

  @override
  String exportSuccess(int count) {
    return 'Uspešno izvoženih $count ploščic';
  }

  @override
  String importSuccess(int count) {
    return 'Uspešno uvoženih $count skladišč';
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
      'Ustvari stisnjeno arhivsko datoteko (.fmtc), ki jo lahko delite in uvozite na drugih napravah.';

  @override
  String get importNote =>
      'Uvozi ploščice zemljevida iz predhodno izvožene arhivske datoteke. Ploščice bodo združene z obstoječim predpomnilnikom.';

  @override
  String get noTilesToExport => 'Ni ploščic za izvoz';

  @override
  String archiveContainsStores(int count) {
    return 'Arhiv vsebuje $count skladišč';
  }

  @override
  String get vectorTiles => 'Vektorske ploščice';

  @override
  String get schema => 'Shema';

  @override
  String get unknown => 'Neznano';

  @override
  String get bounds => 'Meje';

  @override
  String get onlineLayers => 'Spletne plasti';

  @override
  String get offlineLayers => 'Brezpovezne plasti';

  @override
  String get locationTrail => 'Sledilna pot';

  @override
  String get showTrailOnMap => 'Prikaži pot na zemljevidu';

  @override
  String get trailVisible => 'Pot je vidna na zemljevidu';

  @override
  String get trailHiddenRecording => 'Pot je skrita (še se snema)';

  @override
  String get duration => 'Trajanje';

  @override
  String get points => 'Točke';

  @override
  String get clearTrail => 'Počisti pot';

  @override
  String get clearTrailQuestion => 'Počisti pot?';

  @override
  String get clearTrailConfirmation =>
      'Ste prepričani, da želite počistiti trenutno sledilno pot? Tega dejanja ni mogoče razveljaviti.';

  @override
  String get noTrailRecorded => 'Še ni posnete poti';

  @override
  String get startTrackingToRecord =>
      'Začnite sledenje lokacije za snemanje poti';

  @override
  String get trailControls => 'Nadzor poti';

  @override
  String get deviceInformation => 'Informacije o napravi';

  @override
  String get bleName => 'BLE ime';

  @override
  String get meshName => 'Mesh ime';

  @override
  String get notSet => 'Ni nastavljeno';

  @override
  String get model => 'Model';

  @override
  String get version => 'Različica';

  @override
  String get buildDate => 'Datum izdelave';

  @override
  String get firmware => 'Vdelana programska oprema';

  @override
  String get maxContacts => 'Maks. stikov';

  @override
  String get maxChannels => 'Maks. kanalov';

  @override
  String get publicInfo => 'Javne informacije';

  @override
  String get meshNetworkName => 'Ime mesh omrežja';

  @override
  String get nameBroadcastInMesh => 'Ime, ki se oddaja v mesh oglasih';

  @override
  String get telemetryAndLocationSharing => 'Telemetrija in deljenje lokacije';

  @override
  String get lat => 'Šir';

  @override
  String get lon => 'Dol';

  @override
  String get useCurrentLocation => 'Uporabi trenutno lokacijo';

  @override
  String get noneUnknown => 'Brez/Neznano';

  @override
  String get chatNode => 'Vozlišče za klepet';

  @override
  String get repeater => 'Ojačevalnik';

  @override
  String get roomChannel => 'Soba/Kanal';

  @override
  String typeNumber(int number) {
    return 'Tip $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Kopirano $label v odložišče';
  }

  @override
  String failedToSave(String error) {
    return 'Shranjevanje ni uspelo: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Pridobivanje lokacije ni uspelo: $error';
  }

  @override
  String get sarTemplates => 'SAR predloge';

  @override
  String get manageSarTemplates => 'Upravljanje SAR predlog';

  @override
  String get addTemplate => 'Dodaj predlogo';

  @override
  String get editTemplate => 'Uredi predlogo';

  @override
  String get deleteTemplate => 'Izbriši predlogo';

  @override
  String get templateName => 'Ime predloge';

  @override
  String get templateNameHint => 'npr. Najdena oseba';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji je obvezen';

  @override
  String get nameRequired => 'Ime je obvezno';

  @override
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Uvozi';

  @override
  String get exportToClipboard => 'Izvozi';

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
  String get resetToDefaults => 'Ponastavi na privzeto';

  @override
  String get resetToDefaultsConfirmation =>
      'To bo izbrisalo vse prilagojene predloge in obnovilo 4 privzete predloge. Nadaljevati?';

  @override
  String get reset => 'Ponastavi';

  @override
  String get resetComplete => 'Predloge ponastavljene na privzeto';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Dovoljenja';

  @override
  String get locationPermission => 'Dovoljenje za lokacijo';

  @override
  String get checking => 'Preverjanje...';

  @override
  String get locationPermissionGrantedAlways => 'Odobreno (Vedno)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Odobreno (Med uporabo)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Zavrnjeno - Tapnite za zahtevo';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Trajno zavrnjeno - Odpri nastavitve';

  @override
  String get locationPermissionDialogContent =>
      'Dovoljenje za lokacijo je trajno zavrnjeno. Omogočite ga v nastavitvah naprave za uporabo sledenja GPS in deljenja lokacije.';

  @override
  String get openSettings => 'Odpri nastavitve';

  @override
  String get locationPermissionGranted => 'Dovoljenje za lokacijo odobreno!';

  @override
  String get locationPermissionRequiredForGps =>
      'Dovoljenje za lokacijo je potrebno za sledenje GPS in deljenje lokacije.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Dovoljenje za lokacijo je že odobreno.';

  @override
  String get sarNavyBlue => 'SAR Mornarska Modra';

  @override
  String get sarNavyBlueDescription => 'Profesionalni/Operativni Način';

  @override
  String get selectRecipient => 'Izberi prejemnika';

  @override
  String get broadcastToAllNearby => 'Oddajaj vsem v bližini';

  @override
  String get searchRecipients => 'Išči prejemnike...';

  @override
  String get noContactsFound => 'Ni kontaktov';

  @override
  String get noRoomsFound => 'Ni sob';

  @override
  String get noContactsOrRoomsAvailable => 'Ni na voljo kontaktov ali sob';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'Sporočila bodo poslana na javni kanal';

  @override
  String get newMessage => 'Novo sporočilo';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Vodja Policije';

  @override
  String get sampleDroneOperator => 'Operater Drona';

  @override
  String get sampleFirefighterAlpha => 'Gasilec';

  @override
  String get sampleMedicCharlie => 'Zdravnik';

  @override
  String get sampleCommandDelta => 'Poveljstvo';

  @override
  String get sampleFireEngine => 'Gasilsko Vozilo';

  @override
  String get sampleAirSupport => 'Zračna Podpora';

  @override
  String get sampleBaseCoordinator => 'Koordinator Baze';

  @override
  String get channelEmergency => 'Nujno';

  @override
  String get channelCoordination => 'Koordinacija';

  @override
  String get channelUpdates => 'Posodobitve';

  @override
  String get sampleTeamMember => 'Vzorčni Član Ekipe';

  @override
  String get sampleScout => 'Vzorčni Izvidnik';

  @override
  String get sampleBase => 'Vzorčna Baza';

  @override
  String get sampleSearcher => 'Vzorčni Iskalec';

  @override
  String get sampleObjectBackpack => ' Najden nahrbtnik - modra barva';

  @override
  String get sampleObjectVehicle => ' Zapuščeno vozilo - preveriti lastnika';

  @override
  String get sampleObjectCamping => ' Odkrita oprema za kampiranje';

  @override
  String get sampleObjectTrailMarker => ' Oznaka poti najdena izven poti';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Vse ekipe se javite';

  @override
  String get sampleMsgWeatherUpdate =>
      'Posodobitev vremena: Jasno nebo, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Bazni tabor vzpostavljen na zbirališču';

  @override
  String get sampleMsgTeamAlpha => 'Ekipa se premika v sektor 2';

  @override
  String get sampleMsgRadioCheck =>
      'Preverjanje radia - vse postaje odgovorite';

  @override
  String get sampleMsgWaterSupply =>
      'Oskrba z vodo na voljo na kontrolni točki 3';

  @override
  String get sampleMsgTeamBravo => 'Ekipa poroča: sektor 1 čist';

  @override
  String get sampleMsgEtaRallyPoint => 'Prihod na zbirališče: 15 minut';

  @override
  String get sampleMsgSupplyDrop => 'Dostava zalog potrjena za 14:00';

  @override
  String get sampleMsgDroneSurvey => 'Nadzor z dronom zaključen - brez najdb';

  @override
  String get sampleMsgTeamCharlie => 'Ekipa prosi za okrepitev';

  @override
  String get sampleMsgRadioDiscipline =>
      'Vse enote: vzdrževati radijsko disciplino';

  @override
  String get sampleMsgUrgentMedical =>
      'NUJNO: Potrebna medicinska pomoč v sektorju 4';

  @override
  String get sampleMsgAdultMale => ' Odrasel moški, pri zavesti';

  @override
  String get sampleMsgFireSpotted => 'Opažen požar - koordinate sledijo';

  @override
  String get sampleMsgSpreadingRapidly => ' Hitro se širi!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITETA: Potrebna podpora helikopterja';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medicinska ekipa na poti do vaše lokacije';

  @override
  String get sampleMsgEvacHelicopter =>
      'Helikopter za evakuacijo prihod 10 minut';

  @override
  String get sampleMsgEmergencyResolved => 'Nujnost rešena - vse čisto';

  @override
  String get sampleMsgEmergencyStagingArea => ' Nujno zbirališče';

  @override
  String get sampleMsgEmergencyServices =>
      'Nujne službe obveščene in se odzivajo';

  @override
  String get sampleAlphaTeamLead => 'Vodja Ekipe';

  @override
  String get sampleBravoScout => 'Izvidnik';

  @override
  String get sampleCharlieMedic => 'Zdravnik';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Podpora';

  @override
  String get sampleBaseCommand => 'Poveljstvo Baze';

  @override
  String get sampleFieldCoordinator => 'Terenski Koordinator';

  @override
  String get sampleMedicalTeam => 'Medicinska Ekipa';

  @override
  String get mapDrawing => 'Risba zemljevida';

  @override
  String get navigateToDrawing => 'Navigiraj do risbe';

  @override
  String get copyCoordinates => 'Kopiraj koordinate';

  @override
  String get hideFromMap => 'Skrij z zemljevida';

  @override
  String get lineDrawing => 'Linijska risba';

  @override
  String get rectangleDrawing => 'Pravokotna risba';

  @override
  String get coordinatesCopiedToClipboard => 'Koordinate kopirane v odložišče';

  @override
  String get drawingShared => 'Risba zemljevida';

  @override
  String get drawingHidden => 'Risba skrita z zemljevida';

  @override
  String alreadyShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count že deljeno',
      one: '1 že deljeno',
    );
    return '$_temp0';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return 'Deljeno $count nov$plural risb$plural';
  }

  @override
  String get shareDrawing => 'Deli Risbo';

  @override
  String get shareWithAllNearbyDevices => 'Deli z vsemi bližnjimi napravami';

  @override
  String get shareToRoom => 'Deli v Sobo';

  @override
  String get sendToPersistentStorage => 'Pošlji v trajno shrambo sobe';

  @override
  String get deleteDrawingConfirm =>
      'Ali ste prepričani, da želite izbrisati to risbo?';

  @override
  String get drawingDeleted => 'Risba izbrisana';

  @override
  String yourDrawingsCount(int count) {
    return 'Vaše Risbe ($count)';
  }

  @override
  String get shared => 'Deljeno';

  @override
  String get line => 'Črta';

  @override
  String get rectangle => 'Pravokotnik';

  @override
  String get updateAvailable => 'Na Voljo Posodobitev';

  @override
  String get currentVersion => 'Trenutna';

  @override
  String get latestVersion => 'Najnovejša';

  @override
  String get downloadUpdate => 'Prenesi';

  @override
  String get updateLater => 'Kasneje';

  @override
  String get cadastralParcels => 'Katastrske parcele';

  @override
  String get forestRoads => 'Gozdne ceste';

  @override
  String get showCadastralParcels => 'Prikaži katastrske parcele';

  @override
  String get showForestRoads => 'Prikaži gozdne ceste';

  @override
  String get wmsOverlays => 'WMS Prekrivanja';
}
