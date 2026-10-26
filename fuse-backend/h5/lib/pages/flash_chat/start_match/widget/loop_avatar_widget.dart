import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LoopAvatarWidget extends StatefulWidget {
  //头像列表
  final List<String> avatarList;
  //宽度
  final double? width;
  //高度
  final double? height;
  //时间间隔
  final int? interval;
  const LoopAvatarWidget({super.key, required this.avatarList, this.width, this.height, this.interval});

  @override
  State<LoopAvatarWidget> createState() => _LoopAvatarWidgetState();
}

class _LoopAvatarWidgetState extends State<LoopAvatarWidget> {
  
  //当前头像索引
  int currentIndex = 0;
  //定时器
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }
  //开启定时器
  void startTimer() {
    stopTimer();
    timer = Timer.periodic(Duration(seconds: widget.interval ?? 3), (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % widget.avatarList.length;
      });
    });
  }

  //停止定时器
  void stopTimer() {
    timer?.cancel();
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: VisibilityDetector(
        key: ValueKey(widget.avatarList.length),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: EdgeInsets.all(1.5.w),
          decoration:const BoxDecoration(
            color:  Color(0xFFB590CC),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Image.asset(
              widget.avatarList[currentIndex],
              key: ValueKey<String>(widget.avatarList[currentIndex]),
              fit: BoxFit.contain,
            ),
          ),
        ),
        onVisibilityChanged: (VisibilityInfo visibilityInfo) {
          if (visibilityInfo.visibleFraction == 0) {
            stopTimer();
          } else {
            startTimer();
          }
        },
      ),
    );
  }
}

