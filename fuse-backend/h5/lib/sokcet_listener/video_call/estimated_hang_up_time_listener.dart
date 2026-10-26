import '../../event_bus/base/event_bus_util.dart';
import '../../event_bus/video_call/video_call_event.dart';
import '../../res/video_call_data.dart';
import '../base/socket_listener.dart';

/// create: 2023/5/12
/// desc: 预计挂断时间
class EstimatedHangUpTimeListener extends SocketListener {
  EstimatedHangUpTimeListener._internal();

  static final EstimatedHangUpTimeListener _instance = EstimatedHangUpTimeListener._internal();

  factory EstimatedHangUpTimeListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    int estimateTime = data['estimateTime'];
    EventBusUtil.fire<VideoCallEvent>(VideoCallEvent(command: SocketCommandKey.estimatedHangUpTime, data: estimateTime));
  }
}