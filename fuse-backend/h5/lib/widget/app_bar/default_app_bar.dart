import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/utils/device_util.dart';

import '../../res/my_color.dart';

/// create: 2023/4/28
/// desc: 默认标题栏
class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DefaultAppBar({
    Key? key,
    this.onBack,
    this.titleWidget,
    this.title,
    this.style,
    this.action,
    this.leading,
    this.backIconColor, // 添加返回图标颜色参数
    this.centerTitle = true,  // 添加控制标题对齐的参数
  }) : super(key: key);

  final VoidCallback? onBack;

  final Widget? titleWidget;

  final String? title;

  final TextStyle? style;

  final Widget? leading;

  final List<Widget>? action;

  final Color? backIconColor; 

   final bool centerTitle;  // 新增参数声明

  @override
  Widget build(BuildContext context) {
    Widget? titleView = titleWidget;
    if (titleWidget == null && title != null) {
      titleView = Text(
        title ?? "",
        style: style ??
            TextStyle(
              fontSize: 9.sp,
              color: MyColor.white,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: DeviceUtil().statusBarHeight,
        ),
        AppBar(
          backgroundColor: MyColor.transparent,
          shadowColor: MyColor.transparent,
          foregroundColor: MyColor.transparent,
          surfaceTintColor: MyColor.transparent,
          toolbarHeight: (DeviceUtil().toolbarHeight ?? 0) - (DeviceUtil().statusBarHeight ?? 0),
          centerTitle: centerTitle,
          leading: leading ??
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 10.sp,
                  color: backIconColor ?? MyColor.white,
                ),
                onPressed: onBack ?? () => Get.back(),
              ),
          title: titleView,
          actions: action,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(DeviceUtil().toolbarHeight ?? 0);
}
