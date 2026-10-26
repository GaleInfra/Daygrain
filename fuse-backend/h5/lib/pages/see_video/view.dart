import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/custom/swiper_pagination/my_swiper_pagination.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/broadcaster_call_price_util.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/widget/button/call_button.dart';
import 'package:untitled1/widget/dialog/report_sub_sheet.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/status/page_status_widget.dart';
import 'logic.dart';

/// 循环播放视频页
class SeeVideoPage extends StatelessWidget {
  final logic = Get.find<SeeVideoLogic>();

  SeeVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColor.appBackground,
      child: Stack(
        children: [
          GetBuilder<SeeVideoLogic>(
            builder: (logic) {
              return PageStatusWidget(
                logic: logic,
                child: Swiper(
                  index: logic.index.value,
                  itemCount: logic.itemList.length,
                  loop: false,
                  itemBuilder: (ctx, index) {
                    return logic.itemList[index];
                  },
                  onIndexChanged: (value) {
                    print('====> $value');
                    logic.index.value = value;
                  },
                  pagination: (logic.itemList.length ?? 0) > 1
                      ? SwiperPagination(
                          margin: EdgeInsets.all(15.w),
                          builder: MySwiperPagination(
                            activeColor: MyColor.btnGradientColors.first,
                            color: MyColor.white,
                            activeWidth: 6.w,
                            width: 3.w,
                            height: 3.w,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
          const _UserInfo(),
          Positioned(
            top: kIsWeb
                ? (Get.height * 9 / 16.0 * 0.16) < (DeviceUtil().statusBarHeight ?? 0)
                    ? (DeviceUtil().statusBarHeight ?? 0)
                    : (Get.height * 9 / 16.0 * 0.16)
                : 20.w,
            right: BHLanguageMar().isRightToLeft.value ? null : 8.w,
            left: BHLanguageMar().isRightToLeft.value ? 8.w : null,
            child: SizedBox(
              height: 25.w,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ReportSubSheet.show(
                      userId: logic.userInfo?.userId ?? "",
                    ),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      padding: EdgeInsets.only(left: 3.w, right: 3.w, top: 2.w, bottom: 4.w),
                      decoration: BoxDecoration(
                        color: MyColor.black.withOpacity(.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.warning_rounded,
                          size: 10.w,
                          color: MyColor.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          _VideoChat(),
        ],
      ),
    );
  }
}

/// 顶部主播信息
class _UserInfo extends StatelessWidget {
  const _UserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: BHLanguageMar().isRightToLeft.value ? Get.width * .3 : 9.w,
      top: kIsWeb
          ? (Get.height * 9 / 16.0 * 0.16) < (DeviceUtil().statusBarHeight ?? 0)
              ? (DeviceUtil().statusBarHeight ?? 0)
              : (Get.height * 9 / 16.0 * 0.16)
          : 20.w,
      right: BHLanguageMar().isRightToLeft.value ? 9.w : Get.width * .3,
      child: GetBuilder<SeeVideoLogic>(
        builder: (logic) {
          if (logic.userInfo == null) {
            return const SizedBox.shrink();
          }
          var countryText = logic.userInfo?.country ?? "";
          var appConfig = Get.find<AppConfigManager>();
          if (appConfig.nameByEmoji.containsKey(countryText)) {
            countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
          } else if (appConfig.codeByEmoji.containsKey(countryText)) {
            countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
          }

          return GestureDetector(
            onTap: () => Get.back(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        margin: EdgeInsets.only(top: 3.w),
                        padding: EdgeInsets.all(3.w),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 10.w,
                          weight: 1.5,
                          color: MyColor.white,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: MyColor.black.withOpacity(.2),
                          borderRadius: BorderRadius.circular(13.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            MyExtendedNetworkImage(
                              url: logic.userInfo?.avatarUrl ?? "",
                              shape: BoxShape.circle,
                              width: 18.w,
                              height: 18.w,
                              fit: BoxFit.cover,
                            ),
                            MyGaps.hGaps2w,
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (logic.userInfo?.nickname ?? "").fixAutoLines(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: MyColor.white,
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1),
                                          child: GetBuilder<SeeVideoLogic>(
                                            builder: (logic) {
                                              return Text(
                                                countryText.fixAutoLines(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: MyColor.white,
                                                  fontSize: 6.sp,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            MyGaps.hGaps2w,
                            GestureDetector(
                              onTap: () => logic.onFollowOrUnFollow(),
                              child: Image.asset(
                                (logic.userInfo?.isFriend ?? false) ? ImageAssets.broadcasterLikes : ImageAssets.broadcasterUnLikes,
                                width: 14.w,
                                height: 14.w,
                              ),
                            ),
                            MyGaps.hGaps2w,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // MyGaps.vGaps5w,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 视频通话
class _VideoChat extends StatelessWidget {
  _VideoChat({Key? key}) : super(key: key);

  final logic = Get.find<SeeVideoLogic>();

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 20.w,
        right: 0,
        left: 0,
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 10.w),
            child: GetBuilder<SeeVideoLogic>(
              builder: (logic) {
                if (logic.userInfo == null) {
                  return const SizedBox.shrink();
                }
                return Obx(()=>CallButton(
                  status: logic.onlineStatus.value,
                  price: BroadcasterCallPriceUtil.displayPerMinutePriceText(
                    broadcaster: logic.userInfo,
                  ),
                  onTap: () {
                    logic.onCall();
                  },
                ));
              },
            ),
          ),
        ));
  }
}
