// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Messages';

  @override
  String get contacts => 'Contacts';

  @override
  String get map => 'Carte';

  @override
  String get settings => 'Paramètres';

  @override
  String get connect => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get scanningForDevices => 'Recherche d\'appareils...';

  @override
  String get noDevicesFound => 'Aucun appareil trouvé';

  @override
  String get scanAgain => 'Rechercher à nouveau';

  @override
  String get tapToConnect => 'Appuyez pour connecter';

  @override
  String get deviceNotConnected => 'Appareil non connecté';

  @override
  String get locationPermissionDenied => 'Permission de localisation refusée';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permission de localisation définitivement refusée. Veuillez l\'activer dans les Paramètres.';

  @override
  String get locationPermissionRequired =>
      'La permission de localisation est requise pour le suivi GPS et la coordination d\'équipe. Vous pouvez l\'activer plus tard dans les Paramètres.';

  @override
  String get locationServicesDisabled =>
      'Les services de localisation sont désactivés. Veuillez les activer dans les Paramètres.';

  @override
  String get failedToGetGpsLocation =>
      'Échec de l\'obtention de la position GPS';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Annoncé à $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Échec de l\'annonce : $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Reconnexion... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Annuler la reconnexion';

  @override
  String get mapManagement => 'Gestion des cartes';

  @override
  String get general => 'Général';

  @override
  String get theme => 'Thème';

  @override
  String get chooseTheme => 'Choisir le thème';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get blueLightTheme => 'Thème bleu clair';

  @override
  String get blueDarkTheme => 'Thème bleu sombre';

  @override
  String get sarRed => 'SAR Rouge';

  @override
  String get alertEmergencyMode => 'Mode alerte/urgence';

  @override
  String get sarGreen => 'SAR Vert';

  @override
  String get safeAllClearMode => 'Mode sécurisé/dégagé';

  @override
  String get autoSystem => 'Auto (Système)';

  @override
  String get followSystemTheme => 'Suivre le thème du système';

  @override
  String get showRxTxIndicators => 'Afficher les indicateurs RX/TX';

  @override
  String get displayPacketActivity =>
      'Afficher les indicateurs d\'activité des paquets dans la barre supérieure';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get english => 'Anglais';

  @override
  String get slovenian => 'Slovène';

  @override
  String get croatian => 'Croate';

  @override
  String get locationBroadcasting => 'Diffusion de position';

  @override
  String get autoLocationTracking => 'Suivi automatique de position';

  @override
  String get automaticallyBroadcastPosition =>
      'Diffuser automatiquement les mises à jour de position';

  @override
  String get configureTracking => 'Configurer le suivi';

  @override
  String get distanceAndTimeThresholds => 'Seuils de distance et de temps';

  @override
  String get locationTrackingConfiguration =>
      'Configuration du suivi de position';

  @override
  String get configureWhenLocationBroadcasts =>
      'Configurer quand les diffusions de position sont envoyées au réseau maillé';

  @override
  String get minimumDistance => 'Distance minimale';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Diffuser uniquement après un déplacement de $distance mètres';
  }

  @override
  String get maximumDistance => 'Distance maximale';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Toujours diffuser après un déplacement de $distance mètres';
  }

  @override
  String get minimumTimeInterval => 'Intervalle de temps minimal';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Toujours diffuser toutes les $duration';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get about => 'À propos';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get appName => 'Nom de l\'application';

  @override
  String get aboutMeshCoreSar => 'À propos de MeshCore SAR';

  @override
  String get aboutDescription =>
      'Une application de recherche et sauvetage conçue pour les équipes d\'intervention d\'urgence. Les fonctionnalités incluent :\n\n• Réseau maillé BLE pour communication appareil à appareil\n• Cartes hors ligne avec options de couches multiples\n• Suivi en temps réel des membres de l\'équipe\n• Marqueurs tactiques SAR (personne trouvée, feu, zone de rassemblement)\n• Gestion des contacts et messagerie\n• Suivi GPS avec cap du compas\n• Mise en cache des tuiles de carte pour utilisation hors ligne';

  @override
  String get technologiesUsed => 'Technologies utilisées :';

  @override
  String get technologiesList =>
      '• Flutter pour le développement multiplateforme\n• BLE (Bluetooth Low Energy) pour réseau maillé\n• OpenStreetMap pour la cartographie\n• Provider pour la gestion d\'état\n• SharedPreferences pour le stockage local';

  @override
  String get developer => 'Développeur';

  @override
  String get packageName => 'Nom du package';

  @override
  String get sampleData => 'Données d\'exemple';

  @override
  String get sampleDataDescription =>
      'Charger ou effacer les contacts d\'exemple, les messages de canal et les marqueurs SAR pour les tests';

  @override
  String get loadSampleData => 'Charger des données d\'exemple';

  @override
  String get clearAllData => 'Effacer toutes les données';

  @override
  String get clearAllDataConfirmTitle => 'Effacer toutes les données';

  @override
  String get clearAllDataConfirmMessage =>
      'Cela effacera tous les contacts et marqueurs SAR. Êtes-vous sûr ?';

  @override
  String get clear => 'Effacer';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Chargé $teamCount membres d\'équipe, $channelCount canaux, $sarCount marqueurs SAR, $messageCount messages';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Échec du chargement des données d\'exemple : $error';
  }

  @override
  String get allDataCleared => 'Toutes les données effacées';

  @override
  String get failedToStartBackgroundTracking =>
      'Échec du démarrage du suivi en arrière-plan. Vérifiez les permissions et la connexion BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Diffusion de position : $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Le code PIN par défaut pour les appareils sans écran est 123456. Problèmes d\'appairage ? Oubliez l\'appareil Bluetooth dans les paramètres système.';

  @override
  String get noMessagesYet => 'Aucun message pour le moment';

  @override
  String get pullDownToSync =>
      'Tirez vers le bas pour synchroniser les messages';

  @override
  String get deleteContact => 'Supprimer le contact';

  @override
  String get delete => 'Supprimer';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get refresh => 'Actualiser';

  @override
  String get sendDirectMessage => 'Envoyer un message direct';

  @override
  String get resetPath => 'Réinitialiser le chemin (Re-router)';

  @override
  String get publicKeyCopied => 'Clé publique copiée dans le presse-papiers';

  @override
  String copiedToClipboard(String label) {
    return '$label copié dans le presse-papiers';
  }

  @override
  String get pleaseEnterPassword => 'Veuillez saisir un mot de passe';

  @override
  String failedToSyncContacts(String error) {
    return 'Échec de la synchronisation des contacts : $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Connexion réussie ! En attente des messages du salon...';

  @override
  String get loginFailed => 'Échec de la connexion - mot de passe incorrect';

  @override
  String loggingIn(String roomName) {
    return 'Connexion à $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Échec de l\'envoi de la connexion : $error';
  }

  @override
  String get lowLocationAccuracy => 'Précision de localisation faible';

  @override
  String get continue_ => 'Continuer';

  @override
  String get sendSarMarker => 'Envoyer un marqueur SAR';

  @override
  String get deleteDrawing => 'Supprimer le dessin';

  @override
  String get drawLine => 'Tracer une ligne';

  @override
  String get drawLineDesc => 'Tracer une ligne à main levée sur la carte';

  @override
  String get drawRectangle => 'Tracer un rectangle';

  @override
  String get drawRectangleDesc => 'Tracer une zone rectangulaire sur la carte';

  @override
  String get shareDrawings => 'Partager les dessins';

  @override
  String get clearAllDrawings => 'Effacer tous les dessins';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get noLocalDrawings => 'Aucun dessin local à partager';

  @override
  String get publicChannel => 'Canal public';

  @override
  String get broadcastToAll =>
      'Diffuser à tous les nœuds à proximité (éphémère)';

  @override
  String get storedPermanently => 'Stocké de manière permanente dans le salon';

  @override
  String get notConnectedToDevice => 'Non connecté à l\'appareil';

  @override
  String get directMessage => 'Message direct';

  @override
  String directMessageSentTo(String contactName) {
    return 'Message direct envoyé à $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'Ce message sera envoyé directement à $contactName. Il apparaîtra également dans le fil de messages principal.';
  }

  @override
  String get typeYourMessage => 'Saisissez votre message...';

  @override
  String get quickLocationMarker => 'Marqueur de position rapide';

  @override
  String get markerType => 'Type de marqueur';

  @override
  String get sendTo => 'Envoyer à';

  @override
  String get noDestinationsAvailable => 'Aucune destination disponible.';

  @override
  String get selectDestination => 'Sélectionner la destination...';

  @override
  String get ephemeralBroadcastInfo =>
      'Éphémère : Diffusion par ondes uniquement. Non stocké - les nœuds doivent être en ligne.';

  @override
  String get persistentRoomInfo =>
      'Persistant : Stocké de manière immuable dans le salon. Synchronisé automatiquement et préservé hors ligne.';

  @override
  String get location => 'Position';

  @override
  String get fromMap => 'Depuis la carte';

  @override
  String get gettingLocation => 'Obtention de la position...';

  @override
  String get locationError => 'Erreur de localisation';

  @override
  String get retry => 'Réessayer';

  @override
  String get refreshLocation => 'Actualiser la position';

  @override
  String accuracyMeters(int accuracy) {
    return 'Précision : ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notes (facultatives)';

  @override
  String get addAdditionalInformation =>
      'Ajouter des informations supplémentaires...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'La précision de localisation est de ±${accuracy}m. Cela peut ne pas être assez précis pour les opérations SAR.\n\nContinuer quand même ?';
  }

  @override
  String get loginToRoom => 'Se connecter au salon';

  @override
  String get enterPasswordInfo =>
      'Entrez le mot de passe pour accéder à ce salon. Le mot de passe sera enregistré pour une utilisation future.';

  @override
  String get password => 'Mot de passe';

  @override
  String get enterRoomPassword => 'Entrez le mot de passe du salon';

  @override
  String get loggingInDots => 'Connexion...';

  @override
  String get login => 'Se connecter';

  @override
  String failedToAddRoom(String error) {
    return 'Échec de l\'ajout du salon à l\'appareil : $error\n\nLe salon n\'a peut-être pas encore été annoncé.\nEssayez d\'attendre que le salon diffuse.';
  }

  @override
  String get direct => 'Direct';

  @override
  String get flood => 'Inondation';

  @override
  String get admin => 'Admin';

  @override
  String get loggedIn => 'Connecté';

  @override
  String get noGpsData => 'Aucune donnée GPS';

  @override
  String get distance => 'Distance';

  @override
  String pingingDirect(String name) {
    return 'Ping de $name (direct via chemin)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Ping de $name (inondation - pas de chemin)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Délai d\'attente du ping direct - nouvelle tentative de $name avec inondation...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping réussi vers $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (via repli par inondation)';

  @override
  String pingFailed(String name) {
    return 'Échec du ping vers $name - aucune réponse reçue';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?\n\nCela supprimera le contact de l\'application et de l\'appareil radio compagnon.';
  }

  @override
  String removingContact(String name) {
    return 'Suppression de $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Contact \"$name\" supprimé';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Échec de la suppression du contact : $error';
  }

  @override
  String get type => 'Type';

  @override
  String get publicKey => 'Clé publique';

  @override
  String get lastSeen => 'Dernière vue';

  @override
  String get roomStatus => 'État du salon';

  @override
  String get loginStatus => 'État de connexion';

  @override
  String get notLoggedIn => 'Non connecté';

  @override
  String get adminAccess => 'Accès administrateur';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get permissions => 'Permissions';

  @override
  String get passwordSaved => 'Mot de passe enregistré';

  @override
  String get locationColon => 'Position :';

  @override
  String get telemetry => 'Télémétrie';

  @override
  String requestingTelemetry(String name) {
    return 'Demande de télémétrie à $name...';
  }

  @override
  String get voltage => 'Tension';

  @override
  String get battery => 'Batterie';

  @override
  String get temperature => 'Température';

  @override
  String get humidity => 'Humidité';

  @override
  String get pressure => 'Pression';

  @override
  String get gpsTelemetry => 'GPS (Télémétrie)';

  @override
  String get updated => 'Mis à jour';

  @override
  String pathResetInfo(String name) {
    return 'Chemin réinitialisé pour $name. Le prochain message trouvera un nouvel itinéraire.';
  }

  @override
  String get reLoginToRoom => 'Se reconnecter au salon';

  @override
  String get heading => 'Cap';

  @override
  String get elevation => 'Élévation';

  @override
  String get accuracy => 'Précision';

  @override
  String get filterMarkers => 'Filtrer les marqueurs';

  @override
  String get filterMarkersTooltip => 'Filtrer les marqueurs';

  @override
  String get contactsFilter => 'Contacts';

  @override
  String get repeatersFilter => 'Répéteurs';

  @override
  String get sarMarkers => 'Marqueurs SAR';

  @override
  String get foundPerson => 'Personne trouvée';

  @override
  String get fire => 'Feu';

  @override
  String get stagingArea => 'Zone de rassemblement';

  @override
  String get showAll => 'Tout afficher';

  @override
  String get nearbyContacts => 'Contacts à proximité';

  @override
  String get locationUnavailable => 'Position non disponible';

  @override
  String get ahead => 'devant';

  @override
  String degreesRight(int degrees) {
    return '$degrees° à droite';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° à gauche';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat : $latitude Lon : $longitude';
  }

  @override
  String get noContactsYet => 'Aucun contact pour le moment';

  @override
  String get connectToDeviceToLoadContacts =>
      'Connectez-vous à un appareil pour charger les contacts';

  @override
  String get teamMembers => 'Membres de l\'équipe';

  @override
  String get repeaters => 'Répéteurs';

  @override
  String get rooms => 'Salons';

  @override
  String get channels => 'Canaux';

  @override
  String get cacheStatistics => 'Statistiques du cache';

  @override
  String get totalTiles => 'Total de tuiles';

  @override
  String get cacheSize => 'Taille du cache';

  @override
  String get storeName => 'Nom du magasin';

  @override
  String get noCacheStatistics => 'Aucune statistique de cache disponible';

  @override
  String get downloadRegion => 'Télécharger une région';

  @override
  String get mapLayer => 'Couche de carte';

  @override
  String get regionBounds => 'Limites de la région';

  @override
  String get north => 'Nord';

  @override
  String get south => 'Sud';

  @override
  String get east => 'Est';

  @override
  String get west => 'Ouest';

  @override
  String get zoomLevels => 'Niveaux de zoom';

  @override
  String minZoom(int zoom) {
    return 'Min : $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Max : $zoom';
  }

  @override
  String get downloadingDots => 'Téléchargement...';

  @override
  String get cancelDownload => 'Annuler le téléchargement';

  @override
  String get downloadRegionButton => 'Télécharger la région';

  @override
  String get downloadNote =>
      'Remarque : Les grandes régions ou les niveaux de zoom élevés peuvent nécessiter beaucoup de temps et d\'espace de stockage.';

  @override
  String get cacheManagement => 'Gestion du cache';

  @override
  String get clearAllMaps => 'Effacer toutes les cartes';

  @override
  String get clearMapsConfirmTitle => 'Effacer toutes les cartes';

  @override
  String get clearMapsConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer toutes les cartes téléchargées ? Cette action ne peut pas être annulée.';

  @override
  String get mapDownloadCompleted => 'Téléchargement de la carte terminé !';

  @override
  String get cacheClearedSuccessfully => 'Cache effacé avec succès !';

  @override
  String get downloadCancelled => 'Téléchargement annulé';

  @override
  String get startingDownload => 'Démarrage du téléchargement...';

  @override
  String get downloadingMapTiles => 'Téléchargement des tuiles de carte...';

  @override
  String get downloadCompletedSuccessfully =>
      'Téléchargement terminé avec succès !';

  @override
  String get cancellingDownload => 'Annulation du téléchargement...';

  @override
  String errorLoadingStats(String error) {
    return 'Erreur de chargement des statistiques : $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Échec de l\'annulation : $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Échec de l\'effacement du cache : $error';
  }

  @override
  String minZoomError(String error) {
    return 'Zoom min : $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Zoom max : $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'Le zoom minimal doit être inférieur ou égal au zoom maximal';

  @override
  String get selectMapLayer => 'Sélectionner la couche de carte';

  @override
  String get mapOptions => 'Options de carte';

  @override
  String get showLegend => 'Afficher la légende';

  @override
  String get displayMarkerTypeCounts =>
      'Afficher les décomptes des types de marqueurs';

  @override
  String get rotateMapWithHeading => 'Faire pivoter la carte avec le cap';

  @override
  String get mapFollowsDirection =>
      'La carte suit votre direction lorsque vous vous déplacez';

  @override
  String get showMapDebugInfo => 'Afficher les infos de débogage de la carte';

  @override
  String get displayZoomLevelBounds =>
      'Afficher le niveau de zoom et les limites';

  @override
  String get fullscreenMode => 'Mode plein écran';

  @override
  String get hideUiFullMapView =>
      'Masquer tous les contrôles d\'interface pour une vue de carte complète';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satellite ESRI';

  @override
  String get downloadVisibleArea => 'Télécharger la zone visible';

  @override
  String get initializingMap => 'Initialisation de la carte...';

  @override
  String get dragToPosition => 'Faire glisser vers la position';

  @override
  String get createSarMarker => 'Créer un marqueur SAR';

  @override
  String get compass => 'Boussole';

  @override
  String get navigationAndContacts => 'Navigation et contacts';

  @override
  String get sarAlert => 'ALERTE SAR';

  @override
  String get messageSentToPublicChannel => 'Message envoyé au canal public';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Veuillez sélectionner un salon pour envoyer le marqueur SAR';

  @override
  String failedToSendSarMarker(String error) {
    return 'Échec de l\'envoi du marqueur SAR : $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'Marqueur SAR envoyé à $roomName';
  }

  @override
  String get notConnectedCannotSync =>
      'Non connecté - impossible de synchroniser les messages';

  @override
  String syncedMessageCount(int count) {
    return 'Synchronisé $count message(s)';
  }

  @override
  String get noNewMessages => 'Aucun nouveau message';

  @override
  String syncFailed(String error) {
    return 'Échec de la synchronisation : $error';
  }

  @override
  String get failedToResendMessage => 'Échec du renvoi du message';

  @override
  String get retryingMessage => 'Nouvelle tentative de message...';

  @override
  String retryFailed(String error) {
    return 'Échec de la nouvelle tentative : $error';
  }

  @override
  String get textCopiedToClipboard => 'Texte copié dans le presse-papiers';

  @override
  String get cannotReplySenderMissing =>
      'Impossible de répondre : informations sur l\'expéditeur manquantes';

  @override
  String get cannotReplyContactNotFound =>
      'Impossible de répondre : contact non trouvé';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get refreshedContacts => 'Contacts actualisés';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'Il y a ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'Il y a ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'Il y a ${days}j';
  }

  @override
  String secondsAgo(int seconds) {
    return 'Il y a ${seconds}s';
  }

  @override
  String get sending => 'Envoi...';

  @override
  String get sent => 'Envoyé';

  @override
  String get delivered => 'Livré';

  @override
  String deliveredWithTime(int time) {
    return 'Livré (${time}ms)';
  }

  @override
  String get failed => 'Échec';

  @override
  String get sarMarkerFoundPerson => 'Personne trouvée';

  @override
  String get sarMarkerFire => 'Lieu de feu';

  @override
  String get sarMarkerStagingArea => 'Zone de rassemblement';

  @override
  String get sarMarkerObject => 'Objet trouvé';

  @override
  String get from => 'De';

  @override
  String get coordinates => 'Coordonnées';

  @override
  String get tapToViewOnMap => 'Appuyez pour voir sur la carte';

  @override
  String get radioSettings => 'Paramètres radio';

  @override
  String get frequencyMHz => 'Fréquence (MHz)';

  @override
  String get frequencyExample => 'ex. : 869,618';

  @override
  String get bandwidth => 'Bande passante';

  @override
  String get spreadingFactor => 'Facteur d\'étalement';

  @override
  String get codingRate => 'Taux de codage';

  @override
  String get txPowerDbm => 'Puissance TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Max : $power dBm';
  }

  @override
  String get you => 'Vous';

  @override
  String get offlineVectorMaps => 'Cartes vectorielles hors ligne';

  @override
  String get offlineVectorMapsDescription =>
      'Importer et gérer les tuiles de cartes vectorielles hors ligne (format MBTiles) pour une utilisation sans connexion Internet';

  @override
  String get importMbtiles => 'Importer un fichier MBTiles';

  @override
  String get importMbtilesNote =>
      'Prend en charge les fichiers MBTiles avec tuiles vectorielles (format PBF/MVT). Les extraits Geofabrik fonctionnent très bien !';

  @override
  String get noMbtilesFiles => 'Aucune carte vectorielle hors ligne trouvée';

  @override
  String get mbtilesImportedSuccessfully =>
      'Fichier MBTiles importé avec succès';

  @override
  String get failedToImportMbtiles =>
      'Échec de l\'importation du fichier MBTiles';

  @override
  String get deleteMbtilesConfirmTitle => 'Supprimer la carte hors ligne';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ? Cela supprimera définitivement la carte hors ligne.';
  }

  @override
  String get mbtilesDeletedSuccessfully =>
      'Carte hors ligne supprimée avec succès';

  @override
  String get failedToDeleteMbtiles =>
      'Échec de la suppression de la carte hors ligne';

  @override
  String get vectorTiles => 'Tuiles vectorielles';

  @override
  String get schema => 'Schéma';

  @override
  String get unknown => 'Inconnu';

  @override
  String get bounds => 'Limites';

  @override
  String get onlineLayers => 'Couches en ligne';

  @override
  String get offlineLayers => 'Couches hors ligne';

  @override
  String get locationTrail => 'Trace de déplacement';

  @override
  String get showTrailOnMap => 'Afficher la trace sur la carte';

  @override
  String get trailVisible => 'La trace est visible sur la carte';

  @override
  String get trailHiddenRecording =>
      'La trace est masquée (enregistrement en cours)';

  @override
  String get duration => 'Durée';

  @override
  String get points => 'Points';

  @override
  String get clearTrail => 'Effacer la trace';

  @override
  String get clearTrailQuestion => 'Effacer la trace ?';

  @override
  String get clearTrailConfirmation =>
      'Êtes-vous sûr de vouloir effacer la trace de déplacement actuelle ? Cette action ne peut pas être annulée.';

  @override
  String get noTrailRecorded => 'Aucune trace enregistrée pour le moment';

  @override
  String get startTrackingToRecord =>
      'Démarrez le suivi de position pour enregistrer votre trace';

  @override
  String get trailControls => 'Contrôles de la trace';

  @override
  String get deviceInformation => 'Informations sur l\'appareil';

  @override
  String get bleName => 'Nom BLE';

  @override
  String get meshName => 'Nom du maillage';

  @override
  String get notSet => 'Non défini';

  @override
  String get model => 'Modèle';

  @override
  String get version => 'Version';

  @override
  String get buildDate => 'Date de compilation';

  @override
  String get firmware => 'Micrologiciel';

  @override
  String get maxContacts => 'Contacts max';

  @override
  String get maxChannels => 'Canaux max';

  @override
  String get publicInfo => 'Informations publiques';

  @override
  String get meshNetworkName => 'Nom du réseau maillé';

  @override
  String get nameBroadcastInMesh => 'Nom diffusé dans les annonces du maillage';

  @override
  String get telemetryAndLocationSharing => 'Télémétrie et partage de position';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Utiliser la position actuelle';

  @override
  String get noneUnknown => 'Aucun/Inconnu';

  @override
  String get chatNode => 'Nœud de discussion';

  @override
  String get repeater => 'Répéteur';

  @override
  String get roomChannel => 'Salon/Canal';

  @override
  String typeNumber(int number) {
    return 'Type $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label copié dans le presse-papiers';
  }

  @override
  String failedToSave(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Échec de l\'obtention de la position : $error';
  }
}
