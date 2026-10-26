import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/generated/assets.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/flash_chat/start_match/logic.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/msg_notication/ChatSoundPlayer.dart';
import 'package:untitled1/widget/msg_notication/message_pop_event.dart';
import 'package:uuid/uuid.dart';

import '../../common_logic/app_config_manager.dart';
import '../../config/route.dart';
import '../../model/user/user_info_model.dart';
import '../../net/request_repository.dart';
import '../../pages/index/logic.dart';
import '../../pages/message/logic.dart';
import '../../pages/message/message_chat/view.dart';
import '../../res/my_color.dart';
import '../../utils/overlay_util.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/widget/dialog/robot_chat_dialog.dart';

///消息弹窗
class MessageNotication extends StatefulWidget {
  final String userId;
  final String nickName;
  final String avatar;
  final String content;
  final UserInfoModel userInfo;

  const MessageNotication({
    Key? key,
    required this.userId,
    required this.nickName,
    required this.avatar,
    required this.content,
    required this.userInfo,
  }) : super(key: key);

  static String? lastTag;
  static const String tag = "MessageNotication";

  //等待处理的消息
  static JSMessage? _waitHandleMessage;

  ///关闭窗口
  static void dismiss({String? tag}) {
    //修改弹框收起然后再关闭
    tag ??= lastTag;
    if (lastTag != null) {
      OverlayUtil().dismiss(tag: tag!);
    }
  }

  static Future<void> show(JSMessage message) async {
    //判断是否审核模式
    if (Get.isRegistered<AppConfigManager>()) {
      if (Get.find<AppConfigManager>().isReviewPkg.value) {
        ///审核模式不显示呼叫弹框
        return;
      }
    }
    // 判断隐私模式
    if (await PrivacyModeManager.isPrivacyModeEnabled()) {
      ///隐私模式不显示呼叫弹框
      return;
    }
    //过滤不需要通知的消息
    if (message.conversationType != 1 ||
        [JSMessageType.unknown, JSMessageType.commandNotification, JSMessageType.command].contains(message.messageType) ||
        message.targetId == null ||
        message.messageType == JSMessageType.noneFlagMessage) {
      return;
    }

    _waitHandleMessage = message;
    //500毫秒内只显示最后一个
    throttleUtil.throttle(
      () async {},
      key: tag,
      time: 500,
      onAfter: () async {
        //显示通知
        if (!isShow()) {
          return;
        }

        JSMessage message = _waitHandleMessage!;
        if (!Get.isRegistered<RequestRepository>()) {
          return;
        }
        RequestRepository repository = Get.find<RequestRepository>();
        //请求用户数据
        var userInfo = CacheManager.userInfoCache(message.targetId!);
        //播放铃声
        ChatSoundPlayer.instance.chatSoundPause();
        ChatSoundPlayer.instance.chatSoundPlay();

        if (userInfo == null) {
          repository.userGetInfo(
            userId: message.targetId!,
            onSuccess: (data) {
              userInfo = data;
              _show(message, userInfo!);
            },
            onFail: (code, msg) {},
          );
        } else {
          _show(message, userInfo);
        }
      },
    );
  }

  //关闭
  static void _show(JSMessage message, UserInfoModel userInfo) {
    if (!isShow()) {
      return;
    }
    String content = '';
    //根据消息类型显示不同的内容
    /* 图片显示为 [Image] 链接显示为[Link] 语音显示为[Voice] 文件显示为[File] 视频显示为[Video] 为文本是显示文本内容，超过30字符用...代替*/
    switch (message.messageType) {
      case JSMessageType.text:
        //获取文本内容 转换为文本消息
        JSTextMessageContent textMessage = message.content as JSTextMessageContent;
        content = textMessage.content ?? '';
        if (content.length > 30) {
          content = '${content.truncateThan(30)}...';
        }
        break;
      case JSMessageType.image:
      case JSMessageType.gif:
        content = '[${"label_image".bhTR}]';
        break;
      case JSMessageType.voice:
        content = '[${"label_voice".bhTR}]';
        break;
      case JSMessageType.file:
        content = '[${"label_file".bhTR}]';
        // content = '[${"unknown".bhTR}]';
        break;
      case JSMessageType.sight:
        content = '[${"label_video".bhTR}]';
        break;
      case JSMessageType.singleJsonMsg:
        JSSingleJsonMsgMessageContent singleJsonMsg = message.content as JSSingleJsonMsgMessageContent;
        if (singleJsonMsg.contentType == "tpp") {
          content = '[${"recharge_card".bhTR}]';
        }else if (singleJsonMsg.contentType == "script-question") {
         
          content = Get.findCanNull<AppConfigManager>()?.isRecharge ?? false ?  (singleJsonMsg.questionData?.content ?? ""):'[${"label_question".bhTR}]';
        } else if (singleJsonMsg.contentType == "video") {
          content = '[${"label_video".bhTR}]';
        }else {
          content = '[${"label_gift".bhTR}]';
        }
        break;

      case JSMessageType.unknown:
      default:
        content = '[${"unknown".bhTR}]';
        break;
    }
    if (message.messageType == JSMessageType.hyperLinkMessage) {
      content = '[${"Link".bhTR}]';
    } else if (message.messageType == JSMessageType.singleJsonMsg && (message.content as JSSingleJsonMsgMessageContent).contentType == "tpp") {
      content = '[${"recharge_card".bhTR}]';
    }
    //关闭旧的
    dismiss();

    var tagKey = const Uuid().v1();
    lastTag = tagKey;
    OverlayUtil().show(
      context: Get.overlayContext!,
      child: MessageNotication(
        userId: message.targetId!,
        nickName: userInfo.nickname ?? '',
        content: content,
        avatar: userInfo.avatarUrl ?? '',
        userInfo: userInfo,
      ),
      tag: lastTag!,
    );
    //倒计时3秒关闭
    Future.delayed(const Duration(seconds: 5), () {
      dismiss(tag: tagKey);
    });
  }

  static bool isShow() {
    //当前正在被呼叫
    if (Get.isRegistered<VideoCallHandler>() && Get.find<VideoCallHandler>().onCallModel != null) {
      return false;
    }
    // 机器人全屏弹窗优先级更高，显示时不展示消息横条
    if (RobotChatDialog.isShowing) {
      return false;
    }
    //当前是否正在匹配中
    if (Get.isRegistered<StartMatchLogic>()) {
      return false;
    }

    //判断当前是否在私聊页面
    if (Get.currentRoute == RoutePath.messageChatPage ||
        Get.currentRoute == RoutePath.callPage ||
        Get.currentRoute == RoutePath.onCallPage ||
        Get.currentRoute == RoutePath.videoCallPage) {
      return false;
    }

    //判断当前如果在消息页面则不弹出消息弹窗
    if (Get.isRegistered<IndexLogic>()) {
      final index = Get.find<IndexLogic>().currentIndex.value;
      if (Get.currentRoute == RoutePath.indexPage && index == 2) {
        if (Get.isRegistered<MessageLogic>()) {
          final logic = Get.find<MessageLogic>();
          if (logic.index.value == 0) {
            //如果当前在消息列表也不显示弹框
            return false;
          }
        }
      }
    }
    return true;
  }

  @override
  State<MessageNotication> createState() => _MessageNoticationState();
}

class _MessageNoticationState extends State<MessageNotication> {
  double top = -45.w;
  StreamSubscription<MessagePopEvent>? _event;

  void onMountedState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      top = ScreenUtil().statusBarHeight + 50;
      if (mounted) {
        setState(() {});
      }
    });
    _event = EventBusUtil.listen<MessagePopEvent>((event) {
      MessageNotication.dismiss();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _event?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      top: top,
      right: 0,
      left: 0,
      child: GestureDetector(
        onTap: () {
          //转跳消息详情
          top = -46.w;
          MessageNotication.dismiss();
          MessageChatPage.to(widget.userInfo);
        },
        onPanUpdate: (DragUpdateDetails details) {
          top += details.delta.dy;
          if (top > Get.mediaQuery.padding.top) {
            // 限制最下滑动
            top = Get.mediaQuery.padding.top;
          }
          onMountedState();
        },
        onPanEnd: (DragEndDetails details) {
          if (top < -Get.mediaQuery.padding.top) {
            top = -46.w;
            // 挂断
            MessageNotication.dismiss();
          } else {
            top = Get.mediaQuery.padding.top;
          }
          onMountedState();
        },
        child: Container(
          width: double.infinity,
          height: 46.w,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          //渐变背景
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.w)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                MyColor.btnGradientColors2[4],
                MyColor.btnGradientColors2[3],
              ],
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 6.w,
              ),
              MyExtendedNetworkImage(
                url: widget.avatar,
                width: 25.w,
                height: 25.w,
                fit: BoxFit.cover,
                shape: BoxShape.circle,
              ),
              SizedBox(
                width: 5.w,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nickName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: MyColor.grey2C2B29,
                        fontSize: 8.sp,
                      ),
                    ),
                    SizedBox(
                      height: 2.w,
                    ),
                    Text(
                      widget.content,
                      maxLines: 2,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: MyColor.grey2C2B29,
                        fontSize: 6.sp,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 5.w,
              ),
              Container(
                width: 21.w,
                height: 21.w,
                padding: EdgeInsets.only(top: 2.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MyColor.white,
                  borderRadius: BorderRadius.all(Radius.circular(10.w)),
                ),
                child: Image.asset(
                  Assets.messageIcMessageNotication,
                  width: 11.w,
                  height: 11.w,
                ).bh,
              ),
              SizedBox(
                width: 6.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
