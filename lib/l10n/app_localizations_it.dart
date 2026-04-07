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
  String get noDevicesFound => 'Nessun dispositivo trovato';

  @override
  String get scanAgain => 'Cerca Nuovamente';

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
  String failedToAdvertise(String error) {
    return 'Annuncio fallito: $error';
  }

  @override
  String get cancelReconnection => 'Annulla riconnessione';

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
  String get disableMap => 'Disabilita mappa';

  @override
  String get language => 'Lingua';

  @override
  String get chooseLanguage => 'Scegli Lingua';

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
  String get moreInfo => 'Maggiori informazioni';

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
  String get resetPath => 'Resetta Percorso (Ri-instrada)';

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
  String get measureDistance => 'Misura Distanza';

  @override
  String get measureDistanceDesc => 'Premi a lungo su due punti per misurare';

  @override
  String get clearMeasurement => 'Cancella Misurazione';

  @override
  String distanceLabel(String distance) {
    return 'Distanza: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Premi a lungo per il secondo punto';

  @override
  String get longPressToStartMeasurement =>
      'Premi a lungo per impostare il primo punto';

  @override
  String get longPressToStartNewMeasurement =>
      'Premi a lungo per nuova misurazione';

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
  String get publicChannel => 'Canale Pubblico';

  @override
  String get broadcastToAll => 'Trasmetti a tutti i nodi vicini (effimero)';

  @override
  String get storedPermanently => 'Archiviato permanentemente nella stanza';

  @override
  String get notConnectedToDevice => 'Non connesso al dispositivo';

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
  String get autoSend => 'Invio automatico';

  @override
  String get autoSendDescription => 'Invia tramite il percorso attuale.';

  @override
  String get sendDirect => 'Invio diretto';

  @override
  String get sendDirectDescription => 'Invia direttamente a questo contatto.';

  @override
  String get sendFlood => 'Invio flood';

  @override
  String get sendFloodDescription => 'Invia tramite tutti i ripetitori.';

  @override
  String get loggedIn => 'Connesso';

  @override
  String get noGpsData => 'Nessun dato GPS';

  @override
  String get distance => 'Distanza';

  @override
  String directPingTimeout(String name) {
    return 'Timeout ping diretto - nuovo tentativo $name con flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping fallito a $name - nessuna risposta ricevuta';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?\n\nQuesto rimuoverà il contatto sia dall\'app che dal dispositivo radio companion.';
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
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permessi';

  @override
  String get telemetry => 'Telemetria';

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
  String get selectMapLayer => 'Seleziona Livello Mappa';

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
  String get textCopiedToClipboard => 'Testo copiato negli appunti';

  @override
  String get cannotReplySenderMissing =>
      'Impossibile rispondere: informazioni mittente mancanti';

  @override
  String get cannotReplyContactNotFound =>
      'Impossibile rispondere: contatto non trovato';

  @override
  String get copyText => 'Copia testo';

  @override
  String get saveAsTemplate => 'Salva come Modello';

  @override
  String get templateSaved => 'Modello salvato con successo';

  @override
  String get templateAlreadyExists => 'Esiste già un modello con questa emoji';

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
  String deliveredToContacts(int delivered, int total) {
    return 'Consegnato a $delivered/$total contatti';
  }

  @override
  String get allDelivered => 'Tutto consegnato';

  @override
  String get recipientDetails => 'Dettagli destinatari';

  @override
  String get pending => 'In attesa';

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
  String exportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String importFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get onlineLayers => 'Livelli Online';

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
  String get model => 'Modello';

  @override
  String get version => 'Versione';

  @override
  String get maxContacts => 'Contatti Max';

  @override
  String get maxChannels => 'Canali Max';

  @override
  String get publicInfo => 'Informazioni Pubbliche';

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
  String get addTemplate => 'Aggiungi modello';

  @override
  String get editTemplate => 'Modifica modello';

  @override
  String get deleteTemplate => 'Elimina modello';

  @override
  String get templateName => 'Nome modello';

  @override
  String get templateNameHint => 'ad es. Persona trovata';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji è obbligatorio';

  @override
  String get nameRequired => 'Nome è obbligatorio';

  @override
  String get templateDescription => 'Descrizione (facoltativa)';

  @override
  String get templateDescriptionHint => 'Aggiungi contesto aggiuntivo...';

  @override
  String get templateColor => 'Colore';

  @override
  String get previewFormat => 'Anteprima (formato messaggio SAR)';

  @override
  String get importFromClipboard => 'Importa';

  @override
  String get exportToClipboard => 'Esporta';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Eliminare il modello \'$name\'?';
  }

  @override
  String get templateAdded => 'Modello aggiunto';

  @override
  String get templateUpdated => 'Modello aggiornato';

  @override
  String get templateDeleted => 'Modello eliminato';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importati $count modelli',
      one: 'Importato 1 modello',
      zero: 'Nessun modello importato',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Esportati $count modelli negli appunti',
      one: 'Esportato 1 modello negli appunti',
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
  String get noTemplates => 'Nessun modello disponibile';

  @override
  String get tapAddToCreate => 'Tocca + per creare il tuo primo modello';

  @override
  String get ok => 'OK';

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
  String get noRecipientsAvailable => 'Nessun destinatario disponibile';

  @override
  String get noChannelsFound => 'Nessun canale trovato';

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
  String get manualCoordinates => 'Coordinate Manuali';

  @override
  String get enterCoordinatesManually => 'Inserire le coordinate manualmente';

  @override
  String get latitudeLabel => 'Latitudine';

  @override
  String get longitudeLabel => 'Longitudine';

  @override
  String get exampleCoordinates => 'Esempio: 46.0569, 14.5058';

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

  @override
  String get updateAvailable => 'Aggiornamento Disponibile';

  @override
  String get currentVersion => 'Attuale';

  @override
  String get latestVersion => 'Ultima';

  @override
  String get downloadUpdate => 'Scarica';

  @override
  String get updateLater => 'Più Tardi';

  @override
  String get cadastralParcels => 'Particelle Catastali';

  @override
  String get forestRoads => 'Strade Forestali';

  @override
  String get wmsOverlays => 'Sovrapposizioni WMS';

  @override
  String get hikingTrails => 'Sentieri Escursionistici';

  @override
  String get mainRoads => 'Strade Principali';

  @override
  String get houseNumbers => 'Numeri Civici';

  @override
  String get fireHazardZones => 'Zone a Rischio Incendio';

  @override
  String get historicalFires => 'Incendi Storici';

  @override
  String get firebreaks => 'Fasce Tagliafuoco';

  @override
  String get krasFireZones => 'Zone di Incendio Kras';

  @override
  String get placeNames => 'Nomi di Luoghi';

  @override
  String get municipalityBorders => 'Confini Comunali';

  @override
  String get topographicMap => 'Carta Topografica 1:25000';

  @override
  String get recentMessages => 'Messaggi Recenti';

  @override
  String get addChannel => 'Aggiungi Canale';

  @override
  String get channelName => 'Nome del Canale';

  @override
  String get channelNameHint => 'es. Squadra di Soccorso Alfa';

  @override
  String get channelSecret => 'Password del Canale';

  @override
  String get channelSecretHint => 'Password condivisa per questo canale';

  @override
  String get channelSecretHelp =>
      'Questa password deve essere condivisa con tutti i membri del team che necessitano di accesso a questo canale';

  @override
  String get channelTypesInfo =>
      'Canali hash (#squadra): Password generata automaticamente dal nome. Stesso nome = stesso canale su tutti i dispositivi.\n\nCanali privati: Usa una password esplicita. Solo chi ha la password può unirsi.';

  @override
  String get hashChannelInfo =>
      'Canale hash: La password verrà generata automaticamente dal nome del canale. Chiunque utilizzi lo stesso nome si unirà allo stesso canale.';

  @override
  String get channelNameRequired => 'Il nome del canale è obbligatorio';

  @override
  String get channelNameTooLong =>
      'Il nome del canale deve contenere al massimo 31 caratteri';

  @override
  String get channelSecretRequired => 'La password del canale è obbligatoria';

  @override
  String get channelSecretTooLong =>
      'La password del canale deve contenere al massimo 32 caratteri';

  @override
  String get invalidAsciiCharacters => 'Sono consentiti solo caratteri ASCII';

  @override
  String get channelCreatedSuccessfully => 'Canale creato con successo';

  @override
  String channelCreationFailed(String error) {
    return 'Creazione del canale fallita: $error';
  }

  @override
  String get deleteChannel => 'Elimina Canale';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Sei sicuro di voler eliminare il canale \"$channelName\"? Questa azione non può essere annullata.';
  }

  @override
  String get channelDeletedSuccessfully => 'Canale eliminato con successo';

  @override
  String channelDeletionFailed(String error) {
    return 'Eliminazione del canale fallita: $error';
  }

  @override
  String get createChannel => 'Crea Canale';

  @override
  String get wizardBack => 'Indietro';

  @override
  String get wizardSkip => 'Salta';

  @override
  String get wizardNext => 'Avanti';

  @override
  String get wizardGetStarted => 'Inizia';

  @override
  String get wizardWelcomeTitle => 'Benvenuto in MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Visualizza tutorial di benvenuto';

  @override
  String get allTeamContacts => 'Tutti i contatti del team';

  @override
  String directMessagesInfo(int count) {
    return 'Messaggi diretti con conferme. Inviato a $count membri del team.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Marcatore SAR inviato a $count contatti';
  }

  @override
  String get noContactsAvailable => 'Nessun contatto del team disponibile';

  @override
  String get reply => 'Rispondi';

  @override
  String get technicalDetails => 'Dettagli tecnici';

  @override
  String get messageTechnicalDetails => 'Dettagli tecnici del messaggio';

  @override
  String get linkQuality => 'Qualità del collegamento';

  @override
  String get delivery => 'Consegna';

  @override
  String get status => 'Stato';

  @override
  String get expectedAckTag => 'Tag ACK atteso';

  @override
  String get roundTrip => 'Andata e ritorno';

  @override
  String get retryAttempt => 'Tentativo di nuovo invio';

  @override
  String get floodFallback => 'Fallback inondazione';

  @override
  String get identity => 'Identità';

  @override
  String get messageId => 'ID messaggio';

  @override
  String get sender => 'Mittente';

  @override
  String get senderKey => 'Chiave mittente';

  @override
  String get recipient => 'Destinatario';

  @override
  String get recipientKey => 'Chiave destinatario';

  @override
  String get voice => 'Voce';

  @override
  String get voiceId => 'ID vocale';

  @override
  String get envelope => 'Busta';

  @override
  String get sessionProgress => 'Avanzamento sessione';

  @override
  String get complete => 'Completato';

  @override
  String get rawDump => 'Dump grezzo';

  @override
  String get cannotRetryMissingRecipient =>
      'Impossibile riprovare: informazioni destinatario mancanti';

  @override
  String get voiceUnavailable => 'Voce non disponibile al momento';

  @override
  String get requestingVoice => 'Richiesta voce';

  @override
  String get device => 'dispositivo';

  @override
  String get change => 'Modifica';

  @override
  String get wizardOverviewDescription =>
      'Questa app riunisce messaggistica MeshCore, aggiornamenti SAR sul campo, mappe e strumenti del dispositivo in un unico posto.';

  @override
  String get wizardOverviewFeature1 =>
      'Invia messaggi diretti, post nelle stanze e messaggi di canale dalla scheda principale Messaggi.';

  @override
  String get wizardOverviewFeature2 =>
      'Condividi marcatori SAR, disegni sulla mappa, clip vocali e immagini sulla mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Connettiti tramite BLE o TCP e poi gestisci la radio companion direttamente dall\'app.';

  @override
  String get wizardMessagingTitle => 'Messaggistica e rapporti sul campo';

  @override
  String get wizardMessagingDescription =>
      'Qui i messaggi sono più del semplice testo. L\'app supporta già diversi payload operativi e flussi di trasferimento.';

  @override
  String get wizardMessagingFeature1 =>
      'Invia messaggi diretti, post nelle stanze e traffico di canale da un unico compositore.';

  @override
  String get wizardMessagingFeature2 =>
      'Crea aggiornamenti SAR e modelli SAR riutilizzabili per i rapporti sul campo più comuni.';

  @override
  String get wizardMessagingFeature3 =>
      'Trasferisci sessioni vocali e immagini, con avanzamento e stime del tempo d\'aria nell\'interfaccia.';

  @override
  String get wizardConnectDeviceTitle => 'Connetti dispositivo';

  @override
  String get wizardConnectDeviceDescription =>
      'Connetti la tua radio MeshCore, scegli un nome e applica un preset radio prima di continuare.';

  @override
  String get wizardSetupBadge => 'Configurazione';

  @override
  String get wizardOverviewBadge => 'Panoramica';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Connesso a $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Nessun dispositivo ancora connesso';

  @override
  String get wizardSkipForNow => 'Salta per ora';

  @override
  String get wizardDeviceNameLabel => 'Nome del dispositivo';

  @override
  String get wizardDeviceNameHelp =>
      'Questo nome viene annunciato agli altri utenti MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Regione di configurazione';

  @override
  String get wizardConfigRegionHelp =>
      'Usa l\'elenco ufficiale completo dei preset MeshCore. Il valore predefinito è EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Assicurati che il preset selezionato corrisponda alle normative radio locali.';

  @override
  String get wizardPresetNote2 =>
      'L\'elenco corrisponde al feed ufficiale dei preset dello strumento di configurazione MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) resta selezionato per impostazione predefinita durante l\'onboarding.';

  @override
  String get wizardSaving => 'Salvataggio...';

  @override
  String get wizardSaveAndContinue => 'Salva e continua';

  @override
  String get wizardEnterDeviceName =>
      'Inserisci un nome dispositivo prima di continuare.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '$deviceName salvato con $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contatti, stanze e ripetitori';

  @override
  String get wizardNetworkDescription =>
      'La scheda Contatti organizza la rete che scopri e i percorsi che apprendi nel tempo.';

  @override
  String get wizardNetworkFeature1 =>
      'Controlla membri del team, ripetitori, stanze, canali e annunci in sospeso in un unico elenco.';

  @override
  String get wizardNetworkFeature2 =>
      'Usa smart ping, accesso alle stanze, percorsi appresi e strumenti di reset delle route quando la connettività diventa complicata.';

  @override
  String get wizardNetworkFeature3 =>
      'Crea canali e gestisci le destinazioni di rete senza uscire dall\'app.';

  @override
  String get wizardMapOpsTitle => 'Mappa, tracce e geometria condivisa';

  @override
  String get wizardMapOpsDescription =>
      'La mappa dell\'app è collegata direttamente a messaggistica, tracciamento e overlay SAR invece di essere un visualizzatore separato.';

  @override
  String get wizardMapOpsFeature1 =>
      'Monitora la tua posizione, le posizioni dei compagni e le tracce di movimento sulla mappa.';

  @override
  String get wizardMapOpsFeature2 =>
      'Apri i disegni dai messaggi, visualizzali in anteprima in linea e rimuovili dalla mappa quando serve.';

  @override
  String get wizardMapOpsFeature3 =>
      'Usa le viste mappa dei ripetitori e gli overlay condivisi per capire la copertura della rete sul campo.';

  @override
  String get wizardToolsTitle => 'Strumenti oltre la messaggistica';

  @override
  String get wizardToolsDescription =>
      'Qui c\'è più delle quattro schede principali. L\'app include anche configurazione, diagnostica e flussi sensori opzionali.';

  @override
  String get wizardToolsFeature1 =>
      'Apri la configurazione del dispositivo per cambiare impostazioni radio, telemetria, potenza TX e dettagli del companion.';

  @override
  String get wizardToolsFeature2 =>
      'Abilita la scheda Sensori quando vuoi dashboard monitorate e azioni di aggiornamento rapido.';

  @override
  String get wizardToolsFeature3 =>
      'Usa log dei pacchetti, scansione dello spettro e diagnostica sviluppatore per risolvere problemi della mesh.';

  @override
  String get postConnectDiscoveryTitle => 'Scoprire i ripetitori ora?';

  @override
  String get postConnectDiscoveryDescription =>
      'Esegui la scoperta dei ripetitori subito dopo la connessione per vedere i nodi MeshCore nelle vicinanze e aggiungerli alla tua rete più velocemente.';

  @override
  String get contactInSensors => 'Nei Sensori';

  @override
  String get contactAddToSensors => 'Aggiungi ai Sensori';

  @override
  String get contactSetPath => 'Imposta percorso';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName aggiunto a Sensori';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Impossibile cancellare il percorso: $error';
  }

  @override
  String get contactRouteCleared => 'Percorso cancellato';

  @override
  String contactRouteSet(String route) {
    return 'Percorso impostato: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Impossibile impostare il percorso: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Timeout ACK';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Payload';

  @override
  String get hops => 'Hop';

  @override
  String get hashSize => 'Dimensione hash';

  @override
  String get pathBytes => 'Byte percorso';

  @override
  String get selectedPath => 'Percorso selezionato';

  @override
  String get estimatedTx => 'Trasmissione stimata';

  @override
  String get senderToReceipt => 'Mittente a ricevuta';

  @override
  String get receivedCopies => 'Copie ricevute';

  @override
  String get retryCause => 'Causa del ritentativo';

  @override
  String get retryMode => 'Modalità ritentativo';

  @override
  String get retryResult => 'Risultato ritentativo';

  @override
  String get lastRetry => 'Ultimo ritentativo';

  @override
  String get rxPackets => 'Pacchetti RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Velocità';

  @override
  String get window => 'Finestra';

  @override
  String get posttxDelay => 'Ritardo post-tx';

  @override
  String get bandpass => 'Passa-banda';

  @override
  String get bandpassFilterVoice => 'Filtro passa-banda voce';

  @override
  String get active => 'Attivo';

  @override
  String get addContact => 'Aggiungi contatto';

  @override
  String get all => 'Tutto';

  @override
  String get clearAllLabel => 'Cancella tutto';

  @override
  String get clearFilters => 'Cancella filtri';

  @override
  String get clearRoute => 'Cancella percorso';

  @override
  String get clearMessages => 'Cancella messaggi';

  @override
  String get clearScale => 'Cancella scala';

  @override
  String get clearDiscoveries => 'Cancella scoperte';

  @override
  String get clearOnlineTraceDatabase => 'Cancella database tracce';

  @override
  String get clearAllChannels => 'Cancella tutti i canali';

  @override
  String get clearAllContacts => 'Cancella tutti i contatti';

  @override
  String get clearChannels => 'Cancella canali';

  @override
  String get clearContacts => 'Cancella contatti';

  @override
  String get clearPathOnMaxRetry => 'Cancella percorso al max ritentativo';

  @override
  String get create => 'Crea';

  @override
  String get custom => 'Personalizzato';

  @override
  String get defaultValue => 'Predefinito';

  @override
  String get duplicate => 'Duplica';

  @override
  String get editName => 'Modifica nome';

  @override
  String get open => 'Apri';

  @override
  String get paste => 'Incolla';

  @override
  String get preview => 'Anteprima';

  @override
  String get remove => 'Rimuovi';

  @override
  String get rename => 'Rinomina';

  @override
  String get resolveAll => 'Risolvi tutto';

  @override
  String get send => 'Invia';

  @override
  String get sendAnyway => 'Invia comunque';

  @override
  String get share => 'Condividi';

  @override
  String get trace => 'Traccia';

  @override
  String get discovery => 'Scoperta';

  @override
  String get discoverRepeaters => 'Scopri ripetitori';

  @override
  String get discoverSensors => 'Scopri sensori';

  @override
  String get repeaterDiscoverySent => 'Scoperta ripetitori inviata';

  @override
  String get sensorDiscoverySent => 'Scoperta sensori inviata';

  @override
  String get clearedPendingDiscoveries => 'Scoperte in attesa cancellate.';

  @override
  String get autoDiscovery => 'Scoperta automatica';

  @override
  String get enableAutomaticAdding => 'Abilita aggiunta automatica';

  @override
  String get autoaddRepeaters => 'Aggiungi ripetitori automaticamente';

  @override
  String get autoaddRoomServers => 'Aggiungi server stanze automaticamente';

  @override
  String get autoaddSensors => 'Aggiungi sensori automaticamente';

  @override
  String get autoaddUsers => 'Aggiungi utenti automaticamente';

  @override
  String get overwriteOldestWhenFull => 'Sovrascrivi i più vecchi quando pieno';

  @override
  String get storage => 'Archiviazione';

  @override
  String get dangerZone => 'Zona pericolosa';

  @override
  String get profiles => 'Profili';

  @override
  String get favourites => 'Preferiti';

  @override
  String get sensors => 'Sensori';

  @override
  String get others => 'Altri';

  @override
  String get gpsModule => 'Modulo GPS';

  @override
  String get liveTraffic => 'Traffico in tempo reale';

  @override
  String get repeatersMap => 'Mappa ripetitori';

  @override
  String get blePacketLogs => 'Log pacchetti BLE';

  @override
  String get onlineTraceDatabase => 'Database tracce';

  @override
  String get routePathByteSize => 'Dimensione percorso in byte';

  @override
  String get messageNotifications => 'Notifiche messaggi';

  @override
  String get sarAlerts => 'Avvisi SAR';

  @override
  String get discoveryNotifications => 'Notifiche scoperte';

  @override
  String get updateNotifications => 'Notifiche aggiornamenti';

  @override
  String get muteWhileAppIsOpen => 'Silenzia con l\'app aperta';

  @override
  String get disableContacts => 'Disabilita contatti';

  @override
  String get enableSensorsTab => 'Abilita scheda Sensori';

  @override
  String get enableProfiles => 'Abilita profili';

  @override
  String get nearestRepeaterFallback => 'Ripetitore più vicino come fallback';

  @override
  String get deleteAllStoredMessageHistory =>
      'Elimina tutta la cronologia messaggi';

  @override
  String get messageFontSize => 'Dimensione carattere messaggi';

  @override
  String get rotateMapWithHeading => 'Ruota mappa con direzione';

  @override
  String get showMapDebugInfo => 'Mostra info debug mappa';

  @override
  String get openMapInFullscreen => 'Apri mappa a schermo intero';

  @override
  String get showSarMarkersLabel => 'Mostra marcatori SAR';

  @override
  String get hideRepeatersOnMap => 'Nascondi ripetitori sulla mappa';

  @override
  String get setMapScale => 'Imposta scala mappa';

  @override
  String get customMapScaleSaved => 'Scala mappa personalizzata salvata';

  @override
  String get voiceBitrate => 'Bitrate voce';

  @override
  String get voiceCompressor => 'Compressore voce';

  @override
  String get voiceLimiter => 'Limitatore voce';

  @override
  String get micAutoGain => 'Guadagno automatico microfono';

  @override
  String get echoCancellation => 'Cancellazione eco';

  @override
  String get noiseSuppression => 'Soppressione rumore';

  @override
  String get trimSilenceInVoiceMessages =>
      'Taglia silenzio nei messaggi vocali';

  @override
  String get compressor => 'Compressore';

  @override
  String get limiter => 'Limitatore';

  @override
  String get autoGain => 'Guadagno automatico';

  @override
  String get echoCancel => 'Eco';

  @override
  String get noiseSuppress => 'Rumore';

  @override
  String get silenceTrim => 'Silenzio';

  @override
  String get maxImageSize => 'Dimensione massima immagine';

  @override
  String get imageCompression => 'Compressione immagine';

  @override
  String get grayscale => 'Scala di grigi';

  @override
  String get ultraMode => 'Modalità ultra';

  @override
  String get fastPrivateGpsUpdates => 'Aggiornamenti GPS privati veloci';

  @override
  String get movementThreshold => 'Soglia di movimento';

  @override
  String get fastGpsMovementThreshold => 'Soglia movimento GPS veloce';

  @override
  String get fastGpsActiveuseInterval => 'Intervallo uso attivo GPS veloce';

  @override
  String get activeuseUpdateInterval => 'Intervallo aggiornamento uso attivo';

  @override
  String get repeatNearbyTraffic => 'Ripeti traffico vicino';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Inoltra tramite ripetitori nella rete';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Solo vicini, senza flood dei ripetitori';

  @override
  String get multihop => 'Multi-hop';

  @override
  String get createProfile => 'Crea profilo';

  @override
  String get renameProfile => 'Rinomina profilo';

  @override
  String get newProfile => 'Nuovo profilo';

  @override
  String get manageProfiles => 'Gestisci profili';

  @override
  String get enableProfilesToStartManagingThem =>
      'Abilita i profili per iniziare a gestirli.';

  @override
  String get openMessage => 'Apri messaggio';

  @override
  String get jumpToTheRelatedSarMessage => 'Vai al messaggio SAR correlato';

  @override
  String get removeSarMarker => 'Rimuovi marcatore SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Seleziona una destinazione per inviare il marcatore SAR';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Marcatore SAR trasmesso al canale pubblico';

  @override
  String get sarMarkerSentToRoom => 'Marcatore SAR inviato alla stanza';

  @override
  String get loadFromGallery => 'Carica dalla galleria';

  @override
  String get replaceImage => 'Sostituisci immagine';

  @override
  String get selectFromGallery => 'Seleziona dalla galleria';

  @override
  String get team => 'Squadra';

  @override
  String get found => 'Trovato';

  @override
  String get staging => 'Area di raccolta';

  @override
  String get object => 'Oggetto';

  @override
  String get quiet => 'Silenzioso';

  @override
  String get busy => 'Occupato';

  @override
  String get searchMessages => 'Cerca messaggi';

  @override
  String get sendImageFromGallery => 'Invia immagine dalla galleria';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get allMessages => 'Tutti i messaggi';

  @override
  String get sendToPublicChannel => 'Inviare al canale pubblico?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Seleziona tipo marcatore e destinazione';

  @override
  String get noDestinationsAvailableLabel => 'Nessuna destinazione disponibile';

  @override
  String get image => 'Immagine';

  @override
  String get format => 'Formato';

  @override
  String get dimensions => 'Dimensioni';

  @override
  String get segments => 'Segmenti';

  @override
  String get transfers => 'Trasferimenti';

  @override
  String get downloadedBy => 'Scaricato da';

  @override
  String get saveDiscoverySettings => 'Salva impostazioni scoperta';

  @override
  String get savePublicInfo => 'Salva info pubbliche';

  @override
  String get saveRadioSettings => 'Salva impostazioni radio';

  @override
  String get savePath => 'Salva percorso';

  @override
  String get wipeDeviceData => 'Cancella dati dispositivo';

  @override
  String get wipeDevice => 'Cancella dispositivo';

  @override
  String get destructiveDeviceActions => 'Azioni distruttive del dispositivo.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Scegli un preset o personalizza le impostazioni radio.';

  @override
  String get used => 'Usato';

  @override
  String get total => 'Totale';

  @override
  String get renameValue => 'Rinomina valore';

  @override
  String get customizeFields => 'Personalizza campi';

  @override
  String get livePreview => 'Anteprima dal vivo';

  @override
  String get refreshSchedule => 'Programma aggiornamento';

  @override
  String get noResponse => 'Nessuna risposta';

  @override
  String get refreshing => 'Aggiornamento';

  @override
  String get unavailable => 'Non disponibile';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Scegli un relay o nodo da monitorare.';

  @override
  String get publicKeyLabel => 'Chiave pubblica';

  @override
  String get alreadyInContacts => 'Già nei contatti';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Connettiti a un dispositivo prima di aggiungere contatti';

  @override
  String get fromContacts => 'Dai contatti';

  @override
  String get onlineOnly => 'Solo online';

  @override
  String get inBoth => 'In entrambi';

  @override
  String get source => 'Origine';

  @override
  String get allMessagesCleared => 'Tutti i messaggi cancellati';

  @override
  String get onlineTraceDatabaseCleared => 'Database tracce cancellata';

  @override
  String get packetLogsCleared => 'Log pacchetti cancellati';

  @override
  String get hexDataCopiedToClipboard => 'Dati hex copiati negli appunti';

  @override
  String get developerModeEnabled => 'Modalità sviluppatore attivata';

  @override
  String get developerModeDisabled => 'Modalità sviluppatore disattivata';

  @override
  String get clipboardIsEmpty => 'Gli appunti sono vuoti';

  @override
  String get contactImported => 'Contatto importato';

  @override
  String get contactLinkCopiedToClipboard =>
      'Link contatto copiato negli appunti';

  @override
  String get failedToExportContact => 'Esportazione contatto fallita';

  @override
  String get noLogsToExport => 'Nessun log da esportare';

  @override
  String get exportAsCsv => 'Esporta come CSV';

  @override
  String get exportAsText => 'Esporta come testo';

  @override
  String get receivedRfc3339 => 'Ricevuto (RFC3339)';

  @override
  String get buildTime => 'Ora build';

  @override
  String get downloadUrlNotAvailable => 'URL di download non disponibile';

  @override
  String get cannotOpenDownloadUrl => 'Impossibile aprire URL di download';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Il controllo aggiornamenti è disponibile solo su Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Stai utilizzando l\'ultima versione';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Aggiornamento disponibile ma URL di download non trovato';

  @override
  String get startTictactoe => 'Avvia Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe non disponibile';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: avversario sconosciuto';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: in attesa dell\'inizio';

  @override
  String get acceptsShareLinks => 'Accetta link condivisi';

  @override
  String get supportsRawHex => 'Supporta hex grezzo';

  @override
  String get clipboardfriendly => 'Compatibile con appunti';

  @override
  String get captured => 'Catturato';

  @override
  String get size => 'Dimensione';

  @override
  String get noCustomChannelsToClear =>
      'Nessun canale personalizzato da cancellare.';

  @override
  String get noDeviceContactsToClear =>
      'Nessun contatto dispositivo da cancellare.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Aggiungi';

  @override
  String get addAdditionalDetails => 'Aggiungi dettagli aggiuntivi';

  @override
  String get addPeer => 'Aggiungi peer';

  @override
  String get addPeerManually => 'Aggiungi peer manualmente';

  @override
  String addedToContacts(String name) {
    return '$name aggiunto ai contatti';
  }

  @override
  String addedToSensors(String name) {
    return '$name aggiunto ai sensori';
  }

  @override
  String get allowAll => 'Consenti tutto';

  @override
  String get anonymousRxStats => 'Statistiche RX anonime';

  @override
  String get appearance => 'Aspetto';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Telemetria di base';

  @override
  String get blePin => 'PIN BLE';

  @override
  String get buzzerAlerts => 'Avvisi buzzer';

  @override
  String get cancelImageReceive => 'Annulla ricezione immagine';

  @override
  String get choose => 'Scegli';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Scegli quali schede e sezioni contatti mostrare';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get clearHistory => 'Cancella cronologia';

  @override
  String get clearLiveView => 'Cancella vista live';

  @override
  String get clearLogs => 'Cancella log';

  @override
  String get clearOfflineCache => 'Svuotare la cache offline?';

  @override
  String get clearOverlay => 'Cancella sovrapposizione';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Cancella il percorso solo dopo che tutti i tentativi falliscono';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Codec, bitrate ed elaborazione audio';

  @override
  String get connectByIpAddress => 'Connetti tramite indirizzo IP';

  @override
  String get controlWhichAlertsYouReceive => 'Controlla quali avvisi ricevi';

  @override
  String get copyFullHex => 'Copia Hex completo';

  @override
  String get copyRawResponse => 'Copia risposta grezza';

  @override
  String get couldNotLoadMetHistory => 'Impossibile caricare la cronologia MET';

  @override
  String customizeSensor(String name) {
    return 'Personalizza $name';
  }

  @override
  String get data => 'Dati';

  @override
  String get deleteGroup => 'Elimina gruppo';

  @override
  String deleteStyleConfirm(String name) {
    return 'Eliminare $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Eliminare questo $type?';
  }

  @override
  String get deny => 'Nega';

  @override
  String get deviceInfo => 'Info dispositivo';

  @override
  String get deviceSettings => 'Impostazioni dispositivo';

  @override
  String get deviceTimeSynced =>
      'Ora del dispositivo sincronizzata con questo telefono.';

  @override
  String get disableFastGpsPublishing => 'Disabilita pubblicazione GPS rapida';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Visualizzazione, marcatori e database tracce';

  @override
  String get download => 'Scarica';

  @override
  String get environmentalTelemetry => 'Telemetria ambientale';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Errore durante il controllo degli aggiornamenti: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Errore: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Errore nell\'apertura del download: $error';
  }

  @override
  String get exportLogs => 'Esporta log';

  @override
  String get extraAggressiveAvifCompression =>
      'Compressione AVIF extra aggressiva';

  @override
  String failedToAddContact(String error) {
    return 'Impossibile aggiungere il contatto: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Impossibile aggiungere $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Impossibile cancellare i canali: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Impossibile cancellare i contatti: $error';
  }

  @override
  String get failedToConnectViaSerial =>
      'Impossibile connettersi tramite seriale';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Impossibile caricare l\'anteprima: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Impossibile caricare la traccia: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Impossibile inviare il marcatore SAR: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Impossibile impostare la modalità buzzer: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Impossibile impostare la modalità GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Impossibile sincronizzare l\'ora del dispositivo: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Impossibile cancellare i dati del dispositivo: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Canale target GPS rapido';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Aggiornamenti rapidi, soglie e permessi';

  @override
  String get fetchingCatalog => 'Recupero catalogo...';

  @override
  String get fifteenMinutes => '15 minuti';

  @override
  String get fifteenSeconds => '15 secondi';

  @override
  String get filterByDirection => 'Filtra per direzione';

  @override
  String get finish => 'Fine';

  @override
  String get fiveMinutes => '5 minuti';

  @override
  String get fiveSeconds => '5 secondi';

  @override
  String get fix => 'Fix';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Politica annunci GPS';

  @override
  String get gpsAndLocation => 'GPS e posizione';

  @override
  String get gpsDiagnostics => 'Diagnostica GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Aiuto';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Nascosto';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Come la radio aggiunge automaticamente i nodi scoperti.';

  @override
  String get images => 'Immagini';

  @override
  String get importProfile => 'Importa profilo';

  @override
  String get lastFix => 'Ultimo fix';

  @override
  String get latest => 'Più recente';

  @override
  String get latitude => 'Latitudine';

  @override
  String get loadASavedRegion => 'Carica una regione salvata';

  @override
  String get loading => 'Caricamento';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Condivisione posizione, hardware e intervallo di aggiornamento.';

  @override
  String get locationTelemetry => 'Telemetria posizione';

  @override
  String get lockDestination => 'Blocca destinazione';

  @override
  String get longitude => 'Longitudine';

  @override
  String get mapStyle => 'Stile mappa';

  @override
  String get max => 'Max';

  @override
  String get maxZoom => 'Zoom max';

  @override
  String get messaging => 'Messaggistica';

  @override
  String get metHistory => 'Cronologia MET';

  @override
  String get min => 'Min';

  @override
  String get minZoom => 'Zoom min';

  @override
  String get moveDown => 'Sposta giù';

  @override
  String get moveUp => 'Sposta su';

  @override
  String get multiAckMode => 'Modalità multi-ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Gestione spazio di lavoro multi-dispositivo';

  @override
  String get myLocation => 'La mia posizione';

  @override
  String get nameAndTelemetryShared =>
      'Nome e telemetria condivisi con altri dispositivi.';

  @override
  String newVersionAvailable(String version) {
    return 'Nuova versione: $version';
  }

  @override
  String get newer => 'Più recente';

  @override
  String get noNeighboursFound => 'Nessun vicino trovato';

  @override
  String get noServersFound => 'Nessun server trovato';

  @override
  String get notSet => 'Non impostato';

  @override
  String get notifications => 'Notifiche';

  @override
  String get offZeroSeconds => 'Off (0 s)';

  @override
  String get offlineMaps => 'Mappe offline';

  @override
  String get older => 'Meno recente';

  @override
  String get oneByteMode0 => '1 byte (modo 0)';

  @override
  String get oneHour => '1 ora';

  @override
  String get oneMinute => '1 minuto';

  @override
  String get openPacketLogs => 'Apri log pacchetti';

  @override
  String get packetTypeHelp => 'Guida tipi di pacchetto';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Incolla un link di condivisione o annuncio Hex';

  @override
  String get pathHash => 'Hash percorso';

  @override
  String get pathSize => 'Dimensione percorso';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Poligono';

  @override
  String get rawResponseCopied => 'Risposta grezza copiata';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Rinvia tramite il ripetitore più vicino in caso di errore';

  @override
  String get resolveContact => 'Risolvi contatto';

  @override
  String get routingRetriesAndDestinationLock =>
      'Instradamento, tentativi e blocco destinazione';

  @override
  String get samples => 'Campioni';

  @override
  String get satellites => 'Satelliti';

  @override
  String get saving => 'Salvataggio...';

  @override
  String get search => 'Cerca';

  @override
  String get searchByNameOrToken => 'Cerca per nome o token';

  @override
  String get searchDiscoveredNodes => 'Cerca nodi scoperti';

  @override
  String get searchInCurrentFilter => 'Cerca nel filtro corrente';

  @override
  String get searchLogs => 'Cerca nei log...';

  @override
  String get searchSensors => 'Cerca sensori';

  @override
  String get searchThisSection => 'Cerca in questa sezione';

  @override
  String get selectedRelays => 'Ripetitori selezionati';

  @override
  String get sensor => 'Sensore';

  @override
  String serialError(String error) {
    return 'Errore seriale: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Imposta percorso per $name';
  }

  @override
  String get shareLiveGps => 'Condividi GPS in tempo reale';

  @override
  String get shareMyTiles => 'Condividi le mie tile';

  @override
  String get sharingLocationFromPhone =>
      'Condivisione posizione su questo canale dal telefono.';

  @override
  String get sharingLocationFromRadio =>
      'Condivisione posizione su questo canale dalla radio.';

  @override
  String signalDbm(String rssi) {
    return 'Segnale $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview =>
      'Dimensione, compressione e anteprima';

  @override
  String get skip => 'Salta';

  @override
  String get smallerFileSize => 'Dimensione file ridotta';

  @override
  String get sort => 'Ordina';

  @override
  String get stoppedSharingLocation =>
      'Condivisione posizione interrotta su questo canale.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Disattiva notifiche quando l\'app è in primo piano';

  @override
  String get tabsAndNavigation => 'Schede e navigazione';

  @override
  String get templatesAndTutorials => 'Modelli e tutorial';

  @override
  String get tenMinutes => '10 minuti';

  @override
  String get tenSeconds => '10 secondi';

  @override
  String get testSendUpdate => 'Prova invio aggiornamento';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Tema, lingua e preferenze di visualizzazione';

  @override
  String get thirtyMinutes => '30 minuti';

  @override
  String get thirtySeconds => '30 secondi';

  @override
  String get threeBytesMode2 => '3 byte (modo 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Statistiche traffico, cronologia messaggi e strumenti sviluppatore';

  @override
  String get twoBytesMode1 => '2 byte (modo 1)';

  @override
  String get twoMinutes => '2 minuti';

  @override
  String get undo => 'Annulla';

  @override
  String get updated => 'Aggiornato';

  @override
  String get useContactFlags => 'Usa flag contatti';

  @override
  String get useSavedCoordinates => 'Usa coordinate salvate';

  @override
  String get view => 'Visualizza';

  @override
  String get viewNeighbours => 'Visualizza vicini';

  @override
  String get viewPublicStats => 'Visualizza statistiche pubbliche';

  @override
  String get setRegionScope => 'Imposta ambito regionale';

  @override
  String get regionScope => 'Ambito regionale';

  @override
  String get regionScopeNone => 'Nessuno (globale)';

  @override
  String get clearRegionScope => 'Cancella ambito';

  @override
  String get regionScopeWarning =>
      'Solo i ripetitori che consentono questa regione inoltreranno.';

  @override
  String get discoverRegions => 'Scopri dai ripetitori';

  @override
  String get discoveringRegions => 'Scoperta delle regioni...';

  @override
  String get enterRegionName => 'Nome regione (es. auckland)';

  @override
  String get noRegionsFound => 'Nessuna regione trovata su questo ripetitore.';

  @override
  String regionScopeSet(String name) {
    return 'Ambito regionale impostato su $name';
  }

  @override
  String get regionScopeCleared => 'Ambito regionale cancellato';
}
