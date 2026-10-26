

import 'package:untitled1/event_bus/base/event_bus_util.dart';

class HomeChangeTabEvent extends BaseEvent {

  HomeChangeTabEvent({
    required this.index,
  });

  /// 事件名称
  final int index;

}