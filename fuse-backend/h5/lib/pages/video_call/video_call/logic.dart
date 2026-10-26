import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/available_coins_change.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/give_gift_success_event.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/gift/gift_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/on_gift_ask_model.dart';
import 'package:untitled1/model/video_call/on_give_gift_model.dart';
import 'package:untitled1/model/video_call/rear_camera_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/video_call/video_call/widget/flash_chat_banner.dart';
import 'package:untitled1/pages/video_call/video_call/widget/minute_countdown_dialog.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/msg_notication/message_pop_event.dart';

import '../../../event_bus/video_call/video_call_event.dart';
import '../../../model/video_call/hang_up_model.dart';
import '../../../model/video_call/on_chat_model.dart';
import '../../../net/base/response_parse.dart';
import '../../../res/my_color.dart';
import '../../../res/pay_entry.dart';
import '../../../res/video_call_data.dart';
import '../../../translate/translate_manager.dart';
import '../../../utils/gift_util.dart';
import '../../../utils/toast.dart';
import '../../../widget/give_gift_widget.dart';

import 'dart:js' as js;

//视频加入状态
enum VideoJoinState {
  none,

  /// 加入成功
  joined,

  /// 加入中
  joining,

  ///等待视频流加入
  waitingVideo,
}

class VideoCallLogic extends GetBaseController {
  GlobalKey pageKey = GlobalKey();

  /// 对方用户数据
  UserInfoModel? userInfo;

  /// 后置摄像头配置
  RearCameraModel? rearCameraModel;

  /// 己方ID
  String userId = "";

  /// 己方声网id
  int myUid = 0;

  /// 远端uid
  int remoteUid = 0;

  /// 文本消息数据
  final List<OnChatModel> messageList = [];


  /// 送礼动画widget
  Widget? giftWidget;

  /// 显示送礼物横幅
  bool showGiftBanner = false;

  /// 送礼物横幅三秒倒计时
  Timer? giftBannerThree;

  /// 送礼物横幅三秒倒计时
  Timer? giftBannerFive;

  /// 上个送礼的数据
  OnGiveGiftModel? lastGiveGift;

  /// 上个礼物（相同礼物）的数量
  int lastGiftCount = 1;

  /// 被索取礼物
  OnGiftAskModel? giftAskModel;

  /// 被索取倒计时
  Timer? giftAskTimer;

  /// 当前页面是否显示
  final RxBool pageShow = true.obs;

  /// 对方用户退出 true退出 false未退出
  bool userExited = false;

  /// 展示切换摄像头小红点
  final RxBool showRearCameraRed = true.obs;

  /// 显示金币不足提示
  final RxBool showNotEnough = false.obs;

  /// 显示匹配20秒倒计时
  final RxBool showFlachMatchDown = false.obs;

  /// 加入20秒倒计时
  Timer? _joinTimer;

  /// 加入20秒倒计时
  final RxInt joinNum = 20.obs;

  ///加入状态
  final joinState = VideoJoinState.none.obs;

  final _videoHandler = Get.find<VideoCallHandler>();

  final appConfig = Get.find<AppConfigManager>();

  /// 翻译工具
  final _translate = Get.find<TranslateManager>();
  GiftModel? giftKissItem;


  /// 视频通话event
  StreamSubscription<VideoCallEvent>? _event;

  /// app前后台切换event
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleEvent;

  /// 自定义成功送出礼物event
  StreamSubscription<GiveGiftSuccessEvent>? _giveGiftSuccessEvent;

  //余额变化监听
  StreamSubscription<AvailableCoinsChangeEvent>? _availableCoinsChangeEvent;
  //支付结果监听
  StreamSubscription<RechargeSuccessEvent>? _payResultEvent;

  ScrollController messageController = ScrollController();

  //是否清空屏幕
  final isClearScreen = false.obs;

  ///来源
  var _source = -1;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    logHandle.initLog('video_chat');
    EventBusUtil.fire(MessagePopEvent());

    if (GiftManager.to.giftList.isEmpty) return;
    for (var item in GiftManager.to.giftList) {
      if (item.name == "kiss") {
        giftKissItem = item;
        break;
      }
    }
  }

  @override
  void onReady() async {
    _videoHandler.isJoined = false;
    joinState.value = VideoJoinState.none;
    userId = appConfig.userInfo.userId ?? "";
    _videoHandler.onJumpVideoCall();
    _source = _videoHandler.callSource;
    _initRtcEngine();
    _initEvent();
    getInfo();
    _getRearCameraConfig();

    if (SPUtil.containsKey(MyKeys.firstTapRearCamera)) {
      // 存在，不显示切换摄像头小红点
      showRearCameraRed.value = false;
    }
    if (GiftManager.to.giftList.isEmpty) {
      // 礼物列表为空，拉取
      GiftManager.to.getGift();
    }
    // _getPermission();
    _onJoinTimer();

    super.onReady();
  }

  // void _getPermission() async {
  //   // 请求权限，以队列形式，避免退出时弹窗仍存在
  //   DialogQueueUtil.to.addDialog(DialogQueueElement(
  //       onShow: () =>
  //           requestPermission(Permission.microphone, showDialog: true)));
  //   DialogQueueUtil.to.addDialog(DialogQueueElement(
  //       onShow: () => requestPermission(Permission.camera, showDialog: true)));

  //   if (BHPlatform.isAndroid) {
  //     //获取蓝牙连接权限
  //     DialogQueueUtil.to.addDialog(DialogQueueElement(
  //         onShow: () => requestPermission(Permission.bluetoothConnect,
  //             showDialog: false)));
  //   }
  // }

  void _onJoinTimer() {
    joinState.value = VideoJoinState.joining;
    _joinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (Get.currentRoute == RoutePath.videoCallPage) {
        joinNum.trigger(joinNum.value - 1);
        if (joinNum.value <= 0) {
          if (myUid == 0 || remoteUid == 0) {
            _joinTimer?.cancel();

            if (userExited) {
              return;
            }
            userExited = true;
            onBack();
            // 双方任意一方未进入，自动挂断
            _videoHandler.hangUp(
              onSuccess: (data) {},
              onFail: (code, msg) {},
            );
          } else {
            _videoHandler.isJoined = true;
          }
        } else {
          if (myUid == 0 || remoteUid == 0) {
          } else {
            _videoHandler.isJoined = true;
          }
        }
      } else {
        _joinTimer?.cancel();
        return;
      }
    });
  }

  //等待处理的余额不足倒计时
  VideoCallEvent? _waitHandleHangUpTimeEvent;

  //检测
  void _handlEstimatedHangUpTimeEvent(VideoCallEvent event) {
    _waitHandleHangUpTimeEvent = event;
    _checkEstimatedHangUpTime();
  }

  void _checkEstimatedHangUpTime() {
    final event = _waitHandleHangUpTimeEvent;
    final user = userInfo;
    if (event != null) {
      //判断当前余额是否大于通话价格

      final availableCoins = getAppConfigManager()?.userInfo.availableCoins ?? 0;
      final price = ((getAppConfigManager()?.userInfo.isVip ?? false) ? user?.unitPrice : user?.vipUnitPrice) ?? 0;
      // 预计挂断时间
      if (event.data < 61 && availableCoins < price && _videoHandler.isJoined) {
        // 通话时间倒计时，金币不足倒计时弹窗
        showNotEnough.trigger(true);
        if (!showFlachMatchDown.value) {
          // 当匹配20秒倒计时不显示时，照常显示
          // 如果有匹配20秒倒计时显示，则在20秒widget里显示金币不足
          if (event.data < (MinuteCountdownDialog.currentKey?.currentState?.countSecond ?? 61)) {
            MinuteCountdownDialog.show(second: event.data);
          }
        }
      } else {
        // 大于60秒，关闭倒计时弹窗
        showNotEnough.trigger(false);
        MinuteCountdownDialog.dismiss();
      }
    }
  }

  void _initEvent() {
    _giveGiftSuccessEvent = EventBusUtil.listen<GiveGiftSuccessEvent>((event) {
      onGiveGift(show: true, model: event.data);
      isClearScreen.value = false;
    });
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (SocketCommandKey.onHangUpComplete == event.command) {
        if (userExited) {
          return;
        }
        //此处直接使用  onHangUpComplete 即可，一般是相同的Channel才会被触发
        DialogQueueUtil.to.closeAll();
        // 关闭倒计时弹窗和充值弹窗
        MinuteCountdownDialog.dismiss();
        RechargeDialog.dismiss();
        userExited = true;
        HangUpModel data = event.data;
        var reason = HandUpReason.NORMAL;
        if ((data.reason ?? 0) == 2) {
          Toast.showMsg("error_insufficientDiamonds".bhTR);
          reason = HandUpReason.NO_COINS;
        } else if ((data.reason ?? 0) == 1) {
          Toast.showMsg("info_hangUpCall".bhTR);
          reason = HandUpReason.NORMAL;
        } else {
          Toast.showMsg("label_error".bhTR);
          reason = HandUpReason.CL_EXCEPTION;
        }
        if (Get.currentRoute == RoutePath.videoCallPage) {
          onBack();
        }
      }
      if (event.command == SocketCommandKey.onChat) {
        int index = messageList.lastIndexWhere((element) => (event.data as OnChatModel).getOperator(element));
        if (index == -1) {
          // 消息
          messageList.insert(0, event.data);
          update();
          _onCheckTranslate();
          isClearScreen.value = false;
          messageController.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
        }
      }
      if (event.command == SocketCommandKey.estimatedHangUpTime) {
        _handlEstimatedHangUpTimeEvent(event);
      }
      // if (event.command == SocketCommandKey.onGiveGift) {
      //   // 送出礼物
      //   onGiveGift(show: true, model: event.data);
      // }
      if (event.command == SocketCommandKey.onGiftAsk) {
        // 被索取礼物
        onGiftAsk(event.data);
      }
    });
    _appLifecycleEvent = EventBusUtil.listen<AppLifecycleStateEvent>((event) async {
      if (event.state == AppLifecycleState.resumed) {
        try {} catch (e) {
          logger.e("从后台切到前台: $e");
        }
      }
    });

    //监听余额变化
    _availableCoinsChangeEvent = EventBusUtil.listen<AvailableCoinsChangeEvent>(
      (event) {
        _checkEstimatedHangUpTime();
      },
    );
    _payResultEvent = EventBusUtil.listen<RechargeSuccessEvent>((event) {
       _checkEstimatedHangUpTime();
    });
  }

  ///获取主播id
  String getAnchorId() {
    String userId = "";
    if (_videoHandler.isCallOut) {
      // 呼叫方页面
      userId = kIsWeb
          ? _videoHandler.onCallModel?.h5ToUserId?.toString() ?? (_videoHandler.onCallModel?.toUserId?.toString() ?? "")
          : _videoHandler.onCallModel?.toUserId?.toString() ?? "";
    } else {
      // 被呼叫方页面
      userId =
          kIsWeb ? _videoHandler.onCallModel?.h5FromUserId?.toString() ?? ("${_videoHandler.onCallModel?.fromUserId ?? ""}") : "${_videoHandler.onCallModel?.fromUserId ?? ""}";
    }
    return userId;
  }

  /// 获取主播数据
  Future getInfo({int retryNum = 0}) async {
    if (retryNum > 5) {
      userInfo ??= _videoHandler.userInfo;
      update();
      return;
    }
    String userId = getAnchorId();
    userInfo = CacheManager.userInfoCache(userId);
    if (userInfo != null) {
      _videoHandler.updateUserInfo(userInfo!);
      update();
      return;
    }

    await request.userGetInfo(
      userId: userId,
      onSuccess: (data) {
        userInfo = data;
        _videoHandler.updateUserInfo(data);
        update();
      },
      onFail: (code, msg) {
        if (userInfo == null) {
          getInfo(retryNum: ++retryNum);
        }
      },
    );
  }

  /// 监听页面是否显示
  void onListenPageShow(bool show) {
    if (!pageShow.value && show) {
      // 重新回到界面
      if (userExited) {
        onBack();
      }
    }
    pageShow.trigger(show);
  }

  /// 获取后置摄像头配置
  /// 【retryNum】 重试次数
  void _getRearCameraConfig({int retryNum = 5, Success<RearCameraModel>? onSuccess, Fail? onFail}) {
    if (appConfig.strategyModel?.isCallRearCamera ?? false) {
      // 开关为true时请求
      request.rearCameraConfig(
        onSuccess: (data) {
          rearCameraModel = data;
          onSuccess?.call(data);
          update();
        },
        onFail: (code, msg) {
          if (retryNum > 0) {
            _getRearCameraConfig(retryNum: --retryNum, onSuccess: onSuccess, onFail: onFail);
          } else {
            onFail?.call(code, msg);
          }
        },
      );
    }
  }

  /// 初始化声网引擎
  void _initRtcEngine() async {
    if (kIsWeb) {
      try {
        await checkCameraAndMicrophonePermission(showDialog: false, isFore: true, isNotMic: true);
      } catch (e) {
        logger.e(e);
      }

      // 获取appId
      String? appId = appConfig.getAppConfigByKey("rtck");

      if (appId?.isEmpty ?? true) return;
      js.context["myJoined"] = (u) {
        log('[myJoined] uid: $u ');
        if (myUid != 0) return;
        //自己加入
        update();
        _userUpdateAgoraUid(u ?? 0);
        _videoCallChannelJoin();
      };
      js.context["userJoined"] = (u) {
        log('[userJoined] uid: $u ');
        //主播加入
        _onRemoteJoin(u);
      };
      js.context["rtcSendVideoBitrateTooLow"] = (u) {
        log('[rtcSendVideoBitrateTooLow] ');
        //埋点
        final request = Get.find<RequestRepository>();
        request.log(event: "show", page: "rtcSendVideoBitrateTooLow");
      };

      // js.context["onSwitchCameraFlutter"] = () {
      //   log('[onSwitchCameraFlutter] ');
      //   onSwitchCamera();
      // };

      //断开连接
      js.context["rtcDisconnect"] = () {
        log('[rtcDisconnect] ');
        if (!userExited) {
          DialogQueueUtil.to.closeAll();
          // 关闭倒计时弹窗和充值弹窗
          MinuteCountdownDialog.dismiss();
          RechargeDialog.dismiss();
          // if (r == "Quit") {
          Toast.showMsg("info_hangUpCall".bhTR);
          // } else {
          //   Toast.showMsg("User Leaves");
          // }
          if (pageShow.value) {
            userExited = true;
            onBack();
            _videoHandler.hangUp(
              handUpReason: HandUpReason.SER_EXCEPTION,
              manual: false,
              onSuccess: (data) {
                // Toast.showMsg("User Leaves");
              },
              onFail: (code, msg) {
                // Toast.showMsg("User Leaves");
              },
            );
          }
        }
      };

      js.context["userLeft"] = (u, r) {
        log('[onUserOffline] uid: $u reason: $r');
        //延迟300毫秒
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!userExited) {
            DialogQueueUtil.to.closeAll();
            // 关闭倒计时弹窗和充值弹窗
            MinuteCountdownDialog.dismiss();
            RechargeDialog.dismiss();
            if (r == "Quit") {
              Toast.showMsg("info_hangUpCall".bhTR);
            } else {
              Toast.showMsg("User Leaves");
            }
            if (pageShow.value) {
              userExited = true;
              onBack();
              _videoHandler.hangUp(
                handUpReason: HandUpReason.CL_REMOTE_USER_LEFT,
                manual: false,
                onSuccess: (data) {
                  // Toast.showMsg("User Leaves");
                },
                onFail: (code, msg) {
                  // Toast.showMsg("User Leaves");
                },
              );
            }
          }
        });
      };

      js.context["onFirstFrameDecoded"] = () {
        log('[onFirstFrameDecoded] ');
        if (joinState.value != VideoJoinState.joined) {
          joinState.value = VideoJoinState.joined;
        }
      };
      js.context.callMethod("createClient");
      js.context.callMethod("joinChannel", [appId, _videoHandler.onCallModel?.channelName ?? "", _videoHandler.onCallModel?.rtcToken ?? "", userId]);

      return;
    }
  }

  /// 远端用户加入
  void _onRemoteJoin(int rUid) {
    remoteUid = rUid;
    update();
    if (myUid != 0) {
      // if (kIsWeb) joinState.value = VideoJoinState.joined;
      // 远端已加入 && 己方也加入了
      _joinTimer?.cancel();
      _videoHandler.isJoined = true;
      joinNum.trigger(-1);
      if (joinState.value != VideoJoinState.joined) {
        joinState.value = VideoJoinState.waitingVideo;
      }

      if (_source == VideoCallSource.FAST_MATCH) {
        // 当前是匹配通话，开始匹配倒计时
        FlashChatBanner.show();
      }
      _checkEstimatedHangUpTime();
    }
  }

  /// 关注或取消关注
  Future onFollowOrUnFollow() async {
    int followNum = userInfo?.followNum ?? 0;
    bool isFriend = !(userInfo?.isFriend ?? false);
    userInfo = userInfo?.copyWith(
      isFriend: isFriend,
      followNum: followNum == 0 ? 0 : followNum + (isFriend ? -1 : 1),
    );
    update();

    if (!isFriend) {
      // 取消关注
      await request.userUnfriend(
        userId: userInfo?.userId ?? "",
        onSuccess: (data) {
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userId,
            "follow": false,
          }));
          Toast.showMsg("status_unfollowSuccess".bhTR);
        },
        onFail: (code, msg) {
          //失败了则恢复状态
          userInfo = userInfo?.copyWith(
            isFriend: !isFriend,
            followNum: followNum,
          );
          update();
        },
      );
    } else {
      // 关注
      await request.userAddFriend(
        userId: userInfo?.userId ?? "",
        onSuccess: (data) {
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userId,
            "follow": true,
          }));
          Toast.showMsg("status_followSuccess".bhTR);
        },
        onFail: (code, msg) {
          //失败了则恢复状态
          userInfo = userInfo?.copyWith(
            isFriend: !isFriend,
            followNum: followNum,
          );
          update();
        },
      );
    }
  }

  /// 发送消息
  void onSendMessage({required OnChatModel model}) async {
    messageList.insert(0, model);
    update();
    messageController.animateTo(0, duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
    isClearScreen.value = false;
  }

  Future onSendGift(String code) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    OnChatModel data = OnChatModel(
      fromUserId: userId,
      toUserId: userInfo?.userId?.toString() ?? "0",
      content: "I send your a %#$code%#",
      timestamp: timestamp,
    );
    data.giftImage = code;
    onSendMessage(model: data);
  }


  bool sending = false;

  void showSureSendGift(GiftModel item, BuildContext context) {
    throttleUtil.throttle(() async {
      DialogUtil.showDialog(
        bindPage: true,
        tag: "sureSendGift",
        child: GiftSureConfirmDialog(
          item: item,
          onConfirm: () {
            DialogUtil.dismiss(tag: "sureSendGift");
            onkissGiveGift(item, context);
            // onkissGiveGift(item, context);
          },
        ),
      );
    }, key: "onSureSendGift");
  }

  /// 送出礼物
  Future<void> onkissGiveGift(GiftModel item, BuildContext context) async {
    if ((appConfig.userInfo.availableCoins ?? 0) < (item.coinPrice ?? 0)) {
      Toast.showMsg("error_insufficientDiamonds".bhTR);

      String entry = PayEntry.SOURCE_19;
      if (_videoHandler.onCallModel?.channelName == null) {
        entry = PayEntry.SOURCE_5;
      }
      RechargeDialog.show(entry: entry, bindWidget: context);
      return;
    }
    if (sending) {
      return;
    }
    sending = true;
    request
        .userGiveGift(
      channelName: _videoHandler.onCallModel?.channelName ?? "",
      giftCode: item.code ?? "",
      num: 1,
      recipientUserId: getAnchorId(),
      onSuccess: (data) {
        appConfig.saveUserInfo(appConfig.userInfo.copyWith(
          availableCoins: data,
        ));
      },
      onFail: (code, msg) {
        sending = false;
        logger.d("message");
      },
    )
        .then((value) {
      sending = false;
    }).onError((error, stackTrace) {
      sending = false;
    }).timeout(const Duration(seconds: 3), onTimeout: () {
      sending = false;
    });
  }

  /// 送礼成功
  void onGiveGift({
    required bool show,
    required OnGiveGiftModel? model,
  }) {
    if (show) {
      // 创建送礼动画
      String giftImage = "";
      giftWidget = null;
      var result = GiftUtil.giftImageList.where((element) => element.name == model?.giftCode).toList();
      if (result.isNotEmpty) {
        giftImage = result.first.image;
      }
      onSendGift(giftImage);
      String newKey = DateTime.now().millisecondsSinceEpoch.toString();
      giftWidget = GiveGiftWidget(
        key: ValueKey(newKey),
        giftImage: giftImage,
        onEnd: (key) {
          if (key == (giftWidget?.key as ValueKey<String>).value) {
            onGiveGift(show: false, model: null);
          }
        },
      );

      // 统计送礼数据
      showGiftBanner = true;
      if (model?.giftCode == lastGiveGift?.giftCode && giftBannerThree != null && giftBannerThree!.isActive) {
        // 礼物code相等，为同一礼物，同时在上个礼物送出的三秒内
        lastGiftCount++;
      } else {
        // 不想等，为新礼物
        lastGiveGift = model;
        lastGiftCount = 1;
      }
      //三秒倒计时
      giftBannerThree?.cancel();
      giftBannerThree = null;
      giftBannerThree = Timer(const Duration(seconds: 3), () {
        giftBannerThree?.cancel();
        giftBannerThree = null;
      });
      // 五秒倒计时
      giftBannerFive?.cancel();
      giftBannerFive = null;
      giftBannerFive = Timer(const Duration(seconds: 5), () {
        lastGiveGift = null;
        lastGiftCount = 1;
        showGiftBanner = false;
        update();
      });

      if (model?.fromUserId?.toString() == userId) {
        // 系统代替发消息
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        OnChatModel data = OnChatModel(
          fromUserId: userId,
          toUserId: userInfo?.userId?.toString() ?? "0",
          content: "${appConfig.userInfo.nickname} send ${userInfo?.nickname} a %#${model?.giftCode}%#",
          giftImage: giftImage,
          timestamp: timestamp,
        );

        // SocketUtil().emit(event: "messageEvent", data: data.toJson());
        // onSendMessage(model: data);
      }
    } else {
      giftWidget = null;
    }
    update();
  }

  /// 被索取礼物
  void onGiftAsk(OnGiftAskModel askModel) {
    giftAskModel = askModel;
    giftAskTimer?.cancel();
    giftAskTimer = null;
    giftAskTimer = Timer(const Duration(seconds: 10), () {
      // 倒计时结束清空数据
      giftAskModel = null;
      giftAskTimer?.cancel();
      giftAskTimer = null;
      update();
    });
    update();
  }

  /// 挂断
  Future onHangUp() async {
    DialogUtil.showDialog(
      bindWidget: pageKey.currentContext,
      bindPage: false,
      child: CloseVideoCallConfirmDialog(
        title: "",
        message: "confirm_hangUpCall".bhTR,
        messageStyle: TextStyle(
          fontSize: 8.sp,
          color: MyColor.white,
          height: 1.5,
        ),
        onConfirm: () async {
          if (userExited) {
            return;
          }
          final isBackMatch = Get.findCanNull<VideoCallLogic>()?.isBackMatch ?? false;
          userExited = true;
          DialogUtil.dismiss();
          MinuteCountdownDialog.dismiss();
          DialogQueueUtil.to.closeAll();
          onBack();
          _videoHandler.hangUp(
            isBackMatch: isBackMatch,
            onSuccess: (data) {},
            onFail: (code, msg) {},
          );
        },
        userInfo: userInfo,
      ),
    );
  }

  /// 加入频道，在此时，再保存加入时间、开始匹配倒计时
  Future _videoCallChannelJoin() async {
    if (_source == VideoCallSource.FAST_MATCH && remoteUid != 0) {
      // 远端用户已加入
      // 当前是匹配通话，开始匹配倒计时
      FlashChatBanner.show();
    }
    if (_videoHandler.onCallModel?.channelName == null) {
      return;
    }
    await request.videoCallChannelJoin(
      channelName: _videoHandler.onCallModel?.channelName ?? "",
      onSuccess: (data) {},
      onFail: (code, msg) {},
    );
  }

  /// 更新声网uid
  Future _userUpdateAgoraUid(int id) async {
    myUid = id;
    if (remoteUid != 0) {
      _joinTimer?.cancel();
      _videoHandler.isJoined = true;
      joinNum.trigger(-1);
    }
    _checkEstimatedHangUpTime();
    await request.userUpdateAgoraUid(
      uid: id,
      onSuccess: (bool data) {},
      onFail: (int code, String msg) {},
    );
  }

  /// 被索取礼物 - 送出礼物
  Future onGiveGiftAsk(OnGiftAskModel item, BuildContext context) async {
    if ((appConfig.userInfo.availableCoins ?? 0) < (item.content?.coinPrice ?? 0)) {
      Toast.showMsg("error_insufficientDiamonds".bhTR);
      RechargeDialog.show(entry: PayEntry.SOURCE_44, bindWidget: context);
      return;
    }

    giftAskModel = null;
    giftAskTimer?.cancel();
    giftAskTimer = null;
    update();

    await request.userGiveGift(
      channelName: _videoHandler.onCallModel?.channelName ?? "",
      giftCode: item.content?.code ?? "",
      num: 1,
      recipientUserId: userInfo?.userId ?? "",
      onSuccess: (data) {
        appConfig.saveUserInfo(appConfig.userInfo.copyWith(
          availableCoins: data,
        ));
      },
      onFail: (code, msg) {},
    );
  }

  /// 切换摄像头
  void onSwitchCamera() async {
    throttleUtil.throttle(() async {
      if (!SPUtil.containsKey(MyKeys.firstTapRearCamera)) {
        SPUtil.setBool(MyKeys.firstTapRearCamera, true);
        showRearCameraRed.value = false;
      }
      if (rearCameraModel == null) {
        _getRearCameraConfig();
        return;
      }

      // 判断用户是否是VIP
      bool isVip = appConfig.userInfo.hasEquity == true;

      // VIP用户直接使用镜头翻转功能，无需支付金币
      if (isVip || (rearCameraModel?.isOpenCamera ?? false)) {
        // VIP用户或已开通后置摄像头功能的用户
        try {
          // rtcEngine?.switchCamera();
          JSRongCloudManager.onOpenSwitchCamera();
        } catch (e) {
          logger.e("切换摄像头失败: $e");
        }
      } else {
        // 非VIP用户且未开通后置摄像头功能，需要支付金币
        DialogUtil.showDialog(
          bindPage: true,
          tag: "RearCameraOpen",
          child: ConfirmDialog(
            title: "confirm_switchToRearCamera".bhTR,
            bgColor: MyColor.black.withValues(alpha: 0.5),
            titleStyle: TextStyle(
              color: MyColor.white,
              fontSize: 8.sp,
            ),
            message: "${rearCameraModel?.openCoins ?? 0} ${"unit_diamonds".bhTR} / ${rearCameraModel?.openDay ?? 0} ${"unit_days".bhTR}",
            messageStyle: TextStyle(
              color: MyColor.themeColor,
              fontSize: 8.sp,
            ),
            onCancel: () => DialogUtil.dismiss(),
            onConfirm: () {
              DialogUtil.dismiss(tag: "RearCameraOpen");
              _onRearCameraOpen();
            },
            swap: true,
          ),
        );
      }
    }, key: "onSwitchCamera");
  }

  /// 开通摄像头
  Future _onRearCameraOpen() async {
    throttleUtil.throttle(() async {
      if ((appConfig.userInfo.availableCoins ?? 0) < (rearCameraModel?.openCoins ?? 0)) {
        // 金币不足
        Toast.showMsg("error_insufficientDiamonds".bhTR);
        RechargeDialog.show(entry: PayEntry.SOURCE_36, bindWidget: null);
        return;
        
      }

      /// 开通
      await request.rearCameraOpen(
        onSuccess: (data) {
          if (data) {
            rearCameraModel?.isOpenCamera = data;
            appConfig.saveUserInfo(
              // 本地减一次金币数
              appConfig.userInfo.copyWith(
                availableCoins: (appConfig.userInfo.availableCoins ?? 0) - (rearCameraModel?.openCoins ?? 0),
              ),
            );
            Toast.showMsg("status_successfullyOpen".bhTR);
            // 为避免错误，再掉接口刷新用户金币数
            appConfig.onGetInfo();
            // 再次切换摄像头
            onSwitchCamera();
          } else {
            Toast.showMsg("error_openingFailed".bhTR);
          }
        },
        onFail: (code, msg) {
          Toast.showMsg("error_openingFailed".bhTR);
        },
      );
    }, key: "_onRearCameraOpen");
  }

  /// 检查翻译
  void _onCheckTranslate() {
    for (int i = 0; i < messageList.length; i++) {
      OnChatModel message = messageList[i];
      if (message.translate == null && message.fromUserId == userInfo?.userId) {
        String? value = _translate.cache.get(MD5(message.content ?? ""));
        if (value != null) {
          // 拿到缓存中的翻译
          message.translate = value;
        } else {
          // 翻译
          _onTrans(message);
        }
      }
    }
  }

  /// 翻译
  void _onTrans(OnChatModel message) {
    _translate.trans(
      content: message.content ?? "",
      onSuccess: (result) {
        // 翻译后，将翻译的内容放入扩展字段
        message.translate = result;
        update();
      },
      onFail: (msg) {
        message.translate = null;
        update();
      },
    );
  }

  //是否返回匹配中
  //如果是匹配通话页
  // 1. 如果已经Jsoin 判断倒计时是否还在，如果倒计时还在，直接返回匹配页面
  // 2. 如果还没Join ，直接返回开始匹配页
  bool get isBackMatch => _source == VideoCallSource.FAST_MATCH && ((showFlachMatchDown.value && _videoHandler.isJoined) || !_videoHandler.isJoined);

  //是否否已经关闭
  bool _isClose = false;

  void onBack() {
    if (_isClose) {
      return;
    }
    userExited = true;
    //避免重复执行
    _isClose = true;
    if (Get.currentRoute == RoutePath.videoCallPage) {
      if (isBackMatch) {
        // 在跳转到匹配页面之前清除所有弹窗队列，避免评价弹窗出现
        DialogQueueUtil.to.closeAll();
        // 当前是匹配通话 && 通话时长小于20秒，则返回开始匹配页自动开始匹配，不弹任何弹窗
        bool isGoddessMatch = false;

        if (_videoHandler.onCallModel?.callCategory != null) {
          // callCategory 为 2 表示女神匹配
          isGoddessMatch = _videoHandler.onCallModel?.callCategory == 2;
          logger.i(
              "自动重新匹配: 使用callCategory=${_videoHandler.onCallModel?.callCategory}判断，isGoddessMatch=$isGoddessMatch");
        } else {
          // 如果callCategory为空，则默认为普通匹配
          logger.i("自动重新匹配: callCategory为空，默认为普通匹配");
          isGoddessMatch = false;
        }

        Get.offNamed(RoutePath.startMatchPage, arguments: {
          "matchIndex": 0, // 默认匹配索引
          "isGoddessMatch": isGoddessMatch // 保持原来的匹配类型
        });
      } else {
        //延迟500毫秒执行
        print("弹窗执行");
        Future.delayed(const Duration(milliseconds: 200), () {
          if (Get.currentRoute == RoutePath.videoCallPage) {
            Get.back();
          }
        });
      }
    }
  }

  /// 通话结束
  // Future _videoCallEnd() async {
  //   if (_videoHandler.callSource == VideoCallSource.FAST_MATCH && (_videoHandler.resultModel?.duration ?? 0) < 20) {
  //     // 当前是匹配通话 && 通话时长小于20秒，则返回开始匹配页自动开始匹配，不弹任何弹窗
  //     logger.i("匹配通话时间小于20秒拦截===> ${prettyJson(_videoHandler.resultModel?.toJson())}");
  //     _videoHandler.resetData();
  //     return;
  //   }
  //
  //   if (appConfig.userInfo.userType != 1 || appConfig.isReviewPkg.value) {
  //     // 非用户身份 或 审核模式，直接清空数据，并且不弹弹窗
  //     _videoHandler.resetData();
  //     return;
  //   }
  //   UserInfoModel userInfoModel = userInfo ?? UserInfoModel();
  //   String channelName = _onCallModel?.channelName ?? "";
  //
  //   VideoCallEndDialog().handler(
  //     userInfo: userInfoModel,
  //     channelName: channelName,
  //     resultModel: _videoHandler.resultModel,
  //   );
  //   _videoHandler.resetData();
  // }

  Future<void> _dispose() async {
    try {
      // 关闭倒计时弹窗和充值弹窗
      MinuteCountdownDialog.dismiss();
      RechargeDialog.dismiss();
      // if (BHPlatform.isAndroid) {
      //   // 移除禁止截屏录屏
      //   await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      // }
      if (kIsWeb) {
        js.context.callMethod("leaveChannel");
      } else {
        // await rtcEngine?.leaveChannel();
        // await rtcEngine?.stopPreview();
        // await rtcEngine?.release();
        // // await _videoCallEnd();
        // rtcEngine = null;
      }

      logger.d("销毁完成");
    } catch (e) {
      logger.e("退出销毁: $e");
    }
  }

  @override
  void onClose() {
    _event?.cancel();
    _appLifecycleEvent?.cancel();
    giftBannerThree?.cancel();
    giftBannerThree = null;
    giftBannerFive?.cancel();
    giftBannerFive = null;
    giftAskTimer?.cancel();
    giftAskTimer = null;
    _giveGiftSuccessEvent?.cancel();
    _availableCoinsChangeEvent?.cancel();
    _availableCoinsChangeEvent = null;
    _payResultEvent?.cancel();
    _payResultEvent = null;
    _dispose();
    super.onClose();
  }
}
