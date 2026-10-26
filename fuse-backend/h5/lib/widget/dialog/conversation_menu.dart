import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/rong_cloud/rc_conversations_manager.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';

import '../../res/my_color.dart';
import '../../res/my_gaps.dart';
import '../../utils/dialog_util.dart';

/// create: 2023/5/29
/// desc: 会话菜单
class ConversationMenu extends StatelessWidget {
  ConversationMenu.show({
    super.key,
    required this.item,
    BuildContext? bindWidget,
  }) {
    DialogUtil.showDialog(
      bindWidget: bindWidget,
      bindPage: false,
      child: this,
    );
  }

  final JSConversation item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: DialogBgWidget(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.w),
                // color: MyColor.dialogBg,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      DialogUtil.dismiss();
                      _onTop();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 8.w),
                      child: Text(
                        (item.isTop ?? false) ? "action_removeFromTop".bhTR : "action_pinToTop".bhTR,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
                  MyGaps.hLine,
                  GestureDetector(
                    onTap: () {
                      DialogUtil.dismiss();
                      _onRemove();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 8.w),
                      child: Text(
                        "action_removeFromChatList".bhTR,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 置顶
  void _onTop() async {
    await RCConversationsManager().changeTopStatus(targetId: item.targetId!, top: !(item.isTop ?? false), isToast: true);
  }

  /// 删除
  void _onRemove() async {
    await RCConversationsManager().removeConversation(targetId: item.targetId!);
  }
}
