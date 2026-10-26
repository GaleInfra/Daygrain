import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/model/app_info_model.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'dart:js' as js;

import 'package:js/js_util.dart' as js_util;
import 'package:untitled1/utils/business_device_id.dart';
import 'package:untitled1/utils/js_utils.dart';
import 'package:untitled1/utils/web_anchored_image_picker.dart';

import 'package:untitled1/res/baked_config.dart';
import 'package:untitled1/utils/preconnect_origins.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'model/app_config_model.dart';
import 'model/broadcaster/strategy_model.dart';
import 'model/login/login_model.dart';

void main() => realRunApp();

Future<PreLoginConfig?> _consumePreloginWindow({
  required PreLoginConfig? existing,
  required String? deviceId,
}) async {
  if (existing != null || BakedConfig.preloginWindowSlot.isEmpty) return existing;
  if (!js_util.hasProperty(html.window, BakedConfig.preloginWindowSlot)) {
    return existing;
  }
  final pending = js_util.getProperty(html.window, BakedConfig.preloginWindowSlot);
  try {
    js.context.deleteProperty(BakedConfig.preloginWindowSlot);
  } catch (_) {
    js_util.setProperty(html.window, BakedConfig.preloginWindowSlot, null);
  }
  if (pending == null) return existing;
  dynamic resolved;
  try {
    resolved = await js_util.promiseToFuture(pending);
  } catch (_) {
    return existing;
  }
  if (resolved == null) return existing;
  dynamic decoded;
  try {
    decoded = resolved is String ? jsonDecode(resolved) : jsonDecode(stringify(resolved));
  } catch (_) {
    decoded = jsToDart(resolved);
  }
  if (decoded is! Map) return existing;
  final plain = Map<String, dynamic>.from(decoded);
  final bound = narrowBusinessDeviceId(plain[BakedConfig.preloginSlotDeviceId]?.toString() ?? '');
  final current = narrowBusinessDeviceId(deviceId ?? '');
  if (bound.isNotEmpty && current.isNotEmpty && bound != current) {
    return null;
  }
  final configRaw = plain[BakedConfig.preloginSlotConfig];
  final strategyRaw = plain[BakedConfig.preloginSlotStrategy];
  if (configRaw is! Map || strategyRaw is! Map) return existing;
  LoginModel? login;
  final token = plain[BakedConfig.preloginSlotToken]?.toString() ?? '';
  if (token.isNotEmpty) {
    final userRaw = plain[BakedConfig.preloginSlotUser];
    login = LoginModel.fromJson({
      'token': token,
      'isFirstRegister': plain[BakedConfig.preloginSlotFirstReg] == true,
      'userInfo': userRaw is Map ? userRaw : null,
    });
  }
  try {
    return PreLoginConfig(
      appConfigModel: AppConfigModel.fromJson(Map<String, dynamic>.from(configRaw)),
      strategyModel: StrategyModel.fromJson(Map<String, dynamic>.from(strategyRaw)),
      loginModel: login,
    );
  } catch (_) {
    return existing;
  }
}

/// Search params first, then the query part of the hash (`#/route?device-id=...`).
Map<String, String> _launchQuery() {
  final location = Uri.parse(html.window.location.href);
  final merged = <String, String>{};
  final hash = location.fragment;
  final hashQuery = hash.indexOf('?');
  if (hashQuery >= 0) {
    merged.addAll(Uri.splitQueryString(hash.substring(hashQuery + 1)));
  }
  merged.addAll(location.queryParameters);
  return merged;
}

String? _firstQuery(Map<String, String> query, List<String> names) {
  for (final name in names) {
    final value = query[name]?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

void realRunApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 尽早记下指针坐标，选图弹层才能锚在真实点击的控件旁。
  WebAnchoredImagePicker.ensurePointerTracking();
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 800);
  if (BakedConfig.localScheme.isNotEmpty) {
    js.context['__FUSE_LOCAL_SCHEME__'] = BakedConfig.localScheme;
    js.context['__FUSE_PRIMARY_SCHEME__'] = BakedConfig.localScheme.endsWith('-local')
        ? BakedConfig.localScheme.substring(0, BakedConfig.localScheme.length - 6)
        : BakedConfig.localScheme;
  }
  js.context['__FUSE_POP_HOST_MODE__'] = BakedConfig.popHostMode;
  // await AppInit.init();
  // runApp(const MyApp());
  //从网页window.my_host_path_o 获取值


  String? packageName;
  String? baseUrl;
  String? socketUrl;
  String? logUrl;
  String? termsConditions;
  String? privacyPolicy;
  String? iosAppId;
  AppInfoKeyModel? appInfoKeyModel;

  //AppConfig
  AppConfigModel? appConfigModel;
  //Strategy
  StrategyModel? strategyModel;
  //LoginModel
  LoginModel? loginModel;
  //PreLoginConfig
  PreLoginConfig? preLoginConfig;
  String? sdkVersion;

  String? deviceId;

  Map<String, dynamic> riskInfo = {};

  try {
    var pathDic = JSRongCloudManager.codeAppOptions;
    final resultSource = jsToDart(pathDic);
    //字符串解Base64
    final resultBase64 = String.fromCharCodes(base64Decode(resultSource));
    final result = jsonDecode(resultBase64);

    if (result is Map) {
      final ks = result["k"];

      final messageHandleKeys = result[ks[0]] as List;
      final propertysKeys = result[ks[1]] as List;
      final appEventKeys = result[ks[2]] as List;
      final eventKeys = result[ks[3]] as List;
      js.context.callMethod("initSDK", [jsonEncode(messageHandleKeys), jsonEncode(propertysKeys), jsonEncode(appEventKeys), jsonEncode(eventKeys)]);
      // JSRongCloudManager.initSDK(messageHandleKeys, propertysKeys, appEventKeys, eventKeys);
      deviceId = result[propertysKeys[3]];
      baseUrl = result[propertysKeys[4]];
      logUrl = result[propertysKeys[5]];
      final socketUrlTmp = result[propertysKeys[6]];
      if(socketUrlTmp is String){
        socketUrl = socketUrlTmp;
      }else if(socketUrlTmp is List && socketUrlTmp.isNotEmpty){
        socketUrl = socketUrlTmp[0];
      }
      termsConditions = result[propertysKeys[8]];
      privacyPolicy = result[propertysKeys[7]];

      iosAppId = result[propertysKeys[9]];
      packageName = result[propertysKeys[10]];
      final keysKey = result[propertysKeys[11]];
      sdkVersion = result[propertysKeys[12]];
      riskInfo = result[propertysKeys[13]];
      if (keysKey != null && keysKey is List) {
        var keys = keysKey;
        if (keys.length == 4) {
          appInfoKeyModel = AppInfoKeyModel(
            key1: keys[0],
            key2: keys[1],
            key3: keys[2],
            key4: keys[3],
          );
        }
      }

      final appConfigKey = propertysKeys[0];
      final strategyKey = propertysKeys[1];
      final userKey = propertysKeys[2];

      if (result[appConfigKey] != null) {
        appConfigModel = AppConfigModel.fromJson(result[appConfigKey]);
      }
      if (result[strategyKey] != null) {
        strategyModel = StrategyModel.fromJson(result[strategyKey]);
      }
      if (result[userKey] != null) {
        try {
          final loginModelTmp = LoginModel.fromJson(result[userKey]);
          if (loginModelTmp.token != null) {
            loginModel = loginModelTmp;
          }
        } catch (e) {}
      }
      if (appConfigModel != null && strategyModel != null) {
        preLoginConfig = PreLoginConfig(
          appConfigModel: appConfigModel,
          strategyModel: strategyModel,
          loginModel: loginModel,
        );
      }

      //TODO: 不知道为什么 手机浏览器 使用 wss无法发生消息
      if (socketUrl != null && socketUrl != "") {
        socketUrl = socketUrl.replaceAll("wss://", "https://");
      }
    } else {
      throw Exception("初始化出错");
    }
  } catch (e) {
    //log 初始化出错
    print("初始化出错: $e");
    // return;
  }

  final launchQuery = _launchQuery();
  final entryDevice = js.context['__FUSE_ENTRY_DEVICE_ID__']?.toString().trim();
  final queriedDevice = _firstQuery(launchQuery, ['device', BakedConfig.deviceParameter, 'device-id', 'glim_device'])
      ?? ((entryDevice != null && entryDevice.isNotEmpty) ? entryDevice : null);
  if (queriedDevice != null) {
    deviceId = queriedDevice;
  }
  final queriedPkg = _firstQuery(launchQuery, ['pkg', 'packageName']);
  if (queriedPkg != null) {
    packageName = queriedPkg;
  }
  final queriedVersion = _firstQuery(launchQuery, ['ver', 'version']);
  if (queriedVersion != null) {
    sdkVersion = queriedVersion;
  }
  final queriedScheme = _firstQuery(launchQuery, ['scheme', 'localScheme']);
  if (queriedScheme != null) {
    js.context['__FUSE_LOCAL_SCHEME__'] = queriedScheme;
  }

  if (appInfoKeyModel == null &&
      BakedConfig.key1.isNotEmpty &&
      BakedConfig.key2.isNotEmpty &&
      BakedConfig.key3.isNotEmpty &&
      BakedConfig.key4.isNotEmpty) {
    appInfoKeyModel = AppInfoKeyModel(
      key1: BakedConfig.key1,
      key2: BakedConfig.key2,
      key3: BakedConfig.key3,
      key4: BakedConfig.key4,
    );
  }
  PreconnectOrigins.note(baseUrl ?? BakedConfig.baseUrl);
  PreconnectOrigins.note(logUrl ?? BakedConfig.logUrl);
  preLoginConfig = await _consumePreloginWindow(existing: preLoginConfig, deviceId: deviceId);

  BaseManager.instance.runMyApp(
    appInfo: AppInfoModel(
      appName: "Video Chat",
      packageName: packageName ?? BakedConfig.packageName,
      deviceId: deviceId ?? "",
      baseUrl: baseUrl ?? BakedConfig.baseUrl,
      socketUrl: (socketUrl ?? BakedConfig.socketUrl).replaceAll("wss://", "https://"),
      logUrl: logUrl ?? BakedConfig.logUrl,
      termsConditions: termsConditions ?? BakedConfig.termsConditions,
      privacyPolicy: privacyPolicy ?? BakedConfig.privacyPolicy,
      appsFlyerKey: "",
      iosAppId: iosAppId ?? "",
      appIcon: null,
      appInfoKeyModel: appInfoKeyModel,
      preLoginConfig: preLoginConfig,
      sdkVersion: sdkVersion ?? "",
      riskInfo: riskInfo,
    ),
    successJumpToA: (map) async {},
    validJumpToA: () {},
    loseCallback: () {},
    checkRootBuilder: null,
  );
}
