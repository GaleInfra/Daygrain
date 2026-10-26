
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/broadcaster_call_price_util.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import 'logic.dart';

/// 视频通话-呼叫页
class CallPage extends GetView<CallLogic> {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // logic.hangUp();
        return false;
      },
      child: Container(
        decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MyColor.black,
                        Color(0xFF8804A0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
        child: GetBuilder<VideoCallHandler>(
          builder: (handler) {
            var countryText = handler.userInfo?.country ?? "";
            var appConfig = Get.find<AppConfigManager>();
            if (appConfig.nameByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
            } else if (appConfig.codeByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                children: [
                  Padding(
                     padding: EdgeInsets.only(top: 80.w),
                    child: Container(
                      width: 95.w,
                      height: 95.w,
                      padding: EdgeInsets.all(5.5.w),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(95.w / 2.0),
                          gradient: LinearGradient(
                            colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                          )),
                      child: Container(
                        padding: EdgeInsets.all(5.5.w),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(84.w / 2.0),
                            gradient: LinearGradient(
                              colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                            )),
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(73.w / 2.0),
                              gradient: const LinearGradient(
                                colors: MyColor.btnGradientColors,
                              )),
                          child: MyExtendedNetworkImage(
                            url: handler.userInfo?.avatarUrl ?? "",
                            shape: BoxShape.circle,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  MyGaps.vGaps9w,
                  Text(
                    (handler.userInfo?.nickname ?? "").fixAutoLines(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // AgeCountryRowWidget(
                  //   age: "${handler.userInfo?.age ?? 0}",
                  //   country: handler.userInfo?.country ?? "",
                  // ),
                  MyGaps.vGaps2w,
                  Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            countryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          " | ",
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "${handler.userInfo?.age ?? 0}",
                          maxLines: 1,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MyGaps.vGaps2w,
                  Obx(() {
                    final price = BroadcasterCallPriceUtil.displayPerMinutePrice(
                      broadcaster: handler.userInfo,
                      onCallUnitPrice: controller.unitPrice.value > 0
                          ? controller.unitPrice.value
                          : null,
                    );

                    return Visibility(
                      visible: !Get.find<AppConfigManager>().isReviewPkg.value,
                      child: Container(
                        height: 13.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: MyColor.btnGradientColors3),
                          borderRadius: BorderRadius.circular(13.w),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                  ImageAssets.broadcasterDiamondSmall,
                                  width: 7.w,
                                  height: 7.w,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(
                                  width: 2.w,
                                ),
                              //显示图片
                              Text(
                                "$price",
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 5.sp,
                                ),
                              ),
                              SizedBox(
                                width: 2.w,
                              ),
                        
                              Text(
                                "/min".bhTR,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(flex: 2),
                  MyGaps.vGaps20w,
                  GestureDetector(
                    onTap: controller.hangUp,
                    child: Image.asset(
                      ImageAssets.hangUp,
                      width: 30.w,
                      height: 30.w,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
