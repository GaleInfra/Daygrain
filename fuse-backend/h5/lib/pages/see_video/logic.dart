import 'dart:async';

import 'package:get/get.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/see_video/widget/video_page_item.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/utils/toast.dart';

import '../../base/get_base_controller.dart';
import '../../common_logic/user_status_service.dart';

class SeeVideoLogic extends GetBaseController {
  /// 主播信息
  UserInfoModel? userInfo;

  /// 在线状态
  final onlineStatus = "".obs;

  /// 视频索引
  final index = 0.obs;

  /// 视频链接
  final List<String> urls = [];
  /// 视频图片
  final List<String> thumUrls = [];

  /// 视频子页面
  final List<VideoPageItem> itemList = [];

  final _videoLogic = Get.find<VideoCallHandler>();
  StreamSubscription<UserStatusChangeEvent>? _userStatusEvent;

  @override
  void onInit() {
    changeLoading();
    logHandle.initLog('video_preview');
    if (Get.arguments != null) {
      userInfo = Get.arguments['userInfo'];
      urls.addAll(Get.arguments['urls']);
      thumUrls.addAll(Get.arguments['thumUrls']);
      for (var item in urls) {
        itemList.add(VideoPageItem(
          url: item,
          index: urls.indexOf(item),
          thumUrl: thumUrls[urls.indexOf(item)],
        ));
      }
      index.trigger(Get.arguments['index']);
      update();
    }
    super.onInit();
  }

  @override
  void onReady() {
    initOnlineStatus();
    changeSuccess();
    super.onReady();
  }

  Future onFollowOrUnFollow() async {
    if (userInfo?.isFriend ?? false) {
      // 取消关注
      await request.userUnfriend(
        userId: userInfo?.userId ?? "",
        onSuccess: (data) {
          int followNum = userInfo?.followNum ?? 0;
          userInfo = userInfo?.copyWith(
            isFriend: false,
            followNum: followNum == 0 ? 0 : followNum - 1,
          );
          update();
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userInfo?.userId ?? "",
            "follow": false,
          }));
          Toast.showMsg("status_unfollowSuccess".bhTR);
        },
        onFail: (code, msg) {},
      );
    } else {
      // 关注
      await request.userAddFriend(
        userId: userInfo?.userId ?? "",
        onSuccess: (data) {
          userInfo = userInfo?.copyWith(
            isFriend: true,
            followNum: (userInfo?.followNum ?? 0) + 1,
          );
          update();
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userInfo?.userId ?? "",
            "follow": true,
          }));
          Toast.showMsg("status_followSuccess".bhTR);
        },
        onFail: (code, msg) {},
      );
    }
  }

  /// 获取在线状态
  Future initOnlineStatus() async {
    //读取缓存
    final tmpStatus = getUserStatusService()?.getStatus(userInfo?.userId ?? "");
    if (tmpStatus != null) {
      onlineStatus.value = tmpStatus;
    }
    //监听在线状态
    getUserStatusService()?.addUserIdAndForceRefresh(userInfo?.userId ?? "");

    //监听在线状态
    _userStatusEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (event.uidAndStatus.containsKey(userInfo?.userId ?? "")) {
        onlineStatus.value =
            event.uidAndStatus[userInfo?.userId ?? ""] ?? kOffline;
      }
    });
  }

  /// 呼叫
  void onCall() async {
    _videoLogic.onCheckToCall(
      callSource: VideoCallSource.DETAIL_VIDEO_PAGE,
      onlineStatus: onlineStatus.value,
      userInfo: userInfo!,
    );
  }

  @override
  void onClose() {
    _userStatusEvent?.cancel();
    super.onClose();
  }
}
