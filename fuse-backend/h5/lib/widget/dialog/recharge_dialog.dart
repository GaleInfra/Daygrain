import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/banner/banner_widget.dart';
import 'package:untitled1/widget/coins_widget.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
// import 'package:untitled1/widget/vip_widget/vip_access.dart';
import 'package:untitled1/widget/dialog/vip_coin_gift_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
import 'package:untitled1/net/request_repository.dart';

import '../../common_logic/app_config_manager.dart';
import '../../common_logic/coin_goods_logic.dart';
import '../../model/mine/coin_goods_model.dart';
import '../../res/image_assets.dart';
import '../../res/my_color.dart';
import '../../res/my_gaps.dart';
import '../../res/pay_entry.dart';
import '../../utils/common_util.dart';
import 'pay_channel_dialog.dart';

/// create: 2023/6/1
/// desc: 充值弹窗
class RechargeDialog extends StatelessWidget {
  RechargeDialog({
    Key? key,
    required this.entry,
  }) : super(key: key);
  final LogHandle logHandle = LogHandle();

  /// 调起充值弹窗
  static void show({required String entry, required BuildContext? bindWidget}) async {
    //关闭键盘
    FocusManager.instance.primaryFocus?.unfocus();
    //关闭旧的充值弹窗
    await dismiss();

    try {
      // 刷新用户金币
      Get.find<AppConfigManager>().onGetInfo();
      final coinGoodsLogic = Get.find<CoinGoodsLogic>();
      coinGoodsLogic.getCoinPayChannelGet();
      // 无需阻塞请求，金币刷新会自动刷新页面
      coinGoodsLogic.getCoinPromotion();
      coinGoodsLogic.getCoinGoodsSearch(bindPage: false, showLoading: false);
      RechargeDialog recharge = RechargeDialog(entry: entry);
      recharge.logHandle.initLog("recharge_dialog");
      DialogUtil.showDialog(
        alignment: Alignment.bottomCenter,
        keepSingle: true,
        bindPage: true,
        debounce: true,
        animationType: SmartAnimationType.fade,
        child: recharge,
        onDismiss: () {
          Toast.dismiss();
          recharge.logHandle.onClose();
        },
        tag: tag,
      );
    } catch (e) {
      logger.e("充值弹窗显示错误: $e");
    }
  }

  ///无需显示客服的来源有哪些
  final List<String> noShowCustomerList = [
    PayEntry.SOURCE_5,
    PayEntry.SOURCE_6,
    PayEntry.SOURCE_13,
    PayEntry.SOURCE_18,
    PayEntry.SOURCE_36,
    PayEntry.SOURCE_44,
    PayEntry.SOURCE_5,
  ];

  static Future<void> dismiss() async {
    await DialogUtil.dismiss(tag: tag);
  }

  final appConfig = Get.find<AppConfigManager>();

  final String entry;

  static const String tag = "RechargeDialog";


  @override
  Widget build(BuildContext context) {
    double height = 5.w + 37.w + 8.w + 7.w + 6.w + 9.w + DeviceUtil().bottomSafe + 16.w;
    int itemCount = 0;
    if (Get.isRegistered<CoinGoodsLogic>()) {
      itemCount = Get.find<CoinGoodsLogic>().listData.length;
    }
    int rowCount = (itemCount / 3).ceil();
    if (itemCount == 0) {
      rowCount = 2;
    }
    double itemWidth = (Get.width - 18.w - 8.w) / 3.0;
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
              gradient: const LinearGradient(colors: MyColor.messageBGs, begin: AlignmentDirectional.centerEnd, end: AlignmentDirectional.centerStart),
              borderRadius: BorderRadius.all(Radius.circular(20.w))),
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
                          SizedBox(
                            width: 16.w,
                          ),
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
                          SizedBox(
                            width: 16.w,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                      child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
                      color: MyColor.appBackground,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 8.w,
                        ),

                      
                        MyGaps.vGaps5w,
                        Expanded(
                          child: GetBuilder<CoinGoodsLogic>(builder: (logic) {
                            final list = logic.listData;

                            // // 使用实际VIP数据而非写死的数据
                            // final hasVipProducts = logic.hasVipProducts.value;
                            // final vipList = logic.vipList;

                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8.w,
                                crossAxisSpacing: 4.w,
                                childAspectRatio: 110.0 / 146.0,
                              ),
                              // itemCount: list.length + (hasVipProducts ? vipList.length : 0),
                              itemCount: list.length,
                              padding: EdgeInsets.symmetric(horizontal: 9.w),
                              itemBuilder: (ctx, index) {
                                // 如果有VIP产品，前几个位置显示VIP卡片
                                // if (hasVipProducts && index < vipList.length) {
                                //   final vipItem = vipList[index];
                                //   final duration = _getVipDurationText(vipItem);
                                //   final bonus = vipItem.exchangeCoin != null
                                //       ? "+${vipItem.exchangeCoin}"
                                //       : "";

                                //   return VipSubscriptionCard(
                                //     duration: duration,
                                //     price: localPrice(vipItem),
                                //     bonus: bonus,
                                //     isHot: vipItem.tags
                                //             ?.toLowerCase()
                                //             .contains('hot') ??
                                //         false,
                                //     isSelected: true, // 默认选中
                                //     onTap: () {

                                //       // 执行支付
                                //       logic.onPay(
                                //         model: vipItem,
                                //         goodsType: GoodsType.normal, // 使用普通支付流程
                                //         entry: entry,
                                //       );

                                //       // 添加监听器，在支付成功后显示金币赠送弹窗
                                //       if (vipItem.exchangeCoin != null &&
                                //           vipItem.exchangeCoin! > 0) {
                                //         // 使用Worker监听支付成功
                                //         Worker? paySuccessWorker;
                                //         paySuccessWorker = ever(
                                //             logic.payLogic.paySuccessGoodsCode,
                                //             (String code) {
                                //           if (code == vipItem.code) {
                                //             // 支付成功，显示金币赠送弹窗
                                //             Future.delayed(
                                //                 const Duration(
                                //                     milliseconds: 500), () {
                                //               VipCoinGiftDialog.show(
                                //                   coins: vipItem.exchangeCoin!
                                //                       .toInt());
                                //             });
                                //             // 取消监听
                                //             paySuccessWorker?.dispose();
                                //           }
                                //         });
                                //       }
                                //     },
                                //   );
                                // }

                                // 后续位置显示原有充值商品
                                // final adjustedIndex = hasVipProducts ? index - vipList.length : index;
                                 final adjustedIndex = index;
                                CoinGoodsModel item = list[adjustedIndex];
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
                                  item: item,
                                  coinGoodsLogic: logic,
                                  onTap: () {
                                    logic.onPay(
                                      model: item,
                                      goodsType: item.goodsId == logic.specialOfferModel?.goodsId ? GoodsType.promotion : GoodsType.normal,
                                      entry: entry,
                                    );
                                  },
                                );
                              },
                            );
                          }),
                        ),
                        //机器人客服入口
                        noShowCustomerList.contains(entry) || appConfig.isReviewPkg.value
                            ? MyGaps.vGaps10w
                            : GestureDetector(
                                onTap: () {
                                  //跳转到客服
                                  Get.toNamed(RoutePath.robotPage);
                                },
                                child: Container(
                                  padding: EdgeInsets.only(left: 2.w, right: 2.w, bottom: 6.w, top: 7.w),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                                        fontSize: 6.sp,
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
                  ))
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
