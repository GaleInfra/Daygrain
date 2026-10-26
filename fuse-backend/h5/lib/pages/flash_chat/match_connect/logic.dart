import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/on_call_model.dart';
import 'package:untitled1/res/video_call_data.dart';

import '../../../common_logic/video_call_handler.dart';
import '../../../event_bus/video_call/video_call_event.dart';
import '../../../model/video_call/hang_up_model.dart';

class MatchConnectLogic extends GetBaseController {
  GlobalKey pagKey = GlobalKey();

  /// 主播数据
  UserInfoModel? userInfo;

  /// 是否匹配成功
  bool matchSuccess = false;

  /// 跳转定时器
  Timer? timer;

  /// 通话监听
  StreamSubscription<VideoCallEvent>? _event;

  /// 是否显示金币不足
  final RxBool showNotEnough = false.obs;

  OnCallModel? onCallModel;

  final _videoHandler = Get.find<VideoCallHandler>();

  @override
  void onReady() {
    onCallModel = _videoHandler.onCallModel;
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (event.command == SocketCommandKey.onHangUpComplete) {
        // 被挂断
        HangUpModel model = event.data;
        if (onCallModel?.channelName == model.channelName) {
          // 当处理中心的通话数据不为空时，说明已有主播接通但是又马上关闭了，此时取消跳转并关闭页面
          timer?.cancel();
          _videoHandler.resetData();
          Get.back();
        }
      }
    });
    Map<String,dynamic> map = Get.arguments;
    if (map.containsKey("userInfo")) {
      userInfo = map['userInfo'];
    }
    if (map.containsKey("matchSuccess")) {
      matchSuccess = map['matchSuccess'];
    }
    update();
    if (matchSuccess) {
      timer?.cancel();
      timer = Timer(const Duration(seconds: 2), () {
        Get.offNamed(RoutePath.videoCallPage);
      });
    } else {
      showNotEnough.trigger(true);
    }
    super.onReady();
  }

  /// 主动退出页面  匹配链接页无法主动退出
  // void onBack() {
  //   timer?.cancel();
  //   // 主动退出页面调用挂断通话，避免用户退出匹配了，主播却接通
  //   _videoHandler.hangUp(
  //     onSuccess: (data) {},
  //     onFail: (code, msg) {},
  //     saveCall: false,
  //   ).then((value) {
  //     Get.back();
  //     _videoHandler.resetData();
  //   });
  // }

  @override
  void onClose() {
    _event?.cancel();
    timer?.cancel();
    super.onClose();
  }
}
