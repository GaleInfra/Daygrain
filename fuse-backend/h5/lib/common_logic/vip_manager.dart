import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/vip/vip_subscription_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/utils/toast.dart';

/// create: 2024/1/15
/// desc: VIP订阅服务管理
class VipManager extends GetxController {
  final RequestRepository _repository = Get.find<RequestRepository>();

  // 商品一般只有一个，但是为了后期容易升级，直接做成列表
  final RxList<VipSubscriptionModel> goodsList = RxList<VipSubscriptionModel>();

  // 是否加载中
  final RxBool loading = true.obs;

  // 充值成功event
  StreamSubscription<RechargeSuccessEvent>? _event;

  @override
  void onInit() {
    _event = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      if (event.subscribePay) {
        Toast.showMsg("status_subscriptionSuccess".bhTR);
        // 为订阅支付成功通知，刷新订阅商品
        getGoods();
      }
    });
    super.onInit();
  }

  // 获取商品
  Future getGoods({int retryNum = 0}) async {
    if (retryNum < 5) {
      await _repository.subscriptionSearch(
        onSuccess: (list) {
          goodsList.clear();
          goodsList.addAll(list);
          loading.trigger(false);
          Get.findCanNull<CoinGoodsLogic>()?.checkPayStorePrice(
              goodsList.map((element) => element.code ?? "").toSet() ?? {});
          update();
        },
        onFail: (code, msg) async {
          // 获取失败，重试
          await getGoods(retryNum: ++retryNum);
        },
      );
    }
  }

  @override
  void onClose() {
    _event?.cancel();
    super.onClose();
  }
}
