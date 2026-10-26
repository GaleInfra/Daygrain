import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';

// 如果是印度用户 ，判断一下当前默认支付方式是否是LP开头， 如果是的话显示 印度本地支付价格
// ，否则如果是官方支付方式显示印度原价，其他支付方式显示美金。
// 显示印度货币的地方有 促销商品价格，普通商品价格，订阅商品价格
// 非印度用户直接显示美金

/// create: 2024/3/7
/// desc: 获取本地化价格
String localPrice(CoinGoodsModel goods, {String? chooseChannel}) {
  //判断审核模式
  if (getAppConfigManager()?.isReviewPkg.value ?? true) {
    String? localPrice = Get.find<CoinGoodsLogic>().payStorePrcMap[goods.code];
    if (localPrice != null) {
      return localPrice;
    }
  }
  chooseChannel ??=
      Get.find<CoinGoodsLogic>().channelExtra?.chooseChannel ?? "";
  if ("IN"
      .contains(Get.find<AppConfigManager>().userInfo.registerCountry ?? "")) {
    if (chooseChannel.startsWith("LP")) {
      return "₹${_handleEnd(goods.localPaymentPriceRupee)}";
    } else if (chooseChannel.startsWith("GP") ||
        chooseChannel.startsWith("IAP")) {
      return "₹${_handleEnd(goods.priceRupee)}";
    } else {
      return "\$${_handleEnd(goods.price)}";
    }
  } else {
    return "\$${_handleEnd(goods.price)}";
  }
}

/// 获取本地化原价
String localOriginalPrice(CoinGoodsModel goods, {String? chooseChannel}) {
  //判断审核模式
  if (getAppConfigManager()?.isReviewPkg.value ?? true) {
    String? localPrice = Get.find<CoinGoodsLogic>().payStorePrcMap[goods.code];
    if (localPrice != null) {
      return localPrice;
    }
  }
  chooseChannel ??=
      Get.find<CoinGoodsLogic>().channelExtra?.chooseChannel ?? "";
  if ("IN"
      .contains(Get.find<AppConfigManager>().userInfo.registerCountry ?? "")) {
    if (chooseChannel.startsWith("LP")) {
      return "₹${_handleEnd(goods.localPayOriginalPrice)}";
    } else if (chooseChannel.startsWith("GP") ||
        chooseChannel.startsWith("IAP")) {
      return "₹${_handleEnd(goods.originalPriceRupee)}";
    } else {
      return "\$${_handleEnd(goods.originalPrice)}";
    }
  } else {
    return "\$${_handleEnd(goods.originalPrice)}";
  }
}

String _handleEnd(num? price) {
  //保留小数点后两位
  return (price ?? 0).toStringAsFixed(2);
}
