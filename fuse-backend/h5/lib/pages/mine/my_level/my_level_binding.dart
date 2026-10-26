import 'package:get/get.dart';

import 'my_level_logic.dart';

class MyLevelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MyLevelLogic());
  }
}
