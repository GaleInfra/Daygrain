import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// create: 2023/4/26
/// desc: 自定义播放进度条
class MyVideoProgressBar extends StatelessWidget {
  MyVideoProgressBar(
      this.controller, {
        this.height = kToolbarHeight,
        ChewieProgressColors? colors,
        this.onDragEnd,
        this.onDragStart,
        this.onDragUpdate,
        Key? key,
      })  : colors = colors ?? ChewieProgressColors(),
        super(key: key);

  final double height;
  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: 2,
      handleHeight: 2,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
    );
  }
}