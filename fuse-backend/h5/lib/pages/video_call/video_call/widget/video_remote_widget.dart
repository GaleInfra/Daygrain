import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import '../logic.dart';

/// create: 2023/5/10
/// desc: 视频通话 - 全屏显示
class VideoRemoteWidget extends StatefulWidget {
  const VideoRemoteWidget({Key? key}) : super(key: key);

  @override
  State<VideoRemoteWidget> createState() => _VideoRemoteWidgetState();
}

class _VideoRemoteWidgetState extends State<VideoRemoteWidget> {  

  late html.IFrameElement _iframe;

  
  @override
  void initState() {
    super.initState();

    _iframe = html.IFrameElement()
        ..id = 'remoteVideoFrame'
        ..src = 'video.html' // 指向你的 HTML 文件
        ..style.border = 'none'
        ..width = '100%' // 设置宽度
        ..height = '100%' // 设置高度
        ..style.pointerEvents = 'none'; //拦截点击事件


    ui.platformViewRegistry.registerViewFactory("RemoteVideoiframeElement", (int viewId) {
      return _iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoCallLogic>(
      builder: (logic) {
        
        return const HtmlElementView(
          viewType: 'RemoteVideoiframeElement',
        );
      },
    );
  }
}
