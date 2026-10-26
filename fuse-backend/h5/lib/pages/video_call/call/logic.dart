import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../model/video_call/pick_up_model.dart';
import '../../../res/video_call_data.dart';

class CallLogic extends GetBaseController {
  /// 十秒呼叫超时定时器
  Timer? _tenTimer;

  /// 30秒呼叫超时定时器
  Timer? _thirtyTimer;

  StreamSubscription<VideoCallEvent>? _event;

  final appConfig = Get.find<AppConfigManager>();

  final videoCallHandler = Get.find<VideoCallHandler>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    logHandle.initLog('out_call');
    WakelockPlus.enable();
  }

  @override
  void onReady() {
    if (appConfig.isReviewPkg.value) {
      // 审核模式下，直接不给进
      Future.delayed(const Duration(seconds: 1), () {
        Toast.showMsg("error_userIsBusy".bhTR);
        _onBack();
      });
    } else {
      _onInitEvent();
      channelCreate();
    }
    super.onReady();
  }

  void _onInitEvent() {
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (event.command == SocketCommandKey.onHangUpComplete) {
        try {
          debugPrint("挂断频道成功: ${event.data.channelName}");
        } catch (e) {
          debugPrint("挂断频道失败: $e");
        }
        // 被挂断，关闭当前页

        Toast.showMsg("error_userNotAvailable".bhTR);
        // 加一层判断，判断是否当前通话
        if (Get.isRegistered<VideoCallHandler>()) {
          //来到这里，说明这个页面即将销毁但接收到了事件
          //判断频道id是否一致再允许是否返回
          bool isNowChannel = ((videoCallHandler.onCallModel?.channelName) ?? "") == event.data.channelName;
          if (isNowChannel) {
            if (Get.currentRoute == RoutePath.onCallPage || Get.currentRoute == RoutePath.callPage) {
              //重重难关才允许返回
              //1. 呼叫数据中是当前频道
              //2.当前还在呼叫或者被呼叫页
              _onBack();
            }
          } else if (videoCallHandler.onCallModel?.channelName == null) {
            //不在通话中了也返回
            _onBack();
          }
        }
      } else if (event.command == SocketCommandKey.onPickUp) {
        if (userExited) {
          return;
        }
        PickUpModel model = event.data;
        if (model.channelName == videoCallHandler.onCallModel?.channelName) {
          // 被接通
          Get.offNamed(RoutePath.videoCallPage);
        }
      }
    });
  }

  final unitPrice = 0.obs;

  /// 创建频道
  void channelCreate() async {
    _onCreateTimer();
    final toUserId = videoCallHandler.userInfo?.userId?.toString() ?? "";
    videoCallHandler.onCreateChannel(
      onSuccess: (data) {
        if (userExited) {
          //页面已经退出 无需处理
        } else {
          //刷新页面更新金币
          unitPrice.value = videoCallHandler.onCallModel?.unitPrice ?? 0;
        }
      },
      onFail: (code, msg) {
        // 不需要额外处理，方法里已处理
        //添加路由返回
        _onBack();
      },
    );
  }

  /// 创建呼叫倒计时
  void _onCreateTimer() async {
    _tenTimer = Timer(const Duration(seconds: 10), () {
      if (Get.currentRoute == RoutePath.onCallPage || Get.currentRoute == RoutePath.callPage) {
        Toast.showMsg(
          "error_userPhoneUnattended".bhTR,
          displayTime: const Duration(seconds: 5),
          alignment: Alignment.center,
        );
      }
      _tenTimer?.cancel();
      _tenTimer = null;
    });
    _thirtyTimer = Timer(const Duration(seconds: 30), () {
      if (Get.currentRoute == RoutePath.onCallPage || Get.currentRoute == RoutePath.callPage) {
        Toast.showMsg(
          "error_userNotAvailable".bhTR,
          displayTime: const Duration(seconds: 5),
          alignment: Alignment.center,
        );
        // 挂断
        hangUp(handUpReason: HandUpReason.CL_CALL_TIMEOUT);
      }
      _thirtyTimer?.cancel();
      _thirtyTimer = null;
    });
  }

  bool userExited = false;

  /// 挂断
  void hangUp({int handUpReason = HandUpReason.NORMAL}) async {
    userExited = true;
    throttleUtil.throttle(() async {
      if (videoCallHandler.onCallModel == null && handUpReason != HandUpReason.CL_CALL_TIMEOUT) {
        // 频道未创建成功 && 非超时挂断，不给退出
        // 超时挂断一定要保证退出，即使频道为创建成功
        _onBack();
        return;
      }
      _onBack();
      videoCallHandler.hangUp(
        handUpReason: handUpReason,
        onSuccess: (data) {},
        onFail: (code, msg) {},
      );
    }, key: "hangUp");
  }

  /// 回退到上一页
  void _onBack() {
    if (Get.currentRoute == RoutePath.callPage) {
      // 为当前页，退出
      Get.back();
    }
  }

  @override
  void onClose() {
    _event?.cancel();
    _tenTimer?.cancel();
    _tenTimer = null;
    _thirtyTimer?.cancel();
    _thirtyTimer = null;
    if (!kIsWeb) WakelockPlus.disable();
    super.onClose();
  }
}
