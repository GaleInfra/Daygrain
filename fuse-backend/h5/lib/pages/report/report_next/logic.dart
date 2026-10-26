import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ReportNextLogic extends GetxController {
  // 接收上一页传递的问题类型，提供默认值防止错误
  final RxString problemType = 'Unknown issue'.obs;
  final RxInt problemId = (-1).obs;

  // 下拉框选项数据
  final RxList<Map<String, dynamic>> dropdownOptions = [
    {
      'id': 0,
      'text': 'Report an issue with the App Store',
      'child': [
        // {'id': 0, 'text': 'For what reason…'},
        {'id': 1, 'text': 'App was not found in search result'},
        {'id': 2, 'text': 'Other'},
      ]
    },
    {
      'id': 1,
      'text': 'Report an issue with an app',
      'child': [
        // {'id': 0, 'text': 'For what reason…'},
        {'id': 1, 'text': 'An app force me to leave a 5-star review'},
        {'id': 2, 'text': 'A virus alert or ad said my device was hacked'},
        {'id': 3, 'text': 'I was pressured into downloading an app'},
        {'id': 4, 'text': 'Inappropriate app icon'},
        {'id': 5, 'text': 'Misleading claims about app functionality'},
        {'id': 6, 'text': 'Other'},
      ]
    },
    {
      'id': 2,
      'text': 'Report a financial issue',
      'child': [
        // {'id': 0, 'text': 'For what reason…'},
        {'id': 1, 'text': 'I did not receive the content I purchased'},
        {'id': 2, 'text': 'Cryptocurrency scam'},
        {
          'id': 3,
          'text': 'I purchased an app, but it not no longer being updated'
        },
        {'id': 4, 'text': 'I was pressured into purchasing an app'},
        {'id': 5, 'text': 'Other'},
      ]
    },
    {
      'id': 3,
      'text': 'Report misleading charges',
      'child': [
        // {'id': 0, 'text': 'For what reason…'},
        {'id': 1, 'text': 'I was pressured into making an in-app purchase'},
        {'id': 2, 'text': 'I was charged directly by the app developer'},
        {'id': 3, 'text': 'Other'},
      ]
    },
    {
      'id': 4,
      'text': 'Report a privacy concern',
      'child': [
        // {'id': 0, 'text': 'For what reason…'},
        {'id': 1, 'text': 'The app use my information without permission'},
        {'id': 2, 'text': 'App Privacy information is incorrect'},
        {'id': 3, 'text': 'Other'},
      ]
    },
    // {'id': 5, 'text': 'Describe the Issue'},
    // {'id': 6, 'text': '! Enter between 5 and 1000 characters: 0/5    9/1000'},
  ].obs;

  // 当前选中的选项
  final RxInt selectedOptionId = (-1).obs;
  final RxString selectedOptionText = "Tell us more…".obs;
  final RxBool isDropdownOpen = false.obs;

  // 子选项相关状态
  final RxBool showChildDropdown = false.obs; // 是否显示子选项下拉框
  final RxList<Map<String, dynamic>> childOptions =
      <Map<String, dynamic>>[].obs; // 当前子选项数据
  final RxInt selectedChildId = (-1).obs; // 选中的子选项ID
  final RxString selectedChildText = "For what reason…".obs; // 选中的子选项文本
  final RxBool isChildDropdownOpen = false.obs; // 子下拉框是否打开

  // 新增：文本输入相关
  final TextEditingController textController = TextEditingController();
  final RxInt textCount = 0.obs;
  void updateTextCount(int count) {
    textCount.value = count;
  }

  // 选择选项
  void selectOption(int id, String text) {
    try {
      // 基本状态更新
      selectedOptionId.value = id;
      selectedOptionText.value = text;
      isDropdownOpen.value = false;

      // 重置子选项状态
      selectedChildId.value = -1;
      selectedChildText.value = "For what reason…";

      // 简化子选项设置逻辑
      print('准备设置子选项');
      for (var option in dropdownOptions) {
        if (option['id'] == id) {
          if (option.containsKey('child') &&
              option['child'] is List &&
              option['child'].isNotEmpty) {
            print('找到子选项');
            childOptions.clear();
            childOptions
                .addAll(List<Map<String, dynamic>>.from(option['child']));
            showChildDropdown.value = true;
          } else {
            childOptions.clear();
            showChildDropdown.value = false;
          }
          break;
        }
      }
    } catch (e) {
      print('选择选项时出错: $e');
      // 出错时重置状态
      childOptions.clear();
      showChildDropdown.value = false;
    }
  }

  // 切换下拉框状态
  void toggleDropdown() {
    isDropdownOpen.value = !isDropdownOpen.value;
    if (isChildDropdownOpen.value) {
      isChildDropdownOpen.value = false;
    }
  }

  // 切换子下拉框状态
  void toggleChildDropdown() {
    isChildDropdownOpen.value = !isChildDropdownOpen.value;
    if (isDropdownOpen.value) {
      isDropdownOpen.value = false;
    }
  }

  // 选择子选项
  void selectChildOption(int id, String text) {
    selectedChildId.value = id;
    selectedChildText.value = text;
    isChildDropdownOpen.value = false;
  }

  // 检查当前选项是否有子选项
  bool hasChildOptions() {
    try {
      return childOptions.isNotEmpty;
    } catch (e) {
      print('检查子选项时出错: $e');
      return false;
    }
  }

  // 显示子选项下拉框
  void showChildDropdownSection() {
    try {
      print('尝试显示子下拉框');
      showChildDropdown.value = true;
      print('子下拉框状态设置完成');
    } catch (e) {
      print('显示子下拉框时出错: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // 安全地从参数中获取问题类型
    try {
      if (Get.arguments != null && Get.arguments is Map) {
        if (Get.arguments.containsKey('problemType') &&
            Get.arguments['problemType'] != null) {
          problemType.value = Get.arguments['problemType'];
        }
        if (Get.arguments.containsKey('problemId') &&
            Get.arguments['problemId'] != null) {
          problemId.value = Get.arguments['problemId'];
        }
      }
    } catch (e) {
      print('初始化ReportNextLogic时出错: $e');
      // 使用默认值继续
    }
  }

  // 确保在页面销毁时清理资源
  @override
  void onClose() {
    textController.dispose();
    super.onClose();
    print('ReportNextLogic已销毁');
  }
}
