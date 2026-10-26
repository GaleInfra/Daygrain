import 'package:get/get.dart';

import 'logic.dart';

class RobotBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RobotLogic());
  }
}
