import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/infoflow/info_flow_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/base/response_parse.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/DyVideoHandleModel.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class DyScaleVideoLogic extends GetBasePageController<InfoFlowModel> {
  InfoFlowModel? model;
  bool _isDispose = false;

  /// 视频索引
  final index = 0.obs;
  Rx<DyVideoHandleModel?> currentItem = Rx<DyVideoHandleModel?>(null);
  final _videoCallLogic = Get.find<VideoCallHandler>();
  AppConfigManager? appConfig;
  Rx<IndicatorMode> indicatorMode = Rx<IndicatorMode>(IndicatorMode.inactive);
  //状态
  final userStatus = kOffline.obs;
  StreamSubscription? _userStateEvent;
  List<DyVideoHandleModel> itemModels = [];
  late StreamSubscription<OtherEvent> _otherEvent;
  final PageController pageController = PageController();

  int prePage = -1;
  bool isPreRequesting = false;
  RxBool isRefreshing = false.obs;

  int isPreCurrentPage = 0;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // onRequest(page);
    _userStateEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (currentItem.value != null &&
          event.uidAndStatus
              .containsKey(currentItem.value?.item.userId ?? "")) {
        userStatus.value =
            event.uidAndStatus[currentItem.value?.item.userId ?? ""] ??
                kOffline;
      }
    });
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.follow == event.type &&
          currentItem.value?.item.userId == event.data['userId']) {
        currentItem.value?.item.isFriend = event.data['follow'];
        update();
      }
    });
    pageController.addListener(() {
      if (pageController.position.maxScrollExtent -
              pageController.position.pixels <=
          (Get.height) * 3) {
        // 当距离底部不足100像素且不在加载状态且有更多数据时触发加载更多
        if (prePage != (page + 1) &&
            !isPreRequesting &&
            isPreCurrentPage != index.value) {
          // if (!this.isPreCan) {
          //   this.isPreCan = true;
          //   return;
          // }
          // this.isPreCan = false;
          logger.d("测试预加载:$prePage--$page");
          isPreCurrentPage = index.value;
          onRequestInfo_flows(page: page + 1, isPreRequest: true);
        }
      }
    });
  }

  void closeWakelock() async {
    await WakelockPlus.disable();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    final appConfig = Get.find<AppConfigManager>();
    if (appConfig.infoFlowList.isEmpty) {
      initRefresh();
    } else {
      list.clear();
      list.addAll(appConfig.infoFlowList);
      getUsersAvatar(appConfig.infoFlowList);
      for (int i = 0; i < list.length; i++) {
        DyVideoHandleModel model =
            DyVideoHandleModel(item: list[i], itemIndex: i);
        itemModels.add(model);
      }
      if (!_isDispose) {
        refreshController?.finishRefresh(IndicatorResult.success, true);
      }
      // if (!_isDispose) refreshController?.finishLoad(noMore: list.length < limit);
      changeListSuccess();
      if (listImpactPage) changeSuccess(isUpdate: false);
      if (list.isNotEmpty && page == 1) {
        currentItem.value = itemModels.first;

        currentItem.value?.initializeVideo();
        getUserStatusService()
            ?.addUserIdAndForceRefresh(currentItem.value?.item.userId ?? "");
        getUserStatusService()
            ?.addUserIdAndForceRefresh(currentItem.value?.item.userId ?? "");
      }
      update();
    }
    //直接显示当前数据
  }

  @override
  void onClose() {
    // TODO: implement onClose
    _isDispose = true;
    super.onClose();
  }

  // bool isRefreshing = false;

  // void onMore() {
  //   page++;
  //   onRequest(page);
  // }
  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    onRequestInfo_flows(page: page);
    // await onRequestInfoFlow(page: page);
  }

  Future onRequestInfo_flows({int page = 1, bool isPreRequest = false}) async {
    if (page == 1) {
      if (isRefreshing.value) {
        return;
      }
      isRefreshing.value = true;
      prePage = -1;
      isPreRequesting = false;
    }
    if (page == prePage && isPreRequesting && !isPreRequest) {
      //等待预加载完成
      return;
    }

    if (isPreRequest) {
      isPreRequesting = true;
      prePage = page;
    }

    await request.getInfo_flows(
        params: {"limit": 20, "page": page},
        page: page,
        onSuccess: (data) {
          if (isPreRequest) {
            isPreRequesting = false;
          }
          loadOnSuccess(page: page, data, isPreRequest: isPreRequest);

          // if (list.isNotEmpty && page == 1) {
          //   currentItem.value = list.first;
          //   getUserStatusService()?.addUserIdAndForceRefresh(
          //       currentItem?.value?.userId ?? "");
          //   update();
          // }
        },
        onFail: (code, msg) {
          loadOnFail(
              page: page, isPreRequest: isPreRequest, code: code, msg: msg);
        });
  }

  void loadOnFail(
      {int page = 1,
      bool isPreRequest = false,
      int code = 0,
      String msg = ""}) {
    if (isPreRequest && this.page != page) {
      //预加载完成
    } else {
      //当前正在加载的和预加载的是同一页，完成，开启下一页的加载
      if (page == 1) {
        isRefreshing.value = false;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (isRefreshing.value) {
            return;
          }
        });

        changeListError(msg: msg);
        if (listImpactPage) onChangeError(code, msg, isUpdate: false);
      } else {
        if (!isPreRequest) {
          refreshController?.finishLoad(IndicatorResult.fail, true);
        }
      }
    }
  }

  void loadOnSuccess(List<InfoFlowModel> data,
      {int page = 1, isPreRequest = false}) {
    isPreRequesting = false;
    getUsersAvatar(data);
    var l = <InfoFlowModel>[];
    // 第一次去重
    for (var user in data) {
      // bool result = !l.any((element) => element.userId == user.userId); // 返回集去重
      // bool olsList = page == 1
      //     ? true
      //     : !list.any((element) => element.userId == user.userId); // 以前数据去重
      // if (result && olsList) {
      //   l.add(user);
      // }
      l.add(user);
    }

    if (page == 1) {
      isRefreshing.value = false;
      for (int i = 0; i < itemModels.length; i++) {
        DyVideoHandleModel model = itemModels[i];
        model.dispose();
      }
      itemModels.clear();
    }

    //延迟200毫秒，防止闪屏
    if (page == 1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (isRefreshing.value) {
          return;
        }
      });
    }

    if (isPreRequest && this.page != page) {
      //预加载完成
      if (page == 1) {
        itemModels.clear();
        list.clear();
        list.addAll(l);
        for (int i = 0; i < list.length; i++) {
          DyVideoHandleModel model =
              DyVideoHandleModel(item: list[i], itemIndex: i);
          itemModels.add(model);
        }
        if (itemModels.isNotEmpty) {
          currentItem.value = itemModels.first;
          currentItem.value?.initializeVideo();
        }
      } else {
        if (l.isNotEmpty) {
          for (int i = 0; i < l.length; i++) {
            DyVideoHandleModel model =
                DyVideoHandleModel(item: l[i], itemIndex: list.length + i);
            itemModels.add(model);
          }
          list.addAll(l);
          
        } else {
          this.page--;
          if (!_isDispose) {
            refreshController?.finishLoad(IndicatorResult.noMore, true);
          }
        }
      }
      this.page = page;
    } else {
      //当前正在加载的和预加载的是同一页，完成，开启下一页的加载
      if (page == 1) {
        if (l.isEmpty) {
          // 集合为空
          // 列表数据不影响页面时，不关闭下拉刷新
          if (!_isDispose) {
            refreshController?.finishRefresh(IndicatorResult.noMore, true);
          }
          // if (!_isDispose) refreshController?.finishLoad(noMore: true);
          itemModels.clear();
          list.clear();
          changeListEmpty();
          if (listImpactPage) changeEmpty();
        } else {
          itemModels.clear();
          list.clear();
          list.addAll(l);
          for (int i = 0; i < list.length; i++) {
            DyVideoHandleModel model =
                DyVideoHandleModel(item: list[i], itemIndex: i);
            itemModels.add(model);
          }
          if (itemModels.isNotEmpty) {
            currentItem.value = itemModels.first;
            currentItem.value?.initializeVideo();
          }
          if (!_isDispose) {
            refreshController?.finishRefresh(IndicatorResult.success, true);
          }
          // if (!_isDispose) refreshController?.finishLoad(noMore: list.length < limit);
          changeListSuccess();
          if (listImpactPage) changeSuccess(isUpdate: false);
        }
      } else {
        if (l.isEmpty) {
          // 集合为空
          this.page--;
          if (!_isDispose) {
            refreshController?.finishLoad(IndicatorResult.noMore, true);
          }
        } else {
           for (int i = 0; i < l.length; i++) {
            DyVideoHandleModel model =
                DyVideoHandleModel(item: l[i], itemIndex: list.length + i);
            itemModels.add(model);
          }
          list.addAll(l);
         
          if (!_isDispose) {
            refreshController?.finishLoad(IndicatorResult.success, true);
          }
          changeListSuccess();
          if (listImpactPage) changeSuccess(isUpdate: false);
        }
      }
    }

    update();
  }

  void getUsersAvatar(List<InfoFlowModel> list) async{
    if (list.isEmpty) {
      return;
    }
    List<String> userIds = [];
    for (var element in list) {
      if (!list.contains(element.userId ?? "")) {
        userIds.add(element.userId ?? "");
      }
    }
    if (userIds.isEmpty) {
      return;
    }
    List<String> newUserIds = [];
    for (var element in userIds) {
      newUserIds.add(element);
    }
    if (!newUserIds.contains(currentItem.value?.item.userId ?? "")) {
      newUserIds.add(currentItem.value?.item.userId ?? "");
    }
    getUserStatusService()
        ?.addUserIdsAndRefresh(newUserIds);
    await request.getUsersAvatars(params: userIds, page: page, onSuccess: (data) {
      for (var element in data) {
        for (var item in this.list) {
          if (element.userId == item.userId) {
            item.avatar = element.avatarUrl;
          }
        }
      }
      update();
    }, onFail: (code, msg) {

    });

  }


  void onAvatarTap() {
    if (currentItem.value?.item.userId?.isEmpty ?? true) {
      return;
    }
    BroadcasterDetailPage.to(UserInfoModel(
      userId: currentItem.value?.item.userId ?? "",
      avatar: currentItem.value?.item.avatar ?? "",
      nickname: currentItem.value?.item.nickname ?? "",
      age: currentItem.value?.item.age ?? 0,
    ));
  }

  void onFollowTouch() async {
    if (currentItem.value?.item.userId?.isEmpty ?? true) {
      return;
    }
    // 关注
    await request.userAddFriend(
      userId: currentItem.value?.item.userId ?? "",
      onSuccess: (data) {
        currentItem.value?.item.isFriend = true;
        EventBusUtil.fire(OtherEvent(type: OtherType.follow, data: {
          "userId": currentItem.value?.item.userId ?? "",
          "follow": true,
        }));
        Toast.showMsg("status_followSuccess".bhTR);
        currentItem.trigger(currentItem.value);
      },
      onFail: (code, msg) {},
    );
  }

  void onVideoCall() async {
    _videoCallLogic.onCheckToCall(
      callSource: VideoCallSource.DETAIL_PAGE,
      onlineStatus: userStatus.value,
      userInfo: UserInfoModel(
        userId: currentItem.value?.item.userId ?? "",
        nickname: currentItem.value?.item.nickname ?? "",
        unitPrice: currentItem.value?.item.callCoins ?? 0,
        // 身份为VIP时，下发的金币数已经是打了九折的
        vipUnitPrice: currentItem.value?.item.callCoins ?? 0,
        age: currentItem.value?.item.age ?? 0,
        country: currentItem.value?.item.country ?? "",
        avatarUrl: currentItem.value?.item.avatar ?? "",
      ),
    );
  }
}
