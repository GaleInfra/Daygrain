import '../base/rc_base_event.dart';

/// create: 2023/5/17
/// desc: 删除指定会话
class RCRemoveConversationEvent extends RCBaseEvent {
  /// 指定会话id
  String? targetId;

  RCRemoveConversationEvent.success(this.targetId) {
    ok = true;
  }

  RCRemoveConversationEvent.fail(int? result) {
    ok = false;
    code = result;
  }
}