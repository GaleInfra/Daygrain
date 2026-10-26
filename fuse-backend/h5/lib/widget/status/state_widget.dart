import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/widget/button/my_button.dart';

import '../../res/my_color.dart';
import '../../res/my_gaps.dart';
import '../custom_behavior.dart';

/// @description: 各种状态的widget

Widget noFoundWidget = Scaffold(
  appBar: AppBar(
    elevation: 0,
    title: const Text(
      "错误",
    ),
  ),
  body: const Center(
    child: Text("未找到页面"),
  ),
);

///加载widget
class LoadingWidget extends StatelessWidget {
  final Color? background;

  const LoadingWidget({
    Key? key,
    this.background,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background ?? MyColor.transparent,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 15.w,
            height: 15.w,
            child: const CircularProgressIndicator(
                value: null, color: MyColor.themeColorNew),
          ),
        ],
      ),
    );
  }
}

///空数据
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    Key? key,
    this.message,
    this.buttonText,
    this.onRefresh,
  }) : super(key: key);

  /// 空数据文案
  final String? message;

  /// 按钮文案
  final String? buttonText;

  /// 刷新按钮回调
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomBehavior(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                ImageAssets.empty,
                width: 100.w,
                height: 100.w,
              ),
              Text(
                message ?? "error_noData".bhTR,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: MyColor.white,
                ),
              ),
              Visibility(visible: onRefresh != null, child: MyGaps.vGaps10w),
              Visibility(
                visible: onRefresh != null,
                child: MyButton(
                  text: buttonText ?? "action_refresh".bhTR,
                  width: 60.w,
                  height: 18.w,
                  textStyle: TextStyle(
                    color: MyColor.white,
                    fontSize: 8.sp,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  borderRadius: BorderRadius.circular(10.w),
                  background: MyColor.blue51,
                  enable: true,
                  onTap: onRefresh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 出错界面
class OnErrorWidget extends StatelessWidget {
  const OnErrorWidget({
    Key? key,
    this.message,
    this.buttonText,
    this.onRefresh,
  }) : super(key: key);

  /// 错误文案
  final String? message;

  /// 按钮文案
  final String? buttonText;

  /// 重试按钮回调
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomBehavior(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message ?? "label_error".bhTR,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: MyColor.greyCECECE,
                  ),
                ),
                Visibility(
                  visible: onRefresh != null,
                  child: MyGaps.vGaps10w,
                ),
                Visibility(
                  visible: onRefresh != null,
                  child: MyButton(
                    text: buttonText ?? "action_retry".bhTR,
                    // width: 47.w,
                    height: 18.w,
                    textStyle: TextStyle(
                      color: MyColor.white,
                      fontSize: 8.sp,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    borderRadius: BorderRadius.circular(10.w),
                    background: MyColor.blue51,
                    enable: true,
                    onTap: onRefresh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
