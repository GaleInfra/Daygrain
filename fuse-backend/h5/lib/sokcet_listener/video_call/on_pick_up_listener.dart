import 'package:untitled1/model/video_call/pick_up_model.dart';

import '../../event_bus/base/event_bus_util.dart';
import '../../event_bus/video_call/video_call_event.dart';
import '../../res/video_call_data.dart';
import '../base/socket_listener.dart';

/// create: 2023/5/9
/// desc: 视频通话接通事件处理
class OnPickUpListener extends SocketListener {
  OnPickUpListener._internal();

  static final OnPickUpListener _instance = OnPickUpListener._internal();

  factory OnPickUpListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    PickUpModel model = PickUpModel.fromJson(data);

    // 发送挂断/被挂断event
    // <---事件通知--->
    // 关闭呼叫页
    // 关闭被呼叫页
    // 关闭被呼叫弹窗
    EventBusUtil.fire<VideoCallEvent>(
      VideoCallEvent(
        command: SocketCommandKey.onPickUp,
        data: model,
      ),
    );
  }
}