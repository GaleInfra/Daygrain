
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/utils/bh_platform.dart';

/// @description: 取消 Android / Fuchsia 回弹效果
class CustomBehavior extends StatelessWidget {
  const CustomBehavior({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(behavior: MyBehavior(), child: child);
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(context, child, details) {
    if (BHPlatform.isAndroid || BHPlatform.isFuchsia) {
      return child;
    } else {
      return super.buildOverscrollIndicator(context, child, details);
    }
  }
}

class CustomScrollbar extends StatelessWidget {
  const CustomScrollbar({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (BHPlatform.isAndroid || BHPlatform.isFuchsia) {
      return Scrollbar(child: child);
    } else {
      return CupertinoScrollbar(child: child);
    }
  }
}
