import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/res/gift_image.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/socket_util.dart';
import 'package:untitled1/widget/keyboard_listener_widget.dart';

import '../../../../model/video_call/on_chat_model.dart';
import '../../../../res/image_assets.dart';
import '../../../../res/video_call_data.dart';
import '../../../../widget/dialog/gift_sheet.dart';
import '../../../../widget/dialog/recharge_dialog.dart';
import 'video_call_message_widget.dart';

/// create: 2023/5/9
/// desc: 视频聊天页文本输入框
class VideoCallInputWidget extends StatefulWidget {
  final BuildContext? context;

  const VideoCallInputWidget({Key? key, this.context}) : super(key: key);

  static GlobalKey<VideoCallInputWidgetState> myGlobalKey =
      GlobalKey<VideoCallInputWidgetState>();

  @override
  State<VideoCallInputWidget> createState() => VideoCallInputWidgetState();
}

class VideoCallInputWidgetState extends State<VideoCallInputWidget> {
  /// 显示表情包
  bool showEmoji = false;

  /// 输入框焦点
  final FocusNode _focusNode = FocusNode();

  /// 输入框控制器
  final TextEditingController _controller = TextEditingController();

  final logic = Get.find<VideoCallLogic>();

  final _handler = Get.find<VideoCallHandler>();
  final isShowKeyboard = false.obs;

  final GlobalKey<ExtendedTextFieldState> textFiledKey =
      GlobalKey<ExtendedTextFieldState>();

  @override
  void initState() {
    // if (BaseManager.instance.appInfo.sdkVersion.isEmpty) {
    //
    // } else {}
    // _focusNode.addListener(_onFocusListener);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showEmoji) {
          _onEmojiPress();
          return false;
        }
        return true;
      },
      child: KeyboardListenerWidget(
        onKeyboardChanged: (isShow, height) {
          // if (BaseManager.instance.appInfo.sdkVersion.isEmpty) {
          //   //旧版本不走这个逻辑
          //   return;
          // }
          if (isShow) {
            onCloseAll();
            //延迟50毫秒
            // Future.delayed(const Duration(milliseconds: 200), () {
            isShowKeyboard.value = true;
            // });
          } else {
            Future.delayed(const Duration(milliseconds: 200), () {
              isShowKeyboard.value = false;
            });
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if ((VideoCallInputWidget.myGlobalKey.currentState?.isShowKeyboard.value ?? false) || (VideoCallInputWidget.myGlobalKey.currentState?.showEmoji ?? false)) {
                          VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
                          return;
                        }
                        logic.isClearScreen.value = !logic.isClearScreen.value;
                        VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
                      },
                      child:const VideoCallMessageWidget(),
                    ),
                  ),
                  GetBuilder<VideoCallLogic>(
                    builder: (logic) {
                      return Visibility(
                        visible: !(logic.userInfo?.isFriend ?? false),
                        child: GestureDetector(
                          onTap: () => logic.onFollowOrUnFollow(),
                          child: Container(
                            width: 17.w,
                            height: 17.w,
                            margin: EdgeInsets.only(bottom: 25.w),
                            decoration: BoxDecoration(
                              color: MyColor.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10.w),
                            ),
                            child: Center(
                              child: Image.asset(
                                (logic.userInfo?.isFriend ?? false) ? ImageAssets.broadcasterLikes : ImageAssets.broadcasterUnLikes,
                                width: 11.w,
                                height: 10.w,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                     SizedBox(
                      width: 6.5.w,
                    ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 8.w,
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 20.w,
                        padding: BHLanguageMar().isRightToLeft.value ? EdgeInsets.only(right: 3.5.w) : EdgeInsets.only(left: 3.5.w),
                        decoration: BoxDecoration(
                          color: MyColor.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 10.0, // 阴影模糊半径
                              spreadRadius: 0.0, // 阴影扩散半径
                              offset: const Offset(2.0, 2.0), // 阴影偏移量
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _onEmojiPress,
                              child: Container(
                                // constraints: BoxConstraints(
                                //   maxWidth: 11.w,
                                // ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  ImageAssets.videoCallEmoticon,
                                  width: 11.w,
                                  height: 11.w,
                                ),
                              ),
                            ),
                            MyGaps.hGaps2w,
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: BHLanguageMar().isRightToLeft.value
                                        ? 0
                                        : 0.w),
                                child: TextField(
                                  key: textFiledKey,
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.multiline,
                                  enableSuggestions: true,
                                  enableInteractiveSelection: true,
                                  showCursor: true,
                                  style: TextStyle(
                                    color: MyColor.white,
                                    fontSize: 6.sp,
                                  ),
                                  cursorColor: MyColor.white,
                                  textInputAction: TextInputAction.send,
                                  decoration: InputDecoration(
                                    hintText: "placeholder_typeHere".bhTR,
                                    hintStyle: TextStyle(
                                      color: MyColor.white.withOpacity(.5),
                                      fontSize: 6.sp,
                                    ),
                                    contentPadding:
                                        BHLanguageMar().isRightToLeft.value
                                            ? EdgeInsets.symmetric(
                                                horizontal: 5.w, vertical: 0)
                                            : EdgeInsets.symmetric(
                                                horizontal: 5.w, vertical: 0),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10.w),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(10.w),
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    if (text.isNotEmpty) {
                                      onSend();
                                      FocusScope.of(context)
                                          .requestFocus(_focusNode);
                                    }
                                  },
                                ),
                              ),
                            ),
                            MyGaps.hGaps2w,
                            GestureDetector(
                              onTap: () {
                                onSend();
                                // FocusScope.of(context).requestFocus(_focusNode);
                              },
                              child: SizedBox(
                                height: 12.w,
                                width: 12.w,
                                child: Image.asset(
                                  ImageAssets.videoCallSendNew,
                                  width: 17.w,
                                  height: 17.w,
                                )
                              ),
                            ),
                            SizedBox(width: 2.5.w,)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 8.w,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (logic.userInfo != null) {
                          RechargeDialog.show(
                              entry: PayEntry.SOURCE_6, bindWidget: context);
                        }
                      },
                      child: Image.asset(
                        ImageAssets.videoCallIcStore,
                        width: 17.w,
                        height: 17.w,
                      ),
                    ),
                    SizedBox(
                      width: 8.w,
                    ),
                   
                    GestureDetector(
                      onTap: () {
                        if (logic.userInfo != null) {
                          VideoCallInputWidget.myGlobalKey.currentState
                              ?.onCloseAll(unFocus: true);

                          GiftSheet.show(
                            list: GiftManager.to.giftList,
                            channelName:
                            _handler.onCallModel?.channelName ?? "",
                            userInfo: logic.userInfo!,
                            bindWidget: widget.context,
                          );
                        }
                      },
                      child: Image.asset(
                        ImageAssets.gift,
                        width: 17.w,
                        height: 17.w,
                      ),
                    ),
                    SizedBox(
                      width: 8.w,
                    )
                  ],
                ),
              ),
              Visibility(
                visible: showEmoji,
                child: SizedBox(
                  height: 100.w,
                  child: EmojiPicker(
                    // textEditingController: _controller,
                    config: const Config(recentTabBehavior: RecentTabBehavior.NONE
                        // initCategory: Category.SMILEYS,
                        // bgColor: MyColor.grey0B0B0B.withOpacity(.5),

                        ),
                    onEmojiSelected: (Category? category, Emoji emoji) {
                      insertText(emoji.emoji);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 展开/关闭表情
  void _onEmojiPress() {
    _focusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        showEmoji = !showEmoji;
      });
    });
  }

  /// 关闭所有
  void onCloseAll({bool unFocus = false}) {
    if (unFocus) _focusNode.unfocus();
    setState(() {
      showEmoji = false;
    });
  }

  /// 发送消息
  Future onSend() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    OnChatModel data = OnChatModel(
      fromUserId: logic.userId,
      toUserId: logic.getAnchorId(),
      content: _controller.text,
      timestamp: timestamp,
      command: SocketCommandKey.onChat,
    );
    SocketUtil().emit(event: "messageEvent", data: data.toJson());
    logic.onSendMessage(model: data);
    _controller.clear();
  }

  void insertText(String text) {
    final TextEditingValue value = _controller.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      _controller.value = value.copyWith(
        text: newText,
        selection: value.selection.copyWith(
            baseOffset: end + text.length, extentOffset: end + text.length),
      );
    } else {
      _controller.value = TextEditingValue(
        text: text,
        selection:
            TextSelection.fromPosition(TextPosition(offset: text.length)),
      );
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      textFiledKey.currentState?.bringIntoView(_controller.selection.base);
    });
  }
}
