import '../../js/Model/JSConversation.dart';
import '../base/rc_base_event.dart';

/// create: 2023/5/5
/// desc: 融云发送消息Event
class RCSendMessageEvent extends RCBaseEvent {
  /// 消息
  JSMessage? message;

  RCSendMessageEvent.success({required this.message}) {
    super.onSuccess();
  }

  RCSendMessageEvent.fail({required this.message, required int? code}) {
    super.onFail(code);
  }
}
