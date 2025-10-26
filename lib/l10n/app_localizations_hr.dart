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
  String get scanningForDevices => 'Skeniranje uređaja...';

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
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Objavljeno na $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Neuspjela objava: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Ponovno povezivanje... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Otkaži ponovno povezivanje';

  @override
  String get mapManagement => 'Upravljanje kartom';

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
  String get followSystemTheme => 'Slijedi sistemsku temu';

  @override
  String get showRxTxIndicators => 'Prikaži RX/TX indikatore';

  @override
  String get displayPacketActivity =>
      'Prikaži indikatore aktivnosti paketa u gornjoj traci';

  @override
  String get simpleMode => 'Jednostavni način';

  @override
  String get simpleModeDescription =>
      'Sakrij nevažne informacije u porukama i kontaktima';

  @override
  String get language => 'Jezik';

  @override
  String get chooseLanguage => 'Odaberite jezik';

  @override
  String get english => 'Engleski';

  @override
  String get slovenian => 'Slovenski';

  @override
  String get croatian => 'Hrvatski';

  @override
  String get german => 'Njemački';

  @override
  String get spanish => 'Španjolski';

  @override
  String get french => 'Francuski';

  @override
  String get italian => 'Talijanski';

  @override
  String get locationBroadcasting => 'Emitiranje lokacije';

  @override
  String get autoLocationTracking => 'Automatsko praćenje lokacije';

  @override
  String get automaticallyBroadcastPosition =>
      'Automatski emitiraj ažuriranja pozicije';

  @override
  String get configureTracking => 'Konfiguriraj praćenje';

  @override
  String get distanceAndTimeThresholds => 'Pragovi udaljenosti i vremena';

  @override
  String get locationTrackingConfiguration => 'Konfiguracija praćenja lokacije';

  @override
  String get configureWhenLocationBroadcasts =>
      'Konfigurirajte kada se emitiranja lokacije šalju u mesh mrežu';

  @override
  String get minimumDistance => 'Minimalna udaljenost';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Emitiraj tek nakon pomicanja $distance metara';
  }

  @override
  String get maximumDistance => 'Maksimalna udaljenost';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Uvijek emitiraj nakon pomicanja $distance metara';
  }

  @override
  String get minimumTimeInterval => 'Minimalni vremenski interval';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Uvijek emitiraj svakih $duration';
  }

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
      '• Flutter za višeplatformski razvoj\n• BLE (Bluetooth Low Energy) za mesh mrežu\n• OpenStreetMap za kartografiju\n• Provider za upravljanje stanjem\n• SharedPreferences za lokalno pohranu';

  @override
  String get developer => 'Programer';

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
      'Zadani PIN za uređaje bez zaslona je 123456. Problemi s uparivanjem? Zaboravite bluetooth uređaj u postavkama sustava.';

  @override
  String get noMessagesYet => 'Još nema poruka';

  @override
  String get pullDownToSync => 'Povucite prema dolje za sinkronizaciju';

  @override
  String get deleteContact => 'Izbriši kontakt';

  @override
  String get delete => 'Obriši';

  @override
  String get viewOnMap => 'Prikaži na karti';

  @override
  String get refresh => 'Osvježi';

  @override
  String get sendDirectMessage => 'Pošalji';

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
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return 'Poslano $count crtež$plural karte u $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return 'Podijeljeno $success/$total crtež$plural u $roomName';
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
  String get noLocalDrawings => 'Nema lokalnih crteža za dijeljenje';

  @override
  String get publicChannel => 'Javni kanal';

  @override
  String get broadcastToAll => 'Emitiraj svim obližnjim čvorovima (privremeno)';

  @override
  String get storedPermanently => 'Trajno pohranjeno u sobi';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return 'Poslano $count crtež$plural na javni kanal';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return 'Podijeljeno $success/$total crteža na javni kanal';
  }

  @override
  String get notConnectedToDevice => 'Nije povezano s uređajem';

  @override
  String get directMessage => 'Izravna poruka';

  @override
  String directMessageSentTo(String contactName) {
    return 'Izravna poruka poslana $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Neuspjelo slanje: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'Ova poruka će biti poslana izravno $contactName. Također će se prikazati u glavnom feedu poruka.';
  }

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
  String get myLocation => 'Moja lokacija';

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
  String get admin => 'Administrator';

  @override
  String get loggedIn => 'Prijavljen';

  @override
  String get noGpsData => 'Nema GPS podataka';

  @override
  String get distance => 'Udaljenost';

  @override
  String pingingDirect(String name) {
    return 'Pingiranje $name (izravno putem puta)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Pingiranje $name (preplavljanje - nema puta)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Istek izravnog pinga - ponovni pokušaj $name s preplavljanjem...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping uspješan prema $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (putem rezervnog preplavljanja)';

  @override
  String pingFailed(String name) {
    return 'Ping neuspješan prema $name - nije primljen odgovor';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Jeste li sigurni da želite izbrisati \"$name\"?\n\nOvo će ukloniti kontakt iz aplikacije i pratećeg radio uređaja.';
  }

  @override
  String removingContact(String name) {
    return 'Uklanjanje $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Kontakt \"$name\" uklonjen';
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
  String requestingTelemetry(String name) {
    return 'Zahtijevanje telemetrije od $name...';
  }

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
  String get nearbyContacts => 'Obližnji kontakti';

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
    return 'Ššir: $latitude Dužina: $longitude';
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
  String get cacheStatistics => 'Statistika predmemorije';

  @override
  String get totalTiles => 'Ukupno pločica';

  @override
  String get cacheSize => 'Veličina predmemorije';

  @override
  String get storeName => 'Ime pohrane';

  @override
  String get noCacheStatistics => 'Statistika predmemorije nije dostupna';

  @override
  String get downloadRegion => 'Preuzmi regiju';

  @override
  String get mapLayer => 'Sloj karte';

  @override
  String get regionBounds => 'Granice regije';

  @override
  String get north => 'Sjever';

  @override
  String get south => 'Jug';

  @override
  String get east => 'Istok';

  @override
  String get west => 'Zapad';

  @override
  String get zoomLevels => 'Razine zumiranja';

  @override
  String minZoom(int zoom) {
    return 'Min: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Maks: $zoom';
  }

  @override
  String get downloadingDots => 'Preuzimanje...';

  @override
  String get cancelDownload => 'Otkaži preuzimanje';

  @override
  String get downloadRegionButton => 'Preuzmi regiju';

  @override
  String get downloadNote =>
      'Napomena: Velike regije ili visoke razine zumiranja mogu zahtijevati značajno vrijeme i prostor za pohranu.';

  @override
  String get cacheManagement => 'Upravljanje predmemorijom';

  @override
  String get clearAllMaps => 'Očisti sve karte';

  @override
  String get clearMapsConfirmTitle => 'Očisti sve karte';

  @override
  String get clearMapsConfirmMessage =>
      'Jeste li sigurni da želite izbrisati sve preuzete karte? Ova radnja se ne može poništiti.';

  @override
  String get mapDownloadCompleted => 'Preuzimanje karte završeno!';

  @override
  String get cacheClearedSuccessfully => 'Predmemorija uspješno očišćena!';

  @override
  String get downloadCancelled => 'Preuzimanje otkazano';

  @override
  String get startingDownload => 'Pokretanje preuzimanja...';

  @override
  String get downloadingMapTiles => 'Preuzimanje pločica karte...';

  @override
  String get downloadCompletedSuccessfully => 'Preuzimanje uspješno završeno!';

  @override
  String get cancellingDownload => 'Otkazivanje preuzimanja...';

  @override
  String errorLoadingStats(String error) {
    return 'Greška pri učitavanju statistike: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Preuzimanje nije uspjelo: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Otkazivanje nije uspjelo: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Čišćenje predmemorije nije uspjelo: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Min zumiranje: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Maks zumiranje: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Minimalno zumiranje mora biti manje ili jednako maksimalnom zumiranju';

  @override
  String get selectMapLayer => 'Odaberite sloj karte';

  @override
  String get mapOptions => 'Opcije karte';

  @override
  String get showLegend => 'Prikaži legendu';

  @override
  String get displayMarkerTypeCounts => 'Prikaži broj vrsta markera';

  @override
  String get rotateMapWithHeading => 'Rotiraj kartu sa smjerom';

  @override
  String get mapFollowsDirection => 'Karta slijedi vaš smjer pri kretanju';

  @override
  String get showMapDebugInfo => 'Prikaži debug informacije karte';

  @override
  String get displayZoomLevelBounds => 'Prikaži razinu zumiranja i granice';

  @override
  String get fullscreenMode => 'Način cijelog zaslona';

  @override
  String get hideUiFullMapView =>
      'Sakrij sve UI kontrole za prikaz cijele karte';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI satelit';

  @override
  String get googleHybrid => 'Google hibridno';

  @override
  String get googleRoadmap => 'Google cestovna karta';

  @override
  String get googleTerrain => 'Google teren';

  @override
  String get downloadVisibleArea => 'Preuzmi vidljivo područje';

  @override
  String get initializingMap => 'Inicijalizacija karte...';

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
  String get messageSentToPublicChannel => 'Poruka poslana na javni kanal';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Molimo odaberite sobu za slanje SAR markera';

  @override
  String failedToSendSarMarker(String error) {
    return 'Neuspjelo slanje SAR markera: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'SAR marker poslan u $roomName';
  }

  @override
  String get notConnectedCannotSync =>
      'Nije povezano - ne može se sinkronizirati poruke';

  @override
  String syncedMessageCount(int count) {
    return 'Sinkronizirano $count poruka';
  }

  @override
  String get noNewMessages => 'Nema novih poruka';

  @override
  String syncFailed(String error) {
    return 'Sinkronizacija nije uspjela: $error';
  }

  @override
  String get failedToResendMessage => 'Neuspjelo ponovno slanje poruke';

  @override
  String get retryingMessage => 'Ponovni pokušaj slanja poruke...';

  @override
  String retryFailed(String error) {
    return 'Ponovni pokušaj nije uspio: $error';
  }

  @override
  String get textCopiedToClipboard => 'Tekst kopiran u međuspremnik';

  @override
  String get cannotReplySenderMissing =>
      'Ne mogu odgovoriti: informacije o pošiljatelju nedostaju';

  @override
  String get cannotReplyContactNotFound =>
      'Ne mogu odgovoriti: kontakt nije pronađen';

  @override
  String get messageDeleted => 'Poruka izbrisana';

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
  String get locationShared => 'Lokacija podijeljena';

  @override
  String get refreshedContacts => 'Kontakti osvježeni';

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
  String get offlineVectorMaps => 'Offline vektorske karte';

  @override
  String get offlineVectorMapsDescription =>
      'Uvezite i upravljajte offline vektorskim pločicama karata (MBTiles format) za upotrebu bez internetske veze';

  @override
  String get importMbtiles => 'Uvezi MBTiles datoteku';

  @override
  String get importMbtilesNote =>
      'Podržava MBTiles datoteke s vektorskim pločicama (PBF/MVT format). Geofabrik izvodi odlično rade!';

  @override
  String get noMbtilesFiles => 'Nisu pronađene offline vektorske karte';

  @override
  String get mbtilesImportedSuccessfully => 'MBTiles datoteka uspješno uvezena';

  @override
  String get failedToImportMbtiles => 'Neuspjeli uvoz MBTiles datoteke';

  @override
  String get deleteMbtilesConfirmTitle => 'Izbriši offline kartu';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Jeste li sigurni da želite izbrisati \"$name\"? Ovo će trajno ukloniti offline kartu.';
  }

  @override
  String get mbtilesDeletedSuccessfully => 'Offline karta uspješno izbrisana';

  @override
  String get failedToDeleteMbtiles => 'Neuspjelo brisanje offline karte';

  @override
  String get importExportCachedTiles => 'Uvoz/Izvoz predmemoriranih pločica';

  @override
  String get importExportDescription =>
      'Sigurnosno kopirajte, dijelite i vraćajte preuzete pločice karte između uređaja';

  @override
  String get exportTilesToFile => 'Izvezi pločice u datoteku';

  @override
  String get importTilesFromFile => 'Uvezi pločice iz datoteke';

  @override
  String get selectExportLocation => 'Odaberite lokaciju izvoza';

  @override
  String get selectImportFile => 'Odaberite arhivu pločica';

  @override
  String get exportingTiles => 'Izvažanje pločica...';

  @override
  String get importingTiles => 'Uvažanje pločica...';

  @override
  String exportSuccess(int count) {
    return 'Uspješno izvezeno $count pločica';
  }

  @override
  String importSuccess(int count) {
    return 'Uspješno uvezeno $count skladišta';
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
      'Stvara komprimiranu arhivsku datoteku (.fmtc) koju možete dijeliti i uvesti na drugim uređajima.';

  @override
  String get importNote =>
      'Uvozi pločice karte iz prethodno izvezene arhivske datoteke. Pločice će biti spojene s postojećom predmemorijom.';

  @override
  String get noTilesToExport => 'Nema pločica za izvoz';

  @override
  String archiveContainsStores(int count) {
    return 'Arhiva sadrži $count skladišta';
  }

  @override
  String get vectorTiles => 'Vektorske pločice';

  @override
  String get schema => 'Shema';

  @override
  String get unknown => 'Nepoznato';

  @override
  String get bounds => 'Granice';

  @override
  String get onlineLayers => 'Mrežni slojevi';

  @override
  String get offlineLayers => 'Offline slojevi';

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
  String get firmware => 'Firmware';

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
  String get lon => 'Dug';

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
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Uvezi';

  @override
  String get exportToClipboard => 'Izvezi';

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
  String get resetToDefaults => 'Vrati na zadane';

  @override
  String get resetToDefaultsConfirmation =>
      'Ovo će izbrisati sve prilagođene predloške i vratiti 4 zadana predloška. Nastaviti?';

  @override
  String get reset => 'Vrati';

  @override
  String get resetComplete => 'Predlošci vraćeni na zadane';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

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
  String get broadcastToAllNearby => 'Emituj svima u blizini';

  @override
  String get searchRecipients => 'Pretraži primatelje...';

  @override
  String get noContactsFound => 'Nema kontakata';

  @override
  String get noRoomsFound => 'Nema soba';

  @override
  String get noContactsOrRoomsAvailable => 'Nema dostupnih kontakata ili soba';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'Poruke će biti poslane na javni kanal';

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
  String get sampleMsgAllTeamsCheckIn => 'Svi timovi se jave';

  @override
  String get sampleMsgWeatherUpdate =>
      'Ažuriranje vremena: Vedro nebo, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Bazni kamp uspostavljen na okupljalište';

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
  String get coordinatesCopiedToClipboard =>
      'Koordinate kopirane u međuspremnik';

  @override
  String get drawingShared => 'Crtež karte';

  @override
  String get drawingHidden => 'Crtež sakriven s karte';

  @override
  String alreadyShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count već podijeljeno',
      one: '1 već podijeljeno',
    );
    return '$_temp0';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return 'Podijeljeno $count novi$plural crtež$plural';
  }

  @override
  String get shareDrawing => 'Podijeli Crtež';

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
    return 'Vaši Crteži ($count)';
  }

  @override
  String get shared => 'Podijeljeno';

  @override
  String get line => 'Linija';

  @override
  String get rectangle => 'Pravokutnik';
}
