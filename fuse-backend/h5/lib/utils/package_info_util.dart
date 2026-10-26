import 'package:package_info_plus/package_info_plus.dart';

import 'common_util.dart';

/// create: 2023/4/23
/// desc: 获取应用信息工具
PackageInfoUtil packageInfoUtil = PackageInfoUtil();
class PackageInfoUtil {
  PackageInfoUtil._internal();

  static final PackageInfoUtil _instance = PackageInfoUtil._internal();
  factory PackageInfoUtil() => _instance;

  late PackageInfo packageInfo;

  Future getInfo()async {
    packageInfo = await PackageInfo.fromPlatform();
    logger.d("=====当前包信息=====\n"
        "appName: ${packageInfo.appName}\n"
        "packageName: ${packageInfo.packageName}\n"
        "version: ${packageInfo.version}"
    );
  }
}