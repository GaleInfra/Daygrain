import 'package:flutter/material.dart';

/// create: 2023/4/27
/// desc: 渐变色文字
class MyGradientText extends StatelessWidget {
  const MyGradientText({
    super.key,
    required this.text,
    this.style,
    required this.colors,
  });

  final String text;

  final TextStyle? style;

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: (colors.isEmpty ? style : style?.copyWith(color: colors.first)) ??
            TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: colors.isEmpty ? Colors.white : colors.first,
            ),
      ),
    );
  }
}
