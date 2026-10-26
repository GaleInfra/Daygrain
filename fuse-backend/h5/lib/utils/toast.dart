import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:untitled1/language/bh_language_manager.dart';

/// @description: 土司工具及加载弹窗工具
class Toast {
  ///toast
  static void showMsg(
    String msg, {
    Alignment alignment = Alignment.center,
    Duration? displayTime,
    SmartToastType? displayType = SmartToastType.normal,
  }) {
    SmartDialog.showToast(
      msg,
      alignment: alignment,
      debounce: true,
      displayTime: displayTime,
      displayType: displayType,
    );
  }

  ///加载弹窗
  static void showLoading({
    bool clickMaskDismiss = true,
    bool backDismiss = true,
    bool isShowCloseBtn = false,
    String? tag,
    VoidCallback? onDismiss,
  }) {
    SmartDialog.showLoading(
      clickMaskDismiss: clickMaskDismiss,
      backDismiss: backDismiss,
      onDismiss: onDismiss,
      builder: (ctx) => Center(
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child:const Center(
                child:  CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
            //右上角白色关闭按钮
            if (isShowCloseBtn)
              Positioned(
                right: BHLanguageMar().isRightToLeft.value ? null : 0,
                left: BHLanguageMar().isRightToLeft.value? 0 : null,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    dismiss();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child:  Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 8.w,
                    )
                  )
                )
              )
          ],
        ),
      ),
    );
  }

  static void dismiss({
    SmartStatus status = SmartStatus.loading,
    String? tag,
    bool force = false,
  }) {
    SmartDialog.dismiss(
      status: status,
      tag: tag,
      force: force,
    );
  }
}
