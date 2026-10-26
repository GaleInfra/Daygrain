import 'package:get/get.dart';

import '../flash_chat/logic.dart';
import 'logic.dart';

class IndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => IndexLogic());
    Get.lazyPut(() => FlashChatLogic());
  }
}
