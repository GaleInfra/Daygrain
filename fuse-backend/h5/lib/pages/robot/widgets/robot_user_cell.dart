import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/model/robot/RobotModel.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

class RobotUserCell extends StatelessWidget {
  final RobotCQModel model;

  const RobotUserCell({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: SizedBox()),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 24.w,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.r),
              gradient: LinearGradient(
                colors: [
                  MyColor.btnGradientColors2[3],
                  MyColor.btnGradientColors2[4],
                ]
              )
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 5.w,
              vertical: 5.h,
            ),
            child: Text(
              model.content ?? '',
              style: TextStyle(
                color: Colors.black,
                fontSize: 7.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.5.r),
            child: MyExtendedNetworkImage(
              url: Get.find<AppConfigManager>().userInfo.avatarUrl ?? "",
              width: 21.w,
              height: 21.w,
              fit: BoxFit.cover,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7.5.w),
        ],
      ),
    );
  }
} 