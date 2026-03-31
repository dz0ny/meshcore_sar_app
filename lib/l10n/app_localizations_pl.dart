// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Wiadomości';

  @override
  String get contacts => 'Kontakty';

  @override
  String get map => 'Mapa';

  @override
  String get settings => 'Ustawienia';

  @override
  String get connect => 'Połącz';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get noDevicesFound => 'Nie znaleziono urządzeń';

  @override
  String get scanAgain => 'Skanuj ponownie';

  @override
  String get tapToConnect => 'Dotknij, aby połączyć';

  @override
  String get deviceNotConnected => 'Urządzenie nie jest połączone';

  @override
  String get locationPermissionDenied => 'Odmówiono dostępu do lokalizacji';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Dostęp do lokalizacji został trwale zablokowany. Włącz go w Ustawieniach.';

  @override
  String get locationPermissionRequired =>
      'Dostęp do lokalizacji jest wymagany do śledzenia GPS i koordynacji zespołu. Możesz go włączyć później w Ustawieniach.';

  @override
  String get locationServicesDisabled =>
      'Usługi lokalizacji są wyłączone. Włącz je w Ustawieniach.';

  @override
  String get failedToGetGpsLocation => 'Nie udało się pobrać lokalizacji GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Nie udało się rozgłosić: $error';
  }

  @override
  String get cancelReconnection => 'Anuluj ponowne łączenie';

  @override
  String get general => 'Ogólne';

  @override
  String get theme => 'Motyw';

  @override
  String get chooseTheme => 'Wybierz motyw';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get blueLightTheme => 'Niebieski jasny motyw';

  @override
  String get blueDarkTheme => 'Niebieski ciemny motyw';

  @override
  String get sarRed => 'SAR Czerwony';

  @override
  String get alertEmergencyMode => 'Tryb alarmowy/awaryjny';

  @override
  String get sarGreen => 'SAR Zielony';

  @override
  String get safeAllClearMode => 'Tryb bezpieczny/wszystko jasne';

  @override
  String get autoSystem => 'Automatyczny (system)';

  @override
  String get followSystemTheme => 'Dopasuj do motywu systemowego';

  @override
  String get showRxTxIndicators => 'Pokaż wskaźniki RX/TX';

  @override
  String get displayPacketActivity =>
      'Wyświetlaj wskaźniki aktywności pakietów na górnym pasku';

  @override
  String get disableMap => 'Wyłącz mapę';

  @override
  String get disableMapDescription =>
      'Ukryj kartę mapy, aby zmniejszyć zużycie baterii';

  @override
  String get language => 'Język';

  @override
  String get chooseLanguage => 'Wybierz język';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get close => 'Zamknij';

  @override
  String get about => 'Informacje';

  @override
  String get appVersion => 'Wersja aplikacji';

  @override
  String get appName => 'Nazwa aplikacji';

  @override
  String get aboutMeshCoreSar => 'O MeshCore SAR';

  @override
  String get aboutDescription =>
      'Aplikacja poszukiwawczo-ratownicza zaprojektowana dla zespołów reagowania kryzysowego. Funkcje obejmują:\n\n• Sieć BLE mesh do komunikacji urządzenie-urządzenie\n• Mapy offline z wieloma warstwami\n• Śledzenie członków zespołu w czasie rzeczywistym\n• Taktyczne znaczniki SAR (odnaleziona osoba, pożar, strefa zbiórki)\n• Zarządzanie kontaktami i wiadomościami\n• Śledzenie GPS z kompasem\n• Buforowanie kafelków mapy do użytku offline';

  @override
  String get technologiesUsed => 'Użyte technologie:';

  @override
  String get technologiesList =>
      '• Flutter do rozwoju wieloplatformowego\n• BLE (Bluetooth Low Energy) do sieci mesh\n• OpenStreetMap do map\n• Provider do zarządzania stanem\n• SharedPreferences do pamięci lokalnej';

  @override
  String get moreInfo => 'Więcej informacji';

  @override
  String get packageName => 'Nazwa pakietu';

  @override
  String get sampleData => 'Dane przykładowe';

  @override
  String get sampleDataDescription =>
      'Wczytaj lub wyczyść przykładowe kontakty, wiadomości kanałów i znaczniki SAR do testów';

  @override
  String get loadSampleData => 'Wczytaj dane przykładowe';

  @override
  String get clearAllData => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataConfirmTitle => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataConfirmMessage =>
      'To wyczyści wszystkie kontakty i znaczniki SAR. Czy na pewno?';

  @override
  String get clear => 'Wyczyść';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Wczytano $teamCount członków zespołu, $channelCount kanałów, $sarCount znaczników SAR, $messageCount wiadomości';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Nie udało się wczytać danych przykładowych: $error';
  }

  @override
  String get allDataCleared => 'Wszystkie dane wyczyszczono';

  @override
  String get failedToStartBackgroundTracking =>
      'Nie udało się uruchomić śledzenia w tle. Sprawdź uprawnienia i połączenie BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Nadawanie lokalizacji: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Domyślny PIN dla urządzeń bez ekranu to 123456. Problem z parowaniem? Zapomnij urządzenie Bluetooth w ustawieniach systemu.';

  @override
  String get noMessagesYet => 'Brak wiadomości';

  @override
  String get pullDownToSync =>
      'Przeciągnij w dół, aby zsynchronizować wiadomości';

  @override
  String get deleteContact => 'Usuń kontakt';

  @override
  String get delete => 'Usuń';

  @override
  String get viewOnMap => 'Pokaż na mapie';

  @override
  String get refresh => 'Odśwież';

  @override
  String get resetPath => 'Resetuj trasę (wyznacz ponownie)';

  @override
  String get publicKeyCopied => 'Klucz publiczny skopiowano do schowka';

  @override
  String copiedToClipboard(String label) {
    return 'Skopiowano $label do schowka';
  }

  @override
  String get pleaseEnterPassword => 'Wprowadź hasło';

  @override
  String failedToSyncContacts(String error) {
    return 'Nie udało się zsynchronizować kontaktów: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Zalogowano pomyślnie! Oczekiwanie na wiadomości z pokoju...';

  @override
  String get loginFailed => 'Logowanie nie powiodło się - nieprawidłowe hasło';

  @override
  String loggingIn(String roomName) {
    return 'Logowanie do $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Nie udało się wysłać logowania: $error';
  }

  @override
  String get lowLocationAccuracy => 'Niska dokładność lokalizacji';

  @override
  String get continue_ => 'Kontynuuj';

  @override
  String get sendSarMarker => 'Wyślij znacznik SAR';

  @override
  String get deleteDrawing => 'Usuń rysunek';

  @override
  String get drawingTools => 'Narzędzia rysowania';

  @override
  String get drawLine => 'Rysuj linię';

  @override
  String get drawLineDesc => 'Narysuj odręczną linię na mapie';

  @override
  String get drawRectangle => 'Rysuj prostokąt';

  @override
  String get drawRectangleDesc => 'Narysuj prostokątny obszar na mapie';

  @override
  String get measureDistance => 'Mierz odległość';

  @override
  String get measureDistanceDesc => 'Przytrzymaj dwa punkty, aby zmierzyć';

  @override
  String get clearMeasurement => 'Wyczyść pomiar';

  @override
  String distanceLabel(String distance) {
    return 'Odległość: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Przytrzymaj dla drugiego punktu';

  @override
  String get longPressToStartMeasurement =>
      'Przytrzymaj, aby ustawić pierwszy punkt';

  @override
  String get longPressToStartNewMeasurement =>
      'Przytrzymaj, aby rozpocząć nowy pomiar';

  @override
  String get shareDrawings => 'Udostępnij rysunki';

  @override
  String get clearAllDrawings => 'Wyczyść wszystkie rysunki';

  @override
  String get completeLine => 'Zakończ linię';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Nadaj $count rysunek$plural do zespołu';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Usuń wszystkie $count rysunek$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Usunąć wszystkie $count rysunek$plural z mapy?';
  }

  @override
  String get drawing => 'Rysunek';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Udostępnij $count rysunek$plural';
  }

  @override
  String get showReceivedDrawings => 'Pokaż odebrane rysunki';

  @override
  String get showingAllDrawings => 'Pokazywane są wszystkie rysunki';

  @override
  String get showingOnlyYourDrawings => 'Pokazywane są tylko twoje rysunki';

  @override
  String get showSarMarkers => 'Pokaż znaczniki SAR';

  @override
  String get showingSarMarkers => 'Pokazywane są znaczniki SAR';

  @override
  String get hidingSarMarkers => 'Ukrywanie znaczników SAR';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get publicChannel => 'Kanał publiczny';

  @override
  String get broadcastToAll =>
      'Nadaj do wszystkich pobliskich węzłów (tymczasowo)';

  @override
  String get storedPermanently => 'Przechowywane na stałe w pokoju';

  @override
  String get notConnectedToDevice => 'Brak połączenia z urządzeniem';

  @override
  String get typeYourMessage => 'Wpisz wiadomość...';

  @override
  String get quickLocationMarker => 'Szybki znacznik lokalizacji';

  @override
  String get markerType => 'Typ znacznika';

  @override
  String get sendTo => 'Wyślij do';

  @override
  String get noDestinationsAvailable => 'Brak dostępnych odbiorców.';

  @override
  String get selectDestination => 'Wybierz odbiorcę...';

  @override
  String get ephemeralBroadcastInfo =>
      'Tymczasowe: nadawane tylko drogą radiową. Nie jest zapisywane - węzły muszą być online.';

  @override
  String get persistentRoomInfo =>
      'Trwałe: zapisywane niezmiennie w pokoju. Synchronizowane automatycznie i zachowywane offline.';

  @override
  String get location => 'Lokalizacja';

  @override
  String get fromMap => 'Z mapy';

  @override
  String get gettingLocation => 'Pobieranie lokalizacji...';

  @override
  String get locationError => 'Błąd lokalizacji';

  @override
  String get retry => 'Ponów';

  @override
  String get refreshLocation => 'Odśwież lokalizację';

  @override
  String accuracyMeters(int accuracy) {
    return 'Dokładność: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notatki (opcjonalnie)';

  @override
  String get addAdditionalInformation => 'Dodaj dodatkowe informacje...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Dokładność lokalizacji wynosi ±${accuracy}m. To może nie być wystarczająco dokładne dla działań SAR.\n\nKontynuować mimo to?';
  }

  @override
  String get loginToRoom => 'Zaloguj do pokoju';

  @override
  String get enterPasswordInfo =>
      'Wprowadź hasło, aby uzyskać dostęp do tego pokoju. Hasło zostanie zapisane na przyszłość.';

  @override
  String get password => 'Hasło';

  @override
  String get enterRoomPassword => 'Wpisz hasło pokoju';

  @override
  String get loggingInDots => 'Logowanie...';

  @override
  String get login => 'Zaloguj';

  @override
  String failedToAddRoom(String error) {
    return 'Nie udało się dodać pokoju do urządzenia: $error\n\nPokój mógł jeszcze nie rozpocząć nadawania.\nSpróbuj poczekać, aż pokój zacznie nadawać.';
  }

  @override
  String get direct => 'Bezpośrednie';

  @override
  String get flood => 'Rozgłoszeniowo';

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
  String get loggedIn => 'Zalogowano';

  @override
  String get noGpsData => 'Brak danych GPS';

  @override
  String get distance => 'Odległość';

  @override
  String directPingTimeout(String name) {
    return 'Przekroczono czas bezpośredniego ping - ponawianie dla $name przez flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping do $name nie powiódł się - nie otrzymano odpowiedzi';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Czy na pewno chcesz usunąć „$name”?\n\nTo usunie kontakt zarówno z aplikacji, jak i z towarzyszącego urządzenia radiowego.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Nie udało się usunąć kontaktu: $error';
  }

  @override
  String get type => 'Typ';

  @override
  String get publicKey => 'Klucz publiczny';

  @override
  String get lastSeen => 'Ostatnio widziany';

  @override
  String get roomStatus => 'Status pokoju';

  @override
  String get loginStatus => 'Status logowania';

  @override
  String get notLoggedIn => 'Niezalogowany';

  @override
  String get adminAccess => 'Dostęp administratora';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get permissions => 'Uprawnienia';

  @override
  String get passwordSaved => 'Hasło zapisano';

  @override
  String get locationColon => 'Lokalizacja:';

  @override
  String get telemetry => 'Telemetria';

  @override
  String get voltage => 'Napięcie';

  @override
  String get battery => 'Bateria';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Wilgotność';

  @override
  String get pressure => 'Ciśnienie';

  @override
  String get gpsTelemetry => 'GPS (telemetria)';

  @override
  String get updated => 'Zaktualizowano';

  @override
  String pathResetInfo(String name) {
    return 'Trasa dla $name została zresetowana. Następna wiadomość znajdzie nową trasę.';
  }

  @override
  String get reLoginToRoom => 'Zaloguj ponownie do pokoju';

  @override
  String get heading => 'Kierunek';

  @override
  String get elevation => 'Wysokość';

  @override
  String get accuracy => 'Dokładność';

  @override
  String get bearing => 'Namiar';

  @override
  String get direction => 'Kierunek';

  @override
  String get filterMarkers => 'Filtruj znaczniki';

  @override
  String get filterMarkersTooltip => 'Filtruj znaczniki';

  @override
  String get contactsFilter => 'Kontakty';

  @override
  String get repeatersFilter => 'Przekaźniki';

  @override
  String get sarMarkers => 'Znaczniki SAR';

  @override
  String get foundPerson => 'Odnaleziona osoba';

  @override
  String get fire => 'Pożar';

  @override
  String get stagingArea => 'Punkt zbiórki';

  @override
  String get showAll => 'Pokaż wszystko';

  @override
  String get locationUnavailable => 'Lokalizacja niedostępna';

  @override
  String get ahead => 'przed tobą';

  @override
  String degreesRight(int degrees) {
    return '$degrees° w prawo';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° w lewo';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Szer.: $latitude Dł.: $longitude';
  }

  @override
  String get noContactsYet => 'Brak kontaktów';

  @override
  String get connectToDeviceToLoadContacts =>
      'Połącz się z urządzeniem, aby wczytać kontakty';

  @override
  String get teamMembers => 'Członkowie zespołu';

  @override
  String get repeaters => 'Przekaźniki';

  @override
  String get rooms => 'Pokoje';

  @override
  String get channels => 'Kanały';

  @override
  String get selectMapLayer => 'Wybierz warstwę mapy';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satelita ESRI';

  @override
  String get googleHybrid => 'Google Hybrydowa';

  @override
  String get googleRoadmap => 'Google Drogowa';

  @override
  String get googleTerrain => 'Google Teren';

  @override
  String get dragToPosition => 'Przeciągnij do pozycji';

  @override
  String get createSarMarker => 'Utwórz znacznik SAR';

  @override
  String get compass => 'Kompas';

  @override
  String get navigationAndContacts => 'Nawigacja i kontakty';

  @override
  String get sarAlert => 'ALERT SAR';

  @override
  String get textCopiedToClipboard => 'Tekst skopiowano do schowka';

  @override
  String get cannotReplySenderMissing =>
      'Nie można odpowiedzieć: brak informacji o nadawcy';

  @override
  String get cannotReplyContactNotFound =>
      'Nie można odpowiedzieć: nie znaleziono kontaktu';

  @override
  String get copyText => 'Kopiuj tekst';

  @override
  String get saveAsTemplate => 'Zapisz jako szablon';

  @override
  String get templateSaved => 'Szablon zapisano pomyślnie';

  @override
  String get templateAlreadyExists => 'Szablon z tym emoji już istnieje';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get deleteMessageConfirmation =>
      'Czy na pewno chcesz usunąć tę wiadomość?';

  @override
  String get shareLocation => 'Udostępnij lokalizację';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nWspółrzędne: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Lokalizacja SAR';

  @override
  String get justNow => 'Przed chwilą';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min temu';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours godz. temu';
  }

  @override
  String daysAgo(int days) {
    return '$days dni temu';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds sek. temu';
  }

  @override
  String get sending => 'Wysyłanie...';

  @override
  String get sent => 'Wysłano';

  @override
  String get delivered => 'Dostarczono';

  @override
  String deliveredWithTime(int time) {
    return 'Dostarczono (${time}ms)';
  }

  @override
  String get failed => 'Niepowodzenie';

  @override
  String get broadcast => 'Nadawanie';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Dostarczono do $delivered/$total kontaktów';
  }

  @override
  String get allDelivered => 'Wszystko dostarczono';

  @override
  String get recipientDetails => 'Szczegóły odbiorcy';

  @override
  String get pending => 'Oczekujące';

  @override
  String get sarMarkerFoundPerson => 'Odnaleziona osoba';

  @override
  String get sarMarkerFire => 'Miejsce pożaru';

  @override
  String get sarMarkerStagingArea => 'Strefa zbiórki';

  @override
  String get sarMarkerObject => 'Odnaleziony obiekt';

  @override
  String get from => 'Od';

  @override
  String get coordinates => 'Współrzędne';

  @override
  String get tapToViewOnMap => 'Dotknij, aby zobaczyć na mapie';

  @override
  String get radioSettings => 'Ustawienia radia';

  @override
  String get frequencyMHz => 'Częstotliwość (MHz)';

  @override
  String get frequencyExample => 'np. 869.618';

  @override
  String get bandwidth => 'Szerokość pasma';

  @override
  String get spreadingFactor => 'Współczynnik rozpraszania';

  @override
  String get codingRate => 'Szybkość kodowania';

  @override
  String get txPowerDbm => 'Moc TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Maks: $power dBm';
  }

  @override
  String get you => 'Ty';

  @override
  String exportFailed(String error) {
    return 'Eksport nie powiódł się: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import nie powiódł się: $error';
  }

  @override
  String get unknown => 'Nieznane';

  @override
  String get onlineLayers => 'Warstwy online';

  @override
  String get locationTrail => 'Ślad lokalizacji';

  @override
  String get showTrailOnMap => 'Pokaż ślad na mapie';

  @override
  String get trailVisible => 'Ślad jest widoczny na mapie';

  @override
  String get trailHiddenRecording => 'Ślad jest ukryty (nadal nagrywany)';

  @override
  String get duration => 'Czas trwania';

  @override
  String get points => 'Punkty';

  @override
  String get clearTrail => 'Wyczyść ślad';

  @override
  String get clearTrailQuestion => 'Wyczyścić ślad?';

  @override
  String get clearTrailConfirmation =>
      'Czy na pewno chcesz wyczyścić bieżący ślad lokalizacji? Tego działania nie można cofnąć.';

  @override
  String get noTrailRecorded => 'Brak zapisanego śladu';

  @override
  String get startTrackingToRecord =>
      'Rozpocznij śledzenie lokalizacji, aby zapisać ślad';

  @override
  String get trailControls => 'Sterowanie śladem';

  @override
  String get contactTrails => 'Ślady kontaktów';

  @override
  String get showAllContactTrails => 'Pokaż wszystkie ślady kontaktów';

  @override
  String get noContactsWithLocationHistory =>
      'Brak kontaktów z historią lokalizacji';

  @override
  String showingTrailsForContacts(int count) {
    return 'Pokazywane są ślady dla $count kontaktów';
  }

  @override
  String get individualContactTrails => 'Indywidualne ślady kontaktów';

  @override
  String get deviceInformation => 'Informacje o urządzeniu';

  @override
  String get bleName => 'Nazwa BLE';

  @override
  String get meshName => 'Nazwa mesh';

  @override
  String get notSet => 'Nie ustawiono';

  @override
  String get model => 'Model';

  @override
  String get version => 'Wersja';

  @override
  String get buildDate => 'Data kompilacji';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Maks. kontaktów';

  @override
  String get maxChannels => 'Maks. kanałów';

  @override
  String get publicInfo => 'Informacje publiczne';

  @override
  String get meshNetworkName => 'Nazwa sieci mesh';

  @override
  String get nameBroadcastInMesh => 'Nazwa nadawana w ogłoszeniach mesh';

  @override
  String get telemetryAndLocationSharing =>
      'Telemetria i udostępnianie lokalizacji';

  @override
  String get lat => 'Szer.';

  @override
  String get lon => 'Dł.';

  @override
  String get useCurrentLocation => 'Użyj bieżącej lokalizacji';

  @override
  String get noneUnknown => 'Brak/Nieznane';

  @override
  String get chatNode => 'Węzeł czatu';

  @override
  String get repeater => 'Przekaźnik';

  @override
  String get roomChannel => 'Pokój/Kanał';

  @override
  String typeNumber(int number) {
    return 'Typ $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Skopiowano $label do schowka';
  }

  @override
  String failedToSave(String error) {
    return 'Nie udało się zapisać: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Nie udało się pobrać lokalizacji: $error';
  }

  @override
  String get sarTemplates => 'Szablony SAR';

  @override
  String get manageSarTemplates => 'Zarządzaj szablonami SAR';

  @override
  String get addTemplate => 'Dodaj szablon';

  @override
  String get editTemplate => 'Edytuj szablon';

  @override
  String get deleteTemplate => 'Usuń szablon';

  @override
  String get templateName => 'Nazwa szablonu';

  @override
  String get templateNameHint => 'np. Odnaleziona osoba';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji jest wymagane';

  @override
  String get nameRequired => 'Nazwa jest wymagana';

  @override
  String get templateDescription => 'Opis (opcjonalnie)';

  @override
  String get templateDescriptionHint => 'Dodaj dodatkowy kontekst...';

  @override
  String get templateColor => 'Kolor';

  @override
  String get previewFormat => 'Podgląd (format wiadomości SAR)';

  @override
  String get importFromClipboard => 'Importuj';

  @override
  String get exportToClipboard => 'Eksportuj';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Usunąć szablon „$name”?';
  }

  @override
  String get templateAdded => 'Dodano szablon';

  @override
  String get templateUpdated => 'Zaktualizowano szablon';

  @override
  String get templateDeleted => 'Usunięto szablon';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count szablonów',
      one: 'Zaimportowano 1 szablon',
      zero: 'Nie zaimportowano szablonów',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyeksportowano $count szablonów do schowka',
      one: 'Wyeksportowano 1 szablon do schowka',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Przywróć domyślne';

  @override
  String get resetToDefaultsConfirmation =>
      'To usunie wszystkie własne szablony i przywróci 4 domyślne szablony. Kontynuować?';

  @override
  String get reset => 'Resetuj';

  @override
  String get resetComplete => 'Szablony przywrócono do domyślnych';

  @override
  String get noTemplates => 'Brak dostępnych szablonów';

  @override
  String get tapAddToCreate => 'Dotknij +, aby utworzyć pierwszy szablon';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Uprawnienia';

  @override
  String get locationPermission => 'Uprawnienie lokalizacji';

  @override
  String get checking => 'Sprawdzanie...';

  @override
  String get locationPermissionGrantedAlways => 'Przyznano (zawsze)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Przyznano (podczas użycia)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Odrzucono - dotknij, aby poprosić';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Trwale odrzucono - otwórz ustawienia';

  @override
  String get locationPermissionDialogContent =>
      'Dostęp do lokalizacji został trwale odrzucony. Włącz go w ustawieniach urządzenia, aby używać GPS i udostępniania lokalizacji.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get locationPermissionGranted => 'Przyznano uprawnienie lokalizacji!';

  @override
  String get locationPermissionRequiredForGps =>
      'Dostęp do lokalizacji jest wymagany do śledzenia GPS i udostępniania lokalizacji.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Dostęp do lokalizacji został już przyznany.';

  @override
  String get sarNavyBlue => 'SAR Granatowy';

  @override
  String get sarNavyBlueDescription => 'Tryb profesjonalny/operacyjny';

  @override
  String get selectRecipient => 'Wybierz odbiorcę';

  @override
  String get broadcastToAllNearby => 'Nadaj do wszystkich w pobliżu';

  @override
  String get searchRecipients => 'Szukaj odbiorców...';

  @override
  String get noContactsFound => 'Nie znaleziono kontaktów';

  @override
  String get noRoomsFound => 'Nie znaleziono pokoi';

  @override
  String get noRecipientsAvailable => 'Brak dostępnych odbiorców';

  @override
  String get noChannelsFound => 'Nie znaleziono kanałów';

  @override
  String get newMessage => 'Nowa wiadomość';

  @override
  String get channel => 'Kanał';

  @override
  String get samplePoliceLead => 'Dowódca policji';

  @override
  String get sampleDroneOperator => 'Operator drona';

  @override
  String get sampleFirefighterAlpha => 'Strażak';

  @override
  String get sampleMedicCharlie => 'Ratownik medyczny';

  @override
  String get sampleCommandDelta => 'Dowództwo';

  @override
  String get sampleFireEngine => 'Wóz strażacki';

  @override
  String get sampleAirSupport => 'Wsparcie lotnicze';

  @override
  String get sampleBaseCoordinator => 'Koordynator bazy';

  @override
  String get channelEmergency => 'Alarmowy';

  @override
  String get channelCoordination => 'Koordynacja';

  @override
  String get channelUpdates => 'Aktualizacje';

  @override
  String get sampleTeamMember => 'Przykładowy członek zespołu';

  @override
  String get sampleScout => 'Przykładowy zwiadowca';

  @override
  String get sampleBase => 'Przykładowa baza';

  @override
  String get sampleSearcher => 'Przykładowy poszukiwacz';

  @override
  String get sampleObjectBackpack => ' Znaleziono plecak - kolor niebieski';

  @override
  String get sampleObjectVehicle => ' Porzucony pojazd - sprawdzić właściciela';

  @override
  String get sampleObjectCamping => ' Znaleziono sprzęt kempingowy';

  @override
  String get sampleObjectTrailMarker =>
      ' Znaleziono znacznik szlaku poza trasą';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Wszystkie zespoły - meldunek';

  @override
  String get sampleMsgWeatherUpdate =>
      'Aktualizacja pogody: bezchmurnie, temp. 18°C';

  @override
  String get sampleMsgBaseCamp => 'Bazę założono w strefie zbiórki';

  @override
  String get sampleMsgTeamAlpha => 'Zespół przemieszcza się do sektora 2';

  @override
  String get sampleMsgRadioCheck =>
      'Kontrola radiowa - wszystkie stacje proszone o odpowiedź';

  @override
  String get sampleMsgWaterSupply => 'Woda dostępna w punkcie kontrolnym 3';

  @override
  String get sampleMsgTeamBravo => 'Zespół melduje: sektor 1 czysty';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Szacowany czas dotarcia do punktu zbiórki: 15 minut';

  @override
  String get sampleMsgSupplyDrop => 'Zrzut zaopatrzenia potwierdzony na 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Rozpoznanie dronem zakończone - brak wyników';

  @override
  String get sampleMsgTeamCharlie => 'Zespół prosi o wsparcie';

  @override
  String get sampleMsgRadioDiscipline =>
      'Wszystkie jednostki: zachować dyscyplinę radiową';

  @override
  String get sampleMsgUrgentMedical =>
      'PILNE: potrzebna pomoc medyczna w sektorze 4';

  @override
  String get sampleMsgAdultMale => ' Dorosły mężczyzna, przytomny';

  @override
  String get sampleMsgFireSpotted => 'Wykryto pożar - współrzędne w drodze';

  @override
  String get sampleMsgSpreadingRapidly => ' Szybko się rozprzestrzenia!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORYTET: potrzebne wsparcie śmigłowca';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Zespół medyczny jest w drodze do twojej lokalizacji';

  @override
  String get sampleMsgEvacHelicopter => 'ETA śmigłowca ewakuacyjnego 10 minut';

  @override
  String get sampleMsgEmergencyResolved =>
      'Sytuacja opanowana - wszystko jasne';

  @override
  String get sampleMsgEmergencyStagingArea => ' Strefa zbiórki awaryjnej';

  @override
  String get sampleMsgEmergencyServices =>
      'Służby ratunkowe zostały powiadomione i jadą na miejsce';

  @override
  String get sampleAlphaTeamLead => 'Lider zespołu';

  @override
  String get sampleBravoScout => 'Zwiadowca';

  @override
  String get sampleCharlieMedic => 'Ratownik medyczny';

  @override
  String get sampleDeltaNavigator => 'Nawigator';

  @override
  String get sampleEchoSupport => 'Wsparcie';

  @override
  String get sampleBaseCommand => 'Dowództwo bazy';

  @override
  String get sampleFieldCoordinator => 'Koordynator terenowy';

  @override
  String get sampleMedicalTeam => 'Zespół medyczny';

  @override
  String get mapDrawing => 'Rysunek mapy';

  @override
  String get navigateToDrawing => 'Nawiguj do rysunku';

  @override
  String get copyCoordinates => 'Kopiuj współrzędne';

  @override
  String get hideFromMap => 'Ukryj na mapie';

  @override
  String get lineDrawing => 'Rysunek linii';

  @override
  String get rectangleDrawing => 'Rysunek prostokąta';

  @override
  String get manualCoordinates => 'Współrzędne ręczne';

  @override
  String get enterCoordinatesManually => 'Wprowadź współrzędne ręcznie';

  @override
  String get latitudeLabel => 'Szerokość geograficzna';

  @override
  String get longitudeLabel => 'Długość geograficzna';

  @override
  String get exampleCoordinates => 'Przykład: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Udostępnij rysunek';

  @override
  String get shareWithAllNearbyDevices =>
      'Udostępnij wszystkim pobliskim urządzeniom';

  @override
  String get shareToRoom => 'Udostępnij do pokoju';

  @override
  String get sendToPersistentStorage => 'Wyślij do trwałego magazynu pokoju';

  @override
  String get deleteDrawingConfirm => 'Czy na pewno chcesz usunąć ten rysunek?';

  @override
  String get drawingDeleted => 'Rysunek usunięto';

  @override
  String yourDrawingsCount(int count) {
    return 'Twoje rysunki ($count)';
  }

  @override
  String get shared => 'Udostępniono';

  @override
  String get line => 'Linia';

  @override
  String get rectangle => 'Prostokąt';

  @override
  String get updateAvailable => 'Dostępna aktualizacja';

  @override
  String get currentVersion => 'Bieżąca';

  @override
  String get latestVersion => 'Najnowsza';

  @override
  String get downloadUpdate => 'Pobierz';

  @override
  String get updateLater => 'Później';

  @override
  String get cadastralParcels => 'Działki katastralne';

  @override
  String get forestRoads => 'Drogi leśne';

  @override
  String get wmsOverlays => 'Nakładki WMS';

  @override
  String get hikingTrails => 'Szlaki piesze';

  @override
  String get mainRoads => 'Drogi główne';

  @override
  String get houseNumbers => 'Numery budynków';

  @override
  String get fireHazardZones => 'Strefy zagrożenia pożarowego';

  @override
  String get historicalFires => 'Historyczne pożary';

  @override
  String get firebreaks => 'Pasy przeciwpożarowe';

  @override
  String get krasFireZones => 'Strefy pożarowe Krasu';

  @override
  String get placeNames => 'Nazwy miejsc';

  @override
  String get municipalityBorders => 'Granice gmin';

  @override
  String get topographicMap => 'Mapa topograficzna 1:25000';

  @override
  String get recentMessages => 'Ostatnie wiadomości';

  @override
  String get addChannel => 'Dodaj kanał';

  @override
  String get channelName => 'Nazwa kanału';

  @override
  String get channelNameHint => 'np. Zespół Ratunkowy Alfa';

  @override
  String get channelSecret => 'Sekret kanału';

  @override
  String get channelSecretHint => 'Wspólne hasło dla tego kanału';

  @override
  String get channelSecretHelp =>
      'Ten sekret musi być współdzielony ze wszystkimi członkami zespołu, którzy potrzebują dostępu do tego kanału';

  @override
  String get channelTypesInfo =>
      'Kanały hash (#team): sekret jest generowany automatycznie z nazwy. Ta sama nazwa = ten sam kanał na wszystkich urządzeniach.\n\nKanały prywatne: użyj jawnego sekretu. Dołączyć mogą tylko osoby znające sekret.';

  @override
  String get hashChannelInfo =>
      'Kanał hash: sekret zostanie wygenerowany automatycznie z nazwy kanału. Każdy używający tej samej nazwy dołączy do tego samego kanału.';

  @override
  String get channelNameRequired => 'Nazwa kanału jest wymagana';

  @override
  String get channelNameTooLong =>
      'Nazwa kanału może mieć maksymalnie 31 znaków';

  @override
  String get channelSecretRequired => 'Sekret kanału jest wymagany';

  @override
  String get channelSecretTooLong =>
      'Sekret kanału może mieć maksymalnie 32 znaki';

  @override
  String get invalidAsciiCharacters => 'Dozwolone są tylko znaki ASCII';

  @override
  String get channelCreatedSuccessfully => 'Kanał utworzono pomyślnie';

  @override
  String channelCreationFailed(String error) {
    return 'Nie udało się utworzyć kanału: $error';
  }

  @override
  String get deleteChannel => 'Usuń kanał';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Czy na pewno chcesz usunąć kanał „$channelName”? Tej operacji nie można cofnąć.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanał usunięto pomyślnie';

  @override
  String channelDeletionFailed(String error) {
    return 'Nie udało się usunąć kanału: $error';
  }

  @override
  String get createChannel => 'Utwórz kanał';

  @override
  String get wizardBack => 'Wstecz';

  @override
  String get wizardSkip => 'Pomiń';

  @override
  String get wizardNext => 'Dalej';

  @override
  String get wizardGetStarted => 'Zaczynaj';

  @override
  String get wizardWelcomeTitle => 'Witamy w MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'Potężne narzędzie komunikacji poza siecią do operacji poszukiwawczo-ratowniczych. Połącz się ze swoim zespołem przy użyciu technologii radia mesh, gdy tradycyjne sieci są niedostępne.';

  @override
  String get wizardConnectingTitle => 'Łączenie z radiem';

  @override
  String get wizardConnectingDescription =>
      'Połącz smartfon z urządzeniem radiowym MeshCore przez Bluetooth, aby rozpocząć komunikację poza siecią.';

  @override
  String get wizardConnectingFeature1 => 'Skanuj pobliskie urządzenia MeshCore';

  @override
  String get wizardConnectingFeature2 => 'Sparuj radio przez Bluetooth';

  @override
  String get wizardConnectingFeature3 =>
      'Działa całkowicie offline - internet nie jest wymagany';

  @override
  String get wizardChannelTitle => 'Kanały';

  @override
  String get wizardChannelDescription =>
      'Nadawaj wiadomości do wszystkich na kanale, idealne do ogłoszeń i koordynacji całego zespołu.';

  @override
  String get wizardChannelFeature1 =>
      'Kanał publiczny do ogólnej komunikacji zespołu';

  @override
  String get wizardChannelFeature2 =>
      'Twórz własne kanały dla konkretnych grup';

  @override
  String get wizardChannelFeature3 =>
      'Wiadomości są automatycznie przekazywane przez mesh';

  @override
  String get wizardContactsTitle => 'Kontakty';

  @override
  String get wizardContactsDescription =>
      'Członkowie zespołu pojawiają się automatycznie, gdy dołączają do sieci mesh. Wyślij im wiadomość bezpośrednią lub zobacz ich lokalizację.';

  @override
  String get wizardContactsFeature1 => 'Kontakty wykrywane automatycznie';

  @override
  String get wizardContactsFeature2 =>
      'Wysyłaj prywatne wiadomości bezpośrednie';

  @override
  String get wizardContactsFeature3 =>
      'Podgląd poziomu baterii i czasu ostatniej aktywności';

  @override
  String get wizardMapTitle => 'Mapa i lokalizacja';

  @override
  String get wizardMapDescription =>
      'Śledź swój zespół w czasie rzeczywistym i oznaczaj ważne lokalizacje dla działań poszukiwawczo-ratowniczych.';

  @override
  String get wizardMapFeature1 =>
      'Znaczniki SAR dla odnalezionych osób, pożarów i stref zbiórki';

  @override
  String get wizardMapFeature2 =>
      'Śledzenie GPS członków zespołu w czasie rzeczywistym';

  @override
  String get wizardMapFeature3 =>
      'Pobieraj mapy offline dla odległych obszarów';

  @override
  String get wizardMapFeature4 =>
      'Rysuj kształty i udostępniaj informacje taktyczne';

  @override
  String get viewWelcomeTutorial => 'Pokaż samouczek powitalny';

  @override
  String get allTeamContacts => 'Wszystkie kontakty zespołu';

  @override
  String directMessagesInfo(int count) {
    return 'Wiadomości bezpośrednie z ACK. Wysłano do $count członków zespołu.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Znacznik SAR wysłano do $count kontaktów';
  }

  @override
  String get noContactsAvailable => 'Brak kontaktów zespołu';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get technicalDetails => 'Szczegóły techniczne';

  @override
  String get messageTechnicalDetails => 'Szczegóły techniczne wiadomości';

  @override
  String get linkQuality => 'Jakość łącza';

  @override
  String get delivery => 'Dostarczenie';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Oczekiwany znacznik ACK';

  @override
  String get roundTrip => 'Czas podróży w obie strony';

  @override
  String get retryAttempt => 'Próba ponowienia';

  @override
  String get floodFallback => 'Awaryjny flooding';

  @override
  String get identity => 'Tożsamość';

  @override
  String get messageId => 'ID wiadomości';

  @override
  String get sender => 'Nadawca';

  @override
  String get senderKey => 'Klucz nadawcy';

  @override
  String get recipient => 'Odbiorca';

  @override
  String get recipientKey => 'Klucz odbiorcy';

  @override
  String get voice => 'Głos';

  @override
  String get voiceId => 'ID głosu';

  @override
  String get envelope => 'Koperta';

  @override
  String get sessionProgress => 'Postęp sesji';

  @override
  String get complete => 'Zakończono';

  @override
  String get rawDump => 'Surowy zrzut';

  @override
  String get cannotRetryMissingRecipient =>
      'Nie można ponowić: brak informacji o odbiorcy';

  @override
  String get voiceUnavailable => 'Głos jest obecnie niedostępny';

  @override
  String get requestingVoice => 'Pobieranie głosu';

  @override
  String get device => 'urządzenie';

  @override
  String get change => 'Zmień';

  @override
  String get wizardOverviewDescription =>
      'Ta aplikacja łączy wiadomości MeshCore, terenowe aktualizacje SAR, mapy i narzędzia urządzenia w jednym miejscu.';

  @override
  String get wizardOverviewFeature1 =>
      'Wysyłaj wiadomości bezpośrednie, wpisy pokojowe i wiadomości kanałowe z głównej karty Wiadomości.';

  @override
  String get wizardOverviewFeature2 =>
      'Udostępniaj znaczniki SAR, rysunki mapy, klipy głosowe i obrazy przez sieć mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Połącz się przez BLE lub TCP, a następnie zarządzaj radiem towarzyszącym bezpośrednio z aplikacji.';

  @override
  String get wizardMessagingTitle => 'Wiadomości i raporty terenowe';

  @override
  String get wizardMessagingDescription =>
      'Wiadomości to tutaj coś więcej niż zwykły tekst. Aplikacja obsługuje już kilka typów danych operacyjnych i przepływów transferu.';

  @override
  String get wizardMessagingFeature1 =>
      'Wysyłaj wiadomości bezpośrednie, wpisy pokojowe i ruch kanałowy z jednego edytora.';

  @override
  String get wizardMessagingFeature2 =>
      'Twórz aktualizacje SAR i wielokrotnego użytku szablony SAR do typowych raportów terenowych.';

  @override
  String get wizardMessagingFeature3 =>
      'Przesyłaj sesje głosowe i obrazy z postępem i szacowanym czasem transmisji w interfejsie.';

  @override
  String get wizardConnectDeviceTitle => 'Połącz urządzenie';

  @override
  String get wizardConnectDeviceDescription =>
      'Podłącz radio MeshCore, wybierz nazwę i zastosuj profil radiowy przed kontynuacją.';

  @override
  String get wizardSetupBadge => 'Konfiguracja';

  @override
  String get wizardOverviewBadge => 'Przegląd';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Połączono z $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Brak podłączonego urządzenia';

  @override
  String get wizardSkipForNow => 'Pomiń na razie';

  @override
  String get wizardDeviceNameLabel => 'Nazwa urządzenia';

  @override
  String get wizardDeviceNameHelp =>
      'Ta nazwa jest rozgłaszana innym użytkownikom MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Region konfiguracji';

  @override
  String get wizardConfigRegionHelp =>
      'Używa pełnej oficjalnej listy presetów MeshCore. Domyślnie wybrane jest EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Upewnij się, że wybrany preset jest zgodny z lokalnymi przepisami radiowymi.';

  @override
  String get wizardPresetNote2 =>
      'Lista odpowiada oficjalnemu źródłu presetów narzędzia konfiguracji MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) pozostaje domyślnie wybrane podczas wdrożenia.';

  @override
  String get wizardSaving => 'Zapisywanie...';

  @override
  String get wizardSaveAndContinue => 'Zapisz i kontynuuj';

  @override
  String get wizardEnterDeviceName =>
      'Wprowadź nazwę urządzenia przed kontynuacją.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Zapisano $deviceName z ustawieniem $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Kontakty, pokoje i repeatery';

  @override
  String get wizardNetworkDescription =>
      'Karta Kontakty porządkuje sieć, którą odkrywasz, oraz trasy, których uczysz się z czasem.';

  @override
  String get wizardNetworkFeature1 =>
      'Przeglądaj członków zespołu, repeatery, pokoje, kanały i oczekujące ogłoszenia na jednej liście.';

  @override
  String get wizardNetworkFeature2 =>
      'Używaj smart ping, logowania do pokoi, poznanych ścieżek i narzędzi resetowania tras, gdy łączność staje się chaotyczna.';

  @override
  String get wizardNetworkFeature3 =>
      'Twórz kanały i zarządzaj celami sieciowymi bez opuszczania aplikacji.';

  @override
  String get wizardMapOpsTitle => 'Mapa, ślady i współdzielona geometria';

  @override
  String get wizardMapOpsDescription =>
      'Mapa aplikacji jest bezpośrednio powiązana z wiadomościami, śledzeniem i nakładkami SAR zamiast być osobnym podglądem.';

  @override
  String get wizardMapOpsFeature1 =>
      'Śledź własną pozycję, lokalizacje członków zespołu i ślady ruchu na mapie.';

  @override
  String get wizardMapOpsFeature2 =>
      'Otwieraj rysunki z wiadomości, podglądaj je w miejscu i usuwaj z mapy w razie potrzeby.';

  @override
  String get wizardMapOpsFeature3 =>
      'Korzystaj z widoków map repeaterów i współdzielonych nakładek, aby zrozumieć zasięg sieci w terenie.';

  @override
  String get wizardToolsTitle => 'Narzędzia poza wiadomościami';

  @override
  String get wizardToolsDescription =>
      'Jest tu więcej niż cztery główne karty. Aplikacja obejmuje także konfigurację, diagnostykę i opcjonalne przepływy czujników.';

  @override
  String get wizardToolsFeature1 =>
      'Otwórz konfigurację urządzenia, aby zmienić ustawienia radia, telemetrię, moc TX i szczegóły urządzenia towarzyszącego.';

  @override
  String get wizardToolsFeature2 =>
      'Włącz kartę Czujniki, gdy chcesz mieć pulpity monitorowanych czujników i szybkie odświeżanie.';

  @override
  String get wizardToolsFeature3 =>
      'Używaj logów pakietów, skanowania widma i diagnostyki deweloperskiej podczas rozwiązywania problemów z mesh.';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => 'W Czujnikach';

  @override
  String get contactAddToSensors => 'Dodaj do Czujników';

  @override
  String get contactSetPath => 'Ustaw ścieżkę';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName dodano do Czujników';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Nie udało się wyczyścić trasy: $error';
  }

  @override
  String get contactRouteCleared => 'Trasa wyczyszczona';

  @override
  String contactRouteSet(String route) {
    return 'Ustawiono trasę: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Nie udało się ustawić trasy: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Limit czasu ACK';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Ładunek';

  @override
  String get hops => 'Skoki';

  @override
  String get hashSize => 'Rozmiar hash';

  @override
  String get pathBytes => 'Bajty ścieżki';

  @override
  String get selectedPath => 'Wybrana ścieżka';

  @override
  String get estimatedTx => 'Szacowane nadawanie';

  @override
  String get senderToReceipt => 'Od nadawcy do odbioru';

  @override
  String get receivedCopies => 'Otrzymane kopie';

  @override
  String get retryCause => 'Przyczyna ponowienia';

  @override
  String get retryMode => 'Tryb ponowienia';

  @override
  String get retryResult => 'Wynik ponowienia';

  @override
  String get lastRetry => 'Ostatnia próba';

  @override
  String get rxPackets => 'Pakiety RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Szybkość';

  @override
  String get window => 'Okno';

  @override
  String get posttxDelay => 'Opóźnienie po nadawaniu';

  @override
  String get bandpass => 'Pasmowy';

  @override
  String get bandpassFilterVoice => 'Filtr pasmowy głosu';

  @override
  String get frequency => 'Częstotliwość';

  @override
  String get australia => 'Australia';

  @override
  String get australiaNarrow => 'Australia (wąski)';

  @override
  String get australiaQld => 'Australia: QLD';

  @override
  String get australiaSaWa => 'Australia: SA, WA';

  @override
  String get newZealand => 'Nowa Zelandia';

  @override
  String get newZealandNarrow => 'Nowa Zelandia (wąski)';

  @override
  String get switzerland => 'Szwajcaria';

  @override
  String get portugal433 => 'Portugalia 433';

  @override
  String get portugal868 => 'Portugalia 868';

  @override
  String get czechRepublicNarrow => 'Czechy (wąski)';

  @override
  String get eu433mhzLongRange => 'EU 433MHz (daleki zasięg)';

  @override
  String get euukDeprecated => 'EU/UK (przestarzały)';

  @override
  String get euukNarrow => 'EU/UK (wąski)';

  @override
  String get usacanadaRecommended => 'USA/Kanada (zalecany)';

  @override
  String get vietnamDeprecated => 'Wietnam (przestarzały)';

  @override
  String get vietnamNarrow => 'Wietnam (wąski)';

  @override
  String get active => 'Aktywny';

  @override
  String get addContact => 'Dodaj kontakt';

  @override
  String get all => 'Wszystko';

  @override
  String get autoResolve => 'Automatyczne rozwiązanie';

  @override
  String get clearAllLabel => 'Wyczyść wszystko';

  @override
  String get clearRelays => 'Wyczyść przekaźniki';

  @override
  String get clearFilters => 'Wyczyść filtry';

  @override
  String get clearRoute => 'Wyczyść trasę';

  @override
  String get clearMessages => 'Wyczyść wiadomości';

  @override
  String get clearScale => 'Wyczyść skalę';

  @override
  String get clearDiscoveries => 'Wyczyść odkrycia';

  @override
  String get clearOnlineTraceDatabase => 'Wyczyść bazę śladów';

  @override
  String get clearAllChannels => 'Wyczyść wszystkie kanały';

  @override
  String get clearAllContacts => 'Wyczyść wszystkie kontakty';

  @override
  String get clearChannels => 'Wyczyść kanały';

  @override
  String get clearContacts => 'Wyczyść kontakty';

  @override
  String get clearPathOnMaxRetry => 'Wyczyść ścieżkę przy maks. próbie';

  @override
  String get create => 'Utwórz';

  @override
  String get custom => 'Niestandardowy';

  @override
  String get defaultValue => 'Domyślny';

  @override
  String get duplicate => 'Duplikuj';

  @override
  String get editName => 'Edytuj nazwę';

  @override
  String get open => 'Otwórz';

  @override
  String get paste => 'Wklej';

  @override
  String get preview => 'Podgląd';

  @override
  String get remove => 'Usuń';

  @override
  String get rename => 'Zmień nazwę';

  @override
  String get resolveAll => 'Rozwiąż wszystko';

  @override
  String get send => 'Wyślij';

  @override
  String get sendAnyway => 'Wyślij mimo to';

  @override
  String get share => 'Udostępnij';

  @override
  String get shareContact => 'Udostępnij kontakt';

  @override
  String get trace => 'Śledzenie';

  @override
  String get use => 'Użyj';

  @override
  String get useSelectedFrequency => 'Użyj wybranej częstotliwości';

  @override
  String get discovery => 'Wykrywanie';

  @override
  String get discoverRepeaters => 'Wykryj przekaźniki';

  @override
  String get discoverSensors => 'Wykryj czujniki';

  @override
  String get repeaterDiscoverySent => 'Wykrywanie przekaźników wysłane';

  @override
  String get sensorDiscoverySent => 'Wykrywanie czujników wysłane';

  @override
  String get clearedPendingDiscoveries => 'Wyczyszczono oczekujące odkrycia.';

  @override
  String get autoDiscovery => 'Automatyczne wykrywanie';

  @override
  String get enableAutomaticAdding => 'Włącz automatyczne dodawanie';

  @override
  String get autoaddRepeaters => 'Automatycznie dodaj przekaźniki';

  @override
  String get autoaddRoomServers => 'Automatycznie dodaj serwery pokoi';

  @override
  String get autoaddSensors => 'Automatycznie dodaj czujniki';

  @override
  String get autoaddUsers => 'Automatycznie dodaj użytkowników';

  @override
  String get overwriteOldestWhenFull => 'Nadpisz najstarsze gdy pełne';

  @override
  String get storage => 'Pamięć';

  @override
  String get dangerZone => 'Strefa zagrożenia';

  @override
  String get profiles => 'Profile';

  @override
  String get favourites => 'Ulubione';

  @override
  String get sensors => 'Czujniki';

  @override
  String get others => 'Inne';

  @override
  String get gpsModule => 'Moduł GPS';

  @override
  String get liveTraffic => 'Ruch na żywo';

  @override
  String get repeatersMap => 'Mapa przekaźników';

  @override
  String get spectrumScan => 'Skanowanie spektrum';

  @override
  String get blePacketLogs => 'Logi pakietów BLE';

  @override
  String get onlineTraceDatabase => 'Baza śladów';

  @override
  String get routePathByteSize => 'Rozmiar ścieżki w bajtach';

  @override
  String get messageNotifications => 'Powiadomienia o wiadomościach';

  @override
  String get sarAlerts => 'Alerty SAR';

  @override
  String get discoveryNotifications => 'Powiadomienia o wykrywaniu';

  @override
  String get updateNotifications => 'Powiadomienia o aktualizacjach';

  @override
  String get muteWhileAppIsOpen => 'Wycisz gdy aplikacja jest otwarta';

  @override
  String get disableContacts => 'Wyłącz kontakty';

  @override
  String get enableSensorsTab => 'Włącz kartę Czujniki';

  @override
  String get enableProfiles => 'Włącz profile';

  @override
  String get autoRouteRotation => 'Automatyczna rotacja trasy';

  @override
  String get nearestRepeaterFallback => 'Najbliższy przekaźnik awaryjny';

  @override
  String get deleteAllStoredMessageHistory => 'Usuń całą historię wiadomości';

  @override
  String get messageFontSize => 'Rozmiar czcionki wiadomości';

  @override
  String get rotateMapWithHeading => 'Obracaj mapę z kierunkiem';

  @override
  String get showMapDebugInfo => 'Pokaż info debugowania mapy';

  @override
  String get openMapInFullscreen => 'Otwórz mapę na pełnym ekranie';

  @override
  String get showSarMarkersLabel => 'Pokaż znaczniki SAR';

  @override
  String get displaySarMarkersOnTheMainMap =>
      'Wyświetlaj znaczniki SAR na głównej mapie';

  @override
  String get showAllContactTrailsLabel => 'Pokaż wszystkie ślady kontaktów';

  @override
  String get hideRepeatersOnMap => 'Ukryj przekaźniki na mapie';

  @override
  String get setMapScale => 'Ustaw skalę mapy';

  @override
  String get customMapScaleSaved => 'Niestandardowa skala mapy zapisana';

  @override
  String get voiceBitrate => 'Bitrate głosu';

  @override
  String get voiceCompressor => 'Kompresor głosu';

  @override
  String get balancesQuietAndLoudSpeechLevels =>
      'Wyrównuje ciche i głośne poziomy mowy';

  @override
  String get voiceLimiter => 'Limiter głosu';

  @override
  String get preventsClippingPeaksBeforeEncoding =>
      'Zapobiega przycinaniu szczytów przed kodowaniem';

  @override
  String get micAutoGain => 'Automatyczne wzmocnienie mikrofonu';

  @override
  String get letsTheRecorderAdjustInputLevel =>
      'Pozwala nagrywarkowi dostosować poziom wejścia';

  @override
  String get echoCancellation => 'Usuwanie echa';

  @override
  String get noiseSuppression => 'Tłumienie szumu';

  @override
  String get trimSilenceInVoiceMessages =>
      'Przytnij ciszę w wiadomościach głosowych';

  @override
  String get compressor => 'Kompresor';

  @override
  String get limiter => 'Limiter';

  @override
  String get autoGain => 'Automatyczne wzmocnienie';

  @override
  String get echoCancel => 'Echo';

  @override
  String get noiseSuppress => 'Szum';

  @override
  String get silenceTrim => 'Cisza';

  @override
  String get maxImageSize => 'Maksymalny rozmiar obrazu';

  @override
  String get imageCompression => 'Kompresja obrazu';

  @override
  String get grayscale => 'Skala szarości';

  @override
  String get ultraMode => 'Tryb ultra';

  @override
  String get fastPrivateGpsUpdates => 'Szybkie prywatne aktualizacje GPS';

  @override
  String get movementThreshold => 'Próg ruchu';

  @override
  String get fastGpsMovementThreshold => 'Próg ruchu szybkiego GPS';

  @override
  String get fastGpsActiveuseInterval =>
      'Interwał aktywnego użycia szybkiego GPS';

  @override
  String get activeuseUpdateInterval =>
      'Interwał aktualizacji przy aktywnym użyciu';

  @override
  String get repeatNearbyTraffic => 'Powtarzaj pobliski ruch';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Przekazuj przez przekaźniki w sieci';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Tylko w pobliżu, bez zalewania przekaźników';

  @override
  String get multihop => 'Wieloskokowy';

  @override
  String get createProfile => 'Utwórz profil';

  @override
  String get renameProfile => 'Zmień nazwę profilu';

  @override
  String get newProfile => 'Nowy profil';

  @override
  String get manageProfiles => 'Zarządzaj profilami';

  @override
  String get enableProfilesToStartManagingThem =>
      'Włącz profile, aby zacząć nimi zarządzać.';

  @override
  String get openMessage => 'Otwórz wiadomość';

  @override
  String get jumpToTheRelatedSarMessage =>
      'Przejdź do powiązanej wiadomości SAR';

  @override
  String get removeSarMarker => 'Usuń znacznik SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Wybierz cel wysłania znacznika SAR';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Znacznik SAR wysłany na kanał publiczny';

  @override
  String get sarMarkerSentToRoom => 'Znacznik SAR wysłany do pokoju';

  @override
  String get loadFromGallery => 'Załaduj z galerii';

  @override
  String get replaceImage => 'Zamień obraz';

  @override
  String get selectFromGallery => 'Wybierz z galerii';

  @override
  String get team => 'Zespół';

  @override
  String get found => 'Znaleziono';

  @override
  String get staging => 'Punkt zbiórki';

  @override
  String get object => 'Obiekt';

  @override
  String get quiet => 'Cicho';

  @override
  String get moderate => 'Umiarkowane';

  @override
  String get busy => 'Zajęty';

  @override
  String get spectrumScanReturnedNoCandidateFrequencies =>
      'Skanowanie spektrum nie znalazło częstotliwości kandydatów';

  @override
  String get searchMessages => 'Szukaj wiadomości';

  @override
  String get sendImageFromGallery => 'Wyślij obraz z galerii';

  @override
  String get takePhoto => 'Zrób zdjęcie';

  @override
  String get dmOnly => 'Tylko wiadomość bezpośrednia';

  @override
  String get allMessages => 'Wszystkie wiadomości';

  @override
  String get sendToPublicChannel => 'Wysłać na kanał publiczny?';

  @override
  String get selectMarkerTypeAndDestination => 'Wybierz typ znacznika i cel';

  @override
  String get noDestinationsAvailableLabel => 'Brak dostępnych celów';

  @override
  String get image => 'Obraz';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Wymiary';

  @override
  String get segments => 'Segmenty';

  @override
  String get transfers => 'Transfery';

  @override
  String get downloadedBy => 'Pobrane przez';

  @override
  String get saveDiscoverySettings => 'Zapisz ustawienia wykrywania';

  @override
  String get savePublicInfo => 'Zapisz informacje publiczne';

  @override
  String get saveRadioSettings => 'Zapisz ustawienia radia';

  @override
  String get savePath => 'Zapisz ścieżkę';

  @override
  String get wipeDeviceData => 'Wyczyść dane urządzenia';

  @override
  String get wipeDevice => 'Wyczyść urządzenie';

  @override
  String get destructiveDeviceActions => 'Destrukcyjne akcje na urządzeniu.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Wybierz ustawienie wstępne lub dostosuj ustawienia radia.';

  @override
  String get chooseTheNameAndLocationThisDeviceShares =>
      'Wybierz nazwę i lokalizację udostępnianą przez to urządzenie.';

  @override
  String get availableSpaceOnThisDevice =>
      'Dostępne miejsce na tym urządzeniu.';

  @override
  String get used => 'Użyto';

  @override
  String get total => 'Razem';

  @override
  String get renameValue => 'Zmień nazwę wartości';

  @override
  String get customizeFields => 'Dostosuj pola';

  @override
  String get livePreview => 'Podgląd na żywo';

  @override
  String get refreshSchedule => 'Harmonogram odświeżania';

  @override
  String get noResponse => 'Brak odpowiedzi';

  @override
  String get refreshing => 'Odświeżanie';

  @override
  String get unavailable => 'Niedostępny';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Wybierz przekaźnik lub węzeł do obserwacji.';

  @override
  String get publicKeyLabel => 'Klucz publiczny';

  @override
  String get alreadyInContacts => 'Już w kontaktach';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Połącz się z urządzeniem przed dodaniem kontaktów';

  @override
  String get fromContacts => 'Z kontaktów';

  @override
  String get onlineOnly => 'Tylko online';

  @override
  String get inBoth => 'W obu';

  @override
  String get source => 'Źródło';

  @override
  String get manualRouteEdit => 'Ręczna edycja trasy';

  @override
  String get observedMeshRoute => 'Obserwowana trasa sieci';

  @override
  String get allMessagesCleared => 'Wszystkie wiadomości wyczyszczone';

  @override
  String get onlineTraceDatabaseCleared => 'Baza śladów wyczyszczona';

  @override
  String get packetLogsCleared => 'Logi pakietów wyczyszczone';

  @override
  String get hexDataCopiedToClipboard => 'Dane hex skopiowane do schowka';

  @override
  String get developerModeEnabled => 'Tryb programisty włączony';

  @override
  String get developerModeDisabled => 'Tryb programisty wyłączony';

  @override
  String get clipboardIsEmpty => 'Schowek jest pusty';

  @override
  String get contactImported => 'Kontakt zaimportowany';

  @override
  String get contactLinkCopiedToClipboard =>
      'Link kontaktu skopiowany do schowka';

  @override
  String get failedToExportContact => 'Nie udało się wyeksportować kontaktu';

  @override
  String get noLogsToExport => 'Brak logów do eksportu';

  @override
  String get exportAsCsv => 'Eksportuj jako CSV';

  @override
  String get exportAsText => 'Eksportuj jako tekst';

  @override
  String get receivedRfc3339 => 'Odebrano (RFC3339)';

  @override
  String get buildTime => 'Czas budowania';

  @override
  String get downloadUrlNotAvailable => 'URL pobierania niedostępny';

  @override
  String get cannotOpenDownloadUrl => 'Nie można otworzyć URL pobierania';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Sprawdzanie aktualizacji dostępne tylko na Androidzie';

  @override
  String get youAreRunningTheLatestVersion => 'Używasz najnowszej wersji';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Aktualizacja dostępna, ale URL pobierania nie znaleziony';

  @override
  String get startTictactoe => 'Rozpocznij Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe niedostępny';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: przeciwnik nieznany';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: oczekiwanie na start';

  @override
  String get acceptsShareLinks => 'Akceptuje udostępnione linki';

  @override
  String get supportsRawHex => 'Obsługuje surowy hex';

  @override
  String get clipboardfriendly => 'Przyjazne dla schowka';

  @override
  String get captured => 'Przechwycone';

  @override
  String get size => 'Rozmiar';

  @override
  String get noCustomChannelsToClear =>
      'Brak niestandardowych kanałów do wyczyszczenia.';

  @override
  String get noDeviceContactsToClear =>
      'Brak kontaktów urządzenia do wyczyszczenia.';

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
