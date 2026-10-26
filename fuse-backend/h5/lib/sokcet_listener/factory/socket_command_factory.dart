import 'package:untitled1/sokcet_listener/base/socket_listener.dart';
import 'package:untitled1/sokcet_listener/other_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/estimated_hang_up_time_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_chat_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_call_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_gift_ask_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_give_gift_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_hang_up_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_im_trigger_call_listener.dart';
import 'package:untitled1/sokcet_listener/video_call/on_pick_up_listener.dart';

import '../../res/video_call_data.dart';
import '../recharge/recharge_order_listener.dart';
import '../video_call/available_coins_listener.dart';

/// create: 2023/5/8
/// desc: socket事件处理管理类
class SocketCommandFactory {

  /// 获取具体处理类
  static SocketListener? getListener(String command) {
    switch (command) {
      case SocketCommandKey.onCall:
        return OnCallListener.getInstance();
      case SocketCommandKey.onIMTriggerCall:
        return OnIMTriggerCallListener.getInstance();
      case SocketCommandKey.onHangUp:
        return OnHangUpListener.getInstance();
      case SocketCommandKey.onPickUp:
        return OnPickUpListener.getInstance();
      case SocketCommandKey.onChat:
        return OnChatListener.getInstance();
      case SocketCommandKey.availableCoins:
        return AvailableCoinsListener.getInstance();
      case SocketCommandKey.estimatedHangUpTime:
        return EstimatedHangUpTimeListener.getInstance();
      case SocketCommandKey.onGiveGift:
        return OnGiveGiftListener.getInstance();
      case SocketCommandKey.onGiftAsk:
        return OnGiftAskListener.getInstance();
      case SocketCommandKey.rechargeOrderStatus:
        return RechargeOrderListener.getInstance();
      case SocketCommandKey.flashChatFreeTimes:
        return OtherListener.getInstance();
    }
    return null;
  }
}