import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';

import 'base/socket_listener.dart';

/// create: 2024/1/23
/// desc: 其他事件下发处理
class OtherListener extends SocketListener {
  OtherListener._internal();

  static final OtherListener _instance = OtherListener._internal();

  factory OtherListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    int time = data['freeTimes'];
    EventBusUtil.fire(OtherEvent(type: OtherType.flashChatFreeTimes, data: time));
  }
}