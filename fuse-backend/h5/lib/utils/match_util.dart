import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/font_utils.dart';
/// 顶部时间

class RankingTime extends StatelessWidget {
  RankingTime({Key? key}) : super(key: key);

  final formatter = DateFormat('MMMM', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Text(
      "Rank of ${formatter.format(DateTime.now())}",
      style: FontUtils.boldItalic(
        size: 8.5.sp,
        color: MyColor.white,
      ),
    );
  }
}
