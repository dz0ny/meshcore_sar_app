// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => '消息';

  @override
  String get contacts => '联系人';

  @override
  String get map => '地图';

  @override
  String get settings => '设置';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开连接';

  @override
  String get scanningForDevices => '正在扫描设备...';

  @override
  String get noDevicesFound => '未找到设备';

  @override
  String get scanAgain => '重新扫描';

  @override
  String get tapToConnect => '点击连接';

  @override
  String get deviceNotConnected => '设备未连接';

  @override
  String get locationPermissionDenied => '位置权限被拒绝';

  @override
  String get locationPermissionPermanentlyDenied => '位置权限被永久拒绝。请在设置中启用。';

  @override
  String get locationPermissionRequired => 'GPS 跟踪和团队协调需要位置权限。您可以稍后在设置中启用。';

  @override
  String get locationServicesDisabled => '位置服务已禁用。请在设置中启用。';

  @override
  String get failedToGetGpsLocation => '获取 GPS 位置失败';

  @override
  String advertisedAtLocation(String latitude, String longitude) {
    return '已广播位置 $latitude, $longitude';
  }

  @override
  String failedToAdvertise(String error) {
    return '广播失败: $error';
  }

  @override
  String reconnecting(int attempt, int max) {
    return '正在重新连接... ($attempt/$max)';
  }

  @override
  String get cancelReconnection => '取消重新连接';

  @override
  String get mapManagement => '地图管理';

  @override
  String get general => '通用';

  @override
  String get theme => '主题';

  @override
  String get chooseTheme => '选择主题';

  @override
  String get light => '亮色';

  @override
  String get dark => '暗色';

  @override
  String get blueLightTheme => '蓝色亮色主题';

  @override
  String get blueDarkTheme => '蓝色暗色主题';

  @override
  String get sarRed => '搜救红';

  @override
  String get alertEmergencyMode => '警报/紧急模式';

  @override
  String get sarGreen => '搜救绿';

  @override
  String get safeAllClearMode => '安全/解除警报模式';

  @override
  String get autoSystem => '自动 (跟随系统)';

  @override
  String get followSystemTheme => '跟随系统主题';

  @override
  String get showRxTxIndicators => '显示 RX/TX 指示器';

  @override
  String get displayPacketActivity => '在顶部栏显示数据包活动指示器';

  @override
  String get simpleMode => '简洁模式';

  @override
  String get simpleModeDescription => '在消息和联系人中隐藏非必要信息';

  @override
  String get disableMap => '禁用地图';

  @override
  String get disableMapDescription => '隐藏地图标签页以减少电池消耗';

  @override
  String get language => '语言';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get english => '英语';

  @override
  String get slovenian => '斯洛文尼亚语';

  @override
  String get croatian => '克罗地亚语';

  @override
  String get german => '德语';

  @override
  String get spanish => '西班牙语';

  @override
  String get french => '法语';

  @override
  String get italian => '意大利语';

  @override
  String get locationBroadcasting => '位置广播';

  @override
  String get autoLocationTracking => '自动位置跟踪';

  @override
  String get automaticallyBroadcastPosition => '自动广播位置更新';

  @override
  String get configureTracking => '配置跟踪';

  @override
  String get distanceAndTimeThresholds => '距离和时间阈值';

  @override
  String get locationTrackingConfiguration => '位置跟踪配置';

  @override
  String get configureWhenLocationBroadcasts => '配置何时向 Mesh 网络发送位置广播';

  @override
  String get minimumDistance => '最小距离';

  @override
  String broadcastAfterMoving(String distance) {
    return '仅在移动 $distance 米后广播';
  }

  @override
  String get maximumDistance => '最大距离';

  @override
  String alwaysBroadcastAfterMoving(String distance) {
    return '移动 $distance 米后始终广播';
  }

  @override
  String get minimumTimeInterval => '最小时间间隔';

  @override
  String alwaysBroadcastEvery(String duration) {
    return '每隔 $duration 始终广播';
  }

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get about => '关于';

  @override
  String get appVersion => '应用版本';

  @override
  String get appName => '应用名称';

  @override
  String get aboutMeshCoreSar => '关于 MeshCore 搜救助手';

  @override
  String get aboutDescription =>
      '专为应急响应团队设计的搜救应用程序。功能包括：\n\n• 用于设备间通信的 BLE Mesh 网络\n• 带有多个图层选项的离线地图\n• 实时团队成员跟踪\n• 搜救战术标记（找到的人员、火灾、集结区）\n• 联系人管理和消息收发\n• 带有指南针方向的 GPS 跟踪\n• 用于离线使用的地图瓦片缓存';

  @override
  String get technologiesUsed => '使用的技术：';

  @override
  String get technologiesList =>
      '• 用于跨平台开发的 Flutter\n• 用于 Mesh 网络的 BLE（低功耗蓝牙）\n• 用于地图的 OpenStreetMap\n• 用于状态管理的 Provider\n• 用于本地存储的 SharedPreferences';

  @override
  String get moreInfo => '更多信息';

  @override
  String get learnMoreAbout => '了解更多关于 MeshCore 搜救助手的信息';

  @override
  String get developer => '开发者';

  @override
  String get packageName => '包名';

  @override
  String get sampleData => '示例数据';

  @override
  String get sampleDataDescription => '加载或清除用于测试的示例联系人、频道消息和搜救标记';

  @override
  String get loadSampleData => '加载示例数据';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearAllDataConfirmTitle => '清除所有数据';

  @override
  String get clearAllDataConfirmMessage => '这将清除所有联系人和搜救标记。您确定吗？';

  @override
  String get clear => '清除';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return '已加载 $teamCount 个团队成员，$channelCount 个频道，$sarCount 个搜救标记，$messageCount 条消息';
  }

  @override
  String failedToLoadSampleData(String error) {
    return '加载示例数据失败：$error';
  }

  @override
  String get allDataCleared => '所有数据已清除';

  @override
  String get failedToStartBackgroundTracking => '启动后台跟踪失败。请检查权限和 BLE 连接。';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return '位置广播：$latitude, $longitude';
  }

  @override
  String get defaultPinInfo => '无屏幕设备的默认 PIN 是 123456。配对有问题？请在系统设置中忘记该蓝牙设备。';

  @override
  String get noMessagesYet => '暂无消息';

  @override
  String get pullDownToSync => '下拉同步消息';

  @override
  String get deleteContact => '删除联系人';

  @override
  String get delete => '删除';

  @override
  String get viewOnMap => '在地图上查看';

  @override
  String get refresh => '刷新';

  @override
  String get sendDirectMessage => '发送';

  @override
  String get resetPath => '重置路径 (重新路由)';

  @override
  String get publicKeyCopied => '公钥已复制到剪贴板';

  @override
  String copiedToClipboard(String label) {
    return '$label 已复制到剪贴板';
  }

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String failedToSyncContacts(String error) {
    return '同步联系人失败：$error';
  }

  @override
  String get loggedInSuccessfully => '登录成功！正在等待房间消息...';

  @override
  String get loginFailed => '登录失败 - 密码错误';

  @override
  String loggingIn(String roomName) {
    return '正在登录到 $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return '发送登录命令失败：$error';
  }

  @override
  String get lowLocationAccuracy => '位置精度低';

  @override
  String get continue_ => '继续';

  @override
  String get sendSarMarker => '发送搜救标记';

  @override
  String get deleteDrawing => '删除绘图';

  @override
  String get drawingTools => '绘图工具';

  @override
  String get drawLine => '绘制线条';

  @override
  String get drawLineDesc => '在地图上绘制手绘线条';

  @override
  String get drawRectangle => '绘制矩形';

  @override
  String get drawRectangleDesc => '在地图上绘制矩形区域';

  @override
  String get measureDistance => '测量距离';

  @override
  String get measureDistanceDesc => '长按两个点进行测量';

  @override
  String get clearMeasurement => '清除测量';

  @override
  String distanceLabel(String distance) {
    return '距离：$distance';
  }

  @override
  String get longPressForSecondPoint => '长按以选择第二个点';

  @override
  String get longPressToStartMeasurement => '长按以设置第一个点';

  @override
  String get longPressToStartNewMeasurement => '长按以开始新的测量';

  @override
  String get shareDrawings => '共享绘图';

  @override
  String get clearAllDrawings => '清除所有绘图';

  @override
  String get completeLine => '完成线条';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return '向团队广播 $count 个绘图';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return '移除所有 $count 个绘图';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return '从地图上删除所有 $count 个绘图吗？';
  }

  @override
  String get drawing => '绘图';

  @override
  String shareDrawingsCount(int count, String plural) {
    return '共享 $count 个绘图';
  }

  @override
  String sentDrawingsToRoom(int count, String plural, String roomName) {
    return '已发送 $count 个地图绘制到 $roomName';
  }

  @override
  String sharedDrawingsToRoom(
    int success,
    int total,
    String plural,
    String roomName,
  ) {
    return '已将 $success/$total 个绘图共享到 $roomName';
  }

  @override
  String get showReceivedDrawings => '显示接收到的绘图';

  @override
  String get showingAllDrawings => '显示所有绘图';

  @override
  String get showingOnlyYourDrawings => '仅显示您自己的绘图';

  @override
  String get showSarMarkers => '显示搜救标记';

  @override
  String get showingSarMarkers => '显示搜救标记';

  @override
  String get hidingSarMarkers => '隐藏搜救标记';

  @override
  String get clearAll => '全部清除';

  @override
  String get noLocalDrawings => '没有可共享的本地绘图';

  @override
  String get publicChannel => '公共频道';

  @override
  String get broadcastToAll => '广播给所有附近节点（临时）';

  @override
  String get storedPermanently => '永久存储在房间中';

  @override
  String drawingsSentToPublicChannel(int count, String plural) {
    return '已将 $count 个地图绘制发送到公共频道';
  }

  @override
  String drawingsSharedToPublicChannel(int success, int total) {
    return '已将 $success/$total 个绘图共享到公共频道';
  }

  @override
  String get notConnectedToDevice => '未连接到设备';

  @override
  String get directMessage => '直连消息';

  @override
  String directMessageSentTo(String contactName) {
    return '直连消息已发送给 $contactName';
  }

  @override
  String failedToSend(String error) {
    return '发送失败：$error';
  }

  @override
  String directMessageInfo(String contactName) {
    return '此消息将直连发送给 $contactName。它也将出现在主消息流中。';
  }

  @override
  String get typeYourMessage => '输入您的消息...';

  @override
  String get quickLocationMarker => '快速位置标记';

  @override
  String get markerType => '标记类型';

  @override
  String get sendTo => '发送至';

  @override
  String get noDestinationsAvailable => '没有可用的目的地。';

  @override
  String get selectDestination => '选择目的地...';

  @override
  String get ephemeralBroadcastInfo => '临时：仅通过无线广播。不存储 - 节点必须在线。';

  @override
  String get persistentRoomInfo => '持久：不可变地存储在房间中。自动同步并离线保留。';

  @override
  String get location => '位置';

  @override
  String get myLocation => '我的位置';

  @override
  String get fromMap => '来自地图';

  @override
  String get gettingLocation => '正在获取位置...';

  @override
  String get locationError => '位置错误';

  @override
  String get retry => '重试';

  @override
  String get refreshLocation => '刷新位置';

  @override
  String accuracyMeters(int accuracy) {
    return '精度：±$accuracy米';
  }

  @override
  String get notesOptional => '备注（可选）';

  @override
  String get addAdditionalInformation => '添加附加信息...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return '位置精度为 ±$accuracy米。这可能不足以用于搜救行动。\n\n仍然继续吗？';
  }

  @override
  String get loginToRoom => '登录到房间';

  @override
  String get enterPasswordInfo => '输入访问此房间的密码。密码将被保存以供将来使用。';

  @override
  String get password => '密码';

  @override
  String get enterRoomPassword => '输入房间密码';

  @override
  String get loggingInDots => '正在登录...';

  @override
  String get login => '登录';

  @override
  String failedToAddRoom(String error) {
    return '无法将房间添加到设备：$error\n\n该房间可能尚未广播。\n请等待房间广播。';
  }

  @override
  String get direct => '直连';

  @override
  String get flood => '泛洪';

  @override
  String get admin => '管理员';

  @override
  String get loggedIn => '已登录';

  @override
  String get noGpsData => '无 GPS 数据';

  @override
  String get distance => '距离';

  @override
  String pingingDirect(String name) {
    return '正在 Ping $name（通过路径直连发送）...';
  }

  @override
  String pingingFlood(String name) {
    return '正在 Ping $name（泛洪 - 无路径）...';
  }

  @override
  String directPingTimeout(String name) {
    return '直连 Ping 超时 - 正在使用泛洪重试 $name...';
  }

  @override
  String pingSuccessful(String name, String fallback) {
    return '成功 Ping 到 $name$fallback';
  }

  @override
  String get viaFloodingFallback => '（通过泛洪回退）';

  @override
  String pingFailed(String name) {
    return 'Ping $name 失败 - 未收到响应';
  }

  @override
  String deleteContactConfirmation(String name) {
    return '您确定要删除“$name”吗？\n\n这将从应用程序和配套的无线电设备中移除该联系人。';
  }

  @override
  String removingContact(String name) {
    return '正在移除 $name...';
  }

  @override
  String contactRemoved(String name) {
    return '联系人“$name”已移除';
  }

  @override
  String failedToRemoveContact(String error) {
    return '移除联系人失败：$error';
  }

  @override
  String get type => '类型';

  @override
  String get publicKey => '公钥';

  @override
  String get lastSeen => '最后在线';

  @override
  String get roomStatus => '房间状态';

  @override
  String get loginStatus => '登录状态';

  @override
  String get notLoggedIn => '未登录';

  @override
  String get adminAccess => '管理员权限';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get permissions => '权限';

  @override
  String get passwordSaved => '密码已保存';

  @override
  String get locationColon => '位置：';

  @override
  String get telemetry => '遥测';

  @override
  String requestingTelemetry(String name) {
    return '正在向 $name 请求遥测数据...';
  }

  @override
  String get voltage => '电压';

  @override
  String get battery => '电池';

  @override
  String get temperature => '温度';

  @override
  String get humidity => '湿度';

  @override
  String get pressure => '气压';

  @override
  String get gpsTelemetry => 'GPS（遥测）';

  @override
  String get updated => '更新于';

  @override
  String pathResetInfo(String name) {
    return '已重置 $name 的路径。下一条消息将寻找新路由。';
  }

  @override
  String get reLoginToRoom => '重新登录到房间';

  @override
  String get heading => '航向';

  @override
  String get elevation => '海拔';

  @override
  String get accuracy => '精度';

  @override
  String get bearing => '方位角';

  @override
  String get direction => '方向';

  @override
  String get filterMarkers => '筛选标记';

  @override
  String get filterMarkersTooltip => '筛选标记';

  @override
  String get contactsFilter => '联系人';

  @override
  String get repeatersFilter => '转发节点';

  @override
  String get sarMarkers => '搜救标记';

  @override
  String get foundPerson => '找到的人员';

  @override
  String get fire => '火灾';

  @override
  String get stagingArea => '集结区';

  @override
  String get showAll => '显示全部';

  @override
  String get nearbyContacts => '附近联系人';

  @override
  String get locationUnavailable => '位置不可用';

  @override
  String get ahead => '前方';

  @override
  String degreesRight(int degrees) {
    return '向右 $degrees°';
  }

  @override
  String degreesLeft(int degrees) {
    return '向左 $degrees°';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return '纬度：$latitude 经度：$longitude';
  }

  @override
  String get noContactsYet => '暂无联系人';

  @override
  String get connectToDeviceToLoadContacts => '连接设备以加载联系人';

  @override
  String get teamMembers => '团队成员';

  @override
  String get repeaters => '转发节点';

  @override
  String get rooms => '房间';

  @override
  String get channels => '频道';

  @override
  String get cacheStatistics => '缓存统计';

  @override
  String get totalTiles => '总瓦片数';

  @override
  String get cacheSize => '缓存大小';

  @override
  String get storeName => '存储名称';

  @override
  String get noCacheStatistics => '没有可用的缓存统计信息';

  @override
  String get downloadRegion => '下载区域';

  @override
  String get mapLayer => '地图图层';

  @override
  String get regionBounds => '区域边界';

  @override
  String get north => '北';

  @override
  String get south => '南';

  @override
  String get east => '东';

  @override
  String get west => '西';

  @override
  String get zoomLevels => '缩放级别';

  @override
  String minZoom(int zoom) {
    return '最小：$zoom';
  }

  @override
  String maxZoom(int zoom) {
    return '最大：$zoom';
  }

  @override
  String get downloadingDots => '正在下载...';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get downloadRegionButton => '下载区域';

  @override
  String get downloadNote => '注意：大的区域或高缩放级别可能需要大量时间和存储空间。';

  @override
  String get cacheManagement => '缓存管理';

  @override
  String get clearAllMaps => '清除所有地图';

  @override
  String get clearMapsConfirmTitle => '清除所有地图';

  @override
  String get clearMapsConfirmMessage => '您确定要删除所有下载的地图吗？此操作无法撤销。';

  @override
  String get mapDownloadCompleted => '地图下载完成！';

  @override
  String get cacheClearedSuccessfully => '缓存清除成功！';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get startingDownload => '正在开始下载...';

  @override
  String get downloadingMapTiles => '正在下载地图瓦片...';

  @override
  String get downloadCompletedSuccessfully => '下载成功完成！';

  @override
  String get cancellingDownload => '正在取消下载...';

  @override
  String errorLoadingStats(String error) {
    return '加载统计信息时出错：$error';
  }

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String cancelFailed(String error) {
    return '取消失败：$error';
  }

  @override
  String clearCacheFailed(String error) {
    return '清除缓存失败：$error';
  }

  @override
  String minZoomError(String error) {
    return '最小缩放：$error';
  }

  @override
  String maxZoomError(String error) {
    return '最大缩放：$error';
  }

  @override
  String get minZoomGreaterThanMax => '最小缩放必须小于或等于最大缩放';

  @override
  String get selectMapLayer => '选择地图图层';

  @override
  String get mapOptions => '地图选项';

  @override
  String get showLegend => '显示图例';

  @override
  String get displayMarkerTypeCounts => '显示标记类型计数';

  @override
  String get rotateMapWithHeading => '随航向旋转地图';

  @override
  String get mapFollowsDirection => '地图在移动时跟随您的方向';

  @override
  String get resetMapRotation => '重置旋转';

  @override
  String get resetMapRotationTooltip => '重置地图方向为北';

  @override
  String get showMapDebugInfo => '显示地图调试信息';

  @override
  String get displayZoomLevelBounds => '显示缩放级别和边界';

  @override
  String get fullscreenMode => '全屏模式';

  @override
  String get hideUiFullMapView => '隐藏所有 UI 控件以获得全地图视图';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI 卫星图';

  @override
  String get googleHybrid => 'Google 混合图';

  @override
  String get googleRoadmap => 'Google 道路图';

  @override
  String get googleTerrain => 'Google 地形图';

  @override
  String get downloadVisibleArea => '下载可见区域';

  @override
  String get initializingMap => '正在初始化地图...';

  @override
  String get dragToPosition => '拖动以定位';

  @override
  String get createSarMarker => '创建搜救标记';

  @override
  String get compass => '指南针';

  @override
  String get navigationAndContacts => '导航与联系人';

  @override
  String get sarAlert => '搜救警报';

  @override
  String get messageSentToPublicChannel => '消息已发送到公共频道';

  @override
  String get pleaseSelectRoomToSendSar => '请选择一个房间发送搜救标记';

  @override
  String failedToSendSarMarker(String error) {
    return '发送搜救标记失败：$error';
  }

  @override
  String sarMarkerSentTo(String roomName) {
    return '搜救标记已发送到 $roomName';
  }

  @override
  String get notConnectedCannotSync => '未连接 - 无法同步消息';

  @override
  String syncedMessageCount(int count) {
    return '已同步 $count 条消息';
  }

  @override
  String get noNewMessages => '没有新消息';

  @override
  String syncFailed(String error) {
    return '同步失败：$error';
  }

  @override
  String get failedToResendMessage => '重新发送消息失败';

  @override
  String get retryingMessage => '正在重试消息...';

  @override
  String retryFailed(String error) {
    return '重试失败：$error';
  }

  @override
  String get textCopiedToClipboard => '文本已复制到剪贴板';

  @override
  String get cannotReplySenderMissing => '无法回复：缺少发送者信息';

  @override
  String get cannotReplyContactNotFound => '无法回复：未找到联系人';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get copyText => '复制文本';

  @override
  String get saveAsTemplate => '另存为模板';

  @override
  String get templateSaved => '模板保存成功';

  @override
  String get templateAlreadyExists => '具有此表情符号的模板已存在';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get deleteMessageConfirmation => '您确定要删除此消息吗？';

  @override
  String get shareLocation => '共享位置';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\n坐标：$lat, $lon\n\n谷歌地图：$url';
  }

  @override
  String get sarLocationShare => '搜救位置';

  @override
  String get locationShared => '位置已共享';

  @override
  String get refreshedContacts => '联系人已刷新';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds秒前';
  }

  @override
  String get sending => '发送中...';

  @override
  String get sent => '已发送';

  @override
  String get delivered => '已送达';

  @override
  String deliveredWithTime(int time) {
    return '已送达（$time毫秒）';
  }

  @override
  String get failed => '失败';

  @override
  String get broadcast => '广播';

  @override
  String deliveredToContacts(int delivered, int total) {
    return '已送达 $delivered/$total 个联系人';
  }

  @override
  String get allDelivered => '全部送达';

  @override
  String get recipientDetails => '收件人详情';

  @override
  String get pending => '等待中';

  @override
  String get sarMarkerFoundPerson => '找到的人员';

  @override
  String get sarMarkerFire => '火灾位置';

  @override
  String get sarMarkerStagingArea => '集结区';

  @override
  String get sarMarkerObject => '发现的物品';

  @override
  String get from => '来自';

  @override
  String get coordinates => '坐标';

  @override
  String get tapToViewOnMap => '点击在地图上查看';

  @override
  String get radioSettings => '无线电设置';

  @override
  String get frequencyMHz => '频率 (MHz)';

  @override
  String get frequencyExample => '例如 869.618';

  @override
  String get bandwidth => '带宽';

  @override
  String get spreadingFactor => '扩频因子';

  @override
  String get codingRate => '编码率';

  @override
  String get txPowerDbm => '发射功率 (dBm)';

  @override
  String maxPowerDbm(int power) {
    return '最大：$power dBm';
  }

  @override
  String get you => '您';

  @override
  String get offlineVectorMaps => '离线矢量地图';

  @override
  String get offlineVectorMapsDescription =>
      '导入和管理离线矢量地图瓦片（MBTiles 格式），以便在没有互联网连接时使用';

  @override
  String get importMbtiles => '导入 MBTiles 文件';

  @override
  String get importMbtilesNote =>
      '支持带有矢量瓦片（PBF/MVT 格式）的 MBTiles 文件。Geofabrik 的数据提取非常好用！';

  @override
  String get noMbtilesFiles => '未找到离线矢量地图';

  @override
  String get mbtilesImportedSuccessfully => 'MBTiles 文件导入成功';

  @override
  String get failedToImportMbtiles => '导入 MBTiles 文件失败';

  @override
  String get deleteMbtilesConfirmTitle => '删除离线地图';

  @override
  String deleteMbtilesConfirmMessage(String name) {
    return '您确定要删除“$name”吗？这将永久移除该离线地图。';
  }

  @override
  String get mbtilesDeletedSuccessfully => '离线地图删除成功';

  @override
  String get failedToDeleteMbtiles => '删除离线地图失败';

  @override
  String get importExportCachedTiles => '导入/导出缓存的瓦片';

  @override
  String get importExportDescription => '在设备之间备份、共享和恢复下载的地图瓦片';

  @override
  String get exportTilesToFile => '导出瓦片到文件';

  @override
  String get importTilesFromFile => '从文件导入瓦片';

  @override
  String get selectExportLocation => '选择导出位置';

  @override
  String get selectImportFile => '选择瓦片存档';

  @override
  String get exportingTiles => '正在导出瓦片...';

  @override
  String get importingTiles => '正在导入瓦片...';

  @override
  String exportSuccess(int count) {
    return '成功导出 $count 个瓦片';
  }

  @override
  String importSuccess(int count) {
    return '成功导入 $count 个存储';
  }

  @override
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get exportNote => '创建一个压缩存档（.fmtc）文件，可以共享并在其他设备上导入。';

  @override
  String get importNote => '从先前导出的存档文件导入地图瓦片。瓦片将与现有缓存合并。';

  @override
  String get noTilesToExport => '没有可导出的瓦片';

  @override
  String archiveContainsStores(int count) {
    return '存档包含 $count 个存储';
  }

  @override
  String get vectorTiles => '矢量瓦片';

  @override
  String get schema => '模式';

  @override
  String get unknown => '未知';

  @override
  String get bounds => '边界';

  @override
  String get onlineLayers => '在线图层';

  @override
  String get offlineLayers => '离线图层';

  @override
  String get locationTrail => '位置轨迹';

  @override
  String get showTrailOnMap => '在地图上显示轨迹';

  @override
  String get trailVisible => '轨迹在地图上可见';

  @override
  String get trailHiddenRecording => '轨迹已隐藏（仍在记录）';

  @override
  String get duration => '持续时间';

  @override
  String get points => '点数';

  @override
  String get clearTrail => '清除轨迹';

  @override
  String get clearTrailQuestion => '清除轨迹？';

  @override
  String get clearTrailConfirmation => '您确定要清除当前的位置轨迹吗？此操作无法撤销。';

  @override
  String get noTrailRecorded => '尚未记录轨迹';

  @override
  String get startTrackingToRecord => '开始位置跟踪以记录您的轨迹';

  @override
  String get trailControls => '轨迹控制';

  @override
  String get exportTrailToGpx => '导出轨迹到 GPX';

  @override
  String get importTrailFromGpx => '从 GPX 导入轨迹';

  @override
  String get trailExportedSuccessfully => '轨迹导出成功！';

  @override
  String get failedToExportTrail => '导出轨迹失败';

  @override
  String failedToImportTrail(String error) {
    return '导入轨迹失败：$error';
  }

  @override
  String get importTrail => '导入轨迹';

  @override
  String importTrailQuestion(int pointCount) {
    return '导入包含 $pointCount 个点的轨迹吗？\n\n您可以替换当前轨迹，或将其与现有轨迹并排查看。';
  }

  @override
  String get viewAlongside => '并排查看';

  @override
  String get replaceCurrent => '替换当前';

  @override
  String trailImported(int pointCount) {
    return '轨迹已导入！（$pointCount 个点）';
  }

  @override
  String trailReplaced(int pointCount) {
    return '轨迹已替换！（$pointCount 个点）';
  }

  @override
  String get contactTrails => '联系人轨迹';

  @override
  String get showAllContactTrails => '显示所有联系人轨迹';

  @override
  String get noContactsWithLocationHistory => '没有带位置历史的联系人';

  @override
  String showingTrailsForContacts(int count) {
    return '正在显示 $count 个联系人的轨迹';
  }

  @override
  String get individualContactTrails => '单个联系人轨迹';

  @override
  String get deviceInformation => '设备信息';

  @override
  String get bleName => 'BLE 名称';

  @override
  String get meshName => 'Mesh 名称';

  @override
  String get notSet => '未设置';

  @override
  String get model => '型号';

  @override
  String get version => '版本';

  @override
  String get buildDate => '构建日期';

  @override
  String get firmware => '固件';

  @override
  String get maxContacts => '最大联系人数量';

  @override
  String get maxChannels => '最大频道数量';

  @override
  String get publicInfo => '公共信息';

  @override
  String get meshNetworkName => 'Mesh 网络名称';

  @override
  String get nameBroadcastInMesh => '在 Mesh 广播中公布的名称';

  @override
  String get telemetryAndLocationSharing => '遥测与位置共享';

  @override
  String get lat => '纬度';

  @override
  String get lon => '经度';

  @override
  String get useCurrentLocation => '使用当前位置';

  @override
  String get noneUnknown => '无/未知';

  @override
  String get chatNode => '聊天节点';

  @override
  String get repeater => '转发节点';

  @override
  String get roomChannel => '房间/频道';

  @override
  String typeNumber(int number) {
    return '类型 $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label 已复制到剪贴板';
  }

  @override
  String failedToSave(String error) {
    return '保存失败：$error';
  }

  @override
  String failedToGetLocation(String error) {
    return '获取位置失败：$error';
  }

  @override
  String get sarTemplates => '搜救模板';

  @override
  String get manageSarTemplates => '管理光标目标模板';

  @override
  String get addTemplate => '添加模板';

  @override
  String get editTemplate => '编辑模板';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String get templateName => '模板名称';

  @override
  String get templateNameHint => '例如 找到的人员';

  @override
  String get templateEmoji => '表情符号';

  @override
  String get emojiRequired => '需要表情符号';

  @override
  String get nameRequired => '需要名称';

  @override
  String get templateDescription => '描述（可选）';

  @override
  String get templateDescriptionHint => '添加上下文信息...';

  @override
  String get templateColor => '颜色';

  @override
  String get previewFormat => '预览（搜救消息格式）';

  @override
  String get importFromClipboard => '导入';

  @override
  String get exportToClipboard => '导出';

  @override
  String deleteTemplateConfirmation(String name) {
    return '删除模板“$name”？';
  }

  @override
  String get templateAdded => '模板已添加';

  @override
  String get templateUpdated => '模板已更新';

  @override
  String get templateDeleted => '模板已删除';

  @override
  String templatesImported(int count) {
    return '已导入 $count 个模板';
  }

  @override
  String templatesExported(int count) {
    return '已导出 $count 个模板到剪贴板';
  }

  @override
  String get resetToDefaults => '恢复默认';

  @override
  String get resetToDefaultsConfirmation => '这将删除所有自定义模板并恢复 4 个默认模板。是否继续？';

  @override
  String get reset => '重置';

  @override
  String get resetComplete => '模板已重置为默认值';

  @override
  String get noTemplates => '没有可用的模板';

  @override
  String get tapAddToCreate => '点击 + 创建您的第一个模板';

  @override
  String get ok => '确定';

  @override
  String get permissionsSection => '权限';

  @override
  String get locationPermission => '位置权限';

  @override
  String get checking => '正在检查...';

  @override
  String get locationPermissionGrantedAlways => '已授予（始终）';

  @override
  String get locationPermissionGrantedWhileInUse => '已授予（使用期间）';

  @override
  String get locationPermissionDeniedTapToRequest => '已拒绝 - 点击请求';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings => '永久拒绝 - 打开设置';

  @override
  String get locationPermissionDialogContent =>
      '位置权限被永久拒绝。请在设备设置中启用它，以便使用 GPS 跟踪和位置共享功能。';

  @override
  String get openSettings => '打开设置';

  @override
  String get locationPermissionGranted => '位置权限已授予！';

  @override
  String get locationPermissionRequiredForGps => 'GPS 跟踪和位置共享需要位置权限。';

  @override
  String get locationPermissionAlreadyGranted => '位置权限已被授予。';

  @override
  String get sarNavyBlue => '搜救海军蓝';

  @override
  String get sarNavyBlueDescription => '专业/操作模式';

  @override
  String get selectRecipient => '选择收件人';

  @override
  String get broadcastToAllNearby => '广播给所有附近设备';

  @override
  String get searchRecipients => '搜索收件人...';

  @override
  String get noContactsFound => '未找到联系人';

  @override
  String get noRoomsFound => '未找到房间';

  @override
  String get noContactsOrRoomsAvailable => '没有可用的联系人或房间';

  @override
  String get noRecipientsAvailable => '没有可用的收件人';

  @override
  String get noChannelsFound => '未找到频道';

  @override
  String get messagesWillBeSentToPublicChannel => '消息将发送到公共频道';

  @override
  String get newMessage => '新消息';

  @override
  String get channel => '频道';

  @override
  String get samplePoliceLead => '警队负责人';

  @override
  String get sampleDroneOperator => '无人机操作员';

  @override
  String get sampleFirefighterAlpha => '消防员';

  @override
  String get sampleMedicCharlie => '医护人员';

  @override
  String get sampleCommandDelta => '指挥部';

  @override
  String get sampleFireEngine => '消防车';

  @override
  String get sampleAirSupport => '空中支援';

  @override
  String get sampleBaseCoordinator => '基地协调员';

  @override
  String get channelEmergency => '紧急';

  @override
  String get channelCoordination => '协调';

  @override
  String get channelUpdates => '更新';

  @override
  String get sampleTeamMember => '示例团队成员';

  @override
  String get sampleScout => '示例侦察员';

  @override
  String get sampleBase => '示例基地';

  @override
  String get sampleSearcher => '示例搜索员';

  @override
  String get sampleObjectBackpack => ' 发现的背包 - 蓝色';

  @override
  String get sampleObjectVehicle => ' 遗弃车辆 - 请核实车主';

  @override
  String get sampleObjectCamping => ' 发现的露营装备';

  @override
  String get sampleObjectTrailMarker => ' 在小径外发现的路标';

  @override
  String get sampleMsgAllTeamsCheckIn => '所有小队签到';

  @override
  String get sampleMsgWeatherUpdate => '天气更新：晴朗，气温 18°C';

  @override
  String get sampleMsgBaseCamp => '基地营已在集结区建立';

  @override
  String get sampleMsgTeamAlpha => '小队正在前往第 2 区';

  @override
  String get sampleMsgRadioCheck => '无线电检查 - 所有电台回应';

  @override
  String get sampleMsgWaterSupply => '3 号检查点有水源';

  @override
  String get sampleMsgTeamBravo => '小队报告：第 1 区已排查完毕';

  @override
  String get sampleMsgEtaRallyPoint => '预计到达集合点时间：15 分钟';

  @override
  String get sampleMsgSupplyDrop => '已确认 14:00 进行物资空投';

  @override
  String get sampleMsgDroneSurvey => '无人机勘察完成 - 无发现';

  @override
  String get sampleMsgTeamCharlie => '小队请求支援';

  @override
  String get sampleMsgRadioDiscipline => '所有单位：保持无线电纪律';

  @override
  String get sampleMsgUrgentMedical => '紧急：第 4 区需要医疗援助';

  @override
  String get sampleMsgAdultMale => ' 成年男性，意识清醒';

  @override
  String get sampleMsgFireSpotted => '发现火灾 - 坐标即将发送';

  @override
  String get sampleMsgSpreadingRapidly => ' 正在迅速蔓延！';

  @override
  String get sampleMsgPriorityHelicopter => '优先级：需要直升机支援';

  @override
  String get sampleMsgMedicalTeamEnRoute => '医疗队正在前往您的位置';

  @override
  String get sampleMsgEvacHelicopter => '救援直升机预计 10 分钟后到达';

  @override
  String get sampleMsgEmergencyResolved => '紧急情况已解决 - 解除警报';

  @override
  String get sampleMsgEmergencyStagingArea => ' 紧急集结区';

  @override
  String get sampleMsgEmergencyServices => '紧急服务部门已接到通知并正在响应';

  @override
  String get sampleAlphaTeamLead => '小队队长';

  @override
  String get sampleBravoScout => '侦察员';

  @override
  String get sampleCharlieMedic => '医护人员';

  @override
  String get sampleDeltaNavigator => '导航员';

  @override
  String get sampleEchoSupport => '支援';

  @override
  String get sampleBaseCommand => '基地指挥部';

  @override
  String get sampleFieldCoordinator => '现场协调员';

  @override
  String get sampleMedicalTeam => '医疗队';

  @override
  String get mapDrawing => '地图绘制';

  @override
  String get navigateToDrawing => '导航到绘图';

  @override
  String get copyCoordinates => '复制坐标';

  @override
  String get hideFromMap => '在地图上隐藏';

  @override
  String get lineDrawing => '线条绘图';

  @override
  String get rectangleDrawing => '矩形绘图';

  @override
  String get coordinatesCopiedToClipboard => '坐标已复制到剪贴板';

  @override
  String get manualCoordinates => '手动输入坐标';

  @override
  String get enterCoordinatesManually => '手动输入坐标';

  @override
  String get latitudeLabel => '纬度';

  @override
  String get longitudeLabel => '经度';

  @override
  String get invalidLatitude => '无效的纬度（-90 到 90）';

  @override
  String get invalidLongitude => '无效的经度（-180 到 180）';

  @override
  String get exampleCoordinates => '例如：46.0569, 14.5058';

  @override
  String get drawingShared => '地图绘制';

  @override
  String get drawingHidden => '绘图已从地图上隐藏';

  @override
  String alreadyShared(int count) {
    return '$count 个已共享';
  }

  @override
  String newDrawingsShared(int count, String plural) {
    return '已共享 $count 个新绘图';
  }

  @override
  String get shareDrawing => '共享绘图';

  @override
  String get shareWithAllNearbyDevices => '与所有附近设备共享';

  @override
  String get shareToRoom => '共享到房间';

  @override
  String get sendToPersistentStorage => '发送到持久房间存储';

  @override
  String get deleteDrawingConfirm => '您确定要删除此绘图吗？';

  @override
  String get drawingDeleted => '绘图已删除';

  @override
  String yourDrawingsCount(int count) {
    return '您的绘图 ($count)';
  }

  @override
  String get shared => '已共享';

  @override
  String get line => '线条';

  @override
  String get rectangle => '矩形';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get currentVersion => '当前版本';

  @override
  String get latestVersion => '最新版本';

  @override
  String get downloadUpdate => '下载';

  @override
  String get updateLater => '稍后';

  @override
  String get cadastralParcels => '地籍地块';

  @override
  String get forestRoads => '森林道路';

  @override
  String get showCadastralParcels => '显示地籍地块';

  @override
  String get showForestRoads => '显示森林道路';

  @override
  String get wmsOverlays => 'WMS 覆盖层';

  @override
  String get hikingTrails => '徒步小径';

  @override
  String get mainRoads => '主要道路';

  @override
  String get houseNumbers => '门牌号';

  @override
  String get fireHazardZones => '火灾危险区';

  @override
  String get historicalFires => '历史火灾';

  @override
  String get firebreaks => '防火隔离带';

  @override
  String get krasFireZones => '喀斯特火灾区';

  @override
  String get placeNames => '地名';

  @override
  String get municipalityBorders => '市镇边界';

  @override
  String get topographicMap => '地形图 1:25000';

  @override
  String get recentMessages => '最近消息';

  @override
  String get addChannel => '添加频道';

  @override
  String get channelName => '频道名称';

  @override
  String get channelNameHint => '例如 救援队阿尔法';

  @override
  String get channelSecret => '频道密钥';

  @override
  String get channelSecretHint => '此频道的共享密码';

  @override
  String get channelSecretHelp => '此密钥必须与需要访问此频道的所有团队成员共享';

  @override
  String get channelTypesInfo =>
      '哈希频道 (#团队)：密钥根据名称自动生成。名称相同 = 跨设备频道相同。\n\n私有频道：使用显式密钥。只有拥有密钥的人才能加入。';

  @override
  String get hashChannelInfo => '哈希频道：密钥将根据频道名称自动生成。任何使用相同名称的人将加入同一个频道。';

  @override
  String get channelNameRequired => '需要频道名称';

  @override
  String get channelNameTooLong => '频道名称必须为 31 个字符或更少';

  @override
  String get channelSecretRequired => '需要频道密钥';

  @override
  String get channelSecretTooLong => '频道密钥必须为 32 个字符或更少';

  @override
  String get invalidAsciiCharacters => '只允许 ASCII 字符';

  @override
  String get channelCreatedSuccessfully => '频道创建成功';

  @override
  String channelCreationFailed(String error) {
    return '创建频道失败：$error';
  }

  @override
  String get deleteChannel => '删除频道';

  @override
  String deleteChannelConfirmation(String channelName) {
    return '您确定要删除频道“$channelName”吗？此操作无法撤销。';
  }

  @override
  String get channelDeletedSuccessfully => '频道删除成功';

  @override
  String channelDeletionFailed(String error) {
    return '删除频道失败：$error';
  }

  @override
  String get allChannelSlotsInUse => '所有频道槽位都已在使用中（最多 39 个自定义频道）';

  @override
  String get createChannel => '创建频道';

  @override
  String get wizardBack => '返回';

  @override
  String get wizardSkip => '跳过';

  @override
  String get wizardNext => '下一步';

  @override
  String get wizardGetStarted => '开始使用';

  @override
  String get wizardWelcomeTitle => '欢迎使用 MeshCore 搜救助手';

  @override
  String get wizardWelcomeDescription =>
      '一个功能强大的离网通信工具，用于搜索和救援行动。当传统网络不可用时，使用 Mesh 无线电技术与您的团队保持联系。';

  @override
  String get wizardConnectingTitle => '连接到您的无线电';

  @override
  String get wizardConnectingDescription =>
      '通过蓝牙将您的智能手机连接到 MeshCore 无线电设备，开始离网通信。';

  @override
  String get wizardConnectingFeature1 => '扫描附近的 MeshCore 设备';

  @override
  String get wizardConnectingFeature2 => '通过蓝牙与您的无线电配对';

  @override
  String get wizardConnectingFeature3 => '完全离线工作 - 无需互联网';

  @override
  String get wizardSimpleModeTitle => '简洁模式';

  @override
  String get wizardSimpleModeDescription =>
      '刚接触 Mesh 网络？启用简洁模式以获得仅包含基本功能的简化界面。';

  @override
  String get wizardSimpleModeFeature1 => '对初学者友好的界面，包含核心功能';

  @override
  String get wizardSimpleModeFeature2 => '随时在设置中切换到高级模式';

  @override
  String get wizardChannelTitle => '频道';

  @override
  String get wizardChannelDescription => '向频道上的所有人广播消息，非常适合全队通告和协调。';

  @override
  String get wizardChannelFeature1 => '用于一般团队通信的公共频道';

  @override
  String get wizardChannelFeature2 => '为特定小组创建自定义频道';

  @override
  String get wizardChannelFeature3 => '消息由 Mesh 网络自动转发';

  @override
  String get wizardContactsTitle => '联系人';

  @override
  String get wizardContactsDescription =>
      '您的团队成员在加入 Mesh 网络时会自动出现。向他们发送直连消息或查看他们的位置。';

  @override
  String get wizardContactsFeature1 => '联系人自动发现';

  @override
  String get wizardContactsFeature2 => '发送私密的直连消息';

  @override
  String get wizardContactsFeature3 => '查看电池电量和最后在线时间';

  @override
  String get wizardMapTitle => '地图与位置';

  @override
  String get wizardMapDescription => '实时跟踪您的团队，并为搜救行动标记重要位置。';

  @override
  String get wizardMapFeature1 => '用于标记找到的人员、火灾和集结区的搜救标记';

  @override
  String get wizardMapFeature2 => '团队成员的实时 GPS 跟踪';

  @override
  String get wizardMapFeature3 => '为偏远地区下载离线地图';

  @override
  String get wizardMapFeature4 => '绘制形状并共享战术信息';

  @override
  String get viewWelcomeTutorial => '查看欢迎教程';

  @override
  String get allTeamContacts => '所有团队联系人';

  @override
  String directMessagesInfo(int count) {
    return '带有确认消息的直连消息。发送给 $count 名团队成员。';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return '搜救标记已发送给 $count 个联系人';
  }

  @override
  String get noContactsAvailable => '没有可用的团队联系人';

  @override
  String get reply => '回复';

  @override
  String get technicalDetails => '技术细节';

  @override
  String get messageTechnicalDetails => '消息技术细节';

  @override
  String get linkQuality => '链路质量';

  @override
  String get delivery => '投递';

  @override
  String get status => '状态';

  @override
  String get expectedAckTag => '预期的 ACK 标签';

  @override
  String get roundTrip => '往返时间';

  @override
  String get retryAttempt => '重试尝试';

  @override
  String get floodFallback => '泛洪回退';

  @override
  String get identity => '身份';

  @override
  String get messageId => '消息 ID';

  @override
  String get sender => '发送者';

  @override
  String get senderKey => '发送者密钥';

  @override
  String get recipient => '接收者';

  @override
  String get recipientKey => '接收者密钥';

  @override
  String get voice => '语音';

  @override
  String get voiceId => '语音 ID';

  @override
  String get envelope => '信封';

  @override
  String get sessionProgress => '会话进度';

  @override
  String get complete => '完成';

  @override
  String get rawDump => '原始数据';

  @override
  String get cannotRetryMissingRecipient => '无法重试：缺少接收者信息';

  @override
  String get voiceUnavailable => '当前语音不可用';

  @override
  String get requestingVoice => '正在请求语音';
}
