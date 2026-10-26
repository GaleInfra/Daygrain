import 'package:get/get.dart';

import 'logic.dart';

class ModifyInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ModifyInfoLogic());
  }
}
