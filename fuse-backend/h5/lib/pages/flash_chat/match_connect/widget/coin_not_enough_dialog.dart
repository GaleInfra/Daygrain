import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';

import '../../../../res/pay_entry.dart';
import '../../../../widget/dialog/recharge_dialog.dart';

/// create: 2023/6/8
/// desc: 匹配 - 金币不足弹窗
class CoinNotEnoughDialog extends StatelessWidget {
  final bool isDialog;
  const CoinNotEnoughDialog({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 13.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.w),
      decoration: BoxDecoration(
        color: MyColor.white,
        borderRadius: BorderRadius.circular(9.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Center(
                child: Image.asset(
                  ImageAssets.flashCry,
                  width: 45.w,
                  height: 45.w,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    if (isDialog) {
                      CoinNotEnoughDialog.dismiss();
                    } else {
                      Get.back();
                    }
                  },
                  child: Icon(
                    Icons.close,
                    size: 10.w,
                    color: MyColor.black,
                  ),
                ),
              ),
            ],
          ),
          MyGaps.vGaps5w,
          Text(
            "message_apology".bhTR,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MyColor.black,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          MyGaps.vGaps5w,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Text(
              "error_insufficientDiamondsForCall".bhTR,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MyColor.black,
                fontSize: 8.sp,
              ),
            ),
          ),
          MyGaps.vGaps10w,
          MyGradientButton(
            width: 90.w,
            text: "action_getDiamonds".bhTR,
            onTap: () {
              if (isDialog) {
                CoinNotEnoughDialog.dismiss();
              } else {
                Get.back();
              }
              RechargeDialog.show(entry: PayEntry.SOURCE_28, bindWidget: null);
            },
          ),
        ],
      ),
    );

    return isDialog
        ? body
        : Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(.4),
            alignment: Alignment.center,
            child: body);
  }

  static void show() {
    SmartDialog.show(
      builder: (context) => const CoinNotEnoughDialog(
        isDialog: true,
      ),
      tag: "CoinNotEnoughDialog",
      clickMaskDismiss: true,
      backDismiss: true,
    );
  }

  static void dismiss() {
    SmartDialog.dismiss(tag: "CoinNotEnoughDialog");
  }
}
