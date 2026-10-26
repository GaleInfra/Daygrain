import '../base/rc_base_event.dart';

/// create: 2023/5/4
/// desc: 会话未读数eventBus
class RCTotalUnreadCountEvent extends RCBaseEvent {

  /// 数量
  int? count;

  RCTotalUnreadCountEvent.success({required this.count}) {
    ok = true;
  }

  RCTotalUnreadCountEvent.fail({required int? code}) {
    ok = false;
    super.code = code;
  }
}