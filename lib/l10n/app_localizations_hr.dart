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
  String get loadSampleData => 'Učitaj primjer podataka';

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
  String get delete => 'Izbriši';

  @override
  String get viewOnMap => 'Prikaži na karti';

  @override
  String get refresh => 'Osvježi';

  @override
  String get sendDirectMessage => 'Pošalji izravnu poruku';

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
  String get flood => 'Poplava';

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
    return 'Pingiranje $name (poplava - nema puta)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Istek izravnog pinga - ponovni pokušaj $name s poplavom...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping uspješan prema $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (putem rezervnog plavljenja)';

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
  String get filterMarkers => 'Filtriraj markere';

  @override
  String get filterMarkersTooltip => 'Filtriraj markere';

  @override
  String get contactsFilter => 'Kontakti';

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
}
