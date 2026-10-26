import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/res/constant.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/package_info_util.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

import '../../../js/rc_manager_js.dart';
import 'logic.dart';

/// 关于页
class AboutPage extends StatelessWidget {
  AboutPage({super.key});

  final logic = Get.find<AboutLogic>();

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: DefaultAppBar(title: "title_about".bhTR),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18.w),
              // Center(
              //   child: ClipRRect(
              //     borderRadius: BorderRadius.circular(10.w),
              //     child: Image.asset(
              //       ImageAssets.logo,
              //       width: 58.w,
              //       height: 58.w,

              //     ),
              //   ),
              // ),
              // MyGaps.vGaps5w,
              // Center(
              //   child: Text(
              //     Constant.appName,
              //     style: TextStyle(
              //       color: MyColor.white,
              //       fontSize: 9.sp,
              //     ),
              //   ),
              // ),
              MyGaps.vGaps8w,
              Container(
                alignment: Alignment.centerLeft,
                width: double.infinity,
                margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                padding: EdgeInsets.all(6.w),
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF26203A),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "version".bhTR,
                      style: TextStyle(
                          color: MyColor.white,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        "V${PackageInfoUtil().packageInfo.version ?? "1.0"}",
                        style: TextStyle(
                            color: MyColor.white,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500),
                      ),
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => WebViewPage.onJump(
                    url: Constant.termsConditions,
                    title: "terms_termsConditions".bhTR),
                behavior: HitTestBehavior.translucent,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: double.infinity,
                  margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                  padding: EdgeInsets.all(6.w),
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26203A),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Text(
                    "terms_termsConditions".bhTR,
                    style: TextStyle(
                        color: MyColor.white,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              // MyGaps.hLine,
              GestureDetector(
                onTap: () => WebViewPage.onJump(
                    url: Constant.privacyPolicy,
                    title: "terms_privacyPolicy".bhTR),
                behavior: HitTestBehavior.translucent,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: double.infinity,
                  margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                  padding: EdgeInsets.all(6.w),
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26203A),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Text(
                    "terms_privacyPolicy".bhTR,
                    style: TextStyle(
                        color: MyColor.white,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              // MyGaps.hLine,
              if (Get.find<AppConfigManager>().strategyModel?.storeReviews ??
                  true)
                GestureDetector(
                  onTap: () async {
                    // 拉起商店评分
                    //打开外部网页
                    try {
                      JSRongCloudManager.myBrowser(
                          "https://apps.apple.com/app/id${BaseManager.instance.appInfo.iosAppId}?action=write-review",
                          1,
                          0);
                    } catch (e) {}

                    // if (await inAppReview.isAvailable()) {
                    //   inAppReview.requestReview();
                    // } else {
                    //   Toast.showMsg("Unable to find ${(BHPlatform.isAndroid ||  BHPlatform.isWeb) ? "Google Play" : "App"} Store".bhTR);
                    // }
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                    padding: EdgeInsets.all(6.w),
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26203A),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text(
                      "action_rateUs".bhTR,
                      style: TextStyle(
                          color: MyColor.white,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
