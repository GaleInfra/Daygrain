import 'package:get/get.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/common_util.dart';

import '../model/log_upload/log_upload_model.dart';

class AppEventsUploadUtil {
  // static final _fb = FacebookAppEvents();

  static Future logFbCreateOrder({
    double? totalPrice,
    String? currency,
    String? contentType,
    String? contentId,
    int? numItems,
  }) async {
    // // 上报fb
    // await _fb.logInitiatedCheckout(
    //   totalPrice: totalPrice,
    //   currency: currency,
    //   contentType: contentType,
    //   contentId: contentId,
    //   numItems: numItems,
    // );
  }
  static List<String> orders = [];
  // 上报事件到第三方数据平台
  static void logPurchase(
    double price,
    String googleOrderId,
    String? orderNo,
    String payChannel,
  ) {
    // Map<String, dynamic> parameters = {'current_time': DateTimeUtil.getNowSecond(), 'google_order_id': googleOrderId, 'order_no': orderNo ?? '', 'pay_channel': payChannel};
    // // 自定义购买事件上报
    // _fb.logEvent(name: 'purchase_success', parameters: parameters, valueToSum: price);
    // // todo 查询后台是否手动上报购买的标准事件开关，若开启，则手动上报购买的标准事件
    // _fb.logPurchase(amount: price, currency: 'USD');
    // // 接入AppFlyer的埋点上报

    try {
      // logger.d("充值成功测试");
      if (!orders.contains(orderNo) && orderNo != null) {
        orders.add(orderNo);
        JSRongCloudManager.myLog(price, 'USD');
      }

    } catch (e) {}
  }

  // 上报购买事件到应用服务器后台
  static Future<void> logPurchaseToServer(
    List<LogUploadData> reqList,
  ) async {
    try {
      RequestRepository request = Get.find<RequestRepository>();
      await request.eventsLogUpload(
          reqList: reqList,
          onSuccess: (data) {
            logger.i("$reqList 上报成功");
          },
          onFail: (code, msg) {
            logger.i("$reqList 上报失败");
          });
    } catch (e) {
      logger.i("$reqList 上报异常");
    }
  }
}
