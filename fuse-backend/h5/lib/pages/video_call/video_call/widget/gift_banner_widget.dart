import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/utils/gift_util.dart';

import '../../../../res/my_color.dart';

/// create: 2023/5/16
/// desc: 礼物横幅
class GiftBannerWidget extends StatefulWidget {
  const GiftBannerWidget({Key? key}) : super(key: key);

  @override
  State<GiftBannerWidget> createState() => _GiftBannerWidgetState();
}

class _GiftBannerWidgetState extends State<GiftBannerWidget> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft,
      child: GetBuilder<VideoCallLogic>(
        builder: (logic) {
          if (!logic.showGiftBanner) {
            return const SizedBox();
          }
          return Padding(
            padding: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 0 : 12.w, right: BHLanguageMar().isRightToLeft.value ? 12.w : 0),
            child: Stack(
              children: [
                Container(
                  width: 61.w,
                  height: 21.w,
                  padding: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 0 : 20.w, right: BHLanguageMar().isRightToLeft.value ? 20.w : 0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: BHLanguageMar().isRightToLeft.value
                            ? [MyColor.transparent, const Color(0xFF47FAF4)]
                            : [const Color(0xFF47FAF4), MyColor.transparent]),
                    borderRadius: BorderRadius.horizontal(
                        left: BHLanguageMar().isRightToLeft.value ? Radius.zero : Radius.circular(10.w),
                        right: BHLanguageMar().isRightToLeft.value ? Radius.circular(10.w) : Radius.zero),
                  ),
                  child: Text(
                    "x${logic.lastGiftCount}",
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                Positioned(
                  left: BHLanguageMar().isRightToLeft.value ? null : 0,
                  right: BHLanguageMar().isRightToLeft.value ? 0 : null,
                  top: 0,
                  bottom: 0,
                  child: Image.asset(
                    GiftUtil.giftImageList.firstWhere((element) => element.name == logic.lastGiveGift?.giftCode).thumbnail,
                    width: 20.w,
                    height: 30.w,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
