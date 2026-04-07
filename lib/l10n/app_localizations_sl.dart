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
  String get noDevicesFound => 'Ni najdenih naprav';

  @override
  String get scanAgain => 'Ponovi iskanje';

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
  String failedToAdvertise(String error) {
    return 'Objava ni uspela: $error';
  }

  @override
  String get cancelReconnection => 'Prekliči ponovno povezovanje';

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
  String get disableMap => 'Onemogoči zemljevid';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Izberite jezik';

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
      'Privzeta PIN koda za naprave brez zaslona je 123456. Težave s seznanitvijo? Pozabite napravo Bluetooth v sistemskih nastavitvah.';

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
  String get resetPath => 'Ponastavi pot (preusmeri)';

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
  String get publicChannel => 'Javni kanal';

  @override
  String get broadcastToAll => 'Oddajaj vsem bližnjim vozliščem (začasno)';

  @override
  String get storedPermanently => 'Trajno shranjeno v sobi';

  @override
  String get notConnectedToDevice => 'Ni povezano z napravo';

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
  String get autoSend => 'Samodejno pošiljanje';

  @override
  String get autoSendDescription => 'Pošlji po trenutni poti.';

  @override
  String get sendDirect => 'Neposredno pošiljanje';

  @override
  String get sendDirectDescription => 'Pošlji neposredno temu kontaktu.';

  @override
  String get sendFlood => 'Pošiljanje s poplavo';

  @override
  String get sendFloodDescription => 'Pošlji prek vseh repetitorjev.';

  @override
  String get loggedIn => 'Prijavljen';

  @override
  String get noGpsData => 'Ni GPS podatkov';

  @override
  String get distance => 'Razdalja';

  @override
  String directPingTimeout(String name) {
    return 'Časovna omejitev neposrednega pinga - ponovni poskus $name z razprševanjem...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping neuspešen do $name - odgovor ni prejet';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Ste prepričani, da želite izbrisati \"$name\"?\n\nTo bo odstranilo stik iz aplikacije in spremljevalne radijske naprave.';
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
  String get yes => 'Da';

  @override
  String get no => 'Ne';

  @override
  String get permissions => 'Dovoljenja';

  @override
  String get telemetry => 'Telemetrija';

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
  String get repeaters => 'Ponavljalniki';

  @override
  String get rooms => 'Sobe';

  @override
  String get channels => 'Kanali';

  @override
  String get selectMapLayer => 'Izberite sloj zemljevida';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI satelit';

  @override
  String get googleHybrid => 'Google hibridni zemljevid';

  @override
  String get googleRoadmap => 'Google cestni zemljevid';

  @override
  String get googleTerrain => 'Google teren';

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
  String get textCopiedToClipboard => 'Besedilo kopirano v odložišče';

  @override
  String get cannotReplySenderMissing =>
      'Ni mogoče odgovoriti: informacije o pošiljatelju manjkajo';

  @override
  String get cannotReplyContactNotFound =>
      'Ni mogoče odgovoriti: stik ni najden';

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
  String deliveredToContacts(int delivered, int total) {
    return 'Dostavljeno $delivered/$total stikom';
  }

  @override
  String get allDelivered => 'Vse dostavljeno';

  @override
  String get recipientDetails => 'Podrobnosti prejemnikov';

  @override
  String get pending => 'V čakanju';

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
  String exportFailed(String error) {
    return 'Izvoz ni uspel: $error';
  }

  @override
  String importFailed(String error) {
    return 'Uvoz ni uspel: $error';
  }

  @override
  String get unknown => 'Neznano';

  @override
  String get onlineLayers => 'Spletne plasti';

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
  String get model => 'Model';

  @override
  String get version => 'Različica';

  @override
  String get maxContacts => 'Maks. stikov';

  @override
  String get maxChannels => 'Maks. kanalov';

  @override
  String get publicInfo => 'Javne informacije';

  @override
  String get useCurrentLocation => 'Uporabi trenutno lokacijo';

  @override
  String get noneUnknown => 'Brez/Neznano';

  @override
  String get chatNode => 'Vozlišče za klepet';

  @override
  String get repeater => 'Ponavljalnik';

  @override
  String get roomChannel => 'Soba/Kanal';

  @override
  String typeNumber(int number) {
    return 'Tip $number';
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
  String get templateDescription => 'Opis (neobvezno)';

  @override
  String get templateDescriptionHint => 'Dodajte dodatni kontekst...';

  @override
  String get templateColor => 'Barva';

  @override
  String get previewFormat => 'Predogled (oblika SAR sporočila)';

  @override
  String get importFromClipboard => 'Uvozi';

  @override
  String get exportToClipboard => 'Izvozi';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Izbrišem predlogo \'$name\'?';
  }

  @override
  String get templateAdded => 'Predloga dodana';

  @override
  String get templateUpdated => 'Predloga posodobljena';

  @override
  String get templateDeleted => 'Predloga izbrisana';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uvoženih $count predlog',
      one: 'Uvožena 1 predloga',
      zero: 'Ni uvoženih predlog',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Izvoženih $count predlog v odložišče',
      one: 'Izvožena 1 predloga v odložišče',
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
  String get noTemplates => 'Ni razpoložljivih predlog';

  @override
  String get tapAddToCreate => 'Tapnite + za ustvarjanje prve predloge';

  @override
  String get ok => 'V redu';

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
  String get noRecipientsAvailable => 'Ni na voljo prejemnikov';

  @override
  String get noChannelsFound => 'Ni najdenih kanalov';

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
  String get sampleMsgEmergencyResolved => 'Nujna situacija rešena – vse čisto';

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
  String get manualCoordinates => 'Ročne koordinate';

  @override
  String get enterCoordinatesManually => 'Ročno vnesite koordinate';

  @override
  String get latitudeLabel => 'Geografska širina';

  @override
  String get longitudeLabel => 'Geografska dolžina';

  @override
  String get exampleCoordinates => 'Primer: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Deli risbo';

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
    return 'Vaše risbe ($count)';
  }

  @override
  String get shared => 'Deljeno';

  @override
  String get line => 'Črta';

  @override
  String get rectangle => 'Pravokotnik';

  @override
  String get updateAvailable => 'Na voljo je posodobitev';

  @override
  String get currentVersion => 'Trenutna različica';

  @override
  String get latestVersion => 'Najnovejša različica';

  @override
  String get downloadUpdate => 'Prenesi posodobitev';

  @override
  String get updateLater => 'Kasneje';

  @override
  String get cadastralParcels => 'Katastrske parcele';

  @override
  String get forestRoads => 'Gozdne ceste';

  @override
  String get wmsOverlays => 'WMS prekrivanja';

  @override
  String get hikingTrails => 'Planinske poti';

  @override
  String get mainRoads => 'Glavne ceste';

  @override
  String get houseNumbers => 'Hišne številke';

  @override
  String get fireHazardZones => 'Požarna ogroženost';

  @override
  String get historicalFires => 'Zgodovinski požari';

  @override
  String get firebreaks => 'Protipožarne preseke';

  @override
  String get krasFireZones => 'Kraška požarišča';

  @override
  String get placeNames => 'Zemljepisna imena';

  @override
  String get municipalityBorders => 'Občinske meje';

  @override
  String get topographicMap => 'Topografska karta 1:25000';

  @override
  String get recentMessages => 'Nedavna sporočila';

  @override
  String get addChannel => 'Dodaj kanal';

  @override
  String get channelName => 'Ime kanala';

  @override
  String get channelNameHint => 'npr. Reševalna ekipa Alfa';

  @override
  String get channelSecret => 'Geslo kanala';

  @override
  String get channelSecretHint => 'Skupno geslo za ta kanal';

  @override
  String get channelSecretHelp =>
      'To geslo mora biti deljeno z vsemi člani ekipe, ki potrebujejo dostop do tega kanala';

  @override
  String get channelTypesInfo =>
      'Hash kanali (#ekipa): Geslo samodejno generirano iz imena. Enako ime = isti kanal na vseh napravah.\n\nZasebni kanali: Uporabite eksplicitno geslo. Samo tisti z geslom se lahko pridružijo.';

  @override
  String get hashChannelInfo =>
      'Hash kanal: Geslo bo samodejno generirano iz imena kanala. Kdorkoli uporabi isto ime, se bo pridružil istemu kanalu.';

  @override
  String get channelNameRequired => 'Ime kanala je obvezno';

  @override
  String get channelNameTooLong => 'Ime kanala mora imeti največ 31 znakov';

  @override
  String get channelSecretRequired => 'Geslo kanala je obvezno';

  @override
  String get channelSecretTooLong => 'Geslo kanala mora imeti največ 32 znakov';

  @override
  String get invalidAsciiCharacters => 'Dovoljeni so samo ASCII znaki';

  @override
  String get channelCreatedSuccessfully => 'Kanal uspešno ustvarjen';

  @override
  String channelCreationFailed(String error) {
    return 'Neuspešno ustvarjanje kanala: $error';
  }

  @override
  String get deleteChannel => 'Izbriši kanal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Ali ste prepričani, da želite izbrisati kanal \"$channelName\"? Tega dejanja ni mogoče razveljaviti.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal uspešno izbrisan';

  @override
  String channelDeletionFailed(String error) {
    return 'Neuspešno brisanje kanala: $error';
  }

  @override
  String get createChannel => 'Ustvari kanal';

  @override
  String get wizardBack => 'Nazaj';

  @override
  String get wizardSkip => 'Preskoči';

  @override
  String get wizardNext => 'Naprej';

  @override
  String get wizardGetStarted => 'Začni';

  @override
  String get wizardWelcomeTitle => 'Dobrodošli v MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Ogled vadnice dobrodošlice';

  @override
  String get allTeamContacts => 'Vsi stiki ekipe';

  @override
  String directMessagesInfo(int count) {
    return 'Neposredna sporočila s potrditvami. Poslano $count članom ekipe.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR označevalec poslan $count stikom';
  }

  @override
  String get noContactsAvailable => 'Ni razpoložljivih stikov ekipe';

  @override
  String get reply => 'Odgovori';

  @override
  String get technicalDetails => 'Tehnični podrobnosti';

  @override
  String get messageTechnicalDetails => 'Tehnični podrobnosti sporočila';

  @override
  String get linkQuality => 'Kakovost povezave';

  @override
  String get delivery => 'Dostava';

  @override
  String get status => 'Stanje';

  @override
  String get expectedAckTag => 'Pričakovana oznaka ACK';

  @override
  String get roundTrip => 'Povratna pot';

  @override
  String get retryAttempt => 'Poskus ponovnega pošiljanja';

  @override
  String get floodFallback => 'Flood rezerva';

  @override
  String get identity => 'Identiteta';

  @override
  String get messageId => 'ID sporočila';

  @override
  String get sender => 'Pošiljatelj';

  @override
  String get senderKey => 'Ključ pošiljatelja';

  @override
  String get recipient => 'Prejemnik';

  @override
  String get recipientKey => 'Ključ prejemnika';

  @override
  String get voice => 'Glas';

  @override
  String get voiceId => 'ID glasu';

  @override
  String get envelope => 'Ovojnica';

  @override
  String get sessionProgress => 'Napredek seje';

  @override
  String get complete => 'Dokončano';

  @override
  String get rawDump => 'Surovi izpis';

  @override
  String get cannotRetryMissingRecipient =>
      'Ponovnega pošiljanja ni mogoče: informacije o prejemniku manjkajo';

  @override
  String get voiceUnavailable => 'Glas trenutno ni na voljo';

  @override
  String get requestingVoice => 'Zahteva za glasom';

  @override
  String get device => 'naprava';

  @override
  String get change => 'Spremeni';

  @override
  String get wizardOverviewDescription =>
      'Ta aplikacija združuje sporočanje MeshCore, terenske SAR posodobitve, zemljevide in orodja za napravo na enem mestu.';

  @override
  String get wizardOverviewFeature1 =>
      'Pošiljajte neposredna sporočila, objave v sobah in sporočila na kanalih iz glavnega zavihka Sporočila.';

  @override
  String get wizardOverviewFeature2 =>
      'Delite SAR označevalce, risbe zemljevida, glasovne posnetke in slike prek mesh omrežja.';

  @override
  String get wizardOverviewFeature3 =>
      'Povežite se prek BLE ali TCP in nato upravljajte spremljevalni radio kar iz aplikacije.';

  @override
  String get wizardMessagingTitle => 'Sporočanje in terenska poročila';

  @override
  String get wizardMessagingDescription =>
      'Sporočila tukaj niso le navadno besedilo. Aplikacija že podpira več operativnih vrst vsebin in prenosnih tokov.';

  @override
  String get wizardMessagingFeature1 =>
      'Pošiljajte neposredna sporočila, objave v sobah in promet na kanalih iz enega urejevalnika.';

  @override
  String get wizardMessagingFeature2 =>
      'Ustvarjajte SAR posodobitve in večkrat uporabne SAR predloge za pogosta terenska poročila.';

  @override
  String get wizardMessagingFeature3 =>
      'Prenašajte glasovne seje in slike, vmesnik pa prikazuje napredek in oceno časa prenosa.';

  @override
  String get wizardConnectDeviceTitle => 'Poveži napravo';

  @override
  String get wizardConnectDeviceDescription =>
      'Povežite svoj MeshCore radio, izberite ime in uporabite radijski prednastavljeni profil, preden nadaljujete.';

  @override
  String get wizardSetupBadge => 'Nastavitev';

  @override
  String get wizardOverviewBadge => 'Pregled';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Povezano z: $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Nobena naprava še ni povezana';

  @override
  String get wizardSkipForNow => 'Za zdaj preskoči';

  @override
  String get wizardDeviceNameLabel => 'Ime naprave';

  @override
  String get wizardDeviceNameHelp =>
      'To ime se oglašuje drugim uporabnikom MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Konfiguracijska regija';

  @override
  String get wizardConfigRegionHelp =>
      'Uporabi celoten uradni seznam prednastavitev MeshCore. Privzeto je izbran EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Prepričajte se, da izbrana prednastavitev ustreza lokalnim radijskim predpisom.';

  @override
  String get wizardPresetNote2 =>
      'Seznam ustreza uradnemu viru prednastavitev orodja MeshCore config.';

  @override
  String get wizardPresetNote3 =>
      'Za uvajanje ostane privzeto izbran EU/UK (Narrow).';

  @override
  String get wizardSaving => 'Shranjujem...';

  @override
  String get wizardSaveAndContinue => 'Shrani in nadaljuj';

  @override
  String get wizardEnterDeviceName => 'Pred nadaljevanjem vnesite ime naprave.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Shranjeno $deviceName z nastavitvijo $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Stiki, sobe in repetitorji';

  @override
  String get wizardNetworkDescription =>
      'Zavihek Stiki organizira omrežje, ki ga odkrijete, in poti, ki se jih aplikacija nauči skozi čas.';

  @override
  String get wizardNetworkFeature1 =>
      'Na enem seznamu preglejte člane ekipe, repetitorje, sobe, kanale in čakajoče oglase.';

  @override
  String get wizardNetworkFeature2 =>
      'Uporabite smart ping, prijavo v sobe, naučene poti in ponastavitev poti, ko povezljivost postane neurejena.';

  @override
  String get wizardNetworkFeature3 =>
      'Ustvarjajte kanale in upravljajte omrežne cilje, ne da bi zapustili aplikacijo.';

  @override
  String get wizardMapOpsTitle => 'Zemljevid, sledi in deljena geometrija';

  @override
  String get wizardMapOpsDescription =>
      'Zemljevid v aplikaciji je neposredno povezan s sporočanjem, sledenjem in SAR prekrivanji, namesto da bi bil le ločen pregledovalnik.';

  @override
  String get wizardMapOpsFeature1 =>
      'Spremljajte svoj položaj, lokacije sotekmovalcev in gibanje sledi na zemljevidu.';

  @override
  String get wizardMapOpsFeature2 =>
      'Odprite risbe iz sporočil, jih predoglejte v vrstici in jih po potrebi odstranite z zemljevida.';

  @override
  String get wizardMapOpsFeature3 =>
      'Uporabite poglede repetitorjev in deljena prekrivanja za razumevanje dosega omrežja na terenu.';

  @override
  String get wizardToolsTitle => 'Orodja onkraj sporočanja';

  @override
  String get wizardToolsDescription =>
      'Tu je več kot le štirje glavni zavihki. Aplikacija vključuje tudi konfiguracijo, diagnostiko in neobvezne senzorske poteke.';

  @override
  String get wizardToolsFeature1 =>
      'Odprite nastavitve naprave za spremembo radijskih nastavitev, telemetrije, oddajne moči in podatkov spremljevalne naprave.';

  @override
  String get wizardToolsFeature2 =>
      'Omogočite zavihek Senzorji, kadar želite nadzorne plošče in hitra osveževanja spremljanih senzorjev.';

  @override
  String get wizardToolsFeature3 =>
      'Uporabite dnevnik paketov, pregled spektra in razvojno diagnostiko pri odpravljanju težav v mesh omrežju.';

  @override
  String get postConnectDiscoveryTitle => 'Odkriti repetitorje zdaj?';

  @override
  String get postConnectDiscoveryDescription =>
      'Zaženite odkrivanje repetitorjev takoj po povezavi, da vidite bližnja vozlišča MeshCore in jih hitreje dodate v svoje omrežje.';

  @override
  String get contactInSensors => 'V senzorjih';

  @override
  String get contactAddToSensors => 'Dodaj v senzorje';

  @override
  String get contactSetPath => 'Nastavi pot';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName dodan v senzorje';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Brisanje poti ni uspelo: $error';
  }

  @override
  String get contactRouteCleared => 'Pot izbrisana';

  @override
  String contactRouteSet(String route) {
    return 'Pot nastavljena: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Nastavitev poti ni uspela: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Časovna omejitev ACK';

  @override
  String get opcode => 'Opkoda';

  @override
  String get payload => 'Vsebina';

  @override
  String get hops => 'Skoki';

  @override
  String get hashSize => 'Velikost zgoščevalne vrednosti';

  @override
  String get pathBytes => 'Bajti poti';

  @override
  String get selectedPath => 'Izbrana pot';

  @override
  String get estimatedTx => 'Ocenjeni čas oddaje';

  @override
  String get senderToReceipt => 'Od pošiljatelja do prejema';

  @override
  String get receivedCopies => 'Prejete kopije';

  @override
  String get retryCause => 'Razlog ponovitve';

  @override
  String get retryMode => 'Način ponovitve';

  @override
  String get retryResult => 'Rezultat ponovitve';

  @override
  String get lastRetry => 'Zadnja ponovitev';

  @override
  String get rxPackets => 'RX paketi';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Hitrost';

  @override
  String get window => 'Okno';

  @override
  String get posttxDelay => 'Zakasnitev po oddaji';

  @override
  String get bandpass => 'Pasovno sito';

  @override
  String get bandpassFilterVoice => 'Pasovno sito za glas';

  @override
  String get active => 'Aktivno';

  @override
  String get addContact => 'Dodaj stik';

  @override
  String get all => 'Vse';

  @override
  String get clearAllLabel => 'Počisti vse';

  @override
  String get clearFilters => 'Počisti filtre';

  @override
  String get clearRoute => 'Počisti pot';

  @override
  String get clearMessages => 'Počisti sporočila';

  @override
  String get clearScale => 'Počisti merilo';

  @override
  String get clearDiscoveries => 'Počisti odkritja';

  @override
  String get clearOnlineTraceDatabase => 'Počisti bazo sledi';

  @override
  String get clearAllChannels => 'Počisti vse kanale';

  @override
  String get clearAllContacts => 'Počisti vse stike';

  @override
  String get clearChannels => 'Počisti kanale';

  @override
  String get clearContacts => 'Počisti stike';

  @override
  String get clearPathOnMaxRetry => 'Počisti pot ob maks. ponovitvi';

  @override
  String get create => 'Ustvari';

  @override
  String get custom => 'Po meri';

  @override
  String get defaultValue => 'Privzeto';

  @override
  String get duplicate => 'Podvoji';

  @override
  String get editName => 'Uredi ime';

  @override
  String get open => 'Odpri';

  @override
  String get paste => 'Prilepi';

  @override
  String get preview => 'Predogled';

  @override
  String get remove => 'Odstrani';

  @override
  String get rename => 'Preimenuj';

  @override
  String get resolveAll => 'Razreši vse';

  @override
  String get send => 'Pošlji';

  @override
  String get sendAnyway => 'Vseeno pošlji';

  @override
  String get share => 'Deli';

  @override
  String get trace => 'Sledenje';

  @override
  String get discovery => 'Odkrivanje';

  @override
  String get discoverRepeaters => 'Odkrij posrednike';

  @override
  String get discoverSensors => 'Odkrij senzorje';

  @override
  String get repeaterDiscoverySent => 'Odkrivanje posrednikov poslano';

  @override
  String get sensorDiscoverySent => 'Odkrivanje senzorjev poslano';

  @override
  String get clearedPendingDiscoveries => 'Čakalna odkritja počiščena.';

  @override
  String get autoDiscovery => 'Samodejno odkrivanje';

  @override
  String get enableAutomaticAdding => 'Omogoči samodejno dodajanje';

  @override
  String get autoaddRepeaters => 'Samodejno dodaj posrednike';

  @override
  String get autoaddRoomServers => 'Samodejno dodaj strežnike sob';

  @override
  String get autoaddSensors => 'Samodejno dodaj senzorje';

  @override
  String get autoaddUsers => 'Samodejno dodaj uporabnike';

  @override
  String get overwriteOldestWhenFull => 'Prepiši najstarejše ob polnem';

  @override
  String get storage => 'Shramba';

  @override
  String get dangerZone => 'Nevarno območje';

  @override
  String get profiles => 'Profili';

  @override
  String get favourites => 'Priljubljeni';

  @override
  String get sensors => 'Senzorji';

  @override
  String get others => 'Ostali';

  @override
  String get gpsModule => 'GPS modul';

  @override
  String get liveTraffic => 'Promet v živo';

  @override
  String get repeatersMap => 'Zemljevid posrednikov';

  @override
  String get blePacketLogs => 'Dnevniki BLE paketov';

  @override
  String get onlineTraceDatabase => 'Baza sledi';

  @override
  String get routePathByteSize => 'Velikost poti v bajtih';

  @override
  String get messageNotifications => 'Obvestila o sporočilih';

  @override
  String get sarAlerts => 'SAR opozorila';

  @override
  String get discoveryNotifications => 'Obvestila o odkritjih';

  @override
  String get updateNotifications => 'Obvestila o posodobitvah';

  @override
  String get muteWhileAppIsOpen => 'Utišaj ko je aplikacija odprta';

  @override
  String get disableContacts => 'Onemogoči stike';

  @override
  String get enableSensorsTab => 'Omogoči zavihek Senzorji';

  @override
  String get enableProfiles => 'Omogoči profile';

  @override
  String get nearestRepeaterFallback => 'Najbližji posrednik kot rezerva';

  @override
  String get deleteAllStoredMessageHistory =>
      'Izbriši vso shranjeno zgodovino sporočil';

  @override
  String get messageFontSize => 'Velikost pisave sporočil';

  @override
  String get rotateMapWithHeading => 'Vrti zemljevid s smerjo';

  @override
  String get showMapDebugInfo => 'Prikaži razhroščevalne info zemljevida';

  @override
  String get openMapInFullscreen => 'Odpri zemljevid na cel zaslon';

  @override
  String get showSarMarkersLabel => 'Prikaži SAR oznake';

  @override
  String get hideRepeatersOnMap => 'Skrij posrednike na zemljevidu';

  @override
  String get setMapScale => 'Nastavi merilo zemljevida';

  @override
  String get customMapScaleSaved => 'Merilo zemljevida shranjeno';

  @override
  String get voiceBitrate => 'Bitna hitrost glasu';

  @override
  String get voiceCompressor => 'Kompresor glasu';

  @override
  String get voiceLimiter => 'Omejevalnik glasu';

  @override
  String get micAutoGain => 'Samodejna ojačitev mikrofona';

  @override
  String get echoCancellation => 'Odstranjevanje odmeva';

  @override
  String get noiseSuppression => 'Dušenje šuma';

  @override
  String get trimSilenceInVoiceMessages =>
      'Obreži tišino v glasovnih sporočilih';

  @override
  String get compressor => 'Kompresor';

  @override
  String get limiter => 'Omejevalnik';

  @override
  String get autoGain => 'Samodejna ojačitev';

  @override
  String get echoCancel => 'Odmev';

  @override
  String get noiseSuppress => 'Šum';

  @override
  String get silenceTrim => 'Tišina';

  @override
  String get maxImageSize => 'Največja velikost slike';

  @override
  String get imageCompression => 'Stiskanje slik';

  @override
  String get grayscale => 'Sivine';

  @override
  String get ultraMode => 'Ultra način';

  @override
  String get fastPrivateGpsUpdates => 'Hitri zasebni GPS podatki';

  @override
  String get movementThreshold => 'Prag gibanja';

  @override
  String get fastGpsMovementThreshold => 'Prag gibanja za hitri GPS';

  @override
  String get fastGpsActiveuseInterval => 'Interval uporabe hitrega GPS-a';

  @override
  String get activeuseUpdateInterval =>
      'Interval posodobitve pri aktivni uporabi';

  @override
  String get repeatNearbyTraffic => 'Ponavljaj bližnji promet';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Posreduj skozi posrednike po mreži';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Samo bližnji, brez poplavljanja posrednikov';

  @override
  String get multihop => 'Večskočno';

  @override
  String get createProfile => 'Ustvari profil';

  @override
  String get renameProfile => 'Preimenuj profil';

  @override
  String get newProfile => 'Nov profil';

  @override
  String get manageProfiles => 'Upravljaj profile';

  @override
  String get enableProfilesToStartManagingThem =>
      'Omogočite profile, da jih začnete upravljati.';

  @override
  String get openMessage => 'Odpri sporočilo';

  @override
  String get jumpToTheRelatedSarMessage => 'Skoči na povezano SAR sporočilo';

  @override
  String get removeSarMarker => 'Odstrani SAR oznako';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Izberite cilj za pošiljanje SAR oznake';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR oznaka poslana na javni kanal';

  @override
  String get sarMarkerSentToRoom => 'SAR oznaka poslana v sobo';

  @override
  String get loadFromGallery => 'Naloži iz galerije';

  @override
  String get replaceImage => 'Zamenjaj sliko';

  @override
  String get selectFromGallery => 'Izberi iz galerije';

  @override
  String get team => 'Ekipa';

  @override
  String get found => 'Najdeno';

  @override
  String get staging => 'Zbirno mesto';

  @override
  String get object => 'Predmet';

  @override
  String get quiet => 'Tiho';

  @override
  String get busy => 'Zasedeno';

  @override
  String get searchMessages => 'Iskanje sporočil';

  @override
  String get sendImageFromGallery => 'Pošlji sliko iz galerije';

  @override
  String get takePhoto => 'Posnemi fotografijo';

  @override
  String get allMessages => 'Vsa sporočila';

  @override
  String get sendToPublicChannel => 'Pošlji na javni kanal?';

  @override
  String get selectMarkerTypeAndDestination => 'Izberite vrsto oznake in cilj';

  @override
  String get noDestinationsAvailableLabel => 'Ni razpoložljivih ciljev';

  @override
  String get image => 'Slika';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Dimenzije';

  @override
  String get segments => 'Segmenti';

  @override
  String get transfers => 'Prenosi';

  @override
  String get downloadedBy => 'Preneseno od';

  @override
  String get saveDiscoverySettings => 'Shrani nastavitve odkrivanja';

  @override
  String get savePublicInfo => 'Shrani javne podatke';

  @override
  String get saveRadioSettings => 'Shrani radijske nastavitve';

  @override
  String get savePath => 'Shrani pot';

  @override
  String get wipeDeviceData => 'Izbriši podatke naprave';

  @override
  String get wipeDevice => 'Izbriši napravo';

  @override
  String get destructiveDeviceActions => 'Destruktivna dejanja na napravi.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Izberite prednastavitev ali natančno prilagodite radijske nastavitve.';

  @override
  String get used => 'Uporabljeno';

  @override
  String get total => 'Skupaj';

  @override
  String get renameValue => 'Preimenuj vrednost';

  @override
  String get customizeFields => 'Prilagodi polja';

  @override
  String get livePreview => 'Predogled v živo';

  @override
  String get refreshSchedule => 'Interval osvežitve';

  @override
  String get noResponse => 'Ni odgovora';

  @override
  String get refreshing => 'Osvežujem';

  @override
  String get unavailable => 'Nedostopno';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Izberite posrednika ali vozlišče za opazovanje.';

  @override
  String get publicKeyLabel => 'Javni ključ';

  @override
  String get alreadyInContacts => 'Že med stiki';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Povežite se z napravo pred dodajanjem stikov';

  @override
  String get fromContacts => 'Iz stikov';

  @override
  String get onlineOnly => 'Samo povezani';

  @override
  String get inBoth => 'V obeh';

  @override
  String get source => 'Vir';

  @override
  String get allMessagesCleared => 'Vsa sporočila počiščena';

  @override
  String get onlineTraceDatabaseCleared => 'Baza sledi počiščena';

  @override
  String get packetLogsCleared => 'Dnevniki paketov počiščeni';

  @override
  String get hexDataCopiedToClipboard => 'Hex podatki kopirani v odložišče';

  @override
  String get developerModeEnabled => 'Razvojni način omogočen';

  @override
  String get developerModeDisabled => 'Razvojni način onemogočen';

  @override
  String get clipboardIsEmpty => 'Odložišče je prazno';

  @override
  String get contactImported => 'Stik uvožen';

  @override
  String get contactLinkCopiedToClipboard =>
      'Povezava na stik kopirana v odložišče';

  @override
  String get failedToExportContact => 'Izvoz stika ni uspel';

  @override
  String get noLogsToExport => 'Ni dnevnikov za izvoz';

  @override
  String get exportAsCsv => 'Izvozi kot CSV';

  @override
  String get exportAsText => 'Izvozi kot besedilo';

  @override
  String get receivedRfc3339 => 'Prejeto (RFC3339)';

  @override
  String get buildTime => 'Čas gradnje';

  @override
  String get downloadUrlNotAvailable => 'URL za prenos ni na voljo';

  @override
  String get cannotOpenDownloadUrl => 'URL za prenos ni mogoče odpreti';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Preverjanje posodobitev je na voljo le na Androidu';

  @override
  String get youAreRunningTheLatestVersion =>
      'Uporabljate najnovejšo različico';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Posodobitev na voljo, a URL za prenos ni najden';

  @override
  String get startTictactoe => 'Začni Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe ni na voljo';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: nasprotnik neznan';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: čakanje na začetek';

  @override
  String get acceptsShareLinks => 'Sprejema deljene povezave';

  @override
  String get supportsRawHex => 'Podpira surove hex';

  @override
  String get clipboardfriendly => 'Primerno za odložišče';

  @override
  String get captured => 'Zajeto';

  @override
  String get size => 'Velikost';

  @override
  String get noCustomChannelsToClear => 'Ni prilagojenih kanalov za brisanje.';

  @override
  String get noDeviceContactsToClear => 'Ni stikov naprave za brisanje.';

  @override
  String get aToZ => 'A-Ž';

  @override
  String get add => 'Dodaj';

  @override
  String get addAdditionalDetails => 'Dodaj dodatne podrobnosti';

  @override
  String get addPeer => 'Dodaj soležnika';

  @override
  String get addPeerManually => 'Ročno dodaj soležnika';

  @override
  String addedToContacts(String name) {
    return '$name dodan med stike';
  }

  @override
  String addedToSensors(String name) {
    return '$name dodan med senzorje';
  }

  @override
  String get allowAll => 'Dovoli vse';

  @override
  String get anonymousRxStats => 'Anonimna RX statistika';

  @override
  String get appearance => 'Videz';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Osnovna telemetrija';

  @override
  String get blePin => 'BLE PIN';

  @override
  String get buzzerAlerts => 'Zvočni alarmi';

  @override
  String get cancelImageReceive => 'Prekliči prejem slike';

  @override
  String get choose => 'Izberi';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Izberite, katere zavihke in razdelke stikov prikazati';

  @override
  String get clearCache => 'Počisti predpomnilnik';

  @override
  String get clearHistory => 'Počisti zgodovino';

  @override
  String get clearLiveView => 'Počisti pogled v živo';

  @override
  String get clearLogs => 'Počisti dnevnike';

  @override
  String get clearOfflineCache => 'Počisti predpomnilnik brez povezave?';

  @override
  String get clearOverlay => 'Počisti prekrivanje';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Počisti pot šele po neuspehu vseh ponovitev';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Kodek, bitna hitrost in obdelava zvoka';

  @override
  String get connectByIpAddress => 'Poveži prek IP naslova';

  @override
  String get controlWhichAlertsYouReceive =>
      'Nadzirajte, katera opozorila prejemate';

  @override
  String get copyFullHex => 'Kopiraj celoten Hex';

  @override
  String get copyRawResponse => 'Kopiraj surov odgovor';

  @override
  String get couldNotLoadMetHistory => 'Nalaganje MET zgodovine ni uspelo';

  @override
  String customizeSensor(String name) {
    return 'Prilagodi $name';
  }

  @override
  String get data => 'Podatki';

  @override
  String get deleteGroup => 'Izbriši skupino';

  @override
  String deleteStyleConfirm(String name) {
    return 'Izbriši $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Izbriši to $type?';
  }

  @override
  String get deny => 'Zavrni';

  @override
  String get deviceInfo => 'Informacije o napravi';

  @override
  String get deviceSettings => 'Nastavitve naprave';

  @override
  String get deviceTimeSynced => 'Čas naprave sinhroniziran s tem telefonom.';

  @override
  String get disableFastGpsPublishing => 'Onemogoči hitro GPS objavljanje';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Prikaz, oznake in baza sledenja';

  @override
  String get download => 'Prenesi';

  @override
  String get environmentalTelemetry => 'Okoljska telemetrija';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Napaka pri preverjanju posodobitev: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Napaka: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Napaka pri odpiranju prenosa: $error';
  }

  @override
  String get exportLogs => 'Izvozi dnevnike';

  @override
  String get extraAggressiveAvifCompression =>
      'Posebno agresivno AVIF stiskanje';

  @override
  String failedToAddContact(String error) {
    return 'Dodajanje stika ni uspelo: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Dodajanje $name ni uspelo: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Brisanje kanalov ni uspelo: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Brisanje stikov ni uspelo: $error';
  }

  @override
  String get failedToConnectViaSerial =>
      'Povezava prek serijske povezave ni uspela';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Nalaganje predogleda slike ni uspelo: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Nalaganje sledi ni uspelo: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Pošiljanje SAR oznake ni uspelo: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Nastavitev zvočnega alarma ni uspela: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Nastavitev GPS načina ni uspela: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Sinhronizacija časa naprave ni uspela: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Brisanje podatkov naprave ni uspelo: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Ciljni kanal hitrega GPS-a';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Hitre posodobitve, pragovi in dovoljenja';

  @override
  String get fetchingCatalog => 'Pridobivanje kataloga...';

  @override
  String get fifteenMinutes => '15 minut';

  @override
  String get fifteenSeconds => '15 sekund';

  @override
  String get filterByDirection => 'Filtriraj po smeri';

  @override
  String get finish => 'Končaj';

  @override
  String get fiveMinutes => '5 minut';

  @override
  String get fiveSeconds => '5 sekund';

  @override
  String get fix => 'Popravi';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Politika GPS oglašanja';

  @override
  String get gpsAndLocation => 'GPS in lokacija';

  @override
  String get gpsDiagnostics => 'GPS diagnostika';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Pomoč';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Skrito';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Kako radio samodejno dodaja odkrita vozlišča.';

  @override
  String get images => 'Slike';

  @override
  String get importProfile => 'Uvozi profil';

  @override
  String get lastFix => 'Zadnja posneta lokacija';

  @override
  String get latest => 'Najnovejše';

  @override
  String get latitude => 'Geografska širina';

  @override
  String get loadASavedRegion => 'Naloži shranjeno regijo';

  @override
  String get loading => 'Nalaganje';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Deljenje lokacije, strojna oprema in interval posodobitev.';

  @override
  String get locationTelemetry => 'Telemetrija lokacije';

  @override
  String get lockDestination => 'Zakleni cilj';

  @override
  String get longitude => 'Geografska dolžina';

  @override
  String get mapStyle => 'Slog zemljevida';

  @override
  String get max => 'Maks';

  @override
  String get maxZoom => 'Maks. povečava';

  @override
  String get messaging => 'Sporočanje';

  @override
  String get metHistory => 'MET zgodovina';

  @override
  String get min => 'Min';

  @override
  String get minZoom => 'Min. povečava';

  @override
  String get moveDown => 'Premakni navzdol';

  @override
  String get moveUp => 'Premakni navzgor';

  @override
  String get multiAckMode => 'Način večkratne ACK potrditve';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Upravljanje delovnega prostora z več napravami';

  @override
  String get myLocation => 'Moja lokacija';

  @override
  String get nameAndTelemetryShared =>
      'Ime in telemetrija deljena z drugimi napravami.';

  @override
  String newVersionAvailable(String version) {
    return 'Nova različica: $version';
  }

  @override
  String get newer => 'Novejše';

  @override
  String get noNeighboursFound => 'Ni najdenih sosedov';

  @override
  String get noServersFound => 'Ni najdenih strežnikov';

  @override
  String get notSet => 'Ni nastavljeno';

  @override
  String get notifications => 'Obvestila';

  @override
  String get offZeroSeconds => 'Izključeno (0 s)';

  @override
  String get offlineMaps => 'Zemljevidi brez povezave';

  @override
  String get older => 'Starejše';

  @override
  String get oneByteMode0 => '1 bajt (način 0)';

  @override
  String get oneHour => '1 ura';

  @override
  String get oneMinute => '1 minuta';

  @override
  String get openPacketLogs => 'Odpri dnevnike paketov';

  @override
  String get packetTypeHelp => 'Pomoč za vrsto paketa';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Prilepite deljeno povezavo ali Hex oglas';

  @override
  String get pathHash => 'Zgoščevalna vrednost poti';

  @override
  String get pathSize => 'Velikost poti';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Poligon';

  @override
  String get rawResponseCopied => 'Surov odgovor kopiran';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Ponovno pošlji prek najbližjega posrednika ob neuspehu';

  @override
  String get resolveContact => 'Razreši stik';

  @override
  String get routingRetriesAndDestinationLock =>
      'Usmerjanje, ponovitve in zaklepanje cilja';

  @override
  String get samples => 'Vzorci';

  @override
  String get satellites => 'Sateliti';

  @override
  String get saving => 'Shranjujem...';

  @override
  String get search => 'Iskanje';

  @override
  String get searchByNameOrToken => 'Iskanje po imenu ali žetonu';

  @override
  String get searchDiscoveredNodes => 'Iskanje odkritih vozlišč';

  @override
  String get searchInCurrentFilter => 'Iskanje v trenutnem filtru';

  @override
  String get searchLogs => 'Iskanje dnevnikov...';

  @override
  String get searchSensors => 'Iskanje senzorjev';

  @override
  String get searchThisSection => 'Iskanje v tem razdelku';

  @override
  String get selectedRelays => 'Izbrani posredniki';

  @override
  String get sensor => 'Senzor';

  @override
  String serialError(String error) {
    return 'Napaka serijske povezave: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Nastavi pot za $name';
  }

  @override
  String get shareLiveGps => 'Deli GPS v živo';

  @override
  String get shareMyTiles => 'Deli moje ploščice';

  @override
  String get sharingLocationFromPhone =>
      'Deljenje lokacije na tem kanalu s telefona.';

  @override
  String get sharingLocationFromRadio =>
      'Deljenje lokacije na tem kanalu z radia.';

  @override
  String signalDbm(String rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview => 'Velikost, stiskanje in predogled';

  @override
  String get skip => 'Preskoči';

  @override
  String get smallerFileSize => 'Manjša velikost datoteke';

  @override
  String get sort => 'Razvrsti';

  @override
  String get stoppedSharingLocation =>
      'Deljenje lokacije na tem kanalu ustavljeno.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Zadrži obvestila, ko je aplikacija v ospredju';

  @override
  String get tabsAndNavigation => 'Zavihki in navigacija';

  @override
  String get templatesAndTutorials => 'Predloge in vadnice';

  @override
  String get tenMinutes => '10 minut';

  @override
  String get tenSeconds => '10 sekund';

  @override
  String get testSendUpdate => 'Preizkusno pošlji posodobitev';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Tema, jezik in nastavitve prikaza';

  @override
  String get thirtyMinutes => '30 minut';

  @override
  String get thirtySeconds => '30 sekund';

  @override
  String get threeBytesMode2 => '3 bajti (način 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Statistika prometa, zgodovina sporočil in razvojna orodja';

  @override
  String get twoBytesMode1 => '2 bajta (način 1)';

  @override
  String get twoMinutes => '2 minuti';

  @override
  String get undo => 'Razveljavi';

  @override
  String get updated => 'Posodobljeno';

  @override
  String get useContactFlags => 'Uporabi zastavice stikov';

  @override
  String get useSavedCoordinates => 'Uporabi shranjene koordinate';

  @override
  String get view => 'Pogled';

  @override
  String get viewNeighbours => 'Poglej sosede';

  @override
  String get viewPublicStats => 'Poglej javno statistiko';

  @override
  String get setRegionScope => 'Nastavi obseg regije';

  @override
  String get regionScope => 'Obseg regije';

  @override
  String get regionScopeNone => 'Brez (globalno)';

  @override
  String get clearRegionScope => 'Počisti obseg';

  @override
  String get regionScopeWarning =>
      'Samo repetitorji, ki dovoljujejo to regijo, bodo posredovali.';

  @override
  String get discoverRegions => 'Odkrij iz repetitorjev';

  @override
  String get discoveringRegions => 'Odkrivanje regij...';

  @override
  String get enterRegionName => 'Ime regije (npr. auckland)';

  @override
  String get noRegionsFound => 'Na tem repetitorju ni najdenih regij.';

  @override
  String regionScopeSet(String name) {
    return 'Obseg regije nastavljen na $name';
  }

  @override
  String get regionScopeCleared => 'Obseg regije počiščen';
}
