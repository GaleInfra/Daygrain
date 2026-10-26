import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/my_color.dart';
import '../../res/my_gaps.dart';

class PulsatingButton extends StatefulWidget {
  //宽
  final double? width;
  //高
  final double? height;
  //文案
  final String? text;
  //文案样式
  final TextStyle? textStyle;
  //渐变色
  final Gradient? gradient;
  //圆角
  final double? borderRadius;

  const PulsatingButton({
    Key? key,
    this.width,
    this.height,
    this.text,
    this.textStyle,
    this.gradient,
    this.borderRadius,
  }) : super(key: key);
  @override
  _PulsatingButtonState createState() => _PulsatingButtonState();
}

class _PulsatingButtonState extends State<PulsatingButton>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
         width: widget.width,
          height: widget.height,
      padding:  EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 9.w),
        color:const Color(0xFF5F86F9).withValues(alpha: 0.2),
      ),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 9.w),
          color:const Color(0xFF5F86F9).withValues(alpha: 0.2),
        ),
        child: Container(
       
          // padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 9.w),
            gradient: widget.gradient ??
                const LinearGradient(
                  colors: MyColor.btnGradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          ),
          child: Center(
            child: Text(
              widget.text ?? "",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: widget.textStyle ??
                  TextStyle(
                    color: MyColor.white,
                    fontSize: 7.sp,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

//单独封装 ScaleTransition

class ScaleTransitionWidget extends StatefulWidget {
  final Widget child;
  //是否开启
  final bool isAnimate;
  const ScaleTransitionWidget({
    Key? key,
    required this.child,
    this.isAnimate = true,
  }) : super(key: key);
  @override
  _ScaleTransitionWidgetState createState() => _ScaleTransitionWidgetState();
}

class _ScaleTransitionWidgetState extends State<ScaleTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isAnimate
        ? ScaleTransition(
            scale: _animation,
            child: widget.child,
          )
        : widget.child;
  }
}
