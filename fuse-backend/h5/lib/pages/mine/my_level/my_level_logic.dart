import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/model/user/user_level_model.dart';

class MyLevelLogic extends GetBaseController {
  // 用户等级信息
  UserLevelModel? levelModel;

  // 空表或当前等级不在表里时不要用 last/first，否则 Release 会整页变灰。
  int? _coinsAt(int level) {
    final list = levelModel?.userLevelList;
    if (list == null) return null;
    for (final row in list) {
      if (row.level == level) return row.rechargedCoins;
    }
    return null;
  }

  // 当前是否最高级
  bool get maxLevel {
    final list = levelModel?.userLevelList;
    if (list == null || list.isEmpty) return false;
    return levelModel?.level == list.last.level;
  }

  int get currentCoin => _coinsAt(levelModel?.level ?? 0) ?? 0;

  // 下一等级
  int get nextLevel {
    if (maxLevel) {
      return levelModel?.userLevelList?.last.level ?? 10;
    }
    return (levelModel?.level ?? 0) + 1;
  }

  // 下一等级金币
  int get nextCoins {
    if (maxLevel) {
      // 最高等级，返回当前已充值金币已充满进度条
      return levelModel?.rechargedCoins ?? 0;
    }
    return _coinsAt(nextLevel) ?? levelModel?.rechargedCoins ?? 0;
  }

  // 通知充值成功
  late StreamSubscription<RechargeSuccessEvent> _event;

  @override
  void onInit() {
    super.onInit();
    logHandle.initLog('my_level');
    changeLoading();
    // 刷新用户数据
    Get.find<AppConfigManager>().onGetInfo();
    _getLevel();
    _event = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      // 充值成功，刷新当前数据
      _getLevel();
    });
  }

  @override
  void onClose() {
    _event.cancel();
  }

  Future _getLevel() async {
    await request.getLevelInfo(
      onSuccess: (data) {
        levelModel = data;
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }
}
