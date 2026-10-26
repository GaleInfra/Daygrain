import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:untitled1/business/say_hi/robot_script_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/database/db/database_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/overlay_util.dart';
import 'package:untitled1/utils/package_info_util.dart';
import 'package:untitled1/utils/socket_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/style_util.dart';
import 'package:untitled1/utils/toast.dart';

import '../business/say_hi/robot_chat_manager.dart';
import '../common_logic/banner_strong_guide_logic.dart';
import '../common_logic/video_call_handler.dart';
import '../net/base/request_client.dart';
import '../net/request_repository.dart';
import '../rong_cloud/rc_manager.dart';

/// create: 2023/4/23
/// desc:
class AppInit {
  static Future init() async {
    /// 初始化缓存工具
    await SPUtil.getInstance();

    await Future.wait<dynamic>([
      Future<void>(() async => await StyleUtil.redoSystemStyle(isPortrait: true)),
      Future<void>(() async => await StyleUtil.setSystemUIOverlayStyleLight(true)),
      Future<void>(() async => await DeviceUtil().getInfo()),
      PackageInfoUtil().getInfo(),
      BHLanguageMar().init(),
      DatabaseManager().init(),
    ]);

    /// 初始化网络请求
    RequestClient.getInstance().init();

    /// 注入请求仓库
    Get.lazyPut(() => RequestRepository(), fenix: true);

    Get.put<AppConfigManager>(AppConfigManager(), permanent: true);
  }

  /// 退出登录前操作
  static Future beforeLogout() async {
    OverlayUtil().dismissAll();
    SocketUtil().onClose();
    if (Get.isRegistered<RCManager>()) {
      await Get.find<RCManager>().onDestroy();
      Get.delete<RCManager>(force: true);
    }
    if (Get.isRegistered<BannerStrongGuideLogic>()) {
      Get.delete<BannerStrongGuideLogic>(force: true);
    }
    if (Get.isRegistered<VideoCallHandler>()) {
      /// 销毁视频通话仓库中转处理
      await Get.find<VideoCallHandler>().onBeforeClose();
      await Get.delete<VideoCallHandler>(force: true);
    }
    if (Get.isRegistered<UserStatusService>()) {
      await Get.delete<UserStatusService>(force: true);
    }
    if (Get.isRegistered<RobotScriptManager>()) {
      RobotScriptManager().stopAllTimers();
      await Get.delete<RobotScriptManager>(force: true);
    }
    if (Get.isRegistered<RobotChatManager>()) {
      // 退出登录时只停止定时器，不删除实例，保持状态持久化
      // Get.find<RobotChatManager>().stopChatTimer();
      // 注意：不删除 RobotChatManager 实例，保持状态
      // 删除账号时会单独处理 RobotChatManager 的清理
    }
  }

  /// 退出登录后操作
  static Future logout() async {
    SPUtil.remove(MyKeys.userInfo);
    SPUtil.remove(MyKeys.token);
    SPUtil.remove(MyKeys.appConfig);
    SPUtil.remove(MyKeys.rongCloudToken);
    try {
      await JSRongCloudManager.myLogOut();
    } catch (e) {
      Toast.showMsg("logoutFailed".bhTR);
    }
  }

  /// 网络状态监听执行
  static Future onConnectivityChanged(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      logger.d("连接上网络");
      // 重新链接
      if (SPUtil.containsKey(MyKeys.token)) {
        if (Get.currentRoute != RoutePath.loginPage &&
            Get.currentRoute != RoutePath.welcomePage) {
          SocketUtil().reconnect();
        }
      }
    }
  }
}
