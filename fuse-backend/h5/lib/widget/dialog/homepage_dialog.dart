import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/banner_strong_guide_logic.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/net/request_repository.dart';

import '../../common_logic/coin_goods_logic.dart';
import '../../pages/broadcaster/widget/promotion_dialog.dart';
import '../../pages/broadcaster/widget/special_offer_dialog.dart';
import '../../pages/index/logic.dart';
import '../../res/image_assets.dart';

/// create: 2023/5/23
/// desc: 主页右下角的悬浮按钮合集
class HomePageDialog extends StatelessWidget {
  HomePageDialog({Key? key}) : super(key: key);

  // 防止重复上报：导量入口显示
  static bool _hasLoggedStrongGuideEntryShow = false;

  /// 商品/促销商品管理
  final coinGoodsLogic = Get.find<CoinGoodsLogic>();
  final indexLogic = Get.find<IndexLogic>();
  final appConfig = Get.find<AppConfigManager>();
  final strongGuide = Get.find<BannerStrongGuideLogic>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Positioned(
      left: BHLanguageMar().isRightToLeft.value ? 0 : null,
      right: BHLanguageMar().isRightToLeft.value ? null : 0,
      bottom: 12.w,
      child: _buildFloatingWidget(context),
    ));
  }

  Widget _buildFloatingWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// 活动促销悬浮
        Obx(() {
          bool show = !appConfig.isReviewPkg.value &&
              coinGoodsLogic.specialOfferSurplusTime.value.inMilliseconds > 0 &&
              indexLogic.currentIndex.value != 1 &&
              indexLogic.currentIndex.value != 3;
          return Visibility(
            visible: show,
            child: GestureDetector(
              onTap: () {
                if (!appConfig.isReviewPkg.value) {
                  SpecialOfferDialog.show(bindWidget: indexLogic.pageKey.currentContext!);
                }
              },
              child: Container(
                margin: EdgeInsets.only(top: 7.w),
                width: 35.w,
                height: 33.w,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Transform.scale(
                      scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                      child: Image.asset(
                        ImageAssets.homeActivite,
                        fit: BoxFit.contain,
                        width: 27.w,
                      ),
                    ),
                    Positioned(
                      bottom: 0.w,
                      child: RepaintBoundary(
                        child: Container(
                          width: 30.w,
                          height: 10.w,
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                          ),
                          decoration: BoxDecoration(
                            color: MyColor.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(5.w),
                          ),
                          child: Center(
                            child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  coinGoodsLogic.specialOfferSurplusTime.value.toString().split('.').first.padLeft(8, "0"),
                                  style: TextStyle(
                                    color:const Color(0xFF85D3FF),
                                    fontSize: 5.sp,
                                  ),
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // MyGaps.vGaps5w,
        /// 新用户促销悬浮
        Obx(() {
          bool show = !appConfig.isReviewPkg.value &&
              coinGoodsLogic.promotionSurplusTime.value.inMilliseconds > 0 &&
              indexLogic.currentIndex.value != 1 &&
              indexLogic.currentIndex.value != 3;
          return Visibility(
            visible: show,
            child: Padding(
              padding: EdgeInsets.only(top: 7.w),
              child: GestureDetector(
                onTap: () {
                  if (!appConfig.isReviewPkg.value) {
                    PromotionDialog.show(bindWidget: indexLogic.pageKey.currentContext!);
                  }
                },
                child: SizedBox(
                  width: 35.w,
                  height: 32.w,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Transform.scale(
                        scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                        child: Image.asset(
                          ImageAssets.homeNewUser,
                          fit: BoxFit.contain,
                          width: 27.w,
                        ),
                      ),
                      Positioned(
                        bottom: 0.w,
                        child: RepaintBoundary(
                          child: Container(
                            width: 30.w,
                            height: 10.w,
                            padding: EdgeInsets.symmetric(horizontal: 2.w),
                            decoration: BoxDecoration(
                              color: MyColor.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(5.w),
                            ),
                            child: Center(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  coinGoodsLogic.promotionSurplusTime.value.toString().split('.').first.padLeft(8, "0"),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFFFEDC00),
                                    fontSize: 5.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        /// 金币商店悬浮
        Obx(() {
          return Visibility(
            visible: !appConfig.isReviewPkg.value && indexLogic.currentIndex.value != 1 && indexLogic.currentIndex.value != 3,
            child: Padding(
              padding: EdgeInsets.only(top: 7.w),
              child: GestureDetector(
                onTap: () => RechargeDialog.show(entry: "", bindWidget: context), //Get.toNamed(RoutePath.coinStorePage),
                child: SizedBox(
                  width: 35.w,
                  height: 27.w,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Image.asset(
                        ImageAssets.homeStore,
                        fit: BoxFit.fitWidth,
                        width: 27.w,
                        height: 27.w,
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        /// 导量
        Obx(() {
          final visible = !appConfig.isReviewPkg.value && strongGuide.strongGuideModel.value?.guideMode == 3 && indexLogic.currentIndex.value != 1 && indexLogic.currentIndex.value != 3;
          if (visible && !_hasLoggedStrongGuideEntryShow) {
            _hasLoggedStrongGuideEntryShow = true;
            getReqRepo()?.log(
              event: "show",
              page: "strong_guide_permanent_entry",
            );
          }
          return Visibility(
            visible: visible,
            child: Padding(
              padding: EdgeInsets.only(top: 5.w),
              child: GestureDetector(
                onTap: () {
                  getReqRepo()?.log(
                    event: "click",
                    page: "strong_guide_permanent_entry",
                  );
                  StrongGuideSheetV2.show(context);
                }, //Get.toNamed(RoutePath.coinStorePage),
                child: SizedBox(
                  width: 35.w,
                  height: 34.w,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Image.asset(
                        ImageAssets.homeStrongGuide,
                        fit: BoxFit.contain,
                        width: 30.w,
                      ),
                      Positioned(
                        bottom: 0.w,
                        child: RepaintBoundary(
                          child: Container(
                            width: 30.w,
                            height: 10.w,
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                            ),
                            decoration: BoxDecoration(
                              color: MyColor.redFF1F1F,
                              borderRadius: BorderRadius.circular(5.w),
                            ),
                            child: Center(
                              child: Text(
                                "label_upgrade".bhTR,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 5.sp,
                                  color: MyColor.white,
                                  fontWeight: FontWeight.bold, // Equivalent to UIColor(red: 0, green: 0.87, blue: 1, alpha: 1)
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
