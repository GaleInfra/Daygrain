import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/widget/online_status_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../common_logic/user_status_service.dart';
import '../../../../event_bus/base/event_bus_util.dart';
import '../../../../js/Model/JSConversation.dart';
import '../../../../res/my_color.dart';
import '../../../../widget/image/my_extended_network_image.dart';

/// create: 2023/4/27
/// desc: 消息列表item
class MessageListItem extends StatefulWidget {
  const MessageListItem({
    Key? key,
    required this.item,
    required this.userInfoModel,
    this.onTap,
    this.onDelete,
    this.onTop,
  }) : super(key: key);

  /// 消息体
  final JSConversation item;

  final UserInfoModel? userInfoModel;

  final VoidCallback? onTap;

  final VoidCallback? onDelete;
  final VoidCallback? onTop;

  @override
  State<MessageListItem> createState() => _MessageListItemState();
}

class _MessageListItemState extends State<MessageListItem> {
  final appConfig = Get.find<AppConfigManager>();
  // final userStatus = kOffline.obs;
  // StreamSubscription? _userStateEvent;
  // StreamSubscription? _userStateEvent;

  /// 在线状态
  // final onlineStatus = kOffline.obs;
  @override
  void initState() {
    // getUserStatusService()?.getStatus(widget.item.targetId ?? "");
    super.initState();
  }

  //监听显示隐藏
  void onVisibilityChanged(VisibilityInfo info) {
    // if (info.visibleFraction == 0) {
    //   removeListener();
    // } else {
    //   bool systemAccount = appConfig.onCheckSystem(widget.item.targetId ?? "");
    //   if (!systemAccount) {
    //     getUserStatusService()?.addUserId(widget.item.targetId ?? "");
    //     if (_userStateEvent == null) {
    //       registerListener();
    //       final stat =
    //       getUserStatusService()?.getStatus(widget.item.targetId ?? "");
    //       if (stat != null) {
    //         userStatus.value = stat;
    //       }
    //     }
    //   }
    // }
  }

  // //监听状态刷新
  // void registerListener() {
  //   removeListener();
  //   _userStateEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
  //     if (event.uidAndStatus.containsKey(widget.item.targetId)) {
  //       userStatus.value =
  //           event.uidAndStatus[widget.item.targetId] ?? kOffline;
  //     }
  //   });
  // }

  // //移除监听
  // void removeListener() {
  //   if (_userStateEvent != null) {
  //     _userStateEvent!.cancel();
  //     _userStateEvent = null;
  //   }
  // }

  @override
  void dispose() {
    // removeListener();
    // _userStateEvent?.cancel();
    // _userStateEvent = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String lastMsg = "";
    if (widget.item.latestMessage == null) return const SizedBox();
    JSMessage lastMessage = widget.item.latestMessage!;
    if (lastMessage.messageType == JSMessageType.text) {
      lastMsg = lastMessage.content?.content ?? "";
    } else if (lastMessage.messageType == JSMessageType.image) {
      lastMsg = "[${"label_image".bhTR}]";
    } else if (lastMessage.messageType == JSMessageType.voice) {
      lastMsg = "[${"label_voice".bhTR}]";
    } else if (lastMessage.messageType == JSMessageType.file) {
      lastMsg = "[${"label_file".bhTR}]";
    } else if (lastMessage.messageType == JSMessageType.sight) {
      lastMsg = "[${"label_video".bhTR}]";
    } else if (lastMessage.messageType == JSMessageType.singleJsonMsg) {
      if (lastMessage.content?.contentType == "tpp") {
        lastMsg = '[${"recharge_card".bhTR}]';
      } else if (lastMessage.content?.contentType == "script-call") {
        lastMsg = '[${"label_video_call".bhTR}]';
      } else if (lastMessage.content?.contentType == "script-question") {
        lastMsg = Get.findCanNull<AppConfigManager>()?.isRecharge ?? false ?  ((lastMessage.content as JSSingleJsonMsgMessageContent).questionData?.content ?? ""):'[${"label_question".bhTR}]';
      } else if (lastMessage.content?.contentType == "video") {
        lastMsg = '[${"label_video".bhTR}]';
      } else {
        lastMsg = '[${"label_gift".bhTR}]';
      }
    } else if (lastMessage.messageType == JSMessageType.hyperLinkMessage) {
      // 超链接消息
      lastMsg = '[${"Link".bhTR}]';
    } else {
      lastMsg = "[${"unknown".bhTR}]";
    }
    // 是否为系统帐号
    bool systemAccount = appConfig.onCheckSystem(widget.item.targetId ?? "");
    //是否默认置顶用户
    bool isDefaultTop = appConfig.topSystemList.contains(widget.item.targetId);
    if (systemAccount && appConfig.isReviewPkg.value) {
      // 审核模式且系统帐号
      return const SizedBox();
    }

    return Container(
      margin: EdgeInsets.zero,
      width: double.infinity,
      decoration: BoxDecoration(
        // border: Border.all(width: 0.0),
        color: (isDefaultTop || (widget.item.isTop ?? false)) ? const Color(0xFF2B274A) : MyColor.transparent,
      ),
      child: VisibilityDetector(
        key: Key("message_list_item_${widget.item.targetId}"),
        onVisibilityChanged: onVisibilityChanged,
        child: GestureDetector(
          onTap: widget.onTap,
          // onLongPress: systemAccount ? null : widget.onLongPress,
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: 7.w, right: 7.w, top: 3.w, bottom: 3.w),
                child: Slidable(
                  enabled: !systemAccount,
                  endActionPane: ActionPane(
                    extentRatio: 0.5,
                    motion: const ScrollMotion(),
                    children: [
                      CustomSlidableAction(
                        onPressed: (BuildContext context) {
                          widget.onTop?.call();
                        },
                        backgroundColor: !(widget.item.isTop ?? false) ? MyColor.black : const Color(0xFF0AF4D7),
                        foregroundColor: !(widget.item.isTop ?? false) ? Colors.black : const Color(0xFF0AF4D7),
                        borderRadius: BorderRadius.circular(7.5.w),
                        child: !(widget.item.isTop ?? false)
                            ? Image.asset(
                                ImageAssets.chatTop,
                                width: 12.w,
                              )
                            : Image.asset(
                                ImageAssets.chatUnTop,
                                width: 12.w,
                              ),
                      ),
                      SizedBox(width: 4.5.w),
                      CustomSlidableAction(
                        onPressed: (BuildContext context) {
                          widget.onDelete?.call();
                        },
                        backgroundColor: MyColor.pinkFE3E69,
                        foregroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(7.5.w),
                        child: Image.asset(
                          ImageAssets.messageDelete,
                          width: 12.w,
                        ),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 36.w,
                    child: Center(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: GestureDetector(
                              onTap: () {
                                if (!systemAccount) {
                                  BroadcasterDetailPage.to(widget.userInfoModel ?? UserInfoModel(userId: widget.item.targetId));
                                }
                              },
                              child: MyExtendedNetworkImage(
                                url: widget.userInfoModel?.avatarThumbUrl ?? "",
                                width: 24.w,
                                height: 24.w,
                                fit: BoxFit.cover,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          MyGaps.hGaps5w,
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        (widget.userInfoModel?.nickname ?? "").fixAutoLines(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 7.5.sp,
                                          color: MyColor.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    MyGaps.hGaps3w,
                                    Visibility(
                                      visible: systemAccount,
                                      child: Image.asset(
                                        ImageAssets.iconIsSystem,
                                        width: 6.w,
                                        height: 6.w,
                                      ),
                                    ),
                                  ],
                                ),
                                MyGaps.vGaps2w,
                                Text(
                                  lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF9A97A8),
                                    fontSize: 6.5.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MyGaps.hGaps3w,
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateTimeUtil.timeFormat(lastMessage.sentTime ?? 0),
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 6.5.sp,
                                ),
                              ),
                              MyGaps.vGaps4w,
                              Visibility(
                                visible: widget.item.unreadMessageCount != null && (widget.item.unreadMessageCount ?? 0) > 0,
                                replacement: SizedBox(
                                  height: 8.w,
                                ),
                                child: Center(
                                  child: Container(
                                    alignment: Alignment.center,
                                    constraints: BoxConstraints(minWidth: 8.w, minHeight: 8.w, maxHeight: 8.w),
                                    // padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                                    decoration: BoxDecoration(color: MyColor.pinkFE3E69, borderRadius: BorderRadius.circular(6.w), border: Border.all(color: MyColor.white, width: 1)),
                                    child: Text(
                                      "${widget.item.unreadMessageCount! > 99 ? "99+" : widget.item.unreadMessageCount!}",
                                      style: TextStyle(
                                        color: MyColor.white,
                                        fontSize: 5.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
