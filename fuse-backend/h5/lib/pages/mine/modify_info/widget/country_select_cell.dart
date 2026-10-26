import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/res/my_color.dart';

class CountrySelectCell extends StatelessWidget {
  final Map<String,dynamic> model;

  const CountrySelectCell({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff191919),
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
      child: Row(
        children: [
          SizedBox(
            height: 10.h,
            child: model["emoji"] ?? '',
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              model["name"] ?? '',
              style: TextStyle(
                color: MyColor.white,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 