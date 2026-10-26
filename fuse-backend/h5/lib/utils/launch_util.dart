
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../js/rc_manager_js.dart';
import 'bh_platform.dart';

/// create: 2023/7/3
/// desc: 跳转封装工具
class LaunchUtil {
  /// 打开外部
  static void launchJump({
    required String url,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    if (BHPlatform.isWeb) {
      // web
      try {
        await JSRongCloudManager.myBrowser(url, 1,0);
        return;
      } catch (e) {}
    }
    try {
      if (!await launchUrl(Uri.parse(url), mode: mode)) {
        Toast.showMsg("error_unableToLaunch".bhTR);
      }
    } catch (e) {
      logger.e("跳转外部失败===> $e");
      Toast.showMsg("error_unableToLaunch".bhTR);
    }
  }

  /// 打开应用商店
  static void launchAppStore({
    required String packageName,
  }) {
    if (BHPlatform.isAndroid) {
      launchJump(url: "market://details?id=$packageName");
    } else if (BHPlatform.isIOS) {
      launchJump(url: "https://apps.apple.com/app/$packageName");
    }
  }
}
