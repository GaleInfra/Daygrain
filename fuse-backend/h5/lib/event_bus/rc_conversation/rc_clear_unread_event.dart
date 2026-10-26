import '../base/rc_base_event.dart';

/// create: 2023/5/5
/// desc: 融云清除指定会话未读数
class RCClearUnreadEvent extends RCBaseEvent {
  /// 指定会话id
  String? targetId;

  RCClearUnreadEvent.success(this.targetId) {
    ok = true;
  }

  RCClearUnreadEvent.fail(int? result) {
    ok = false;
    code = result;
  }
}