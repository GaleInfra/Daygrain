import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../res/image_assets.dart'; // Assuming ImageAssets is here
// Import MyGaps
import '../../config/route.dart'; // 导入路由配置
import 'logic.dart'; // Import Task model

import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/widget/dialog/lock_countdown_dialog.dart';
import 'package:untitled1/utils/privacy_mode_util.dart'; // 导入隐私模式工具类
import 'package:untitled1/js/rc_manager_js.dart';
import '../../utils/device_util.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/mine/logic.dart';

class CPage extends StatefulWidget {
  const CPage({Key? key}) : super(key: key);

  @override
  State<CPage> createState() => _CPageState();
}

void reportSwitchClick() {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";
  getReqRepo()?.log(
    event: "click",
    page: "privacy_mode_tab_switch",
    terPage: payStatusTag,
  );
}

void reportBackClick() {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";
  getReqRepo()?.log(
    event: "click",
    page: "privacy_mode_exit_click",
    terPage: payStatusTag,
  );
}

// 上报退出隐私模式时的停留时长
void reportExitDuration(int durationMs) {
  // 获取MineLogic实例以获取用户付费状态
  final mineLogic =
      Get.isRegistered<MineLogic>() ? Get.find<MineLogic>() : null;

  // 获取付费状态标识
  final payStatusTag = mineLogic?.userPaidStatusForLog ?? "notPaidUser";
  // 计算分钟数和秒数
  final minutes = (durationMs / 60000).floor();
  final seconds = ((durationMs % 60000) / 1000).floor();
  final formattedTime = "${minutes}m${seconds}s";

  getReqRepo()?.log(
    event: "pv",
    page: "privacy_mode_stay_duration",
    duration: durationMs,
    terPage: payStatusTag,
  );
}

class _CPageState extends State<CPage> {
  final logic = Get.put(CPageLogic());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        JSRongCloudManager.dismissLoading();
        // 显示新的隐私模式弹窗
        PrivacyModeUtil.showPrivacyModeDialogNew(context);
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部安全高度
            Container(
              height: DeviceUtil().statusBarHeight ?? 0,
              color: Colors.black,
            ),
            Expanded(
              child: Obx(() {
                // 显示安全页面
                if (logic.showSafePageFlag.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          ImageAssets.defert1, // 安全图标
                          width: 23.w,
                          height: 23.w,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 15.h),
                        InkWell(
                          onTap: () async {
                            reportBackClick();
                            // 退出隐私模式，将isPrivate设置为false
                            await PrivacyModeManager.setPrivacyMode(false);

                            // 计算并上报停留时长
                            final duration = await PrivacyModeManager
                                .getPrivacyModeDuration();
                            reportExitDuration(duration);

                            // 更新视频通话监听状态
                            if (Get.isRegistered<VideoCallHandler>()) {
                              await Get.find<VideoCallHandler>()
                                  .updateListenerByPrivacyMode();
                            }
                            // 跳转到首页
                            Get.offAllNamed(RoutePath.indexPage);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5D0),
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            child: Text(
                              'Back to home',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 原有内容
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 12.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Timer
                            SizedBox(
                              width: 130.w,
                              height: 130.w,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipOval(
                                    child: Image.asset(
                                      ImageAssets.yuanpan,
                                      width: 165.w,
                                      height: 165.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Obx(() {
                                    final minutes =
                                        (logic.remainingSeconds.value ~/ 60)
                                            .toString()
                                            .padLeft(2, '0');
                                    final seconds =
                                        (logic.remainingSeconds.value % 60)
                                            .toString()
                                            .padLeft(2, '0');
                                    return Text(
                                      '$minutes:$seconds',
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Reset 按钮
                                Container(
                                  width: 70.w,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: ElevatedButton(
                                    onPressed: () => logic.resetTimer(),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.w),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            Colors.grey.shade600
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.w),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        constraints: BoxConstraints(
                                          minHeight: 24.h,
                                        ),
                                        child: Text(
                                          'action_reset'.bhTR,
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Begin 按钮
                                Container(
                                  width: 70.w,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: ElevatedButton(
                                    onPressed: () => logic.startTimer(),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.w),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple,
                                            Colors.blueAccent
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.w),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        constraints: BoxConstraints(
                                          minHeight: 24.h,
                                        ),
                                        child: Text(
                                          'action_begin'.bhTR,
                                          style: TextStyle(
                                            fontSize: 8.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              }),
            ),

            // 底部Tab栏
            Container(
              color: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Row(
                children: [
                  // 左侧Tab - 时间
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        logic.toggleTab(0);
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 30.h,
                        child: Center(
                          child: Obx(() => Image.asset(
                                logic.selectedTab.value == 0
                                    ? ImageAssets.time
                                    : ImageAssets.time1,
                                width: 14.w,
                                height: 14.w,
                                fit: BoxFit.contain,
                              )),
                        ),
                      ),
                    ),
                  ),
                  // 右侧Tab - 锁定
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        logic.toggleTab(1);
                        showLockCountdownDialog(context);
                        reportSwitchClick();
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 30.h,
                        child: Center(
                          child: Obx(() => Image.asset(
                                logic.selectedTab.value == 1
                                    ? ImageAssets.lock1
                                    : ImageAssets.lock,
                                width: 14.w,
                                height: 14.w,
                                fit: BoxFit.contain,
                              )),
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

// New Stateful widget for editable task items
class EditableTaskItem extends StatefulWidget {
  final Task task;
  final int index;
  final CPageLogic logic;

  const EditableTaskItem({
    Key? key,
    required this.task,
    required this.index,
    required this.logic,
  }) : super(key: key);

  @override
  _EditableTaskItemState createState() => _EditableTaskItemState();
}

class _EditableTaskItemState extends State<EditableTaskItem> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.task.name);
    _textController.addListener(() {
      widget.logic.updateTaskName(widget.index, _textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Editable Task Name
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(fontSize: 8.sp, color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              widget.logic.toggleTaskChecked(widget.index);
            },
            child: Icon(
              widget.task.isChecked
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: widget.task.isChecked
                  ? Colors.cyanAccent
                  : Colors.grey.shade600,
              size: 12.w,
            ),
          ),
        ],
      ),
    );
  }
}
