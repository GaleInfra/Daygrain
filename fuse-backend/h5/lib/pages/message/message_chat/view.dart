import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/message/message_chat/widget/chat_bubble_widget.dart';
import 'package:untitled1/pages/message/message_chat/widget/chat_input_widget.dart';
import 'package:untitled1/pages/message/message_chat/widget/chat_more_menu_widget.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/online_status_util.dart';
import 'package:untitled1/widget/animated_background.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/dialog/block_report_sheet.dart';
import 'package:untitled1/widget/dialog/gift_sheet.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';

import '../../../config/route_observer.dart';
import '../../../model/message/rc_message_model.dart';
import '../../../res/my_color.dart';
import '../../../res/my_gaps.dart';
import '../../../res/pay_entry.dart';
import '../../../widget/button/pulsating_button.dart';
import '../../../widget/dialog/message_menu.dart';
import 'logic.dart';

/// 私聊页
class MessageChatPage extends StatefulWidget {
  const MessageChatPage({Key? key}) : super(key: key);

  static void to(UserInfoModel userInfo) {
    List<Route<dynamic>> allRoutes = routeObserver.routes;

    for (Route route in allRoutes) {
      if (route.settings.name == RoutePath.messageChatPage) {
        if (route == allRoutes.first) {
          Get.back();
        } else {
          Get.removeRoute(route);
        }

        //延迟500毫秒用于释放Controller
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.toNamed(RoutePath.messageChatPage,
              arguments: {
                "userInfo": userInfo,
              },
              preventDuplicates: false);
        });
        return;
      }
    }
    Get.toNamed(RoutePath.messageChatPage,
        arguments: {
          "userInfo": userInfo,
        },
        preventDuplicates: false);
  }

  @override
  State<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends State<MessageChatPage> with RouteAware {
  late final MessageChatLogic logic;

  String userId = "";
  UserInfoModel model = UserInfoModel();

  GlobalKey<ChatInputWidgetState> inputGlobalKey = GlobalKey<ChatInputWidgetState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // TODO: implement didPopNext
    super.didPopNext();
  }

  @override
  void didPushNext() {
    //关闭键盘
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPushNext();
  }

  @override
  void initState() {
    if (Get.arguments != null) {
      Map map = Get.arguments;
      if (map.containsKey("userInfo")) {
        model = map['userInfo'];
        userId = model.userId ?? "";
        logic = Get.put(MessageChatLogic(), tag: userId)..initData(model);
      }
    }
  }

  bool get isAndroidWeb {
    return (kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColor.appBackground,
      child: GetBuilder<MessageChatLogic>(
        tag: userId,
        builder: (logic) {
          return Stack(
            children: [
              // Positioned.fill(child: Visibility(
              //   visible: !logic.systemAccount.value
              //   ,child: AnimatedBackground(userId: userId))),
               

              Scaffold(
                resizeToAvoidBottomInset: isAndroidWeb ? false : true,
                backgroundColor: MyColor.transparent,
                appBar: DefaultAppBar(
                  title: (logic.userInfo?.nickname ?? "").fixAutoLines(),
                  centerTitle: false, // 设置为false使标题靠左对齐
                  action: [
                    Obx(() {
                      return Visibility(
                        visible: !logic.systemAccount.value && !logic.isLockChat(),
                        child: GestureDetector(
                          onTap: () {
                            inputGlobalKey.currentState?.onCloseAll();
                            logic.onCall();
                          },
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            color: Colors.transparent,
                            child: Opacity(
                              opacity: logic.onlineStatus.value == OnlineStatusUtil.online ? 1 : 0.15,
                              child: Image.asset(
                                ImageAssets.messageVideoCall,
                                width: 14.w,
                                height: 14.w,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Obx(() {
                      return Visibility(
                        visible: !logic.systemAccount.value,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 4.w,
                            ),
                            GestureDetector(
                              onTap: () {
                                inputGlobalKey.currentState?.onCloseAll();
                                BlockReportSheet.show(
                                  bindWidget: context,
                                  toUserId: logic.userId,
                                  isBlock: logic.userInfo?.isBlock ?? false,
                                  isFollow: logic.userInfo?.isFriend ?? false,
                                  isShowTop: true,
                                  isTop: logic.isTop.value,
                                  onTopOrUnTop: (result) {
                                    logic.onTop();
                                  },
                                  onFollowOrUnBack: (result) => logic.onFollowOrUnBack(result),
                                  onBlockOrUnBack: (result) => logic.onBlockOrUnBack(result),
                                );
                              },
                              child: Image.asset(
                                ImageAssets.chatMore,
                                width: 10.w,
                                height: 10.w,
                              ),
                            ),
                            SizedBox(
                              width: 9.w,
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                bottomNavigationBar: Obx(() {
                  return logic.deleteMore.value
                      ? ChatMoreMenuWidget(logic: logic)
                      : ChatInputWidget(
                          key: inputGlobalKey,
                          targetId: logic.userId,
                        );
                }),
                body: GestureDetector(
                  onTap: () {
                    inputGlobalKey.currentState?.onCloseAll();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        _ListWidget(
                            logic: logic,
                            onTapPress: () {
                              inputGlobalKey.currentState?.onCloseAll();
                            }),
                        Positioned(
                          right: BHLanguageMar().isRightToLeft.value ? null : 10.w,
                          left: BHLanguageMar().isRightToLeft.value ? 10.w : null,
                          bottom: 9.w,
                          child: Obx(() {
                            return Visibility(
                              visible: !logic.systemAccount.value && !logic.isLockChat(),
                              child: GestureDetector(
                                onTap: () {
                                  // if (logic.limitIM.value) {
                                  //   RechargeDialog.show(
                                  //       entry: PayEntry.SOURCE_31,
                                  //       bindWidget: context);
                                  // } else {
                                  inputGlobalKey.currentState?.onCloseAll();
                                  GiftSheet.show(
                                    bindWidget: context,
                                    list: GiftManager.to.giftList,
                                    channelName: "",
                                    userInfo: logic.userInfo!,
                                  );
                                  // }
                                },
                                child: Image.asset(
                                  ImageAssets.gift,
                                  width: 24.w,
                                  height: 24.w,
                                ),
                              ),
                            );
                          }),
                        ),
                        Obx(() {
                          return Visibility(
                            visible: logic.showGiveGift.value,
                            child: RepaintBoundary(
                              child: logic.giftWidget,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              Obx(() {
                if (logic.limitIM.value) {
                  // 限制聊天
                }
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Visibility(
                      visible: logic.isLockChat(),
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          height: Get.height * 0.5,
                          // color: const Color(0xFF1C1F2C).withOpacity(0.95),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1C1F2C).withOpacity(0.0),
                              const Color(0xFF1C1F2C).withOpacity(0.0),
                              const Color(0xFF1C1F2C).withOpacity(1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )),
                        ),
                      )),
                );
              }),
              Obx(() {
                if (logic.limitIM.value) {
                  // 限制聊天
                }
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 11.w,
                  child: Visibility(
                      visible: logic.isLockChat(),
                      child: Container(
                        width: Get.width,
                        color: Colors.transparent,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: GestureDetector(
                            onTap: () =>  VipPrivilegesSheet.show(),
                            child: SizedBox(
                              width: Get.width,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Positioned(
                                  //   bottom: 0,
                                  //   left: 0,
                                  //   right: 0,
                                  //   child: Container(
                                  //   width: Get.width,
                                  //   height: 40.w + DeviceUtil().bottomSafe,
                                  //   color:const Color(0xFF1A2231).withValues(alpha: 0.5),
                                  // )),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Image.asset(
                                        ImageAssets.messageLock,
                                        width: 32.w,
                                        height: 32.w,
                                      ),
                                      SizedBox(height: 6.w),
                                      PulsatingButton(
                                        text: "Reply and ask for contact details".bhTR,
                                        width: 150.w,
                                        height: 28.w,
                                        borderRadius: 15.w,
                                      ),
                                      SizedBox(height: 5.w),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                );
              }),
              Obx(() {
                if (logic.questionMessageObs.value == null) {
                  return const SizedBox();
                }
                JSSingleJsonMsgMessageContent content = logic.questionMessageObs.value?.message.content as JSSingleJsonMsgMessageContent;
                QuestionData? questionData = content.questionData;
                return Positioned(
                  bottom: 80.w,
                  left: BHLanguageMar().isRightToLeft.value ? null : 6.w,
                  right: BHLanguageMar().isRightToLeft.value ? 6.w : null,
                  child: SizedBox(
                    width: 119.w,
                    child: Visibility(
                      visible: questionData != null,
                      child: Column(
                        children: [
                          //标题 顶部圆角 左右渐变
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            height: 24.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4.5.w),
                                topRight: Radius.circular(4.5.w),
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7B31B6),
                                  Color(0xFF6C6AFA),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  ImageAssets.messageQuestionMsg,
                                  width: 11.w,
                                  height: 11.w,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  "Quick reply".bhTR,
                                  style: TextStyle(color: Colors.white, fontSize: 8.sp,fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 9.w, bottom: 5.w),
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(4.5.w),
                                bottomRight: Radius.circular(4.5.w),
                              ),
                              color: const Color(0xFF393065),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  questionData?.content ?? "",
                                  style: TextStyle(color: const Color(0xFFCCCCCC), fontSize: 7.sp,fontWeight: FontWeight.w600),
                                ),
                                MyGaps.vGaps5w,
                                //数组 显示 questionData.replies 的item ,每个Item 渐变圆形边框 边框 1.w 宽度 ，中间显示 白色字体 居中显示
                                for (var index = 0; index < (questionData?.replies?.length ?? 0); index++)
                                  GestureDetector(
                                    onTap: () {
                                      logic.onSendMessage(questionData?.replies?[index] ?? "");
                                    },
                                    child: Container(
                                      height: 19.w,
                                      padding: EdgeInsets.all(1.w),
                                      margin: EdgeInsets.only(bottom: 4.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12.w),
                                        gradient:  LinearGradient(
                                          colors: index == 0 ? [
                                            Color(0xFFA73AFF),
                                            Color(0xFF06F9D5),
                                          ] : [
                                            MyColor.white,
                                            MyColor.white,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12.w),
                                          color: const Color(0xFF393065),
                                        ),
                                        child: Center(
                                          child: Text(
                                            questionData?.replies?[index] ?? "",
                                            style: TextStyle(color: Colors.white, fontSize: 7.sp, fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(width: 27.w),
                              Transform.scale(
                                scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                                child: Image.asset(
                                  ImageAssets.messageQuestionTriangle,
                                  width: 15.w,
                                  height: 9.w,
                                  fit: BoxFit.fill,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              })
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    Get.delete<MessageChatLogic>(tag: userId);
    routeObserver.unsubscribe(this);
  }
}

class _ListWidget extends StatelessWidget {
  const _ListWidget({
    Key? key,
    required this.logic,
    required this.onTapPress,
  }) : super(key: key);

  final VoidCallback? onTapPress;
  final MessageChatLogic logic;

  @override
  Widget build(BuildContext context) {
    List<RCMessageModel> list = List.from(logic.list);
    return Align(
      alignment: Alignment.topCenter,
      child: ListViewObserver(
        controller: logic.observerController,
        child: NotificationListener(
          onNotification: (ScrollNotification notification) {
            if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 30) {
              EasyThrottle.throttle("message_logic.onLoadMore", const Duration(milliseconds: 200), () {
                // 滑动到尾部，加载数据
                logic.onLoadMore();
              });
            }
            return true;
          },
          child: ListView.separated(
            controller: logic.scrollController,
            padding: EdgeInsets.symmetric(vertical: 9.w),
            reverse: true,
            shrinkWrap: true,
            itemCount: list.length,
            separatorBuilder: (ctx, index) => MyGaps.vGaps10w,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (ctx, index) {
              return ChatBubbleWidget(
                key: ValueKey(list[index].message.messageUId),
                model: logic.userInfo,
                receivedAvatar: logic.userInfo?.avatarThumbUrl ?? "",
                sendAvatar: logic.avatar,
                item: list[index],
                previousTime: index == list.length - 1 ? -1 : list[index + 1].message.sentTime!,
                onTrans: () => logic.onTrans(list[index]),
                onTapPress: () {
                  if (onTapPress != null) {
                    onTapPress?.call();
                  }
                },
                onLongPress: () => MessageMenu.show(message: logic.list[index].message, logic: logic, bindWidget: context),
                deleteList: logic.deleteList,
                logic: logic,
              );
            },
          ),
        ),
      ),
    );
  }
}
