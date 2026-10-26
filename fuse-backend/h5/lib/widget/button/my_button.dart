import 'package:flutter/material.dart';

/// create: 2023/4/23
/// desc: 自定义按钮
class MyButton extends StatelessWidget {
  const MyButton({
    Key? key,
    this.width,
    this.height,
    this.child,
    this.text,
    this.textStyle,
    this.disableTextStyle,
    this.background,
    this.disableColor,
    this.elevation = 0,
    this.borderRadius,
    this.alignment,
    this.margin,
    this.padding,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
    this.enable = true,
    this.progressWidth,
    this.progressHeight,
    this.isBusy = false,
    this.progressColor,
  })  : assert(!(text != null && child != null), "按钮文案和子内容只能唯一"),
        super(key: key);

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double? height;

  /// 子内容
  final Widget? child;

  /// 按钮文案
  final String? text;

  /// 文案样式
  final TextStyle? textStyle;

  /// 禁用下文案样式
  final TextStyle? disableTextStyle;

  /// 背景色，null时使用系统颜色
  final Color? background;

  /// 禁用状态下的背景色，null时使用系统颜色
  final Color? disableColor;

  /// 阴影范围，默认 0
  final double? elevation;

  /// 圆角，默认 5
  final BorderRadius? borderRadius;

  /// 子级对齐方式
  final Alignment? alignment;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 边框颜色，默认 主题色
  final Color? borderColor;

  /// 边框宽度，默认 0，为0时不显示边框
  final double borderWidth;

  /// 点击的回调
  final Function()? onTap;

  /// 是否启用，默认 true
  final bool enable;

  /// 忙碌中，默认为false，true：忙碌中无法点击, false：正常状态，可点击
  final bool isBusy;

  /// 进度加载宽度
  final double? progressWidth;

  /// 进度加载高度
  final double? progressHeight;

  /// 进度加载颜色
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(enable ? background : disableColor),
          elevation: WidgetStateProperty.all(elevation),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.zero)),
          side: borderWidth == 0
              ? null
              : WidgetStateProperty.all(
                  BorderSide(
                    color: borderColor ?? background ?? Theme.of(context).primaryColor,
                    width: borderWidth,
                  ),
                ),
          padding: WidgetStateProperty.all(padding ?? EdgeInsets.zero),
          alignment: alignment ?? Alignment.center,
        ),
        onPressed: enable && !isBusy ? onTap : null,
        child: _child(),
      ),
    );
  }

  Widget _child() {
    TextStyle defaultStyle = TextStyle(
      color: (background?.computeLuminance() ?? 1) < .5 ? Colors.white : Colors.black,
    );

    if (isBusy) {
      return SizedBox(
        width: progressWidth,
        height: progressHeight,
        child: CircularProgressIndicator(
          color: progressColor ?? Colors.green,
        ),
      );
    } else {
      return child ??
          Text(
            text ?? "--",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: enable ? textStyle ?? defaultStyle : disableTextStyle,
          );
    }
  }
}
