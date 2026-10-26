import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/rc_conversation/rc_conversation_top_status_event.dart';
import 'package:untitled1/event_bus/rc_conversation/rc_remove_conversation_event.dart';
import 'package:untitled1/event_bus/rc_conversation/rc_total_unread_count_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';

import '../event_bus/rc_conversation/rc_appoint_conversation_event.dart';
import '../event_bus/rc_conversation/rc_clear_unread_event.dart';
import '../event_bus/rc_conversation/rc_conversations_event.dart';
import '../js/Model/JSConversation.dart';
import 'rc_manager.dart';

/// create: 2023/5/4
/// desc: 融云会话管理
class RCConversationsManager {
  RCConversationsManager._internal();

  static final RCConversationsManager _instance = RCConversationsManager._internal();

  factory RCConversationsManager() => _instance;

  RCManager get _engine => Get.find<RCManager>();

  /// 获取所有未读会话数
  Future getTotalUnreadCount({bool clearSystem = true}) async {
    await Get.find<RCManager>().completer?.future;
    if (clearSystem) {
      getSystemUnreadCount();
    }
    JSGetTotalUnreadCountCallback? callback = JSGetTotalUnreadCountCallback(
      onSuccess: (int? t) {
        EventBusUtil.fire<RCTotalUnreadCountEvent>(RCTotalUnreadCountEvent.success(count: t ?? 0));
        logger.d("会话未读数===> $t");
      },
      onError: (int? code) {
        EventBusUtil.fire<RCTotalUnreadCountEvent>(RCTotalUnreadCountEvent.fail(code: code));
      },
    );
    int? ret = await _engine.getTotalUnreadCount(null, callback: callback);
    if (ret != 0) {
      EventBusUtil.fire<RCTotalUnreadCountEvent>(RCTotalUnreadCountEvent.fail(code: ret));
    }
  }

  /// 获取会话列表
  Future getConversations({
    int startTime = 0,
    int limit = 50,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSGetConversationsCallback? callback = JSGetConversationsCallback(
      onSuccess: (List<JSConversation>? data) {
        logger.d("获取会话列表===> ${data?.length}");
        EventBusUtil.fire<RCConversationsEvent>(RCConversationsEvent.success(data, startTime != 0, false));
      },
      onError: (int? code) {
        EventBusUtil.fire<RCConversationsEvent>(RCConversationsEvent.fail(code));
      },
    );
    await _engine.getConversations(null, startTime, limit, callback: callback);

    if (startTime == 0) {
      ///如果是第一页则刷新置顶会话列表
      getTopConversations();
    }
  }

  /// 获取置顶会话列表
  Future getTopConversations({JSGetConversationsCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    JSGetConversationsCallback? callback = JSGetConversationsCallback(
      onSuccess: (List<JSConversation>? data) {
        logger.d("获取会话列表===> ${data?.length}");
        EventBusUtil.fire<RCConversationsEvent>(RCConversationsEvent.success(data, true, true));
        getTotalUnreadCount();
      },
      onError: (int? code) {
        EventBusUtil.fire<RCConversationsEvent>(RCConversationsEvent.fail(code));
      },
    );
    await _engine.getTopConversations(callback: callback);
  }

  /// 获取指定会话
  Future getConversation({
    required String targetId,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSGetConversationCallback? callback = JSGetConversationCallback(
      onSuccess: (JSConversation? t) {
        logger.d("获取指定会话===> ${t?.toJson()}");
        EventBusUtil.fire<RCAppointConversationEvent>(RCAppointConversationEvent.success(t));
      },
      onError: (int? code) {
        EventBusUtil.fire<RCAppointConversationEvent>(RCAppointConversationEvent.fail(code));
      },
    );
    int? ret = await _engine.getConversation(
      targetId,
      null,
      callback: callback,
    );
    if (ret != 0) {
      EventBusUtil.fire<RCAppointConversationEvent>(RCAppointConversationEvent.fail(ret));
    }
  }

  /// 清除指定会话未读数
  /// [targetId] 会话id
  /// [timestamp] 该会话已阅读的最后一条消息的发送时间戳，清除所有传入当前最新时间戳
  /// [retryTotalCount] 重新获取未读数
  Future clearUnreadCount({
    required String targetId,
    required int timestamp,
    bool retryTotalCount = true,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSClearUnreadCountCallback? callback = JSClearUnreadCountCallback(
      onUnreadCountCleared: (int? code) {
        if (code == 0) {
          debugPrint("清除指定会话[$targetId]未读数");
          // 清除成功
          if (retryTotalCount) {
            // 重新获取所有未读数
            getTotalUnreadCount();
          }
          // 发送通知
          EventBusUtil.fire<RCClearUnreadEvent>(RCClearUnreadEvent.success(targetId));
        } else {
          EventBusUtil.fire<RCClearUnreadEvent>(RCClearUnreadEvent.fail(code));
        }
      },
    );

    int? ret = await _engine.clearUnreadCount(
      targetId,
      callback: callback,
    );
    if (ret != 0) {
      EventBusUtil.fire<RCClearUnreadEvent>(RCClearUnreadEvent.fail(ret));
    }
    if (retryTotalCount) {
      // 重新获取所有未读数
      getTotalUnreadCount();
    }
  }

  /// 删除指定会话
  Future removeConversation({
    required String targetId,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSRemoveConversationCallback? callback = JSRemoveConversationCallback(
      onSuccess: (int? code) {
        logger.d("删除指定会话===>$code");
        EventBusUtil.fire<RCRemoveConversationEvent>(RCRemoveConversationEvent.success(targetId));
      },
      onError: (int? code) {
        EventBusUtil.fire<RCRemoveConversationEvent>(RCRemoveConversationEvent.fail(code));
      },
    );
    int ret = await _engine.removeConversation(
      targetId,
      callback: callback,
    );
    if (ret != 0) {
      EventBusUtil.fire<RCRemoveConversationEvent>(RCRemoveConversationEvent.fail(ret));
    }
    RCConversationsManager().clearUnreadCount(
      targetId: targetId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 清除审核模式下的系统未读数
  Future getSystemUnreadCount() async {
    await Get.find<RCManager>().completer?.future;
    final appConfig = Get.find<AppConfigManager>();
    if ((appConfig.strategyModel?.reviewOfficialBlacklistUserIds?.isEmpty ?? false) || !appConfig.isReviewPkg.value) {
      // 无需隐藏系统帐号 或 当前非审核模式
      appConfig.strategyModel?.reviewOfficialBlacklistUserIds?.forEach((element) {
        RCMessageManager().removeBlock(element);
      });
      return;
    }
    appConfig.strategyModel?.reviewOfficialBlacklistUserIds?.forEach((element) {
      clearUnreadCount(targetId: element, timestamp: DateTime.now().millisecondsSinceEpoch, retryTotalCount: false);
      RCMessageManager().addBlock(element);
    });
    // 清除完系统账号未读数后再次获取总数，但是不需要再重新清除系统账号未读数，避免死循环
    getTotalUnreadCount(clearSystem: false);
  }

  /// 切换置顶状态
  /// 是否通知刷新
  Future changeTopStatus({
    required String targetId,
    required bool top,
    bool notice = true,
    bool isToast = false,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSActionCallback? callback = JSActionCallback(
      onSuccess: (int? code) {
        if (code == 0 && notice) {
          EventBusUtil.fire<RCConversationsTopStatusEvent>(RCConversationsTopStatusEvent.success(targetId: targetId, top: top));
        }
      },
      onError: (int? code) {},
    );
    int? ret = await _engine.changeConversationTopStatus(targetId, top, callback: callback);
    if (isToast) {
      top ? Toast.showMsg("Successfully_Sticky_on_Top".bhTR) : Toast.showMsg("Sticky_on_Top_Cancelled".bhTR);
    }
  }
}
