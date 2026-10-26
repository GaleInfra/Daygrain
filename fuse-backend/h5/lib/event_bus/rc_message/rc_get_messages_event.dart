import '../../js/Model/JSConversation.dart';
import '../base/rc_base_event.dart';

/// create: 2023/5/4
/// desc: 融云获取历史消息
class RCGetMessagesEvent extends RCBaseEvent {
  /// 获取成功
  RCGetMessagesEvent.success({required this.list}) {
    ok = true;
  }

  /// 获取失败
  RCGetMessagesEvent.fail({required int? code}) {
    ok = false;
    super.code = code;
  }

  List<JSMessage>? list;
}
