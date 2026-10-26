import 'dart:async';

import 'package:event_bus/event_bus.dart';

/// create: 2023/5/4
/// desc: EventBus工具
class EventBusUtil {
  static EventBus? _eventBus;

  ///获取单例
  static EventBus getInstance() {
    _eventBus ??= EventBus();
    return _eventBus!;
  }

  ///返回某事件的订阅者
  static StreamSubscription<T> listen<T extends BaseEvent>(Function(T event) onData) {
    //内部流属于广播模式，可以有多个订阅者
    return getInstance().on<T>().listen(onData);
  }

  ///发送事件
  static void fire<T extends BaseEvent>(T e) {
    getInstance().fire(e);
  }

  /// 销毁
  static void onDestroy() {
    _eventBus?.destroy();
  }
}

/// eventBus 抽象基类
abstract class BaseEvent {

}
