// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Mesajlar';

  @override
  String get contacts => 'Kişiler';

  @override
  String get map => 'Harita';

  @override
  String get settings => 'Ayarlar';

  @override
  String get connect => 'Bağlan';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get noDevicesFound => 'Cihaz bulunamadı';

  @override
  String get scanAgain => 'Tekrar tara';

  @override
  String get tapToConnect => 'Bağlanmak için dokunun';

  @override
  String get deviceNotConnected => 'Cihaz bağlı değil';

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Konum izni kalıcı olarak reddedildi. Lütfen Ayarlar bölümünden etkinleştirin.';

  @override
  String get locationPermissionRequired =>
      'GPS takibi ve ekip koordinasyonu için konum izni gereklidir. Daha sonra Ayarlar bölümünden etkinleştirebilirsiniz.';

  @override
  String get locationServicesDisabled =>
      'Konum servisleri kapalı. Lütfen Ayarlar bölümünden etkinleştirin.';

  @override
  String get failedToGetGpsLocation => 'GPS konumu alınamadı';

  @override
  String failedToAdvertise(String error) {
    return 'Yayın başarısız: $error';
  }

  @override
  String get cancelReconnection => 'Yeniden bağlanmayı iptal et';

  @override
  String get general => 'Genel';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Tema seç';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get blueLightTheme => 'Mavi açık tema';

  @override
  String get blueDarkTheme => 'Mavi koyu tema';

  @override
  String get sarRed => 'SAR Kırmızı';

  @override
  String get alertEmergencyMode => 'Uyarı/Acil durum modu';

  @override
  String get sarGreen => 'SAR Yeşil';

  @override
  String get safeAllClearMode => 'Güvenli/Tamam modu';

  @override
  String get autoSystem => 'Otomatik (Sistem)';

  @override
  String get followSystemTheme => 'Sistem temasını takip et';

  @override
  String get showRxTxIndicators => 'RX/TX göstergelerini göster';

  @override
  String get displayPacketActivity =>
      'Üst çubukta paket etkinliği göstergelerini göster';

  @override
  String get disableMap => 'Haritayı devre dışı bırak';

  @override
  String get disableMapDescription =>
      'Pil kullanımını azaltmak için harita sekmesini gizle';

  @override
  String get language => 'Dil';

  @override
  String get chooseLanguage => 'Dil seç';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get about => 'Hakkında';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get appName => 'Uygulama adı';

  @override
  String get aboutMeshCoreSar => 'MeshCore SAR hakkında';

  @override
  String get aboutDescription =>
      'Acil durum müdahale ekipleri için tasarlanmış bir Arama ve Kurtarma uygulaması. Özellikler:\n\n• Cihazdan cihaza iletişim için BLE mesh ağı\n• Birden çok katman seçeneğiyle çevrimdışı haritalar\n• Ekip üyelerinin gerçek zamanlı takibi\n• SAR taktik işaretleri (bulunan kişi, yangın, toplanma alanı)\n• Kişi yönetimi ve mesajlaşma\n• Pusula yönüyle GPS takibi\n• Çevrimdışı kullanım için harita karo önbelleği';

  @override
  String get technologiesUsed => 'Kullanılan teknolojiler:';

  @override
  String get technologiesList =>
      '• Çok platformlu geliştirme için Flutter\n• Mesh ağı için BLE (Bluetooth Low Energy)\n• Haritalama için OpenStreetMap\n• Durum yönetimi için Provider\n• Yerel depolama için SharedPreferences';

  @override
  String get moreInfo => 'Daha fazla bilgi';

  @override
  String get packageName => 'Paket adı';

  @override
  String get sampleData => 'Örnek veriler';

  @override
  String get sampleDataDescription =>
      'Test için örnek kişiler, kanal mesajları ve SAR işaretleri yükleyin veya temizleyin';

  @override
  String get loadSampleData => 'Örnek verileri yükle';

  @override
  String get clearAllData => 'Tüm verileri temizle';

  @override
  String get clearAllDataConfirmTitle => 'Tüm verileri temizle';

  @override
  String get clearAllDataConfirmMessage =>
      'Bu işlem tüm kişileri ve SAR işaretlerini temizleyecek. Emin misiniz?';

  @override
  String get clear => 'Temizle';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return '$teamCount ekip üyesi, $channelCount kanal, $sarCount SAR işareti, $messageCount mesaj yüklendi';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Örnek veriler yüklenemedi: $error';
  }

  @override
  String get allDataCleared => 'Tüm veriler temizlendi';

  @override
  String get failedToStartBackgroundTracking =>
      'Arka plan takibi başlatılamadı. İzinleri ve BLE bağlantısını kontrol edin.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Konum yayını: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Ekranı olmayan cihazlar için varsayılan PIN 123456’dır. Eşleştirme sorunu mu yaşıyorsunuz? Sistem ayarlarından Bluetooth cihazını unutun.';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get pullDownToSync => 'Mesajları senkronize etmek için aşağı çekin';

  @override
  String get deleteContact => 'Kişiyi sil';

  @override
  String get delete => 'Sil';

  @override
  String get viewOnMap => 'Haritada görüntüle';

  @override
  String get refresh => 'Yenile';

  @override
  String get resetPath => 'Yolu sıfırla (yeniden yönlendir)';

  @override
  String get publicKeyCopied => 'Genel anahtar panoya kopyalandı';

  @override
  String copiedToClipboard(String label) {
    return '$label panoya kopyalandı';
  }

  @override
  String get pleaseEnterPassword => 'Lütfen bir parola girin';

  @override
  String failedToSyncContacts(String error) {
    return 'Kişiler senkronize edilemedi: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Giriş başarılı! Oda mesajları bekleniyor...';

  @override
  String get loginFailed => 'Giriş başarısız - yanlış parola';

  @override
  String loggingIn(String roomName) {
    return '$roomName odasına giriş yapılıyor...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Giriş gönderilemedi: $error';
  }

  @override
  String get lowLocationAccuracy => 'Düşük konum doğruluğu';

  @override
  String get continue_ => 'Devam et';

  @override
  String get sendSarMarker => 'SAR işareti gönder';

  @override
  String get deleteDrawing => 'Çizimi sil';

  @override
  String get drawingTools => 'Çizim araçları';

  @override
  String get drawLine => 'Çizgi çiz';

  @override
  String get drawLineDesc => 'Harita üzerinde serbest çizgi çiz';

  @override
  String get drawRectangle => 'Dikdörtgen çiz';

  @override
  String get drawRectangleDesc => 'Harita üzerinde dikdörtgen alan çiz';

  @override
  String get measureDistance => 'Mesafe ölç';

  @override
  String get measureDistanceDesc => 'Ölçmek için iki noktaya uzun basın';

  @override
  String get clearMeasurement => 'Ölçümü temizle';

  @override
  String distanceLabel(String distance) {
    return 'Mesafe: $distance';
  }

  @override
  String get longPressForSecondPoint => 'İkinci nokta için uzun basın';

  @override
  String get longPressToStartMeasurement =>
      'İlk noktayı ayarlamak için uzun basın';

  @override
  String get longPressToStartNewMeasurement =>
      'Yeni ölçüm başlatmak için uzun basın';

  @override
  String get shareDrawings => 'Çizimleri paylaş';

  @override
  String get clearAllDrawings => 'Tüm çizimleri temizle';

  @override
  String get completeLine => 'Çizgiyi tamamla';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return '$count çizim$plural ekibe yayınla';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Tüm $count çizim$plural kaldır';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Haritadaki tüm $count çizim$plural silinsin mi?';
  }

  @override
  String get drawing => 'Çizim';

  @override
  String shareDrawingsCount(int count, String plural) {
    return '$count çizim$plural paylaş';
  }

  @override
  String get showReceivedDrawings => 'Alınan çizimleri göster';

  @override
  String get showingAllDrawings => 'Tüm çizimler gösteriliyor';

  @override
  String get showingOnlyYourDrawings =>
      'Yalnızca sizin çizimleriniz gösteriliyor';

  @override
  String get showSarMarkers => 'SAR işaretlerini göster';

  @override
  String get showingSarMarkers => 'SAR işaretleri gösteriliyor';

  @override
  String get hidingSarMarkers => 'SAR işaretleri gizleniyor';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get publicChannel => 'Genel kanal';

  @override
  String get broadcastToAll => 'Yakındaki tüm düğümlere yayınla (geçici)';

  @override
  String get storedPermanently => 'Odada kalıcı olarak saklanır';

  @override
  String get notConnectedToDevice => 'Cihaza bağlı değil';

  @override
  String get typeYourMessage => 'Mesajınızı yazın...';

  @override
  String get quickLocationMarker => 'Hızlı konum işareti';

  @override
  String get markerType => 'İşaret türü';

  @override
  String get sendTo => 'Gönder';

  @override
  String get noDestinationsAvailable => 'Kullanılabilir hedef yok.';

  @override
  String get selectDestination => 'Hedef seçin...';

  @override
  String get ephemeralBroadcastInfo =>
      'Geçici: yalnızca havadan yayınlanır. Saklanmaz; düğümlerin çevrimiçi olması gerekir.';

  @override
  String get persistentRoomInfo =>
      'Kalıcı: odada değişmez şekilde saklanır. Otomatik olarak eşitlenir ve çevrimdışı korunur.';

  @override
  String get location => 'Konum';

  @override
  String get fromMap => 'Haritadan';

  @override
  String get gettingLocation => 'Konum alınıyor...';

  @override
  String get locationError => 'Konum hatası';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get refreshLocation => 'Konumu yenile';

  @override
  String accuracyMeters(int accuracy) {
    return 'Doğruluk: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notlar (isteğe bağlı)';

  @override
  String get addAdditionalInformation => 'Ek bilgi ekleyin...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Konum doğruluğu ±${accuracy}m. Bu, SAR operasyonları için yeterince doğru olmayabilir.\n\nYine de devam edilsin mi?';
  }

  @override
  String get loginToRoom => 'Odaya giriş yap';

  @override
  String get enterPasswordInfo =>
      'Bu odaya erişmek için parolayı girin. Parola daha sonra kullanılmak üzere kaydedilecektir.';

  @override
  String get password => 'Parola';

  @override
  String get enterRoomPassword => 'Oda parolasını girin';

  @override
  String get loggingInDots => 'Giriş yapılıyor...';

  @override
  String get login => 'Giriş yap';

  @override
  String failedToAddRoom(String error) {
    return 'Oda cihaza eklenemedi: $error\n\nOda henüz yayın yapmamış olabilir.\nYayın yapmasını beklemeyi deneyin.';
  }

  @override
  String get direct => 'Doğrudan';

  @override
  String get flood => 'Yayılım';

  @override
  String get loggedIn => 'Giriş yapıldı';

  @override
  String get noGpsData => 'GPS verisi yok';

  @override
  String get distance => 'Mesafe';

  @override
  String directPingTimeout(String name) {
    return 'Doğrudan ping zaman aşımına uğradı - $name flooding ile yeniden deneniyor...';
  }

  @override
  String pingFailed(String name) {
    return '$name için ping başarısız - yanıt alınamadı';
  }

  @override
  String deleteContactConfirmation(String name) {
    return '\"$name\" kişisini silmek istediğinizden emin misiniz?\n\nBu işlem kişiyi hem uygulamadan hem de bağlı radyo cihazından kaldıracaktır.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Kişi kaldırılamadı: $error';
  }

  @override
  String get type => 'Tür';

  @override
  String get publicKey => 'Genel anahtar';

  @override
  String get lastSeen => 'Son görülme';

  @override
  String get roomStatus => 'Oda durumu';

  @override
  String get loginStatus => 'Giriş durumu';

  @override
  String get notLoggedIn => 'Giriş yapılmadı';

  @override
  String get adminAccess => 'Yönetici erişimi';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get permissions => 'İzinler';

  @override
  String get passwordSaved => 'Parola kaydedildi';

  @override
  String get locationColon => 'Konum:';

  @override
  String get telemetry => 'Telemetri';

  @override
  String get voltage => 'Voltaj';

  @override
  String get battery => 'Pil';

  @override
  String get temperature => 'Sıcaklık';

  @override
  String get humidity => 'Nem';

  @override
  String get pressure => 'Basınç';

  @override
  String get gpsTelemetry => 'GPS (telemetri)';

  @override
  String get updated => 'Güncellendi';

  @override
  String pathResetInfo(String name) {
    return '$name için yol sıfırlandı. Sonraki mesaj yeni bir rota bulacak.';
  }

  @override
  String get reLoginToRoom => 'Odaya yeniden giriş yap';

  @override
  String get heading => 'Yön';

  @override
  String get elevation => 'Rakım';

  @override
  String get accuracy => 'Doğruluk';

  @override
  String get bearing => 'İstikamet';

  @override
  String get direction => 'Yön';

  @override
  String get filterMarkers => 'İşaretleri filtrele';

  @override
  String get filterMarkersTooltip => 'İşaretleri filtrele';

  @override
  String get contactsFilter => 'Kişiler';

  @override
  String get repeatersFilter => 'Tekrarlayıcılar';

  @override
  String get sarMarkers => 'SAR işaretleri';

  @override
  String get foundPerson => 'Bulunan kişi';

  @override
  String get fire => 'Yangın';

  @override
  String get stagingArea => 'Toplanma alanı';

  @override
  String get showAll => 'Tümünü göster';

  @override
  String get locationUnavailable => 'Konum kullanılamıyor';

  @override
  String get ahead => 'ileride';

  @override
  String degreesRight(int degrees) {
    return '$degrees° sağda';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° solda';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Enl: $latitude Boy: $longitude';
  }

  @override
  String get noContactsYet => 'Henüz kişi yok';

  @override
  String get connectToDeviceToLoadContacts =>
      'Kişileri yüklemek için bir cihaza bağlanın';

  @override
  String get teamMembers => 'Ekip üyeleri';

  @override
  String get repeaters => 'Tekrarlayıcılar';

  @override
  String get rooms => 'Odalar';

  @override
  String get channels => 'Kanallar';

  @override
  String get selectMapLayer => 'Harita katmanını seç';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Uydu';

  @override
  String get googleHybrid => 'Google Hibrit';

  @override
  String get googleRoadmap => 'Google Yol Haritası';

  @override
  String get googleTerrain => 'Google Arazi';

  @override
  String get dragToPosition => 'Konuma sürükle';

  @override
  String get createSarMarker => 'SAR işareti oluştur';

  @override
  String get compass => 'Pusula';

  @override
  String get navigationAndContacts => 'Navigasyon ve kişiler';

  @override
  String get sarAlert => 'SAR ALARMI';

  @override
  String get textCopiedToClipboard => 'Metin panoya kopyalandı';

  @override
  String get cannotReplySenderMissing =>
      'Yanıtlanamıyor: gönderen bilgisi eksik';

  @override
  String get cannotReplyContactNotFound => 'Yanıtlanamıyor: kişi bulunamadı';

  @override
  String get copyText => 'Metni kopyala';

  @override
  String get saveAsTemplate => 'Şablon olarak kaydet';

  @override
  String get templateSaved => 'Şablon başarıyla kaydedildi';

  @override
  String get templateAlreadyExists => 'Bu emoji ile bir şablon zaten var';

  @override
  String get deleteMessage => 'Mesajı sil';

  @override
  String get deleteMessageConfirmation =>
      'Bu mesajı silmek istediğinizden emin misiniz?';

  @override
  String get shareLocation => 'Konumu paylaş';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nKoordinatlar: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR konumu';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours sa önce';
  }

  @override
  String daysAgo(int days) {
    return '$days g önce';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds sn önce';
  }

  @override
  String get sending => 'Gönderiliyor...';

  @override
  String get sent => 'Gönderildi';

  @override
  String get delivered => 'Teslim edildi';

  @override
  String deliveredWithTime(int time) {
    return 'Teslim edildi (${time}ms)';
  }

  @override
  String get failed => 'Başarısız';

  @override
  String get broadcast => 'Yayın';

  @override
  String deliveredToContacts(int delivered, int total) {
    return '$delivered/$total kişiye teslim edildi';
  }

  @override
  String get allDelivered => 'Hepsi teslim edildi';

  @override
  String get recipientDetails => 'Alıcı ayrıntıları';

  @override
  String get pending => 'Bekliyor';

  @override
  String get sarMarkerFoundPerson => 'Bulunan kişi';

  @override
  String get sarMarkerFire => 'Yangın konumu';

  @override
  String get sarMarkerStagingArea => 'Toplanma alanı';

  @override
  String get sarMarkerObject => 'Bulunan nesne';

  @override
  String get from => 'Kimden';

  @override
  String get coordinates => 'Koordinatlar';

  @override
  String get tapToViewOnMap => 'Haritada görüntülemek için dokunun';

  @override
  String get radioSettings => 'Radyo ayarları';

  @override
  String get frequencyMHz => 'Frekans (MHz)';

  @override
  String get frequencyExample => 'örn. 869.618';

  @override
  String get bandwidth => 'Bant genişliği';

  @override
  String get spreadingFactor => 'Yayılma faktörü';

  @override
  String get codingRate => 'Kodlama oranı';

  @override
  String get txPowerDbm => 'TX gücü (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Maks: $power dBm';
  }

  @override
  String get you => 'Siz';

  @override
  String exportFailed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String importFailed(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get onlineLayers => 'Çevrimiçi katmanlar';

  @override
  String get locationTrail => 'Konum izi';

  @override
  String get showTrailOnMap => 'İzi haritada göster';

  @override
  String get trailVisible => 'İz haritada görünüyor';

  @override
  String get trailHiddenRecording => 'İz gizli (kayıt devam ediyor)';

  @override
  String get duration => 'Süre';

  @override
  String get points => 'Noktalar';

  @override
  String get clearTrail => 'İzi temizle';

  @override
  String get clearTrailQuestion => 'İz temizlensin mi?';

  @override
  String get clearTrailConfirmation =>
      'Geçerli konum izini temizlemek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get noTrailRecorded => 'Henüz iz kaydedilmedi';

  @override
  String get startTrackingToRecord =>
      'İzi kaydetmek için konum takibini başlatın';

  @override
  String get trailControls => 'İz kontrolleri';

  @override
  String get contactTrails => 'Kişi izleri';

  @override
  String get showAllContactTrails => 'Tüm kişi izlerini göster';

  @override
  String get noContactsWithLocationHistory => 'Konum geçmişi olan kişi yok';

  @override
  String showingTrailsForContacts(int count) {
    return '$count kişi için izler gösteriliyor';
  }

  @override
  String get individualContactTrails => 'Tek tek kişi izleri';

  @override
  String get deviceInformation => 'Cihaz bilgileri';

  @override
  String get bleName => 'BLE adı';

  @override
  String get meshName => 'Mesh adı';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get model => 'Model';

  @override
  String get version => 'Sürüm';

  @override
  String get buildDate => 'Derleme tarihi';

  @override
  String get firmware => 'Bellenim';

  @override
  String get maxContacts => 'Maks kişi';

  @override
  String get maxChannels => 'Maks kanal';

  @override
  String get publicInfo => 'Genel bilgiler';

  @override
  String get meshNetworkName => 'Mesh ağ adı';

  @override
  String get nameBroadcastInMesh => 'Mesh duyurularında yayınlanan ad';

  @override
  String get telemetryAndLocationSharing => 'Telemetri ve konum paylaşımı';

  @override
  String get lat => 'Enl.';

  @override
  String get lon => 'Boyl.';

  @override
  String get useCurrentLocation => 'Geçerli konumu kullan';

  @override
  String get noneUnknown => 'Yok/Bilinmiyor';

  @override
  String get chatNode => 'Sohbet düğümü';

  @override
  String get repeater => 'Tekrarlayıcı';

  @override
  String get roomChannel => 'Oda/Kanal';

  @override
  String typeNumber(int number) {
    return 'Tür $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label panoya kopyalandı';
  }

  @override
  String failedToSave(String error) {
    return 'Kaydetme başarısız: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get sarTemplates => 'SAR şablonları';

  @override
  String get manageSarTemplates => 'SAR şablonlarını yönet';

  @override
  String get addTemplate => 'Şablon ekle';

  @override
  String get editTemplate => 'Şablonu düzenle';

  @override
  String get deleteTemplate => 'Şablonu sil';

  @override
  String get templateName => 'Şablon adı';

  @override
  String get templateNameHint => 'örn. Bulunan kişi';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji gerekli';

  @override
  String get nameRequired => 'Ad gerekli';

  @override
  String get templateDescription => 'Açıklama (isteğe bağlı)';

  @override
  String get templateDescriptionHint => 'Ek bağlam ekleyin...';

  @override
  String get templateColor => 'Renk';

  @override
  String get previewFormat => 'Önizleme (SAR mesaj biçimi)';

  @override
  String get importFromClipboard => 'İçe aktar';

  @override
  String get exportToClipboard => 'Dışa aktar';

  @override
  String deleteTemplateConfirmation(String name) {
    return '“$name” şablonu silinsin mi?';
  }

  @override
  String get templateAdded => 'Şablon eklendi';

  @override
  String get templateUpdated => 'Şablon güncellendi';

  @override
  String get templateDeleted => 'Şablon silindi';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şablon içe aktarıldı',
      one: '1 şablon içe aktarıldı',
      zero: 'Şablon içe aktarılmadı',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şablon panoya aktarıldı',
      one: '1 şablon panoya aktarıldı',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Varsayılanlara sıfırla';

  @override
  String get resetToDefaultsConfirmation =>
      'Bu işlem tüm özel şablonları silecek ve 4 varsayılan şablonu geri yükleyecek. Devam edilsin mi?';

  @override
  String get reset => 'Sıfırla';

  @override
  String get resetComplete => 'Şablonlar varsayılana sıfırlandı';

  @override
  String get noTemplates => 'Kullanılabilir şablon yok';

  @override
  String get tapAddToCreate =>
      'İlk şablonunuzu oluşturmak için + işaretine dokunun';

  @override
  String get ok => 'Tamam';

  @override
  String get permissionsSection => 'İzinler';

  @override
  String get locationPermission => 'Konum izni';

  @override
  String get checking => 'Kontrol ediliyor...';

  @override
  String get locationPermissionGrantedAlways => 'Verildi (Her zaman)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Verildi (Kullanım sırasında)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Reddedildi - istemek için dokunun';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Kalıcı olarak reddedildi - ayarları aç';

  @override
  String get locationPermissionDialogContent =>
      'Konum izni kalıcı olarak reddedildi. GPS takibi ve konum paylaşımını kullanmak için lütfen cihaz ayarlarından etkinleştirin.';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get locationPermissionGranted => 'Konum izni verildi!';

  @override
  String get locationPermissionRequiredForGps =>
      'GPS takibi ve konum paylaşımı için konum izni gereklidir.';

  @override
  String get locationPermissionAlreadyGranted => 'Konum izni zaten verilmiş.';

  @override
  String get sarNavyBlue => 'SAR Lacivert';

  @override
  String get sarNavyBlueDescription => 'Profesyonel/Operasyon modu';

  @override
  String get selectRecipient => 'Alıcı seç';

  @override
  String get broadcastToAllNearby => 'Yakındaki herkese yayınla';

  @override
  String get searchRecipients => 'Alıcı ara...';

  @override
  String get noContactsFound => 'Kişi bulunamadı';

  @override
  String get noRoomsFound => 'Oda bulunamadı';

  @override
  String get noRecipientsAvailable => 'Kullanılabilir alıcı yok';

  @override
  String get noChannelsFound => 'Kanal bulunamadı';

  @override
  String get newMessage => 'Yeni mesaj';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Polis lideri';

  @override
  String get sampleDroneOperator => 'Drone operatörü';

  @override
  String get sampleFirefighterAlpha => 'İtfaiyeci';

  @override
  String get sampleMedicCharlie => 'Sağlık görevlisi';

  @override
  String get sampleCommandDelta => 'Komuta';

  @override
  String get sampleFireEngine => 'İtfaiye aracı';

  @override
  String get sampleAirSupport => 'Hava desteği';

  @override
  String get sampleBaseCoordinator => 'Üs koordinatörü';

  @override
  String get channelEmergency => 'Acil durum';

  @override
  String get channelCoordination => 'Koordinasyon';

  @override
  String get channelUpdates => 'Güncellemeler';

  @override
  String get sampleTeamMember => 'Örnek ekip üyesi';

  @override
  String get sampleScout => 'Örnek keşifçi';

  @override
  String get sampleBase => 'Örnek üs';

  @override
  String get sampleSearcher => 'Örnek arayıcı';

  @override
  String get sampleObjectBackpack => ' Sırt çantası bulundu - mavi renk';

  @override
  String get sampleObjectVehicle => ' Terk edilmiş araç - sahibi kontrol edin';

  @override
  String get sampleObjectCamping => ' Kamp ekipmanı bulundu';

  @override
  String get sampleObjectTrailMarker => ' Yol dışında patika işareti bulundu';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Tüm ekipler durum bildirimi yapsın';

  @override
  String get sampleMsgWeatherUpdate =>
      'Hava durumu: açık gökyüzü, sıcaklık 18°C';

  @override
  String get sampleMsgBaseCamp => 'Üs kampı toplanma alanında kuruldu';

  @override
  String get sampleMsgTeamAlpha => 'Ekip sektör 2’ye ilerliyor';

  @override
  String get sampleMsgRadioCheck =>
      'Telsiz kontrolü - tüm istasyonlar yanıt versin';

  @override
  String get sampleMsgWaterSupply =>
      'Su ikmali 3 numaralı kontrol noktasında mevcut';

  @override
  String get sampleMsgTeamBravo => 'Ekip raporu: sektör 1 temiz';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Toplanma noktasına tahmini varış: 15 dakika';

  @override
  String get sampleMsgSupplyDrop => 'İkmal bırakma 14:00 için onaylandı';

  @override
  String get sampleMsgDroneSurvey => 'Drone taraması tamamlandı - bulgu yok';

  @override
  String get sampleMsgTeamCharlie => 'Ekip takviye istiyor';

  @override
  String get sampleMsgRadioDiscipline =>
      'Tüm birimler: telsiz disiplinini koruyun';

  @override
  String get sampleMsgUrgentMedical => 'ACİL: sektör 4’te tıbbi yardım gerekli';

  @override
  String get sampleMsgAdultMale => ' Yetişkin erkek, bilinci açık';

  @override
  String get sampleMsgFireSpotted => 'Yangın görüldü - koordinatlar geliyor';

  @override
  String get sampleMsgSpreadingRapidly => ' Hızla yayılıyor!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'ÖNCELİK: helikopter desteği gerekli';

  @override
  String get sampleMsgMedicalTeamEnRoute => 'Tıbbi ekip konumunuza geliyor';

  @override
  String get sampleMsgEvacHelicopter => 'Tahliye helikopteri ETA 10 dakika';

  @override
  String get sampleMsgEmergencyResolved => 'Acil durum çözüldü - tehlike yok';

  @override
  String get sampleMsgEmergencyStagingArea => ' Acil durum toplanma alanı';

  @override
  String get sampleMsgEmergencyServices =>
      'Acil servisler bilgilendirildi ve müdahale ediyor';

  @override
  String get sampleAlphaTeamLead => 'Ekip lideri';

  @override
  String get sampleBravoScout => 'Keşifçi';

  @override
  String get sampleCharlieMedic => 'Sağlık görevlisi';

  @override
  String get sampleDeltaNavigator => 'Navigatör';

  @override
  String get sampleEchoSupport => 'Destek';

  @override
  String get sampleBaseCommand => 'Üs komutası';

  @override
  String get sampleFieldCoordinator => 'Saha koordinatörü';

  @override
  String get sampleMedicalTeam => 'Tıbbi ekip';

  @override
  String get mapDrawing => 'Harita çizimi';

  @override
  String get navigateToDrawing => 'Çizime git';

  @override
  String get copyCoordinates => 'Koordinatları kopyala';

  @override
  String get hideFromMap => 'Haritadan gizle';

  @override
  String get lineDrawing => 'Çizgi çizimi';

  @override
  String get rectangleDrawing => 'Dikdörtgen çizimi';

  @override
  String get manualCoordinates => 'Manuel koordinatlar';

  @override
  String get enterCoordinatesManually => 'Koordinatları manuel girin';

  @override
  String get latitudeLabel => 'Enlem';

  @override
  String get longitudeLabel => 'Boylam';

  @override
  String get exampleCoordinates => 'Örnek: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Çizimi paylaş';

  @override
  String get shareWithAllNearbyDevices => 'Yakındaki tüm cihazlarla paylaş';

  @override
  String get shareToRoom => 'Odaya paylaş';

  @override
  String get sendToPersistentStorage => 'Kalıcı oda depolamasına gönder';

  @override
  String get deleteDrawingConfirm =>
      'Bu çizimi silmek istediğinizden emin misiniz?';

  @override
  String get drawingDeleted => 'Çizim silindi';

  @override
  String yourDrawingsCount(int count) {
    return 'Çizimleriniz ($count)';
  }

  @override
  String get shared => 'Paylaşıldı';

  @override
  String get line => 'Çizgi';

  @override
  String get rectangle => 'Dikdörtgen';

  @override
  String get updateAvailable => 'Güncelleme mevcut';

  @override
  String get currentVersion => 'Geçerli';

  @override
  String get latestVersion => 'En son';

  @override
  String get downloadUpdate => 'İndir';

  @override
  String get updateLater => 'Daha sonra';

  @override
  String get cadastralParcels => 'Kadastro parselleri';

  @override
  String get forestRoads => 'Orman yolları';

  @override
  String get wmsOverlays => 'WMS katmanları';

  @override
  String get hikingTrails => 'Yürüyüş parkurları';

  @override
  String get mainRoads => 'Ana yollar';

  @override
  String get houseNumbers => 'Kapı numaraları';

  @override
  String get fireHazardZones => 'Yangın tehlike bölgeleri';

  @override
  String get historicalFires => 'Geçmiş yangınlar';

  @override
  String get firebreaks => 'Yangın şeritleri';

  @override
  String get krasFireZones => 'Kras yangın bölgeleri';

  @override
  String get placeNames => 'Yer adları';

  @override
  String get municipalityBorders => 'Belediye sınırları';

  @override
  String get topographicMap => 'Topoğrafik harita 1:25000';

  @override
  String get recentMessages => 'Son mesajlar';

  @override
  String get addChannel => 'Kanal ekle';

  @override
  String get channelName => 'Kanal adı';

  @override
  String get channelNameHint => 'örn. Kurtarma Ekibi Alfa';

  @override
  String get channelSecret => 'Kanal sırrı';

  @override
  String get channelSecretHint => 'Bu kanal için paylaşılan parola';

  @override
  String get channelSecretHelp =>
      'Bu sır, bu kanala erişmesi gereken tüm ekip üyeleriyle paylaşılmalıdır';

  @override
  String get channelTypesInfo =>
      'Hash kanallar (#team): sır, isimden otomatik üretilir. Aynı isim = tüm cihazlarda aynı kanal.\n\nÖzel kanallar: açık bir sır kullanın. Yalnızca sırrı bilenler katılabilir.';

  @override
  String get hashChannelInfo =>
      'Hash kanal: sır kanal adından otomatik üretilecektir. Aynı adı kullanan herkes aynı kanala katılır.';

  @override
  String get channelNameRequired => 'Kanal adı gerekli';

  @override
  String get channelNameTooLong => 'Kanal adı en fazla 31 karakter olabilir';

  @override
  String get channelSecretRequired => 'Kanal sırrı gerekli';

  @override
  String get channelSecretTooLong =>
      'Kanal sırrı en fazla 32 karakter olabilir';

  @override
  String get invalidAsciiCharacters =>
      'Yalnızca ASCII karakterlere izin verilir';

  @override
  String get channelCreatedSuccessfully => 'Kanal başarıyla oluşturuldu';

  @override
  String channelCreationFailed(String error) {
    return 'Kanal oluşturulamadı: $error';
  }

  @override
  String get deleteChannel => 'Kanalı sil';

  @override
  String deleteChannelConfirmation(String channelName) {
    return '\"$channelName\" kanalını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal başarıyla silindi';

  @override
  String channelDeletionFailed(String error) {
    return 'Kanal silinemedi: $error';
  }

  @override
  String get createChannel => 'Kanal oluştur';

  @override
  String get wizardBack => 'Geri';

  @override
  String get wizardSkip => 'Atla';

  @override
  String get wizardNext => 'İleri';

  @override
  String get wizardGetStarted => 'Başla';

  @override
  String get wizardWelcomeTitle => 'MeshCore SAR uygulamasına hoş geldiniz';

  @override
  String get wizardWelcomeDescription =>
      'Arama ve kurtarma operasyonları için güçlü bir şebeke dışı iletişim aracı. Geleneksel ağlar kullanılamadığında ekibinizle mesh radyo teknolojisi üzerinden bağlantı kurun.';

  @override
  String get wizardConnectingTitle => 'Radyonuza bağlanma';

  @override
  String get wizardConnectingDescription =>
      'Şebeke dışı iletişime başlamak için akıllı telefonunuzu Bluetooth üzerinden bir MeshCore radyo cihazına bağlayın.';

  @override
  String get wizardConnectingFeature1 =>
      'Yakındaki MeshCore cihazlarını tarayın';

  @override
  String get wizardConnectingFeature2 =>
      'Radyonuzla Bluetooth üzerinden eşleşin';

  @override
  String get wizardConnectingFeature3 =>
      'Tamamen çevrimdışı çalışır - internet gerekmez';

  @override
  String get wizardChannelTitle => 'Kanallar';

  @override
  String get wizardChannelDescription =>
      'Bir kanaldaki herkese mesaj yayınlayın; ekip genelindeki duyurular ve koordinasyon için idealdir.';

  @override
  String get wizardChannelFeature1 =>
      'Genel ekip iletişimi için herkese açık kanal';

  @override
  String get wizardChannelFeature2 =>
      'Belirli gruplar için özel kanallar oluşturun';

  @override
  String get wizardChannelFeature3 =>
      'Mesajlar mesh tarafından otomatik iletilir';

  @override
  String get wizardContactsTitle => 'Kişiler';

  @override
  String get wizardContactsDescription =>
      'Ekip üyeleriniz mesh ağına katıldıkça otomatik olarak görünür. Onlara doğrudan mesaj gönderin veya konumlarını görüntüleyin.';

  @override
  String get wizardContactsFeature1 => 'Kişiler otomatik bulunur';

  @override
  String get wizardContactsFeature2 => 'Özel doğrudan mesaj gönderin';

  @override
  String get wizardContactsFeature3 =>
      'Pil seviyesini ve son görülme zamanını görüntüleyin';

  @override
  String get wizardMapTitle => 'Harita ve konum';

  @override
  String get wizardMapDescription =>
      'Ekibinizi gerçek zamanlı izleyin ve arama kurtarma operasyonları için önemli konumları işaretleyin.';

  @override
  String get wizardMapFeature1 =>
      'Bulunan kişiler, yangınlar ve toplanma alanları için SAR işaretleri';

  @override
  String get wizardMapFeature2 => 'Ekip üyelerinin gerçek zamanlı GPS takibi';

  @override
  String get wizardMapFeature3 =>
      'Uzak bölgeler için çevrimdışı haritalar indirin';

  @override
  String get wizardMapFeature4 => 'Şekiller çizin ve taktik bilgileri paylaşın';

  @override
  String get viewWelcomeTutorial => 'Karşılama eğitimini görüntüle';

  @override
  String get allTeamContacts => 'Tüm ekip kişileri';

  @override
  String directMessagesInfo(int count) {
    return 'ACK’li doğrudan mesajlar. $count ekip üyesine gönderildi.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR işareti $count kişiye gönderildi';
  }

  @override
  String get noContactsAvailable => 'Ekip kişisi yok';

  @override
  String get reply => 'Yanıtla';

  @override
  String get technicalDetails => 'Teknik ayrıntılar';

  @override
  String get messageTechnicalDetails => 'Mesaj teknik ayrıntıları';

  @override
  String get linkQuality => 'Bağlantı kalitesi';

  @override
  String get delivery => 'Teslimat';

  @override
  String get status => 'Durum';

  @override
  String get expectedAckTag => 'Beklenen ACK etiketi';

  @override
  String get roundTrip => 'Gidiş dönüş';

  @override
  String get retryAttempt => 'Yeniden deneme sayısı';

  @override
  String get floodFallback => 'Flood yedeği';

  @override
  String get identity => 'Kimlik';

  @override
  String get messageId => 'Mesaj kimliği';

  @override
  String get sender => 'Gönderen';

  @override
  String get senderKey => 'Gönderen anahtarı';

  @override
  String get recipient => 'Alıcı';

  @override
  String get recipientKey => 'Alıcı anahtarı';

  @override
  String get voice => 'Ses';

  @override
  String get voiceId => 'Ses kimliği';

  @override
  String get envelope => 'Zarf';

  @override
  String get sessionProgress => 'Oturum ilerlemesi';

  @override
  String get complete => 'Tamamlandı';

  @override
  String get rawDump => 'Ham döküm';

  @override
  String get cannotRetryMissingRecipient =>
      'Yeniden denenemiyor: alıcı bilgisi eksik';

  @override
  String get voiceUnavailable => 'Ses şu anda kullanılamıyor';

  @override
  String get requestingVoice => 'Ses isteniyor';

  @override
  String get device => 'cihaz';

  @override
  String get change => 'Değiştir';

  @override
  String get wizardOverviewDescription =>
      'Bu uygulama MeshCore mesajlaşmasını, SAR saha güncellemelerini, haritalamayı ve cihaz araçlarını tek bir yerde birleştirir.';

  @override
  String get wizardOverviewFeature1 =>
      'Ana Mesajlar sekmesinden doğrudan mesajlar, oda gönderileri ve kanal mesajları gönderin.';

  @override
  String get wizardOverviewFeature2 =>
      'Mesh üzerinden SAR işaretleri, harita çizimleri, ses klipleri ve görseller paylaşın.';

  @override
  String get wizardOverviewFeature3 =>
      'BLE veya TCP ile bağlanın, ardından yardımcı radyoyu uygulamanın içinden yönetin.';

  @override
  String get wizardMessagingTitle => 'Mesajlaşma ve saha raporları';

  @override
  String get wizardMessagingDescription =>
      'Buradaki mesajlar düz metinden fazlasıdır. Uygulama zaten çeşitli operasyonel yükleri ve aktarım akışlarını destekliyor.';

  @override
  String get wizardMessagingFeature1 =>
      'Doğrudan mesajları, oda gönderilerini ve kanal trafiğini tek bir düzenleyiciden gönderin.';

  @override
  String get wizardMessagingFeature2 =>
      'Yaygın saha raporları için SAR güncellemeleri ve yeniden kullanılabilir SAR şablonları oluşturun.';

  @override
  String get wizardMessagingFeature3 =>
      'Arayüzde ilerleme ve yayın süresi tahminleriyle ses oturumları ve görseller aktarın.';

  @override
  String get wizardConnectDeviceTitle => 'Cihazı bağla';

  @override
  String get wizardConnectDeviceDescription =>
      'MeshCore radyonuzu bağlayın, bir ad seçin ve devam etmeden önce bir radyo ön ayarı uygulayın.';

  @override
  String get wizardSetupBadge => 'Kurulum';

  @override
  String get wizardOverviewBadge => 'Genel bakış';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return '$deviceName cihazına bağlandı';
  }

  @override
  String get wizardNoDeviceConnected => 'Henüz bağlı cihaz yok';

  @override
  String get wizardSkipForNow => 'Şimdilik atla';

  @override
  String get wizardDeviceNameLabel => 'Cihaz adı';

  @override
  String get wizardDeviceNameHelp =>
      'Bu ad diğer MeshCore kullanıcılarına duyurulur.';

  @override
  String get wizardConfigRegionLabel => 'Yapılandırma bölgesi';

  @override
  String get wizardConfigRegionHelp =>
      'MeshCore\'un resmi ön ayar listesinin tamamını kullanır. Varsayılan EU/UK (Narrow) olur.';

  @override
  String get wizardPresetNote1 =>
      'Seçilen ön ayarın yerel radyo düzenlemelerinize uygun olduğundan emin olun.';

  @override
  String get wizardPresetNote2 =>
      'Liste, MeshCore yapılandırma aracının resmi ön ayar akışıyla eşleşir.';

  @override
  String get wizardPresetNote3 =>
      'Onboarding sırasında varsayılan olarak EU/UK (Narrow) seçili kalır.';

  @override
  String get wizardSaving => 'Kaydediliyor...';

  @override
  String get wizardSaveAndContinue => 'Kaydet ve devam et';

  @override
  String get wizardEnterDeviceName => 'Devam etmeden önce bir cihaz adı girin.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '$deviceName, $presetName ile kaydedildi.';
  }

  @override
  String get wizardNetworkTitle => 'Kişiler, odalar ve tekrarlayıcılar';

  @override
  String get wizardNetworkDescription =>
      'Kişiler sekmesi keşfettiğiniz ağı ve zamanla öğrendiğiniz rotaları düzenler.';

  @override
  String get wizardNetworkFeature1 =>
      'Ekip üyelerini, tekrarlayıcıları, odaları, kanalları ve bekleyen duyuruları tek listede inceleyin.';

  @override
  String get wizardNetworkFeature2 =>
      'Bağlantı karmaşıklaştığında smart ping, oda girişi, öğrenilen yollar ve rota sıfırlama araçlarını kullanın.';

  @override
  String get wizardNetworkFeature3 =>
      'Uygulamadan çıkmadan kanallar oluşturun ve ağ hedeflerini yönetin.';

  @override
  String get wizardMapOpsTitle => 'Harita, izler ve paylaşılan geometri';

  @override
  String get wizardMapOpsDescription =>
      'Uygulama haritası ayrı bir görüntüleyici olmak yerine mesajlaşma, takip ve SAR katmanlarıyla doğrudan bağlantılıdır.';

  @override
  String get wizardMapOpsFeature1 =>
      'Kendi konumunuzu, ekip arkadaşlarının konumlarını ve hareket izlerini harita üzerinde takip edin.';

  @override
  String get wizardMapOpsFeature2 =>
      'Mesajlardaki çizimleri açın, satır içinde önizleyin ve gerektiğinde haritadan kaldırın.';

  @override
  String get wizardMapOpsFeature3 =>
      'Sahadaki ağ kapsamasını anlamak için tekrarlayıcı harita görünümleri ve paylaşılan katmanları kullanın.';

  @override
  String get wizardToolsTitle => 'Mesajlaşma dışındaki araçlar';

  @override
  String get wizardToolsDescription =>
      'Burada dört ana sekmeden fazlası var. Uygulama ayrıca yapılandırma, tanılama ve isteğe bağlı sensör akışları içerir.';

  @override
  String get wizardToolsFeature1 =>
      'Radyo ayarlarını, telemetriyi, TX gücünü ve yardımcı cihaz ayrıntılarını değiştirmek için cihaz yapılandırmasını açın.';

  @override
  String get wizardToolsFeature2 =>
      'İzlenen sensör panoları ve hızlı yenileme eylemleri istediğinizde Sensörler sekmesini etkinleştirin.';

  @override
  String get wizardToolsFeature3 =>
      'Mesh sorunlarını giderirken paket günlükleri, spektrum taraması ve geliştirici tanılamalarını kullanın.';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => 'Sensörlerde';

  @override
  String get contactAddToSensors => 'Sensörlere ekle';

  @override
  String get contactSetPath => 'Yol ayarla';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName Sensörlere eklendi';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Rota temizlenemedi: $error';
  }

  @override
  String get contactRouteCleared => 'Rota temizlendi';

  @override
  String contactRouteSet(String route) {
    return 'Rota ayarlandı: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Rota ayarlanamadı: $error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'ACK zaman aşımı';

  @override
  String get opcode => 'Opcode';

  @override
  String get payload => 'Yük';

  @override
  String get hops => 'Atlama';

  @override
  String get hashSize => 'Hash boyutu';

  @override
  String get pathBytes => 'Yol baytları';

  @override
  String get selectedPath => 'Seçilen yol';

  @override
  String get estimatedTx => 'Tahmini gönderim';

  @override
  String get senderToReceipt => 'Gönderenden alındıya';

  @override
  String get receivedCopies => 'Alınan kopyalar';

  @override
  String get retryCause => 'Yeniden deneme nedeni';

  @override
  String get retryMode => 'Yeniden deneme modu';

  @override
  String get retryResult => 'Yeniden deneme sonucu';

  @override
  String get lastRetry => 'Son deneme';

  @override
  String get rxPackets => 'RX paketleri';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => 'Hız';

  @override
  String get window => 'Pencere';

  @override
  String get posttxDelay => 'Gönderim sonrası gecikme';

  @override
  String get bandpass => 'Bant geçiren';

  @override
  String get bandpassFilterVoice => 'Bant geçiren filtre ses';

  @override
  String get frequency => 'Frekans';

  @override
  String get australia => 'Avustralya';

  @override
  String get australiaNarrow => 'Avustralya (Dar)';

  @override
  String get australiaQld => 'Avustralya: QLD';

  @override
  String get australiaSaWa => 'Avustralya: SA, WA';

  @override
  String get newZealand => 'Yeni Zelanda';

  @override
  String get newZealandNarrow => 'Yeni Zelanda (Dar)';

  @override
  String get switzerland => 'İsviçre';

  @override
  String get portugal433 => 'Portekiz 433';

  @override
  String get portugal868 => 'Portekiz 868';

  @override
  String get czechRepublicNarrow => 'Çek Cumhuriyeti (Dar)';

  @override
  String get eu433mhzLongRange => 'AB 433MHz (Uzun Menzil)';

  @override
  String get euukDeprecated => 'AB/BK (Kullanımdan kalktı)';

  @override
  String get euukNarrow => 'AB/BK (Dar)';

  @override
  String get usacanadaRecommended => 'ABD/Kanada (Önerilen)';

  @override
  String get vietnamDeprecated => 'Vietnam (Kullanımdan kalktı)';

  @override
  String get vietnamNarrow => 'Vietnam (Dar)';

  @override
  String get active => 'Aktif';

  @override
  String get addContact => 'Kişi ekle';

  @override
  String get all => 'Tümü';

  @override
  String get autoResolve => 'Otomatik çöz';

  @override
  String get clearAllLabel => 'Tümünü temizle';

  @override
  String get clearRelays => 'Röleleri temizle';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get clearRoute => 'Rotayı temizle';

  @override
  String get clearMessages => 'Mesajları temizle';

  @override
  String get clearScale => 'Ölçeği temizle';

  @override
  String get clearDiscoveries => 'Keşifleri temizle';

  @override
  String get clearOnlineTraceDatabase => 'Çevrimiçi iz veritabanını temizle';

  @override
  String get clearAllChannels => 'Tüm kanalları temizle';

  @override
  String get clearAllContacts => 'Tüm kişileri temizle';

  @override
  String get clearChannels => 'Kanalları temizle';

  @override
  String get clearContacts => 'Kişileri temizle';

  @override
  String get clearPathOnMaxRetry => 'Maks denemede yolu temizle';

  @override
  String get create => 'Oluştur';

  @override
  String get custom => 'Özel';

  @override
  String get defaultValue => 'Varsayılan';

  @override
  String get duplicate => 'Çoğalt';

  @override
  String get editName => 'Adı düzenle';

  @override
  String get open => 'Aç';

  @override
  String get paste => 'Yapıştır';

  @override
  String get preview => 'Önizleme';

  @override
  String get remove => 'Kaldır';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get resolveAll => 'Tümünü çöz';

  @override
  String get send => 'Gönder';

  @override
  String get sendAnyway => 'Yine de gönder';

  @override
  String get share => 'Paylaş';

  @override
  String get shareContact => 'Kişiyi paylaş';

  @override
  String get trace => 'İz';

  @override
  String get use => 'Kullan';

  @override
  String get useSelectedFrequency => 'Seçilen frekansı kullan';

  @override
  String get discovery => 'Keşif';

  @override
  String get discoverRepeaters => 'Tekrarlayıcıları keşfet';

  @override
  String get discoverSensors => 'Sensörleri keşfet';

  @override
  String get repeaterDiscoverySent => 'Tekrarlayıcı keşfi gönderildi';

  @override
  String get sensorDiscoverySent => 'Sensör keşfi gönderildi';

  @override
  String get clearedPendingDiscoveries => 'Bekleyen keşifler temizlendi.';

  @override
  String get autoDiscovery => 'Otomatik keşif';

  @override
  String get enableAutomaticAdding => 'Otomatik eklemeyi etkinleştir';

  @override
  String get autoaddRepeaters => 'Tekrarlayıcıları otomatik ekle';

  @override
  String get autoaddRoomServers => 'Oda sunucularını otomatik ekle';

  @override
  String get autoaddSensors => 'Sensörleri otomatik ekle';

  @override
  String get autoaddUsers => 'Kullanıcıları otomatik ekle';

  @override
  String get overwriteOldestWhenFull => 'Dolduğunda en eskiyi üzerine yaz';

  @override
  String get storage => 'Depolama';

  @override
  String get dangerZone => 'Tehlikeli bölge';

  @override
  String get profiles => 'Profiller';

  @override
  String get favourites => 'Favoriler';

  @override
  String get sensors => 'Sensörler';

  @override
  String get others => 'Diğerleri';

  @override
  String get gpsModule => 'GPS Modülü';

  @override
  String get liveTraffic => 'Canlı trafik';

  @override
  String get repeatersMap => 'Tekrarlayıcılar haritası';

  @override
  String get spectrumScan => 'Spektrum taraması';

  @override
  String get blePacketLogs => 'BLE paket günlükleri';

  @override
  String get onlineTraceDatabase => 'Çevrimiçi iz veritabanı';

  @override
  String get routePathByteSize => 'Yol bayt boyutu';

  @override
  String get messageNotifications => 'Mesaj bildirimleri';

  @override
  String get sarAlerts => 'SAR uyarıları';

  @override
  String get discoveryNotifications => 'Keşif bildirimleri';

  @override
  String get updateNotifications => 'Güncelleme bildirimleri';

  @override
  String get muteWhileAppIsOpen => 'Uygulama açıkken sessize al';

  @override
  String get disableContacts => 'Kişileri devre dışı bırak';

  @override
  String get enableSensorsTab => 'Sensörler sekmesini etkinleştir';

  @override
  String get enableProfiles => 'Profilleri etkinleştir';

  @override
  String get autoRouteRotation => 'Otomatik rota rotasyonu';

  @override
  String get nearestRepeaterFallback => 'En yakın tekrarlayıcıya geri dönüş';

  @override
  String get deleteAllStoredMessageHistory => 'Tüm mesaj geçmişini sil';

  @override
  String get messageFontSize => 'Mesaj yazı tipi boyutu';

  @override
  String get rotateMapWithHeading => 'Haritayı yön ile döndür';

  @override
  String get showMapDebugInfo => 'Harita hata ayıklama bilgisini göster';

  @override
  String get openMapInFullscreen => 'Haritayı tam ekranda aç';

  @override
  String get showSarMarkersLabel => 'SAR işaretçilerini göster';

  @override
  String get displaySarMarkersOnTheMainMap =>
      'SAR işaretçilerini ana haritada göster';

  @override
  String get showAllContactTrailsLabel => 'Tüm kişi izlerini göster';

  @override
  String get hideRepeatersOnMap => 'Haritada tekrarlayıcıları gizle';

  @override
  String get setMapScale => 'Harita ölçeğini ayarla';

  @override
  String get customMapScaleSaved => 'Özel harita ölçeği kaydedildi';

  @override
  String get voiceBitrate => 'Ses bit hızı';

  @override
  String get voiceCompressor => 'Ses sıkıştırıcı';

  @override
  String get balancesQuietAndLoudSpeechLevels =>
      'Sessiz ve yüksek konuşma seviyelerini dengeler';

  @override
  String get voiceLimiter => 'Ses sınırlayıcı';

  @override
  String get preventsClippingPeaksBeforeEncoding =>
      'Kodlama öncesi tepe kırpmasını önler';

  @override
  String get micAutoGain => 'Mikrofon otomatik kazancı';

  @override
  String get letsTheRecorderAdjustInputLevel =>
      'Kaydedicinin giriş seviyesini ayarlamasına izin verir';

  @override
  String get echoCancellation => 'Yankı iptali';

  @override
  String get noiseSuppression => 'Gürültü bastırma';

  @override
  String get trimSilenceInVoiceMessages => 'Sesli mesajlarda sessizliği kırp';

  @override
  String get compressor => 'Sıkıştırıcı';

  @override
  String get limiter => 'Sınırlayıcı';

  @override
  String get autoGain => 'Otomatik kazanç';

  @override
  String get echoCancel => 'Yankı';

  @override
  String get noiseSuppress => 'Gürültü';

  @override
  String get silenceTrim => 'Sessizlik';

  @override
  String get maxImageSize => 'Maksimum resim boyutu';

  @override
  String get imageCompression => 'Resim sıkıştırma';

  @override
  String get grayscale => 'Gri tonlama';

  @override
  String get ultraMode => 'Ultra mod';

  @override
  String get fastPrivateGpsUpdates => 'Hızlı özel GPS güncellemeleri';

  @override
  String get movementThreshold => 'Hareket eşiği';

  @override
  String get fastGpsMovementThreshold => 'Hızlı GPS hareket eşiği';

  @override
  String get fastGpsActiveuseInterval => 'Hızlı GPS aktif kullanım aralığı';

  @override
  String get activeuseUpdateInterval => 'Aktif kullanım güncelleme aralığı';

  @override
  String get repeatNearbyTraffic => 'Yakın trafiği tekrarla';

  @override
  String get relayThroughRepeatersAcrossTheMesh =>
      'Ağ üzerindeki tekrarlayıcılar aracılığıyla ilet';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding =>
      'Yalnızca yakın, tekrarlayıcı taşkını olmadan';

  @override
  String get multihop => 'Çok atlamalı';

  @override
  String get createProfile => 'Profil oluştur';

  @override
  String get renameProfile => 'Profili yeniden adlandır';

  @override
  String get newProfile => 'Yeni profil';

  @override
  String get manageProfiles => 'Profilleri yönet';

  @override
  String get enableProfilesToStartManagingThem =>
      'Profilleri yönetmeye başlamak için etkinleştirin.';

  @override
  String get openMessage => 'Mesajı aç';

  @override
  String get jumpToTheRelatedSarMessage => 'İlgili SAR mesajına git';

  @override
  String get removeSarMarker => 'SAR işaretçisini kaldır';

  @override
  String get pleaseSelectADestinationToSendSarMarker =>
      'SAR işaretçisi göndermek için bir hedef seçin';

  @override
  String get sarMarkerBroadcastToPublicChannel =>
      'SAR işaretçisi genel kanala yayınlandı';

  @override
  String get sarMarkerSentToRoom => 'SAR işaretçisi odaya gönderildi';

  @override
  String get loadFromGallery => 'Galeriden yükle';

  @override
  String get replaceImage => 'Resmi değiştir';

  @override
  String get selectFromGallery => 'Galeriden seç';

  @override
  String get team => 'Takım';

  @override
  String get found => 'Bulundu';

  @override
  String get staging => 'Toplanma alanı';

  @override
  String get object => 'Nesne';

  @override
  String get quiet => 'Sessiz';

  @override
  String get moderate => 'Orta';

  @override
  String get busy => 'Meşgul';

  @override
  String get spectrumScanReturnedNoCandidateFrequencies =>
      'Spektrum taraması aday frekans bulamadı';

  @override
  String get searchMessages => 'Mesajlarda ara';

  @override
  String get sendImageFromGallery => 'Galeriden resim gönder';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get dmOnly => 'Yalnızca DM';

  @override
  String get allMessages => 'Tüm mesajlar';

  @override
  String get sendToPublicChannel => 'Genel kanala gönderilsin mi?';

  @override
  String get selectMarkerTypeAndDestination =>
      'İşaretçi türünü ve hedefi seçin';

  @override
  String get noDestinationsAvailableLabel => 'Kullanılabilir hedef yok';

  @override
  String get image => 'Resim';

  @override
  String get format => 'Biçim';

  @override
  String get dimensions => 'Boyutlar';

  @override
  String get segments => 'Segmentler';

  @override
  String get transfers => 'Transferler';

  @override
  String get downloadedBy => 'İndiren';

  @override
  String get saveDiscoverySettings => 'Keşif ayarlarını kaydet';

  @override
  String get savePublicInfo => 'Genel bilgileri kaydet';

  @override
  String get saveRadioSettings => 'Radyo ayarlarını kaydet';

  @override
  String get savePath => 'Yolu kaydet';

  @override
  String get wipeDeviceData => 'Cihaz verilerini sil';

  @override
  String get wipeDevice => 'Cihazı sil';

  @override
  String get destructiveDeviceActions => 'Yıkıcı cihaz işlemleri.';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings =>
      'Bir ön ayar seçin veya radyo ayarlarını ince ayarlayın.';

  @override
  String get chooseTheNameAndLocationThisDeviceShares =>
      'Bu cihazın paylaştığı ad ve konumu seçin.';

  @override
  String get availableSpaceOnThisDevice => 'Bu cihazda kullanılabilir alan.';

  @override
  String get used => 'Kullanılan';

  @override
  String get total => 'Toplam';

  @override
  String get renameValue => 'Değeri yeniden adlandır';

  @override
  String get customizeFields => 'Alanları özelleştir';

  @override
  String get livePreview => 'Canlı önizleme';

  @override
  String get refreshSchedule => 'Yenileme programı';

  @override
  String get noResponse => 'Yanıt yok';

  @override
  String get refreshing => 'Yenileniyor';

  @override
  String get unavailable => 'Kullanılamaz';

  @override
  String get pickARelayOrNodeToWatchInSensors =>
      'İzlemek için bir röle veya düğüm seçin.';

  @override
  String get publicKeyLabel => 'Genel anahtar';

  @override
  String get alreadyInContacts => 'Zaten kişilerde';

  @override
  String get connectToADeviceBeforeAddingContacts =>
      'Kişi eklemeden önce bir cihaza bağlanın';

  @override
  String get fromContacts => 'Kişilerden';

  @override
  String get onlineOnly => 'Yalnızca çevrimiçi';

  @override
  String get inBoth => 'Her ikisinde';

  @override
  String get source => 'Kaynak';

  @override
  String get manualRouteEdit => 'Manuel rota düzenle';

  @override
  String get observedMeshRoute => 'Gözlemlenen mesh rotası';

  @override
  String get allMessagesCleared => 'Tüm mesajlar temizlendi';

  @override
  String get onlineTraceDatabaseCleared => 'Çevrimiçi iz veritabanı temizlendi';

  @override
  String get packetLogsCleared => 'Paket günlükleri temizlendi';

  @override
  String get hexDataCopiedToClipboard => 'Hex verisi panoya kopyalandı';

  @override
  String get developerModeEnabled => 'Geliştirici modu etkinleştirildi';

  @override
  String get developerModeDisabled => 'Geliştirici modu devre dışı bırakıldı';

  @override
  String get clipboardIsEmpty => 'Pano boş';

  @override
  String get contactImported => 'Kişi içe aktarıldı';

  @override
  String get contactLinkCopiedToClipboard =>
      'Kişi bağlantısı panoya kopyalandı';

  @override
  String get failedToExportContact => 'Kişi dışa aktarılamadı';

  @override
  String get noLogsToExport => 'Dışa aktarılacak günlük yok';

  @override
  String get exportAsCsv => 'CSV olarak dışa aktar';

  @override
  String get exportAsText => 'Metin olarak dışa aktar';

  @override
  String get receivedRfc3339 => 'Alındı (RFC3339)';

  @override
  String get buildTime => 'Derleme zamanı';

  @override
  String get downloadUrlNotAvailable => 'İndirme URL\'si mevcut değil';

  @override
  String get cannotOpenDownloadUrl => 'İndirme URL\'si açılamıyor';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid =>
      'Güncelleme kontrolü yalnızca Android\'de kullanılabilir';

  @override
  String get youAreRunningTheLatestVersion => 'En son sürümü kullanıyorsunuz';

  @override
  String get updateAvailableButDownloadUrlNotFound =>
      'Güncelleme mevcut ancak indirme URL\'si bulunamadı';

  @override
  String get startTictactoe => 'Tic-Tac-Toe başlat';

  @override
  String get tictactoeUnavailable => 'Tic-Tac-Toe kullanılamıyor';

  @override
  String get tictactoeOpponentUnknown => 'Tic-Tac-Toe: rakip bilinmiyor';

  @override
  String get tictactoeWaitingForStart => 'Tic-Tac-Toe: başlangıç bekleniyor';

  @override
  String get acceptsShareLinks => 'Paylaşım bağlantılarını kabul eder';

  @override
  String get supportsRawHex => 'Ham hex destekler';

  @override
  String get clipboardfriendly => 'Pano dostu';

  @override
  String get captured => 'Yakalandı';

  @override
  String get size => 'Boyut';

  @override
  String get noCustomChannelsToClear => 'Temizlenecek özel kanal yok.';

  @override
  String get noDeviceContactsToClear => 'Temizlenecek cihaz kişisi yok.';
}
