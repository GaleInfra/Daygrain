import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/my_color.dart';

/// create: 2023/4/26
/// desc: 底部Sheet item
class SheetItem extends StatelessWidget {
  const SheetItem({
    Key? key,
    required this.title,
    this.style,
    this.onTap,
  }) : super(key: key);

  final String title;

  final TextStyle? style;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 29.w,
        color: MyColor.transparent,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ??
              TextStyle(
                fontWeight: FontWeight.bold,
                color: MyColor.black,
                fontSize: 8.sp,
              ),
        ),
      ),
    );
  }
}
