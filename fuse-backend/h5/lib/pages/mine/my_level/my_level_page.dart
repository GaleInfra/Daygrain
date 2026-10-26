import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/mine/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/status/page_status_widget.dart';

import '../../../res/my_color.dart';
import '../../../res/pay_entry.dart';
import 'my_level_logic.dart';

class MyLevelPage extends StatelessWidget {
  MyLevelPage({super.key});

  final logic = Get.find<MyLevelLogic>();
  final _imageList = <String>[
    ImageAssets.level0,
    ImageAssets.level1,
    ImageAssets.level2,
    ImageAssets.level3,
    ImageAssets.level4,
    ImageAssets.level5,
    ImageAssets.level6,
    ImageAssets.level7,
    ImageAssets.level8,
    ImageAssets.level9,
    ImageAssets.level10,
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: DefaultAppBar(title: "title_myLevel".bhTR),
        body: GetBuilder<MyLevelLogic>(
          builder: (logic) {
            return PageStatusWidget(
              logic: logic,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _topInfo(logic)),
                  SliverToBoxAdapter(child: SizedBox(height: 8.w)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    sliver: SliverToBoxAdapter(
                      child: MyGradientButton(
                        text: "action_topUpNow".bhTR,
                        onTap: () => RechargeDialog.show(entry: PayEntry.SOURCE_16, bindWidget: context),
                      ),
                    ),
                  ),
                  _levelTable(logic),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 顶部等级信息
  Widget _topInfo(MyLevelLogic logic) {
    double percent = 0;
    if (logic.maxLevel) {
      percent = 1;
    } else {
      final all = logic.nextCoins - logic.currentCoin;
      if (all > 0) {
        final sel = all - (logic.levelModel?.needRechargeCoins ?? 0);
        percent = (sel / all).clamp(0.0, 1.0);
      }
    }
    return Container(
      width: double.infinity,
      height: 57.w,
      padding: EdgeInsets.symmetric(vertical: 5.w, horizontal: 8.w),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient:const LinearGradient(colors: MyColor.messageBGs, begin:  AlignmentDirectional.centerEnd ,end: AlignmentDirectional.centerStart),
          borderRadius: BorderRadius.all(Radius.circular(8.w))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Image.asset(
            ImageAssets.myLevel,
            fit: BoxFit.contain,
            width: 20.w,
            height: 20.w,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Lv${logic.levelModel?.level ?? 0}",
                style: TextStyle(
                  fontSize: 7.sp,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(5.w),
                  ),
                  padding: const EdgeInsets.all(1),
                  child: Transform.rotate(
                    angle: BHLanguageMar().isRightToLeft.value ? 3.14 : 0,
                    child: LinearPercentIndicator(
                      lineHeight: 3.w,
                      percent: percent,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.black,
                      barRadius: Radius.circular(5.w),
                      progressColor: const Color(0xFF51CAFF),
                    ),
                  ),
                ),
              ),
              Text(
                logic.maxLevel ? "label_max".bhTR : "Lv${logic.nextLevel}",
                style: TextStyle(
                  fontSize: 7.sp,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          progressText(logic),
        ],
      ),
    );
  }

  Widget _levelTable(MyLevelLogic logic) {
    final userLevelList = List.from(logic.levelModel?.userLevelList ?? []);
    return SliverPadding(
      padding: EdgeInsets.all(8.w),
      sliver: SliverToBoxAdapter(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: Container(
            color: const Color(0xFF26203A),
            padding: EdgeInsets.all(1.w),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "label_level".bhTR,
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: (Get.width - 18.w) / 2 - 10.w,
                        alignment: Alignment.center,
                        child: Text(
                          "label_topUpAmount".bhTR,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (userLevelList.length + 1) * 18.w,
                  child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final levelModel = userLevelList[index];
                        int level = levelModel.level ?? 0;
                        bool deep = level % 2 == 0;
                        final badgeLevel = level < 0 || level > 10 ? 0 : level;
                        String image = _imageList[badgeLevel];
                        final color = deep ? MyColor.appBackground : null;
                        return Container(
                          width: double.infinity,
                          height: 18.w,
                          color: color,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  color: color,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 28.w,
                                    height: 13.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.w),
                                      color: LevelColor.levelColorList[badgeLevel],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          image,
                                          width: 10.w,
                                          height: 8.w,
                                        ),
                                        Center(
                                          child: Text(
                                            "Lv$level",
                                            style: TextStyle(
                                              fontSize: 7.sp,
                                              color: level == 0 ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(color: const Color(0xFF26203A), width: 2),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: EdgeInsets.only(left: 3.w),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "${levelModel.rechargedCoins ?? 0}",
                                    style: TextStyle(
                                      fontSize: 7.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: userLevelList.length),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 剩余进度文案
  Widget progressText(MyLevelLogic logic) {
    String text = "";
    if (logic.maxLevel) {
      // 若用户当前等级为最高级
      text = "You've reached the highest level.";
    } else {
      // 下一等级所需充值金币
      text = "${"action_topUp".bhTR} ${logic.levelModel?.needRechargeCoins ?? 0} ${"info_coinsToLevelUp".bhTR}";
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 6.sp,
        color: Colors.black,
      ),
    );
  }
}
