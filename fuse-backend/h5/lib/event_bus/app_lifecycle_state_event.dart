import 'package:flutter/material.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';

/// create: 2023/5/25
/// desc: app前后台切换event
class AppLifecycleStateEvent extends BaseEvent {

  AppLifecycleStateEvent(this.state);

  final AppLifecycleState state;
}