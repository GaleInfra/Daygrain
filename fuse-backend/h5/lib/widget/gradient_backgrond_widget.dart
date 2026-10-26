import 'package:flutter/material.dart';

import '../res/my_color.dart';

/// create: 2023/4/28
/// desc: 渐变背景色widget
class GradientBackgroundWidget extends StatelessWidget {
  const GradientBackgroundWidget({
    Key? key,
    required this.child,
    this.colors,
  }) : super(key: key);

  final Widget child;

  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: colors == null
            ? null
            : LinearGradient(
                colors: colors!,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: colors == null ? MyColor.appBackground : null,
      ),
      child: child,
    );
  }
}

class GradientBackgroundWidgetSubPage extends GradientBackgroundWidget {
  const GradientBackgroundWidgetSubPage({
    Key? key,
    required super.child,
    super.colors = const [Color(0xFF111419), Color(0xFF111419)],
  }) : super(key: key);
}
