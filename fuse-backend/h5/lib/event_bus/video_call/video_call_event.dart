import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// create: 2023/5/9
/// desc: 视频通话event
class VideoCallEvent extends BaseEvent {

  VideoCallEvent({
    required this.command,
    required this.data,
  });

  /// 事件名称
  final String command;

  /// 事件数据
  final dynamic data;
}
