import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/MyLinearGradient.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/net/request_repository.dart';

/// create: 2024/1/15
/// desc: 金币商品组件
class CoinsWidget extends StatelessWidget {
  const CoinsWidget({
    Key? key,
    required this.item,
    required this.onTap,
    required this.coinGoodsLogic,
    this.dense = true,
  }) : super(key: key);

  final CoinGoodsModel item;

  final VoidCallback onTap;

  final CoinGoodsLogic coinGoodsLogic;

  /// 收紧
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Align(
              child: Container(
            padding:
                (item.isPromotion ?? false) ? const EdgeInsets.all(1) : null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.w),
              gradient: (item.isPromotion ?? false)
                  ? const LinearGradient(
                      colors: MyColor.btnGradientColors,
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      stops: [0.1, 0.2, 0.3, 0.4, 0.5],
                    )
                  : null,
            ),
            child: Container(),
          )),
          Container(
              width: double.infinity,
              height: 20.w,
              decoration: BoxDecoration(
                gradient: (item.isPromotion ?? false)
                    ? MyLinearGradient.getGradient()
                    : null,
                borderRadius: (item.isPromotion ?? false)
                    ? BorderRadius.only(
                        bottomLeft: Radius.circular(8.w),
                        bottomRight: Radius.circular(8.w))
                    : null,
              )),
          Container(
            padding:
                (item.isPromotion ?? false) ? const EdgeInsets.all(1) : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: MyColor.rechargeItemBG,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8.w),
                                topRight: Radius.circular(8.w)),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 10.w),
                                child: Image.asset(
                                  ImageAssets.coinsStore1,
                                  width: dense ? 20.w : 20.w,
                                  height: dense ? 20.w : 20.w,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${item.exchangeCoin ?? 0}",
                                    style: TextStyle(
                                      color: item.isPromotion ?? false
                                          ? MyColor.white
                                          : MyColor.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Visibility(
                                    visible: item.extraCoin != null &&
                                        item.extraCoin! > 0,
                                    child: Text(
                                      " +${item.extraCoin}",
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: MyColor.white,
                                        fontSize: 6.sp,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Visibility(
                                        visible: item.discount != null &&
                                            item.discount! > 0,
                                        child: Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              "${((item.discount ?? 0) * 100).toStringAsFixed(0)}%off",
                                              style: TextStyle(
                                                color: const Color(0xFFFFE500),
                                                fontSize: 6.sp,
                                              ),
                                            )),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 20.w,
                        decoration: BoxDecoration(
                          gradient: (item.isPromotion ?? false)
                              ? null
                              : MyLinearGradient.getGradient(),
                          borderRadius: (item.isPromotion ?? false)
                              ? null
                              : BorderRadius.only(
                                  bottomLeft: Radius.circular(8.w),
                                  bottomRight: Radius.circular(8.w)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  localPrice(item),
                                  style: TextStyle(
                                    color: MyColor.white,
                                    fontSize: 8.sp,
                                  ),
                                )),
                            MyGaps.hGaps2w,
                            //原价格 中划线
                            Visibility(
                              visible:
                                  localOriginalPrice(item) != localPrice(item),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 3,
                                  ),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      localOriginalPrice(item),
                                      style: TextStyle(
                                        color: const Color(0xFF064BA6),
                                        fontSize: 6.sp,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: BHLanguageMar().isRightToLeft.value ? null : 0,
                    left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                    child: Visibility(
                      visible: item.tags != null &&
                          item.tags!.isNotEmpty &&
                          !(item.isPromotion ?? false),
                      child: Stack(
                        children: [
                          Transform.scale(
                            scaleX:
                                BHLanguageMar().isRightToLeft.value ? -1 : 1,
                            child: Image.asset(
                              ImageAssets.rechargeBgCoinsTag,
                              width: 26.5.w,
                              height: 30.w,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Transform.rotate(
                            angle: BHLanguageMar().isRightToLeft.value
                                ? -48 * pi / 180
                                : 48 * pi / 180,
                            alignment: Alignment.bottomCenter,
                            child: RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.only(top: 6.5.w),
                                child: SizedBox(
                                  width: 26.5.w,
                                  height: 6.w,
                                  child: Center(
                                    child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          "${item.tags}",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: MyColor.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 5.sp,
                                          ),
                                        )),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(() {
                    return Positioned(
                      top: 0,
                      right: BHLanguageMar().isRightToLeft.value ? null : 0,
                      left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                      child: Visibility(
                        // 控制显示，如果倒计时结束则
                        visible: (item.isPromotion ?? false) &&
                            coinGoodsLogic
                                    .promotionSurplusTime.value.inMilliseconds >
                                0,
                        child: Stack(
                          children: [
                            Image.asset(
                              ImageAssets.rechargeBgCoinsPromotionTag,
                              width: 26.5.w,
                              height: 30.w,
                              fit: BoxFit.fill,
                            ).bh,
                            Transform.rotate(
                              angle: BHLanguageMar().isRightToLeft.value
                                  ? -48 * pi / 180
                                  : 48 * pi / 180,
                              alignment: Alignment.bottomCenter,
                              child: RepaintBoundary(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 6.5.w),
                                  child: SizedBox(
                                    width: 26.5.w,
                                    height: 6.w,
                                    child: Center(
                                      child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            coinGoodsLogic
                                                .promotionSurplusTime.value
                                                .toString()
                                                .split('.')
                                                .first
                                                .padLeft(8, "0"),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: MyColor.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 5.sp,
                                            ),
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class StrongGuideItemWidget extends StatefulWidget {
  const StrongGuideItemWidget({
    super.key,
    required this.onTap,
  });
  final VoidCallback onTap;

  @override
  State<StrongGuideItemWidget> createState() => _StrongGuideItemWidgetState();
}

class _StrongGuideItemWidgetState extends State<StrongGuideItemWidget> {
  bool _hasLoggedEntry = false;

  @override
  void initState() {
    super.initState();
    // 组件创建并完成首帧后，上报一次入口展示（每次弹窗重新创建都会重新上报）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoggedEntry) {
        _hasLoggedEntry = true;
        getReqRepo()?.log(
          event: "show",
          page: "strong_guide_rechargePop_entry",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.w),
          image: const DecorationImage(
            image: AssetImage(ImageAssets.strongGuideCoinsItem),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Spacer(),
          Container(
            height: 22.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF73D65),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.w),
                bottomRight: Radius.circular(8.w),
              ),
            ),
            child: Center(
              child: Text(
                "Upgrade to Premium".bhTR,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: MyColor.white,
                  fontSize: 6.sp,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// 新增：VIP订阅卡片Widget
class VipSubscriptionCard extends StatelessWidget {
  final String duration;
  final String price;
  final String bonus;
  final bool isHot;
  final bool isSelected;
  final VoidCallback? onTap;

  const VipSubscriptionCard({
    Key? key,
    required this.duration,
    required this.price,
    required this.bonus,
    this.isHot = false,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取CoinGoodsLogic实例检查用户是否有VIP权益
    final coinGoodsLogic = Get.find<CoinGoodsLogic>();

    // 如果用户已有VIP权益，则不显示此卡片
    if (coinGoodsLogic.hasVipEquity()) {
      return const SizedBox(); // 返回空组件，不显示任何内容
    }

    final Color borderColor =
        isSelected ? Color(0xFFFFDAB1) : const Color(0xFF2F2F2F);
    final Color textColor = Colors.white;
    final Color priceColor = isSelected ? Colors.black : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: borderColor,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(color: borderColor, width: 0.6.w),
        ),
        padding: EdgeInsets.all(1.w),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 上半部分
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isSelected
                          ? [Color(0xFF623C0F), Color(0xFF050503)]
                          : [Color(0xFF232323), Color(0xFF232323)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.w),
                      topRight: Radius.circular(8.w),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.75.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8.w),
                                  bottomRight: Radius.circular(2.w)),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  ImageAssets.coins,
                                  width: 10.w,
                                  height: 10.w,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  bonus,
                                  style: TextStyle(
                                    color: Color(0xFFFFD500),
                                    fontSize: 6.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.w),
                      Image.asset(
                        ImageAssets.queen,
                        width: 17.w,
                        height: 17.w,
                      ),
                      SizedBox(height: 1.w),
                      Text(
                        duration,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 9.w),
                    ],
                  ),
                ),
                // 下半部分
                Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFFFDAB1) : Color(0xFF363636),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4.w),
                      bottomRight: Radius.circular(4.w),
                    ),
                  ),
                  padding: EdgeInsets.only(top: 4.w, bottom: 2.w),
                  child: Center(
                    child: Text(
                      price,
                      style: TextStyle(
                        color: Color(0xFF1B1A18),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w500,
                        
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
              ],
            ),
            if (isHot)
              Positioned(
                top: 3.w,
                right: -6.w,
                child: Image.asset(
                  ImageAssets.hot,
                  width: 29.w,
                  height: 8.w,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
