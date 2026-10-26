/// create: 2023/5/8
/// desc: 视频通话入口来源
class VideoCallSource {
  static const int CONVERSATION = 1; //会话界面
  static const int JSAPI = 2; //页端调用
  static const int MATCH_RESULT = 3; //匹配结果页
  static const int POPULAR_WALL = 4; //主播/用户墙
  static const int ANOTHER_ANCHOR = 5; //呼叫失败时推荐另一批
  static const int DETAIL_PAGE = 6; //主播主页调用
  static const int DETAIL_VIDEO_PAGE = 7; //主播视频详情页
  static const int MISS_CALL_PAGE = 8; //miss call 弹框回拨
  static const int CONNECTION_ERROR_CALL_BACK = 9; //用户网络不好弹框回拨
  static const int MEDIA_WALL = 10; //视频流
  static const int CALLS_PAGE = 11; //通话记录
  static const int FAST_MATCH = 12; //快速匹配
  static const int AUTO_CALL = 13; //auto call
  static const int MULTIPLE = 14; //多人连线
  static const int RECOMMEND_GODDESS = 15; //女神推荐
}

/// 视频通话-挂断原因字段
class HandUpReason {
  static const int NORMAL = 1; // 常规
  static const int NO_COINS = 2; // 金币不足
  static const int CL_EXCEPTION = 3; // 客户端异常
  static const int CL_CALL_TIMEOUT = 4; // 呼叫超时
  static const int CL_REMOTE_USER_LEFT = 5; // 对方退出
  static const int SER_EXCEPTION = 6; // 服务端错误
  static const int NET_EXCEPTION = 7; // 网络错误
}

/// create: 2023/5/9
/// desc: Socket command 名称key
class SocketCommandKey {
  /// 拨打事件名称
  static const String onCall = "onCall";

  /// 搭讪电话
  static const String onIMTriggerCall = "onIMTriggerCall";

  /// 挂断事件名称
  static const String onHangUp = "onHangUp";

  /// 被挂断执行完成
  static const String onHangUpComplete = "onHangUpComplete";

  /// 接通事件名称
  static const String onPickUp = "onPickUp";

  /// v1视频页聊天文本消息
  static const String onChat = "onChat";

  /// 可用余额消息
  static const String availableCoins = "availableCoins";

  /// 预估挂断时间消息
  static const String estimatedHangUpTime = "estimatedHangUpTime";

  /// 送出礼物
  static const String onGiveGift = "onGiveGift";

  /// 被索取礼物
  static const String onGiftAsk = "onGiftAsk";

  /// 三方支付充值成功
  static const String rechargeOrderStatus = "rechargeOrderStatus";

  /// 匹配免费次数下发
  static const String flashChatFreeTimes = "flashChatFreeTimes";
}

/// create: 2023/5/11
/// desc: 视频通话记录类型
class VideoCallType {
  /// 拨出，接通
  static const String outgoing = "Outgoing";

  /// 收到，接通
  static const String incoming = "Incoming";

  /// 收到，自己挂断
  static const String rejected = "Rejected";

  /// 呼出，自己挂断
  static const String cancelled = "Cancelled";

  /// 呼出，被挂断
  static const String unanswered = "Unanswered";

  /// 收到，没有接听
  static const String missed = "Missed";
}
