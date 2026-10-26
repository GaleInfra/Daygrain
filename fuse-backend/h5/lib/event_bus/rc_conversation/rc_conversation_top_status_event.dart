import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// create: 2023/5/29
/// desc: 置顶会话event
class RCConversationsTopStatusEvent extends BaseEvent {

  RCConversationsTopStatusEvent.success({required this.targetId, required this.top});

  final String targetId;

  final bool top;
}