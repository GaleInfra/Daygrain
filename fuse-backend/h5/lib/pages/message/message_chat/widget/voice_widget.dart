import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/message/message_chat/logic.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/throttle_util.dart';

import '../../../../base_manager.dart';
import '../../../../res/my_color.dart';
import 'dart:math' as math;

/// 自定义语音播放条
class VoiceWidget extends StatefulWidget {
  const VoiceWidget({
    super.key,
    required this.logic,
    required this.message,
    required this.isSend,
  });

  final MessageChatLogic logic;

  final JSMessage message;

  final bool isSend;

  @override
  State<StatefulWidget> createState() => VoiceWidgetState();
}

class VoiceWidgetState extends State<VoiceWidget> with SingleTickerProviderStateMixin {
  /// 图片资源
  final List<String> _assetList = [
    "${BaseManager.instance.assetsPrefix}assets/images/voice/left_voice_1.webp",
    "${BaseManager.instance.assetsPrefix}assets/images/voice/left_voice_2.webp",
    "${BaseManager.instance.assetsPrefix}assets/images/voice/left_voice_3.webp",
  ];

  // 动画控制
  late Animation<double> _animation;
  late AnimationController _controller;
  bool playing = false;
  late Worker worker;

  @override
  void initState() {
    super.initState();

    final int imageCount = _assetList.length;

    // 监听每次播放索引
    worker = ever(widget.logic.playVoiceIndex, (callback) {
      if (callback == -1) {
        stopAni();
      } else if (widget.logic.list[callback].message.messageUId == widget.message.messageUId && widget.logic.list[callback].message.messageId == widget.message.messageId) {
        // 如果是当前数据，则启动动画
        startAni();
      } else {
        stopAni();
      }
    });

    // 启动动画controller
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.forward(from: 0.0); // 完成后重新开始
      }
    });

    _animation = Tween<double>(begin: 0, end: imageCount.toDouble()).animate(_controller)
      ..addListener(
        () {
          setState(() {});
        },
      );

    int index = widget.logic.playVoiceIndex.value;
    if (index != -1 && widget.logic.list[index].message.messageUId == widget.message.messageUId) {
      // 初始化播放状态，因为列表滑动过程中，会销毁此widget
      startAni();
    }
  }

  @override
  void dispose() {
    worker.dispose();
    _controller.dispose();
    super.dispose();
  }

  startAni() {
    playing = true;
    _controller.forward();
    setState(() {});
  }

  stopAni() {
    playing = false;
    _controller.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var isShowRed = false;
    String isRed = SPUtil.getString(widget.message.messageId != null ? widget.message.messageId.toString() : "");
    if (isRed.isNotEmpty) {
      isShowRed = true;
    }

    num index = _animation.value.floor() % _assetList.length;
    List<Widget> images = [];
    // 把所有图片都加载进内容，否则每一帧加载时会卡顿
    for (int i = 0; i < _assetList.length; ++i) {
      if (i != index) {
        images.add(Image.asset(
          _assetList[i],
          width: 0,
          height: 0,
        ));
      }
    }
    images.add(Image.asset(
      _assetList[index.toInt()],
      width: 15.w,
      height: 15.w,
      fit: BoxFit.cover,
      color: widget.isSend ? MyColor.black : MyColor.white,
    ));
    //旋转角度
    double rotationY = widget.message.messageDirection == 1 ? math.pi : 0;
    if (BHLanguageMar().isRightToLeft.value) {
      if (rotationY == 0) {
        rotationY = math.pi;
      } else {
        rotationY = 0;
      }
    }
    JSVoiceMessageContent voice = widget.message.content as JSVoiceMessageContent;

    return GestureDetector(
      onTap: () {
        throttleUtil.throttle(
          () async {
            SPUtil.remove(widget.message.messageId != null ? widget.message.messageId.toString() : "");
            if (playing) {
              widget.logic.stopVoice();
            } else {
              widget.logic.playVoice(
                  widget.logic.list.indexWhere((element) => element.message.messageUId == widget.message.messageUId && element.message.messageId == widget.message.messageId));
            }
          },
          key: "voice.play",
          time: 500,
        );
      },
      child: Row(
        mainAxisAlignment: !widget.isSend ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            padding: EdgeInsets.symmetric(vertical: 5.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9.w),
              color: widget.isSend ? null : MyColor.otherMessageBGColor,
              gradient: widget.isSend ? const LinearGradient(colors: MyColor.myMessageBGColors):null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: !playing && widget.message.messageDirection == 2,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(rotationY),
                    child: Image.asset(
                      "${BaseManager.instance.assetsPrefix}assets/images/voice/left_voice_3.webp",
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      color: widget.isSend ? MyColor.textBlack : MyColor.white,
                    ),
                  ),
                ),
                Visibility(
                  visible: playing && widget.message.messageDirection == 2,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(rotationY),
                    child: Stack(alignment: AlignmentDirectional.center, children: images),
                  ),
                ),
                MyGaps.hGaps5w,
                Text(
                  "${voice.duration?.toInt() ?? 0}\"", //DateTimeUtil.formatVoiceDuration(Duration(seconds: widget.message.duration ?? 0)),
                  style: TextStyle(
                    color: widget.isSend ? MyColor.black : MyColor.white,
                    fontSize: 8.sp,
                  ),
                ),
                MyGaps.hGaps5w,
                Visibility(
                  visible: !playing && widget.message.messageDirection == 1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(rotationY),
                    child: Image.asset(
                      "${BaseManager.instance.assetsPrefix}assets/images/voice/left_voice_3.webp",
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      color: widget.isSend ? MyColor.black : MyColor.white,
                    ),
                  ),
                ),
                Visibility(
                  visible: playing && widget.message.messageDirection == 1,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(rotationY),
                    child: Stack(alignment: AlignmentDirectional.center, children: images),
                  ),
                ),
              ],
            ),
          ),
          if (!widget.isSend && isShowRed)
            Container(
              margin: EdgeInsets.only(left: 5.w),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            )
        ],
      ),
    );
  }
}
