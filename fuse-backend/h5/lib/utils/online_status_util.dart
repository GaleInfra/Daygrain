import 'package:flutter/material.dart';
import 'package:untitled1/res/my_color.dart';

/// create: 2023/4/24
/// desc: 在线状态工具
class OnlineStatusUtil {
  static const String online = "Online";
  static const String busy = "Busy";
  static const String offline = "Offline";
  static const String inCall = "InCall";
  static const String available = "Available";

  /// 获取状态颜色
  static Color getColor(String status) {
    if (status == online || status == available) {
      // 在线
      return MyColor.green64FF2D;
    } else if (status == busy) {
      // 忙碌
      // return MyColor.yellowFAB96F;
      //改为统一 红色
      return MyColor.redFF0808;
    } else if (status == offline) {
      // 离线
      return MyColor.greyD6D6D6;
    } else if (status == inCall) {
      // 通话中
      return MyColor.redFF0808;
    }
    return MyColor.transparent;
  }
}
