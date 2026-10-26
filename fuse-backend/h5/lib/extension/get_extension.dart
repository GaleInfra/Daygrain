import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../base_manager.dart';
import '../config/route.dart';
import '../config/route_observer.dart';
import '../pages/index/logic.dart';

extension GetExt on GetInterface {
  ///路由历史
  List<Route<dynamic>> get history => routeObserver.routes;

  ///根据名称获取路由
  Route<dynamic>? getRouteByName(String name) {
    var index = history.lastIndexWhere((element) => element.settings.name == name);
    if (index != -1) {
      return history[index];
    }
    return null;
  }

  //根据名称获取路由列表
  List<Route<dynamic>> getRoutesByName(String name) {
    return routeObserver.routes.where((element) => element.settings.name == name).toList();
  }

  //根据名称移除路由
  void removeRouteByName(String name) {
    var index = history.lastIndexWhere((element) => element.settings.name == name);
    if (index != -1) {
      Get.removeRoute(history[index]);
    }
  }

  //回退到主页
  void goHome() {
    Get.until((route) => route.settings.name == RoutePath.indexPage);
    //显示主播墙页面
    //【只有登录状态才能进入】
    if (BaseManager.instance.isLogin) {
      if (Get.isRegistered<IndexLogic>()) {
        //切换到主页
        Get.find<IndexLogic>().onChangeIndex(0);
      }
    }
  }

  //回退到主页
  void reloadHome() {
    Get.until((route) => route.settings.name == RoutePath.indexPage);
    //显示主播墙页面
    //【只有登录状态才能进入】
    if (BaseManager.instance.isLogin) {
      if (Get.isRegistered<IndexLogic>()) {
        //切换到主页
        Get.find<IndexLogic>().onChangeIndex(0);
      }
    }
  }

  //获取Controller
  T? findCanNull<T extends GetxController>() {
    return Get.isRegistered<T>() ? Get.find<T>() : null;
  }
}
