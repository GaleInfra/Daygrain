import 'package:flutter/services.dart';

import 'common_util.dart';

/// create: 2024/3/26
/// desc: 
class RiskChannel {
  static final RiskChannel _instance = RiskChannel._initial();
  static RiskChannel get instance => _instance;

  static const _riskChannelName = "risk_channel";  // 获取方法通道名称
  late MethodChannel _riskChannel;

  RiskChannel._initial() {
    _riskChannel = const MethodChannel(_riskChannelName);
  }
  
  /// 获取是否自动设置时区
  Future<bool> getAutoTimeZone() async {
    try {
      bool result = await _riskChannel.invokeMethod("getAutoTimeZone");
      logger.d("获取是否自动设置时区: $result");
      return result;
    } catch (e) {
      logger.e("获取是否自动设置时区: $e");
      return false;
    }
  }

  /// 获取是否多开
  Future<bool> getVirtual() async {
    try {
      bool result = await _riskChannel.invokeMethod("getVirtual");
      logger.d("获取是否多开: $result");
      return result;
    } catch (e) {
      logger.e("获取是否多开错误: $e");
      return false;
    }
  }

  /// 获取是否hook
  Future<bool> getHook() async {
    try {
      bool result = await _riskChannel.invokeMethod("getHook");
      logger.d("获取是否hook: $result");
      return result;
    } catch (e) {
      logger.e("获取是否是否hook错误: $e");
      return false;
    }
  }

  /// 获取是否root
  Future<bool> getRoot() async {
    try {
      bool result = await _riskChannel.invokeMethod("getRoot");
      logger.d("获取是否Root: $result");
      return result;
    } catch (e) {
      logger.e("获取是否是否Root错误: $e");
      return false;
    }
  }

  /// 获取是否开启代理
  Future<bool> getProxy() async {
    try {
      bool result = await _riskChannel.invokeMethod("getProxy");
      logger.d("获取是否开启Proxy: $result");
      return result;
    } catch (e) {
      logger.e("获取是否开启Proxy错误: $e");
      return false;
    }
  }
}