import 'package:easy_refresh/easy_refresh.dart';
import 'package:get/get.dart';

import '../net/base/response_parse.dart';
import 'get_base_controller.dart';

/// @author: zx
/// @description: 分页控制器基类 controller
abstract class GetBasePageController<T> extends GetBaseController {
  /// 当前页数
  int page = 1;

  ///
  int limit = 20;

  List<T> list = [];

  /// 是否销毁
  bool _isDispose = false;

  /// 列表状态
  RxStatus listStatus = RxStatus.loading();

  /// 列表影响页面，true: 列表结果直接改变页面状态  false: 仅影响列表状态
  bool listImpactPage = true;

  /// 刷新控制器
  EasyRefreshController? refreshController;

  /// 初始化控制器
  Future initController(EasyRefreshController controller) async {
    refreshController = controller;
  }

  /// 初次刷新
  Future<void> initRefresh({bool showLoading = true}) async {
    page = 1;
    if (showLoading) {
      changeListLoading();
      if (listImpactPage) changeLoading();
    }
    await onRefresh();
  }

  /// 刷新
  Future<void> onRefresh() async {
    page = 1;
    refreshController?.resetHeader();
    refreshController?.resetFooter();
    await onRequest((value) {
      List<T> data = value;
      if (data.isEmpty) {
        // 集合为空
        // 列表数据不影响页面时，不关闭下拉刷新
        if (!_isDispose) refreshController?.finishRefresh(IndicatorResult.noMore, true);
        // if (!_isDispose) refreshController?.finishLoad(noMore: true);
        list.clear();
        changeListEmpty();
        if (listImpactPage) changeEmpty();
      } else {
        list.clear();
        list.addAll(data);
        if (!_isDispose) refreshController?.finishRefresh(IndicatorResult.success, true);
        // if (!_isDispose) refreshController?.finishLoad(noMore: list.length < limit);
        changeListSuccess();
        if (listImpactPage) changeSuccess(isUpdate: false);
      }
      update();
    }, (code, msg) {
      changeListError(msg: msg);
      if (listImpactPage) onChangeError(code, msg, isUpdate: false);
    }, page: page);
  }

  /// 加载更多
  /// [autoNoMore] 无更多数据时，自动改变控制器状态
  Future<void> onLoadMore({
    bool autoNoMore = true,
  }) async {
    await onRequest((value) {
      List<T> data = value;
      if (data.isEmpty) {
        // 集合为空
        page--;
        if (!_isDispose) refreshController?.finishLoad(IndicatorResult.noMore, true);
      } else {
        list.addAll(data);
        if (!_isDispose) refreshController?.finishLoad(IndicatorResult.success, true);
        changeListSuccess();
        if (listImpactPage) changeSuccess(isUpdate: false);
      }
      // update();
    }, (code, msg) {
      page--;
      if (!_isDispose) refreshController?.finishLoad(IndicatorResult.fail, true);
      // onChangeError(code, msg);
    }, page: ++page);
  }

  /// 网络请求
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1});

  changeListLoading() {
    listStatus = RxStatus.loading();
    update();
  }

  changeListSuccess() {
    listStatus = RxStatus.success();
    // update();
  }

  changeListEmpty() {
    listStatus = RxStatus.empty();
    update();
  }

  changeListError({String? msg}) {
    listStatus = RxStatus.error(msg);
    // update();
  }

  @override
  update([List<Object>? ids, bool condition = true]) {
    if (!_isDispose) {
      super.update(ids, condition);
    }
  }

  @override
  void onClose() {
    _isDispose = true;
    super.onClose();
  }
}
