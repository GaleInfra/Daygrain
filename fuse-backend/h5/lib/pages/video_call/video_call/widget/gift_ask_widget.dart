import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/gift_util.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

/// create: 2023/5/16
/// desc: 被索取礼物widget
class GiftAskWidget extends StatelessWidget {
  const GiftAskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoCallLogic>(
      builder: (logic) {
        if (logic.giftAskModel == null) {
          return const SizedBox();
        }

        String image = "";
        var list = GiftUtil.giftImageList
            .where(
                (element) => element.name == logic.giftAskModel?.content?.code)
            .toList();
        if (list.isNotEmpty) {
          image = list.first.image;
        }

        return Align(
          alignment: BHLanguageMar().isRightToLeft.value
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
                left: BHLanguageMar().isRightToLeft.value ? 0 : 12.w,
                right: BHLanguageMar().isRightToLeft.value ? 12.w : 0,
                top: 40.w),
            child: Container(
              padding: EdgeInsets.only(
                  left: BHLanguageMar().isRightToLeft.value ? 0 : 2.w,
                  right: BHLanguageMar().isRightToLeft.value ? 2.w : 0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .8,
              ),
              decoration: BoxDecoration(
                color: MyColor.black.withOpacity(.2),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyExtendedNetworkImage(
                    url: logic.userInfo?.avatarUrl ?? "",
                    width: 13.w,
                    height: 13.w,
                    shape: BoxShape.circle,
                  ),
                  MyGaps.hGaps3w,
                  Flexible(
                    child: Text(
                      "${(logic.userInfo?.nickname ?? "").truncateThan(10)} ${"info_askForGift".bhTR} ",
                      style: TextStyle(
                        color: MyColor.white,
                        fontSize: 6.sp,
                      ),
                    ),
                  ),
                  MyGaps.hGaps2w,
                  Image.asset(
                    image,
                    width: 18.w,
                    height: 18.w,
                  ),
                  MyGaps.hGaps3w,
                  GestureDetector(
                    onTap: () =>
                        logic.onGiveGiftAsk(logic.giftAskModel!, context),
                    child: Container(
                      width: 30.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: MyColor.btnGradientColors,
                        ),
                        borderRadius:
                            BorderRadius.all(Radius.circular((18 / 2.0).r)),
                      ),
                      alignment: Alignment.center,
                      child: AutoSizeText(
                        "action_send".bhTR,
                        maxLines: 1,
                        style: TextStyle(
                          color: MyColor.black,
                          fontSize: 6.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
