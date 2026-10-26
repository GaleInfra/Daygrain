import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';

import '../../../common_logic/coin_goods_logic.dart';

class CoinStoreLogic extends GetBaseController {
  /// 商品/促销商品管理
  final coinGoodsLogic = Get.find<CoinGoodsLogic>();

  final appConfig = Get.find<AppConfigManager>();
  @override
  void onInit() {
    super.onInit();
    logHandle.initLog('recharge');
  }
  @override
  void onReady() {
    if (coinGoodsLogic.list.isEmpty) {
      changeLoading();
    } else {
      changeSuccess();
    }
    _getUserCoin();
    _getCoinGoodsSearch();
    super.onReady();
  }

  /// 刷新用户金币
  Future _getUserCoin() async {
    await request.userGetCoins(
      userId: appConfig.userInfo.userId ?? "",
      showLoading: false,
      onSuccess: (coin) {
        appConfig.saveUserInfo(appConfig.userInfo.copyWith(
          availableCoins: coin,
        ));
      },
      onFail: (code, msg) {},
    );
  }

  /// 获取商品列表
  Future _getCoinGoodsSearch() async {
    // 获取新用户促销商品，获取成功后会自动刷新列表
    coinGoodsLogic.getCoinPromotion();
    // 获取商品列表
    coinGoodsLogic.getCoinGoodsSearch(
      onSuccess: (data) {
        // 刷新状态，不持有list数据
        if (data.isEmpty) {
          changeEmpty();
        } else {
          changeSuccess();
        }
      },
      onFail: (code, msg) {
        if (coinGoodsLogic.list.isEmpty) {
          // 仅当无金币列表数据时显示错误状态，否则显示旧金币数据
          onChangeError(code, msg);
        }
      },
    );
    update();
  }

  /// 购买
  Future onPay(CoinGoodsModel item) async {
    await coinGoodsLogic.onPay(
      model: item,
      goodsType: item.goodsId == coinGoodsLogic.specialOfferModel?.goodsId ? GoodsType.promotion : GoodsType.normal,
      entry: PayEntry.SOURCE_2,
    );
  }
}
