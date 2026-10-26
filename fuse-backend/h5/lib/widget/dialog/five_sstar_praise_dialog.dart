import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/MyLinearGradient.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';

import '../../base_manager.dart';
import '../../res/image_assets.dart';
import '../../res/my_color.dart';
import '../../res/my_gaps.dart';
import '../../js/rc_manager_js.dart';
import '../../utils/toast.dart';

/// create: 2023/5/23
/// desc: 商店评分引导弹窗
class FiveStarPraiseDialog extends StatelessWidget {
  const FiveStarPraiseDialog({
    super.key,
    this.onCall,
  });

  static Future show({VoidCallback? onCall}) {
    if (!(Get.find<AppConfigManager>().strategyModel?.storeReviews ?? true)) {
      onCall?.call();
      return Future.value();
    }
    if (!SPUtil.containsKey(MyKeys.firstEvaluate)) {
      // 第一次通话，弹商店评分引导弹窗
      SPUtil.setBool(MyKeys.firstEvaluate, true);
      return DialogUtil.showDialog(
        alignment: Alignment.center,
        keepSingle: true,
        child: FiveStarPraiseDialog(onCall: onCall),
        tag: _tag,
      );
    }
    return Future.value();
  }

  static const String _tag = "FiveStarPraiseDialog";

  final VoidCallback? onCall;

  void _dismiss() {
    DialogUtil.dismiss(tag: _tag);
    onCall?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 13.w),
          decoration: BoxDecoration(
            color: MyColor.grey373634,
            borderRadius: BorderRadius.circular(11.5.w),
          ),
          child: Column(
            children: [
              Container(
                height: 62.w,
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: MyLinearGradient.getGradient(),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11.5.w),
                    topRight: Radius.circular(11.5.w),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      ImageAssets.iconsIcFiveStarPraise,
                      width: 43.w,
                      height: 37.w,
                      fit: BoxFit.fill,
                    ),
                    Text(
                      "Five-star praise".bhTR,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: MyColor.otherMessageBG,
                        fontWeight: FontWeight.bold,
                        fontFamily: "GillSans-BoldItalic",
                      ),
                    ),
                  ],
                ),
              ),
              MyGaps.vGaps10w,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Text(
                  "${"question_likeOurApp".bhTR}\n${"Please rate a five star or give a feedback to us".bhTR}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 7.sp,
                  ),
                ),
              ),
              SizedBox(
                height: 6.w,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: MyGradientButton(
                  height: 23.w,
                  width: 119.w,
                  onTap: () async {
                    _dismiss();
                    try {
                      JSRongCloudManager.myBrowser(
                          "https://apps.apple.com/app/id${BaseManager.instance.appInfo.iosAppId}?action=write-review",
                          1,
                          0);
                    } catch (e) {
                      Toast.showMsg(
                          "Unable to find ${Platform.isAndroid ? "Google Play" : "App"} Store"
                              .bhTR);
                    }
                    onCall?.call();
                  },
                  text: "action_praise".bhTR,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
                child: MyGradientButton(
                  width: 119.w,
                  gradientColor: const [Color(0xFF484848), Color(0xFF484848)],
                  height: 23.w,
                  onTap: () async {
                    _dismiss();
                  },
                  text: "Negative".bhTR,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: MyGradientButton(
                  width: 119.w,
                  gradientColor: const [Color(0xFF484848), Color(0xFF484848)],
                  height: 23.w,
                  onTap: () async {
                    _dismiss();
                  },
                  text: "Next Time".bhTR,
                ),
              ),
              MyGaps.vGaps12w,
            ],
          ),
        ),
      ],
    );
  }
}
