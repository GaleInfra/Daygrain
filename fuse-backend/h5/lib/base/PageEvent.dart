import 'package:untitled1/event_bus/base/event_bus_util.dart';

class PageEvent extends BaseEvent {
  final int type; //0 进入 1 退出 2 强制关闭
  final String pageEvent;
  PageEvent({
    required this.type,
    required this.pageEvent,
  });
}