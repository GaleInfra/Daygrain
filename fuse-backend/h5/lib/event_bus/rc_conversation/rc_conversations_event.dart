import '../../js/Model/JSConversation.dart';
import '../base/rc_base_event.dart';

/// create: 2023/5/5
/// desc: 融云获取会话列表Event
class RCConversationsEvent extends RCBaseEvent {
  /// 会话数据
  List<JSConversation>? list;

  /// 是否为加载更多
  bool? loadMore;

  /// 获取置顶会话列表
  bool? getTop;

  RCConversationsEvent.success(this.list, this.loadMore, this.getTop) {
    ok = true;
  }

  RCConversationsEvent.fail(int? result) {
    ok = false;
    code = result;
  }
}
