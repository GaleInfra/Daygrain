import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'logic.dart';
import '../report_next/view.dart';
import '../report_next/logic.dart';
import 'package:untitled1/utils/device_util.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({Key? key}) : super(key: key);

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final logic = Get.put(ReportDetailLogic());
  final String email = Get.arguments != null &&
          Get.arguments is Map &&
          Get.arguments.containsKey('email')
      ? Get.arguments['email']
      : 'husnfshfihdf@Gmail.com';

  // 创建一个全局键，用于定位下拉框
  final GlobalKey _dropdownKey = GlobalKey();
  // 创建一个Overlay条目
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              color: Color(0xFF3A3A3C),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.apple, color: Colors.white, size: 8.w),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 8.w),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          // 标题区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(
                bottom: BorderSide(color: Color(0xFF979797), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Report a Problem",
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // 登出操作
                    Get.back();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.5.h),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 222, 222, 222),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: Text(
                      "Sign Out",
                      style: TextStyle(
                        fontSize: 5.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 邮箱区域
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFCFCFCF), width: 0.5),
              ),
            ),
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 说明文本
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 10.h),
            color: Colors.grey.shade100,
            child: Text(
              "Get help with content you have purchased through Apple",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // Logo区域
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 15.h),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    color: Colors.black,
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: null,
                      // Image.asset(
                      //   ImageAssets.logo,
                      //   width: 25.w,
                      //   height: 25.w,
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                  ),
                ),
                SizedBox(width: 7.5.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wing",
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      "Wing",
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 问题类型
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 7.5.w),
            child: Text(
              "What can we help you with?",
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // 下拉选择框和按钮
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 7.5.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(),
                ),
                SizedBox(width: 5.w),
                GestureDetector(
                  onTap: () {
                    if (logic.selectedOptionId.value >= 0) {
                      // 先移除当前的OverlayEntry，避免泄露
                      _closeDropdown();

                      // 先检查是否存在控制器，如果存在则删除
                      try {
                        if (Get.isRegistered<ReportNextLogic>(
                            tag: 'report_next_logic')) {
                          Get.delete<ReportNextLogic>(tag: 'report_next_logic');
                        }
                      } catch (e) {
                        print('清理控制器时出错: $e');
                      }

                      // 使用独立的实例创建并导航
                      final nextPage = ReportNextPage(key: UniqueKey());
                      Get.to(
                        () => nextPage,
                        arguments: {
                          'email': email,
                          'problemType': logic.selectedOptionText.value,
                          'problemId': logic.selectedOptionId.value
                        },
                        preventDuplicates: true,
                        transition: Transition.rightToLeft,
                      );
                    } else {
                      Get.snackbar("提示", "请选择问题类型",
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  child: Obx(() => Container(
                        width: 40.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: logic.selectedOptionId.value >= 0
                              ? const Color(0xFF007AFF) // 选中状态蓝色
                              : const Color(0xFFD1D1D6), // 未选中状态灰色
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Center(
                          child: Text(
                            "Next",
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 下拉框组件
  Widget _buildDropdown() {
    return Container(
      key: _dropdownKey,
      child: InkWell(
        onTap: () {
          if (_overlayEntry != null) {
            _closeDropdown();
          } else {
            _openDropdown();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          height: 20.h,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => Text(
                      logic.selectedOptionId.value >= 0
                          ? logic.selectedOptionText.value
                          : "I would like to...",
                      style: TextStyle(
                        fontSize: 7.sp,
                        color: logic.selectedOptionId.value >= 0
                            ? Colors.black
                            : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 12.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 打开下拉菜单
  void _openDropdown() {
    // 获取下拉框的位置和大小
    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    // 创建覆盖层条目
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height + 2,
        width: size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0.5,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部选中项(初始占位选项)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                  child: Row(
                    children: [
                      Obx(() => logic.selectedOptionId.value < 0
                          ? Icon(
                              Icons.check,
                              size: 8.sp,
                              color: Colors.black,
                            )
                          : SizedBox(width: 8.sp)),
                      SizedBox(width: 8.w),
                      Text(
                        "I would like to...",
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
                // 选项列表
                ...logic.dropdownOptions.map((option) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: option == logic.dropdownOptions.last
                              ? Colors.transparent
                              : Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          logic.selectOption(option['id'], option['text']);
                          _closeDropdown();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 5.h),
                          child: Row(
                            children: [
                              Obx(() =>
                                  logic.selectedOptionId.value == option['id']
                                      ? Icon(
                                          Icons.check,
                                          size: 8.sp,
                                          color: Colors.black,
                                        )
                                      : SizedBox(width: 8.sp)),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  option['text'],
                                  style: TextStyle(
                                    fontSize: 7.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: null,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );

    // 显示下拉菜单
    Overlay.of(context).insert(_overlayEntry!);

    // 更新状态
    logic.isDropdownOpen.value = true;
  }

  // 关闭下拉菜单
  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      logic.isDropdownOpen.value = false;
    }
  }
}
