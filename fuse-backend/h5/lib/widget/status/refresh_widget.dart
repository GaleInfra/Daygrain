import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import '../../base/get_base_page_controller.dart';
import '../../res/my_color.dart';
import 'state_widget.dart';

/// @author: zx
/// @description: 上拉刷新、下拉加载控件
class RefreshWidget extends StatefulWidget {
  const RefreshWidget({
    Key? key,
    required this.logic,
    this.enablePullUp = true,
    this.enablePullDown = true,
    this.onRefresh,
    this.onLoadMore,
    required this.child,
    this.emptyWidget,
    this.emptyMsg,
    this.emptyButtonMsg,
    this.onEmptyRefresh,
    this.showEmptyBtn = true,
    this.errorMsg,
    this.errorButtonMsg,
    this.onRetry,
    this.tag,
    this.header,
    this.footer,
    this.autoNoMore = true,
    this.loadingWidget,
  }) : super(key: key);

  final Widget? loadingWidget;

  /// 控制器
  final GetBasePageController logic;

  ///是否启用上拉
  final bool enablePullUp;

  ///是否启用下拉
  final bool enablePullDown;

  ///下拉刷新回调
  final FutureOr Function()? onRefresh;

  ///上拉加载回调
  final FutureOr Function()? onLoadMore;

  /// 子级
  final Widget? child;

  /// 空页面
  final Widget? emptyWidget;

  final String? emptyMsg;

  final String? emptyButtonMsg;

  /// 空数据Widget 刷新方法，没有传入时默认调用[GetBasePageController]的 [initRefresh]方法
  final VoidCallback? onEmptyRefresh;

  final String? errorMsg;

  final String? errorButtonMsg;

  /// 是否展示空数据刷新按钮
  final bool showEmptyBtn;

  /// 错误Widget 重试方法，没有传入时默认调用[GetBasePageController]的 [initRefresh]方法
  final VoidCallback? onRetry;

  final String? tag;

  final Header? header;

  final Footer? footer;

  final bool autoNoMore;

  @override
  State<RefreshWidget> createState() => _RefreshWidgetState();
}

class _RefreshWidgetState extends State<RefreshWidget> {
  GetBasePageController get logic => widget.logic;

  /// 刷新控制器
  EasyRefreshController controller = EasyRefreshController();

  @override
  void initState() {
    logic.initController(controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EasyRefresh(
          controller: controller,
          onRefresh: logic.status.isSuccess && widget.enablePullDown
              ? () async {
                  await (widget.onRefresh?.call() ?? logic.onRefresh());
                }
              : null,
          onLoad: logic.status.isSuccess && widget.enablePullUp
              ? () async {
                  await (widget.onLoadMore?.call() ?? logic.onLoadMore(autoNoMore: widget.autoNoMore));
                }
              : null,
          header: widget.header ??
              ClassicHeader(
                textStyle: TextStyle(
                  color: MyColor.white,
                  fontSize: 9.sp,
                ),
                messageStyle: TextStyle(
                  color: MyColor.white.withValues(alpha: 0.5),
                  fontSize: 5.sp,
                ),
                dragText: "pull_to_refresh".bhTR,
                armedText: "release_to_refresh".bhTR,
                readyText: "refreshing".bhTR,
                processingText: "refreshing".bhTR,
                processedText: "refresh_completed".bhTR,
                noMoreText: "no_more_data".bhTR,
                failedText: "refresh_failed".bhTR,
                messageText: "${"last_updated".bhTR} %T",
                triggerOffset: 25.w,
                iconTheme: const IconThemeData(color: MyColor.white),
              ),
          footer: widget.footer ??
              ClassicFooter(
                textStyle: TextStyle(
                  color: MyColor.white,
                  fontSize: 9.sp,
                ),
                messageStyle: TextStyle(
                  color: MyColor.white.withValues(alpha: 0.5),
                  fontSize: 5.sp,
                ),
                infiniteOffset: null,
                dragText: "pull_up_load".bhTR,
                armedText: "release_to_load".bhTR,
                readyText: "loading".bhTR,
                processingText: "loading".bhTR,
                processedText: "load_completed".bhTR,
                noMoreText: "no_more_data".bhTR,
                failedText: "load_failed".bhTR,
                messageText: "${"last_updated".bhTR} %T",
                triggerOffset: 25.w,
                iconTheme: const IconThemeData(color: MyColor.white),
              ),
          child: logic.status.isSuccess ? widget.child ?? const SizedBox() : const SizedBox(),
        ),
        if (!logic.status.isSuccess)
          Center(
            child: _getStatusWidget(),
          ),
      ],
    );
  }

  Widget _getStatusWidget() {
    if (logic.status.isLoading) {
      return widget.loadingWidget ?? const LoadingWidget();
    }
    if (logic.status.isEmpty) {
      return widget.emptyWidget ??
          EmptyWidget(
            message: widget.emptyMsg,
            buttonText: widget.emptyButtonMsg,
            onRefresh: widget.showEmptyBtn ? widget.onEmptyRefresh ?? logic.initRefresh : null,
          );
    }
    if (logic.status.isError) {
      return OnErrorWidget(
        message: "something_wrong".bhTR,
        buttonText: widget.errorButtonMsg,
        onRefresh: widget.onRetry ?? logic.initRefresh,
      );
    }
    return const SizedBox();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
