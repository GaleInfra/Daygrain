import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/hang_up_model.dart';
import 'package:untitled1/model/video_call/on_call_model.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/msg_notication/message_pop_event.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../common_logic/cache_manager.dart';
import '../../../event_bus/video_call/video_call_event.dart';
import '../../../model/video_call/pick_up_model.dart';
import '../../../res/pay_entry.dart';
import '../../../widget/dialog/recharge_dialog.dart';

class StartMatchLogic extends GetBaseController {
  /// 话术数据集
  final List<String> _contentList = [];

  /// 话术内容
  final content = "".obs;

  /// 话术轮播定时器
  Timer? contentTimer;

  /// 匹配定时器
  Timer? matchTimer;

  /// 匹配成功后的跳转定时器
  Timer? jumpTimer;

  /// 匹配数据
  OnCallModel? onCallModel;

  UserInfoModel? userInfo;

  // 匹配成功
  final RxBool matchSuccess = false.obs;

  String clientSessionId = "";

  /// 通话监听
  StreamSubscription<VideoCallEvent>? _event;

  final appConfig = Get.find<AppConfigManager>();

  final _videoHandler = Get.find<VideoCallHandler>();

  ///当前页面是否已经退出
  bool isExit = false;

  // 使用全局配置的匹配参数
  int get matchIndex => appConfig.matchIndex;
  bool get isGoddessMatch => appConfig.isGoddessMatch;

  @override
  void onInit() {
    super.onInit();

    // 打印当前匹配类型
    print("匹配初始化: matchIndex=$matchIndex, isGoddessMatch=$isGoddessMatch");

    EventBusUtil.fire(MessagePopEvent());
    logHandle.initLog('flash_matching');
    Future.delayed(const Duration(seconds: 2), () async {
      if (Get.isRegistered<StartMatchLogic>()) {
        if (!kIsWeb) await WakelockPlus.enable();
        return false;
      }
    });
  }

  @override
  void onReady() {
    clientSessionId = uuid.v4();
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (isExit) {
        return;
      }
      if (event.command == SocketCommandKey.onPickUp &&
          onCallModel?.toUserIdStr?.toString() == "0") {
        // 被接通 && toUserId无有效值的情况下，才监听执行事件监听
        PickUpModel model = event.data;
        if (model.channelName == onCallModel?.channelName) {
          _onGetInfo(
              userId: model.h5FromUserId?.toString() ?? "",
              mClientSessionId: clientSessionId);
        }
      }
      if (SocketCommandKey.onHangUp == event.command) {
        HangUpModel hangUpModel = event.data;
        if (hangUpModel.channelName == onCallModel?.channelName) {
          //相同频道
          if (hangUpModel.h5FromUserId?.toString() ==
                  userInfo?.userId?.toString() ||
              hangUpModel.h5ToUserId?.toString() ==
                  userInfo?.userId?.toString()) {
            // 使用全局参数，不需要重置匹配类型
            print("挂断后重新匹配: 保持匹配类型 - ${isGoddessMatch ? '女神匹配' : '普通匹配'}");
            restartMatch();
          } else {
            onBack();
            Toast.showMsg("status_noUsersAvailable".bhTR);
          }
        }
      }
    });
    _getContentSearch();
    matchInlet();
    super.onReady();
  }

  ///重新开始匹配
  void restartMatch() {
    matchSuccess.value = false;
    onCallModel = null;
    //重置SessionId
    clientSessionId = uuid.v4();
    //销毁定时器

    matchTimer?.cancel();
    matchTimer = null;
    jumpTimer?.cancel();
    jumpTimer = null;

    // 使用全局参数，不需要重置匹配类型
    matchInlet();
  }

  /// 匹配入口
  void matchInlet() {
    if ((appConfig.strategyModel?.flashChatConfig?.isFreeCall ?? false) &&
        (appConfig.strategyModel?.flashChatConfig?.residueFreeCallTimes ?? 0) >
            0) {
      // 当前有免费匹配次数，正常进入匹配
      _flashChat();
    } else {
      // 非免费匹配
      final genderMatchCoin = appConfig.strategyModel?.genderMatchCoin;
      final hasEquity = appConfig.userInfo.hasEquity ?? false;
      final requiredCoins = isGoddessMatch
          ? genderMatchCoin?.goddessMatchCoins(hasEquity: hasEquity) ?? 0
          : (genderMatchCoin?.femaleCoins ?? 0);

      if ((appConfig.userInfo.availableCoins ?? 0) >= requiredCoins) {
        // 金币充足，正常进入匹配
        _flashChat();
      } else {
        // 金币不足，随机获取主播并进入金币不足
        onBack();
        //延迟300毫秒
        Future.delayed(const Duration(milliseconds: 300), () {
          Toast.showMsg("error_insufficientDiamonds".bhTR);
          RechargeDialog.show(entry: PayEntry.SOURCE_28, bindWidget: null);
        });
      }
    }
    matchTimer?.cancel();
    matchTimer = null;
    matchTimer = Timer(const Duration(seconds: 30), () {
      Toast.showMsg("status_noUsersAvailable".bhTR);
      onBack();
    });
  }

  /// 获取随机话术
  Future _getContentSearch() async {
    request.configContentSearch(
      onSuccess: (data) {
        _contentList.clear();
        _contentList.addAll(data);
        content.value = _contentList.first;
        contentTimer?.cancel();
        contentTimer = null;
        contentTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          int index = _contentList.indexOf(content.value);
          if (index == _contentList.length - 1) {
            index = 0;
          } else {
            index++;
          }
          content.value = _contentList[index];
        });
      },
      onFail: (code, msg) {},
    );
  }

  /// 快速匹配
  Future _flashChat() async {
    print("匹配类型: ${isGoddessMatch ? '女神匹配' : '普通匹配'}, 场景: 开始匹配");
    final chatType = isGoddessMatch ? 2 : 1; // 1代表快速匹配，2代表女神匹配
    await request.videoCallFlashChat(
      clientSessionId: clientSessionId,
      chatType: chatType,
      onSuccess: (data) {
        // 使用 prettyJson 工具函数格式化打印
        print("匹配成功数据返回: ${prettyJson(data.toJson())}");
        print(
            "匹配类型一致性检查: 发送chatType=$chatType, 返回callCategory=${data.callCategory}");
        if (isExit) {
          //应用已经销毁
          _cancelMatch();
          return;
        }
        onCallModel = data;
        update();
        if (data.toUserIdStr != null && data.toUserIdStr?.toString() != "0") {
          // 不为空 && 不为0，说明匹配到了live主播
          print("匹配成功: 匹配到live主播, toUserIdStr=${data.toUserIdStr}");
          _onGetInfo(
              userId: data.toUserIdStr!.toString(),
              mClientSessionId: clientSessionId);
        } else {
          print("匹配等待: toUserIdStr为空或为0，等待抢单池主播接受");
        }
      },
      onFail: (code, msg) {
        print("匹配失败: code=$code, msg=$msg");
      },
    );
  }

  /// 匹配成功获取用户数据，停留2秒后进入匹配连接页
  /// [userId] 匹配到的主播id
  /// [mClientSessionId] 客户端SessionId 用于标记是否已经被重置
  Future _onGetInfo(
      {required String userId, required String mClientSessionId}) async {
    userInfo = UserInfoModel(userId: userId);
    appConfig.onGetStrategy();
    if (userId.isEmpty) return;

    //获取缓存是否有用户信息
    final user = CacheManager.userInfoCache(userId);
    if (user != null) {
      userInfo = user;
      // 刷新免费次数
      matchSuccess.trigger(true);
      // 已经匹配到了，取消20秒定时器
      matchTimer?.cancel();
      matchTimer = null;
      _onMatchJump(data: user, mClientSessionId: mClientSessionId);
      return;
    }
    //没有缓存就去获取线上用户数据
    // 获取用户数据以显示头像用户名等
    await request.userGetInfo(
      userId: userId,
      bindPage: false,
      onSuccess: (data) {
        if (mClientSessionId != clientSessionId || isExit) {
          //匹配已经被重置
          return;
        }
        // 刷新免费次数
        matchSuccess.trigger(true);
        // 已经匹配到了，取消20秒定时器
        matchTimer?.cancel();
        matchTimer = null;
        _onMatchJump(data: data, mClientSessionId: mClientSessionId);
      },
      onFail: (code, msg) {
        if (mClientSessionId != clientSessionId || isExit) {
          //匹配已经被重置
          return;
        }
        // 获取异常取消匹配
        Toast.showMsg("status_noUsersAvailable".bhTR);
        onBack();
      },
    );
  }

  /// 匹配成功/随机获取到主播，准备跳转
  /// [data] 匹配到的主播数据
  void _onMatchJump({
    required UserInfoModel data,
    required String mClientSessionId,
  }) {
    userInfo = data;
    update();
    jumpTimer?.cancel();

    jumpTimer = Timer(Duration(seconds: Random().nextInt(2) + 2), () {
      if (onCallModel == null) {
        return;
      }

      if (mClientSessionId != clientSessionId || isExit) {
        //匹配已经被重置
        return;
      }

      _videoHandler.onFlashChat(
        userInfo: userInfo,
        // 匹配时永远为呼叫方，所以只需要更新被呼叫方id
        // 同时还有一种情况，当随机获取主播时，onCallModel是为空的，所以还需要更新发起方id
        onCallModel: onCallModel?.copyWith(
          fromUserId: appConfig.userInfo.userId?.toString(),
          toUserId: userInfo?.userId ?? "",
        ),
      );
      //转跳视频页面
      Get.offNamed(RoutePath.videoCallPage);
      Future.delayed(const Duration(milliseconds: 500), () {
        isExit = true;
      });
    });
  }

  /// 主动退出页面
  void onBack() {
    logger.d("flash:$isExit");
    if (isExit) {
      return;
    }
    isExit = true;
    if (onCallModel != null) {
      _cancelMatch();
      onCallModel = null;
    }
    jumpTimer?.cancel();

    //用户体验优先，先退出
    //判断当前页面是否还在匹配中 如果是则关闭
    if (Get.currentRoute == RoutePath.startMatchPage) {
      Get.back();
    }
  }

  Future _cancelMatch({int retryNum = 0}) async {
    request.matchCancel(
      clientSessionId: clientSessionId,
      onSuccess: (data) {
        // Get.back();
      },
      onFail: (code, msg) {
        if (retryNum < 3) {
          _cancelMatch(retryNum: retryNum + 1);
        }
      },
    );
  }

  @override
  void onClose() {
    isExit = true;
    _event?.cancel();
    _event = null;
    contentTimer?.cancel();
    contentTimer = null;
    matchTimer?.cancel();
    matchTimer = null;
    jumpTimer?.cancel();
    jumpTimer = null;
    if (!kIsWeb) WakelockPlus.disable();
    super.onClose();
  }
}
