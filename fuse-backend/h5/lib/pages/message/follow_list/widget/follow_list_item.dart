import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/model/message/follow/friend_list_model.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../common_logic/user_status_service.dart';
import '../../../../event_bus/base/event_bus_util.dart';
import '../../../../language/bh_language_manager.dart';
import '../../../../res/my_color.dart';
import '../../../../res/my_gaps.dart';
import '../../../../widget/image/my_extended_network_image.dart';
import '../../../../widget/online_status_widget.dart';

/// create: 2023/4/27
/// desc: 关注列表item
class FollowListItem extends StatefulWidget {
  const FollowListItem({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  final FriendListModel item;

  final VoidCallback onTap;

  @override
  State<FollowListItem> createState() => _FollowListItemState();
}

class _FollowListItemState extends State<FollowListItem> {
  //状态
  final userStatus = kOffline.obs;
  StreamSubscription? _userStateEvent;

  @override
  void initState() {
    super.initState();
  }

  //监听显示隐藏
  void onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0) {
      removeListener();
    } else {
      getUserStatusService()?.addUserId(widget.item.userId ?? "");
      if (_userStateEvent == null) {
        registerListener();
        final stat = getUserStatusService()?.getStatus(widget.item.userId ?? "");
        if (stat != null) {
          userStatus.value = stat;
        }
      }
    }
  }

  //监听状态刷新
  void registerListener() {
    removeListener();
    _userStateEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (event.uidAndStatus.containsKey(widget.item.userId)) {
        userStatus.value = event.uidAndStatus[widget.item.userId] ?? kOffline;
      }
    });
  }

  //移除监听
  void removeListener() {
    if (_userStateEvent != null) {
      _userStateEvent!.cancel();
      _userStateEvent = null;
    }
  }

  @override
  void dispose() {
    removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var countryText = widget.item.country ?? "";
    var appConfig = Get.find<AppConfigManager>();
    if (appConfig.nameByEmoji.containsKey(countryText)) {
      countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
    } else if (appConfig.codeByEmoji.containsKey(countryText)) {
      countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
    }

    return VisibilityDetector(
      key: ValueKey("follow_list_item_${widget.item.userId}"),
      onVisibilityChanged: onVisibilityChanged,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 42.5.w,
              padding: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 7.w : 13.w, right: BHLanguageMar().isRightToLeft.value ? 13.w : 7.w),
              child: Row(
                children: [
                  Stack(
                    children: [
                      MyExtendedNetworkImage(
                        url: widget.item.avatarUrl ?? "",
                        width: 25.w,
                        height: 25.w,
                        fit: BoxFit.cover,
                        shape: BoxShape.circle,
                      ),
                      Positioned(
                        right: BHLanguageMar().isRightToLeft.value ? null : 0,
                        left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                        bottom: 0,
                        child: Obx(
                          () => OnlineStatusWidget(
                            status: userStatus.value,
                          ),
                        ),
                      )
                    ],
                  ),
                  MyGaps.hGaps5w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (widget.item.nickname ?? "").fixAutoLines(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 7.5.sp,
                                  color: MyColor.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        MyGaps.vGaps2w,
                        Text(
                          "$countryText   ${widget.item.age ?? 0}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 6.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
           
          ],
        ),
      ),
    );
  }
}
