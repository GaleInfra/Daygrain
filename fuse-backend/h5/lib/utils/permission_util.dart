import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';

import 'bh_platform.dart';
import 'dart:html' as html;

// 是否显示权限申请弹窗
bool kShowPermission = false;

/// @description: 权限申请工具，预留位置给以后对权限请求对封装
Future<bool> requestPermission(Permission permission,
    {bool showDialog = true}) async {
  /// 获取此权限的当前状态，如果还没有请求许可，或者许可已经被拒绝
  var status = await permission.status;
  if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
    status = await permission.request();
    if (status.isPermanentlyDenied && showDialog) {
      kShowPermission = true;

      /// 用户永久拒绝
      String name = permission.toString().replaceAll("Permission.", "");
      await DialogUtil.showDialog(
        keepSingle: true,
        tag: "Permission",
        onDismiss: () => kShowPermission = false,
        child: ConfirmDialog(
          title:
              "Unable to obtain #### permissions. Please go to the app settings page to obtain permissions."
                  .bhTR
                  .replaceAll("####", name),
          swap: true,
          onConfirm: () async {
            DialogUtil.dismiss(tag: "Permission");
            await openAppSettings();
          },
        ),
      );
    }
  }
  return status.isGranted || status.isLimited;
}

//是否已经有全部权限
bool isHasAllPermission = false;

Future<bool> checkCameraAndMicrophonePermission(
    {bool showDialog = true,
    bool isAwait = false,
    bool isFore = false,
    bool isNotMic = false}) async {
  bool isAllow = false;
  if (!isFore && isHasAllPermission) {
    return true;
  }
  try {
    var hasCamera = false;
    var hasMicrophone = false;
    if (html.window.navigator.mediaDevices != null) {
      if (isNotMic) {
        hasMicrophone = true;
      } else {
        try {
          final stream = await html.window.navigator.mediaDevices
              ?.getUserMedia({'audio': true})
              .then<html.MediaStream?>((s) => s)
              .timeout(
            const Duration(seconds: 8),
            onTimeout: () => null,
          );
          if (stream != null) {
            hasMicrophone = true;
            stream.getTracks().forEach((track) => track.stop());
          }
        } catch (e) {
          hasMicrophone = false;
        }
      }

      try {
        // 限时，避免 WKWebView 上 getUserMedia 永不返回导致通话/匹配卡住。
        final stream = await html.window.navigator.mediaDevices
            ?.getUserMedia({'video': true})
            .then<html.MediaStream?>((s) => s)
            .timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
        if (stream != null) {
          hasCamera = true;
          // 不在探测阶段 applyConstraints：environment/focusMode 等在
          // iOS WKWebView 上可能挂起，探测成功后立刻停轨即可。
          stream.getTracks().forEach((track) => track.stop());
        }
      } catch (e) {
        hasCamera = false;
      }
    } else {
      hasCamera = false;
      hasMicrophone = false;
    }
    if (!isNotMic) {
      isAllow = hasCamera && hasMicrophone;
    }
    
  } catch (e) {
    isAllow = false;
  }
  if (!isAllow) {
    if (showDialog) {
      Completer? completer;
      if (isAwait) {
        completer = Completer();
      }

      DialogUtil.showDialog(
        keepSingle: true,
        tag: "Permission",
        // onDismiss: () => kShowPermission = false,
        child: ConfirmDialog(
          title:
              "Unable to obtain Camera or Microphone permissions. Please go to the app settings page to obtain permissions"
                  .bhTR,
          swap: true,
          onCancel: () {
            DialogUtil.dismiss(tag: "Permission");
            if (completer != null) {
              completer.complete();
            }
          },
          onConfirm: () async {
            DialogUtil.dismiss(tag: "Permission");
            if (completer != null) {
              completer.completeError("fail");
            }
            JSRongCloudManager.myLogSetting();
          },
        ),
      );
      if (isAwait) {
        await completer?.future;
      }
    }
  }
  if (!isNotMic) {
    isHasAllPermission = isAllow;
  }
  
  return isAllow;
}

/// 申请相册权限
Future<bool> requestPhoto() async {
  bool rStorage = false; // 是否是申请存储权限
  if (BHPlatform.isAndroid) {
    // 如果是安卓平台，判断系统版本，小于33才是申请存储权限
    rStorage = (DeviceUtil().androidDeviceInfo.version.sdkInt) < 33;
  }
  if (rStorage) {
    return requestPermission(Permission.storage, showDialog: true);
  } else {
    return requestPermission(Permission.photos, showDialog: true);
  }
}
