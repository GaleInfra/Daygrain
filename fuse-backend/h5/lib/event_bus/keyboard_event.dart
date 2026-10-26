import 'package:untitled1/event_bus/base/event_bus_util.dart';

class KeyboardEvent extends BaseEvent {
  KeyboardEvent(this.isShow, this.keyBoardHeight);

  final bool isShow;
  final int keyBoardHeight;
}

//SayHiEvent
class SayHiEvent extends BaseEvent {
  SayHiEvent(this.broadcasterId);

  final String broadcasterId;
}