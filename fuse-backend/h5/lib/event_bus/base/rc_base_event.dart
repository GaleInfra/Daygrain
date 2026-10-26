import 'event_bus_util.dart';

/// create: 2023/5/9
/// desc: 融云EventBus抽象基类
abstract class RCBaseEvent extends BaseEvent{
  /// 是否成功
  late bool ok;

  /// 错误回调状态码
  int? code;

  onSuccess() {
    ok = true;
  }

  onFail(int? result) {
    ok = false;
    code = result;
  }
}