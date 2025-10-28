// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Mensajes';

  @override
  String get contacts => 'Contactos';

  @override
  String get map => 'Mapa';

  @override
  String get settings => 'Configuración';

  @override
  String get connect => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get scanningForDevices => 'Buscando dispositivos...';

  @override
  String get noDevicesFound => 'No se encontraron dispositivos';

  @override
  String get scanAgain => 'Buscar de nuevo';

  @override
  String get tapToConnect => 'Toca para conectar';

  @override
  String get deviceNotConnected => 'Dispositivo no conectado';

  @override
  String get locationPermissionDenied => 'Permiso de ubicación denegado';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permiso de ubicación denegado permanentemente. Por favor, actívalo en Configuración.';

  @override
  String get locationPermissionRequired =>
      'El permiso de ubicación es necesario para el seguimiento GPS y la coordinación del equipo. Puedes activarlo más tarde en Configuración.';

  @override
  String get locationServicesDisabled =>
      'Los servicios de ubicación están desactivados. Por favor, actívalos en Configuración.';

  @override
  String get failedToGetGpsLocation => 'Error al obtener la ubicación GPS';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return 'Anunciado en $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return 'Error al anunciar: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return 'Reconectando... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => 'Cancelar reconexión';

  @override
  String get mapManagement => 'Gestión de mapas';

  @override
  String get general => 'General';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Elegir tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get blueLightTheme => 'Tema azul claro';

  @override
  String get blueDarkTheme => 'Tema azul oscuro';

  @override
  String get sarRed => 'SAR Rojo';

  @override
  String get alertEmergencyMode => 'Modo de alerta/emergencia';

  @override
  String get sarGreen => 'SAR Verde';

  @override
  String get safeAllClearMode => 'Modo seguro/todo despejado';

  @override
  String get autoSystem => 'Auto (Sistema)';

  @override
  String get followSystemTheme => 'Seguir el tema del sistema';

  @override
  String get showRxTxIndicators => 'Mostrar indicadores RX/TX';

  @override
  String get displayPacketActivity =>
      'Mostrar indicadores de actividad de paquetes en la barra superior';

  @override
  String get simpleMode => 'Modo Simple';

  @override
  String get simpleModeDescription =>
      'Ocultar información no esencial en mensajes y contactos';

  @override
  String get language => 'Idioma';

  @override
  String get chooseLanguage => 'Elegir idioma';

  @override
  String get english => 'Inglés';

  @override
  String get slovenian => 'Esloveno';

  @override
  String get croatian => 'Croata';

  @override
  String get german => 'Alemán';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Francés';

  @override
  String get italian => 'Italiano';

  @override
  String get locationBroadcasting => 'Difusión de ubicación';

  @override
  String get autoLocationTracking => 'Seguimiento automático de ubicación';

  @override
  String get automaticallyBroadcastPosition =>
      'Difundir automáticamente actualizaciones de posición';

  @override
  String get configureTracking => 'Configurar seguimiento';

  @override
  String get distanceAndTimeThresholds => 'Umbrales de distancia y tiempo';

  @override
  String get locationTrackingConfiguration =>
      'Configuración de seguimiento de ubicación';

  @override
  String get configureWhenLocationBroadcasts =>
      'Configurar cuándo se envían difusiones de ubicación a la red mesh';

  @override
  String get minimumDistance => 'Distancia mínima';

  @override
  String broadcastAfterMoving(String distance) {
    return 'Difundir solo después de moverse $distance metros';
  }

  @override
  String get maximumDistance => 'Distancia máxima';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return 'Siempre difundir después de moverse $distance metros';
  }

  @override
  String get minimumTimeInterval => 'Intervalo de tiempo mínimo';

  @override
  String alwaysBroadcastEvery(String duration) {
    return 'Siempre difundir cada $duration';
  }

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get about => 'Acerca de';

  @override
  String get appVersion => 'Versión de la aplicación';

  @override
  String get appName => 'Nombre de la aplicación';

  @override
  String get aboutMeshCoreSar => 'Acerca de MeshCore SAR';

  @override
  String get aboutDescription =>
      'Una aplicación de Búsqueda y Rescate diseñada para equipos de respuesta a emergencias. Las características incluyen:\n\n• Red mesh BLE para comunicación entre dispositivos\n• Mapas sin conexión con múltiples opciones de capas\n• Seguimiento en tiempo real de miembros del equipo\n• Marcadores tácticos SAR (persona encontrada, fuego, zona de preparación)\n• Gestión de contactos y mensajería\n• Seguimiento GPS con rumbo de brújula\n• Caché de teselas de mapa para uso sin conexión';

  @override
  String get technologiesUsed => 'Tecnologías utilizadas:';

  @override
  String get technologiesList =>
      '• Flutter para desarrollo multiplataforma\n• BLE (Bluetooth Low Energy) para redes mesh\n• OpenStreetMap para mapas\n• Provider para gestión de estado\n• SharedPreferences para almacenamiento local';

  @override
  String get moreInfo => 'Más información';

  @override
  String get learnMoreAbout => 'Más información sobre MeshCore SAR';

  @override
  String get developer => 'Desarrollador';

  @override
  String get packageName => 'Nombre del paquete';

  @override
  String get sampleData => 'Datos de muestra';

  @override
  String get sampleDataDescription =>
      'Cargar o borrar contactos de muestra, mensajes de canal y marcadores SAR para pruebas';

  @override
  String get loadSampleData => 'Cargar datos de muestra';

  @override
  String get clearAllData => 'Borrar todos los datos';

  @override
  String get clearAllDataConfirmTitle => 'Borrar todos los datos';

  @override
  String get clearAllDataConfirmMessage =>
      'Esto borrará todos los contactos y marcadores SAR. ¿Estás seguro?';

  @override
  String get clear => 'Borrar';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Cargados $teamCount miembros del equipo, $channelCount canales, $sarCount marcadores SAR, $messageCount mensajes';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Error al cargar datos de muestra: $error';
  }

  @override
  String get allDataCleared => 'Todos los datos borrados';

  @override
  String get failedToStartBackgroundTracking =>
      'Error al iniciar el seguimiento en segundo plano. Verifica los permisos y la conexión BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Difusión de ubicación: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'El PIN predeterminado para dispositivos sin pantalla es 123456. ¿Problemas para emparejar? Olvida el dispositivo bluetooth en la configuración del sistema.';

  @override
  String get noMessagesYet => 'Aún no hay mensajes';

  @override
  String get pullDownToSync => 'Desliza hacia abajo para sincronizar mensajes';

  @override
  String get deleteContact => 'Eliminar contacto';

  @override
  String get delete => 'Eliminar';

  @override
  String get viewOnMap => 'Ver en el mapa';

  @override
  String get refresh => 'Actualizar';

  @override
  String get sendDirectMessage => 'Enviar';

  @override
  String get resetPath => 'Restablecer ruta (Re-enrutar)';

  @override
  String get publicKeyCopied => 'Clave pública copiada al portapapeles';

  @override
  String copiedToClipboard(String label) {
    return '$label copiado al portapapeles';
  }

  @override
  String get pleaseEnterPassword => 'Por favor, introduce una contraseña';

  @override
  String failedToSyncContacts(String error) {
    return 'Error al sincronizar contactos: $error';
  }

  @override
  String get loggedInSuccessfully =>
      '¡Inicio de sesión exitoso! Esperando mensajes de la sala...';

  @override
  String get loginFailed => 'Error de inicio de sesión - contraseña incorrecta';

  @override
  String loggingIn(String roomName) {
    return 'Iniciando sesión en $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Error al enviar inicio de sesión: $error';
  }

  @override
  String get lowLocationAccuracy => 'Baja precisión de ubicación';

  @override
  String get continue_ => 'Continuar';

  @override
  String get sendSarMarker => 'Enviar marcador SAR';

  @override
  String get deleteDrawing => 'Eliminar dibujo';

  @override
  String get drawingTools => 'Herramientas de Dibujo';

  @override
  String get drawLine => 'Dibujar línea';

  @override
  String get drawLineDesc => 'Dibujar una línea a mano alzada en el mapa';

  @override
  String get drawRectangle => 'Dibujar rectángulo';

  @override
  String get drawRectangleDesc => 'Dibujar un área rectangular en el mapa';

  @override
  String get measureDistance => 'Medir distancia';

  @override
  String get measureDistanceDesc =>
      'Presión prolongada en dos puntos para medir';

  @override
  String get clearMeasurement => 'Borrar medición';

  @override
  String distanceLabel(String distance) {
    return 'Distancia: $distance';
  }

  @override
  String get longPressForSecondPoint =>
      'Presión prolongada para el segundo punto';

  @override
  String get longPressToStartMeasurement =>
      'Presión prolongada para establecer el primer punto';

  @override
  String get longPressToStartNewMeasurement =>
      'Presión prolongada para nueva medición';

  @override
  String get shareDrawings => 'Compartir dibujos';

  @override
  String get clearAllDrawings => 'Borrar todos los dibujos';

  @override
  String get completeLine => 'Completar línea';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Transmitir $count dibujo$plural al equipo';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Eliminar todos los $count dibujo$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return '¿Eliminar todos los $count dibujo$plural del mapa?';
  }

  @override
  String get drawing => 'Dibujo';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Compartir $count dibujo$plural';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return 'Enviados $count dibujo$plural de mapa a $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return 'Compartidos $success/$total dibujo$plural con $roomName';
  }

  @override
  String get showReceivedDrawings => 'Mostrar dibujos recibidos';

  @override
  String get showingAllDrawings => 'Mostrando todos los dibujos';

  @override
  String get showingOnlyYourDrawings => 'Mostrando solo tus dibujos';

  @override
  String get showSarMarkers => 'Mostrar marcadores SAR';

  @override
  String get showingSarMarkers => 'Mostrando marcadores SAR';

  @override
  String get hidingSarMarkers => 'Ocultando marcadores SAR';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get noLocalDrawings => 'No hay dibujos locales para compartir';

  @override
  String get publicChannel => 'Canal público';

  @override
  String get broadcastToAll => 'Difundir a todos los nodos cercanos (efímero)';

  @override
  String get storedPermanently => 'Almacenado permanentemente en la sala';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return '$count dibujo$plural de mapa enviado al Canal Público';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return '$success/$total dibujos compartidos al Canal Público';
  }

  @override
  String get notConnectedToDevice => 'No conectado al dispositivo';

  @override
  String get directMessage => 'Mensaje directo';

  @override
  String directMessageSentTo(String contactName) {
    return 'Mensaje directo enviado a $contactName';
  }

  @override
  String failedToSend(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String directMessageInfo(String contactName) {
    return 'Este mensaje se enviará directamente a $contactName. También aparecerá en el feed de mensajes principal.';
  }

  @override
  String get typeYourMessage => 'Escribe tu mensaje...';

  @override
  String get quickLocationMarker => 'Marcador de ubicación rápida';

  @override
  String get markerType => 'Tipo de marcador';

  @override
  String get sendTo => 'Enviar a';

  @override
  String get noDestinationsAvailable => 'No hay destinos disponibles.';

  @override
  String get selectDestination => 'Seleccionar destino...';

  @override
  String get ephemeralBroadcastInfo =>
      'Efímero: Solo difusión por el aire. No se almacena - los nodos deben estar en línea.';

  @override
  String get persistentRoomInfo =>
      'Persistente: Almacenado de manera inmutable en la sala. Se sincroniza automáticamente y se conserva sin conexión.';

  @override
  String get location => 'Ubicación';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get fromMap => 'Desde el mapa';

  @override
  String get gettingLocation => 'Obteniendo ubicación...';

  @override
  String get locationError => 'Error de ubicación';

  @override
  String get retry => 'Reintentar';

  @override
  String get refreshLocation => 'Actualizar ubicación';

  @override
  String accuracyMeters(int accuracy) {
    return 'Precisión: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get addAdditionalInformation => 'Agregar información adicional...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'La precisión de la ubicación es ±${accuracy}m. Esto puede no ser lo suficientemente preciso para operaciones SAR.\n\n¿Continuar de todos modos?';
  }

  @override
  String get loginToRoom => 'Iniciar sesión en la sala';

  @override
  String get enterPasswordInfo =>
      'Introduce la contraseña para acceder a esta sala. La contraseña se guardará para uso futuro.';

  @override
  String get password => 'Contraseña';

  @override
  String get enterRoomPassword => 'Introduce la contraseña de la sala';

  @override
  String get loggingInDots => 'Iniciando sesión...';

  @override
  String get login => 'Iniciar sesión';

  @override
  String failedToAddRoom(String error) {
    return 'Error al agregar la sala al dispositivo: $error\n\nLa sala puede no haber anunciado aún.\nIntenta esperar a que la sala transmita.';
  }

  @override
  String get direct => 'Directo';

  @override
  String get flood => 'Inundación';

  @override
  String get admin => 'Admin';

  @override
  String get loggedIn => 'Sesión iniciada';

  @override
  String get noGpsData => 'Sin datos GPS';

  @override
  String get distance => 'Distancia';

  @override
  String pingingDirect(String name) {
    return 'Haciendo ping a $name (directo vía ruta)...';
  }

  @override
  String pingingFlood(String name) {
    return 'Haciendo ping a $name (inundación - sin ruta)...';
  }

  @override
  String directPingTimeout(String name) {
    return 'Tiempo de espera de ping directo agotado - reintentando $name con inundación...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return 'Ping exitoso a $name$fallback';
  }

  @override
  String get viaFloodingFallback => ' (vía respaldo de inundación)';

  @override
  String pingFailed(String name) {
    return 'Ping fallido a $name - no se recibió respuesta';
  }

  @override
  String deleteContactConfirmation(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?\n\nEsto eliminará el contacto tanto de la aplicación como del dispositivo de radio compañero.';
  }

  @override
  String removingContact(String name) {
    return 'Eliminando $name...';
  }

  @override
  String contactRemoved(String name) {
    return 'Contacto \"$name\" eliminado';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Error al eliminar contacto: $error';
  }

  @override
  String get type => 'Tipo';

  @override
  String get publicKey => 'Clave pública';

  @override
  String get lastSeen => 'Visto por última vez';

  @override
  String get roomStatus => 'Estado de la sala';

  @override
  String get loginStatus => 'Estado de inicio de sesión';

  @override
  String get notLoggedIn => 'No ha iniciado sesión';

  @override
  String get adminAccess => 'Acceso de administrador';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permisos';

  @override
  String get passwordSaved => 'Contraseña guardada';

  @override
  String get locationColon => 'Ubicación:';

  @override
  String get telemetry => 'Telemetría';

  @override
  String requestingTelemetry(String name) {
    return 'Solicitando telemetría de $name...';
  }

  @override
  String get voltage => 'Voltaje';

  @override
  String get battery => 'Batería';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Humedad';

  @override
  String get pressure => 'Presión';

  @override
  String get gpsTelemetry => 'GPS (Telemetría)';

  @override
  String get updated => 'Actualizado';

  @override
  String pathResetInfo(String name) {
    return 'Ruta restablecida para $name. El próximo mensaje encontrará una nueva ruta.';
  }

  @override
  String get reLoginToRoom => 'Re-iniciar sesión en la sala';

  @override
  String get heading => 'Rumbo';

  @override
  String get elevation => 'Elevación';

  @override
  String get accuracy => 'Precisión';

  @override
  String get bearing => 'Rumbo';

  @override
  String get direction => 'Dirección';

  @override
  String get filterMarkers => 'Filtrar marcadores';

  @override
  String get filterMarkersTooltip => 'Filtrar marcadores';

  @override
  String get contactsFilter => 'Contactos';

  @override
  String get repeatersFilter => 'Repetidores';

  @override
  String get sarMarkers => 'Marcadores SAR';

  @override
  String get foundPerson => 'Persona encontrada';

  @override
  String get fire => 'Fuego';

  @override
  String get stagingArea => 'Área de preparación';

  @override
  String get showAll => 'Mostrar todo';

  @override
  String get nearbyContacts => 'Contactos cercanos';

  @override
  String get locationUnavailable => 'Ubicación no disponible';

  @override
  String get ahead => 'adelante';

  @override
  String degreesRight(int degrees) {
    return '$degrees° derecha';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° izquierda';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Aún no hay contactos';

  @override
  String get connectToDeviceToLoadContacts =>
      'Conéctate a un dispositivo para cargar contactos';

  @override
  String get teamMembers => 'Miembros del equipo';

  @override
  String get repeaters => 'Repetidores';

  @override
  String get rooms => 'Salas';

  @override
  String get channels => 'Canales';

  @override
  String get cacheStatistics => 'Estadísticas de caché';

  @override
  String get totalTiles => 'Total de teselas';

  @override
  String get cacheSize => 'Tamaño de caché';

  @override
  String get storeName => 'Nombre del almacén';

  @override
  String get noCacheStatistics => 'No hay estadísticas de caché disponibles';

  @override
  String get downloadRegion => 'Descargar región';

  @override
  String get mapLayer => 'Capa de mapa';

  @override
  String get regionBounds => 'Límites de región';

  @override
  String get north => 'Norte';

  @override
  String get south => 'Sur';

  @override
  String get east => 'Este';

  @override
  String get west => 'Oeste';

  @override
  String get zoomLevels => 'Niveles de zoom';

  @override
  String minZoom(int zoom) {
    return 'Mín: $zoom';
  }

  @override
  String maxZoom(int zoom) {
    return 'Máx: $zoom';
  }

  @override
  String get downloadingDots => 'Descargando...';

  @override
  String get cancelDownload => 'Cancelar descarga';

  @override
  String get downloadRegionButton => 'Descargar región';

  @override
  String get downloadNote =>
      'Nota: Las regiones grandes o niveles de zoom altos pueden tomar un tiempo y espacio de almacenamiento significativos.';

  @override
  String get cacheManagement => 'Gestión de caché';

  @override
  String get clearAllMaps => 'Borrar todos los mapas';

  @override
  String get clearMapsConfirmTitle => 'Borrar todos los mapas';

  @override
  String get clearMapsConfirmMessage =>
      '¿Estás seguro de que quieres eliminar todos los mapas descargados? Esta acción no se puede deshacer.';

  @override
  String get mapDownloadCompleted => '¡Descarga de mapa completada!';

  @override
  String get cacheClearedSuccessfully => '¡Caché borrada exitosamente!';

  @override
  String get downloadCancelled => 'Descarga cancelada';

  @override
  String get startingDownload => 'Iniciando descarga...';

  @override
  String get downloadingMapTiles => 'Descargando teselas de mapa...';

  @override
  String get downloadCompletedSuccessfully =>
      '¡Descarga completada exitosamente!';

  @override
  String get cancellingDownload => 'Cancelando descarga...';

  @override
  String errorLoadingStats(String error) {
    return 'Error al cargar estadísticas: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String cancelFailed(String error) {
    return 'Error al cancelar: $error';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Error al borrar caché: $error';
  }

  @override
  String minZoomError(String error) {
    return 'Zoom mín: $error';
  }

  @override
  String maxZoomError(String error) {
    return 'Zoom máx: $error';
  }

  @override
  String get minZoomGreaterThanMax =>
      'El zoom mínimo debe ser menor o igual al zoom máximo';

  @override
  String get selectMapLayer => 'Seleccionar capa de mapa';

  @override
  String get mapOptions => 'Opciones de mapa';

  @override
  String get showLegend => 'Mostrar leyenda';

  @override
  String get displayMarkerTypeCounts =>
      'Mostrar recuentos de tipos de marcadores';

  @override
  String get rotateMapWithHeading => 'Rotar mapa con rumbo';

  @override
  String get mapFollowsDirection =>
      'El mapa sigue tu dirección cuando te mueves';

  @override
  String get resetMapRotation => 'Restablecer rotación';

  @override
  String get resetMapRotationTooltip => 'Restablecer mapa al norte';

  @override
  String get showMapDebugInfo => 'Mostrar información de depuración del mapa';

  @override
  String get displayZoomLevelBounds => 'Mostrar nivel de zoom y límites';

  @override
  String get fullscreenMode => 'Modo de pantalla completa';

  @override
  String get hideUiFullMapView =>
      'Ocultar todos los controles de IU para vista de mapa completo';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Satélite';

  @override
  String get googleHybrid => 'Google Híbrido';

  @override
  String get googleRoadmap => 'Google Mapa de Carreteras';

  @override
  String get googleTerrain => 'Google Terreno';

  @override
  String get downloadVisibleArea => 'Descargar área visible';

  @override
  String get initializingMap => 'Inicializando mapa...';

  @override
  String get dragToPosition => 'Arrastrar a posición';

  @override
  String get createSarMarker => 'Crear marcador SAR';

  @override
  String get compass => 'Brújula';

  @override
  String get navigationAndContacts => 'Navegación y contactos';

  @override
  String get sarAlert => 'ALERTA SAR';

  @override
  String get messageSentToPublicChannel => 'Mensaje enviado al canal público';

  @override
  String get pleaseSelectRoomToSendSar =>
      'Por favor, selecciona una sala para enviar marcador SAR';

  @override
  String failedToSendSarMarker(String error) {
    return 'Error al enviar marcador SAR: $error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return 'Marcador SAR enviado a $roomName';
  }

  @override
  String get notConnectedCannotSync =>
      'No conectado - no se pueden sincronizar mensajes';

  @override
  String syncedMessageCount(int count) {
    return 'Sincronizados $count mensaje(s)';
  }

  @override
  String get noNewMessages => 'No hay mensajes nuevos';

  @override
  String syncFailed(String error) {
    return 'Error de sincronización: $error';
  }

  @override
  String get failedToResendMessage => 'Error al reenviar mensaje';

  @override
  String get retryingMessage => 'Reintentando mensaje...';

  @override
  String retryFailed(String error) {
    return 'Error de reintento: $error';
  }

  @override
  String get textCopiedToClipboard => 'Texto copiado al portapapeles';

  @override
  String get cannotReplySenderMissing =>
      'No se puede responder: falta información del remitente';

  @override
  String get cannotReplyContactNotFound =>
      'No se puede responder: contacto no encontrado';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get saveAsTemplate => 'Guardar como Plantilla';

  @override
  String get templateSaved => 'Plantilla guardada exitosamente';

  @override
  String get templateAlreadyExists => 'Ya existe una plantilla con este emoji';

  @override
  String get deleteMessage => 'Eliminar mensaje';

  @override
  String get deleteMessageConfirmation =>
      '¿Está seguro de que desea eliminar este mensaje?';

  @override
  String get shareLocation => 'Compartir ubicación';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nCoordenadas: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Ubicación SAR';

  @override
  String get locationShared => 'Ubicación compartida';

  @override
  String get refreshedContacts => 'Contactos actualizados';

  @override
  String get justNow => 'Justo ahora';

  @override
  String minutesAgo(int minutes) {
    return 'Hace ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'Hace ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'Hace ${days}d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'Hace ${seconds}s';
  }

  @override
  String get sending => 'Enviando...';

  @override
  String get sent => 'Enviado';

  @override
  String get delivered => 'Entregado';

  @override
  String deliveredWithTime(int time) {
    return 'Entregado (${time}ms)';
  }

  @override
  String get failed => 'Fallido';

  @override
  String get broadcast => 'Difusión';

  @override
  String get sarMarkerFoundPerson => 'Persona encontrada';

  @override
  String get sarMarkerFire => 'Ubicación de fuego';

  @override
  String get sarMarkerStagingArea => 'Área de preparación';

  @override
  String get sarMarkerObject => 'Objeto encontrado';

  @override
  String get from => 'De';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get tapToViewOnMap => 'Toca para ver en el mapa';

  @override
  String get radioSettings => 'Configuración de radio';

  @override
  String get frequencyMHz => 'Frecuencia (MHz)';

  @override
  String get frequencyExample => 'ej., 869.618';

  @override
  String get bandwidth => 'Ancho de banda';

  @override
  String get spreadingFactor => 'Factor de dispersión';

  @override
  String get codingRate => 'Tasa de codificación';

  @override
  String get txPowerDbm => 'Potencia TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Máx: $power dBm';
  }

  @override
  String get you => 'Tú';

  @override
  String get offlineVectorMaps => 'Mapas vectoriales sin conexión';

  @override
  String get offlineVectorMapsDescription =>
      'Importar y gestionar teselas de mapas vectoriales sin conexión (formato MBTiles) para usar sin conexión a internet';

  @override
  String get importMbtiles => 'Importar archivo MBTiles';

  @override
  String get importMbtilesNote =>
      'Compatible con archivos MBTiles con teselas vectoriales (formato PBF/MVT). ¡Los extractos de Geofabrik funcionan muy bien!';

  @override
  String get noMbtilesFiles =>
      'No se encontraron mapas vectoriales sin conexión';

  @override
  String get mbtilesImportedSuccessfully =>
      'Archivo MBTiles importado exitosamente';

  @override
  String get failedToImportMbtiles => 'Error al importar archivo MBTiles';

  @override
  String get deleteMbtilesConfirmTitle => 'Eliminar mapa sin conexión';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"? Esto eliminará permanentemente el mapa sin conexión.';
  }

  @override
  String get mbtilesDeletedSuccessfully =>
      'Mapa sin conexión eliminado exitosamente';

  @override
  String get failedToDeleteMbtiles => 'Error al eliminar mapa sin conexión';

  @override
  String get importExportCachedTiles => 'Importar/Exportar teselas en caché';

  @override
  String get importExportDescription =>
      'Realice copias de seguridad, comparta y restaure teselas de mapas descargadas entre dispositivos';

  @override
  String get exportTilesToFile => 'Exportar teselas a archivo';

  @override
  String get importTilesFromFile => 'Importar teselas desde archivo';

  @override
  String get selectExportLocation => 'Seleccionar ubicación de exportación';

  @override
  String get selectImportFile => 'Seleccionar archivo de teselas';

  @override
  String get exportingTiles => 'Exportando teselas...';

  @override
  String get importingTiles => 'Importando teselas...';

  @override
  String exportSuccess(int count) {
    return '$count teselas exportadas exitosamente';
  }

  @override
  String importSuccess(int count) {
    return '$count almacenes importados exitosamente';
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
      'Crea un archivo comprimido (.fmtc) que se puede compartir e importar en otros dispositivos.';

  @override
  String get importNote =>
      'Importa teselas de mapa desde un archivo previamente exportado. Las teselas se fusionarán con la caché existente.';

  @override
  String get noTilesToExport => 'No hay teselas para exportar';

  @override
  String archiveContainsStores(int count) {
    return 'El archivo contiene $count almacenes';
  }

  @override
  String get vectorTiles => 'Teselas vectoriales';

  @override
  String get schema => 'Esquema';

  @override
  String get unknown => 'Desconocido';

  @override
  String get bounds => 'Límites';

  @override
  String get onlineLayers => 'Capas en línea';

  @override
  String get offlineLayers => 'Capas sin conexión';

  @override
  String get locationTrail => 'Rastro de ubicación';

  @override
  String get showTrailOnMap => 'Mostrar rastro en el mapa';

  @override
  String get trailVisible => 'El rastro es visible en el mapa';

  @override
  String get trailHiddenRecording => 'El rastro está oculto (aún grabando)';

  @override
  String get duration => 'Duración';

  @override
  String get points => 'Puntos';

  @override
  String get clearTrail => 'Borrar rastro';

  @override
  String get clearTrailQuestion => '¿Borrar rastro?';

  @override
  String get clearTrailConfirmation =>
      '¿Estás seguro de que quieres borrar el rastro de ubicación actual? Esta acción no se puede deshacer.';

  @override
  String get noTrailRecorded => 'Aún no se ha grabado rastro';

  @override
  String get startTrackingToRecord =>
      'Inicia el seguimiento de ubicación para grabar tu rastro';

  @override
  String get trailControls => 'Controles del rastro';

  @override
  String get exportTrailToGpx => 'Exportar rastro a GPX';

  @override
  String get importTrailFromGpx => 'Importar rastro desde GPX';

  @override
  String get trailExportedSuccessfully => '¡Rastro exportado exitosamente!';

  @override
  String get failedToExportTrail => 'Error al exportar el rastro';

  @override
  String failedToImportTrail(String error) {
    return 'Error al importar el rastro: $error';
  }

  @override
  String get importTrail => 'Importar rastro';

  @override
  String importTrailQuestion(int pointCount) {
    return '¿Importar rastro con $pointCount puntos?\n\nPuede reemplazar su rastro actual o verlo junto a él.';
  }

  @override
  String get viewAlongside => 'Ver junto';

  @override
  String get replaceCurrent => 'Reemplazar actual';

  @override
  String trailImported(int pointCount) {
    return '¡Rastro importado! ($pointCount puntos)';
  }

  @override
  String trailReplaced(int pointCount) {
    return '¡Rastro reemplazado! ($pointCount puntos)';
  }

  @override
  String get contactTrails => 'Rastros de contactos';

  @override
  String get showAllContactTrails => 'Mostrar todos los rastros de contactos';

  @override
  String get noContactsWithLocationHistory =>
      'No hay contactos con historial de ubicación';

  @override
  String showingTrailsForContacts(int count) {
    return 'Mostrando rastros para $count contactos';
  }

  @override
  String get individualContactTrails => 'Rastros individuales de contactos';

  @override
  String get deviceInformation => 'Información del dispositivo';

  @override
  String get bleName => 'Nombre BLE';

  @override
  String get meshName => 'Nombre Mesh';

  @override
  String get notSet => 'No establecido';

  @override
  String get model => 'Modelo';

  @override
  String get version => 'Versión';

  @override
  String get buildDate => 'Fecha de compilación';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Contactos máximos';

  @override
  String get maxChannels => 'Canales máximos';

  @override
  String get publicInfo => 'Información pública';

  @override
  String get meshNetworkName => 'Nombre de red Mesh';

  @override
  String get nameBroadcastInMesh => 'Nombre difundido en anuncios mesh';

  @override
  String get telemetryAndLocationSharing => 'Telemetría y compartir ubicación';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Usar ubicación actual';

  @override
  String get noneUnknown => 'Ninguno/Desconocido';

  @override
  String get chatNode => 'Nodo de chat';

  @override
  String get repeater => 'Repetidor';

  @override
  String get roomChannel => 'Sala/Canal';

  @override
  String typeNumber(int number) {
    return 'Tipo $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Copiado $label al portapapeles';
  }

  @override
  String failedToSave(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Error al obtener ubicación: $error';
  }

  @override
  String get sarTemplates => 'Plantillas SAR';

  @override
  String get manageSarTemplates => 'Gestionar plantillas SAR';

  @override
  String get addTemplate => 'Agregar plantilla';

  @override
  String get editTemplate => 'Editar plantilla';

  @override
  String get deleteTemplate => 'Eliminar plantilla';

  @override
  String get templateName => 'Nombre de plantilla';

  @override
  String get templateNameHint => 'e.g. Found Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Se requiere emoji';

  @override
  String get nameRequired => 'Se requiere nombre';

  @override
  String get templateDescription => 'Description (Optional)';

  @override
  String get templateDescriptionHint => 'Add additional context...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Preview (SAR Message Format)';

  @override
  String get importFromClipboard => 'Importar';

  @override
  String get exportToClipboard => 'Exportar';

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
  String get resetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get resetToDefaultsConfirmation =>
      'Esto eliminará todas las plantillas personalizadas y restaurará las 4 plantillas predeterminadas. ¿Continuar?';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetComplete =>
      'Plantillas restablecidas a valores predeterminados';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get tapAddToCreate => 'Tap + to create your first template';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Permisos';

  @override
  String get locationPermission => 'Permiso de ubicación';

  @override
  String get checking => 'Comprobando...';

  @override
  String get locationPermissionGrantedAlways => 'Concedido (Siempre)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Concedido (Durante el uso)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Denegado - Toca para solicitar';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Denegado permanentemente - Abrir ajustes';

  @override
  String get locationPermissionDialogContent =>
      'El permiso de ubicación está permanentemente denegado. Por favor, actívalo en la configuración de tu dispositivo para usar el rastreo GPS y compartir ubicación.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get locationPermissionGranted => '¡Permiso de ubicación concedido!';

  @override
  String get locationPermissionRequiredForGps =>
      'El permiso de ubicación es necesario para el rastreo GPS y compartir ubicación.';

  @override
  String get locationPermissionAlreadyGranted =>
      'El permiso de ubicación ya está concedido.';

  @override
  String get sarNavyBlue => 'SAR Azul Marino';

  @override
  String get sarNavyBlueDescription => 'Modo Profesional/Operaciones';

  @override
  String get selectRecipient => 'Seleccionar destinatario';

  @override
  String get broadcastToAllNearby => 'Transmitir a todos cercanos';

  @override
  String get searchRecipients => 'Buscar destinatarios...';

  @override
  String get noContactsFound => 'No se encontraron contactos';

  @override
  String get noRoomsFound => 'No se encontraron salas';

  @override
  String get noContactsOrRoomsAvailable =>
      'No hay contactos o salas disponibles';

  @override
  String get messagesWillBeSentToPublicChannel =>
      'Los mensajes se enviarán al canal público';

  @override
  String get newMessage => 'Nuevo mensaje';

  @override
  String get channel => 'Canal';

  @override
  String get samplePoliceLead => 'Jefe de Policía';

  @override
  String get sampleDroneOperator => 'Operador de Dron';

  @override
  String get sampleFirefighterAlpha => 'Bombero';

  @override
  String get sampleMedicCharlie => 'Médico';

  @override
  String get sampleCommandDelta => 'Comando';

  @override
  String get sampleFireEngine => 'Camión de Bomberos';

  @override
  String get sampleAirSupport => 'Apoyo Aéreo';

  @override
  String get sampleBaseCoordinator => 'Coordinador de Base';

  @override
  String get channelEmergency => 'Emergencia';

  @override
  String get channelCoordination => 'Coordinación';

  @override
  String get channelUpdates => 'Actualizaciones';

  @override
  String get sampleTeamMember => 'Miembro de Equipo de Muestra';

  @override
  String get sampleScout => 'Explorador de Muestra';

  @override
  String get sampleBase => 'Base de Muestra';

  @override
  String get sampleSearcher => 'Buscador de Muestra';

  @override
  String get sampleObjectBackpack => ' Mochila encontrada - color azul';

  @override
  String get sampleObjectVehicle =>
      ' Vehículo abandonado - verificar propietario';

  @override
  String get sampleObjectCamping => ' Equipo de camping descubierto';

  @override
  String get sampleObjectTrailMarker =>
      ' Marcador de sendero encontrado fuera del camino';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Todos los equipos reporten';

  @override
  String get sampleMsgWeatherUpdate =>
      'Actualización del clima: Cielo despejado, temp 18°C';

  @override
  String get sampleMsgBaseCamp =>
      'Campamento base establecido en área de preparación';

  @override
  String get sampleMsgTeamAlpha => 'Equipo moviéndose al sector 2';

  @override
  String get sampleMsgRadioCheck =>
      'Prueba de radio - todas las estaciones respondan';

  @override
  String get sampleMsgWaterSupply =>
      'Suministro de agua disponible en punto de control 3';

  @override
  String get sampleMsgTeamBravo => 'Equipo reportando: sector 1 despejado';

  @override
  String get sampleMsgEtaRallyPoint => 'ETA al punto de encuentro: 15 minutos';

  @override
  String get sampleMsgSupplyDrop =>
      'Caída de suministros confirmada para las 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Inspección con dron completada - sin hallazgos';

  @override
  String get sampleMsgTeamCharlie => 'Equipo solicitando apoyo';

  @override
  String get sampleMsgRadioDiscipline =>
      'Todas las unidades: mantener disciplina de radio';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENTE: Asistencia médica necesaria en sector 4';

  @override
  String get sampleMsgAdultMale => ' Hombre adulto, consciente';

  @override
  String get sampleMsgFireSpotted => 'Fuego avistado - coordenadas próximas';

  @override
  String get sampleMsgSpreadingRapidly => ' ¡Se propaga rápidamente!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORIDAD: Necesitamos apoyo de helicóptero';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Equipo médico en camino a su ubicación';

  @override
  String get sampleMsgEvacHelicopter =>
      'Helicóptero de evacuación ETA 10 minutos';

  @override
  String get sampleMsgEmergencyResolved =>
      'Emergencia resuelta - todo despejado';

  @override
  String get sampleMsgEmergencyStagingArea =>
      ' Área de preparación de emergencia';

  @override
  String get sampleMsgEmergencyServices =>
      'Servicios de emergencia notificados y respondiendo';

  @override
  String get sampleAlphaTeamLead => 'Líder de Equipo';

  @override
  String get sampleBravoScout => 'Explorador';

  @override
  String get sampleCharlieMedic => 'Médico';

  @override
  String get sampleDeltaNavigator => 'Navegador';

  @override
  String get sampleEchoSupport => 'Apoyo';

  @override
  String get sampleBaseCommand => 'Comando de Base';

  @override
  String get sampleFieldCoordinator => 'Coordinador de Campo';

  @override
  String get sampleMedicalTeam => 'Equipo Médico';

  @override
  String get mapDrawing => 'Dibujo del Mapa';

  @override
  String get navigateToDrawing => 'Navegar al Dibujo';

  @override
  String get copyCoordinates => 'Copiar Coordenadas';

  @override
  String get hideFromMap => 'Ocultar del Mapa';

  @override
  String get lineDrawing => 'Línea';

  @override
  String get rectangleDrawing => 'Rectángulo';

  @override
  String get coordinatesCopiedToClipboard =>
      'Coordenadas copiadas al portapapeles';

  @override
  String get drawingShared => 'Dibujo del Mapa';

  @override
  String get drawingHidden => 'Dibujo ocultado del mapa';

  @override
  String alreadyShared(int count) {
    return '$count ya compartido';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return '$count nuevo(s) dibujo(s) compartido(s)';
  }

  @override
  String get shareDrawing => 'Compartir Dibujo';

  @override
  String get shareWithAllNearbyDevices =>
      'Compartir con todos los dispositivos cercanos';

  @override
  String get shareToRoom => 'Compartir en Sala';

  @override
  String get sendToPersistentStorage =>
      'Enviar a almacenamiento persistente de sala';

  @override
  String get deleteDrawingConfirm =>
      '¿Está seguro de que desea eliminar este dibujo?';

  @override
  String get drawingDeleted => 'Dibujo eliminado';

  @override
  String yourDrawingsCount(int count) {
    return 'Sus Dibujos ($count)';
  }

  @override
  String get shared => 'Compartido';

  @override
  String get line => 'Línea';

  @override
  String get rectangle => 'Rectángulo';

  @override
  String get updateAvailable => 'Actualización Disponible';

  @override
  String get currentVersion => 'Actual';

  @override
  String get latestVersion => 'Última';

  @override
  String get downloadUpdate => 'Descargar';

  @override
  String get updateLater => 'Más Tarde';

  @override
  String get cadastralParcels => 'Parcelas Catastrales';

  @override
  String get forestRoads => 'Caminos Forestales';

  @override
  String get showCadastralParcels => 'Mostrar parcelas catastrales';

  @override
  String get showForestRoads => 'Mostrar caminos forestales';

  @override
  String get wmsOverlays => 'Superposiciones WMS';

  @override
  String get hikingTrails => 'Senderos de Montaña';

  @override
  String get mainRoads => 'Carreteras Principales';

  @override
  String get houseNumbers => 'Números de Casa';

  @override
  String get fireHazardZones => 'Zonas de Riesgo de Incendio';

  @override
  String get historicalFires => 'Incendios Históricos';

  @override
  String get firebreaks => 'Cortafuegos';

  @override
  String get krasFireZones => 'Zonas de Incendio Kras';

  @override
  String get placeNames => 'Nombres de Lugares';

  @override
  String get municipalityBorders => 'Límites Municipales';

  @override
  String get topographicMap => 'Mapa Topográfico 1:25000';

  @override
  String get recentMessages => 'Mensajes Recientes';

  @override
  String get addChannel => 'Agregar Canal';

  @override
  String get channelName => 'Nombre del Canal';

  @override
  String get channelNameHint => 'ej. Equipo de Rescate Alfa';

  @override
  String get channelSecret => 'Contraseña del Canal';

  @override
  String get channelSecretHint => 'Contraseña compartida para este canal';

  @override
  String get channelSecretHelp =>
      'Esta contraseña debe compartirse con todos los miembros del equipo que necesiten acceso a este canal';

  @override
  String get channelNameRequired => 'El nombre del canal es obligatorio';

  @override
  String get channelNameTooLong =>
      'El nombre del canal debe tener 31 caracteres o menos';

  @override
  String get channelSecretRequired => 'La contraseña del canal es obligatoria';

  @override
  String get channelSecretTooLong =>
      'La contraseña del canal debe tener 32 caracteres o menos';

  @override
  String get invalidAsciiCharacters => 'Solo se permiten caracteres ASCII';

  @override
  String get channelCreatedSuccessfully => 'Canal creado exitosamente';

  @override
  String channelCreationFailed(String error) {
    return 'Error al crear el canal: $error';
  }

  @override
  String get allChannelSlotsInUse =>
      'Todos los espacios de canales están en uso (máximo 39 canales personalizados)';

  @override
  String get createChannel => 'Crear Canal';

  @override
  String get wizardBack => 'Atrás';

  @override
  String get wizardSkip => 'Omitir';

  @override
  String get wizardNext => 'Siguiente';

  @override
  String get wizardGetStarted => 'Comenzar';

  @override
  String get wizardWelcomeTitle => 'Bienvenido a MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'Una poderosa herramienta de comunicación sin conexión para operaciones de búsqueda y rescate. Conéctese con su equipo usando tecnología de radio en malla cuando las redes tradicionales no estén disponibles.';

  @override
  String get wizardConnectingTitle => 'Conectando a su Radio';

  @override
  String get wizardConnectingDescription =>
      'Conecte su smartphone a un dispositivo de radio MeshCore vía Bluetooth para comenzar a comunicarse sin conexión.';

  @override
  String get wizardConnectingFeature1 =>
      'Buscar dispositivos MeshCore cercanos';

  @override
  String get wizardConnectingFeature2 => 'Emparejar con su radio vía Bluetooth';

  @override
  String get wizardConnectingFeature3 =>
      'Funciona completamente sin conexión - no se requiere internet';

  @override
  String get wizardSimpleModeTitle => 'Modo Simple';

  @override
  String get wizardSimpleModeDescription =>
      '¿Nuevo en redes en malla? Habilite el modo simple para una interfaz optimizada con solo funciones esenciales.';

  @override
  String get wizardSimpleModeFeature1 =>
      'Interfaz amigable para principiantes con funciones principales';

  @override
  String get wizardSimpleModeFeature2 =>
      'Cambie al modo avanzado en cualquier momento en Configuración';

  @override
  String get wizardChannelTitle => 'Canales';

  @override
  String get wizardChannelDescription =>
      'Transmita mensajes a todos en un canal, perfecto para anuncios y coordinación de todo el equipo.';

  @override
  String get wizardChannelFeature1 =>
      'Canal público para comunicación general del equipo';

  @override
  String get wizardChannelFeature2 =>
      'Cree canales personalizados para grupos específicos';

  @override
  String get wizardChannelFeature3 =>
      'Los mensajes se retransmiten automáticamente por la malla';

  @override
  String get wizardContactsTitle => 'Contactos';

  @override
  String get wizardContactsDescription =>
      'Los miembros de su equipo aparecen automáticamente cuando se unen a la red en malla. Envíeles mensajes directos o vea su ubicación.';

  @override
  String get wizardContactsFeature1 => 'Contactos descubiertos automáticamente';

  @override
  String get wizardContactsFeature2 => 'Enviar mensajes directos privados';

  @override
  String get wizardContactsFeature3 =>
      'Ver nivel de batería y hora de última vista';

  @override
  String get wizardMapTitle => 'Mapa & Ubicación';

  @override
  String get wizardMapDescription =>
      'Rastree a su equipo en tiempo real y marque ubicaciones importantes para operaciones de búsqueda y rescate.';

  @override
  String get wizardMapFeature1 =>
      'Marcadores SAR para personas encontradas, incendios y áreas de preparación';

  @override
  String get wizardMapFeature2 =>
      'Rastreo GPS en tiempo real de miembros del equipo';

  @override
  String get wizardMapFeature3 =>
      'Descargar mapas sin conexión para áreas remotas';

  @override
  String get wizardMapFeature4 =>
      'Dibujar formas y compartir información táctica';

  @override
  String get viewWelcomeTutorial => 'Ver tutorial de bienvenida';
}
