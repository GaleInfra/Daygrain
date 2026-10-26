import 'package:flutter/material.dart';

class FontUtils {
  /// GillSans字体样式
  static TextStyle gillSansFont(
    String fontFamily, {
    double? size,
    Color? color,
    FontWeight? weight,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    TextOverflow? overflow,
    bool? softWrap,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      overflow: overflow,
    );
  }

  /// 常用预设
  static TextStyle boldItalic({
    double? size = 14,
    Color? color = Colors.black,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    TextOverflow? overflow,
  }) {
    return gillSansFont(
      "GillSans-BoldItalic",
      size: size,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      overflow: overflow,
      weight: FontWeight.bold,
    );
  }

  static TextStyle sansSemiBold({
    double? size = 14,
    Color? color = Colors.black,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    TextOverflow? overflow,
  }) {
    return gillSansFont(
      "GillSans-SemiBold",
      size: size,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      overflow: overflow,
      weight: FontWeight.bold,
    );
  }
}
