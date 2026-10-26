import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/broadcaster/broadcaster_extra_info_model.dart';
import 'package:untitled1/model/gift/gift_model.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/utils/gift_util.dart';
import 'package:untitled1/utils/toast.dart';

import '../../../base/get_base_controller.dart';
import '../../../model/user/user_info_model.dart';

class BroadcasterDetailLogic extends GetBaseController {
  /// 当前主播的id
  String userId = "";

  /// 主播数据
  UserInfoModel? userInfo;
  int imageIndex = 0;
  /// 在线状态
  final onlineStatus = kOffline.obs;

  /// 礼物数据 和 标签数据
  BroadcasterExtraInfoModel? extraInfoModel;

  /// 礼物数量
  List<GiftModel> giftList = [];

  late StreamSubscription<OtherEvent> _otherEvent;

  final _videoCallLogic = Get.find<VideoCallHandler>();

  Timer? _getUserStatusTimer;

  CancelToken? infoCancelToken;
  CancelToken? extenCancelToken;

  StreamSubscription<UserStatusChangeEvent>? _userStatusEvent;

  /// 监听SayHiEvent
  StreamSubscription<SayHiEvent>? _sayHiEvent;

  @override
  void onInit() {
    logHandle.initLog('anchor_details');
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.follow == event.type && userId == event.data['userId']) {
        userInfo = userInfo?.copyWith(
          isFriend: event.data['follow'],
        );
        update();
      }
      if (OtherType.block == event.type && userId == event.data['userId']) {
        userInfo = userInfo?.copyWith(
          isBlock: event.data['block'],
        );
        update();
      }
    });
    _sayHiEvent = EventBusUtil.listen<SayHiEvent>((event) {
      if (event.broadcasterId == userId) {
        update();
      }
    });
    super.onInit();

    _userStatusEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (event.uidAndStatus.containsKey(userId)) {
        onlineStatus.value = event.uidAndStatus[userId] ?? kOffline;
      }
    });
  }

  void initData(UserInfoModel model) {
    userId = model.userId ?? "";
    userInfo = model;
    extraInfoModel = null;
    imageIndex = 0;
    giftList = [];
    update();
    handleCache();
    getInfo();
    getExtraInfo();
    if (GiftManager.to.giftList.isEmpty) {
      // 礼物列表为空，拉取
      GiftManager.to.getGift();
    }
    //先获取是否有有效期内的在线状态
    final tmpStatus = getUserStatusService()?.getStatus(userId);
    if (tmpStatus != null) {
      onlineStatus.value = tmpStatus;
    }
    //监听在线状态
    getUserStatusService()?.addUserIdAndForceRefresh(userId);


    // final anchorList = BaseManager.instance.anchorAllList;
    // List<String> newUserIds = anchorList.map((e) => e.userId!).toList();
    // getUserStatusService()?.addUserIdsAndRefresh(newUserIds);

  }

  void handleCache() {
    final user = CacheManager.userInfoCache(userId);
    final extraInfo = CacheManager.userExtendInfoCache(userId);
    if (extraInfo != null) {
      extraInfoModel = extraInfo;
    }
    if (user != null) {
      userInfo = user;
      if (extraInfo != null) {
        handleExtraInfo(isUpdate: false);
      }
      changeSuccess();
    }
  }

  /// 获取主播数据
  Future getInfo() async {
    infoCancelToken = CancelToken();
    await request.userGetInfo(
      userId: userId,
      cancelToken: infoCancelToken,
      onSuccess: (data) {
        userInfo = data;
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }

  /// 整理数据
  void handleExtraInfo({isUpdate = true}) {
    if (userInfo == null) return;
    final data = extraInfoModel;
    if (data != null) {
      giftList.clear();
      for (var item in data.giftList ?? <String>[]) {
        final code = item.substring(0, item.indexOf(":"));
        int imageIndex = GiftUtil.giftImageList.indexWhere((element) => element.name == code);
        if (imageIndex != -1) {
          giftList.add(
            GiftModel(
              code: code,
              count: int.parse(item.substring(item.indexOf(":") + 1)),
              sortNo: 0,
            ),
          );
        } else {
          print("===> 未找到 $item");
        }
      }
      if (isUpdate) {
        update();
      }
    }
  }

  /// 获取额外数据
  Future getExtraInfo() async {
    extenCancelToken = CancelToken();
    await request.userGetBroadcasterExtraInfo(
      userId: userId,
      cancelToken: extenCancelToken,
      onSuccess: (data) {
        extraInfoModel = data;
        handleExtraInfo();
      },
      onFail: (code, msg) {},
    );
  }

  /// 关注或取消关注结果回调（弹窗返回数据）
  void onFollowOrUnBack(bool result) async {
    int followNum = userInfo?.followNum ?? 0;
    if (result) {
      followNum++;
    } else {
      followNum--;
    }
    userInfo = userInfo?.copyWith(
      isFriend: result,
      followNum: followNum,
    );
    update();
  }

  /// 关注或取消关注
  Future onFollowOrUnFollow() async {
    if (userInfo?.isFriend ?? false) {
      // 取消关注
      await request.userUnfriend(
        userId: userId,
        onSuccess: (data) {
          int followNum = userInfo?.followNum ?? 0;
          userInfo = userInfo?.copyWith(
            isFriend: false,
            followNum: followNum == 0 ? 0 : followNum - 1,
          );
          update();
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userId,
            "follow": false,
          }));
          Toast.showMsg("status_unfollowSuccess".bhTR);
        },
        onFail: (code, msg) {},
      );
    } else {
      // 关注
      await request.userAddFriend(
        userId: userId,
        onSuccess: (data) {
          userInfo = userInfo?.copyWith(
            isFriend: true,
            followNum: (userInfo?.followNum ?? 0) + 1,
          );
          update();
          EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
            "userId": userId,
            "follow": true,
          }));
          Toast.showMsg("status_followSuccess".bhTR);
        },
        onFail: (code, msg) {},
      );
    }
  }

  /// 拉黑/取消拉黑返回
  void onBlockOrUnBack(bool result) async {
    userInfo = userInfo?.copyWith(
      isBlock: result,
    );
    update();
  }

  /// 视频通话呼叫
  void onVideoCall() async {
    _videoCallLogic.onCheckToCall(
      callSource: VideoCallSource.DETAIL_PAGE,
      onlineStatus: onlineStatus.value,
      userInfo: userInfo!,
    );
  }
  bool isBack = false;
  /// 退出当前页，回馈数据给上一页
  void onBack() {
    if(isBack) return;
    isBack = true;
    Get.back(result: {
      "userInfo": userInfo,
    });
  }

  @override
  void onClose() {
    _getUserStatusTimer?.cancel();
    _otherEvent.cancel();
    _userStatusEvent?.cancel();
    _userStatusEvent = null;
    _sayHiEvent?.cancel();
    _sayHiEvent = null;
    super.onClose();
  }
}
