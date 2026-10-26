import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// create: 2023/5/22
/// desc: 空消息接收
class NoneFlagEvent extends BaseEvent {

  NoneFlagEvent(this.contentType);

  /// 消息类型
  final String contentType;
}