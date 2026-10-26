import 'package:get/get.dart';

import 'logic.dart';

class CallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CallLogic());
  }
}
