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
  String get displayPacketActivity =>
      'Prikaži kazalnike aktivnosti paketov v zgornji vrstici';

  @override
  String get disableMap => 'Onemogoči zemljevid';

  @override
  String get disableMapDescription =>
      'Skrij zavihek z zemljevidom za varčevanje z baterijo';

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
  String get contactTrails => 'Poti stikov';

  @override
  String get showAllContactTrails => 'Prikaži vse poti stikov';

  @override
  String get noContactsWithLocationHistory => 'Ni stikov z zgodovino lokacije';

  @override
  String showingTrailsForContacts(int count) {
    return 'Prikazujem poti za $count stikov';
  }

  @override
  String get individualContactTrails => 'Posamezne poti stikov';

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
  String get lon => 'Dolž';

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
  String get wizardWelcomeDescription =>
      'Zmogljivo orodje za komunikacijo brez omrežja za reševalne operacije. S svojo ekipo se povežite z mesh radijsko tehnologijo, ko tradicionalna omrežja niso na voljo.';

  @override
  String get wizardConnectingTitle => 'Povezava z radijem';

  @override
  String get wizardConnectingDescription =>
      'Svoj telefon povežite z radijsko napravo MeshCore prek Bluetootha in začnite komunicirati brez omrežja.';

  @override
  String get wizardConnectingFeature1 => 'Poišče bližnje naprave MeshCore';

  @override
  String get wizardConnectingFeature2 =>
      'Seznanitev z radijsko napravo prek Bluetootha';

  @override
  String get wizardConnectingFeature3 =>
      'Deluje povsem brez povezave — internet ni potreben';

  @override
  String get wizardChannelTitle => 'Kanali';

  @override
  String get wizardChannelDescription =>
      'Pošiljajte sporočila vsem na kanalu — idealno za obvestila in koordinacijo ekipe.';

  @override
  String get wizardChannelFeature1 =>
      'Javni kanal za splošno komunikacijo ekipe';

  @override
  String get wizardChannelFeature2 =>
      'Ustvarite kanale po meri za določene skupine';

  @override
  String get wizardChannelFeature3 =>
      'Sporočila se samodejno posredujejo prek mreže';

  @override
  String get wizardContactsTitle => 'Stiki';

  @override
  String get wizardContactsDescription =>
      'Člani ekipe se prikažejo samodejno, ko se pridružijo mesh omrežju. Pošiljajte jim neposredna sporočila ali si oglejte njihovo lokacijo.';

  @override
  String get wizardContactsFeature1 => 'Samodejno odkrivanje stikov';

  @override
  String get wizardContactsFeature2 =>
      'Pošiljanje zasebnih neposrednih sporočil';

  @override
  String get wizardContactsFeature3 =>
      'Prikaz stanja baterije in časa zadnje aktivnosti';

  @override
  String get wizardMapTitle => 'Zemljevid in lokacija';

  @override
  String get wizardMapDescription =>
      'Spremljajte svojo ekipo v realnem času in označujte ključne lokacije za reševalne operacije.';

  @override
  String get wizardMapFeature1 =>
      'SAR označevalci za najdene osebe, požare in zbirna mesta';

  @override
  String get wizardMapFeature2 => 'Sledenje članom ekipe z GPS v realnem času';

  @override
  String get wizardMapFeature3 =>
      'Prenesite zemljevide za uporabo brez povezave';

  @override
  String get wizardMapFeature4 =>
      'Rišite oblike in delite taktične informacije';

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
  String get status => 'Status';

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
}
