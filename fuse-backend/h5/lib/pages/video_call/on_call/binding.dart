import 'package:get/get.dart';

import 'logic.dart';

class OnCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OnCallLogic());
  }
}
