import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/banner_strong_guide_logic.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/model/user/user_info_model.dart'; // 添加引用
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/broadcaster/widget/promotion_dialog.dart';
import 'package:untitled1/pages/broadcaster/widget/special_offer_dialog.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/res/my_keys.dart'; // 导入常量

import '../event_bus/app_lifecycle_state_event.dart';
import '../model/pay/coin_pay_channel_model.dart';
import '../net/base/response_parse.dart';
import '../utils/bh_platform.dart';
import '../language/bh_language_manager.dart';
import 'app_config_manager.dart';
import 'pay_bridge.dart';
import 'pay_handler.dart';

/// create: 2023/5/16
/// desc: 商品、购买管理（包括促销商品）
class CoinGoodsLogic extends GetxController {
  // 常量定义
  static const int VIP_MONTH_SUB_TYPE = 101; // 月会员的subType值
  static const int VIP_WEEK_SUB_TYPE = 103; // 周会员的subType值

  final _request = Get.find<RequestRepository>();
  //导量
  final strongGuide = Get.find<BannerStrongGuideLogic>();

  /// 新用户促销商品
  CoinGoodsModel? promotionModel;

  /// 活动促销数据
  CoinGoodsModel? specialOfferModel;

  /// 商品列表
  final List<CoinGoodsModel> list = [];

  /// VIP商品列表 (subType=101的商品)
  final List<CoinGoodsModel> vipList = [];

  /// 是否有VIP商品可显示
  final RxBool hasVipProducts = false.obs;

  /// 标记最便宜的两个无折扣商品ID（这些商品拥有全部支付渠道）
  final List<String> fullChannelProductIds = <String>[];

  /// 与 [getCoinGoodsSearch] 一致：会员档看 [CoinGoodsModel.isVipTerm]
  /// （validity 非空、validDays>0 或 exchangeDays>0），不进金币商店列表。
  static List<CoinGoodsModel> filterNonVipCoinGoods(Iterable<CoinGoodsModel> source) {
    return source
        .where((item) => !item.isVipTerm && item.code != "-1")
        .toList();
  }

  /// 槽位没有可购买 code 时，改用 vipList 里第一件会员商品。
  /// exchangeDays>0 与 validDays>0、validity 非空同等可买。
  CoinGoodsModel? resolveVipPurchase(CoinGoodsModel? selected) {
    if (selected != null && (selected.code ?? '').isNotEmpty) {
      return selected;
    }
    for (final item in vipList) {
      if (item.isVipTerm && (item.code ?? '').isNotEmpty) {
        return item;
      }
    }
    return selected;
  }

  List<CoinGoodsModel> get listData {
    // // 筛选出最便宜的两个无折扣商品
    // filterSpecialFullChannelProducts();

    if (strongGuide.strongGuideModel.value != null) {
      var listNew = List<CoinGoodsModel>.from(list);
      listNew.add(CoinGoodsModel(code: "-1"));

      return listNew;
    }

    return list;
  }

  /// 充值渠道列表
  final List<ChannelList> channelList = [];

  /// 新用户促销剩余倒计时
  final promotionSurplusTime = const Duration(milliseconds: 0).obs;

  /// 新版活动促销剩余倒计时
  final specialOfferSurplusTime = const Duration(milliseconds: 0).obs;

  ///
  final appConfig = Get.find<AppConfigManager>();

  /// 支付管理
  final payLogic = Get.find<PayHandler>();

  // 充值成功通知
  late StreamSubscription<RechargeSuccessEvent> _event;

  // 等待渠道列表刷新成功再显示渠道弹窗
  bool _forceAwait = true;

  // 渠道扩展数据
  ChannelExtra? channelExtra;

  Timer? _timer;

  //app生命周期监听
  late StreamSubscription<AppLifecycleStateEvent> _appLifecycleStateEvent;
  // EventBusUtil.fire<AppLifecycleStateEvent>(AppLifecycleStateEvent(state));
  final payStorePrcMap = <String, String>{}.obs;
  // 获取商品价格
  Future<void> checkPayStorePrice(Set<String> codeSet) async {
    if (!(getAppConfigManager()?.isReviewPkg.value ?? true)) {
      ///非审核模式不显示本地化价格
      return;
    }
    if (kIsWeb) {
      return;
    }

    // if (codeSet.isNotEmpty) {
    //   try {
    //     final storeDetails = await InAppPurchase.instance.queryProductDetails(codeSet);
    //     if (storeDetails.notFoundIDs.isNotEmpty) {
    //       // 未找到商品
    //       return;
    //     }
    //     var map = payStorePrcMap.value;
    //     // 缓存当前goodsCode对应的价格
    //     for (var element in storeDetails.productDetails) {
    //       //获取本地价格
    //       map[element.id] = element.price;
    //     }
    //     payStorePrcMap.value = map;
    //     return;
    //   } catch (e) {}
    // }
  }

  @override
  void onReady() {
    _appLifecycleStateEvent =
        EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        // 应用程序从后台切换到前台--全部更新
        getCoinPayChannelGet(forceAwait: true);
        getCoinSpecialOffer();
        getCoinPromotion();
        getCoinGoodsSearch(bindPage: false);
      }
    });
    // 监听倒计时每次改变
    ever(promotionSurplusTime, (callback) {
      if (promotionSurplusTime.value.inMilliseconds == 0) {
        // 倒计时结束
        onPromotionDone();
      }
    });
    ever(specialOfferSurplusTime, (callback) {
      if (specialOfferSurplusTime.value.inMilliseconds == 0) {
        // 倒计时结束
        onSpecialOfferDone();
      }
    });
    ever(payLogic.paySuccessGoodsCode, (callback) async {
      // 监听每次支付的改变
      final successCode = payLogic.paySuccessGoodsCode.value;

      if (successCode == promotionModel?.code) {
        // 支付成功商品编号 与 新用户促销商品编号一致，说明购买的是新用户促销商品
        onPromotionDone();
      } else if (successCode == specialOfferModel?.code) {
        // 支付成功商品编号 与 活动促销商品编号一致，说明购买的是活动促销商品
        // 已充值次数需要加1
        specialOfferModel?.rechargeNum =
            (specialOfferModel?.rechargeNum ?? 0) + 1;
        if (specialOfferModel?.rechargeNum ==
            specialOfferModel?.capableRechargeNum) {
          // 若已充值次数与可充值次数相等，则关闭悬浮窗
          onSpecialOfferDone();
        }
        // 同时直接刷新
        getCoinSpecialOffer();
      } else {
        // 检查是否购买了VIP商品
        final vipItem = vipList.firstWhere((item) => item.code == successCode,
            orElse: () => CoinGoodsModel());

        // 如果找到了对应的VIP商品
        if (vipItem.code != null) {
          String membershipType =
              vipItem.subType == VIP_WEEK_SUB_TYPE ? "周会员" : "VIP会员";
          print("\n======== 购买${membershipType}成功 ========");
          print("商品代码: ${vipItem.code}");
          print(
              "${membershipType}有效期: ${vipItem.validity} ${vipItem.validityUnit}");
          print("======== 购买${membershipType}结束 ========\n");
        }
      }
    });
    _event = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      // 充值成功刷新
      // 刷新渠道列表，充值成功后列表赠送比例不同，所以要强制刷新
      getCoinPayChannelGet(forceAwait: true);
      getCoinSpecialOffer();
      getCoinPromotion();
      getCoinGoodsSearch(bindPage: false);

      // 强制刷新用户信息
      appConfig.onGetInfo();

      // 打印是否是VIP订阅支付
      print("\n======== 充值成功事件 ========");
      print("是否是VIP订阅支付: ${event.subscribePay}");
      print("======== 充值成功事件结束 ========\n");
    });
    super.onReady();
  }

  @override
  void onClose() {
    _event.cancel();
    _timer?.cancel();
    _appLifecycleStateEvent.cancel();
    super.onClose();
  }

  void _onCreateTimer() {
    if (promotionModel != null || specialOfferModel != null) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (promotionSurplusTime.value.inSeconds > -1) {
          promotionSurplusTime.trigger(
              Duration(seconds: promotionSurplusTime.value.inSeconds - 1));
          if (promotionSurplusTime.value.inSeconds == 0) {
            onPromotionDone();
          }
        }
        if (specialOfferSurplusTime.value.inSeconds > -1) {
          specialOfferSurplusTime.trigger(
              Duration(seconds: specialOfferSurplusTime.value.inSeconds - 1));
          if (specialOfferSurplusTime.value.inSeconds == 0) {
            onSpecialOfferDone();
          }
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// 新用户促销倒计时
  void onPromotionTime(Duration duration) {
    promotionSurplusTime.value = duration;
  }

  /// 新用户促销商品倒计时完成
  void onPromotionDone() {
    // 从商品列表中删除促销商品
    list.removeWhere((element) => element.goodsId == promotionModel?.goodsId);
    promotionModel = null;
    promotionSurplusTime.value = const Duration(milliseconds: 0);
    DialogUtil.dismiss(tag: PromotionDialog.tag);
    update();
    _onCreateTimer();
  }

  /// 活动促销倒计时完成
  void onSpecialOfferDone() {
    specialOfferModel = null;
    specialOfferSurplusTime.value = const Duration(milliseconds: 0);
    SpecialOfferDialog.dismiss();
    update();
    _onCreateTimer();
  }

  /// 获取新用户促销
  Future getCoinPromotion(
      {CancelToken? cancelToken, int retryCount = 3}) async {
    bool isError = false;
    await _request.coinGetPromotion(
      cancelToken: cancelToken,
      onSuccess: (data) {
        if (data == null) {
          onPromotionDone();
        } else {
          promotionModel = CoinGoodsModel.fromJson(data.toJson());
          promotionSurplusTime.value = Duration(
              milliseconds:
                  int.parse(data.surplusMillisecond?.toString() ?? "0"));
          if (promotionModel != null) {
            checkPayStorePrice({promotionModel!.code ?? ""});
            // 若有促销商品数据，则添加进列表
            int index = list.indexWhere(
                (element) => element.goodsId == promotionModel?.goodsId);
            if (index != -1) {
              list.removeAt(index);
            }
            // 放入第一位
            list.insert(0, promotionModel!);
          }
        }
        update();
        _onCreateTimer();
      },
      onFail: (code, msg) {
        isError = true;
      },
    );
    if (isError && retryCount > 0) {
      await getCoinPromotion(retryCount: retryCount - 1);
    }
  }

  /// 获取商品列表
  Future getCoinGoodsSearch({
    bool bindPage = true,
    bool showLoading = false,
    CancelToken? cancelToken,
    Success<List<CoinGoodsModel>>? onSuccess,
    Fail? onFail,
  }) async {
    await _request.coinGoodsSearch(
      bindPage: bindPage,
      showLoading: showLoading,
      isIncludeSubscription: true, // 修改为true以包含订阅商品
      cancelToken: cancelToken,
      onSuccess: (data) {
        // 清空原有数据
        list.clear();
        vipList.clear(); // 清空VIP列表

        if (promotionModel != null) {
          // 若有促销商品数据，则添加进普通商品列表
          list.insert(0, promotionModel!);
        }

        for (var item in data) {
          // 根据subType区分VIP商品和普通金币商品
          if (item.isVipTerm) {
            // VIP：validity 非空、validDays>0 或 exchangeDays>0
            vipList.add(item);
          } else {
            // 去重，为了避免促销商品重复
            if (list.indexWhere((element) => element.goodsId == item.goodsId) ==
                -1) {
              list.add(item);
            }
          }
        }

        // 更新是否有VIP商品的标志 - 只有在有VIP商品且用户没有VIP权益时才显示入口
        hasVipProducts.value = vipList.isNotEmpty && !hasVipEquity();

        // 打印详细数据信息
        _printCoinGoodsData(data);
        _printVipData();

        checkPayStorePrice(Set.from(
            [...list.map((e) => e.code), ...vipList.map((e) => e.code)]));
        // filterSpecialFullChannelProducts();
        update();
        onSuccess?.call(list); // 仍然返回普通商品列表，保持兼容性
      },
      onFail: (code, msg) {
        onFail?.call(code, msg);
      },
    );
  }

  /// 打印金币商品数据
  void _printCoinGoodsData(List<CoinGoodsModel> data) {
    print("\n======== 金币商品数据开始 ========");
    print("商品总数: ${data.length}");
    print("普通金币商品数: ${list.length}");
    print("VIP商品数: ${vipList.length}");
    print("======== 金币商品数据结束 ========\n");
  }

  /// 打印VIP商品数据
  void _printVipData() {
    if (vipList.isEmpty) {
      print("【没有VIP商品数据】");
      return;
    }

    print("\n======== VIP商品数据开始 ========");
    print("VIP商品数量: ${vipList.length}");

    for (var i = 0; i < vipList.length; i++) {
      final item = vipList[i];
      final membershipType = item.subType == 103 ? "周会员" : "VIP会员";

      print("$membershipType商品 #${i + 1}:");
      print("  商品ID: ${item.goodsId}");
      print("  商品代码: ${item.code}");
      print("  subType: ${item.subType}");
      print("  价格: ${item.price}");
      print("  有效期: ${item.validity} ${item.validityUnit}");
      print("  validDays: ${item.validDays} exchangeDays: ${item.exchangeDays}");
      print("  赠送金币: ${item.exchangeCoin}");
      if (item.extraCoin != null && item.extraCoin! > 0) {
        print("  额外金币: ${item.extraCoin}");
      }
    }

    print("======== VIP商品数据结束 ========\n");
  }

  /// 活动促销
  Future getCoinSpecialOffer() async {
    await _request.coinSpecialOffer(
      onSuccess: (data) {
        if (data == null) {
          onSpecialOfferDone();
        } else {
          specialOfferSurplusTime.value = Duration(
              milliseconds:
                  int.parse(data.remainMilliseconds?.toString() ?? "0"));
          specialOfferModel = data;
          if (specialOfferModel != null) {
            checkPayStorePrice({specialOfferModel!.code ?? ""});
          }
          update();
        }
        _onCreateTimer();
      },
      onFail: (code, msg) {
        onSpecialOfferDone();
      },
    );
  }

  /// 获取充值渠道
  /// 刷新时机：进入App，充值完成
  /// [forceRef] 强制等待列表刷新
  Future getCoinPayChannelGet({bool forceAwait = false}) async {
    _forceAwait = forceAwait;
    await _request.coinPayChannelGet(
      showLoading: false,
      onSuccess: (data) async {
        _forceAwait = false;
        channelExtra = data.extra;
        var list = data.channelList ?? [];
        if (list.isNotEmpty) {
          //过滤原生支付 IPA GP
          // list = list
          //     .where((element) =>
          //         !(element.payChannel?.startsWith("GP") ?? false) &&
          //         !(element.payChannel?.startsWith("IAP") ?? false))
          //     .toList();
        }
        channelList.clear();
        channelList.addAll(list);
        update();
      },
      onFail: (code, msg) async {},
    );
  }

  // /// 筛选出最便宜的两个无折扣商品并标记为有全部支付渠道的产品
  // void filterSpecialFullChannelProducts() {
  //   fullChannelProductIds.clear();

  //   // 筛选出 code 不为 "-1" 且 discount 为 0 的商品
  //   final filteredList = list.where((item) => item.code != "-1").toList();

  //   // 按价格排序（从低到高）
  //   filteredList.sort((a, b) {
  //     final priceA = double.tryParse(a.price?.toString() ?? "0") ?? 0;
  //     final priceB = double.tryParse(b.price?.toString() ?? "0") ?? 0;
  //     return priceA.compareTo(priceB);
  //   });

  //   // 取最便宜的前两个商品ID
  //   for (int i = 0; i < filteredList.length; i++) {
  //     if (filteredList[i].goodsId != null && (filteredList[i].price ?? 0) <= 9.99) {
  //       fullChannelProductIds.add(filteredList[i].goodsId!);
  //     }
  //   }
  // }

  // /// 判断商品是否属于拥有全部支付渠道的特殊商品
  // bool hasFullPaymentChannels(CoinGoodsModel model) {
  //   return fullChannelProductIds.contains(model.goodsId);
  // }

  /// 购买
  /// [model] 商品数据
  /// [source] 充值邀请码，主播邀请链接，活动商品等特殊附带赠送比例的需要传
  /// [invitationRecharge] 是否为邀请充值，如果是邀请充值，原生支付要有+10%的字样
  Future onPay({
    required CoinGoodsModel model,
    required GoodsType goodsType,
    required String entry,
    String? robotUserId,
  }) async {
    throttleUtil.throttle(() async {
      if (appConfig.isReviewPkg.value) {
        // 审核模式，直接走原生支付
        await _onGpOrIapPay(model, entry);
        return;
      }

      if (_forceAwait) {
        Toast.showLoading();
        // 强制等待渠道列表刷新，则再次重新拉取数据直到响应成功
        await getCoinPayChannelGet();
      }

      // // 判断是否是特殊的拥有全部支付渠道的商品
      // final hasAllChannels = hasFullPaymentChannels(model);

      if (!hasNativePayBridge()) {
        final webChannels = channelList.where((element) => !isNativePayChannel(element.payChannel)).toList();
        Toast.dismiss();
        if (webChannels.isEmpty) {
          Toast.showMsg('recharge_failed_please_try_again_later'.bhTR);
          return;
        }
        PayChannelDialog.show(
          model: model,
          list: webChannels,
          goodsType: goodsType,
          entry: entry,
          robotUserId: robotUserId,
        );
        return;
      }
      // 获取渠道成功，判断有几种渠道，若只有原生支付(GP/IAP)，就直接走原生支付
      if (channelList.isEmpty) {
        // 无返回渠道，走原生
        await _onGpOrIapPay(model, entry);
      } else if (channelList.length == 1 &&
          (channelList.any((element) => element.payChannel == "GP") ||
              channelList.any((element) => element.payChannel == "IAP"))) {
        // 只下发一种渠道，且是原生渠道时，不弹窗走原生支付
        await _onGpOrIapPay(model, entry);
      } else {
        Toast.dismiss();
        // 具有三方支付，弹窗
        // 如果不是特殊商品，传递标识表示要隐藏原生支付渠道
        PayChannelDialog.show(
          model: model,
          list: channelList,
          goodsType: goodsType,
          entry: entry,
          // hideNativePay: !hasAllChannels, // 反转逻辑：非特殊商品隐藏所有原生支付渠道
        );
      }
    }, key: "onPay");
  }

  /// 原生支付
  Future _onGpOrIapPay(CoinGoodsModel model, String entry) async {
    await payLogic.executePay(
      model.code ?? "",
      BHPlatform.isAndroid ? "GP" : "IAP",
      model.invitationId ?? "",
      entry,
    );
  }

  // 也为促销商品添加打印方法
  void _printPromotionData(CoinGoodsModel? model) {
    if (model == null) {
      print("======== 促销商品数据：无 ========");
      return;
    }

    print("======== 促销商品数据详情 ========");
    print("  goodsId: ${model.goodsId}");
    print("  code: ${model.code}");
    print("  price: ${model.price}");
    print("  originalPrice: ${model.originalPrice}");
    print("  exchangeCoin: ${model.exchangeCoin}");
    print("  extraCoin: ${model.extraCoin}");
    print("  discount: ${model.discount}");
    print("  isPromotion: ${model.isPromotion}");
    print("  tags: ${model.tags}");
    print("  surplusMillisecond: ${model.surplusMillisecond}");
    print("======== 促销商品数据结束 ========");
  }

  /// 获取用户是否拥有VIP会员特权
  bool hasVipEquity() {
    // 直接使用AppConfigManager中的用户信息
    final userInfo = appConfig.userInfo;

    // 检查用户是否有VIP权益
    final hasEquity = userInfo.hasEquity ?? false;
    if (!hasEquity) {
      return false;
    }

    // 检查权益是否已过期
    final expiryTimeStr = userInfo.equityExpiryTime;
    if (expiryTimeStr == null || expiryTimeStr.isEmpty) {
      return false;
    }

    try {
      // 解析过期时间并判断是否已过期
      final now = DateTime.now();
      DateTime expiryDate;

      if (expiryTimeStr.contains("-")) {
        // ISO格式日期字符串，如"2023-06-15T10:30:00.000Z"
        expiryDate = DateTime.parse(expiryTimeStr);
      } else {
        // 时间戳格式，如"1686827400000"
        expiryDate =
            DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTimeStr));
      }

      // 打印VIP权益检查日志
      print("\n======== VIP权益检查 ========");
      print("当前时间: ${now.toIso8601String()}");
      print("过期时间: ${expiryDate.toIso8601String()}");
      print("是否已过期: ${now.isAfter(expiryDate)}");
      print("======== VIP权益检查结束 ========\n");

      return now.isBefore(expiryDate); // 如果当前时间在过期时间之前，则未过期
    } catch (e) {
      print("解析VIP过期时间出错: $e");
      return false; // 解析出错默认没有VIP权益
    }
  }

  /// 获取VIP特权过期时间
  String? getVipEquityExpiryTime() {
    return appConfig.userInfo.equityExpiryTime;
  }
}
