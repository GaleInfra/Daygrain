import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/net/api_address.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/sokcet_listener/base/socket_listener.dart';
import 'package:untitled1/sokcet_listener/factory/socket_command_factory.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../model/broadcaster/reward_model.dart';

/// create: 2023/5/8
/// desc: Socket工具
class SocketUtil {
  SocketUtil._internal();

  static final SocketUtil _instance = SocketUtil._internal();

  factory SocketUtil() => _instance;

  Socket? _socket;

  /// 重连定时器
  Timer? retryTimer;

  // 重连尝试次数
  int retryNum = 0;

  /// 每分钟的校验心跳定时器
  /// 当链接成功后开启
  /// 当断开链接后置空
  Timer? timer;

  final RequestRepository _request = Get.find<RequestRepository>();

  bool _logout = false;

  bool isFirstLuanch = false;
  //iOS 切后台后socket 重连存在问题，因此直接重新初始化
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleEvent;
  /// 初始化
  void init() {

    _appLifecycleEvent ??= EventBusUtil.listen<AppLifecycleStateEvent>((event) async {
        if (BHPlatform.isAndroid) {return;}
        if (!isFirstLuanch) {
          isFirstLuanch = true;
          return;
        }
        if (event.state == AppLifecycleState.resumed) {
          logger.d("测试socket进入重连");
          _socket?.disconnect();
          _socket?.close();
          _socket?.destroy();
          _socket?.dispose();
          initSocket();
        }else if (event.state == AppLifecycleState.paused) {
          logger.d("测试socket进入退出");
          // _socket?.disconnect();
          // _socket?.close();
          // _socket?.destroy();
          // _socket?.dispose();
        }
      });

    initSocket();
  }

  void initSocket(){
    _logout = false;
    if (_checkConnect()) {
      // 当前为链接状态
      logger.d("socket当前为已链接状态");
      return;
    }
    startTimer();

    String token = SPUtil.getString(MyKeys.token);
    if (token.isEmpty) {
      return;
    }
    if (retryTimer != null) {
      retryTimer?.cancel();
      retryTimer = null;
      retryNum = 0;
    }
    // 采用socket内部重连，但提示链接错误后则每10秒一次尝试重连
    _socket = null;
    _socket = io(
      "${ApiAddress.socketTest}?token=$token",
      {
        'transports': ["websocket"],
        //Fix: 关闭自动连接，会和下面收到调用 connect 冲突导致重复链接
        'autoConnect': false,
        'reconnection': true,
        "forceNew": true,
        // "extraHeaders": getHeader(),
      },
    );

    logger.d("开始链接socket");
    _socket?.connect();
    _socket?.onConnect(_onConnect);
    _socket?.onConnectError(_onConnectError);
    _socket?.onDisconnect(_onDisconnect);
    _socket?.onConnectTimeout(_onConnectTimeout);

    // 注册事件
    _socket?.on("responseEvent", _onEvent); // 事件处理
    _socket?.on("messageEvent", _onEvent); // 聊天事件处理
  }

  /// 连接/重新链接
  void connect() {
    logger.d("socket开始链接");
    if (_socket == null) {
      //重新初始化
      init();
    } else {
      _socket?.connect();
    }
  }

  ///断网重连
  void reconnect() {
    if (!_checkConnect()) {
      init();
    } else {
      //fix: fix:退到后台重新回来socket没有重新连接，就没有调用领取金币接口，导致没有机器人呼叫的bug
      if (BaseManager.instance.isLogin) {
        //获取领取金币
        if(Get.isRegistered<AppConfigManager>()){
        final appConfig = Get.find<AppConfigManager>();
        if(!(appConfig.userInfo.isRecharge ?? false)){
          // 检查是否已完成五个主播弹窗
          final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
              ? appConfig.userInfo.userId!.toString()
              : 'guest';
          final completedKey = 'robot_chat_completed_$uid';
          final isCompleted = SPUtil.getBool(completedKey, defaultValue: false);
          
          if (isCompleted) {
            getReqRepo()?.coinPresentedGet(onSuccess: (RewardModel data) {});
          }
        }
      }
      }
    }
  }

  /// 发送
  void emit({
    required String event,
    required dynamic data,
  }) {
    if (_socket == null) {
      logger.e("socket为空");
      return;
    }
    _socket?.emit(event, data);
  }

  /// 链接成功
  void _onConnect(dynamic data) {
    logger.d("socket链接成功===> $data");
    DialogUtil.dismissNetworkDialog();
    //进行新用户奖励请求
    if (Get.isRegistered<RequestRepository>()) {
      // 检查是否已完成五个主播弹窗
      final uid = SPUtil.getString(MyKeys.token).isNotEmpty 
          ? SPUtil.getString(MyKeys.userInfo).isNotEmpty 
              ? jsonDecode(SPUtil.getString(MyKeys.userInfo))['userId']?.toString().trim().isNotEmpty == true
                  ? jsonDecode(SPUtil.getString(MyKeys.userInfo))['userId'].toString()
                  : 'guest'
              : 'guest'
          : 'guest';
      final completedKey = 'robot_chat_completed_$uid';
      final isCompleted = SPUtil.getBool(completedKey, defaultValue: false);
      
      if (isCompleted) {
        Get.find<RequestRepository>().coinPresentedGet(onSuccess: (RewardModel data) {});
      }
    }
    isFirstLuanch = true;
    retryTimer?.cancel();
    retryTimer = null;
  }

  /// 链接错误时
  void _onConnectError(dynamic data) {
    logger.d("socket链接错误===> $data");
    _onRetry();
  }

  /// 断开链接时
  void _onDisconnect(dynamic data) {
    logger.d("socket断开链接===> $data");
    _onRetry();
  }

  /// 链接超时
  void _onConnectTimeout(dynamic data) {
    logger.d("socket链接超时");
    // 重连
    connect();
  }

  /// 重试
  void _onRetry() {
    if (!_logout) {
      retryNum++;
      if (retryNum == 5) {
        // Toast.showMsg("The network is disconnected, please check the network settings.");
        //现在超过5次不再提示，但是这里加个重新初始化，因为socket在后台太久会永久断开且不再工作
        retryNum = 0;
      }
      retryTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_checkConnect()) {
          // 取消定时器
          retryTimer?.cancel();
          retryTimer = null;
        } else {
          // 重连
          connect();
        }
      });
    }
  }

  /// 开启心跳检测
  void startTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }

    logger.d("socket开启每分钟心跳");
    _request.userActiveing();
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      log("socket心跳");
      if (!_checkConnect()) {
        // 当前断开，进行重连
        connect();
      }
      // 心跳上报
      _request.userActiveing();
    });
  }

  /// 关闭心跳检测
  void stopTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }
  }

  /// 检查链接状态
  bool _checkConnect() {
    return _socket != null && (_socket?.connected ?? false);
  }

  /// 事件处理/聊天事件处理，数据结构为：
  /// {
  ///    "commandId": "ecef3f5cb6ba48c2ba60fb14455a4184",  // 长连消息id， 用于判断消息的唯一性，相同id不做二次处理
  ///    "command": "onPickUp", // 长连消息名称
  ///    "code": "200",  // 长连消息状态
  ///    "timestamp": 1616384073490,
  ///    "data": null -> Object: 不同长连事件，返回结构不一样
  /// }
  void _onEvent(dynamic data) {
    if (!_checkConnect()) {
      // 断开链接
      connect();
      return;
    }
    logger.d(data);
    handlerMessage(data);
  }

  /// 处理消息
  void handlerMessage(dynamic data) {
    if (data != null) {
      try {
        data = data is String ? jsonDecode(data) : data;
        String code = data['code'];
        if (code != "200") {
          return;
        }
        // 解析数据结构，处理消息数据
        String key = data['command'];
        SocketListener? listener = SocketCommandFactory.getListener(key);
        if (listener == null) {
          return;
        }
        listener.onHandler(data['data']);
        logger.d("socket事件正常处理");
      } catch (e) {
        logger.d("socket事件处理异常: ${e.toString()}");
      }
    }
  }

  /// 关闭
  void onClose() {
    _logout = true;
    _socket?.close();
    _socket?.destroy();
    _socket?.dispose();
    retryTimer?.cancel();
    timer?.cancel();
  }
}
