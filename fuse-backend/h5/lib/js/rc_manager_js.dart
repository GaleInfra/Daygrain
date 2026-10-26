import 'dart:async';
import 'package:js/js.dart';

import '../utils/js_utils.dart';
import 'Model/JSConversation.dart';

@JS('window')
class JSRongCloudManager {
  // Initialize RongCloud
  @JS('initRongCloud')
  external static Future<bool> initRongCloud(String appKey, String token, String areaCodeStr, BHCallbackJS callback);

  // Get total unread count
  @JS('getTotalUnreadCount')
  external static Future<int> getTotalUnreadCount(BHCallbackJS callback);

  //清空未读消息
  @JS('clearMessagesUnreadStatus')
  external static Future<int> clearMessagesUnreadStatus(String targetId, BHCallbackJS callback);

  //删除会话
  @JS('removeConversation')
  external static Future<int> removeConversation(String targetId, BHCallbackJS callback);

  //设置会话为置顶
  @JS('changeConversationTopStatus')
  external static Future<int> changeConversationTopStatus(String targetId, bool top, BHCallbackJS callback);

  //拉黑
  @JS('addToBlacklist')
  external static Future<int> addToBlacklist(String userId, BHCallbackJS callback);

  //从黑名单移除
  @JS('removeFromBlacklist')
  external static Future<int> removeFromBlacklist(String userId, BHCallbackJS callback);

  // Get conversation
  @JS('getConversation')
  external static Future<int> getConversation(String targetId, String? channelId, BHCallbackJS callback);

  // Get conversations
  @JS('getConversations')
  external static Future<int> getConversations(String? channelId, int startTime, int count, BHCallbackJS callback);
  // 获取置顶会话列表 getTopConversations
  @JS('getTopConversations')
  external static Future<int> getTopConversations(BHCallbackJS callback);
  // 设置消息监听
  @JS('setMessageListener')
  external static void setMessageListener(BHCallbackJS callback);

  //获取消息记录 getHistoryMessages(targetId, channelId, count,sentTime, order, callback)
  @JS('getHistoryMessages')
  external static Future<int> getHistoryMessages(String targetId, String? channelId, int count, int sentTime, int order, BHCallbackJS callback);

  //删除消息 deleteMessages(targetId, channelId, messages, callback)
  @JS('deleteMessages')
  external static Future<int> deleteMessages(String targetId, String? channelId, List<dynamic> messages, BHCallbackJS callback);

//创建消息 createTextMessage(type, targetId, channelId, content, callback)
  @JS('createTextMessage')
  external static Future<dynamic> createTextMessage(String content, BHCallbackJS callback);

  // Send text message
  @JS('sendTextMessage')
  external static Future<dynamic> sendTextMessage(String targetId, int? messageId, String content, BHSendMessageCallbackJS callback);

  // Send image message sendImageMessage(targetId, file, messageId, callback)
  @JS('sendImageMessage')
  external static Future<dynamic> sendImageMessage(
      String targetId, dynamic imageFile, int? messageId, String? sendId, String? nickname, String? avatar, BHSendMessageCallbackJS callback);
  // Send voice message sendVoiceMessage(targetId, file, messageId, callback)
  @JS('sendVoiceMessage')
  external static Future<dynamic> sendVoiceMessage(
      String targetId, dynamic voiceFile, int? messageId, String? sendId, String? nickname, String? avatar, BHSendMessageCallbackJS callback);
  // Decode custom message
  @JS('decodeCustomMessage')
  external static Future<dynamic> decodeCustomMessage(String messageType, String content);

  //sendSingleJsonMsgMessage(targetId, content, extra,contentType, callback)
  @JS('sendSingleJsonMsgMessage')
  external static Future<dynamic> sendSingleJsonMsgMessage(String targetId, String content, String extra, String contentType, BHSendMessageCallbackJS callback);

  // Conversation type constants
  static const int PRIVATE = 1;
  static const int GROUP = 2;
  static const int DISCUSSION = 3;
  static const int SYSTEM = 4;

  @JS('my_log_p')
  external static Future<String> myLogP(String goodsCode, String paySource, String invitationId, BHCallbackJS callback);

  @JS('my_browser')
  external static Future<String> myBrowser(String url, int type, int bizType);

  @JS('hasNativePayBridge')
  external static bool hasNativePayBridge();

  //权限申请  0 麦克风  1 摄像头 2 相册
  @JS('my_request_permission')
  external static Future<String> requestPermissions(List<int> permissions, BHCallbackJS callback);

  //获取请求头
  @JS('get_update_my_log_header')
  external static Future<String> getUpdateMyLogHeader(BHCallbackJS callback);

  //退出登录
  @JS('my_log_out')
  external static Future<String> myLogOut();
  //my_log_setting_o
  @JS('my_log_setting')
  external static Future<String> myLogSetting();
  //my_log_wakelock
  @JS('my_log_wakelock')
  external static Future<String> myLogWakelock(bool lock);
  @JS('my_log_recharge')
  external static Future<String> myRecharge(String recharge);

  //my_log
  @JS('my_log')
  external static Future<String> myLog(double price, String currency);

  @JS('my_path')
  external static Future<String> myPath();
  //function(mMessageHandleKeys,mPropertysKeys,mAppEventKeys,mEventKeys
  @JS('initSDK')
  external static Future<String> initSDK(List<String> mMessageHandleKeys, List<String> mPropertysKeys, List<String> mAppEventKeys, List<String> mEventKeys);
  //dismissLoading
  @JS('dismissLoading')
  external static Future<String> dismissLoading();

  //属性
  @JS('sat')
  external static String sat;

  @JS('sab')
  external static String sab;

  @JS('my_log_view_safe_bottom_o')
  external static String? viewSafeBottom;

  @JS('my_log_view_safe_top_o')
  external static String? viewSafeTop;

  @JS('onOpenSwitchCamera')
  external static void onOpenSwitchCamera();

  @JS('codeAppOptions')
  external static dynamic codeAppOptions;

  @JS('updateStrategy')
  external static Future<dynamic> updateStrategy(String str);
  @JS('selectImage')
  external static Future<dynamic> selectImage(BHCallbackJS callback);
}

// Extension to provide more Dart-friendly methods
extension JSConversationExtension on JSRongCloudManager {
  // Convert JavaScript conversation to Dart RCIMIWConversation
  static JSConversation? convertToConversation(dynamic jsConversation) {
    if (jsConversation == null) return null;

    try {
      // Convert JavaScript object to Dart map
      var dartConversation = jsToDart(jsConversation);
      // dartConversation["lastMessage"] = dartConversation["lastMessage"];
      // Create RCIMIWConversation from the converted map
      return JSConversation.fromJson(dartConversation);
    } catch (e) {
      print('Error converting conversation: $e');
      return null;
    }
  }

  // Convert JavaScript conversations list to Dart list of RCIMIWConversation
  static List<JSConversation> convertToConversationList(dynamic jsConversations) {
    var result = jsToDart(jsConversations);
    if (result is List) {
      return result.map((e) => JSConversation.fromJson(e)).toList();
    }
    return [];
  }
}
