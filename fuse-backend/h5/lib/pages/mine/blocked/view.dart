import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/blocked_list_model.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';

import 'logic.dart';

/// 黑名单列表页
class BlockedPage extends StatelessWidget {
  final logic = Get.find<BlockedLogic>();

  BlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: DefaultAppBar(title: "title_blockedList".bhTR),
        body: GetBuilder<BlockedLogic>(
          builder: (logic) {
            return RefreshWidget(
              logic: logic,
              enablePullUp: false,
              showEmptyBtn: false,
              child: ListView.builder(
                itemCount: logic.list.length,
                itemBuilder: (ctx, index) {
                  BlockedListModel item = logic.list[index];
                  return GestureDetector(
                    onTap: () => logic.jumpDetail(item),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      alignment: Alignment.center,
                      height: 38.w,
                      margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: MyColor.grey373634,
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MyExtendedNetworkImage(
                            url: item.avatar ?? "",
                            width: 24.w,
                            height: 24.w,
                            shape: BoxShape.circle,
                          ),
                          MyGaps.hGaps5w,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    (item.nickName ?? "").fixAutoLines(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: MyColor.white,
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                MyGaps.vGaps3w,
                                Text(
                                  "${item.age ?? 0} ${item.registerCountry ?? ""}",
                                  style: TextStyle(
                                    color: MyColor.white,
                                    fontSize: 6.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              logic.unblock(item.broadcasterId ?? "");
                            },
                            child: Container(
                              width: 40.w,
                              height: 15.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: Text(
                                "action_unblock".bhTR,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 6.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // MyGradientButton(
                          //   text: "action_unblock".bhTR,
                          //   width: 40.w,
                          //   height: 15.w,
                          //   onTap: () =>
                          //       logic.unblock(item.broadcasterId ?? ""),
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
