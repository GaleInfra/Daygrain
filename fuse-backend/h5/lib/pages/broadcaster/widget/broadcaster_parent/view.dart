import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/broadcaster/widget/country_picker.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/font_utils.dart';

import '../../../../model/skip_model.dart';
import '../../../../res/my_color.dart';
import 'logic.dart';

/// 主播墙-父级tabView内容
class BroadcasterParentComponent extends StatefulWidget {
  const BroadcasterParentComponent({super.key, required this.item});

  /// 该tab的数据
  final BroadcasterWallTagList item;

  @override
  State<BroadcasterParentComponent> createState() => _BroadcasterParentComponentState();
}

class _BroadcasterParentComponentState extends State<BroadcasterParentComponent> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController tabController;
  late BroadcasterParentLogic logic;

  @override
  void initState() {
    logic = Get.put(BroadcasterParentLogic(), tag: widget.item.tagName);
    tabController = TabController(length: widget.item.subTagList?.length ?? 0,animationDuration: Duration.zero, vsync: this);
    logic.initData(widget.item);
    tabController.animation?.addListener(_onChangeListener);
    super.initState();
  }

  @override
  void dispose() {
    tabController.animation?.removeListener(_onChangeListener);
    super.dispose();
  }

  void _onChangeListener() {
    int index = (tabController.animation?.value ?? 0).round();
    if (index != logic.index.value) {
      logic.onIndexChanged(index);
      if (widget.item.tagName == Get.find<AppConfigManager>().strategyModel?.broadcasterWallTagList?.first.tagName) {
        // 大标签是第一个大标签
        EventBusUtil.fire(OtherEvent(type: OtherType.broadcasterIndex, data: index));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _TabBar(
          tabController: tabController,
          tag: widget.item.tagName,
        ),
        Expanded(
          child: ExtendedTabBarView(
            controller: tabController,
            link: true,
            children: logic.pageList,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    Key? key,
    required this.tabController,
    required this.tag,
  }) : super(key: key);

  final TabController tabController;

  final String? tag;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BroadcasterParentLogic>(
      tag: tag,
      builder: (logic) {
        if ((logic.tagItem.subTagList?.length ?? 0) < 2) {
          return const SizedBox();
        }
        return SizedBox(
          height: 18.w,
          child: Row(
            children: [
              Expanded(child: Align(
                alignment: BHLanguageMar().isRightToLeft.value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: TabBar(
                  controller: tabController,
                  isScrollable: true,
                  dividerColor: MyColor.transparent,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: MyColor.appBackground,
                  labelPadding: EdgeInsets.symmetric(horizontal: 2.w),
                  labelStyle:  FontUtils.sansSemiBold(
                              size:  7.w,
                             color: MyColor.black,
                          ),
                  unselectedLabelStyle:  FontUtils.sansSemiBold(
                              size:  7.w,
                             color: MyColor.white,
                          ),
                 
                  labelColor: MyColor.black,
                  unselectedLabelColor: MyColor.white,
                  tabs: logic.tagItem.subTagList!
                      .map((e) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w,vertical: 2.w),
                        decoration: BoxDecoration(
                          color:  logic.tagItem.subTagList?.indexOf(e) == logic.index.value ? Color(0xFFFFFFFF) : Color(0xFF373548),
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Text(
                                             e,
                                             style: FontUtils.sansSemiBold(
                              size:  7.w,
                             color: logic.tagItem.subTagList?.indexOf(e) == logic.index.value ? MyColor.black : MyColor.white,
                          ),
                                          ),
                      ))
                      .toList(),
                ),
              )),
              SizedBox(
                width: 4.w,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _earth(BroadcasterParentLogic logic) {
    return Obx(() {
      if (Get.find<AppConfigManager>().isReviewPkg.value) {
        return  const SizedBox();
      }
      Widget child = Image.asset(
        ImageAssets.broadcasterEarth,
        width: 10.w,
        height: 10.w,
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
            onTap: () => showCountryPicker(
              targetContext: context,
              initCode: logic.countryCode.value,
              onSelect: (code, emoji) {
                logic.onChangeCountryEmoji(emoji, code);
              },
            ),
            child: child,
          );
        }),
      );
    });
  }
}
