import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as get_x;
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/give_gift_success_event.dart';
import 'package:untitled1/model/UserAvatarModel.dart';
import 'package:untitled1/model/app_config_model.dart';
import 'package:untitled1/model/banner_strong_guide/banner_info_model.dart';
import 'package:untitled1/model/broadcaster/broadcaster_extra_info_model.dart';
import 'package:untitled1/model/broadcaster/reward_model.dart';
import 'package:untitled1/model/banner_strong_guide/strong_guide_model.dart';
import 'package:untitled1/model/gift/gift_model.dart';
import 'package:untitled1/model/infoflow/info_flow_model.dart';
import 'package:untitled1/model/log_upload/log_upload_model.dart';
import 'package:untitled1/model/message/follow/friend_list_model.dart';
import 'package:untitled1/model/message/im_limit_model.dart';
import 'package:untitled1/model/mine/blocked_list_model.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/model/mine/update_avatar_model.dart';
import 'package:untitled1/model/mine/upload_oss_model.dart';
import 'package:untitled1/model/mine/user_oss_policy_model.dart';
import 'package:untitled1/model/pay/coin_pay_channel_model.dart';
import 'package:untitled1/model/pay/order_model.dart';
import 'package:untitled1/model/ranking/rank_cp_model.dart';
import 'package:untitled1/model/ranking/ranking_model.dart';
import 'package:untitled1/model/robot/RobotModel.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/user/user_level_model.dart';
import 'package:untitled1/model/video_call/on_give_gift_model.dart';
import 'package:untitled1/model/video_call/rear_camera_model.dart';
import 'package:untitled1/model/video_call/video_call_result_model.dart';
import 'package:untitled1/model/vip/vip_subscription_model.dart';
import 'package:untitled1/net/api_address.dart';
import 'package:untitled1/res/api_header.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/package_info_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../model/broadcaster/broadcaster_model.dart';
import '../model/broadcaster/promotion_model.dart';
import '../model/broadcaster/strategy_model.dart';
import '../model/login/login_model.dart';
import '../model/video_call/on_call_model.dart';
import '../pages/broadcaster/widget/reward_dialog.dart';
import '../utils/bh_platform.dart';
import '../utils/dialog_queue_util.dart';
import 'base/base_repository.dart';
import 'base/response_parse.dart';
import 'dart:ui' as ui;

/// Gets the [RequestRepository] instance if it is registered with Get, otherwise returns null.
///
/// Returns:
///   - [RequestRepository] if it is registered with Get.
///   - `null` otherwise.
///
RequestRepository? getReqRepo() {
  // Check if [RequestRepository] is registered with Get.
  return get_x.Get.isRegistered<RequestRepository>() ? get_x.Get.find<RequestRepository>() : null;
}

/// @author: zx
/// @description: 网络请求接口仓库
class RequestRepository extends BaseRepository {
  /// 登录接口
  /// [deviceId] 设备id
  /// [riskInfo] 风控信息
  login({
    CancelToken? cancelToken,
    required String deviceId,
    required String riskInfo,
    required Success<LoginModel> onSuccess,
    required Fail onFail,
  }) async {
    Map<String, dynamic> map = {
      "oauthType": 4,
      "token": deviceId,
    };
    if (riskInfo.isNotEmpty) {
      map.addAll({"info": riskInfo});
    }
    FormData data = FormData.fromMap(map);
    await POST(
      ApiAddress.login,
      data: data,
      cancelToken: cancelToken,
      bindPage: false,
      onSuccess: (data) {
        onSuccess.call(LoginModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: true,
    );
  }

  /// app 配置信息
  appConfig({
    String ver = "0",
    required Success<AppConfigModel?> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.appConfig,
      bindPage: false,
      data: {"ver": ver},
      onSuccess: (data) {
        if (data != null && data != "") {
          onSuccess.call(AppConfigModel.fromJson(data));
        } else {
          onSuccess.call(null);
        }
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取融云token
  rongCloudToken({
    required String rcKey,
    required Success<String> onSuccess,
    required Fail onFail,
  }) async {
    Map<String, dynamic>? param;
    if (rcKey.isNotEmpty) {
      param = {
        "appKey": rcKey,
      };
    }
    await POST(
      ApiAddress.rongCloudToken,
      data: param,
      bindPage: false,
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 校验token
  isValidToken({
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.isValidToken,
      data: {
        "token": SPUtil.getString(MyKeys.token),
      },
      onSuccess: (data) {
        if (data) {
          // 返回 true,校验有效
          onSuccess.call(data);
        } else {
          onFail.call(-1, "校验失败");
        }
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 主播列表页配置信息获取
  getStrategy({
    String? token,
    CancelToken? cancelToken,
    required Success<StrategyModel> onSuccess,
    required Fail onFail,
  }) async {
    Options? options;
    if (token != null && token.isNotEmpty) {
      options = Options(headers: {
        "Authorization": "Bearer $token",
      });
    }
    await POST(
      ApiAddress.getStrategy,
      options: options,
      bindPage: false,
      showErrorTip: false,
      cancelToken: cancelToken,
      onSuccess: (data) {
        // 打印 getStrategy 返回的源数据
        // logger.i("========== getStrategy 返回数据 ==========");
        // logger.i("原始 data: ${prettyJson(data)}");
        // // 检查 data 字段是否存在
        // if (data is Map) {
        //   logger.i("data 字段是否存在: ${data.containsKey('data')}");
        //   if (data.containsKey('data') && data['data'] is Map) {
        //     final innerData = data['data'] as Map;
        //     logger.i("内层 data 内容: ${prettyJson(innerData)}");
        //     logger.i("custom_list 是否存在: ${innerData.containsKey('custom_list')}");
        //     if (innerData.containsKey('custom_list')) {
        //       logger.i("custom_list 内容: ${prettyJson(innerData['custom_list'])}");
        //     }
        //   }
        // }
        // try {
        //   final strategyModel = StrategyModel.fromJson(data);
        //   logger.i("解析后的 StrategyModel: ${prettyJson(strategyModel.toJson())}");
        //   logger.i("customList 是否为空: ${strategyModel.customList == null}");
        //   if (strategyModel.customList != null) {
        //     logger.i("customList 内容: ${prettyJson(strategyModel.customList?.toJson())}");
        //   }
        // } catch (e) {
        //   logger.e("解析 StrategyModel 失败: $e");
        // }
        // logger.i("=============================================");
        onSuccess.call(StrategyModel.fromJson(data));
      },
      onFail: onFail,
    );
  }

  /// 主播墙列表
  wallSearch({
    required String category,
    required String tag,
    required String region,
    required int page,
    required int limit,
    required Success<List<BroadcasterModel>> onSuccess,
    required Fail onFail,
  }) async {
    var data = {
      "category": category,
      "tag": tag,
      "isPageMode": true,
      "isRemoteImageUrl": true,
      "limit": limit,
      "page": page,
    };
    if (data.isNotEmpty && !"All".contains(region)) {
      data.addAll({"region": region});
    }
    await POST(
      ApiAddress.wallSearch,
      data: data,
      onSuccess: (data) {
        List<BroadcasterModel> list = [];
        list.addAll(data.map<BroadcasterModel>((e) => BroadcasterModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
      showTip: false,
    );
  }

  /// 新用户促销
  coinGetPromotion({
    CancelToken? cancelToken,
    required Success<PromotionModel?> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.coinGetPromotion,
      cancelToken: cancelToken,
      data: {
        "isIncludeSubscription": false,
        "payChannel": BHPlatform.isAndroid ? "GP" : "IAP",
      },
      onSuccess: (data) {
        if (data != null) {
          // 存在key，说明有促销产品
          onSuccess.call(PromotionModel.fromJson(data));
        } else {
          onSuccess.call(null);
        }
      },
      bindPage: false,
      showErrorTip: false,
      onFail: onFail,
    );
  }

  /// 主播排行榜列表查询
  rankBroadcasterSearch({
    required Success<List<RankingModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.rankBroadcasterSearch,
      data: {
        "count": 0,
      },
      onSuccess: (data) {
        final list = <RankingModel>[];
        list.addAll(data['rankData'].map<RankingModel>((e) => RankingModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 用户排行榜列表查询
  rankUserSearch({
    required Success<List<RankingModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.rankUserSearch,
      data: {
        "count": 0,
      },
      onSuccess: (data) {
        final list = <RankingModel>[];
        list.addAll(data['rankData'].map<RankingModel>((e) => RankingModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 主播 - 获取详情
  userGetInfo({
    bool bindPage = true,
    required String userId,
    CancelToken? cancelToken,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetInfo,
      cancelToken: cancelToken,
      bindPage: bindPage,
      data: {
        "userId": userId,
      },
      onSuccess: (data) {
        try {
          // 打印原始API返回数据
          print("\n======== userGetInfo API原始返回数据 ========");
          print(jsonEncode(data));
          print("======== userGetInfo API原始返回数据结束 ========\n");

          CacheManager.saveUserInfoCache(userId, jsonEncode(data));
        } catch (e) {}
        onSuccess.call(UserInfoModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取用户在线状态
  userGetOnlineStatus({
    required String userId,
    required Success<String> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetOnlineStatus,
      data: {
        "userId": userId,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取用户在线状态
  userGetMoreOnline({
    required List<String> userIds,
    required Success<Map<String, dynamic>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetMoreOnline,
      data: {
        "userIds": userIds,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showErrorTip: false,
      showTip: false,
      bindPage: false,
    );
  }

  /// 获取主播额外信息
  userGetBroadcasterExtraInfo({
    required String userId,
    CancelToken? cancelToken,
    required Success<BroadcasterExtraInfoModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetBroadcasterExtraInfo,
      cancelToken: cancelToken,
      data: {
        "userId": userId,
      },
      onSuccess: (data) {
        try {
          CacheManager.saveUserExtendInfoCache(userId, jsonEncode(data));
        } catch (e) {}
        onSuccess.call(BroadcasterExtraInfoModel.fromJson(data));
      },
      onFail: onFail,
    );
  }

  /// 关注好友
  userAddFriend({
    required String userId,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userAddFriend,
      data: {
        "followUserId": userId,
      },
      onSuccess: onSuccess,
      onFail: onFail,
      showLoading: false,
    );
  }

  /// 取消关注好友
  userUnfriend({
    required String userId,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userUnfriend,
      data: {
        "followUserId": userId,
      },
      onSuccess: onSuccess,
      onFail: onFail,
      showLoading: false,
    );
  }

  /// 拉黑/举报接口
  /// [userId] 屏蔽id
  /// [complainCategory]
  reportInsertRecord({
    required String userId,
    required String complainCategory,
    String? complainSub,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.reportInsertRecord,
      data: {
        "broadcasterId": userId,
        "complainCategory": complainCategory,
        "complainSub": complainSub,
      },
      onSuccess: onSuccess,
      onFail: onFail,
      showLoading: false,
    );
  }

  /// 取消拉黑接口
  reportRemoveBlock({
    required String userId,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.reportRemoveBlock,
      data: {
        "blockUserId": userId,
      },
      onSuccess: onSuccess,
      onFail: onFail,
      showLoading: false,
    );
  }

  /// 全部的普通礼物数据信息
  giftList({
    required Success<List<GiftModel>> onSuccess,
    Fail? onFail,
  }) async {
    await POST(
      ApiAddress.giftList,
      onSuccess: (data) {
        List<GiftModel> list = [];
        list.addAll(data.map<GiftModel>((e) => GiftModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
      showLoading: false,
      showErrorTip: false,
    );
  }

  /// 关注列表
  userGetFriendList({
    required int page,
    required int limit,
    required Success<List<FriendListModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetFriendList,
      data: {
        "page": page,
        "limit": limit,
      },
      bindPage: false,
      onSuccess: (data) {
        List<FriendListModel> list = [];
        list.addAll(data.map<FriendListModel>((e) => FriendListModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取用户的头像和昵称
  userGetNameAndAvatar({
    required String userId,
    required Success<UserInfoModel> onSuccess,
    bool showErrorTip = false,
  }) async {
    await POST(
      ApiAddress.userGetNameAndAvatar,
      bindPage: false,
      showErrorTip: showErrorTip,
      data: {
        "userId": userId,
      },
      onSuccess: (data) {
        //保存缓存数据
        CacheManager.saveUserGetNameAndAvatarCache(userId, jsonEncode(data));
        onSuccess.call(UserInfoModel.fromJson(data));
      },
    );
  }

  /// 获取用户金币
  userGetCoins({
    required String userId,
    bool showLoading = true,
    required Success<int> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGetCoins,
      data: {
        "userId": userId,
      },
      onSuccess: (data) {
        onSuccess.call(data['availableCoins']);
      },
      onFail: onFail,
      showLoading: showLoading,
      showErrorTip: false,
    );
  }

  /// 用户心跳上报
  userActiveing() async {
    await POST(
      ApiAddress.userActiveing,
      bindPage: false,
      showErrorTip: false,
      onSuccess: (data) {},
    );
  }

  /// 用户心跳上报
  /// [mode] 模式（0-前台 1-后台）
  /// [recount] 重连次数 (默认5次)
  userModeSwitch({
    required int mode,
    int recount = 5,
  }) async {
    await POST(
      ApiAddress.userModeSwitch,
      bindPage: false,
      data: {
        "mode": mode,
      },
      onSuccess: (data) {},
      onFail: (code, msg) {
        if (recount > 0) {
          userModeSwitch(mode: mode, recount: --recount);
        }
      },
    );
  }

  /// 视频通话-创建频道
  /// [callType] 1 私人电话；2 匹配电话； 正常通话情况传1，快速匹配才传2
  /// [callSource] 入口来源，详情看客户端文档关键字：callSource字典值
  videoCallChannelCreate({
    required String toUserId,
    required int callType,
    required int callSource,
    required String clientSessionId,
    required Success<OnCallModel> onSuccess,
    required Fail onFail,
    bool bindPage = false,
  }) async {
    await POST(
      ApiAddress.videoCallChannelCreate,
      data: {
        "toUserId": toUserId,
        "clientSessionId": clientSessionId,
        "callType": callType,
        "callSource": callSource,
        "playSupportType": 1, // 传入1即可
        "isFree": false, // 传入false即可，
        "supportVideoSdks": [1] // List<Integer>类型
      },
      onSuccess: (data) {
        onSuccess.call(OnCallModel.fromJson(data));
      },
      onFail: onFail,
      bindPage: bindPage,
    );
  }

  /// 挂断
  /// [channelName] 通话频道号
  /// [oppositeUserId] 对方id
  videoCallHangUp({
    required String channelName,
    required int handUpReason,
    required String oppositeUserId,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.videoCallHangUp,
      bindPage: false,
      data: {
        "channelName": channelName,
        "handUpReason": handUpReason,
        "oppositeUserId": oppositeUserId,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// [channelName] 通话频道号
  videoCallPickUp({
    required String channelName,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.videoCallPickUp,
      data: {
        "channelName": channelName,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// 加入频道接口
  videoCallChannelJoin({
    required String channelName,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.videoCallChannelJoin,
      bindPage: false,
      data: {
        "channelName": channelName,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// 更新声网uid
  userUpdateAgoraUid({
    required int uid,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userUpdateAgoraUid,
      bindPage: false,
      data: {
        "agoraUid": uid,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// 查询通话结果接口
  videoCallResult({
    required String channelName,
    required Success<VideoCallResultModel> onSuccess,
    required Fail onFail,
    bool showLoading = false,
  }) async {
    await POST(
      ApiAddress.videoCallResult,
      bindPage: false,
      data: {
        "channelName": channelName,
        "isRemoteImageUrl": true,
      },
      onSuccess: (data) {
        onSuccess.call(VideoCallResultModel.fromJson(data));
      },
      showLoading: showLoading,
      onFail: onFail,
    );
  }

  /// 评价主播接口
  evaluateSubmit({
    required String channelName,
    required int score,
    required List<String> tags,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.evaluateSubmit,
      bindPage: false,
      data: {
        "channelName": channelName,
        "score": score,
        "tags": tags,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      showLoading: true,
    );
  }

  /// 注册奖励金币接口
  /// [recount] 重试次数 默认为5
  coinPresentedGet({
    required Success<RewardModel> onSuccess,
    int recount = 5,
  }) async {
    await POST(
      ApiAddress.coinPresentedGet,
      onSuccess: (data) {
        final rewardModel = RewardModel.fromJson(data);
        onSuccess.call(rewardModel);
        if ((rewardModel.coins ?? 0) > 0) {
          // 金币数大于0，且首次打开，显示注册奖励弹窗
          DialogQueueUtil.to.addDialog(DialogQueueElement(
              onShow: () => RewardDialog.show(
                    rewardModel: rewardModel,
                  )));
        }
      },
      onFail: (code, msg) {
        if (recount > 0) {
          coinPresentedGet(
            onSuccess: onSuccess,
            recount: recount - 1,
          );
        }
      },
    );
  }

  /// 获取oss上传权限
  userOssPolicy({
    CancelToken? cancelToken,
    required Success<UserOssPolicyModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userOssPolicy,
      cancelToken: cancelToken,
      onSuccess: (data) {
        onSuccess.call(UserOssPolicyModel.fromJson(data));
      },
    );
  }

  /// 上传oss资源
  uploadOSS({
    CancelToken? cancelToken,
    required FormData formData,
    required String url,
    required Success<UploadOssModel> onSuccess,
    required Fail? onFail,
  }) async {
    try {
      // 创建dio实例用于文件上传
      final dio = Dio();

      // 发送POST请求上传文件
      final response = await dio.post(
        url,
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          // 设置较长的超时时间用于文件上传
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200 && response.data is Map && response.data['data'] is Map) {
        onSuccess.call(UploadOssModel.fromJson(response.data['data']));
      } else {
        onFail?.call(response.statusCode ?? -1, "上传失败");
      }
    } catch (e) {
      onFail?.call(-1, "上传出错: ${e.toString()}");
    }
  }

  /// 更新头像
  /// [avatar] oss返回的相对地址
  Future userUpdateAvatar({
    CancelToken? cancelToken,
    required String avatar,
    required Success<UpdateAvatarModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userUpdateAvatar,
      data: {
        "avatarPath": avatar,
      },
      cancelToken: cancelToken,
      onSuccess: (data) {
        onSuccess.call(UpdateAvatarModel.fromJson(data));
      },
      onFail: onFail,
    );
  }

  /// 保存用户所有信息
  Future userSaveUserInfo({
    CancelToken? cancelToken,
    required String nickName,
    required String birthday,
    required String country,
    required String about,
    required String language,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userSaveUserInfo,
      cancelToken: cancelToken,
      data: {
        "nickname": nickName,
        "birthday": birthday,
        "country": country,
        "about": about,
        "language": language,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// 更新媒体资源接口
  /// [actionType] 新增=1,更新=2,删除=3
  /// [coins] 设置的媒体价格
  /// [mediaType] //图片：photo 视频：video
  Future userUpdateMedia({
    required int actionType,
    required int coins,
    required String deleteMediaId,
    required String mediaPath,
    required String mediaType,
    required String replaceMediaId,
    required Success onSuccess,
    required Fail onFail,
  }) async {
    await POST(ApiAddress.userUpdateMedia,
        data: {
          "actionType": actionType,
          "coins": coins,
          "deleteMediaId": deleteMediaId,
          "mediaPath": mediaPath,
          "mediaType": mediaType,
          "replaceMediaId": replaceMediaId,
        },
        onSuccess: onSuccess,
        onFail: onFail);
  }

  /// 屏蔽列表
  Future reportBlockList({
    required Success<List<BlockedListModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.reportBlockList,
      onSuccess: (data) {
        List<BlockedListModel> list = [];
        list.addAll(data.map<BlockedListModel>((e) => BlockedListModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
    );
  }

  /// 退出登录
  Future securityLogout() async {
    await POST(
      ApiAddress.securityLogout,
      onSuccess: (data) {},
      showLoading: false,
      onFail: (code, msg) {},
    );
  }

  /// 删除帐号
  Future userDeleteAccount() async {
    await POST(
      ApiAddress.userDeleteAccount,
      clickMaskDismiss: false,
      onSuccess: (data) {},
      showLoading: true,
    );
  }

  /// 获取资料图片
  getInfo_flows({
    required dynamic params,
    required int page,
    required Success<List<InfoFlowModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.infoFlow,
      data: params,
      onSuccess: (data) {
        List<InfoFlowModel> list = [];
        for (var item in data) {
          InfoFlowModel model = InfoFlowModel.fromJson(item);
          list.add(model);
        }
        onSuccess.call(list);
        // String jsonString = jsonEncode(data);
        //
        // // 打印 JSON 字符串
        // print(jsonString);
        // InfoFlowModel model = InfoFlowModel.fromJson(data);
        // // if (page == 1) {
        // //   String jsonString = jsonEncode(model);
        // //   CacheManager.saveDyVideoCache(jsonString);
        // // }
        // onSuccess.call(model.records ?? []);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取多用户头像
  getUsersAvatars({
    required dynamic params,
    required int page,
    required Success<List<UserAvatarModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.usersAvatars,
      data: {"userIds": params},
      onSuccess: (data) {
        List<UserAvatarModel> list = [];
        for (var item in data) {
          // String jsonString = jsonEncode(item);
          //
          // // 打印 JSON 字符串
          // print(jsonString);
          UserAvatarModel model = UserAvatarModel.fromJson(item);
          list.add(model);
        }
        onSuccess.call(list);
        // String jsonString = jsonEncode(data);
        //
        // // 打印 JSON 字符串
        // print(jsonString);
        // InfoFlowModel model = InfoFlowModel.fromJson(data);
        // // if (page == 1) {
        // //   String jsonString = jsonEncode(model);
        // //   CacheManager.saveDyVideoCache(jsonString);
        // // }
        // onSuccess.call(model.records ?? []);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 查询商品列表
  Future coinGoodsSearch({
    required bool isIncludeSubscription,
    required Success<List<CoinGoodsModel>> onSuccess,
    CancelToken? cancelToken,
    bool bindPage = true,
    bool showLoading = false,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.coinGoodsSearch,
      bindPage: bindPage,
      cancelToken: cancelToken,
      data: {
        "isIncludeSubscription": isIncludeSubscription,
        "payChannel": BHPlatform.isAndroid ? "GP" : "IAP",
      },
      onSuccess: (data) {
        List<CoinGoodsModel> list = [];
        list.addAll(data.map<CoinGoodsModel>((e) => CoinGoodsModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      showLoading: showLoading,
      onFail: onFail,
    );
  }

  /// 赠送礼物
  Future userGiveGift({
    required String channelName,
    required String giftCode,
    required int num,
    required String recipientUserId,
    required Success<int> onSuccess, // 返回剩余金币数量
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.userGiveGift,
      data: {
        "channelName": channelName,
        "giftCode": giftCode,
        "num": num,
        "recipientUserId": recipientUserId,
      },
      onSuccess: (data) {
        onSuccess.call(data['coins']);
        // 发送自定义的送礼成功通知
        EventBusUtil.fire<GiveGiftSuccessEvent>(GiveGiftSuccessEvent(
            data: OnGiveGiftModel(
          channelName: channelName,
          giftCode: giftCode,
          fromUserId: int.parse(get_x.Get.find<AppConfigManager>().userInfo.userId?.toString() ?? "0"),
        )));
      },
      showLoading: false,
      onFail: onFail,
    );
  }

  /// 新版活动促销
  Future coinSpecialOffer({
    required Success<CoinGoodsModel?> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.coinSpecialOffer,
      bindPage: false,
      data: {"payChannel": BHPlatform.isAndroid ? "GP" : "IAP", "invitationId": ""},
      onSuccess: (data) {
        List<CoinGoodsModel> list = [];
        list.addAll(data.map<CoinGoodsModel>((e) => CoinGoodsModel.fromJson(e)).toList());
        onSuccess.call(list.isNotEmpty ? list.first : null);
      },
      onFail: onFail,
    );
  }

  /// 获取摄像头配置
  Future rearCameraConfig({
    required Success<RearCameraModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.rearCameraConfig,
      onSuccess: (data) {
        onSuccess.call(RearCameraModel.fromJson(data));
      },
      onFail: onFail,
    );
  }

  /// 开通后置摄像头
  Future rearCameraOpen({
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.rearCameraOpen,
      data: {},
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showLoading: true,
    );
  }

  /// 获取充值渠道列表
  Future coinPayChannelGet({
    required Success<CoinPayChannelModel> onSuccess,
    required Fail onFail,
    bool showLoading = true,
  }) async {
    await POST(
      ApiAddress.coinPayChannelGet,
      bindPage: false,
      onSuccess: (data) {
        onSuccess.call(CoinPayChannelModel.fromJson(data));
      },
      onFail: onFail,
      showLoading: showLoading,
    );
  }

  /// 支付相关接口

  /// 创建订单
  /// [goodsCode] (string, optional): 商品编号 ,
  /// [payChannel] (string, optional): 支付通道
  /// [source] (string, optional): 充值邀请码，主播邀请链接，活动商品等特殊附带赠送比例的需要传

  Future coinRechargeCreate({
    required String goodsCode,
    required String payChannel,
    required String source,
    required String entry,
    required Success<OrderModel> onSuccess,
    required Fail onFail,
    bool showTip = false,
    bool showLoading = false,
    int retryCount = 3,
  }) async {
    int? errorCode;
    String? errorMsg;
    await POST(
      ApiAddress.coinRechargeCreate,
      data: {"goodsCode": goodsCode, "payChannel": payChannel, "source": source, "entry": entry},
      onSuccess: (data) {
        onSuccess.call(OrderModel.fromJson(data));
      },
      onFail: (code, msg) {
        errorCode = code;
        errorMsg = msg;
      },
      showTip: showTip,
      showLoading: showLoading,
    );

    if (errorCode != null && errorMsg != null) {
      if (retryCount > 0) {
        //等待300毫秒重试
        await Future.delayed(const Duration(seconds: 1));
        return coinRechargeCreate(
          goodsCode: goodsCode,
          payChannel: payChannel,
          source: source,
          entry: entry,
          onSuccess: onSuccess,
          onFail: onFail,
          showTip: showTip,
          showLoading: showLoading,
          retryCount: retryCount - 1,
        );
      }
      onFail.call(errorCode!, errorMsg!);
    }
  }

  /// GooglePlay付款成功后，订单的校验
  Future coinRechargePaymentGp({
    required String orderNo,
    required String purchaseData,
    required String signature,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.coinRechargePaymentGp,
      data: {"orderNo": orderNo, "purchaseData": purchaseData, "signature": signature},
      onSuccess: (data) {
        onSuccess.call(data);
      },
      bindPage: false,
      showLoading: false,
      showErrorTip: false,
      onFail: onFail,
    );
  }

  /// 查询充值结果
  Future coinRechargeSearch({
    required String orderNo,
    required Success<int> onSuccess,
    required Fail onFail,
    bool showErrorTip = false,
  }) async {
    await POST(
      ApiAddress.coinRechargeSearch,
      data: {
        "orderNo": orderNo,
      },
      onSuccess: (data) {
        int status = data['status'];
        onSuccess.call(status);
      },
      bindPage: false,
      onFail: onFail,
      showErrorTip: showErrorTip,
    );
  }

  /// 判断充值链接有效性
  Future coinCheckInvitation({
    required String invitationId,
    required Success<bool> onSuccess,
    required Fail onFail,
    bool showLoading = false,
    CancelToken? cancelToken,
  }) async {
    await POST(
      ApiAddress.coinCheckInvitation,
      cancelToken: cancelToken,
      data: {
        "invitationId": invitationId,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      showLoading: showLoading,
      onFail: onFail,
    );
  }

  /// 搜索主播邀请链接的商品列表
  Future coinGoodsInvitation({
    required String invitationId,
    required Success<List<CoinGoodsModel>> onSuccess,
    required Fail onFail,
    CancelToken? cancelToken,
  }) async {
    await POST(
      ApiAddress.coinGoodsInvitation,
      cancelToken: cancelToken,
      data: {
        "invitationId": invitationId,
        "payChannel": BHPlatform.isAndroid ? "GP" : "IAP",
      },
      onSuccess: (data) {
        List<CoinGoodsModel> list = [];
        list.addAll(data.map<CoinGoodsModel>((e) => CoinGoodsModel.fromJson(e)).toList());
        onSuccess.call(list);
      },
      onFail: onFail,
    );
  }

  /// 谷歌归因数据上报
  Future googleInstallReferer({
    required int appInstallServerTime,
    required int appInstallTime,
    required String installVersion,
    required int referrerClickServerTime,
    required int referrerClickTime,
    required String referrerUrl,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.googleInstallReferer,
      data: {
        "appInstallServerTime": appInstallServerTime,
        "appInstallTime": appInstallTime,
        "installVersion": installVersion,
        "referrerClickServerTime": referrerClickServerTime,
        "referrerClickTime": referrerClickTime,
        "referrerUrl": referrerUrl,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: (code, msg) {
        onFail.call(code, msg);
      },
    );
  }

  /// 核心操作日志上报到后台，默认事件类型为purchase_detail
  Future eventsLogUpload({
    String subtype = "purchase_detail",
    required List<LogUploadData> reqList,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    if (reqList.isEmpty) {
      return;
    }
    List<LogUploadModel> modelList = reqList
        .map((e) => LogUploadModel(
            data: [e],
            logType: "event",
            subtype: subtype,
            behavior: "event",
            utmSource: "",
            androidId: DeviceUtil().deviceId,
            userId: AppConfigManager.userInfoModel.userId,
            pkg: BaseManager.instance.appInfo.packageName, //Env.envConfig.applicationId,
            //Constant.testPackageName,
            ver: reportedAppVersion(),
            platform: (BHPlatform.isAndroid || BHPlatform.isWeb) ? "Android" : "iOS",
            model: DeviceUtil().model,
            lanId: DeviceUtil().lanId,
            secId: 0,
            sysLan: ui.window.locale.languageCode,
            country: AppConfigManager.userInfoModel.country,
            isInBg: false,
            isAnchor: false,
            clientType: "common",
            bizver: "",
            tm: e.tm))
        .toList();
    await POST(
      ApiAddress.logUpload,
      showErrorTip: false,
      data: modelList,
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// appsFlyer归因单独上传
  Future appsFlyerAscribe({
    required String userId,
    required Map<String, dynamic>? afData,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.appsFlyerAscribe,
      data: {
        "pkg": BaseManager.instance.appInfo.packageName,
        "ver": reportedAppVersion(),
        "deviceId": DeviceUtil().deviceId,
        "userId": userId,
        "utmSource": '${afData?['media_source'] ?? ''}',
        "adgroupId": '${afData?['adgroup_id'] ?? ''}',
        "adset": '${afData?['adset'] ?? ''}',
        "adsetId": '${afData?['adset_id'] ?? ''}',
        "afStatus": '${afData?['af_status'] ?? ''}',
        "agency": '${afData?['agency'] ?? ''}',
        "afChannel": '${afData?['af_channel'] ?? ''}',
        "campaign": '${afData?['campaign'] ?? ''}',
        "campaignId": '${afData?['campaign_id'] ?? ''}',
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// 免打扰开关接口
  Future switchNotDisturb({
    required bool isSwitchNotDisturbCall,
    required bool isSwitchNotDisturbIm,
    required Success<bool> onSuccess,
  }) async {
    await POST(
      ApiAddress.switchNotDisturb,
      options: Options(
        receiveTimeout: const Duration(milliseconds: 5000),
        sendTimeout: const Duration(milliseconds: 5000),
      ),
      data: {
        "isSwitchNotDisturbCall": isSwitchNotDisturbCall,
        "isSwitchNotDisturbIm": isSwitchNotDisturbIm,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      showLoading: true,
      clickMaskDismiss: false,
    );
  }

  /// 随机获取一个主播信息
  Future<void> getRandomBroadcaster({
    required Success<UserInfoModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.getRandomBroadcaster,
      onSuccess: (data) {
        onSuccess.call(UserInfoModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: false,
      showTip: false,
    );
  }

  /// 匹配页轮播话术
  Future configContentSearch({
    required Success<List<String>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.configContentSearch,
      data: {
        "type": 1,
      },
      onSuccess: (data) {
        onSuccess.call(data.map<String>((e) => e.toString()).toList());
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 快速匹配
  Future videoCallFlashChat({
    CancelToken? cancelToken,
    required String clientSessionId,
    int chatType = 1, // 1代表快速匹配，2代表女神匹配
    required Success<OnCallModel> onSuccess,
    required Fail onFail,
  }) async {
    String time = DateTime.now().millisecondsSinceEpoch.toString();
    String batchId =
        "${time.substring(time.length - 3)}${(Random().nextInt(8) + 1) * 100000}";
    print("匹配类型: ${chatType == 1 ? '快速匹配' : '女神匹配'},");
    print("batchId: $batchId");
    print("clientSessionId: $clientSessionId");
    print("chatType: $chatType");
    print("supportVideoSdks: [1]");
    await POST(
      ApiAddress.videoCallFlashChat,
      cancelToken: cancelToken,
      showErrorTip: false,
      data: {
        "batchId": batchId,
        "clientSessionId": clientSessionId,
        "callSource": 12,
        "chatType": chatType,
        "supportVideoSdks": [1],
      },
      onSuccess: (data) {
        print("匹配返回数据====: ${data.toString()}");
        onSuccess.call(OnCallModel.fromJson(data));
      },
      onFail: onFail,
    );
  }

  /// 获取banner数据
  Future bannerInfo({
    required Success<List<BannerInfoModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.bannerInfo,
      bindPage: false,
      onSuccess: (data) {
        List<BannerInfoModel> list = [];
        data.forEach((e) {
          list.add(BannerInfoModel.fromJson(e));
        });
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 获取导量数据
  Future strongGuideConfig({
    required Success<StrongGuideModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.strongGuideConfig,
      bindPage: false,
      onSuccess: (data) {
        onSuccess.call(StrongGuideModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 订阅商品获取
  Future subscriptionSearch({
    required Success<List<VipSubscriptionModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.subscriptionSearch,
      data: {
        "payChannel": "GP",
      },
      onSuccess: (data) {
        List<VipSubscriptionModel> list = [];
        data.forEach((e) {
          list.add(VipSubscriptionModel.fromJson(e));
        });
        onSuccess.call(list);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 上报日志
  Future<bool> logLiveChat({required Map<String, dynamic> parameters}) async {
    final data = {
      "list": [parameters]
    };
    print("csd上报日志: $data");
    try {
      final result = await POST(
        ApiAddress.logUpload,
        data: data,
        bindPage: false,
        showErrorTip: false,
        onSuccess: (data) {},
      );
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// 记录事件日志
  void log({required String event, required String page, String? subPage, String? terPage, int? duration}) {
    var dict = <String, dynamic>{};
    dict["event"] = event;
    dict["page"] = page;
    if (subPage != null) {
      dict["subPage"] = subPage;
    }
    if (terPage != null) {
      dict["terPage"] = terPage;
    }
    if (duration != null) {
      dict["duration"] = duration;
    }
    dict["tm"] = DateTime.now().millisecondsSinceEpoch;

    logEvent(data: dict);
  }

  /// 处理事件日志
  Future<bool> logEvent({Map<String, dynamic>? data}) async {
    var dict = <String, dynamic>{};
    if (data != null) {
      dict["data"] = [data];
    }
    final headerMap = getHeader();
    dict["log_type"] = "event";
    dict["subtype"] = "global_behavior";
    dict["behavior"] = "event";
    dict["utm_source"] = headerMap["utm-source"];
    if (get_x.Get.isRegistered<AppConfigManager>()) {
      dict['user_id'] = get_x.Get.find<AppConfigManager>().userInfo.userId;
    }
    dict["pkg"] = headerMap.containsKey("pkg") ? headerMap["pkg"] : "";
    dict["ver"] = headerMap.containsKey("ver") ? headerMap["ver"] : "";
    dict["platform"] = headerMap.containsKey("platform") ? headerMap["platform"] : "";
    dict["platform_ver"] = headerMap.containsKey("platform_ver") ? headerMap["platform_ver"] : "";
    dict["model"] = headerMap.containsKey("model") ? headerMap["model"] : "";
    dict["lan_id"] = lan_id;
    dict["sys_lan"] = headerMap.containsKey("sys_lan") ? headerMap["sys_lan"] : "";
    dict["country"] = headerMap.containsKey("country") ? headerMap["country"] : "";
    dict["is_in_bg"] = false;
    dict["is_anchor"] = false;
    dict["client_type"] = "common";
    dict["bizver"] = "";
    dict["android_id"] = headerMap.containsKey("device-id") ? headerMap["device-id"] : "";
    if (data?["tm"] != null) {
      dict["tm"] = data!["tm"];
    }

    return await logLiveChat(parameters: dict);
  }

  /// 上报已聊天主播
  Future createImSession({
    required String broadcasterId,
    required Success<ImLimitModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.createImSession,
      data: {
        "broadcasterId": broadcasterId,
      },
      onSuccess: (data) {
        onSuccess.call(ImLimitModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 上报已聊天主播
  Future getLevelInfo({
    required Success<UserLevelModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.getLevelInfo,
      onSuccess: (data) {
        onSuccess.call(UserLevelModel.fromJson(data));
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 取消匹配接口
  Future matchCancel({
    required String clientSessionId,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.matchCancel,
      options: Options(
        receiveTimeout: const Duration(milliseconds: 5000),
        sendTimeout: const Duration(milliseconds: 5000),
      ),
      data: {
        "clientSessionId": clientSessionId,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showLoading: false,
      clickMaskDismiss: false,
      showErrorTip: false,
      bindPage: false,
    );
  }

  /// 苹果支付IAP付款成功后，订单的校验
  Future coinRechargePaymentIap({
    required String orderNo,
    required String payload,
    required String transactionId,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.coinRechargePaymentIpa,
      data: {
        "orderNo": orderNo,
        "payload": payload,
        "transactionId": transactionId,
        "type": 1,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      bindPage: false,
      onFail: onFail,
    );
  }

  /// 风控上报
  Future riskUpload({
    required String info,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.riskUpload,
      bindPage: false,
      showErrorTip: false,
      showLoading: false,
      showTip: false,
      data: {
        "info": info,
      },
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
    );
  }

  /// CP榜数据
  Future searchCouple({
    required Success<RankCpModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.searchCouple,
      showLoading: false,
      data: {
        "count": 50,
      },
      onSuccess: (data) {
        RankCpModel model = RankCpModel.fromJson(data);
        onSuccess.call(model);
      },
      onFail: onFail,
    );
  }

  /// 机器人问题列表
  Future robotFAQ({
    required Success<RobotModel> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.robotService,
      onSuccess: (data) {
        RobotModel model = RobotModel.fromJson(data);
        onSuccess.call(model);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }

  /// 机器人随机话术
  Future robotScript({
    required String fromUserId,
    required int scriptTriggerType,
    String? targetId,
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    var data = {
      "fromUserId": fromUserId,
      "scriptTriggerType": scriptTriggerType,
    };
    if (targetId?.isNotEmpty ?? false) {
      data["targetId"] = targetId!;
    }
    await POST(
      ApiAddress.robotScript,
      data: data,
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showErrorTip: false,
    );
  }
  //记录已经SayHi   broadcaster/oneClickSayHi
  Future oneClickSayHi({
    required Success<bool> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.broadcasterOneClickSayHi,
      data: {},
      onSuccess: (data) {
        onSuccess.call(data);
      },
      onFail: onFail,
      showErrorTip: false,
      showLoading: false,
    );
  }

  /// 获取SayHi推荐主播列表
  Future getSayHiRecommendBroadcasters({
    required Success<List<SayHiRecommendBroadcasterModel>> onSuccess,
    required Fail onFail,
  }) async {
    await POST(
      ApiAddress.sayHiRecommendBroadcasters,
      data: {},
      onSuccess: (data) {
        List<SayHiRecommendBroadcasterModel> broadcasters = [];
        if (data is List) {
          broadcasters = data.map((item) => SayHiRecommendBroadcasterModel.fromJson(item)).toList();
        }
        onSuccess.call(broadcasters);
      },
      onFail: onFail,
      showErrorTip: false,
      showLoading: false,
    );
  }
}
