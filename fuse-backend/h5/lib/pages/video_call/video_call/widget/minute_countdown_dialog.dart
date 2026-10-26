import 'dart:async';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/overlay_util.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';

import '../../../../res/image_assets.dart';
import '../../../../res/my_color.dart';
import '../../../../res/pay_entry.dart';
import '../../../../utils/device_util.dart';
import '../../../../utils/dialog_util.dart';
import '../../../../widget/dialog/gift_sheet.dart';

/// create: 2023/6/2
/// desc: 通话一分钟倒计时弹窗
class MinuteCountdownDialog extends StatefulWidget {
  const MinuteCountdownDialog({
    Key? key,
    required this.second,
  }) : super(key: key);

  //记录当前正在显示的倒计时弹窗
  static GlobalKey<MinuteCountdownDialogState>? currentKey;

  /// 打开金币不足倒计时弹窗
  static void show({
    required int second,
  }) {
    dismiss();
    final logic = Get.find<VideoCallLogic>();
    if (logic.showFlachMatchDown.value) {
      logger.i("显示匹配倒计时中，不显示金币不足弹窗");
      return;
    }
    if (logic.userExited) {
      // 用户退出
      return;
    }
    // if (logic.myUid == 0 || logic.remoteUid == 0) {
    //   // 有一方未加入
    //   return;
    // }
    currentKey = GlobalKey();
    OverlayUtil().show(
      context: Get.overlayContext!,
      child: Obx(() {
        return Offstage(
          offstage: !logic.pageShow.value,
          child: MinuteCountdownDialog(key: currentKey!, second: second),
        );
      }),
      tag: _tag,
    );
    // DialogUtil.showDialog(
    //   bindPage: false,
    //   usePenetrate: true,
    //   clickMaskDismiss: false,
    //   backDismiss: false,
    //   alignment: Alignment.topCenter,
    //   // 这里使用Offstage原因是SmartDialog进入到其他页面时不会隐藏，所以手动隐藏一下
    //   child: Obx(() {
    //     return Offstage(
    //       offstage: !logic.pageShow.value,
    //       child: MinuteCountdownDialog(second: second),
    //     );
    //   }),
    //   tag: _tag,
    // );
  }

  /// 关闭金币不足倒计时弹窗
  static void dismiss() {
    OverlayUtil().dismiss(tag: _tag);
    currentKey = null;
    // DialogUtil.dismiss(tag: _tag, force: true);
    // 同时关闭充值弹窗
    RechargeDialog.dismiss();
  }

  final int second;

  static const String _tag = "MinuteCountdownDialog";

  @override
  State<MinuteCountdownDialog> createState() => MinuteCountdownDialogState();
}

class MinuteCountdownDialogState extends State<MinuteCountdownDialog> {
  late int countSecond;
  Timer? timer;

  @override
  void initState() {
    countSecond = widget.second;
    // 创建倒计时
    timer?.cancel();
    timer = null;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countSecond--;
      if (mounted) {
        setState(() {});
      }
      if (countSecond == 0) {
        timer.cancel();
        MinuteCountdownDialog.dismiss();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(top: DeviceUtil().statusBarHeight ?? 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                width: double.infinity,
                height: 46.w,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.w)),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      MyColor.btnGradientColors2[4],
                      MyColor.btnGradientColors2[3],
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => MinuteCountdownDialog.dismiss(),
                          child: const Icon(
                            Icons.close,
                            color: MyColor.grey2C2B29,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    ImageAssets.broadcasterDiamondBig,
                                    width: 15.w,
                                    height: 15.w,
                                  ),
                                  MyGaps.hGaps2w,
                                  AutoSizeText(
                                    "error_insufficientDiamonds".bhTR,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: MyColor.grey2C2B29,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              MyGaps.vGaps3w,
                              Row(
                                children: [
                                  Text(
                                    "label_remainingVideoDuration".bhTR,
                                    style: TextStyle(
                                      color: MyColor.grey2C2B29,
                                      fontSize: 6.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  RichText(
                                    textDirection: TextDirection.ltr,
                                    text: TextSpan(
                                      text: "$countSecond",
                                      style: TextStyle(
                                        color: MyColor.redFF3333,
                                        fontSize: 8.sp,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: " s",
                                          style: TextStyle(
                                            color: MyColor.grey2C2B29,
                                            fontSize: 6.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: .3.w, top: .3.w),
                          decoration: BoxDecoration(
                            // color: MyColor.white,
                            borderRadius: BorderRadius.circular(9.w),
                          ),
                          child: MyGradientButton(
                            isAuto: true,
                            width: 45.w,
                            height: 18.w,
                            text: "action_recharge".bhTR,
                            gradientColor: const [
                              MyColor.black,
                              MyColor.black,
                            ],
                            onTap: () {
                              //如果有礼物弹窗则关闭
                              DialogUtil.dismiss(tag: GiftSheet.tag);
                              RechargeDialog.show(entry: PayEntry.SOURCE_13, bindWidget: context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
