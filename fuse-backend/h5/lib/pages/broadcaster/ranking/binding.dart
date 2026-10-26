import 'package:get/get.dart';

import 'logic.dart';

class RankingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RankingLogic());
  }
}
