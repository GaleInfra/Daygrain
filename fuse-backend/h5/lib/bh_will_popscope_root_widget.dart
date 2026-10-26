import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/toast.dart';

class BHWillPopScopeRootWidget extends StatefulWidget {
  const BHWillPopScopeRootWidget({super.key, required this.child, this.isRootRoute = false});

  final Widget child;
  final bool isRootRoute; // 新增一个标识，标记当前页面是否为根目录

  @override
  State<BHWillPopScopeRootWidget> createState() => _WillPopScopeRouteState();
}

class _WillPopScopeRouteState extends State<BHWillPopScopeRootWidget> {
  DateTime? _lastClick; //上次点击时间

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return widget.child;
    }

    if (!widget.isRootRoute) {
      // 如果不是根目录直接返回子Widget
      return widget.child;
    }
    // 剩下的逻辑与之前相同
    return WillPopScope(
      onWillPop: () async {
        //通话中不给返回
        if (Get.isRegistered<VideoCallHandler>()) {
          if (Get.find<VideoCallHandler>().onCallModel != null) {
            return Future.value(false);
          }
        }
        if (_lastClick == null) {
          //第一次点击不给返回
          _lastClick = DateTime.now();
          Toast.showMsg(
            "action_clickAgainToExit".bhTR,
          );
          return Future.value(false);
        }
        if (DateTime.now().difference(_lastClick!) > const Duration(seconds: 1)) {
          _lastClick = DateTime.now();
          Toast.showMsg(
            "action_clickAgainToExit".bhTR,
          );
          return Future.value(false);
        }
        _lastClick = null;
        return Future.value(true);
      },
      child: widget.child,
    );
  }
}
