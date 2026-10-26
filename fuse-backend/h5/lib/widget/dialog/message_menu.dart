import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/message/message_chat/logic.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';

import '../../res/my_color.dart';
import '../../res/my_gaps.dart';

/// create: 2023/5/29
/// desc: 私聊页消息菜单
class MessageMenu extends StatelessWidget {
  MessageMenu.show({
    super.key,
    required this.message,
    required this.logic,
    BuildContext? bindWidget,
  }) {
    DialogUtil.showDialog(
      bindWidget: bindWidget,
      bindPage: false,
      child: this,
    );
  }

  final JSMessage message;

  final MessageChatLogic logic;

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
              ),
              child: Column(
                children: [
                  // 仅文本消息可复制
                  Visibility(
                    visible: message.messageType == JSMessageType.text,
                    child: GestureDetector(
                      onTap: () {
                        DialogUtil.dismiss();
                        _onCopy();
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(vertical: 6.w),
                        child: Text(
                          "action_copy".bhTR,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 9.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  MyGaps.hLine,
                  GestureDetector(
                    onTap: () {
                      DialogUtil.dismiss();
                      _onDel();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 6.w),
                      child: Text(
                        "action_delete".bhTR,
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
                      _onDelMore();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 6.w),
                      child: Text(
                        "label_more".bhTR,
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

  /// 复制
  void _onCopy() {
    Clipboard.setData(ClipboardData(text: (message.content as JSTextMessageContent).content ?? ""));
  }

  /// 删除消息
  void _onDel() async {
    try {
      await RCMessageManager().deleteMessages(targetId: message.targetId!, messages: [message]);
      logic.list.removeWhere((element) {
        if (element.message.messageUId != null && element.message.messageUId == message.messageUId) {
          return true;
        } else if (element.message.messageId != null && element.message.messageId == message.messageId) {
          return true;
        } else {
          return false;
        }
      });
    } catch (e) {}
  }

  /// 删除更多
  void _onDelMore() {
    logic.deleteMore.value = !logic.deleteMore.value;
  }
}
