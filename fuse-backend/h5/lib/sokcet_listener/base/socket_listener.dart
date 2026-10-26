/// create: 2023/5/8
/// desc: Socket事件处理抽象基类
abstract class SocketListener {

  /// 处理消息
  void onHandler(dynamic data);
}