import 'package:get/get.dart';

import 'logic.dart';

class StartMatchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StartMatchLogic());
  }
}
