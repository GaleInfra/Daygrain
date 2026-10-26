import '../base_manager.dart';

/// @description: 接口地址管理
class ApiAddress {
  /// 地址前缀
  static String baseUrl = BaseManager.instance.appInfo.baseUrl; //Env.envConfig.baseUrl;

  /// 长连接地址
  static String socketTest = BaseManager.instance.appInfo.socketUrl;

  /// 上报日志的地址
  static String logUrl = BaseManager.instance.appInfo.logUrl;

  /// 登录接口
  static const String login = "/security/oauth";
  ///视频流
  static const String infoFlow = "/broadcaster/videoStream/search";
  ///获取多个用户头像
  static const String usersAvatars = "/user/baseinfo/search";
  /// 查询app配置
  static const String appConfig = "/config/getAppConfigPostV2";
  //机器人服务
  static const String robotService = "/user/FAQ/get";

  /// 机器人随机话术
  static const String robotScript = "/IMBack/robotScriptV2";

  /// SayHi推荐主播列表
  static const String sayHiRecommendBroadcasters = "/broadcaster/recommend/sayHi";

  /// 获取融云token
  static const String rongCloudToken = "/user/rongcloud/tokenPostV2";

  /// 校验token
  static const String isValidToken = "/security/isValidToken";

  /// 主播墙 - 主播墙列表页配置信息获取
  static const String getStrategy = "/config/getStrategyPostV2";

  /// 主播墙 - 主播墙列表
  static const String wallSearch = "/broadcaster/wall/search";

  /// 主播墙 - 新用户促销
  static const String coinGetPromotion = "/coin/goods/getPromotion";

  /// 排行榜 - 主播排行榜列表查询
  static const String rankBroadcasterSearch = "/broadcaster/rank/search";

  /// 排行榜 - 用户排行榜列表查询
  static const String rankUserSearch = "/user/rank/search";

  /// 主播 - 获取详情（获取用户信息接口）
  static const String userGetInfo = "/user/getUserInfoPostV2";

  /// 获取用户在线状态
  static const String userGetOnlineStatus = "/user/getUserOnlineStatusPostV2";

  /// 获取一批用户在线状态
  static const String userGetMoreOnline = "/user/getUserListOnlineStatusPostV2";

  /// 获取主播额外信息
  static const String userGetBroadcasterExtraInfo = "/user/getBroadcasterExtraInfoPostV2";

  /// 关注好友
  static const String userAddFriend = "/user/addFriend";

  /// 取消关注好友
  static const String userUnfriend = "/user/unfriend";

  /// 拉黑/举报接口
  static const String reportInsertRecord = "/report/complain/insertRecord";

  /// 取消拉黑接口
  static const String reportRemoveBlock = "/report/complain/removeBlock";

  /// 举报接口
  static const String reportApply = "/report/apply";

  /// 全部的普通礼物数据信息
  static const String giftList = "/gift/listPostV2";

  /// 关注列表
  static const String userGetFriendList = "/user/getFriendsListPage";

  /// 获取用户的头像和昵称
  static const String userGetNameAndAvatar = "/user/getUsernameAndAvatarPostV2";

  /// 获取用户金币
  static const String userGetCoins = "/user/getUserCoinsPostV2";

  /// 用户心跳上报
  static const String userActiveing = "/user/activeing";

  /// 用户前后台上报
  static const String userModeSwitch = "/user/mode/switch";

  /// 视频通话-创建频道
  static const String videoCallChannelCreate = "/video-call/channel/create";

  /// 视频通话-挂断
  static const String videoCallHangUp = "/video-call/hangUp";

  /// 视频通话-接通
  static const String videoCallPickUp = "/video-call/pickUp";

  /// 视频通话-加入频道
  static const String videoCallChannelJoin = "/video-call/channel/join";

  /// 视频通话-更新声网uid
  static const String userUpdateAgoraUid = "/user/updateAgoraUid";

  /// 视频通话-查询通话结果接口
  static const String videoCallResult = "/video-call/user/callResult";

  /// 评价主播接口
  static const String evaluateSubmit = "/broadcaster/evaluate/submit";

  /// 注册奖励接口
  static const String coinPresentedGet = "/coin/presented/getPostV2";

  /// 获取oss上传权限
  static const String userOssPolicy = "/user/oss/policyPostV2";

  /// 更新头像
  static const String userUpdateAvatar = "/user/updateAvatar";

  /// 保存用户所有信息
  static const String userSaveUserInfo = "/user/saveUserInfo";

  /// 更新媒体资源接口
  static const String userUpdateMedia = "/user/updateMedia";

  /// 屏蔽列表
  static const String reportBlockList = "/report/complain/blockList";

  /// 退出登录
  static const String securityLogout = "/security/logout";

  /// 删除帐号
  static const String userDeleteAccount = "/user/deleteAccount";

  /// 查询商品列表
  static const String coinGoodsSearch = "/coin/goods/search";

  /// 赠送礼物
  static const String userGiveGift = "/user/giveUserGifts";

  /// 新版活动促销
  static const String coinSpecialOffer = "/coin/goods/getLastSpecialOfferV2";

  /// 获取后置摄像头配置
  static const String rearCameraConfig = "/user/rearCamera/config";

  /// 开通后置摄像头
  static const String rearCameraOpen = "/user/rearCamera/open";

  /// 获取充值渠道列表
  static const String coinPayChannelGet = "/coin/payChannel/getPostV2";

  /// 创建订单
  static const String coinRechargeCreate = "/coin/recharge/create";

  /// Google支付信息校验
  static const String coinRechargePaymentGp = "/coin/recharge/payment/gp";

  /// 查询充值结果
  static const String coinRechargeSearch = "/coin/recharge/search";

  /// 判断充值链接有效性
  static const String coinCheckInvitation = "/coin/recharge/checkBroadcasterInvitationPostV2";

  /// 搜索主播邀请链接的商品列表
  static const String coinGoodsInvitation = "/coin/goods/broadcasterInvitation";

  /// Google归因数据上报
  static const String googleInstallReferer = "/config/submitInstallReferer";

  /// 关键操作日志上报到服务器端
  static String logUpload = "$logUrl/log/liveChatPostV2";

  /// AppsFlyer归因上报
  static const String appsFlyerAscribe = "/hit/ascribeRecordReqs";

  /// 免打扰开关接口
  static const String switchNotDisturb = "/user/switchNotDisturb";

  /// 获取一个随机主播信息
  static const String getRandomBroadcaster = "/user/getRandomBroadcasterPostV2";

  /// 匹配页轮播话术
  static const String configContentSearch = "/config/content/search";

  /// 快速匹配
  static const String videoCallFlashChat = "/video-call/flash/chat";

  /// 获取Banner
  static const String bannerInfo = "/game/banner/info";

  /// 获取导量数据
  static const String strongGuideConfig = "/user/strongGuide/config";

  /// 订阅商品获取
  static const String subscriptionSearch = "/coin/subscription/search";

  /// 上报已聊天主播
  static const String createImSession = "/user/createImSession";

  /// 获取用户等级
  static const String getLevelInfo = "/user/getLevelInfoPostV2";

  /// 添加匹配取消接口
  static const String matchCancel = "/video-call/match/cancel";

  /// 苹果支付iap信息校验
  static const String coinRechargePaymentIpa = "/coin/recharge/payment/ipa";

  /// 风控上报
  static const String riskUpload = "/risk/info/upload";

  /// CP榜数据
  static const String searchCouple = "/user/rank/searchCouple";

  /// 主播一键SayHi
  static const String broadcasterOneClickSayHi = "/broadcaster/oneClickSayHi";
}
