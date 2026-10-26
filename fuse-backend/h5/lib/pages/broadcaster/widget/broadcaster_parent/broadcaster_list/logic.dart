import 'dart:async';
import 'dart:convert';

import 'package:card_swiper/card_swiper.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/business/say_hi/robot_script_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/banner_strong_guide_logic.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/base/response_parse.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/res/video_call_data.dart';

import '../../../../../event_bus/app_lifecycle_state_event.dart';
import '../../../../../model/broadcaster/broadcaster_model.dart';

class BroadcasterListLogic extends GetBasePageController<BroadcasterModel> {
  final _appConfig = Get.find<AppConfigManager>();

  late String category;

  late String apiTag;

  final _videoLogic = Get.find<VideoCallHandler>();

  /// 显示banner
  bool showBanner = false;

  // 页面是否显示
  RxBool pageShow = false.obs;
  // 当前选中的国家
  String countryCode = "All";

  StreamSubscription? _otherEvent;
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleStateEvent;

  SwiperController? swiperController;

  ScrollController scrollController = ScrollController();

  //预加载主播墙数据
  List<BroadcasterModel> preList = [];
  int prePage = -1;
  bool isPreRequesting = false;
  bool _isDispose = false;
  Worker? worker;
  void initData(String category, String tag) async {
    pageShow.trigger(true);
    this.category = category;
    apiTag = tag;
    // 判断当前页面是否需要显示banner
    // 大标签为第一位 && 小标签为第一位
    if (_appConfig.strategyModel?.broadcasterWallTagList?.indexWhere((element) => element.tagName == category) == 0 &&
        _appConfig.strategyModel?.broadcasterWallTagList?.first.subTagList?.indexWhere((element) => apiTag == element) == 0) {
      showBanner = true;
    }
    if (list.isEmpty) {
      final cachedWall = SPUtil.getString('cached_wall_v1_${category}_$apiTag');
      if (cachedWall.isNotEmpty) {
        try {
          final decoded = (jsonDecode(cachedWall) as List)
              .map((e) => BroadcasterModel.fromJson(e))
              .toList();
          if (decoded.isNotEmpty) {
            list.addAll(decoded);
            changeSuccess();
            onRequestWall(page: 1);
          }
        } catch (_) {}
      }
      if (list.isEmpty) await initRefresh();
    }
    if (_otherEvent != null) {
      _otherEvent?.cancel();
      _otherEvent = null;
    }
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.follow == event.type && category == "Followed") {
        onRefresh();
      }
      // 显示banner即为第tab
      if (OtherType.broadcasterCountry == event.type && showBanner) {
        onChangeCountryCode(event.data);
      }
    });
    // refreshController?.callLoad(overOffset: 100,scrollController: scrollController,force: false);
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent - scrollController.position.pixels <= 250 * 3) {
        // 当距离底部不足100像素且不在加载状态且有更多数据时触发加载更多

        if (prePage != (page + 1) && !isPreRequesting) {
          onRequestWall(page: page + 1, isPreRequest: true);
        }
      }
    });
  }

  @override
  void onInit() {
    limit = 10;
    super.onInit();
  }

  @override
  Future<void> onRefresh() async {
    // 刷新时，销毁定时器
    // onCancelTimer();
    if (showBanner) {
      Get.find<BannerStrongGuideLogic>().onInitData();
      swiperController ??= SwiperController();
    }
    return super.onRefresh();
  }

  /// 呼叫
  void onCall(BroadcasterModel item) async {
    _videoLogic.onCheckToCall(
      callSource: VideoCallSource.POPULAR_WALL,
      onlineStatus: item.status ?? "",
      userInfo: UserInfoModel(
        userId: item.userId,
        nickname: item.nickname,
        unitPrice: item.callCoins,
        // 身份为VIP时，下发的金币数已经是打了九折的
        vipUnitPrice: item.callCoins,
        age: item.age,
        country: item.country,
        avatarUrl: item.avatar,
      ),
    );
  }

  void onChangeCountryCode(String code) {
    countryCode = code;
    changeLoading();
    // 调用父级的刷新，不刷新banner
    super.onRefresh();
  }

  @override
  void onClose() {
    _appLifecycleStateEvent?.cancel();
    worker?.dispose();
    _otherEvent?.cancel();
    _isDispose = true;
    super.onClose();
  }

  bool isRefreshing = false;
  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    await onRequestWall(page: page);
  }

  Future onRequestWall({int page = 1, bool isPreRequest = false}) async {
    if (page == 1) {
      if (isRefreshing) {
        return;
      }
      isRefreshing = true;
      swiperController?.stopAutoplay();
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

    Future<List<BroadcasterModel>> _fallbackBroadcasters() async {
      const officialIds = <String>[
        "1961011549309108224",
        "1961011441205116928",
        "1961011258434125824",
        "1961011140259610624",
        "1961010995912638464",
      ];
      final completer = Completer<List<BroadcasterModel>>();
      request.getUsersAvatars(
        params: officialIds,
        page: 1,
        onSuccess: (avatars) {
          completer.complete(avatars
              .map((a) => BroadcasterModel(
                    userId: a.userId,
                    nickname: a.nickname,
                    avatar: a.avatarUrl ?? a.avatar,
                    avatarThumbUrl: a.avatarUrl ?? a.avatar,
                    status: "1",
                    age: 23,
                  ))
              .toList());
        },
        onFail: (_, __) => completer.complete(const []),
      );
      return completer.future;
    }

    await request.wallSearch(
      category: category,
      tag: apiTag,
      region: countryCode,
      page: page,
      limit: limit,
      onSuccess: (data) async {
        if (isPreRequest) {
          isPreRequesting = false;
        }
        var items = data;
        if (items.isEmpty && page == 1) {
          items = await _fallbackBroadcasters();
        }
        loadOnSuccess(page: page, items, isPreRequest: isPreRequest);
      },
      onFail: (code, msg) {
        loadOnFail(page: page, isPreRequest: isPreRequest, code: code, msg: msg);
      },
    );
  }

  void loadOnFail({int page = 1, bool isPreRequest = false, int code = 0, String msg = ""}) {
    if (isPreRequest && this.page != page) {
      //预加载完成
    } else {
      //当前正在加载的和预加载的是同一页，完成，开启下一页的加载
      if (page == 1) {
        isRefreshing = false;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (isRefreshing) {
            return;
          }
          swiperController?.startAutoplay();
        });

        changeListError(msg: msg);
        if (listImpactPage) onChangeError(code, msg, isUpdate: false);
      } else {
        if (!isPreRequest) {
          refreshController?.finishLoad(IndicatorResult.fail, true);
        }
      }
    }

    if (isPreRequest) {
      isPreRequesting = false;
      prePage = -1;
    }
  }

  void loadOnSuccess(List<BroadcasterModel> data, {int page = 1, isPreRequest = false}) {
    isPreRequesting = false;

    var l = <BroadcasterModel>[];
    // 第一次去重
    for (var user in data) {
      bool result = !l.any((element) => element.userId == user.userId); // 返回集去重
      bool olsList = page == 1 ? true : !list.any((element) => element.userId == user.userId); // 以前数据去重
      if (result && olsList) {
        //处理 国家数据
        if (user.country != null && user.country!.isNotEmpty) {
          if (Get.find<AppConfigManager>().nameByEmoji.containsKey(user.country!)) {
            user.countryAndEmoji = "${Get.find<AppConfigManager>().nameByEmoji[user.country]}${user.country}";
          } else if (Get.find<AppConfigManager>().codeByEmoji.containsKey(user.country!)) {
            user.countryAndEmoji = "${Get.find<AppConfigManager>().codeByEmoji[user.country]}${user.country}";
          } else {
            user.countryAndEmoji = user.country!;
          }
        }

        l.add(user);
      }
    }
    if (page == 1) {
      isRefreshing = false;
      if (l.isNotEmpty) {
        try {
          SPUtil.setString(
            'cached_wall_v1_${category}_$apiTag',
            jsonEncode(l.map((e) => e.toJson()).toList()),
          );
        } catch (_) {}
      }
    }

    //延迟200毫秒，防止闪屏
    if (page == 1) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (isRefreshing) {
          return;
        }
        swiperController?.startAutoplay();
      });
    }

    if (isPreRequest && this.page != page) {
      //预加载完成
      if (page == 1) {
        list.clear();
        list.addAll(l);
      } else {
        if (l.isNotEmpty) {
          list.addAll(l);
        } else {
          this.page--;
          if (!_isDispose) refreshController?.finishLoad(IndicatorResult.noMore, true);
        }
      }
      this.page = page;
    } else {
      //当前正在加载的和预加载的是同一页，完成，开启下一页的加载
      if (page == 1) {
        if (l.isEmpty) {
          // 集合为空
          // 列表数据不影响页面时，不关闭下拉刷新
          if (!_isDispose) refreshController?.finishRefresh(IndicatorResult.noMore, true);
          // if (!_isDispose) refreshController?.finishLoad(noMore: true);
          list.clear();
          changeListEmpty();
          if (listImpactPage) changeEmpty();
        } else {
          list.clear();
          list.addAll(l);
          if (!_isDispose) refreshController?.finishRefresh(IndicatorResult.success, true);
          // if (!_isDispose) refreshController?.finishLoad(noMore: list.length < limit);
          changeListSuccess();
          if (listImpactPage) changeSuccess(isUpdate: false);
        }
      } else {
        if (l.isEmpty) {
          // 集合为空
          this.page--;
          if (!_isDispose) refreshController?.finishLoad(IndicatorResult.noMore, true);
        } else {
          list.addAll(l);
          if (!_isDispose) refreshController?.finishLoad(IndicatorResult.success, true);
          changeListSuccess();
          if (listImpactPage) changeSuccess(isUpdate: false);
        }
      }
    }
    update();
  }

  void onSayHi(BroadcasterModel item) {

    Get.find<RobotScriptManager>().onSayHiPressed([SayHiRecommendBroadcasterModel.fromBroadcasterModel(item)]);
    update();
  }

  void onChat(BroadcasterModel item) {
    // 跳转聊天页面
    MessageChatPage.to(UserInfoModel(userId: item.userId, nickname: item.nickname, avatarUrl: item.avatar));
  }
}
