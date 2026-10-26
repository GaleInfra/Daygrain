import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/utils/overlay_util.dart';

class RcMessageDialog extends StatefulWidget {
  const RcMessageDialog({super.key});

  static String tag = "RcMessageDialog";

  static void show(JSMessage message) {
    //判断是否显示
    //过滤不显示的消息 和 只显示私聊消息
    if ([JSMessageType.command, JSMessageType.commandNotification, JSMessageType.unknown].contains(message.messageType) || message.targetId == null) {
      return;
    }
    //判断如果是空消息就不处理
    if (message.messageType == JSMessageType.singleJsonMsg) {
      return;
    }
    //如果在通话中不处理

    // OverlayUtil().show(
    //   context: Get.context!,
    //   child: const RcMessageDialog(),
    //   tag: RcMessageDialog.tag,
    // );
  }

  //判断是否可以弹出
  static bool canShow() {
    if (Get.context == null) {
      return false;
    }

    if (Get.currentRoute == RoutePath.vipPage) {}

    return true;
  }

  static void dismiss() {
    OverlayUtil().dismiss(tag: RcMessageDialog.tag);
  }

  @override
  State<RcMessageDialog> createState() => _RcMessageDialogState();
}

class _RcMessageDialogState extends State<RcMessageDialog> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
