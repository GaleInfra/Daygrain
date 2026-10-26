import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/model/video_call/hang_up_model.dart';

import '../../res/video_call_data.dart';
import '../base/socket_listener.dart';

/// create: 2023/5/9
/// desc: 被挂断事件处理
class OnHangUpListener extends SocketListener {
  OnHangUpListener._internal();

  static final OnHangUpListener _instance = OnHangUpListener._internal();

  factory OnHangUpListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    HangUpModel model = HangUpModel.fromJson(data);

    // 发送挂断/被挂断event
    // <---事件通知--->
    // 关闭呼叫页
    // 关闭被呼叫页
    // 关闭被呼叫弹窗
    EventBusUtil.fire<VideoCallEvent>(
      VideoCallEvent(
        command: SocketCommandKey.onHangUp,
        data: model,
      ),
    );
  }
}
