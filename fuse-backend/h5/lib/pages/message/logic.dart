import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';

import 'calls_list/view.dart';
import 'follow_list/view.dart';
import 'message_list/view.dart';

class MessageLogic extends GetxController with GetSingleTickerProviderStateMixin {
  final tagList = ["label_messages", "label_calls", "label_followed"];
  final List<Widget> pages = [
    const MessageListWidget(),
    const CallsListWidget(),
    const FollowListWidget(),
  ];
  final appConfig = Get.find<AppConfigManager>();
  late TabController tabController;
  final RxInt index = 0.obs;
  LogHandle logHandle = LogHandle();
  @override
  void onInit() {
    tabController = TabController(length: tagList.length,animationDuration: Duration.zero, vsync: this);
    tabController.animation?.addListener(_onTabChange);
    String tag = "message";
    if (index.value == 0) {
      tag = "message";
    }else if (index.value == 1) {
      tag = "calls";
    }else {
      tag = "followed";
    }
    appConfig.imTag = tag;
    super.onInit();
  }

  @override
  void onClose() {
    tabController.animation?.removeListener(_onTabChange);
    logHandle.onClose();
    super.onClose();
  }

  void _onTabChange() {
    int i = (tabController.animation?.value ?? 0).round();

    if (i != index.value) {
      index.trigger(i);
      String tag = "message";
      if (index.value == 0) {
        tag = "message";
      }else if (index.value == 1) {
        tag = "calls";
      }else {
        tag = "followed";
      }
      appConfig.imTag = tag;

      logHandle.initLog('im',subPage: appConfig.imTag);
    }

  }
}
