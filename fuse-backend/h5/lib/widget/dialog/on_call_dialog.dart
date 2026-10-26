import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/video_call/hang_up_model.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/utils/overlay_util.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../common_logic/app_config_manager.dart';
import '../../res/image_assets.dart';
import '../../res/my_gaps.dart';
import '../../res/video_call_data.dart';
import '../../utils/common_util.dart';
import '../image/my_extended_network_image.dart';

const double _defaultTop = 0;

/// create: 2023/5/8
/// desc: 被呼叫顶部弹窗
class OnCallDialog extends StatefulWidget {
  const OnCallDialog({super.key});

  /// 显示被呼叫弹窗
  static void show() {
    debugPrint("显示被呼叫弹窗");
    OverlayUtil().dismiss(tag: tag);
    OverlayUtil().show(
      context: Get.overlayContext!,
      child: const OnCallDialog(),
      tag: tag,
    );
  }

  static void dismiss() {
    OverlayUtil().dismiss(tag: tag);
  }

  static const String tag = "OnCallDialog";

  @override
  State<OnCallDialog> createState() => _OnCallDialogState();
}

class _OnCallDialogState extends State<OnCallDialog> {
  StreamSubscription<VideoCallEvent>? _videoCallEvent;
  final videoCallHandler = Get.find<VideoCallHandler>();

  /// 距离顶部的距离
  double top = -45.w;

  @override
  void initState() {
    _wakelockPlusEnable();
    _videoCallEvent = EventBusUtil.listen<VideoCallEvent>((event) {
      // 此方法为被呼叫方监听当前呼叫事件
      if (event.command == SocketCommandKey.onHangUp) {
        HangUpModel hangUpModel = event.data;
        if (videoCallHandler.onCallModel == null || hangUpModel.channelName != videoCallHandler.onCallModel?.channelName) {
          // 被挂断，但是当前无任何被呼叫数据 || 挂断频道不同，则拦截
          logger.e("被挂断事件拦截");
          return;
        }
        // 挂断，关闭当前弹窗
        OnCallDialog.dismiss();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      top = _defaultTop;
      _update();
    });
    super.initState();
  }

  _wakelockPlusEnable() async {
    if (!kIsWeb) await WakelockPlus.enable();
  }

  @override
  void dispose() {
    if (!kIsWeb) WakelockPlus.disable();
    _videoCallEvent?.cancel();
    super.dispose();
    debugPrint("显示被呼叫弹窗dispose");
  }

  @override
  Widget build(BuildContext context) {
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      top: top,
      right: 0,
      left: 0,
      child: GestureDetector(
        onTap: () {
          DialogQueueUtil.to.closeAll();
          OnCallDialog.dismiss();
          Get.toNamed(RoutePath.onCallPage);
        },
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10.w),
                bottomRight: Radius.circular(10.w),
              ),
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.only(bottom: 5.w),
                  alignment: Alignment.center,
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
                    builder: (logic) {
                      var countryText = videoCallHandler.onCallModel?.country ?? "";
                      var appConfig = Get.find<AppConfigManager>();
                      if (appConfig.nameByEmoji.containsKey(countryText)) {
                        countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
                      } else if (appConfig.codeByEmoji.containsKey(countryText)) {
                        countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
                      }
                      return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: _defaultTop + 30.w,
                      ),
                      Container(
                        width: 60.w,
                        height: 60.w,
                        padding: EdgeInsets.all(2.5.w),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60.w / 2.0),
                            gradient: LinearGradient(
                              colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                            )),
                        child: Container(
                          padding: EdgeInsets.all(2.5.w),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(55.w / 2.0),
                              gradient: LinearGradient(
                                colors: MyColor.btnGradientColors.map((e) => e.withOpacity(0.2)).toList(),
                              )),
                          child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50.w / 2.0),
                                gradient: const LinearGradient(
                                  colors: MyColor.btnGradientColors,
                                )),
                            child: MyExtendedNetworkImage(
                              url: logic.onCallModel?.avatarThumbUrl ?? "",
                              shape: BoxShape.circle,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.w, horizontal: 7.w),
                        child: Text(
                          (logic.onCallModel?.nickname ?? "").fixAutoLines(),
                          textDirection: TextDirection.ltr,
                          textAlign: BHLanguageMar().isRightToLeft.value ? TextAlign.right : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
                              "${videoCallHandler.onCallModel?.age ?? 0}",
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
                      MyGaps.vGaps4w,
                      Obx(() {
                        bool free = videoCallHandler.onCallModel?.isFree ?? false;
                        Widget child = const SizedBox();
                        if (free) {
                          // final texts = "youll_be_charged_for_the_first_minute".bhTR.split("####");

                          child = RichText(
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
                                "${videoCallHandler.onCallModel?.unitPrice ?? 0}",
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
                          visible: !Get.find<AppConfigManager>().isReviewPkg.value && !free,
                          child: Container(
                            height: 13.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: MyColor.btnGradientColors2),
                              borderRadius: BorderRadius.circular(13.w),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
                              child: child,
                            ),
                          ),
                        );
                      }),
                      MyGaps.vGaps4w,
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () => _hangUp(),
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
                                    onTap: _onPickUp,
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
                                  visible: videoCallHandler.onCallModel?.isFree ?? false,
                                  child: Positioned(
                                    left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                                    right: BHLanguageMar().isRightToLeft.value ? null : 0,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(top: 2.w),
                                            child: Image.asset(
                                              ImageAssets.newCallFree,
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
                                                fontSize: "label_free".bhTR.length > 6 ? 4.sp : 6.sp,
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
                      MyGaps.vGaps10w,
                    ],
                  );
                    },
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  /// 滑动中
  void _onPanUpdate(DragUpdateDetails details) {
    top += details.delta.dy;
    if (top > _defaultTop) {
      // 限制最下滑动
      top = _defaultTop;
    }
    _update();
  }

  void _onPanEnd(DragEndDetails details) {
    if (top < -_defaultTop) {
      top = -45.w;
      // 挂断
      _hangUp();
    } else {
      top = _defaultTop;
    }
    _update();
  }

  /// 挂断
  void _hangUp() async {
    throttleUtil.throttle(() async {
      OnCallDialog.dismiss();
      await videoCallHandler.hangUp(
        onSuccess: (data) {},
        onFail: (code, msg) {},
      );
    }, key: "on_call_dialog_hangUp");
  }

  /// 接通
  void _onPickUp() async {

    //判断是否是搭讪电话
    if (videoCallHandler.onCallModel?.channelName?.startsWith("im_trigger_call_") ?? false) {
       //判断是否vip
    if (!(Get.findCanNull<AppConfigManager>()?.userInfo.hasEquity ?? false)) {
      //弹窗vip弹窗
      VipPrivilegesSheet.show();
      return;
    }
      Toast.showMsg("not_enough_money".bhTR);
      //弹窗充值弹窗
      RechargeDialog.show(entry: PayEntry.SOURCE_63, bindWidget: null);
      return;
    }

    try {
      await checkCameraAndMicrophonePermission(showDialog: true, isAwait: true);
    } catch (e) {
      //点击获取权限则中断流程
      return;
    }
    // 防止重复点击
    throttleUtil.throttle(() async {
      DialogQueueUtil.to.closeAll();
      await videoCallHandler.onPickUp();
    }, key: "on_call_dialog_onPickUp");
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }
}
