import 'package:untitled1/js/Model/JSConversation.dart';

import '../base/rc_base_event.dart';

/// create: 2023/5/5
/// desc: 融云接收消息
class RCMessageReceivedEvent extends RCBaseEvent {
  JSMessage? message;

  RCMessageReceivedEvent.success(this.message) {
    ok = true;
  }

  RCMessageReceivedEvent.fail(int? result) {
    ok = false;
    code = result;
  }
}
