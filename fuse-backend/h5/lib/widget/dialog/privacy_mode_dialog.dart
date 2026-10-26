import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/mine/logic.dart';

/// 显示隐私模式弹窗
void showPrivacyModeDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const PrivacyModeDialog(),
  );
}

void reportEnterClick() {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";

  getReqRepo()?.log(
    event: "click",
    page: "privacy_mode_enter_click",
    terPage: payStatusTag,
  );
}

void reportEnterFalse() {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";

  getReqRepo()?.log(
    event: "click",
    page: "privacy_mode_confirm_click",
    subPage: "is_confirmed_false",
    terPage: payStatusTag,
  );
}

void reportEnterTrue() {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";

  getReqRepo()?.log(
    event: "click",
    page: "privacy_mode_confirm_click",
    subPage: "is_confirmed_true",
    terPage: payStatusTag,
  );
}

class PrivacyModeDialog extends StatelessWidget {
  const PrivacyModeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade700.withOpacity(0.9),
              Colors.grey.shade900.withOpacity(0.9)
            ],
          ),
          borderRadius: BorderRadius.circular(12.5.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "title_privacy_mode".bhTR,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                  letterSpacing: 0.25,
                ),
              ),
              SizedBox(height: 7.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  "confirm_privacy_mode_question".bhTR,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 7.sp,
                    height: 1.3,
                  ),
                ),
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    context,
                    "action_no".bhTR,
                    Colors.grey.shade600,
                    Colors.grey.shade500,
                    () => {Navigator.of(context).pop(), reportEnterFalse()},
                  ),
                  _buildButton(
                    context,
                    "action_yes".bhTR,
                    Color(0xFF7C2FB1),
                    Color(0xFF3EBDFC),
                    () async {
                      // 设置隐私模式为启用
                      await PrivacyModeManager.setPrivacyMode(true);
                      // 更新视频通话监听状态
                      if (Get.isRegistered<VideoCallHandler>()) {
                        await Get.find<VideoCallHandler>()
                            .updateListenerByPrivacyMode();
                      }
                      Navigator.of(context).pop();
                      Get.offAllNamed(RoutePath.cPage);
                      reportEnterTrue();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color startColor,
    Color endColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55.w,
        height: 25.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: text == "action_yes".bhTR
                ? [startColor, endColor]
                : [Colors.grey.shade500, Colors.grey.shade600],
          ),
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2.5,
              spreadRadius: 0.5,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 9.sp,
            letterSpacing: 0.25,
          ),
        ),
      ),
    );
  }
}
