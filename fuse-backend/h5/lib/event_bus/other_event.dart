import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// create: 2024/1/19
/// desc: 其他类型的通知
class OtherEvent extends BaseEvent {
  final OtherType type;

  final dynamic data;

  OtherEvent({
    required this.type,
    required this.data,
  });
}

enum OtherType {
  /// 主播墙索引切换
  broadcasterIndex,

  /// 策略刷新
  strategyUpdate,

  /// 用户数据刷新
  userInfoUpdate,

  /// 拉黑通知
  block,

  /// 关注通知
  follow,

  /// 免费匹配次数下发
  flashChatFreeTimes,

  /// 主播墙国家刷新
  broadcasterCountry,
}
