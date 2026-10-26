import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';

import '../../../res/my_color.dart';
import 'logic.dart';
import 'widget/follow_list_item.dart';

class FollowListWidget extends StatefulWidget {
  const FollowListWidget({super.key});

  @override
  State<FollowListWidget> createState() => _FollowListWidgetState();
}

class _FollowListWidgetState extends State<FollowListWidget> with AutomaticKeepAliveClientMixin {
  final logic = Get.put(FollowListLogic());
  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AppBar? appBar;

    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: appBar,
        backgroundColor: MyColor.transparent,
        body: GetBuilder<FollowListLogic>(
          builder: (logic) {
            return RefreshWidget(
              logic: logic,
              emptyMsg: "status_noFollowedRecord".bhTR,
              child: ListView.separated(
                itemCount: logic.list.length,
                separatorBuilder: (_, __) => Container(
                  height: .25.w,
                  width: double.infinity,
                  color: MyColor.transparent,
                ),
                itemBuilder: (ctx, index) {
                  return FollowListItem(
                    item: logic.list[index],
                    onTap: () => logic.onJumpDetail(logic.list[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
