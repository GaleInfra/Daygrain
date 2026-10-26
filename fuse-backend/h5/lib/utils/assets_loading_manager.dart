import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/gift_util.dart';
import 'package:untitled1/widget/animated_background.dart';
import 'package:untitled1/widget/strong_image.dart';

import '../generated/assets.dart';

/// 图片，字体，视频等资源加载管理
/// 
class AssetsLoadingManager {
  //单例
  static AssetsLoadingManager instance = AssetsLoadingManager._internal();
  AssetsLoadingManager._internal();

  factory AssetsLoadingManager() => instance;

  //是否已经初始化过
  bool _isInit = false;

  //初始化
  Future<void> init(BuildContext? context) async {
    if (_isInit) {
      return;
    }
    try {
      //预加载图片
      await _preloadImages(context);

      //延迟300毫秒执行
      Future.delayed(const Duration(milliseconds: 300), () {
        //不卡流程的预加载图片
        for (var image in _needPreloadImagesAsync) {
          final imageProvider = AssetImage(image);
          precacheImage(imageProvider, context ?? Get.context!);
          // _imageCache[image] = imageProvider;
        }
        //预加载礼物图片
        _preloadGiftImages(context);
      // _preloadChatBackgroundImages();
      });
    } catch (e) {}

    _isInit = true;
  }

  //需要预加载的图片数组
  final List<String> _needPreloadImages = [
    /// 导量弹窗背景图（优先加载）
    Assets.newguide,
    
    //占位图
    ImageAssets.invalidImage,
    /// 空数据
    ImageAssets.empty,

    /// 主播墙-排行榜
    ImageAssets.broadcasterRank,

    /// 主播墙-国家选择
    ImageAssets.broadcasterEarth,


    /// 主播墙-拨打
    ImageAssets.broadcasterCall,

    ImageAssets.dsBotton,

    ImageAssets.messageVideoCall,
    ImageAssets.broadcasterMsg,

    Assets.tabsTab1,
    Assets.tabsTab1Select,
    Assets.tabsTab2,
    Assets.tabsTab2Select,
    Assets.tabsTab3,
    Assets.tabsTab3Select,
    Assets.tabsTabFlash,
    Assets.tabsTabFlashSelect,

    Assets.vipBGJpeg,
    // //匹配图片
    // ImageAssets.matchIcon0,
    // ImageAssets.matchIcon1,
    // ImageAssets.matchIcon2,
    // ImageAssets.matchIcon3,
    ImageAssets.flashBgGoddess,
    ImageAssets.flashBgRandom,

    //VIP相关
    /// VIP 特权弹窗 - 功能图标
    ImageAssets.vip18,
    ImageAssets.vipMessage,
    ImageAssets.vipFire,
    ImageAssets.vipPhoto,
    ImageAssets.vipVip,
    ImageAssets.vipAvatarBorder,
      /// vip - 入口钻石
    ImageAssets.vipIconVip,
    ///ic_un_select
    ImageAssets.vipIcUnSelect,
    /// ic_selected
    ImageAssets.vipIcSelected ,

    /// vip - banner图
    
    ImageAssets.hasopen ,
    ImageAssets.unopen,
    ImageAssets.righticon,

    ImageAssets.right,
    ImageAssets.coins ,
    ImageAssets.calls ,
    ImageAssets.camera,
    ImageAssets.qurrn ,
    ImageAssets.queen,
    ImageAssets.hot,
    ImageAssets.viptop,
    ImageAssets.dialogbg,
    ImageAssets.kuan,

    /// bg_vip_dialog
    ImageAssets.bgVipDialog ,
    /// ic_vip_benefits_call
    ImageAssets.icVipBenefitsCall,
    /// ic_vip_benefits_camera
    ImageAssets.icVipBenefitsCamera,
    /// ic_vip_benefits_chat
    ImageAssets.icVipBenefitsChat,
        ///ic_vip_benefits_avatar
    ImageAssets.icVipBenefitsAvatar,

    /// 个人中心 - VIP 皇冠
    ImageAssets.vipCrown ,

    /// 主播详情 - 折扣背景
    ImageAssets.bgDiscount,

    /// VIP - 钻石
    ImageAssets.vipDiamond,
   
  ];
  final List<String> _needPreloadImagesAsync = [
    //bg_message_notication
   /// 主播资料 - 钻石小
    ImageAssets.broadcasterDiamondSmall,

    /// 主播资料 - 钻石大
    ImageAssets.broadcasterDiamondBig,

    /// 主播资料 - 关注
    ImageAssets.broadcasterLikes,

    /// 主播资料 - 取消关注
    ImageAssets.broadcasterUnLikes,

    /// 主播资料 - 聊天
    ImageAssets.broadcasterChat,

    /// 主播资料 - 手机
    ImageAssets.broadcasterVideo,

    // //主播资料 - 礼物

    // ImageAssets.broadcasterInfoLabelGiftr,
    // //主播资料 - 标签

    // ImageAssets.broadcasterInfoLabelLabel,
    // //主播资料 - 视频

    // ImageAssets.broadcasterInfoLabelVideo,

    /// 举报图标
    ImageAssets.iconReport,

    /// 系统消息
    ImageAssets.iconIsSystem,

    /// 我的 - 修改头像
    ImageAssets.mineModify,

    /// 我的 - 客服
    ImageAssets.mineService,

    ImageAssets.mineCustomService,

    /// 我的 - 黑名单列表
    ImageAssets.mineBlocked,

    /// 我的 - 关于
    ImageAssets.mineAbout,

    /// 我的 - 设置
    ImageAssets.mineSetting,

    /// 金币充值页1
    ImageAssets.coinsStore1,

    /// 我的 - 客服
    ImageAssets.customServiceIcon,

    /// 我的 - 举报
    ImageAssets.report,

    /// 礼物悬浮图标
    ImageAssets.gift,

    /// 匹配tab页背景
    ImageAssets.flashBackground,

    /// 匹配tab页推荐主播
    ImageAssets.flashClub,

    /// 首页背景图片
    ImageAssets.flashBg,

    /// 首页神明背景图
    ImageAssets.flashGodBg,

    /// 首页神明背景图
    ImageAssets.yuan,

    /// 主播详情 - 折扣背景
    ImageAssets.bgDiscount,

    /// 异常通话补偿 - 钻石
    ImageAssets.compensationDiamond,

    /// 个人中心 - 等级入口
    ImageAssets.myLevel,

    /// 个人等级 - 等级
    ImageAssets.level0,
    ImageAssets.level1,
    ImageAssets.level2,
    ImageAssets.level3,
    ImageAssets.level4,
    ImageAssets.level5,
    ImageAssets.level6,
    ImageAssets.level7,
    ImageAssets.level8,
    ImageAssets.level9,
    ImageAssets.level10,

    ImageAssets.flashFree,

    /// 首页悬浮入口
    ImageAssets.homeStore,
    ImageAssets.homeNewUser,
    ImageAssets.homeActivite,

    ///主播详情页


    //ic_translate
    ImageAssets.messageTranslate,
    ImageAssets.messageTranslateReload,

    ///emoji_pitiful
    ImageAssets.emojiPitiful,

    //视频的首帧图
    Assets.newUserJpeg,
    Assets.specialOfferJpeg,
    Assets.loginVideoJpeg,

    ImageAssets.videoCallIcStore,
    /// 私聊 - 更多
    ImageAssets.chatMore,


    /// 私聊 - 置顶
    ImageAssets.chatTop,

    /// 私聊 - 没置顶
    ImageAssets.chatUnTop,

    /// 私聊 - 语音
    ImageAssets.chatVoice,

    /// 私聊 - 表情包
    ImageAssets.chatEmoticon,

    /// 私聊 - 图片
    ImageAssets.chatPicture,

    /// 私聊 - 金光
    ImageAssets.goldenLight,

    ///发送按钮
    ImageAssets.messageSend,

    ///私聊 - 更多  
    ImageAssets.chatMore2,

    //消息 - 删除
    ImageAssets.messageDelete,


    /// 视频通过 - 挂断
    ImageAssets.hangUp,

    /// 视频通过 - 关注
    ImageAssets.videoCallLikes,

    /// 视频通过 - 表情
    ImageAssets.videoCallEmoticon,

    /// 视频通过 - 发送
    ImageAssets.videoCallSend,

    /// 视频通过 - 切换
    ImageAssets.videoCallPhoto,

    //
    ImageAssets.videoCallGiveUPSelect,
    ImageAssets.videoCallGiveUP,

    /// 视频通过 - 一分钟倒计时钻石
    //ic_five_star_praise

    ImageAssets.iconsIcFiveStarPraise,


  ];

  //缓存的图片
  // Map<String, ImageProvider> _imageCache = {};

  //获取缓存资源
  // ImageProvider? getImage(String image) {
  //   return _imageCache[image];
  // }

  //预加载图片
  Future<void> _preloadImages(BuildContext? context) async {
    List<Future> futures = [];
    for (var image in _needPreloadImages) {
      final imageProvider = AssetImage(image);
      futures.add(Future.sync(() async {
        //防止某个资源加载失败,导致整体加载失败
        try {
          await precacheImage(imageProvider, context ?? Get.context!);
          // _imageCache[image] = imageProvider;
        } catch (e) {}
      }));
    }
    await Future.wait(futures);
  }

  //预加载礼物图片
  Future<void> _preloadGiftImages(BuildContext? context) async {
    List<Future> futures = [];
    List<Future> futuresTmp = [];
    for (var image in GiftUtil.giftImageList) {
      final imageProvider = AssetImage(image.image);
      futures.add(Future.sync(() async {
        //防止某个资源加载失败,导致整体加载失败
        try {
          await precacheImage(imageProvider, context ?? Get.context!);
        } catch (e) {}
      }));
      final imageProvider2 = AssetImage(image.thumbnail);
      futuresTmp.add(Future.sync(() async {
        //防止某个资源加载失败,导致整体加载失败
        try {
          await precacheImage(imageProvider2, context ?? Get.context!);
        } catch (e) {}
      }));
    }
    //礼物大图图标无需卡流程加载。
    Future.wait(futures);
    //预加载礼物小图片
    Future.wait(futuresTmp);
  }

  //预加载聊天页面背景图
  Future<void> _preloadChatBackgroundImages() async {
    // 去掉预加载，仅保留图片路径整理逻辑
    final List<String> backgrounds = AnimatedBackgroundManager.getInstance()
        .list
        .map((e) => AssetsHandle.instance.getPassiveAssetsDomain(e))
        .toList();
    // 如需后续使用，可将 backgrounds 传递或缓存；这里不触发实际预加载。
  }


}
