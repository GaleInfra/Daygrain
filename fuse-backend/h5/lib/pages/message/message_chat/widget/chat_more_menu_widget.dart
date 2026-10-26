import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/pages/message/message_chat/logic.dart';
import 'package:untitled1/res/my_color.dart';

/// create: 2023/5/29
/// desc: 私聊页更多操作
class ChatMoreMenuWidget extends StatelessWidget {
  const ChatMoreMenuWidget({
    Key? key,
    required this.logic,
  }) : super(key: key);

  final MessageChatLogic logic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => logic.onDelMore(),
      child: Container(
        width: double.infinity,
        height: 25.w,
        color: MyColor.white,
        child: const Icon(
          Icons.delete_outline,
        ),
      ),
    );
  }
}
