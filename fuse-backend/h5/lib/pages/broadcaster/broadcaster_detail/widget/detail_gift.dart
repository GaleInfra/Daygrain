import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/gift_util.dart';

import '../../../../res/my_color.dart';
import '../../../../res/my_gaps.dart';
import '../logic.dart';
import '../view.dart';

/// create: 2023/4/26
/// desc: 资料页礼物墙
class DetailGift extends StatelessWidget {
  const DetailGift({
    Key? key,
    required this.tagUserId,
  }) : super(key: key);

  final String tagUserId;

  @override
  Widget build(BuildContext context) {

    return GetBuilder<BroadcasterDetailLogic>(
      tag: tagUserId,
      builder: (logic) {
        final giftList = List.from(logic.giftList);
        //GiftUtil.giftImageList 转 字典 {code: image}
        Map<String, GiftImageModel> giftImageByCodeMap = {};
        for (var item in GiftUtil.giftImageList) {
          giftImageByCodeMap[item.name] = item;
        }
        return Visibility(
          visible: giftList.isNotEmpty,
          child: Column(
            children: [
              MyGaps.vGaps10w,
              DetailTitle(icon: ImageAssets.broadcasterInfoLabelGiftr, title: "label_gift".bhTR),
              MyGaps.vGaps5w,
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: giftList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 2.w,
                  crossAxisSpacing: 3.w,
                  childAspectRatio: 77 / 94.0,
                ),
                itemBuilder: (ctx, index) {
                  String giftImage = giftImageByCodeMap[giftList[index].code]?.thumbnail ?? ImageAssets.invalidImage;
                  return Column(
                    children: [
                      Container(
                        width: 30.w,
                        height: 30.w * 94 / 77.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7.w),
                          color:const Color(0xFF26203A),
                        ),
                        child: Column(
                          children: [
                            Expanded(child: Center(
                              child: Image.asset(
                                giftImage,
                                width: 14.w,
                                height: 18.w,
                                fit: BoxFit.contain,
                              ),
                            )),
                            SizedBox(height: 2.w),
                            Text(
                              "x ${giftList[index].count}".fixAutoLines(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MyColor.white,
                                fontSize: 6.sp,
                              ),
                            ),
                            SizedBox(height: 2.w),
                          ],
                        ),
                      ),

                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
