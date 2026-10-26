import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';

import '../../model/skip_model.dart';
import 'widget/broadcaster_parent/view.dart';

class BroadcasterLogic extends GetBaseController {
  final GlobalKey pageKey = GlobalKey();

  /// tab标签数据
  List<BroadcasterWallTagList> tagList = [];

  /// 父级tab控制器
  late TabController tabController;

  /// 父级页面
  final pageList = <Widget>[];

  /// 父级标签
  final parentTag = "".obs;

  /// 全局配置管理
  final appConfig = Get.find<AppConfigManager>();

  /// 商品/促销商品管理
  final coinGoodsLogic = Get.find<CoinGoodsLogic>();

  // 其他类型通知
  late StreamSubscription<OtherEvent> _otherEvent;

  // 子级tabBarView 索引
  int _listIndex = 0;

  // 是否显示国家筛选器
  final RxBool showCountry = true.obs;

  // 当前选中的国家图标
  final RxString countryEmoji = "".obs;

  final RxString countryCode = "".obs;

  @override
  void onInit() {

    tagList.addAll(appConfig.strategyModel?.broadcasterWallTagList ?? []);
    // 选择默认标签
    parentTag.value = tagList.first.tagName ?? "";
    // 创建子级
    for (var item in tagList) {
      pageList.add(BroadcasterParentComponent(
        key: ValueKey("${item.tagName ?? ""}_BroadcasterParentComponent"),
        item: item,
      ));
    }
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.broadcasterIndex == event.type) {
        _listIndex = event.data;
        showCountry.trigger(0 == _listIndex && 0 == tabController.index);
        logHandle.initLog('wall',subPage: parentTag.value,terPage: tagList[tabController.index].subTagList![_listIndex],isUploadLog: false);
        appConfig.wallParentTag = parentTag.value;
        appConfig.walSubTag = tagList[tabController.index].subTagList![_listIndex];
        update();
      }
    });
    changeSuccess();
    appConfig.wallParentTag = parentTag.value;
    appConfig.walSubTag = tagList[0].subTagList?.first ?? '';

    super.onInit();
  }

  /// 初始化父级tab控制器
  void initParentTab(TabController parent) {
    tabController = parent;
    tabController.animation?.addListener(_parentControllerListener);
  }

  /// 父级tab控制器监听
  void _parentControllerListener() {
    int index = (tabController.animation?.value ?? 0).round();
    if (tagList[index].tagName != parentTag.value) {
      parentTag.value = tagList[index].tagName ?? "";
      var subIndex = _listIndex;
      if (0 != index) {
        subIndex = 0;
      }
      logHandle.initLog('wall',subPage: parentTag.value,terPage: tagList[index].subTagList![subIndex],isUploadLog: false);
      showCountry.trigger(0 == _listIndex && 0 == index);
      appConfig.wallParentTag = parentTag.value;
      appConfig.walSubTag = tagList[index].subTagList![subIndex];
      update();
    }
  }

  void onChangeCountryEmoji(String emoji, String code) {
    EventBusUtil.fire(OtherEvent(type: OtherType.broadcasterCountry, data: code));
    countryEmoji.trigger(emoji);
    countryCode.trigger(code);
  }

  @override
  void onClose() {
    tabController.animation?.removeListener(_parentControllerListener);
    _otherEvent.cancel();
    logHandle.onClose();
    super.onClose();
  }
}
