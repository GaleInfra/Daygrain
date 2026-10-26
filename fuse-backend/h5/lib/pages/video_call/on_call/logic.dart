import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/widget/dialog/on_call_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../common_logic/app_config_manager.dart';
import '../../../config/route.dart';
import '../../../res/video_call_data.dart';
import '../../../widget/dialog/recharge_dialog.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/language/bh_language_manager.dart';

class OnCallLogic extends GetBaseController {
  StreamSubscription<VideoCallEvent>? _event;

  final videoCallHandler = Get.find<VideoCallHandler>();

  @override
  void onInit() {
    super.onInit();
    logHandle.initLog('in_call');
    _initEvent();
    OnCallDialog.dismiss();

    //防止上一个调用了息屏
    Future.delayed(const Duration(seconds: 2), () async {
      if (Get.isRegistered<VideoCallHandler>()) {
        if (Get.find<VideoCallHandler>().onCallModel != null) {
          WakelockPlus.enable();
        }
      }
    });
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    //如果当前已经被挂断并且还在被呼叫页面则关闭
    if (videoCallHandler.onCallModel == null) {
      if (Get.currentRoute == RoutePath.onCallPage) {
        Get.back();
      }
    }
  }

  /// 初始化event监听
  void _initEvent() {
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (event.command == SocketCommandKey.onHangUpComplete) {
        onBack();
      }
    });
  }

  /// 挂断
  void onHangUp() async {
    throttleUtil.throttle(() async {
      onBack();
      videoCallHandler.hangUp(
        onSuccess: (data) {},
        onFail: (code, msg) {},
      );
    }, key: "on_call_onHangUp");
  }

  /// 接通
  void onPickUp() async {
    //判断是否vip
    if (!(Get.findCanNull<AppConfigManager>()?.userInfo.hasEquity ?? false)) {
      //弹窗vip弹窗
      VipPrivilegesSheet.show();
      return;
    }
    if (videoCallHandler.onCallModel?.channelName?.startsWith("im_trigger_call_") ?? false) {
      Toast.showMsg("not_enough_money".bhTR);
      RechargeDialog.show(entry: PayEntry.SOURCE_62, bindWidget: null);
      return;
    }
    try {
      await checkCameraAndMicrophonePermission(showDialog: true, isAwait: true);
    } catch (e) {
      //点击获取权限则中断流程
      return;
    }
    throttleUtil.throttle(() async {
      await videoCallHandler.onPickUp();
    }, key: "on_call_onPickUp");
  }

  /// 回退到上一页
  /// [hangUp] 是否挂断
  void onBack({bool hangUp = true}) {
    if (!hangUp) {
      // 未挂断，重新显示弹窗
      OnCallDialog.show();
    }
    //关闭充值弹窗
    RechargeDialog.dismiss();
    if (Get.currentRoute == RoutePath.onCallPage) {
      // 为当前页，退出
      Get.back();
    } else {
      //正在三方支付
      Get.removeRouteByName(RoutePath.onCallPage);
    }
  }

  @override
  void onClose() {
    _event?.cancel();
    super.onClose();
  }
}
