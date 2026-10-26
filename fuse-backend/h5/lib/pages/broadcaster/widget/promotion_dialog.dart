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
import 'package:untitled1/widget/status/state_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';

/// create: 2023/4/24
/// desc: 新用户促销弹窗
class PromotionDialog extends StatefulWidget {
  static const String tag = "PromotionDialog";
  LogHandle logHandle = LogHandle();
  PromotionDialog({super.key});

  static Future show({
    BuildContext? bindWidget,
    VoidCallback? onDismiss,
  }) async {
    await dismiss();
    var dialog = PromotionDialog();
    dialog.logHandle.initLog('promotion_dialog');

    return DialogUtil.showDialog(
        keepSingle: true,
        tag: tag,
        clickMaskDismiss: false,
        bindPage: true,
        bindWidget: bindWidget,
        child: dialog,
        onDismiss: () {
          dialog.logHandle.onClose();
          onDismiss?.call();
        });
  }

  static Future dismiss() {
    return DialogUtil.dismiss(tag: tag);
  }

  @override
  State createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<PromotionDialog> {
  StreamSubscription<RechargeEvent>? _rechargeEvent;
  StreamSubscription<LocalRechargeEvent>? _localRechargeEvent;
  final logic = Get.find<CoinGoodsLogic>();

  late VideoPlayerController videoController;
  ChewieController? chewieController;
  final isPlaying = false.obs;
  StreamSubscription? _appLifecycleSubscription;

  void cancelEvent() {
    videoController.dispose();
    chewieController?.dispose();
    _rechargeEvent?.cancel();
    _rechargeEvent = null;
    _localRechargeEvent?.cancel();
    _localRechargeEvent = null;
    _appLifecycleSubscription?.cancel();
  }

  @override
  dispose() {
    super.dispose();
    cancelEvent();
  }

  @override
  void initState() {
    super.initState();
    videoController = VideoPlayerController.asset(Assets.newUserMp4);
    videoController.setLooping(true);
    videoController.addListener(() {
      if (videoController.value.isInitialized) {
        if (chewieController == null) {
            chewieController = ChewieController(
                      videoPlayerController: videoController,
                      autoPlay: true,
                      looping: true,
                      showControls: false,
                      aspectRatio: 640.0 / 480.0,
                    );
                    if (!videoController.value.isPlaying) {
          videoController.seekTo(Duration.zero);
          videoController.play();
          isPlaying.value = true;
          setState(() {});
        }
        }
      }
    });
    videoController.initialize().then((value) {});

    //监听前后台切换
    _appLifecycleSubscription =
        EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        if (videoController.value.isInitialized) {
          if (!videoController.value.isPlaying) {
            videoController.play();
            isPlaying.value = true;
            setState(() {});
          }
        }
      } else if (event.state == AppLifecycleState.paused) {
        if (videoController.value.isInitialized) {
          if (videoController.value.isPlaying) {
            videoController.pause();
            isPlaying.value = false;
            setState(() {});
          }
        }
      }
    });

    _rechargeEvent = EventBusUtil.listen<RechargeEvent>((event) async {
      if (event.model.status == 2) {
        DialogUtil.dismiss(tag: PromotionDialog.tag);
      }
    });

    _localRechargeEvent =
        EventBusUtil.listen<LocalRechargeEvent>((event) async {
      DialogUtil.dismiss(tag: PromotionDialog.tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    double containerW = (Get.width - 24.w);

    double containerH = containerW * 680 / 500.0;

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
        color: MyColor.black.withValues(alpha: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerW,
            height: containerH,
            child: Stack(
              children: [
                Container(
                  width: containerW,
                  height: containerH,
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
                      child: Transform.scale(
                        scale: scale,
                        child: Obx(
                          () => Stack(
                            children: [
                              Offstage(
                                offstage: !(isPlaying.value &&
                                    chewieController != null),
                                child: chewieController != null
                                    ? Chewie(controller: chewieController!)
                                    : Container(),
                              ),
                              if(!isPlaying.value || chewieController == null)
                              const Center(
                                      child: LoadingWidget(),
                                    )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5.w,
                  left: 5.w,
                  right: 5.w,
                  child: Text(
                    "A Worthful Discount for New User!".bhTR,
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
                                    logic.promotionSurplusTime.value
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
                            DialogUtil.dismiss(tag: PromotionDialog.tag);
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
                    width: 21.5.w, height: 21.5.w, fit: BoxFit.contain),
                SizedBox(
                  width: 4.w,
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      "${logic.promotionModel?.exchangeCoin ?? 0} ${"Coins".bhTR}",
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MyColor.white,
                        fontSize: 12.5.sp,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 2.w),
                      child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: AutoSizeText(
                            '${((logic.promotionModel?.discount ?? 100) * 100).ceil()}%off',
                            style: TextStyle(
                              color: MyColor.yellowFF,
                              fontSize: 9.sp,
                            ),
                          )),
                    )
                  ],
                )),
                GestureDetector(
                  onTap: () async {
                    await logic.onPay(
                      model: logic.promotionModel!,
                      goodsType: GoodsType.promotion,
                      entry: PayEntry.SOURCE_15,
                    );
                  },
                  child: Container(
                    width: 50.w,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 50.w,
                            height: 24.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11.5.w),
                                color: MyColor.blank1E),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      localPrice(logic.promotionModel ??
                                          CoinGoodsModel()),
                                      style: TextStyle(
                                          color: MyColor.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w700),
                                    )),
                                if (logic.promotionModel?.price !=
                                    logic.promotionModel?.originalPrice)
                                  SizedBox(
                                    height: 1.w,
                                  ),
                                if (logic.promotionModel?.price !=
                                    logic.promotionModel?.originalPrice)
                                  Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        localOriginalPrice(
                                            logic.promotionModel ??
                                                CoinGoodsModel()),
                                        style: TextStyle(
                                          color: MyColor.greyD5,
                                          fontSize: 6.5.sp,
                                          decorationColor: Colors.white,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      )),
                              ],
                            ),
                          ),
                        )
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
