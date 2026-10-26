import 'package:get/get.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';

class VipPrivilegesBinding extends Bindings {
  @override
  void dependencies() {
    // 确保 CoinGoodsLogic 已被注入
    if (!Get.isRegistered<CoinGoodsLogic>()) {
      Get.lazyPut<CoinGoodsLogic>(() => CoinGoodsLogic());
    }
  }
}
