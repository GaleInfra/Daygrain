import 'dart:async';

import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/base/response_parse.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';

import '../../../model/message/follow/friend_list_model.dart';

class FollowListLogic extends GetBasePageController<FriendListModel> {
  late StreamSubscription<OtherEvent> _otherEvent;

  @override
  void onReady() {
    initRefresh();
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.follow == event.type) {
        // 刷新
        if (event.data["follow"] == false) {
           String userId = event.data["userId"];
           for (int i = 0; i < list.length; i++) {
             if (list[i].userId == userId) {
               list.removeAt(i);
               update();
               break;
             }
           }
        }else {
          initRefresh();
        }


      }
    });
    super.onReady();
  }

  @override
  void onClose() {
    _otherEvent.cancel();
    super.onClose();
  }

  /// 跳转主播详情
  void onJumpDetail(FriendListModel item) {
    BroadcasterDetailPage.to(UserInfoModel.fromJson(item.toJson()));
  }

  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    await request.userGetFriendList(
      page: page,
      limit: limit,
      onSuccess: onSuccess,
      onFail: onFail,
    );
  }
}
