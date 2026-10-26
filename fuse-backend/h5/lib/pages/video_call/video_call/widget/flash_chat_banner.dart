import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/pages/video_call/video_call/widget/minute_countdown_dialog.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/broadcaster_call_price_util.dart';

/// create: 2023/6/8
/// desc: 视频通话页 - 匹配倒计时banner
class FlashChatBanner extends StatefulWidget {
  const FlashChatBanner({
    Key? key,
  }) : super(key: key);

  static void show() {
    Get.find<VideoCallLogic>().showFlachMatchDown.value = true;
  }

  static void dismiss() {
    Get.find<VideoCallLogic>().showFlachMatchDown.value = false;
  }

  @override
  State<FlashChatBanner> createState() => _FlashChatBannerState();
}

class _FlashChatBannerState extends State<FlashChatBanner> {
  late Timer timer;

  int second = 20;

  final logic = Get.find<VideoCallLogic>();

  final _videoHandler = Get.find<VideoCallHandler>();

  @override
  void initState() {
    second = _videoHandler.onCallModel?.callFreeSeconds ?? 20;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (second > 1) {
        second--;
        setState(() {});
      } else {
        // 倒计时完成
        timer.cancel();
        if (logic.showNotEnough.value) {
          // 如果当前需要显示金币不足，则倒计时完成弹出金币不足弹窗
          MinuteCountdownDialog.show(
            second: 60 - (_videoHandler.onCallModel?.callFreeSeconds ?? 20),
          );
        }
        FlashChatBanner.dismiss();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var s = "After ####，you’ll be charged #### per minute.".bhTR;

    ///使用 #### 分割字符串
    var list = s.split("####");
    var after = "";
    var charge = "";
    var minute = "";
    if (list.length == 3) {
      after = list[0];
      charge = list[1];
      minute = list[2];
    }else{
      after = "${"After".bhTR} ";
      charge = "${"info_callChargeModal".bhTR} ";
      minute = " ${"info_PerMinute".bhTR}";
    }

    return Visibility(
      /// 倒计时大于0 && 匹配通话时
      visible: second > 0,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 13.w),
        decoration: BoxDecoration(color: MyColor.black.withValues(alpha: 0.15)
            // gradient: LinearGradient(
            //   begin: Alignment.centerLeft,
            //   end: Alignment.centerRight,
            //   colors: MyColor.btnGradientColors.map((e) => e.withValues(alpha: .4)).toList(),
            // ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Color(0xff9525FF).withOpacity(0.8),
            //     offset: Offset(0, 0),
            //     blurRadius: 6.5,
            //   ),
            // ],
            ),
        padding: EdgeInsets.only(top: 2.w, bottom: 2.w, left: BHLanguageMar().isRightToLeft.value ? 0 : 4.w, right: BHLanguageMar().isRightToLeft.value ? 4.w : 0),
        child: Align(
          alignment: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 2.w,
              ),
              Image.asset(
                ImageAssets.videoCallIcRing,
                width: 10.w,
                fit: BoxFit.fitWidth,
              ),
              SizedBox(
                width: 2.w,
              ),
              Text(
                after,
                maxLines: 1,
                
                style: TextStyle(
                  color: MyColor.white,
                  fontSize: 6.sp,
                ),
              ),
              Text(
                "${second}s",
                style: TextStyle(
                  color: const Color(0xFFFE3E69),
                  fontSize: 7.sp,
                ),
              ),
              Text(
                charge,
                maxLines: 1,
                style: TextStyle(
                  color: MyColor.white,
                  fontSize: 6.sp,
                ),
              ),
              GetBuilder<VideoCallLogic>(
                builder: (logic) {
                  final price = BroadcasterCallPriceUtil.displayPerMinutePrice(
                    broadcaster: logic.userInfo,
                  );
                  return AutoSizeText(
                    "$price",
                    style: TextStyle(
                      color: const Color(0xFFFE3E69),
                      fontSize: 7.sp,
                    ),
                  );
                },
              ),
              AutoSizeText(
                minute,
                style: TextStyle(
                  color: MyColor.white,
                  fontSize: 6.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
