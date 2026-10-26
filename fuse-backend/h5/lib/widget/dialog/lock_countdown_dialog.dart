import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/pages/c_page/logic.dart';
import 'package:untitled1/language/bh_language_manager.dart';

/// 显示锁定倒计时弹窗
void showLockCountdownDialog(BuildContext context) {
  // 记录是否通过Get按钮关闭
  bool closedByGetButton = false;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => LockCountdownDialog(
      onGetPressed: () {
        closedByGetButton = true;
      },
    ),
  ).then((_) {
    // 只有在非Get按钮关闭的情况下才切换回左侧tab
    if (!closedByGetButton && Get.isRegistered<CPageLogic>()) {
      Get.find<CPageLogic>().toggleTab(0);
    }
  });
}

class LockCountdownDialog extends StatefulWidget {
  final Function? onGetPressed;

  const LockCountdownDialog({Key? key, this.onGetPressed}) : super(key: key);

  @override
  State<LockCountdownDialog> createState() => _LockCountdownDialogState();
}

class _LockCountdownDialogState extends State<LockCountdownDialog> {
  // 直接显示Get按钮，无倒计时

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部区域 - 蓝色渐变背景
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF94F9D9),
                    Color(0xFF73C0FF),
                  ],
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 3.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 安全图标
                  SizedBox(
                    width: 25.w,
                    height: 25.w,
                    child: Image.asset(
                      ImageAssets.defert1,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shield,
                          color: Colors.white,
                          size: 20.w,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 2.w),
                  // 标题文本
                  Text(
                    "title_turn_off_private_mode".bhTR,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),

            // 中间区域 - 灰色背景，包含两层指导
            Container(
              width: double.infinity,
              color: Colors.grey.shade800,
              // padding: EdgeInsets.all(5.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  // 第一层 - 第一步指导
                  Row(
                    children: [
                      // 左侧图片
                      Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          SizedBox(
                            width: 83.w,
                            height: 66.w,
                            // decoration: BoxDecoration(
                            //   color: Colors.black,
                            //   borderRadius: BorderRadius.circular(5.r),
                            // ),
                            child: Image.asset(
                              ImageAssets.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.lock,
                                  color: Colors.blue,
                                  size: 20.w,
                                );
                              },
                            ),
                          ),
                          // 移除编号1
                        ],
                      ),
                      // SizedBox(width: 5.w),
                      // 右侧文本说明
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: EdgeInsets.only(
                                  left: 8.w, right: 5.w, top: 5.w, bottom: 5.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                "instruction_click_second_button".bhTR,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.sp,
                                ),
                              ),
                            ),
                            Positioned(
                              left: -6.25.w,
                              top: -6.25.w,
                              child: Container(
                                width: 12.5.w,
                                height: 12.5.w,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "1",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 7.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // SizedBox(height: 7.5.w),

                  // 第二层 - 第二步指导
                  Row(
                    children: [
                      // 左侧文本说明
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: EdgeInsets.only(
                                  left: 10.w,
                                  right: 5.w,
                                  top: 5.w,
                                  bottom: 5.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                "instruction_click_back_to_home".bhTR,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6.sp,
                                ),
                              ),
                            ),
                            Positioned(
                              left: -6.25.w,
                              top: -6.25.w,
                              child: Container(
                                width: 12.5.w,
                                height: 12.5.w,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "2",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 7.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 5.w),
                      // 右侧图片
                      SizedBox(
                        width: 77.w,
                        height: 84.w,
                        // decoration: BoxDecoration(
                        //   color: Colors.black,
                        //   borderRadius: BorderRadius.circular(5.r),
                        // ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              ImageAssets.second,
                              // fit: BoxFit.cover,
                              // errorBuilder: (context, error, stackTrace) {
                              //   return Icon(
                              //     Icons.home,
                              //     color: Colors.greenAccent,
                              //     size: 20.w,
                              //   );
                              // },
                            ),
                            // Positioned(
                            //   bottom: 7.5.w,
                            //   child: Container(
                            //     padding: EdgeInsets.symmetric(
                            //         horizontal: 7.5.w, vertical: 4.w),
                            //     decoration: BoxDecoration(
                            //       color: Color(0xFF00E5D0),
                            //       borderRadius: BorderRadius.circular(10.r),
                            //     ),
                            //     child: Text(
                            //       "Back to home",
                            //       style: TextStyle(
                            //         color: Colors.black,
                            //         fontWeight: FontWeight.bold,
                            //         fontSize: 5.sp,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 底部区域 - Get按钮
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.w, top: 5.w),
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          // 调用Get按钮回调
                          if (widget.onGetPressed != null) {
                            widget.onGetPressed!();
                          }

                          // 关闭对话框
                          Navigator.of(context).pop();

                          // 通知CPage显示安全页面，并确保选中右侧tab
                          if (Get.isRegistered<CPageLogic>()) {
                            Get.find<CPageLogic>().toggleTab(1); // 确保选中右侧tab
                            // Get.find<CPageLogic>().showSafePage();
                          }
                        },
                        child: Container(
                          width: 120.w,
                          height: 25.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.purple,
                                Colors.cyan,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Center(
                            child: Text(
                              "action_get".bhTR,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
