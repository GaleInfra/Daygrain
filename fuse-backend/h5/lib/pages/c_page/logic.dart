import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/net/request_repository.dart';

// Task 数据模型
class Task {
  String name;
  bool isChecked;

  Task({required this.name, this.isChecked = false});
}

class CPageLogic extends GetxController {
  // 任务列表
  final tasks = <Task>[].obs;

  // 选中的Tab
  final selectedTab = 0.obs;

  // 计时器控制
  final isRunning = false.obs;
  final remainingSeconds = 1500.obs; // 25分钟 = 1500秒
  Timer? _timer;

  // 安全页面标志
  final showSafePageFlag = false.obs;

  // 记录隐私模式进入时间
  int enterTimestamp = 0;

  @override
  void onInit() {
    super.onInit();
    // 初始化任务列表
    tasks.assignAll([
      Task(name: 'Focus on work'),
      Task(name: 'Read documents'),
      Task(name: 'Complete project'),
    ]);

    // 异步初始化进入时间
    _initEnterTime();
  }

  // 初始化进入时间
  Future<void> _initEnterTime() async {
    enterTimestamp = await PrivacyModeManager.getEnterTime();
  }

  // 开始计时器
  void startTimer() {
    if (!isRunning.value) {
      isRunning.value = true;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainingSeconds.value > 0) {
          remainingSeconds.value--;
        } else {
          stopTimer();
        }
      });
    } else {
      stopTimer();
    }
  }

  // 停止计时器
  void stopTimer() {
    _timer?.cancel();
    isRunning.value = false;
  }

  // 重置计时器
  void resetTimer() {
    stopTimer();
    remainingSeconds.value = 1500; // 重置为25分钟
  }

  // 切换Tab
  void toggleTab(int tabIndex) {
    if (tabIndex == 1) {
      // 切换到安全页面
      showSafePageFlag.value = true;
    } else {
      // 切换到计时器页面
      showSafePageFlag.value = false;
    }
    selectedTab.value = tabIndex;
  }

  // 添加新任务
  void addTask(String name) {
    if (name.trim().isNotEmpty) {
      tasks.add(Task(name: name));
    }
  }

  // 删除任务
  void removeTask(int index) {
    if (index >= 0 && index < tasks.length) {
      tasks.removeAt(index);
    }
  }

  // 切换任务完成状态
  void toggleTaskChecked(int index) {
    if (index >= 0 && index < tasks.length) {
      tasks[index].isChecked = !tasks[index].isChecked;
      tasks.refresh();
    }
  }

  // 更新任务名称
  void updateTaskName(int index, String newName) {
    if (index >= 0 && index < tasks.length) {
      tasks[index].name = newName;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
