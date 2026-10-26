import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/on_im_trigger_call_model.dart';
import 'package:untitled1/model/video_call/pick_up_model.dart';
import 'package:untitled1/my_app.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/pages/video_call/video_call/widget/guided_recharge_dialog.dart';
import 'package:untitled1/res/pay_entry.dart';
import 'package:untitled1/utils/audio_play.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/utils/privacy_mode_manager.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/widget/dialog/vip_coin_gift_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
// import 'package:vibration/vibration.dart';

import '../base_manager.dart';
import '../config/route.dart';
import '../database/controller/video_call_contoller.dart';
import '../database/dao/video_call_dao.dart';
import '../event_bus/base/event_bus_util.dart';
import '../event_bus/video_call/video_call_event.dart';
import '../model/video_call/hang_up_model.dart';
import '../model/video_call/on_call_model.dart';
import '../model/video_call/video_call_result_model.dart';
import '../net/base/response_parse.dart';
import '../net/request_repository.dart';
import '../pages/flash_chat/start_match/logic.dart';
import '../pages/video_call/video_call/video_call_end_dialog.dart';
import '../res/video_call_data.dart';
import '../utils/online_status_util.dart';
import '../utils/throttle_util.dart';
import '../utils/toast.dart';
import '../widget/dialog/on_call_dialog.dart';
import '../widget/dialog/recharge_dialog.dart';
import '../widget/msg_notication/message_notication.dart';
import 'app_config_manager.dart';
// import 'package:untitled1/business/say_hi/robot_chat_manager.dart';

/// create: 2023/6/8
/// desc: 视频通话处理中转
class VideoCallHandler extends GetxController {
  /// 请求仓库
  final _request = Get.find<RequestRepository>();

  /// 视频通话数据库操作类
  final _videoSql = Get.find<VideoCallController>();

  /// 呼叫/被呼叫数据，当前用户为被呼叫时，该字段有呼叫方的头像等，改变值时用这个字段
  /// 目前保持fromUserId都是发起方id
  /// 为VIP时，呼入下发的价格已经是VIP价格
  OnCallModel? _onCallModel;

  /// 非改变值状态时，用这个字段
  OnCallModel? get onCallModel => _onCallModel;

  /// 被呼叫方用户数据，该字段仅呼叫方所有
  UserInfoModel? _userInfo;

  /// 非改变值状态时，用这个字段
  UserInfoModel? get userInfo => _userInfo;

  /// 呼叫入口来源，分类见[VideoCallSource]类，该字段仅呼叫方所有
  int _callSource = -1;

  /// 非改变值状态时，用这个字段
  int get callSource => _callSource;

  /// 是否通话中
  bool _calling = false;

  ///判断双方是否已经加入通话
  bool isJoined = false;

  /// 是否为呼出方
  bool get isCallOut => onCallModel?.fromUserIdStr?.toString() == _appConfig.userInfo.userId;

  /// socket流监听
  StreamSubscription<VideoCallEvent>? _event;

  /// 监听支付成功事件
  StreamSubscription<RechargeSuccessEvent>? _rechargeSuccessEvent;

  final _appConfig = Get.find<AppConfigManager>();

  /// ===========  声明周期  =========
  ///
  /// 集中统一处理socket事件
  void init() async {
    // 检查隐私模式状态
    final isPrivateMode = await PrivacyModeManager.isPrivacyModeEnabled();
    if (isPrivateMode) {
      // 处于隐私模式，不初始化监听
      logger.d("当前处于隐私模式，不初始化视频通话监听");
      return;
    }

    // 未完成五次全屏假视频时，禁止初始化监听（不接任何消息）
    final bool isRobotCompleted = await _isRobotFiveCompleted();
    if (!isRobotCompleted) {
      logger.d("未完成五次全屏假视频，不初始化视频通话监听");
      return;
    }

    _event?.cancel();
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      if (event.command == SocketCommandKey.onIMTriggerCall) {
        // 被呼叫
        _onIMTriggerCall(event.data);
      } else if (event.command == SocketCommandKey.onCall) {
        // 被呼叫
        _onCall(event.data);
      } else if (event.command == SocketCommandKey.onPickUp) {
        PickUpModel model = event.data;
        if (model.channelName == _onCallModel?.channelName) {
          // 被接通
          _onPickUp();
        }
      } else if (event.command == SocketCommandKey.onHangUp) {
        // 被挂断
        _onHangUp(event.data);
      }
    });
    _rechargeSuccessEvent?.cancel();
    _rechargeSuccessEvent = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      //判断当前是否正在被呼叫，并且是否是搭讪电话
      if (onCallModel?.channelName?.startsWith("im_trigger_call_") ?? false) {
        //挂断通话
        _doHangUp(
            mOnCallModel: onCallModel!,
            userId: onCallModel?.fromUserIdStr.toString() ?? "",
            callSource: callSource,
            callType: VideoCallType.missed,
            isCalling: true,
            mIsCallOut: false,
            isBackMatch: false);
      }
    });
  }

  /// 搭讪电话
  void _onIMTriggerCall(OnIMTriggerCallModel model) async {
    // 拦截：未完成五次全屏假视频，不接收任何消息
    if (!await _isRobotFiveCompleted()) {
      logger.d("未完成五次全屏假视频，拦截搭讪来电");
      return;
    }
    OnCallModel onCallModel = OnCallModel(
      fromUserId: model.fromUserId,
      toUserId: model.toUserId,
      unitPrice: model.unitPrice,
      isFree: model.isFree,
      h5FromUserId: model.h5FromUserId,
      h5ToUserId: model.h5ToUserId,
      callCategory: model.callCategory,
      clientSessionId: model.uniqueId,
      broadcasterUnitPrice: model.unitPrice,
      channelName: "im_trigger_call_${model.uniqueId}",
    );
    // 获取对方用户数据 先拿缓存
    UserInfoModel? userInfo = CacheManager.userInfoCache(model.fromUserIdStr.toString());
    if (userInfo == null) {
      // 获取对方用户数据
      await _request.userGetInfo(
        userId: model.fromUserIdStr.toString(),
        onSuccess: (data) {
          if (this.onCallModel?.channelName == "im_trigger_call_${model.uniqueId}") {
            userInfo = data;
          }
        },
        onFail: (code, msg) {},
      );
    }
    if (userInfo != null) {
      onCallModel.gender = userInfo!.gender;
      onCallModel.age = userInfo!.age;
      onCallModel.country = userInfo!.country;
      onCallModel.nickname = userInfo!.nickname;
      onCallModel.avatar = userInfo!.avatar;
      onCallModel.avatarThumbUrl = userInfo!.avatarThumbUrl;
      onCallModel.isFriend = userInfo!.isFriend;
      onCallModel.isVip = userInfo!.isVip;
    } else {
      return;
    }

    // 搭讪电话
    _onCall(onCallModel);
  }

  /// 销毁前操作【销毁Controller前调用】
  Future onBeforeClose() async {
    await hangUp(
      onSuccess: (data) {},
      onFail: (code, msg) {},
    );
    _event?.cancel();
    onShopCallPlayer();
    _onCancelTimer();
    disposePlayer();
  }

  /// 检查是否可通话，如果可通话，保存入口来源和被呼叫方用户数据
  /// [callSource] 入口来源
  /// [userInfo] 对方用户数据，需要[userId]、[unitPrice]、[age]、[country]、[nickname]、[avatarThumbUrl]字段
  Future<void> onCheckToCall({
    required int callSource,
    required String onlineStatus,
    required UserInfoModel userInfo,
  }) async {
    //判断是否vip（无 VIP 商品时不拦，避免空弹窗；Web 端 sheet 已禁用背景视频）
    if (VipPrivilegesSheet.shouldGateNonVip()) {
      VipPrivilegesSheet.show();
      return;
    }
    if ((_appConfig.userInfo.availableCoins ?? 0) < (userInfo.unitPrice ?? 0) && !_appConfig.isReviewPkg.value) {
      // 金币不足且当前不是审核模式，弹充值弹窗
      Toast.showMsg("error_insufficientDiamonds".bhTR);
      RechargeDialog.show(entry: PayEntry.SOURCE_8, bindWidget: null);
      return;
    }
    try {
      await checkCameraAndMicrophonePermission(showDialog: true, isAwait: true);
    } catch (e) {
      logger.e(e);
      //点击获取权限则中断流程
      return;
    }
    if (onlineStatus != OnlineStatusUtil.online && onlineStatus != OnlineStatusUtil.available) {
      // if (callSource == 4) {
      //   //呼叫超时
      //   Toast.showMsg("error_userPhoneUnattended".bhTR);
      // } else {
      //Toast 当前用户在忙中
      if (onlineStatus == OnlineStatusUtil.offline) {
        Toast.showMsg("error_userIsOffline".bhTR);
      } else if (onlineStatus == OnlineStatusUtil.busy) {
        Toast.showMsg("user_is_busy".bhTR);
      } else {
        Toast.showMsg("error_userIsBusy".bhTR);
      }

      // }
      return;
    }
    if (onCallModel != null) {
      // 当前正在通话中
      return;
    }
    //当前是否正在匹配中
    if (Get.isRegistered<StartMatchLogic>()) {
      //正在匹配中
      return;
    }
    //关闭IM弹框
    MessageNotication.dismiss();
    throttleUtil.throttle(() async {
      if (VipPrivilegesSheet.shouldGateNonVip()) {
        VipPrivilegesSheet.show();
        return;
      }
      // 在线状态为可拨打状态，点击可进行拨打
      // 判断金币数，不足够的话不能拨打，审核模式呼叫时无需判断是否金币不足
      if ((_appConfig.userInfo.availableCoins ?? 0) < (userInfo.unitPrice ?? 0) && !_appConfig.isReviewPkg.value) {
        // 金币不足且当前不是审核模式，弹充值弹窗
        Toast.showMsg("error_insufficientDiamonds".bhTR);
        RechargeDialog.show(entry: PayEntry.SOURCE_8, bindWidget: null);
      } else {
        /// 保存入口来源 和 对方用户数据
        _callSource = callSource;
        _userInfo = userInfo;
        update();
        // 前往呼叫页
        Get.toNamed(RoutePath.callPage);
      }
    }, time: 2000, key: "call_handler_onCheckToCall");
  }

  /// 创建频道
  Future<void> onCreateChannel({
    required Success<String?> onSuccess,
    required Fail onFail,
  }) async {
    if (callSource == -1 || userInfo == null) {
      // 数据为空时直接返回错误
      onFail.call(-1, "error");
      logger.e("创建频道错误[data must not empty]===>\ncallSource: [$callSource]\nuserInfo: ${prettyJson(userInfo?.toJson())}");
      return;
    }
    _onCallModel = OnCallModel(clientSessionId: uuid.v4());
    onNotice();

    final String toUserId = userInfo?.userId ?? "";
    final String clientSessionId = _onCallModel!.clientSessionId!;
    await _request.videoCallChannelCreate(
      toUserId: toUserId,
      callType: 1,
      clientSessionId: clientSessionId,
      callSource: callSource,
      onSuccess: (data) {
        if (Get.currentRoute == RoutePath.callPage && _onCallModel?.clientSessionId == clientSessionId) {
          _onCallModel = data;
          debugPrint("创建频道成功: ${prettyJson(data.toJson())}");
          //只有还在呼叫也才创建
          onSuccess.call(data.channelName);
          update();
        } else {
          //不在呼叫页 关闭铃声
          // _onCancelNotice();
          if (_onCallModel?.clientSessionId != clientSessionId) {
            _requestVideoCallHangUp(
              channelName: data.channelName ?? "",
              handUpReason: HandUpReason.NORMAL,
              oppositeUserId: toUserId,
              onSuccess: (data) {},
              onFail: (int code, String msg) {},
            );
          } else {
            //只有还在呼叫也才创建
            onSuccess.call(data.channelName);
          }
        }
      },
      onFail: (int code, String msg) {
        if (_onCallModel?.clientSessionId != clientSessionId) {
          // 不是本次创建的通话 忽略
          return;
        }
        _onCallModel = null;
        if (Get.currentRoute == RoutePath.callPage) {
          // 当前是呼叫页时退出
          Get.back();
        }
        if (code == 20010009) {
          if (VipPrivilegesSheet.shouldGateNonVip()) {
            VipPrivilegesSheet.show();
            return;
          }
          // 金币不足，进入充值页
          RechargeDialog.show(entry: PayEntry.SOURCE_8, bindWidget: null);
          // 金币不足，进入充值页

          Toast.showMsg("error_insufficientDiamonds".bhTR);
        } else {
          if (code == 20010016 || code == 20010024) {
            // 机器人忙线 或 主播忙线
            Toast.showMsg("status_callerBusy".bhTR);
            //刷新用户状态
            getUserStatusService()?.addUserIdsAndRefresh([toUserId]);
          }
        }
        onShopCallPlayer();
        onFail.call(code, msg);
        // 创建频道失败，重置所有数据
        resetData();
      },
    );
  }

  /// 快速匹配
  Future<void> onFlashChat({
    required UserInfoModel? userInfo,
    required OnCallModel? onCallModel,
  }) async {
    _userInfo = userInfo;
    _onCallModel = onCallModel;
    _callSource = VideoCallSource.FAST_MATCH;
    logger.i("设置匹配通话来源: _callSource=${_callSource}, 期望值=${VideoCallSource.FAST_MATCH}");
    logger.i("匹配类型信息: callCategory=${onCallModel?.callCategory}, 匹配类型=${onCallModel?.callCategory == 2 ? '女神匹配' : '普通匹配'}");
    update();
  }

  /// 被挂断 - EventBus事件
  /// 被挂断事件不处理页面关闭（因为会有通话中打开充值的情况）
  void _onHangUp(HangUpModel hangUpModel) async {
    if (onCallModel == null || hangUpModel.channelName != onCallModel?.channelName) {
      // 被挂断，但是当前无任何被呼叫数据 || 挂断频道不同，则拦截 PS: 匹配中不会走这个流程，因为目前匹配中 onCallModel 是为空的
      logger.e("被挂断事件拦截");
      return;
    }
    throttleUtil.throttle(() async {
      throttleUtil.throttle(() async {}, key: "playHangUpSound1", onAfter: () async {
        AudioPlay.instance.playHangUpSound();
      }, time: 500);
      //提前获取全局数据，因为后面需要清空
      final OnCallModel mOnCallModel = onCallModel!;
      final bool mIsCalling = _calling;

      final bool mIsCallOut = isCallOut;
      final int mCallSource = _callSource;

      final bool isBackMatch = Get.findCanNull<VideoCallLogic>()?.isBackMatch ?? false;

      String userId = "";

      /// 对方用户id
      String callType = "";

      /// 通话类型
      if (mIsCallOut) {
        // [呼叫方] 被挂断
        userId = mOnCallModel.toUserIdStr?.toString() ?? "";
        callType = mIsCalling ? VideoCallType.outgoing : VideoCallType.unanswered;
      } else {
        // [被呼叫方] 被挂断
        userId = mOnCallModel.fromUserIdStr?.toString() ?? "";
        callType = mIsCalling ? VideoCallType.incoming : VideoCallType.missed;
      }
      print("SocketCommandKey.onHangUpComplete");

      /// 发送被挂断执行完成事件 给到页面更新
      EventBusUtil.fire<VideoCallEvent>(VideoCallEvent(
        command: SocketCommandKey.onHangUpComplete,
        data: hangUpModel,
      ));
      var reason = HandUpReason.NORMAL;
      if ((hangUpModel.reason ?? 0) == 2) {
        reason = HandUpReason.NO_COINS;
      } else if ((hangUpModel.reason ?? 0) == 1) {
        reason = HandUpReason.NORMAL;
      } else {
        reason = HandUpReason.CL_EXCEPTION;
      }
      _requestVideoCallHangUp(
        channelName: mOnCallModel.channelName ?? "",
        handUpReason: reason,
        oppositeUserId: userId,
        onSuccess: (data) {},
        onFail: (code, msg) {},
      );

      _doHangUp(mOnCallModel: mOnCallModel, userId: userId, callType: callType, isCalling: mIsCalling, mIsCallOut: mIsCallOut, callSource: mCallSource, isBackMatch: isBackMatch);
    }, key: "on_hang_up_${onCallModel?.channelName ?? (onCallModel?.clientSessionId ?? "")}");
  }

  /// 主动挂断
  /// [saveCall] 是否保存记录
  /// [manual] 是否手动挂断
  /// [onSuccess] 成功回调
  /// [onFail] 失败回调
  /// [onCancelTimer] 是否取消计时
  Future<void> hangUp({
    int handUpReason = HandUpReason.NORMAL,
    bool manual = true,
    bool isBackMatch = false,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    AudioPlay.instance.playHangUpSound();
    logger.i("主动挂断拦截===>");
    if (onCallModel == null) {
      onFail.call(-1, "error");
      logger.i("主动挂断拦截===>onCallModel:${prettyJson(onCallModel?.toJson())}");
      return;
    }
    throttleUtil.throttle(() async {
      //提前获取全局数据，因为后面需要清空
      final OnCallModel mOnCallModel = onCallModel!;
      final bool isCalling = _calling;

      final bool mIsCallOut = isCallOut;
      final int mCallSource = _callSource;
      String userId = "";

      /// 对方用户id
      String callType = "";

      /// 通话类型
      if (isCallOut) {
        // 呼出
        userId = onCallModel?.toUserIdStr?.toString() ?? "";
        if (isCalling) {
          // 已通话，为呼出类型
          callType = VideoCallType.outgoing;
        } else if (handUpReason == HandUpReason.CL_CALL_TIMEOUT) {
          // 超时挂断
          callType = VideoCallType.unanswered;
        } else {
          // 其他挂断
          callType = VideoCallType.cancelled;
        }
      } else {
        // 呼入挂断
        userId = onCallModel?.fromUserIdStr?.toString() ?? "";
        if (handUpReason == HandUpReason.CL_CALL_TIMEOUT) {
          callType = VideoCallType.missed;
        } else {
          callType = isCalling ? VideoCallType.incoming : VideoCallType.rejected;
        }
      }

      if (mOnCallModel.channelName?.isNotEmpty ?? false) {
        //如果要请求接口则提前关闭声音和倒计时，避免接口等待过程声音不关闭PS:后续再调整
        // 关闭被呼叫弹窗
        OnCallDialog.dismiss();
        _onCancelTimer();
        onShopCallPlayer();
        //只有有channelName的时候才会请求挂断
        _requestVideoCallHangUp(
          channelName: mOnCallModel.channelName ?? "",
          handUpReason: handUpReason,
          oppositeUserId: userId,
          onSuccess: (data) {
            //成功回调
            onSuccess.call(true);
            _doHangUp(
              mOnCallModel: mOnCallModel,
              userId: userId,
              callType: callType,
              isCalling: isCalling,
              callSource: mCallSource,
              mIsCallOut: mIsCallOut,
              isBackMatch: isBackMatch,
            );
          },
          onFail: (code, msg) {
            //失败回调
            onFail.call(code, msg);
            _doHangUp(
              mOnCallModel: mOnCallModel,
              userId: userId,
              callType: callType,
              isCalling: isCalling,
              callSource: mCallSource,
              mIsCallOut: mIsCallOut,
              isBackMatch: isBackMatch,
            );
          },
        );
      } else {
        _doHangUp(
          mOnCallModel: mOnCallModel,
          userId: userId,
          callType: callType,
          isCalling: isCalling,
          callSource: mCallSource,
          mIsCallOut: mIsCallOut,
          isBackMatch: isBackMatch,
        );
        onSuccess.call(true);
      }
    }, key: "on_hang_up_${onCallModel?.channelName ?? (onCallModel?.clientSessionId ?? "")}");
  }

  //请求挂断接口
  void _requestVideoCallHangUp({
    required String channelName,
    required int handUpReason,
    required String oppositeUserId,
    required Success<bool> onSuccess,
    required Fail onFail,
    int retryCount = 2,
  }) {
    _request.videoCallHangUp(
      channelName: channelName,
      handUpReason: handUpReason,
      oppositeUserId: oppositeUserId,
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: (code, msg) {
        if (retryCount > 0) {
          _requestVideoCallHangUp(
            channelName: channelName,
            handUpReason: handUpReason,
            oppositeUserId: oppositeUserId,
            onSuccess: onSuccess,
            onFail: onFail,
            retryCount: retryCount - 1,
          );
        } else {
          onFail.call(code, msg);
        }
      },
    );
  }

//执行内部挂断逻辑 执行数据保存和状态回复
  ///[mOnCallModel] 当前被呼叫信息
  ///[userId] 对方用户id
  ///[callType] 通话类型
  /// 执行逻辑
  /// 1. 关闭弹窗&计时器&铃声
  /// 2. 将数据保存为临时变量
  /// 3. 如果有通话中的数据
  ///    1. 调用通话结果接口
  /// 4. 添加通话记录
  /// 5. 重置全局状态的数据
  Future<bool> _doHangUp({
    required OnCallModel mOnCallModel,
    required String userId,
    required int callSource,
    required String callType,
    required bool isCalling,
    required bool mIsCallOut,
    required bool isBackMatch,
  }) async {
    // 关闭被呼叫弹窗
    OnCallDialog.dismiss();
    _onCancelTimer();
    onShopCallPlayer();
    final UserInfoModel mUserInfo = _userInfo ??
        UserInfoModel(
          nickname: mOnCallModel.nickname ?? "",
          avatar: mOnCallModel.avatar ?? "",
          userId: userId,
        );

    // 在这里保留 callSource 的值，用于后面的记录
    int originalCallSource = _callSource;
    logger.i("保存通话来源: originalCallSource=$originalCallSource, _callSource=$_callSource");

    VideoCallResultModel? resultModel;
    if (isCalling) {
      // 通话过程中挂断，获取通话结果
      if (!isBackMatch) {
        if (!(_appConfig.userInfo.isRecharge ?? false) && isJoined) {
          Future.delayed(const Duration(milliseconds: 300), () {
            DialogQueueUtil.to.addDialog(DialogQueueElement(
              onShow: () => GuidedRechargeDialog.show(userInfo: mUserInfo),
            ));
          });
        }
      }

      if (mOnCallModel.channelName != null) {
        resultModel = await _getCallResult(channelName: mOnCallModel.channelName ?? "");
        if (!isBackMatch) {
          _videoCallEnd(
            callSource: originalCallSource,
            resultModel: resultModel,
            onCallModel: mOnCallModel,
            userInfoModel: mUserInfo,
            isBackMatch: isBackMatch,
          );
        }
      }
    }

    if (mOnCallModel.channelName != null && userId.isNotEmpty) {
      //添加通话记录
      _insertHistory(
        userId: userId,
        callType: callType,
        seconds: resultModel?.duration ?? 0,
        onCallModel: mOnCallModel,
        isCallOut: mIsCallOut,
        userInfo: mUserInfo,
        calling: isCalling,
        forceCallSource: originalCallSource, // 传递保存的匹配来源
      );
    }

    //清空数据 - 移到这里，在保存通话记录之后
    resetData();

    return true;
  }

  /// 接听，此方法为被呼叫方调用，所以在此处处理被呼叫方到跳转逻辑
  /// 被呼叫方流程--> 关闭被呼叫弹窗、被呼叫页，跳转到视频通话页
  /// 呼叫方流程--> 关闭呼叫页，跳转到视频通话页
  Future<void> onPickUp() async {
    if (!(onCallModel?.isFree ?? false) && VipPrivilegesSheet.shouldGateNonVip()) {
      VipPrivilegesSheet.show();
      return;
    }
    // 拦截：未完成五次全屏假视频，不允许接听
    if (!await _isRobotFiveCompleted()) {
      logger.d("未完成五次全屏假视频，拦截接听");
      return;
    }
    if (!(onCallModel?.isFree ?? false) && (onCallModel?.unitPrice ?? 0) > (_appConfig.userInfo.availableCoins ?? 0) && !_appConfig.isReviewPkg.value) {
      // 金币余额不足，且非审核模式
      Toast.showMsg("error_insufficientDiamonds".bhTR);
      // if (Get.isRegistered<OnCallLogic>()) {
      //   // 如果已打开被呼叫页，则关闭被呼叫页
      //   Get.find<OnCallLogic>().onBack(hangUp: false);
      // }
      // 打开充值弹窗
      RechargeDialog.show(entry: PayEntry.SOURCE_7, bindWidget: null);
      return;
    }

    throttleUtil.throttle(() async {
      await _request.videoCallPickUp(
        channelName: onCallModel?.channelName ?? "",
        onSuccess: (data) {
          OnCallDialog.dismiss();
          if (Get.currentRoute == RoutePath.onCallPage) {
            Get.offNamed(RoutePath.videoCallPage);
          } else {
            Get.toNamed(RoutePath.videoCallPage);
          }
        },
        onFail: (code, msg) {
          Toast.showMsg(msg);
        },
      );
      _onCancelTimer();
      onShopCallPlayer();
    }, key: "call_handler_videoCallPickUp");
  }

  /// 被呼叫 - EventBus事件
  void _onCall(OnCallModel model) async {
    // 拦截：未完成五次全屏假视频，不接收任何来电
    if (!await _isRobotFiveCompleted()) {
      logger.d("未完成五次全屏假视频，拦截来电");
      return;
    }
    // 检查是否处于隐私模式
    final isPrivateMode = await PrivacyModeManager.isPrivacyModeEnabled();
    if (isPrivateMode) {
      // 处于隐私模式，忽略呼叫
      logger.e("处于隐私模式，拦截来电通知");
      return;
    }

    //判断是否审核模式
    if (Get.isRegistered<AppConfigManager>()) {
      if (Get.find<AppConfigManager>().isReviewPkg.value) {
        ///审核模式不显示呼叫弹框
        return;
      }
    }
    if (onCallModel != null) {
      // 当前有被呼叫或通话中的数据，则不通知
      logger.e("被呼叫拦截");
      return;
    }

    if (Get.isRegistered<StartMatchLogic>()) {
      //如果匹配中不弹窗
      return;
    }
    // 免费通话限流：本地五个主播未展示完成前，免费通话不弹入
    // try {
    //   if ((model.isFree ?? false) && Get.isRegistered<RobotChatManager>()) {
    //     final completed = await Get.find<RobotChatManager>().isLocalFiveCompleted();
    //     if (!completed) {
    //       logger.d("免费通话拦截：本地五位主播未展示完");
    //       return;
    //     }
    //   }
    // } catch (e) {
    //   // 防御：出现异常不影响正常流程
    // }

    _onCallModel = model;
    update();
    _onCreateTimer();
    isCanTouchPlay = true;
    // _player = AudioPlayer();
    onNotice(vibrator: true);
    //关闭消息弹窗
    MessageNotication.dismiss();
    // 弹呼叫弹窗
    OnCallDialog.show();
    //转跳到onCall页面
    // Get.toNamed(RoutePath.onCallPage);
  }

  /// 被接听(仅呼叫方所有) - EventBus事件
  void _onPickUp() {
    _onCancelTimer();
    onShopCallPlayer();
  }

  /// 获取通话结果
  Future<VideoCallResultModel?> _getCallResult({
    required String channelName,
  }) async {
    VideoCallResultModel? resultModel;

    try {
      await _request.videoCallResult(
        channelName: channelName,
        onSuccess: (data) {
          resultModel = data;
        },
        onFail: (code, msg) {},
      );
    } catch (e) {}
    return resultModel;
  }

  Future _videoCallEnd({
    required int callSource,
    required VideoCallResultModel? resultModel,
    required OnCallModel? onCallModel,
    required UserInfoModel? userInfoModel,
    required bool isBackMatch,
  }) async {
    if (isBackMatch) {
      return;
    }

    if (_appConfig.userInfo.userType != 1 || _appConfig.isReviewPkg.value) {
      // 非用户身份 或 审核模式，直接清空数据，并且不弹弹窗
      // resetData();
      return;
    }
    userInfoModel ??= UserInfoModel();
    String channelName = onCallModel?.channelName ?? "";

    VideoCallEndDialog().handler(
      userInfo: userInfoModel,
      channelName: channelName,
      resultModel: resultModel,
    );
  }

  /// 保存通话记录
  /// [saveCall] 是否保存记录
  Future<void> _insertHistory({
    required String userId,
    required String callType,
    required int seconds,
    required OnCallModel onCallModel,
    required bool isCallOut,
    required UserInfoModel userInfo,
    required bool calling,
    int? forceCallSource,
  }) async {
    try {
      // 判断是否为匹配通话
      bool isMatch = (forceCallSource ?? _callSource) == VideoCallSource.FAST_MATCH;

      // 打印更详细的日志
      logger.i("保存通话记录: userId=$userId, callType=$callType");
      logger.i("通话来源: _callSource=${forceCallSource ?? _callSource}, VideoCallSource.FAST_MATCH=${VideoCallSource.FAST_MATCH}, isFromMatch=$isMatch");
      logger.i("onCallModel: ${prettyJson(onCallModel.toJson())}");

      VideoCallDao dao = VideoCallDao(
        userId: userId,
        channelName: onCallModel.channelName ?? "",
        // 为拨出方时，使用对方用户数据中的头像和名称
        // 为接收方时，使用被呼叫数据中的头像和名称
        nickname: isCallOut ? userInfo.nickname : onCallModel.nickname,
        avatar: isCallOut ? userInfo.avatarUrl : onCallModel.avatarThumbUrl,
        callType: callType,
        endTime: DateTime.now().millisecondsSinceEpoch,
        duration: Duration(seconds: seconds).inMilliseconds,
        isFromMatch: isMatch, // 添加匹配标识
      );

      logger.i("准备插入通话记录: isFromMatch=${dao.isFromMatch}");

      _videoSql.insert(dao: dao);
    } catch (e) {
      //保存失败先不管，不能影响下面清空数据，否则后续无法视频
      logger.e("保存通话记录失败: $e");
    }
  }

  /// 进入视频通话页
  void onJumpVideoCall() {
    _calling = true;
    //关闭消息弹窗
    MessageNotication.dismiss();
  }

  /// 重置呼叫数据
  /// 重置时机：创建频道失败、保存通话记录、退出视频通话页(弹窗之后)
  /// 有个坑，如果不重置数据，则会导致通话不被释放，后续无法再通话
  /// 所有要追根溯源，遇到请求失败的直接释放就好了，先不管后果
  void resetData() {
    _onCallModel = null;
    _userInfo = null;
    _calling = false;
    // 无需重置，因为下次获取前会清空
    // _resultModel = null;
    _callSource = -1;
    update();
    logger.i("数据已清空");
  }

  void updateUserInfo(UserInfoModel info) {
    _userInfo = info;
  }

  /// 30秒超时定时器
  Timer? _thirtyTimer;

  /// 震动器定时器
  Timer? _vibratorTimer;

  /// 铃声播放器
  AudioPlayer? _player;

  AudioPlayer? get player => _player;

  //是否可以点击的时候重新播放 （PS:用于iOS Safari浏览器断掉自动播放后，点击屏幕重新开始播放）
  bool isCanTouchPlay = false;

  void onNotice({bool vibrator = false, bool isRePay = true}) async {
    try {
      // 播放铃声

      reInitPlayer(isRePay: isRePay);
      // if (!vibrator) {
      //   return;
      // }
      // 震动
      // bool hasVibrator = await Vibration.hasVibrator() ?? false;
      // _vibratorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      //   if (hasVibrator) {
      //     await Vibration.vibrate(amplitude: 255);
      //   } else {
      //     await HapticFeedback.vibrate();
      //   }
      //   // 不能使用以下方式震动，iOS端会无效
      //   // Vibration.vibrate(pattern: [1000, 1000], repeat: 0, amplitude: 255);
      // });
    } catch (e) {
      logger.e("播放铃声/震动错误: $e");
    }
  }

  /// 取消响铃震动
  void onShopCallPlayer() async {
    try {
      _player?.stop();
      disposePlayer();
    } catch (e) {
      logger.e("停止铃声播放错误: $e");
    }
    // try {
    //   Vibration.cancel();
    //   _vibratorTimer?.cancel();
    // } catch (e) {}
  }

  /// 创建超时倒计时
  void _onCreateTimer() async {
    _thirtyTimer = Timer(const Duration(seconds: 30), () {
      _onCancelTimer();
      onShopCallPlayer();
      OnCallDialog.dismiss();
      if (Get.currentRoute == RoutePath.onCallPage) {
        Get.back();
      }
      hangUp(handUpReason: HandUpReason.CL_CALL_TIMEOUT, onSuccess: (data) {}, onFail: (code, msg) {});
    });
  }

  /// 销毁超时倒计时
  void _onCancelTimer() {
    _thirtyTimer?.cancel();
    _thirtyTimer = null;
  }

  //销毁铃声
  Future<void> disposePlayer() async {
    if (_player != null) {
      await _player?.dispose();
      _player = null;
    }
  }

  //重新初始化铃声
  void reInitPlayer({bool isRePay = true}) async {
    if (myAppLifecycleState == AppLifecycleState.paused) {
      //如果退到后台则不播放铃声
      return;
    }
    try {
      if (isRePay) await disposePlayer();
      _player = AudioPlayer();

      String path = "";
      path = "${BaseManager.instance.assetsPrefix}assets/audio/audio_new.aac";
      if (path.startsWith("packages") || path.startsWith("assets")) {
        await _player?.setAsset(path);
      } else {
        await _player?.setFilePath(path);
      }
      await _player?.setLoopMode(LoopMode.all);
      // await _player?.setVolume(1);
      _player?.play();
    } catch (e) {
      logger.e("设置铃声错误: $e");
    }
  }

  //重新开始
  void rePlay() async {
    if (_player != null) {
      if (_player!.playerState.playing) {
        await _player?.pause();
      }
      await _player?.play();
    }
  }

  /// 根据隐私模式状态更新监听
  Future<void> updateListenerByPrivacyMode() async {
    final isPrivateMode = await PrivacyModeManager.isPrivacyModeEnabled();
    if (isPrivateMode) {
      // 在隐私模式下，取消监听
      _event?.cancel();
      _event = null;
      logger.d("隐私模式已启用，已取消视频通话监听");
    } else {
      // 不在隐私模式下，且已完成五次全屏假视频后，才恢复监听
      if (_event == null) {
        if (await _isRobotFiveCompleted()) {
          init();
          logger.d("隐私模式已禁用，已恢复视频通话监听");
        } else {
          logger.d("未完成五次全屏假视频，不恢复视频通话监听");
        }
      }
    }
  }

  /// 判断是否已完成五次全屏假视频
  Future<bool> _isRobotFiveCompleted() async {
    try {
      final String uid = (_appConfig.userInfo.userId?.toString().trim().isNotEmpty == true)
          ? _appConfig.userInfo.userId!.toString()
          : 'guest';
      final String completedKey = 'robot_chat_completed_' + uid;
      return SPUtil.getBool(completedKey, defaultValue: false);
    } catch (e) {
      logger.e("检查五次全屏假视频完成状态异常: $e");
      return false;
    }
  }

  @override
  void onClose() {
    _rechargeSuccessEvent?.cancel();
    _rechargeSuccessEvent = null;
    _event?.cancel();
    _event = null;
    super.onClose();
  }
}
