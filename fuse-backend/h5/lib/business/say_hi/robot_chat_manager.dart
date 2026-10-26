import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/widget/dialog/robot_chat_dialog.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/database/controller/video_call_contoller.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/pages/flash_chat/start_match/logic.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/broadcaster/reward_model.dart';
import 'package:video_player/video_player.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';

/// 机器人搭讪管理器
/// 负责在登录后按照指定时间间隔触发主播通话弹窗
class RobotChatManager extends GetxController {
  final _appConfig = Get.find<AppConfigManager>();
  final _request = Get.find<RequestRepository>();

  /// 第一个定时器：登录后10-20秒随机触发
  Timer? _firstChatTimer;
  
  /// 第二个定时器：登录后20-30秒随机触发
  Timer? _secondChatTimer;
  
  /// 周期性定时器：每30秒触发一次
  Timer? _periodicChatTimer;

  /// 是否已经初始化
  bool _isInitialized = false;

  /// 是否正在显示弹窗
  bool _isShowingDialog = false;

  /// 是否被VIP弹窗暂停（引用计数，防重入）
  int _vipPauseRefCount = 0;

  /// 随机数生成器
  final Random _random = Random();

  /// 本地主播搭讪数据。Release 默认只保留正式 ID；测试 ID 仅在 BROADCASTER_ENV=test 时从编译参数进入。
  List<Map<String, dynamic>> get _broadcasterData {
    const formal = <Map<String, dynamic>>[
      {"id": "1961011549309108224", "name": "主播1", "avatar": ""},
      {"id": "1961011441205116928", "name": "主播2", "avatar": ""},
      {"id": "1961011258434125824", "name": "主播3", "avatar": ""},
      {"id": "1961011140259610624", "name": "主播4", "avatar": ""},
      {"id": "1961010995912638464", "name": "主播5", "avatar": ""},
    ];
    const env = String.fromEnvironment('BROADCASTER_ENV', defaultValue: 'prod');
    const csv = String.fromEnvironment('TEST_BROADCASTER_IDS_CSV');
    if (env == 'test' && csv.isNotEmpty) {
      return csv.split(',').where((id) => id.isNotEmpty).map((id) => {"id": id, "name": "主播", "avatar": ""}).toList();
    }
    return formal;
  }

  /// 当前主播索引（持久化）
  int _currentBroadcasterIndex = 0;

  /// 已拨打次数（持久化）
  int _callCount = 0;

  /// 是否已完成五次（持久化）
  bool _completed = false;

  /// 是否外部抑制（例如根据主播状态临时关闭）
  bool _externallySuppressed = false;

  /// App 前后台事件订阅
  StreamSubscription<AppLifecycleStateEvent>? _lifecycleSub;

  /// 登录状态事件订阅
  StreamSubscription<OtherEvent>? _loginEventSub;

  /// 充值成功事件订阅
  StreamSubscription<RechargeSuccessEvent>? _rechargeSuccessSub;

  /// 预加载的用户信息与媒体缓存
  final Map<String, UserInfoModel> _userInfoCache = {};
  final Map<String, String> _thumbCache = {}; // userId -> thumbUrl
  final Map<String, String> _videoUrlCache = {}; // userId -> mediaUrl
  final Map<String, VideoPlayerController> _videoControllerCache = {}; // userId -> controller

  /// 用户信息拉取重试控制
  final Map<String, int> _userInfoRetryCount = {}; // userId -> attempts
  final Set<String> _userInfoRetrying = {}; // userId currently retrying

  /// 视频预加载重试控制
  final Map<String, int> _videoRetryCount = {}; // userId -> attempts
  final Set<String> _videoRetrying = {}; // userId currently retrying

  String get _uid => _appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
      ? _appConfig.userInfo.userId!.toString()
      : 'guest';

  String get _indexKey => 'robot_chat_index_$_uid';
  String get _countKey => 'robot_chat_count_$_uid';
  String get _completedKey => 'robot_chat_completed_$_uid';

  //是否生效 非审核用户 & 非付费用户
  bool get isEnabled => !(_appConfig.userInfo.isRecharge ?? false) && !(_appConfig.isReviewPkg.value);

  bool get _isLogin => BaseManager.instance.isLogin;

  @override
  void onInit() {
    super.onInit();
    logger.d('RobotChatManager initialized');

    // 前后台切换监听：与项目机制对齐（见 IndexLogic）
    _lifecycleSub = EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.paused) {
        logger.d('RobotChat onPaused -> stop timers');
        stopChatTimer();
      } else if (event.state == AppLifecycleState.resumed) {
        logger.d('RobotChat onResumed -> ensure timers');
        if (!_completed && isEnabled && _isLogin) {
          _isInitialized = true;
          if (_periodicChatTimer == null) {
            _startPeriodicTimer();
          }
        }
      }
    });

    // 登录状态监听：未登录 -> 停止；登录 -> 恢复
    _loginEventSub = EventBusUtil.listen<OtherEvent>((event) {
      if (event.type == OtherType.userInfoUpdate) {
        if (_isLogin) {
          logger.d('RobotChat login detected, ensure timers');
          // 付费用户：直接视为已完成五通并开闸
          if ((_appConfig.userInfo.isRecharge ?? false) && !_completed) {
            logger.d('RobotChat detected paid user on login update -> force complete');
            _forceCompleteDueToRecharge();
            return;
          }
          if (!_completed && isEnabled) {
            _isInitialized = true;
            if (_periodicChatTimer == null) {
              _startPeriodicTimer();
            }
          }
        } else {
          logger.d('RobotChat logout detected, stop timers');
          stopChatTimer();
        }
      }
    });

    // 充值成功事件监听：购买成功后自动关闭机器人通话弹窗
    _rechargeSuccessSub = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      logger.d('RobotChat: 收到充值成功事件，subscribePay=${event.subscribePay}');
      if (_isShowingDialog && RobotChatDialog.isShowing) {
        logger.d('RobotChat: 检测到充值成功，自动关闭机器人通话弹窗');
        // 通过dismiss的回调来确保正确的关闭流程
        RobotChatDialog.dismiss(onDismiss: () {
          // 充值后，直接标记五通完成并开闸
          _forceCompleteDueToRecharge();
        });
      } else {
        logger.d('RobotChat: 充值成功但弹窗未显示，_isShowingDialog=$_isShowingDialog, isShowing=${RobotChatDialog.isShowing}');
        // 无弹窗时也要直接标记五通完成并开闸
        _forceCompleteDueToRecharge();
      }
    });
  }

  @override
  void onClose() {
    stopChatTimer();
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
    _loginEventSub?.cancel();
    _loginEventSub = null;
    _rechargeSuccessSub?.cancel();
    _rechargeSuccessSub = null;
    _disposeAllControllers();
    super.onClose();
  }

  /// 对外：是否已完成本地五位主播展示（同步读取持久化，防漏）
  // Future<bool> isLocalFiveCompleted() async {
  //   try {
  //     await _loadProgress();
  //   } catch (_) {}
  //   return _completed || _callCount >= _broadcasterData.length;
  // }

  void _disposeAllControllers() {
    _videoControllerCache.forEach((key, controller) {
      try {
        // iOS环境下需要更彻底的清理
        if (controller.value.isPlaying) {
          controller.pause();
        }
        controller.seekTo(Duration.zero);
        controller.dispose();
        
        logger.d('视频控制器已释放: $key');
      } catch (e) {
        logger.e('清理视频控制器失败: $key, error: $e');
      }
    });
    _videoControllerCache.clear();
    
    // iOS特定清理
    _iosSpecificCleanup();
  }

  /// iOS环境下的额外清理
  void _iosSpecificCleanup() {
    try {
      // 清理图片缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      logger.d('iOS特定清理完成');
    } catch (e) {
      logger.e('iOS特定清理失败: $e');
    }
  }

  /// 设置外部抑制（true 则不弹出）
  void setExternalSuppressed(bool suppressed) {
    _externallySuppressed = suppressed;
    logger.d('RobotChat external suppressed set to: $suppressed');
  }

  /// VIP弹窗出现：暂停机器人计时与展示
  void onVipDialogShown() {
    try {
      _vipPauseRefCount++;
      _externallySuppressed = true;
      _periodicChatTimer?.cancel();
      _periodicChatTimer = null;
      logger.d('RobotChat paused due to VIP dialog. refCount=$_vipPauseRefCount');
    } catch (e) {
      logger.e('RobotChat pause for VIP failed: $e');
    }
  }

  /// VIP弹窗关闭：恢复机器人计时（若未完成且条件允许）
  void onVipDialogDismissed() {
    try {
      _vipPauseRefCount = (_vipPauseRefCount - 1).clamp(0, 1 << 20);
      logger.d('RobotChat resume check after VIP dialog dismissed. refCount=$_vipPauseRefCount');
      if (_vipPauseRefCount == 0) {
        _externallySuppressed = false;
        if (!_completed && isEnabled && _isLogin) {
          _startPeriodicTimer();
        }
      }
    } catch (e) {
      logger.e('RobotChat resume after VIP failed: $e');
    }
  }

  /// 启动周期性定时器：改为“滚动定时器”，每次随机15-30秒后触发一次
  void _startPeriodicTimer() {
    _periodicChatTimer?.cancel();
    _scheduleNextTick();
    logger.d('Periodic robot chat timer started (rolling 15-30s)');
  }

  /// 安排下一次触发，随机15-30秒
  void _scheduleNextTick() {
    final int delay = 15 + _random.nextInt(16); // 15-30秒
    logger.d('RobotChat next tick in ${delay}s');
    _periodicChatTimer = Timer(Duration(seconds: delay), () {
      _triggerRobotChat();
    });
  }

  /// 确保周期定时器存在（如被系统清理或为null则重建）
  void _ensurePeriodicTimer() {
    if (_periodicChatTimer == null && _isInitialized && !_completed) {
      logger.d('Periodic timer missing, recreating...');
      _startPeriodicTimer();
    }
  }

  /// 读取持久化进度
  Future<void> _loadProgress() async {
    try {
      await SPUtil.getInstance();
      _currentBroadcasterIndex = SPUtil.getInt(_indexKey, defaultValue: 0);
      _callCount = SPUtil.getInt(_countKey, defaultValue: 0);
      _completed = SPUtil.getBool(_completedKey, defaultValue: false);
      if (_currentBroadcasterIndex < 0 || _currentBroadcasterIndex >= _broadcasterData.length) {
        _currentBroadcasterIndex = 0;
      }
      if (_callCount < 0 || _callCount > _broadcasterData.length) {
        _callCount = 0;
      }
      logger.d('RobotChat progress loaded: index=$_currentBroadcasterIndex, count=$_callCount, completed=$_completed');
    } catch (e) {
      logger.e('RobotChat load progress error: $e');
    }
  }

  /// 保存持久化进度
  Future<void> _saveProgress() async {
    try {
      await SPUtil.getInstance();
      await SPUtil.setInt(_indexKey, _currentBroadcasterIndex);
      await SPUtil.setInt(_countKey, _callCount);
      await SPUtil.setBool(_completedKey, _completed);
      logger.d('RobotChat progress saved: index=$_currentBroadcasterIndex, count=$_callCount, completed=$_completed');
    } catch (e) {
      logger.e('RobotChat save progress error: $e');
    }
  }

  /// 预加载指定索引主播的 userInfo 与视频
  Future<void> _prepareForIndex(int index) async {
    if (index < 0 || index >= _broadcasterData.length) return;
    final String userId = (_broadcasterData[index]['id'] ?? '').toString();
    if (userId.isEmpty) return;
    if (_userInfoCache.containsKey(userId) && _videoControllerCache.containsKey(userId)) {
      logger.d('【预加载】缓存命中，跳过加载，userId=$userId，索引=$index');
      return; // 已有缓存
    }

    logger.d('【预加载】开始加载主播资料，userId=$userId，索引=$index');
    try {
      await _request.userGetInfo(
        bindPage: false,
        userId: userId,
        onSuccess: (data) {
          final info = data as UserInfoModel;
          _onUserInfoFetched(userId, info);
        },
        onFail: (code, msg) {
          logger.e('【预加载】加载主播资料失败，userId=$userId，code=$code，msg=$msg');
          _scheduleUserInfoRetry(userId, index);
        },
      );
    } catch (e) {
      logger.e('【预加载】加载主播资料异常，userId=$userId，error=$e');
      _scheduleUserInfoRetry(userId, index);
    }
  }

  Future<void> _onUserInfoFetched(String userId, UserInfoModel info) async {
    // 打印完整JSON
    try {
      logger.d('''\n=================【主播资料加载完成-完整JSON】=================\nuserId: $userId\n${info.toJson()}\n=====================================================''' );
    } catch (e) {
      logger.e('【打印主播完整资料失败】userId=$userId，error=$e');
    }

    _userInfoCache[userId] = info;

    // 统一从 mediaList.mediaUrl 字段取视频地址
    String? thumb;
    String? videoUrl;
    if (info.mediaList != null && info.mediaList!.isNotEmpty) {
      // 先尝试找到看起来是视频的 mediaUrl（包含 .mp4 或包含 "video" 字样）
      final candidates = info.mediaList!;
      final preferVideo = candidates.firstWhere(
        (m) => (m.mediaUrl ?? '').toLowerCase().contains('.mp4') || (m.mediaUrl ?? '').toLowerCase().contains('video'),
        orElse: () => candidates.first,
      );
      videoUrl = preferVideo.mediaUrl;
      thumb = preferVideo.thumbUrl;

      // 如果选中的 videoUrl 仍为空，则尝试找第一个非空 mediaUrl
      if (videoUrl == null || videoUrl.isEmpty) {
        final anyWithUrl = candidates.firstWhere(
          (m) => (m.mediaUrl ?? '').isNotEmpty,
          orElse: () => candidates.first,
        );
        videoUrl = anyWithUrl.mediaUrl;
        thumb = anyWithUrl.thumbUrl ?? thumb;
      }
    }

    logger.d('【预加载】本次选取的视频URL(mediaUrl)=$videoUrl，封面(thumb)=${thumb ?? '空'}，userId=$userId');

    if (thumb != null && thumb.isNotEmpty) {
      _thumbCache[userId] = thumb;
      try {
        logger.d('【预加载】开始缓存封面图，userId=$userId，thumb=$thumb');
        await precacheImage(Image.network(thumb).image, Get.overlayContext!);
        logger.d('【预加载】封面图缓存完成，userId=$userId');
      } catch (e) {
        logger.e('【预加载】封面图缓存失败，userId=$userId，error=$e');
      }
    }
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoUrlCache[userId] = videoUrl;
      try {
        logger.d('【预加载】开始预加载视频，userId=$userId，url=$videoUrl');
        final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0);
        _videoControllerCache[userId] = controller;
        logger.d('【预加载】视频预加载完成，userId=$userId，size=${controller.value.size.width.toInt()}x${controller.value.size.height.toInt()}');
      } catch (e) {
        logger.e('【预加载】视频预加载失败，userId=$userId，error=$e');
        _scheduleVideoRetry(userId);
      }
    } else {
      logger.d('【预加载】该主播无可用的 mediaUrl 视频地址，userId=$userId');
    }
  }
  
  bool _isDataReadyForUser(String userId) {
    return _userInfoCache.containsKey(userId);
  }
  
  void _scheduleUserInfoRetry(String userId, int index) {
    if (_userInfoRetrying.contains(userId)) return;
    _userInfoRetrying.add(userId);
    final attempt = (_userInfoRetryCount[userId] ?? 0) + 1;
    _userInfoRetryCount[userId] = attempt;
    logger.d('【预加载】用户资料加载失败，3秒后重试第$attempt次，userId=$userId');
    Future.delayed(const Duration(seconds: 3), () async {
      _userInfoRetrying.remove(userId);
      if (!_isLogin || _completed || !isEnabled) return;
      await _prepareForIndex(index);
    });
  }

  bool _isVideoReadyForUser(String userId) {
    final c = _videoControllerCache[userId];
    return c != null && c.value.isInitialized;
  }

  void _scheduleVideoRetry(String userId) {
    if (_videoRetrying.contains(userId)) return;
    _videoRetrying.add(userId);
    final attempt = (_videoRetryCount[userId] ?? 0) + 1;
    _videoRetryCount[userId] = attempt;
    logger.d('【预加载】视频未就绪，3秒后重试第$attempt次，userId=$userId');
    Future.delayed(const Duration(seconds: 3), () async {
      _videoRetrying.remove(userId);
      if (!_isLogin || _completed || !isEnabled) return;
      final index = _broadcasterData.indexWhere((e) => (e['id'] ?? '').toString() == userId);
      if (index >= 0) {
        await _prepareForIndex(index);
      }
    });
  }
  /// 开始触发机器人搭讪定时器
  /// 在用户登录后进入主页时调用
  Future<void> startRobotChatTimer() async {
    if (_isInitialized) {
      stopChatTimer();
    }
    
    if (!isEnabled) {
      logger.d('Robot chat is not enabled');
      return;
    }

    if (!_isLogin) {
      logger.d('Robot chat deferred: user not logged in');
      return;
    }

    await _loadProgress();
    if (_completed) {
      logger.d('Robot chat already completed for this user, skipping timers');
      // 已完成则放开弹窗队列
      DialogQueueUtil.to.openGate();
      return;
    }

    // 首个视频预加载滞后2秒，避免阻塞首页主播墙渲染
    logger.d('【预加载】首个视频将在2秒后开始预加载');
    await Future.delayed(const Duration(seconds: 2));

    // 预加载当前主播（资料+视频）
    await _prepareForIndex(_currentBroadcasterIndex);

    // 可选：并行预加载下一位，但不阻塞
    unawaited(_prepareForIndex((_currentBroadcasterIndex + 1) % _broadcasterData.length));

    logger.d('Starting robot chat timer');
    _isInitialized = true;

    // 未完成：先关闭弹窗队列总闸，等待五通结束
    DialogQueueUtil.to.closeGate();

    // 合并为单一滚动定时器
    _startPeriodicTimer();
  }

  /// 启动第一个定时器：10-20秒随机触发
  void _startFirstTimer() {
    // 已合并到滚动定时器中
  }

  /// 启动第二个定时器：20-30秒随机触发
  void _startSecondTimer() {
    // 已合并到滚动定时器中
  }

  bool get _canTrigger => !_isShowingDialog && !_completed && _callCount < _broadcasterData.length;

  /// 与消息弹窗一致的场景屏蔽判断（增强版）
  bool _isSceneBlocked() {
    if (_externallySuppressed) {
      logger.d('SceneBlocked: externally suppressed');
      return true;
    }
    if (!_isLogin) {
      logger.d('SceneBlocked: not logged in');
      return true;
    }
    if (Get.isRegistered<VideoCallHandler>() && Get.find<VideoCallHandler>().onCallModel != null) {
      logger.d('SceneBlocked: onCallModel != null');
      return true;
    }
    if (Get.isRegistered<StartMatchLogic>()) {
      logger.d('SceneBlocked: StartMatchLogic registered (matching)');
      return true;
    }
    if (
        Get.currentRoute == RoutePath.callPage ||
        Get.currentRoute == RoutePath.onCallPage ||
        Get.currentRoute == RoutePath.videoCallPage) {
      logger.d('SceneBlocked: currentRoute=${Get.currentRoute}');
      return true;
    }
    return false;
  }

  /// 触发机器人搭讪
  void _triggerRobotChat() async {
    _ensurePeriodicTimer();
    if (!isEnabled) { _scheduleNextTick(); return; }
    if (_isSceneBlocked()) {
      logger.d('Robot chat blocked by current scene, waiting next tick');
      _scheduleNextTick();
      return;
    }

    if (!_canTrigger) {
      if (_callCount >= _broadcasterData.length) {
        _completed = true;
        _saveProgress();
        stopChatTimer();
      }
      logger.d('Robot chat cannot trigger. showing=$_isShowingDialog, completed=$_completed, count=$_callCount');
      _scheduleNextTick();
      return;
    }

    // 确保当前索引的数据已准备；若未准备则先准备并再显示
    await _prepareForIndex(_currentBroadcasterIndex);

    // 如果数据仍未就绪（如接口失败等待重试），则延后3秒再尝试
    final String pendingUserId = (_broadcasterData[_currentBroadcasterIndex]['id'] ?? '').toString();
    if (!_isDataReadyForUser(pendingUserId)) {
      logger.d('【预加载】资料未就绪，延后3秒再尝试显示，userId=$pendingUserId');
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isLogin || _completed || !isEnabled) return;
        _triggerRobotChat();
      });
      return;
    }
    logger.d('Triggering robot chat with broadcaster ${_currentBroadcasterIndex + 1}');
    _showChatDialog();
  }

  /// 显示通话弹窗（展示即计数，传入预加载的媒体）
  void _showChatDialog() {
    if (_isShowingDialog) return;
    if (_isSceneBlocked()) {
      logger.d('Show blocked on final check, waiting next 30s tick');
      return;
    }

    final Map<String, dynamic> data = _broadcasterData[_currentBroadcasterIndex];
    final String userId = (data['id'] ?? '').toString();
    String name = (data['name'] ?? '').toString();

    final info = _userInfoCache[userId];
    final controller = _videoControllerCache[userId];
    final String? thumb = _thumbCache[userId];
    final String? avatar = info?.avatarUrl ?? info?.mediumAvatarUrl ?? info?.avatarThumbUrl;
    if ((info?.nickname ?? '').toString().isNotEmpty) {
      name = info!.nickname!;
    }

    // 视频未就绪则不展示，不消耗计数，3秒后重试
    if (!_isVideoReadyForUser(userId)) {
      logger.d('【弹窗展示】视频未就绪，暂停展示与计数，3秒后重试。userId=$userId');
      _scheduleVideoRetry(userId);
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isLogin || _completed || !isEnabled) return;
        if (!_isSceneBlocked() && !_isShowingDialog) {
          _showChatDialog();
        }
      });
      return;
    }

    logger.d('''\n———【弹窗展示使用数据】———\nuserId: $userId\n昵称(用于展示): $name\n头像(用于展示): ${avatar ?? '空'}\n封面(用于展示): ${thumb ?? '空'}\n视频控制器是否就绪: ${controller != null && controller.value.isInitialized}\n———————————————''');

    _callCount += 1;
    _currentBroadcasterIndex = (_currentBroadcasterIndex + 1) % _broadcasterData.length;
    if (_callCount >= _broadcasterData.length) {
      _completed = true;
      stopChatTimer();
    }
    _saveProgress();

    _isShowingDialog = true;

    if (controller != null) {
      controller.play();
    }

    // 插入一条“未接听”通话记录到通话列表（假电话）
    _insertFakeMissedRecord(
      userId: userId,
      nickname: name,
      avatar: avatar ?? "",
    );

    RobotChatDialog.show(
      broadcasterData: {"name": name},
      onClose: () {
        if (controller != null) {
          controller.pause();
          controller.seekTo(Duration.zero);
        }
        _onDialogClosed();
      },
      videoController: controller,
      thumbUrl: thumb,
      avatarUrl: avatar,
    );
  }

  /// 向通话记录插入一条未接听的假记录
  Future<void> _insertFakeMissedRecord({
    required String userId,
    required String nickname,
    required String avatar,
  }) async {
    try {
      if (!Get.isRegistered<VideoCallController>()) return;
      final vc = Get.find<VideoCallController>();
      final String channel = "robot_fake_call_${DateTime.now().millisecondsSinceEpoch}";
      await vc.insert(
        dao: VideoCallDao(
          userId: userId,
          channelName: channel,
          nickname: nickname,
          avatar: avatar,
          callType: VideoCallType.missed, // 呼进未接听，使用统一常量，保证多语言key一致
          endTime: DateTime.now().millisecondsSinceEpoch,
          duration: 0,
        ),
      );
    } catch (e) {
      logger.e('插入假通话记录失败: $e');
    }
  }

  /// 弹窗关闭回调
  void _onDialogClosed() async {
    _isShowingDialog = false;

    // 关闭弹窗后：立即预加载下一位
    logger.d('【预加载】弹窗关闭，开始加载下一位主播资源，索引=$_currentBroadcasterIndex');
    unawaited(_prepareForIndex(_currentBroadcasterIndex));

    if (_completed || _callCount >= _broadcasterData.length) {
      _completed = true;
      
      // 先保存进度，确保状态及时更新
      await _saveProgress();
      logger.d('第五次机器人通话完成，状态已保存：completed=$_completed, count=$_callCount');
      
      stopChatTimer();
      
      // 第五个弹窗关闭后，重新调用coinPresentedGet接口
      _callCoinPresentedGetAfterCompletion();

      // 五通完成：打开弹窗队列总闸
      DialogQueueUtil.to.openGate();
      
      // 通知其他组件状态已更新
      _notifyRobotChatCompleted();
      return;
    }
    // 重新安排下一次触发
    _scheduleNextTick();
  }

  /// 停止搭讪定时器（不重置本地进度）
  void stopChatTimer() {
    _firstChatTimer?.cancel();
    _firstChatTimer = null;
    _secondChatTimer?.cancel();
    _secondChatTimer = null;
    _periodicChatTimer?.cancel();
    _periodicChatTimer = null;
    _isInitialized = false;
    _isShowingDialog = false;
    logger.d('Robot chat timer stopped');
  }

  /// 充值后强制视为五通完成：持久化并开闸
  void _forceCompleteDueToRecharge() async {
    try {
      _completed = true;
      _callCount = _broadcasterData.length;
      await _saveProgress();
      stopChatTimer();
      DialogQueueUtil.to.openGate();
      _notifyRobotChatCompleted();
      logger.d('RobotChat: 已因充值直接标记为五通完成并开闸');
    } catch (e) {
      logger.e('RobotChat: 充值后强制完成流程异常: $e');
    }
  }

  /// 第五个弹窗关闭后调用coinPresentedGet接口
  void _callCoinPresentedGetAfterCompletion() {
    try {
      if (Get.isRegistered<RequestRepository>()) {
        final request = Get.find<RequestRepository>();
        request.coinPresentedGet(onSuccess: (RewardModel data) {
          logger.d('第五个主播弹窗完成后，重新调用coinPresentedGet接口成功');
        });
      }
    } catch (e) {
      logger.e('调用coinPresentedGet接口异常: $e');
    }
  }

  /// 通知其他组件机器人通话已完成
  void _notifyRobotChatCompleted() {
    try {
      // 通知 VideoCallHandler 更新状态
      if (Get.isRegistered<VideoCallHandler>()) {
        final videoCallHandler = Get.find<VideoCallHandler>();
        // 触发隐私模式状态更新，这会重新检查机器人完成状态
        unawaited(videoCallHandler.updateListenerByPrivacyMode());
        logger.d('已通知 VideoCallHandler 更新机器人通话完成状态');
      }
      
      // 强制刷新 SPUtil 缓存，确保其他组件能立即读取到最新状态
      _forceRefreshSPUtilCache();
      
      logger.d('机器人通话完成状态通知完成');
    } catch (e) {
      logger.e('通知其他组件机器人通话完成状态失败: $e');
    }
  }

  /// 强制刷新 SPUtil 缓存，确保状态立即生效
  void _forceRefreshSPUtilCache() {
    try {
      // 通过读取操作强制刷新缓存
      final uid = _appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
          ? _appConfig.userInfo.userId!.toString()
          : 'guest';
      
      // 强制读取一次，确保缓存更新
      final completed = SPUtil.getBool(_completedKey, defaultValue: false);
      final count = SPUtil.getInt(_countKey, defaultValue: 0);
      final index = SPUtil.getInt(_indexKey, defaultValue: 0);
      
      logger.d('强制刷新SPUtil缓存完成: completed=$completed, count=$count, index=$index');
    } catch (e) {
      logger.e('强制刷新SPUtil缓存失败: $e');
    }
  }

  /// 清理所有视频缓存（用于删除账号时彻底清理）
  Future<void> clearAllVideoCache() async {
    try {
      logger.d('开始清理所有视频缓存...');
      
      // 清理视频控制器
      _videoControllerCache.forEach((key, controller) {
        try {
          if (controller.value.isPlaying) {
            controller.pause();
          }
          controller.seekTo(Duration.zero);
          controller.dispose();
          logger.d('视频控制器已释放: $key');
        } catch (e) {
          logger.e('清理视频控制器失败: $key, error: $e');
        }
      });
      _videoControllerCache.clear();
      
      // 清理用户信息缓存
      _userInfoCache.clear();
      
      // 清理封面图缓存
      _thumbCache.clear();
      
      // 清理视频URL缓存
      _videoUrlCache.clear();
      
      // 等待一段时间确保资源完全释放
      await Future.delayed(const Duration(milliseconds: 200));
      
      logger.d('所有视频缓存清理完成');
    } catch (e) {
      logger.e('清理视频缓存失败: $e');
    }
  }

  /// 手动触发一次搭讪（用于测试）
  void manualTriggerChat() {
    if (_isShowingDialog) return;
    _triggerRobotChat();
  }
}

