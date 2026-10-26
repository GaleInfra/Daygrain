import 'package:flutter/material.dart';
import 'package:untitled1/widget/dialog/privacy_mode_dialog.dart' as original;
import 'package:untitled1/widget/dialog/privacy_mode_dialog_new.dart'
    as new_dialog;

class PrivacyModeUtil {
  /// 显示原始隐私模式弹窗
  static void showPrivacyModeDialog(BuildContext context) {
    original.showPrivacyModeDialog(context);
  }

  /// 显示新的隐私模式弹窗
  static void showPrivacyModeDialogNew(BuildContext context) {
    new_dialog.showPrivacyModeDialogNew(context);
  }
}
