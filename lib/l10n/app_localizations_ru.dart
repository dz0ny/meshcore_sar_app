// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Сообщения';

  @override
  String get contacts => 'Контакты';

  @override
  String get map => 'Карта';

  @override
  String get settings => 'Настройки';

  @override
  String get connect => 'Подключить';

  @override
  String get disconnect => 'Отключить';

  @override
  String get noDevicesFound => 'Устройства не найдены';

  @override
  String get scanAgain => 'Повторить поиск';

  @override
  String get deviceNotConnected => 'Устройство не подключено';

  @override
  String get locationPermissionDenied => 'Доступ к геолокации запрещён';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Доступ к геолокации запрещён навсегда. Включите его в настройках.';

  @override
  String get locationPermissionRequired =>
      'Доступ к геолокации необходим для GPS-трекинга и координации команды. Вы можете включить его позже в настройках.';

  @override
  String get locationServicesDisabled =>
      'Службы геолокации отключены. Пожалуйста, включите их в настройках.';

  @override
  String get failedToGetGpsLocation => 'Не удалось получить GPS-координаты';

  @override
  String failedToAdvertise(String error) {
    return 'Ошибка трансляции: $error';
  }

  @override
  String get cancelReconnection => 'Отменить переподключение';

  @override
  String get general => 'Основные';

  @override
  String get theme => 'Тема';

  @override
  String get chooseTheme => 'Выбрать тему';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get blueLightTheme => 'Синяя светлая тема';

  @override
  String get blueDarkTheme => 'Синяя тёмная тема';

  @override
  String get sarRed => 'SAR Красная';

  @override
  String get alertEmergencyMode => 'Режим тревоги / ЧС';

  @override
  String get sarGreen => 'SAR Зелёная';

  @override
  String get safeAllClearMode => 'Режим «Всё в порядке»';

  @override
  String get autoSystem => 'Авто (Система)';

  @override
  String get followSystemTheme => 'Следовать системной теме';

  @override
  String get showRxTxIndicators => 'Показывать индикаторы RX/TX';

  @override
  String get disableMap => 'Отключить карту';

  @override
  String get language => 'Язык';

  @override
  String get chooseLanguage => 'Выбрать язык';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get about => 'О приложении';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get aboutMeshCoreSar => 'О MeshCore SAR';

  @override
  String get aboutDescription =>
      'Приложение для поисково-спасательных операций, разработанное для аварийно-спасательных служб. Возможности:\n\n• BLE mesh-сеть для связи между устройствами\n• Офлайн-карты с несколькими вариантами слоёв\n• Отслеживание членов команды в реальном времени\n• Тактические маркеры SAR (найденный человек, пожар, место сбора)\n• Управление контактами и обмен сообщениями\n• GPS-трекинг с показанием курса компаса\n• Кэширование тайлов карт для работы офлайн';

  @override
  String get technologiesUsed => 'Используемые технологии:';

  @override
  String get technologiesList =>
      '• Flutter для кросс-платформенной разработки\n• BLE (Bluetooth Low Energy) для mesh-сети\n• OpenStreetMap для карт\n• Provider для управления состоянием\n• SharedPreferences для локального хранилища';

  @override
  String get moreInfo => 'Подробнее';

  @override
  String get packageName => 'Имя пакета';

  @override
  String get sampleData => 'Тестовые данные';

  @override
  String get sampleDataDescription =>
      'Загрузить или очистить тестовые контакты, сообщения каналов и маркеры SAR';

  @override
  String get loadSampleData => 'Загрузить тестовые данные';

  @override
  String get clearAllData => 'Очистить все данные';

  @override
  String get clearAllDataConfirmTitle => 'Очистить все данные';

  @override
  String get clearAllDataConfirmMessage =>
      'Это удалит все контакты и маркеры SAR. Вы уверены?';

  @override
  String get clear => 'Очистить';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Загружено: $teamCount членов команды, $channelCount каналов, $sarCount маркеров SAR, $messageCount сообщений';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Не удалось загрузить тестовые данные: $error';
  }

  @override
  String get allDataCleared => 'Все данные очищены';

  @override
  String get failedToStartBackgroundTracking =>
      'Не удалось запустить фоновое отслеживание. Проверьте разрешения и BLE-соединение.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Трансляция геолокации: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'PIN-код по умолчанию для устройств без экрана — 123456. Проблемы с сопряжением? Удалите устройство из Bluetooth в системных настройках.';

  @override
  String get noMessagesYet => 'Сообщений пока нет';

  @override
  String get pullDownToSync => 'Потяните вниз для синхронизации сообщений';

  @override
  String get deleteContact => 'Удалить контакт';

  @override
  String get delete => 'Удалить';

  @override
  String get viewOnMap => 'Показать на карте';

  @override
  String get refresh => 'Обновить';

  @override
  String get resetPath => 'Сбросить маршрут (перепроложить)';

  @override
  String copiedToClipboard(String label) {
    return '$label скопировано в буфер обмена';
  }

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String failedToSyncContacts(String error) {
    return 'Не удалось синхронизировать контакты: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Вход выполнен! Ожидание сообщений комнаты...';

  @override
  String get loginFailed => 'Ошибка входа — неверный пароль';

  @override
  String loggingIn(String roomName) {
    return 'Вход в $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Не удалось отправить данные входа: $error';
  }

  @override
  String get lowLocationAccuracy => 'Низкая точность геолокации';

  @override
  String get continue_ => 'Продолжить';

  @override
  String get sendSarMarker => 'Отправить маркер SAR';

  @override
  String get deleteDrawing => 'Удалить рисунок';

  @override
  String get drawingTools => 'Инструменты рисования';

  @override
  String get drawLine => 'Нарисовать линию';

  @override
  String get drawLineDesc => 'Нарисуйте произвольную линию на карте';

  @override
  String get drawRectangle => 'Нарисовать прямоугольник';

  @override
  String get drawRectangleDesc => 'Нарисуйте прямоугольную область на карте';

  @override
  String get measureDistance => 'Измерить расстояние';

  @override
  String get measureDistanceDesc => 'Долгое нажатие на две точки для измерения';

  @override
  String get clearMeasurement => 'Сбросить измерение';

  @override
  String distanceLabel(String distance) {
    return 'Расстояние: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Долгое нажатие для второй точки';

  @override
  String get longPressToStartMeasurement =>
      'Долгое нажатие для установки первой точки';

  @override
  String get longPressToStartNewMeasurement =>
      'Долгое нажатие для начала нового измерения';

  @override
  String get shareDrawings => 'Поделиться рисунками';

  @override
  String get clearAllDrawings => 'Удалить все рисунки';

  @override
  String get completeLine => 'Завершить линию';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Транслировать $count рисун$plural команде';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Удалить все $count рисун$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Удалить все $count рисун$plural с карты?';
  }

  @override
  String get drawing => 'Рисунок';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Поделиться $count рисун$plural';
  }

  @override
  String get showReceivedDrawings => 'Показать полученные рисунки';

  @override
  String get showingAllDrawings => 'Показаны все рисунки';

  @override
  String get showingOnlyYourDrawings => 'Показаны только ваши рисунки';

  @override
  String get showSarMarkers => 'Показать маркеры SAR';

  @override
  String get showingSarMarkers => 'Маркеры SAR отображаются';

  @override
  String get hidingSarMarkers => 'Маркеры SAR скрыты';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get publicChannel => 'Публичный канал';

  @override
  String get broadcastToAll => 'Трансляция всем ближайшим узлам (временно)';

  @override
  String get storedPermanently => 'Сохранено постоянно в комнате';

  @override
  String get notConnectedToDevice => 'Устройство не подключено';

  @override
  String get typeYourMessage => 'Введите сообщение...';

  @override
  String get quickLocationMarker => 'Быстрый маркер местоположения';

  @override
  String get markerType => 'Тип маркера';

  @override
  String get sendTo => 'Отправить в';

  @override
  String get noDestinationsAvailable => 'Нет доступных получателей.';

  @override
  String get selectDestination => 'Выберите получателя...';

  @override
  String get ephemeralBroadcastInfo =>
      'Временно: передаётся по эфиру. Не сохраняется — узлы должны быть онлайн.';

  @override
  String get persistentRoomInfo =>
      'Постоянно: хранится неизменно в комнате. Синхронизируется автоматически и доступно офлайн.';

  @override
  String get location => 'Местоположение';

  @override
  String get fromMap => 'С карты';

  @override
  String get gettingLocation => 'Получение местоположения...';

  @override
  String get locationError => 'Ошибка геолокации';

  @override
  String get retry => 'Повторить';

  @override
  String get refreshLocation => 'Обновить местоположение';

  @override
  String accuracyMeters(int accuracy) {
    return 'Точность: ±$accuracyм';
  }

  @override
  String get notesOptional => 'Заметки (необязательно)';

  @override
  String get addAdditionalInformation =>
      'Добавьте дополнительную информацию...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Точность геолокации: ±$accuracyм. Этого может быть недостаточно для операций SAR.\n\nПродолжить всё равно?';
  }

  @override
  String get loginToRoom => 'Войти в комнату';

  @override
  String get enterPasswordInfo =>
      'Введите пароль для доступа к этой комнате. Пароль будет сохранён для дальнейшего использования.';

  @override
  String get password => 'Пароль';

  @override
  String get enterRoomPassword => 'Введите пароль комнаты';

  @override
  String get loggingInDots => 'Вход...';

  @override
  String get login => 'Войти';

  @override
  String failedToAddRoom(String error) {
    return 'Не удалось добавить комнату на устройство: $error\n\nВозможно, комната ещё не объявила себя.\nПопробуйте подождать, пока комната не выйдет на связь.';
  }

  @override
  String get direct => 'Напрямую';

  @override
  String get flood => 'Широковещательно';

  @override
  String get autoSend => 'Автоотправка';

  @override
  String get autoSendDescription => 'Отправить текущим маршрутом.';

  @override
  String get sendDirect => 'Прямая отправка';

  @override
  String get sendDirectDescription => 'Отправить напрямую этому контакту.';

  @override
  String get sendFlood => 'Отправка лавиной';

  @override
  String get sendFloodDescription => 'Отправить через все ретрансляторы.';

  @override
  String get loggedIn => 'Вход выполнен';

  @override
  String get noGpsData => 'Нет данных GPS';

  @override
  String get distance => 'Расстояние';

  @override
  String directPingTimeout(String name) {
    return 'Таймаут прямого пинга — повтор $name широковещательно...';
  }

  @override
  String pingFailed(String name) {
    return 'Пинг не удался: $name — ответ не получен';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Вы уверены, что хотите удалить \"$name\"?\n\nЭто удалит контакт как из приложения, так и с сопряжённого радиоустройства.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Не удалось удалить контакт: $error';
  }

  @override
  String get type => 'Тип';

  @override
  String get publicKey => 'Публичный ключ';

  @override
  String get lastSeen => 'Последнее появление';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get permissions => 'Разрешения';

  @override
  String get telemetry => 'Телеметрия';

  @override
  String get voltage => 'Напряжение';

  @override
  String get battery => 'Батарея';

  @override
  String get temperature => 'Температура';

  @override
  String get humidity => 'Влажность';

  @override
  String get pressure => 'Давление';

  @override
  String get gpsTelemetry => 'GPS (телеметрия)';

  @override
  String get reLoginToRoom => 'Войти в комнату повторно';

  @override
  String get heading => 'Курс';

  @override
  String get elevation => 'Высота';

  @override
  String get accuracy => 'Точность';

  @override
  String get bearing => 'Азимут';

  @override
  String get direction => 'Направление';

  @override
  String get filterMarkers => 'Фильтр маркеров';

  @override
  String get filterMarkersTooltip => 'Фильтровать маркеры';

  @override
  String get contactsFilter => 'Контакты';

  @override
  String get repeatersFilter => 'Ретрансляторы';

  @override
  String get sarMarkers => 'Маркеры SAR';

  @override
  String get foundPerson => 'Найденный человек';

  @override
  String get fire => 'Пожар';

  @override
  String get stagingArea => 'Место сбора';

  @override
  String get showAll => 'Показать все';

  @override
  String get locationUnavailable => 'Местоположение недоступно';

  @override
  String get ahead => 'впереди';

  @override
  String degreesRight(int degrees) {
    return '$degrees° вправо';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° влево';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Ш: $latitude Д: $longitude';
  }

  @override
  String get noContactsYet => 'Контактов пока нет';

  @override
  String get connectToDeviceToLoadContacts =>
      'Подключите устройство для загрузки контактов';

  @override
  String get teamMembers => 'Члены команды';

  @override
  String get repeaters => 'Ретрансляторы';

  @override
  String get rooms => 'Комнаты';

  @override
  String get channels => 'Каналы';

  @override
  String get selectMapLayer => 'Выбрать слой карты';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Спутник';

  @override
  String get googleHybrid => 'Google Гибрид';

  @override
  String get googleRoadmap => 'Google Дороги';

  @override
  String get googleTerrain => 'Google Рельеф';

  @override
  String get dragToPosition => 'Перетащите для позиционирования';

  @override
  String get createSarMarker => 'Создать маркер SAR';

  @override
  String get compass => 'Компас';

  @override
  String get navigationAndContacts => 'Навигация и контакты';

  @override
  String get sarAlert => 'ТРЕВОГА SAR';

  @override
  String get textCopiedToClipboard => 'Текст скопирован в буфер обмена';

  @override
  String get cannotReplySenderMissing =>
      'Не удаётся ответить: нет информации об отправителе';

  @override
  String get cannotReplyContactNotFound =>
      'Не удаётся ответить: контакт не найден';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get saveAsTemplate => 'Сохранить как шаблон';

  @override
  String get templateSaved => 'Шаблон успешно сохранён';

  @override
  String get templateAlreadyExists => 'Шаблон с таким эмодзи уже существует';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get deleteMessageConfirmation =>
      'Вы уверены, что хотите удалить это сообщение?';

  @override
  String get shareLocation => 'Поделиться местоположением';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nКоординаты: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Местоположение SAR';

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int minutes) {
    return '$minutesм назад';
  }

  @override
  String hoursAgo(int hours) {
    return '$hoursч назад';
  }

  @override
  String daysAgo(int days) {
    return '$daysд назад';
  }

  @override
  String secondsAgo(int seconds) {
    return '$secondsс назад';
  }

  @override
  String get sending => 'Отправка...';

  @override
  String get sent => 'Отправлено';

  @override
  String get delivered => 'Доставлено';

  @override
  String deliveredWithTime(int time) {
    return 'Доставлено ($timeмс)';
  }

  @override
  String get failed => 'Ошибка';

  @override
  String get broadcast => 'Трансляция';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Доставлено $delivered/$total контактам';
  }

  @override
  String get allDelivered => 'Все доставлено';

  @override
  String get recipientDetails => 'Детали получателей';

  @override
  String get pending => 'Ожидание';

  @override
  String get sarMarkerFoundPerson => 'Найденный человек';

  @override
  String get sarMarkerFire => 'Место пожара';

  @override
  String get sarMarkerStagingArea => 'Место сбора';

  @override
  String get sarMarkerObject => 'Найденный объект';

  @override
  String get from => 'От';

  @override
  String get coordinates => 'Координаты';

  @override
  String get tapToViewOnMap => 'Нажмите, чтобы открыть на карте';

  @override
  String get radioSettings => 'Настройки радио';

  @override
  String get frequencyMHz => 'Частота (МГц)';

  @override
  String get bandwidth => 'Полоса пропускания';

  @override
  String get spreadingFactor => 'Коэффициент расширения';

  @override
  String get codingRate => 'Скорость кодирования';

  @override
  String get txPowerDbm => 'Мощность TX (дБм)';

  @override
  String maxPowerDbm(int power) {
    return 'Макс: $power дБм';
  }

  @override
  String get you => 'Вы';

  @override
  String exportFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String importFailed(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get unknown => 'Неизвестно';

  @override
  String get onlineLayers => 'Онлайн-слои';

  @override
  String get locationTrail => 'Трек местоположения';

  @override
  String get showTrailOnMap => 'Показать трек на карте';

  @override
  String get trailVisible => 'Трек отображается на карте';

  @override
  String get trailHiddenRecording => 'Трек скрыт (запись продолжается)';

  @override
  String get duration => 'Продолжительность';

  @override
  String get points => 'Точки';

  @override
  String get clearTrail => 'Очистить трек';

  @override
  String get clearTrailQuestion => 'Очистить трек?';

  @override
  String get clearTrailConfirmation =>
      'Вы уверены, что хотите очистить текущий трек? Это действие нельзя отменить.';

  @override
  String get noTrailRecorded => 'Трек ещё не записан';

  @override
  String get startTrackingToRecord =>
      'Запустите отслеживание геолокации для записи трека';

  @override
  String get trailControls => 'Управление треком';

  @override
  String get model => 'Модель';

  @override
  String get version => 'Версия';

  @override
  String get maxContacts => 'Макс. контактов';

  @override
  String get maxChannels => 'Макс. каналов';

  @override
  String get publicInfo => 'Публичная информация';

  @override
  String get useCurrentLocation => 'Использовать текущее местоположение';

  @override
  String get noneUnknown => 'Нет/Неизвестно';

  @override
  String get chatNode => 'Узел чата';

  @override
  String get repeater => 'Ретранслятор';

  @override
  String get roomChannel => 'Комната/Канал';

  @override
  String typeNumber(int number) {
    return 'Тип $number';
  }

  @override
  String failedToSave(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Не удалось получить местоположение: $error';
  }

  @override
  String get sarTemplates => 'Шаблоны SAR';

  @override
  String get addTemplate => 'Добавить шаблон';

  @override
  String get editTemplate => 'Изменить шаблон';

  @override
  String get deleteTemplate => 'Удалить шаблон';

  @override
  String get templateName => 'Название шаблона';

  @override
  String get templateNameHint => 'например, Найденный человек';

  @override
  String get templateEmoji => 'Эмодзи';

  @override
  String get emojiRequired => 'Требуется эмодзи';

  @override
  String get nameRequired => 'Требуется название';

  @override
  String get templateDescription => 'Описание (необязательно)';

  @override
  String get templateDescriptionHint => 'Добавьте дополнительный контекст...';

  @override
  String get templateColor => 'Цвет';

  @override
  String get previewFormat => 'Предпросмотр (формат сообщения SAR)';

  @override
  String get importFromClipboard => 'Импорт';

  @override
  String get exportToClipboard => 'Экспорт';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Удалить шаблон \'$name\'?';
  }

  @override
  String get templateAdded => 'Шаблон добавлен';

  @override
  String get templateUpdated => 'Шаблон обновлён';

  @override
  String get templateDeleted => 'Шаблон удалён';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count шаблонов',
      one: 'Импортирован 1 шаблон',
      zero: 'Шаблоны не импортированы',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count шаблонов экспортировано в буфер обмена',
      one: '1 шаблон экспортирован в буфер обмена',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Сбросить до умолчаний';

  @override
  String get resetToDefaultsConfirmation =>
      'Все пользовательские шаблоны будут удалены и восстановлены 4 шаблона по умолчанию. Продолжить?';

  @override
  String get reset => 'Сбросить';

  @override
  String get resetComplete => 'Шаблоны сброшены до умолчаний';

  @override
  String get noTemplates => 'Шаблоны недоступны';

  @override
  String get tapAddToCreate => 'Нажмите +, чтобы создать первый шаблон';

  @override
  String get ok => 'ОК';

  @override
  String get locationPermission => 'Разрешение геолокации';

  @override
  String get checking => 'Проверка...';

  @override
  String get locationPermissionGrantedAlways => 'Разрешено (всегда)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Разрешено (при использовании)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Запрещено — нажмите для запроса';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Запрещено навсегда — откройте настройки';

  @override
  String get locationPermissionDialogContent =>
      'Доступ к геолокации запрещён навсегда. Включите его в настройках устройства для GPS-трекинга и обмена местоположением.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get locationPermissionGranted => 'Разрешение геолокации получено!';

  @override
  String get locationPermissionRequiredForGps =>
      'Разрешение геолокации необходимо для GPS-трекинга и обмена местоположением.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Разрешение геолокации уже предоставлено.';

  @override
  String get sarNavyBlue => 'SAR Тёмно-синяя';

  @override
  String get sarNavyBlueDescription => 'Профессиональный / оперативный режим';

  @override
  String get selectRecipient => 'Выбрать получателя';

  @override
  String get broadcastToAllNearby => 'Трансляция всем ближайшим';

  @override
  String get searchRecipients => 'Поиск получателей...';

  @override
  String get noContactsFound => 'Контакты не найдены';

  @override
  String get noRoomsFound => 'Комнаты не найдены';

  @override
  String get noRecipientsAvailable => 'Нет доступных получателей';

  @override
  String get noChannelsFound => 'Каналы не найдены';

  @override
  String get newMessage => 'Новое сообщение';

  @override
  String get channel => 'Канал';

  @override
  String get samplePoliceLead => 'Руководитель группы полиции';

  @override
  String get sampleDroneOperator => 'Оператор дрона';

  @override
  String get sampleFirefighterAlpha => 'Пожарный';

  @override
  String get sampleMedicCharlie => 'Медик';

  @override
  String get sampleCommandDelta => 'Командование';

  @override
  String get sampleFireEngine => 'Пожарная машина';

  @override
  String get sampleAirSupport => 'Авиационная поддержка';

  @override
  String get sampleBaseCoordinator => 'Базовый координатор';

  @override
  String get channelEmergency => 'Аварийный';

  @override
  String get channelCoordination => 'Координация';

  @override
  String get channelUpdates => 'Обновления';

  @override
  String get sampleTeamMember => 'Тестовый член команды';

  @override
  String get sampleScout => 'Тестовый разведчик';

  @override
  String get sampleBase => 'Тестовая база';

  @override
  String get sampleSearcher => 'Тестовый поисковик';

  @override
  String get sampleObjectBackpack => ' Найден рюкзак синего цвета';

  @override
  String get sampleObjectVehicle =>
      ' Брошенный автомобиль — установить владельца';

  @override
  String get sampleObjectCamping => ' Обнаружено туристическое снаряжение';

  @override
  String get sampleObjectTrailMarker => ' Указатель тропы найден вне маршрута';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Всем группам: сообщить о готовности';

  @override
  String get sampleMsgWeatherUpdate => 'Погода: ясно, температура 18°C';

  @override
  String get sampleMsgBaseCamp => 'Базовый лагерь развёрнут у места сбора';

  @override
  String get sampleMsgTeamAlpha => 'Группа выдвигается в сектор 2';

  @override
  String get sampleMsgRadioCheck => 'Проверка связи — всем станциям ответить';

  @override
  String get sampleMsgWaterSupply => 'Вода доступна на контрольной точке 3';

  @override
  String get sampleMsgTeamBravo => 'Группа докладывает: сектор 1 чист';

  @override
  String get sampleMsgEtaRallyPoint => 'Прибытие на место сбора: 15 минут';

  @override
  String get sampleMsgSupplyDrop => 'Сброс снаряжения подтверждён на 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Разведка дроном завершена — ничего не обнаружено';

  @override
  String get sampleMsgTeamCharlie => 'Группа запрашивает подкрепление';

  @override
  String get sampleMsgRadioDiscipline =>
      'Всем подразделениям: соблюдать радиодисциплину';

  @override
  String get sampleMsgUrgentMedical =>
      'СРОЧНО: нужна медицинская помощь в секторе 4';

  @override
  String get sampleMsgAdultMale => ' Взрослый мужчина, в сознании';

  @override
  String get sampleMsgFireSpotted => 'Обнаружен пожар — координаты следуют';

  @override
  String get sampleMsgSpreadingRapidly => ' Распространяется быстро!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'ПРИОРИТЕТ: нужна поддержка вертолёта';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Медицинская группа движется к вашему местоположению';

  @override
  String get sampleMsgEvacHelicopter =>
      'Вертолёт эвакуации: прибытие через 10 минут';

  @override
  String get sampleMsgEmergencyResolved =>
      'Чрезвычайная ситуация ликвидирована — опасности нет';

  @override
  String get sampleMsgEmergencyStagingArea => ' Аварийное место сбора';

  @override
  String get sampleMsgEmergencyServices =>
      'Аварийные службы уведомлены и реагируют';

  @override
  String get sampleAlphaTeamLead => 'Руководитель группы';

  @override
  String get sampleBravoScout => 'Разведчик';

  @override
  String get sampleCharlieMedic => 'Медик';

  @override
  String get sampleDeltaNavigator => 'Навигатор';

  @override
  String get sampleEchoSupport => 'Поддержка';

  @override
  String get sampleBaseCommand => 'Базовое командование';

  @override
  String get sampleFieldCoordinator => 'Полевой координатор';

  @override
  String get sampleMedicalTeam => 'Медицинская группа';

  @override
  String get mapDrawing => 'Рисунок на карте';

  @override
  String get navigateToDrawing => 'Перейти к рисунку';

  @override
  String get copyCoordinates => 'Копировать координаты';

  @override
  String get hideFromMap => 'Скрыть с карты';

  @override
  String get lineDrawing => 'Линия';

  @override
  String get rectangleDrawing => 'Прямоугольник';

  @override
  String get manualCoordinates => 'Ввод координат вручную';

  @override
  String get enterCoordinatesManually => 'Ввести координаты вручную';

  @override
  String get latitudeLabel => 'Широта';

  @override
  String get longitudeLabel => 'Долгота';

  @override
  String get exampleCoordinates => 'Пример: 55.7558, 37.6173';

  @override
  String get shareDrawing => 'Поделиться рисунком';

  @override
  String get shareWithAllNearbyDevices =>
      'Поделиться со всеми ближайшими устройствами';

  @override
  String get shareToRoom => 'Отправить в комнату';

  @override
  String get sendToPersistentStorage =>
      'Отправить в постоянное хранилище комнаты';

  @override
  String get deleteDrawingConfirm =>
      'Вы уверены, что хотите удалить этот рисунок?';

  @override
  String get drawingDeleted => 'Рисунок удалён';

  @override
  String yourDrawingsCount(int count) {
    return 'Ваши рисунки ($count)';
  }

  @override
  String get shared => 'Передано';

  @override
  String get line => 'Линия';

  @override
  String get rectangle => 'Прямоугольник';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get currentVersion => 'Текущая';

  @override
  String get latestVersion => 'Последняя';

  @override
  String get downloadUpdate => 'Скачать';

  @override
  String get updateLater => 'Позже';

  @override
  String get cadastralParcels => 'Кадастровые участки';

  @override
  String get forestRoads => 'Лесные дороги';

  @override
  String get wmsOverlays => 'WMS-наложения';

  @override
  String get hikingTrails => 'Туристические маршруты';

  @override
  String get mainRoads => 'Главные дороги';

  @override
  String get houseNumbers => 'Номера домов';

  @override
  String get fireHazardZones => 'Пожароопасные зоны';

  @override
  String get historicalFires => 'Исторические пожары';

  @override
  String get firebreaks => 'Противопожарные просеки';

  @override
  String get krasFireZones => 'Пожарные зоны Краса';

  @override
  String get placeNames => 'Названия мест';

  @override
  String get municipalityBorders => 'Границы муниципалитетов';

  @override
  String get topographicMap => 'Топографическая карта 1:25000';

  @override
  String get recentMessages => 'Последние сообщения';

  @override
  String get addChannel => 'Добавить канал';

  @override
  String get channelName => 'Название канала';

  @override
  String get channelNameHint => 'например, Группа спасения Альфа';

  @override
  String get channelSecret => 'Секрет канала';

  @override
  String get channelSecretHint => 'Общий пароль для этого канала';

  @override
  String get channelSecretHelp =>
      'Этот секрет необходимо передать всем членам команды, которым нужен доступ к каналу';

  @override
  String get channelTypesInfo =>
      'Hash-каналы (#команда): секрет генерируется из названия автоматически. Одно название = один канал на всех устройствах.\n\nЗакрытые каналы: используется явный секрет. Войти могут только те, у кого есть секрет.';

  @override
  String get hashChannelInfo =>
      'Hash-канал: секрет будет автоматически создан из названия. Все, кто использует одно и то же имя, окажутся в одном канале.';

  @override
  String get channelNameRequired => 'Требуется название канала';

  @override
  String get channelNameTooLong =>
      'Название канала не должно превышать 31 символ';

  @override
  String get channelSecretRequired => 'Требуется секрет канала';

  @override
  String get channelSecretTooLong =>
      'Секрет канала не должен превышать 32 символа';

  @override
  String get invalidAsciiCharacters => 'Разрешены только символы ASCII';

  @override
  String get channelCreatedSuccessfully => 'Канал успешно создан';

  @override
  String channelCreationFailed(String error) {
    return 'Не удалось создать канал: $error';
  }

  @override
  String get deleteChannel => 'Удалить канал';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Вы уверены, что хотите удалить канал \"$channelName\"? Это действие нельзя отменить.';
  }

  @override
  String get channelDeletedSuccessfully => 'Канал успешно удалён';

  @override
  String channelDeletionFailed(String error) {
    return 'Не удалось удалить канал: $error';
  }

  @override
  String get createChannel => 'Создать канал';

  @override
  String get wizardBack => 'Назад';

  @override
  String get wizardSkip => 'Пропустить';

  @override
  String get wizardNext => 'Далее';

  @override
  String get wizardGetStarted => 'Начать';

  @override
  String get wizardWelcomeTitle => 'Добро пожаловать в MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Просмотреть обучение';

  @override
  String get allTeamContacts => 'Все контакты команды';

  @override
  String directMessagesInfo(int count) {
    return 'Личные сообщения с подтверждением. Отправлено $count членам команды.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Маркер SAR отправлен $count контактам';
  }

  @override
  String get noContactsAvailable => 'Нет доступных контактов команды';

  @override
  String get reply => 'Ответить';

  @override
  String get technicalDetails => 'Технические детали';

  @override
  String get messageTechnicalDetails => 'Технические детали сообщения';

  @override
  String get linkQuality => 'Качество связи';

  @override
  String get delivery => 'Доставка';

  @override
  String get status => 'Статус';

  @override
  String get expectedAckTag => 'Ожидаемый тег ACK';

  @override
  String get roundTrip => 'Время отклика';

  @override
  String get retryAttempt => 'Попытка повтора';

  @override
  String get floodFallback => 'Широковещательный резерв';

  @override
  String get identity => 'Идентификатор';

  @override
  String get messageId => 'ID сообщения';

  @override
  String get sender => 'Отправитель';

  @override
  String get senderKey => 'Ключ отправителя';

  @override
  String get recipient => 'Получатель';

  @override
  String get recipientKey => 'Ключ получателя';

  @override
  String get voice => 'Голос';

  @override
  String get voiceId => 'ID голоса';

  @override
  String get envelope => 'Конверт';

  @override
  String get sessionProgress => 'Прогресс сессии';

  @override
  String get complete => 'Завершено';

  @override
  String get rawDump => 'Необработанные данные';

  @override
  String get cannotRetryMissingRecipient =>
      'Повтор невозможен: нет информации о получателе';

  @override
  String get voiceUnavailable => 'Голос сейчас недоступен';

  @override
  String get requestingVoice => 'Запрос голоса';

  @override
  String get device => 'устройство';

  @override
  String get change => 'Изменить';

  @override
  String get wizardOverviewDescription =>
      'Это приложение объединяет сообщения MeshCore, полевые обновления SAR, карты и инструменты устройства в одном месте.';

  @override
  String get wizardOverviewFeature1 =>
      'Отправляйте личные сообщения, сообщения комнат и сообщения каналов из основной вкладки «Сообщения».';

  @override
  String get wizardOverviewFeature2 =>
      'Делитесь SAR-маркерами, рисунками на карте, голосовыми клипами и изображениями через mesh-сеть.';

  @override
  String get wizardOverviewFeature3 =>
      'Подключайтесь по BLE или TCP, а затем управляйте сопутствующей радиостанцией прямо из приложения.';

  @override
  String get wizardMessagingTitle => 'Сообщения и полевые отчёты';

  @override
  String get wizardMessagingDescription =>
      'Здесь сообщения это больше, чем просто текст. Приложение уже поддерживает несколько видов операционных данных и сценариев передачи.';

  @override
  String get wizardMessagingFeature1 =>
      'Отправляйте личные сообщения, сообщения комнат и трафик каналов из одного редактора.';

  @override
  String get wizardMessagingFeature2 =>
      'Создавайте обновления SAR и повторно используемые шаблоны SAR для типовых полевых отчётов.';

  @override
  String get wizardMessagingFeature3 =>
      'Передавайте голосовые сессии и изображения с индикатором прогресса и оценкой эфирного времени в интерфейсе.';

  @override
  String get wizardConnectDeviceTitle => 'Подключить устройство';

  @override
  String get wizardConnectDeviceDescription =>
      'Подключите свою радиостанцию MeshCore, выберите имя и примените радиопрофиль перед продолжением.';

  @override
  String get wizardSetupBadge => 'Настройка';

  @override
  String get wizardOverviewBadge => 'Обзор';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Подключено к $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Устройство ещё не подключено';

  @override
  String get wizardSkipForNow => 'Пропустить пока';

  @override
  String get wizardDeviceNameLabel => 'Имя устройства';

  @override
  String get wizardDeviceNameHelp =>
      'Это имя транслируется другим пользователям MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Регион конфигурации';

  @override
  String get wizardConfigRegionHelp =>
      'Используется полный официальный список профилей MeshCore. По умолчанию выбран EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Убедитесь, что выбранный профиль соответствует местным радиоправилам.';

  @override
  String get wizardPresetNote2 =>
      'Список соответствует официальному потоку профилей инструмента MeshCore config.';

  @override
  String get wizardPresetNote3 =>
      'Для онбординга по умолчанию остаётся выбран EU/UK (Narrow).';

  @override
  String get wizardSaving => 'Сохранение...';

  @override
  String get wizardSaveAndContinue => 'Сохранить и продолжить';

  @override
  String get wizardEnterDeviceName =>
      'Введите имя устройства перед продолжением.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Сохранено: $deviceName, профиль $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Контакты, комнаты и ретрансляторы';

  @override
  String get wizardNetworkDescription =>
      'Вкладка «Контакты» организует сеть, которую вы обнаруживаете, и маршруты, которые вы узнаёте со временем.';

  @override
  String get wizardNetworkFeature1 =>
      'Просматривайте участников команды, ретрансляторы, комнаты, каналы и ожидающие объявления в одном списке.';

  @override
  String get wizardNetworkFeature2 =>
      'Используйте smart ping, вход в комнаты, изученные пути и инструменты сброса маршрутов, когда связь становится нестабильной.';

  @override
  String get wizardNetworkFeature3 =>
      'Создавайте каналы и управляйте сетевыми назначениями, не покидая приложение.';

  @override
  String get wizardMapOpsTitle => 'Карта, следы и общая геометрия';

  @override
  String get wizardMapOpsDescription =>
      'Карта приложения напрямую связана с сообщениями, отслеживанием и SAR-слоями, а не является отдельным просмотрщиком.';

  @override
  String get wizardMapOpsFeature1 =>
      'Отслеживайте свою позицию, местоположение команды и траектории движения на карте.';

  @override
  String get wizardMapOpsFeature2 =>
      'Открывайте рисунки из сообщений, просматривайте их прямо в интерфейсе и удаляйте с карты при необходимости.';

  @override
  String get wizardMapOpsFeature3 =>
      'Используйте карты ретрансляторов и общие слои, чтобы понимать покрытие сети в поле.';

  @override
  String get wizardToolsTitle => 'Инструменты помимо сообщений';

  @override
  String get wizardToolsDescription =>
      'Здесь есть больше, чем четыре основные вкладки. Приложение также включает настройку, диагностику и необязательные сценарии датчиков.';

  @override
  String get wizardToolsFeature1 =>
      'Откройте настройки устройства, чтобы изменить параметры радио, телеметрию, мощность TX и сведения о сопутствующем устройстве.';

  @override
  String get wizardToolsFeature2 =>
      'Включите вкладку «Датчики», если нужны панели наблюдаемых датчиков и быстрые действия обновления.';

  @override
  String get wizardToolsFeature3 =>
      'Используйте журналы пакетов, сканирование спектра и диагностику разработчика для устранения проблем mesh-сети.';

  @override
  String get postConnectDiscoveryTitle => 'Обнаружить ретрансляторы сейчас?';

  @override
  String get postConnectDiscoveryDescription =>
      'Запустите обнаружение ретрансляторов сразу после подключения, чтобы увидеть ближайшие узлы MeshCore и быстрее добавить их в свою сеть.';

  @override
  String get contactInSensors => 'В датчиках';

  @override
  String get contactAddToSensors => 'Добавить в датчики';

  @override
  String get contactSetPath => 'Задать путь';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName добавлен в Датчики';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Не удалось очистить маршрут: $error';
  }

  @override
  String get contactRouteCleared => 'Маршрут очищен';

  @override
  String contactRouteSet(String route) {
    return 'Маршрут задан: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Не удалось задать маршрут: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Таймаут ACK';

  @override
  String get opcode => 'Опкод';

  @override
  String get payload => 'Полезная нагрузка';

  @override
  String get hops => 'Хопы';

  @override
  String get hashSize => 'Размер хеша';

  @override
  String get pathBytes => 'Байты пути';

  @override
  String get selectedPath => 'Выбранный путь';

  @override
  String get estimatedTx => 'Ожидаемая передача';

  @override
  String get senderToReceipt => 'От отправителя до получения';

  @override
  String get receivedCopies => 'Полученные копии';

  @override
  String get retryCause => 'Причина повтора';

  @override
  String get retryMode => 'Режим повтора';

  @override
  String get retryResult => 'Результат повтора';

  @override
  String get lastRetry => 'Последний повтор';

  @override
  String get rxPackets => 'RX-пакеты';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Скорость';

  @override
  String get window => 'Окно';

  @override
  String get posttxDelay => 'Задержка после передачи';

  @override
  String get bandpass => 'Полосовой';

  @override
  String get bandpassFilterVoice => 'Полосовой фильтр голоса';

  @override
  String get active => 'Активно';

  @override
  String get addContact => 'Добавить контакт';

  @override
  String get all => 'Все';

  @override
  String get clearAllLabel => 'Очистить все';

  @override
  String get clearFilters => 'Очистить фильтры';

  @override
  String get clearRoute => 'Очистить маршрут';

  @override
  String get clearMessages => 'Очистить сообщения';

  @override
  String get clearScale => 'Очистить масштаб';

  @override
  String get clearDiscoveries => 'Очистить обнаружения';

  @override
  String get clearOnlineTraceDatabase => 'Очистить базу трассировок';

  @override
  String get clearAllChannels => 'Очистить все каналы';

  @override
  String get clearAllContacts => 'Очистить все контакты';

  @override
  String get clearChannels => 'Очистить каналы';

  @override
  String get clearContacts => 'Очистить контакты';

  @override
  String get clearPathOnMaxRetry => 'Очистить путь при макс. повторе';

  @override
  String get create => 'Создать';

  @override
  String get custom => 'Пользовательский';

  @override
  String get defaultValue => 'По умолчанию';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get editName => 'Редактировать имя';

  @override
  String get open => 'Открыть';

  @override
  String get paste => 'Вставить';

  @override
  String get preview => 'Предпросмотр';

  @override
  String get remove => 'Удалить';

  @override
  String get rename => 'Переименовать';

  @override
  String get resolveAll => 'Разрешить все';

  @override
  String get send => 'Отправить';

  @override
  String get sendAnyway => 'Отправить все равно';

  @override
  String get share => 'Поделиться';

  @override
  String get trace => 'Трассировка';

  @override
  String get discovery => 'Обнаружение';

  @override
  String get discoverRepeaters => 'Обнаружить повторители';

  @override
  String get discoverSensors => 'Обнаружить датчики';

  @override
  String get repeaterDiscoverySent => 'Обнаружение повторителей отправлено';

  @override
  String get sensorDiscoverySent => 'Обнаружение датчиков отправлено';

  @override
  String get clearedPendingDiscoveries => 'Ожидающие обнаружения очищены.';

  @override
  String get autoDiscovery => 'Автоматическое обнаружение';

  @override
  String get enableAutomaticAdding => 'Включить автоматическое добавление';

  @override
  String get autoaddRepeaters => 'Автодобавление повторителей';

  @override
  String get autoaddRoomServers => 'Автодобавление серверов комнат';

  @override
  String get autoaddSensors => 'Автодобавление датчиков';

  @override
  String get autoaddUsers => 'Автодобавление пользователей';

  @override
  String get overwriteOldestWhenFull => 'Перезаписать старейшие при заполнении';

  @override
  String get storage => 'Хранилище';

  @override
  String get dangerZone => 'Опасная зона';

  @override
  String get profiles => 'Профили';

  @override
  String get favourites => 'Избранное';

  @override
  String get sensors => 'Датчики';

  @override
  String get others => 'Другие';

  @override
  String get gpsModule => 'Модуль GPS';

  @override
  String get liveTraffic => 'Живой трафик';

  @override
  String get repeatersMap => 'Карта повторителей';

  @override
  String get blePacketLogs => 'Журналы BLE-пакетов';

  @override
  String get onlineTraceDatabase => 'База трассировок';

  @override
  String get routePathByteSize => 'Размер пути в байтах';

  @override
  String get messageNotifications => 'Уведомления о сообщениях';

  @override
  String get sarAlerts => 'SAR-оповещения';

  @override
  String get discoveryNotifications => 'Уведомления об обнаружении';

  @override
  String get updateNotifications => 'Уведомления об обновлениях';

  @override
  String get muteWhileAppIsOpen => 'Без звука при открытом приложении';

  @override
  String get disableContacts => 'Отключить контакты';

  @override
  String get enableSensorsTab => 'Включить вкладку Датчики';

  @override
  String get enableProfiles => 'Включить профили';

  @override
  String get nearestRepeaterFallback => 'Ближайший повторитель как резерв';

  @override
  String get deleteAllStoredMessageHistory => 'Удалить всю историю сообщений';

  @override
  String get messageFontSize => 'Размер шрифта сообщений';

  @override
  String get rotateMapWithHeading => 'Вращать карту по направлению';

  @override
  String get showMapDebugInfo => 'Показать отладочную информацию карты';

  @override
  String get openMapInFullscreen => 'Открыть карту на весь экран';

  @override
  String get showSarMarkersLabel => 'Показать SAR-маркеры';

  @override
  String get hideRepeatersOnMap => 'Скрыть повторители на карте';

  @override
  String get setMapScale => 'Установить масштаб карты';

  @override
  String get customMapScaleSaved => 'Пользовательский масштаб карты сохранён';

  @override
  String get voiceBitrate => 'Битрейт голоса';

  @override
  String get voiceCompressor => 'Компрессор голоса';

  @override
  String get voiceLimiter => 'Лимитер голоса';

  @override
  String get micAutoGain => 'Автоусиление микрофона';

  @override
  String get echoCancellation => 'Подавление эха';

  @override
  String get noiseSuppression => 'Подавление шума';

  @override
  String get trimSilenceInVoiceMessages =>
      'Обрезать тишину в голосовых сообщениях';

  @override
  String get compressor => 'Компрессор';

  @override
  String get limiter => 'Лимитер';

  @override
  String get autoGain => 'Автоусиление';

  @override
  String get echoCancel => 'Эхо';

  @override
  String get noiseSuppress => 'Шум';

  @override
  String get silenceTrim => 'Тишина';

  @override
  String get maxImageSize => 'Максимальный размер изображения';

  @override
  String get imageCompression => 'Сжатие изображения';

  @override
  String get grayscale => 'Оттенки серого';

  @override
  String get ultraMode => 'Режим ультра';

  @override
  String get fastPrivateGpsUpdates => 'Быстрые приватные GPS-обновления';

  @override
  String get movementThreshold => 'Порог движения';

  @override
  String get fastGpsMovementThreshold => 'Порог движения быстрого GPS';

  @override
  String get fastGpsActiveuseInterval =>
      'Интервал активного использования быстрого GPS';

  @override
  String get activeuseUpdateInterval =>
      'Интервал обновления при активном использовании';

  @override
  String get repeatNearbyTraffic => 'Повторять ближний трафик';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Ретранслировать через повторители по сети';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Только рядом, без flood повторителей';

  @override
  String get multihop => 'Многохоповый';

  @override
  String get createProfile => 'Создать профиль';

  @override
  String get renameProfile => 'Переименовать профиль';

  @override
  String get newProfile => 'Новый профиль';

  @override
  String get manageProfiles => 'Управление профилями';

  @override
  String get enableProfilesToStartManagingThem =>
      'Включите профили, чтобы начать управлять ими.';

  @override
  String get openMessage => 'Открыть сообщение';

  @override
  String get jumpToTheRelatedSarMessage => 'Перейти к связанному SAR-сообщению';

  @override
  String get removeSarMarker => 'Удалить SAR-маркер';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Выберите назначение для отправки SAR-маркера';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR-маркер отправлен в публичный канал';

  @override
  String get sarMarkerSentToRoom => 'SAR-маркер отправлен в комнату';

  @override
  String get loadFromGallery => 'Загрузить из галереи';

  @override
  String get replaceImage => 'Заменить изображение';

  @override
  String get selectFromGallery => 'Выбрать из галереи';

  @override
  String get team => 'Команда';

  @override
  String get found => 'Найдено';

  @override
  String get staging => 'Место сбора';

  @override
  String get object => 'Объект';

  @override
  String get quiet => 'Тихо';

  @override
  String get busy => 'Занято';

  @override
  String get searchMessages => 'Поиск сообщений';

  @override
  String get sendImageFromGallery => 'Отправить изображение из галереи';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get allMessages => 'Все сообщения';

  @override
  String get sendToPublicChannel => 'Отправить в публичный канал?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Выберите тип маркера и назначение';

  @override
  String get noDestinationsAvailableLabel => 'Нет доступных назначений';

  @override
  String get image => 'Изображение';

  @override
  String get format => 'Формат';

  @override
  String get dimensions => 'Размеры';

  @override
  String get segments => 'Сегменты';

  @override
  String get transfers => 'Передачи';

  @override
  String get downloadedBy => 'Загружено';

  @override
  String get saveDiscoverySettings => 'Сохранить настройки обнаружения';

  @override
  String get savePublicInfo => 'Сохранить публичную информацию';

  @override
  String get saveRadioSettings => 'Сохранить настройки радио';

  @override
  String get savePath => 'Сохранить путь';

  @override
  String get wipeDeviceData => 'Стереть данные устройства';

  @override
  String get wipeDevice => 'Стереть устройство';

  @override
  String get destructiveDeviceActions => 'Деструктивные действия устройства.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Выберите пресет или настройте радио вручную.';

  @override
  String get used => 'Использовано';

  @override
  String get total => 'Всего';

  @override
  String get renameValue => 'Переименовать значение';

  @override
  String get customizeFields => 'Настроить поля';

  @override
  String get livePreview => 'Предпросмотр в реальном времени';

  @override
  String get refreshSchedule => 'Расписание обновления';

  @override
  String get noResponse => 'Нет ответа';

  @override
  String get refreshing => 'Обновление';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Выберите реле или узел для наблюдения.';

  @override
  String get publicKeyLabel => 'Публичный ключ';

  @override
  String get alreadyInContacts => 'Уже в контактах';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Подключитесь к устройству перед добавлением контактов';

  @override
  String get fromContacts => 'Из контактов';

  @override
  String get onlineOnly => 'Только онлайн';

  @override
  String get inBoth => 'В обоих';

  @override
  String get source => 'Источник';

  @override
  String get allMessagesCleared => 'Все сообщения очищены';

  @override
  String get onlineTraceDatabaseCleared => 'База трассировок очищена';

  @override
  String get packetLogsCleared => 'Журналы пакетов очищены';

  @override
  String get hexDataCopiedToClipboard => 'Hex-данные скопированы в буфер';

  @override
  String get developerModeEnabled => 'Режим разработчика включён';

  @override
  String get developerModeDisabled => 'Режим разработчика отключён';

  @override
  String get clipboardIsEmpty => 'Буфер обмена пуст';

  @override
  String get contactImported => 'Контакт импортирован';

  @override
  String get contactLinkCopiedToClipboard =>
      'Ссылка на контакт скопирована в буфер';

  @override
  String get failedToExportContact => 'Не удалось экспортировать контакт';

  @override
  String get noLogsToExport => 'Нет журналов для экспорта';

  @override
  String get exportAsCsv => 'Экспортировать как CSV';

  @override
  String get exportAsText => 'Экспортировать как текст';

  @override
  String get receivedRfc3339 => 'Получено (RFC3339)';

  @override
  String get buildTime => 'Время сборки';

  @override
  String get downloadUrlNotAvailable => 'URL загрузки недоступен';

  @override
  String get cannotOpenDownloadUrl => 'Не удаётся открыть URL загрузки';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Проверка обновлений доступна только на Android';

  @override
  String get youAreRunningTheLatestVersion => 'Вы используете последнюю версию';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Обновление доступно, но URL загрузки не найден';

  @override
  String get startTictactoe => 'Начать Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe недоступно';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: противник неизвестен';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: ожидание начала';

  @override
  String get acceptsShareLinks => 'Принимает общие ссылки';

  @override
  String get supportsRawHex => 'Поддерживает raw hex';

  @override
  String get clipboardfriendly => 'Удобно для буфера';

  @override
  String get captured => 'Захвачено';

  @override
  String get size => 'Размер';

  @override
  String get noCustomChannelsToClear =>
      'Нет пользовательских каналов для очистки.';

  @override
  String get noDeviceContactsToClear => 'Нет контактов устройства для очистки.';

  @override
  String get aToZ => 'А-Я';

  @override
  String get add => 'Добавить';

  @override
  String get addAdditionalDetails => 'Добавить дополнительные сведения';

  @override
  String get addPeer => 'Добавить узел';

  @override
  String get addPeerManually => 'Добавить узел вручную';

  @override
  String addedToContacts(String name) {
    return '$name добавлен в контакты';
  }

  @override
  String addedToSensors(String name) {
    return '$name добавлен в Датчики';
  }

  @override
  String get allowAll => 'Разрешить все';

  @override
  String get anonymousRxStats => 'Анонимная статистика RX';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Базовая телеметрия';

  @override
  String get blePin => 'BLE PIN';

  @override
  String get buzzerAlerts => 'Звуковые оповещения';

  @override
  String get cancelImageReceive => 'Отменить получение изображения';

  @override
  String get choose => 'Выбрать';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Выберите отображаемые вкладки и разделы контактов';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearLiveView => 'Очистить режим реального времени';

  @override
  String get clearLogs => 'Очистить журналы';

  @override
  String get clearOfflineCache => 'Очистить офлайн-кэш?';

  @override
  String get clearOverlay => 'Очистить наложение';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Очищать маршрут только после всех неудачных повторов';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Кодек, битрейт и обработка звука';

  @override
  String get connectByIpAddress => 'Подключиться по IP-адресу';

  @override
  String get controlWhichAlertsYouReceive =>
      'Управление получаемыми оповещениями';

  @override
  String get copyFullHex => 'Копировать полный Hex';

  @override
  String get copyRawResponse => 'Копировать необработанный ответ';

  @override
  String get couldNotLoadMetHistory => 'Не удалось загрузить историю MET';

  @override
  String customizeSensor(String name) {
    return 'Настроить $name';
  }

  @override
  String get data => 'Данные';

  @override
  String get deleteGroup => 'Удалить группу';

  @override
  String deleteStyleConfirm(String name) {
    return 'Удалить $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Удалить этот $type?';
  }

  @override
  String get deny => 'Запретить';

  @override
  String get deviceInfo => 'Информация об устройстве';

  @override
  String get deviceSettings => 'Настройки устройства';

  @override
  String get deviceTimeSynced =>
      'Время устройства синхронизировано с телефоном.';

  @override
  String get disableFastGpsPublishing => 'Отключить быструю публикацию GPS';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Отображение, маркеры и база трассировок';

  @override
  String get download => 'Скачать';

  @override
  String get environmentalTelemetry => 'Телеметрия окружающей среды';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Ошибка проверки обновлений: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Ошибка: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Ошибка открытия загрузки: $error';
  }

  @override
  String get exportLogs => 'Экспортировать журналы';

  @override
  String get extraAggressiveAvifCompression => 'Сверхагрессивное сжатие AVIF';

  @override
  String failedToAddContact(String error) {
    return 'Не удалось добавить контакт: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Не удалось добавить $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Не удалось очистить каналы: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Не удалось очистить контакты: $error';
  }

  @override
  String get failedToConnectViaSerial =>
      'Не удалось подключиться через последовательный порт';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Не удалось загрузить изображение предпросмотра: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Не удалось загрузить трассировку: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Не удалось отправить маркер SAR: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Не удалось установить режим зуммера: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Не удалось установить режим GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Не удалось синхронизировать время устройства: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Не удалось стереть данные устройства: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Целевой канал быстрого GPS';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Быстрые обновления, пороги и разрешения';

  @override
  String get fetchingCatalog => 'Загрузка каталога...';

  @override
  String get fifteenMinutes => '15 минут';

  @override
  String get fifteenSeconds => '15 секунд';

  @override
  String get filterByDirection => 'Фильтр по направлению';

  @override
  String get finish => 'Завершить';

  @override
  String get fiveMinutes => '5 минут';

  @override
  String get fiveSeconds => '5 секунд';

  @override
  String get fix => 'Фикс';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Политика объявлений GPS';

  @override
  String get gpsAndLocation => 'GPS и местоположение';

  @override
  String get gpsDiagnostics => 'Диагностика GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Помощь';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Скрыто';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Как радио автоматически добавляет обнаруженные узлы.';

  @override
  String get images => 'Изображения';

  @override
  String get importProfile => 'Импортировать профиль';

  @override
  String get lastFix => 'Последний фикс';

  @override
  String get latest => 'Последняя';

  @override
  String get latitude => 'Широта';

  @override
  String get loadASavedRegion => 'Загрузить сохранённый регион';

  @override
  String get loading => 'Загрузка';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Обмен местоположением, оборудование и интервал обновления.';

  @override
  String get locationTelemetry => 'Телеметрия местоположения';

  @override
  String get lockDestination => 'Зафиксировать назначение';

  @override
  String get longitude => 'Долгота';

  @override
  String get mapStyle => 'Стиль карты';

  @override
  String get max => 'Макс';

  @override
  String get maxZoom => 'Макс. масштаб';

  @override
  String get messaging => 'Сообщения';

  @override
  String get metHistory => 'История MET';

  @override
  String get min => 'Мин';

  @override
  String get minZoom => 'Мин. масштаб';

  @override
  String get moveDown => 'Переместить вниз';

  @override
  String get moveUp => 'Переместить вверх';

  @override
  String get multiAckMode => 'Режим множественного ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Управление рабочим пространством на нескольких устройствах';

  @override
  String get myLocation => 'Моё местоположение';

  @override
  String get nameAndTelemetryShared =>
      'Имя и телеметрия доступны другим устройствам.';

  @override
  String newVersionAvailable(String version) {
    return 'Новая версия: $version';
  }

  @override
  String get newer => 'Новее';

  @override
  String get noNeighboursFound => 'Соседи не найдены';

  @override
  String get noServersFound => 'Серверы не найдены';

  @override
  String get notSet => 'Не задано';

  @override
  String get notifications => 'Уведомления';

  @override
  String get offZeroSeconds => 'Выкл (0 с)';

  @override
  String get offlineMaps => 'Офлайн-карты';

  @override
  String get older => 'Старее';

  @override
  String get oneByteMode0 => '1 байт (режим 0)';

  @override
  String get oneHour => '1 час';

  @override
  String get oneMinute => '1 минута';

  @override
  String get openPacketLogs => 'Открыть журналы пакетов';

  @override
  String get packetTypeHelp => 'Справка по типам пакетов';

  @override
  String get pasteShareLinkOrHexAdvert => 'Вставьте ссылку или Hex-объявление';

  @override
  String get pathHash => 'Хеш пути';

  @override
  String get pathSize => 'Размер пути';

  @override
  String get ping => 'Пинг';

  @override
  String get polygon => 'Полигон';

  @override
  String get rawResponseCopied => 'Необработанный ответ скопирован';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Повторить через ближайший ретранслятор при ошибке';

  @override
  String get resolveContact => 'Разрешить контакт';

  @override
  String get routingRetriesAndDestinationLock =>
      'Маршрутизация, повторы и фиксация назначения';

  @override
  String get samples => 'Образцы';

  @override
  String get satellites => 'Спутники';

  @override
  String get saving => 'Сохранение...';

  @override
  String get search => 'Поиск';

  @override
  String get searchByNameOrToken => 'Поиск по имени или токену';

  @override
  String get searchDiscoveredNodes => 'Поиск обнаруженных узлов';

  @override
  String get searchInCurrentFilter => 'Поиск в текущем фильтре';

  @override
  String get searchLogs => 'Поиск по журналам...';

  @override
  String get searchSensors => 'Поиск датчиков';

  @override
  String get searchThisSection => 'Поиск в этом разделе';

  @override
  String get selectedRelays => 'Выбранные ретрансляторы';

  @override
  String get sensor => 'Датчик';

  @override
  String serialError(String error) {
    return 'Ошибка последовательного порта: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Задать путь для $name';
  }

  @override
  String get shareLiveGps => 'Транслировать GPS';

  @override
  String get shareMyTiles => 'Поделиться моими тайлами';

  @override
  String get sharingLocationFromPhone =>
      'Трансляция местоположения на этом канале с телефона.';

  @override
  String get sharingLocationFromRadio =>
      'Трансляция местоположения на этом канале с радио.';

  @override
  String signalDbm(String rssi) {
    return 'Сигнал $rssi дБм';
  }

  @override
  String get sizeCompressionAndPreview => 'Размер, сжатие и предпросмотр';

  @override
  String get skip => 'Пропустить';

  @override
  String get smallerFileSize => 'Меньший размер файла';

  @override
  String get sort => 'Сортировка';

  @override
  String get stoppedSharingLocation =>
      'Трансляция местоположения на этом канале остановлена.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Отключить уведомления при открытом приложении';

  @override
  String get tabsAndNavigation => 'Вкладки и навигация';

  @override
  String get templatesAndTutorials => 'Шаблоны и обучение';

  @override
  String get tenMinutes => '10 минут';

  @override
  String get tenSeconds => '10 секунд';

  @override
  String get testSendUpdate => 'Тестовая отправка обновления';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Тема, язык и настройки отображения';

  @override
  String get thirtyMinutes => '30 минут';

  @override
  String get thirtySeconds => '30 секунд';

  @override
  String get threeBytesMode2 => '3 байта (режим 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Статистика трафика, история сообщений и инструменты разработчика';

  @override
  String get twoBytesMode1 => '2 байта (режим 1)';

  @override
  String get twoMinutes => '2 минуты';

  @override
  String get undo => 'Отменить';

  @override
  String get updated => 'Обновлено';

  @override
  String get useContactFlags => 'Использовать флаги контактов';

  @override
  String get useSavedCoordinates => 'Использовать сохранённые координаты';

  @override
  String get view => 'Просмотр';

  @override
  String get viewNeighbours => 'Просмотр соседей';

  @override
  String get viewPublicStats => 'Просмотр публичной статистики';

  @override
  String get setRegionScope => 'Установить область региона';

  @override
  String get regionScope => 'Область региона';

  @override
  String get regionScopeNone => 'Нет (глобально)';

  @override
  String get clearRegionScope => 'Очистить область';

  @override
  String get regionScopeWarning =>
      'Только ретрансляторы, разрешающие этот регион, будут пересылать.';

  @override
  String get discoverRegions => 'Обнаружить из ретрансляторов';

  @override
  String get discoveringRegions => 'Обнаружение регионов...';

  @override
  String get enterRegionName => 'Название региона (напр. auckland)';

  @override
  String get noRegionsFound => 'Регионы не найдены на этом ретрансляторе.';

  @override
  String regionScopeSet(String name) {
    return 'Область региона установлена на $name';
  }

  @override
  String get regionScopeCleared => 'Область региона очищена';
}
