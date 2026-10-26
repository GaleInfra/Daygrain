import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/net/request_repository.dart';

import 'PageEvent.dart';



class LogHandle {
  late RequestRepository request;
  DateTime? inTime;

  String pageEvent = '';
  String subPage = '';
  String terPage = '';
  bool isUploadLog = false;
  bool isHaveLoad = false;
  AppConfigManager? appConfigManager;
  bool isInit = false;
  late StreamSubscription<PageEvent> _pageEvent;
  initEvent(){
    request = Get.find<RequestRepository>();
    if (Get.isRegistered<AppConfigManager>()) {
      appConfigManager = Get.find<AppConfigManager>();
    }
    // request.addCancelTokenListener(runtimeType.toString(), tag: tag);
    // ever(Get.routing, (route) {
    //   print("当前路由: ${Get.currentRoute}");
    //   // 在这里执行相关操作
    // });
    isInit = true;
    _pageEvent = EventBusUtil.listen<PageEvent>((event) {
      if (appConfigManager == null) {
        return;
      }
      if (event.type == 0) {
        if (appConfigManager!.logPageEventList.isNotEmpty && 
            appConfigManager!.logPageEventList.last == (pageEvent + subPage + terPage)) {
          uploadLog();
        }
      }else if (event.type == 1) {
        if (appConfigManager!.logPageEventList.isNotEmpty && 
            appConfigManager!.logPageEventList.last == (pageEvent + subPage + terPage)) {
          initLog(pageEvent, subPage: subPage, terPage: terPage,isEvent: false);
        }
      }else if (event.type == 2) {
        if (event.pageEvent.isNotEmpty && event.pageEvent == (pageEvent + subPage + terPage)) {
          uploadLog();
        }
      }
    });
  }

  void onClose() {
    List<String> logPageEventList = appConfigManager?.logPageEventList ?? [];
    for (int i = 0; i < logPageEventList.length; i++) {
      if (logPageEventList[i] == (pageEvent + subPage + terPage)) {
        logPageEventList.removeAt(i);
        break;
      }
    }
    appConfigManager?.logPageEventList = logPageEventList;
    if (isUploadLog && !isHaveLoad) {
      uploadLog();
      EventBusUtil.fire(PageEvent(type: 1, pageEvent: (pageEvent + subPage + terPage)));
    }
  }
  void nextUploadLog(String page, {String subPage = '', String terPage = ''}) {
    EventBusUtil.fire(PageEvent(type: 2, pageEvent: (page + subPage + terPage)));
  }

  void initLog(String page, {String subPage = '', String terPage = '',bool isUploadLog = true,bool isEvent = true}) {
    if (!isInit) {
      initEvent();
    }
    if (isEvent) {
      EventBusUtil.fire(PageEvent(type: 0, pageEvent: (pageEvent + this.subPage + this.terPage)));
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      pageEvent = page;
      this.subPage = subPage;
      this.terPage = terPage;
      this.isUploadLog = isUploadLog;
      isHaveLoad = false;
      inTime = DateTime.now();
      // appConfigManager?.logLastPageEvent = appConfigManager?.logPageEvent ?? '';
      if (appConfigManager == null) {
        if (Get.isRegistered<AppConfigManager>()) {
          appConfigManager = Get.find<AppConfigManager>();
        }
      }
      if (appConfigManager != null) {
        appConfigManager?.logPageEvent = (pageEvent + subPage + terPage);
        if (appConfigManager!.logPageEventList.isNotEmpty) {
          List<String> logPageEventList = appConfigManager?.logPageEventList ?? [];
          for (int i = 0; i < logPageEventList.length; i++) {
            if (logPageEventList[i] == (pageEvent + subPage + terPage)) {
              logPageEventList.removeAt(i);
            }
          }
          appConfigManager?.logPageEventList = logPageEventList;
        }
        if (appConfigManager?.logPageEventList != null) {
          appConfigManager?.logPageEventList.add((pageEvent + subPage + terPage));
        }
      }
    });



  }

  void uploadLog() {

    if (pageEvent.isNotEmpty && !isHaveLoad) {
      isHaveLoad = true;
      int duration = DateTime.now().difference(inTime!).inMilliseconds;
      request.log(event: "pv", page: pageEvent, subPage: subPage, terPage: terPage,duration: duration);
    }

  }

}