import 'package:flutter/material.dart';
import 'package:untitled1/widget/button/my_button.dart';

import '../../res/my_gaps.dart';

/// create: 2023/5/8
/// desc: 默认弹窗样式

/// 按钮位置状态
enum MyDialogStatus {
  /// 撑满
  expand,

  /// 单独个体
  alone,

  /// 垂直
  vertical,
}

/// 基础弹窗，带有图标、标题、辅助内容、警告内容、双按钮，可自定义子级内容
/// version: 1.0
class MyDialog extends StatelessWidget {
  const MyDialog({
    Key? key,
    this.width,
    this.background,
    this.borderRadius,
    this.icons,
    this.localImage,
    this.iconWidth,
    this.iconHeight,
    this.iconColor,
    this.title,
    this.titleStyle,
    this.titlePadding,
    this.showTitleLine = false,
    this.confirm,
    this.confirmTextStyle,
    this.confirmBackground,
    this.confirmBorderRadius,
    this.confirmMargin,
    this.confirmBorderColor,
    this.onConfirm,
    this.cancel,
    this.cancelTextStyle,
    this.cancelBackground,
    this.cancelBorderRadius,
    this.cancelMargin,
    this.cancelBorderColor,
    this.onCancel,
    this.child,
    this.message,
    this.messageTextStyle,
    this.warning,
    this.warningTextStyle,
    this.dialogStatus = MyDialogStatus.expand,
  })  : assert(!(icons != null && localImage != null), "icons和localImage只能唯一"),
        assert(!(confirm == null && cancel != null), "未使用主按钮时不可使用次按钮"),
        assert(!(title == null && message == null && warning == null && child == null), "标题或子内容必须有其一"),
        super(key: key);

  /// 弹窗宽度，默认是屏幕的80%
  final double? width;

  ///弹窗背景色，默认 白色
  final Color? background;

  ///弹窗圆角
  final BorderRadius? borderRadius;

  /// Icons图标
  final IconData? icons;

  /// 本地图片
  final String? localImage;

  /// 图标宽度
  final double? iconWidth;

  /// 图标高度
  final double? iconHeight;

  /// 图标颜色
  final Color? iconColor;

  /// 标题
  final String? title;

  /// 标题样式
  final TextStyle? titleStyle;

  /// 标题内边距
  final EdgeInsetsGeometry? titlePadding;

  /// 显示标题下面的分割线
  final bool showTitleLine;

  /// 主按钮文案
  final String? confirm;

  /// 主按钮文案样式
  final TextStyle? confirmTextStyle;

  /// 主按钮背景色
  final Color? confirmBackground;

  /// 主按钮圆角，当[dialogStatus]为[MyDialogStatus.expand]时无效
  final BorderRadius? confirmBorderRadius;

  /// 主按钮外边距，当[dialogStatus]为[MyDialogStatus.expand]时无效
  final EdgeInsetsGeometry? confirmMargin;

  /// 主按钮边框颜色
  final Color? confirmBorderColor;

  /// 主按钮点击事件
  final VoidCallback? onConfirm;

  /// 次按钮文案
  final String? cancel;

  /// 次按钮文案样式
  final TextStyle? cancelTextStyle;

  /// 次按钮背景色
  final Color? cancelBackground;

  /// 次按钮圆角，当[dialogStatus]为[MyDialogStatus.expand]时无效
  final BorderRadius? cancelBorderRadius;

  /// 次按钮外边距，当[dialogStatus]为[MyDialogStatus.expand]时无效
  final EdgeInsetsGeometry? cancelMargin;

  /// 次按钮边框颜色
  final Color? cancelBorderColor;

  /// 次按钮点击事件
  final VoidCallback? onCancel;

  /// 子级
  final Widget? child;

  /// 内容文案
  final String? message;

  /// 内容文案样式
  final TextStyle? messageTextStyle;

  /// 警示内容
  final String? warning;

  /// 警示内容样式
  final TextStyle? warningTextStyle;

  /// 按钮位置状态
  final MyDialogStatus dialogStatus;

  @override
  Widget build(BuildContext context) {
    // 图标
    Widget? imageView;
    if (icons != null) {
      imageView = Center(
        child: Container(
          width: iconWidth,
          height: iconHeight,
          margin: const EdgeInsets.only(top: 20, bottom: 5),
          child: Icon(
            icons,
            size: iconWidth,
            color: iconColor,
          ),
        ),
      );
    } else if (localImage != null) {
      imageView = Center(
        child: Container(
          width: iconWidth,
          height: iconHeight,
          margin: const EdgeInsets.only(top: 20, bottom: 5),
          child: Image.asset(
            localImage!,
            width: iconWidth,
            height: iconHeight,
            color: iconColor,
          ),
        ),
      );
    }

    // 标题
    Widget? titleView;
    if (title != null) {
      titleView = Container(
        padding: titlePadding ?? const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        child: Text(
          title!,
          style: titleStyle ??
              const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    }

    // 主按钮
    Widget? confirmButton;
    if (confirm != null) {
      confirmButton = _getConfirmButton(context);
    }

    // 次按钮
    Widget? cancelButton;
    if (cancel != null) {
      cancelButton = _getCancelButton(context);
    }

    // 内容文案
    Widget? messageWidget;
    if (message != null) {
      messageWidget = Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          top: 10,
          right: 15,
          left: 15,
          bottom: warning != null ? 10 : 20,
        ),
        child: Text(
          message!,
          textAlign: TextAlign.center,
          style: messageTextStyle ??
              TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
        ),
      );
    }

    // 警告内容
    Widget? warningWidget;
    if (warning != null) {
      warningWidget = Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          top: message != null ? 0 : 10,
          right: 15,
          left: 15,
          bottom: 20,
        ),
        child: Text(
          warning!,
          textAlign: TextAlign.center,
          style: messageTextStyle ??
              const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width ?? MediaQuery.of(context).size.width * .8,
          decoration: BoxDecoration(
            color: background ?? Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageView != null) imageView,
              if (titleView != null) titleView,
              if (showTitleLine) MyGaps.hLine,
              if (messageWidget != null && child == null) messageWidget,
              if (warningWidget != null && child == null) warningWidget,
              if (child != null) child!,
              // 有按钮，且按钮撑满时显示分割线
              if (confirmButton != null && dialogStatus == MyDialogStatus.expand) MyGaps.hLine,
              // 按钮撑满的布局
              if (dialogStatus == MyDialogStatus.expand)
                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (cancelButton != null) Expanded(child: cancelButton),
                      if (cancelButton != null) MyGaps.vLine,
                      if (confirmButton != null) Expanded(child: confirmButton),
                    ],
                  ),
                ),
              if (dialogStatus == MyDialogStatus.alone)
                Row(
                  children: [
                    if (cancelButton != null) Expanded(child: cancelButton),
                    if (confirmButton != null) Expanded(child: confirmButton),
                  ],
                ),
              if (dialogStatus == MyDialogStatus.vertical && confirmButton != null) confirmButton,
              if (dialogStatus == MyDialogStatus.vertical && cancelButton != null) cancelButton,
            ],
          ),
        ),
      ],
    );
  }

  /// 确定按钮
  Widget _getConfirmButton(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    Color background = confirmBackground ?? (dialogStatus != MyDialogStatus.expand ? themeData.colorScheme.primary : Colors.white);
    TextStyle? textStyle = confirmTextStyle;
    textStyle ??= TextStyle(
      fontSize: 16,
      color: dialogStatus == MyDialogStatus.expand ? themeData.colorScheme.primary
          : (background.computeLuminance() < .5 ? Colors.white : Colors.black),
    );
    return MyButton(
      width: double.infinity,
      height: 50,
      text: confirm,
      textStyle: textStyle,
      borderRadius: _getConfirmBorderRadius(),
      margin: _getConfirmMargin(),
      borderWidth: confirmBorderColor != null ? 1 : 0,
      borderColor: confirmBorderColor,
      background: background,
      onTap: onConfirm ?? () {Navigator.pop(context);},
    );
  }

  /// 取消按钮
  Widget _getCancelButton(BuildContext context) {
    Color background = cancelBackground ?? Colors.white;
    TextStyle? textStyle = cancelTextStyle ?? TextStyle(
      color: background.computeLuminance() < .5 ? Colors.white : Colors.black,
      fontSize: 16,
    );
    return MyButton(
      width: double.infinity,
      height: 50,
      text: cancel,
      textStyle: textStyle,
      borderRadius: _getCancelBorderRadius(),
      margin: _getCancelMargin(),
      borderWidth: cancelBorderColor != null ? 1 : 0,
      borderColor: cancelBorderColor,
      background: background,
      onTap: onCancel ?? () {Navigator.pop(context);},
    );
  }

  /// 获取主按钮圆角
  BorderRadius _getConfirmBorderRadius() {
    if (dialogStatus == MyDialogStatus.expand) {
      return BorderRadius.only(
        bottomLeft: cancel == null ? (borderRadius?.bottomLeft ?? Radius.zero) : Radius.zero,
        bottomRight: borderRadius?.bottomRight ?? Radius.zero,
      );
    }
    return confirmBorderRadius ?? BorderRadius.circular(5);
  }

  /// 获取次按钮圆角
  BorderRadius _getCancelBorderRadius() {
    if (dialogStatus == MyDialogStatus.expand) {
      return BorderRadius.only(bottomLeft: borderRadius?.bottomLeft ?? Radius.zero);
    }
    return confirmBorderRadius ?? BorderRadius.circular(5);
  }

  /// 获取主按钮外边距
  EdgeInsetsGeometry _getConfirmMargin() {
    switch (dialogStatus) {
      case MyDialogStatus.expand:
        return EdgeInsets.zero;
      case MyDialogStatus.alone:
        return confirmMargin ??
            EdgeInsets.only(left: cancel != null ? 7.5 : 15, right: 15, bottom: 15, top: 10);
      case MyDialogStatus.vertical:
        return confirmMargin ?? const EdgeInsets.only(left: 15, right: 15, bottom: 10, top: 10);
    }
  }

  /// 获取次按钮外边距
  EdgeInsetsGeometry _getCancelMargin() {
    switch (dialogStatus) {
      case MyDialogStatus.expand:
        return EdgeInsets.zero;
      case MyDialogStatus.alone:
        return cancelMargin ?? const EdgeInsets.only(left: 15, right: 7.5, bottom: 15, top: 10);
      case MyDialogStatus.vertical:
        return cancelMargin ?? const EdgeInsets.only(left: 15, right: 15, bottom: 15);
    }
  }
}