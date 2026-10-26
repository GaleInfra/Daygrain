import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// 全局背景音乐控制事件
/// 任何负责播放背景音乐的模块可监听这些事件进行暂停/恢复
class BGMPauseEvent extends BaseEvent {}

class BGMResumeEvent extends BaseEvent {}

/// 机器人弹窗铃声控制事件
class RobotRingPauseEvent extends BaseEvent {}

class RobotRingResumeEvent extends BaseEvent {}


