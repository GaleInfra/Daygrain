import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/LocalRechargeEvent.dart';
import 'package:untitled1/event_bus/recharge/recharge_event.dart';
import 'package:untitled1/generated/assets.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/MyLinearGradient.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';

/// create: 2023/4/24
/// desc: 新版活动促销弹窗
class SpecialOfferDialog extends StatefulWidget {
  static const String tag = "SpecialOfferDialog";

  SpecialOfferDialog({super.key});
  LogHandle logHandle = LogHandle();

  static Future show({BuildContext? bindWidget}) async {
    var dialog =  SpecialOfferDialog();
    try {
      await dismiss();
    } catch (e) {}
    dialog.logHandle.initLog('special_recharge_dialog',);
    return DialogUtil.showDialog(
        keepSingle: true,
        tag: tag,
        clickMaskDismiss: false,
        // bindPage: true,
        bindWidget: bindWidget,
        child: dialog,
        onDismiss: () {
          dialog.logHandle.onClose();
        });
  }
  
  //关闭
  static Future<void> dismiss() async {
    await DialogUtil.dismiss(tag: tag);
  }

  @override
  State<SpecialOfferDialog> createState() => _SpecialOfferDialogState();
}

class _SpecialOfferDialogState extends State<SpecialOfferDialog> {
  StreamSubscription<RechargeEvent>? _rechargeEvent;
  StreamSubscription<LocalRechargeEvent>? _localRechargeEvent;

  
  final logic = Get.find<CoinGoodsLogic>();

  void cancelEvent() {
    _rechargeEvent?.cancel();
    _localRechargeEvent?.cancel();
  }

  @override
  void initState() {
    super.initState();
    

    // 活动促销弹窗的额外赠送比例逻辑
    // 如果用户有三方支付，则选择活动商品与三方支付中，赠送比例最大的一个进行显示
    // 若不支持三方，则显示商品原有的比例
    _rechargeEvent = EventBusUtil.listen<RechargeEvent>((event) async {
      if (event.model.status == 2) {
        DialogUtil.dismiss(tag: SpecialOfferDialog.tag);
      }
    });

    _localRechargeEvent =
        EventBusUtil.listen<LocalRechargeEvent>((event) async {
      DialogUtil.dismiss(tag: SpecialOfferDialog.tag);
    });
  }

  @override
  void dispose() {
    cancelEvent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 最大赠送比例
    num maxCoinRatio = 0;
    if (logic.channelList.isNotEmpty) {
      // 有三方渠道，获取三方比例
      maxCoinRatio = logic.specialOfferModel?.thirdpartyCoinPercent ?? 0;
    } else {
      // 无三方，获取普通额外比例
      maxCoinRatio = logic.specialOfferModel?.extraCoinPercent ?? 0;
    }
    // 获取三方中最大的赠送比例
    for (var element in logic.channelList) {
      if (logic.specialOfferModel?.isPromotion ?? false) {
        // 促销
        if ((element.promotionPresentCoinRatio ?? 0) > maxCoinRatio) {
          maxCoinRatio = element.promotionPresentCoinRatio ?? 0;
        }
      } else {
        // 非促销
        if ((element.presentCoinRatio ?? 0) > maxCoinRatio) {
          maxCoinRatio = element.presentCoinRatio ?? 0;
        }
      }
    }
    // 额外的金币数量
    String extraCoin =
        ((logic.specialOfferModel?.exchangeCoin ?? 0) * (maxCoinRatio / 100))
            .toStringAsFixed(0);

    // 剩余可充值次数
    num residueNum = logic.specialOfferModel?.capableRechargeNum ?? 0;
    residueNum -= logic.specialOfferModel?.rechargeNum ?? 0;

    double containerW = (Get.width - 24.w);

   double containerH = containerW * 459 / 350.0;

    double aspectRatio =  640.0/480.0;

    //计算视频组件的宽高 使其充满屏幕
    double videoWidth = containerW;
    double videoHeight = containerH;
    double scale = 1.0;
    if (videoWidth / aspectRatio > videoHeight) {
      videoHeight = videoWidth / aspectRatio;
      scale = videoHeight / containerH;
    } else {
      videoWidth = videoHeight * aspectRatio;
      scale = videoWidth / containerW;
    }
    return Container(
      width: containerW,
      decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.w),
              color: MyColor.gray45,
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: containerW,
            height: containerH ,
            
            child: Stack(
              children: [
                SizedBox(
                  width: containerW,
                  height: containerH ,
                  child: Container(
                    color: Colors.transparent,
                    height: videoHeight,
                    width: videoWidth,
                    alignment: Alignment.topLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.w),
                        topRight: Radius.circular(8.w),
                      ),
                      child: SizedBox(
                              width: videoWidth,
                              height: videoHeight,
                              child: AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Image.asset(
                                  Assets.specialOfferJpeg,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                //
                Positioned(
                  bottom: 5.w,
                  left: 5.w,
                  right: 5.w,
                  child: Text(
                        "offer_limitedTime".bhTR,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF00FFEC),
                          fontSize: 10.sp,
                        ),
                      ),),
               
      
                ///头部那两个按钮
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 6.w),
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    width: double.infinity,
                    height: 16.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Container(
                          width: 36.w,
                          height: 13.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: MyColor.btnGradientColors,
                              begin: BHLanguageMar().isRightToLeft.value
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              end: BHLanguageMar().isRightToLeft.value
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: RepaintBoundary(
                            child: Obx(() {
                              return Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    logic.specialOfferSurplusTime.value
                                        .toString()
                                        .split('.')
                                        .first
                                        .padLeft(8, "0"),
                                    style: TextStyle(
                                      color: MyColor.white,
                                      fontSize: 6.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ));
                            }),
                          ),
                        ),
                        
                        GestureDetector(
                          onTap: () {
                            DialogUtil.dismiss(tag: SpecialOfferDialog.tag);
                          },
                          child: Container(
                            width: 14.w,
                            height: 14.w,
                            decoration: BoxDecoration(
                              color: MyColor.black.withOpacity(.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 10.w,
                              color: MyColor.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
                        width: double.infinity,
                        height: 45.w,
                        padding: EdgeInsets.symmetric(horizontal: 7.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.w),
                            bottomRight: Radius.circular(8.w),
                          ),
                          gradient: MyLinearGradient.getGradient(),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(ImageAssets.coinsStore1,
                                width: 21.5.w,
                                height: 21.5.w,
                                fit: BoxFit.contain),
                            SizedBox(
                              width: 4.w,
                            ),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AutoSizeText(
                                  "${logic.specialOfferModel?.exchangeCoin ?? 0} ${"Coins".bhTR}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: MyColor.white,
                                    fontSize: 12.5.sp,
                                  ),
                                ),
                                if (extraCoin.isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(top: 2.w),
                                    child: AutoSizeText(
                                      "+$extraCoin  ${"Coins".bhTR}",
                                      style: TextStyle(
                                        color: MyColor.yellowFF,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  )
                              ],
                            )),
                            GestureDetector(
                              onTap: () async {
                                await logic.onPay(
                                  model: logic.specialOfferModel!,
                                  goodsType: GoodsType.specialOffer,
                                  entry: PayEntry.SOURCE_29,
                                );
                              },
                              child: SizedBox(
                                width: 50.w,
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        width: 50.w,
                                        height: 23.w,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(11.5.w),
                                            color: MyColor.blank1E),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                localPrice(
                                                    logic.specialOfferModel ??
                                                        CoinGoodsModel()),
                                                style: TextStyle(
                                                    color: MyColor.white,
                                                    fontSize: 9.sp,
                                                    fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            if (logic.specialOfferModel?.price !=
                                                logic.specialOfferModel
                                                    ?.originalPrice)
                                              SizedBox(
                                                height: 1.w,
                                              ),
                                            if (logic.specialOfferModel?.price !=
                                                logic.specialOfferModel
                                                    ?.originalPrice)
                                              Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Text(
                                                    localOriginalPrice(
                                                        logic.specialOfferModel ??
                                                            CoinGoodsModel()),
                                                    style: TextStyle(
                                                      color: MyColor.greyD5,
                                                      fontSize: 6.5.sp,
                                                      decorationColor: Colors.white,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  )),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (residueNum > 1)
                                      Align(
                                          alignment:
                                              BHLanguageMar().isRightToLeft.value
                                                  ? Alignment.topLeft
                                                  : Alignment.topRight,
                                          child: Container(
                                            width: 14.5.w,
                                            height: 10.w,
                                            margin: EdgeInsets.only(top: 5.w),
                                            child: Stack(
                                              children: [
                                                Align(
                                                  child: Image.asset(
                                                    ImageAssets.activityNum,
                                                    width: 14.5.w,
                                                    height: 10.w,
                                                  ).bh,
                                                ),
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Directionality(
                                                      textDirection:
                                                          TextDirection.ltr,
                                                      child: Text(
                                                        "x$residueNum",
                                                        style: TextStyle(
                                                            color: MyColor.white,
                                                            fontSize: 5.sp,
                                                            fontWeight:
                                                                FontWeight.w400),
                                                      )),
                                                ),
                                              ],
                                            ),
                                          ))
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
        ],
      ),
    );
  }
}
