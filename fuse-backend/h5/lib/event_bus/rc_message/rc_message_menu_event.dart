import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/js/Model/JSConversation.dart';

/// create: 2023/5/29
/// desc: 消息删除操作event
class RCMessageDeleteEvent extends BaseEvent {
  RCMessageDeleteEvent({
    required this.targetId,
    required this.messages,
  });

  final String targetId;
  final List<JSMessage>? messages;
}
