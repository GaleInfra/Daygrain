import 'package:get/get.dart';

import 'logic.dart';

class MatchConnectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MatchConnectLogic());
  }
}
