import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base/get_base_controller.dart';
import 'state_widget.dart';

/// @author: zx
/// @description: 页面状态组件
class PageStatusWidget<Controller extends GetBaseController> extends StatelessWidget {
  const PageStatusWidget({
    Key? key,
    required this.child,
    required this.logic,
    this.emptyMsg,
    this.emptyButtonMsg,
    this.onRefresh,
    this.errorMsg,
    this.errorButtonMsg,
    this.onRetry,
  }) : super(key: key);

  final Widget child;

  final GetBaseController logic;

  final String? emptyMsg;

  final String? emptyButtonMsg;

  /// 空数据Widget 刷新方法，没有传入时默认调用[GetBaseController]的 [onReady]方法
  final VoidCallback? onRefresh;

  final String? errorMsg;

  final String? errorButtonMsg;

  /// 错误Widget 重试方法，没有传入时默认调用[GetBaseController]的 [onReady]方法
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return logic.obx(
      (state) => child,
      onLoading: const Center(child: LoadingWidget()),
      onEmpty: Center(
        child: EmptyWidget(
          message: emptyMsg,
          buttonText: emptyButtonMsg,
          onRefresh: onRefresh ?? logic.onReady,
        ),
      ),
      onError: (error) => Center(
        child: OnErrorWidget(
          message: errorMsg ?? error,
          buttonText: errorButtonMsg,
          onRefresh: onRetry ?? logic.onReady,
        ),
      ),
    );
  }
}
