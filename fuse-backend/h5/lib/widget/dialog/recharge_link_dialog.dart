import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/net/request_repository.dart';

import '../../common_logic/coin_goods_logic.dart';
import '../../model/mine/coin_goods_model.dart';
import '../../res/my_color.dart';
import '../../res/pay_entry.dart';
import '../../utils/font_utils.dart';
import '../coins_widget.dart';

/// create: 2023/5/25
/// desc: 充值邀请链接弹窗
class RechargeLinkDialog extends StatelessWidget {
  RechargeLinkDialog.show({
    super.key,
    required List<CoinGoodsModel> list,
    required BuildContext bindWidget,
  }) : list = CoinGoodsLogic.filterNonVipCoinGoods(list) {
    logHandle.initLog('recharge_invitation_dialog');
    DialogUtil.showDialog(
      alignment: Alignment.bottomCenter,
      child: this,
      keepSingle: true,
      bindPage: true,
      bindWidget: bindWidget,
      animationType: SmartAnimationType.fade,
      onDismiss: (){
        logHandle.onClose();
      },
      tag: "RechargeLinkDialog",
    );
  }

  static void dismiss() {
    DialogUtil.dismiss(tag: "RechargeLinkDialog");
  }
  final LogHandle logHandle = LogHandle();
  final List<CoinGoodsModel> list;

  final appConfig = Get.find<AppConfigManager>();

  final coinGoodsLogic = Get.find<CoinGoodsLogic>();

  @override
  Widget build(BuildContext context) {
    double height = 5.w + 37.w + 8.w + 7.w + 6.w + 9.w + DeviceUtil().bottomSafe;
    int itemCount = list.length;
    int rowCount = (itemCount / 3).ceil();
    if (itemCount == 0) {
      rowCount = 2;
    }
    double itemWidth = (Get.width - 18.w - 8.w) / 3.0 ;
    height += (itemWidth * 146.0 / 110.0 + 8.w) * rowCount;
    height = min(height, Get.height * 0.9);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
          gradient:const LinearGradient(colors: MyColor.messageBGs, begin:  AlignmentDirectional.centerEnd ,end: AlignmentDirectional.centerStart),
          borderRadius: BorderRadius.all(Radius.circular(20.w))
          ),
          child: Stack(
            children: [
             // 在这里添加下拉指示器
              Positioned(
                top: 3.w,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40.w,
                    height: 2.5.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2.5.w),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 5.w, bottom: 1.5.w),
                    child: SizedBox(
                      width: double.infinity,
                      height: 37.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 16.w,),
                          Image.asset(
                            ImageAssets.coinsStore1,
                            width: 21.w,
                            height: 21.w,
                          ),
                          MyGaps.hGaps5w,
                          Text(
                              "lable_my_coins".bhTR,
                            style: FontUtils.boldItalic(
                              color: const Color(0xFF2C2B29),
                              size: 10.sp,
                            ),
                          ),
                          const Spacer(
                            flex: 1,
                          ),
                          GetBuilder<AppConfigManager>(
                            builder: (appConfig) {
                              return Text(
                                "${appConfig.userInfo.availableCoins ?? 0}",
                                maxLines: 1,
                                style: FontUtils.sansSemiBold(
                                  color: Colors.white,
                                  size: 10.sp,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 16.w,),
                        ],
                      ),
                    ),
                  ),
                 
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20.w)),
                        color: MyColor.appBackground,
                      ),
                      child: Column(
                        children: [
                         SizedBox(
                          height: 8.w,
                         ),
                          Expanded(
                            child: GridView.builder(
                              itemCount: list.length,
                              padding: EdgeInsets.symmetric(horizontal: 9.w),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8.w,
                                crossAxisSpacing: 4.w,
                                childAspectRatio: 110.0 / 146.0,
                              ),
                              itemBuilder: (ctx, index) {
                                CoinGoodsModel item = list[index];
                                if (item.code == "-1") {
                                  return StrongGuideItemWidget(
                                    onTap: () {
                                      getReqRepo()?.log(
                                        event: "click",
                                        page: "strong_guide_rechargePop_entry",
                                      );
                                      StrongGuideSheetV2.show(context);
                                    },
                                  );
                                }
                                return CoinsWidget(
                                  item: list[index],
                                  onTap: () {
                                    // DialogUtil.dismiss();
                                    coinGoodsLogic.onPay(
                                      model: list[index],
                                      goodsType: GoodsType.rechargeLink,
                                      entry: PayEntry.SOURCE_17,
                                    );
                                  },
                                  coinGoodsLogic: coinGoodsLogic,
                                );
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              //关闭弹窗
                              RechargeLinkDialog.dismiss();

                              // MessageChatPage.to(
                              //   UserInfoModel(
                              //       userId: Get.find<AppConfigManager>()
                              //           .strategyModel
                              //           ?.userServiceAccountId),
                              // );
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                Get.toNamed(RoutePath.robotPage);
                              });
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
                          SizedBox(
                            height: DeviceUtil().bottomSafe,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
