import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import '../res/my_color.dart';
import '../widget/dialog/my_dialog.dart';

class DialogUtil {
  /// 显示自定义弹窗
  static Future<void> showDialog({
    required Widget child,
    SmartDialogController? controller,
    Alignment? alignment,
    bool? clickMaskDismiss,
    bool? usePenetrate,
    bool? useAnimation,
    SmartAnimationType animationType = SmartAnimationType.fade,
    List<SmartNonAnimationType>? nonAnimationTypes,
    Duration? animationTime,
    Color? maskColor,
    Widget? maskWidget,
    bool? debounce,
    VoidCallback? onDismiss,
    VoidCallback? onMask,
    Duration? displayTime,
    String? tag,
    bool? backDismiss,
    bool? keepSingle,
    bool? permanent,
    bool? useSystem,
    bool? bindPage,
    BuildContext? bindWidget,
    Rect? ignoreArea,
  }) {
    return SmartDialog.show(
      builder: (ctx) {
        return child;
      },
      alignment: alignment,
      clickMaskDismiss: clickMaskDismiss,
      animationType: animationType ?? SmartAnimationType.centerFade_otherSlide,
      nonAnimationTypes: nonAnimationTypes,
      usePenetrate: usePenetrate,
      useAnimation: useAnimation,
      animationTime: animationTime,
      maskColor: maskColor ?? Colors.black.withValues(alpha: .6),
      maskWidget: maskWidget,
      debounce: debounce,
      onDismiss: onDismiss,
      onMask: onMask,
      displayTime: displayTime,
      tag: tag,
      backDismiss: backDismiss,
      keepSingle: keepSingle,
      permanent: permanent,
      useSystem: useSystem,
      bindPage: bindPage,
      bindWidget: bindWidget,
      ignoreArea: ignoreArea,
    );
  }

  /// 网络错误弹窗
  static void showNetworkDialog({VoidCallback? onConfirm}) {
    showDialog(
      keepSingle: true,
      clickMaskDismiss: false,
      backDismiss: false,
      tag: "NetworkDialog",
      child: MyDialog(
        background: MyColor.themeColor1E2440,
        title: "label_networkAnomaly".bhTR,
        warning: "suggestion_checkNetworkSettings".bhTR,
        titleStyle: TextStyle(
          color: MyColor.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
        icons: Icons.warning_amber,
        iconColor: MyColor.yellowFAB96F,
        dialogStatus: MyDialogStatus.alone,
        confirm: "action_confirm".bhTR,
        confirmBackground: MyColor.purpleB081FF,
        onConfirm: () {
          onConfirm?.call();
          DialogUtil.dismiss();
        },
      ),
    );
  }

  /// 关闭网络错误弹窗
  static void dismissNetworkDialog() {
    dismiss(tag: "NetworkDialog");
  }

  static Future dismiss({
    SmartStatus status = SmartStatus.dialog,
    String? tag,
    bool force = false,
  }) async {
    await SmartDialog.dismiss(status: status, tag: tag, force: force);
  }
}
