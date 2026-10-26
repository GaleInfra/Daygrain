import 'package:get/get.dart';

class ReportDetailLogic extends GetxController {
  // 下拉框选项数据
  final RxList<Map<String, dynamic>> dropdownOptions = [
    {'id': 0, 'text': 'Requst a refund'},
    {'id': 1, 'text': 'Report a quality issue'},
    {'id': 2, 'text': 'Report a scam of fraud'},
    {'id': 3, 'text': 'Report offensive, illegal, or abusive content'}
  ].obs;

  // 当前选中的选项
  final RxInt selectedOptionId = (-1).obs;
  final RxString selectedOptionText = "我想要...".obs;
  final RxBool isDropdownOpen = false.obs;

  // 选择选项
  void selectOption(int id, String text) {
    selectedOptionId.value = id;
    selectedOptionText.value = text;
    isDropdownOpen.value = false;
  }

  // 切换下拉框状态
  void toggleDropdown() {
    isDropdownOpen.value = !isDropdownOpen.value;
  }
}
