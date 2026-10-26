import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/widget/user_info/age_widget.dart';

import '../../res/my_gaps.dart';
import 'country_widget.dart';

class AgeCountryRowWidget extends StatelessWidget {
  final String? age;
  final String? country;
  final int? countryMaxLength;

  const AgeCountryRowWidget(
      {Key? key, this.age, this.country, this.countryMaxLength})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
            visible: age != null,
            child: Container(

                constraints: BoxConstraints(maxWidth: 30.w, minWidth: 10.w),
                child: AgeWidget(text: age!))),
        MyGaps.hGaps5w,
        Flexible(
          flex: 1,
            child: CountryWidget(
          text: country!,
          countryMaxLength: countryMaxLength ?? 10,
        )),
      ],
    );
  }
}
