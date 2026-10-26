import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/pages/message/message_list/widget/message_list_item.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/rong_cloud/rc_conversations_manager.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';

import 'logic.dart';

/// 消息列表
class MessageListWidget extends StatefulWidget {
  const MessageListWidget({super.key});

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget>
    with AutomaticKeepAliveClientMixin {
  final logic = Get.put(MessageListLogic());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyColor.transparent,
      body: GetBuilder<MessageListLogic>(
        builder: (logic) {
          final chatList = List.from(logic.list);
          return RefreshWidget(
            logic: logic,
            emptyMsg: "status_noMessageRecord".bhTR,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: ListView.builder(
                  itemCount: chatList.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          Get.toNamed(RoutePath.robotPage);
                        },
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.zero,
                          height: 42.5.w,
                          color: const Color(0xFF2B274A),
                          padding: EdgeInsets.only(
                              left: 7.w,
                              right: 7.w),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        ImageAssets.mineCustomService,
                                        width: 24.w,
                                        height: 24.w,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              MyGaps.hGaps5w,
                              Expanded(
                                child: Text(
                                  "title_customerService".bhTR,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 7.sp,
                                    color: MyColor.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final chatItem = chatList[index - 1];
                      final userInfo = logic.userInfoMap[chatItem.targetId];
                      logic.uodateNameAndAvatar(chatItem.targetId);
                      return MessageListItem(
                        key: ValueKey(chatItem.targetId),
                        item: chatItem,
                        userInfoModel: userInfo,
                        onTap: () {
                          MessageChatPage.to(
                              userInfo ?? UserInfoModel(userId: chatItem.targetId));
                        },
                        onDelete: () async {
                          await RCConversationsManager()
                              .removeConversation(targetId: chatItem.targetId!);
                        },
                        onTop: () async {
                          await RCConversationsManager().changeTopStatus(
                              targetId: chatItem.targetId!,
                              top: !(chatItem.isTop ?? false),
                              isToast: true);
                        },
                      );
                    }
                  },
                ))
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
