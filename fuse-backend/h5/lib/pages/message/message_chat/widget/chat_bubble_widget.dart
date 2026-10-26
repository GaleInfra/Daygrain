import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:linkify_plus/linkify_plus.dart';
// import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/pay_handler.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/common_logic/banner_strong_guide_logic.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/message/rc_message_model.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/pages/message/message_chat/logic.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/pages/message/message_chat/widget/voice_widget.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/launch_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/dialog/recharge_link_dialog.dart';

import '../../../../config/route.dart';
import '../../../../res/my_color.dart';
import '../../../../rong_cloud/rc_message_manager.dart';
import '../../../../utils/gift_util.dart';
import '../../../../widget/image/my_extended_network_image.dart';
import '../../../../widget/my_gradient_text.dart';

/// create: 2023/5/17
/// desc: 聊天气泡，包括了系统提示的送礼消息
class ChatBubbleWidget extends StatelessWidget {
  const ChatBubbleWidget({
    Key? key,
    required this.model,
    required this.receivedAvatar,
    required this.sendAvatar,
    required this.item,
    required this.previousTime,
    required this.onTrans,
    required this.onTapPress,
    required this.onLongPress,
    required this.deleteList,
    required this.logic,
  }) : super(key: key);

  final UserInfoModel? model;

  /// 对方头像
  final String receivedAvatar;

  /// 自己的头像
  final String sendAvatar;

  /// 对话数据
  final RCMessageModel item;

  /// 上一条对话时间
  final int previousTime;

  /// 翻译
  final VoidCallback onTrans;

  /// 长按操作
  final VoidCallback? onLongPress;

  final VoidCallback? onTapPress;

  /// 待删除消息集合
  final List<JSMessage> deleteList;

  final MessageChatLogic logic;

  /// 重试
  Future _onRetry() async {
    if (item.message.messageType == JSMessageType.text) {
      // 文本消息重试
      RCMessageManager().sendTextMessage(
        message: item.message,
        targetId: null,
        sendId: null,
        nickname: null,
        avatar: null,
        text: null,
      );
    } else if (item.message.messageType == JSMessageType.image) {
      // 图片消息重试
      // RCMessageManager().sendPicMessage(
      //   message: item.message,
      //   targetId: null,
      //   sendId: null,
      //   nickname: null,
      //   avatar: null,
      //   path: null,
      // );
    } else if (item.message.messageType == JSMessageType.voice) {
      // 语音消息重试
      // RCMessageManager().sendVoiceMessage(
      //   message: item.message,
      //   targetId: null,
      //   sendId: null,
      //   nickname: null,
      //   avatar: null,
      //   path: null,
      //   duration: null,
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 为礼物消息
    bool isGift = item.message.messageType == JSMessageType.singleJsonMsg && (item.message.content as JSSingleJsonMsgMessageContent).contentType == "gift";

    /// 是否为正确的消息
    bool isMessage =
        item.message.messageType != JSMessageType.unknown && item.message.messageType != JSMessageType.command && item.message.messageType != JSMessageType.noneFlagMessage;

    /// 是否为发送方
    bool isSend = item.message.messageDirection == 1;

    if (isGift) {
      if (item.message.messageType == JSMessageType.singleJsonMsg) {
        // 礼物消息
        return Center(child: _GiftTip(item: item.message));
      }
    }
    if (item.message.messageType == JSMessageType.singleJsonMsg &&
        ((item.message.content as JSSingleJsonMsgMessageContent).contentType == "script-question" ||
            (item.message.content as JSSingleJsonMsgMessageContent).contentType == "video")) {
      // 问题消息
      isMessage = true;
    }

    if (isMessage) {
      /// 头像
      Widget header = GestureDetector(
        onTap: () {
          if (!isSend && !Get.find<AppConfigManager>().onCheckSystem(item.message.senderUserId!)) {
            BroadcasterDetailPage.to(model ?? UserInfoModel(userId: item.message.senderUserId));
          }
        },
        child: Stack(
          children: [
            MyExtendedNetworkImage(
              url: isSend ? sendAvatar : receivedAvatar,
              width: 21.w,
              height: 21.w,
              shape: BoxShape.circle,
              fit: BoxFit.cover,
            ),
            //在线状态
            // if (!isSend &&
            //     !Get.find<AppConfigManager>()
            //         .onCheckSystem(item.message.senderUserId!))
            //   Positioned(
            //     bottom: 0,
            //     right: BHLanguageMar().isRightToLeft.value ? null : 0,
            //     left: BHLanguageMar().isRightToLeft.value ? 0 : null,
            //     child: Obx(
            //       () => OnlineStatusWidget(
            //         status: logic.onlineStatus.value,
            //       ),
            //     ),
            //   ),
          ],
        ),
      );
      Widget? child;
      if (item.message.messageType == JSMessageType.text) {
        /// 文本消息
        child = _BubbleMsg(
          item: item,
          isSend: isSend,
          onTrans: onTrans,
        );
      } else if (item.message.messageType == JSMessageType.image) {
        /// 图片消息
        child = _BubblePic(item: item.message.content as JSImageMessageContent, isSend: isSend);
      } else if (item.message.messageType == JSMessageType.singleJsonMsg && (item.message.content as JSSingleJsonMsgMessageContent).contentType == "video") {
        // 视频消息
        child = _BubbleVideo(item: item.message.content as JSSingleJsonMsgMessageContent, isSend: isSend, logic: logic);
      } else if (item.message.messageType == JSMessageType.voice) {
        /// 语音消息
        child = VoiceWidget(logic: logic, message: item.message, isSend: isSend);
        // child = ChatBubbleVoiceWidget(key: ValueKey(item.message.messageId), item: item.message as RCIMIWVoiceMessage, isSend: isSend);
      } else if (item.message.messageType == JSMessageType.file) {
        child = _BubbleFileMsg(
          item: item,
        );

        /// 文件消息
        // 获取文件类型
        // String? mimeType = lookupMimeType(path);

        // mimeType.startsWith('image'); 图片
        // mimeType?.startsWith('video/'); 视频
      } else if (item.message.messageType == JSMessageType.hyperLinkMessage) {
        /// 超链接消息
        child = _BubbleLinkMsg(item: item, isSend: isSend);
      } else if (item.message.content is JSSingleJsonMsgMessageContent && (item.message.content as JSSingleJsonMsgMessageContent).contentType == "tpp") {
        // im充值卡片
        child = _RechargeCard(item: item.message);
      } else if (item.message.messageType == JSMessageType.singleJsonMsg && (item.message.content as JSSingleJsonMsgMessageContent).contentType == "script-question") {
        // 问题消息
        child = _QuestionBubbleMsg(item: item, isSend: isSend, onTrans: onTrans);
      } else {
        return const SizedBox();
      }

      Widget? timeWidget;
      DateTime current = DateTime.fromMillisecondsSinceEpoch(item.message.sentTime ?? 0); // 当前数据时间
      DateTime previous = DateTime.fromMillisecondsSinceEpoch(previousTime); // 上一条数据时间
      if (current.difference(previous).inMinutes > 1) {
        timeWidget = Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 3.w),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              DateTimeUtil.getDateTimeForChat(current),
              style: TextStyle(
                color: const Color.fromARGB(255, 155, 153, 160),
                fontSize: 5.sp,
              ),
            ),
          ),
        );
      }

      child = Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 发送失败
            Visibility(
              visible: isSend && item.message.sentStatus == SentStatus.failed.value,
              child: _Retry(
                onRetry: _onRetry,
              ),
            ),
            Visibility(
              visible: isSend && item.message.sentStatus == SentStatus.sending.value,
              child: SizedBox(
                width: 5.w,
                height: 5.w,
                child: const CircularProgressIndicator(
                  color: MyColor.black,
                  strokeWidth: 2,
                ),
              ),
            ),
            Flexible(
              child: child,
            ),
          ],
        ),
      );

      return GestureDetector(
        onTap: () {
          if (logic.deleteMore.value) {
            logic.onSelectDelete(item.message);
          } else {
            if (onTapPress != null) {
              onTapPress?.call();
            }
          }
        },
        onLongPress: onLongPress,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          child: Column(
            children: [
              if (timeWidget != null) timeWidget,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    return Visibility(
                      visible: logic.deleteMore.value,
                      child: Checkbox(
                        value: deleteList.any((element) => element.messageUId == item.message.messageUId && element.messageId == item.message.messageId),
                        onChanged: (value) => logic.onSelectDelete(item.message),
                        shape: const CircleBorder(),
                        activeColor: MyColor.themeColor,
                        side: BorderSide(color: MyColor.white, width: .5.w),
                      ),
                    );
                  }),
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isSend ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        // 对方头像
                        if (!isSend) header,
                        child,
                        // 己方头像
                        if (isSend) header,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }
}

class _BubbleFileMsg extends StatelessWidget {
  const _BubbleFileMsg({
    Key? key,
    required this.item,
  }) : super(key: key);

  final RCMessageModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.w),
        color: MyColor.otherMessageBGColor,
      ),
      child: Container(
        child: Text("[${"un_support_file_message".bhTR}]",
            style: TextStyle(
              color: MyColor.white,
              fontSize: 8.sp,
            )),
      ),
    );
  }
}

/// 文本内容气泡
class _BubbleMsg extends StatelessWidget {
  const _BubbleMsg({
    Key? key,
    required this.item,
    required this.isSend,
    required this.onTrans,
  }) : super(key: key);

  final RCMessageModel item;

  /// 是否为发送方
  final bool isSend;

  /// 翻译
  final VoidCallback onTrans;

  @override
  Widget build(BuildContext context) {
    JSTextMessageContent textMessage = item.message.content as JSTextMessageContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.w),
            color: isSend ? null : MyColor.otherMessageBGColor,
            gradient: isSend ? const LinearGradient(colors: MyColor.myMessageBGColors) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? EdgeInsets.only(bottom: 7.w)
                    : null,
                margin: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? EdgeInsets.only(bottom: 7.w)
                    : null,
                decoration: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFF7C7C7C), width: .3.w),
                        ),
                      )
                    : null,
                child: Linkify(
                  text: textMessage.content ?? "",
                  style: TextStyle(
                    color: isSend ? MyColor.textBlack : MyColor.white,
                    fontSize: 7.5.sp,
                  ),
                  options: const LinkifyOptions(
                    humanize: false,
                  ),
                  onOpen: (link) async {
                    LaunchUtil.launchJump(url: link.url);
                  },
                ),
              ),
              Visibility(
                visible: !isSend && item.translateStatus == TranslateStatus.translating,
                child: SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(MyColor.highlightColor),
                  ),
                ),
              ),
              Visibility(
                visible: !isSend && item.translateStatus == TranslateStatus.translateSuccess,
                child: Text(
                  item.translate ?? "",
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 6.5.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: !isSend && (item.translateStatus == TranslateStatus.translateFail || item.translateStatus == TranslateStatus.none),
          child: Padding(
            padding: EdgeInsets.only(top: 2.w, left: 5.w, right: 5.w),
            child: GestureDetector(
              onTap: onTrans,
              child: Container(
                color: Colors.transparent,
                height: 12.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      item.translateStatus == TranslateStatus.translateFail ? ImageAssets.messageTranslateReload : ImageAssets.messageTranslate,
                      width: 8.w,
                      height: 8.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 3.w),
                    Text(item.translateStatus == TranslateStatus.translateFail ? "Translation_failed".bhTR : "action_clickToTranslate".bhTR,
                      style: TextStyle(
                        color:   MyColor.highlightColor,
                        fontSize: 6.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 文本内容气泡
class _QuestionBubbleMsg extends StatelessWidget {
  const _QuestionBubbleMsg({
    Key? key,
    required this.item,
    required this.isSend,
    required this.onTrans,
  }) : super(key: key);

  final RCMessageModel item;

  /// 是否为发送方
  final bool isSend;

  /// 翻译
  final VoidCallback onTrans;

  @override
  Widget build(BuildContext context) {
    JSSingleJsonMsgMessageContent textMessage = item.message.content as JSSingleJsonMsgMessageContent;
    QuestionData questionData = textMessage.questionData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.w),
            color: isSend ? null : MyColor.otherMessageBGColor,
            gradient: isSend ? const LinearGradient(colors: MyColor.myMessageBGColors) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? EdgeInsets.only(bottom: 7.w)
                    : null,
                margin: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? EdgeInsets.only(bottom: 7.w)
                    : null,
                decoration: !isSend && (item.translateStatus == TranslateStatus.translating || item.translateStatus == TranslateStatus.translateSuccess)
                    ? BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: const Color(0xFF7C7C7C), width: .3.w),
                        ),
                      )
                    : null,
                child: Linkify(
                  text: questionData.content ?? "",
                  style: TextStyle(
                    color: isSend ? MyColor.textBlack : MyColor.white,
                    fontSize: 7.5.sp,
                  ),
                  options: const LinkifyOptions(
                    humanize: false,
                  ),
                  onOpen: (link) async {
                    LaunchUtil.launchJump(url: link.url);
                  },
                ),
              ),
              Visibility(
                visible: !isSend && item.translateStatus == TranslateStatus.translating,
                child: SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(MyColor.highlightColor),
                  ),
                ),
              ),
              Visibility(
                visible: !isSend && item.translateStatus == TranslateStatus.translateSuccess,
                child: Text(
                  item.translate ?? "",
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 6.5.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: !isSend && (item.translateStatus == TranslateStatus.translateFail || item.translateStatus == TranslateStatus.none),
          child: Padding(
            padding: EdgeInsets.only(top: 2.w, left: 5.w, right: 5.w),
            child: GestureDetector(
              onTap: onTrans,
              child: Container(
                color: Colors.transparent,
                height: 12.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      item.translateStatus == TranslateStatus.translateFail ? ImageAssets.messageTranslateReload : ImageAssets.messageTranslate,
                      width: 8.w,
                      height: 8.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                     
                      item.translateStatus == TranslateStatus.translateFail ? "Translation_failed".bhTR : "action_clickToTranslate".bhTR,
                     style: TextStyle(
                        color:   MyColor.highlightColor,
                        fontSize: 6.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 超链接文本内容气泡
class _BubbleLinkMsg extends StatelessWidget {
  _BubbleLinkMsg({
    Key? key,
    required this.item,
    required this.isSend,
  }) : super(key: key);

  final RCMessageModel item;

  /// 是否为发送方
  final bool isSend;

  final _request = Get.find<RequestRepository>();

  @override
  Widget build(BuildContext context) {
    JSHyperLinkMessageContent message = item.message.content as JSHyperLinkMessageContent;

    return GestureDetector(
      onTap: () => _onCheck(message, context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.w),
          color: isSend ? null : MyColor.otherMessageBGColor,
          gradient: isSend ? const LinearGradient(colors: MyColor.myMessageBGColors) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content ?? "",
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFEFF04E),
                color: const Color(0xFFEFF04E),
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查链接有效性
  Future _onCheck(JSHyperLinkMessageContent message, BuildContext context) async {
    if (message.contentType != "recharge_link") {
      // 非充值链接，不处理
      return;
    }
    Map map = jsonDecode(message.extra ?? "");

    CancelToken cancelToken = CancelToken();
    Toast.showLoading(onDismiss: () {
      cancelToken.cancel("cancel");
    });
    try {
      bool valid = false;
      await _request.coinCheckInvitation(
        invitationId: map['invitationId'],
        cancelToken: cancelToken,
        onSuccess: (data) {
          valid = data;
        },
        onFail: (code, msg) {
          throw Exception(msg);
        },
      );
      if (!valid) {
        // 无效
        Toast.showMsg("Recharge info is Passed".bhTR);
        return;
      }
      await _request.coinGoodsInvitation(
        invitationId: map['invitationId'],
        onSuccess: (data) {
          var list = CoinGoodsLogic.filterNonVipCoinGoods(data);
          if (Get.isRegistered<BannerStrongGuideLogic>()) {
            final strongGuide = Get.find<BannerStrongGuideLogic>();
            if (strongGuide.strongGuideModel.value != null) {
              list.add(CoinGoodsModel(code: "-1"));
            }
          }
          RechargeLinkDialog.show(
            list: list,
            bindWidget: context,
          );
        },
        onFail: (code, msg) {
          throw Exception(msg);
        },
      );
    } catch (e) {
      logger.e(e.toString());
    } finally {
      Toast.dismiss();
    }
  }
}

/// 图片内容气泡
class _BubblePic extends StatelessWidget {
  const _BubblePic({
    Key? key,
    required this.item,
    required this.isSend,
  }) : super(key: key);

  /// 对话数据
  final JSImageMessageContent item;

  /// 是否是自己
  final bool isSend;

  @override
  Widget build(BuildContext context) {
    // Size? imageSize;

    // ///判断是否有缩略图 ，有的话将Base64转为图片获取宽高比
    // if (item.thumbnailBase64String?.isNotEmpty ?? false) {
    //   Size imageSize2 = item.thumbnailBase64String!.getImageSize();
    //   if (imageSize2.width > 0 && imageSize2.height > 0) {
    //     imageSize = imageSize2;
    //   }
    // }
    Widget image = const SizedBox();
    // if (item.imageUri != null && item.imageUri!.isNotEmpty) {
    //   image = GestureDetector(
    //     onTap: () {
    //       final imageUrl = item.imageUri;
    //       if (imageUrl?.isNotEmpty ?? false) {
    //         Get.toNamed(RoutePath.seeImagePage, arguments: {
    //           "index": 0,
    //           "urls": [item.imageUri!],
    //         });
    //       }
    //     },
    //     child: ClipRRect(
    //       borderRadius: BorderRadius.circular(6.w),
    //       child: Image.file(
    //         File(item.local?.replaceAll("file:///", "") ?? ""),
    //         fit: BoxFit.fitWidth,
    //       ),
    //     ),
    //   );
    // } else if (item == RCIMIWSentStatus.sent) {
    image = GestureDetector(
      onTap: () => Get.toNamed(RoutePath.seeImagePage, arguments: {
        "index": 0,
        "isChat": 1,
        "urls": [item.imageUri!],
      }),
      child: MyExtendedNetworkImage(
        url: item.imageUri ?? "",
        fit: BoxFit.cover,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6.w),
        // width: 70.w,
        // height: 70.w,
      ),
    );
    // }
    // todo 宽高比还未实现
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Container(
          constraints: BoxConstraints(
            minWidth: 70.w,
            maxWidth: 70.w,
            minHeight: 110.w,
            maxHeight: 110.w,
          ),
          child: image),
    );
  }
}

/// 视频消息
class _BubbleVideo extends StatelessWidget {
  const _BubbleVideo({
    Key? key,
    required this.item,
    required this.isSend,
    required this.logic,
  }) : super(key: key);

  /// 对话数据
  final JSSingleJsonMsgMessageContent item;
  final MessageChatLogic logic;

  /// 是否是自己
  final bool isSend;

  @override
  Widget build(BuildContext context) {
    VideoData? videoData = item.videoData;
    if (videoData == null) {
      return const SizedBox();
    }
    String videoUrl = videoData.videoUrl ?? "";
    String videoThumb = videoData.videoThumb ?? "";

    //获取是否付费用户
    bool isRecharge = Get.find<AppConfigManager>().isRecharge;
    // //是否需要解锁
    // bool isLock = item.extensionData?.isLock ?? false;
    //是否拦截
    bool isIntercept = false;
    if (!isRecharge) {
      isIntercept = true;
    }

    Widget image = const SizedBox();

    //图片加载完成后 高斯模糊

    image = MyExtendedNetworkImage(
      url: videoThumb,
      fit: BoxFit.cover,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(6.w),
    );
    if (isIntercept) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(6.w),
        child: Stack(
          children: [
            image,
            BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent)),
          ],
        ),
      );
    }

    // }
    // todo 宽高比还未实现
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: GestureDetector(
        onTap: () {
          if (isIntercept) {
            // 弹出充值弹窗
            RechargeDialog.show(entry: PayEntry.SOURCE_62, bindWidget: context);
            return;
          }
          Get.toNamed(RoutePath.seeVideoPage, arguments: {
            "index": 0,
            "userInfo": logic.userInfo,
            "urls": [videoUrl],
            "thumUrls": [videoThumb],
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
                constraints: BoxConstraints(
                  minWidth: 70.w,
                  maxWidth: 70.w,
                  minHeight: 110.w,
                  maxHeight: 110.w,
                ),
                child: image),
            //中间显示 播放按钮
            Positioned(
              child: Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  color: MyColor.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18.w),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: MyColor.white,
                    size: 16.w,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Visibility(
                visible: isIntercept,
                child: Container(
                  height: 18.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(6.w),
                      bottomRight: Radius.circular(6.w),
                    ),
                    color: MyColor.black.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 2.w),
                      //🔐
                      Image.asset(
                        ImageAssets.messageMediaLock,
                        width: 6.w,
                        height: 7.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(child: Text("Top up to view".bhTR, style: TextStyle(color: MyColor.white, fontSize: 5.5.sp),maxLines: 2,)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// 送礼tip
class _GiftTip extends StatelessWidget {
  const _GiftTip({
    Key? key,
    required this.item,
  }) : super(key: key);

  final JSMessage item;

  @override
  Widget build(BuildContext context) {
    JSSingleJsonMsgMessageContent item = this.item.content as JSSingleJsonMsgMessageContent;
    if (!(item.content?.contains("toUserName") ?? false)) {
      return const SizedBox();
    }

    Map<String, dynamic> map = jsonDecode(item.content ?? "");
    String name = map['toUserName'] ?? "";
    if (name.length > 10) {
      name = "${name.substring(0, 10)}...";
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              "you_have_sent_a".bhTR.replaceAll("####", name.truncateThan(10)),
              style: TextStyle(
                color: MyColor.white,
                fontSize: 7.sp,
              ),
            ),
          ),
          Image.asset(
            GiftUtil.giftImageList.where((element) => element.name == map['giftCode']).first.thumbnail,
            width: 15.w,
            height: 15.w,
            cacheWidth: 50,
          ),
          Text(
            " !",
            style: TextStyle(
              color: MyColor.white,
              fontSize: 7.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// 充值卡片
class _RechargeCard extends StatelessWidget {
  _RechargeCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  final JSMessage item;

  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    JSSingleJsonMsgMessageContent content = item.content as JSSingleJsonMsgMessageContent;

    Map data = jsonDecode(content.content ?? "");
    dynamic tppOpenType = appConfig.getAppConfigByKey("tpp_open_type");
    tppOpenType ??= "1";
    String url = data['tppUrl'];

    return GestureDetector(
      onTap: () async {
        logger.d(url);
        final inside = tppOpenType.toString() == "0";
        if (BHPlatform.isWeb) {
          try {
            await JSRongCloudManager.myBrowser(url, inside ? 0 : 1, 1);
          } catch (e) {}
          Get.find<PayHandler>().listenRecharge();
          return;
        }
        if (inside) {
          WebViewPage.onJump(url: url, isCanMultiWindow: false);
        } else {
          LaunchUtil.launchJump(url: url);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.w),
          color: MyColor.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['tppOutsideTitle'],
              style: TextStyle(
                color: MyColor.black,
                fontSize: 8.sp,
              ),
            ),
            MyGaps.vGaps5w,
            MyExtendedNetworkImage(
              url: data['tppImageUrl'],
              width: double.infinity,
              height: 70.w,
              fit: BoxFit.cover,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(5.w),
            ),
            MyGaps.vGaps5w,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "action_clickForDetails".bhTR,
                  style: TextStyle(
                    color: MyColor.blue4A99F4,
                    fontSize: 8.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 发送失败提示重试组件
class _Retry extends StatelessWidget {
  const _Retry({
    Key? key,
    required this.onRetry,
  }) : super(key: key);

  /// 重新发送
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Icon(
        Icons.error,
        color: MyColor.redFF5E5E,
        size: 11.w,
      ),
    );
  }
}
