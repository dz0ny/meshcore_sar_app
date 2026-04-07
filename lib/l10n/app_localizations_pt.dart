// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Mensagens';

  @override
  String get contacts => 'Contatos';

  @override
  String get map => 'Mapa';

  @override
  String get settings => 'Configurações';

  @override
  String get connect => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get noDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get scanAgain => 'Escanear novamente';

  @override
  String get deviceNotConnected => 'Dispositivo não conectado';

  @override
  String get locationPermissionDenied => 'Permissão de localização negada';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permissão de localização negada permanentemente. Ative-a em Configurações.';

  @override
  String get locationPermissionRequired =>
      'A permissão de localização é necessária para rastreamento GPS e coordenação da equipe. Você pode ativá-la depois em Configurações.';

  @override
  String get locationServicesDisabled =>
      'Os serviços de localização estão desativados. Ative-os em Configurações.';

  @override
  String get failedToGetGpsLocation => 'Falha ao obter localização GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Falha ao anunciar: $error';
  }

  @override
  String get cancelReconnection => 'Cancelar reconexão';

  @override
  String get general => 'Geral';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Escolher tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get blueLightTheme => 'Tema azul claro';

  @override
  String get blueDarkTheme => 'Tema azul escuro';

  @override
  String get sarRed => 'SAR Vermelho';

  @override
  String get alertEmergencyMode => 'Modo de alerta/emergência';

  @override
  String get sarGreen => 'SAR Verde';

  @override
  String get safeAllClearMode => 'Modo seguro/tudo limpo';

  @override
  String get autoSystem => 'Automático (Sistema)';

  @override
  String get followSystemTheme => 'Seguir tema do sistema';

  @override
  String get showRxTxIndicators => 'Mostrar indicadores RX/TX';

  @override
  String get disableMap => 'Desativar mapa';

  @override
  String get language => 'Idioma';

  @override
  String get chooseLanguage => 'Escolher idioma';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get about => 'Sobre';

  @override
  String get appVersion => 'Versão do app';

  @override
  String get aboutMeshCoreSar => 'Sobre o MeshCore SAR';

  @override
  String get aboutDescription =>
      'Um aplicativo de Busca e Resgate projetado para equipes de resposta a emergências. Os recursos incluem:\n\n• Rede mesh BLE para comunicação entre dispositivos\n• Mapas offline com múltiplas opções de camadas\n• Rastreamento em tempo real dos membros da equipe\n• Marcadores táticos SAR (pessoa encontrada, incêndio, área de apoio)\n• Gerenciamento de contatos e mensagens\n• Rastreamento GPS com rumo da bússola\n• Cache de blocos de mapa para uso offline';

  @override
  String get technologiesUsed => 'Tecnologias utilizadas:';

  @override
  String get technologiesList =>
      '• Flutter para desenvolvimento multiplataforma\n• BLE (Bluetooth Low Energy) para rede mesh\n• OpenStreetMap para mapas\n• Provider para gerenciamento de estado\n• SharedPreferences para armazenamento local';

  @override
  String get moreInfo => 'Mais informações';

  @override
  String get packageName => 'Nome do pacote';

  @override
  String get sampleData => 'Dados de exemplo';

  @override
  String get sampleDataDescription =>
      'Carregar ou limpar contatos, mensagens de canal e marcadores SAR de exemplo para testes';

  @override
  String get loadSampleData => 'Carregar dados de exemplo';

  @override
  String get clearAllData => 'Limpar todos os dados';

  @override
  String get clearAllDataConfirmTitle => 'Limpar todos os dados';

  @override
  String get clearAllDataConfirmMessage =>
      'Isso limpará todos os contatos e marcadores SAR. Tem certeza?';

  @override
  String get clear => 'Limpar';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Carregados $teamCount membros da equipe, $channelCount canais, $sarCount marcadores SAR, $messageCount mensagens';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Falha ao carregar dados de exemplo: $error';
  }

  @override
  String get allDataCleared => 'Todos os dados foram limpos';

  @override
  String get failedToStartBackgroundTracking =>
      'Falha ao iniciar rastreamento em segundo plano. Verifique permissões e conexão BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Transmissão de localização: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'O PIN padrão para dispositivos sem tela é 123456. Problemas ao parear? Esqueça o dispositivo Bluetooth nas configurações do sistema.';

  @override
  String get noMessagesYet => 'Ainda não há mensagens';

  @override
  String get pullDownToSync => 'Puxe para baixo para sincronizar mensagens';

  @override
  String get deleteContact => 'Excluir contato';

  @override
  String get delete => 'Excluir';

  @override
  String get viewOnMap => 'Ver no mapa';

  @override
  String get refresh => 'Atualizar';

  @override
  String get resetPath => 'Redefinir rota';

  @override
  String copiedToClipboard(String label) {
    return '$label copiado para a área de transferência';
  }

  @override
  String get pleaseEnterPassword => 'Digite uma senha';

  @override
  String failedToSyncContacts(String error) {
    return 'Falha ao sincronizar contatos: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Login realizado com sucesso! Aguardando mensagens da sala...';

  @override
  String get loginFailed => 'Falha no login - senha incorreta';

  @override
  String loggingIn(String roomName) {
    return 'Entrando em $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Falha ao enviar login: $error';
  }

  @override
  String get lowLocationAccuracy => 'Baixa precisão de localização';

  @override
  String get continue_ => 'Continuar';

  @override
  String get sendSarMarker => 'Enviar marcador SAR';

  @override
  String get deleteDrawing => 'Excluir desenho';

  @override
  String get drawingTools => 'Ferramentas de desenho';

  @override
  String get drawLine => 'Desenhar linha';

  @override
  String get drawLineDesc => 'Desenhar uma linha livre no mapa';

  @override
  String get drawRectangle => 'Desenhar retângulo';

  @override
  String get drawRectangleDesc => 'Desenhar uma área retangular no mapa';

  @override
  String get measureDistance => 'Medir distância';

  @override
  String get measureDistanceDesc =>
      'Pressione longamente dois pontos para medir';

  @override
  String get clearMeasurement => 'Limpar medição';

  @override
  String distanceLabel(String distance) {
    return 'Distância: $distance';
  }

  @override
  String get longPressForSecondPoint =>
      'Pressione longamente para o segundo ponto';

  @override
  String get longPressToStartMeasurement =>
      'Pressione longamente para definir o primeiro ponto';

  @override
  String get longPressToStartNewMeasurement =>
      'Pressione e segure para iniciar uma nova medição';

  @override
  String get shareDrawings => 'Compartilhar desenhos';

  @override
  String get clearAllDrawings => 'Limpar todos os desenhos';

  @override
  String get completeLine => 'Concluir linha';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Transmitir $count desenho$plural para a equipe';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Remover todos os $count desenho$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Excluir todos os $count desenho$plural do mapa?';
  }

  @override
  String get drawing => 'Desenho';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Compartilhar $count desenho$plural';
  }

  @override
  String get showReceivedDrawings => 'Mostrar desenhos recebidos';

  @override
  String get showingAllDrawings => 'Mostrando todos os desenhos';

  @override
  String get showingOnlyYourDrawings => 'Mostrando apenas seus desenhos';

  @override
  String get showSarMarkers => 'Mostrar marcadores SAR';

  @override
  String get showingSarMarkers => 'Mostrando marcadores SAR';

  @override
  String get hidingSarMarkers => 'Ocultando marcadores SAR';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get publicChannel => 'Canal público';

  @override
  String get broadcastToAll => 'Transmitir para todos os nós próximos';

  @override
  String get storedPermanently => 'Armazenado permanentemente na sala';

  @override
  String get notConnectedToDevice => 'Não conectado ao dispositivo';

  @override
  String get typeYourMessage => 'Digite sua mensagem...';

  @override
  String get quickLocationMarker => 'Marcador rápido de localização';

  @override
  String get markerType => 'Tipo de marcador';

  @override
  String get sendTo => 'Enviar para';

  @override
  String get noDestinationsAvailable => 'Nenhum destino disponível.';

  @override
  String get selectDestination => 'Selecione o destino...';

  @override
  String get ephemeralBroadcastInfo =>
      'Efêmero: transmitido apenas pelo ar. Não é armazenado; os nós precisam estar online.';

  @override
  String get persistentRoomInfo =>
      'Persistente: armazenado de forma imutável na sala. Sincronizado automaticamente e preservado offline.';

  @override
  String get location => 'Localização';

  @override
  String get fromMap => 'Do mapa';

  @override
  String get gettingLocation => 'Obtendo localização...';

  @override
  String get locationError => 'Erro de localização';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get refreshLocation => 'Atualizar localização';

  @override
  String accuracyMeters(int accuracy) {
    return 'Precisão: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get addAdditionalInformation => 'Adicionar informações extras...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'A precisão da localização é ±${accuracy}m. Isso pode não ser preciso o suficiente para operações SAR.\n\nDeseja continuar mesmo assim?';
  }

  @override
  String get loginToRoom => 'Entrar na sala';

  @override
  String get enterPasswordInfo =>
      'Digite a senha para acessar esta sala. A senha será salva para uso futuro.';

  @override
  String get password => 'Senha';

  @override
  String get enterRoomPassword => 'Digite a senha da sala';

  @override
  String get loggingInDots => 'Entrando...';

  @override
  String get login => 'Entrar';

  @override
  String failedToAddRoom(String error) {
    return 'Falha ao adicionar a sala ao dispositivo: $error\n\nA sala talvez ainda não tenha sido anunciada.\nTente esperar a sala começar a transmitir.';
  }

  @override
  String get direct => 'Direto';

  @override
  String get flood => 'Inundação';

  @override
  String get autoSend => 'Envio automático';

  @override
  String get autoSendDescription => 'Enviar pela rota atual.';

  @override
  String get sendDirect => 'Envio direto';

  @override
  String get sendDirectDescription => 'Enviar diretamente a este contacto.';

  @override
  String get sendFlood => 'Envio por inundação';

  @override
  String get sendFloodDescription => 'Enviar por todos os repetidores.';

  @override
  String get loggedIn => 'Conectado';

  @override
  String get noGpsData => 'Sem dados GPS';

  @override
  String get distance => 'Distância';

  @override
  String directPingTimeout(String name) {
    return 'Tempo limite do ping direto - tentando novamente $name com flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Falha no ping para $name - nenhuma resposta recebida';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Tem certeza de que deseja excluir \"$name\"?\n\nIsso removerá o contato tanto do aplicativo quanto do dispositivo de rádio associado.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Falha ao remover contato: $error';
  }

  @override
  String get type => 'Tipo';

  @override
  String get publicKey => 'Chave pública';

  @override
  String get lastSeen => 'Visto por último';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get permissions => 'Permissões';

  @override
  String get telemetry => 'Telemetria';

  @override
  String get voltage => 'Voltagem';

  @override
  String get battery => 'Bateria';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Umidade';

  @override
  String get pressure => 'Pressão';

  @override
  String get gpsTelemetry => 'GPS (telemetria)';

  @override
  String get reLoginToRoom => 'Entrar novamente na sala';

  @override
  String get heading => 'Direção';

  @override
  String get elevation => 'Elevação';

  @override
  String get accuracy => 'Precisão';

  @override
  String get bearing => 'Rumo';

  @override
  String get direction => 'Direção';

  @override
  String get filterMarkers => 'Filtrar marcadores';

  @override
  String get filterMarkersTooltip => 'Filtrar marcadores';

  @override
  String get contactsFilter => 'Contatos';

  @override
  String get repeatersFilter => 'Repetidores';

  @override
  String get sarMarkers => 'Marcadores SAR';

  @override
  String get foundPerson => 'Pessoa encontrada';

  @override
  String get fire => 'Incêndio';

  @override
  String get stagingArea => 'Área de apoio';

  @override
  String get showAll => 'Mostrar tudo';

  @override
  String get locationUnavailable => 'Localização indisponível';

  @override
  String get ahead => 'à frente';

  @override
  String degreesRight(int degrees) {
    return '$degrees° à direita';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° à esquerda';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat.: $latitude Lon.: $longitude';
  }

  @override
  String get noContactsYet => 'Ainda não há contatos';

  @override
  String get connectToDeviceToLoadContacts =>
      'Conecte-se a um dispositivo para carregar contatos';

  @override
  String get teamMembers => 'Membros da equipe';

  @override
  String get repeaters => 'Repetidores';

  @override
  String get rooms => 'Salas';

  @override
  String get channels => 'Canais';

  @override
  String get selectMapLayer => 'Selecionar camada do mapa';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satélite ESRI';

  @override
  String get googleHybrid => 'Google Híbrido';

  @override
  String get googleRoadmap => 'Google Mapa';

  @override
  String get googleTerrain => 'Google Terreno';

  @override
  String get dragToPosition => 'Arraste para a posição';

  @override
  String get createSarMarker => 'Criar marcador SAR';

  @override
  String get compass => 'Bússola';

  @override
  String get navigationAndContacts => 'Navegação e contatos';

  @override
  String get sarAlert => 'ALERTA SAR';

  @override
  String get textCopiedToClipboard =>
      'Texto copiado para a área de transferência';

  @override
  String get cannotReplySenderMissing =>
      'Não é possível responder: faltam informações do remetente';

  @override
  String get cannotReplyContactNotFound =>
      'Não é possível responder: contato não encontrado';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get saveAsTemplate => 'Salvar como modelo';

  @override
  String get templateSaved => 'Modelo salvo com sucesso';

  @override
  String get templateAlreadyExists => 'Já existe um modelo com este emoji';

  @override
  String get deleteMessage => 'Excluir mensagem';

  @override
  String get deleteMessageConfirmation =>
      'Tem certeza de que deseja excluir esta mensagem?';

  @override
  String get shareLocation => 'Compartilhar localização';

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
  String get sarLocationShare => 'Localização SAR';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String minutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String hoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String daysAgo(int days) {
    return 'há $days d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'há $seconds s';
  }

  @override
  String get sending => 'Enviando...';

  @override
  String get sent => 'Enviado';

  @override
  String get delivered => 'Entregue';

  @override
  String deliveredWithTime(int time) {
    return 'Entregue (${time}ms)';
  }

  @override
  String get failed => 'Falhou';

  @override
  String get broadcast => 'Transmitir';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Entregue a $delivered/$total contatos';
  }

  @override
  String get allDelivered => 'Todos entregues';

  @override
  String get recipientDetails => 'Detalhes do destinatário';

  @override
  String get pending => 'Pendente';

  @override
  String get sarMarkerFoundPerson => 'Pessoa encontrada';

  @override
  String get sarMarkerFire => 'Local do incêndio';

  @override
  String get sarMarkerStagingArea => 'Área de apoio';

  @override
  String get sarMarkerObject => 'Objeto encontrado';

  @override
  String get from => 'De';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get tapToViewOnMap => 'Toque para ver no mapa';

  @override
  String get radioSettings => 'Configurações do rádio';

  @override
  String get frequencyMHz => 'Frequência (MHz)';

  @override
  String get bandwidth => 'Largura de banda';

  @override
  String get spreadingFactor => 'Fator de espalhamento';

  @override
  String get codingRate => 'Taxa de codificação';

  @override
  String get txPowerDbm => 'Potência TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Máx: $power dBm';
  }

  @override
  String get you => 'Você';

  @override
  String exportFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String importFailed(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get onlineLayers => 'Camadas online';

  @override
  String get locationTrail => 'Trilha de localização';

  @override
  String get showTrailOnMap => 'Mostrar trilha no mapa';

  @override
  String get trailVisible => 'A trilha está visível no mapa';

  @override
  String get trailHiddenRecording => 'A trilha está oculta (ainda gravando)';

  @override
  String get duration => 'Duração';

  @override
  String get points => 'Pontos';

  @override
  String get clearTrail => 'Limpar trilha';

  @override
  String get clearTrailQuestion => 'Limpar trilha?';

  @override
  String get clearTrailConfirmation =>
      'Tem certeza de que deseja limpar a trilha de localização atual?';

  @override
  String get noTrailRecorded => 'Nenhuma trilha gravada ainda';

  @override
  String get startTrackingToRecord =>
      'Inicie o rastreamento de localização para gravar sua trilha';

  @override
  String get trailControls => 'Controles da trilha';

  @override
  String get model => 'Modelo';

  @override
  String get version => 'Versão';

  @override
  String get maxContacts => 'Máx. de contatos';

  @override
  String get maxChannels => 'Máx. de canais';

  @override
  String get publicInfo => 'Informações públicas';

  @override
  String get useCurrentLocation => 'Usar localização atual';

  @override
  String get noneUnknown => 'Nenhum/Desconhecido';

  @override
  String get chatNode => 'Nó de chat';

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
    return 'Falha ao salvar: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Falha ao obter localização: $error';
  }

  @override
  String get sarTemplates => 'Modelos SAR';

  @override
  String get addTemplate => 'Adicionar modelo';

  @override
  String get editTemplate => 'Editar modelo';

  @override
  String get deleteTemplate => 'Excluir modelo';

  @override
  String get templateName => 'Nome do modelo';

  @override
  String get templateNameHint => 'ex.: Pessoa encontrada';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji é obrigatório';

  @override
  String get nameRequired => 'Nome é obrigatório';

  @override
  String get templateDescription => 'Descrição (opcional)';

  @override
  String get templateDescriptionHint => 'Adicionar contexto extra...';

  @override
  String get templateColor => 'Cor';

  @override
  String get previewFormat => 'Pré-visualização (formato de mensagem SAR)';

  @override
  String get importFromClipboard => 'Importar';

  @override
  String get exportToClipboard => 'Exportar';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Excluir o modelo “$name”?';
  }

  @override
  String get templateAdded => 'Modelo adicionado';

  @override
  String get templateUpdated => 'Modelo atualizado';

  @override
  String get templateDeleted => 'Modelo excluído';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modelos importados',
      one: '1 modelo importado',
      zero: 'Nenhum modelo importado',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modelos exportados para a área de transferência',
      one: '1 modelo exportado para a área de transferência',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Restaurar padrão';

  @override
  String get resetToDefaultsConfirmation =>
      'Isso excluirá todos os modelos personalizados e restaurará os 4 modelos padrão. Continuar?';

  @override
  String get reset => 'Redefinir';

  @override
  String get resetComplete => 'Modelos redefinidos para o padrão';

  @override
  String get noTemplates => 'Nenhum modelo disponível';

  @override
  String get tapAddToCreate => 'Toque em + para criar seu primeiro modelo';

  @override
  String get ok => 'OK';

  @override
  String get locationPermission => 'Permissão de localização';

  @override
  String get checking => 'Verificando...';

  @override
  String get locationPermissionGrantedAlways => 'Concedida (Sempre)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Concedida (Durante o uso)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Negada - toque para solicitar';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Negada permanentemente - abrir configurações';

  @override
  String get locationPermissionDialogContent =>
      'A permissão de localização foi negada permanentemente. Ative-a nas configurações do dispositivo.';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get locationPermissionGranted => 'Permissão de localização concedida!';

  @override
  String get locationPermissionRequiredForGps =>
      'A permissão de localização é necessária para rastreamento GPS e compartilhamento de localização.';

  @override
  String get locationPermissionAlreadyGranted =>
      'A permissão de localização já foi concedida.';

  @override
  String get sarNavyBlue => 'SAR Azul Marinho';

  @override
  String get sarNavyBlueDescription => 'Modo profissional/operações';

  @override
  String get selectRecipient => 'Selecionar destinatário';

  @override
  String get broadcastToAllNearby => 'Transmitir para todos os próximos';

  @override
  String get searchRecipients => 'Pesquisar destinatários...';

  @override
  String get noContactsFound => 'Nenhum contato encontrado';

  @override
  String get noRoomsFound => 'Nenhuma sala encontrada';

  @override
  String get noRecipientsAvailable => 'Nenhum destinatário disponível';

  @override
  String get noChannelsFound => 'Nenhum canal encontrado';

  @override
  String get newMessage => 'Nova mensagem';

  @override
  String get channel => 'Canal';

  @override
  String get samplePoliceLead => 'Chefe da polícia';

  @override
  String get sampleDroneOperator => 'Operador de drone';

  @override
  String get sampleFirefighterAlpha => 'Bombeiro';

  @override
  String get sampleMedicCharlie => 'Paramédico';

  @override
  String get sampleCommandDelta => 'Comando';

  @override
  String get sampleFireEngine => 'Caminhão de bombeiros';

  @override
  String get sampleAirSupport => 'Apoio aéreo';

  @override
  String get sampleBaseCoordinator => 'Coordenador da base';

  @override
  String get channelEmergency => 'Emergência';

  @override
  String get channelCoordination => 'Coordenação';

  @override
  String get channelUpdates => 'Atualizações';

  @override
  String get sampleTeamMember => 'Membro de equipe de exemplo';

  @override
  String get sampleScout => 'Batedor de exemplo';

  @override
  String get sampleBase => 'Base de exemplo';

  @override
  String get sampleSearcher => 'Buscador de exemplo';

  @override
  String get sampleObjectBackpack => ' Mochila encontrada - cor azul';

  @override
  String get sampleObjectVehicle =>
      ' Veículo abandonado - verificar proprietário';

  @override
  String get sampleObjectCamping => ' Equipamento de camping encontrado';

  @override
  String get sampleObjectTrailMarker =>
      ' Marco de trilha encontrado fora da rota';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Todas as equipes, façam check-in';

  @override
  String get sampleMsgWeatherUpdate =>
      'Atualização do tempo: céu limpo, temp. 18°C';

  @override
  String get sampleMsgBaseCamp => 'Base estabelecida na área de apoio';

  @override
  String get sampleMsgTeamAlpha => 'Equipe deslocando-se para o setor 2';

  @override
  String get sampleMsgRadioCheck =>
      'Teste de rádio - todas as estações respondam';

  @override
  String get sampleMsgWaterSupply =>
      'Abastecimento de água disponível no ponto de controle 3';

  @override
  String get sampleMsgTeamBravo => 'Equipe informa: setor 1 livre';

  @override
  String get sampleMsgEtaRallyPoint =>
      'ETA para o ponto de reunião: 15 minutos';

  @override
  String get sampleMsgSupplyDrop =>
      'Entrega de suprimentos confirmada para 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Levantamento com drone concluído - nada encontrado';

  @override
  String get sampleMsgTeamCharlie => 'Equipe solicitando reforço';

  @override
  String get sampleMsgRadioDiscipline =>
      'Todas as unidades: mantenham disciplina de rádio';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENTE: assistência médica necessária no setor 4';

  @override
  String get sampleMsgAdultMale => ' Homem adulto, consciente';

  @override
  String get sampleMsgFireSpotted => 'Incêndio avistado - coordenadas a seguir';

  @override
  String get sampleMsgSpreadingRapidly => ' Se espalhando rapidamente!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORIDADE: necessidade de apoio de helicóptero';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Equipe médica a caminho da sua localização';

  @override
  String get sampleMsgEvacHelicopter =>
      'ETA do helicóptero de evacuação: 10 minutos';

  @override
  String get sampleMsgEmergencyResolved => 'Emergência resolvida - tudo limpo';

  @override
  String get sampleMsgEmergencyStagingArea => ' Área de apoio de emergência';

  @override
  String get sampleMsgEmergencyServices =>
      'Serviços de emergência notificados e em deslocamento';

  @override
  String get sampleAlphaTeamLead => 'Líder da equipe';

  @override
  String get sampleBravoScout => 'Batedor';

  @override
  String get sampleCharlieMedic => 'Paramédico';

  @override
  String get sampleDeltaNavigator => 'Navegador';

  @override
  String get sampleEchoSupport => 'Apoio';

  @override
  String get sampleBaseCommand => 'Comando da base';

  @override
  String get sampleFieldCoordinator => 'Coordenador de campo';

  @override
  String get sampleMedicalTeam => 'Equipe médica';

  @override
  String get mapDrawing => 'Desenho do mapa';

  @override
  String get navigateToDrawing => 'Navegar até o desenho';

  @override
  String get copyCoordinates => 'Copiar coordenadas';

  @override
  String get hideFromMap => 'Ocultar do mapa';

  @override
  String get lineDrawing => 'Desenho de linha';

  @override
  String get rectangleDrawing => 'Desenho de retângulo';

  @override
  String get manualCoordinates => 'Coordenadas manuais';

  @override
  String get enterCoordinatesManually => 'Inserir coordenadas manualmente';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get exampleCoordinates => 'Exemplo: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Compartilhar desenho';

  @override
  String get shareWithAllNearbyDevices =>
      'Compartilhar com todos os dispositivos próximos';

  @override
  String get shareToRoom => 'Compartilhar na sala';

  @override
  String get sendToPersistentStorage =>
      'Enviar para armazenamento persistente da sala';

  @override
  String get deleteDrawingConfirm =>
      'Tem certeza de que deseja excluir este desenho?';

  @override
  String get drawingDeleted => 'Desenho excluído';

  @override
  String yourDrawingsCount(int count) {
    return 'Seus desenhos ($count)';
  }

  @override
  String get shared => 'Compartilhado';

  @override
  String get line => 'Linha';

  @override
  String get rectangle => 'Retângulo';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get currentVersion => 'Atual';

  @override
  String get latestVersion => 'Mais recente';

  @override
  String get downloadUpdate => 'Baixar';

  @override
  String get updateLater => 'Mais tarde';

  @override
  String get cadastralParcels => 'Parcelas cadastrais';

  @override
  String get forestRoads => 'Estradas florestais';

  @override
  String get wmsOverlays => 'Sobreposições WMS';

  @override
  String get hikingTrails => 'Trilhas de caminhada';

  @override
  String get mainRoads => 'Estradas principais';

  @override
  String get houseNumbers => 'Números de porta';

  @override
  String get fireHazardZones => 'Zonas de risco de incêndio';

  @override
  String get historicalFires => 'Incêndios históricos';

  @override
  String get firebreaks => 'Aceiros';

  @override
  String get krasFireZones => 'Zonas de incêndio do Karst';

  @override
  String get placeNames => 'Topônimos';

  @override
  String get municipalityBorders => 'Limites municipais';

  @override
  String get topographicMap => 'Mapa topográfico 1:25000';

  @override
  String get recentMessages => 'Mensagens recentes';

  @override
  String get addChannel => 'Adicionar canal';

  @override
  String get channelName => 'Nome do canal';

  @override
  String get channelNameHint => 'ex.: Equipe de Resgate Alfa';

  @override
  String get channelSecret => 'Segredo do canal';

  @override
  String get channelSecretHint => 'Senha compartilhada para este canal';

  @override
  String get channelSecretHelp =>
      'Este segredo deve ser compartilhado com todos os membros da equipe que precisam de acesso a este canal';

  @override
  String get channelTypesInfo =>
      'Canais hash (#team): o segredo é gerado automaticamente a partir do nome. Mesmo nome = mesmo canal em todos os dispositivos.\n\nCanais privados: use um segredo explícito. Somente quem tiver o segredo poderá entrar.';

  @override
  String get hashChannelInfo =>
      'Canal hash: o segredo será gerado automaticamente a partir do nome do canal. Qualquer pessoa usando o mesmo nome entrará no mesmo canal.';

  @override
  String get channelNameRequired => 'O nome do canal é obrigatório';

  @override
  String get channelNameTooLong =>
      'O nome do canal deve ter no máximo 31 caracteres';

  @override
  String get channelSecretRequired => 'O segredo do canal é obrigatório';

  @override
  String get channelSecretTooLong =>
      'O segredo do canal deve ter no máximo 32 caracteres';

  @override
  String get invalidAsciiCharacters =>
      'Somente caracteres ASCII são permitidos';

  @override
  String get channelCreatedSuccessfully => 'Canal criado com sucesso';

  @override
  String channelCreationFailed(String error) {
    return 'Falha ao criar canal: $error';
  }

  @override
  String get deleteChannel => 'Excluir canal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Tem certeza de que deseja excluir o canal \"$channelName\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get channelDeletedSuccessfully => 'Canal excluído com sucesso';

  @override
  String channelDeletionFailed(String error) {
    return 'Falha ao excluir canal: $error';
  }

  @override
  String get createChannel => 'Criar canal';

  @override
  String get wizardBack => 'Voltar';

  @override
  String get wizardSkip => 'Pular';

  @override
  String get wizardNext => 'Próximo';

  @override
  String get wizardGetStarted => 'Começar';

  @override
  String get wizardWelcomeTitle => 'Bem-vindo ao MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Ver tutorial de boas-vindas';

  @override
  String get allTeamContacts => 'Todos os contatos da equipe';

  @override
  String directMessagesInfo(int count) {
    return 'Mensagens diretas com ACKs. Enviadas para $count membros da equipe.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Marcador SAR enviado para $count contatos';
  }

  @override
  String get noContactsAvailable => 'Nenhum contato da equipe disponível';

  @override
  String get reply => 'Responder';

  @override
  String get technicalDetails => 'Detalhes técnicos';

  @override
  String get messageTechnicalDetails => 'Detalhes técnicos da mensagem';

  @override
  String get linkQuality => 'Qualidade do link';

  @override
  String get delivery => 'Entrega';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Tag ACK esperada';

  @override
  String get roundTrip => 'Ida e volta';

  @override
  String get retryAttempt => 'Tentativa de repetição';

  @override
  String get floodFallback => 'Fallback de flooding';

  @override
  String get identity => 'Identidade';

  @override
  String get messageId => 'ID da mensagem';

  @override
  String get sender => 'Remetente';

  @override
  String get senderKey => 'Chave do remetente';

  @override
  String get recipient => 'Destinatário';

  @override
  String get recipientKey => 'Chave do destinatário';

  @override
  String get voice => 'Voz';

  @override
  String get voiceId => 'ID de voz';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Progresso da sessão';

  @override
  String get complete => 'Concluído';

  @override
  String get rawDump => 'Dump bruto';

  @override
  String get cannotRetryMissingRecipient =>
      'Não é possível repetir: faltam informações do destinatário';

  @override
  String get voiceUnavailable => 'A voz não está disponível no momento';

  @override
  String get requestingVoice => 'Solicitando voz';

  @override
  String get device => 'dispositivo';

  @override
  String get change => 'Alterar';

  @override
  String get wizardOverviewDescription =>
      'Este aplicativo reúne mensagens MeshCore, atualizações SAR em campo, mapas e ferramentas do dispositivo em um só lugar.';

  @override
  String get wizardOverviewFeature1 =>
      'Envie mensagens diretas, publicações em salas e mensagens de canal pela guia principal Mensagens.';

  @override
  String get wizardOverviewFeature2 =>
      'Compartilhe marcadores SAR, desenhos de mapa, clipes de voz e imagens pela malha.';

  @override
  String get wizardOverviewFeature3 =>
      'Conecte-se via BLE ou TCP e depois gerencie o rádio complementar dentro do aplicativo.';

  @override
  String get wizardMessagingTitle => 'Mensagens e relatórios de campo';

  @override
  String get wizardMessagingDescription =>
      'Aqui, as mensagens são mais do que texto simples. O aplicativo já oferece suporte a várias cargas operacionais e fluxos de transferência.';

  @override
  String get wizardMessagingFeature1 =>
      'Envie mensagens diretas, publicações em salas e tráfego de canal a partir de um único compositor.';

  @override
  String get wizardMessagingFeature2 =>
      'Crie atualizações SAR e modelos SAR reutilizáveis para relatórios de campo comuns.';

  @override
  String get wizardMessagingFeature3 =>
      'Transfira sessões de voz e imagens com progresso e estimativas de tempo de transmissão na interface.';

  @override
  String get wizardConnectDeviceTitle => 'Conectar dispositivo';

  @override
  String get wizardConnectDeviceDescription =>
      'Conecte seu rádio MeshCore, escolha um nome e aplique uma predefinição de rádio antes de continuar.';

  @override
  String get wizardSetupBadge => 'Configuração';

  @override
  String get wizardOverviewBadge => 'Visão geral';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Nenhum dispositivo conectado ainda';

  @override
  String get wizardSkipForNow => 'Ignorar por enquanto';

  @override
  String get wizardDeviceNameLabel => 'Nome do dispositivo';

  @override
  String get wizardDeviceNameHelp =>
      'Esse nome é anunciado para outros usuários do MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Região de configuração';

  @override
  String get wizardConfigRegionHelp =>
      'Usa a lista oficial completa de predefinições do MeshCore. O padrão é EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Certifique-se de que a predefinição selecionada corresponda às regulamentações locais de rádio.';

  @override
  String get wizardPresetNote2 =>
      'A lista corresponde ao feed oficial de predefinições da ferramenta de configuração do MeshCore.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) permanece selecionado por padrão durante a configuração inicial.';

  @override
  String get wizardSaving => 'Salvando...';

  @override
  String get wizardSaveAndContinue => 'Salvar e continuar';

  @override
  String get wizardEnterDeviceName =>
      'Digite um nome para o dispositivo antes de continuar.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '$deviceName salvo com $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contatos, salas e repetidores';

  @override
  String get wizardNetworkDescription =>
      'A guia Contatos organiza a rede que você descobre e as rotas aprendidas ao longo do tempo.';

  @override
  String get wizardNetworkFeature1 =>
      'Revise membros da equipe, repetidores, salas, canais e anúncios pendentes em uma única lista.';

  @override
  String get wizardNetworkFeature2 =>
      'Use ping inteligente, login em salas, caminhos aprendidos e ferramentas de redefinição de rota quando a conectividade ficar confusa.';

  @override
  String get wizardNetworkFeature3 =>
      'Crie canais e gerencie destinos de rede sem sair do aplicativo.';

  @override
  String get wizardMapOpsTitle => 'Mapa, trilhas e geometria compartilhada';

  @override
  String get wizardMapOpsDescription =>
      'O mapa do aplicativo está ligado diretamente às mensagens, ao rastreamento e às sobreposições SAR, em vez de ser um visualizador separado.';

  @override
  String get wizardMapOpsFeature1 =>
      'Acompanhe sua própria posição, as localizações da equipe e as trilhas de movimento no mapa.';

  @override
  String get wizardMapOpsFeature2 =>
      'Abra desenhos de mensagens, visualize-os em linha e remova-os do mapa quando necessário.';

  @override
  String get wizardMapOpsFeature3 =>
      'Use vistas de mapa de repetidores e sobreposições compartilhadas para entender o alcance da rede em campo.';

  @override
  String get wizardToolsTitle => 'Ferramentas além das mensagens';

  @override
  String get wizardToolsDescription =>
      'Há mais aqui do que as quatro guias principais. O aplicativo também inclui configuração, diagnóstico e fluxos opcionais de sensores.';

  @override
  String get wizardToolsFeature1 =>
      'Abra a configuração do dispositivo para alterar ajustes de rádio, telemetria, potência TX e detalhes do equipamento complementar.';

  @override
  String get wizardToolsFeature2 =>
      'Ative a guia Sensores quando quiser painéis monitorados e ações de atualização rápida.';

  @override
  String get wizardToolsFeature3 =>
      'Use logs de pacotes, varredura de espectro e diagnóstico de desenvolvedor ao solucionar problemas da malha.';

  @override
  String get postConnectDiscoveryTitle => 'Descobrir repetidores agora?';

  @override
  String get postConnectDiscoveryDescription =>
      'Execute a descoberta de repetidores logo após a conexão para ver os nós MeshCore próximos e adicioná-los à sua rede mais rapidamente.';

  @override
  String get contactInSensors => 'Nos Sensores';

  @override
  String get contactAddToSensors => 'Adicionar aos Sensores';

  @override
  String get contactSetPath => 'Definir rota';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName adicionado a Sensores';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Falha ao limpar a rota: $error';
  }

  @override
  String get contactRouteCleared => 'Rota limpa';

  @override
  String contactRouteSet(String route) {
    return 'Rota definida: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Falha ao definir a rota: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Tempo limite ACK';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Carga útil';

  @override
  String get hops => 'Saltos';

  @override
  String get hashSize => 'Tamanho do hash';

  @override
  String get pathBytes => 'Bytes do caminho';

  @override
  String get selectedPath => 'Caminho selecionado';

  @override
  String get estimatedTx => 'Transmissão estimada';

  @override
  String get senderToReceipt => 'Do remetente ao recibo';

  @override
  String get receivedCopies => 'Cópias recebidas';

  @override
  String get retryCause => 'Causa da nova tentativa';

  @override
  String get retryMode => 'Modo de nova tentativa';

  @override
  String get retryResult => 'Resultado da nova tentativa';

  @override
  String get lastRetry => 'Última tentativa';

  @override
  String get rxPackets => 'Pacotes RX';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Taxa';

  @override
  String get window => 'Janela';

  @override
  String get posttxDelay => 'Atraso pós-tx';

  @override
  String get bandpass => 'Passa-banda';

  @override
  String get bandpassFilterVoice => 'Filtro passa-banda de voz';

  @override
  String get active => 'Ativo';

  @override
  String get addContact => 'Adicionar contacto';

  @override
  String get all => 'Tudo';

  @override
  String get clearAllLabel => 'Limpar tudo';

  @override
  String get clearFilters => 'Limpar filtros';

  @override
  String get clearRoute => 'Limpar rota';

  @override
  String get clearMessages => 'Limpar mensagens';

  @override
  String get clearScale => 'Limpar escala';

  @override
  String get clearDiscoveries => 'Limpar descobertas';

  @override
  String get clearOnlineTraceDatabase => 'Limpar base de dados de rastreio';

  @override
  String get clearAllChannels => 'Limpar todos os canais';

  @override
  String get clearAllContacts => 'Limpar todos os contactos';

  @override
  String get clearChannels => 'Limpar canais';

  @override
  String get clearContacts => 'Limpar contactos';

  @override
  String get clearPathOnMaxRetry => 'Limpar caminho no máx. de tentativas';

  @override
  String get create => 'Criar';

  @override
  String get custom => 'Personalizado';

  @override
  String get defaultValue => 'Padrão';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get editName => 'Editar nome';

  @override
  String get open => 'Abrir';

  @override
  String get paste => 'Colar';

  @override
  String get preview => 'Pré-visualização';

  @override
  String get remove => 'Remover';

  @override
  String get rename => 'Renomear';

  @override
  String get resolveAll => 'Resolver tudo';

  @override
  String get send => 'Enviar';

  @override
  String get sendAnyway => 'Enviar mesmo assim';

  @override
  String get share => 'Partilhar';

  @override
  String get trace => 'Rastreio';

  @override
  String get discovery => 'Descoberta';

  @override
  String get discoverRepeaters => 'Descobrir repetidores';

  @override
  String get discoverSensors => 'Descobrir sensores';

  @override
  String get repeaterDiscoverySent => 'Descoberta de repetidores enviada';

  @override
  String get sensorDiscoverySent => 'Descoberta de sensores enviada';

  @override
  String get clearedPendingDiscoveries => 'Descobertas pendentes limpas.';

  @override
  String get autoDiscovery => 'Descoberta automática';

  @override
  String get enableAutomaticAdding => 'Ativar adição automática';

  @override
  String get autoaddRepeaters => 'Adicionar repetidores automaticamente';

  @override
  String get autoaddRoomServers =>
      'Adicionar servidores de sala automaticamente';

  @override
  String get autoaddSensors => 'Adicionar sensores automaticamente';

  @override
  String get autoaddUsers => 'Adicionar utilizadores automaticamente';

  @override
  String get overwriteOldestWhenFull =>
      'Sobrescrever mais antigos quando cheio';

  @override
  String get storage => 'Armazenamento';

  @override
  String get dangerZone => 'Zona de perigo';

  @override
  String get profiles => 'Perfis';

  @override
  String get favourites => 'Favoritos';

  @override
  String get sensors => 'Sensores';

  @override
  String get others => 'Outros';

  @override
  String get gpsModule => 'Módulo GPS';

  @override
  String get liveTraffic => 'Tráfego ao vivo';

  @override
  String get repeatersMap => 'Mapa de repetidores';

  @override
  String get blePacketLogs => 'Registos de pacotes BLE';

  @override
  String get onlineTraceDatabase => 'Base de dados de rastreio';

  @override
  String get routePathByteSize => 'Tamanho do caminho em bytes';

  @override
  String get messageNotifications => 'Notificações de mensagens';

  @override
  String get sarAlerts => 'Alertas SAR';

  @override
  String get discoveryNotifications => 'Notificações de descoberta';

  @override
  String get updateNotifications => 'Notificações de atualização';

  @override
  String get muteWhileAppIsOpen => 'Silenciar com a app aberta';

  @override
  String get disableContacts => 'Desativar contactos';

  @override
  String get enableSensorsTab => 'Ativar separador Sensores';

  @override
  String get enableProfiles => 'Ativar perfis';

  @override
  String get nearestRepeaterFallback => 'Repetidor mais próximo como reserva';

  @override
  String get deleteAllStoredMessageHistory =>
      'Apagar todo o histórico de mensagens';

  @override
  String get messageFontSize => 'Tamanho da fonte de mensagens';

  @override
  String get rotateMapWithHeading => 'Rodar mapa com direção';

  @override
  String get showMapDebugInfo => 'Mostrar info de depuração do mapa';

  @override
  String get openMapInFullscreen => 'Abrir mapa em ecrã inteiro';

  @override
  String get showSarMarkersLabel => 'Mostrar marcadores SAR';

  @override
  String get hideRepeatersOnMap => 'Ocultar repetidores no mapa';

  @override
  String get setMapScale => 'Definir escala do mapa';

  @override
  String get customMapScaleSaved => 'Escala de mapa personalizada guardada';

  @override
  String get voiceBitrate => 'Taxa de bits de voz';

  @override
  String get voiceCompressor => 'Compressor de voz';

  @override
  String get voiceLimiter => 'Limitador de voz';

  @override
  String get micAutoGain => 'Ganho automático do microfone';

  @override
  String get echoCancellation => 'Cancelamento de eco';

  @override
  String get noiseSuppression => 'Supressão de ruído';

  @override
  String get trimSilenceInVoiceMessages =>
      'Cortar silêncio em mensagens de voz';

  @override
  String get compressor => 'Compressor';

  @override
  String get limiter => 'Limitador';

  @override
  String get autoGain => 'Ganho automático';

  @override
  String get echoCancel => 'Eco';

  @override
  String get noiseSuppress => 'Ruído';

  @override
  String get silenceTrim => 'Silêncio';

  @override
  String get maxImageSize => 'Tamanho máximo de imagem';

  @override
  String get imageCompression => 'Compressão de imagem';

  @override
  String get grayscale => 'Escala de cinzentos';

  @override
  String get ultraMode => 'Modo ultra';

  @override
  String get fastPrivateGpsUpdates => 'Atualizações GPS privadas rápidas';

  @override
  String get movementThreshold => 'Limiar de movimento';

  @override
  String get fastGpsMovementThreshold => 'Limiar de movimento GPS rápido';

  @override
  String get fastGpsActiveuseInterval => 'Intervalo de uso ativo GPS rápido';

  @override
  String get activeuseUpdateInterval => 'Intervalo de atualização de uso ativo';

  @override
  String get repeatNearbyTraffic => 'Repetir tráfego próximo';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Retransmitir através de repetidores na rede';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Apenas próximos, sem flood de repetidores';

  @override
  String get multihop => 'Multi-salto';

  @override
  String get createProfile => 'Criar perfil';

  @override
  String get renameProfile => 'Renomear perfil';

  @override
  String get newProfile => 'Novo perfil';

  @override
  String get manageProfiles => 'Gerir perfis';

  @override
  String get enableProfilesToStartManagingThem =>
      'Ative os perfis para começar a geri-los.';

  @override
  String get openMessage => 'Abrir mensagem';

  @override
  String get jumpToTheRelatedSarMessage => 'Ir para a mensagem SAR relacionada';

  @override
  String get removeSarMarker => 'Remover marcador SAR';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Selecione um destino para enviar o marcador SAR';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'Marcador SAR transmitido no canal público';

  @override
  String get sarMarkerSentToRoom => 'Marcador SAR enviado para a sala';

  @override
  String get loadFromGallery => 'Carregar da galeria';

  @override
  String get replaceImage => 'Substituir imagem';

  @override
  String get selectFromGallery => 'Selecionar da galeria';

  @override
  String get team => 'Equipa';

  @override
  String get found => 'Encontrado';

  @override
  String get staging => 'Área de reunião';

  @override
  String get object => 'Objeto';

  @override
  String get quiet => 'Silencioso';

  @override
  String get busy => 'Ocupado';

  @override
  String get searchMessages => 'Pesquisar mensagens';

  @override
  String get sendImageFromGallery => 'Enviar imagem da galeria';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get allMessages => 'Todas as mensagens';

  @override
  String get sendToPublicChannel => 'Enviar para o canal público?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Selecione tipo de marcador e destino';

  @override
  String get noDestinationsAvailableLabel => 'Nenhum destino disponível';

  @override
  String get image => 'Imagem';

  @override
  String get format => 'Formato';

  @override
  String get dimensions => 'Dimensões';

  @override
  String get segments => 'Segmentos';

  @override
  String get transfers => 'Transferências';

  @override
  String get downloadedBy => 'Transferido por';

  @override
  String get saveDiscoverySettings => 'Guardar definições de descoberta';

  @override
  String get savePublicInfo => 'Guardar informação pública';

  @override
  String get saveRadioSettings => 'Guardar definições de rádio';

  @override
  String get savePath => 'Guardar caminho';

  @override
  String get wipeDeviceData => 'Apagar dados do dispositivo';

  @override
  String get wipeDevice => 'Apagar dispositivo';

  @override
  String get destructiveDeviceActions => 'Ações destrutivas do dispositivo.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Escolha uma predefinição ou ajuste as definições de rádio.';

  @override
  String get used => 'Usado';

  @override
  String get total => 'Total';

  @override
  String get renameValue => 'Renomear valor';

  @override
  String get customizeFields => 'Personalizar campos';

  @override
  String get livePreview => 'Pré-visualização ao vivo';

  @override
  String get refreshSchedule => 'Agenda de atualização';

  @override
  String get noResponse => 'Sem resposta';

  @override
  String get refreshing => 'A atualizar';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Escolha um relay ou nó para observar.';

  @override
  String get publicKeyLabel => 'Chave pública';

  @override
  String get alreadyInContacts => 'Já nos contactos';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Conecte-se a um dispositivo antes de adicionar contactos';

  @override
  String get fromContacts => 'Dos contactos';

  @override
  String get onlineOnly => 'Apenas online';

  @override
  String get inBoth => 'Em ambos';

  @override
  String get source => 'Fonte';

  @override
  String get allMessagesCleared => 'Todas as mensagens limpas';

  @override
  String get onlineTraceDatabaseCleared => 'Base de dados de rastreio limpa';

  @override
  String get packetLogsCleared => 'Registos de pacotes limpos';

  @override
  String get hexDataCopiedToClipboard =>
      'Dados hex copiados para a área de transferência';

  @override
  String get developerModeEnabled => 'Modo de programador ativado';

  @override
  String get developerModeDisabled => 'Modo de programador desativado';

  @override
  String get clipboardIsEmpty => 'A área de transferência está vazia';

  @override
  String get contactImported => 'Contacto importado';

  @override
  String get contactLinkCopiedToClipboard =>
      'Link do contacto copiado para a área de transferência';

  @override
  String get failedToExportContact => 'Falha ao exportar contacto';

  @override
  String get noLogsToExport => 'Sem registos para exportar';

  @override
  String get exportAsCsv => 'Exportar como CSV';

  @override
  String get exportAsText => 'Exportar como texto';

  @override
  String get receivedRfc3339 => 'Recebido (RFC3339)';

  @override
  String get buildTime => 'Hora de compilação';

  @override
  String get downloadUrlNotAvailable => 'URL de download não disponível';

  @override
  String get cannotOpenDownloadUrl => 'Não é possível abrir o URL de download';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'A verificação de atualizações só está disponível no Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Está a usar a versão mais recente';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Atualização disponível mas URL de download não encontrado';

  @override
  String get startTictactoe => 'Iniciar Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe indisponível';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: oponente desconhecido';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: a aguardar início';

  @override
  String get acceptsShareLinks => 'Aceita links partilhados';

  @override
  String get supportsRawHex => 'Suporta hex bruto';

  @override
  String get clipboardfriendly => 'Compatível com a área de transferência';

  @override
  String get captured => 'Capturado';

  @override
  String get size => 'Tamanho';

  @override
  String get noCustomChannelsToClear =>
      'Sem canais personalizados para limpar.';

  @override
  String get noDeviceContactsToClear =>
      'Sem contactos do dispositivo para limpar.';

  @override
  String get aToZ => 'A-Z';

  @override
  String get add => 'Adicionar';

  @override
  String get addAdditionalDetails => 'Adicionar detalhes adicionais';

  @override
  String get addPeer => 'Adicionar par';

  @override
  String get addPeerManually => 'Adicionar par manualmente';

  @override
  String addedToContacts(String name) {
    return '$name adicionado aos contatos';
  }

  @override
  String addedToSensors(String name) {
    return '$name adicionado aos Sensores';
  }

  @override
  String get allowAll => 'Permitir todos';

  @override
  String get anonymousRxStats => 'Estatísticas RX anónimas';

  @override
  String get appearance => 'Aparência';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Telemetria base';

  @override
  String get blePin => 'PIN BLE';

  @override
  String get buzzerAlerts => 'Alertas sonoros';

  @override
  String get cancelImageReceive => 'Cancelar receção de imagem';

  @override
  String get choose => 'Escolher';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Escolher quais separadores e secções de contatos mostrar';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get clearLiveView => 'Limpar vista ao vivo';

  @override
  String get clearLogs => 'Limpar registos';

  @override
  String get clearOfflineCache => 'Limpar cache offline?';

  @override
  String get clearOverlay => 'Limpar sobreposição';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Limpar rota apenas após todas as tentativas falharem';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Codec, bitrate e processamento de áudio';

  @override
  String get connectByIpAddress => 'Conectar por endereço IP';

  @override
  String get controlWhichAlertsYouReceive => 'Controlar quais alertas recebe';

  @override
  String get copyFullHex => 'Copiar hex completo';

  @override
  String get copyRawResponse => 'Copiar resposta bruta';

  @override
  String get couldNotLoadMetHistory =>
      'Não foi possível carregar o histórico MET';

  @override
  String customizeSensor(String name) {
    return 'Personalizar $name';
  }

  @override
  String get data => 'Dados';

  @override
  String get deleteGroup => 'Eliminar grupo';

  @override
  String deleteStyleConfirm(String name) {
    return 'Eliminar $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Eliminar este $type?';
  }

  @override
  String get deny => 'Negar';

  @override
  String get deviceInfo => 'Informações do dispositivo';

  @override
  String get deviceSettings => 'Definições do dispositivo';

  @override
  String get deviceTimeSynced =>
      'Hora do dispositivo sincronizada com este telemóvel.';

  @override
  String get disableFastGpsPublishing => 'Desativar publicação rápida de GPS';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Ecrã, marcadores e base de dados de percursos';

  @override
  String get download => 'Transferir';

  @override
  String get environmentalTelemetry => 'Telemetria ambiental';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Erro ao verificar atualizações: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Erro: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Erro ao abrir transferência: $error';
  }

  @override
  String get exportLogs => 'Exportar registos';

  @override
  String get extraAggressiveAvifCompression =>
      'Compressão AVIF extra-agressiva';

  @override
  String failedToAddContact(String error) {
    return 'Falha ao adicionar contato: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Falha ao adicionar $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Falha ao limpar canais: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Falha ao limpar contatos: $error';
  }

  @override
  String get failedToConnectViaSerial => 'Falha ao conectar via série';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Falha ao carregar imagem de pré-visualização: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Falha ao carregar percurso: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Falha ao enviar marcador SAR: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Falha ao definir modo de alarme: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Falha ao definir modo GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Falha ao sincronizar hora do dispositivo: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Falha ao apagar dados do dispositivo: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Canal alvo de GPS rápido';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Atualizações rápidas, limiares e permissões';

  @override
  String get fetchingCatalog => 'A obter catálogo...';

  @override
  String get fifteenMinutes => '15 minutos';

  @override
  String get fifteenSeconds => '15 segundos';

  @override
  String get filterByDirection => 'Filtrar por direção';

  @override
  String get finish => 'Concluir';

  @override
  String get fiveMinutes => '5 minutos';

  @override
  String get fiveSeconds => '5 segundos';

  @override
  String get fix => 'Correção';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Política de anúncio GPS';

  @override
  String get gpsAndLocation => 'GPS e Localização';

  @override
  String get gpsDiagnostics => 'Diagnósticos GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Ajuda';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Oculto';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Como o rádio adiciona automaticamente nós descobertos.';

  @override
  String get images => 'Imagens';

  @override
  String get importProfile => 'Importar perfil';

  @override
  String get lastFix => 'Última correção';

  @override
  String get latest => 'Mais recente';

  @override
  String get latitude => 'Latitude';

  @override
  String get loadASavedRegion => 'Carregar uma região guardada';

  @override
  String get loading => 'A carregar';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Partilha de localização, hardware e intervalo de atualização.';

  @override
  String get locationTelemetry => 'Telemetria de localização';

  @override
  String get lockDestination => 'Bloquear destino';

  @override
  String get longitude => 'Longitude';

  @override
  String get mapStyle => 'Estilo do mapa';

  @override
  String get max => 'Máx';

  @override
  String get maxZoom => 'Zoom máximo';

  @override
  String get messaging => 'Mensagens';

  @override
  String get metHistory => 'Histórico MET';

  @override
  String get min => 'Mín';

  @override
  String get minZoom => 'Zoom mínimo';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get multiAckMode => 'Modo multi-ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Gestão de espaço de trabalho multi-dispositivo';

  @override
  String get myLocation => 'A minha localização';

  @override
  String get nameAndTelemetryShared =>
      'Nome e telemetria partilhados com outros dispositivos.';

  @override
  String newVersionAvailable(String version) {
    return 'Nova versão: $version';
  }

  @override
  String get newer => 'Mais recente';

  @override
  String get noNeighboursFound => 'Nenhum vizinho encontrado';

  @override
  String get noServersFound => 'Nenhum servidor encontrado';

  @override
  String get notSet => 'Não definido';

  @override
  String get notifications => 'Notificações';

  @override
  String get offZeroSeconds => 'Desligado (0 s)';

  @override
  String get offlineMaps => 'Mapas offline';

  @override
  String get older => 'Mais antigo';

  @override
  String get oneByteMode0 => '1 byte (modo 0)';

  @override
  String get oneHour => '1 hora';

  @override
  String get oneMinute => '1 minuto';

  @override
  String get openPacketLogs => 'Abrir registos de pacotes';

  @override
  String get packetTypeHelp => 'Ajuda sobre tipos de pacotes';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Colar um link de partilha ou anúncio hex';

  @override
  String get pathHash => 'Hash do caminho';

  @override
  String get pathSize => 'Tamanho do caminho';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Polígono';

  @override
  String get rawResponseCopied => 'Resposta bruta copiada';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Reenviar pelo repetidor mais próximo em caso de falha';

  @override
  String get resolveContact => 'Resolver contato';

  @override
  String get routingRetriesAndDestinationLock =>
      'Encaminhamento, tentativas e bloqueio de destino';

  @override
  String get samples => 'Amostras';

  @override
  String get satellites => 'Satélites';

  @override
  String get saving => 'A guardar...';

  @override
  String get search => 'Pesquisar';

  @override
  String get searchByNameOrToken => 'Pesquisar por nome ou token';

  @override
  String get searchDiscoveredNodes => 'Pesquisar nós descobertos';

  @override
  String get searchInCurrentFilter => 'Pesquisar no filtro atual';

  @override
  String get searchLogs => 'Pesquisar registos...';

  @override
  String get searchSensors => 'Pesquisar sensores';

  @override
  String get searchThisSection => 'Pesquisar nesta secção';

  @override
  String get selectedRelays => 'Repetidores selecionados';

  @override
  String get sensor => 'Sensor';

  @override
  String serialError(String error) {
    return 'Erro de série: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Definir caminho para $name';
  }

  @override
  String get shareLiveGps => 'Partilhar GPS ao vivo';

  @override
  String get shareMyTiles => 'Partilhar os meus mosaicos';

  @override
  String get sharingLocationFromPhone =>
      'A partilhar localização neste canal a partir do telemóvel.';

  @override
  String get sharingLocationFromRadio =>
      'A partilhar localização neste canal a partir do rádio.';

  @override
  String signalDbm(String rssi) {
    return 'Sinal $rssi dBm';
  }

  @override
  String get sizeCompressionAndPreview =>
      'Tamanho, compressão e pré-visualização';

  @override
  String get skip => 'Saltar';

  @override
  String get smallerFileSize => 'Tamanho de ficheiro menor';

  @override
  String get sort => 'Ordenar';

  @override
  String get stoppedSharingLocation =>
      'Deixou de partilhar localização neste canal.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Suprimir notificações em primeiro plano';

  @override
  String get tabsAndNavigation => 'Separadores e Navegação';

  @override
  String get templatesAndTutorials => 'Modelos e tutoriais';

  @override
  String get tenMinutes => '10 minutos';

  @override
  String get tenSeconds => '10 segundos';

  @override
  String get testSendUpdate => 'Testar envio de atualização';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Tema, idioma e preferências de apresentação';

  @override
  String get thirtyMinutes => '30 minutos';

  @override
  String get thirtySeconds => '30 segundos';

  @override
  String get threeBytesMode2 => '3 bytes (modo 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Estatísticas de tráfego, histórico de mensagens e ferramentas de programador';

  @override
  String get twoBytesMode1 => '2 bytes (modo 1)';

  @override
  String get twoMinutes => '2 minutos';

  @override
  String get undo => 'Desfazer';

  @override
  String get updated => 'Atualizado';

  @override
  String get useContactFlags => 'Usar bandeiras de contato';

  @override
  String get useSavedCoordinates => 'Usar coordenadas guardadas';

  @override
  String get view => 'Ver';

  @override
  String get viewNeighbours => 'Ver vizinhos';

  @override
  String get viewPublicStats => 'Ver estatísticas públicas';

  @override
  String get setRegionScope => 'Definir âmbito de região';

  @override
  String get regionScope => 'Âmbito de região';

  @override
  String get regionScopeNone => 'Nenhum (global)';

  @override
  String get clearRegionScope => 'Limpar âmbito';

  @override
  String get regionScopeWarning =>
      'Apenas os repetidores que permitem esta região irão retransmitir.';

  @override
  String get discoverRegions => 'Descobrir a partir dos repetidores';

  @override
  String get discoveringRegions => 'A descobrir regiões...';

  @override
  String get enterRegionName => 'Nome da região (ex. auckland)';

  @override
  String get noRegionsFound => 'Nenhuma região encontrada neste repetidor.';

  @override
  String regionScopeSet(String name) {
    return 'Âmbito de região definido para $name';
  }

  @override
  String get regionScopeCleared => 'Âmbito de região limpo';
}
