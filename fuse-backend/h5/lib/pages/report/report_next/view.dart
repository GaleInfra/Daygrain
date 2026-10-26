import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../language/bh_language_manager.dart';
import 'logic.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/pages/index/logic.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/widget/keyboard_listener_widget.dart';

class ReportNextPage extends StatefulWidget {
  const ReportNextPage({Key? key}) : super(key: key);

  @override
  _ReportNextPageState createState() => _ReportNextPageState();
}

class _ReportNextPageState extends State<ReportNextPage> {
  // 使用唯一tag和懒加载方式创建控制器
  late final ReportNextLogic logic;
  // 安全获取email参数，提供默认值
  late final String email;

  // 创建一个全局键，用于定位下拉框
  final GlobalKey _dropdownKey = GlobalKey();
  // 创建一个全局键，用于定位子下拉框
  final GlobalKey _childDropdownKey = GlobalKey();
  // 创建一个Overlay条目
  OverlayEntry? _overlayEntry;
  // 创建一个子选项的Overlay条目
  OverlayEntry? _childOverlayEntry;

  @override
  void initState() {
    super.initState();
    // 在initState中安全地初始化控制器和参数
    try {
      // 尝试获取已经存在的控制器实例，如果没有则创建新的
      logic = Get.find<ReportNextLogic>(tag: 'report_next_logic');
    } catch (e) {
      // 如果找不到控制器，创建一个新的
      logic = Get.put(ReportNextLogic(), tag: 'report_next_logic');
    }

    // 安全获取email参数
    email = _safeGetEmail();
  }

  // 安全获取email的方法
  String _safeGetEmail() {
    try {
      if (Get.arguments != null &&
          Get.arguments is Map &&
          Get.arguments.containsKey('email') &&
          Get.arguments['email'] != null) {
        return Get.arguments['email'];
      }
    } catch (e) {
      print('获取email参数时出错: $e');
    }
    return 'user@example.com'; // 默认值
  }

  @override
  void dispose() {
    // 确保正确关闭Overlay
    if (_overlayEntry != null) {
      _closeDropdown();
    }
    if (_childOverlayEntry != null) {
      _closeChildDropdown();
    }
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

          // 显示所选问题类型和操作
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：上一步选择的问题（标题）
                Obx(() => Text(
                      logic.problemType.value,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )),
                SizedBox(height: 5.h),

                // 第二行：Examples 说明文本
                Text(
                  "Examples: Abusive interactions, hate speech, inappropriate content etc."
                      .bhTR,
                  style: TextStyle(
                    fontSize: 7.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 5.h),

                // 第三行：选择提示文本
                Text(
                  "Select items from your purchase history".bhTR,
                  style: TextStyle(
                    fontSize: 7.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7.5.h),

                // 第四行：按钮（取消和提交）
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 取消按钮
                    Container(
                      width: 35.w,
                      height: 18.h,
                      margin: EdgeInsets.only(right: 4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Center(
                          child: Text(
                            "Cancel".bhTR,
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 提交按钮
                    Obx(() => Container(
                          width: 35.w,
                          height: 18.h,
                          margin: EdgeInsets.only(left: 4.w),
                          decoration: BoxDecoration(
                            color: logic.selectedOptionId.value >= 0 &&
                                    (!logic.hasChildOptions() ||
                                        logic.selectedChildId.value >= 0)
                                ? const Color(0xFF007AFF)
                                : const Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (logic.selectedOptionId.value >= 0 &&
                                  (!logic.hasChildOptions() ||
                                      logic.selectedChildId.value >= 0)) {
                                Get.dialog(
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20.w),
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20.w, vertical: 14.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "thank you for submitting your feedback. we have received your report and will review it",
                                              style: TextStyle(
                                                fontSize: 8.sp,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 16.h),
                                            SizedBox(
                                              width: 80.w,
                                              height: 28.h,
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                          const Color(0xFF007AFF)),
                                                  shape:
                                                      WidgetStateProperty.all(
                                                          RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.r),
                                                  )),
                                                ),
                                                onPressed: () {
                                                  // 跳转到个人中心页面
                                                  Get.offAllNamed(
                                                      RoutePath.indexPage);
                                                  // 切换到底部tab的个人中心
                                                  Future.delayed(
                                                      const Duration(
                                                          milliseconds: 300),
                                                      () {
                                                    final indexLogic = Get
                                                            .isRegistered<
                                                                IndexLogic>()
                                                        ? Get.find<IndexLogic>()
                                                        : null;
                                                    indexLogic
                                                        ?.onChangeIndex(3);
                                                  });
                                                },
                                                child: Text(
                                                  "go back",
                                                  style: TextStyle(
                                                    fontSize: 8.sp,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  barrierDismissible: true,
                                );
                              } else {
                                Get.dialog(
                                  Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w, vertical: 14.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        "please select the issue frequency",
                                        style: TextStyle(
                                          fontSize: 8.sp,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  barrierDismissible: true,
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                "Submit".bhTR,
                                style: TextStyle(
                                  fontSize: 6.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),

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
                      // child: Image.asset(
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

          // 问题频率下拉框
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 7.5.w),
          //   child: Text(
          //     "How often does this issue occur?",
          //     style: TextStyle(
          //       fontSize: 8.sp,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.black,
          //     ),
          //   ),
          // ),

          // SizedBox(height: 4.h),

          // 下拉选择框
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 7.5.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(),
                ),
              ],
            ),
          ),

          // SizedBox(height: 12.h),

          // 子选项下拉框区域
          Obx(() {
            print('子下拉框状态更新: ${logic.showChildDropdown.value}');
            return Visibility(
              visible: logic.showChildDropdown.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  // 子选项标题
                  // Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                  //   child: Text(
                  //     "What is the specific reason?",
                  //     style: TextStyle(
                  //       fontSize: 8.sp,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.black,
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 4.h),
                  // 子选项下拉框
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildChildDropdown(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: 2.h),

          // 判断是否需要显示输入框
          Obx(() {
            if (logic.selectedOptionId.value >= 0 &&
                logic.childOptions.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(height: 1.w),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        borderRadius: BorderRadius.circular(4.r),
                        color: Colors.white,
                      ),
                      child: KeyboardListenerWidget(
                        onKeyboardChanged: (isShow, height) {
                          if (!isShow) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                        child: TextField(
                          controller: logic.textController,
                          maxLines: 5,
                          minLines: 3,
                          maxLength: 1000,
                          style: TextStyle(fontSize: 7.sp, color: Colors.black),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 8.h),
                            border: InputBorder.none,
                            hintText: "Enter example enter example",
                            hintStyle: TextStyle(
                                fontSize: 7.sp, color: Colors.black87),
                            counterText: "",
                          ),
                          onChanged: (val) {
                            logic.updateTextCount(val.length);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Obx(() => Text(
                          "Enter between 5 and 1000 characters: ${logic.textCount.value}/1000",
                          style: TextStyle(
                              fontSize: 7.sp, color: const Color(0xFF1DBF73)),
                        )),
                  ],
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),

          // 提交按钮
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 7.5.w),
          //   child: GestureDetector(
          //     onTap: () {
          //       if (logic.selectedOptionId.value >= 0) {
          //         // 如果有子选项但未选择，提示用户
          //         if (logic.hasChildOptions() &&
          //             logic.selectedChildId.value < 0) {
          //           Get.snackbar("提示".bhTR, "请选择具体原因".bhTR,
          //               snackPosition: SnackPosition.BOTTOM);
          //           return;
          //         }

          //         String message =
          //             "已收到您的举报信息，问题频率: ${logic.selectedOptionText.value}";
          //         if (logic.selectedChildId.value >= 0) {
          //           message += "，具体原因: ${logic.selectedChildText.value}";
          //         }

          //         Get.snackbar("提交成功".bhTR, message,
          //             snackPosition: SnackPosition.BOTTOM);
          //       } else {
          //         Get.snackbar("提示".bhTR, "请先选择问题发生频率".bhTR,
          //             snackPosition: SnackPosition.BOTTOM);
          //       }
          //     },
          //     child: Obx(() => Container(
          //           width: double.infinity,
          //           height: 20.h,
          //           decoration: BoxDecoration(
          //             color: logic.selectedOptionId.value >= 0 &&
          //                     (!logic.hasChildOptions() ||
          //                         logic.selectedChildId.value >= 0)
          //                 ? Color(0xFF007AFF) // 选中状态蓝色
          //                 : Color(0xFFD1D1D6), // 未选中状态灰色
          //             borderRadius: BorderRadius.circular(4.r),
          //           ),
          //           child: Center(
          //             child: Text(
          //               "Submit Report",
          //               style: TextStyle(
          //                 fontSize: 7.sp,
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //           ),
          //         )),
          //   ),
          // ),
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
          height: 24.h,
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
                          : "Tell us more…",
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
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 90.w,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部选中项(初始占位选项)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade200, width: 0.5),
                        ),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
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
                            "Tell us more…",
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
                              try {
                                print('点击选项: ${option['id']}');
                                logic.selectOption(
                                    option['id'], option['text']);
                                _closeDropdown();
                                print('选项设置完成');
                              } catch (e) {
                                print('选择选项时出错: $e');
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 5.h),
                              child: Row(
                                children: [
                                  Obx(() => logic.selectedOptionId.value ==
                                          option['id']
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

  // 子选项下拉框组件
  Widget _buildChildDropdown() {
    return Container(
      key: _childDropdownKey,
      child: InkWell(
        onTap: () {
          if (_childOverlayEntry != null) {
            _closeChildDropdown();
          } else {
            _openChildDropdown();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w),
          height: 24.h,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => Text(
                      logic.selectedChildId.value >= 0
                          ? logic.selectedChildText.value
                          : "Select reason...",
                      style: TextStyle(
                        fontSize: 7.sp,
                        color: logic.selectedChildId.value >= 0
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

  // 关闭子选项下拉菜单
  void _closeChildDropdown() {
    if (_childOverlayEntry != null) {
      _childOverlayEntry!.remove();
      _childOverlayEntry = null;
      logic.isChildDropdownOpen.value = false;
    }
  }

  // 打开子选项下拉菜单
  void _openChildDropdown() {
    // 获取子选项下拉框的位置和大小
    final RenderBox renderBox =
        _childDropdownKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    // 计算内容高度
    double itemHeight = 40.w; // 每项高度，按实际UI调整
    int itemCount =
        logic.childOptions.length + 1; // 选项数+1（包含顶部"Select reason..."）
    double contentHeight = itemHeight * itemCount;
    double dropdownHeight = contentHeight > 140.w ? 140.w : contentHeight;
    int childCount = logic.childOptions.length;
    double top;
    if (childCount > 4) {
      // 显示在上方
      top = position.dy - dropdownHeight - 2;
      if (top < 0) top = 0;
    } else {
      // 显示在下方
      top = position.dy + size.height + 2;
    }

    // 创建子选项覆盖层条目
    _childOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx,
          top: top,
          width: size.width,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: dropdownHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 0.5),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 5.h),
                        child: Row(
                          children: [
                            Obx(() => logic.selectedChildId.value < 0
                                ? Icon(
                                    Icons.check,
                                    size: 8.sp,
                                    color: Colors.black,
                                  )
                                : SizedBox(width: 8.sp)),
                            SizedBox(width: 8.w),
                            Text(
                              "Select reason...",
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
                      ...logic.childOptions.map((option) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: option == logic.childOptions.last
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
                                logic.selectChildOption(
                                    option['id'], option['text']);
                                _closeChildDropdown();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 5.h),
                                child: Row(
                                  children: [
                                    Obx(() => logic.selectedChildId.value ==
                                            option['id']
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
          ),
        );
      },
    );

    // 显示子选项下拉菜单
    Overlay.of(context).insert(_childOverlayEntry!);

    // 更新状态
    logic.isChildDropdownOpen.value = true;
  }
}
