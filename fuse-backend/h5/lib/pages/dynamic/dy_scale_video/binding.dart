import 'package:get/get.dart';

import 'logic.dart';

class DyScaleVideoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DyScaleVideoLogic());
  }
}
