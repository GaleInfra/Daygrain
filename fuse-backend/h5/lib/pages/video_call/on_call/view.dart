
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import '../../../common_logic/app_config_manager.dart';
import '../../../res/image_assets.dart';
import '../../../res/my_color.dart';
import '../../../res/my_gaps.dart';
import '../../../widget/image/my_extended_network_image.dart';
import 'logic.dart';

/// 视频通话 - 被呼叫页
class OnCallPage extends StatelessWidget {
  final logic = Get.find<OnCallLogic>();

  OnCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // logic.onBack(hangUp: false);
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
            var countryText = handler.onCallModel?.country ?? "";
            var appConfig = Get.find<AppConfigManager>();
            if (appConfig.nameByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
            } else if (appConfig.codeByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
            }

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 70.w),
                    child: Container(
                      width: 95.w,
                      height: 95.w,
                      padding: EdgeInsets.all(5.5.w),
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(95.w / 2.0),
                          gradient: LinearGradient(
                            colors: MyColor.btnGradientColors
                                .map((e) => e.withOpacity(0.2))
                                .toList(),
                          )),
                      child: Container(
                        padding: EdgeInsets.all(5.5.w),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(84.w / 2.0),
                            gradient: LinearGradient(
                              colors: MyColor.btnGradientColors
                                  .map((e) => e.withOpacity(0.2))
                                  .toList(),
                            )),
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(73.w / 2.0),
                              gradient: const LinearGradient(
                                colors: MyColor.btnGradientColors,
                              )),
                          child: MyExtendedNetworkImage(
                            url: handler.onCallModel?.avatarThumbUrl ??
                                "",
                            shape: BoxShape.circle,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  MyGaps.vGaps9w,
                  Text(
                    (handler.onCallModel?.nickname ?? "")
                        .fixAutoLines(),
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
                          "${handler.onCallModel?.age ?? 0}",
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
                    bool free = handler.onCallModel?.isFree ?? false;
                    Widget child = const SizedBox();
                    if (free) {
                      // final texts = "youll_be_charged_for_the_first_minute".bhTR.split("####");
                      child = RichText(
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        text: TextSpan(
                            // text: texts[0],
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 8.sp,
                            ),
                            children: [
                              TextSpan(
                                text: "label_free".bhTR,
                                style: TextStyle(
                                  color: const Color(0xFF18DD6C),
                                  fontSize: 8.sp,
                                ),
                              ),
                              TextSpan(
                                // text: texts[1],
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 8.sp,
                                ),
                              ),
                            ]),
                      );
                    } else {
                      child = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //显示图片
              
                          Text(
                            "${handler.onCallModel?.unitPrice ?? 0}",
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 5.sp,
                            ),
                          ),
                          SizedBox(
                            width: 2.w,
                          ),
                          Image.asset(
                            ImageAssets.broadcasterDiamondSmall,
                            width: 7.w,
                            height: 7.w,
                            fit: BoxFit.cover,
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
                      );
                    }
                    return Visibility(
                      visible: !Get.find<AppConfigManager>()
                              .isReviewPkg
                              .value &&
                          !free,
                      child: Container(
                        height: 13.w,
                        decoration: BoxDecoration(
                          gradient:const LinearGradient(
                              colors: MyColor.btnGradientColors2),
                          borderRadius: BorderRadius.circular(13.w),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.w),
                          child: child,
                        ),
                      ),
                    );
                  }),
                  const Spacer(flex: 2),
                  MyGaps.vGaps20w,
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => logic.onHangUp(),
                          child: Image.asset(
                            ImageAssets.hangUp,
                            width: 30.w,
                            height: 30.w,
                          ),
                        ),
                        Stack(
                          children: [
                            SizedBox(
                              height: 60.w,
                              child: Center(
                                  child: Container(
                                    width: 42.w,
                                    height: 42.w,
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(42.w / 2.0),
                                    gradient: LinearGradient(
                                      colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                                    )),
                                                                  child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36.w / 2.0),
                                      gradient: LinearGradient(
                                        colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                                      )),
                                  child: GestureDetector(
                                onTap: logic.onPickUp,
                                child: Image.asset(
                                  ImageAssets.broadcasterCall,
                                  width: 30.w,
                                  height: 30.w,
                                ),
                              ),
                                ),
                              ),
                                ),
                            ),
                            Visibility(
                              visible:
                                  handler.onCallModel?.isFree ?? false,
                              child: Positioned(
                                left:
                                    BHLanguageMar().isRightToLeft.value
                                        ? 0
                                        : null,
                                right:
                                    BHLanguageMar().isRightToLeft.value
                                        ? null
                                        : 0,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        margin:
                                            EdgeInsets.only(top: 2.w),
                                        child: Image.asset(
                                          ImageAssets.callFree,
                                          width: 26.w,
                                          height: 18.w,
                                        ).bh,
                                      ),
                                      Transform.rotate(
                                        // 设置旋转角度，这里是 15 度，可根据需要调整
                                        angle: 15 * (3.1415926 / 180),
                                        child: Text(
                                          "label_free".bhTR,
                                          style: TextStyle(
                                            color: MyColor.white,
                                            fontSize: "label_free"
                                                        .bhTR
                                                        .length >
                                                    6
                                                ? 4.sp
                                                : 6.sp,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
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
