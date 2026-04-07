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
  String get noDevicesFound => 'No se encontraron dispositivos';

  @override
  String get scanAgain => 'Buscar de nuevo';

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
  String failedToAdvertise(String error) {
    return 'Error al anunciar: $error';
  }

  @override
  String get cancelReconnection => 'Cancelar reconexión';

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
  String get disableMap => 'Desactivar mapa';

  @override
  String get language => 'Idioma';

  @override
  String get chooseLanguage => 'Elegir idioma';

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
  String get resetPath => 'Restablecer ruta (Re-enrutar)';

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
  String get publicChannel => 'Canal público';

  @override
  String get broadcastToAll => 'Difundir a todos los nodos cercanos (efímero)';

  @override
  String get storedPermanently => 'Almacenado permanentemente en la sala';

  @override
  String get notConnectedToDevice => 'No conectado al dispositivo';

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
  String get autoSend => 'Envío automático';

  @override
  String get autoSendDescription => 'Enviar por la ruta actual.';

  @override
  String get sendDirect => 'Envío directo';

  @override
  String get sendDirectDescription => 'Enviar directamente a este contacto.';

  @override
  String get sendFlood => 'Envío por inundación';

  @override
  String get sendFloodDescription =>
      'Enviar a través de todos los repetidores.';

  @override
  String get loggedIn => 'Sesión iniciada';

  @override
  String get noGpsData => 'Sin datos GPS';

  @override
  String get distance => 'Distancia';

  @override
  String directPingTimeout(String name) {
    return 'Tiempo de espera de ping directo agotado - reintentando $name con inundación...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping fallido a $name - no se recibió respuesta';
  }

  @override
  String deleteContactConfirmation(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?\n\nEsto eliminará el contacto tanto de la aplicación como del dispositivo de radio compañero.';
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
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get permissions => 'Permisos';

  @override
  String get telemetry => 'Telemetría';

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
  String get selectMapLayer => 'Seleccionar capa de mapa';

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
  String get textCopiedToClipboard => 'Texto copiado al portapapeles';

  @override
  String get cannotReplySenderMissing =>
      'No se puede responder: falta información del remitente';

  @override
  String get cannotReplyContactNotFound =>
      'No se puede responder: contacto no encontrado';

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
  String deliveredToContacts(int delivered, int total) {
    return 'Entregado a $delivered/$total contactos';
  }

  @override
  String get allDelivered => 'Todo entregado';

  @override
  String get recipientDetails => 'Detalles de destinatarios';

  @override
  String get pending => 'Pendiente';

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
  String exportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String importFailed(String error) {
    return 'Error al importar: $error';
  }

  @override
  String get unknown => 'Desconocido';

  @override
  String get onlineLayers => 'Capas en línea';

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
  String get model => 'Modelo';

  @override
  String get version => 'Versión';

  @override
  String get maxContacts => 'Contactos máximos';

  @override
  String get maxChannels => 'Canales máximos';

  @override
  String get publicInfo => 'Información pública';

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
  String get addTemplate => 'Agregar plantilla';

  @override
  String get editTemplate => 'Editar plantilla';

  @override
  String get deleteTemplate => 'Eliminar plantilla';

  @override
  String get templateName => 'Nombre de plantilla';

  @override
  String get templateNameHint => 'p. ej., Persona encontrada';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Se requiere emoji';

  @override
  String get nameRequired => 'Se requiere nombre';

  @override
  String get templateDescription => 'Descripcion (opcional)';

  @override
  String get templateDescriptionHint => 'Anade contexto adicional...';

  @override
  String get templateColor => 'Color';

  @override
  String get previewFormat => 'Vista previa (formato de mensaje SAR)';

  @override
  String get importFromClipboard => 'Importar';

  @override
  String get exportToClipboard => 'Exportar';

  @override
  String deleteTemplateConfirmation(String name) {
    return '¿Eliminar la plantilla \'$name\'?';
  }

  @override
  String get templateAdded => 'Plantilla anadida';

  @override
  String get templateUpdated => 'Plantilla actualizada';

  @override
  String get templateDeleted => 'Plantilla eliminada';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count plantillas',
      one: 'Se importo 1 plantilla',
      zero: 'No se importaron plantillas',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se exportaron $count plantillas al portapapeles',
      one: 'Se exporto 1 plantilla al portapapeles',
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
  String get noTemplates => 'No hay plantillas disponibles';

  @override
  String get tapAddToCreate => 'Toca + para crear tu primera plantilla';

  @override
  String get ok => 'OK';

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
  String get noRecipientsAvailable => 'No hay destinatarios disponibles';

  @override
  String get noChannelsFound => 'No se encontraron canales';

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
  String get manualCoordinates => 'Coordenadas Manuales';

  @override
  String get enterCoordinatesManually => 'Introducir coordenadas manualmente';

  @override
  String get latitudeLabel => 'Latitud';

  @override
  String get longitudeLabel => 'Longitud';

  @override
  String get exampleCoordinates => 'Ejemplo: 46.0569, 14.5058';

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
  String get channelTypesInfo =>
      'Canales hash (#equipo): Contraseña generada automáticamente del nombre. Mismo nombre = mismo canal en todos los dispositivos.\n\nCanales privados: Use contraseña explícita. Solo aquellos con la contraseña pueden unirse.';

  @override
  String get hashChannelInfo =>
      'Canal hash: La contraseña se generará automáticamente del nombre del canal. Cualquiera que use el mismo nombre se unirá al mismo canal.';

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
  String get deleteChannel => 'Eliminar Canal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return '¿Está seguro de que desea eliminar el canal \"$channelName\"? Esta acción no se puede deshacer.';
  }

  @override
  String get channelDeletedSuccessfully => 'Canal eliminado exitosamente';

  @override
  String channelDeletionFailed(String error) {
    return 'Error al eliminar el canal: $error';
  }

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
  String get viewWelcomeTutorial => 'Ver tutorial de bienvenida';

  @override
  String get allTeamContacts => 'Todos los contactos del equipo';

  @override
  String directMessagesInfo(int count) {
    return 'Mensajes directos con confirmaciones. Enviado a $count miembros del equipo.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Marcador SAR enviado a $count contactos';
  }

  @override
  String get noContactsAvailable => 'No hay contactos del equipo disponibles';

  @override
  String get reply => 'Responder';

  @override
  String get technicalDetails => 'Detalles técnicos';

  @override
  String get messageTechnicalDetails => 'Detalles técnicos del mensaje';

  @override
  String get linkQuality => 'Calidad del enlace';

  @override
  String get delivery => 'Entrega';

  @override
  String get status => 'Estado';

  @override
  String get expectedAckTag => 'Etiqueta ACK esperada';

  @override
  String get roundTrip => 'Ida y vuelta';

  @override
  String get retryAttempt => 'Intento de reenvío';

  @override
  String get floodFallback => 'Reserva de inundación';

  @override
  String get identity => 'Identidad';

  @override
  String get messageId => 'ID de mensaje';

  @override
  String get sender => 'Remitente';

  @override
  String get senderKey => 'Clave del remitente';

  @override
  String get recipient => 'Destinatario';

  @override
  String get recipientKey => 'Clave del destinatario';

  @override
  String get voice => 'Voz';

  @override
  String get voiceId => 'ID de voz';

  @override
  String get envelope => 'Envolvente';

  @override
  String get sessionProgress => 'Progreso de sesión';

  @override
  String get complete => 'Completo';

  @override
  String get rawDump => 'Volcado sin procesar';

  @override
  String get cannotRetryMissingRecipient =>
      'No se puede reintentar: falta información del destinatario';

  @override
  String get voiceUnavailable => 'Voz no disponible en este momento';

  @override
  String get requestingVoice => 'Solicitando voz';

  @override
  String get device => 'dispositivo';

  @override
  String get change => 'Cambiar';

  @override
  String get wizardOverviewDescription =>
      'Esta aplicación reúne mensajería MeshCore, actualizaciones SAR de campo, mapas y herramientas del dispositivo en un solo lugar.';

  @override
  String get wizardOverviewFeature1 =>
      'Envía mensajes directos, publicaciones en salas y mensajes de canal desde la pestaña principal Mensajes.';

  @override
  String get wizardOverviewFeature2 =>
      'Comparte marcadores SAR, dibujos del mapa, clips de voz e imágenes a través de la malla.';

  @override
  String get wizardOverviewFeature3 =>
      'Conéctate por BLE o TCP y luego gestiona la radio complementaria desde la aplicación.';

  @override
  String get wizardMessagingTitle => 'Mensajería e informes de campo';

  @override
  String get wizardMessagingDescription =>
      'Aquí los mensajes son más que texto plano. La aplicación ya admite varias cargas operativas y flujos de transferencia.';

  @override
  String get wizardMessagingFeature1 =>
      'Envía mensajes directos, publicaciones en salas y tráfico de canal desde un solo editor.';

  @override
  String get wizardMessagingFeature2 =>
      'Crea actualizaciones SAR y plantillas SAR reutilizables para informes de campo habituales.';

  @override
  String get wizardMessagingFeature3 =>
      'Transfiere sesiones de voz e imágenes con progreso y estimaciones de tiempo de aire en la interfaz.';

  @override
  String get wizardConnectDeviceTitle => 'Conectar dispositivo';

  @override
  String get wizardConnectDeviceDescription =>
      'Conecta tu radio MeshCore, elige un nombre y aplica un ajuste predefinido antes de continuar.';

  @override
  String get wizardSetupBadge => 'Configuración';

  @override
  String get wizardOverviewBadge => 'Resumen';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get wizardNoDeviceConnected =>
      'Aún no hay ningún dispositivo conectado';

  @override
  String get wizardSkipForNow => 'Omitir por ahora';

  @override
  String get wizardDeviceNameLabel => 'Nombre del dispositivo';

  @override
  String get wizardDeviceNameHelp =>
      'Este nombre se anuncia a otros usuarios de MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Región de configuración';

  @override
  String get wizardConfigRegionHelp =>
      'Usa la lista oficial completa de ajustes predefinidos de MeshCore. El valor predeterminado es EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Asegúrate de que el ajuste seleccionado coincida con la normativa local de radio.';

  @override
  String get wizardPresetNote2 =>
      'La lista coincide con la fuente oficial de ajustes predefinidos de la herramienta de configuración de MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) sigue seleccionado por defecto durante la incorporación.';

  @override
  String get wizardSaving => 'Guardando...';

  @override
  String get wizardSaveAndContinue => 'Guardar y continuar';

  @override
  String get wizardEnterDeviceName =>
      'Introduce un nombre de dispositivo antes de continuar.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Se guardó $deviceName con $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contactos, salas y repetidores';

  @override
  String get wizardNetworkDescription =>
      'La pestaña Contactos organiza la red que descubres y las rutas que aprendes con el tiempo.';

  @override
  String get wizardNetworkFeature1 =>
      'Revisa miembros del equipo, repetidores, salas, canales y anuncios pendientes en una sola lista.';

  @override
  String get wizardNetworkFeature2 =>
      'Usa ping inteligente, acceso a salas, rutas aprendidas y herramientas de reinicio de ruta cuando la conectividad se complique.';

  @override
  String get wizardNetworkFeature3 =>
      'Crea canales y gestiona destinos de red sin salir de la aplicación.';

  @override
  String get wizardMapOpsTitle => 'Mapa, rastros y geometría compartida';

  @override
  String get wizardMapOpsDescription =>
      'El mapa de la aplicación está vinculado directamente a la mensajería, el seguimiento y las superposiciones SAR en lugar de ser un visor aparte.';

  @override
  String get wizardMapOpsFeature1 =>
      'Sigue tu propia posición, las ubicaciones de tus compañeros y los rastros de movimiento en el mapa.';

  @override
  String get wizardMapOpsFeature2 =>
      'Abre dibujos desde mensajes, prévisualos en línea y elimínalos del mapa cuando sea necesario.';

  @override
  String get wizardMapOpsFeature3 =>
      'Usa vistas de mapa de repetidores y superposiciones compartidas para comprender el alcance de la red sobre el terreno.';

  @override
  String get wizardToolsTitle => 'Herramientas más allá de la mensajería';

  @override
  String get wizardToolsDescription =>
      'Aquí hay más que las cuatro pestañas principales. La aplicación también incluye configuración, diagnóstico y flujos opcionales de sensores.';

  @override
  String get wizardToolsFeature1 =>
      'Abre la configuración del dispositivo para cambiar ajustes de radio, telemetría, potencia TX y detalles del equipo complementario.';

  @override
  String get wizardToolsFeature2 =>
      'Activa la pestaña Sensores cuando quieras paneles de sensores vigilados y acciones de actualización rápida.';

  @override
  String get wizardToolsFeature3 =>
      'Usa registros de paquetes, escaneo de espectro y diagnósticos de desarrollador al solucionar problemas de la malla.';

  @override
  String get postConnectDiscoveryTitle => '¿Descubrir repetidores ahora?';

  @override
  String get postConnectDiscoveryDescription =>
      'Ejecutar descubrimiento de repetidores justo después de conectarse para ver nodos MeshCore cercanos y agregarlos a su red más rápido.';

  @override
  String get contactInSensors => 'En Sensores';

  @override
  String get contactAddToSensors => 'Añadir a Sensores';

  @override
  String get contactSetPath => 'Definir ruta';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName se añadió a Sensores';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'No se pudo borrar la ruta: $error';
  }

  @override
  String get contactRouteCleared => 'Ruta borrada';

  @override
  String contactRouteSet(String route) {
    return 'Ruta establecida: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'No se pudo establecer la ruta: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Tiempo de espera ACK';

  @override
  String get opcode => 'Código de operación';

  @override
  String get payload => 'Carga útil';

  @override
  String get hops => 'Saltos';

  @override
  String get hashSize => 'Tamaño del hash';

  @override
  String get pathBytes => 'Bytes de ruta';

  @override
  String get selectedPath => 'Ruta seleccionada';

  @override
  String get estimatedTx => 'Transmisión estimada';

  @override
  String get senderToReceipt => 'Del remitente al recibo';

  @override
  String get receivedCopies => 'Copias recibidas';

  @override
  String get retryCause => 'Causa del reintento';

  @override
  String get retryMode => 'Modo de reintento';

  @override
  String get retryResult => 'Resultado del reintento';

  @override
  String get lastRetry => 'Último reintento';

  @override
  String get rxPackets => 'Paquetes RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Velocidad';

  @override
  String get window => 'Ventana';

  @override
  String get posttxDelay => 'Retardo post-tx';

  @override
  String get bandpass => 'Paso de banda';

  @override
  String get bandpassFilterVoice => 'Filtro de paso de banda de voz';

  @override
  String get active => 'Activo';

  @override
  String get addContact => 'Añadir contacto';

  @override
  String get all => 'Todo';

  @override
  String get clearAllLabel => 'Borrar todo';

  @override
  String get clearFilters => 'Borrar filtros';

  @override
  String get clearRoute => 'Borrar ruta';

  @override
  String get clearMessages => 'Borrar mensajes';

  @override
  String get clearScale => 'Borrar escala';

  @override
  String get clearDiscoveries => 'Borrar descubrimientos';

  @override
  String get clearOnlineTraceDatabase => 'Borrar base de datos de trazas';

  @override
  String get clearAllChannels => 'Borrar todos los canales';

  @override
  String get clearAllContacts => 'Borrar todos los contactos';

  @override
  String get clearChannels => 'Borrar canales';

  @override
  String get clearContacts => 'Borrar contactos';

  @override
  String get clearPathOnMaxRetry => 'Borrar ruta en máximo reintento';

  @override
  String get create => 'Crear';

  @override
  String get custom => 'Personalizado';

  @override
  String get defaultValue => 'Predeterminado';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get editName => 'Editar nombre';

  @override
  String get open => 'Abrir';

  @override
  String get paste => 'Pegar';

  @override
  String get preview => 'Vista previa';

  @override
  String get remove => 'Eliminar';

  @override
  String get rename => 'Renombrar';

  @override
  String get resolveAll => 'Resolver todo';

  @override
  String get send => 'Enviar';

  @override
  String get sendAnyway => 'Enviar de todos modos';

  @override
  String get share => 'Compartir';

  @override
  String get trace => 'Traza';

  @override
  String get discovery => 'Descubrimiento';

  @override
  String get discoverRepeaters => 'Descubrir repetidores';

  @override
  String get discoverSensors => 'Descubrir sensores';

  @override
  String get repeaterDiscoverySent => 'Descubrimiento de repetidores enviado';

  @override
  String get sensorDiscoverySent => 'Descubrimiento de sensores enviado';

  @override
  String get clearedPendingDiscoveries =>
      'Descubrimientos pendientes borrados.';

  @override
  String get autoDiscovery => 'Descubrimiento automático';

  @override
  String get enableAutomaticAdding => 'Habilitar adición automática';

  @override
  String get autoaddRepeaters => 'Añadir repetidores automáticamente';

  @override
  String get autoaddRoomServers => 'Añadir servidores de sala automáticamente';

  @override
  String get autoaddSensors => 'Añadir sensores automáticamente';

  @override
  String get autoaddUsers => 'Añadir usuarios automáticamente';

  @override
  String get overwriteOldestWhenFull =>
      'Sobrescribir más antiguos cuando esté lleno';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get dangerZone => 'Zona de peligro';

  @override
  String get profiles => 'Perfiles';

  @override
  String get favourites => 'Favoritos';

  @override
  String get sensors => 'Sensores';

  @override
  String get others => 'Otros';

  @override
  String get gpsModule => 'Módulo GPS';

  @override
  String get liveTraffic => 'Tráfico en vivo';

  @override
  String get repeatersMap => 'Mapa de repetidores';

  @override
  String get blePacketLogs => 'Registros de paquetes BLE';

  @override
  String get onlineTraceDatabase => 'Base de datos de trazas';

  @override
  String get routePathByteSize => 'Tamaño en bytes de la ruta';

  @override
  String get messageNotifications => 'Notificaciones de mensajes';

  @override
  String get sarAlerts => 'Alertas SAR';

  @override
  String get discoveryNotifications => 'Notificaciones de descubrimiento';

  @override
  String get updateNotifications => 'Notificaciones de actualización';

  @override
  String get muteWhileAppIsOpen => 'Silenciar con la app abierta';

  @override
  String get disableContacts => 'Desactivar contactos';

  @override
  String get enableSensorsTab => 'Habilitar pestaña Sensores';

  @override
  String get enableProfiles => 'Habilitar perfiles';

  @override
  String get nearestRepeaterFallback => 'Repetidor más cercano como reserva';

  @override
  String get deleteAllStoredMessageHistory =>
      'Eliminar todo el historial de mensajes';

  @override
  String get messageFontSize => 'Tamaño de fuente de mensajes';

  @override
  String get rotateMapWithHeading => 'Rotar mapa con rumbo';

  @override
  String get showMapDebugInfo => 'Mostrar info de depuración del mapa';

  @override
  String get openMapInFullscreen => 'Abrir mapa en pantalla completa';

  @override
  String get showSarMarkersLabel => 'Mostrar marcadores SAR';

  @override
  String get hideRepeatersOnMap => 'Ocultar repetidores en el mapa';

  @override
  String get setMapScale => 'Establecer escala del mapa';

  @override
  String get customMapScaleSaved => 'Escala de mapa personalizada guardada';

  @override
  String get voiceBitrate => 'Tasa de bits de voz';

  @override
  String get voiceCompressor => 'Compresor de voz';

  @override
  String get voiceLimiter => 'Limitador de voz';

  @override
  String get micAutoGain => 'Ganancia automática del micrófono';

  @override
  String get echoCancellation => 'Cancelación de eco';

  @override
  String get noiseSuppression => 'Supresión de ruido';

  @override
  String get trimSilenceInVoiceMessages =>
      'Recortar silencio en mensajes de voz';

  @override
  String get compressor => 'Compresor';

  @override
  String get limiter => 'Limitador';

  @override
  String get autoGain => 'Ganancia automática';

  @override
  String get echoCancel => 'Eco';

  @override
  String get noiseSuppress => 'Ruido';

  @override
  String get silenceTrim => 'Silencio';

  @override
  String get maxImageSize => 'Tamaño máximo de imagen';

  @override
  String get imageCompression => 'Compresión de imagen';

  @override
  String get grayscale => 'Escala de grises';

  @override
  String get ultraMode => 'Modo ultra';

  @override
  String get fastPrivateGpsUpdates => 'Actualizaciones GPS privadas rápidas';

  @override
  String get movementThreshold => 'Umbral de movimiento';

  @override
  String get fastGpsMovementThreshold => 'Umbral de movimiento GPS rápido';

  @override
  String get fastGpsActiveuseInterval => 'Intervalo de uso activo GPS rápido';

  @override
  String get activeuseUpdateInterval =>
      'Intervalo de actualización de uso activo';

  @override
  String get repeatNearbyTraffic => 'Repetir tráfico cercano';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Retransmitir a través de repetidores en la red';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Solo cercanos, sin inundación de repetidores';

  @override
  String get multihop => 'Multi-salto';

  @override
  String get createProfile => 'Crear perfil';

  @override
  String get renameProfile => 'Renombrar perfil';

  @override
  String get newProfile => 'Nuevo perfil';

  @override
  String get manageProfiles => 'Gestionar perfiles';

  @override
  String get enableProfilesToStartManagingThem =>
      'Habilite los perfiles para comenzar a gestionarlos.';

  @override
  String get openMessage => 'Abrir mensaje';

  @override
  String get jumpToTheRelatedSarMessage => 'Ir al mensaje SAR relacionado';

  @override
  String get removeSarMarker => 'Eliminar marcador SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Seleccione un destino para enviar el marcador SAR';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Marcador SAR transmitido al canal público';

  @override
  String get sarMarkerSentToRoom => 'Marcador SAR enviado a la sala';

  @override
  String get loadFromGallery => 'Cargar desde galería';

  @override
  String get replaceImage => 'Reemplazar imagen';

  @override
  String get selectFromGallery => 'Seleccionar de galería';

  @override
  String get team => 'Equipo';

  @override
  String get found => 'Encontrado';

  @override
  String get staging => 'Área de reunión';

  @override
  String get object => 'Objeto';

  @override
  String get quiet => 'Silencioso';

  @override
  String get busy => 'Ocupado';

  @override
  String get searchMessages => 'Buscar mensajes';

  @override
  String get sendImageFromGallery => 'Enviar imagen desde galería';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get allMessages => 'Todos los mensajes';

  @override
  String get sendToPublicChannel => '¿Enviar al canal público?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Seleccione tipo de marcador y destino';

  @override
  String get noDestinationsAvailableLabel => 'No hay destinos disponibles';

  @override
  String get image => 'Imagen';

  @override
  String get format => 'Formato';

  @override
  String get dimensions => 'Dimensiones';

  @override
  String get segments => 'Segmentos';

  @override
  String get transfers => 'Transferencias';

  @override
  String get downloadedBy => 'Descargado por';

  @override
  String get saveDiscoverySettings => 'Guardar ajustes de descubrimiento';

  @override
  String get savePublicInfo => 'Guardar información pública';

  @override
  String get saveRadioSettings => 'Guardar ajustes de radio';

  @override
  String get savePath => 'Guardar ruta';

  @override
  String get wipeDeviceData => 'Borrar datos del dispositivo';

  @override
  String get wipeDevice => 'Borrar dispositivo';

  @override
  String get destructiveDeviceActions =>
      'Acciones destructivas del dispositivo.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Elija un preajuste o ajuste la configuración de radio.';

  @override
  String get used => 'Usado';

  @override
  String get total => 'Total';

  @override
  String get renameValue => 'Renombrar valor';

  @override
  String get customizeFields => 'Personalizar campos';

  @override
  String get livePreview => 'Vista previa en vivo';

  @override
  String get refreshSchedule => 'Programación de actualización';

  @override
  String get noResponse => 'Sin respuesta';

  @override
  String get refreshing => 'Actualizando';

  @override
  String get unavailable => 'No disponible';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Elija un relay o nodo para observar.';

  @override
  String get publicKeyLabel => 'Clave pública';

  @override
  String get alreadyInContacts => 'Ya en contactos';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Conéctese a un dispositivo antes de añadir contactos';

  @override
  String get fromContacts => 'De contactos';

  @override
  String get onlineOnly => 'Solo en línea';

  @override
  String get inBoth => 'En ambos';

  @override
  String get source => 'Fuente';

  @override
  String get allMessagesCleared => 'Todos los mensajes borrados';

  @override
  String get onlineTraceDatabaseCleared => 'Base de datos de trazas borrada';

  @override
  String get packetLogsCleared => 'Registros de paquetes borrados';

  @override
  String get hexDataCopiedToClipboard => 'Datos hex copiados al portapapeles';

  @override
  String get developerModeEnabled => 'Modo desarrollador activado';

  @override
  String get developerModeDisabled => 'Modo desarrollador desactivado';

  @override
  String get clipboardIsEmpty => 'El portapapeles está vacío';

  @override
  String get contactImported => 'Contacto importado';

  @override
  String get contactLinkCopiedToClipboard =>
      'Enlace de contacto copiado al portapapeles';

  @override
  String get failedToExportContact => 'Error al exportar el contacto';

  @override
  String get noLogsToExport => 'No hay registros para exportar';

  @override
  String get exportAsCsv => 'Exportar como CSV';

  @override
  String get exportAsText => 'Exportar como texto';

  @override
  String get receivedRfc3339 => 'Recibido (RFC3339)';

  @override
  String get buildTime => 'Hora de compilación';

  @override
  String get downloadUrlNotAvailable => 'URL de descarga no disponible';

  @override
  String get cannotOpenDownloadUrl => 'No se puede abrir la URL de descarga';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'La comprobación de actualizaciones solo está disponible en Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Está ejecutando la última versión';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Actualización disponible pero URL de descarga no encontrada';

  @override
  String get startTictactoe => 'Iniciar Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe no disponible';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: oponente desconocido';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: esperando inicio';

  @override
  String get acceptsShareLinks => 'Acepta enlaces compartidos';

  @override
  String get supportsRawHex => 'Soporta hex sin procesar';

  @override
  String get clipboardfriendly => 'Compatible con portapapeles';

  @override
  String get captured => 'Capturado';

  @override
  String get size => 'Tamaño';

  @override
  String get noCustomChannelsToClear =>
      'No hay canales personalizados que borrar.';

  @override
  String get noDeviceContactsToClear =>
      'No hay contactos del dispositivo que borrar.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Agregar';

  @override
  String get addAdditionalDetails => 'Agregar detalles adicionales';

  @override
  String get addPeer => 'Agregar par';

  @override
  String get addPeerManually => 'Agregar par manualmente';

  @override
  String addedToContacts(String name) {
    return '$name agregado a contactos';
  }

  @override
  String addedToSensors(String name) {
    return '$name agregado a Sensores';
  }

  @override
  String get allowAll => 'Permitir todos';

  @override
  String get anonymousRxStats => 'Estadísticas RX anónimas';

  @override
  String get appearance => 'Apariencia';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Telemetría base';

  @override
  String get blePin => 'PIN BLE';

  @override
  String get buzzerAlerts => 'Alertas de zumbador';

  @override
  String get cancelImageReceive => 'Cancelar recepción de imagen';

  @override
  String get choose => 'Elegir';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Elige qué pestañas y secciones de contactos mostrar';

  @override
  String get clearCache => 'Limpiar caché';

  @override
  String get clearHistory => 'Limpiar historial';

  @override
  String get clearLiveView => 'Limpiar vista en vivo';

  @override
  String get clearLogs => 'Limpiar registros';

  @override
  String get clearOfflineCache => '¿Limpiar caché sin conexión?';

  @override
  String get clearOverlay => 'Limpiar superposición';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Limpiar ruta solo después de que fallen todos los reintentos';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Códec, tasa de bits y procesamiento de audio';

  @override
  String get connectByIpAddress => 'Conectar por dirección IP';

  @override
  String get controlWhichAlertsYouReceive => 'Controla qué alertas recibes';

  @override
  String get copyFullHex => 'Copiar Hex completo';

  @override
  String get copyRawResponse => 'Copiar respuesta sin procesar';

  @override
  String get couldNotLoadMetHistory => 'No se pudo cargar el historial MET';

  @override
  String customizeSensor(String name) {
    return 'Personalizar $name';
  }

  @override
  String get data => 'Datos';

  @override
  String get deleteGroup => 'Eliminar grupo';

  @override
  String deleteStyleConfirm(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return '¿Eliminar este $type?';
  }

  @override
  String get deny => 'Denegar';

  @override
  String get deviceInfo => 'Información del dispositivo';

  @override
  String get deviceSettings => 'Configuración del dispositivo';

  @override
  String get deviceTimeSynced =>
      'Hora del dispositivo sincronizada con este teléfono.';

  @override
  String get disableFastGpsPublishing => 'Desactivar publicación rápida de GPS';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Pantalla, marcadores y base de datos de trazas';

  @override
  String get download => 'Descargar';

  @override
  String get environmentalTelemetry => 'Telemetría ambiental';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Error al buscar actualizaciones: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Error al abrir la descarga: $error';
  }

  @override
  String get exportLogs => 'Exportar registros';

  @override
  String get extraAggressiveAvifCompression => 'Compresión AVIF extra agresiva';

  @override
  String failedToAddContact(String error) {
    return 'Error al agregar contacto: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Error al agregar $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Error al limpiar canales: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Error al limpiar contactos: $error';
  }

  @override
  String get failedToConnectViaSerial => 'Error al conectar por serial';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Error al cargar imagen de vista previa: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Error al cargar traza: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Error al enviar marcador SAR: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Error al configurar modo de zumbador: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Error al configurar modo GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Error al sincronizar hora del dispositivo: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Error al borrar datos del dispositivo: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Canal objetivo de GPS rápido';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Actualizaciones rápidas, umbrales y permisos';

  @override
  String get fetchingCatalog => 'Obteniendo catálogo...';

  @override
  String get fifteenMinutes => '15 minutos';

  @override
  String get fifteenSeconds => '15 segundos';

  @override
  String get filterByDirection => 'Filtrar por dirección';

  @override
  String get finish => 'Finalizar';

  @override
  String get fiveMinutes => '5 minutos';

  @override
  String get fiveSeconds => '5 segundos';

  @override
  String get fix => 'Posición';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Política de anuncio GPS';

  @override
  String get gpsAndLocation => 'GPS y ubicación';

  @override
  String get gpsDiagnostics => 'Diagnósticos GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Ayuda';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Oculto';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Cómo la radio agrega automáticamente nodos descubiertos.';

  @override
  String get images => 'Imágenes';

  @override
  String get importProfile => 'Importar perfil';

  @override
  String get lastFix => 'Última posición';

  @override
  String get latest => 'Más reciente';

  @override
  String get latitude => 'Latitud';

  @override
  String get loadASavedRegion => 'Cargar una región guardada';

  @override
  String get loading => 'Cargando';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Compartir ubicación, hardware e intervalo de actualización.';

  @override
  String get locationTelemetry => 'Telemetría de ubicación';

  @override
  String get lockDestination => 'Bloquear destino';

  @override
  String get longitude => 'Longitud';

  @override
  String get mapStyle => 'Estilo de mapa';

  @override
  String get max => 'Máx';

  @override
  String get maxZoom => 'Zoom máximo';

  @override
  String get messaging => 'Mensajería';

  @override
  String get metHistory => 'Historial MET';

  @override
  String get min => 'Mín';

  @override
  String get minZoom => 'Zoom mínimo';

  @override
  String get moveDown => 'Mover abajo';

  @override
  String get moveUp => 'Mover arriba';

  @override
  String get multiAckMode => 'Modo multi-ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Gestión de espacio de trabajo multidispositivo';

  @override
  String get myLocation => 'Mi ubicación';

  @override
  String get nameAndTelemetryShared =>
      'Nombre y telemetría compartidos con otros dispositivos.';

  @override
  String newVersionAvailable(String version) {
    return 'Nueva versión: $version';
  }

  @override
  String get newer => 'Más nuevo';

  @override
  String get noNeighboursFound => 'No se encontraron vecinos';

  @override
  String get noServersFound => 'No se encontraron servidores';

  @override
  String get notSet => 'Sin configurar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get offZeroSeconds => 'Apagado (0 s)';

  @override
  String get offlineMaps => 'Mapas sin conexión';

  @override
  String get older => 'Más antiguo';

  @override
  String get oneByteMode0 => '1 byte (modo 0)';

  @override
  String get oneHour => '1 hora';

  @override
  String get oneMinute => '1 minuto';

  @override
  String get openPacketLogs => 'Abrir registros de paquetes';

  @override
  String get packetTypeHelp => 'Ayuda de tipo de paquete';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Pega un enlace compartido o anuncio hex';

  @override
  String get pathHash => 'Hash de ruta';

  @override
  String get pathSize => 'Tamaño de ruta';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Polígono';

  @override
  String get rawResponseCopied => 'Respuesta sin procesar copiada';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Reenviar a través del repetidor más cercano en caso de fallo';

  @override
  String get resolveContact => 'Resolver contacto';

  @override
  String get routingRetriesAndDestinationLock =>
      'Enrutamiento, reintentos y bloqueo de destino';

  @override
  String get samples => 'Muestras';

  @override
  String get satellites => 'Satélites';

  @override
  String get saving => 'Guardando...';

  @override
  String get search => 'Buscar';

  @override
  String get searchByNameOrToken => 'Buscar por nombre o token';

  @override
  String get searchDiscoveredNodes => 'Buscar nodos descubiertos';

  @override
  String get searchInCurrentFilter => 'Buscar en el filtro actual';

  @override
  String get searchLogs => 'Buscar registros...';

  @override
  String get searchSensors => 'Buscar sensores';

  @override
  String get searchThisSection => 'Buscar en esta sección';

  @override
  String get selectedRelays => 'Relés seleccionados';

  @override
  String get sensor => 'Sensor';

  @override
  String serialError(String error) {
    return 'Error serial: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Establecer ruta para $name';
  }

  @override
  String get shareLiveGps => 'Compartir GPS en vivo';

  @override
  String get shareMyTiles => 'Compartir mis mosaicos';

  @override
  String get sharingLocationFromPhone =>
      'Compartiendo ubicación en este canal desde el teléfono.';

  @override
  String get sharingLocationFromRadio =>
      'Compartiendo ubicación en este canal desde la radio.';

  @override
  String signalDbm(String rssi) {
    return 'Señal $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview => 'Tamaño, compresión y vista previa';

  @override
  String get skip => 'Omitir';

  @override
  String get smallerFileSize => 'Tamaño de archivo más pequeño';

  @override
  String get sort => 'Ordenar';

  @override
  String get stoppedSharingLocation =>
      'Se dejó de compartir ubicación en este canal.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Suprimir notificaciones en primer plano';

  @override
  String get tabsAndNavigation => 'Pestañas y navegación';

  @override
  String get templatesAndTutorials => 'Plantillas y tutoriales';

  @override
  String get tenMinutes => '10 minutos';

  @override
  String get tenSeconds => '10 segundos';

  @override
  String get testSendUpdate => 'Probar envío de actualización';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Tema, idioma y preferencias de visualización';

  @override
  String get thirtyMinutes => '30 minutos';

  @override
  String get thirtySeconds => '30 segundos';

  @override
  String get threeBytesMode2 => '3 bytes (modo 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Estadísticas de tráfico, historial de mensajes y herramientas de desarrollo';

  @override
  String get twoBytesMode1 => '2 bytes (modo 1)';

  @override
  String get twoMinutes => '2 minutos';

  @override
  String get undo => 'Deshacer';

  @override
  String get updated => 'Actualizado';

  @override
  String get useContactFlags => 'Usar banderas de contacto';

  @override
  String get useSavedCoordinates => 'Usar coordenadas guardadas';

  @override
  String get view => 'Ver';

  @override
  String get viewNeighbours => 'Ver vecinos';

  @override
  String get viewPublicStats => 'Ver estadísticas públicas';

  @override
  String get setRegionScope => 'Establecer ámbito de región';

  @override
  String get regionScope => 'Ámbito de región';

  @override
  String get regionScopeNone => 'Ninguno (global)';

  @override
  String get clearRegionScope => 'Limpiar ámbito';

  @override
  String get regionScopeWarning =>
      'Solo los repetidores que permitan esta región reenviarán.';

  @override
  String get discoverRegions => 'Descubrir desde repetidores';

  @override
  String get discoveringRegions => 'Descubriendo regiones...';

  @override
  String get enterRegionName => 'Nombre de región (ej. auckland)';

  @override
  String get noRegionsFound => 'No se encontraron regiones en este repetidor.';

  @override
  String regionScopeSet(String name) {
    return 'Ámbito de región establecido a $name';
  }

  @override
  String get regionScopeCleared => 'Ámbito de región limpiado';
}
