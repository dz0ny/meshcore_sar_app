// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Poruke';

  @override
  String get contacts => 'Kontakti';

  @override
  String get map => 'Karta';

  @override
  String get settings => 'Postavke';

  @override
  String get connect => 'Poveži';

  @override
  String get disconnect => 'Prekini';

  @override
  String get noDevicesFound => 'Nisu pronađeni uređaji';

  @override
  String get scanAgain => 'Skeniraj ponovno';

  @override
  String get tapToConnect => 'Dodirnite za povezivanje';

  @override
  String get deviceNotConnected => 'Uređaj nije povezan';

  @override
  String get locationPermissionDenied => 'Dopuštenje za lokaciju odbijeno';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Dopuštenje za lokaciju trajno odbijeno. Molimo omogućite u Postavkama.';

  @override
  String get locationPermissionRequired =>
      'Dopuštenje za lokaciju potrebno je za GPS praćenje i koordinaciju tima. Možete ga omogućiti kasnije u Postavkama.';

  @override
  String get locationServicesDisabled =>
      'Usluge lokacije su onemogućene. Molimo omogućite ih u Postavkama.';

  @override
  String get failedToGetGpsLocation => 'Neuspjelo dobivanje GPS lokacije';

  @override
  String failedToAdvertise(String error) {
    return 'Neuspjela objava: $error';
  }

  @override
  String get cancelReconnection => 'Otkaži ponovno povezivanje';

  @override
  String get general => 'Općenito';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Odaberite temu';

  @override
  String get light => 'Svijetla';

  @override
  String get dark => 'Tamna';

  @override
  String get blueLightTheme => 'Plava svijetla tema';

  @override
  String get blueDarkTheme => 'Plava tamna tema';

  @override
  String get sarRed => 'SAR crvena';

  @override
  String get alertEmergencyMode => 'Način upozorenja/hitna situacija';

  @override
  String get sarGreen => 'SAR zelena';

  @override
  String get safeAllClearMode => 'Način sigurno/sve jasno';

  @override
  String get autoSystem => 'Automatski (Sustav)';

  @override
  String get followSystemTheme => 'Slijedi temu sustava';

  @override
  String get showRxTxIndicators => 'Prikaži RX/TX indikatore';

  @override
  String get displayPacketActivity =>
      'Prikaži indikatore aktivnosti paketa u gornjoj traci';

  @override
  String get disableMap => 'Onemogući kartu';

  @override
  String get disableMapDescription => 'Sakrij karticu karte za uštedu baterije';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Odaberite jezik';

  @override
  String get save => 'Spremi';

  @override
  String get cancel => 'Otkaži';

  @override
  String get close => 'Zatvori';

  @override
  String get about => 'O aplikaciji';

  @override
  String get appVersion => 'Verzija aplikacije';

  @override
  String get appName => 'Ime aplikacije';

  @override
  String get aboutMeshCoreSar => 'O MeshCore SAR';

  @override
  String get aboutDescription =>
      'Aplikacija za potragu i spašavanje dizajnirana za timove za hitne slučajeve. Značajke uključuju:\n\n• BLE mesh mrežu za komunikaciju uređaj-uređaj\n• Offline karte s više slojeva\n• Praćenje članova tima u stvarnom vremenu\n• SAR taktički markeri (pronađena osoba, požar, zbirno mjesto)\n• Upravljanje kontaktima i razmjena poruka\n• GPS praćenje s kompasnim smjerom\n• Predmemoriranje karata za offline upotrebu';

  @override
  String get technologiesUsed => 'Korištene tehnologije:';

  @override
  String get technologiesList =>
      '• Flutter za višeplatformski razvoj\n• BLE (Bluetooth Low Energy) za mesh mrežu\n• OpenStreetMap za kartografiju\n• Provider za upravljanje stanjem\n• SharedPreferences za lokalnu pohranu';

  @override
  String get moreInfo => 'Više informacija';

  @override
  String get packageName => 'Ime paketa';

  @override
  String get sampleData => 'Primjer podataka';

  @override
  String get sampleDataDescription =>
      'Učitajte ili očistite primjere kontakata, poruka kanala i SAR markera za testiranje';

  @override
  String get loadSampleData => 'Učitaj primjer';

  @override
  String get clearAllData => 'Očisti sve podatke';

  @override
  String get clearAllDataConfirmTitle => 'Očisti sve podatke';

  @override
  String get clearAllDataConfirmMessage =>
      'Ovo će očistiti sve kontakte i SAR markere. Jeste li sigurni?';

  @override
  String get clear => 'Očisti';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Učitano $teamCount članova tima, $channelCount kanala, $sarCount SAR markera, $messageCount poruka';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Neuspjelo učitavanje primjera podataka: $error';
  }

  @override
  String get allDataCleared => 'Svi podaci očišćeni';

  @override
  String get failedToStartBackgroundTracking =>
      'Neuspjelo pokretanje praćenja u pozadini. Provjerite dopuštenja i BLE vezu.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Emitiranje lokacije: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Zadani PIN za uređaje bez zaslona je 123456. Problemi s uparivanjem? Zaboravite Bluetooth uređaj u postavkama sustava.';

  @override
  String get noMessagesYet => 'Još nema poruka';

  @override
  String get pullDownToSync => 'Povucite prema dolje za sinkronizaciju';

  @override
  String get deleteContact => 'Izbriši kontakt';

  @override
  String get delete => 'Izbriši';

  @override
  String get viewOnMap => 'Prikaži na karti';

  @override
  String get refresh => 'Osvježi';

  @override
  String get resetPath => 'Resetiraj put (preusmjeri)';

  @override
  String get publicKeyCopied => 'Javni ključ kopiran u međuspremnik';

  @override
  String copiedToClipboard(String label) {
    return '$label kopirano u međuspremnik';
  }

  @override
  String get pleaseEnterPassword => 'Molimo unesite lozinku';

  @override
  String failedToSyncContacts(String error) {
    return 'Neuspjela sinkronizacija kontakata: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Uspješno prijavljen! Čekanje na poruke sobe...';

  @override
  String get loginFailed => 'Prijava neuspjela - netočna lozinka';

  @override
  String loggingIn(String roomName) {
    return 'Prijavljivanje u $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Neuspjelo slanje prijave: $error';
  }

  @override
  String get lowLocationAccuracy => 'Niska točnost lokacije';

  @override
  String get continue_ => 'Nastavi';

  @override
  String get sendSarMarker => 'Pošalji SAR marker';

  @override
  String get deleteDrawing => 'Izbriši crtež';

  @override
  String get drawingTools => 'Alati za crtanje';

  @override
  String get drawLine => 'Nacrtaj liniju';

  @override
  String get drawLineDesc => 'Nacrtaj slobodnu liniju na karti';

  @override
  String get drawRectangle => 'Nacrtaj pravokutnik';

  @override
  String get drawRectangleDesc => 'Nacrtaj pravokutno područje na karti';

  @override
  String get measureDistance => 'Izmjeri udaljenost';

  @override
  String get measureDistanceDesc => 'Dugi pritisak na dvije točke za mjerenje';

  @override
  String get clearMeasurement => 'Očisti mjerenje';

  @override
  String distanceLabel(String distance) {
    return 'Udaljenost: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Dugi pritisak za drugu točku';

  @override
  String get longPressToStartMeasurement => 'Dugi pritisak za prvu točku';

  @override
  String get longPressToStartNewMeasurement => 'Dugi pritisak za novo mjerenje';

  @override
  String get shareDrawings => 'Podijeli crteže';

  @override
  String get clearAllDrawings => 'Očisti sve crteže';

  @override
  String get completeLine => 'Završi liniju';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Objavi $count crtež$plural timu';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Ukloni svih $count crtež$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Izbrisati sve $count crtež$plural s karte?';
  }

  @override
  String get drawing => 'Crtanje';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Podijeli $count crtež$plural';
  }

  @override
  String get showReceivedDrawings => 'Prikaži primljene crteže';

  @override
  String get showingAllDrawings => 'Prikazujem sve crteže';

  @override
  String get showingOnlyYourDrawings => 'Prikazujem samo vaše crteže';

  @override
  String get showSarMarkers => 'Prikaži SAR oznake';

  @override
  String get showingSarMarkers => 'Prikazujem SAR oznake';

  @override
  String get hidingSarMarkers => 'Skrivam SAR oznake';

  @override
  String get clearAll => 'Očisti sve';

  @override
  String get publicChannel => 'Javni kanal';

  @override
  String get broadcastToAll => 'Emitiraj svim obližnjim čvorovima (privremeno)';

  @override
  String get storedPermanently => 'Trajno pohranjeno u sobi';

  @override
  String get notConnectedToDevice => 'Nije povezano s uređajem';

  @override
  String get typeYourMessage => 'Upišite svoju poruku...';

  @override
  String get quickLocationMarker => 'Brzi označitelj lokacije';

  @override
  String get markerType => 'Vrsta markera';

  @override
  String get sendTo => 'Pošalji na';

  @override
  String get noDestinationsAvailable => 'Nema dostupnih odredišta.';

  @override
  String get selectDestination => 'Odaberite odredište...';

  @override
  String get ephemeralBroadcastInfo =>
      'Privremeno: Samo emitiranje. Nije pohranjeno - čvorovi moraju biti online.';

  @override
  String get persistentRoomInfo =>
      'Trajno: Nepromjenjivo pohranjeno u sobi. Automatski sinkronizirano i očuvano offline.';

  @override
  String get location => 'Lokacija';

  @override
  String get fromMap => 'S karte';

  @override
  String get gettingLocation => 'Dohvaćanje lokacije...';

  @override
  String get locationError => 'Greška lokacije';

  @override
  String get retry => 'Pokušaj ponovno';

  @override
  String get refreshLocation => 'Osvježi lokaciju';

  @override
  String accuracyMeters(int accuracy) {
    return 'Točnost: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Napomene (opcionalno)';

  @override
  String get addAdditionalInformation => 'Dodajte dodatne informacije...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Točnost lokacije je ±${accuracy}m. Ovo možda nije dovoljno precizno za SAR operacije.\n\nNastaviti svejedno?';
  }

  @override
  String get loginToRoom => 'Prijava u sobu';

  @override
  String get enterPasswordInfo =>
      'Unesite lozinku za pristup ovoj sobi. Lozinka će biti spremljena za buduću upotrebu.';

  @override
  String get password => 'Lozinka';

  @override
  String get enterRoomPassword => 'Unesite lozinku sobe';

  @override
  String get loggingInDots => 'Prijavljivanje...';

  @override
  String get login => 'Prijava';

  @override
  String failedToAddRoom(String error) {
    return 'Neuspjelo dodavanje sobe na uređaj: $error\n\nSoba možda još nije oglašena.\nPokušajte pričekati da soba emitira.';
  }

  @override
  String get direct => 'Izravno';

  @override
  String get flood => 'Preplavljanje';

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
  String get loggedIn => 'Prijavljen';

  @override
  String get noGpsData => 'Nema GPS podataka';

  @override
  String get distance => 'Udaljenost';

  @override
  String directPingTimeout(String name) {
    return 'Istek izravnog pinga - ponovni pokušaj $name s preplavljanjem...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping neuspješan prema $name - nije primljen odgovor';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Jeste li sigurni da želite izbrisati \"$name\"?\n\nOvo će ukloniti kontakt iz aplikacije i pratećeg radio uređaja.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Neuspjelo uklanjanje kontakta: $error';
  }

  @override
  String get type => 'Vrsta';

  @override
  String get publicKey => 'Javni ključ';

  @override
  String get lastSeen => 'Zadnje viđen';

  @override
  String get roomStatus => 'Status sobe';

  @override
  String get loginStatus => 'Status prijave';

  @override
  String get notLoggedIn => 'Nije prijavljen';

  @override
  String get adminAccess => 'Administratorski pristup';

  @override
  String get yes => 'Da';

  @override
  String get no => 'Ne';

  @override
  String get permissions => 'Dopuštenja';

  @override
  String get passwordSaved => 'Lozinka spremljena';

  @override
  String get locationColon => 'Lokacija:';

  @override
  String get telemetry => 'Telemetrija';

  @override
  String get voltage => 'Napon';

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
  String get updated => 'Ažurirano';

  @override
  String pathResetInfo(String name) {
    return 'Put resetiran za $name. Sljedeća poruka će pronaći novu rutu.';
  }

  @override
  String get reLoginToRoom => 'Ponovna prijava u sobu';

  @override
  String get heading => 'Smjer';

  @override
  String get elevation => 'Nadmorska visina';

  @override
  String get accuracy => 'Točnost';

  @override
  String get bearing => 'Azimut';

  @override
  String get direction => 'Smjer';

  @override
  String get filterMarkers => 'Filtriraj markere';

  @override
  String get filterMarkersTooltip => 'Filtriraj markere';

  @override
  String get contactsFilter => 'Kontakti';

  @override
  String get repeatersFilter => 'Repetitori';

  @override
  String get sarMarkers => 'SAR markeri';

  @override
  String get foundPerson => 'Pronađena osoba';

  @override
  String get fire => 'Požar';

  @override
  String get stagingArea => 'Zbirno mjesto';

  @override
  String get showAll => 'Prikaži sve';

  @override
  String get locationUnavailable => 'Lokacija nije dostupna';

  @override
  String get ahead => 'naprijed';

  @override
  String degreesRight(int degrees) {
    return '$degrees° desno';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° lijevo';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Šir: $latitude Duž: $longitude';
  }

  @override
  String get noContactsYet => 'Još nema kontakata';

  @override
  String get connectToDeviceToLoadContacts =>
      'Povežite se s uređajem da učitate kontakte';

  @override
  String get teamMembers => 'Članovi tima';

  @override
  String get repeaters => 'Repetitori';

  @override
  String get rooms => 'Sobe';

  @override
  String get channels => 'Kanali';

  @override
  String get selectMapLayer => 'Odaberite sloj karte';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI satelit';

  @override
  String get googleHybrid => 'Google hibridna karta';

  @override
  String get googleRoadmap => 'Google cestovna karta';

  @override
  String get googleTerrain => 'Google teren';

  @override
  String get dragToPosition => 'Povuci na poziciju';

  @override
  String get createSarMarker => 'Kreiraj SAR marker';

  @override
  String get compass => 'Kompas';

  @override
  String get navigationAndContacts => 'Navigacija i kontakti';

  @override
  String get sarAlert => 'SAR UZBUNA';

  @override
  String get textCopiedToClipboard => 'Tekst kopiran u međuspremnik';

  @override
  String get cannotReplySenderMissing =>
      'Ne mogu odgovoriti: informacije o pošiljatelju nedostaju';

  @override
  String get cannotReplyContactNotFound =>
      'Ne mogu odgovoriti: kontakt nije pronađen';

  @override
  String get copyText => 'Kopiraj tekst';

  @override
  String get saveAsTemplate => 'Spremi kao predložak';

  @override
  String get templateSaved => 'Predložak uspješno spremljen';

  @override
  String get templateAlreadyExists => 'Predložak s ovim emojijem već postoji';

  @override
  String get deleteMessage => 'Izbriši poruku';

  @override
  String get deleteMessageConfirmation =>
      'Jeste li sigurni da želite izbrisati ovu poruku?';

  @override
  String get shareLocation => 'Podijeli lokaciju';

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
  String get justNow => 'Upravo sada';

  @override
  String minutesAgo(int minutes) {
    return 'prije ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'prije ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'prije ${days}d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'prije ${seconds}s';
  }

  @override
  String get sending => 'Slanje...';

  @override
  String get sent => 'Poslano';

  @override
  String get delivered => 'Dostavljeno';

  @override
  String deliveredWithTime(int time) {
    return 'Dostavljeno (${time}ms)';
  }

  @override
  String get failed => 'Neuspjelo';

  @override
  String get broadcast => 'Emitirano';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Dostavljeno na $delivered/$total kontakata';
  }

  @override
  String get allDelivered => 'Sve dostavljeno';

  @override
  String get recipientDetails => 'Detalji primatelja';

  @override
  String get pending => 'Na čekanju';

  @override
  String get sarMarkerFoundPerson => 'Pronađena osoba';

  @override
  String get sarMarkerFire => 'Lokacija požara';

  @override
  String get sarMarkerStagingArea => 'Zbirno mjesto';

  @override
  String get sarMarkerObject => 'Pronađen objekt';

  @override
  String get from => 'Od';

  @override
  String get coordinates => 'Koordinate';

  @override
  String get tapToViewOnMap => 'Dodirnite za prikaz na karti';

  @override
  String get radioSettings => 'Postavke radija';

  @override
  String get frequencyMHz => 'Frekvencija (MHz)';

  @override
  String get frequencyExample => 'npr. 869.618';

  @override
  String get bandwidth => 'Širina pojasa';

  @override
  String get spreadingFactor => 'Faktor širenja';

  @override
  String get codingRate => 'Omjer kodiranja';

  @override
  String get txPowerDbm => 'TX snaga (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Maks: $power dBm';
  }

  @override
  String get you => 'Ti';

  @override
  String exportFailed(String error) {
    return 'Izvoz nije uspio: $error';
  }

  @override
  String importFailed(String error) {
    return 'Uvoz nije uspio: $error';
  }

  @override
  String get unknown => 'Nepoznato';

  @override
  String get onlineLayers => 'Mrežni slojevi';

  @override
  String get locationTrail => 'Putanja lokacije';

  @override
  String get showTrailOnMap => 'Prikaži putanju na karti';

  @override
  String get trailVisible => 'Putanja je vidljiva na karti';

  @override
  String get trailHiddenRecording => 'Putanja je skrivena (još se snima)';

  @override
  String get duration => 'Trajanje';

  @override
  String get points => 'Točke';

  @override
  String get clearTrail => 'Obriši putanju';

  @override
  String get clearTrailQuestion => 'Obrisati putanju?';

  @override
  String get clearTrailConfirmation =>
      'Jeste li sigurni da želite obrisati trenutnu putanju lokacije? Ova radnja se ne može poništiti.';

  @override
  String get noTrailRecorded => 'Još nije snimljena putanja';

  @override
  String get startTrackingToRecord =>
      'Pokrenite praćenje lokacije za snimanje putanje';

  @override
  String get trailControls => 'Upravljanje putanjom';

  @override
  String get contactTrails => 'Putanje kontakata';

  @override
  String get showAllContactTrails => 'Prikaži sve putanje kontakata';

  @override
  String get noContactsWithLocationHistory =>
      'Nema kontakata s poviješću lokacije';

  @override
  String showingTrailsForContacts(int count) {
    return 'Prikazujem putanje za $count kontakata';
  }

  @override
  String get individualContactTrails => 'Pojedinačne putanje kontakata';

  @override
  String get deviceInformation => 'Informacije o uređaju';

  @override
  String get bleName => 'BLE naziv';

  @override
  String get meshName => 'Mesh naziv';

  @override
  String get notSet => 'Nije postavljeno';

  @override
  String get model => 'Model';

  @override
  String get version => 'Verzija';

  @override
  String get buildDate => 'Datum izgradnje';

  @override
  String get firmware => 'Firmver';

  @override
  String get maxContacts => 'Maks. kontakata';

  @override
  String get maxChannels => 'Maks. kanala';

  @override
  String get publicInfo => 'Javne informacije';

  @override
  String get meshNetworkName => 'Naziv mesh mreže';

  @override
  String get nameBroadcastInMesh => 'Naziv koji se emitira u mesh oglasima';

  @override
  String get telemetryAndLocationSharing => 'Telemetrija i dijeljenje lokacije';

  @override
  String get lat => 'Šir';

  @override
  String get lon => 'Duž';

  @override
  String get useCurrentLocation => 'Koristi trenutnu lokaciju';

  @override
  String get noneUnknown => 'Nema/Nepoznato';

  @override
  String get chatNode => 'Čvorište za razgovor';

  @override
  String get repeater => 'Repetitor';

  @override
  String get roomChannel => 'Soba/Kanal';

  @override
  String typeNumber(int number) {
    return 'Tip $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Kopirano $label u međuspremnik';
  }

  @override
  String failedToSave(String error) {
    return 'Neuspjelo spremanje: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Neuspjelo dohvaćanje lokacije: $error';
  }

  @override
  String get sarTemplates => 'SAR predlošci';

  @override
  String get manageSarTemplates => 'Upravljanje SAR predlošcima';

  @override
  String get addTemplate => 'Dodaj predložak';

  @override
  String get editTemplate => 'Uredi predložak';

  @override
  String get deleteTemplate => 'Izbriši predložak';

  @override
  String get templateName => 'Naziv predloška';

  @override
  String get templateNameHint => 'npr. Pronađena osoba';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji je obavezan';

  @override
  String get nameRequired => 'Ime je obavezno';

  @override
  String get templateDescription => 'Opis (neobavezno)';

  @override
  String get templateDescriptionHint => 'Dodajte dodatni kontekst...';

  @override
  String get templateColor => 'Boja';

  @override
  String get previewFormat => 'Pregled (format SAR poruke)';

  @override
  String get importFromClipboard => 'Uvezi';

  @override
  String get exportToClipboard => 'Izvezi';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Izbrisati predložak \'$name\'?';
  }

  @override
  String get templateAdded => 'Predložak dodan';

  @override
  String get templateUpdated => 'Predložak ažuriran';

  @override
  String get templateDeleted => 'Predložak izbrisan';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uvezeno $count predložaka',
      one: 'Uvezen 1 predložak',
      zero: 'Nema uvezenih predložaka',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Izvezeno $count predložaka u međuspremnik',
      one: 'Izvezen 1 predložak u međuspremnik',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Vrati na zadane';

  @override
  String get resetToDefaultsConfirmation =>
      'Ovo će izbrisati sve prilagođene predloške i vratiti 4 zadana predloška. Nastaviti?';

  @override
  String get reset => 'Vrati';

  @override
  String get resetComplete => 'Predlošci vraćeni na zadane';

  @override
  String get noTemplates => 'Nema dostupnih predložaka';

  @override
  String get tapAddToCreate => 'Dodirnite + za izradu prvog predloška';

  @override
  String get ok => 'U redu';

  @override
  String get permissionsSection => 'Dozvole';

  @override
  String get locationPermission => 'Dozvola za lokaciju';

  @override
  String get checking => 'Provjera...';

  @override
  String get locationPermissionGrantedAlways => 'Odobreno (Uvijek)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Odobreno (Tijekom uporabe)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Odbijeno - Dodirnite za zahtjev';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Trajno odbijeno - Otvori postavke';

  @override
  String get locationPermissionDialogContent =>
      'Dozvola za lokaciju je trajno odbijena. Omogućite je u postavkama uređaja kako biste koristili GPS praćenje i dijeljenje lokacije.';

  @override
  String get openSettings => 'Otvori postavke';

  @override
  String get locationPermissionGranted => 'Dozvola za lokaciju odobrena!';

  @override
  String get locationPermissionRequiredForGps =>
      'Dozvola za lokaciju je potrebna za GPS praćenje i dijeljenje lokacije.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Dozvola za lokaciju je već odobrena.';

  @override
  String get sarNavyBlue => 'SAR Mornarsko Plava';

  @override
  String get sarNavyBlueDescription => 'Profesionalni/Operativni Način';

  @override
  String get selectRecipient => 'Odaberi primatelja';

  @override
  String get broadcastToAllNearby => 'Emitiraj svima u blizini';

  @override
  String get searchRecipients => 'Pretraži primatelje...';

  @override
  String get noContactsFound => 'Nema kontakata';

  @override
  String get noRoomsFound => 'Nema soba';

  @override
  String get noRecipientsAvailable => 'Nema dostupnih primatelja';

  @override
  String get noChannelsFound => 'Nije pronađen nijedan kanal';

  @override
  String get newMessage => 'Nova poruka';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Voditelj Policije';

  @override
  String get sampleDroneOperator => 'Operater Drona';

  @override
  String get sampleFirefighterAlpha => 'Vatrogasac';

  @override
  String get sampleMedicCharlie => 'Medičar';

  @override
  String get sampleCommandDelta => 'Zapovjedništvo';

  @override
  String get sampleFireEngine => 'Vatrogasno Vozilo';

  @override
  String get sampleAirSupport => 'Zračna Podrška';

  @override
  String get sampleBaseCoordinator => 'Koordinator Baze';

  @override
  String get channelEmergency => 'Hitno';

  @override
  String get channelCoordination => 'Koordinacija';

  @override
  String get channelUpdates => 'Ažuriranja';

  @override
  String get sampleTeamMember => 'Primjer Člana Tima';

  @override
  String get sampleScout => 'Primjer Izviđača';

  @override
  String get sampleBase => 'Primjer Baze';

  @override
  String get sampleSearcher => 'Primjer Tragača';

  @override
  String get sampleObjectBackpack => ' Pronađen ruksak - plava boja';

  @override
  String get sampleObjectVehicle => ' Napušteno vozilo - provjeriti vlasnika';

  @override
  String get sampleObjectCamping => ' Otkrivena oprema za kampiranje';

  @override
  String get sampleObjectTrailMarker => ' Oznaka staze pronađena izvan puta';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Svi timovi, javite se';

  @override
  String get sampleMsgWeatherUpdate =>
      'Ažuriranje vremena: Vedro nebo, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Bazni kamp uspostavljen na okupljalištu';

  @override
  String get sampleMsgTeamAlpha => 'Tim se kreće prema sektoru 2';

  @override
  String get sampleMsgRadioCheck => 'Provjera radija - sve stanice odgovorite';

  @override
  String get sampleMsgWaterSupply =>
      'Opskrba vodom dostupna na kontrolnoj točki 3';

  @override
  String get sampleMsgTeamBravo => 'Tim izvještava: sektor 1 čist';

  @override
  String get sampleMsgEtaRallyPoint => 'ETA do točke okupljanja: 15 minuta';

  @override
  String get sampleMsgSupplyDrop => 'Isporuka zaliha potvrđena za 14:00';

  @override
  String get sampleMsgDroneSurvey => 'Nadzor dronom završen - bez nalaza';

  @override
  String get sampleMsgTeamCharlie => 'Tim traži pojačanje';

  @override
  String get sampleMsgRadioDiscipline =>
      'Sve jedinice: održavati radio disciplinu';

  @override
  String get sampleMsgUrgentMedical =>
      'HITNO: Potrebna medicinska pomoć u sektoru 4';

  @override
  String get sampleMsgAdultMale => ' Odrasli muškarac, pri svijesti';

  @override
  String get sampleMsgFireSpotted => 'Uočen požar - koordinate slijede';

  @override
  String get sampleMsgSpreadingRapidly => ' Širi se brzo!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITET: Potrebna podrška helikoptera';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medicinski tim na putu do vaše lokacije';

  @override
  String get sampleMsgEvacHelicopter =>
      'Helikopter za evakuaciju ETA 10 minuta';

  @override
  String get sampleMsgEmergencyResolved => 'Hitnost riješena - sve čisto';

  @override
  String get sampleMsgEmergencyStagingArea => ' Hitno okupljalište';

  @override
  String get sampleMsgEmergencyServices =>
      'Hitne službe obaviještene i odgovaraju';

  @override
  String get sampleAlphaTeamLead => 'Voditelj Tima';

  @override
  String get sampleBravoScout => 'Izviđač';

  @override
  String get sampleCharlieMedic => 'Medičar';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Podrška';

  @override
  String get sampleBaseCommand => 'Zapovjedništvo Baze';

  @override
  String get sampleFieldCoordinator => 'Terenski Koordinator';

  @override
  String get sampleMedicalTeam => 'Medicinski Tim';

  @override
  String get mapDrawing => 'Crtež karte';

  @override
  String get navigateToDrawing => 'Navigiraj do crteža';

  @override
  String get copyCoordinates => 'Kopiraj koordinate';

  @override
  String get hideFromMap => 'Sakrij s karte';

  @override
  String get lineDrawing => 'Linijski crtež';

  @override
  String get rectangleDrawing => 'Pravokutni crtež';

  @override
  String get manualCoordinates => 'Ručne koordinate';

  @override
  String get enterCoordinatesManually => 'Ručno unesite koordinate';

  @override
  String get latitudeLabel => 'Geografska širina';

  @override
  String get longitudeLabel => 'Geografska dužina';

  @override
  String get exampleCoordinates => 'Primjer: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Podijeli crtež';

  @override
  String get shareWithAllNearbyDevices =>
      'Podijeli sa svim obližnjim uređajima';

  @override
  String get shareToRoom => 'Podijeli u Sobu';

  @override
  String get sendToPersistentStorage => 'Pošalji u trajnu pohranu sobe';

  @override
  String get deleteDrawingConfirm =>
      'Jeste li sigurni da želite izbrisati ovaj crtež?';

  @override
  String get drawingDeleted => 'Crtež izbrisan';

  @override
  String yourDrawingsCount(int count) {
    return 'Vaši crteži ($count)';
  }

  @override
  String get shared => 'Podijeljeno';

  @override
  String get line => 'Linija';

  @override
  String get rectangle => 'Pravokutnik';

  @override
  String get updateAvailable => 'Dostupno ažuriranje';

  @override
  String get currentVersion => 'Trenutna verzija';

  @override
  String get latestVersion => 'Najnovija verzija';

  @override
  String get downloadUpdate => 'Preuzmi ažuriranje';

  @override
  String get updateLater => 'Kasnije';

  @override
  String get cadastralParcels => 'Katastarske čestice';

  @override
  String get forestRoads => 'Šumske ceste';

  @override
  String get wmsOverlays => 'WMS prekrivanja';

  @override
  String get hikingTrails => 'Planinske staze';

  @override
  String get mainRoads => 'Glavne ceste';

  @override
  String get houseNumbers => 'Kućni brojevi';

  @override
  String get fireHazardZones => 'Požarna ugroženost';

  @override
  String get historicalFires => 'Povijesni požari';

  @override
  String get firebreaks => 'Protupožarni pojasi';

  @override
  String get krasFireZones => 'Kraška požarišta';

  @override
  String get placeNames => 'Zemljopisna imena';

  @override
  String get municipalityBorders => 'Općinske granice';

  @override
  String get topographicMap => 'Topografska karta 1:25000';

  @override
  String get recentMessages => 'Nedavne poruke';

  @override
  String get addChannel => 'Dodaj kanal';

  @override
  String get channelName => 'Ime kanala';

  @override
  String get channelNameHint => 'npr. Spasilačka ekipa Alfa';

  @override
  String get channelSecret => 'Lozinka kanala';

  @override
  String get channelSecretHint => 'Zajednička lozinka za ovaj kanal';

  @override
  String get channelSecretHelp =>
      'Ova lozinka mora biti podijeljena sa svim članovima tima koji trebaju pristup ovom kanalu';

  @override
  String get channelTypesInfo =>
      'Hash kanali (#tim): Lozinka automatski generirana iz imena. Isto ime = isti kanal na svim uređajima.\n\nPrivatni kanali: Koristite eksplicitnu lozinku. Samo oni s lozinkom se mogu pridružiti.';

  @override
  String get hashChannelInfo =>
      'Hash kanal: Lozinka će biti automatski generirana iz imena kanala. Bilo tko tko koristi isto ime pridružit će se istom kanalu.';

  @override
  String get channelNameRequired => 'Ime kanala je obavezno';

  @override
  String get channelNameTooLong => 'Ime kanala mora imati najviše 31 znak';

  @override
  String get channelSecretRequired => 'Lozinka kanala je obavezna';

  @override
  String get channelSecretTooLong =>
      'Lozinka kanala mora imati najviše 32 znaka';

  @override
  String get invalidAsciiCharacters => 'Samo ASCII znakovi su dozvoljeni';

  @override
  String get channelCreatedSuccessfully => 'Kanal uspješno kreiran';

  @override
  String channelCreationFailed(String error) {
    return 'Neuspješno kreiranje kanala: $error';
  }

  @override
  String get deleteChannel => 'Izbriši kanal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Jeste li sigurni da želite izbrisati kanal \"$channelName\"? Ova radnja se ne može poništiti.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal uspješno izbrisan';

  @override
  String channelDeletionFailed(String error) {
    return 'Neuspješno brisanje kanala: $error';
  }

  @override
  String get createChannel => 'Kreiraj kanal';

  @override
  String get wizardBack => 'Natrag';

  @override
  String get wizardSkip => 'Preskoči';

  @override
  String get wizardNext => 'Dalje';

  @override
  String get wizardGetStarted => 'Započni';

  @override
  String get wizardWelcomeTitle => 'Dobrodošli u MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'Moćan alat za komunikaciju izvan mreže za spasilačke operacije. Povežite se s timom uz mesh radijsku tehnologiju kada tradicionalne mreže nisu dostupne.';

  @override
  String get wizardConnectingTitle => 'Povezivanje s radiom';

  @override
  String get wizardConnectingDescription =>
      'Povežite telefon s MeshCore radijskim uređajem putem Bluetootha i započnite komunikaciju izvan mreže.';

  @override
  String get wizardConnectingFeature1 => 'Skenira obližnje MeshCore uređaje';

  @override
  String get wizardConnectingFeature2 =>
      'Uparivanje s radijem putem Bluetootha';

  @override
  String get wizardConnectingFeature3 =>
      'Radi potpuno izvan mreže — internet nije potreban';

  @override
  String get wizardChannelTitle => 'Kanali';

  @override
  String get wizardChannelDescription =>
      'Šaljite poruke svima na kanalu — idealno za obavijesti i koordinaciju tima.';

  @override
  String get wizardChannelFeature1 => 'Javni kanal za opću komunikaciju ekipe';

  @override
  String get wizardChannelFeature2 =>
      'Stvorite prilagođene kanale za specifične grupe';

  @override
  String get wizardChannelFeature3 =>
      'Poruke se automatski prosljeđuju putem mreže';

  @override
  String get wizardContactsTitle => 'Kontakti';

  @override
  String get wizardContactsDescription =>
      'Članovi tima se prikazuju automatski kada se pridruže mesh mreži. Šaljite im izravne poruke ili pogledajte njihovu lokaciju.';

  @override
  String get wizardContactsFeature1 => 'Kontakti se automatski otkrivaju';

  @override
  String get wizardContactsFeature2 => 'Šaljite privatne direktne poruke';

  @override
  String get wizardContactsFeature3 =>
      'Prikažite stanje baterije i vrijeme zadnje aktivnosti';

  @override
  String get wizardMapTitle => 'Karta i lokacija';

  @override
  String get wizardMapDescription =>
      'Pratite tim u stvarnom vremenu i označavajte ključne lokacije za spasilačke operacije.';

  @override
  String get wizardMapFeature1 =>
      'SAR oznake za pronađene osobe, požare i točke okupljanja';

  @override
  String get wizardMapFeature2 =>
      'GPS praćenje članova tima u stvarnom vremenu';

  @override
  String get wizardMapFeature3 => 'Preuzmite karte za rad izvan mreže';

  @override
  String get wizardMapFeature4 =>
      'Crtajte oblike i dijelite taktičke informacije';

  @override
  String get viewWelcomeTutorial => 'Pogledaj uputu dobrodošlice';

  @override
  String get allTeamContacts => 'Svi kontakti tima';

  @override
  String directMessagesInfo(int count) {
    return 'Izravne poruke s potvrdom. Poslano $count članovima tima.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR oznaka poslana $count kontaktima';
  }

  @override
  String get noContactsAvailable => 'Nema dostupnih kontakata tima';

  @override
  String get reply => 'Odgovori';

  @override
  String get technicalDetails => 'Tehnički detalji';

  @override
  String get messageTechnicalDetails => 'Tehnički detalji poruke';

  @override
  String get linkQuality => 'Kvaliteta veze';

  @override
  String get delivery => 'Dostava';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Očekivana ACK oznaka';

  @override
  String get roundTrip => 'Povratno putovanje';

  @override
  String get retryAttempt => 'Pokušaj ponovnog slanja';

  @override
  String get floodFallback => 'Flood rezerva';

  @override
  String get identity => 'Identitet';

  @override
  String get messageId => 'ID poruke';

  @override
  String get sender => 'Pošiljatelj';

  @override
  String get senderKey => 'Ključ pošiljatelja';

  @override
  String get recipient => 'Primatelj';

  @override
  String get recipientKey => 'Ključ primatelja';

  @override
  String get voice => 'Glas';

  @override
  String get voiceId => 'ID glasa';

  @override
  String get envelope => 'Omotnica';

  @override
  String get sessionProgress => 'Napredak sesije';

  @override
  String get complete => 'Dovršeno';

  @override
  String get rawDump => 'Sirovi ispis';

  @override
  String get cannotRetryMissingRecipient =>
      'Nije moguće ponoviti: nedostaju informacije o primatelju';

  @override
  String get voiceUnavailable => 'Glas trenutno nije dostupan';

  @override
  String get requestingVoice => 'Zahtjev za glasom';

  @override
  String get device => 'uređaj';

  @override
  String get change => 'Promijeni';

  @override
  String get wizardOverviewDescription =>
      'Ova aplikacija objedinjuje MeshCore poruke, SAR ažuriranja s terena, karte i alate za uređaj na jednom mjestu.';

  @override
  String get wizardOverviewFeature1 =>
      'Šaljite izravne poruke, objave u sobama i poruke kanala iz glavne kartice Poruke.';

  @override
  String get wizardOverviewFeature2 =>
      'Dijelite SAR oznake, crteže karte, glasovne isječke i slike preko mesh mreže.';

  @override
  String get wizardOverviewFeature3 =>
      'Povežite se putem BLE-a ili TCP-a, a zatim upravljajte pratećim radijem izravno iz aplikacije.';

  @override
  String get wizardMessagingTitle => 'Poruke i terenska izvješća';

  @override
  String get wizardMessagingDescription =>
      'Poruke ovdje nisu samo običan tekst. Aplikacija već podržava više operativnih sadržaja i tijekova prijenosa.';

  @override
  String get wizardMessagingFeature1 =>
      'Šaljite izravne poruke, objave u sobama i promet kanala iz jednog uređivača.';

  @override
  String get wizardMessagingFeature2 =>
      'Stvarajte SAR ažuriranja i višekratne SAR predloške za uobičajena terenska izvješća.';

  @override
  String get wizardMessagingFeature3 =>
      'Prenosite glasovne sesije i slike uz prikaz napretka i procjene vremena prijenosa u sučelju.';

  @override
  String get wizardConnectDeviceTitle => 'Poveži uređaj';

  @override
  String get wizardConnectDeviceDescription =>
      'Povežite svoj MeshCore radio, odaberite naziv i primijenite radijski predložak prije nastavka.';

  @override
  String get wizardSetupBadge => 'Postavljanje';

  @override
  String get wizardOverviewBadge => 'Pregled';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Povezano s uređajem $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Još nema povezanog uređaja';

  @override
  String get wizardSkipForNow => 'Preskoči za sada';

  @override
  String get wizardDeviceNameLabel => 'Naziv uređaja';

  @override
  String get wizardDeviceNameHelp =>
      'Taj se naziv oglašava drugim korisnicima MeshCorea.';

  @override
  String get wizardConfigRegionLabel => 'Regija konfiguracije';

  @override
  String get wizardConfigRegionHelp =>
      'Koristi puni službeni popis MeshCore predložaka. Zadana je opcija EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Provjerite odgovara li odabrani predložak lokalnim radijskim propisima.';

  @override
  String get wizardPresetNote2 =>
      'Popis odgovara službenom izvoru predložaka alata MeshCore config.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) ostaje zadano odabran tijekom uvodnog postavljanja.';

  @override
  String get wizardSaving => 'Spremanje...';

  @override
  String get wizardSaveAndContinue => 'Spremi i nastavi';

  @override
  String get wizardEnterDeviceName => 'Unesite naziv uređaja prije nastavka.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Spremljeno $deviceName s postavkom $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Kontakti, sobe i repetitori';

  @override
  String get wizardNetworkDescription =>
      'Kartica Kontakti organizira mrežu koju otkrijete i rute koje s vremenom naučite.';

  @override
  String get wizardNetworkFeature1 =>
      'Pregledajte članove tima, repetitore, sobe, kanale i oglase na čekanju na jednom popisu.';

  @override
  String get wizardNetworkFeature2 =>
      'Koristite pametni ping, prijavu u sobe, naučene putanje i alate za resetiranje ruta kada povezanost postane neuredna.';

  @override
  String get wizardNetworkFeature3 =>
      'Stvarajte kanale i upravljajte mrežnim odredištima bez napuštanja aplikacije.';

  @override
  String get wizardMapOpsTitle => 'Karta, tragovi i dijeljena geometrija';

  @override
  String get wizardMapOpsDescription =>
      'Karta u aplikaciji izravno je povezana s porukama, praćenjem i SAR slojevima umjesto da bude zaseban preglednik.';

  @override
  String get wizardMapOpsFeature1 =>
      'Pratite vlastitu poziciju, lokacije suigrača i tragove kretanja na karti.';

  @override
  String get wizardMapOpsFeature2 =>
      'Otvorite crteže iz poruka, pregledajte ih unutar sučelja i po potrebi ih uklonite s karte.';

  @override
  String get wizardMapOpsFeature3 =>
      'Koristite karte repetitora i dijeljene slojeve kako biste razumjeli doseg mreže na terenu.';

  @override
  String get wizardToolsTitle => 'Alati izvan poruka';

  @override
  String get wizardToolsDescription =>
      'Ovdje postoji više od četiri glavne kartice. Aplikacija uključuje i konfiguraciju, dijagnostiku te opcionalne radne tokove senzora.';

  @override
  String get wizardToolsFeature1 =>
      'Otvorite konfiguraciju uređaja kako biste promijenili radijske postavke, telemetriju, TX snagu i detalje pratećeg uređaja.';

  @override
  String get wizardToolsFeature2 =>
      'Omogućite karticu Senzori kada želite nadzorne ploče praćenih senzora i brza osvježavanja.';

  @override
  String get wizardToolsFeature3 =>
      'Koristite zapisnike paketa, skeniranje spektra i razvojnu dijagnostiku pri rješavanju problema s mesh mrežom.';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => 'U Senzorima';

  @override
  String get contactAddToSensors => 'Dodaj u Senzore';

  @override
  String get contactSetPath => 'Postavi putanju';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName dodan u Senzore';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Brisanje rute nije uspjelo: $error';
  }

  @override
  String get contactRouteCleared => 'Ruta obrisana';

  @override
  String contactRouteSet(String route) {
    return 'Ruta postavljena: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Postavljanje rute nije uspjelo: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'ACK istek vremena';

  @override
  String get opcode => 'Opkod';

  @override
  String get payload => 'Sadržaj';

  @override
  String get hops => 'Skokovi';

  @override
  String get hashSize => 'Veličina hash-a';

  @override
  String get pathBytes => 'Bajtovi putanje';

  @override
  String get selectedPath => 'Odabrana putanja';

  @override
  String get estimatedTx => 'Procijenjeno slanje';

  @override
  String get senderToReceipt => 'Od pošiljatelja do primitka';

  @override
  String get receivedCopies => 'Primljene kopije';

  @override
  String get retryCause => 'Razlog ponovnog pokušaja';

  @override
  String get retryMode => 'Način ponovnog pokušaja';

  @override
  String get retryResult => 'Rezultat ponovnog pokušaja';

  @override
  String get lastRetry => 'Zadnji pokušaj';

  @override
  String get rxPackets => 'RX paketi';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Brzina';

  @override
  String get window => 'Prozor';

  @override
  String get posttxDelay => 'Kašnjenje nakon slanja';

  @override
  String get bandpass => 'Pojasni filtar';

  @override
  String get bandpassFilterVoice => 'Pojasni filtar glasa';

  @override
  String get frequency => 'Frekvencija';

  @override
  String get australia => 'Australija';

  @override
  String get australiaNarrow => 'Australija (usko)';

  @override
  String get australiaQld => 'Australija: QLD';

  @override
  String get australiaSaWa => 'Australija: SA, WA';

  @override
  String get newZealand => 'Novi Zeland';

  @override
  String get newZealandNarrow => 'Novi Zeland (usko)';

  @override
  String get switzerland => 'Švicarska';

  @override
  String get portugal433 => 'Portugal 433';

  @override
  String get portugal868 => 'Portugal 868';

  @override
  String get czechRepublicNarrow => 'Češka (usko)';

  @override
  String get eu433mhzLongRange => 'EU 433MHz (veliki domet)';

  @override
  String get euukDeprecated => 'EU/UK (zastarjelo)';

  @override
  String get euukNarrow => 'EU/UK (usko)';

  @override
  String get usacanadaRecommended => 'SAD/Kanada (preporučeno)';

  @override
  String get vietnamDeprecated => 'Vijetnam (zastarjelo)';

  @override
  String get vietnamNarrow => 'Vijetnam (usko)';

  @override
  String get active => 'Aktivno';

  @override
  String get addContact => 'Dodaj kontakt';

  @override
  String get all => 'Sve';

  @override
  String get autoResolve => 'Automatski razriješi';

  @override
  String get clearAllLabel => 'Očisti sve';

  @override
  String get clearRelays => 'Očisti posrednike';

  @override
  String get clearFilters => 'Očisti filtre';

  @override
  String get clearRoute => 'Očisti putanju';

  @override
  String get clearMessages => 'Očisti poruke';

  @override
  String get clearScale => 'Očisti mjerilo';

  @override
  String get clearDiscoveries => 'Očisti otkrića';

  @override
  String get clearOnlineTraceDatabase => 'Očisti bazu mrežnih tragova';

  @override
  String get clearAllChannels => 'Očisti sve kanale';

  @override
  String get clearAllContacts => 'Očisti sve kontakte';

  @override
  String get clearChannels => 'Očisti kanale';

  @override
  String get clearContacts => 'Očisti kontakte';

  @override
  String get clearPathOnMaxRetry => 'Očisti putanju kod maks. pokušaja';

  @override
  String get create => 'Stvori';

  @override
  String get custom => 'Prilagođeno';

  @override
  String get defaultValue => 'Zadano';

  @override
  String get duplicate => 'Dupliciraj';

  @override
  String get editName => 'Uredi ime';

  @override
  String get open => 'Otvori';

  @override
  String get paste => 'Zalijepi';

  @override
  String get preview => 'Pregled';

  @override
  String get remove => 'Ukloni';

  @override
  String get rename => 'Preimenuj';

  @override
  String get resolveAll => 'Razriješi sve';

  @override
  String get send => 'Pošalji';

  @override
  String get sendAnyway => 'Svejedno pošalji';

  @override
  String get share => 'Dijeli';

  @override
  String get shareContact => 'Dijeli kontakt';

  @override
  String get trace => 'Praćenje';

  @override
  String get use => 'Koristi';

  @override
  String get useSelectedFrequency => 'Koristi odabranu frekvenciju';

  @override
  String get discovery => 'Otkrivanje';

  @override
  String get discoverRepeaters => 'Otkrij posrednike';

  @override
  String get discoverSensors => 'Otkrij senzore';

  @override
  String get repeaterDiscoverySent => 'Otkrivanje posrednika poslano';

  @override
  String get sensorDiscoverySent => 'Otkrivanje senzora poslano';

  @override
  String get clearedPendingDiscoveries => 'Očišćena čekajuća otkrića.';

  @override
  String get autoDiscovery => 'Automatsko otkrivanje';

  @override
  String get enableAutomaticAdding => 'Omogući automatsko dodavanje';

  @override
  String get autoaddRepeaters => 'Automatski dodaj posrednike';

  @override
  String get autoaddRoomServers => 'Automatski dodaj poslužitelje soba';

  @override
  String get autoaddSensors => 'Automatski dodaj senzore';

  @override
  String get autoaddUsers => 'Automatski dodaj korisnike';

  @override
  String get overwriteOldestWhenFull => 'Prepiši najstarije kad je puno';

  @override
  String get storage => 'Pohrana';

  @override
  String get dangerZone => 'Opasna zona';

  @override
  String get profiles => 'Profili';

  @override
  String get favourites => 'Favoriti';

  @override
  String get sensors => 'Senzori';

  @override
  String get others => 'Ostali';

  @override
  String get gpsModule => 'GPS modul';

  @override
  String get liveTraffic => 'Promet uživo';

  @override
  String get repeatersMap => 'Karta posrednika';

  @override
  String get spectrumScan => 'Spektralno skeniranje';

  @override
  String get blePacketLogs => 'BLE zapisi paketa';

  @override
  String get onlineTraceDatabase => 'Baza mrežnih tragova';

  @override
  String get routePathByteSize => 'Veličina putanje u bajtima';

  @override
  String get messageNotifications => 'Obavijesti o porukama';

  @override
  String get sarAlerts => 'SAR upozorenja';

  @override
  String get discoveryNotifications => 'Obavijesti o otkrivanju';

  @override
  String get updateNotifications => 'Obavijesti o ažuriranju';

  @override
  String get muteWhileAppIsOpen => 'Utišaj dok je aplikacija otvorena';

  @override
  String get disableContacts => 'Onemogući kontakte';

  @override
  String get enableSensorsTab => 'Omogući karticu Senzori';

  @override
  String get enableProfiles => 'Omogući profile';

  @override
  String get autoRouteRotation => 'Automatsko rotiranje putanje';

  @override
  String get nearestRepeaterFallback => 'Najbliži posrednik kao rezerva';

  @override
  String get deleteAllStoredMessageHistory =>
      'Izbriši svu pohranjenu povijest poruka';

  @override
  String get messageFontSize => 'Veličina fonta poruka';

  @override
  String get rotateMapWithHeading => 'Rotiraj kartu prema smjeru';

  @override
  String get showMapDebugInfo => 'Prikaži debug info karte';

  @override
  String get openMapInFullscreen => 'Otvori kartu na cijelom zaslonu';

  @override
  String get showSarMarkersLabel => 'Prikaži SAR oznake';

  @override
  String get displaySarMarkersOnTheMainMap =>
      'Prikaži SAR oznake na glavnoj karti';

  @override
  String get showAllContactTrailsLabel => 'Prikaži sve tragove kontakata';

  @override
  String get hideRepeatersOnMap => 'Sakrij posrednike na karti';

  @override
  String get setMapScale => 'Postavi mjerilo karte';

  @override
  String get customMapScaleSaved => 'Prilagođeno mjerilo karte spremljeno';

  @override
  String get voiceBitrate => 'Bitna brzina glasa';

  @override
  String get voiceCompressor => 'Kompresor glasa';

  @override
  String get balancesQuietAndLoudSpeechLevels =>
      'Izravnava tihe i glasne razine govora';

  @override
  String get voiceLimiter => 'Ograničivač glasa';

  @override
  String get preventsClippingPeaksBeforeEncoding =>
      'Sprječava rezanje vrhova prije kodiranja';

  @override
  String get micAutoGain => 'Automatsko pojačanje mikrofona';

  @override
  String get letsTheRecorderAdjustInputLevel =>
      'Dopušta snimaču prilagodbu razine ulaza';

  @override
  String get echoCancellation => 'Poništavanje odjeka';

  @override
  String get noiseSuppression => 'Potiskivanje šuma';

  @override
  String get trimSilenceInVoiceMessages => 'Izreži tišinu u glasovnim porukama';

  @override
  String get compressor => 'Kompresor';

  @override
  String get limiter => 'Ograničivač';

  @override
  String get autoGain => 'Automatsko pojačanje';

  @override
  String get echoCancel => 'Odjek';

  @override
  String get noiseSuppress => 'Šum';

  @override
  String get silenceTrim => 'Tišina';

  @override
  String get maxImageSize => 'Maksimalna veličina slike';

  @override
  String get imageCompression => 'Kompresija slike';

  @override
  String get grayscale => 'Sivine';

  @override
  String get ultraMode => 'Ultra način';

  @override
  String get fastPrivateGpsUpdates => 'Brza privatna GPS ažuriranja';

  @override
  String get movementThreshold => 'Prag kretanja';

  @override
  String get fastGpsMovementThreshold => 'Prag kretanja za brzi GPS';

  @override
  String get fastGpsActiveuseInterval =>
      'Interval aktivnog korištenja brzog GPS-a';

  @override
  String get activeuseUpdateInterval =>
      'Interval ažuriranja pri aktivnom korištenju';

  @override
  String get repeatNearbyTraffic => 'Ponovi obližnji promet';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Proslijedi kroz posrednike kroz mrežu';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Samo obližnji, bez preplavljivanja posrednika';

  @override
  String get multihop => 'Višeskočno';

  @override
  String get createProfile => 'Stvori profil';

  @override
  String get renameProfile => 'Preimenuj profil';

  @override
  String get newProfile => 'Novi profil';

  @override
  String get manageProfiles => 'Upravljaj profilima';

  @override
  String get enableProfilesToStartManagingThem =>
      'Omogućite profile da biste ih počeli upravljati.';

  @override
  String get openMessage => 'Otvori poruku';

  @override
  String get jumpToTheRelatedSarMessage => 'Skoči na povezanu SAR poruku';

  @override
  String get removeSarMarker => 'Ukloni SAR oznaku';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Odaberite odredište za slanje SAR oznake';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR oznaka emitirana na javni kanal';

  @override
  String get sarMarkerSentToRoom => 'SAR oznaka poslana u sobu';

  @override
  String get loadFromGallery => 'Učitaj iz galerije';

  @override
  String get replaceImage => 'Zamijeni sliku';

  @override
  String get selectFromGallery => 'Odaberi iz galerije';

  @override
  String get team => 'Tim';

  @override
  String get found => 'Pronađeno';

  @override
  String get staging => 'Sabirno mjesto';

  @override
  String get object => 'Objekt';

  @override
  String get quiet => 'Tiho';

  @override
  String get moderate => 'Umjereno';

  @override
  String get busy => 'Zauzeto';

  @override
  String get spectrumScanReturnedNoCandidateFrequencies =>
      'Spektralno skeniranje nije pronašlo prikladne frekvencije';

  @override
  String get searchMessages => 'Pretraži poruke';

  @override
  String get sendImageFromGallery => 'Pošalji sliku iz galerije';

  @override
  String get takePhoto => 'Snimi fotografiju';

  @override
  String get dmOnly => 'Samo izravno';

  @override
  String get allMessages => 'Sve poruke';

  @override
  String get sendToPublicChannel => 'Pošalji na javni kanal?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Odaberite vrstu oznake i odredište';

  @override
  String get noDestinationsAvailableLabel => 'Nema dostupnih odredišta';

  @override
  String get image => 'Slika';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Dimenzije';

  @override
  String get segments => 'Segmenti';

  @override
  String get transfers => 'Prijenosi';

  @override
  String get downloadedBy => 'Preuzeo';

  @override
  String get saveDiscoverySettings => 'Spremi postavke otkrivanja';

  @override
  String get savePublicInfo => 'Spremi javne podatke';

  @override
  String get saveRadioSettings => 'Spremi radijske postavke';

  @override
  String get savePath => 'Spremi putanju';

  @override
  String get wipeDeviceData => 'Obriši podatke uređaja';

  @override
  String get wipeDevice => 'Obriši uređaj';

  @override
  String get destructiveDeviceActions => 'Destruktivne radnje na uređaju.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Odaberite predefiniranu postavku ili fino podesite radijske postavke.';

  @override
  String get chooseTheNameAndLocationThisDeviceShares =>
      'Odaberite ime i lokaciju koju ovaj uređaj dijeli.';

  @override
  String get availableSpaceOnThisDevice =>
      'Raspoloživi prostor na ovom uređaju.';

  @override
  String get used => 'Korišteno';

  @override
  String get total => 'Ukupno';

  @override
  String get renameValue => 'Preimenuj vrijednost';

  @override
  String get customizeFields => 'Prilagodi polja';

  @override
  String get livePreview => 'Pregled uživo';

  @override
  String get refreshSchedule => 'Raspored osvježavanja';

  @override
  String get noResponse => 'Nema odgovora';

  @override
  String get refreshing => 'Osvježavam';

  @override
  String get unavailable => 'Nedostupno';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Odaberite posrednika ili čvor za praćenje.';

  @override
  String get publicKeyLabel => 'Javni ključ';

  @override
  String get alreadyInContacts => 'Već u kontaktima';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Povežite se s uređajem prije dodavanja kontakata';

  @override
  String get fromContacts => 'Iz kontakata';

  @override
  String get onlineOnly => 'Samo povezani';

  @override
  String get inBoth => 'U oba';

  @override
  String get source => 'Izvor';

  @override
  String get manualRouteEdit => 'Ručno uređivanje putanje';

  @override
  String get observedMeshRoute => 'Opažena mrežna putanja';

  @override
  String get allMessagesCleared => 'Sve poruke očišćene';

  @override
  String get onlineTraceDatabaseCleared => 'Baza mrežnih tragova očišćena';

  @override
  String get packetLogsCleared => 'Zapisi paketa očišćeni';

  @override
  String get hexDataCopiedToClipboard => 'Hex podaci kopirani u međuspremnik';

  @override
  String get developerModeEnabled => 'Razvojni način omogućen';

  @override
  String get developerModeDisabled => 'Razvojni način onemogućen';

  @override
  String get clipboardIsEmpty => 'Međuspremnik je prazan';

  @override
  String get contactImported => 'Kontakt uvezen';

  @override
  String get contactLinkCopiedToClipboard =>
      'Poveznica na kontakt kopirana u međuspremnik';

  @override
  String get failedToExportContact => 'Izvoz kontakta nije uspio';

  @override
  String get noLogsToExport => 'Nema zapisa za izvoz';

  @override
  String get exportAsCsv => 'Izvezi kao CSV';

  @override
  String get exportAsText => 'Izvezi kao tekst';

  @override
  String get receivedRfc3339 => 'Primljeno (RFC3339)';

  @override
  String get buildTime => 'Vrijeme gradnje';

  @override
  String get downloadUrlNotAvailable => 'URL za preuzimanje nije dostupan';

  @override
  String get cannotOpenDownloadUrl => 'Ne mogu otvoriti URL za preuzimanje';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Provjera ažuriranja dostupna je samo na Androidu';

  @override
  String get youAreRunningTheLatestVersion => 'Koristite najnoviju verziju';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Ažuriranje dostupno, ali URL za preuzimanje nije pronađen';

  @override
  String get startTictactoe => 'Pokreni Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe nije dostupan';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: protivnik nepoznat';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: čekanje na početak';

  @override
  String get acceptsShareLinks => 'Prihvaća dijeljene veze';

  @override
  String get supportsRawHex => 'Podržava sirovi hex';

  @override
  String get clipboardfriendly => 'Pogodno za međuspremnik';

  @override
  String get captured => 'Zabilježeno';

  @override
  String get size => 'Veličina';

  @override
  String get noCustomChannelsToClear => 'Nema prilagođenih kanala za brisanje.';

  @override
  String get noDeviceContactsToClear => 'Nema kontakata uređaja za brisanje.';

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
