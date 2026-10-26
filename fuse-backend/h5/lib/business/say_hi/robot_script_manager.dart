import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/broadcaster/broadcaster_model.dart';
import 'package:untitled1/business/say_hi/widget/say_hi_dialog.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';

/// 机器人随机话术管理器
/// 负责在登录后进入主页时触发随机话术
class RobotScriptManager extends GetxController {
  //{"Hi","Hello,Baby","Hello~~","You seem right for me,let's chat"}
  final List<String> _scriptList = ["Hi", "Hello,Baby", "Hello~~", "You seem right for me,let's chat"];

  final _request = Get.find<RequestRepository>();
  final _appConfig = Get.find<AppConfigManager>();

  /// 第一个定时器：10-20秒后调用一次
  Timer? _firstTimer;

  /// 第二个定时器：60-90秒后调用一次
  Timer? _secondTimer;

  /// 第三个定时器：每2分钟调用一次
  Timer? _periodicTimer;

  /// 是否已经初始化
  bool _isInitialized = false;

  /// 随机数生成器
  final Random _random = Random();

  //是否生效 非审核用户 & 非付费用户
  bool get isEnabled => !(_appConfig.userInfo.isRecharge ?? false) && !(_appConfig.userInfo.isRecharge ?? false);

  @override
  void onInit() {
    super.onInit();
    logger.d('RobotScriptManager initialized');
  }

  @override
  void onClose() {
    stopAllTimers();
    super.onClose();
  }

  /// 开始触发随机话术定时器
  /// 在用户登录后进入主页时调用
  void startRobotScriptTimers() {
    if (_isInitialized) {
      // 如果已经初始化过，先停止所有定时器
      stopAllTimers();
    }
    if (!isEnabled) {
      logger.d('Robot script is not enabled');
      return;
    }

    logger.d('Starting robot script timers');
    _isInitialized = true;

    // 第一个定时器：10-20秒后调用一次
    final int firstDelay = 10 + _random.nextInt(11); // 10-20秒
    _firstTimer = Timer(Duration(seconds: firstDelay), () {
      _triggerRobotScript('First timer (${firstDelay}s)');
    });

    // 第二个定时器：60-90秒后调用一次
    final int secondDelay = 60 + _random.nextInt(31); // 60-90秒
    _secondTimer = Timer(Duration(seconds: secondDelay), () {
      _triggerRobotScript('Second timer (${secondDelay}s)');
    });

    // 第三个定时器：每2分钟调用一次
    _startPeriodicTimer();
  }

  /// 开始周期性定时器（每2分钟）
  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _triggerRobotScript('Periodic timer (2min)');
    });
  }

  /// 重新开始周期性定时器
  /// 当用户点击Say Hi之后调用，重新计时
  void restartPeriodicTimer() {
    logger.d('Restarting periodic timer after Say Hi');
    _startPeriodicTimer();
  }

  /// 停止所有定时器
  void stopAllTimers() {
    _firstTimer?.cancel();
    _firstTimer = null;

    _secondTimer?.cancel();
    _secondTimer = null;

    _periodicTimer?.cancel();
    _periodicTimer = null;

    _isInitialized = false;
    _sayHiBroadcasterIds.clear();
    logger.d('All robot script timers stopped');
  }

  /// 触发机器人随机话术
  void _triggerRobotScript(String source) {
    final String? userId = _appConfig.userInfo.userId;
    if (userId == null || userId.isEmpty) {
      logger.w('Cannot trigger robot script: user ID is null or empty');
      return;
    }

    logger.d('Triggering robot script from: $source');

    _request.robotScript(
      fromUserId: userId,
      scriptTriggerType: 1, //0:用户触发、1:机器人触发
      onSuccess: (data) {
        logger.d('Robot script triggered successfully from $source: $data');
      },
      onFail: (code, msg) {
        logger.e('Failed to trigger robot script from $source: code=$code, msg=$msg');
      },
    );
  }

  /// 处理Say Hi按钮点击
  void onSayHiPressed(List<SayHiRecommendBroadcasterModel> broadcasters) async{
    final String? userId = _appConfig.userInfo.userId;
    if (userId == null || userId.isEmpty) {
      logger.w('Cannot send Say Hi: user ID is null or empty');
      return;
    }

    final sayHiMaxCount = _appConfig.strategyModel?.sayHiMaxCount;
    final imSessionBroadcasterIds = _appConfig.strategyModel?.imSessionBroadcasterIds ?? [];
    //imSessionBroadcasterIds 和 _sayHiBroadcasterIds 去重 后的数量
    final uniqueBroadcasterIds = imSessionBroadcasterIds.toSet().union(_sayHiBroadcasterIds);

    //是否已经超过最大次数
    if (uniqueBroadcasterIds.length >= (sayHiMaxCount ?? 0)) {
      //Toast You have used up your Say Hi times. You can Top up to chat.
      // Toast.showMsg("You have used up your Say Hi times. You can Top up to chat.".bhTR);
      // //弹出充值弹窗
      // RechargeDialog.show(entry: PayEntry.SOURCE_59, bindWidget: null);
      VipPrivilegesSheet.show();
      return;
    }

    logger.d('Sending Say Hi from robot script manager');
    for (var broadcaster in broadcasters) {
      final String? targetId = broadcaster.broadcasterId;
      if (targetId == null || targetId.isEmpty) {
        logger.w('Cannot send Say Hi: target ID is null or empty');
        continue;
      }
      //随机话术
      final String script = _scriptList[_random.nextInt(_scriptList.length)];
      logger.d('Sending Say Hi: $script');
      //发送融云消息
      try {
       RCMessageManager().sendTextMessage(
          message: null,
          targetId: targetId,
          sendId: _appConfig.userInfo.userId ?? "",
          nickname: _appConfig.userInfo.nickname ?? "",
          avatar: _appConfig.userInfo.avatarUrl ?? "",
          text: script,
          onComplete: () {
            //添加到imSessionBroadcasterIds
             //发送Event
            // EventBusUtil.fire<SayHiEvent>(SayHiEvent(targetId));
          },
        );
      } catch (e) {
        logger.e('Failed to send Say Hi: $e');
      }
      // //添加到imSessionBroadcasterIds
      // _appConfig.strategyModel?.imSessionBroadcasterIds?.add(targetId);
      // 调用机器人话术API (用户触发)
      _request.robotScript(
        fromUserId: userId,
        scriptTriggerType: 0, // 8:用户触发Say Hi
        targetId: targetId,
        onSuccess: (data) {
          logger.d('Say Hi sent successfully: $data');
          // 重新启动周期性定时器
          restartPeriodicTimer();
        },
        onFail: (code, msg) {
          logger.e('Failed to send Say Hi: code=$code, msg=$msg');
        },
      );
      _request.oneClickSayHi(
          onSuccess: (data) {
            logger.d('Record Say Hi Broadcaster Id: $data');
          },
          onFail: (code, msg) {});
      //Toast Message Sent
      Toast.showMsg("Message Sent".bhTR);
      _sayHiBroadcasterIds.add(targetId);
      //发送Event
      EventBusUtil.fire<SayHiEvent>(SayHiEvent(targetId));
    }
  }

  //记录点击了Say Hi 的主播id
  static final Set<String> _sayHiBroadcasterIds = {};

  //判断当前主播是否可以发送Say Hi
  static bool isCanSendSayHi(String broadcasterId, String? status) {
    //获取策略接口say hi 最大次数
    final appConfig = Get.find<AppConfigManager>();
    //是否付费用户
    if (appConfig.isRecharge && (appConfig.userInfo.hasEquity ?? false)) {
      return false;
    }
    //如果主播是online 则返回false
    if (status?.toLowerCase() == "online") {
      return false;
    }
    
    //获取 已经发送过消息的 主播id
    final imSessionBroadcasterIds = appConfig.strategyModel?.imSessionBroadcasterIds ?? [];
    //如果imSessionBroadcasterIds包含当前主播id，则返回false
    if (imSessionBroadcasterIds.contains(broadcasterId)) {
      return false;
    }
    if (RobotScriptManager._sayHiBroadcasterIds.contains(broadcasterId)) {
      return false;
    }

    return true;
  }
  //判断当前主播是否可以发送Say Hi
  static bool isCanSendSayHiInfo(String broadcasterId) {
     //获取策略接口say hi 最大次数
    final appConfig = Get.find<AppConfigManager>();
     //是否付费用户
    if (appConfig.isRecharge && (appConfig.userInfo.hasEquity ?? false) ) {
      return false;
    }
   
    //获取 已经发送过消息的 主播id
    final imSessionBroadcasterIds = appConfig.strategyModel?.imSessionBroadcasterIds ?? [];
    //如果imSessionBroadcasterIds包含当前主播id，则返回false
    if (imSessionBroadcasterIds.contains(broadcasterId)) {
      return false;
    }
    return true;
  }
}
