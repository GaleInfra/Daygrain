import '../../js/Model/JSConversation.dart';
import '../base/rc_base_event.dart';

/// create: 2023/5/5
/// desc: 获取指定会话
class RCAppointConversationEvent extends RCBaseEvent {
  JSConversation? data;

  RCAppointConversationEvent.success(this.data) {
    ok = true;
  }

  RCAppointConversationEvent.fail(int? result) {
    ok = false;
    code = result;
  }
}
