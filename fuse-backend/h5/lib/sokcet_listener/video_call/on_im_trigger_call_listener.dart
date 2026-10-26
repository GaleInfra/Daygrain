import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/model/video_call/on_im_trigger_call_model.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/sokcet_listener/base/socket_listener.dart';

class OnIMTriggerCallListener extends SocketListener {
  OnIMTriggerCallListener._internal();

  static final OnIMTriggerCallListener _instance = OnIMTriggerCallListener._internal();

  factory OnIMTriggerCallListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    OnIMTriggerCallModel model = OnIMTriggerCallModel.fromJson(data);
    EventBusUtil.fire<VideoCallEvent>(VideoCallEvent(command: SocketCommandKey.onIMTriggerCall, data: model));
  }
}
