import 'dart:developer';

import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// create: 2023/5/22
/// desc:
class JsChannel {
  JsChannel._internal();

  static final JsChannel _instance = JsChannel._internal();

  factory JsChannel() => _instance;

  /// 关闭WebView
  void newTppClose(WebViewController controller) {
    controller.addJavaScriptChannel("newTppClose",
        onMessageReceived: (JavaScriptMessage message) {
      log("newTppClose: ${message.message}");
      Get.back();
    });
  }

  /// 打开客服中心
  void openVipService(WebViewController controller) {
    controller.addJavaScriptChannel("openVipService",
        onMessageReceived: (JavaScriptMessage message) {
      log("openVipService: ${message.message}");
      String? userServiceAccountId =
          Get.find<AppConfigManager>().strategyModel?.userServiceAccountId;
      if (userServiceAccountId != null && userServiceAccountId.isNotEmpty) {
        MessageChatPage.to(UserInfoModel(userId: userServiceAccountId));
      }
    });
  }

  void newTppLogEvent(WebViewController controller) {
    controller.addJavaScriptChannel("newTppLogEvent",
        onMessageReceived: (JavaScriptMessage message) {
      log("newTppLogEvent: ${message.message}");
    });
  }

  /// 充值
  void recharge(WebViewController controller) {
    controller.addJavaScriptChannel("recharge",
        onMessageReceived: (JavaScriptMessage message) {
      log("js channel recharge: ${message.message}");
      Get.toNamed(RoutePath.coinStorePage);
    });
  }

  void rechargeSource(WebViewController controller) {
    controller.addJavaScriptChannel("rechargeSource",
        onMessageReceived: (JavaScriptMessage message) {
      log("rechargeSource: ${message.message}");
    });
  }

  Map<String, dynamic> getSupportApi() {
    Map<String, dynamic> apis = {
      "newTppClose": "newTppClose",
      "openVipService": "openVipService",
      "newTppLogEvent": "newTppLogEvent",
      "recharge": "recharge",
      "rechargeSource": "rechargeSource",
    };
    return apis;
  }
}
