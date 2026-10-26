import 'package:untitled1/base_manager.dart';

/// create: 2023/4/23
/// desc: 
class Constant {

  /// app名字
  static String appName = BaseManager.instance.appInfo.appName;

  /// 包名
  static String packageName = BaseManager.instance.appInfo.packageName;

  /// singleJsonMsg
  static const String singleJsonMsg = "LC:SingleJsonMsg";

  /// noneFlagMessage
  static const String noneFlagMessage = "LC:NoneFlagMsg";

  /// hyperLinkMessage
  static const String hyperLinkMessage = "LC:HyperLinkMsg";

  /// 用户协议
  static String termsConditions = BaseManager.instance.appInfo.termsConditions;

  /// 隐私协议
  static String privacyPolicy = BaseManager.instance.appInfo.privacyPolicy;

  /// appsFlyer 归因key
  // static const String appsFlyerKey = "";
}