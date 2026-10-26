import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';

import '../../../../model/skip_model.dart';
import 'broadcaster_list/view.dart';

class BroadcasterParentLogic extends GetxController {
  /// 该tab的数据
  late BroadcasterWallTagList tagItem;
  LogHandle logHandle = LogHandle();
  /// 所选子级标签
  String? childTag;

  /// 页面列表
  final pageList = <Widget>[];

  final RxInt index = 0.obs;

  // 是否显示国家筛选器
  final RxBool showCountry = true.obs;
  // 当前选中的国家图标
  final RxString countryEmoji = "".obs;

  final RxString countryCode = "".obs;

  // 其他类型通知
  late StreamSubscription<OtherEvent> _otherEvent;

  // 子级tabBarView 索引
  int _listIndex = 0;

  init() {
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.broadcasterIndex == event.type) {
        _listIndex = event.data;
        showCountry.trigger(0 == _listIndex && 0 == index.value);
      }
    });
  }
  /// 初始化数据
  initData(BroadcasterWallTagList item) {
    tagItem = item;

    for (var value in tagItem.subTagList!) {
      pageList.add(BroadcasterListComment(key: ValueKey("${tagItem.tagName!}_$value"), category: tagItem.tagName!, tag: value));
    }
  }

  void onIndexChanged(int i) {
    index.value = i;
    showCountry.trigger(0 == _listIndex && 0 == index.value);

    update();
  }

  void onChangeCountryEmoji(String emoji, String code) {
    EventBusUtil.fire(
        OtherEvent(type: OtherType.broadcasterCountry, data: code));
    countryEmoji.trigger(emoji);
    countryCode.trigger(code);
  }
  @override
  void onClose() {
    _otherEvent.cancel();
    super.onClose();
  }
}
