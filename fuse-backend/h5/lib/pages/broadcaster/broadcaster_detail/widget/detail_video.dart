/*
 * @Author: Chensd ”851329628@qq.com“
 * @Date: 2025-07-09 16:55:37
 * @LastEditors: Chensd ”851329628@qq.com“
 * @LastEditTime: 2025-07-09 18:33:40
 * @FilePath: \bon-hub\lib\pages\broadcaster\broadcaster_detail\widget\detail_video.dart
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/logic.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import '../view.dart';

/// create: 2023/4/25
/// desc: 视频
class DetailVideo extends StatelessWidget {
  const DetailVideo({
    Key? key,
    required this.tagUserId,
  }) : super(key: key);

  final String tagUserId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BroadcasterDetailLogic>(
      tag: tagUserId,
      builder: (logic) {
        final list = logic.userInfo?.mediaList?.where((element) => element.mediaType == "video").toList();

        // 指定不展示视频模块的主播ID列表
        const Set<String> blacklistUserIds = {
          "1961011549309108224",
          "1961011441205116928",
          "1961011258434125824",
          "1961011140259610624",
          "1961010995912638464",
        };

        final String currentUserId = logic.userInfo?.userId ?? "";
        final bool isBlacklisted = blacklistUserIds.contains(currentUserId);

        return Visibility(
          visible: (list?.isNotEmpty ?? false) && !isBlacklisted,
          child: Column(
            children: [
              DetailTitle(
                  icon: ImageAssets.broadcasterInfoLabelVideo,
                  title: "label_video".bhTR),
              MyGaps.vGaps5w,
              SizedBox(
                height: 50.w,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                  itemCount: list?.length ?? 0,
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => MyGaps.hGaps10w,
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed(RoutePath.seeVideoPage, arguments: {
                          "index": index,
                          "userInfo": logic.userInfo,
                          "urls": list?.map((e) => e.mediaUrl ?? "").toList(),
                          "thumUrls": list?.map((e) => e.thumbUrl ?? "").toList(),
                        });
                      },
                      behavior: HitTestBehavior.translucent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.w),
                        child: Stack(
                          children: [
                            MyExtendedNetworkImage(
                              url: list?[index].thumbUrl ?? "",
                              key: ValueKey("image_${list?[index].thumbUrl ?? ""}"),
                              width: 37.w,
                              height: 50.w,
                              fit: BoxFit.cover,
                            ),
                            Center(
                              child: SizedBox(
                                width: 37.w,
                                child: SizedBox(
                                  width: 11.w,
                                  height: 11.w,
                                  child: Image.asset(ImageAssets.broadcasterVideoPre,width: 11.w,height: 11.w,),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
