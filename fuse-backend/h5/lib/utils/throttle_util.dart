import 'dart:async';

import 'package:easy_debounce/easy_throttle.dart';

ThrottleUtil throttleUtil = ThrottleUtil();

/// create: 2023/5/22
/// desc: 节流工具
class ThrottleUtil {
  /// 传入[key]作为事件的名称，注意不要重复
  /// 不使用callback.hashCode作为key的原因是
  /// '''
  ///   throttleUtil.throttle(() {});
  /// '''
  /// 上面这种写法的hashCode每次都不同，无法达到节流的目的
  Future<void> throttle(Future<void> Function() callback, {required String key, int time = 1000, Future<void> Function()? onAfter}) async {
    EasyThrottle.throttle(key, Duration(milliseconds: time), callback, onAfter: onAfter);
  }

  void cancel(String key) {
    EasyThrottle.cancel(key);
  }
}
