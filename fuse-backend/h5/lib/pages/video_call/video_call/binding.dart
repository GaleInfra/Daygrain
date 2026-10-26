import 'package:get/get.dart';

import 'logic.dart';

class VideoCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VideoCallLogic());
  }
}
