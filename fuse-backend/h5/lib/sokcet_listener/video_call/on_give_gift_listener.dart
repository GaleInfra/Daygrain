import 'package:untitled1/model/video_call/on_give_gift_model.dart';

import '../../event_bus/base/event_bus_util.dart';
import '../../event_bus/video_call/video_call_event.dart';
import '../../res/video_call_data.dart';
import '../base/socket_listener.dart';

/// create: 2023/5/9
/// desc: 送出礼物事件处理
class OnGiveGiftListener extends SocketListener {
  OnGiveGiftListener._internal();

  static final OnGiveGiftListener _instance = OnGiveGiftListener._internal();

  factory OnGiveGiftListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    OnGiveGiftModel model = OnGiveGiftModel.fromJson(data);

    EventBusUtil.fire<VideoCallEvent>(
      VideoCallEvent(
        command: SocketCommandKey.onGiveGift,
        data: model,
      ),
    );
  }
}