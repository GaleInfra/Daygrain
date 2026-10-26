import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/model/video_call/on_give_gift_model.dart';

/// create: 2024/1/19
/// desc: 成功送出礼物event
class GiveGiftSuccessEvent extends BaseEvent {
  GiveGiftSuccessEvent({
    required this.data,
  });

  final OnGiveGiftModel data;
}
