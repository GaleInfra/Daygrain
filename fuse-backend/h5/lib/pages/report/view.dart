import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'logic.dart';
import '../../utils/device_util.dart';
import '../../widget/keyboard_listener_widget.dart';

class ReportPage extends StatelessWidget {
  ReportPage({Key? key}) : super(key: key);

  final logic = Get.put(ReportLogic());
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final RxBool _rememberMe = false.obs;
  final RxBool _canSubmit = false.obs;

  void _updateCanSubmit() {
    _canSubmit.value = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // 顶部安全高度
            Container(
              height: DeviceUtil().statusBarHeight ?? 0,
              color: Colors.white,
            ),
            // 自定义顶部栏（原AppBar内容）
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 5.h),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.apple, color: Colors.black, size: 8.w),
                  Row(
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.search, color: Colors.black, size: 8.w),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.shopping_bag_outlined,
                            color: Colors.black, size: 8.w),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.black, size: 8.w),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 可拖动区域指示器
            // Center(
            //   child: Container(
            //     margin: EdgeInsets.symmetric(vertical: 10.h),
            //     child: Icon(
            //       Icons.open_with,
            //       color: Colors.black,
            //       size: 18.w,
            //     ),
            //   ),
            // ),

            SizedBox(height: 40.h),

            // 标题
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Text(
                "Sign in to your Apple Account",
                style: TextStyle(
                    fontSize: 10.sp,
                    // fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333)),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 7.h),

            // 输入框
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Container(
                // height: 24.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.w),
                  border: Border.all(color: const Color(0xFF007AFF), width: 1),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _emailController,
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 7.sp),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: "Email or Phone Number",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 7.sp,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                      border: InputBorder.none,
                      suffixIcon: const Align(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                      ),
                    ),
                    onChanged: (val) => _updateCanSubmit(),
                  ),
                ),
              ),
            ),

            SizedBox(height: 5.h),

            // 输入框
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Container(
                // height: 24.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.w),
                  border: Border.all(color: const Color(0xFF007AFF), width: 1),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: KeyboardListenerWidget(
                    onKeyboardChanged: (isShow, height) {
                      if (!isShow) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 7.sp),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: "Password",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 7.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.w),
                        border: InputBorder.none,
                        suffixIcon: Align(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 2.w, horizontal: 2.w),
                            width: 11.w,
                            height: 11.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 0.5),
                            ),
                            child: Obx(() => InkWell(
                                  onTap: _canSubmit.value
                                      ? () {
                                          String emailText =
                                              _emailController.text.isEmpty
                                                  ? 'husnfshfihdf@Gmail.com'
                                                  : _emailController.text;
                                          Get.toNamed('/report_detail',
                                              arguments: {'email': emailText});
                                        }
                                      : null,
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: _canSubmit.value
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    size: 7.w,
                                  ),
                                )),
                          ),
                        ),
                      ),
                      onChanged: (val) => _updateCanSubmit(),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 60.h),

            // 记住我选项
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Obx(() => Checkbox(
                          value: _rememberMe.value,
                          onChanged: (value) {
                            _rememberMe.value = value ?? false;
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        )),
                  ),
                  Text(
                    "Remember me",
                    style: TextStyle(
                      fontSize: 7.sp,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),

            // 忘记密码链接
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Forgot password?",
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 7.sp,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // 底部"创建新账号"链接
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 6.h),
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an Apple Account?",
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 7.sp, color: Colors.black),
                  ),
                  // SizedBox(width: 5.w),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding:
                          EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Create Your Apple Account",
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 7.sp,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 底部留白，为固定在底部的区域腾出空间
            // SizedBox(height: 30.h),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        color: Colors.grey.shade200,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 国家/地区选择
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "United States",
                  style: TextStyle(
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // 版权信息
            Text(
              "Copyright © 2025 Apple Inc. All rights reserved.",
              style: TextStyle(
                  fontSize: 5.sp, color: const Color.fromARGB(255, 75, 75, 75)),
            ),

            SizedBox(height: 3.h),

            // 隐私政策和使用条款
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Privacy Policy",
                  style: TextStyle(
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    "|",
                    style: TextStyle(
                        fontSize: 5.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
                Text(
                  "Terms of Use",
                  style: TextStyle(
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ],
            ),
            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }
}
