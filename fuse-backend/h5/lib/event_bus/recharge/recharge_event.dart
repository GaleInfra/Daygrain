import 'package:untitled1/model/pay/recharge_status_model.dart';

import '../base/event_bus_util.dart';

/// create: 2023/5/19
/// desc: 充值结果Event
class RechargeEvent extends BaseEvent {

  RechargeEvent({
    required this.model,
  });

  /// 充值结果
  final RechargeStatusModel model;
}
