import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/broadcaster/ranking/ranking_child/logic.dart';
import 'package:untitled1/pages/broadcaster/ranking/ranking_child/widget/ranking_top.dart';
import 'package:untitled1/pages/broadcaster/ranking/ranking_cp/ranking_cp_logic.dart';
import 'package:untitled1/pages/broadcaster/ranking/ranking_cp/ranking_cp_view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/match_util.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

import '../../../widget/app_bar/default_app_bar.dart';
import 'logic.dart';
import 'ranking_child/view.dart';
import 'widget/ranking_tabbar.dart';

/// 排行榜
class RankingPage extends StatelessWidget {
  final logic = Get.find<RankingLogic>();

  RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Stack(
        children: [
          Align(
            child: Image.asset(ImageAssets.rankBg,
              width: Get.width,
              height: Get.height,
              fit: BoxFit.cover,),
          ),
          Align(
            child: SafeArea(
              child: Scaffold(
                appBar: DefaultAppBar(
                  titleWidget: RankingTime(),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 145.w + 8.w,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Obx(() {
                            if (logic.requestSuccess.value == false) {

                            }
                            if (logic.index.value == 0) {
                              if (Get.isRegistered<RankingChildLogic>(tag: logic.tagList[0])) {
                                RankingChildLogic controller = Get.find<RankingChildLogic>(tag: logic.tagList[0]);
                                controller.logHandle.initLog('rank',subPage: 'charm');
                              }
                              return RankingTopWidget(
                                  index: 0,
                                  items: logic.charmList);

                            }else if (logic.index.value == 1){
                              if (Get.isRegistered<RankingChildLogic>(tag: logic.tagList[1])) {
                                RankingChildLogic controller = Get.find<RankingChildLogic>(tag: logic.tagList[1]);
                                controller.logHandle.initLog('rank',subPage: 'rich');
                              }
                              return RankingTopWidget(
                                  index: 1,
                                  items: logic.richList);
                            }else {
                              if (Get.isRegistered<RankingCpLogic>()) {
                                // 控制器已注册
                                RankingCpLogic controller = Get.find<RankingCpLogic>();
                                controller.logHandle.initLog('rank',subPage: 'couple');
                                if (controller.cpModel != null) {
                                  logic.couplesList = controller.cpModel!.rankData ?? [];
                                }
                              }


                              return TopCoupleWidget(
                                  items: logic.couplesList);
                            }

                          }),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              color: MyColor.appBackground2,
                              width: double.infinity,
                              height: 16.w,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.w),
                                child: Row(
                                  children: [
                                    Container(
                                        height: 16.w,
                                        margin: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 0 : 8.w, right: BHLanguageMar().isRightToLeft.value ? 8.w : 0),
                                        decoration: BoxDecoration(
                                          color: MyColor.grey4C,
                                          borderRadius: BorderRadius.circular(8.w),
                                        ),
                                        child: RankingTabBar())
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                        child: TabBarView(
                          controller: logic.tabController,
                          children: [
                            RankingChildComponent(
                              type: logic.tagList[0],
                              onDataBack: (data) {
                                if (logic.tabController.index == 0) {
                                  //更新
                                  logic.charmList = data;
                                  logic.requestSuccess.value = !logic.requestSuccess.value;
                                }
                              },
                            ),
                            RankingChildComponent(
                                type: logic.tagList[1],
                                onDataBack: (data) {
                                  if (logic.tabController.index == 1) {
                                    //更新
                                    logic.richList = data;
                                    logic.requestSuccess.value = !logic.requestSuccess.value;
                                  }
                                }),
                            RankCpView(onDataBack: (data) {
                              if (logic.tabController.index == 2) {
                                //更新
                                logic.couplesList = data;
                                logic.requestSuccess.value = !logic.requestSuccess.value;
                              }
                            }),
                          ],
                        ))
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
