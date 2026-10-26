import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/business/say_hi/robot_chat_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/app_init.dart';
import 'package:untitled1/database/controller/video_call_contoller.dart';
import 'package:untitled1/database/db/hive_database_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';
import 'package:untitled1/widget/dialog/robot_chat_dialog.dart';

import '../../../config/route.dart';

class SettingLogic extends GetBaseController {
  GlobalKey pageKay = GlobalKey();

  final appConfig = Get.find<AppConfigManager>();

  final videoCallManager = Get.find<VideoCallController>();

  @override
  void onReady() {
    appConfig.onGetInfo();
    super.onReady();
  }

  /// 复制id
  void onCopy(String text) async {
    Clipboard.setData(ClipboardData(text: text));
    Toast.showMsg("status_copySuccessfully".bhTR);
  }

  /// 改变是否自动翻译
  void onChangeAutoTranslate() {
    appConfig.onChangeAutoTranslate(!appConfig.autoTranslate.value);
  }

  /// 删除帐号第一次弹窗
  void onDelAccountFirstConfirm() {
    if (Get.find<VideoCallHandler>().onCallModel != null) {
      return;
    }
    DialogUtil.showDialog(
      bindPage: false,
      bindWidget: pageKay.currentContext,
      child: ConfirmDialog(
        title: "warning_confirmAccountDeletion".bhTR,
        onConfirm: () {
          DialogUtil.dismiss();
          _onSecondConfirm();
        },
      ),
    );
  }

  /// 二次确认
  void _onSecondConfirm() {
    DialogUtil.showDialog(
      bindPage: false,
      bindWidget: pageKay.currentContext,
      child: ConfirmDialog(
        title: "action_confirmAccountDeletion".bhTR,
        onConfirm: () {
          DialogUtil.dismiss().then((value) {
            _onDelAccount();
          });
        },
      ),
    );
  }

  /// 删除帐号
  void _onDelAccount() async {
    if (Get.find<VideoCallHandler>().onCallModel != null) {
      return;
    }
    // 仅在删除帐号的情况下删除这些数据
    try {
      await AppInit.beforeLogout();
      await request.userDeleteAccount();
      await AppInit.logout();
      await videoCallManager.deleteAll();
      SPUtil.remove(MyKeys.translateJson);
      SPUtil.remove(MyKeys.firstRecharge);
      SPUtil.remove(MyKeys.firstTapRearCamera);
      SPUtil.remove(MyKeys.jumpExternalRecharge);
      SPUtil.remove(MyKeys.vipDialogShow);
      SPUtil.remove(MyKeys.firstLoginSuccess);
      
      // 清理机器人通话状态
      await _clearRobotChatState();
      
      //删除Box
      try {
        HiveDatabaseManager.deleteAllBox();
      } catch (e) {
        
      }
      BaseManager.instance.isFirstRegisterLoginSuccess = true;
      //删除Box
      try {
        await HiveDatabaseManager.clearDatabase();
      } catch (e) {
        
      }
      await BaseManager.instance.loseLogin();
      appConfig.saveUserInfo(UserInfoModel());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// 清理机器人通话状态
  Future<void> _clearRobotChatState() async {
    try {
      // 获取当前用户ID
      final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
          ? appConfig.userInfo.userId!.toString()
          : 'guest';
      
      // 删除机器人通话相关的持久化状态
      SPUtil.remove('robot_chat_index_$uid');
      SPUtil.remove('robot_chat_count_$uid');
      SPUtil.remove('robot_chat_completed_$uid');
      
      // 清理所有可能的用户ID状态（防止多用户切换时的状态残留）
      _clearAllRobotChatStates();
      
      // 关闭机器人通话弹窗（必须在清理管理器之前）
      if (RobotChatDialog.isShowing) {
        RobotChatDialog.dismiss();
      }
      
      // 清理 RobotChatManager 实例（这会清理所有视频缓存）
      if (Get.isRegistered<RobotChatManager>()) {
        final robotChatManager = Get.find<RobotChatManager>();
        robotChatManager.stopChatTimer();
        
        // 异步清理所有视频缓存，等待完成
        await robotChatManager.clearAllVideoCache();
        
        // 强制删除实例，确保新账号重新初始化
        Get.delete<RobotChatManager>(force: true);
      }
            
      // 验证清理是否成功
      final success = _verifyCleanupSuccess();
      debugPrint('机器人通话状态已清理完成，验证结果: $success');
    } catch (e) {
      debugPrint('清理机器人通话状态失败: $e');
    }
  }

  // 清除logout的视频
  Future<void> _clearRobotChatLogout() async {
    try {
      // 获取当前用户ID
      final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
          ? appConfig.userInfo.userId!.toString()
          : 'guest';
      
      // 删除机器人通话相关的持久化状态
      // SPUtil.remove('robot_chat_index_$uid');
      // SPUtil.remove('robot_chat_count_$uid');
      // SPUtil.remove('robot_chat_completed_$uid');
      
      // 清理所有可能的用户ID状态（防止多用户切换时的状态残留）
      // _clearAllRobotChatStates();
      
      // 关闭机器人通话弹窗（必须在清理管理器之前）
      if (RobotChatDialog.isShowing) {
        RobotChatDialog.dismiss();
      }
      
      // 清理 RobotChatManager 实例（这会清理所有视频缓存）
      if (Get.isRegistered<RobotChatManager>()) {
        final robotChatManager = Get.find<RobotChatManager>();
        robotChatManager.stopChatTimer();
        
        // 异步清理所有视频缓存，等待完成
        await robotChatManager.clearAllVideoCache();
        
        // 强制删除实例，确保新账号重新初始化
        Get.delete<RobotChatManager>(force: true);
      }
            
      // 验证清理是否成功
      final success = _verifyCleanupSuccess();
      debugPrint('机器人通话状态已清理完成，验证结果: $success');
    } catch (e) {
      debugPrint('清理机器人通话状态失败: $e');
    }
  }

  /// 验证清理是否成功
  bool _verifyCleanupSuccess() {
    try {
      // 检查实例是否已被删除
      bool instanceDeleted = !Get.isRegistered<RobotChatManager>();
      
      // 检查弹窗是否已关闭
      bool dialogClosed = !RobotChatDialog.isShowing;
      
      // 检查持久化状态是否已清理
      final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
          ? appConfig.userInfo.userId!.toString()
          : 'guest';
      bool stateCleared = SPUtil.getInt('robot_chat_index_$uid', defaultValue: -1) == -1;
      
      bool success = instanceDeleted && dialogClosed && stateCleared;
      
      debugPrint('清理验证结果: 实例删除=$instanceDeleted, 弹窗关闭=$dialogClosed, 状态清理=$stateCleared, 总体=$success');
      
      return success;
    } catch (e) {
      debugPrint('清理验证失败: $e');
      return false;
    }
  }

  /// 清理所有用户的机器人通话状态（防止多用户切换时的状态残留）
  void _clearAllRobotChatStates() {
    try {
      // 获取所有SP键值
      final keys = SPUtil.getKeys();
      
      // 清理所有机器人通话相关的键值
      for (final key in keys) {
        if (key.startsWith('robot_chat_index_') || 
            key.startsWith('robot_chat_count_') || 
            key.startsWith('robot_chat_completed_')) {
          SPUtil.remove(key);
          debugPrint('清理机器人状态键: $key');
        }
      }
    } catch (e) {
      debugPrint('清理所有机器人状态失败: $e');
    }
  }

  /// 退出登录
  void onLogout() async {
    if (Get.isRegistered<VideoCallHandler>()) {
      if (Get.find<VideoCallHandler>().onCallModel != null) {
        return;
      }
    }

    //显示Loading
    Toast.showLoading(backDismiss: false, clickMaskDismiss: false);
    try {
      try {
        await request.securityLogout();
      } catch (e) {
        debugPrint("$e");
      }
      SPUtil.remove(MyKeys.token);
      await AppInit.beforeLogout();
      await AppInit.logout();
      await videoCallManager.deleteAll();

      // 登出与删除账号保持一致：清理机器人全屏状态（含进度）
      // await _clearRobotChatState();
      await _clearRobotChatLogout();

      //删除Box
      try {
        HiveDatabaseManager.deleteAllBox();
      } catch (e) {
        
      }
      // BaseManager.instance.isFirstRegisterLoginSuccess = true;
      //删除Box
      try {
        await HiveDatabaseManager.clearDatabase();
      } catch (e) {
        
      }
      await BaseManager.instance.loseLogin();
      appConfig.saveUserInfo(UserInfoModel());
    } catch (e) {
      debugPrint("$e");
    }
    Toast.dismiss();
  }

  void onLanguageSelect() {
    Get.toNamed(RoutePath.languagePage);
  }
}
