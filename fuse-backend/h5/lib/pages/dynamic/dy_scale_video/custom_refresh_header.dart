import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/logic.dart';

class CustomRefreshHeader extends Header {
  const CustomRefreshHeader({
    super.triggerOffset = 50,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = Duration.zero,
  });

  @override
  Widget build(BuildContext context, IndicatorState state) {
    return _CustomRefreshIndicator(
      state: state,
    );
  }
}

class _CustomRefreshIndicator extends StatefulWidget {
  final IndicatorState state;
   DyScaleVideoLogic dyScaleVideoLogic = Get.find<DyScaleVideoLogic>();
   _CustomRefreshIndicator({
    required this.state,
  });

  @override
  State<_CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<_CustomRefreshIndicator> {
  @override
  Widget build(BuildContext context) {
    // logger.d("下拉刷新状态${widget.state.mode}");

    if (widget.dyScaleVideoLogic.indicatorMode.value != widget.state.mode) {
      widget.dyScaleVideoLogic.indicatorMode.value = widget.state.mode;
      widget.dyScaleVideoLogic.update();
    }

    if (widget.state.mode != IndicatorMode.processing) {
      return Container(
        width: double.infinity,
        height: widget.state.offset,
        alignment: Alignment.center,
        child: const SizedBox(),
      );
    }

    return Container(
      width: double.infinity,
      height: widget.state.offset,
      alignment: Alignment.center,
      child: const SizedBox(height: 60,),
    );
  }
} 