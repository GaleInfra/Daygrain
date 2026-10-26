import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/sokcet_listener/base/socket_listener.dart';

import '../../event_bus/recharge/recharge_event.dart';
import '../../model/pay/recharge_status_model.dart';

/// create: 2023/5/8
/// desc: 充值结果事件下发处理监听
class RechargeOrderListener extends SocketListener {
  RechargeOrderListener._internal();

  static final RechargeOrderListener _instance = RechargeOrderListener._internal();

  factory RechargeOrderListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    RechargeStatusModel model = RechargeStatusModel.fromJson(data);
    // 发送事件通知结果
    EventBusUtil.fire<RechargeEvent>(RechargeEvent(model: model));
  }
}
