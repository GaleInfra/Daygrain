import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import '../../res/my_color.dart';

/// create: 2023/4/23
/// desc: 渐变色按钮
class MyGradientButton extends StatelessWidget {
  const MyGradientButton({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.gradientColor,
    this.gradient,
    this.child,
    this.text,
    this.style,
    this.onTap,
    this.isAuto = true,
  }) : super(key: key);

  final bool isAuto;
  final double? width;

  final double? height;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 渐变颜色集
  final List<Color>? gradientColor;

  ///
  final Gradient? gradient;

  /// 子级widget
  final Widget? child;

  /// 子级文本内容
  final String? text;

  /// 子级文本样式
  final TextStyle? style;

  /// 点击
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    bool isRTL = BHLanguageMar().isRightToLeft.value;
    Gradient gradient = this.gradient ??
        LinearGradient(
            colors: gradientColor ??
                MyColor.btnGradientColors2,
          begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
          end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12.w),
        gradient: gradient,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: MyColor.transparent,
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          width: width ?? double.infinity,
          height: height ?? 24.w,
          alignment: Alignment.center,
          child: child ??
              (isAuto
                  ? AutoSizeText(
                text ?? "",
                maxLines: 1,
                textAlign: TextAlign.center,
                style: style ??
                    TextStyle(
                      color: MyColor.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                    ),
              )
                  : Text(
                text ?? "",
                textAlign: TextAlign.center,
                style: style ??
                    TextStyle(
                      color: MyColor.white,
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
              )),
        ),
      ),
    );
  }
}
