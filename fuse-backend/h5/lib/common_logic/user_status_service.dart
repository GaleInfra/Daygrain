//用户在线状态服务

//状态常量
//"Offline", "Online", "Busy", "InCall", "Available"
import 'dart:async';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/flash_chat/start_match/logic.dart';
import 'package:untitled1/utils/common_util.dart';

import '../event_bus/app_lifecycle_state_event.dart';
import '../event_bus/base/event_bus_util.dart';

const String kOffline = "Offline";
const String kOnline = "Online";
const String kBusy = "Busy";
const String kInCall = "InCall";
const String kAvailable = "Available";

//可通话的状态
const List<String> kAvailableStatusList = [kOnline, kAvailable];
//不可通话的状态
const List<String> kDisableStatusList = [kOffline, kBusy, kInCall];

//状态有效期数据模型
class UserStatusModel {
  //用户ID
  String userId;
  //在想状态
  String status;
  //上次更新的时间戳
  int lastUpdate;

  UserStatusModel({required this.userId, required this.status, required this.lastUpdate});
}

UserStatusService? getUserStatusService() {
  return Get.isRegistered<UserStatusService>() ? Get.find<UserStatusService>() : null;
}

class UserStatusService extends GetxService {
  // 当前开启状态
  bool _isStart = false;
  bool get isStart => _isStart;

  // 定时器
  Timer? _timer;

  // 报错在线状态刷新时间
  Map<String, UserStatusModel> statusTimeDic = {};
  // 首页的用户ID  key:Id
  List<String> userIds = [];

  // 用户ID最大容量
  final int maxUserCount = 20;

  // 单次请求最大数量
  final int maxRequestCount = 20;
  // 单次轮询间隔时长
  final Duration requestTimeInterval = const Duration(milliseconds: 2500);
  // 容器偏移值
  final int offset = 10;
  // 有效时长
  final Duration validDuration = const Duration(seconds: 5);
  //缓存读取有效时长
  final Duration validCacheDuration = const Duration(seconds: 10);

  // 监听App状态
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleStateChange;
  @override
  void onInit() {
    super.onInit();
    start();
    //监听前后台变化
    _appLifecycleStateChange = EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        //回到前台
        if (BaseManager.instance.isLogin) {
          start();
          _checkStatus();
        }
      } else if (event.state == AppLifecycleState.paused) {
        //退到后台
        stop();
      }
    });
  }

  // 开启服务
  void start() {
    stop();
    _startTimer();
    _isStart = true;
  }

  // 关闭服务
  void stop() {
    _stopTimer();
    _isStart = false;
  }

  // 开启定时器
  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(requestTimeInterval, (timer) {
      _checkStatus();
    });
  }

  // 关闭定时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // 添加用户ID
  void addUserId(String userId) {
    userIds.remove(userId);
    userIds.insert(0, userId);
    if (userIds.length > maxUserCount + offset) {
      userIds = userIds.sublist(0, maxUserCount);
    }
  }

  // 移除用户ID
  void removeUserId(String userId) {
    userIds.remove(userId);
  }

  // 强制刷新全部状态
  void forceRefresh() {
    statusTimeDic.updateAll((key, value) => UserStatusModel(userId: value.userId, lastUpdate: 0, status: value.status));
    _checkStatus();
  }

  // 批量添加并刷新
  void addUserIdsAndRefresh(List<String> newUserIds) {
    for (String userId in newUserIds) {
      if (statusTimeDic.containsKey(userId)) {
        statusTimeDic[userId] = UserStatusModel(userId: statusTimeDic[userId]!.userId, lastUpdate: 0, status: statusTimeDic[userId]!.status);
      }
      addUserId(userId);
    }
    _checkStatus();
  }

  // 添加用户ID并强制刷新
  void addUserIdAndForceRefresh(String userId) {
    if (statusTimeDic.containsKey(userId)) {
      statusTimeDic[userId] = UserStatusModel(userId: statusTimeDic[userId]!.userId, lastUpdate: 0, status: statusTimeDic[userId]!.status);
    }
    addUserId(userId);
    _checkStatus();
  }

  // 检测一次接口
  void checkStatus() {
    _checkStatus();
  }

  //获取缓存的用户状态
  String? getStatus(String userId) {
    UserStatusModel? model = statusTimeDic[userId];
    if (model == null) {
      return null;
    }
    return model.lastUpdate >= DateTime.now().millisecondsSinceEpoch - validCacheDuration.inMilliseconds ? model.status : null;
  }

   bool _isRequestStatus() {
    //当前正在被呼叫
    if (Get.isRegistered<VideoCallHandler>() && Get.find<VideoCallHandler>().onCallModel != null) {
      return false;
    }
    //当前是否正在匹配中
    if (Get.isRegistered<StartMatchLogic>()) {
      return false;
    }

    //判断当前是否在私聊页面
    if (Get.currentRoute == RoutePath.callPage ||
        Get.currentRoute == RoutePath.onCallPage ||
        Get.currentRoute == RoutePath.videoCallPage) {
      return false;
    }

    return true;
  }

  // 检查在线状态
  void _checkStatus() async {
    if (!BaseManager.instance.isLogin) {
      return;
    }

    List<String> timeOutUserIds = userIds.where((id) => (statusTimeDic[id]?.lastUpdate ?? 0) <= DateTime.now().millisecondsSinceEpoch - validDuration.inMilliseconds).toList();
    if (timeOutUserIds.length > maxRequestCount) {
      timeOutUserIds = timeOutUserIds.sublist(timeOutUserIds.length - maxRequestCount);
    }

    if (timeOutUserIds.isEmpty) {
      logger.e("没有超时用户");
      return;
    }
    
    if (!_isRequestStatus()) {
      return;
    }
    await getReqRepo()?.userGetMoreOnline(
      userIds: timeOutUserIds,
      onSuccess: (obj) {
        statusTimeDic.removeWhere((key, value) => value.lastUpdate <= DateTime.now().millisecondsSinceEpoch - validDuration.inMilliseconds * 1.5);
        final nowTime = DateTime.now().millisecondsSinceEpoch;
        Map<String, String> uidAndStatus = <String, String>{};
        obj.forEach((key, value) {
          statusTimeDic[key] = UserStatusModel(userId: key, lastUpdate: nowTime, status: value);
          uidAndStatus[key] = value;
        });

        if (uidAndStatus.isNotEmpty) {
          EventBusUtil.fire(UserStatusChangeEvent(uidAndStatus: uidAndStatus));
        }
      },
      onFail: (code, msg) {},
    );
  }

  @override
  void onClose() {
    _appLifecycleStateChange?.cancel();
    _appLifecycleStateChange = null;
    _stopTimer();
    userIds.clear();
    statusTimeDic.clear();
    _isStart = false;
    super.onClose();
  }
}

///用户状态变化Event
class UserStatusChangeEvent extends BaseEvent {
  UserStatusChangeEvent({
    required this.uidAndStatus,
  });

  final Map<String, String> uidAndStatus;
}
