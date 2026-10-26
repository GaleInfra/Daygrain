import 'package:get/get.dart';

import 'logic.dart';

class SeeVideoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SeeVideoLogic());
  }
}
