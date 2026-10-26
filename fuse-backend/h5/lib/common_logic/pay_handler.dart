import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/constants/common_constants.dart';
import 'package:untitled1/constants/enums/pay_channel_enum.dart';
import 'package:untitled1/constants/enums/purchase_event_enum.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/log_upload/log_upload_model.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/model/pay/order_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/video_call/video_call/widget/guided_recharge_dialog.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/app_events_upload_util.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/five_sstar_praise_dialog.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/dialog/recharge_link_dialog.dart';
import '../event_bus/recharge/recharge_event.dart';
import '../net/base/response_parse.dart';
import '../utils/bh_platform.dart';
import '../utils/js_utils.dart';
import 'banner_strong_guide_logic.dart';

final bool _kAutoConsume = BHPlatform.isIOS || false;

/// PayHandler handles the payment process, including listening for
/// the third-party recharge result, creating orders, and refreshing
/// user coins.
class PayHandler extends GetxController {
  final _request = Get.find<RequestRepository>();
  final _appConfigManager = Get.find<AppConfigManager>();

  bool flag = true;

  /// 三方充值结果event
  StreamSubscription<RechargeEvent>? _rechargeEvent;

  /// 一分钟定时器
  Timer? _listenTimer;

  /// 支付结果轮询定时器
  Timer? _searchTimer;

  /// 发起支付的商品
  String? _toPayGoodsCode;

  /// 支付成功的商品，用于活动促销、新用户促销显示判断
  final paySuccessGoodsCode = "".obs;

  // final _vipManager = Get.find<VipManager>();

  final _strongLogic = Get.find<BannerStrongGuideLogic>();

  @override
  void onReady() async {
    _initEvent();

    super.onReady();
  }

  // 刷新用户金币
  // [subscribePay] 是否是订阅支付
  Future<void> refreshUserCoin({bool subscribePay = false}) async {
    // 执行刷新金币，说明支付成功了
    // 设置当前支付成功的商品，通知刷新
    paySuccessGoodsCode.value = _toPayGoodsCode ?? "";

    // 打印支付成功信息
    print("\n======== 支付成功详情 ========");
    print("支付商品Code: ${_toPayGoodsCode}");
    print("是否是VIP订阅支付: $subscribePay");
    if (_waitForPayOrderModel != null) {
      print("订单详情: {");
      print("  orderNo: ${_waitForPayOrderModel!.orderNo}");
      print("  goodsCode: ${_waitForPayOrderModel!.goodsCode}");
      print("  goodsName: ${_waitForPayOrderModel!.goodsName}");
      print("  payAmount: ${_waitForPayOrderModel!.payAmount}");
      print("  paidAmount: ${_waitForPayOrderModel!.paidAmount}");
      print("  paidCurrency: ${_waitForPayOrderModel!.paidCurrency}");
      print("  requestUrl: ${_waitForPayOrderModel!.requestUrl}");
      print("  tradeNo: ${_waitForPayOrderModel!.tradeNo}");
      print("}");
    }
    print("======== 支付成功详情结束 ========\n");

    // 通知刷新成功之后，再清空数据，因为GetX的ever函数监听的字段相同值下不会触发
    _toPayGoodsCode = null;
    paySuccessGoodsCode.value = "";

    // 发送充值成功事件，通知客户端各处刷新
    EventBusUtil.fire<RechargeSuccessEvent>(RechargeSuccessEvent(subscribePay));

    FiveStarPraiseDialog.show();

    try {
      print("\n======== 开始刷新用户信息 (支付后) ========");
      if (subscribePay) {
        // 订阅支付，刷新策略接口
        print("订阅支付 - 刷新策略接口");
        _appConfigManager.onGetStrategy();
      }
      // 刷新用户金币和用户充值身份
      print("开始请求userGetInfo接口...");
      await _appConfigManager.onGetInfo();
      print("userGetInfo接口请求完成");

      // 打印刷新后的用户信息
      print("\n======== 刷新后的用户信息 ========");
      print("用户ID: ${_appConfigManager.userInfo.userId}");
      print("用户金币数量: ${_appConfigManager.userInfo.availableCoins}");
      print("是否是VIP: ${_appConfigManager.userInfo.isVip}");
      print("VIP过期时间: ${_appConfigManager.userInfo.vipExpiryTime}");
      print("是否充值用户: ${_appConfigManager.userInfo.isRecharge}");

      // 打印VIP特权相关信息
      if (_appConfigManager.userInfo.hasEquity != null ||
          _appConfigManager.userInfo.equityExpiryTime != null) {
        print("\n===== VIP特权相关信息 =====");
        print("hasEquity: ${_appConfigManager.userInfo.hasEquity}");
        print(
            "equityExpiryTime: ${_appConfigManager.userInfo.equityExpiryTime}");
      }

      print("======== 用户信息结束 ========\n");

      _strongLogic.onInitData();
      print("======== 结束刷新用户信息 (支付后) ========\n");
    } catch (e) {
      logger.e("充值成功后刷新失败: $e");
    }
  }

  // 调起一次支付流程
  Future<void> executePay(
      String goodsCode, String payChannel, String source, String entry) async {
    if (kIsWeb) {
      Toast.showLoading();
      //修复SDK S8-2.1.4 支付 获取参数错误的bug
      //出问题的SDK标识版本
      final sdkVers = ["S8-2.1.4", "S8", "k2-2.0"];
      //获取当前SDK版本
      final sdkVer = BaseManager.instance.appInfo.sdkVersion;
      var entryTmp = entry;
      var sourceTmp = source;
      if (sdkVer.isNotEmpty && sdkVers.contains(sdkVer)) {
        //调转 entry 和 source 参数
        entryTmp = source;
        sourceTmp = entry;
      }

      await JSRongCloudManager.myLogP(
          goodsCode,
          entryTmp,
          sourceTmp,
          (BHCallbackWeb(
            onSuccess: (dynamic data) {
              Toast.dismiss(status: SmartStatus.loading);
              Toast.showMsg("info_paymentProcessed".bhTR);
              //关闭充值弹窗
              RechargeDialog.dismiss();
              PayChannelDialog.dismiss();
              //关闭引导充值弹窗
              RechargeLinkDialog.dismiss();
              GuidedRechargeDialog.dismiss();
              refreshUserCoin();
              _onCancelTimer();
            },
            onError: (int code) {
              //info_paymentFailed
              Toast.dismiss(status: SmartStatus.loading);
              // Toast.showMsg("info_paymentFailed".bhTR);
            },
          )).toJS());
    } else {}
  }

  /// 获取原生支付的缓存key
  String nativeRechargeCacheKey(String goodsCode) {
    if (BHPlatform.isIOS) {
      return appStoreRechargeCacheKey(goodsCode);
    } else {
      return googleRechargeCacheKey(goodsCode);
    }
  }

  /// 苹果支付的缓存key
  String appStoreRechargeCacheKey(String goodsCode) {
    return "$appStoreRechargePrefix$goodsCode";
  }

  // 谷歌充值的缓存key
  String googleRechargeCacheKey(String goodsCode) {
    return "$googleRechargePrefix$goodsCode";
  }

  // 三方订单的缓存key
  String threeRechargeCacheKey(String orderNo) {
    return "$threeRechargePrefix$orderNo";
  }

  /// 初始化第三方充值结果socket监听
  void _initEvent() {
    _rechargeEvent = EventBusUtil.listen<RechargeEvent>((event) async {
      var orderNo = event.model.orderNo;
      //充值状态(1-充值中 2-充值成功 3-充值失败)
      if (event.model.status == 2) {
        if (_waitForPayOrderModel?.goodsCode == event.model.code) {
          Toast.showMsg("info_paymentProcessed".bhTR);
          _waitForPayOrderModel = null;
        }
        //关闭充值弹窗
        RechargeDialog.dismiss();
        PayChannelDialog.dismiss();
        //关闭引导充值弹窗
        RechargeLinkDialog.dismiss();
        GuidedRechargeDialog.dismiss();
        refreshUserCoin();
        _onCancelTimer();
        if (orderNo != null &&
            orderNo.isNotEmpty &&
            SPUtil.containsKey(threeRechargeCacheKey(orderNo))) {
          var map = SPUtil.getMap(threeRechargeCacheKey(orderNo));
          // 上报购买成功事件
          AppEventsUploadUtil.logPurchase(
              map[usdPrice], "", orderNo, PayChannelEnum.three.name);
          await AppEventsUploadUtil.logPurchaseToServer([
            LogUploadData(
                event: PurchaseEventEnum.refresh_coins_resp.name,
                code: map["goodsCode"],
                orderId: orderNo,
                result: "[三方]购买成功",
                resultCode: 0,
                orderNo: "")
          ]);
          // 删除对应订单号的缓存
          await SPUtil.remove(threeRechargeCacheKey(orderNo));
        }
      } else if (event.model.status == 3) {
        if (orderNo != null &&
            orderNo.isNotEmpty &&
            SPUtil.containsKey(orderNo)) {
          var map = SPUtil.getMap(threeRechargeCacheKey(orderNo));
          await AppEventsUploadUtil.logPurchaseToServer([
            LogUploadData(
                event: PurchaseEventEnum.refresh_coins_resp.name,
                code: map["goodsCode"],
                orderId: orderNo,
                result: "[三方]购买失败",
                resultCode: 1,
                orderNo: "")
          ]);
          // 删除对应订单号的缓存
          await SPUtil.remove(threeRechargeCacheKey(orderNo));
        }
        _onCancelTimer();
      }
    });
  }

  ///等待支付的订单
  OrderModel? _waitForPayOrderModel;

  /// 创建订单
  Future<void> coinRechargeCreate({
    required String goodsCode,
    required String payChannel,
    required String source,
    required String entry,
    required Success<OrderModel> onSuccess,
    required Fail onFail,
  }) async {
    List<LogUploadData> reqList = [];
    _toPayGoodsCode = goodsCode;
    try {
      // 创建订单
      var log1 = LogUploadData(
        event: PurchaseEventEnum.create_order.name,
        code: goodsCode,
        orderId: "",
        result: "[三方]准备创建订单",
        resultCode: 0,
      );
      reqList.add(log1);
      await _request.coinRechargeCreate(
        goodsCode: goodsCode,
        payChannel: payChannel,
        source: source,
        showLoading: false,
        entry: entry,
        onSuccess: (data) {
          _waitForPayOrderModel = data;
          AppEventsUploadUtil.logFbCreateOrder(
            totalPrice: getUSDPrice(data).toDouble(),
            currency: "USD",
          );
          // 创建订单成功
          var log2 = LogUploadData(
            event: PurchaseEventEnum.create_order_resp.name,
            code: goodsCode,
            orderId: data.orderNo ?? "",
            result: "[三方]订单创建成功",
            resultCode: 0,
          );
          reqList.add(log2);

          /// 将当前订单加入缓存中，为随后消费做准备
          if (data.orderNo != null && data.orderNo!.isNotEmpty) {
            var map = data.toJson();
            map[usdPrice] = getUSDPrice(data);
            SPUtil.setMap("$threeRechargePrefix${data.orderNo!}", map);
          }
          onSuccess.call(data);
        },
        onFail: (code, msg) {
          // 创建订单失败
          var log2 = LogUploadData(
            event: PurchaseEventEnum.create_order_resp.name,
            code: goodsCode,
            orderId: "",
            result: "[三方]订单创建失败, code: $code, msg:$msg",
            resultCode: code,
          );
          reqList.add(log2);
          onFail.call(code, msg);
        },
      );
    } catch (e) {
      logger.e("创建订单错误===> $e");
    } finally {
      await AppEventsUploadUtil.logPurchaseToServer(reqList);
    }
  }

  /// 监听第三方充值结果
  Future<void> listenRecharge() async {
    _onCancelTimer();
    _listenTimer = Timer(const Duration(minutes: 1), () {
      // 一分钟已到，结束轮询
      _onCancelTimer();
    });
    _searchTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (flag) {
        // 如果已经有一个轮询在进行中，则不再发起新的轮询
        flag = false;
        // 创建定时器，5秒查询一次
        await coinRechargeResult();
      }
    });
  }

  /// 查询充值结果
  Future<void> coinRechargeResult() async {
    var keyList = SPUtil.getKeys()
        .where((element) => element.startsWith(threeRechargePrefix))
        .toList();
    for (var key in keyList) {
      if (!SPUtil.containsKey(MyKeys.token) ||
          SPUtil.getString(MyKeys.token).isEmpty) {
        // 登录态失效
        _onCancelTimer();
        return;
      }
      var map = SPUtil.getMap(key);
      String orderNo = map["orderNo"];
      String goodsCode = map["goodsCode"];
      await _request.coinRechargeSearch(
        showErrorTip: false,
        orderNo: orderNo,
        onSuccess: (status) async {
          //充值状态(1-充值中 2-充值成功 3-充值失败)
          if (status == 2) {
            if (_waitForPayOrderModel?.goodsCode == goodsCode) {
              Toast.showMsg("info_paymentProcessed".bhTR);
              _waitForPayOrderModel = null;
            }

            refreshUserCoin();
            _onCancelTimer();
            //关闭充值弹窗
            RechargeDialog.dismiss();
            PayChannelDialog.dismiss();
            //关闭引导充值弹窗
            RechargeLinkDialog.dismiss();
            GuidedRechargeDialog.dismiss();
            // 上报购买成功事件
            AppEventsUploadUtil.logPurchase(
                map[usdPrice], "", orderNo, PayChannelEnum.three.name);
            await AppEventsUploadUtil.logPurchaseToServer([
              LogUploadData(
                event: PurchaseEventEnum.refresh_coins_resp.name,
                code: goodsCode,
                orderId: orderNo,
                result: "[三方]购买成功",
                resultCode: 0,
              )
            ]);
            // 删除对应订单号的缓存
            await SPUtil.remove(key);
          } else if (status == 3) {
            await AppEventsUploadUtil.logPurchaseToServer([
              LogUploadData(
                event: PurchaseEventEnum.refresh_coins_resp.name,
                code: goodsCode,
                orderId: orderNo,
                result: "[三方]购买失败",
                resultCode: 1,
              )
            ]);
            // 删除对应订单号的缓存
            await SPUtil.remove(key);
            _onCancelTimer();
          }
          flag = true;
        },
        onFail: (code, msg) async {
          await AppEventsUploadUtil.logPurchaseToServer([
            LogUploadData(
              event: PurchaseEventEnum.refresh_coins_resp.name,
              code: map["goodsCode"],
              orderId: orderNo,
              result: "[三方]购买订单查询异常, code: $code, msg:$msg",
              resultCode: 1,
            )
          ]);
          flag = true;
        },
      );
    }
  }

  /// 销毁定时器
  void _onCancelTimer() {
    if (_listenTimer != null) {
      _listenTimer?.cancel();
      _listenTimer = null;
    }
    if (_searchTimer != null) {
      _searchTimer?.cancel();
      _searchTimer = null;
    }
  }

  num getUSDPrice(OrderModel orderModel) {
    var paidCurrency = orderModel.paidCurrency;
    var paidAmount = orderModel.paidAmount;
    var payAmount = orderModel.payAmount;
    if ("USD" == paidCurrency && paidAmount != null) {
      return paidAmount;
    }
    return payAmount ?? 0;
  }

  @override
  void onClose() {
    _rechargeEvent?.cancel();
    super.onClose();
  }
}
