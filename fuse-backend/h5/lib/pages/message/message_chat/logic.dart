import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/im_limit_event.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/event_bus/rc_message/rc_get_messages_event.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/message/rc_message_model.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/translate/translate_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/gift_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/msg_notication/message_pop_event.dart';

import '../../../common_logic/app_config_manager.dart';
import '../../../common_logic/cache_manager.dart';
import '../../../common_logic/user_status_service.dart';
import '../../../event_bus/rc_conversation/rc_appoint_conversation_event.dart';
import '../../../event_bus/rc_conversation/rc_conversation_top_status_event.dart';
import '../../../event_bus/rc_message/rc_message_menu_event.dart';
import '../../../event_bus/rc_message/rc_message_received_event.dart';
import '../../../event_bus/rc_message/rc_send_message_event.dart';
import '../../../js/Model/JSConversation.dart';
import '../../../model/user/user_info_model.dart';
import '../../../rong_cloud/rc_conversations_manager.dart';
import '../../../utils/bh_platform.dart';
import '../../../widget/give_gift_widget.dart';

AudioPlayer? _lastPlayer;

class MessageChatLogic extends GetBaseController {
  String userId = "";

  final onlineStatus = "".obs;

  /// 对方用户数据
  UserInfoModel? userInfo;

  /// 是否为系统帐号
  final systemAccount = true.obs;

  /// 当前用户头像
  String avatar = "";

  /// 对话消息
  final List<RCMessageModel> list = [];

  /// 显示送礼动画
  final showGiveGift = false.obs;

  /// 送礼动画widget
  Widget? giftWidget;

  /// 送出的礼物
  final giftImage = "".obs;

  /// 是否删除更多
  final deleteMore = false.obs;

  final keyBordShow = false.obs;

  /// 待删除消息集合
  final List<JSMessage> deleteList = [];

  /// 语音播放控制器
  AudioPlayer? _player;

  /// 语音播放索引
  final playVoiceIndex = RxInt(-1);

  /// 接收消息监听
  StreamSubscription<RCMessageReceivedEvent>? _receiveEvent;

  /// 历史消息监听
  StreamSubscription<RCGetMessagesEvent>? _messageEvent;

  /// 消息发送监听
  StreamSubscription<RCSendMessageEvent>? _sendEvent;

  /// 消息删除监听
  StreamSubscription<RCMessageDeleteEvent>? _deleteEvent;

  ScrollController scrollController = ScrollController();

  late ListObserverController observerController;

  late ChatScrollObserver chatObserver;

  final _videoLogic = Get.find<VideoCallHandler>();

  final appConfig = Get.find<AppConfigManager>();

  final translate = Get.find<TranslateManager>();

  late StreamSubscription _otherEvent;

  StreamSubscription? _topEvent;
  StreamSubscription? _conversationEvent;

  final limitIM = false.obs;
  final isTop = false.obs;

  StreamSubscription? _userStatusEvent;

  final FocusNode focusNode = FocusNode();

  //最后一条消息是问答消息
  final questionMessageObs = Rx<RCMessageModel?>(null);

  //监听支付成功
  StreamSubscription? _paySuccessEvent;

  initData(UserInfoModel model) async {
    logHandle.initLog('conversation');
    try {
      EventBusUtil.fire(MessagePopEvent());
      userId = model.userId ?? "";
      userInfo = model;
      avatar = appConfig.userInfo.avatarThumbUrl ?? "";
      observerController = ListObserverController(controller: scrollController)..cacheJumpIndexOffset = true;
      chatObserver = ChatScrollObserver(observerController);

      changeLoading();
      _getInfo();
      _initReceiveEvent();
      _initMessageEvent();
      _initSendEvent();
      _initDeleteEvent();
      _initPaySuccessEvent();

      focusNode.addListener(_onFocusChange);

      if (GiftManager.to.giftList.isEmpty) {
        // 礼物列表为空，拉取
        GiftManager.to.getGift();
      }
      if (userInfo != null) {
        _onCheckIsSystem();
        _onGetMessage(0);
        _clearUnread();
      }
      //获取当前是否置顶
      _onGetTopStatus();
      //初始化在线状态监听
      _iniUserStatus();
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
      _topEvent = EventBusUtil.listen<RCConversationsTopStatusEvent>((event) {
        isTop.trigger(event.top);
      });
      //获取会话
      _conversationEvent = EventBusUtil.listen<RCAppointConversationEvent>((event) {
        if (event.data?.targetId == userId) {
          isTop.call(event.data?.isTop ?? false);
        }
      });
    } catch (e) {
      logger.e("错误: $e");
    }
  }

  void _onFocusChange() {
    if (focusNode.hasFocus) {
      // 键盘弹起
      keyBordShow.value = true;
    } else {
      // 键盘收起
      keyBordShow.value = false;
    }
  }

  //初始化在线状态监听
  void _iniUserStatus() {
    //不是系统帐号，监听在线状态
    if (systemAccount.value) {
      return;
    }
    final tmpStatus = getUserStatusService()?.getStatus(userId);
    if (tmpStatus != null) {
      onlineStatus.value = tmpStatus;
    }
    //监听在线状态
    getUserStatusService()?.addUserIdAndForceRefresh(userId);
    _userStatusEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (event.uidAndStatus.containsKey(userId)) {
        onlineStatus.value = event.uidAndStatus[userId] ?? kOffline;
      }
    });
  }

  /// 检查是否为系统帐号
  void _onCheckIsSystem() {
    systemAccount.value = appConfig.onCheckSystem(userId);
  }

  /// 获取主播数据
  Future _getInfo() async {
    //先获取缓存
    final user = CacheManager.userInfoCache(userId);
    if (user != null) {
      userInfo = user;
      changeSuccess();
    }

    await request.userGetInfo(
      userId: userId,
      onSuccess: (data) {
        userInfo = data;
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }

  bool isLockChat() {
    return appConfig.switchImLimit && !appConfig.systemList.contains(userId);
  }

  /// 初始化消息接收监听
  void _initReceiveEvent() {
    _receiveEvent = EventBusUtil.listen<RCMessageReceivedEvent>((event) {
      if (event.ok && event.message?.targetId == userId) {
        //消息去重
        list.removeWhere((element) => element.message.messageUId == event.message?.messageUId);
        // 当前用户
        list.insert(0, RCMessageModel(message: event.message!));
        _clearUnread();
        _onCheckTrans();
        _onCheckQuestionMessage();
        update();
        try {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceIn,
          );
        } catch (e) {}
      }
    });
  }

  /// 初始化历史消息监听
  void _initMessageEvent() {
    _messageEvent = EventBusUtil.listen<RCGetMessagesEvent>((event) {
      if (event.ok && (event.list?.isNotEmpty ?? false) && event.list?.first.targetId == userId) {
        // 分页去重，查询历史消息的time时间准确就不需要
        // if (!list.any((element) => element.message.messageUId == event.list?.first.messageUId)) {
        //   list.addAll(event.list!.map((e) => RCMessageModel(message: e)));
        // }

        event.list?.forEach((element) {
          if (list.every((e) => e.message.messageUId != element.messageUId)) {
            list.add(RCMessageModel(message: element));
          }
        });
      }

      _onCheckTrans();
      _onCheckQuestionMessage();
      update();
    });
  }

  //检查最后一条消息是否是问答消息
  void _onCheckQuestionMessage() {
    if (appConfig.isRecharge) {
      questionMessageObs.value = null;
    }else{
      if (list.isNotEmpty &&
        list.first.message.content is JSSingleJsonMsgMessageContent &&
        (list.first.message.content as JSSingleJsonMsgMessageContent).contentType == "script-question") {
      questionMessageObs.trigger(list.first);
    } else {
      questionMessageObs.value = null;
    }
    }
    
  }

  /// 初始化消息发送监听
  void _initSendEvent() {
    _sendEvent = EventBusUtil.listen<RCSendMessageEvent>((event) {
      if (event.message?.targetId == userId) {
        // 与当前用户聊天
        // 如果能找到索引，就更新该索引所在的值
        //注意，判断本地Id就行，发送失败时远程Id可能为null
        int index = list.indexWhere((element) => element.message.messageId == event.message?.messageId);
        if (index != -1) {
          list.replaceRange(index, index + 1, [RCMessageModel(message: event.message!)]);
        } else {
          list.insert(0, RCMessageModel(message: event.message!));
        }
        if (event.message?.content is JSSingleJsonMsgMessageContent) {
          // 礼物消息
          Map map = jsonDecode((event.message?.content as JSSingleJsonMsgMessageContent).content!);
          onChangeGiftShow(show: true, giftCode: map['giftCode']);
        }
        _onCheckQuestionMessage();
        update();
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.bounceIn,
        );
      }

      onUploadIM();
    });
  }

  /// 初始化消息删除监听
  void _initDeleteEvent() {
    _deleteEvent = EventBusUtil.listen<RCMessageDeleteEvent>((event) {
      if (event.targetId == userId) {
        // 当前用户消息
        for (var item in (event.messages ?? <JSMessage>[])) {
          list.removeWhere((element) => element.message.messageUId == item.messageUId && item.messageId != element.message.messageId);
        }
        update();
      }
    });
  }

  /// 检查文本数据的翻译
  void _onCheckTrans() {
    for (int i = 0; i < list.length; i++) {
      // 当前无翻译数据且当前为文本数据，则获取缓存数据
      if (list[i].message.content is JSTextMessageContent && list[i].translateStatus == TranslateStatus.none) {
        String? value = translate.cache.get(MD5((list[i].message.content as JSTextMessageContent).content ?? ""));

        if (value != null) {
          // 拿到缓存中的翻译
          list[i].translate = value;
          list[i].translateStatus = TranslateStatus.translateSuccess;
        } else if (appConfig.autoTranslate.value) {
          // 无缓存，且开启自动翻译

          onTrans(list[i]);
        }
      }
    }
  }

  /// 加载更多
  Future onLoadMore() async {
    // 获取最后一条消息发送时间（接收时间为对方的已读时间），时间一定要准确，否则会重复获取
    _onGetMessage(list.last.message.sentTime ?? 0);
  }

  /// 清除会话未读数
  Future _clearUnread() async {
    RCConversationsManager().clearUnreadCount(
      targetId: userId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 获取历史消息
  Future _onGetMessage(int sentTime) async {
    RCMessageManager().getMessages(targetId: userId, time: sentTime, isOnlyGetLocal: list.isEmpty);
  }

  /// 改变礼物显示状态
  void onChangeGiftShow({required bool show, required String giftCode}) {
    showGiveGift.value = show;
    if (show) {
      giftWidget = null;
      var result = GiftUtil.giftImageList.where((element) => element.name == giftCode).toList();
      if (result.isNotEmpty) {
        giftImage.value = result.first.image;
      }
      giftWidget = GiveGiftWidget(
        key: ValueKey(DateTime.now().millisecondsSinceEpoch.toString()),
        giftImage: giftImage.value,
        onEnd: (key) => onChangeGiftShow(show: false, giftCode: ""),
      );
    }
    update();
  }

  /// 呼叫
  void onCall() async {
    _videoLogic.onCheckToCall(
      callSource: VideoCallSource.CONVERSATION,
      onlineStatus: onlineStatus.value,
      userInfo: userInfo!,
    );
  }

  //置顶
  void onTop() async {
    await RCConversationsManager().changeTopStatus(
      targetId: userId,
      top: !isTop.value,
      isToast: true,
    );
  }

  /// 翻译
  void onTrans(RCMessageModel message) {
    int index = list.indexWhere((element) => element.message.messageUId == message.message.messageUId);
    if (index == -1) {
      return;
    }
    RCMessageModel model = list[index];
    String text = "";
    if (message.message.content is JSSingleJsonMsgMessageContent) {
      text = (message.message.content as JSSingleJsonMsgMessageContent).questionData?.content ?? "";
    } else {
      text = (message.message.content as JSTextMessageContent).content ?? "";
    }
    // 将翻译字段设为空
    model.translate = translate.getCache(text) ?? "";
    if (model.translate?.isNotEmpty ?? false) {
      model.translateStatus = TranslateStatus.translateSuccess;
      // update();
      throttleUtil.throttle(
        () async {},
        key: "translate.trans",
        onAfter: () async {
          update();
        },
        time: 100,
      );

      return;
    }
    //标记翻译中
    model.translateStatus = TranslateStatus.translating;
    throttleUtil.throttle(
      () async {},
      key: "translate.trans",
      onAfter: () async {
        update();
      },
      time: 100,
    );

    translate.trans(
      content: text,
      onSuccess: (result) {
        model.translate = result;
        model.translateStatus = TranslateStatus.translateSuccess;
        //防抖
        throttleUtil.throttle(
          () async {},
          key: "translate.trans",
          onAfter: () async {
            update();
          },
          time: 500,
        );
        update();
      },
      onFail: (msg) {
        // 翻译失败，重新显示翻译入口
        model.translate = null;
        model.translateStatus = TranslateStatus.translateFail;

        //防抖
        throttleUtil.throttle(
          () async {},
          key: "translate.trans",
          onAfter: () async {
            update();
          },
          time: 500,
        );
      },
    );
  }

  /// 多选任务选择
  void onSelectDelete(JSMessage item) {
    int index = deleteList.indexWhere((element) => element.messageUId == item.messageUId && item.messageId == element.messageId);
    if (index == -1) {
      deleteList.add(item);
    } else {
      deleteList.removeAt(index);
    }
    update();
  }

  /// 删除更多
  void onDelMore() async {
    deleteMore.value = false;
    try {
      await RCMessageManager().deleteMessages(targetId: userId, messages: deleteList);
    } catch (e) {
      logger.e("删除消息错误===${e.toString()}");
    }
    //移除list中的deleteList数据
    list.removeWhere((element) => deleteList.contains(element.message));
    deleteList.clear();
    update();
  }

  /// 关注或取消关注结果回调（弹窗返回数据）
  void onFollowOrUnBack(bool result) async {
    userInfo = userInfo?.copyWith(
      isFriend: result,
    );
    update();
  }

  /// 拉黑/取消拉黑返回
  void onBlockOrUnBack(bool result) async {
    userInfo = userInfo?.copyWith(
      isBlock: result,
    );
    update();
  }

  StreamSubscription<PlayerState>? _playerStream;

  /// 播放语音
  Future<void> playVoice(int index) async {
    try {
      await stopVoice();
      await _lastPlayer?.stop();
      playVoiceIndex.trigger(index);
      JSVoiceMessageContent message = list[index].message.content as JSVoiceMessageContent;
      if (message.localUrl != null) {
        await _player?.setAudioSource(AudioSource.uri(Uri.parse(message.localUrl!)));
      } else if (message.remoteUrl != null) {
        await _player?.setAudioSource(AudioSource.uri(Uri.parse(message.remoteUrl!)));
      }
      // await _player?.setLoopMode(LoopMode.one);
      _player?.play();
      _lastPlayer = _player;
    } catch (e) {
      Toast.showMsg("error_playFail".bhTR);
      logger.e("播放语音错误===${e.toString()}");
    }
  }

  /// 停止语音播放
  Future<void> stopVoice() async {
    try {
      if (_player != null) {
        _playerStream?.cancel();
        _playerStream = null;
        playVoiceIndex.trigger(-1);
        _player?.stop();
        _player = null;
      }

      _player = AudioPlayer();
      // 监听音频播放完成事件
      _playerStream = _player?.playerStateStream.listen((PlayerState state) {
        if (state.processingState == ProcessingState.completed) {
          // 音频播放完成
          // 执行你的操作
          if (_player != null) {
            _player?.stop();
            _player = null;
            if (_player == _lastPlayer) {
              _lastPlayer = null;
            }
          }
          playVoiceIndex.trigger(-1);
        }
      });
    } catch (e) {
      logger.e("停止语音播放错误: $e");
    }
  }

  Future onUploadIM() async {
    if (appConfig.switchImLimit) {
      // 是否已聊过
      bool contains = appConfig.strategyModel?.imSessionBroadcasterIds?.contains(userId) ?? false;
      bool isSystem = appConfig.systemList.contains(userId);
      if (!contains && !isSystem) {
        // 开启限制 && 未聊过
        await request.createImSession(
          broadcasterId: userId,
          onSuccess: (model) {
            appConfig.onUpdateIMLimit(model);
            EventBusUtil.fire(IMLimitEvent());
          },
          onFail: (code, msg) {},
        );
      }
    }
  }

  void updateLimitIM(bool value) {
    limitIM.value = value;
  }

  @override
  void onClose() {
    _playerStream?.cancel();
    _playerStream = null;
    _player?.stop();
    _player = null;
    _receiveEvent?.cancel();
    _messageEvent?.cancel();
    _sendEvent?.cancel();
    _deleteEvent?.cancel();
    _otherEvent.cancel();
    _userStatusEvent?.cancel();
    _userStatusEvent = null;
    _topEvent?.cancel();
    _topEvent = null;
    _conversationEvent?.cancel();
    _conversationEvent = null;
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    _paySuccessEvent?.cancel();
    _paySuccessEvent = null;
    super.onClose();
  }

  void _onGetTopStatus() async {
    RCConversationsManager().getConversation(targetId: userId);
  }

  void onSendMessage(String reply) {
    // 发送消息
    RCMessageManager().sendTextMessage(
      message: null,
      targetId: userId,
      sendId: appConfig.userInfo.userId ?? "",
      nickname: appConfig.userInfo.nickname ?? "",
      avatar: appConfig.userInfo.avatarUrl ?? "",
      text: reply,
    );
    request.robotScript(
      fromUserId: appConfig.userInfo.userId ?? "",
      scriptTriggerType: 1, //0:用户触发、1:机器人触发
      targetId: userId,
      onSuccess: (data) {
        logger.d('Robot script triggered successfully from : $data');
      },
      onFail: (code, msg) {
        logger.e('Failed to trigger robot script from : code=$code, msg=$msg');
      },
    );
  }

  void _initPaySuccessEvent() {
    _paySuccessEvent = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      //更新充值状态
      appConfig.userInfo.isRecharge = true;
      onUploadIM();
      updateLimitIM(false);
      _onCheckQuestionMessage();
      update();
    });
  }
}
