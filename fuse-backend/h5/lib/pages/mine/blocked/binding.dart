import 'package:get/get.dart';

import 'logic.dart';

class BlockedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BlockedLogic());
  }
}
