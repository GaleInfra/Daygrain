import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';

class KeyboardListenerWidget extends StatefulWidget {
  final Widget child;

  /// 键盘显示/隐藏回调
  final Function(bool isShow, int height) onKeyboardChanged;

  const KeyboardListenerWidget({
    Key? key,
    required this.child,
    required this.onKeyboardChanged,
  }) : super(key: key);

  @override
  State<KeyboardListenerWidget> createState() => _KeyboardListenerWidgetState();
}

class _KeyboardListenerWidgetState extends State<KeyboardListenerWidget> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = EventBusUtil.listen<KeyboardEvent>((event) {
      // height为0表示键盘隐藏，大于0表示键盘显示
      widget.onKeyboardChanged(event.isShow, event.keyBoardHeight);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
