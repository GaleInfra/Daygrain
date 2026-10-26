import 'dart:async';
import 'dart:ui';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/rc_conversation/rc_conversation_top_status_event.dart';
import 'package:untitled1/net/base/response_parse.dart';
import 'package:untitled1/rong_cloud/rc_conversations_manager.dart';

import '../../../common_logic/cache_manager.dart';
import '../../../event_bus/rc_conversation/rc_appoint_conversation_event.dart';
import '../../../event_bus/rc_conversation/rc_clear_unread_event.dart';
import '../../../event_bus/rc_conversation/rc_conversations_event.dart';
import '../../../event_bus/rc_conversation/rc_remove_conversation_event.dart';
import '../../../js/Model/JSConversation.dart';
import '../../../model/user/user_info_model.dart';

class MessageListLogic extends GetBasePageController<JSConversation> {
  /// 用户数据map
  final Map<String, UserInfoModel?> userInfoMap = {};

  /// 会话列表监听
  StreamSubscription<RCConversationsEvent>? _conversationEvent;

  /// 获取指定会话监听
  StreamSubscription<RCAppointConversationEvent>? _appointEvent;

  /// 清除指定会话未读数监听
  StreamSubscription<RCClearUnreadEvent>? _clearUnreadEvent;

  /// 删除指定会话未读数监听
  StreamSubscription<RCRemoveConversationEvent>? _removeEvent;

  /// 置顶监听
  StreamSubscription<RCConversationsTopStatusEvent>? _topEvent;

  //监听前后台切换
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleEvent;

  final appConfig = Get.find<AppConfigManager>();

  @override
  void onInit() {
    _onGetTopSystem();
    super.onInit();
  }

  @override
  void onReady() {
    _initEvent();
    _initAppointEvent();
    _initClearUnreadEvent();
    _initRemoveEvent();
    _initTopEvent();
    initRefresh();

    super.onReady();
  }

  /// 初始化会话列表监听
  void _initEvent() {
    _conversationEvent = EventBusUtil.listen<RCConversationsEvent>((event) {
      if (event.ok) {
        //event.list 去重
        List<JSConversation> uniqueList = [];
        for (var item in event.list!) {
          if (!uniqueList.any((element) => element.targetId == item.targetId)) {
            uniqueList.add(item);
          }
        }

        if (event.getTop ?? false) {
          //获取到置顶会话列表
          for (var item in uniqueList) {
            int index = list.indexWhere((element) => element.targetId == item.targetId);
            if (index == -1) {
              // 当前会话列表中无该会话，则添加(为避免加载更多出现问题)
              list.add(item);
            }
          }
   
        } else if (event.loadMore ?? false) {
          //加载更多
          for (var item in uniqueList) {
            int index = list.indexWhere((element) => element.targetId == item.targetId);
            if (index == -1) {
              // 当前会话列表中无该会话，则添加(为避免加载更多出现问题)
              list.add(item);
            }
          }
          refreshController?.finishLoad(IndicatorResult.success, true);

        } else {
          list.clear();
          list.addAll(uniqueList);
          refreshController?.finishRefresh(IndicatorResult.success, true);
        }
        if (!(event.loadMore ?? false)) {
          changeSuccess();
        }
        _onSort();
      } else {
        if(list.isEmpty){
          onChangeError(event.code!, "error");
        }
      }
    });
    _appLifecycleEvent = EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        // 从后台切换到前台
        //延迟1秒后刷新 （因为刚进入App融云不移动，所以需要延迟1秒后刷新）
        Future.delayed(const Duration(seconds: 1), () {
          _request();
        });
      }
    });
  }

  /// 初始化清除未读监听
  void _initClearUnreadEvent() {
    _clearUnreadEvent = EventBusUtil.listen<RCClearUnreadEvent>((event) {
      if (event.ok) {
        int index =
            list.indexWhere((element) => element.targetId == event.targetId);
        if (index != -1) {
          list[index].unreadMessageCount = 0;
          update();
        }
      }
    });
  }

  /// 初始化指定会话监听
  void _initAppointEvent() {
    _appointEvent = EventBusUtil.listen<RCAppointConversationEvent>((event) {
      if (event.ok) {
        final data = event.data;
        if (data != null) {
          int index =
              list.indexWhere((element) => element.targetId == data.targetId);
          if (index != -1) {
            // 当前会话列表中存在该会话，删除该条数据，并重新插入到第一的位置
            list.removeAt(index);
          }
          list.insert(0, data);
          changeSuccess();
          _onSort();
        }
      }
    });
  }

  /// 初始化删除指定会话监听
  void _initRemoveEvent() {
    _removeEvent = EventBusUtil.listen<RCRemoveConversationEvent>((event) {
      if (event.ok) {
        list.removeWhere((element) => element.targetId == event.targetId);
        update();
      }
      //  重新获取未读数
      RCConversationsManager().getTotalUnreadCount();
    });
  }

  /// 置顶监听
  void _initTopEvent() {
    _topEvent = EventBusUtil.listen<RCConversationsTopStatusEvent>((event) {
      // if (event.top) {
      int index =
          list.indexWhere((element) => element.targetId == event.targetId);
      if (index != -1) {
        list[index].isTop = event.top;
        _onSort();
      }
      // } else {
      //   initRefresh();
      // }
    });
  }

  void uodateNameAndAvatar(String targetId) {
    if (userInfoMap[targetId] != null) {
      return;
    }
    userGetNameAndAvatar(targetId: targetId);
  }

  /// 对数据进行排序
  void _onSort() async {
    if (appConfig.isReviewPkg.value) {
      appConfig.strategyModel?.reviewOfficialBlacklistUserIds
          ?.forEach((reviewId) {
        // 审核，删除系统账号不显示
        list.removeWhere((element) => element.targetId == reviewId);
      });
    }
    for (var item in list) {
      uodateNameAndAvatar(item.targetId!);
    }
    // 首先按照top字段进行排序，top为true的排在前面
    list.sort((a, b) {
      bool aTop = a.isTop ?? false;
      bool bTop = b.isTop ?? false;
      if (aTop && !bTop) {
        return -1; // a排在b前面
      } else if (!aTop && bTop) {
        return 1; // b排在a前面
      } else {
        // 如果top字段相同，则按照sentTime字段进行排序
        return (b.latestMessage?.sentTime ?? 0)
            .compareTo((a.latestMessage?.sentTime ?? 0));
      }
    });
    // 置顶需要置顶的系统消息
    for (var value in appConfig.strategyModel?.topOfficialUserIds ?? []) {
      int index = list.indexWhere((element) => element.targetId == value);
      if (index != -1) {
        list.insert(0, list[index]);
        list.removeAt(index + 1);
        // 将系统账号置顶
        RCConversationsManager().changeTopStatus(
          targetId: value,
          top: true,
          notice: false,
        );
      }
    }
    // 置顶最高级系统帐号
    int index = list.indexWhere((element) =>
        element.targetId == appConfig.strategyModel?.userServiceAccountId);
    if (index != -1) {
      list.insert(0, list[index]);
      list.removeAt(index + 1);
      if (list[index].isTop == false) {
        // 将系统账号置顶
        RCConversationsManager().changeTopStatus(
          targetId: appConfig.strategyModel?.userServiceAccountId ?? "",
          top: true,
          notice: false,
        );
      }
    }
    update();
  }

  /// 请求数据
  Future _request({
    int startTime = 0,
  }) async {
    await RCConversationsManager().getConversations(
      startTime: startTime,
    );
  }

  /// 获取用户头像昵称
  Future userGetNameAndAvatar({required String targetId}) async {
    //缓存获取用户数据
    final user = CacheManager.userGetNameAndAvatarCache(targetId);
    if (user != null) {
      userInfoMap[targetId] = user;
      update();
    }

    request.userGetNameAndAvatar(
      userId: targetId,
      showErrorTip: false,
      onSuccess: (data) {
        userInfoMap.addAll({targetId: data});
        update();
      },
    );
  }

  // 置顶系统账号
  void _onGetTopSystem() {
    // appConfig.strategyModel?.topOfficialUserIds?.forEach((topId) {
    //   if (!list.any((element) => topId.contains(element.targetId ?? ""))) {
    //     // 不存在需要置顶的系统消息时
    //     RCConversationsManager()
    //         .changeTopStatus(targetId: topId, top: true, notice: false);
    //   }
    // });
    // if (!list.any((element) =>
    //     appConfig.strategyModel?.userServiceAccountId == element.targetId)) {
    //   // 客服消息无置顶时，直接置顶
    //   RCConversationsManager().changeTopStatus(
    //     targetId: appConfig.strategyModel?.userServiceAccountId ?? "",
    //     top: true,
    //     notice: false,
    //   );
    // }
  }

  @override
  void onClose() {
    _conversationEvent?.cancel();
    _appointEvent?.cancel();
    _clearUnreadEvent?.cancel();
    _removeEvent?.cancel();
    _topEvent?.cancel();
    _appLifecycleEvent?.cancel();
    super.onClose();
  }

  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    if (page == 1) {
      _request();
    } else {
      // 获取最后一条消息的接收时间或者发送时间
      int startTime = 0;
      startTime = list.last.latestMessage?.sentTime ?? 0;
      await _request(
        // 以最后一条数据的时间为请求起点
        startTime: startTime,
      );
    }
  }
}
