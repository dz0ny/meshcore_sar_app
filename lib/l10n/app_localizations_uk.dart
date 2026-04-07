// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Повідомлення';

  @override
  String get contacts => 'Контакти';

  @override
  String get map => 'Мапа';

  @override
  String get settings => 'Налаштування';

  @override
  String get connect => 'Підключити';

  @override
  String get disconnect => 'Відключити';

  @override
  String get noDevicesFound => 'Пристроїв не знайдено';

  @override
  String get scanAgain => 'Сканувати знову';

  @override
  String get deviceNotConnected => 'Пристрій не підключено';

  @override
  String get locationPermissionDenied => 'Доступ до геолокації відхилено';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Дозвіл на геолокацію назавжди відхилено. Увімкніть його в Налаштуваннях.';

  @override
  String get locationPermissionRequired =>
      'Для GPS-відстеження та координації команди потрібен дозвіл на геолокацію. Ви можете ввімкнути його пізніше в Налаштуваннях.';

  @override
  String get locationServicesDisabled =>
      'Служби геолокації вимкнені. Увімкніть їх у Налаштуваннях.';

  @override
  String get failedToGetGpsLocation => 'Не вдалося отримати GPS-координати';

  @override
  String failedToAdvertise(String error) {
    return 'Не вдалося транслювати: $error';
  }

  @override
  String get cancelReconnection => 'Скасувати повторне підключення';

  @override
  String get general => 'Загальні';

  @override
  String get theme => 'Тема';

  @override
  String get chooseTheme => 'Вибрати тему';

  @override
  String get light => 'Світла';

  @override
  String get dark => 'Темна';

  @override
  String get blueLightTheme => 'Світло-синя тема';

  @override
  String get blueDarkTheme => 'Темно-синя тема';

  @override
  String get sarRed => 'SAR Червоний';

  @override
  String get alertEmergencyMode => 'Режим тривоги/надзвичайної ситуації';

  @override
  String get sarGreen => 'SAR Зелений';

  @override
  String get safeAllClearMode => 'Безпечний режим/усе чисто';

  @override
  String get autoSystem => 'Авто (система)';

  @override
  String get followSystemTheme => 'Слідувати системній темі';

  @override
  String get showRxTxIndicators => 'Показувати індикатори RX/TX';

  @override
  String get disableMap => 'Вимкнути мапу';

  @override
  String get language => 'Мова';

  @override
  String get chooseLanguage => 'Вибрати мову';

  @override
  String get save => 'Зберегти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get close => 'Закрити';

  @override
  String get about => 'Про програму';

  @override
  String get appVersion => 'Версія застосунку';

  @override
  String get aboutMeshCoreSar => 'Про MeshCore SAR';

  @override
  String get aboutDescription =>
      'Застосунок для пошуку та рятування, створений для команд екстреного реагування. Можливості:\n\n• BLE mesh-мережа для зв’язку між пристроями\n• Офлайн-мапи з кількома шарами\n• Відстеження членів команди в реальному часі\n• Тактичні маркери SAR (знайдена людина, пожежа, зона збору)\n• Керування контактами та повідомленнями\n• GPS-відстеження з компасом\n• Кешування тайлів мапи для офлайн-використання';

  @override
  String get technologiesUsed => 'Використані технології:';

  @override
  String get technologiesList =>
      '• Flutter для кросплатформної розробки\n• BLE (Bluetooth Low Energy) для mesh-мережі\n• OpenStreetMap для мап\n• Provider для керування станом\n• SharedPreferences для локального зберігання';

  @override
  String get moreInfo => 'Більше інформації';

  @override
  String get packageName => 'Назва пакета';

  @override
  String get sampleData => 'Тестові дані';

  @override
  String get sampleDataDescription =>
      'Завантажити або очистити тестові контакти, повідомлення каналів і маркери SAR для перевірки';

  @override
  String get loadSampleData => 'Завантажити тестові дані';

  @override
  String get clearAllData => 'Очистити всі дані';

  @override
  String get clearAllDataConfirmTitle => 'Очистити всі дані';

  @override
  String get clearAllDataConfirmMessage =>
      'Це очистить усі контакти та маркери SAR. Ви впевнені?';

  @override
  String get clear => 'Очистити';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Завантажено $teamCount членів команди, $channelCount каналів, $sarCount маркерів SAR, $messageCount повідомлень';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Не вдалося завантажити тестові дані: $error';
  }

  @override
  String get allDataCleared => 'Усі дані очищено';

  @override
  String get failedToStartBackgroundTracking =>
      'Не вдалося запустити фонове відстеження. Перевірте дозволи та BLE-з’єднання.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Трансляція місцезнаходження: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Стандартний PIN для пристроїв без екрана - 123456. Проблеми зі сполученням? Видаліть Bluetooth-пристрій у системних налаштуваннях.';

  @override
  String get noMessagesYet => 'Повідомлень ще немає';

  @override
  String get pullDownToSync =>
      'Потягніть вниз, щоб синхронізувати повідомлення';

  @override
  String get deleteContact => 'Видалити контакт';

  @override
  String get delete => 'Видалити';

  @override
  String get viewOnMap => 'Показати на мапі';

  @override
  String get refresh => 'Оновити';

  @override
  String get resetPath => 'Скинути маршрут (побудувати заново)';

  @override
  String copiedToClipboard(String label) {
    return '$label скопійовано в буфер обміну';
  }

  @override
  String get pleaseEnterPassword => 'Будь ласка, введіть пароль';

  @override
  String failedToSyncContacts(String error) {
    return 'Не вдалося синхронізувати контакти: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Вхід виконано успішно! Очікування повідомлень кімнати...';

  @override
  String get loginFailed => 'Помилка входу - неправильний пароль';

  @override
  String loggingIn(String roomName) {
    return 'Вхід до $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Не вдалося надіслати вхід: $error';
  }

  @override
  String get lowLocationAccuracy => 'Низька точність геолокації';

  @override
  String get continue_ => 'Продовжити';

  @override
  String get sendSarMarker => 'Надіслати маркер SAR';

  @override
  String get deleteDrawing => 'Видалити рисунок';

  @override
  String get drawingTools => 'Інструменти малювання';

  @override
  String get drawLine => 'Намалювати лінію';

  @override
  String get drawLineDesc => 'Намалювати довільну лінію на мапі';

  @override
  String get drawRectangle => 'Намалювати прямокутник';

  @override
  String get drawRectangleDesc => 'Намалювати прямокутну область на мапі';

  @override
  String get measureDistance => 'Виміряти відстань';

  @override
  String get measureDistanceDesc => 'Затисніть дві точки, щоб виміряти';

  @override
  String get clearMeasurement => 'Очистити вимірювання';

  @override
  String distanceLabel(String distance) {
    return 'Відстань: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Затисніть для другої точки';

  @override
  String get longPressToStartMeasurement =>
      'Затисніть, щоб встановити першу точку';

  @override
  String get longPressToStartNewMeasurement =>
      'Затисніть, щоб почати нове вимірювання';

  @override
  String get shareDrawings => 'Поділитися рисунками';

  @override
  String get clearAllDrawings => 'Очистити всі рисунки';

  @override
  String get completeLine => 'Завершити лінію';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Транслювати $count рисунок$plural команді';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Видалити всі $count рисунок$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Видалити всі $count рисунок$plural з мапи?';
  }

  @override
  String get drawing => 'Рисунок';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Поділитися $count рисунок$plural';
  }

  @override
  String get showReceivedDrawings => 'Показати отримані рисунки';

  @override
  String get showingAllDrawings => 'Показуються всі рисунки';

  @override
  String get showingOnlyYourDrawings => 'Показуються лише ваші рисунки';

  @override
  String get showSarMarkers => 'Показати маркери SAR';

  @override
  String get showingSarMarkers => 'Показуються маркери SAR';

  @override
  String get hidingSarMarkers => 'Приховування маркерів SAR';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get publicChannel => 'Публічний канал';

  @override
  String get broadcastToAll => 'Транслювати всім сусіднім вузлам (тимчасово)';

  @override
  String get storedPermanently => 'Постійно збережено в кімнаті';

  @override
  String get notConnectedToDevice => 'Не підключено до пристрою';

  @override
  String get typeYourMessage => 'Введіть повідомлення...';

  @override
  String get quickLocationMarker => 'Швидкий маркер місця';

  @override
  String get markerType => 'Тип маркера';

  @override
  String get sendTo => 'Надіслати до';

  @override
  String get noDestinationsAvailable => 'Немає доступних отримувачів.';

  @override
  String get selectDestination => 'Виберіть отримувача...';

  @override
  String get ephemeralBroadcastInfo =>
      'Тимчасове: транслюється лише по радіо. Не зберігається - вузли мають бути онлайн.';

  @override
  String get persistentRoomInfo =>
      'Постійне: незмінно зберігається в кімнаті. Автоматично синхронізується і зберігається офлайн.';

  @override
  String get location => 'Місцезнаходження';

  @override
  String get fromMap => 'З мапи';

  @override
  String get gettingLocation => 'Отримання місцезнаходження...';

  @override
  String get locationError => 'Помилка геолокації';

  @override
  String get retry => 'Повторити';

  @override
  String get refreshLocation => 'Оновити місцезнаходження';

  @override
  String accuracyMeters(int accuracy) {
    return 'Точність: ±$accuracyм';
  }

  @override
  String get notesOptional => 'Нотатки (необов’язково)';

  @override
  String get addAdditionalInformation => 'Додайте додаткову інформацію...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Точність місцезнаходження становить ±$accuracyм. Це може бути недостатньо точно для операцій SAR.\n\nПродовжити все одно?';
  }

  @override
  String get loginToRoom => 'Увійти до кімнати';

  @override
  String get enterPasswordInfo =>
      'Введіть пароль для доступу до цієї кімнати. Пароль буде збережено для подальшого використання.';

  @override
  String get password => 'Пароль';

  @override
  String get enterRoomPassword => 'Введіть пароль кімнати';

  @override
  String get loggingInDots => 'Вхід...';

  @override
  String get login => 'Увійти';

  @override
  String failedToAddRoom(String error) {
    return 'Не вдалося додати кімнату до пристрою: $error\n\nМожливо, кімната ще не почала трансляцію.\nСпробуйте зачекати, поки вона почне транслюватися.';
  }

  @override
  String get direct => 'Напряму';

  @override
  String get flood => 'Широкомовно';

  @override
  String get autoSend => 'Автовідправлення';

  @override
  String get autoSendDescription => 'Надіслати поточним маршрутом.';

  @override
  String get sendDirect => 'Пряме надсилання';

  @override
  String get sendDirectDescription => 'Надіслати безпосередньо цьому контакту.';

  @override
  String get sendFlood => 'Надсилання лавиною';

  @override
  String get sendFloodDescription => 'Надіслати через усі ретранслятори.';

  @override
  String get loggedIn => 'Увійшли';

  @override
  String get noGpsData => 'Немає GPS-даних';

  @override
  String get distance => 'Відстань';

  @override
  String directPingTimeout(String name) {
    return 'Час очікування прямого ping вичерпано - повторна спроба для $name через flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping до $name не вдався - відповіді не отримано';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Ви впевнені, що хочете видалити \"$name\"?\n\nЦе видалить контакт і з застосунку, і з пов’язаного радіопристрою.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Не вдалося видалити контакт: $error';
  }

  @override
  String get type => 'Тип';

  @override
  String get publicKey => 'Публічний ключ';

  @override
  String get lastSeen => 'Востаннє бачили';

  @override
  String get yes => 'Так';

  @override
  String get no => 'Ні';

  @override
  String get permissions => 'Дозволи';

  @override
  String get telemetry => 'Телеметрія';

  @override
  String get voltage => 'Напруга';

  @override
  String get battery => 'Батарея';

  @override
  String get temperature => 'Температура';

  @override
  String get humidity => 'Вологість';

  @override
  String get pressure => 'Тиск';

  @override
  String get gpsTelemetry => 'GPS (телеметрія)';

  @override
  String get reLoginToRoom => 'Повторно увійти до кімнати';

  @override
  String get heading => 'Напрямок';

  @override
  String get elevation => 'Висота';

  @override
  String get accuracy => 'Точність';

  @override
  String get bearing => 'Пеленг';

  @override
  String get direction => 'Напрямок';

  @override
  String get filterMarkers => 'Фільтрувати маркери';

  @override
  String get filterMarkersTooltip => 'Фільтрувати маркери';

  @override
  String get contactsFilter => 'Контакти';

  @override
  String get repeatersFilter => 'Ретранслятори';

  @override
  String get sarMarkers => 'Маркери SAR';

  @override
  String get foundPerson => 'Знайдена людина';

  @override
  String get fire => 'Пожежа';

  @override
  String get stagingArea => 'Зона збору';

  @override
  String get showAll => 'Показати все';

  @override
  String get locationUnavailable => 'Місцезнаходження недоступне';

  @override
  String get ahead => 'попереду';

  @override
  String degreesRight(int degrees) {
    return '$degrees° праворуч';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° ліворуч';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Шир.: $latitude Довг.: $longitude';
  }

  @override
  String get noContactsYet => 'Контактів ще немає';

  @override
  String get connectToDeviceToLoadContacts =>
      'Підключіться до пристрою, щоб завантажити контакти';

  @override
  String get teamMembers => 'Члени команди';

  @override
  String get repeaters => 'Ретранслятори';

  @override
  String get rooms => 'Кімнати';

  @override
  String get channels => 'Канали';

  @override
  String get selectMapLayer => 'Вибрати шар мапи';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Супутник';

  @override
  String get googleHybrid => 'Google Гібрид';

  @override
  String get googleRoadmap => 'Google Дорожня карта';

  @override
  String get googleTerrain => 'Google Рельєф';

  @override
  String get dragToPosition => 'Перетягніть у позицію';

  @override
  String get createSarMarker => 'Створити маркер SAR';

  @override
  String get compass => 'Компас';

  @override
  String get navigationAndContacts => 'Навігація та контакти';

  @override
  String get sarAlert => 'ТРИВОГА SAR';

  @override
  String get textCopiedToClipboard => 'Текст скопійовано в буфер обміну';

  @override
  String get cannotReplySenderMissing =>
      'Неможливо відповісти: відсутня інформація про відправника';

  @override
  String get cannotReplyContactNotFound =>
      'Неможливо відповісти: контакт не знайдено';

  @override
  String get copyText => 'Копіювати текст';

  @override
  String get saveAsTemplate => 'Зберегти як шаблон';

  @override
  String get templateSaved => 'Шаблон успішно збережено';

  @override
  String get templateAlreadyExists => 'Шаблон із цим emoji уже існує';

  @override
  String get deleteMessage => 'Видалити повідомлення';

  @override
  String get deleteMessageConfirmation =>
      'Ви впевнені, що хочете видалити це повідомлення?';

  @override
  String get shareLocation => 'Поділитися місцезнаходженням';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nКоординати: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Місцезнаходження SAR';

  @override
  String get justNow => 'Щойно';

  @override
  String minutesAgo(int minutes) {
    return '$minutes хв тому';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours год тому';
  }

  @override
  String daysAgo(int days) {
    return '$days дн тому';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds с тому';
  }

  @override
  String get sending => 'Надсилання...';

  @override
  String get sent => 'Надіслано';

  @override
  String get delivered => 'Доставлено';

  @override
  String deliveredWithTime(int time) {
    return 'Доставлено (${time}ms)';
  }

  @override
  String get failed => 'Помилка';

  @override
  String get broadcast => 'Трансляція';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Доставлено $delivered/$total контактам';
  }

  @override
  String get allDelivered => 'Усе доставлено';

  @override
  String get recipientDetails => 'Деталі отримувача';

  @override
  String get pending => 'Очікує';

  @override
  String get sarMarkerFoundPerson => 'Знайдена людина';

  @override
  String get sarMarkerFire => 'Місце пожежі';

  @override
  String get sarMarkerStagingArea => 'Зона збору';

  @override
  String get sarMarkerObject => 'Знайдений об’єкт';

  @override
  String get from => 'Від';

  @override
  String get coordinates => 'Координати';

  @override
  String get tapToViewOnMap => 'Торкніться, щоб переглянути на мапі';

  @override
  String get radioSettings => 'Налаштування радіо';

  @override
  String get frequencyMHz => 'Частота (MHz)';

  @override
  String get bandwidth => 'Ширина смуги';

  @override
  String get spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get codingRate => 'Швидкість кодування';

  @override
  String get txPowerDbm => 'Потужність TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Макс: $power dBm';
  }

  @override
  String get you => 'Ви';

  @override
  String exportFailed(String error) {
    return 'Помилка експорту: $error';
  }

  @override
  String importFailed(String error) {
    return 'Помилка імпорту: $error';
  }

  @override
  String get unknown => 'Невідомо';

  @override
  String get onlineLayers => 'Онлайн-шари';

  @override
  String get locationTrail => 'Слід місцезнаходження';

  @override
  String get showTrailOnMap => 'Показати слід на мапі';

  @override
  String get trailVisible => 'Слід видно на мапі';

  @override
  String get trailHiddenRecording => 'Слід прихований (запис триває)';

  @override
  String get duration => 'Тривалість';

  @override
  String get points => 'Точки';

  @override
  String get clearTrail => 'Очистити слід';

  @override
  String get clearTrailQuestion => 'Очистити слід?';

  @override
  String get clearTrailConfirmation =>
      'Ви впевнені, що хочете очистити поточний слід місцезнаходження? Цю дію не можна скасувати.';

  @override
  String get noTrailRecorded => 'Слід ще не записано';

  @override
  String get startTrackingToRecord =>
      'Почніть відстеження місцезнаходження, щоб записати слід';

  @override
  String get trailControls => 'Керування слідом';

  @override
  String get model => 'Модель';

  @override
  String get version => 'Версія';

  @override
  String get maxContacts => 'Макс. контактів';

  @override
  String get maxChannels => 'Макс. каналів';

  @override
  String get publicInfo => 'Публічна інформація';

  @override
  String get useCurrentLocation => 'Використати поточне місцезнаходження';

  @override
  String get noneUnknown => 'Немає/Невідомо';

  @override
  String get chatNode => 'Вузол чату';

  @override
  String get repeater => 'Ретранслятор';

  @override
  String get roomChannel => 'Кімната/Канал';

  @override
  String typeNumber(int number) {
    return 'Тип $number';
  }

  @override
  String failedToSave(String error) {
    return 'Не вдалося зберегти: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Не вдалося отримати місцезнаходження: $error';
  }

  @override
  String get sarTemplates => 'Шаблони SAR';

  @override
  String get addTemplate => 'Додати шаблон';

  @override
  String get editTemplate => 'Редагувати шаблон';

  @override
  String get deleteTemplate => 'Видалити шаблон';

  @override
  String get templateName => 'Назва шаблону';

  @override
  String get templateNameHint => 'напр. Знайдена людина';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji обов’язковий';

  @override
  String get nameRequired => 'Назва обов’язкова';

  @override
  String get templateDescription => 'Опис (необов’язково)';

  @override
  String get templateDescriptionHint => 'Додайте додатковий контекст...';

  @override
  String get templateColor => 'Колір';

  @override
  String get previewFormat => 'Попередній перегляд (формат повідомлення SAR)';

  @override
  String get importFromClipboard => 'Імпорт';

  @override
  String get exportToClipboard => 'Експорт';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Видалити шаблон \"$name\"?';
  }

  @override
  String get templateAdded => 'Шаблон додано';

  @override
  String get templateUpdated => 'Шаблон оновлено';

  @override
  String get templateDeleted => 'Шаблон видалено';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Імпортовано $count шаблонів',
      one: 'Імпортовано 1 шаблон',
      zero: 'Шаблони не імпортовано',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Експортовано $count шаблонів у буфер обміну',
      one: 'Експортовано 1 шаблон у буфер обміну',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Скинути до стандартних';

  @override
  String get resetToDefaultsConfirmation =>
      'Це видалить усі користувацькі шаблони та відновить 4 стандартні шаблони. Продовжити?';

  @override
  String get reset => 'Скинути';

  @override
  String get resetComplete => 'Шаблони скинуто до стандартних';

  @override
  String get noTemplates => 'Немає доступних шаблонів';

  @override
  String get tapAddToCreate => 'Торкніться +, щоб створити перший шаблон';

  @override
  String get ok => 'OK';

  @override
  String get locationPermission => 'Дозвіл на геолокацію';

  @override
  String get checking => 'Перевірка...';

  @override
  String get locationPermissionGrantedAlways => 'Надано (Завжди)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Надано (Під час використання)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Відхилено - торкніться, щоб запросити';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Назавжди відхилено - відкрити налаштування';

  @override
  String get locationPermissionDialogContent =>
      'Дозвіл на геолокацію назавжди відхилено. Увімкніть його в налаштуваннях пристрою, щоб використовувати GPS та поширення місцезнаходження.';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get locationPermissionGranted => 'Дозвіл на геолокацію надано!';

  @override
  String get locationPermissionRequiredForGps =>
      'Для GPS-відстеження та поширення місцезнаходження потрібен дозвіл на геолокацію.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Дозвіл на геолокацію вже надано.';

  @override
  String get sarNavyBlue => 'SAR Темно-синій';

  @override
  String get sarNavyBlueDescription => 'Професійний/операційний режим';

  @override
  String get selectRecipient => 'Вибрати отримувача';

  @override
  String get broadcastToAllNearby => 'Транслювати всім поблизу';

  @override
  String get searchRecipients => 'Пошук отримувачів...';

  @override
  String get noContactsFound => 'Контактів не знайдено';

  @override
  String get noRoomsFound => 'Кімнат не знайдено';

  @override
  String get noRecipientsAvailable => 'Немає доступних отримувачів';

  @override
  String get noChannelsFound => 'Каналів не знайдено';

  @override
  String get newMessage => 'Нове повідомлення';

  @override
  String get channel => 'Канал';

  @override
  String get samplePoliceLead => 'Керівник поліції';

  @override
  String get sampleDroneOperator => 'Оператор дрона';

  @override
  String get sampleFirefighterAlpha => 'Пожежник';

  @override
  String get sampleMedicCharlie => 'Медик';

  @override
  String get sampleCommandDelta => 'Командування';

  @override
  String get sampleFireEngine => 'Пожежна машина';

  @override
  String get sampleAirSupport => 'Повітряна підтримка';

  @override
  String get sampleBaseCoordinator => 'Координатор бази';

  @override
  String get channelEmergency => 'Надзвичайна ситуація';

  @override
  String get channelCoordination => 'Координація';

  @override
  String get channelUpdates => 'Оновлення';

  @override
  String get sampleTeamMember => 'Тестовий член команди';

  @override
  String get sampleScout => 'Тестовий розвідник';

  @override
  String get sampleBase => 'Тестова база';

  @override
  String get sampleSearcher => 'Тестовий пошуковець';

  @override
  String get sampleObjectBackpack => ' Знайдено рюкзак - синього кольору';

  @override
  String get sampleObjectVehicle =>
      ' Покинутий транспорт - перевірити власника';

  @override
  String get sampleObjectCamping => ' Знайдено туристичне спорядження';

  @override
  String get sampleObjectTrailMarker =>
      ' Знайдено маркер стежки поза маршрутом';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Усі команди - дайте відмітку';

  @override
  String get sampleMsgWeatherUpdate =>
      'Оновлення погоди: ясно, температура 18°C';

  @override
  String get sampleMsgBaseCamp => 'Базовий табір розгорнуто в зоні збору';

  @override
  String get sampleMsgTeamAlpha => 'Команда рухається до сектора 2';

  @override
  String get sampleMsgRadioCheck =>
      'Перевірка радіо - усім станціям відповісти';

  @override
  String get sampleMsgWaterSupply =>
      'Запас води доступний на контрольній точці 3';

  @override
  String get sampleMsgTeamBravo => 'Команда доповідає: сектор 1 чистий';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Орієнтовний час до точки збору: 15 хвилин';

  @override
  String get sampleMsgSupplyDrop => 'Скидання постачання підтверджено на 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Обстеження дроном завершено - результатів немає';

  @override
  String get sampleMsgTeamCharlie => 'Команда просить підкріплення';

  @override
  String get sampleMsgRadioDiscipline =>
      'Усім підрозділам: дотримуйтеся радіодисципліни';

  @override
  String get sampleMsgUrgentMedical =>
      'ТЕРМІНОВО: потрібна медична допомога в секторі 4';

  @override
  String get sampleMsgAdultMale => ' Дорослий чоловік, при свідомості';

  @override
  String get sampleMsgFireSpotted => 'Помічено пожежу - координати надходять';

  @override
  String get sampleMsgSpreadingRapidly => ' Швидко поширюється!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'ПРІОРИТЕТ: потрібна підтримка гелікоптера';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Медична команда прямує до вашого місця';

  @override
  String get sampleMsgEvacHelicopter =>
      'ETA евакуаційного гелікоптера 10 хвилин';

  @override
  String get sampleMsgEmergencyResolved =>
      'Надзвичайну ситуацію вирішено - все чисто';

  @override
  String get sampleMsgEmergencyStagingArea => ' Аварійна зона збору';

  @override
  String get sampleMsgEmergencyServices =>
      'Екстрені служби повідомлені та вже реагують';

  @override
  String get sampleAlphaTeamLead => 'Керівник команди';

  @override
  String get sampleBravoScout => 'Розвідник';

  @override
  String get sampleCharlieMedic => 'Медик';

  @override
  String get sampleDeltaNavigator => 'Навігатор';

  @override
  String get sampleEchoSupport => 'Підтримка';

  @override
  String get sampleBaseCommand => 'Командування бази';

  @override
  String get sampleFieldCoordinator => 'Польовий координатор';

  @override
  String get sampleMedicalTeam => 'Медична команда';

  @override
  String get mapDrawing => 'Рисунок на мапі';

  @override
  String get navigateToDrawing => 'Перейти до рисунка';

  @override
  String get copyCoordinates => 'Копіювати координати';

  @override
  String get hideFromMap => 'Приховати з мапи';

  @override
  String get lineDrawing => 'Лінійний рисунок';

  @override
  String get rectangleDrawing => 'Рисунок прямокутника';

  @override
  String get manualCoordinates => 'Ручні координати';

  @override
  String get enterCoordinatesManually => 'Введіть координати вручну';

  @override
  String get latitudeLabel => 'Широта';

  @override
  String get longitudeLabel => 'Довгота';

  @override
  String get exampleCoordinates => 'Приклад: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Поділитися рисунком';

  @override
  String get shareWithAllNearbyDevices =>
      'Поділитися з усіма пристроями поблизу';

  @override
  String get shareToRoom => 'Поділитися в кімнату';

  @override
  String get sendToPersistentStorage => 'Надіслати в постійне сховище кімнати';

  @override
  String get deleteDrawingConfirm =>
      'Ви впевнені, що хочете видалити цей рисунок?';

  @override
  String get drawingDeleted => 'Рисунок видалено';

  @override
  String yourDrawingsCount(int count) {
    return 'Ваші рисунки ($count)';
  }

  @override
  String get shared => 'Спільний';

  @override
  String get line => 'Лінія';

  @override
  String get rectangle => 'Прямокутник';

  @override
  String get updateAvailable => 'Доступне оновлення';

  @override
  String get currentVersion => 'Поточна';

  @override
  String get latestVersion => 'Остання';

  @override
  String get downloadUpdate => 'Завантажити';

  @override
  String get updateLater => 'Пізніше';

  @override
  String get cadastralParcels => 'Кадастрові ділянки';

  @override
  String get forestRoads => 'Лісові дороги';

  @override
  String get wmsOverlays => 'Накладки WMS';

  @override
  String get hikingTrails => 'Пішохідні стежки';

  @override
  String get mainRoads => 'Основні дороги';

  @override
  String get houseNumbers => 'Номери будинків';

  @override
  String get fireHazardZones => 'Зони пожежної небезпеки';

  @override
  String get historicalFires => 'Історичні пожежі';

  @override
  String get firebreaks => 'Протипожежні смуги';

  @override
  String get krasFireZones => 'Пожежні зони Красу';

  @override
  String get placeNames => 'Назви місць';

  @override
  String get municipalityBorders => 'Межі громад';

  @override
  String get topographicMap => 'Топографічна мапа 1:25000';

  @override
  String get recentMessages => 'Останні повідомлення';

  @override
  String get addChannel => 'Додати канал';

  @override
  String get channelName => 'Назва каналу';

  @override
  String get channelNameHint => 'напр. Рятувальна команда Альфа';

  @override
  String get channelSecret => 'Секрет каналу';

  @override
  String get channelSecretHint => 'Спільний пароль для цього каналу';

  @override
  String get channelSecretHelp =>
      'Цей секрет має бути спільним для всіх членів команди, яким потрібен доступ до цього каналу';

  @override
  String get channelTypesInfo =>
      'Hash-канали (#team): секрет автоматично генерується з назви. Однакова назва = той самий канал на всіх пристроях.\n\nПриватні канали: використовуйте явний секрет. Приєднатися можуть лише ті, хто його знає.';

  @override
  String get hashChannelInfo =>
      'Hash-канал: секрет буде автоматично згенерований з назви каналу. Кожен, хто використовує ту саму назву, приєднається до того самого каналу.';

  @override
  String get channelNameRequired => 'Назва каналу обов’язкова';

  @override
  String get channelNameTooLong =>
      'Назва каналу має бути не довшою за 31 символ';

  @override
  String get channelSecretRequired => 'Секрет каналу обов’язковий';

  @override
  String get channelSecretTooLong =>
      'Секрет каналу має бути не довшим за 32 символи';

  @override
  String get invalidAsciiCharacters => 'Дозволені лише символи ASCII';

  @override
  String get channelCreatedSuccessfully => 'Канал успішно створено';

  @override
  String channelCreationFailed(String error) {
    return 'Не вдалося створити канал: $error';
  }

  @override
  String get deleteChannel => 'Видалити канал';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Ви впевнені, що хочете видалити канал \"$channelName\"? Цю дію не можна скасувати.';
  }

  @override
  String get channelDeletedSuccessfully => 'Канал успішно видалено';

  @override
  String channelDeletionFailed(String error) {
    return 'Не вдалося видалити канал: $error';
  }

  @override
  String get createChannel => 'Створити канал';

  @override
  String get wizardBack => 'Назад';

  @override
  String get wizardSkip => 'Пропустити';

  @override
  String get wizardNext => 'Далі';

  @override
  String get wizardGetStarted => 'Почати';

  @override
  String get wizardWelcomeTitle => 'Ласкаво просимо до MeshCore SAR';

  @override
  String get viewWelcomeTutorial => 'Переглянути вступний посібник';

  @override
  String get allTeamContacts => 'Усі контакти команди';

  @override
  String directMessagesInfo(int count) {
    return 'Прямі повідомлення з ACK. Надіслано $count членам команди.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Маркер SAR надіслано $count контактам';
  }

  @override
  String get noContactsAvailable => 'Немає доступних контактів команди';

  @override
  String get reply => 'Відповісти';

  @override
  String get technicalDetails => 'Технічні деталі';

  @override
  String get messageTechnicalDetails => 'Технічні деталі повідомлення';

  @override
  String get linkQuality => 'Якість зв’язку';

  @override
  String get delivery => 'Доставка';

  @override
  String get status => 'Статус';

  @override
  String get expectedAckTag => 'Очікуваний тег ACK';

  @override
  String get roundTrip => 'Час в обидва боки';

  @override
  String get retryAttempt => 'Спроба повтору';

  @override
  String get floodFallback => 'Резервний flooding';

  @override
  String get identity => 'Ідентичність';

  @override
  String get messageId => 'ID повідомлення';

  @override
  String get sender => 'Відправник';

  @override
  String get senderKey => 'Ключ відправника';

  @override
  String get recipient => 'Отримувач';

  @override
  String get recipientKey => 'Ключ отримувача';

  @override
  String get voice => 'Голос';

  @override
  String get voiceId => 'ID голосу';

  @override
  String get envelope => 'Конверт';

  @override
  String get sessionProgress => 'Прогрес сеансу';

  @override
  String get complete => 'Завершено';

  @override
  String get rawDump => 'Сирий дамп';

  @override
  String get cannotRetryMissingRecipient =>
      'Неможливо повторити: відсутня інформація про отримувача';

  @override
  String get voiceUnavailable => 'Голос зараз недоступний';

  @override
  String get requestingVoice => 'Запит голосу';

  @override
  String get device => 'пристрій';

  @override
  String get change => 'Змінити';

  @override
  String get wizardOverviewDescription =>
      'Ця програма поєднує повідомлення MeshCore, польові оновлення SAR, карти та інструменти пристрою в одному місці.';

  @override
  String get wizardOverviewFeature1 =>
      'Надсилайте особисті повідомлення, повідомлення кімнат і повідомлення каналів з основної вкладки «Повідомлення».';

  @override
  String get wizardOverviewFeature2 =>
      'Діліться SAR-маркерами, малюнками на карті, голосовими кліпами та зображеннями через mesh-мережу.';

  @override
  String get wizardOverviewFeature3 =>
      'Підключайтеся через BLE або TCP, а потім керуйте супутнім радіопристроєм прямо з програми.';

  @override
  String get wizardMessagingTitle => 'Повідомлення та польові звіти';

  @override
  String get wizardMessagingDescription =>
      'Повідомлення тут це більше, ніж просто текст. Програма вже підтримує кілька типів операційних даних і сценаріїв передачі.';

  @override
  String get wizardMessagingFeature1 =>
      'Надсилайте особисті повідомлення, повідомлення кімнат і трафік каналів з одного редактора.';

  @override
  String get wizardMessagingFeature2 =>
      'Створюйте оновлення SAR і багаторазові шаблони SAR для типових польових звітів.';

  @override
  String get wizardMessagingFeature3 =>
      'Передавайте голосові сесії та зображення з індикатором прогресу й оцінками ефірного часу в інтерфейсі.';

  @override
  String get wizardConnectDeviceTitle => 'Підключити пристрій';

  @override
  String get wizardConnectDeviceDescription =>
      'Підключіть своє радіо MeshCore, виберіть назву та застосуйте радіопрофіль перед продовженням.';

  @override
  String get wizardSetupBadge => 'Налаштування';

  @override
  String get wizardOverviewBadge => 'Огляд';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Підключено до $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'Ще немає підключеного пристрою';

  @override
  String get wizardSkipForNow => 'Пропустити поки що';

  @override
  String get wizardDeviceNameLabel => 'Назва пристрою';

  @override
  String get wizardDeviceNameHelp =>
      'Ця назва оголошується іншим користувачам MeshCore.';

  @override
  String get wizardConfigRegionLabel => 'Регіон конфігурації';

  @override
  String get wizardConfigRegionHelp =>
      'Використовується повний офіційний список профілів MeshCore. Типово вибрано EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Переконайтеся, що вибраний профіль відповідає місцевим радіоправилам.';

  @override
  String get wizardPresetNote2 =>
      'Список відповідає офіційному потоку профілів інструмента MeshCore config.';

  @override
  String get wizardPresetNote3 =>
      'Для онбордингу типовим залишається EU/UK (Narrow).';

  @override
  String get wizardSaving => 'Збереження...';

  @override
  String get wizardSaveAndContinue => 'Зберегти й продовжити';

  @override
  String get wizardEnterDeviceName =>
      'Введіть назву пристрою перед продовженням.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Збережено $deviceName з профілем $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Контакти, кімнати та ретранслятори';

  @override
  String get wizardNetworkDescription =>
      'Вкладка «Контакти» організовує мережу, яку ви виявляєте, і маршрути, які вивчаєте з часом.';

  @override
  String get wizardNetworkFeature1 =>
      'Переглядайте членів команди, ретранслятори, кімнати, канали та оголошення в очікуванні в одному списку.';

  @override
  String get wizardNetworkFeature2 =>
      'Використовуйте smart ping, вхід до кімнат, вивчені шляхи й інструменти скидання маршрутів, коли зв\'язок стає нестабільним.';

  @override
  String get wizardNetworkFeature3 =>
      'Створюйте канали та керуйте мережевими призначеннями, не виходячи з програми.';

  @override
  String get wizardMapOpsTitle => 'Мапа, сліди та спільна геометрія';

  @override
  String get wizardMapOpsDescription =>
      'Мапа програми напряму пов\'язана з повідомленнями, відстеженням і SAR-накладками, а не є окремим переглядачем.';

  @override
  String get wizardMapOpsFeature1 =>
      'Відстежуйте власну позицію, місця розташування команди та сліди руху на мапі.';

  @override
  String get wizardMapOpsFeature2 =>
      'Відкривайте малюнки з повідомлень, переглядайте їх в інтерфейсі та видаляйте з мапи за потреби.';

  @override
  String get wizardMapOpsFeature3 =>
      'Використовуйте мапи ретрансляторів і спільні накладки, щоб розуміти покриття мережі в полі.';

  @override
  String get wizardToolsTitle => 'Інструменти поза повідомленнями';

  @override
  String get wizardToolsDescription =>
      'Тут є більше, ніж чотири основні вкладки. Програма також включає налаштування, діагностику та необов\'язкові сценарії датчиків.';

  @override
  String get wizardToolsFeature1 =>
      'Відкрийте налаштування пристрою, щоб змінити параметри радіо, телеметрію, потужність TX і дані супутнього пристрою.';

  @override
  String get wizardToolsFeature2 =>
      'Увімкніть вкладку «Датчики», коли потрібні панелі моніторингу та швидкі дії оновлення.';

  @override
  String get wizardToolsFeature3 =>
      'Використовуйте журнали пакетів, сканування спектра та діагностику розробника для усунення проблем mesh-мережі.';

  @override
  String get postConnectDiscoveryTitle => 'Виявити ретранслятори зараз?';

  @override
  String get postConnectDiscoveryDescription =>
      'Запустіть виявлення ретрансляторів одразу після підключення, щоб побачити найближчі вузли MeshCore та швидше додати їх до своєї мережі.';

  @override
  String get contactInSensors => 'У датчиках';

  @override
  String get contactAddToSensors => 'Додати до датчиків';

  @override
  String get contactSetPath => 'Задати шлях';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName додано до Датчиків';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Не вдалося очистити маршрут: $error';
  }

  @override
  String get contactRouteCleared => 'Маршрут очищено';

  @override
  String contactRouteSet(String route) {
    return 'Маршрут задано: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Не вдалося задати маршрут: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'Тайм-аут ACK';

  @override
  String get opcode => 'Опкод';

  @override
  String get payload => 'Корисне навантаження';

  @override
  String get hops => 'Хопи';

  @override
  String get hashSize => 'Розмір хешу';

  @override
  String get pathBytes => 'Байти шляху';

  @override
  String get selectedPath => 'Обраний шлях';

  @override
  String get estimatedTx => 'Очікувана передача';

  @override
  String get senderToReceipt => 'Від відправника до отримання';

  @override
  String get receivedCopies => 'Отримані копії';

  @override
  String get retryCause => 'Причина повтору';

  @override
  String get retryMode => 'Режим повтору';

  @override
  String get retryResult => 'Результат повтору';

  @override
  String get lastRetry => 'Остання спроба';

  @override
  String get rxPackets => 'RX-пакети';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Швидкість';

  @override
  String get window => 'Вікно';

  @override
  String get posttxDelay => 'Затримка після передачі';

  @override
  String get bandpass => 'Смуговий';

  @override
  String get bandpassFilterVoice => 'Смуговий фільтр голосу';

  @override
  String get active => 'Активно';

  @override
  String get addContact => 'Додати контакт';

  @override
  String get all => 'Усі';

  @override
  String get clearAllLabel => 'Очистити все';

  @override
  String get clearFilters => 'Очистити фільтри';

  @override
  String get clearRoute => 'Очистити маршрут';

  @override
  String get clearMessages => 'Очистити повідомлення';

  @override
  String get clearScale => 'Очистити масштаб';

  @override
  String get clearDiscoveries => 'Очистити виявлення';

  @override
  String get clearOnlineTraceDatabase => 'Очистити базу трасувань';

  @override
  String get clearAllChannels => 'Очистити всі канали';

  @override
  String get clearAllContacts => 'Очистити всі контакти';

  @override
  String get clearChannels => 'Очистити канали';

  @override
  String get clearContacts => 'Очистити контакти';

  @override
  String get clearPathOnMaxRetry => 'Очистити шлях при макс. спробі';

  @override
  String get create => 'Створити';

  @override
  String get custom => 'Користувацький';

  @override
  String get defaultValue => 'За замовчуванням';

  @override
  String get duplicate => 'Дублювати';

  @override
  String get editName => 'Редагувати ім\'я';

  @override
  String get open => 'Відкрити';

  @override
  String get paste => 'Вставити';

  @override
  String get preview => 'Попередній перегляд';

  @override
  String get remove => 'Видалити';

  @override
  String get rename => 'Перейменувати';

  @override
  String get resolveAll => 'Вирішити все';

  @override
  String get send => 'Надіслати';

  @override
  String get sendAnyway => 'Надіслати все одно';

  @override
  String get share => 'Поділитися';

  @override
  String get trace => 'Трасування';

  @override
  String get discovery => 'Виявлення';

  @override
  String get discoverRepeaters => 'Виявити повторювачі';

  @override
  String get discoverSensors => 'Виявити датчики';

  @override
  String get repeaterDiscoverySent => 'Виявлення повторювачів надіслано';

  @override
  String get sensorDiscoverySent => 'Виявлення датчиків надіслано';

  @override
  String get clearedPendingDiscoveries => 'Очікувані виявлення очищено.';

  @override
  String get autoDiscovery => 'Автоматичне виявлення';

  @override
  String get enableAutomaticAdding => 'Увімкнути автоматичне додавання';

  @override
  String get autoaddRepeaters => 'Автододавання повторювачів';

  @override
  String get autoaddRoomServers => 'Автододавання серверів кімнат';

  @override
  String get autoaddSensors => 'Автододавання датчиків';

  @override
  String get autoaddUsers => 'Автододавання користувачів';

  @override
  String get overwriteOldestWhenFull =>
      'Перезаписати найстаріші при заповненні';

  @override
  String get storage => 'Сховище';

  @override
  String get dangerZone => 'Небезпечна зона';

  @override
  String get profiles => 'Профілі';

  @override
  String get favourites => 'Обране';

  @override
  String get sensors => 'Датчики';

  @override
  String get others => 'Інші';

  @override
  String get gpsModule => 'Модуль GPS';

  @override
  String get liveTraffic => 'Живий трафік';

  @override
  String get repeatersMap => 'Карта повторювачів';

  @override
  String get blePacketLogs => 'Журнали BLE-пакетів';

  @override
  String get onlineTraceDatabase => 'База трасувань';

  @override
  String get routePathByteSize => 'Розмір шляху в байтах';

  @override
  String get messageNotifications => 'Сповіщення про повідомлення';

  @override
  String get sarAlerts => 'SAR-сповіщення';

  @override
  String get discoveryNotifications => 'Сповіщення про виявлення';

  @override
  String get updateNotifications => 'Сповіщення про оновлення';

  @override
  String get muteWhileAppIsOpen => 'Без звуку при відкритому додатку';

  @override
  String get disableContacts => 'Вимкнути контакти';

  @override
  String get enableSensorsTab => 'Увімкнути вкладку Датчики';

  @override
  String get enableProfiles => 'Увімкнути профілі';

  @override
  String get nearestRepeaterFallback => 'Найближчий повторювач як резерв';

  @override
  String get deleteAllStoredMessageHistory =>
      'Видалити всю історію повідомлень';

  @override
  String get messageFontSize => 'Розмір шрифту повідомлень';

  @override
  String get rotateMapWithHeading => 'Обертати карту за напрямком';

  @override
  String get showMapDebugInfo => 'Показати налагоджувальну інфо карти';

  @override
  String get openMapInFullscreen => 'Відкрити карту на повний екран';

  @override
  String get showSarMarkersLabel => 'Показати SAR-маркери';

  @override
  String get hideRepeatersOnMap => 'Сховати повторювачі на карті';

  @override
  String get setMapScale => 'Встановити масштаб карти';

  @override
  String get customMapScaleSaved => 'Користувацький масштаб карти збережено';

  @override
  String get voiceBitrate => 'Бітрейт голосу';

  @override
  String get voiceCompressor => 'Компресор голосу';

  @override
  String get voiceLimiter => 'Лімітер голосу';

  @override
  String get micAutoGain => 'Автопідсилення мікрофона';

  @override
  String get echoCancellation => 'Придушення ехо';

  @override
  String get noiseSuppression => 'Придушення шуму';

  @override
  String get trimSilenceInVoiceMessages =>
      'Обрізати тишу в голосових повідомленнях';

  @override
  String get compressor => 'Компресор';

  @override
  String get limiter => 'Лімітер';

  @override
  String get autoGain => 'Автопідсилення';

  @override
  String get echoCancel => 'Ехо';

  @override
  String get noiseSuppress => 'Шум';

  @override
  String get silenceTrim => 'Тиша';

  @override
  String get maxImageSize => 'Максимальний розмір зображення';

  @override
  String get imageCompression => 'Стиснення зображення';

  @override
  String get grayscale => 'Відтінки сірого';

  @override
  String get ultraMode => 'Ультра режим';

  @override
  String get fastPrivateGpsUpdates => 'Швидкі приватні GPS-оновлення';

  @override
  String get movementThreshold => 'Поріг руху';

  @override
  String get fastGpsMovementThreshold => 'Поріг руху швидкого GPS';

  @override
  String get fastGpsActiveuseInterval =>
      'Інтервал активного використання швидкого GPS';

  @override
  String get activeuseUpdateInterval =>
      'Інтервал оновлення при активному використанні';

  @override
  String get repeatNearbyTraffic => 'Повторювати близький трафік';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Ретранслювати через повторювачі по мережі';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Лише поблизу, без flood повторювачів';

  @override
  String get multihop => 'Багатохоповий';

  @override
  String get createProfile => 'Створити профіль';

  @override
  String get renameProfile => 'Перейменувати профіль';

  @override
  String get newProfile => 'Новий профіль';

  @override
  String get manageProfiles => 'Керувати профілями';

  @override
  String get enableProfilesToStartManagingThem =>
      'Увімкніть профілі, щоб почати керувати ними.';

  @override
  String get openMessage => 'Відкрити повідомлення';

  @override
  String get jumpToTheRelatedSarMessage =>
      'Перейти до пов\'язаного SAR-повідомлення';

  @override
  String get removeSarMarker => 'Видалити SAR-маркер';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'Виберіть призначення для надсилання SAR-маркера';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR-маркер надіслано на публічний канал';

  @override
  String get sarMarkerSentToRoom => 'SAR-маркер надіслано в кімнату';

  @override
  String get loadFromGallery => 'Завантажити з галереї';

  @override
  String get replaceImage => 'Замінити зображення';

  @override
  String get selectFromGallery => 'Вибрати з галереї';

  @override
  String get team => 'Команда';

  @override
  String get found => 'Знайдено';

  @override
  String get staging => 'Місце збору';

  @override
  String get object => 'Об\'єкт';

  @override
  String get quiet => 'Тихо';

  @override
  String get busy => 'Зайнято';

  @override
  String get searchMessages => 'Пошук повідомлень';

  @override
  String get sendImageFromGallery => 'Надіслати зображення з галереї';

  @override
  String get takePhoto => 'Зробити фото';

  @override
  String get allMessages => 'Усі повідомлення';

  @override
  String get sendToPublicChannel => 'Надіслати в публічний канал?';

  @override
  String get selectMarkerTypeAndDestination =>
      'Виберіть тип маркера та призначення';

  @override
  String get noDestinationsAvailableLabel => 'Немає доступних призначень';

  @override
  String get image => 'Зображення';

  @override
  String get format => 'Формат';

  @override
  String get dimensions => 'Розміри';

  @override
  String get segments => 'Сегменти';

  @override
  String get transfers => 'Передачі';

  @override
  String get downloadedBy => 'Завантажено';

  @override
  String get saveDiscoverySettings => 'Зберегти налаштування виявлення';

  @override
  String get savePublicInfo => 'Зберегти публічну інформацію';

  @override
  String get saveRadioSettings => 'Зберегти налаштування радіо';

  @override
  String get savePath => 'Зберегти шлях';

  @override
  String get wipeDeviceData => 'Стерти дані пристрою';

  @override
  String get wipeDevice => 'Стерти пристрій';

  @override
  String get destructiveDeviceActions => 'Деструктивні дії пристрою.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Оберіть пресет або налаштуйте радіо вручну.';

  @override
  String get used => 'Використано';

  @override
  String get total => 'Загалом';

  @override
  String get renameValue => 'Перейменувати значення';

  @override
  String get customizeFields => 'Налаштувати поля';

  @override
  String get livePreview => 'Попередній перегляд наживо';

  @override
  String get refreshSchedule => 'Розклад оновлення';

  @override
  String get noResponse => 'Немає відповіді';

  @override
  String get refreshing => 'Оновлення';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'Оберіть реле або вузол для спостереження.';

  @override
  String get publicKeyLabel => 'Публічний ключ';

  @override
  String get alreadyInContacts => 'Вже в контактах';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Підключіться до пристрою перед додаванням контактів';

  @override
  String get fromContacts => 'З контактів';

  @override
  String get onlineOnly => 'Лише онлайн';

  @override
  String get inBoth => 'В обох';

  @override
  String get source => 'Джерело';

  @override
  String get allMessagesCleared => 'Усі повідомлення очищено';

  @override
  String get onlineTraceDatabaseCleared => 'Базу трасувань очищено';

  @override
  String get packetLogsCleared => 'Журнали пакетів очищено';

  @override
  String get hexDataCopiedToClipboard => 'Hex-дані скопійовано в буфер';

  @override
  String get developerModeEnabled => 'Режим розробника увімкнено';

  @override
  String get developerModeDisabled => 'Режим розробника вимкнено';

  @override
  String get clipboardIsEmpty => 'Буфер обміну порожній';

  @override
  String get contactImported => 'Контакт імпортовано';

  @override
  String get contactLinkCopiedToClipboard =>
      'Посилання на контакт скопійовано в буфер';

  @override
  String get failedToExportContact => 'Не вдалося експортувати контакт';

  @override
  String get noLogsToExport => 'Немає журналів для експорту';

  @override
  String get exportAsCsv => 'Експортувати як CSV';

  @override
  String get exportAsText => 'Експортувати як текст';

  @override
  String get receivedRfc3339 => 'Отримано (RFC3339)';

  @override
  String get buildTime => 'Час збірки';

  @override
  String get downloadUrlNotAvailable => 'URL завантаження недоступний';

  @override
  String get cannotOpenDownloadUrl => 'Не вдається відкрити URL завантаження';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Перевірка оновлень доступна лише на Android';

  @override
  String get youAreRunningTheLatestVersion =>
      'Ви використовуєте останню версію';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Оновлення доступне, але URL завантаження не знайдено';

  @override
  String get startTictactoe => 'Почати Tic-Tac-Toe';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe недоступно';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: суперник невідомий';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: очікування початку';

  @override
  String get acceptsShareLinks => 'Приймає посилання для обміну';

  @override
  String get supportsRawHex => 'Підтримує raw hex';

  @override
  String get clipboardfriendly => 'Зручно для буфера';

  @override
  String get captured => 'Захоплено';

  @override
  String get size => 'Розмір';

  @override
  String get noCustomChannelsToClear =>
      'Немає користувацьких каналів для очищення.';

  @override
  String get noDeviceContactsToClear =>
      'Немає контактів пристрою для очищення.';

  @override
  String get aToZ => 'А-Я';

  @override
  String get add => 'Додати';

  @override
  String get addAdditionalDetails => 'Додати додаткові деталі';

  @override
  String get addPeer => 'Додати вузол';

  @override
  String get addPeerManually => 'Додати вузол вручну';

  @override
  String addedToContacts(String name) {
    return '$name додано до контактів';
  }

  @override
  String addedToSensors(String name) {
    return '$name додано до сенсорів';
  }

  @override
  String get allowAll => 'Дозволити все';

  @override
  String get anonymousRxStats => 'Анонімна статистика RX';

  @override
  String get appearance => 'Зовнішній вигляд';

  @override
  String get ascii => 'ASCII';

  @override
  String get baseTelemetry => 'Базова телеметрія';

  @override
  String get blePin => 'BLE PIN';

  @override
  String get buzzerAlerts => 'Сповіщення зумером';

  @override
  String get cancelImageReceive => 'Скасувати отримання зображення';

  @override
  String get choose => 'Обрати';

  @override
  String get chooseWhichTabsAndContactSectionsToShow =>
      'Оберіть, які вкладки та розділи контактів показувати';

  @override
  String get clearCache => 'Очистити кеш';

  @override
  String get clearHistory => 'Очистити історію';

  @override
  String get clearLiveView => 'Очистити живий перегляд';

  @override
  String get clearLogs => 'Очистити журнали';

  @override
  String get clearOfflineCache => 'Очистити офлайн-кеш?';

  @override
  String get clearOverlay => 'Очистити накладання';

  @override
  String get clearRouteOnlyAfterAllRetriesFail =>
      'Очистити маршрут лише після невдачі всіх спроб';

  @override
  String get codecBitrateAndAudioProcessing =>
      'Кодек, бітрейт та обробка звуку';

  @override
  String get connectByIpAddress => 'Підключити за IP-адресою';

  @override
  String get controlWhichAlertsYouReceive =>
      'Керуйте сповіщеннями, які ви отримуєте';

  @override
  String get copyFullHex => 'Копіювати повний Hex';

  @override
  String get copyRawResponse => 'Копіювати необроблену відповідь';

  @override
  String get couldNotLoadMetHistory => 'Не вдалося завантажити історію MET';

  @override
  String customizeSensor(String name) {
    return 'Налаштувати $name';
  }

  @override
  String get data => 'Дані';

  @override
  String get deleteGroup => 'Видалити групу';

  @override
  String deleteStyleConfirm(String name) {
    return 'Видалити $name?';
  }

  @override
  String deleteThisDrawing(String type) {
    return 'Видалити цей $type?';
  }

  @override
  String get deny => 'Відхилити';

  @override
  String get deviceInfo => 'Інформація про пристрій';

  @override
  String get deviceSettings => 'Налаштування пристрою';

  @override
  String get deviceTimeSynced => 'Час пристрою синхронізовано з цим телефоном.';

  @override
  String get disableFastGpsPublishing => 'Вимкнути швидку публікацію GPS';

  @override
  String get displayMarkersAndTraceDatabase =>
      'Відображення, маркери та база даних трасувань';

  @override
  String get download => 'Завантажити';

  @override
  String get environmentalTelemetry => 'Телеметрія довкілля';

  @override
  String errorCheckingForUpdates(String error) {
    return 'Помилка перевірки оновлень: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Помилка: $error';
  }

  @override
  String errorOpeningDownload(String error) {
    return 'Помилка відкриття завантаження: $error';
  }

  @override
  String get exportLogs => 'Експортувати журнали';

  @override
  String get extraAggressiveAvifCompression => 'Надагресивне стиснення AVIF';

  @override
  String failedToAddContact(String error) {
    return 'Не вдалося додати контакт: $error';
  }

  @override
  String failedToAddName(String name, String error) {
    return 'Не вдалося додати $name: $error';
  }

  @override
  String failedToClearChannels(String error) {
    return 'Не вдалося очистити канали: $error';
  }

  @override
  String failedToClearContacts(String error) {
    return 'Не вдалося очистити контакти: $error';
  }

  @override
  String get failedToConnectViaSerial =>
      'Не вдалося підключитися через послідовний порт';

  @override
  String failedToLoadPreviewImage(String error) {
    return 'Не вдалося завантажити попередній перегляд: $error';
  }

  @override
  String failedToLoadTrace(String error) {
    return 'Не вдалося завантажити трасування: $error';
  }

  @override
  String failedToSendSarMarker(String error) {
    return 'Не вдалося надіслати SAR маркер: $error';
  }

  @override
  String failedToSetBuzzerMode(String error) {
    return 'Не вдалося встановити режим зумера: $error';
  }

  @override
  String failedToSetGpsMode(String error) {
    return 'Не вдалося встановити режим GPS: $error';
  }

  @override
  String failedToSyncDeviceTime(String error) {
    return 'Не вдалося синхронізувати час пристрою: $error';
  }

  @override
  String failedToWipeDeviceData(String error) {
    return 'Не вдалося стерти дані пристрою: $error';
  }

  @override
  String get fastGpsTargetChannel => 'Цільовий канал швидкого GPS';

  @override
  String get fastUpdatesThresholdsAndPermissions =>
      'Швидкі оновлення, пороги та дозволи';

  @override
  String get fetchingCatalog => 'Завантаження каталогу...';

  @override
  String get fifteenMinutes => '15 хвилин';

  @override
  String get fifteenSeconds => '15 секунд';

  @override
  String get filterByDirection => 'Фільтрувати за напрямком';

  @override
  String get finish => 'Завершити';

  @override
  String get fiveMinutes => '5 хвилин';

  @override
  String get fiveSeconds => '5 секунд';

  @override
  String get fix => 'Фіксація';

  @override
  String get gps => 'GPS';

  @override
  String get gpsAdvertPolicy => 'Політика оголошень GPS';

  @override
  String get gpsAndLocation => 'GPS та місцезнаходження';

  @override
  String get gpsDiagnostics => 'Діагностика GPS';

  @override
  String get gpsSection => 'GPS';

  @override
  String get help => 'Допомога';

  @override
  String get hex => 'Hex';

  @override
  String get hidden => 'Приховано';

  @override
  String get howTheRadioAutoAddsDiscoveredNodes =>
      'Як радіо автоматично додає виявлені вузли.';

  @override
  String get images => 'Зображення';

  @override
  String get importProfile => 'Імпортувати профіль';

  @override
  String get lastFix => 'Остання фіксація';

  @override
  String get latest => 'Найновіші';

  @override
  String get latitude => 'Широта';

  @override
  String get loadASavedRegion => 'Завантажити збережений регіон';

  @override
  String get loading => 'Завантаження';

  @override
  String get locationSharingHardwareAndUpdateInterval =>
      'Обмін місцезнаходженням, обладнання та інтервал оновлення.';

  @override
  String get locationTelemetry => 'Телеметрія місцезнаходження';

  @override
  String get lockDestination => 'Зафіксувати призначення';

  @override
  String get longitude => 'Довгота';

  @override
  String get mapStyle => 'Стиль мапи';

  @override
  String get max => 'Макс';

  @override
  String get maxZoom => 'Макс. масштаб';

  @override
  String get messaging => 'Обмін повідомленнями';

  @override
  String get metHistory => 'Історія MET';

  @override
  String get min => 'Мін';

  @override
  String get minZoom => 'Мін. масштаб';

  @override
  String get moveDown => 'Перемістити вниз';

  @override
  String get moveUp => 'Перемістити вгору';

  @override
  String get multiAckMode => 'Режим мульти-ACK';

  @override
  String get multiDeviceWorkspaceManagement =>
      'Керування робочим простором кількох пристроїв';

  @override
  String get myLocation => 'Моє місцезнаходження';

  @override
  String get nameAndTelemetryShared =>
      'Ім\'я та телеметрія надсилаються іншим пристроям.';

  @override
  String newVersionAvailable(String version) {
    return 'Нова версія: $version';
  }

  @override
  String get newer => 'Новіші';

  @override
  String get noNeighboursFound => 'Сусідів не знайдено';

  @override
  String get noServersFound => 'Серверів не знайдено';

  @override
  String get notSet => 'Не встановлено';

  @override
  String get notifications => 'Сповіщення';

  @override
  String get offZeroSeconds => 'Вимк (0 с)';

  @override
  String get offlineMaps => 'Офлайн-мапи';

  @override
  String get older => 'Старіші';

  @override
  String get oneByteMode0 => '1 байт (режим 0)';

  @override
  String get oneHour => '1 година';

  @override
  String get oneMinute => '1 хвилина';

  @override
  String get openPacketLogs => 'Відкрити журнали пакетів';

  @override
  String get packetTypeHelp => 'Довідка типів пакетів';

  @override
  String get pasteShareLinkOrHexAdvert =>
      'Вставте посилання або hex-оголошення';

  @override
  String get pathHash => 'Хеш шляху';

  @override
  String get pathSize => 'Розмір шляху';

  @override
  String get ping => 'Ping';

  @override
  String get polygon => 'Полігон';

  @override
  String get rawResponseCopied => 'Необроблену відповідь скопійовано';

  @override
  String get resendThroughNearestRepeaterOnFailure =>
      'Повторно надіслати через найближчий ретранслятор у разі невдачі';

  @override
  String get resolveContact => 'Розв\'язати контакт';

  @override
  String get routingRetriesAndDestinationLock =>
      'Маршрутизація, повторні спроби та фіксація призначення';

  @override
  String get samples => 'Зразки';

  @override
  String get satellites => 'Супутники';

  @override
  String get saving => 'Збереження...';

  @override
  String get search => 'Пошук';

  @override
  String get searchByNameOrToken => 'Шукати за іменем або токеном';

  @override
  String get searchDiscoveredNodes => 'Шукати виявлені вузли';

  @override
  String get searchInCurrentFilter => 'Шукати в поточному фільтрі';

  @override
  String get searchLogs => 'Шукати в журналах...';

  @override
  String get searchSensors => 'Шукати сенсори';

  @override
  String get searchThisSection => 'Шукати в цьому розділі';

  @override
  String get selectedRelays => 'Обрані ретранслятори';

  @override
  String get sensor => 'Сенсор';

  @override
  String serialError(String error) {
    return 'Помилка послідовного порту: $error';
  }

  @override
  String setPathForContact(String name) {
    return 'Встановити шлях для $name';
  }

  @override
  String get shareLiveGps => 'Поділитися GPS у реальному часі';

  @override
  String get shareMyTiles => 'Поділитися моїми тайлами';

  @override
  String get sharingLocationFromPhone =>
      'Обмін місцезнаходженням на цьому каналі з телефону.';

  @override
  String get sharingLocationFromRadio =>
      'Обмін місцезнаходженням на цьому каналі з радіо.';

  @override
  String signalDbm(String rssi) {
    return 'Сигнал $rssi дБм';
  }

  @override
  String get sizeCompressionAndPreview =>
      'Розмір, стиснення та попередній перегляд';

  @override
  String get skip => 'Пропустити';

  @override
  String get smallerFileSize => 'Менший розмір файлу';

  @override
  String get sort => 'Сортувати';

  @override
  String get stoppedSharingLocation =>
      'Обмін місцезнаходженням на цьому каналі зупинено.';

  @override
  String get suppressNotificationsWhileInForeground =>
      'Придушити сповіщення, коли застосунок на передньому плані';

  @override
  String get tabsAndNavigation => 'Вкладки та навігація';

  @override
  String get templatesAndTutorials => 'Шаблони та посібники';

  @override
  String get tenMinutes => '10 хвилин';

  @override
  String get tenSeconds => '10 секунд';

  @override
  String get testSendUpdate => 'Тестове надсилання оновлення';

  @override
  String get themeLanguageAndDisplayPreferences =>
      'Тема, мова та налаштування відображення';

  @override
  String get thirtyMinutes => '30 хвилин';

  @override
  String get thirtySeconds => '30 секунд';

  @override
  String get threeBytesMode2 => '3 байти (режим 2)';

  @override
  String get trafficStatsMessageHistoryAndDeveloperTools =>
      'Статистика трафіку, історія повідомлень та інструменти розробника';

  @override
  String get twoBytesMode1 => '2 байти (режим 1)';

  @override
  String get twoMinutes => '2 хвилини';

  @override
  String get undo => 'Скасувати';

  @override
  String get updated => 'Оновлено';

  @override
  String get useContactFlags => 'Використовувати прапорці контактів';

  @override
  String get useSavedCoordinates => 'Використати збережені координати';

  @override
  String get view => 'Перегляд';

  @override
  String get viewNeighbours => 'Переглянути сусідів';

  @override
  String get viewPublicStats => 'Переглянути публічну статистику';

  @override
  String get setRegionScope => 'Встановити область регіону';

  @override
  String get regionScope => 'Область регіону';

  @override
  String get regionScopeNone => 'Немає (глобально)';

  @override
  String get clearRegionScope => 'Очистити область';

  @override
  String get regionScopeWarning =>
      'Лише ретранслятори, що дозволяють цей регіон, будуть пересилати.';

  @override
  String get discoverRegions => 'Виявити з ретрансляторів';

  @override
  String get discoveringRegions => 'Виявлення регіонів...';

  @override
  String get enterRegionName => 'Назва регіону (напр. auckland)';

  @override
  String get noRegionsFound => 'Регіони не знайдені на цьому ретрансляторі.';

  @override
  String regionScopeSet(String name) {
    return 'Область регіону встановлена на $name';
  }

  @override
  String get regionScopeCleared => 'Область регіону очищена';
}
