import 'package:untitled1/res/constant.dart';

/// create: 2023/5/25
/// desc: 多环境配置文件
class Env {
  // 获取到当前环境
  static const appEnv = String.fromEnvironment(EnvName.envKey);

  // 开发环境
  static final EnvConfig _debugConfig = EnvConfig(
    baseUrl: "http://test-app.bonhubs.xyz",
    socketUrl: "https://test-im.bonhubs.xyz",
    applicationId: Constant.packageName,
  );

  // 发布环境
  static final EnvConfig _produceConfig = EnvConfig(
    baseUrl: "http://app.bonhubs.xyz",
    socketUrl: "https://im.bonhubs.xyz",
    applicationId: "",
  );

  static EnvConfig get envConfig => _getEnvConfig();

// 根据不同环境返回对应的环境配置
  static EnvConfig _getEnvConfig() {
    switch (appEnv) {
      case EnvName.envKey:
        return _debugConfig;
      case EnvName.envProduce:
        return _produceConfig;
      default:
        return _debugConfig;
    }
  }
}

// 声明的环境
abstract class EnvName {
  // 环境key
  static const String envKey = "DART_DEFINE_APP_ENV";

  // 环境value
  /// 开发版
  static const String envDebug = "envDebug";

  /// 发布版
  static const String envProduce = "envProduce";
}

/// 环境配置
class EnvConfig {
  EnvConfig({
    required this.baseUrl,
    required this.socketUrl,
    required this.applicationId,
  });

  /// 地址前缀
  final String baseUrl;

  /// socketUrl地址
  final String socketUrl;

  /// 包名
  final String applicationId;
}
