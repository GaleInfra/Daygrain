import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/broadcaster/widget/country_picker.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/status/page_status_widget.dart';

import '../../config/route.dart';
import '../../res/image_assets.dart';
import 'logic.dart';

/// 主播墙
class BroadcasterPage extends StatefulWidget {
  const BroadcasterPage({super.key});

  @override
  State<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends State<BroadcasterPage>
    with AutomaticKeepAliveClientMixin {
  final logic = Get.put(BroadcasterLogic());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GradientBackgroundWidget(
      key: logic.pageKey,
      child: SafeArea(
        child: PageStatusWidget(
          logic: logic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (BHPlatform.isWeb)
                SizedBox(
                  height: DeviceUtil().statusBarHeight,
                ),
              const _TabBar(),
              Expanded(
                child: GetBuilder<BroadcasterLogic>(
                  builder: (logic) {
                    return ExtendedTabBarView(
                      controller: logic.tabController,
                      link: true,
                      children: logic.pageList,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TabBar extends StatefulWidget {
  const _TabBar({Key? key}) : super(key: key);

  @override
  State<_TabBar> createState() => _TabBarState();
}

class _TabBarState extends State<_TabBar> with SingleTickerProviderStateMixin {
  final logic = Get.find<BroadcasterLogic>();

  @override
  void initState() {
    TabController parent =
        TabController(length: logic.tagList.length,animationDuration: Duration.zero, vsync: this);
    logic.initParentTab(parent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GetBuilder<BroadcasterLogic>(
              builder: (logic) {
                return TabBar(
                  controller: logic.tabController,
                  tabs: logic.tagList.map((e) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        if (logic.parentTag.value == e.tagName)
                          Positioned(
                            top: 0.w,
                            left: BHLanguageMar().isRightToLeft.value ? null : 0,
                            right: BHLanguageMar().isRightToLeft.value ? 0 : null,
                            child: Image.asset(
                              ImageAssets.topTabBack,
                              width: 15.w,
                              height: 13.w,
                              fit: BoxFit.fill,
                            ),
                          ),
                        Container(
                          alignment: Alignment.bottomCenter,
                          padding: EdgeInsets.only(bottom: 4.w),
                          child: Text(
                            e.tagName ?? "",
                            style: logic.parentTag.value == e.tagName
                                ? FontUtils.boldItalic(
                                    size: 11.w, color: MyColor.white)
                                : FontUtils.sansSemiBold(
                                    size: 10.w, color: MyColor.topBarColor),
                          ),
                        ),
                        
                      ],
                    );
                  }).toList(),
                  isScrollable: true,
                  indicatorColor: MyColor.appBackground,
                  labelPadding: EdgeInsets.symmetric(horizontal: 5.w),
                  dividerColor: MyColor.transparent,
                  tabAlignment: TabAlignment.start,
                );
              },
            ),
          ),
          _earth(),
          SizedBox(
            width: 9.w,
          ),
          Obx(() {
            return Visibility(
              visible: !Get.find<AppConfigManager>().isReviewPkg.value,
              child: GestureDetector(
                onTap: () => Get.toNamed(RoutePath.rankingPage),
                child: Image.asset(
                  ImageAssets.broadcasterRank,
                  width: 13.w,
                  height: 12.w,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }),
          SizedBox(
            width: 3.w,
          ),
        ],
      ),
    );
  }

  // 国家选择
  Widget _earth() {
    return Obx(() {
      if (Get.find<AppConfigManager>().isReviewPkg.value) {
        return const SizedBox();
      }
      Widget child = Image.asset(
        ImageAssets.broadcasterEarth,
        width: 12.w,
        height: 12.w,
        fit: BoxFit.contain,
      );
      if (logic.countryEmoji.isNotEmpty) {
        child = Text(
          logic.countryEmoji.value,
          style: TextStyle(
            fontSize: 10.sp,
          ),
        );
      }
      return Visibility(
        visible: logic.showCountry.value,
        child: Builder(builder: (context) {
          return GestureDetector(
            onTap: () {
              showCountryPicker(
                targetContext: context,
                initCode: logic.countryCode.value,
                onSelect: (code, emoji) {
                  logic.onChangeCountryEmoji(emoji, code);
                },
              );
            },
            child: child,
          );
        }),
      );
    });
  }
}
