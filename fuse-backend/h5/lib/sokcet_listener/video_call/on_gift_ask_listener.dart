import 'dart:convert';

import '../../event_bus/base/event_bus_util.dart';
import '../../event_bus/video_call/video_call_event.dart';
import '../../model/video_call/on_gift_ask_model.dart';
import '../../res/video_call_data.dart';
import '../base/socket_listener.dart';

/// create: 2023/5/9
/// desc: 被索取礼物事件处理
class OnGiftAskListener extends SocketListener {
  OnGiftAskListener._internal();

  static final OnGiftAskListener _instance = OnGiftAskListener._internal();

  factory OnGiftAskListener.getInstance() => _instance;

  @override
  void onHandler(data) {
    Map<String, dynamic> content = jsonDecode(data['content']);
    data['content'] = content;
    OnGiftAskModel model = OnGiftAskModel.fromJson(data);

    EventBusUtil.fire<VideoCallEvent>(
      VideoCallEvent(
        command: SocketCommandKey.onGiftAsk,
        data: model,
      ),
    );
  }
}