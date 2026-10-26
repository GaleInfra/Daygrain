import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';
import 'package:untitled1/widget/dialog/report_sub_sheet.dart';

import '../../utils/toast.dart';
import 'sheet_item.dart';

/// create: 2023/4/26
/// desc: 拉黑举报弹窗
class BlockReportSheet extends StatelessWidget {
  BlockReportSheet.show({
    super.key,
    this.isShowTop = false,
    required this.toUserId,
    required this.isBlock,
    required this.isFollow,
    this.isTop = false,
    required this.onFollowOrUnBack,
    required this.onBlockOrUnBack,
    this.onTopOrUnTop,
    BuildContext? bindWidget,
  }) {
    DialogUtil.showDialog(
      alignment: Alignment.bottomCenter,
      bindWidget: bindWidget,
      bindPage: false,
      child: this,
    );
  }

  //是否配置置顶
  final bool isShowTop;
  //是否置顶
  final bool isTop;

  /// 用户ID
  final String toUserId;

  /// 关注状态
  final bool isFollow;

  /// 拉黑状态
  final bool isBlock;

  /// 关注/取消关注 关注：true，取消关注：false
  final Function(bool result) onFollowOrUnBack;

  /// 拉黑/取消拉黑 拉黑：true， 取消拉黑：false
  final Function(bool result) onBlockOrUnBack;

  /// 置顶/取消置顶 置顶：true，取消置顶：false
  final Function(bool result)? onTopOrUnTop;

  /// 获取请求仓库
  final request = Get.find<RequestRepository>();

  @override
  Widget build(BuildContext context) {
    Container gap = Container(
      width: double.infinity,
      height: 1,
      color: const Color.fromARGB(255, 189, 189, 189).withOpacity(0.2),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomDialogBgWidget(
          child: Container(
            child: Column(
              children: [
                if (isShowTop)
                SheetItem(
                  title:
                      isTop ? "action_unTop".bhTR : "action_top".bhTR,
                  onTap: () {
                    onTopOrUnTop?.call(isTop);
                    DialogUtil.dismiss();
                  },
                ),
                 gap,
                SheetItem(
                  title:
                      isFollow ? "action_unfollow".bhTR : "action_follow".bhTR,
                  onTap: () {
                    onFollowOrUnFollow();
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: isBlock ? "action_unblock".bhTR : "action_block".bhTR,
                  onTap: () {
                    onBlockOrUn();
                    DialogUtil.dismiss();
                  },
                ),
                gap,
                SheetItem(
                  title: "action_report".bhTR,
                  onTap: () {
                    DialogUtil.dismiss();
                    ReportSubSheet.show(
                      userId: toUserId,
                    );
                  },
                ),
                gap,
                GestureDetector(
                  onTap: () => DialogUtil.dismiss(),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    height: 23.w,
                    margin: EdgeInsets.symmetric(horizontal: 6.w,vertical: 5.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11.5.w),
                      gradient: const LinearGradient(
                          colors: MyColor.btnGradientColors)
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "action_cancel".bhTR,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MyColor.white,
                            fontSize: 8.sp,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 关注或取消关注
  Future onFollowOrUnFollow() async {
    if (isFollow) {
      // 取消关注
      await request.userUnfriend(
        userId: toUserId,
        onSuccess: (data) {
          onFollowOrUnBack.call(false);
          Toast.showMsg("status_unfollowSuccess".bhTR);
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": toUserId,
            "follow": false,
          }));
        },
        onFail: (code, msg) {},
      );
    } else {
      // 关注
      await request.userAddFriend(
        userId: toUserId,
        onSuccess: (data) {
          onFollowOrUnBack.call(true);
          Toast.showMsg("status_followSuccess".bhTR);
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": toUserId,
            "follow": true,
          }));
        },
        onFail: (code, msg) {},
      );
    }
  }

  /// 拉黑/取消拉黑
  void onBlockOrUn() async {
    if (isBlock) {
      // 取消拉黑
      await request.reportRemoveBlock(
        userId: toUserId,
        onSuccess: (data) {
          onBlockOrUnBack.call(false);
          Toast.showMsg("status_unblockSuccessfully".bhTR);
          RCMessageManager().removeBlock(toUserId);
          EventBusUtil.fire(OtherEvent(type: OtherType.block, data: {
            "userId": toUserId,
            "block": false,
          }));
        },
        onFail: (code, msg) {},
      );
    } else {
      // 拉黑
      await request.reportInsertRecord(
        userId: toUserId,
        complainCategory: "Block",
        onSuccess: (data) {
          onBlockOrUnBack.call(true);
          RCMessageManager().addBlock(toUserId);
          EventBusUtil.fire(OtherEvent(type: OtherType.block, data: {
            "userId": toUserId,
            "block": true,
          }));
          Toast.showMsg("status_blockSuccessfully".bhTR);
        },
        onFail: (code, msg) {},
      );
    }
  }
}
