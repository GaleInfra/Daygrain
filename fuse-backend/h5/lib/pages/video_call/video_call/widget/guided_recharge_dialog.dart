import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/widget/coins_widget.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

/// create: 2023/5/16
/// desc: 主播引导充值
class GuidedRechargeDialog extends StatelessWidget {
  const GuidedRechargeDialog({
    super.key,
    required this.userInfo,
  });

  static Future show({required UserInfoModel userInfo}) async {
    logger.e("csd打开弹窗2");
    await DialogUtil.showDialog(
      keepSingle: true,
      alignment: Alignment.bottomCenter,
      animationType: SmartAnimationType.fade,
      child: GuidedRechargeDialog(userInfo: userInfo),
      tag: "GuidedRechargeDialog",
    );
  }

  //关闭
  static void dismiss() {
    DialogUtil.dismiss(tag: "GuidedRechargeDialog");
  }

  /// 主播数据
  final UserInfoModel userInfo;

  /// 获取VIP持续时间的文本显示
  String _getVipDurationText(CoinGoodsModel item) {
    final validity = item.validity;
    final validityUnit = item.validityUnit;
    final subType = item.subType;

    // 特殊处理周会员类型
    if (subType == 103) {
      return "vip_duration_week".bhTR;
    }

    if (validity == null) return "VIP";

    // 根据有效期单位显示不同文本
    switch (validityUnit) {
      case "day":
        return validity == 1 ? "vip_duration_day".bhTR : "${validity} ${"vip_duration_days".bhTR}";
      case "month":
        return validity == 1 ? "vip_duration_month".bhTR : "${validity} ${"vip_duration_months".bhTR}";
      case "year":
        return validity == 1 ? "vip_duration_year".bhTR : "${validity} ${"vip_duration_years".bhTR}";
      default:
        return "VIP";
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = 5.w + 46.w + 5.w + 10.w + 9.w + DeviceUtil().bottomSafe;
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

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(9.w)),
        color: MyColor.appBackground,
      ),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          MyGaps.vGaps5w,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(23.w),
                      gradient: const LinearGradient(
                        colors: MyColor.btnGradientColors,
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      )),
                  padding: EdgeInsets.all(1.w),
                  child: MyExtendedNetworkImage(
                    url: userInfo.avatarUrl ?? "",
                    width: 46.w,
                    height: 46.w,
                    shape: BoxShape.circle,
                  ),
                ),
                MyGaps.hGaps5w,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (userInfo.nickname ?? "").truncateThan(30),
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      MyGaps.vGaps2w,
                      Text(
                        "${"action_askForLike".bhTR} ${(userInfo.nickname ?? "").truncateThan(15)}?",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 7.sp,
                        ),
                      ),
                      Text(
                        "info_rechargeCall".bhTR,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 7.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MyGaps.vGaps5w,
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w),
              child: GetBuilder<CoinGoodsLogic>(builder: (logic) {
                final list = logic.listData;
                // 获取VIP商品列表和状态
                final vipList = logic.vipList;
                final hasVipProducts = logic.hasVipProducts.value;

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8.w,
                    crossAxisSpacing: 4.w,
                    childAspectRatio: 110.0 / 146.0,
                  ),
                  // itemCount: list.length + (hasVipProducts ? vipList.length : 0),
                  itemCount: list.length ,
                  itemBuilder: (ctx, index) {
                    // 如果有VIP产品，前几个位置显示VIP卡片
                    // if (hasVipProducts && index < vipList.length) {
                    //   final vipItem = vipList[index];
                    //   final duration = vipItem.getDisplyValidity();
                    //   final bonus = vipItem.exchangeCoin != null ? "+${vipItem.exchangeCoin}" : "";

                    //   return VipSubscriptionCard(
                    //     duration: duration,
                    //     price: localPrice(vipItem),
                    //     bonus: bonus,
                    //     isHot: vipItem.tags?.toLowerCase().contains('hot') ?? false,
                    //     isSelected: true, // 默认选中
                    //     onTap: () async {
                    //       await logic.onPay(
                    //         model: vipItem,
                    //         goodsType: GoodsType.normal,
                    //         entry: PayEntry.SOURCE_18,
                    //       );
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
                          StrongGuideSheetV2.show(context);
                        },
                      );
                    }
                    return CoinsWidget(
                      item: item,
                      coinGoodsLogic: logic,
                      onTap: () async {
                        // DialogUtil.dismiss(tag: "GuidedRechargeDialog");
                        await logic.onPay(model: item, goodsType: GoodsType.normal, entry: PayEntry.SOURCE_18);
                      },
                    );
                  },
                );
              }),
            ),
          ),
          //机器人客服入口
          GestureDetector(
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
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 5.w),
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
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.item,
    required this.onTap,
    required this.coinGoodsLogic,
  }) : super(key: key);

  final CoinGoodsModel item;

  final VoidCallback onTap;

  final CoinGoodsLogic coinGoodsLogic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: double.infinity,
            margin: EdgeInsets.only(top: 4.w),
            padding: EdgeInsets.only(left: 2.w, top: 4.w, bottom: 4.w, right: 4.w),
            decoration: BoxDecoration(
              color: item.isPromotion ?? false ? MyColor.purpleC83DFF : MyColor.white.withOpacity(.31),
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      ImageAssets.broadcasterDiamondBig,
                      width: 17.w,
                      height: 17.w,
                    ),
                    MyGaps.hGaps5w,
                    Text(
                      "${item.exchangeCoin ?? 0}${item.extraCoin != null && item.extraCoin! > 0 ? "+${item.extraCoin}" : ""}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MyColor.white,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      localPrice(item),
                      style: TextStyle(
                        color: MyColor.white,
                        fontSize: 7.sp,
                      ),
                    ),
                    SizedBox(
                      width: 3.w,
                    ),
                    Visibility(
                      visible: item.price != item.originalPrice,
                      child: Padding(
                        padding: EdgeInsets.only(right: 3.w),
                        child: Text(
                          localOriginalPrice(item),
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: MyColor.white.withOpacity(.59),
                            fontSize: 7.sp,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: item.price != item.originalPrice,
                      child: SizedBox(
                        width: 3.w,
                      ),
                    ),
                    Visibility(
                      visible: item.discount != null && item.discount! > 0,
                      child: Text(
                        "${(item.discount ?? 0) * 100}%",
                        style: TextStyle(
                          color: (item.isPromotion ?? false) ? MyColor.white : MyColor.green5BFF89,
                          fontSize: 7.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Visibility(
              visible: item.tags != null && !(item.isPromotion ?? false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4.w), topRight: Radius.circular(4.w), bottomRight: Radius.circular(4.w)),
                  gradient: const LinearGradient(colors: [MyColor.purpleDA5DF4, MyColor.purpleB24CE2]),
                ),
                child: Text(
                  "${item.tags}",
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 7.sp,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Visibility(
              visible: (item.isPromotion ?? false) && coinGoodsLogic.promotionSurplusTime.value.inMilliseconds > 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4.w), topRight: Radius.circular(4.w), bottomRight: Radius.circular(4.w)),
                  gradient: const LinearGradient(colors: [MyColor.yellowFFC640, MyColor.yellowFFAC3E]),
                ),
                child: RepaintBoundary(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
                    child: Obx(() {
                      return Text(
                        coinGoodsLogic.promotionSurplusTime.value.toString().split('.').first.padLeft(8, "0"),
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 6.sp,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
