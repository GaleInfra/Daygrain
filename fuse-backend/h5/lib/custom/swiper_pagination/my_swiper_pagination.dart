import 'dart:developer';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';

/// create: 2023/4/25
/// desc: 自定义轮播图指示器
class MySwiperPagination extends SwiperPlugin {
  final Color? activeColor;

  final Color? color;

  final double activeWidth;

  final double width;

  final double height;

  final double space;

  final Key? key;

  const MySwiperPagination({
    this.activeColor,
    this.color,
    this.key,
    this.width = 6.0,
    this.activeWidth = 12.0,
    this.height = 6.0,
    this.space = 3.0,
  });

  @override
  Widget build(BuildContext context, SwiperPluginConfig config) {
    if (config.itemCount > 20) {
      log("The itemCount is too big, we suggest use FractionPaginationBuilder instead of DotSwiperPaginationBuilder in this sitituation");
    }
    Color? activeColor = this.activeColor;
    Color? color = this.color;

    if (activeColor == null || color == null) {
      ThemeData themeData = Theme.of(context);
      activeColor = this.activeColor ?? themeData.primaryColor;
      color = this.color ?? themeData.scaffoldBackgroundColor;
    }

    List<Widget> list = [];

    int itemCount = config.itemCount;
    int activeIndex = config.activeIndex;

    for (int i = 0; i < itemCount; ++i) {
      bool active = i == activeIndex;
      list.add(
        Container(
          key: Key("pagination_$i"),
          margin: EdgeInsets.all(space),
          child: Container(
            decoration: BoxDecoration(
              gradient: active ? LinearGradient(
                colors: MyColor.btnGradientColors,
                begin: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft ,
                end: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
              ) : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(height),
            ),
            width: active ? activeWidth : width,
            height: height,
          ),
        ),
      );
    }

    if (config.scrollDirection == Axis.vertical) {
      return Column(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: list,
      );
    } else {
      return Row(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: list,
      );
    }
  }
}
