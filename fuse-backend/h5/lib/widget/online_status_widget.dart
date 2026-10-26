import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/utils/online_status_util.dart';

/// create: 2023/4/27
/// desc: 在线状态widget
class OnlineStatusWidget extends StatelessWidget {
  OnlineStatusWidget({
    Key? key,
    required this.status,
    this.width ,
    this.height ,
  }) : super(key: key);

  /// 当前状态
  final String status;

   double? width;

   double? height;

  /// 获取配置管理
  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    width ??= 6.w;
    height ??= 6.w;
    return Obx(() {
      return Visibility(
        visible: !appConfig.isReviewPkg.value,
        child: RepaintBoundary(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: OnlineStatusUtil.getColor(status),
              shape: BoxShape.circle,
              // border: Border.all(
              //   color: Colors.white,
              //   width: 1,
              // ),
            ),
          ),
        ),
      );
    });
  }
}
