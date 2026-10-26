import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/res/my_color.dart';

class AgeWidget extends StatelessWidget {
  final String text;
  const AgeWidget({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 1.5.w, bottom: 1.w),
      decoration: BoxDecoration(
        color: MyColor.pinkFF7B7B,
        borderRadius: BorderRadius.circular(9.w),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: MyColor.white,
          fontSize: 7.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
