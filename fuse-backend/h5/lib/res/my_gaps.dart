import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'my_color.dart';

/// @author: zx
/// @description: 通用占位盒子封装和分割线
class MyGaps {
  //水平间隔
  static Widget hGaps2w = SizedBox(
    width: 2.w,
  );
  static Widget hGaps3w = SizedBox(
    width: 3.w,
  );
  static Widget hGaps5w = SizedBox(
    width: 5.w,
  );
  static Widget hGaps7w = SizedBox(
    width: 7.w,
  );
  static Widget hGaps10w = SizedBox(
    width: 10.w,
  );
  static Widget hGaps15w = SizedBox(
    width: 15.w,
  );
  static Widget hGaps20w = SizedBox(
    width: 20.w,
  );
  static Widget hGaps25w = SizedBox(
    width: 25.w,
  );
  static Widget hGaps30w = SizedBox(
    width: 30.w,
  );
  static Widget hGaps50w = SizedBox(
    width: 50.w,
  );

  //垂直间隔
  static Widget vGaps1w = SizedBox(
    height: 1.w,
  );
  static Widget vGaps2w = SizedBox(
    height: 2.w,
  );
  static Widget vGaps3w = SizedBox(
    height: 3.w,
  );
  static Widget vGaps4w = SizedBox(
    height: 4.w,
  );
  static Widget vGaps5w = SizedBox(
    height: 5.w,
  );
  static Widget vGaps7w = SizedBox(
    height: 7.w,
  );
  static Widget vGaps8w = SizedBox(
    height: 8.w,
  );
  static Widget vGaps9w = SizedBox(
    height: 9.w,
  );
  static Widget vGaps10w = SizedBox(
    height: 10.w,
  );
  static Widget vGaps11w = SizedBox(
    height: 11.w,
  );
  static Widget vGaps12w = SizedBox(
    height: 12.w,
  );
  static Widget vGaps15w = SizedBox(
    height: 15.w,
  );
  static Widget vGaps20w = SizedBox(
    height: 20.w,
  );
  static Widget vGaps25w = SizedBox(
    height: 25.w,
  );
  static Widget vGaps30w = SizedBox(
    height: 30.w,
  );
  static Widget vGaps40w = SizedBox(
    height: 40.w,
  );
  static Widget vGaps50w = SizedBox(
    height: 50.w,
  );

  static Widget hLine = Divider(
    height: 0.5,
    color: Colors.white.withValues(alpha: 0.2),
  );
  static Widget hLine2 = Container(
    width: double.infinity,
    height: 1,
    color: const Color(0xFFF8F6F6).withValues(alpha: 0.1),
  );

  static const Widget vLine = SizedBox(
    width: 1,
    height: double.infinity,
    child: DecoratedBox(decoration: BoxDecoration(color: MyColor.greyF8F6F6)),
  );
}
