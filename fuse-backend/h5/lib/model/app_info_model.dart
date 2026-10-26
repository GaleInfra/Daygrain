import 'package:flutter/material.dart';
import 'package:untitled1/model/app_config_model.dart';
import 'package:untitled1/model/broadcaster/strategy_model.dart';
import 'package:untitled1/model/login/login_model.dart';

/// create: 2024/3/14
/// desc: App信息
class AppInfoModel {
  /// App 名称
  final String appName;

  /// 包名
  final String packageName;

  /// iOS端设备信息ID
  final String deviceId;

  /// 域名前缀
  final String baseUrl;

  /// 长链接前缀
  final String socketUrl;

  /// 上报前缀
  final String logUrl;

  /// 用户协议
  final String termsConditions;

  /// 隐私政策
  final String privacyPolicy;

  /// af归因key
  final String appsFlyerKey;

  /// 苹果ID 安卓端不需要
  final String iosAppId;

  /// AppIcon图标
  final Widget? appIcon;

  /// 资源路径密文
  final String? assetsPathText;

  /// 资源路径密钥
  final String? assetsPathPwd;

  /// 资源密钥的密文
  final String? assetsPwdText;

  /// 资源密钥的密钥
  final String? assetsPwdPwd;

  final AppInfoKeyModel? appInfoKeyModel;

  final PreLoginConfig? preLoginConfig;

  final String sdkVersion;

  final Map<String, dynamic> riskInfo;

  AppInfoModel({
    required this.appName,
    required this.packageName,
    required this.deviceId,
    required this.baseUrl,
    required this.socketUrl,
    required this.logUrl,
    required this.termsConditions,
    required this.privacyPolicy,
    required this.appsFlyerKey,
    required this.iosAppId,
    required this.appIcon,
    this.assetsPathText,
    this.assetsPathPwd,
    this.assetsPwdText,
    this.assetsPwdPwd,
    this.appInfoKeyModel,
    this.preLoginConfig,
    required this.sdkVersion,
    required this.riskInfo,
  });

  AppInfoModel copyWith({
    String? appName,
    String? packageName,
    String? deviceId,
    String? baseUrl,
    String? socketUrl,
    String? logUrl,
    String? termsConditions,
    String? privacyPolicy,
    Map<String, String>? apiConfusion,
    Map<String, String>? apiConverseConfusion,
    String? appsFlyerKey,
    String? iosAppId,
    Widget? appIcon,
    String? sdkVersion,
    Map<String, dynamic>? riskInfo,
  }) =>
      AppInfoModel(
        appName: appName ?? this.appName,
        packageName: packageName ?? this.packageName,
        deviceId: deviceId ?? this.deviceId,
        baseUrl: baseUrl ?? this.baseUrl,
        socketUrl: socketUrl ?? this.socketUrl,
        logUrl: logUrl ?? this.logUrl,
        termsConditions: termsConditions ?? this.termsConditions,
        privacyPolicy: privacyPolicy ?? this.privacyPolicy,
        appsFlyerKey: appsFlyerKey ?? this.appsFlyerKey,
        iosAppId: iosAppId ?? this.iosAppId,
        appIcon: appIcon ?? this.appIcon,
        sdkVersion: sdkVersion ?? this.sdkVersion,
        riskInfo: riskInfo ?? this.riskInfo,
      );
}

class AppInfoKeyModel {
  final String key1;
  final String key2;
  final String key3;
  final String key4;

  AppInfoKeyModel({
    required this.key1,
    required this.key2,
    required this.key3,
    required this.key4,
  });
}

//预登陆配置
class PreLoginConfig {
  final AppConfigModel appConfigModel;
  final StrategyModel strategyModel;
  final LoginModel? loginModel;

  PreLoginConfig({
    required this.appConfigModel,
    required this.strategyModel,
    this.loginModel,
  });
}
