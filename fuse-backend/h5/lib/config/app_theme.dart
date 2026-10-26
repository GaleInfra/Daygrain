import 'package:flutter/material.dart';

import '../res/my_color.dart';

/// create: 2023/4/23
/// desc: 主题管理
ThemeData getThemeData() {
  ColorScheme colorScheme = ColorScheme.fromSwatch(
    primarySwatch: MyColor.themeColor1E2440,
  );
  AppBarTheme appBarTheme = const AppBarTheme(
      elevation: 0,
      backgroundColor: MyColor.themeColor1E2440,
      titleTextStyle: TextStyle(
        color: MyColor.themeColor1E2440,
        fontSize: 18,
      ),
      iconTheme: IconThemeData(
        color: MyColor.themeColor1E2440,
      ),
  );

  var themeData = ThemeData.light().copyWith(
    colorScheme: colorScheme,
    appBarTheme: appBarTheme,
    primaryColor: MyColor.themeColor1E2440,
    scaffoldBackgroundColor: MyColor.transparent,
  );
  return themeData;
}