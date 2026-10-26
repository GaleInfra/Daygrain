import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/res/my_color.dart';

/// create: 2023/5/6
/// desc: 私聊-语音气泡
class ChatBubbleVoiceWidget extends StatefulWidget {
  const ChatBubbleVoiceWidget({
    Key? key,
    required this.item,
    required this.isSend,
  }) : super(key: key);

  final JSMessage item;

  JSVoiceMessageContent get content => item.content as JSVoiceMessageContent;

  /// 是否是自己
  final bool isSend;

  @override
  State<ChatBubbleVoiceWidget> createState() => _ChatBubbleVoiceWidgetState();
}

class _ChatBubbleVoiceWidgetState extends State<ChatBubbleVoiceWidget> {
  PlayerController? controller;
  StreamSubscription<PlayerState>? playerStateSubscription;
  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
    showSeekLine: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.content.remoteUrl == null) {
      controller = PlayerController();
      _preparePlayer();
      playerStateSubscription = controller?.onPlayerStateChanged.listen((e) {
        setState(() {});
      });
    }
  }

  void _preparePlayer() async {
    String? path = widget.content.localUrl?.replaceAll("file://", "");
    await controller?.preparePlayer(
      path: path!,
      shouldExtractWaveform: true,
      noOfSamples: 100,
      volume: 1.0,
    );
  }

  @override
  void dispose() {
    playerStateSubscription?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.remoteUrl != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        // child: VoiceMessage(
        //   audioSrc: widget.item.remote ?? "",
        //   contactBgColor: MyColor.white,
        //   meBgColor: MyColor.grey7B7B7B,
        //   contactPlayIconColor: MyColor.white,
        //   played: false,
        //   me: widget.isSend,
        // ),
      );
    }
    return Container(
      width: MediaQuery.of(context).size.width / 2,
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.w),
        gradient: LinearGradient(
          colors: widget.isSend ? [MyColor.grey7B7B7B, MyColor.grey6B6B6B] : [MyColor.white, MyColor.white],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              controller?.playerState.isPlaying ?? false ? await controller?.pausePlayer() : await controller?.startPlayer();
            },
            icon: Icon(
              controller?.playerState.isPlaying ?? false ? Icons.stop : Icons.play_arrow,
            ),
            color: Colors.white,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          AudioFileWaveforms(
            size: Size((MediaQuery.of(context).size.width / 3), 28.w),
            playerController: controller!,
            waveformType: WaveformType.long,
            playerWaveStyle: playerWaveStyle,
          ),
        ],
      ),
    );
  }
}
