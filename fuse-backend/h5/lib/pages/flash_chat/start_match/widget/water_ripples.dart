import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../event_bus/app_lifecycle_state_event.dart';
import '../../../../event_bus/base/event_bus_util.dart';

/// create: 2023/6/7
/// desc: 水波纹扩散效果
class WaterRipples extends StatefulWidget {
  const WaterRipples({
    Key? key,
    required this.width,
    required this.color,
    this.rippleCount = 3,
    this.enableAnimation = true,
  }) : super(key: key);

  final Color color;
  final double width;
  final int rippleCount;
  final bool enableAnimation;

  @override
  State<StatefulWidget> createState() => _WaterRipplesState();
}

class _WaterRipplesState extends State<WaterRipples> with TickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleStateEvent;
  double oldShow = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if(widget.enableAnimation ){
          _controller.reset();
          _controller.forward();
        }
      }
    });
    _appLifecycleStateEvent = EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        if (oldShow == 100) {
          _start();
        }
      } else if (event.state == AppLifecycleState.paused) {
        _controller.reset();
        _controller.stop();
      }
    });
    if (widget.enableAnimation) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant WaterRipples oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation && !_controller.isAnimating) {
      _start();
    } else if (!widget.enableAnimation && _controller.isAnimating) {
      _controller.reset();
      _controller.stop();
    }
  }

  @override
  void dispose() {
    log("tag--=========================dispose===================");
    _appLifecycleStateEvent?.cancel();
    _appLifecycleStateEvent = null;
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    _controller.reset();
    _controller.forward();
  }

  void _widgetShow(double visiblePercentage) {
    if (!widget.enableAnimation) return;
    if (visiblePercentage > 80 && oldShow == 0) {
      _start();
    } else if (visiblePercentage <= 80) {
      _controller.reset();
      _controller.stop();
    }
    oldShow = visiblePercentage;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation) {

        List<Widget> ripples = [];
            for (int i = 0; i < widget.rippleCount; i++) {
              double phase = i / widget.rippleCount;
              double progress = (_controller.value + phase) % 1.0;
              double radius = (widget.width / 3.0) + (widget.width - widget.width / 3.0) * progress;
              double opacity = 1.0 - progress;
              if (opacity < 0) opacity = 0;
              if (opacity > 1) opacity = 1;
              ripples.add(
                Opacity(
                  opacity: opacity,
                  child: ClipOval(
                    child: Container(
                      width: radius,
                      height: radius,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            }
             

      // 静态最大展开光波
      return SizedBox(
        width: widget.width,
        height: widget.width,
        child: Center(
          child: Stack(
              alignment: Alignment.center,
              children: ripples,
            ),
        ),
      );
    }
    return VisibilityDetector(
      key: ValueKey(DateTime.now().millisecondsSinceEpoch.toString()),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        _widgetShow(visiblePercentage);
      },
      child: SizedBox(
        width: widget.width,
        height: widget.width,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            List<Widget> ripples = [];
            for (int i = 0; i < widget.rippleCount; i++) {
              double phase = i / widget.rippleCount;
              double progress = (_controller.value + phase) % 1.0;
              double radius = (widget.width / 3.0) + (widget.width - widget.width / 3.0) * progress;
              double opacity = 1.0 - progress;
              if (opacity < 0) opacity = 0;
              if (opacity > 1) opacity = 1;
              ripples.add(
                Opacity(
                  opacity: opacity,
                  child: ClipOval(
                    child: Container(
                      width: radius,
                      height: radius,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            }
            return Stack(
              alignment: Alignment.center,
              children: ripples,
            );
          },
        ),
      ),
    );
  }
}
