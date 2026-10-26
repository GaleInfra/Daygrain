import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/model/video_call/on_call_model.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/sokcet_listener/base/socket_listener.dart';

/// create: 2023/5/8
/// desc: 被呼叫事件处理监听
class OnCallListener extends SocketListener {
  OnCallListener._internal();

  static final OnCallListener _instance = OnCallListener._internal();

  factory OnCallListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    OnCallModel model = OnCallModel.fromJson(data);
    EventBusUtil.fire<VideoCallEvent>(VideoCallEvent(command: SocketCommandKey.onCall, data: model));
  }
}
