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
  String get noDevicesFound => 'Aucun appareil trouvé';

  @override
  String get scanAgain => 'Rechercher à nouveau';

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
  String failedToAdvertise(String error) {
    return 'Échec de l\'annonce : $error';
  }

  @override
  String get cancelReconnection => 'Annuler la reconnexion';

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
  String get disableMap => 'Désactiver la carte';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';

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
  String get moreInfo => 'Plus d\'infos';

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
  String get resetPath => 'Réinitialiser le chemin (Re-router)';

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
  String get drawingTools => 'Outils de Dessin';

  @override
  String get drawLine => 'Tracer une ligne';

  @override
  String get drawLineDesc => 'Tracer une ligne à main levée sur la carte';

  @override
  String get drawRectangle => 'Tracer un rectangle';

  @override
  String get drawRectangleDesc => 'Tracer une zone rectangulaire sur la carte';

  @override
  String get measureDistance => 'Mesurer la distance';

  @override
  String get measureDistanceDesc => 'Appui long sur deux points pour mesurer';

  @override
  String get clearMeasurement => 'Effacer la mesure';

  @override
  String distanceLabel(String distance) {
    return 'Distance : $distance';
  }

  @override
  String get longPressForSecondPoint => 'Appui long pour le deuxième point';

  @override
  String get longPressToStartMeasurement =>
      'Appui long pour définir le premier point';

  @override
  String get longPressToStartNewMeasurement =>
      'Appui long pour nouvelle mesure';

  @override
  String get shareDrawings => 'Partager les dessins';

  @override
  String get clearAllDrawings => 'Effacer tous les dessins';

  @override
  String get completeLine => 'Terminer la ligne';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Diffuser $count dessin$plural à l\'équipe';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Supprimer tous les $count dessin$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Supprimer tous les $count dessin$plural de la carte ?';
  }

  @override
  String get drawing => 'Dessin';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Partager $count dessin$plural';
  }

  @override
  String get showReceivedDrawings => 'Afficher les dessins reçus';

  @override
  String get showingAllDrawings => 'Affichage de tous les dessins';

  @override
  String get showingOnlyYourDrawings => 'Affichage uniquement de vos dessins';

  @override
  String get showSarMarkers => 'Afficher les marqueurs SAR';

  @override
  String get showingSarMarkers => 'Affichage des marqueurs SAR';

  @override
  String get hidingSarMarkers => 'Masquage des marqueurs SAR';

  @override
  String get clearAll => 'Tout effacer';

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
  String get autoSend => 'Envoi automatique';

  @override
  String get autoSendDescription => 'Envoyer via le chemin actuel.';

  @override
  String get sendDirect => 'Envoi direct';

  @override
  String get sendDirectDescription => 'Envoyer directement à ce contact.';

  @override
  String get sendFlood => 'Envoi par inondation';

  @override
  String get sendFloodDescription => 'Envoyer via tous les relais.';

  @override
  String get loggedIn => 'Connecté';

  @override
  String get noGpsData => 'Aucune donnée GPS';

  @override
  String get distance => 'Distance';

  @override
  String directPingTimeout(String name) {
    return 'Délai d\'attente du ping direct - nouvelle tentative de $name avec inondation...';
  }

  @override
  String pingFailed(String name) {
    return 'Échec du ping vers $name - aucune réponse reçue';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?\n\nCela supprimera le contact de l\'application et de l\'appareil radio compagnon.';
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
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get permissions => 'Permissions';

  @override
  String get telemetry => 'Télémétrie';

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
  String get reLoginToRoom => 'Se reconnecter au salon';

  @override
  String get heading => 'Cap';

  @override
  String get elevation => 'Élévation';

  @override
  String get accuracy => 'Précision';

  @override
  String get bearing => 'Relèvement';

  @override
  String get direction => 'Direction';

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
  String get selectMapLayer => 'Sélectionner la couche de carte';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satellite ESRI';

  @override
  String get googleHybrid => 'Google Hybride';

  @override
  String get googleRoadmap => 'Google Carte Routière';

  @override
  String get googleTerrain => 'Google Terrain';

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
  String get textCopiedToClipboard => 'Texte copié dans le presse-papiers';

  @override
  String get cannotReplySenderMissing =>
      'Impossible de répondre : informations sur l\'expéditeur manquantes';

  @override
  String get cannotReplyContactNotFound =>
      'Impossible de répondre : contact non trouvé';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get saveAsTemplate => 'Enregistrer comme Modèle';

  @override
  String get templateSaved => 'Modèle enregistré avec succès';

  @override
  String get templateAlreadyExists => 'Un modèle avec cet emoji existe déjà';

  @override
  String get deleteMessage => 'Supprimer le message';

  @override
  String get deleteMessageConfirmation =>
      'Êtes-vous sûr de vouloir supprimer ce message?';

  @override
  String get shareLocation => 'Partager la position';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nCoordonnées: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Position SAR';

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
  String get broadcast => 'Diffusion';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Livré à $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'Tout livré';

  @override
  String get recipientDetails => 'Détails des destinataires';

  @override
  String get pending => 'En attente';

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
  String exportFailed(String error) {
    return 'Echec de l\'exportation : $error';
  }

  @override
  String importFailed(String error) {
    return 'Echec de l\'importation : $error';
  }

  @override
  String get unknown => 'Inconnu';

  @override
  String get onlineLayers => 'Couches en ligne';

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
  String get model => 'Modèle';

  @override
  String get version => 'Version';

  @override
  String get maxContacts => 'Contacts max';

  @override
  String get maxChannels => 'Canaux max';

  @override
  String get publicInfo => 'Informations publiques';

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
  String failedToSave(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Échec de l\'obtention de la position : $error';
  }

  @override
  String get sarTemplates => 'Modèles SAR';

  @override
  String get addTemplate => 'Ajouter un modèle';

  @override
  String get editTemplate => 'Modifier le modèle';

  @override
  String get deleteTemplate => 'Supprimer le modèle';

  @override
  String get templateName => 'Nom du modèle';

  @override
  String get templateNameHint => 'p. ex. Personne trouvee';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji est requis';

  @override
  String get nameRequired => 'Nom est requis';

  @override
  String get templateDescription => 'Description (facultative)';

  @override
  String get templateDescriptionHint => 'Ajoutez un contexte supplementaire...';

  @override
  String get templateColor => 'Couleur';

  @override
  String get previewFormat => 'Apercu (format de message SAR)';

  @override
  String get importFromClipboard => 'Importer';

  @override
  String get exportToClipboard => 'Exporter';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Supprimer le modele \'$name\' ?';
  }

  @override
  String get templateAdded => 'Modele ajoute';

  @override
  String get templateUpdated => 'Modele mis a jour';

  @override
  String get templateDeleted => 'Modele supprime';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modeles importes',
      one: '1 modele importe',
      zero: 'Aucun modele importe',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modeles exportes vers le presse-papiers',
      one: '1 modele exporte vers le presse-papiers',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Réinitialiser aux valeurs par défaut';

  @override
  String get resetToDefaultsConfirmation =>
      'Cela supprimera tous les modèles personnalisés et restaurera les 4 modèles par défaut. Continuer?';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetComplete => 'Modèles réinitialisés aux valeurs par défaut';

  @override
  String get noTemplates => 'Aucun modele disponible';

  @override
  String get tapAddToCreate => 'Appuyez sur + pour creer votre premier modele';

  @override
  String get ok => 'OK';

  @override
  String get locationPermission => 'Autorisation de localisation';

  @override
  String get checking => 'Vérification...';

  @override
  String get locationPermissionGrantedAlways => 'Accordée (Toujours)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Accordée (En cours d\'utilisation)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Refusée - Appuyez pour demander';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Refusée définitivement - Ouvrir les paramètres';

  @override
  String get locationPermissionDialogContent =>
      'L\'autorisation de localisation est définitivement refusée. Veuillez l\'activer dans les paramètres de votre appareil pour utiliser le suivi GPS et le partage de localisation.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get locationPermissionGranted =>
      'Autorisation de localisation accordée !';

  @override
  String get locationPermissionRequiredForGps =>
      'L\'autorisation de localisation est nécessaire pour le suivi GPS et le partage de localisation.';

  @override
  String get locationPermissionAlreadyGranted =>
      'L\'autorisation de localisation est déjà accordée.';

  @override
  String get sarNavyBlue => 'SAR Bleu Marine';

  @override
  String get sarNavyBlueDescription => 'Mode Professionnel/Opérations';

  @override
  String get selectRecipient => 'Sélectionner le destinataire';

  @override
  String get broadcastToAllNearby => 'Diffuser à tous à proximité';

  @override
  String get searchRecipients => 'Rechercher des destinataires...';

  @override
  String get noContactsFound => 'Aucun contact trouvé';

  @override
  String get noRoomsFound => 'Aucune salle trouvée';

  @override
  String get noRecipientsAvailable => 'Aucun destinataire disponible';

  @override
  String get noChannelsFound => 'Aucun canal trouvé';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get channel => 'Canal';

  @override
  String get samplePoliceLead => 'Chef de Police';

  @override
  String get sampleDroneOperator => 'Opérateur de Drone';

  @override
  String get sampleFirefighterAlpha => 'Pompier';

  @override
  String get sampleMedicCharlie => 'Médecin';

  @override
  String get sampleCommandDelta => 'Commandement';

  @override
  String get sampleFireEngine => 'Camion de Pompiers';

  @override
  String get sampleAirSupport => 'Soutien Aérien';

  @override
  String get sampleBaseCoordinator => 'Coordinateur de Base';

  @override
  String get channelEmergency => 'Urgence';

  @override
  String get channelCoordination => 'Coordination';

  @override
  String get channelUpdates => 'Mises à jour';

  @override
  String get sampleTeamMember => 'Membre d\'Équipe Exemple';

  @override
  String get sampleScout => 'Éclaireur Exemple';

  @override
  String get sampleBase => 'Base Exemple';

  @override
  String get sampleSearcher => 'Chercheur Exemple';

  @override
  String get sampleObjectBackpack => ' Sac à dos trouvé - couleur bleue';

  @override
  String get sampleObjectVehicle =>
      ' Véhicule abandonné - vérifier le propriétaire';

  @override
  String get sampleObjectCamping => ' Équipement de camping découvert';

  @override
  String get sampleObjectTrailMarker => ' Balise de sentier trouvée hors piste';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Toutes les équipes se signaler';

  @override
  String get sampleMsgWeatherUpdate =>
      'Mise à jour météo : Ciel dégagé, temp 18°C';

  @override
  String get sampleMsgBaseCamp =>
      'Camp de base établi à la zone de rassemblement';

  @override
  String get sampleMsgTeamAlpha => 'Équipe se déplaçant vers le secteur 2';

  @override
  String get sampleMsgRadioCheck =>
      'Test radio - toutes les stations répondent';

  @override
  String get sampleMsgWaterSupply =>
      'Approvisionnement en eau disponible au point de contrôle 3';

  @override
  String get sampleMsgTeamBravo => 'Équipe signale : secteur 1 dégagé';

  @override
  String get sampleMsgEtaRallyPoint =>
      'ETA au point de ralliement : 15 minutes';

  @override
  String get sampleMsgSupplyDrop =>
      'Largage de ravitaillement confirmé pour 14h00';

  @override
  String get sampleMsgDroneSurvey =>
      'Surveillance par drone terminée - aucune découverte';

  @override
  String get sampleMsgTeamCharlie => 'Équipe demande du renfort';

  @override
  String get sampleMsgRadioDiscipline =>
      'Toutes les unités : maintenir la discipline radio';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENT : Assistance médicale nécessaire au secteur 4';

  @override
  String get sampleMsgAdultMale => ' Homme adulte, conscient';

  @override
  String get sampleMsgFireSpotted => 'Feu repéré - coordonnées à venir';

  @override
  String get sampleMsgSpreadingRapidly => ' Se propage rapidement !';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITÉ : Besoin de soutien hélicoptère';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Équipe médicale en route vers votre position';

  @override
  String get sampleMsgEvacHelicopter =>
      'Hélicoptère d\'évacuation ETA 10 minutes';

  @override
  String get sampleMsgEmergencyResolved => 'Urgence résolue - tout est clair';

  @override
  String get sampleMsgEmergencyStagingArea =>
      ' Zone de rassemblement d\'urgence';

  @override
  String get sampleMsgEmergencyServices =>
      'Services d\'urgence notifiés et en réponse';

  @override
  String get sampleAlphaTeamLead => 'Chef d\'Équipe';

  @override
  String get sampleBravoScout => 'Éclaireur';

  @override
  String get sampleCharlieMedic => 'Médecin';

  @override
  String get sampleDeltaNavigator => 'Navigateur';

  @override
  String get sampleEchoSupport => 'Soutien';

  @override
  String get sampleBaseCommand => 'Commandement de Base';

  @override
  String get sampleFieldCoordinator => 'Coordinateur de Terrain';

  @override
  String get sampleMedicalTeam => 'Équipe Médicale';

  @override
  String get mapDrawing => 'Dessin de Carte';

  @override
  String get navigateToDrawing => 'Naviguer vers le Dessin';

  @override
  String get copyCoordinates => 'Copier les Coordonnées';

  @override
  String get hideFromMap => 'Masquer de la Carte';

  @override
  String get lineDrawing => 'Ligne';

  @override
  String get rectangleDrawing => 'Rectangle';

  @override
  String get manualCoordinates => 'Coordonnées Manuelles';

  @override
  String get enterCoordinatesManually => 'Entrer les coordonnées manuellement';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get exampleCoordinates => 'Exemple: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Partager le Dessin';

  @override
  String get shareWithAllNearbyDevices =>
      'Partager avec tous les appareils à proximité';

  @override
  String get shareToRoom => 'Partager dans la Salle';

  @override
  String get sendToPersistentStorage =>
      'Envoyer au stockage persistant de la salle';

  @override
  String get deleteDrawingConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce dessin?';

  @override
  String get drawingDeleted => 'Dessin supprimé';

  @override
  String yourDrawingsCount(int count) {
    return 'Vos Dessins ($count)';
  }

  @override
  String get shared => 'Partagé';

  @override
  String get line => 'Ligne';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get updateAvailable => 'Mise à Jour Disponible';

  @override
  String get currentVersion => 'Actuelle';

  @override
  String get latestVersion => 'Dernière';

  @override
  String get downloadUpdate => 'Télécharger';

  @override
  String get updateLater => 'Plus Tard';

  @override
  String get cadastralParcels => 'Parcelles Cadastrales';

  @override
  String get forestRoads => 'Chemins Forestiers';

  @override
  String get wmsOverlays => 'Superpositions WMS';

  @override
  String get hikingTrails => 'Sentiers de Randonnée';

  @override
  String get mainRoads => 'Routes Principales';

  @override
  String get houseNumbers => 'Numéros de Maison';

  @override
  String get fireHazardZones => 'Zones à Risque d\'Incendie';

  @override
  String get historicalFires => 'Incendies Historiques';

  @override
  String get firebreaks => 'Coupe-feu';

  @override
  String get krasFireZones => 'Zones d\'Incendie Kras';

  @override
  String get placeNames => 'Noms de Lieux';

  @override
  String get municipalityBorders => 'Limites Municipales';

  @override
  String get topographicMap => 'Carte Topographique 1:25000';

  @override
  String get recentMessages => 'Messages Récents';

  @override
  String get addChannel => 'Ajouter un Canal';

  @override
  String get channelName => 'Nom du Canal';

  @override
  String get channelNameHint => 'par ex. Équipe de Sauvetage Alpha';

  @override
  String get channelSecret => 'Mot de Passe du Canal';

  @override
  String get channelSecretHint => 'Mot de passe partagé pour ce canal';

  @override
  String get channelSecretHelp =>
      'Ce mot de passe doit être partagé avec tous les membres de l\'équipe qui ont besoin d\'accéder à ce canal';

  @override
  String get channelTypesInfo =>
      'Canaux hash (#équipe) : Mot de passe généré automatiquement à partir du nom. Même nom = même canal sur tous les appareils.\n\nCanaux privés : Utilisez un mot de passe explicite. Seuls ceux qui ont le mot de passe peuvent rejoindre.';

  @override
  String get hashChannelInfo =>
      'Canal hash : Le mot de passe sera automatiquement généré à partir du nom du canal. Toute personne utilisant le même nom rejoindra le même canal.';

  @override
  String get channelNameRequired => 'Le nom du canal est requis';

  @override
  String get channelNameTooLong =>
      'Le nom du canal doit contenir 31 caractères ou moins';

  @override
  String get channelSecretRequired => 'Le mot de passe du canal est requis';

  @override
  String get channelSecretTooLong =>
      'Le mot de passe du canal doit contenir 32 caractères ou moins';

  @override
  String get invalidAsciiCharacters =>
      'Seuls les caractères ASCII sont autorisés';

  @override
  String get channelCreatedSuccessfully => 'Canal créé avec succès';

  @override
  String channelCreationFailed(String error) {
    return 'Échec de la création du canal : $error';
  }

  @override
  String get deleteChannel => 'Supprimer le Canal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Êtes-vous sûr de vouloir supprimer le canal \"$channelName\" ? Cette action ne peut pas être annulée.';
  }

  @override
  String get channelDeletedSuccessfully => 'Canal supprimé avec succès';

  @override
  String channelDeletionFailed(String error) {
    return 'Échec de la suppression du canal : $error';
  }

  @override
  String get createChannel => 'Créer un Canal';

  @override
  String get wizardBack => 'Retour';

  @override
  String get wizardSkip => 'Passer';

  @override
  String get wizardNext => 'Suivant';

  @override
  String get wizardGetStarted => 'Commencer';

  @override
  String get wizardWelcomeTitle => 'Bienvenue dans MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Voir le tutoriel de bienvenue';

  @override
  String get allTeamContacts => 'Tous les contacts de l\'équipe';

  @override
  String directMessagesInfo(int count) {
    return 'Messages directs avec confirmations. Envoyé à $count membres de l\'équipe.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Marqueur SAR envoyé à $count contacts';
  }

  @override
  String get noContactsAvailable => 'Aucun contact d\'équipe disponible';

  @override
  String get reply => 'Répondre';

  @override
  String get technicalDetails => 'Détails techniques';

  @override
  String get messageTechnicalDetails => 'Détails techniques du message';

  @override
  String get linkQuality => 'Qualité du lien';

  @override
  String get delivery => 'Livraison';

  @override
  String get status => 'Statut';

  @override
  String get expectedAckTag => 'Balise ACK attendue';

  @override
  String get roundTrip => 'Aller-retour';

  @override
  String get retryAttempt => 'Tentative de renvoi';

  @override
  String get floodFallback => 'Repli inondation';

  @override
  String get identity => 'Identité';

  @override
  String get messageId => 'ID du message';

  @override
  String get sender => 'Expéditeur';

  @override
  String get senderKey => 'Clé de l\'expéditeur';

  @override
  String get recipient => 'Destinataire';

  @override
  String get recipientKey => 'Clé du destinataire';

  @override
  String get voice => 'Voix';

  @override
  String get voiceId => 'ID vocal';

  @override
  String get envelope => 'Enveloppe';

  @override
  String get sessionProgress => 'Progression de session';

  @override
  String get complete => 'Complet';

  @override
  String get rawDump => 'Vidage brut';

  @override
  String get cannotRetryMissingRecipient =>
      'Impossible de réessayer : informations du destinataire manquantes';

  @override
  String get voiceUnavailable => 'Voix indisponible pour le moment';

  @override
  String get requestingVoice => 'Demande de voix';

  @override
  String get device => 'appareil';

  @override
  String get change => 'Modifier';

  @override
  String get wizardOverviewDescription =>
      'Cette application réunit la messagerie MeshCore, les mises à jour SAR sur le terrain, la cartographie et les outils de l\'appareil au même endroit.';

  @override
  String get wizardOverviewFeature1 =>
      'Envoyez des messages directs, des publications de salon et des messages de canal depuis l\'onglet principal Messages.';

  @override
  String get wizardOverviewFeature2 =>
      'Partagez des marqueurs SAR, des dessins de carte, des extraits vocaux et des images sur le réseau maillé.';

  @override
  String get wizardOverviewFeature3 =>
      'Connectez-vous en BLE ou en TCP, puis gérez la radio compagnon directement dans l\'application.';

  @override
  String get wizardMessagingTitle => 'Messagerie et rapports de terrain';

  @override
  String get wizardMessagingDescription =>
      'Ici, les messages sont plus que du texte brut. L\'application prend déjà en charge plusieurs charges opérationnelles et flux de transfert.';

  @override
  String get wizardMessagingFeature1 =>
      'Envoyez des messages directs, des publications de salon et du trafic de canal depuis un seul compositeur.';

  @override
  String get wizardMessagingFeature2 =>
      'Créez des mises à jour SAR et des modèles SAR réutilisables pour les rapports de terrain courants.';

  @override
  String get wizardMessagingFeature3 =>
      'Transférez des sessions vocales et des images avec la progression et les estimations de temps d\'antenne dans l\'interface.';

  @override
  String get wizardConnectDeviceTitle => 'Connecter l\'appareil';

  @override
  String get wizardConnectDeviceDescription =>
      'Connectez votre radio MeshCore, choisissez un nom et appliquez un préréglage radio avant de continuer.';

  @override
  String get wizardSetupBadge => 'Configuration';

  @override
  String get wizardOverviewBadge => 'Aperçu';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Connecté à $deviceName';
  }

  @override
  String get wizardNoDeviceConnected =>
      'Aucun appareil connecté pour le moment';

  @override
  String get wizardSkipForNow => 'Ignorer pour l\'instant';

  @override
  String get wizardDeviceNameLabel => 'Nom de l\'appareil';

  @override
  String get wizardDeviceNameHelp =>
      'Ce nom est annoncé aux autres utilisateurs de MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Région de configuration';

  @override
  String get wizardConfigRegionHelp =>
      'Utilise la liste officielle complète des préréglages MeshCore. La valeur par défaut est EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Assurez-vous que le préréglage sélectionné correspond à votre réglementation radio locale.';

  @override
  String get wizardPresetNote2 =>
      'La liste correspond au flux officiel des préréglages de l\'outil de configuration MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) reste sélectionné par défaut pendant l\'onboarding.';

  @override
  String get wizardSaving => 'Enregistrement...';

  @override
  String get wizardSaveAndContinue => 'Enregistrer et continuer';

  @override
  String get wizardEnterDeviceName =>
      'Saisissez un nom d\'appareil avant de continuer.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '$deviceName enregistré avec $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contacts, salons et répéteurs';

  @override
  String get wizardNetworkDescription =>
      'L\'onglet Contacts organise le réseau que vous découvrez et les routes apprises au fil du temps.';

  @override
  String get wizardNetworkFeature1 =>
      'Consultez les membres de l\'équipe, les répéteurs, les salons, les canaux et les annonces en attente dans une seule liste.';

  @override
  String get wizardNetworkFeature2 =>
      'Utilisez le smart ping, la connexion aux salons, les chemins appris et les outils de réinitialisation des routes lorsque la connectivité devient chaotique.';

  @override
  String get wizardNetworkFeature3 =>
      'Créez des canaux et gérez les destinations réseau sans quitter l\'application.';

  @override
  String get wizardMapOpsTitle => 'Carte, traces et géométrie partagée';

  @override
  String get wizardMapOpsDescription =>
      'La carte de l\'application est directement liée à la messagerie, au suivi et aux couches SAR au lieu d\'être un simple visualiseur séparé.';

  @override
  String get wizardMapOpsFeature1 =>
      'Suivez votre position, celles de vos coéquipiers et les traces de déplacement sur la carte.';

  @override
  String get wizardMapOpsFeature2 =>
      'Ouvrez les dessins depuis les messages, prévisualisez-les en ligne et supprimez-les de la carte si nécessaire.';

  @override
  String get wizardMapOpsFeature3 =>
      'Utilisez les vues de carte des répéteurs et les couches partagées pour comprendre la portée du réseau sur le terrain.';

  @override
  String get wizardToolsTitle => 'Outils au-delà de la messagerie';

  @override
  String get wizardToolsDescription =>
      'Il y a plus ici que les quatre onglets principaux. L\'application inclut aussi la configuration, le diagnostic et des workflows de capteurs optionnels.';

  @override
  String get wizardToolsFeature1 =>
      'Ouvrez la configuration de l\'appareil pour modifier les réglages radio, la télémétrie, la puissance TX et les détails du compagnon.';

  @override
  String get wizardToolsFeature2 =>
      'Activez l\'onglet Capteurs lorsque vous voulez des tableaux de bord surveillés et des actions d\'actualisation rapide.';

  @override
  String get wizardToolsFeature3 =>
      'Utilisez les journaux de paquets, le balayage du spectre et les diagnostics développeur pour dépanner le réseau maillé.';

  @override
  String get postConnectDiscoveryTitle => 'Découvrir les relais maintenant ?';

  @override
  String get postConnectDiscoveryDescription =>
      'Lancer la découverte des relais juste après la connexion pour voir les nœuds MeshCore à proximité et les ajouter plus rapidement à votre réseau.';

  @override
  String get contactInSensors => 'Dans Capteurs';

  @override
  String get contactAddToSensors => 'Ajouter aux capteurs';

  @override
  String get contactSetPath => 'Définir le chemin';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName ajouté aux capteurs';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Échec de l\'effacement de la route : $error';
  }

  @override
  String get contactRouteCleared => 'Route effacée';

  @override
  String contactRouteSet(String route) {
    return 'Route définie : $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Échec du réglage de la route : $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Délai ACK expiré';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Charge utile';

  @override
  String get hops => 'Sauts';

  @override
  String get hashSize => 'Taille du hash';

  @override
  String get pathBytes => 'Octets du chemin';

  @override
  String get selectedPath => 'Chemin sélectionné';

  @override
  String get estimatedTx => 'Émission estimée';

  @override
  String get senderToReceipt => 'Émetteur au reçu';

  @override
  String get receivedCopies => 'Copies reçues';

  @override
  String get retryCause => 'Cause de la relance';

  @override
  String get retryMode => 'Mode de relance';

  @override
  String get retryResult => 'Résultat de la relance';

  @override
  String get lastRetry => 'Dernière relance';

  @override
  String get rxPackets => 'Paquets RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Débit';

  @override
  String get window => 'Fenêtre';

  @override
  String get posttxDelay => 'Délai post-émission';

  @override
  String get bandpass => 'Passe-bande';

  @override
  String get bandpassFilterVoice => 'Filtre passe-bande voix';

  @override
  String get active => 'Actif';

  @override
  String get addContact => 'Ajouter un contact';

  @override
  String get all => 'Tout';

  @override
  String get clearAllLabel => 'Tout effacer';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get clearRoute => 'Effacer la route';

  @override
  String get clearMessages => 'Effacer les messages';

  @override
  String get clearScale => 'Effacer l\'échelle';

  @override
  String get clearDiscoveries => 'Effacer les découvertes';

  @override
  String get clearOnlineTraceDatabase => 'Effacer la base de traces';

  @override
  String get clearAllChannels => 'Effacer tous les canaux';

  @override
  String get clearAllContacts => 'Effacer tous les contacts';

  @override
  String get clearChannels => 'Effacer les canaux';

  @override
  String get clearContacts => 'Effacer les contacts';

  @override
  String get clearPathOnMaxRetry => 'Effacer le chemin au max de relances';

  @override
  String get create => 'Créer';

  @override
  String get custom => 'Personnalisé';

  @override
  String get defaultValue => 'Par défaut';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get editName => 'Modifier le nom';

  @override
  String get open => 'Ouvrir';

  @override
  String get paste => 'Coller';

  @override
  String get preview => 'Aperçu';

  @override
  String get remove => 'Supprimer';

  @override
  String get rename => 'Renommer';

  @override
  String get resolveAll => 'Résoudre tout';

  @override
  String get send => 'Envoyer';

  @override
  String get sendAnyway => 'Envoyer quand même';

  @override
  String get share => 'Partager';

  @override
  String get trace => 'Trace';

  @override
  String get discovery => 'Découverte';

  @override
  String get discoverRepeaters => 'Découvrir les répéteurs';

  @override
  String get discoverSensors => 'Découvrir les capteurs';

  @override
  String get repeaterDiscoverySent => 'Découverte de répéteurs envoyée';

  @override
  String get sensorDiscoverySent => 'Découverte de capteurs envoyée';

  @override
  String get clearedPendingDiscoveries => 'Découvertes en attente effacées.';

  @override
  String get autoDiscovery => 'Découverte automatique';

  @override
  String get enableAutomaticAdding => 'Activer l\'ajout automatique';

  @override
  String get autoaddRepeaters => 'Ajout auto des répéteurs';

  @override
  String get autoaddRoomServers => 'Ajout auto des serveurs de salle';

  @override
  String get autoaddSensors => 'Ajout auto des capteurs';

  @override
  String get autoaddUsers => 'Ajout auto des utilisateurs';

  @override
  String get overwriteOldestWhenFull => 'Écraser les plus anciens si plein';

  @override
  String get storage => 'Stockage';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get profiles => 'Profils';

  @override
  String get favourites => 'Favoris';

  @override
  String get sensors => 'Capteurs';

  @override
  String get others => 'Autres';

  @override
  String get gpsModule => 'Module GPS';

  @override
  String get liveTraffic => 'Trafic en direct';

  @override
  String get repeatersMap => 'Carte des répéteurs';

  @override
  String get blePacketLogs => 'Journaux de paquets BLE';

  @override
  String get onlineTraceDatabase => 'Base de données de traces';

  @override
  String get routePathByteSize => 'Taille en octets du chemin';

  @override
  String get messageNotifications => 'Notifications de messages';

  @override
  String get sarAlerts => 'Alertes SAR';

  @override
  String get discoveryNotifications => 'Notifications de découverte';

  @override
  String get updateNotifications => 'Notifications de mise à jour';

  @override
  String get muteWhileAppIsOpen => 'Muet quand l\'appli est ouverte';

  @override
  String get disableContacts => 'Désactiver les contacts';

  @override
  String get enableSensorsTab => 'Activer l\'onglet Capteurs';

  @override
  String get enableProfiles => 'Activer les profils';

  @override
  String get nearestRepeaterFallback => 'Répéteur le plus proche en repli';

  @override
  String get deleteAllStoredMessageHistory => 'Supprimer tout l\'historique';

  @override
  String get messageFontSize => 'Taille de police des messages';

  @override
  String get rotateMapWithHeading => 'Tourner la carte avec le cap';

  @override
  String get showMapDebugInfo => 'Afficher les infos de débogage';

  @override
  String get openMapInFullscreen => 'Ouvrir la carte en plein écran';

  @override
  String get showSarMarkersLabel => 'Afficher les marqueurs SAR';

  @override
  String get hideRepeatersOnMap => 'Masquer les répéteurs sur la carte';

  @override
  String get setMapScale => 'Définir l\'échelle de la carte';

  @override
  String get customMapScaleSaved =>
      'Échelle de carte personnalisée enregistrée';

  @override
  String get voiceBitrate => 'Débit vocal';

  @override
  String get voiceCompressor => 'Compresseur vocal';

  @override
  String get voiceLimiter => 'Limiteur vocal';

  @override
  String get micAutoGain => 'Gain auto du micro';

  @override
  String get echoCancellation => 'Annulation d\'écho';

  @override
  String get noiseSuppression => 'Suppression du bruit';

  @override
  String get trimSilenceInVoiceMessages =>
      'Couper le silence dans les messages vocaux';

  @override
  String get compressor => 'Compresseur';

  @override
  String get limiter => 'Limiteur';

  @override
  String get autoGain => 'Gain automatique';

  @override
  String get echoCancel => 'Écho';

  @override
  String get noiseSuppress => 'Bruit';

  @override
  String get silenceTrim => 'Silence';

  @override
  String get maxImageSize => 'Taille d\'image maximale';

  @override
  String get imageCompression => 'Compression d\'image';

  @override
  String get grayscale => 'Niveaux de gris';

  @override
  String get ultraMode => 'Mode ultra';

  @override
  String get fastPrivateGpsUpdates => 'Mises à jour GPS privées rapides';

  @override
  String get movementThreshold => 'Seuil de mouvement';

  @override
  String get fastGpsMovementThreshold => 'Seuil de mouvement GPS rapide';

  @override
  String get fastGpsActiveuseInterval =>
      'Intervalle d\'utilisation active GPS rapide';

  @override
  String get activeuseUpdateInterval =>
      'Intervalle de mise à jour en utilisation active';

  @override
  String get repeatNearbyTraffic => 'Répéter le trafic proche';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Relayer via les répéteurs du réseau';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Proximité seulement, sans inondation';

  @override
  String get multihop => 'Multi-saut';

  @override
  String get createProfile => 'Créer un profil';

  @override
  String get renameProfile => 'Renommer le profil';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get manageProfiles => 'Gérer les profils';

  @override
  String get enableProfilesToStartManagingThem =>
      'Activez les profils pour commencer à les gérer.';

  @override
  String get openMessage => 'Ouvrir le message';

  @override
  String get jumpToTheRelatedSarMessage => 'Aller au message SAR associé';

  @override
  String get removeSarMarker => 'Supprimer le marqueur SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Sélectionnez une destination pour envoyer le marqueur';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Marqueur SAR diffusé sur le canal public';

  @override
  String get sarMarkerSentToRoom => 'Marqueur SAR envoyé à la salle';

  @override
  String get loadFromGallery => 'Charger depuis la galerie';

  @override
  String get replaceImage => 'Remplacer l\'image';

  @override
  String get selectFromGallery => 'Sélectionner depuis la galerie';

  @override
  String get team => 'Équipe';

  @override
  String get found => 'Trouvé';

  @override
  String get staging => 'Zone de regroupement';

  @override
  String get object => 'Objet';

  @override
  String get quiet => 'Calme';

  @override
  String get busy => 'Occupé';

  @override
  String get searchMessages => 'Rechercher des messages';

  @override
  String get sendImageFromGallery => 'Envoyer une image de la galerie';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get allMessages => 'Tous les messages';

  @override
  String get sendToPublicChannel => 'Envoyer au canal public ?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Sélectionnez le type de marqueur et la destination';

  @override
  String get noDestinationsAvailableLabel => 'Aucune destination disponible';

  @override
  String get image => 'Image';

  @override
  String get format => 'Format';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get segments => 'Segments';

  @override
  String get transfers => 'Transferts';

  @override
  String get downloadedBy => 'Téléchargé par';

  @override
  String get saveDiscoverySettings =>
      'Enregistrer les paramètres de découverte';

  @override
  String get savePublicInfo => 'Enregistrer les infos publiques';

  @override
  String get saveRadioSettings => 'Enregistrer les paramètres radio';

  @override
  String get savePath => 'Enregistrer le chemin';

  @override
  String get wipeDeviceData => 'Effacer les données de l\'appareil';

  @override
  String get wipeDevice => 'Effacer l\'appareil';

  @override
  String get destructiveDeviceActions => 'Actions destructives de l\'appareil.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Choisissez un préréglage ou ajustez les paramètres radio.';

  @override
  String get used => 'Utilisé';

  @override
  String get total => 'Total';

  @override
  String get renameValue => 'Renommer la valeur';

  @override
  String get customizeFields => 'Personnaliser les champs';

  @override
  String get livePreview => 'Aperçu en direct';

  @override
  String get refreshSchedule => 'Planification d\'actualisation';

  @override
  String get noResponse => 'Pas de réponse';

  @override
  String get refreshing => 'Actualisation';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Choisissez un relais ou nœud à surveiller.';

  @override
  String get publicKeyLabel => 'Clé publique';

  @override
  String get alreadyInContacts => 'Déjà dans les contacts';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Connectez-vous à un appareil avant d\'ajouter des contacts';

  @override
  String get fromContacts => 'Des contacts';

  @override
  String get onlineOnly => 'En ligne uniquement';

  @override
  String get inBoth => 'Dans les deux';

  @override
  String get source => 'Source';

  @override
  String get allMessagesCleared => 'Tous les messages effacés';

  @override
  String get onlineTraceDatabaseCleared => 'Base de données de traces effacée';

  @override
  String get packetLogsCleared => 'Journaux de paquets effacés';

  @override
  String get hexDataCopiedToClipboard =>
      'Données hex copiées dans le presse-papiers';

  @override
  String get developerModeEnabled => 'Mode développeur activé';

  @override
  String get developerModeDisabled => 'Mode développeur désactivé';

  @override
  String get clipboardIsEmpty => 'Le presse-papiers est vide';

  @override
  String get contactImported => 'Contact importé';

  @override
  String get contactLinkCopiedToClipboard =>
      'Lien du contact copié dans le presse-papiers';

  @override
  String get failedToExportContact => 'Échec de l\'exportation du contact';

  @override
  String get noLogsToExport => 'Aucun journal à exporter';

  @override
  String get exportAsCsv => 'Exporter en CSV';

  @override
  String get exportAsText => 'Exporter en texte';

  @override
  String get receivedRfc3339 => 'Reçu (RFC3339)';

  @override
  String get buildTime => 'Heure de build';

  @override
  String get downloadUrlNotAvailable => 'URL de téléchargement non disponible';

  @override
  String get cannotOpenDownloadUrl =>
      'Impossible d\'ouvrir l\'URL de téléchargement';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'La vérification des mises à jour n\'est disponible que sur Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Vous utilisez la dernière version';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Mise à jour disponible mais URL de téléchargement introuvable';

  @override
  String get startTictactoe => 'Démarrer Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe indisponible';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: adversaire inconnu';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: en attente du début';

  @override
  String get acceptsShareLinks => 'Accepte les liens partagés';

  @override
  String get supportsRawHex => 'Supporte le hex brut';

  @override
  String get clipboardfriendly => 'Compatible avec le presse-papiers';

  @override
  String get captured => 'Capturé';

  @override
  String get size => 'Taille';

  @override
  String get noCustomChannelsToClear => 'Aucun canal personnalisé à effacer.';

  @override
  String get noDeviceContactsToClear =>
      'Aucun contact de l\'appareil à effacer.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Ajouter';

  @override
  String get addAdditionalDetails => 'Ajouter des détails supplémentaires';

  @override
  String get addPeer => 'Ajouter un pair';

  @override
  String get addPeerManually => 'Ajouter un pair manuellement';

  @override
  String addedToContacts(String name) {
    return '$name ajouté aux contacts';
  }

  @override
  String addedToSensors(String name) {
    return '$name ajouté aux capteurs';
  }

  @override
  String get allowAll => 'Tout autoriser';

  @override
  String get anonymousRxStats => 'Statistiques RX anonymes';

  @override
  String get appearance => 'Apparence';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Télémétrie de base';

  @override
  String get blePin => 'PIN BLE';

  @override
  String get buzzerAlerts => 'Alertes sonores';

  @override
  String get cancelImageReceive => 'Annuler la réception d\'image';

  @override
  String get choose => 'Choisir';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Choisir les onglets et sections de contacts à afficher';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get clearLiveView => 'Effacer la vue en direct';

  @override
  String get clearLogs => 'Effacer les journaux';

  @override
  String get clearOfflineCache => 'Vider le cache hors ligne ?';

  @override
  String get clearOverlay => 'Effacer la superposition';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Effacer la route uniquement après l\'échec de toutes les tentatives';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Codec, débit et traitement audio';

  @override
  String get connectByIpAddress => 'Connexion par adresse IP';

  @override
  String get controlWhichAlertsYouReceive =>
      'Contrôler les alertes que vous recevez';

  @override
  String get copyFullHex => 'Copier le Hex complet';

  @override
  String get copyRawResponse => 'Copier la réponse brute';

  @override
  String get couldNotLoadMetHistory =>
      'Impossible de charger l\'historique MET';

  @override
  String customizeSensor(String name) {
    return 'Personnaliser $name';
  }

  @override
  String get data => 'Données';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String deleteStyleConfirm(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Supprimer ce $type ?';
  }

  @override
  String get deny => 'Refuser';

  @override
  String get deviceInfo => 'Infos de l\'appareil';

  @override
  String get deviceSettings => 'Paramètres de l\'appareil';

  @override
  String get deviceTimeSynced =>
      'Heure de l\'appareil synchronisée avec ce téléphone.';

  @override
  String get disableFastGpsPublishing => 'Désactiver la publication GPS rapide';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Affichage, marqueurs et base de données de traces';

  @override
  String get download => 'Télécharger';

  @override
  String get environmentalTelemetry => 'Télémétrie environnementale';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Erreur lors de la vérification des mises à jour : $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Erreur lors de l\'ouverture du téléchargement : $error';
  }

  @override
  String get exportLogs => 'Exporter les journaux';

  @override
  String get extraAggressiveAvifCompression =>
      'Compression AVIF extra-agressive';

  @override
  String failedToAddContact(String error) {
    return 'Échec de l\'ajout du contact : $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Échec de l\'ajout de $name : $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Échec de l\'effacement des canaux : $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Échec de l\'effacement des contacts : $error';
  }

  @override
  String get failedToConnectViaSerial => 'Échec de la connexion via série';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Échec du chargement de l\'aperçu : $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Échec du chargement de la trace : $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Échec de l\'envoi du marqueur SAR : $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Échec du réglage du mode buzzer : $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Échec du réglage du mode GPS : $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Échec de la synchronisation de l\'heure de l\'appareil : $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Échec de l\'effacement des données de l\'appareil : $error';
  }

  @override
  String get fastGpsTargetChannel => 'Canal cible GPS rapide';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Mises à jour rapides, seuils et permissions';

  @override
  String get fetchingCatalog => 'Récupération du catalogue...';

  @override
  String get fifteenMinutes => '15 minutes';

  @override
  String get fifteenSeconds => '15 secondes';

  @override
  String get filterByDirection => 'Filtrer par direction';

  @override
  String get finish => 'Terminer';

  @override
  String get fiveMinutes => '5 minutes';

  @override
  String get fiveSeconds => '5 secondes';

  @override
  String get fix => 'Correctif';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Politique d\'annonce GPS';

  @override
  String get gpsAndLocation => 'GPS et localisation';

  @override
  String get gpsDiagnostics => 'Diagnostics GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Aide';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Masqué';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Comment la radio ajoute automatiquement les nœuds découverts.';

  @override
  String get images => 'Images';

  @override
  String get importProfile => 'Importer un profil';

  @override
  String get lastFix => 'Dernier correctif';

  @override
  String get latest => 'Le plus récent';

  @override
  String get latitude => 'Latitude';

  @override
  String get loadASavedRegion => 'Charger une région enregistrée';

  @override
  String get loading => 'Chargement';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Partage de position, matériel et intervalle de mise à jour.';

  @override
  String get locationTelemetry => 'Télémétrie de position';

  @override
  String get lockDestination => 'Verrouiller la destination';

  @override
  String get longitude => 'Longitude';

  @override
  String get mapStyle => 'Style de carte';

  @override
  String get max => 'Max';

  @override
  String get maxZoom => 'Zoom max';

  @override
  String get messaging => 'Messagerie';

  @override
  String get metHistory => 'Historique MET';

  @override
  String get min => 'Min';

  @override
  String get minZoom => 'Zoom min';

  @override
  String get moveDown => 'Déplacer vers le bas';

  @override
  String get moveUp => 'Déplacer vers le haut';

  @override
  String get multiAckMode => 'Mode multi-ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Gestion d\'espace de travail multi-appareils';

  @override
  String get myLocation => 'Ma position';

  @override
  String get nameAndTelemetryShared =>
      'Nom et télémétrie partagés avec d\'autres appareils.';

  @override
  String newVersionAvailable(String version) {
    return 'Nouvelle version : $version';
  }

  @override
  String get newer => 'Plus récent';

  @override
  String get noNeighboursFound => 'Aucun voisin trouvé';

  @override
  String get noServersFound => 'Aucun serveur trouvé';

  @override
  String get notSet => 'Non défini';

  @override
  String get notifications => 'Notifications';

  @override
  String get offZeroSeconds => 'Désactivé (0 s)';

  @override
  String get offlineMaps => 'Cartes hors ligne';

  @override
  String get older => 'Plus ancien';

  @override
  String get oneByteMode0 => '1 octet (mode 0)';

  @override
  String get oneHour => '1 heure';

  @override
  String get oneMinute => '1 minute';

  @override
  String get openPacketLogs => 'Ouvrir les journaux de paquets';

  @override
  String get packetTypeHelp => 'Aide sur les types de paquets';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Coller un lien de partage ou une annonce hex';

  @override
  String get pathHash => 'Hash du chemin';

  @override
  String get pathSize => 'Taille du chemin';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Polygone';

  @override
  String get rawResponseCopied => 'Réponse brute copiée';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Renvoyer via le répéteur le plus proche en cas d\'échec';

  @override
  String get resolveContact => 'Résoudre le contact';

  @override
  String get routingRetriesAndDestinationLock =>
      'Routage, tentatives et verrouillage de destination';

  @override
  String get samples => 'Échantillons';

  @override
  String get satellites => 'Satellites';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get search => 'Rechercher';

  @override
  String get searchByNameOrToken => 'Rechercher par nom ou jeton';

  @override
  String get searchDiscoveredNodes => 'Rechercher les nœuds découverts';

  @override
  String get searchInCurrentFilter => 'Rechercher dans le filtre actuel';

  @override
  String get searchLogs => 'Rechercher dans les journaux...';

  @override
  String get searchSensors => 'Rechercher les capteurs';

  @override
  String get searchThisSection => 'Rechercher dans cette section';

  @override
  String get selectedRelays => 'Relais sélectionnés';

  @override
  String get sensor => 'Capteur';

  @override
  String serialError(String error) {
    return 'Erreur série : $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Définir le chemin pour $name';
  }

  @override
  String get shareLiveGps => 'Partager le GPS en direct';

  @override
  String get shareMyTiles => 'Partager mes tuiles';

  @override
  String get sharingLocationFromPhone =>
      'Partage de la position sur ce canal depuis le téléphone.';

  @override
  String get sharingLocationFromRadio =>
      'Partage de la position sur ce canal depuis la radio.';

  @override
  String signalDbm(String rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview => 'Taille, compression et aperçu';

  @override
  String get skip => 'Passer';

  @override
  String get smallerFileSize => 'Taille de fichier réduite';

  @override
  String get sort => 'Trier';

  @override
  String get stoppedSharingLocation =>
      'Arrêt du partage de position sur ce canal.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Supprimer les notifications en premier plan';

  @override
  String get tabsAndNavigation => 'Onglets et navigation';

  @override
  String get templatesAndTutorials => 'Modèles et tutoriels';

  @override
  String get tenMinutes => '10 minutes';

  @override
  String get tenSeconds => '10 secondes';

  @override
  String get testSendUpdate => 'Tester l\'envoi de mise à jour';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Thème, langue et préférences d\'affichage';

  @override
  String get thirtyMinutes => '30 minutes';

  @override
  String get thirtySeconds => '30 secondes';

  @override
  String get threeBytesMode2 => '3 octets (mode 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Statistiques de trafic, historique des messages et outils de développement';

  @override
  String get twoBytesMode1 => '2 octets (mode 1)';

  @override
  String get twoMinutes => '2 minutes';

  @override
  String get undo => 'Annuler';

  @override
  String get updated => 'Mis à jour';

  @override
  String get useContactFlags => 'Utiliser les drapeaux de contact';

  @override
  String get useSavedCoordinates => 'Utiliser les coordonnées enregistrées';

  @override
  String get view => 'Voir';

  @override
  String get viewNeighbours => 'Voir les voisins';

  @override
  String get viewPublicStats => 'Voir les statistiques publiques';

  @override
  String get setRegionScope => 'Définir la portée régionale';

  @override
  String get regionScope => 'Portée régionale';

  @override
  String get regionScopeNone => 'Aucune (globale)';

  @override
  String get clearRegionScope => 'Effacer la portée';

  @override
  String get regionScopeWarning =>
      'Seuls les relais autorisant cette région retransmettront.';

  @override
  String get discoverRegions => 'Découvrir depuis les relais';

  @override
  String get discoveringRegions => 'Découverte des régions...';

  @override
  String get enterRegionName => 'Nom de région (ex. auckland)';

  @override
  String get noRegionsFound => 'Aucune région trouvée sur ce relais.';

  @override
  String regionScopeSet(String name) {
    return 'Portée régionale définie sur $name';
  }

  @override
  String get regionScopeCleared => 'Portée régionale effacée';
}
