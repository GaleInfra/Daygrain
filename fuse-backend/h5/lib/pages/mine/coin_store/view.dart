import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/coins_widget.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/widget/status/page_status_widget.dart';

import '../../../common_logic/coin_goods_logic.dart';
import '../../../common_logic/app_config_manager.dart';
import '../../../widget/app_bar/default_app_bar.dart';
import '../../../widget/banner/banner_widget.dart';
import 'logic.dart';

/// 金币充值页
class CoinStorePage extends StatelessWidget {
  final logic = Get.find<CoinStoreLogic>();

  CoinStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:const BoxDecoration(
          gradient: LinearGradient(colors: MyColor.messageBGs, begin:  AlignmentDirectional.centerEnd ,end: AlignmentDirectional.centerStart),
       
        ),
      child: Scaffold(
        appBar: DefaultAppBar(
          backIconColor: MyColor.rechargeItemBG,
          titleWidget: Text(
            "title_diamondStore".bhTR,
            style: FontUtils.sansSemiBold(size: 9.sp, color: MyColor.black),
          ),
        ),
        backgroundColor: Colors.transparent,
        body: GetBuilder<CoinStoreLogic>(
          builder: (logic) {
            return PageStatusWidget(
              logic: logic,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 0.w,
                        height: 51.w,
                      ),
                      Image.asset(
                        ImageAssets.coinsStore1,
                        width: 21.w,
                        height: 21.w,
                      ),
                      MyGaps.hGaps5w,
                      GetBuilder<AppConfigManager>(
                        builder: (logic) {
                          return Text(
                            "${logic.userInfo.availableCoins ?? 0}",
                            style: FontUtils.sansSemiBold(
                              color:Colors.white,
                              size: 16.w,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 18.w,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20.w)),
                        color: MyColor.appBackground,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 3.w,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.w),
                            child: BannerWidget(
                              showBanner: true,
                              onlyStrongGuide: true,
                              horizontalPadding: 4.w,
                            ),
                          ),
                          Expanded(
                            child: GetBuilder<CoinGoodsLogic>(
                              builder: (coinLogic) {
                                final list = coinLogic.listData;
                                return GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8.w,
                                    crossAxisSpacing: 4.w,
                                    childAspectRatio: 110.0 / 146.0,
                                  ),
                                  itemCount: list.length,
                                  padding: EdgeInsets.only(
                                      left: 4.w, right: 4.w, bottom: 10.w),
                                  itemBuilder: (ctx, index) {
                                    CoinGoodsModel item = list[index];
                                    if (item.code == "-1") {
                                      return StrongGuideItemWidget(
                                        onTap: () {
                                          StrongGuideSheetV2.show(context);
                                        },
                                      );
                                    }
                                    return CoinsWidget(
                                      item: item,
                                      coinGoodsLogic: coinLogic,
                                      onTap: () => logic.onPay(item),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Visibility(
                            visible: !Get.find<AppConfigManager>()
                                .isReviewPkg
                                .value,
                            child: GestureDetector(
                              onTap: () {
                                // MessageChatPage.to(
                                //   UserInfoModel(
                                //       userId: Get.find<AppConfigManager>()
                                //           .strategyModel
                                //           ?.userServiceAccountId),
                                // );
                                Get.toNamed(RoutePath.robotPage);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 5.w),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      //图标
                                      Image.asset(
                                        ImageAssets.mineService,
                                        width: 9.w,
                                        height: 9.w,
                                        fit: BoxFit.contain,
                                      ),
                                      MyGaps.hGaps5w,
                                      //文字
      
                                      Text(
                                        "title_customerService".bhTR,
                                        style: TextStyle(
                                          color: MyColor.white,
                                          fontSize: 7.sp,
                                        ),
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: DeviceUtil().bottomSafe,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
