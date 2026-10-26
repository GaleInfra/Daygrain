import 'dart:convert';

import 'package:get/get.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/im_limit_event.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/event_bus/none_flag/none_flag_event.dart';
import 'package:untitled1/event_bus/rc_message/rc_get_messages_event.dart';
import 'package:untitled1/event_bus/rc_message/rc_message_menu_event.dart';
import 'package:untitled1/event_bus/rc_message/rc_message_received_event.dart';
import 'package:untitled1/event_bus/rc_message/rc_send_message_event.dart';
import 'package:untitled1/js/Model/JSConversation.dart';
import 'package:untitled1/js/js_utils.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/rong_cloud/message_dialog/message_dialog.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/widget/dialog/compensation_dialog.dart';
import 'package:untitled1/widget/msg_notication/message_notication.dart';

import '../common_logic/app_config_manager.dart';
import '../utils/socket_util.dart';
import 'rc_conversations_manager.dart';
import 'rc_manager.dart';
import 'dart:html' as html;

/// create: 2023/5/4
/// desc: 融云消息管理
class RCMessageManager {
  RCMessageManager._internal();

  static final RCMessageManager _instance = RCMessageManager._internal();

  factory RCMessageManager() => _instance;

  RCManager get _engine => Get.find<RCManager>();

  /// 初始化
  Future init() async {
    onMessageReceived();
  }

  /// 接收消息
  Future onMessageReceived() async {
    await Get.find<RCManager>().completer?.future;
    if (_engine.onMessageReceived != null) {
      // 重新获取所有未读数
      RCConversationsManager().getTotalUnreadCount();
      return;
    }
    _engine.onMessageReceived = (JSMessage? message) {
      // logger.d("接收消息 $left $offline $hasPackage ${prettyJson(message?.toJson())}");
      if (message != null) {
        MessageNotication.show(message);
      }
      if (message != null) {
        if (message.messageType == JSMessageType.command) {
          // 模拟当前时间
          int currentTime = DateTime.now().millisecondsSinceEpoch;

          // 模拟消息发送时间（这里需要实际的消息时间）
          int messageTime = message.sentTime ?? 0; // 假设这个函数返回消息的发送时间

          // 检查消息时间是否为秒级时间戳
          if (messageTime <= 9999999999) {
            messageTime *= 1000; // 转换为毫秒级时间戳
          }

          bool isCurrentOff = false;

          // 检查当前时间与消息时间的差距
          if ((currentTime - messageTime) > 2 * 60 * 1000) {
            isCurrentOff = true;
          }
          if (!(message.offLine ?? false) && !isCurrentOff) {
            //只处理非离线消息
            // 如果用户当前自长链断开了，此处会收到长链下发，请同样此处进行事件处理
            if (message.content is Map) {
              SocketUtil().handlerMessage(message.content["data"]);
            } else if (message.content is String) {
              Map<String, dynamic> map = jsonDecode(message.content);
              SocketUtil().handlerMessage(map["data"]);
            } else {
              SocketUtil().handlerMessage(message.content);
            }
          }
        } else if (message.messageType == JSMessageType.singleJsonMsg) {
          // 空消息
          EventBusUtil.fire<NoneFlagEvent>(
              NoneFlagEvent(message.messageType ?? ""));
              EventBusUtil.fire<RCMessageReceivedEvent>(
            RCMessageReceivedEvent.success(message));
          // 刷新列表
          Future.delayed(Duration(milliseconds: BHPlatform.isWeb ? 300 : 0),
              () {
            //网页 融云SDK会出现还没入库但是已经收到消息的情况
            RCConversationsManager().getConversations();
          });
        } else if (message.messageType != JSMessageType.unknown) {
          // 礼物、超链接消息也同样走这里
          // 非离线消息且为最新一条消息

          EventBusUtil.fire<RCMessageReceivedEvent>(RCMessageReceivedEvent.success(message));
          // 刷新列表
          Future.delayed(Duration(milliseconds: BHPlatform.isWeb ? 200 : 0), () {
            //网页 融云SDK会出现还没入库但是已经收到消息的情况
            RCConversationsManager().getConversations();
          });
          if (message.messageType == JSMessageType.text && (message.content as JSTextMessageContent).extra == "compensation") {
            if (message.receivedStatus == 8) {
              return;
            }
            showCompensationDialog((message.content as JSTextMessageContent).content ?? "");
          } else {
            //在这里触发消息通知，前面的都是其他消息类型，不处理
            if (Get.isRegistered<AppConfigManager>()) {
              AppConfigManager appConfig = Get.find<AppConfigManager>();
              if (appConfig.userInfo.isSwitchNotDisturbIm == false) {
                RcMessageDialog.show(message);
              }
            }
            //给语言类型加载个未播放状态，点击播放后红点消失
            switch (message.messageType) {
              case JSMessageType.text:
                //获取文本内容 转换为文本消息

                break;
              case JSMessageType.image:
              case JSMessageType.gif:
                break;
              case JSMessageType.voice:
                SPUtil.setString(message.messageId != null ? message.messageId.toString() : "", "1");
                break;
              case JSMessageType.file:
                break;
              case JSMessageType.sight:
                break;

              case JSMessageType.unknown:
              default:
                break;
            }
          }
        }
      }
      // 重新获取所有未读数
      RCConversationsManager().getTotalUnreadCount();
    };
  }

  ///为网络差兜底
  ///添加一个消息保存到本地数据库监听
  // Future onMessageAttached()async{
  //   await Get.find<RCManager>().completer?.future;
  //   if (_engine.onMessageAttached != null) {
  //     return;
  //   }
  //   _engine.onMessageAttached = (RCIMIWMessage? message, int? left, bool? offline, bool? hasPackage) {
  //     if (message?.messageType == RCIMIWMessageType.command) {
  //       // 如果用户当前自长链断开了，此处会收到长链下发，请同样此处进行事件处理
  //       SocketUtil().handlerMessage((message as RCIMIWCommandMessage).data);
  //     }
  //   };
  // }

  /// 获取历史消息
  Future getMessages({
    required String targetId,
    required int time,
    bool isOnlyGetLocal = false,
  }) async {
    await Get.find<RCManager>().completer?.future;

    JSGetMessagesCallback? callback = JSGetMessagesCallback(
      onSuccess: (List<JSMessage>? t) {
        logger.d("以时间戳[$time]获取历史消息 ===> ${t?.length}");
        EventBusUtil.fire<RCGetMessagesEvent>(RCGetMessagesEvent.success(list: t ?? []));
      },
      onError: (int? code) {
        EventBusUtil.fire<RCGetMessagesEvent>(RCGetMessagesEvent.fail(code: code));
      },
    );
    int? result = await _engine.getMessages(
      targetId,
      null,
      time,
      0,
      20,
      callback: callback,
    );
    if (result != 0) {
      EventBusUtil.fire<RCGetMessagesEvent>(RCGetMessagesEvent.fail(code: result));
    }
  }

  /// 删除消息
  Future deleteMessages({
    required String targetId,
    required List<JSMessage> messages,
  }) async {
    await Get.find<RCManager>().completer?.future;
    JSDeleteMessagesCallback? callback = JSDeleteMessagesCallback(
      onMessagesDeleted: (int? code, List<JSMessage>? messages) {
        if (code == 0) {
          EventBusUtil.fire<RCMessageDeleteEvent>(RCMessageDeleteEvent(targetId: targetId, messages: messages));
        }
      },
    );
    await _engine.deleteMessages(targetId, null, messages, callback: callback);
  }

  /// 发送自定义消息
  Future sendSingleJsonMessage({
    required String targetId,
    required String content,
    required String contentType,
    required String customExtra,
  }) async {
    await Get.find<RCManager>().completer?.future;
    // 发送即通知
    JSSendMessageCallback? callback = JSSendMessageCallback(
      onMessageSaved: _onMessageSaved,
      onMessageSent: _onMessageSent,
    );

    await _engine.sendSingleJsonMessage(targetId: targetId, content: content, contentType: contentType, customExtra: customExtra, callback: callback);
  }

  /// 发送文本消息
  /// 当[message]为空时，其他值不应该为空
  /// [message] 发送失败后重试的消息体
  /// [targetId] 单聊时为接收方id，即用户id
  /// [sendId] 发送方id
  /// [nickname] 发送方昵称
  /// [avatar] 发送方头像
  /// [text] 文本消息
  Future sendTextMessage({
    required JSMessage? message,
    required String? targetId,
    required String? sendId,
    required String? nickname,
    required String? avatar,
    required String? text,
    void Function()? onComplete,
  }) async {
    await Get.find<RCManager>().completer?.future;
    // 构建消息体
    assert(!(message == null && targetId == null) || !(targetId == null && text == null));

    if (message == null) {
    } else {}

    // message ??= await _engine.createTextMessage(
    //   RCIMIWConversationType.private,
    //   targetId!,
    //   null,
    //   text!,
    // )
    //   ?..userInfo = RCIMIWUserInfo.create(
    //     userId: sendId,
    //     name: nickname,
    //     portrait: avatar,
    //   );

    // 发送即通知
    JSSendMessageCallback? callback = JSSendMessageCallback(
      onMessageSaved: _onMessageSaved,
      onMessageSent: (code, message) {
        _onMessageSent(code, message);
        onComplete?.call();
      },
    );
    await _engine.sendTextMessage(message?.targetId ?? (targetId ?? ""), message?.messageId, message?.content ?? (text ?? ""), callback: callback);
    // _checkSendResult(ret, message);
  }

  /// 发送图片消息
  /// 当[message]为空时，其他值不应该为空
  Future sendPicMessage({
    required JSMessage? message,
    required String? targetId,
    required String? path,
    required String? sendId,
    required String? nickname,
    required String? avatar,
  }) async {
    await Get.find<RCManager>().completer?.future;
    assert(!(message == null && targetId == null) || !(targetId == null && path == null));

    await _sendMediaMessage(message!);
  }

  /// 发送图片消息
  /// 当[message]为空时，其他值不应该为空
  Future sendPicMessageWeb({
    required JSMessage? message,
    required String? targetId,
    required html.File? file,
    required String? sendId,
    required String? nickname,
    required String? avatar,
  }) async {
    await Get.find<RCManager>().completer?.future;
    assert(!(message == null && targetId == null) || !(targetId == null && file == null));
    JSSendMessageCallback? callback = JSSendMessageCallback(
      onMessageSent: _onMessageSent,
      onMessageSaved: _onMessageSaved,
    );

    await _engine.sendImageMessage(message?.targetId ?? (targetId ?? ""), file!, message?.messageId, sendId, nickname, avatar, callback: callback);
  }

  /// 发送语音消息
  /// 当[message]为空时，其他值不应该为空
  Future sendVoiceMessage({
    required JSMessage? message,
    required String? targetId,
    required String? path,
    required int? duration,
    required String? sendId,
    required String? nickname,
    required String? avatar,
  }) async {
    await Get.find<RCManager>().completer?.future;
    assert(!(message == null && targetId == null) || !(targetId == null && path == null && duration == null));
    html.File? file;
    try {
      file = await JsUtils.blobUrlToFile(path ?? "", "tmp.acc");
    } catch (e) {
      return -1;
    }
    JSSendMessageCallback? callback = JSSendMessageCallback(
      onMessageSent: _onMessageSent,
      onMessageSaved: _onMessageSaved,
    );

    await _engine.sendVoiceMessage(message?.targetId ?? (targetId ?? ""), file, message?.messageId, sendId, nickname, avatar, callback: callback);
  }

  /// 发起媒体消息
  Future _sendMediaMessage(JSMessage message) async {
    // await Get.find<RCManager>().completer?.future;
    // RCIMIWSendMediaMessageListener? listener = RCIMIWSendMediaMessageListener(
    //   onMediaMessageSaved: _onMessageSaved,
    //   onMediaMessageSending: (RCIMIWMediaMessage? message, int? progress) {
    //     //网络较差时注意发送中
    //   },
    //   onSendingMediaMessageCanceled: (RCIMIWMediaMessage? message) {},
    //   onMediaMessageSent: _onMessageSent,
    // );
    // int ret = await _engine.sendMediaMessage(message, listener: listener);
    // _checkSendResult(ret, message);
  }

  /// 发送语音消息
  /// 当[message]为空时，其他值不应该为空
  Future sendVoiceMessageWeb({
    required JSMessage? message,
    required String? targetId,
    required String? path,
    required int? duration,
    required String? sendId,
    required String? nickname,
    required String? avatar,
  }) async {
    await Get.find<RCManager>().completer?.future;
    assert(!(message == null && targetId == null) || !(targetId == null && path == null && duration == null));
    html.File file = html.File(
      [
        html.Blob([path!])
      ],
      "test.mp3",
    );
    JSSendMessageCallback? callback = JSSendMessageCallback(
      onMessageSent: _onMessageSent,
      onMessageSaved: _onMessageSaved,
    );
    // await _engine.sendVoiceMessage(message?.targetId ?? (targetId ?? ""), file,
    //     message?.messageId, sendId, nickname, avatar,
    //     callback: callback);
    // await _sendMediaMessage(message!);
  }

  /// 消息保存到本地数据库
  void _onMessageSaved(JSMessage? message) {
    // 发送即通知，显示发送中到对话列表中
    if (message?.messageType != JSMessageType.singleJsonMsg) {
      EventBusUtil.fire<RCSendMessageEvent>(RCSendMessageEvent.success(message: message));
    }
  }

  /// 消息发送
  void _onMessageSent(int? code, JSMessage? message) {
    if (code == 0) {
      logger.d("发送消息 ===> ${prettyJson(message?.toJson())}");
      final appConfig = Get.find<AppConfigManager>();
      if (appConfig.switchImLimit) {
        // 是否已聊过
        final userId = message?.targetId ?? "";
        bool contains = appConfig.strategyModel?.imSessionBroadcasterIds?.contains(userId) ?? false;
        bool isSystem = appConfig.systemList.contains(userId);
        if (!contains && !isSystem) {
          // 开启限制 && 未聊过
          Get.find<RequestRepository>().createImSession(
            broadcasterId: userId,
            onSuccess: (model) {
              // appConfig.strategyModel?.imSessionBroadcasterIds?.add(userId);
              appConfig.onUpdateIMLimit(model);
              EventBusUtil.fire(IMLimitEvent());
              EventBusUtil.fire<SayHiEvent>(SayHiEvent(userId));
            },
            onFail: (code, msg) {},
          );
        }
      }
      EventBusUtil.fire<RCSendMessageEvent>(RCSendMessageEvent.success(message: message));
      // 刷新该会话
      Future.delayed(Duration(milliseconds: BHPlatform.isWeb ? 500 : 0), () {
        //网页 融云SDK会出现还没入库但是已经收到消息的情况
        RCConversationsManager().getConversation(targetId: message!.targetId!);
      });
    } else {
      logger.d("发送消息失败 ===> ${message?.toJson()}");
      EventBusUtil.fire<RCSendMessageEvent>(RCSendMessageEvent.fail(message: message, code: code));
      // 刷新该会话
      Future.delayed(Duration(milliseconds: BHPlatform.isWeb ? 500 : 0), () {
        //网页 融云SDK会出现还没入库但是已经收到消息的情况
        RCConversationsManager().getConversation(targetId: message!.targetId!);
      });
    }
  }

  /// 检查发送结果
  void _checkSendResult(int? result, JSMessage? message) {
    if (result != 0) {
      logger.d("发送消息失败 ===> ${message?.toJson()}");
      EventBusUtil.fire<RCSendMessageEvent>(RCSendMessageEvent.fail(message: message, code: result));
      // 刷新该会话
      RCConversationsManager().getConversation(targetId: message!.targetId!);
    }
  }

  // 拉黑用户
  void addBlock(String userId) {
    _engine.addToBlacklist(
      userId,
    );
  }

  // 取消拉黑
  void removeBlock(String userId) {
    _engine.removeFromBlacklist(
      userId,
    );
  }
}
