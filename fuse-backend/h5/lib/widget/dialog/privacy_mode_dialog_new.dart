import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';

/// 显示新的隐私模式弹窗
void showPrivacyModeDialogNew(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => PrivacyModeDialogNew(),
  );
}

class PrivacyModeDialogNew extends StatelessWidget {
  const PrivacyModeDialogNew({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth - 20.w; // 屏幕宽度减去左右各10.w的边距

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 10.w), // 设置为10.w的边距
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none, // 允许子元素超出父元素边界
        children: [
          // 主要内容容器
          Container(
            width: dialogWidth, // 设置容器宽度
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF283634),
                  Color(0xFF00D394),
                ],
              ),
              borderRadius: BorderRadius.circular(7.5.r), // 减半
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部图标和标题
                Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 5.h), // 减半
                  child: Column(
                    children: [
                      // 使用Image.asset加载图片，添加errorBuilder处理加载失败的情况
                      Image.asset(
                        ImageAssets.titlelogo,
                        width: 79.w, // 设置合适的宽度
                        height: 62.h, // 设置合适的高度
                        fit: BoxFit.contain, // 确保图片完整显示
                        errorBuilder: (context, error, stackTrace) {
                          print('图片加载错误: $error');
                          // 加载失败时显示文本
                          return Text(
                            "privacy_mode_title".bhTR,
                            style: TextStyle(
                              color: Color(0xFF00E5D0),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 7.5.h), // 减半
                      // Private Mode 文字
                      Text(
                        "privacy_mode_title".bhTR,
                        style: TextStyle(
                          color: Color(0xFF00F3AA),
                          fontSize: 8.sp, // 减半
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tips 部分
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h), // 减半
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "privacy_mode_tips".bhTR,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp, // 减半
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3.5.h), // 减半
                      Text(
                        "privacy_mode_description".bhTR,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.sp, // 减半
                        ),
                      ),
                    ],
                  ),
                ),

                // Turn off Private Mode 部分
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h), // 减半
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "privacy_mode_turn_off".bhTR,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp, // 减半
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3.5.h), // 减半
                      // 步骤1
                      Row(
                        children: [
                          Text(
                            "1.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp, // 减半
                            ),
                          ),
                          SizedBox(width: 2.5.w), // 减半
                          Text(
                            "privacy_mode_step1".bhTR,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp, // 减半
                            ),
                          ),
                          SizedBox(width: 2.5.w), // 减半
                          Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 7.w, // 减半
                          ),
                          SizedBox(width: 2.5.w), // 减半
                          Text(
                            "privacy_mode_step1_suffix".bhTR,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp, // 减半
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.5.h), // 减半
                      // 步骤2
                      Row(
                        children: [
                          Text(
                            "2.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp, // 减半
                            ),
                          ),
                          SizedBox(width: 2.5.w), // 减半
                          Text(
                            "privacy_mode_step2".bhTR,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6.sp, // 减半
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Get 按钮
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 9.h), // 减半
                  child: GestureDetector(
                    onTap: () async {
                      // 关闭对话框
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 100.w, // 减半
                      height: 22.5.h, // 减半
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15.r), // 减半
                      ),
                      child: Center(
                        child: Text(
                          "action_get".bhTR,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp, // 减半
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 为箭头图片预留空间
                // SizedBox(height: 15.h),
              ],
            ),
          ),

          // 箭头图片，定位在底部中间，超出对话框
          Positioned(
            bottom: -40.h, // 向下偏移，使图片部分超出对话框
            right: 35.w,
            child: Image.asset(
              ImageAssets.jiantou,
              width: 50.w,
              height: 50.h,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
