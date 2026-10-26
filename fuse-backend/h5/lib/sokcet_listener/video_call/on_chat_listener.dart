import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/sokcet_listener/base/socket_listener.dart';

import '../../model/video_call/on_chat_model.dart';
import '../../res/video_call_data.dart';

/// create: 2023/5/10
/// desc: 视频通话 1v1消息
class OnChatListener extends SocketListener {
  OnChatListener._internal();

  static final OnChatListener _instance = OnChatListener._internal();

  factory OnChatListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    OnChatModel model = OnChatModel.fromJson(data);
    EventBusUtil.fire<VideoCallEvent>(VideoCallEvent(command: SocketCommandKey.onChat, data: model));
  }
}