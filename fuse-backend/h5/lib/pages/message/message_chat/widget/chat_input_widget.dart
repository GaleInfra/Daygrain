import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/utils/web_anchored_image_picker.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/im_limit_event.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/js_utils.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/widget/keyboard_listener_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../rong_cloud/rc_message_manager.dart';
import '../../../../utils/bh_platform.dart';
import '../logic.dart';
import 'chat_voice_widget.dart';
import 'dart:html' as html;

/// create: 2023/4/28
/// desc: 私聊页 - 底部输入组件
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    Key? key,
    required this.targetId,
  }) : super(key: key);

  /// 会话 ID
  final String targetId;

  @override
  State<ChatInputWidget> createState() => ChatInputWidgetState();
}

class ChatInputWidgetState extends State<ChatInputWidget> {
  String hintText = "placeholder_typeHere".bhTR;

  /// 展示更多
  bool _showMore = false;

  /// 显示发送按钮
  bool _showSend = false;

  /// 显示表情包
  bool _showEmoji = false;

  //是否显示键盘
  bool _showKeyboard = false;

  /// 显示录制语音
  bool _showVoice = false;

  /// 更多按钮旋转角度
  double _rotationAngle = 0;

  /// 是否已经聊过
  bool containsIM = false;

  /// 是否是系统账号
  bool isSystem = false;

  /// 输入框控制器
  final TextEditingController _controller = TextEditingController();

  final appConfig = Get.find<AppConfigManager>();

  final ScrollController scrollController = ScrollController();

  // late StreamSubscription<bool> _keyboardSubscription;

  late StreamSubscription<IMLimitEvent> _imLimitEvent;

  late StreamSubscription<OtherEvent> _otherEvent;

  final GlobalKey<ExtendedTextFieldState> textFiledKey = GlobalKey<ExtendedTextFieldState>();

  late MessageChatLogic logic;

  @override
  void initState() {
    logic = Get.find<MessageChatLogic>(tag: widget.targetId);
    isSystem = appConfig.systemList.contains(widget.targetId);
    _controller.addListener(_onInputListener);
    // var keyboardVisibilityController = KeyboardVisibilityController();
    onUpdateHint();
    // Subscribe
    // _keyboardSubscription = keyboardVisibilityController.onChange.listen((bool visible) {
    //   if (visible) {
    //     onCloseAll();
    //   }
    // });
    _imLimitEvent = EventBusUtil.listen<IMLimitEvent>((event) {
      onUpdateHint();
    });
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.strategyUpdate == event.type || OtherType.userInfoUpdate == event.type) {
        onUpdateHint();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF26203A),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(left: 9.w, right: 9.w, top: 6.w),
                child: Row(
                  children: [
                    Visibility(
                      visible: false,
                      child: GestureDetector(
                        onTap: _onShowVoice,
                        child: Image.asset(
                          ImageAssets.chatVoice,
                          width: 11.w,
                          height: 11.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: false  ,
                      child: MyGaps.hGaps5w),
                    Visibility(
                      visible: false,
                      child: Expanded(
                        child: ChatVoiceWidget(
                          onVoiceBack: _onSendVoiceMessage,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C192C),
                                  borderRadius: BorderRadius.circular(20.w),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        key: textFiledKey,
                                        controller: _controller,
                                        scrollController: scrollController,
                                        enableSuggestions: true,
                                        enableInteractiveSelection: true,
                                        maxLines: 1,
                                        textInputAction: TextInputAction.send,
                                        showCursor: true,
                                        focusNode: logic.focusNode,
                                        cursorColor: Colors.white,
                                        // autocorrect: false,
                                        style: TextStyle(
                                          fontSize: 7.sp,
                                          color: MyColor.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: hintText,
                                          hintStyle: TextStyle(
                                            fontSize: 7.sp,
                                            // color: isLimit ? Color(0xFFFFFF7F) : const Color(0xFF7C7C7C),
                                            color: const Color(0xFF7C7C7C),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w),
                                          enabledBorder: const OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onTap: () {
                                          closeMoreAndEmoji();
                                        },
                                        onSubmitted: (value) {
                                          _onSendTextMessage();
                                          FocusScope.of(context).requestFocus(logic.focusNode);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            MyGaps.hGaps5w,
                            GestureDetector(
                              onTap: _onEmojiPress,
                              child: Image.asset(
                                ImageAssets.chatEmoticon,
                                width: 11.w,
                                height: 11.w,
                              ),
                            ),
                            MyGaps.hGaps7w,
                            Visibility(
                              visible: !_showSend,
                              child: GestureDetector(
                                onTap: _onMorePress,
                                child: Image.asset(
                                  ImageAssets.chatMore2,
                                  width: 11.w,
                                  height: 11.w,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: _showSend,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque, // 防止事件穿透
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular((8 + 9).w),
                                    gradient: const LinearGradient(
                                      colors: MyColor.btnGradientColors,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                                        child: Image.asset(
                                          ImageAssets.messageSend,
                                          width: 9.w,
                                          height: 9.w,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 1.w,
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  _onSendTextMessage();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _showMore,
                child: Container(
                  height: 50.w,
                  padding: EdgeInsets.only(left: 9.w, right: 9.w, top: 9.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MoreItem(
                        pic: ImageAssets.chatPicture,
                        name: "label_picture".bhTR,
                        onTap: _onPicSelect,
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _showEmoji,
                child: SizedBox(
                  height: 140.w,
                  child: EmojiPicker(
                    // textEditingController: _controller,
                    config: const Config(
                      recentTabBehavior: RecentTabBehavior.NONE,
                      bgColor: Color(0xFF32312F),
                    ),
                    onEmojiSelected: (Category? category, Emoji emoji) {
                      insertText(emoji.emoji);
                    },
                  ),
                ),
              ),
              KeyboardListenerWidget(
                onKeyboardChanged: (isShow, height) {
                  if (_showKeyboard != isShow && isShow == false) {
                    logic.focusNode.unfocus();
                  }
                  _showKeyboard = isShow;
                  setState(() {});
                },
                child: Container(
                  height: !_showKeyboard && (!_showEmoji && !_showMore && DeviceUtil().bottomSafe > 0) ? DeviceUtil().bottomSafe : 10.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isLimit = true;
  // 更新文本框提示文案和颜色
  void onUpdateHint() {
    if (!BHPlatform.isAndroid) {
      return;
    }
    // 是否已聊过
    containsIM = appConfig.strategyModel?.imSessionBroadcasterIds?.contains(widget.targetId) ?? false;
    // 已聊过 || 未开启IM限制
    if (!appConfig.switchImLimit || containsIM || isSystem) {
      hintText = "placeholder_typeHere".bhTR;
      isLimit = false;
    } else {
      isLimit = true;
      hintText = "label_you_have_free_chats".bhTR.replaceAll("###", "${appConfig.strategyModel?.imSessionBalance ?? 0}");
    }
    logic.updateLimitIM(appConfig.switchImLimit && appConfig.meetImLimit && !containsIM && !isSystem);
    if (mounted) {
      setState(() {});
    }
  }

  // final FocusNode _focusNode = FocusNode();

  /// 对外暴露关闭所有
  void onCloseAll({isUnFocus = false}) {
    setState(() {
      if (isUnFocus) logic.focusNode.unfocus();
      _showMore = false;
      _showEmoji = false;
      _rotationAngle = 0;
    });
  }

  void closeMoreAndEmoji() {
    setState(() {
      _showMore = false;
      _showEmoji = false;
    });
  }

  /// 显示/关闭语音录入
  void _onShowVoice() {
    _showVoice = !_showVoice;
    onCloseAll();
  }

  /// 展开/关闭表情
  void _onEmojiPress() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showEmoji = !_showEmoji;
        _showMore = false;
        _rotationAngle = 0;
      });
    });
  }

  /// 展开/关闭更多
  void _onMorePress() {
    setState(() {
      _showMore = !_showMore;
      _showEmoji = false;
      if (_showMore) {
        _rotationAngle += 45;
      } else {
        _rotationAngle -= 45;
      }
    });
  }

  /// 输入监听
  void _onInputListener() {
    if (_controller.text.trim().isNotEmpty && !_showSend) {
      setState(() {
        _showSend = true;
      });
    } else if (_controller.text.isEmpty && _showSend) {
      setState(() {
        _showSend = false;
      });
    }
  }

  /// 图片选择及发送
  Future _onPicSelect() async {
    if (BHPlatform.isWeb) {
      // web
      // Pick an image.
      html.File? image;
      if (BaseManager.instance.appInfo.sdkVersion.isNotEmpty) {
            
        final completer = Completer<Uint8List?>();

        JSRongCloudManager.selectImage(BHCallbackWeb(onSuccess: (u) async {
          if (u is String) {
            if (u.isNotEmpty) {
              Uint8List imageBytes = base64Decode(u);

              completer.complete(imageBytes);
              return;
            }
          }
          completer.complete(null);
        }, onError: (data) {
          completer.complete(null);
        }).toJS());

        Uint8List? bytesMaxList = await completer.future;
        image =  html.File([bytesMaxList!],const Uuid().v1(), {'type': 'image/png'});
      }else{
        image = await WebAnchoredImagePicker.getImageAsFile();
      }
      

      if (image != null) {
        onCloseAll();
        RCMessageManager().sendPicMessageWeb(
          message: null,
          targetId: widget.targetId,
          file: image,
          sendId: appConfig.userInfo.userId ?? "",
          nickname: appConfig.userInfo.nickname ?? "",
          avatar: appConfig.userInfo.avatarUrl ?? "",
        );
      }
    } else {
      bool permissionResult = await requestPhoto();
      if (!permissionResult) {
        return;
      }
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        Get.context!,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
          themeColor: MyColor.themeColor1E2440,
        ),
      );
      if (result != null) {
        onCloseAll();
        File? file = await result.first.file;
        RCMessageManager().sendPicMessage(
          message: null,
          targetId: widget.targetId,
          path: file!.path,
          sendId: appConfig.userInfo.userId ?? "",
          nickname: appConfig.userInfo.nickname ?? "",
          avatar: appConfig.userInfo.avatarUrl ?? "",
        );
      }
    }
  }

  /// 发送文本消息
  Future _onSendTextMessage() async {
    if (_controller.text.trim().isEmpty) {
      _controller.clear();
      return;
    }
    RCMessageManager().sendTextMessage(
      message: null,
      targetId: widget.targetId,
      sendId: appConfig.userInfo.userId ?? "",
      nickname: appConfig.userInfo.nickname ?? "",
      avatar: appConfig.userInfo.avatarUrl ?? "",
      text: _controller.text,
    );
    _controller.clear();
    // FocusScope.of(context).requestFocus(_focusNode);
  }

  /// 发送语音消息
  Future _onSendVoiceMessage(String path, int duration) async {
    RCMessageManager().sendVoiceMessage(
      message: null,
      targetId: widget.targetId,
      path: path,
      duration: duration,
      sendId: appConfig.userInfo.userId ?? "",
      nickname: appConfig.userInfo.nickname ?? "",
      avatar: appConfig.userInfo.avatarUrl ?? "",
    );
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
        selection: value.selection.copyWith(baseOffset: end + text.length, extentOffset: end + text.length),
      );
    } else {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.fromPosition(TextPosition(offset: text.length)),
      );
    }
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      textFiledKey.currentState?.bringIntoView(_controller.selection.base);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputListener);
    _controller.dispose();
    // _keyboardSubscription.cancel();
    _imLimitEvent.cancel();
    _otherEvent.cancel();
    super.dispose();
  }
}

/// 更多的item
class _MoreItem extends StatelessWidget {
  const _MoreItem({
    Key? key,
    required this.pic,
    required this.name,
    this.onTap,
  }) : super(key: key);

  final String pic;

  final String name;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22.5.w,
        height: 21.w,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6.w), color: const Color(0xFF464543)),
        child: Center(
          child: Image.asset(
            pic,
            width: 11.w,
            height: 11.w,
            color: MyColor.white,
          ),
        ),
      ),
    );
  }
}
