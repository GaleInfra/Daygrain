import 'package:flutter/material.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';


class MyLinearGradient {
  static LinearGradient getGradient() {
    bool isRTL = BHLanguageMar().isRightToLeft.value;
    return LinearGradient(
      colors: MyColor.btnGradientColors,
      begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
      end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
    );
  }
}