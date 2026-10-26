import 'package:dio/dio.dart';

import '../../utils/toast.dart';
import 'network_exception.dart';
import 'request_client.dart';
import 'response_parse.dart';

typedef GetCancelToken = Function(String type, CancelToken token);

/// @author: zx
/// @description: 仓库基类
class BaseRepository {
  // /// cancelToken 数据
  // /// key: 绑定的对象名称，如页面（需要注意，如果是多个同名页面[例如pageView共用页面]，需要利用tag以区分开）
  // /// value: 该对象里发起的所有请求的cancelToken
  // final Map<String, List<CancelToken>> _cancelMap = {};

  // /// 绑定统一管理取消请求方法
  // /// [objectName] 绑定的对象名称
  // /// [tag] 当同对象名时，使用tag区分
  // void addCancelTokenListener(String objectName, {String? tag}) {
  //   _cancelMap.addAll({"$objectName${tag ?? ""}": []});
  // }

  // /// 解除统一管理取消请求绑定
  // void removeCancelTokenListener(String objectName, {String? tag}) {
  //   String key = "$objectName${tag ?? ""}"; // 对象名称
  //   // 存在该对象
  //   if (_cancelMap.keys.any((element) => element == key)) {
  //     _cancelMap[key]?.forEach((element) {
  //       // 取消当前页所有绑定的请求，包括已经完成的请求
  //       if (!element.isCancelled) {
  //         element.cancel("退出");
  //       }
  //     });
  //     _cancelMap.remove(key);
  //   }
  // }

  Future GET(
    String url, {
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    required Success onSuccess,
    Fail? onFail,
    bool clickMaskDismiss = true,
    bool showLoading = false,
    bool showErrorTip = false,
    bool showTip = false,
    bool bindPage = true,
  }) async {
    await _request(
      url,
      options: options,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSuccess: onSuccess,
      onFail: onFail,
      clickMaskDismiss: clickMaskDismiss,
      showLoading: showLoading,
      showErrorTip: showErrorTip,
      showTip: showTip,
      bindPage: bindPage,
    );
  }

  Future POST(
    String url, {
    Options? options,
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required Success onSuccess,
    Fail? onFail,
    bool clickMaskDismiss = true,
    bool showLoading = false,
    bool showErrorTip = false,
    bool showTip = false,
    bool bindPage = true,
  }) async {
    await _request(
      url,
      method: Method.post,
      options: options,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      onSuccess: onSuccess,
      onFail: onFail,
      clickMaskDismiss: clickMaskDismiss,
      showLoading: showLoading,
      showErrorTip: showErrorTip,
      showTip: showTip,
      bindPage: bindPage,
    );
  }

  /// [showErrorTip] 显示错误toast
  /// [showTip] 显示接口返回msg
  /// [bindPage] 请求是否绑定页面生命周期
  Future _request(
    String url, {
    Method method = Method.get,
    Options? options,
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required Success onSuccess,
    Fail? onFail,
    bool clickMaskDismiss = true,
    bool showLoading = false,
    bool showErrorTip = false,
    bool showTip = false,
    bool bindPage = true,
  }) async {
    //屏蔽页面绑定
    bindPage = false;
    // cancelToken ??= CancelToken();
    bool loading = true;
    // if (bindPage && _cancelMap.isNotEmpty) {
    //   // 从路由上看，一般最后一个是当前页面
    //   _cancelMap[_cancelMap.keys.last]?.add(cancelToken);
    // }
    if (showLoading) {
      Toast.showLoading(
        clickMaskDismiss: clickMaskDismiss,
        onDismiss: () {
          // if (loading) cancelToken?.cancel("取消请求");
        },
      );
    }
    await RequestClient.getInstance().request(url,
        method: method,
        options: options,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress, onSuccess: (data) {
      if (showLoading) {
        Toast.dismiss();
        loading = false;
      }
      /* try {
          onSuccess.call(data);
        } catch (e) {
          logger.e("接口获取成功，但发生了其他错误===> $e");
          onFail?.call(-1, "错误啦~");
        }*/
      onSuccess.call(data);
    }, onFail: (code, msg) {
      if (showLoading) {
        Toast.dismiss();
        loading = false;
      }
      if (showLoading && code == HttpExceptionCode.cancelError) {
        // 显示加载loading且取消请求
      } else if (showErrorTip &&
          code != HttpExceptionCode.cancelError &&
          code > 0 &&
          HttpExceptionCode.timeoutError != code) {
        Toast.showMsg(msg);
      }
      onFail?.call(code, msg);
    }, onMessageBack: (msg) {
      if (showTip) Toast.showMsg(msg);
    });
  }
}
