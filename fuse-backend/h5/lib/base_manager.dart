library app_base;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/pay_handler.dart';
import 'package:untitled1/config/app_init.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/app_info_model.dart';
import 'package:untitled1/model/broadcaster/strategy_model.dart';
import 'package:untitled1/model/login/login_model.dart';
import 'package:untitled1/my_app.dart';
import 'package:untitled1/res/api_header.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/js_utils.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/utils/toast.dart';

import 'user_valid_manager.dart';
import 'config/route.dart';
import 'utils/sp_util.dart';
import 'dart:js' as js;

/// 登录成功策略进入A回调
typedef SuccessJumpToA = Future<void> Function(Map<String, dynamic>? loginResp);

/// 失败进入A回调
typedef FailJumpToA = Future<void> Function();

/// create: 2024/3/14
/// desc: App管理
class BaseManager {
  BaseManager._initial();

  static final BaseManager _instance = BaseManager._initial();

  static BaseManager get instance => _instance;

  // App信息
  late AppInfoModel appInfo;

  /// 登录/校验成功跳转
  late SuccessJumpToA successJumpToA;

  /// 二次进入校验成功
  late VoidCallback validJumpToA;

  /// token失效回调
  late VoidCallback loseCallback;

  bool get isLogin => SPUtil.getString(MyKeys.token).isNotEmpty;

  // 资源package 或 本地文件路径前缀
  String assetsPrefix = '';

  // 是否拥有多模块
  late final bool hasMoreModule;

  /// 退出登录跳过启动页，每次退出登录时都为true
  bool logoutSkipSplash = false;

  /// 登录信息
  LoginModel? loginModel;

  /// 是否正在登录
  bool _inLogin = false;

  /// 当前处于A模块
  bool currentModuleIsA = true;

  final isShowKeyboard = false.obs;

  ///是否首次注册登录
  bool isFirstRegisterLoginSuccess = true;

  /// 解析js传入的heade
  void parseJsHeader(Map<String, dynamic> logHeader) {
    if (logHeader.keys.length == 1) {
      parseJsHeader(logHeader.values.first);
    } else {
      webHeader = logHeader;
    }
  }

  /// 启动App运行
  /// iOS 端需传入设备ID以双端同步ID
  /// [appInfo] App配置信息
  /// [checkRootBuilder] A面端MyApp组件
  void runMyApp({
    required AppInfoModel appInfo,
    required SuccessJumpToA successJumpToA,
    required VoidCallback validJumpToA,
    required VoidCallback loseCallback,
    required Widget? checkRootBuilder,
  }) async {
    this.appInfo = appInfo;
    this.successJumpToA = successJumpToA;
    this.validJumpToA = validJumpToA;
    this.loseCallback = loseCallback;

    js.context["update_my_log_header"] = (u) {
      dynamic logHeader = jsToDart(u);
      if (logHeader is Map<String, dynamic>) {
        parseJsHeader(logHeader);
      }
    };
    //监听键盘显示
    js.context["onKeyBoardShow"] = (u) {
      isShowKeyboard.value = true;
      final keyboardHeight = jsToDart(u);
      if (keyboardHeight is num) {
        EventBusUtil.fire<KeyboardEvent>(
            KeyboardEvent(true, keyboardHeight.toInt()));
      } else if (keyboardHeight is String) {
        EventBusUtil.fire<KeyboardEvent>(
            KeyboardEvent(true, int.tryParse(keyboardHeight) ?? 0));
      }
    };
    //监听键盘隐藏
    js.context["onKeyBoardHide"] = (u) {
      isShowKeyboard.value = false;
      EventBusUtil.fire<KeyboardEvent>(KeyboardEvent(false, 0));
    };

    js.context["__fusePayResume"] = (u) {
      if (Get.isRegistered<PayHandler>()) {
        Get.find<PayHandler>().coinRechargeResult();
      }
    };

    js.context["onGetRecharge"] = (u) {
      JSRongCloudManager.myRecharge(
          (Get.find<AppConfigManager>().userInfo.isRecharge == true
              ? "1"
              : "0"));
    };

    //监听更新用户信息
    js.context["onUpdateUserInfo"] = (userMap, strategyMap) async {
      final strategyDic = jsToDart(strategyMap);
      if (strategyDic is Map) {
        final strategyModel = StrategyModel.fromJson(strategyDic);

        await UserValidManager.instance.setStrategyData(strategyModel);
      }
      final userDic = jsToDart(userMap);
      if (userDic is Map) {
        loginModel = LoginModel.fromJson(userDic);
        UserValidManager.instance.saveLoginModel(loginModel!);
      }
    };

    // 仅旧壳存在时才调 getUpdateMyLogHeader，避免新宿主白等回调
    if (js.context['__FUSE_LEGACY_BRIDGE__'] == true) {
      try {
        await JSRongCloudManager.getUpdateMyLogHeader(BHCallbackWeb(
                onSuccess: (u) {
                  dynamic logHeader = jsToDart(u);
                  if (logHeader is Map<String, dynamic>) {
                    parseJsHeader(logHeader);
                  }
                },
                onError: (data) {})
            .toJS());
      } catch (e) {}
    }

    //更新安全区高度
    try {
      js.context.callMethod('refreshSafeAreaHeight');
    } catch (e) {}

    await AppInit.init();
    // AFUploadUtil().init();

    if (appInfo.preLoginConfig != null) {
      await UserValidManager.instance.setPreLoginData(appInfo.preLoginConfig!);
      // final isFirstRegisterLoginSuccess = SPUtil.getBool(MyKeys.firstLoginSuccess, defaultValue: true);

      if (appInfo.preLoginConfig!.loginModel != null) {
        //只有没登录启动App时才会有
        UserValidManager.instance.saveLoginModel(appInfo.preLoginConfig!.loginModel!);
      }
    } else {
      // Block in-session silent re-login until welcome finishes the first
      // Index/C push — otherwise preRequest's getStrategy can deadlock it.
      _coldStartOpening = true;
      // 发起前置请求
      UserValidManager.instance.preRequest();
    }

    if (checkRootBuilder != null) {
      assetsPrefix = "packages/untitled1/";
    } else {
      assetsPrefix = "";
    }
    hasMoreModule = checkRootBuilder != null;

    // if (BHPlatform.isAndroid || checkRootBuilder == null) {
    runApp(const MyApp());
    // } else {
    //   runApp(RootSwitchWidget(
    //     key: switchKey,
    //     checkBuilder: () => checkRootBuilder,
    //     contentBuilder: () => const MyApp(),
    //   ));
    // }
  }

  /// 启动
  Future handleOnOpen() async {
    _coldStartOpening = true;
    try {
      if (_isHomeRoute(Get.currentRoute)) {
        return;
      }
      if (appInfo.preLoginConfig != null &&
          UserValidManager.instance.tryFastOpenFromCache()) {
        BaseManager.instance.isFirstRegisterLoginSuccess =
            SPUtil.getBool(MyKeys.firstLoginSuccess, defaultValue: true);
        await _navigateHomeAfterAuth();
        return;
      }
      if (isLogin) {
        BaseManager.instance.isFirstRegisterLoginSuccess =
            SPUtil.getBool(MyKeys.firstLoginSuccess, defaultValue: true);
        // Probe the cached token with one getStrategy call, then navigate
        // once. Do not open Index from cache. Do not await preRequest (that
        // future can be the other side of the silent-relogin deadlock).
        bool result = await UserValidManager.instance.validLogin();
        if (result) {
          await _navigateHomeAfterAuth();
        } else {
          await login(waitPreRequest: false);
        }
      } else {
        await login();
      }
    } finally {
      loginModel = null;
      if (_isHomeRoute(Get.currentRoute)) {
        _coldStartOpening = false;
      }
    }
  }

  /// 登录
  /// [force] timeout fallback: ignore the _inLogin guard (the in-flight
  /// login() may be the hung waiter).
  /// [waitPreRequest] false on the cached-token recovery path so we never
  /// wait on a preRequest that is waiting on us.
  Future login({bool force = false, bool waitPreRequest = true}) async {
    if (_isHomeRoute(Get.currentRoute)) {
      return;
    }
    if (_inLogin && !force) {
      return;
    }

    ///读取是否首次登录成功
    BaseManager.instance.isFirstRegisterLoginSuccess =
        SPUtil.getBool(MyKeys.firstLoginSuccess, defaultValue: true);
    _inLogin = true;
    try {
      bool result = await UserValidManager.instance
          .clickLogin(waitPreRequest: waitPreRequest);
      if (result) {
        await _navigateHomeAfterAuth();
      } else {
        logger.e("登录失败: ");
        Toast.showMsg("error_loginFail".bhTR);
      }
      loginModel = null;
    } catch (e) {
      logger.e("登录失败: $e");
      Toast.showMsg("error_loginFail".bhTR);
    } finally {
      _inLogin = false;
    }
  }

  bool isLoseLoginHanding = false;

  Future<bool>? _silentReloginFuture;

  bool get isSilentReloginInProgress => _silentReloginFuture != null;

  /// Welcome/handleOnOpen is still in charge of the first Index/C push.
  /// Login-lost handlers must not start a parallel silent re-login.
  bool _coldStartOpening = false;

  bool get isColdStartOpening => _coldStartOpening;

  Timer? _welcomeSafetyTimer;
  bool _welcomeSafetyArmed = false;

  /// If cold start is still on welcome after ~10s, abandon in-flight waits
  /// and oauth + navigate once.
  void armWelcomeSafetyTimeout() {
    _coldStartOpening = true;
    if (_welcomeSafetyArmed) {
      return;
    }
    _welcomeSafetyArmed = true;
    _welcomeSafetyTimer?.cancel();
    _welcomeSafetyTimer = Timer(const Duration(seconds: 10), () {
      if (_isHomeRoute(Get.currentRoute)) {
        _coldStartOpening = false;
        return;
      }
      if (Get.currentRoute != RoutePath.welcomePage) {
        return;
      }
      logger.e("welcome safety timeout — fallback login");
      login(force: true, waitPreRequest: false);
    });
  }

  bool _isHomeRoute(String route) {
    return route == RoutePath.indexPage || route == RoutePath.cPage;
  }

  Future<void> _navigateHomeAfterAuth() async {
    if (_isHomeRoute(Get.currentRoute)) {
      return;
    }
    logoutSkipSplash = false;
    final appConfig = Get.find<AppConfigManager>();
    if (!(appConfig.strategyModel?.isReviewPkg ?? true)) {
      try {
        SPUtil.setBool(MyKeys.firstLoginSuccess, false);
      } catch (e) {}
    }
    final isPrivateMode = await PrivacyModeManager.isPrivacyModeEnabled();
    if (isPrivateMode) {
      currentModuleIsA = false;
      _openHomeOnce(RoutePath.cPage);
    } else {
      currentModuleIsA = false;
      _openHomeOnce(RoutePath.indexPage);
    }
  }

  /// Open Index/C only if we are not already there (avoid a second B page).
  void _openHomeOnce(String route) {
    _welcomeSafetyTimer?.cancel();
    _coldStartOpening = false;
    if (Get.currentRoute == route) {
      return;
    }
    Get.offAllNamed(route);
  }

  /// Re-oauth without toast or navigation. Concurrent callers share one Future.
  /// Nested / in-progress callers must NOT await that Future — Dio response
  /// callbacks leave the Zone, so a getStrategy issued by clickLogin can
  /// otherwise wait on the same future that is waiting on it (welcome hang).
  Future<bool> trySilentRelogin() async {
    if (_coldStartOpening || Zone.current[#silentRelogin] == true) {
      return false;
    }
    if (_silentReloginFuture != null) {
      // In-session callers that are not on the clickLogin stack may join.
      // Login-lost recovery must not reach here while in progress (see
      // _recoverLoginLost); awaiting here from that path deadlocks.
      return _silentReloginFuture!;
    }
    // Never wait on _inLogin: login() may be blocked on a request whose
    // login-lost handler is waiting on this method.
    if (_inLogin || isLoseLoginHanding) {
      return isLogin;
    }
    isLoseLoginHanding = true;
    _silentReloginFuture = runZoned(
      () => _silentReloginBody(),
      zoneValues: {#silentRelogin: true},
    );
    try {
      return await _silentReloginFuture!;
    } finally {
      _silentReloginFuture = null;
      isLoseLoginHanding = false;
    }
  }

  Future<bool> _silentReloginBody() async {
    try {
      UserValidManager.instance.loginModel = null;
      webHeader.remove("Authorization");
      SPUtil.remove(MyKeys.token);
      return await UserValidManager.instance.clickLogin(waitPreRequest: false);
    } catch (e) {
      logger.e("静默重新登录失败: $e");
      return false;
    }
  }

  /// 登录失效
  Future loseLogin() async {
    if (isLoseLoginHanding) {
      return;
    }
    isLoseLoginHanding = true;
    try {
      logoutSkipSplash = true;
      await AppInit.beforeLogout();
      await AppInit.logout();
      webHeader.remove("Authorization");
      SPUtil.remove(MyKeys.token);
      // 开始前置请求
      if (BaseManager.instance.appInfo.sdkVersion.isEmpty) {
          await UserValidManager.instance.preRequest();
      }
    } catch (e) {
      logger.e("登录失效失败: $e");
    }
    // if (BHPlatform.isWeb) {
    //   if (Get.currentRoute != RoutePath.loginPage) {
    //     Get.offAllNamed(RoutePath.loginPage);
    //   }
    // } else if (BHPlatform.isAndroid) {
    if (Get.currentRoute != RoutePath.welcomePage) {
      Get.offAllNamed(RoutePath.welcomePage);
    }
    // } else {
    //   if (currentModuleIsA) {
    //     // A模块时直接跳转
    //     loseCallback.call();
    //   } else {
    //     // 否则切换根路由
    //     RootSwitchWidget.logout();
    //   }
    // }
    loginModel = null;
    isLoseLoginHanding = false;
  }
}
