import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/pay_handler.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/app_init.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/js_utils.dart';
import 'package:untitled1/utils/socket_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/throttle_util.dart';

import 'config/app_theme.dart';
import 'res/constant.dart';
import 'widget/toast_widget.dart';
import 'dart:js' as js;

AppLifecycleState? myAppLifecycleState;
/// create: 2023/4/21
/// desc:
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late StreamSubscription<ConnectivityResult> subscription;
  final _request = Get.find<RequestRepository>();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this); // 添加观察者
    // 网络状态监听
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      AppInit.onConnectivityChanged(result);
    });

    if (BHPlatform.isWeb) {
      js.context["onLifecycleState"] = (u) {
        dynamic logHeader = jsToDart(u);
        if (logHeader is String) {
          if (logHeader == "resumed") {
            doChangeAppLifecycleState(AppLifecycleState.resumed);
          } else if (logHeader == "paused") {
            doChangeAppLifecycleState(AppLifecycleState.paused);
          }
        }
      };
    }

    super.initState();
  }

  void doChangeAppLifecycleState(AppLifecycleState state) {
    // Web: index.html 按页面可见性发 resumed/paused，同状态不重复处理。
    if (BHPlatform.isWeb && state == myAppLifecycleState) {
      return;
    }
    /// 发送前后台切换通知
    EventBusUtil.fire<AppLifecycleStateEvent>(AppLifecycleStateEvent(state));
    myAppLifecycleState = state;
    logger.d("AppLifecycleState:111 $myAppLifecycleState");
    if (state == AppLifecycleState.paused) {
      // 退后台立即上报 mode:1，不等 500ms 节流；iOS WKWebView 进后台后 JS 很快被挂起。
      throttleUtil.cancel("app_lifecycle_state_change");
      _onAppPausedNow();
      return;
    }
    //防抖
    throttleUtil.throttle(() async {}, key: "app_lifecycle_state_change",
        onAfter: () async {
      //判断是否登录状态
      if (!BaseManager.instance.isLogin) {
        //没有登录不执行
        return;
      }
      //打印log
      logger.d("AppLifecycleState: $myAppLifecycleState");
      if (myAppLifecycleState == AppLifecycleState.resumed) {
        // 应用程序从后台切换到前台
        _request.userModeSwitch(mode: 0);
        //尝试重连长链接
        SocketUtil().reconnect();
        SocketUtil().startTimer();
        if (SPUtil.containsKey(MyKeys.jumpExternalRecharge)) {
          // 判断是否充值跳外部后重新回来
          SPUtil.remove(MyKeys.jumpExternalRecharge);
          Get.find<PayHandler>().listenRecharge();
        }
        Future.delayed(const Duration(seconds: 1), () {
          Get.find<PayHandler>().coinRechargeResult();
        });

      }
    }, time: 500);
  }

  void _onAppPausedNow() {
    if (!BaseManager.instance.isLogin) {
      return;
    }
    logger.d("AppLifecycleState: $myAppLifecycleState");
    // 应用程序从前台切换到后台(包括息屏)
    _request.userModeSwitch(mode: 1);
    //停止心跳
    SocketUtil().onClose();
    SocketUtil().stopTimer();
    //停止被呼叫音乐播放
    if (Get.isRegistered<VideoCallHandler>()) {
      Get.find<VideoCallHandler>().onShopCallPlayer();
    }
  }

  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!BHPlatform.isWeb) {
      doChangeAppLifecycleState(state);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除观察者
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(188, 406),
      minTextAdapt: false,
      splitScreenMode: true,
      builder: (ctx, child) {
        return GetMaterialApp(
          title: Constant.appName,
          debugShowCheckedModeBanner: false,
          theme: getThemeData(),
          getPages: Routes.routePages,
          initialRoute: BaseManager.instance.hasMoreModule
              ? RoutePath.indexPage
              : RoutePath.welcomePage,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          navigatorObservers: [
            FlutterSmartDialog.observer,
            routeObserver,
          ],
          supportedLocales: const [
            Locale("en", "US"),
          ],
          builder: FlutterSmartDialog.init(
            toastBuilder: (msg) => ToastWidget(msg: msg),
            builder: (ctx, child) {
              return Obx(
                () => Listener(
                  onPointerDown: (event) async {
                    //判断当前是否正在被呼叫
                    //当前正在被呼叫
                    if (Get.isRegistered<VideoCallHandler>() && Get.find<VideoCallHandler>().onCallModel != null) {
                      //判断当前是否是自己
                      final videoCallHandler = Get.find<VideoCallHandler>();
                      //当前是自己
                      if (videoCallHandler.onCallModel?.toUserIdStr == AppConfigManager.userInfoModel.userId) {
                        if (videoCallHandler.player != null && videoCallHandler.isCanTouchPlay) {
                          //如果是自己，但是没有播放视频，那么就播放视频
                          videoCallHandler.rePlay();
                          videoCallHandler.isCanTouchPlay = false;
                        }
                      }
                    }
                  },
                  child: Directionality(
                    textDirection: BHLanguageMar().isRightToLeft.value
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: MediaQuery(
                      //设置文字大小不随系统设置改变
                      data: MediaQuery.of(ctx).copyWith(textScaler: const TextScaler.linear(1.0)),
                      child: Scaffold(
                        body: TextSelectionTheme(
                          data: TextSelectionThemeData(
                            cursorColor: Get.theme.primaryColor, //输入框光标颜色
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // //点击空白收起键盘
                              // FocusScopeNode currentFocus = FocusScope.of(ctx);
                              // if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
                              //   FocusManager.instance.primaryFocus?.unfocus();
                              // }
                            },
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
