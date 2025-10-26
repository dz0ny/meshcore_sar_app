// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Messaggi';

  @override
  String get contacts => 'Contatti';

  @override
  String get map => 'Mappa';

  @override
  String get settings => 'Impostazioni';

  @override
  String get connect => 'Connetti';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get scanningForDevices => 'Ricerca dispositivi in corso...';

  @override
  String get noDevicesFound => 'Nessun dispositivo trovato';

  @override
  String get scanAgain => 'Cerca Nuovamente';

  @override
  String get tapToConnect => 'Tocca per connettere';

  @override
  String get deviceNotConnected => 'Dispositivo non connesso';

  @override
  String get locationPermissionDenied => 'Autorizzazione posizione negata';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Autorizzazione posizione negata permanentemente. Abilitarla nelle Impostazioni.';

  @override
  String get locationPermissionRequired =>
      'L\'autorizzazione alla posizione è necessaria per il tracciamento GPS e il coordinamento del team. Puoi abilitarla successivamente nelle Impostazioni.';

  @override
  String get locationServicesDisabled =>
      'I servizi di localizzazione sono disabilitati. Abilitarli nelle Impostazioni.';

  @override
  String get failedToGetGpsLocation => 'Impossibile ottenere la posizione GPS';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Annunciato a $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Annuncio fallito: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Riconnessione in corso... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Annulla riconnessione';

  @override
  String get mapManagement => 'Gestione Mappa';

  @override
  String get general => 'Generale';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Scegli Tema';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get blueLightTheme => 'Tema blu chiaro';

  @override
  String get blueDarkTheme => 'Tema blu scuro';

  @override
  String get sarRed => 'SAR Rosso';

  @override
  String get alertEmergencyMode => 'Modalità Allerta/Emergenza';

  @override
  String get sarGreen => 'SAR Verde';

  @override
  String get safeAllClearMode => 'Modalità Sicuro/Tutto Libero';

  @override
  String get autoSystem => 'Auto (Sistema)';

  @override
  String get followSystemTheme => 'Segui tema di sistema';

  @override
  String get showRxTxIndicators => 'Mostra Indicatori RX/TX';

  @override
  String get displayPacketActivity =>
      'Mostra indicatori di attività pacchetti nella barra superiore';

  @override
  String get simpleMode => 'Modalità Semplice';

  @override
  String get simpleModeDescription =>
      'Nascondi informazioni non essenziali nei messaggi e contatti';

  @override
  String get language => 'Lingua';

  @override
  String get chooseLanguage => 'Scegli Lingua';

  @override
  String get english => 'Inglese';

  @override
  String get slovenian => 'Sloveno';

  @override
  String get croatian => 'Croato';

  @override
  String get german => 'Tedesco';

  @override
  String get spanish => 'Spagnolo';

  @override
  String get french => 'Francese';

  @override
  String get italian => 'Italiano';

  @override
  String get locationBroadcasting => 'Trasmissione Posizione';

  @override
  String get autoLocationTracking => 'Tracciamento Posizione Automatico';

  @override
  String get automaticallyBroadcastPosition =>
      'Trasmetti automaticamente aggiornamenti di posizione';

  @override
  String get configureTracking => 'Configura Tracciamento';

  @override
  String get distanceAndTimeThresholds => 'Soglie di distanza e tempo';

  @override
  String get locationTrackingConfiguration =>
      'Configurazione Tracciamento Posizione';

  @override
  String get configureWhenLocationBroadcasts =>
      'Configura quando le trasmissioni di posizione vengono inviate alla rete mesh';

  @override
  String get minimumDistance => 'Distanza Minima';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Trasmetti solo dopo essersi spostati di $distance metri';
  }

  @override
  String get maximumDistance => 'Distanza Massima';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Trasmetti sempre dopo essersi spostati di $distance metri';
  }

  @override
  String get minimumTimeInterval => 'Intervallo Minimo di Tempo';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Trasmetti sempre ogni $duration';
  }

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get about => 'Informazioni';

  @override
  String get appVersion => 'Versione App';

  @override
  String get appName => 'Nome App';

  @override
  String get aboutMeshCoreSar => 'Informazioni su MeshCore SAR';

  @override
  String get aboutDescription =>
      'Un\'applicazione di Ricerca e Soccorso progettata per i team di emergenza. Le caratteristiche includono:\n\n• Rete mesh BLE per comunicazione dispositivo-a-dispositivo\n• Mappe offline con opzioni di livelli multipli\n• Tracciamento in tempo reale dei membri del team\n• Marcatori tattici SAR (persona trovata, incendio, area di appoggio)\n• Gestione contatti e messaggistica\n• Tracciamento GPS con direzione bussola\n• Caching dei tile della mappa per uso offline';

  @override
  String get technologiesUsed => 'Tecnologie Utilizzate:';

  @override
  String get technologiesList =>
      '• Flutter per lo sviluppo multipiattaforma\n• BLE (Bluetooth Low Energy) per la rete mesh\n• OpenStreetMap per la mappatura\n• Provider per la gestione dello stato\n• SharedPreferences per l\'archiviazione locale';

  @override
  String get developer => 'Sviluppatore';

  @override
  String get packageName => 'Nome Pacchetto';

  @override
  String get sampleData => 'Dati di Esempio';

  @override
  String get sampleDataDescription =>
      'Carica o cancella contatti di esempio, messaggi di canale e marcatori SAR per test';

  @override
  String get loadSampleData => 'Carica Dati di Esempio';

  @override
  String get clearAllData => 'Cancella Tutti i Dati';

  @override
  String get clearAllDataConfirmTitle => 'Cancella Tutti i Dati';

  @override
  String get clearAllDataConfirmMessage =>
      'Questo cancellerà tutti i contatti e i marcatori SAR. Sei sicuro?';

  @override
  String get clear => 'Cancella';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Caricati $teamCount membri del team, $channelCount canali, $sarCount marcatori SAR, $messageCount messaggi';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Impossibile caricare dati di esempio: $error';
  }

  @override
  String get allDataCleared => 'Tutti i dati cancellati';

  @override
  String get failedToStartBackgroundTracking =>
      'Impossibile avviare il tracciamento in background. Verifica le autorizzazioni e la connessione BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Trasmissione posizione: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Il PIN predefinito per i dispositivi senza schermo è 123456. Problemi di accoppiamento? Dimentica il dispositivo bluetooth nelle impostazioni di sistema.';

  @override
  String get noMessagesYet => 'Nessun messaggio ancora';

  @override
  String get pullDownToSync =>
      'Trascina verso il basso per sincronizzare i messaggi';

  @override
  String get deleteContact => 'Elimina Contatto';

  @override
  String get delete => 'Elimina';

  @override
  String get viewOnMap => 'Visualizza su Mappa';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get sendDirectMessage => 'Invia';

  @override
  String get resetPath => 'Resetta Percorso (Ri-instrada)';

  @override
  String get publicKeyCopied => 'Chiave pubblica copiata negli appunti';

  @override
  String copiedToClipboard(String label) {
    return '$label copiato negli appunti';
  }

  @override
  String get pleaseEnterPassword => 'Inserisci una password';

  @override
  String failedToSyncContacts(String error) {
    return 'Impossibile sincronizzare i contatti: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Accesso effettuato con successo! In attesa dei messaggi della stanza...';

  @override
  String get loginFailed => 'Accesso fallito - password errata';

  @override
  String loggingIn(String roomName) {
    return 'Accesso a $roomName in corso...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Impossibile inviare l\'accesso: $error';
  }

  @override
  String get lowLocationAccuracy => 'Precisione Posizione Bassa';

  @override
  String get continue_ => 'Continua';

  @override
  String get sendSarMarker => 'Invia marcatore SAR';

  @override
  String get deleteDrawing => 'Elimina Disegno';

  @override
  String get drawingTools => 'Strumenti di Disegno';

  @override
  String get drawLine => 'Disegna Linea';

  @override
  String get drawLineDesc => 'Disegna una linea a mano libera sulla mappa';

  @override
  String get drawRectangle => 'Disegna Rettangolo';

  @override
  String get drawRectangleDesc => 'Disegna un\'area rettangolare sulla mappa';

  @override
  String get shareDrawings => 'Condividi Disegni';

  @override
  String get clearAllDrawings => 'Cancella Tutti i Disegni';

  @override
  String get completeLine => 'Completa Linea';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Trasmetti $count disegno$plural alla squadra';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Rimuovi tutti i $count disegno$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Eliminare tutti i $count disegno$plural dalla mappa?';
  }

  @override
  String get drawing => 'Disegno';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Condividi $count disegno$plural';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return 'Inviati $count disegno$plural mappa a $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return 'Condivisi $success/$total disegno$plural con $roomName';
  }

  @override
  String get showReceivedDrawings => 'Mostra Disegni Ricevuti';

  @override
  String get showingAllDrawings => 'Visualizzazione di tutti i disegni';

  @override
  String get showingOnlyYourDrawings => 'Visualizzazione solo dei tuoi disegni';

  @override
  String get showSarMarkers => 'Mostra marcatori SAR';

  @override
  String get showingSarMarkers => 'Visualizzazione marcatori SAR';

  @override
  String get hidingSarMarkers => 'Nascondere marcatori SAR';

  @override
  String get clearAll => 'Cancella Tutto';

  @override
  String get noLocalDrawings => 'Nessun disegno locale da condividere';

  @override
  String get publicChannel => 'Canale Pubblico';

  @override
  String get broadcastToAll => 'Trasmetti a tutti i nodi vicini (effimero)';

  @override
  String get storedPermanently => 'Archiviato permanentemente nella stanza';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return '$count disegno$plural mappa inviato al Canale Pubblico';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return '$success/$total disegni condivisi sul Canale Pubblico';
  }

  @override
  String get notConnectedToDevice => 'Non connesso al dispositivo';

  @override
  String get directMessage => 'Messaggio Diretto';

  @override
  String directMessageSentTo(String contactName) {
    return 'Messaggio diretto inviato a $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Invio fallito: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'Questo messaggio verrà inviato direttamente a $contactName. Apparirà anche nel feed dei messaggi principali.';
  }

  @override
  String get typeYourMessage => 'Scrivi il tuo messaggio...';

  @override
  String get quickLocationMarker => 'Marcatore posizione rapido';

  @override
  String get markerType => 'Tipo Marcatore';

  @override
  String get sendTo => 'Invia A';

  @override
  String get noDestinationsAvailable => 'Nessuna destinazione disponibile.';

  @override
  String get selectDestination => 'Seleziona destinazione...';

  @override
  String get ephemeralBroadcastInfo =>
      'Effimero: Trasmissione via etere solamente. Non archiviato - i nodi devono essere online.';

  @override
  String get persistentRoomInfo =>
      'Persistente: Archiviato in modo immutabile nella stanza. Sincronizzato automaticamente e conservato offline.';

  @override
  String get location => 'Posizione';

  @override
  String get myLocation => 'La mia posizione';

  @override
  String get fromMap => 'Dalla Mappa';

  @override
  String get gettingLocation => 'Ottenimento posizione...';

  @override
  String get locationError => 'Errore Posizione';

  @override
  String get retry => 'Riprova';

  @override
  String get refreshLocation => 'Aggiorna posizione';

  @override
  String accuracyMeters(int accuracy) {
    return 'Precisione: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Note (facoltativo)';

  @override
  String get addAdditionalInformation => 'Aggiungi informazioni aggiuntive...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'La precisione della posizione è ±${accuracy}m. Potrebbe non essere abbastanza accurata per le operazioni SAR.\n\nContinuare comunque?';
  }

  @override
  String get loginToRoom => 'Accedi alla Stanza';

  @override
  String get enterPasswordInfo =>
      'Inserisci la password per accedere a questa stanza. La password verrà salvata per usi futuri.';

  @override
  String get password => 'Password';

  @override
  String get enterRoomPassword => 'Inserisci password stanza';

  @override
  String get loggingInDots => 'Accesso in corso...';

  @override
  String get login => 'Accedi';

  @override
  String failedToAddRoom(String error) {
    return 'Impossibile aggiungere la stanza al dispositivo: $error\n\nLa stanza potrebbe non aver ancora trasmesso.\nProva ad attendere che la stanza trasmetta.';
  }

  @override
  String get direct => 'Diretto';

  @override
  String get flood => 'Flood';

  @override
  String get admin => 'Admin';

  @override
  String get loggedIn => 'Connesso';

  @override
  String get noGpsData => 'Nessun dato GPS';

  @override
  String get distance => 'Distanza';

  @override
  String pingingDirect(String name) {
    return 'Ping $name (diretto via percorso)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Ping $name (flooding - nessun percorso)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Timeout ping diretto - nuovo tentativo $name con flooding...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping riuscito a $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (via fallback flooding)';

  @override
  String pingFailed(String name) {
    return 'Ping fallito a $name - nessuna risposta ricevuta';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?\n\nQuesto rimuoverà il contatto sia dall\'app che dal dispositivo radio companion.';
  }

  @override
  String removingContact(String name) {
    return 'Rimozione di $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Contatto \"$name\" rimosso';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Impossibile rimuovere il contatto: $error';
  }

  @override
  String get type => 'Tipo';

  @override
  String get publicKey => 'Chiave Pubblica';

  @override
  String get lastSeen => 'Ultima Visita';

  @override
  String get roomStatus => 'Stato Stanza';

  @override
  String get loginStatus => 'Stato Accesso';

  @override
  String get notLoggedIn => 'Non Connesso';

  @override
  String get adminAccess => 'Accesso Admin';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permessi';

  @override
  String get passwordSaved => 'Password Salvata';

  @override
  String get locationColon => 'Posizione:';

  @override
  String get telemetry => 'Telemetria';

  @override
  String requestingTelemetry(String name) {
    return 'Richiesta telemetria da $name...';
  }

  @override
  String get voltage => 'Tensione';

  @override
  String get battery => 'Batteria';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Umidità';

  @override
  String get pressure => 'Pressione';

  @override
  String get gpsTelemetry => 'GPS (Telemetria)';

  @override
  String get updated => 'Aggiornato';

  @override
  String pathResetInfo(String name) {
    return 'Percorso resettato per $name. Il prossimo messaggio troverà un nuovo instradamento.';
  }

  @override
  String get reLoginToRoom => 'Riaccedi alla Stanza';

  @override
  String get heading => 'Direzione';

  @override
  String get elevation => 'Elevazione';

  @override
  String get accuracy => 'Precisione';

  @override
  String get bearing => 'Rilevamento';

  @override
  String get direction => 'Direzione';

  @override
  String get filterMarkers => 'Filtra Marcatori';

  @override
  String get filterMarkersTooltip => 'Filtra marcatori';

  @override
  String get contactsFilter => 'Contatti';

  @override
  String get repeatersFilter => 'Ripetitori';

  @override
  String get sarMarkers => 'Marcatori SAR';

  @override
  String get foundPerson => 'Persona Trovata';

  @override
  String get fire => 'Incendio';

  @override
  String get stagingArea => 'Area di Appoggio';

  @override
  String get showAll => 'Mostra Tutto';

  @override
  String get nearbyContacts => 'Contatti Vicini';

  @override
  String get locationUnavailable => 'Posizione non disponibile';

  @override
  String get ahead => 'avanti';

  @override
  String degreesRight(int degrees) {
    return '$degrees° destra';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° sinistra';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Nessun contatto ancora';

  @override
  String get connectToDeviceToLoadContacts =>
      'Connetti a un dispositivo per caricare i contatti';

  @override
  String get teamMembers => 'Membri del Team';

  @override
  String get repeaters => 'Ripetitori';

  @override
  String get rooms => 'Stanze';

  @override
  String get channels => 'Canali';

  @override
  String get cacheStatistics => 'Statistiche Cache';

  @override
  String get totalTiles => 'Tile Totali';

  @override
  String get cacheSize => 'Dimensione Cache';

  @override
  String get storeName => 'Nome Archivio';

  @override
  String get noCacheStatistics => 'Nessuna statistica cache disponibile';

  @override
  String get downloadRegion => 'Scarica Regione';

  @override
  String get mapLayer => 'Livello Mappa';

  @override
  String get regionBounds => 'Limiti Regione';

  @override
  String get north => 'Nord';

  @override
  String get south => 'Sud';

  @override
  String get east => 'Est';

  @override
  String get west => 'Ovest';

  @override
  String get zoomLevels => 'Livelli di Zoom';

  @override
  String minZoom(int zoom) {
    return 'Min: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Max: $zoom';
  }

  @override
  String get downloadingDots => 'Scaricamento in corso...';

  @override
  String get cancelDownload => 'Annulla Download';

  @override
  String get downloadRegionButton => 'Scarica Regione';

  @override
  String get downloadNote =>
      'Nota: Regioni grandi o livelli di zoom elevati possono richiedere tempo e spazio di archiviazione significativi.';

  @override
  String get cacheManagement => 'Gestione Cache';

  @override
  String get clearAllMaps => 'Cancella Tutte le Mappe';

  @override
  String get clearMapsConfirmTitle => 'Cancella Tutte le Mappe';

  @override
  String get clearMapsConfirmMessage =>
      'Sei sicuro di voler eliminare tutte le mappe scaricate? Questa azione non può essere annullata.';

  @override
  String get mapDownloadCompleted => 'Download mappa completato!';

  @override
  String get cacheClearedSuccessfully => 'Cache cancellata con successo!';

  @override
  String get downloadCancelled => 'Download annullato';

  @override
  String get startingDownload => 'Avvio download...';

  @override
  String get downloadingMapTiles => 'Scaricamento tile mappa...';

  @override
  String get downloadCompletedSuccessfully =>
      'Download completato con successo!';

  @override
  String get cancellingDownload => 'Annullamento download...';

  @override
  String errorLoadingStats(String error) {
    return 'Errore nel caricamento delle statistiche: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download fallito: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Annullamento fallito: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Cancellazione cache fallita: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Zoom minimo: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Zoom massimo: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Lo zoom minimo deve essere minore o uguale allo zoom massimo';

  @override
  String get selectMapLayer => 'Seleziona Livello Mappa';

  @override
  String get mapOptions => 'Opzioni Mappa';

  @override
  String get showLegend => 'Mostra Legenda';

  @override
  String get displayMarkerTypeCounts =>
      'Visualizza conteggio tipi di marcatori';

  @override
  String get rotateMapWithHeading => 'Ruota Mappa con Direzione';

  @override
  String get mapFollowsDirection =>
      'La mappa segue la tua direzione quando ti muovi';

  @override
  String get showMapDebugInfo => 'Mostra Info Debug Mappa';

  @override
  String get displayZoomLevelBounds => 'Visualizza livello di zoom e limiti';

  @override
  String get fullscreenMode => 'Modalità Schermo Intero';

  @override
  String get hideUiFullMapView =>
      'Nascondi tutti i controlli UI per la visualizzazione completa della mappa';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Satellite';

  @override
  String get googleHybrid => 'Google Ibrido';

  @override
  String get googleRoadmap => 'Google Mappa Stradale';

  @override
  String get googleTerrain => 'Google Terreno';

  @override
  String get downloadVisibleArea => 'Scarica area visibile';

  @override
  String get initializingMap => 'Inizializzazione mappa...';

  @override
  String get dragToPosition => 'Trascina per Posizionare';

  @override
  String get createSarMarker => 'Crea Marcatore SAR';

  @override
  String get compass => 'Bussola';

  @override
  String get navigationAndContacts => 'Navigazione e Contatti';

  @override
  String get sarAlert => 'ALLERTA SAR';

  @override
  String get messageSentToPublicChannel =>
      'Messaggio inviato al canale pubblico';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Seleziona una stanza per inviare il marcatore SAR';

  @override
  String failedToSendSarMarker(String error) {
    return 'Impossibile inviare il marcatore SAR: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'Marcatore SAR inviato a $roomName';
  }

  @override
  String get notConnectedCannotSync =>
      'Non connesso - impossibile sincronizzare i messaggi';

  @override
  String syncedMessageCount(int count) {
    return 'Sincronizzati $count messaggio(i)';
  }

  @override
  String get noNewMessages => 'Nessun nuovo messaggio';

  @override
  String syncFailed(String error) {
    return 'Sincronizzazione fallita: $error';
  }

  @override
  String get failedToResendMessage => 'Impossibile reinviare il messaggio';

  @override
  String get retryingMessage => 'Nuovo tentativo messaggio...';

  @override
  String retryFailed(String error) {
    return 'Nuovo tentativo fallito: $error';
  }

  @override
  String get textCopiedToClipboard => 'Testo copiato negli appunti';

  @override
  String get cannotReplySenderMissing =>
      'Impossibile rispondere: informazioni mittente mancanti';

  @override
  String get cannotReplyContactNotFound =>
      'Impossibile rispondere: contatto non trovato';

  @override
  String get messageDeleted => 'Messaggio eliminato';

  @override
  String get copyText => 'Copia testo';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Elimina messaggio';

  @override
  String get deleteMessageConfirmation =>
      'Sei sicuro di voler eliminare questo messaggio?';

  @override
  String get shareLocation => 'Condividi posizione';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nCoordinate: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Posizione SAR';

  @override
  String get locationShared => 'Posizione condivisa';

  @override
  String get refreshedContacts => 'Contatti aggiornati';

  @override
  String get justNow => 'Proprio ora';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m fa';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String daysAgo(int days) {
    return '${days}g fa';
  }

  @override
  String secondsAgo(int seconds) {
    return '${seconds}s fa';
  }

  @override
  String get sending => 'Invio...';

  @override
  String get sent => 'Inviato';

  @override
  String get delivered => 'Consegnato';

  @override
  String deliveredWithTime(int time) {
    return 'Consegnato (${time}ms)';
  }

  @override
  String get failed => 'Fallito';

  @override
  String get broadcast => 'Trasmissione';

  @override
  String get sarMarkerFoundPerson => 'Persona Trovata';

  @override
  String get sarMarkerFire => 'Posizione Incendio';

  @override
  String get sarMarkerStagingArea => 'Area di Appoggio';

  @override
  String get sarMarkerObject => 'Oggetto Trovato';

  @override
  String get from => 'Da';

  @override
  String get coordinates => 'Coordinate';

  @override
  String get tapToViewOnMap => 'Tocca per visualizzare sulla mappa';

  @override
  String get radioSettings => 'Impostazioni Radio';

  @override
  String get frequencyMHz => 'Frequenza (MHz)';

  @override
  String get frequencyExample => 'es., 869.618';

  @override
  String get bandwidth => 'Larghezza di Banda';

  @override
  String get spreadingFactor => 'Fattore di Spreading';

  @override
  String get codingRate => 'Tasso di Codifica';

  @override
  String get txPowerDbm => 'Potenza TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Max: $power dBm';
  }

  @override
  String get you => 'Tu';

  @override
  String get offlineVectorMaps => 'Mappe Vettoriali Offline';

  @override
  String get offlineVectorMapsDescription =>
      'Importa e gestisci tile di mappe vettoriali offline (formato MBTiles) per l\'uso senza connessione internet';

  @override
  String get importMbtiles => 'Importa File MBTiles';

  @override
  String get importMbtilesNote =>
      'Supporta file MBTiles con tile vettoriali (formato PBF/MVT). Gli estratti Geofabrik funzionano benissimo!';

  @override
  String get noMbtilesFiles => 'Nessuna mappa vettoriale offline trovata';

  @override
  String get mbtilesImportedSuccessfully =>
      'File MBTiles importato con successo';

  @override
  String get failedToImportMbtiles => 'Impossibile importare il file MBTiles';

  @override
  String get deleteMbtilesConfirmTitle => 'Elimina Mappa Offline';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"? Questo rimuoverà permanentemente la mappa offline.';
  }

  @override
  String get mbtilesDeletedSuccessfully =>
      'Mappa offline eliminata con successo';

  @override
  String get failedToDeleteMbtiles => 'Impossibile eliminare la mappa offline';

  @override
  String get importExportCachedTiles => 'Importa/Esporta tile in cache';

  @override
  String get importExportDescription =>
      'Esegui backup, condividi e ripristina tile mappa scaricati tra dispositivi';

  @override
  String get exportTilesToFile => 'Esporta tile su file';

  @override
  String get importTilesFromFile => 'Importa tile da file';

  @override
  String get selectExportLocation => 'Seleziona posizione esportazione';

  @override
  String get selectImportFile => 'Seleziona archivio tile';

  @override
  String get exportingTiles => 'Esportazione tile...';

  @override
  String get importingTiles => 'Importazione tile...';

  @override
  String exportSuccess(int count) {
    return '$count tile esportati con successo';
  }

  @override
  String importSuccess(int count) {
    return '$count archivi importati con successo';
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
      'Crea un file archivio compresso (.fmtc) che può essere condiviso e importato su altri dispositivi.';

  @override
  String get importNote =>
      'Importa tile mappa da un file archivio precedentemente esportato. I tile verranno uniti con la cache esistente.';

  @override
  String get noTilesToExport => 'Nessun tile da esportare';

  @override
  String archiveContainsStores(int count) {
    return 'L\'archivio contiene $count archivi';
  }

  @override
  String get vectorTiles => 'Tile Vettoriali';

  @override
  String get schema => 'Schema';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get bounds => 'Limiti';

  @override
  String get onlineLayers => 'Livelli Online';

  @override
  String get offlineLayers => 'Livelli Offline';

  @override
  String get locationTrail => 'Traccia Posizione';

  @override
  String get showTrailOnMap => 'Mostra Traccia sulla Mappa';

  @override
  String get trailVisible => 'La traccia è visibile sulla mappa';

  @override
  String get trailHiddenRecording =>
      'La traccia è nascosta (ancora in registrazione)';

  @override
  String get duration => 'Durata';

  @override
  String get points => 'Punti';

  @override
  String get clearTrail => 'Cancella Traccia';

  @override
  String get clearTrailQuestion => 'Cancellare Traccia?';

  @override
  String get clearTrailConfirmation =>
      'Sei sicuro di voler cancellare la traccia posizione attuale? Questa azione non può essere annullata.';

  @override
  String get noTrailRecorded => 'Nessuna traccia registrata ancora';

  @override
  String get startTrackingToRecord =>
      'Avvia il tracciamento posizione per registrare la tua traccia';

  @override
  String get trailControls => 'Controlli Traccia';

  @override
  String get deviceInformation => 'Informazioni Dispositivo';

  @override
  String get bleName => 'Nome BLE';

  @override
  String get meshName => 'Nome Mesh';

  @override
  String get notSet => 'Non impostato';

  @override
  String get model => 'Modello';

  @override
  String get version => 'Versione';

  @override
  String get buildDate => 'Data Build';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Contatti Max';

  @override
  String get maxChannels => 'Canali Max';

  @override
  String get publicInfo => 'Informazioni Pubbliche';

  @override
  String get meshNetworkName => 'Nome Rete Mesh';

  @override
  String get nameBroadcastInMesh => 'Nome trasmesso negli annunci mesh';

  @override
  String get telemetryAndLocationSharing =>
      'Telemetria e Condivisione Posizione';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Usa posizione attuale';

  @override
  String get noneUnknown => 'Nessuno/Sconosciuto';

  @override
  String get chatNode => 'Nodo Chat';

  @override
  String get repeater => 'Ripetitore';

  @override
  String get roomChannel => 'Stanza/Canale';

  @override
  String typeNumber(int number) {
    return 'Tipo $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Copiato $label negli appunti';
  }

  @override
  String failedToSave(String error) {
    return 'Impossibile salvare: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Impossibile ottenere la posizione: $error';
  }

  @override
  String get sarTemplates => 'Modelli SAR';

  @override
  String get manageSarTemplates => 'Gestisci modelli SAR';

  @override
  String get addTemplate => 'Aggiungi modello';

  @override
  String get editTemplate => 'Modifica modello';

  @override
  String get deleteTemplate => 'Elimina modello';

  @override
  String get templateName => 'Nome modello';

  @override
  String get templateNameHint => 'e.g. Found Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji è obbligatorio';

  @override
  String get nameRequired => 'Nome è obbligatorio';

  @override
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Importa';

  @override
  String get exportToClipboard => 'Esporta';

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
  String get resetToDefaults => 'Ripristina predefiniti';

  @override
  String get resetToDefaultsConfirmation =>
      'Questo eliminerà tutti i modelli personalizzati e ripristinerà i 4 modelli predefiniti. Continuare?';

  @override
  String get reset => 'Ripristina';

  @override
  String get resetComplete => 'Modelli ripristinati ai valori predefiniti';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Permessi';

  @override
  String get locationPermission => 'Permesso di posizione';

  @override
  String get checking => 'Verifica in corso...';

  @override
  String get locationPermissionGrantedAlways => 'Concesso (Sempre)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Concesso (Durante l\'uso)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Negato - Tocca per richiedere';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Negato permanentemente - Apri impostazioni';

  @override
  String get locationPermissionDialogContent =>
      'Il permesso di posizione è permanentemente negato. Si prega di abilitarlo nelle impostazioni del dispositivo per utilizzare il tracciamento GPS e la condivisione della posizione.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get locationPermissionGranted => 'Permesso di posizione concesso!';

  @override
  String get locationPermissionRequiredForGps =>
      'Il permesso di posizione è necessario per il tracciamento GPS e la condivisione della posizione.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Il permesso di posizione è già concesso.';

  @override
  String get sarNavyBlue => 'SAR Blu Navy';

  @override
  String get sarNavyBlueDescription => 'Modalità Professionale/Operativa';

  @override
  String get selectRecipient => 'Seleziona destinatario';

  @override
  String get broadcastToAllNearby => 'Trasmetti a tutti nelle vicinanze';

  @override
  String get searchRecipients => 'Cerca destinatari...';

  @override
  String get noContactsFound => 'Nessun contatto trovato';

  @override
  String get noRoomsFound => 'Nessuna stanza trovata';

  @override
  String get noContactsOrRoomsAvailable =>
      'Nessun contatto o stanza disponibile';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'I messaggi saranno inviati al canale pubblico';

  @override
  String get newMessage => 'Nuovo messaggio';

  @override
  String get channel => 'Canale';

  @override
  String get samplePoliceLead => 'Capo della Polizia';

  @override
  String get sampleDroneOperator => 'Operatore Drone';

  @override
  String get sampleFirefighterAlpha => 'Vigile del Fuoco';

  @override
  String get sampleMedicCharlie => 'Medico';

  @override
  String get sampleCommandDelta => 'Comando';

  @override
  String get sampleFireEngine => 'Autopompa';

  @override
  String get sampleAirSupport => 'Supporto Aereo';

  @override
  String get sampleBaseCoordinator => 'Coordinatore di Base';

  @override
  String get channelEmergency => 'Emergenza';

  @override
  String get channelCoordination => 'Coordinamento';

  @override
  String get channelUpdates => 'Aggiornamenti';

  @override
  String get sampleTeamMember => 'Membro del Team di Esempio';

  @override
  String get sampleScout => 'Esploratore di Esempio';

  @override
  String get sampleBase => 'Base di Esempio';

  @override
  String get sampleSearcher => 'Cercatore di Esempio';

  @override
  String get sampleObjectBackpack => ' Zaino trovato - colore blu';

  @override
  String get sampleObjectVehicle =>
      ' Veicolo abbandonato - controllare il proprietario';

  @override
  String get sampleObjectCamping => ' Attrezzatura da campeggio scoperta';

  @override
  String get sampleObjectTrailMarker => ' Segnavia trovato fuori sentiero';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Tutti i team segnalarsi';

  @override
  String get sampleMsgWeatherUpdate =>
      'Aggiornamento meteo: Cielo sereno, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Campo base stabilito all\'area di raduno';

  @override
  String get sampleMsgTeamAlpha => 'Team si sta spostando al settore 2';

  @override
  String get sampleMsgRadioCheck =>
      'Controllo radio - tutte le stazioni rispondano';

  @override
  String get sampleMsgWaterSupply =>
      'Rifornimento idrico disponibile al punto di controllo 3';

  @override
  String get sampleMsgTeamBravo => 'Team segnala: settore 1 libero';

  @override
  String get sampleMsgEtaRallyPoint => 'ETA al punto di raduno: 15 minuti';

  @override
  String get sampleMsgSupplyDrop =>
      'Lancio rifornimenti confermato per le 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Sorveglianza con drone completata - nessun ritrovamento';

  @override
  String get sampleMsgTeamCharlie => 'Team richiede rinforzi';

  @override
  String get sampleMsgRadioDiscipline =>
      'Tutte le unità: mantenere disciplina radio';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENTE: Assistenza medica necessaria al settore 4';

  @override
  String get sampleMsgAdultMale => ' Uomo adulto, cosciente';

  @override
  String get sampleMsgFireSpotted =>
      'Incendio avvistato - coordinate in arrivo';

  @override
  String get sampleMsgSpreadingRapidly => ' Si sta diffondendo rapidamente!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITÀ: Necessario supporto elicottero';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Team medico in rotta verso la vostra posizione';

  @override
  String get sampleMsgEvacHelicopter =>
      'Elicottero di evacuazione ETA 10 minuti';

  @override
  String get sampleMsgEmergencyResolved => 'Emergenza risolta - tutto libero';

  @override
  String get sampleMsgEmergencyStagingArea => ' Area di raduno di emergenza';

  @override
  String get sampleMsgEmergencyServices =>
      'Servizi di emergenza notificati e in risposta';

  @override
  String get sampleAlphaTeamLead => 'Capo Team';

  @override
  String get sampleBravoScout => 'Esploratore';

  @override
  String get sampleCharlieMedic => 'Medico';

  @override
  String get sampleDeltaNavigator => 'Navigatore';

  @override
  String get sampleEchoSupport => 'Supporto';

  @override
  String get sampleBaseCommand => 'Comando di Base';

  @override
  String get sampleFieldCoordinator => 'Coordinatore sul Campo';

  @override
  String get sampleMedicalTeam => 'Team Medico';

  @override
  String get mapDrawing => 'Disegno della Mappa';

  @override
  String get navigateToDrawing => 'Naviga al Disegno';

  @override
  String get copyCoordinates => 'Copia Coordinate';

  @override
  String get hideFromMap => 'Nascondi dalla Mappa';

  @override
  String get lineDrawing => 'Linea';

  @override
  String get rectangleDrawing => 'Rettangolo';

  @override
  String get coordinatesCopiedToClipboard => 'Coordinate copiate negli appunti';

  @override
  String get drawingShared => 'Disegno della Mappa';

  @override
  String get drawingHidden => 'Disegno nascosto dalla mappa';

  @override
  String alreadyShared(int count) {
    return '$count già condiviso';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return '$count nuovo(i) disegno(i) condiviso(i)';
  }

  @override
  String get shareDrawing => 'Condividi Disegno';

  @override
  String get shareWithAllNearbyDevices =>
      'Condividi con tutti i dispositivi vicini';

  @override
  String get shareToRoom => 'Condividi nella Stanza';

  @override
  String get sendToPersistentStorage =>
      'Invia allo storage persistente della stanza';

  @override
  String get deleteDrawingConfirm =>
      'Sei sicuro di voler eliminare questo disegno?';

  @override
  String get drawingDeleted => 'Disegno eliminato';

  @override
  String yourDrawingsCount(int count) {
    return 'I Tuoi Disegni ($count)';
  }

  @override
  String get shared => 'Condiviso';

  @override
  String get line => 'Linea';

  @override
  String get rectangle => 'Rettangolo';
}
