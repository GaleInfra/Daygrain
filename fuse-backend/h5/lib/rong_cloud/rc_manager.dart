import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../common_logic/app_config_manager.dart';
import '../js/Model/JSConversation.dart';
import '../utils/js_utils.dart';

import 'dart:html' as html;

/// create: 2023/5/4
/// desc: 融云服务管理
class RCManager {
  /// 获取请求仓库
  final RequestRepository _request = Get.find<RequestRepository>();

  String? _rcKey;

  /// 融云token
  String? token;

  Completer? completer;

  final bool isOpenJSIM = true;

  //消息监听回调
  Function(JSMessage? message)? _onMessageReceived;

  Function(JSMessage? message)? get onMessageReceived => _onMessageReceived;
  set onMessageReceived(Function(JSMessage? message)? callback) {
    _onMessageReceived = callback;
    BHCallbackWeb callbackWeb = BHCallbackWeb(
        onSuccess: (data) {
          if (data != null) {
            dynamic dartData = jsToDart(data);
            if (dartData is Map) {
              JSMessage? message = JSMessage.fromJson(dartData as Map<String, dynamic>);
              callback?.call(message);
            } else if (dartData is List) {
              for (var item in dartData) {
                if (item is Map) {
                  JSMessage? message = JSMessage.fromJson(item as Map<String, dynamic>);
                  callback?.call(message);
                }
              }
            }
          }
        },
        onError: (error) {});
    JSRongCloudManager.setMessageListener(callbackWeb.toJS());
  }

  /// 初始化入口，登录成功之后 或 校验token成功之后调用
  /// 由各自请求内部抛出异常给外部获取
  Future initEnter() async {
    completer = Completer();
    String? key = _getRcAppKey();
    if (key == null || key.isEmpty) {
      key = _getRckKey();
    }
    if (key == null || key.isEmpty) {
      logger.e("无融云key");
      return;
    }
    _rcKey = key;
    await _getRongCloudToken();

    //TODO:后续看如何兼容融云迁移

    try {
      _initEngine();
    } catch (e) {}
  }

  /// 初始化引擎
  Future _initEngine() async {
    SPUtil.setString(MyKeys.oldRcKey, _rcKey!);
    // 初始化
    logger.d("融云引擎初始化");

    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      completer?.complete("rc connect");
    }, onError: (error) {
      completer?.completeError(error);
    });
    await JSRongCloudManager.initRongCloud(_rcKey!, token!, rcAreaCode()!, callbackWeb.toJS());
    // 初始化消息监听
    RCMessageManager().init();
  }

  /// 获取融云token
  Future _getRongCloudToken() async {
    token = SPUtil.getString(MyKeys.rongCloudToken);
    await _request.rongCloudToken(
      rcKey: _getRcAppKey() ?? "",
      onSuccess: (data) {
        token = data;
        SPUtil.setString(MyKeys.rongCloudToken, data);
      },
      onFail: (code, msg) {},
    );
  }

  /// 销毁
  Future onDestroy() async {
    // await _engine?.disconnect(false);
    // _engine?.onMessageReceived = null;
    // await _engine?.destroy();
  }

  // 旧融云key
  String? _getRckKey() {
    return Get.find<AppConfigManager>().getAppConfigByKey("rck");
  }

  // 新融云key
  String? _getRcAppKey() {
    return Get.find<AppConfigManager>().getAppConfigByKey("rc_app_key");
  }

  String? _rcNaviServer() {
    return Get.find<AppConfigManager>().getAppConfigByKey("rc_navi_server");
  }

  String? _rcStatServer() {
    return Get.find<AppConfigManager>().getAppConfigByKey("rc_stat_server");
  }

  // 获取安卓端融云目录
  Future<String> _getAndroidRcDir(String key) async {
    final userId = Get.find<AppConfigManager>().userInfo.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception("异常: userId is null");
    }
    try {
      final directory = await getApplicationSupportDirectory();
      return "${directory.path}/$key/$userId";
    } catch (e) {
      logger.e("获取安卓端融云目录失败: $e");
      rethrow;
    }
  }

  // 获取iOS端Documents融云目录
  Future<String> _getIOSRcDocDir(String appKey) async {
    final userId = Get.find<AppConfigManager>().userInfo.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception("异常: userId is null");
    }
    try {
      //Documents/newAppKey/userId/storage 路径
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$appKey/$userId';
    } catch (e) {
      logger.e("获取iOS端Documents失败: $e");
      rethrow;
    }
  }

  // 获取iOS端Library融云目录
  Future<String> _getIOSRcLibraryDir(String appKey) async {
    final userId = Get.find<AppConfigManager>().userInfo.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception("异常: userId is null");
    }
    try {
      //Documents/newAppKey/userId/storage 路径
      final directory = await getApplicationSupportDirectory();
      return '${directory.path}/RongCloud/$appKey/$userId';
    } catch (e) {
      logger.e("获取iOS端Library失败: $e");
      rethrow;
    }
  }

  // 迁移
  Future<void> _moveRcDir(String oldDirPath, String newDirPath) async {
    //判断 newDir 是否存在，不存在则创建
    var newDir = Directory(newDirPath);
    if (!newDir.existsSync()) {
      // 目录不存在则创建
      newDir.createSync(recursive: true);
    }
    var oldDir = Directory(oldDirPath);
    var oldFiles = oldDir.listSync();
    for (var file in oldFiles) {
      final fileName = file.path.split('/').last;
      // 只迁移“storage”、“storage-shm”、“storage-wal” 文件
      if (['storage', 'storage-shm', 'storage-wal'].contains(fileName)) {
        var newPath = file.path.replaceAll(oldDirPath, newDirPath);
        file.renameSync(newPath);
      }
    }
  }

  getTotalUnreadCount(String? channelId, {JSGetTotalUnreadCountCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      if (data != null) {
        callback?.onSuccess(jsToDart(data));
      }
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });

    JSRongCloudManager.getTotalUnreadCount(callbackWeb.toJS());

    return 0;
  }

  getConversation(String targetId, String? channelId, {JSGetConversationCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      if (data != null) {
        //LinkedHashMap => List<RCIMIWConversationType>
        JSConversation? conversationList = JSConversationExtension.convertToConversation(data);

        callback?.onSuccess(conversationList);
      }
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });

    await JSRongCloudManager.getConversation(targetId, channelId, callbackWeb.toJS());

    return 0;
  }

  getConversations(String? channelId, int startTime, int count, {JSGetConversationsCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      if (data != null) {
        List<JSConversation> conversationList = JSConversationExtension.convertToConversationList(data);
        callback?.onSuccess(conversationList);
      }
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });

    var result = await JSRongCloudManager.getConversations(channelId, startTime, count, callbackWeb.toJS());

    return result;
  }

  //获取置顶会话列表
  getTopConversations({JSGetConversationsCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      if (data != null) {
        List<JSConversation> conversationList = JSConversationExtension.convertToConversationList(data);
        callback?.onSuccess(conversationList);
      }
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });

    await JSRongCloudManager.getTopConversations(callbackWeb.toJS());
  }

  clearUnreadCount(String targetId, {JSClearUnreadCountCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      callback?.onUnreadCountCleared(0);
    }, onError: (error) {
      callback?.onUnreadCountCleared(-1);
    });
    await JSRongCloudManager.clearMessagesUnreadStatus(targetId, callbackWeb.toJS());
    return 0;
  }

  removeConversation(String targetId, {JSRemoveConversationCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      callback?.onSuccess(0);
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });
    await JSRongCloudManager.removeConversation(targetId, callbackWeb.toJS());
    return 0;
  }

  changeConversationTopStatus(String targetId, bool top, {JSActionCallback? callback}) async {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      callback?.onSuccess(0);
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });
    await JSRongCloudManager.changeConversationTopStatus(targetId, top, callbackWeb.toJS());
    return 0;
  }

  void addToBlacklist(String userId, {JSActionCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    try {
      JSRongCloudManager.addToBlacklist(
          userId,
          BHCallbackWeb(onSuccess: (data) {
            callback?.onSuccess(0);
          }, onError: (error) {
            callback?.onError(jsToDart(error));
          }).toJS());
    } catch (e) {}
  }

  void removeFromBlacklist(String userId, {JSActionCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    try {
      JSRongCloudManager.removeFromBlacklist(
          userId,
          BHCallbackWeb(onSuccess: (data) {
            callback?.onSuccess(0);
          }, onError: (error) {
            callback?.onError(jsToDart(error));
          }).toJS());
    } catch (e) {}
  }

  getMessages(String targetId, String? channelId, int sentTime, int order, int count, {JSGetMessagesCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      if (data != null) {
        List<dynamic> listM = jsToDart(data);
        List<JSMessage> conversationList = listM.map((e) => JSMessage.fromJson(e)).toList();
        //数组倒序
        conversationList = conversationList.reversed.toList();
        callback?.onSuccess(conversationList);
      }
    }, onError: (error) {
      callback?.onError(jsToDart(error));
    });

    JSRongCloudManager.getHistoryMessages(targetId, channelId, count, sentTime, order, callbackWeb.toJS());

    return 0;
  }

  deleteMessages(String targetId, String? channelId, List<JSMessage> messages, {JSDeleteMessagesCallback? callback}) {
    BHCallbackWeb callbackWeb = BHCallbackWeb(onSuccess: (data) {
      callback?.onMessagesDeleted(0, messages);
    }, onError: (error) {
      callback?.onMessagesDeleted(-1, []);
    });

    JSRongCloudManager.deleteMessages(targetId, channelId, dartToJS(messages.map((e) => e.toJson()).toList()), callbackWeb.toJS());

    return 0;
  }

  Future sendSingleJsonMessage(
      {required String targetId, required String content, required String contentType, required String customExtra, JSSendMessageCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHSendMessageCallbackWeb callbackWeb = BHSendMessageCallbackWeb(
        onSuccess: (data) {
          if (data != null) {
            dynamic dataJson = jsToDart(data);
            if (dataJson is Map) callback?.onMessageSent(0, JSMessage.fromJson(dataJson as Map<String, dynamic>));
          }
        },
        onSendBefore: (data) {
          if (data != null) {
            dynamic dataJson = jsToDart(data);
            if (dataJson is Map) callback?.onMessageSaved!(JSMessage.fromJson(dataJson as Map<String, dynamic>));
          }
        },
        onError: (error) {});

    await JSRongCloudManager.sendSingleJsonMsgMessage(targetId, content, customExtra, contentType, callbackWeb.toJS());

    return 0;
  }

  ///发送文本消息
  Future sendTextMessage(String targetId, int? messageId, String content, {JSSendMessageCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHSendMessageCallbackWeb callbackWeb = BHSendMessageCallbackWeb(onSuccess: (data) {
      if (data != null) {
        callback?.onMessageSent(0, JSMessage.fromJson(jsToDart(data)));
      }
    }, onSendBefore: (data) {
      if (data != null) {
        if (callback?.onMessageSaved != null) callback!.onMessageSaved!(JSMessage.fromJson(jsToDart(data)));
      }
    }, onError: (code) {
      callback?.onMessageSent(code, null);
    });

    await JSRongCloudManager.sendTextMessage(targetId, messageId, content, callbackWeb.toJS());
  }

  //发送图片消息
  Future sendImageMessage(String targetId, html.File imageFile, int? messageId, String? sendId, String? nickname, String? avatar, {JSSendMessageCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHSendMessageCallbackWeb callbackWeb = BHSendMessageCallbackWeb(
        onSuccess: (data) {
          if (data != null) {
            callback?.onMessageSent(0, JSMessage.fromJson(jsToDart(data)));
          }
        },
        onSendBefore: (data) {
          if (data != null) {
            if (callback?.onMessageSaved != null) callback!.onMessageSaved!(JSMessage.fromJson(jsToDart(data)));
          }
        },
        onError: (error) {});
    await JSRongCloudManager.sendImageMessage(targetId, imageFile, messageId, sendId, nickname, avatar, callbackWeb.toJS());
  }
  //发送语音消息
  Future sendVoiceMessage(String targetId, html.File voiceFile, int? messageId, String? sendId, String? nickname, String? avatar, {JSSendMessageCallback? callback}) async {
    await Get.find<RCManager>().completer?.future;
    BHSendMessageCallbackWeb callbackWeb = BHSendMessageCallbackWeb(
        onSuccess: (data) {
          if (data!= null) {
            callback?.onMessageSent(0, JSMessage.fromJson(jsToDart(data)));
          }
        },
        onSendBefore: (data) {
          if (data!= null) {
            if (callback?.onMessageSaved!= null) callback!.onMessageSaved!(JSMessage.fromJson(jsToDart(data)));
          }
        },
        onError: (code) {
          
        },
    );
    await JSRongCloudManager.sendVoiceMessage(targetId, voiceFile, messageId, sendId, nickname, avatar, callbackWeb.toJS());
  }
}

/// 融云area_code
String? rcAreaCode() {
  return Get.find<AppConfigManager>().getAppConfigByKey("rc_area_code");
}

class JSGetConversationsCallback {
  JSGetConversationsCallback({required this.onSuccess, required this.onError});

  Function(List<JSConversation>? t) onSuccess;
  Function(int? code) onError;
}

class JSGetConversationCallback {
  JSGetConversationCallback({required this.onSuccess, required this.onError});

  Function(JSConversation? t) onSuccess;
  Function(int? code) onError;
}

class JSGetMessagesCallback {
  JSGetMessagesCallback({required this.onSuccess, required this.onError});

  Function(List<JSMessage>? t) onSuccess;
  Function(int? code) onError;
}

class JSDeleteMessagesCallback {
  JSDeleteMessagesCallback({required this.onMessagesDeleted});

  Function(int? code, List<JSMessage>? messages) onMessagesDeleted;
}

class JSSendMessageCallback {
  JSSendMessageCallback({this.onMessageSaved, required this.onMessageSent});

  Function(JSMessage? message)? onMessageSaved;
  Function(int? code, JSMessage? message) onMessageSent;
}

class JSGetTotalUnreadCountCallback {
  JSGetTotalUnreadCountCallback({required this.onSuccess, required this.onError});

  Function(int? t) onSuccess;
  Function(int? code) onError;
}

class JSClearUnreadCountCallback {
  JSClearUnreadCountCallback({required this.onUnreadCountCleared});

  Function(int? code) onUnreadCountCleared;
}

class JSRemoveConversationCallback {
  JSRemoveConversationCallback({required this.onSuccess, required this.onError});

  Function(int? code) onSuccess;
  Function(int? code) onError;
}

class JSActionCallback {
  JSActionCallback({required this.onSuccess, required this.onError});

  Function(int? code) onSuccess;
  Function(int? code) onError;
}
