import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';

import '../net/request_repository.dart';

/// @author: zx
/// @description: Controller 基类
class GetBaseController extends GetxController with StateMixin {
  /// 请求仓库
  late RequestRepository request;

  /// 是否销毁
  bool _isDispose = false;

  // DateTime? inTime;
  //
  // String pageEvent = '';
  // String subPage = '';
  // String terPage = '';
  // bool isUploadLog = false;
  // bool isHaveLoad = false;
  // AppConfigManager? appConfigManager;
  //
  //
  // late StreamSubscription<PageEvent> _pageEvent;
  ///
  String? tag;

  LogHandle logHandle = LogHandle();

  @override
  void onInit() {
    request = Get.find<RequestRepository>();
    logHandle.initEvent();
    super.onInit();
  }


  changeSuccess({bool isUpdate = true}) {
    change(null, status: RxStatus.success());
    if (isUpdate) update();
  }

  changeLoading({bool isUpdate = true}) {
    change(null, status: RxStatus.loading());
    if (isUpdate) update();
  }

  changeEmpty({bool isUpdate = true}) {
    change(null, status: RxStatus.empty());
    if (isUpdate) update();
  }

  /// 接口报错时处理
  onChangeError(int code, String msg, {bool isUpdate = true}) {
    change(null, status: RxStatus.error(msg));
    if (isUpdate) update();
  }

  @override
  update([List<Object>? ids, bool condition = true]) {
    if (!_isDispose) {
      //获取帧后更新
      if (kIsWeb) {
        Future.delayed(const Duration(microseconds: 100)).then((value) {
          super.update(ids, condition);
        });
      } else {
        super.update(ids, condition);
      }
    }
  }



  @override
  void onClose() {
    _isDispose = true;
    // request.removeCancelTokenListener(runtimeType.toString(), tag: tag);

    logHandle.onClose();

    super.onClose();
  }

}
