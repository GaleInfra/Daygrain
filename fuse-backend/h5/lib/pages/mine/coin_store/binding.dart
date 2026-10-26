import 'package:get/get.dart';

import 'logic.dart';

class CoinStoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CoinStoreLogic());
  }
}
