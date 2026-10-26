import 'dart:async';

import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/blocked_list_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/base/response_parse.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';

import '../../../utils/toast.dart';

class BlockedLogic extends GetBasePageController<BlockedListModel> {
  late StreamSubscription _otherEvent;
  @override
  void onInit() {
    
    super.onInit();
    logHandle.initLog('block_list');
  }
  @override
  void onReady() {
    initRefresh();
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.block == event.type) {
        initRefresh();
      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    _otherEvent.cancel();
    super.onClose();
  }

  /// 跳转详情
  void jumpDetail(BlockedListModel item) async {
    await BroadcasterDetailPage.to(UserInfoModel(
      userId: item.broadcasterId,
      avatar: item.avatar,
      nickname: item.nickName,
      age: item.age,
    ));
  }

  /// 暴露给外部的添加或删除
  /// [blocked] 添加拉黑
  void addOrRemove({
    required String userId,
    required bool blocked,
  }) {
    int index = list.indexWhere((element) => element.broadcasterId == userId);
    if (index != -1) {
      list.removeAt(index);
      update();
    }
    if (blocked) {
      // 添加操作，直接刷新
      onRefresh();
    }

    if (list.isEmpty) {
      changeEmpty();
    }
  }

  void unblock(String userId) async {
    await request.reportRemoveBlock(
      userId: userId,
      onSuccess: (data) {
        Toast.showMsg("status_unblockSuccessfully".bhTR);
        addOrRemove(userId: userId, blocked: false);
        RCMessageManager().removeBlock(userId);
      },
      onFail: (code, msg) {},
    );
  }

  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    request.reportBlockList(
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onChangeError,
    );
  }
}
