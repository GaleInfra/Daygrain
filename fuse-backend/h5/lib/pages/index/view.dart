import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/flash_chat/view.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/widget/dialog/homepage_dialog.dart';

import '../../js/rc_manager_js.dart';
import '../../business/say_hi/robot_chat_manager.dart';
import '../broadcaster/view.dart';
import '../message/view.dart';
import '../mine/view.dart';
import 'logic.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with RouteAware {
  final logic = Get.find<IndexLogic>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // 回到当前页
    logic.resetLogHandle();
    logic.onDidPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    logic.nextLogHandle();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //获取首帧再执行关闭
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        JSRongCloudManager.dismissLoading();
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
              width: double.infinity,
              height: double.infinity,
              margin: EdgeInsets.only(bottom: (25.w + DeviceUtil().bottomSafe)),
              child: Stack(
                children: [
                  PageView(
                    key: logic.pageKey,
                    controller: logic.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BroadcasterPage(
                        key: ValueKey(
                            "BroadcasterPage${BHLanguageMar().currentLang}"),
                      ),
                      FlashChatPage(
                        key: ValueKey(
                            "FlashChatPage${BHLanguageMar().currentLang}"),
                      ),
                      MessagePage(
                        key: ValueKey(
                            "MessagePage${BHLanguageMar().currentLang}"),
                      ),
                      // FollowListWidget(),
                      MinePage(
                        key: ValueKey("MinePage${BHLanguageMar().currentLang}"),
                      ),
                    ],
                  ),
                  HomePageDialog(),
                  
                  // 测试按钮 - 手动触发机器人搭讪
                  // Positioned(
                  //   top: 100.h,
                  //   right: 20.w,
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       final robotChatManager = Get.find<RobotChatManager>();
                  //       robotChatManager.manualTriggerChat();
                  //     },
                  //     child: Container(
                  //       padding: EdgeInsets.symmetric(
                  //         horizontal: 16.w,
                  //         vertical: 8.h,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: MyColor.pinkFE3E69,
                  //         borderRadius: BorderRadius.circular(20.r),
                  //       ),
                  //       child: Text(
                  //         '测试搭讪1',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 12.sp,
                  //           fontWeight: FontWeight.w500,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              )),
          _BottomBar()
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  _BottomBar({Key? key}) : super(key: key);

  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    final indexLogic = Get.find<IndexLogic>();
    List<Widget> nor = [];
    List<Widget> select = [];
    for (int i = 0; i < indexLogic.tabItems.length; i++) {
      nor.add(Image.asset(
        indexLogic.tabItems[i]["unSelect"],
        key: ValueKey("tab_$i"),
        // 此处因为图标大小不一致，所以这样
        width: 16.w,
        height: 13.w,
      ));
      select.add(Image.asset(
        indexLogic.tabItems[i]["select"],
        key: ValueKey("tab_select$i"),
        // 此处因为图标大小不一致，所以这样
        width: 18.w,
        height: 15.w,
      ));
    }

    return GetBuilder<IndexLogic>(
      builder: (logic) {
        return Container(
          width: double.infinity,
          height: 30.w + DeviceUtil().bottomSafe,
          alignment: Alignment.topCenter,
          decoration: const BoxDecoration(
              color: Color(0xFF26203A),
              border: Border(
                top: BorderSide(color: Colors.transparent), // 设置顶部边框为透明
              )),
          child: SizedBox(
            height: 30.w,
            // padding: EdgeInsets.only(bottom: 6.w),
            child: Row(
              children: logic.tabItems
                  .map((e) => Visibility(
                        // 当tab为快速匹配时，审核模式或者匹配开关为关时不需要显示
                        visible: (logic.tabItems.indexOf(e) == 1 &&
                                !appConfig.isReviewPkg.value &&
                                (appConfig.strategyModel?.flashChatConfig
                                        ?.isSwitch ??
                                    false))
                            // 当tab为followed关注列表时，审核模式下显示
                            // || (logic.tabItems.indexOf(e) == 2 && appConfig.isReviewPkg.value)
                            // 其他的tab照常显示
                            ||
                            (logic.tabItems.indexOf(e) != 1),

                        child: Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                logic.onChangeIndex(logic.tabItems.indexOf(e)),
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              alignment: Alignment.center,
                              child: Obx(() {
                                return badges.Badge(
                                  badgeStyle:const badges.BadgeStyle(
                                    badgeColor: MyColor.transparent,
                                    padding: EdgeInsets.all(0),
                                    
                                  ),
                                  showBadge: logic.tabItems.indexOf(e) == 2 &&
                                      logic.unreadCount.value > 0,
                                  badgeContent: Container(
                                     alignment: Alignment.center,
                                     padding: EdgeInsets.symmetric(horizontal: 2.w),
                                    constraints: BoxConstraints(minWidth: 8.w, minHeight: 8.w, maxHeight: 8.w),
                                    decoration: BoxDecoration(
                                      color: MyColor.pinkFE3E69,
                                      borderRadius: BorderRadius.circular(4.w),
                                      border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    )
                                    ),
                                    child: Text(
                                      logic.unreadCount.value > 99
                                          ? "99+"
                                          : logic.unreadCount.value.toString(),
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        color: MyColor.white,
                                        fontSize: 5.sp,
                                      ),
                                    ),
                                  ),
                                  child: logic.currentIndex.value ==
                                          logic.tabItems.indexOf(e)
                                      ? select[logic.tabItems.indexOf(e)]
                                      : nor[logic.tabItems.indexOf(e)],
                                );
                              }),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
