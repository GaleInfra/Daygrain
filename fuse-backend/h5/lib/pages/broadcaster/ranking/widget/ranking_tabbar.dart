import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/utils/MyLinearGradient.dart';
import 'package:untitled1/utils/font_utils.dart';

import '../../../../res/my_color.dart';
import '../logic.dart';

/// create: 2023/4/24
/// desc: 排行榜标签
class RankingTabBar extends StatelessWidget {
  RankingTabBar({Key? key}) : super(key: key);

  final logic = Get.find<RankingLogic>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      int index = logic.index.value;

      return SizedBox(
        height: 16.w,
        child: TabBar(
          isScrollable: true,
          dividerColor: MyColor.transparent,
          tabAlignment: TabAlignment.start,
          indicatorColor: MyColor.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 0.w),
          controller: logic.tabController,
          indicatorWeight: 0, // 将指示器宽度设为0
          indicator: const BoxDecoration(),
          tabs: [
            for (int i = 0; i < logic.tagList.length; i++) ...{
              Tab(
                child: Container(
                  height: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 4.7.w),
                  decoration: BoxDecoration(
                    gradient: index == i
                        ? MyLinearGradient.getGradient()
                        : null,
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Center(
                    child: Text(
                      logic.tagList[i],
                      style: FontUtils.boldItalic(
                        size: index == i ? 6.7.sp : 5.5.sp,
                        color: index == i
                            ? MyColor.white
                            : MyColor.greyCE,
                      ),
                    ),
                  ),
                ),
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     const SizedBox(
                //       height: 3,
                //     ),
                //     MyGradientText(
                //       text: logic.tagList[i],
                //       colors: index == i ? selectColor : unSelectColor,
                //       style: TextStyle(
                //         fontWeight:
                //         index == i ? FontWeight.w500 : FontWeight.w300,
                //         fontSize: index == i ? 10.w : 8.w,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ],
                // ),
              ),
            }
          ],
        ),
      );
    });
  }
}
