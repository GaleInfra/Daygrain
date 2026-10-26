import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/model/app_config_model.dart';
import 'package:untitled1/model/app_info_model.dart';
import 'package:untitled1/model/broadcaster/strategy_model.dart';
import 'package:untitled1/model/login/login_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/rong_cloud/rc_manager.dart';
import 'package:untitled1/translate/translate_manager.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/risk_util.dart';
import 'package:untitled1/utils/socket_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import 'common_logic/user_status_service.dart';
import 'database/controller/video_call_contoller.dart';
import 'common_logic/banner_strong_guide_logic.dart';
import 'common_logic/coin_goods_logic.dart';
import 'common_logic/pay_handler.dart';
import 'business/say_hi/robot_script_manager.dart';
import 'common_logic/video_call_handler.dart';
import 'common_logic/vip_manager.dart';
import 'dart:js' as js;

/// create: 2024/1/17
/// desc: 用户身份校验工具
class UserValidManager {
  UserValidManager._internal();
  static final UserValidManager _instance = UserValidManager._internal();
  static UserValidManager get instance => _instance;
  factory UserValidManager() => _instance;

  final RequestRepository _request = Get.find<RequestRepository>();
  final AppConfigManager _appManager = Get.find<AppConfigManager>();

  LoginModel? _loginModel;
  StrategyModel? _strategyModel;

  // 为避免前置请求在用户主动请求后返回数据导致token失效，在用户点击登录前取消前置请求
  CancelToken? _cancelToken;

  ///获取登录数据
  LoginModel? get loginModel => _loginModel;

  set loginModel(LoginModel? model) {
    _loginModel = model;
  }

  //设置预登陆数据
  Future<void> setPreLoginData(PreLoginConfig preLoginConfig) async {
    //如有有原生传入的登录配置
    //初始化AppConfig 数据
    _appManager.onSaveAppConfig(preLoginConfig.appConfigModel);

    await _appManager.onGetStrategy(model: preLoginConfig.strategyModel);
    _strategyModel = preLoginConfig.strategyModel;

    _loginModel = preLoginConfig.loginModel;
  }

  //配置策略数据
  Future<void> setStrategyData(StrategyModel strategyModel) async {
    await _appManager.onGetStrategy(model: strategyModel);
    _strategyModel = strategyModel;
  }

  Future<void>? _preRequestFuture;

  /// 前置请求（单飞：与启动自动登录共用同一轮请求，避免取消在途 /login）
  Future preRequest() {
    return _preRequestFuture ??= _runPreRequest().whenComplete(() {
      _preRequestFuture = null;
    });
  }

  /// 若本地已缓存 token + AppConfig + Strategy，则立即同步初始化首页所需服务，零网络等待直接进主播墙；后台再静默刷新。
  bool tryFastOpenFromCache() {
    final token = SPUtil.getString(MyKeys.token);
    final appConfigStr = SPUtil.getString(MyKeys.appConfig);
    final strategyStr = SPUtil.getString('cached_strategy_v1');
    if (token.isEmpty || appConfigStr.isEmpty || strategyStr.isEmpty) {
      return false;
    }
    try {
      _appManager.appConfigModel ??= AppConfigModel.fromJson(jsonDecode(appConfigStr));
      _appManager.appConfigReady = true;
      _appManager.strategyModel ??= StrategyModel.fromJson(jsonDecode(strategyStr));
      _strategyModel = _appManager.strategyModel;
      if (!Get.isRegistered<TranslateManager>()) {
        Get.put(TranslateManager(), permanent: true);
      }
      if (!Get.isRegistered<BannerStrongGuideLogic>()) {
        Get.put(BannerStrongGuideLogic(), permanent: true);
      }
      if (!Get.isRegistered<RCManager>()) {
        final rcLogic = Get.put<RCManager>(RCManager(), permanent: true);
        rcLogic.initEnter();
      }
      if (!Get.isRegistered<VideoCallController>()) {
        Get.put<VideoCallController>(VideoCallController(), permanent: true);
      }
      if (!Get.isRegistered<VipManager>()) {
        Get.put<VipManager>(VipManager(), permanent: true);
      }
      if (!Get.isRegistered<PayHandler>()) {
        Get.put<PayHandler>(PayHandler(), permanent: true);
      }
      if (!Get.isRegistered<CoinGoodsLogic>()) {
        Get.put<CoinGoodsLogic>(CoinGoodsLogic(), permanent: true);
      }
      if (!Get.isRegistered<VideoCallHandler>()) {
        Get.put<VideoCallHandler>(VideoCallHandler(), permanent: true).init();
      }
      if (!Get.isRegistered<UserStatusService>()) {
        Get.put<UserStatusService>(UserStatusService(), permanent: true);
      }
      if (!Get.isRegistered<RobotScriptManager>()) {
        Get.put<RobotScriptManager>(RobotScriptManager(), permanent: true);
      }
      SocketUtil().init();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _dropMismatchedDeviceToken() {
    final bound = SPUtil.getString('bound_device_id');
    final current = DeviceUtil().deviceId;
    if (bound.isNotEmpty && current.isNotEmpty && bound != current) {
      SPUtil.remove(MyKeys.token);
      SPUtil.remove('bound_device_id');
      _loginModel = null;
    }
  }

  Future<void> _runPreRequest() async {
    try {
      _dropMismatchedDeviceToken();
      RiskUtil.instance.getSIMInfo();
      await RiskUtil.instance.simCompleter?.future;
      _appManager.appConfigReady = false;
      if (SPUtil.containsKey(MyKeys.token)) {
        // 已登录，并行获取AppConfig 和 策略
        await Future.wait([
          _appManager.onGetAppConfig(),
          _appManager.onGetStrategy(),
        ]);
        _strategyModel = _appManager.strategyModel;
      } else {
        // 未登录，先获取AppConfig，再执行登录流程
        await _appManager.onGetAppConfig();
        if (_appManager.appConfigReady == true) {
          // 未登录执行登录
          _cancelToken = CancelToken();
          String riskInfo = "";
          // if (kReleaseMode) {
          riskInfo = await RiskUtil.instance.infoEncrypt(null, true) ?? "";
          // }
          await _request.login(
            deviceId: DeviceUtil().deviceId,
            riskInfo: riskInfo,
            cancelToken: _cancelToken,
            onSuccess: (data) {
              _loginModel = data;
            },
            onFail: (code, msg) {},
          );
          if (_loginModel != null) {
            // 获取策略
            await _request.getStrategy(
              token: _loginModel?.token,
              cancelToken: _cancelToken,
              onSuccess: (data) async {
                _strategyModel = data;
              },
              onFail: (code, msg) {},
            );
          }
        }
      }
    } catch (e) {
      logger.e("前置请求错误: $e");
    }
  }

  /// 点击登录（启动无登录页时由 WelcomeLogic 自动调用，直接复用在途 preRequest 结果）
  Future<bool> clickLogin({bool waitPreRequest = true}) async {
    // Toast.showLoading(clickMaskDismiss: false, backDismiss: false);
    try {
      if (waitPreRequest && _preRequestFuture != null) {
        await _preRequestFuture;
      }
      if (_appManager.appConfigReady == false) {
        // AppConfig 还未请求完，再发起一次
        await _appManager.onGetAppConfig();
      }
      if (_appManager.appConfigReady == false) {
        throw Exception("AppConfig获取错误");
      }
      if (_loginModel == null) {
        // 登录数据为空，再次发起请求，避免点击登录后前置登录成功响应导致token失效
        _cancelToken?.cancel();
        String riskInfo = "";
        // if (kReleaseMode) {
        riskInfo = await RiskUtil.instance.infoEncrypt(null, true) ?? "";
        // }
        await _request.login(
          deviceId: DeviceUtil().deviceId,
          riskInfo: riskInfo,
          onSuccess: (data) {
            _loginModel = data;
          },
          onFail: (code, msg) {},
        );
      }
      if (_loginModel == null) {
        throw Exception("登录数据为空");
      }
      saveLoginModel(_loginModel!);

      bool result = await _validSuccess(true);
      if (result) {
        return true;
        // Get.offAllNamed(RoutePath.indexPage);
      }
      return false;
    } catch (e) {
      SPUtil.remove(MyKeys.token);
      logger.d("点击登录失败: $e");
      // Toast.showMsg("点击登录失败: $e");
      return false;
    } finally {
      // Toast.dismiss();
    }
  }

  //
  void saveLoginModel(LoginModel loginModel) {
    _loginModel = loginModel;
    BaseManager.instance.loginModel = _loginModel;
    if (_loginModel!.userInfo != null) {
      _appManager.saveUserInfo(_loginModel!.userInfo!, isFirstRegister: _loginModel!.isFirstRegister ?? false);
    }
    SPUtil.setString(MyKeys.token, _loginModel!.token ?? '');
    final current = DeviceUtil().deviceId;
    if (current.isNotEmpty) {
      SPUtil.setString('bound_device_id', current);
    }
    if (kIsWeb) {
      try {
        js.context.callMethod("setId_token", [_loginModel!.token]);
      } catch (e) {}
    }
  }

  /// One real token-authenticated server call. Ignores in-memory / SP strategy
  /// cache (that cache is why Index used to open with a dead token).
  /// Does not await [_preRequestFuture]: that future may be blocked on a
  /// login-lost getStrategy that is waiting on silent re-login, which itself
  /// waits on clickLogin — a deadlock.
  Future<bool> _probeCachedToken() async {
    _dropMismatchedDeviceToken();
    final token = SPUtil.getString(MyKeys.token);
    if (token.isEmpty) {
      return false;
    }
    var ok = false;
    await _request.getStrategy(
      token: token,
      onSuccess: (data) {
        _strategyModel = data;
        ok = true;
      },
      onFail: (code, msg) {},
    );
    if (ok && _strategyModel != null) {
      await _appManager.onGetStrategy(model: _strategyModel);
    }
    return ok;
  }

  // 已登录二次进入校验（冷启：必须先用服务端校验 token，不能只看本地缓存）
  Future<bool> validLogin() async {
    try {
      if (_preRequestFuture != null) {
        await _preRequestFuture;
        if (_strategyModel != null && _appManager.appConfigReady == true) {
          return await _validSuccess(false);
        }
      }
      if (_appManager.appConfigReady == false) {
        await _appManager.onGetAppConfig();
      }
      if (_appManager.appConfigReady == false) {
        return false;
      }
      final probed = await _probeCachedToken();
      if (!probed) {
        return false;
      }
      return await _validSuccess(false);
    } catch (e) {
      logger.e("校验错误: $e");
      return false;
    }
  }

  /// 登录/验证成功后续校验
  Future<bool> _validSuccess(bool loginValid) async {
    try {
      if (_loginModel == null && loginValid) {
        throw Exception("登录数据为空");
      }
      var list = <Future>[];
      if (_appManager.strategyModel == null || _strategyModel != null) {
        list.add(_appManager.onGetStrategy(model: _strategyModel));
      }
      if (_appManager.appConfigReady == false) {
        list.add(_appManager.onGetAppConfig());
      }
      if (list.isNotEmpty) {
        await Future.wait(list);
      }
      if (_appManager.appConfigModel == null) {
        throw Exception("AppConfig获取失败");
      }
      if (_appManager.strategyModel == null) {
        throw Exception("策略获取失败");
      }
      bool checkA = _appManager.strategyModel?.isReviewPkg ?? true;
      checkA = checkA && BHPlatform.isIOS && !kIsWeb;
      if (checkA) {
        // 检查
        _loginModel = null;
        _strategyModel = null;
        return true;
      }
      // 创建翻译工具
      if (!Get.isRegistered<TranslateManager>()) {
        Get.put(TranslateManager(), permanent: true);
      }
      Get.put(BannerStrongGuideLogic(), permanent: true);
      var rcLogic = Get.put<RCManager>(RCManager(), permanent: true);
      rcLogic.initEnter();
      // 以下内容延后获取
      // list.clear();
      // list.addAll([
      //   _appManager.onGetInfo(),
      //   guideLogic.onInitData(),
      //   rcLogic.initEnter(),
      // ]);
      // await Future.wait(list);
      // if (guideLogic.bannerReady == false) {
      //   throw Exception("banner获取失败");
      // }
      // if (guideLogic.guideReady == false) {
      //   throw Exception("导量获取失败");
      // }
      // if (rcLogic.token == null) {
      //   throw Exception("融云token获取失败");
      // }
      if (BaseManager.instance.appInfo.assetsPathText != null &&
          BaseManager.instance.appInfo.assetsPathPwd != null &&
          BaseManager.instance.appInfo.assetsPwdText != null &&
          BaseManager.instance.appInfo.assetsPwdPwd != null) {
        // 密钥密文不为空时，执行解压逻辑
        bool result = await AssetsHandle.instance.handle();
        if (!result) {
          throw Exception("资源解压错误");
        }
      }
      // 登录校验后
      _request.userModeSwitch(mode: 0);
      // 链接长连接
      SocketUtil().init();

      /// 注入视频通话记录操作类
      Get.put<VideoCallController>(VideoCallController(), permanent: true);
      // 注入VIP订阅服务
      Get.put<VipManager>(VipManager(), permanent: true);
      // 初始化支付
      Get.put<PayHandler>(PayHandler(), permanent: true);
      // 注入商品列表工具（因为多处需要）
      Get.put<CoinGoodsLogic>(CoinGoodsLogic(), permanent: true);
      // 注入视频通话仓库中转处理
      Get.put<VideoCallHandler>(VideoCallHandler(), permanent: true).init();
      // 注入用户状态服务
      Get.put<UserStatusService>(UserStatusService(), permanent: true);
      // 注入机器人话术管理器
      Get.put<RobotScriptManager>(RobotScriptManager(), permanent: true);
      _loginModel = null;
      _strategyModel = null;
        return true;
      } catch (e) {
        //TODO:临时屏蔽
        // if (loginValid) {
        //   Toast.showMsg("error_loginFail".bhTR);
        // } else {
        //   BaseManager.instance.loseLogin();
        // }
        // SPUtil.remove(MyKeys.token);
        // logger.d("获取策略等信息失败: $e");
        // return false;
        return true;
      }
  }
}
