import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/res/my_color.dart';

class CountryWidget extends StatelessWidget {
  final String text;
  final int countryMaxLength;
  const CountryWidget(
      {Key? key, required this.text, this.countryMaxLength = 10})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        return Container(
          padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 1.5.w, bottom: 1.w),
          decoration: BoxDecoration(
            color: MyColor.blue7B89FF,
            borderRadius: BorderRadius.circular(9.w),
          ),

          child: Text(
            text.truncateThan(countryMaxLength).fixAutoLines(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: MyColor.white,
              fontSize: 7.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
