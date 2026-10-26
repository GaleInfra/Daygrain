import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/available_coins_change.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';

import '../base/socket_listener.dart';

/// create: 2023/5/11
/// desc: 可用余额消息
class AvailableCoinsListener extends SocketListener {
  AvailableCoinsListener._internal();

  static final AvailableCoinsListener _instance =
      AvailableCoinsListener._internal();

  factory AvailableCoinsListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    int coins = data['coins'];

    // 更新用户金币
    Get.find<AppConfigManager>()
        .saveUserInfo(Get.find<AppConfigManager>().userInfo.copyWith(
              availableCoins: coins,
            ));

    EventBusUtil.fire(AvailableCoinsChangeEvent(coins: coins));
  }
}
