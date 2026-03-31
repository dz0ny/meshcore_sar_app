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
  String failedToAdvertise(String error) {
    return '广播失败: $error';
  }

  @override
  String get cancelReconnection => '取消重新连接';

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
  String get disableMap => '禁用地图';

  @override
  String get disableMapDescription => '隐藏地图标签页以减少电池消耗';

  @override
  String get language => '语言';

  @override
  String get chooseLanguage => '选择语言';

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
  String get publicChannel => '公共频道';

  @override
  String get broadcastToAll => '广播给所有附近节点（临时）';

  @override
  String get storedPermanently => '永久存储在房间中';

  @override
  String get notConnectedToDevice => '未连接到设备';

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
  String get autoSend => 'Auto Send';

  @override
  String get autoSendDescription => 'Send via current path.';

  @override
  String get sendDirect => 'Send Direct';

  @override
  String get sendDirectDescription => 'Send directly to this contact.';

  @override
  String get sendFlood => 'Send Flood';

  @override
  String get sendFloodDescription => 'Send via all repeaters.';

  @override
  String get loggedIn => '已登录';

  @override
  String get noGpsData => '无 GPS 数据';

  @override
  String get distance => '距离';

  @override
  String directPingTimeout(String name) {
    return '直连 Ping 超时 - 正在使用泛洪重试 $name...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping $name 失败 - 未收到响应';
  }

  @override
  String deleteContactConfirmation(String name) {
    return '您确定要删除“$name”吗？\n\n这将从应用程序和配套的无线电设备中移除该联系人。';
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
  String get selectMapLayer => '选择地图图层';

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
  String get textCopiedToClipboard => '文本已复制到剪贴板';

  @override
  String get cannotReplySenderMissing => '无法回复：缺少发送者信息';

  @override
  String get cannotReplyContactNotFound => '无法回复：未找到联系人';

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
  String exportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get unknown => '未知';

  @override
  String get onlineLayers => '在线图层';

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
  String get noRecipientsAvailable => '没有可用的收件人';

  @override
  String get noChannelsFound => '未找到频道';

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
  String get manualCoordinates => '手动输入坐标';

  @override
  String get enterCoordinatesManually => '手动输入坐标';

  @override
  String get latitudeLabel => '纬度';

  @override
  String get longitudeLabel => '经度';

  @override
  String get exampleCoordinates => '例如：46.0569, 14.5058';

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

  @override
  String get device => '设备';

  @override
  String get change => '更改';

  @override
  String get wizardOverviewDescription =>
      '此应用将 MeshCore 消息、SAR 现场更新、地图功能和设备工具整合到同一处。';

  @override
  String get wizardOverviewFeature1 => '在主消息标签页中发送私聊消息、房间消息和频道消息。';

  @override
  String get wizardOverviewFeature2 => '通过 mesh 网络共享 SAR 标记、地图绘图、语音片段和图像。';

  @override
  String get wizardOverviewFeature3 => '通过 BLE 或 TCP 连接，然后直接在应用中管理配套电台。';

  @override
  String get wizardMessagingTitle => '消息与现场报告';

  @override
  String get wizardMessagingDescription => '这里的消息不只是纯文本。应用已经支持多种操作载荷和传输流程。';

  @override
  String get wizardMessagingFeature1 => '通过一个编辑器发送私聊消息、房间消息和频道流量。';

  @override
  String get wizardMessagingFeature2 => '为常见现场报告创建 SAR 更新和可复用的 SAR 模板。';

  @override
  String get wizardMessagingFeature3 => '传输语音会话和图像，并在界面中显示进度和空口时间估算。';

  @override
  String get wizardConnectDeviceTitle => '连接设备';

  @override
  String get wizardConnectDeviceDescription =>
      '连接你的 MeshCore 电台，选择名称，并在继续前应用无线电预设。';

  @override
  String get wizardSetupBadge => '设置';

  @override
  String get wizardOverviewBadge => '概览';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return '已连接到 $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => '尚未连接设备';

  @override
  String get wizardSkipForNow => '暂时跳过';

  @override
  String get wizardDeviceNameLabel => '设备名称';

  @override
  String get wizardDeviceNameHelp => '此名称会广播给其他 MeshCore 用户。';

  @override
  String get wizardConfigRegionLabel => '配置区域';

  @override
  String get wizardConfigRegionHelp =>
      '使用完整的官方 MeshCore 预设列表。默认值为 EU/UK (Narrow)。';

  @override
  String get wizardPresetNote1 => '请确认所选预设符合你所在地区的无线电规定。';

  @override
  String get wizardPresetNote2 => '该列表与 MeshCore 配置工具的官方预设源保持一致。';

  @override
  String get wizardPresetNote3 => '在引导设置中默认保持选中 EU/UK (Narrow)。';

  @override
  String get wizardSaving => '正在保存...';

  @override
  String get wizardSaveAndContinue => '保存并继续';

  @override
  String get wizardEnterDeviceName => '继续前请输入设备名称。';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return '已保存 $deviceName，配置为 $presetName。';
  }

  @override
  String get wizardNetworkTitle => '联系人、房间和中继器';

  @override
  String get wizardNetworkDescription => '联系人标签页会整理你发现的网络以及随着时间学习到的路由。';

  @override
  String get wizardNetworkFeature1 => '在一个列表中查看团队成员、中继器、房间、频道和待处理广播。';

  @override
  String get wizardNetworkFeature2 => '当连接变得混乱时，使用智能 ping、房间登录、已学习路径和路由重置工具。';

  @override
  String get wizardNetworkFeature3 => '无需离开应用即可创建频道并管理网络目的地。';

  @override
  String get wizardMapOpsTitle => '地图、轨迹与共享几何';

  @override
  String get wizardMapOpsDescription => '应用地图直接与消息、跟踪和 SAR 叠加层关联，而不是单独的查看器。';

  @override
  String get wizardMapOpsFeature1 => '在地图上跟踪你自己的位置、队友位置和移动轨迹。';

  @override
  String get wizardMapOpsFeature2 => '打开消息中的绘图，内联预览，并在需要时将其从地图上移除。';

  @override
  String get wizardMapOpsFeature3 => '使用中继器地图视图和共享叠加层来了解现场网络覆盖范围。';

  @override
  String get wizardToolsTitle => '消息之外的工具';

  @override
  String get wizardToolsDescription => '这里不只有四个主标签页。应用还包含配置、诊断和可选的传感器工作流。';

  @override
  String get wizardToolsFeature1 => '打开设备配置以更改无线电设置、遥测、TX 功率和配套设备详情。';

  @override
  String get wizardToolsFeature2 => '当你需要受监控的传感器面板和快速刷新操作时，启用传感器标签页。';

  @override
  String get wizardToolsFeature3 => '在排查 mesh 网络问题时使用数据包日志、频谱扫描和开发者诊断。';

  @override
  String get postConnectDiscoveryTitle => 'Discover repeaters now?';

  @override
  String get postConnectDiscoveryDescription =>
      'Run repeater discovery right after connecting so you can see nearby MeshCore nodes and add them to your network faster.';

  @override
  String get contactInSensors => '在传感器中';

  @override
  String get contactAddToSensors => '添加到传感器';

  @override
  String get contactSetPath => '设置路径';

  @override
  String contactAddedToSensors(String contactName) {
    return '已将 $contactName 添加到传感器';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return '清除路由失败：$error';
  }

  @override
  String get contactRouteCleared => '路由已清除';

  @override
  String contactRouteSet(String route) {
    return '路由已设置：$route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return '设置路由失败：$error';
  }

  @override
  String get rssi => 'RSSI';

  @override
  String get snr => 'SNR';

  @override
  String get ackTimeout => 'ACK 超时';

  @override
  String get opcode => '操作码';

  @override
  String get payload => '有效载荷';

  @override
  String get hops => '跳数';

  @override
  String get hashSize => '哈希大小';

  @override
  String get pathBytes => '路径字节';

  @override
  String get selectedPath => '选定路径';

  @override
  String get estimatedTx => '预计传输';

  @override
  String get senderToReceipt => '发送到接收';

  @override
  String get receivedCopies => '收到的副本';

  @override
  String get retryCause => '重试原因';

  @override
  String get retryMode => '重试模式';

  @override
  String get retryResult => '重试结果';

  @override
  String get lastRetry => '最后重试';

  @override
  String get rxPackets => 'RX 数据包';

  @override
  String get mesh => 'Mesh';

  @override
  String get rate => '速率';

  @override
  String get window => '窗口';

  @override
  String get posttxDelay => '发送后延迟';

  @override
  String get bandpass => '带通';

  @override
  String get bandpassFilterVoice => '带通语音滤波';

  @override
  String get frequency => '频率';

  @override
  String get australia => '澳大利亚';

  @override
  String get australiaNarrow => '澳大利亚（窄带）';

  @override
  String get australiaQld => '澳大利亚：QLD';

  @override
  String get australiaSaWa => '澳大利亚：SA, WA';

  @override
  String get newZealand => '新西兰';

  @override
  String get newZealandNarrow => '新西兰（窄带）';

  @override
  String get switzerland => '瑞士';

  @override
  String get portugal433 => '葡萄牙 433';

  @override
  String get portugal868 => '葡萄牙 868';

  @override
  String get czechRepublicNarrow => '捷克（窄带）';

  @override
  String get eu433mhzLongRange => '欧盟 433MHz（远距离）';

  @override
  String get euukDeprecated => '欧盟/英国（已弃用）';

  @override
  String get euukNarrow => '欧盟/英国（窄带）';

  @override
  String get usacanadaRecommended => '美国/加拿大（推荐）';

  @override
  String get vietnamDeprecated => '越南（已弃用）';

  @override
  String get vietnamNarrow => '越南（窄带）';

  @override
  String get active => '活动';

  @override
  String get addContact => '添加联系人';

  @override
  String get all => '全部';

  @override
  String get autoResolve => '自动解析';

  @override
  String get clearAllLabel => '清除全部';

  @override
  String get clearRelays => '清除中继';

  @override
  String get clearFilters => '清除过滤器';

  @override
  String get clearRoute => '清除路由';

  @override
  String get clearMessages => '清除消息';

  @override
  String get clearScale => '清除比例';

  @override
  String get clearDiscoveries => '清除发现';

  @override
  String get clearOnlineTraceDatabase => '清除在线追踪数据库';

  @override
  String get clearAllChannels => '清除所有频道';

  @override
  String get clearAllContacts => '清除所有联系人';

  @override
  String get clearChannels => '清除频道';

  @override
  String get clearContacts => '清除联系人';

  @override
  String get clearPathOnMaxRetry => '最大重试时清除路径';

  @override
  String get create => '创建';

  @override
  String get custom => '自定义';

  @override
  String get defaultValue => '默认';

  @override
  String get duplicate => '复制';

  @override
  String get editName => '编辑名称';

  @override
  String get open => '打开';

  @override
  String get paste => '粘贴';

  @override
  String get preview => '预览';

  @override
  String get remove => '移除';

  @override
  String get rename => '重命名';

  @override
  String get resolveAll => '解析全部';

  @override
  String get send => '发送';

  @override
  String get sendAnyway => '仍然发送';

  @override
  String get share => '分享';

  @override
  String get shareContact => '分享联系人';

  @override
  String get trace => '追踪';

  @override
  String get use => '使用';

  @override
  String get useSelectedFrequency => '使用选定频率';

  @override
  String get discovery => '发现';

  @override
  String get discoverRepeaters => '发现中继器';

  @override
  String get discoverSensors => '发现传感器';

  @override
  String get repeaterDiscoverySent => '中继器发现已发送';

  @override
  String get sensorDiscoverySent => '传感器发现已发送';

  @override
  String get clearedPendingDiscoveries => '已清除待处理的发现。';

  @override
  String get autoDiscovery => '自动发现';

  @override
  String get enableAutomaticAdding => '启用自动添加';

  @override
  String get autoaddRepeaters => '自动添加中继器';

  @override
  String get autoaddRoomServers => '自动添加房间服务器';

  @override
  String get autoaddSensors => '自动添加传感器';

  @override
  String get autoaddUsers => '自动添加用户';

  @override
  String get overwriteOldestWhenFull => '满时覆盖最旧的';

  @override
  String get storage => '存储';

  @override
  String get dangerZone => '危险区域';

  @override
  String get profiles => '配置文件';

  @override
  String get favourites => '收藏夹';

  @override
  String get sensors => '传感器';

  @override
  String get others => '其他';

  @override
  String get gpsModule => 'GPS 模块';

  @override
  String get liveTraffic => '实时流量';

  @override
  String get repeatersMap => '中继器地图';

  @override
  String get spectrumScan => '频谱扫描';

  @override
  String get blePacketLogs => 'BLE 数据包日志';

  @override
  String get onlineTraceDatabase => '在线追踪数据库';

  @override
  String get routePathByteSize => '路由路径字节大小';

  @override
  String get messageNotifications => '消息通知';

  @override
  String get sarAlerts => 'SAR 警报';

  @override
  String get discoveryNotifications => '发现通知';

  @override
  String get updateNotifications => '更新通知';

  @override
  String get muteWhileAppIsOpen => '应用打开时静音';

  @override
  String get disableContacts => '禁用联系人';

  @override
  String get enableSensorsTab => '启用传感器标签';

  @override
  String get enableProfiles => '启用配置文件';

  @override
  String get autoRouteRotation => '自动路由轮换';

  @override
  String get nearestRepeaterFallback => '最近中继器回退';

  @override
  String get deleteAllStoredMessageHistory => '删除所有存储的消息历史';

  @override
  String get messageFontSize => '消息字体大小';

  @override
  String get rotateMapWithHeading => '随航向旋转地图';

  @override
  String get showMapDebugInfo => '显示地图调试信息';

  @override
  String get openMapInFullscreen => '全屏打开地图';

  @override
  String get showSarMarkersLabel => '显示 SAR 标记';

  @override
  String get displaySarMarkersOnTheMainMap => '在主地图上显示 SAR 标记';

  @override
  String get showAllContactTrailsLabel => '显示所有联系人轨迹';

  @override
  String get hideRepeatersOnMap => '在地图上隐藏中继器';

  @override
  String get setMapScale => '设置地图比例';

  @override
  String get customMapScaleSaved => '自定义地图比例已保存';

  @override
  String get voiceBitrate => '语音比特率';

  @override
  String get voiceCompressor => '语音压缩器';

  @override
  String get balancesQuietAndLoudSpeechLevels => '平衡安静和响亮的语音级别';

  @override
  String get voiceLimiter => '语音限制器';

  @override
  String get preventsClippingPeaksBeforeEncoding => '防止编码前的削波';

  @override
  String get micAutoGain => '麦克风自动增益';

  @override
  String get letsTheRecorderAdjustInputLevel => '让录音器调整输入级别';

  @override
  String get echoCancellation => '回声消除';

  @override
  String get noiseSuppression => '噪音抑制';

  @override
  String get trimSilenceInVoiceMessages => '修剪语音消息中的静音';

  @override
  String get compressor => '压缩器';

  @override
  String get limiter => '限制器';

  @override
  String get autoGain => '自动增益';

  @override
  String get echoCancel => '回声';

  @override
  String get noiseSuppress => '噪声';

  @override
  String get silenceTrim => '静音';

  @override
  String get maxImageSize => '最大图片大小';

  @override
  String get imageCompression => '图片压缩';

  @override
  String get grayscale => '灰度';

  @override
  String get ultraMode => '超级模式';

  @override
  String get fastPrivateGpsUpdates => '快速私有 GPS 更新';

  @override
  String get movementThreshold => '移动阈值';

  @override
  String get fastGpsMovementThreshold => '快速 GPS 移动阈值';

  @override
  String get fastGpsActiveuseInterval => '快速 GPS 活动使用间隔';

  @override
  String get activeuseUpdateInterval => '活动使用更新间隔';

  @override
  String get repeatNearbyTraffic => '转发附近流量';

  @override
  String get relayThroughRepeatersAcrossTheMesh => '通过网格中的中继器转发';

  @override
  String get nearbyOnlyWithoutRepeaterFlooding => '仅附近，无中继器泛洪';

  @override
  String get multihop => '多跳';

  @override
  String get createProfile => '创建配置文件';

  @override
  String get renameProfile => '重命名配置文件';

  @override
  String get newProfile => '新配置文件';

  @override
  String get manageProfiles => '管理配置文件';

  @override
  String get enableProfilesToStartManagingThem => '启用配置文件以开始管理它们。';

  @override
  String get openMessage => '打开消息';

  @override
  String get jumpToTheRelatedSarMessage => '跳转到相关的 SAR 消息';

  @override
  String get removeSarMarker => '移除 SAR 标记';

  @override
  String get pleaseSelectADestinationToSendSarMarker => '请选择目标以发送 SAR 标记';

  @override
  String get sarMarkerBroadcastToPublicChannel => 'SAR 标记已广播到公共频道';

  @override
  String get sarMarkerSentToRoom => 'SAR 标记已发送到房间';

  @override
  String get loadFromGallery => '从图库加载';

  @override
  String get replaceImage => '替换图片';

  @override
  String get selectFromGallery => '从图库选择';

  @override
  String get team => '团队';

  @override
  String get found => '已找到';

  @override
  String get staging => '集结区';

  @override
  String get object => '物体';

  @override
  String get quiet => '安静';

  @override
  String get moderate => '中等';

  @override
  String get busy => '繁忙';

  @override
  String get spectrumScanReturnedNoCandidateFrequencies => '频谱扫描未找到候选频率';

  @override
  String get searchMessages => '搜索消息';

  @override
  String get sendImageFromGallery => '从图库发送图片';

  @override
  String get takePhoto => '拍照';

  @override
  String get dmOnly => '仅私信';

  @override
  String get allMessages => '所有消息';

  @override
  String get sendToPublicChannel => '发送到公共频道？';

  @override
  String get selectMarkerTypeAndDestination => '选择标记类型和目标';

  @override
  String get noDestinationsAvailableLabel => '没有可用的目标';

  @override
  String get image => '图片';

  @override
  String get format => '格式';

  @override
  String get dimensions => '尺寸';

  @override
  String get segments => '分段';

  @override
  String get transfers => '传输';

  @override
  String get downloadedBy => '已下载';

  @override
  String get saveDiscoverySettings => '保存发现设置';

  @override
  String get savePublicInfo => '保存公共信息';

  @override
  String get saveRadioSettings => '保存无线电设置';

  @override
  String get savePath => '保存路径';

  @override
  String get wipeDeviceData => '擦除设备数据';

  @override
  String get wipeDevice => '擦除设备';

  @override
  String get destructiveDeviceActions => '破坏性设备操作。';

  @override
  String get chooseAPresetOrFinetuneCustomRadioSettings => '选择预设或微调自定义无线电设置。';

  @override
  String get chooseTheNameAndLocationThisDeviceShares => '选择此设备共享的名称和位置。';

  @override
  String get availableSpaceOnThisDevice => '此设备上的可用空间。';

  @override
  String get used => '已使用';

  @override
  String get total => '总计';

  @override
  String get renameValue => '重命名值';

  @override
  String get customizeFields => '自定义字段';

  @override
  String get livePreview => '实时预览';

  @override
  String get refreshSchedule => '刷新计划';

  @override
  String get noResponse => '无响应';

  @override
  String get refreshing => '刷新中';

  @override
  String get unavailable => '不可用';

  @override
  String get pickARelayOrNodeToWatchInSensors => '选择要在传感器中监视的中继或节点。';

  @override
  String get publicKeyLabel => '公钥';

  @override
  String get alreadyInContacts => '已在联系人中';

  @override
  String get connectToADeviceBeforeAddingContacts => '添加联系人前请连接到设备';

  @override
  String get fromContacts => '来自联系人';

  @override
  String get onlineOnly => '仅在线';

  @override
  String get inBoth => '两者中';

  @override
  String get source => '来源';

  @override
  String get manualRouteEdit => '手动路由编辑';

  @override
  String get observedMeshRoute => '观察到的网格路由';

  @override
  String get allMessagesCleared => '所有消息已清除';

  @override
  String get onlineTraceDatabaseCleared => '在线追踪数据库已清除';

  @override
  String get packetLogsCleared => '数据包日志已清除';

  @override
  String get hexDataCopiedToClipboard => '十六进制数据已复制到剪贴板';

  @override
  String get developerModeEnabled => '开发者模式已启用';

  @override
  String get developerModeDisabled => '开发者模式已禁用';

  @override
  String get clipboardIsEmpty => '剪贴板为空';

  @override
  String get contactImported => '联系人已导入';

  @override
  String get contactLinkCopiedToClipboard => '联系人链接已复制到剪贴板';

  @override
  String get failedToExportContact => '导出联系人失败';

  @override
  String get noLogsToExport => '没有日志可导出';

  @override
  String get exportAsCsv => '导出为 CSV';

  @override
  String get exportAsText => '导出为文本';

  @override
  String get receivedRfc3339 => '收到 (RFC3339)';

  @override
  String get buildTime => '构建时间';

  @override
  String get downloadUrlNotAvailable => '下载链接不可用';

  @override
  String get cannotOpenDownloadUrl => '无法打开下载链接';

  @override
  String get updateCheckIsOnlyAvailableOnAndroid => '更新检查仅在 Android 上可用';

  @override
  String get youAreRunningTheLatestVersion => '您正在使用最新版本';

  @override
  String get updateAvailableButDownloadUrlNotFound => '有更新可用但未找到下载链接';

  @override
  String get startTictactoe => '开始井字棋';

  @override
  String get tictactoeUnavailable => '井字棋不可用';

  @override
  String get tictactoeOpponentUnknown => '井字棋：对手未知';

  @override
  String get tictactoeWaitingForStart => '井字棋：等待开始';

  @override
  String get acceptsShareLinks => '接受分享链接';

  @override
  String get supportsRawHex => '支持原始十六进制';

  @override
  String get clipboardfriendly => '剪贴板友好';

  @override
  String get captured => '已捕获';

  @override
  String get size => '大小';

  @override
  String get noCustomChannelsToClear => '没有自定义频道可清除。';

  @override
  String get noDeviceContactsToClear => '没有设备联系人可清除。';

  @override
  String get setRegionScope => 'Set region scope';

  @override
  String get regionScope => 'Region scope';

  @override
  String get regionScopeNone => 'None (global)';

  @override
  String get clearRegionScope => 'Clear scope';

  @override
  String get regionScopeWarning =>
      'Only repeaters allowing this region will forward.';

  @override
  String get discoverRegions => 'Discover from repeaters';

  @override
  String get discoveringRegions => 'Discovering regions...';

  @override
  String get enterRegionName => 'Region name (e.g. auckland)';

  @override
  String get noRegionsFound => 'No regions found on this repeater.';

  @override
  String regionScopeSet(String name) {
    return 'Region scope set to $name';
  }

  @override
  String get regionScopeCleared => 'Region scope cleared';
}
