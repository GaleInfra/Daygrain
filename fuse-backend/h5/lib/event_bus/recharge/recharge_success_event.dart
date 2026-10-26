import '../base/event_bus_util.dart';

/// create: 2023/7/3
/// desc: 充值成功Event
class RechargeSuccessEvent extends BaseEvent {

  // 是否是订阅购买
  final bool subscribePay;

  RechargeSuccessEvent(this.subscribePay);
}
