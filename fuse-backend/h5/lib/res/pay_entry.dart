/// desc: 充值来源
class PayEntry {
  //1. 匹配页面右上角商店。
  static const String SOURCE_1 = "match_title";
//2. 个人页商店。
  static const String SOURCE_2 = "user_center";
//3. 匹配页面右下角悬浮快捷弹窗。
  static const String SOURCE_3 = "match_float";
//4. 虚假机器人拨打界面引起悬浮快捷弹窗。
  static const String SOURCE_4 = "oncall_robot";
//5. 视频通话中赠送礼物金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_5 = "chatting_gift";
//6. 视频通话中主动点击getCoin引起悬浮快捷弹窗。
  static const String SOURCE_6 = "chatting";
//7. 被呼叫时候pickup 但是由于金币不足引起悬浮快捷弹窗。
  static const String SOURCE_7 = "oncall";
//8. 拨打电话时由于金币不足引起悬浮快捷弹窗。
  static const String SOURCE_8 = "call";
//9. 首充弹窗直接充值。
  static const String SOURCE_9 = "pop_newbee";
//10. 主播/用户查找页右上角商店
  static const String SOURCE_10 = "look_for_title";
//11. 匹配页面左上角VIP入口
  static const String SOURCE_11 = "subscribe_match";
//12. 个人页VIP入口
  static const String SOURCE_12 = "subscribe_detail";
//13. 视频聊天界面金币不足弹框
  static const String SOURCE_13 = "coin_not_enough";
//14. VIP订阅弹窗
  static const String SOURCE_14 = "subscribe_dialog";
//15. 限时充值弹窗
  static const String SOURCE_15 = "pop_promotion";       //新用户促销弹窗
//16. Vip等级页面升级按钮点击充值
  static const String SOURCE_16 = "vip_level_up";
//17. 充值链接充值弹框
  static const String SOURCE_17 = "recharge_link";
//18. 免费电话后诱导弹窗
  static const String SOURCE_18 = "after_free_call";
//19. IM聊天页中赠送礼物金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_19 = "im_gift";
//20. IM聊天页中主动点击礼物弹框getCoin引起悬浮快捷弹窗。
  static const String SOURCE_20 = "im";
//21. 主播个人中心拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_21 = "anchor_profile_call";
//22. 主播视频详情页拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_22 = "anchor_profile_video_call";
//23. IM聊天界面右上角拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_23 = "conversation";
//24. 视频流拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_24 = "videoflow";
//25. 匹配结果页面拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_25 = "match_result_call";
//26. 主播墙拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_26 = "anchorWall";
//27. 主播详情页面付费 照片/视频 点击
  static const String SOURCE_27 = "detail_media";
//28. 匹配功能金币不足
  static const String SOURCE_28 = "match_coin_not_enough";
//29. 后台推送优惠信息
  static const String SOURCE_29 = "push_special_offer";   //活动促销
//30. 消费升级弹窗
  static const String SOURCE_30 = "consume_upgrade_dialog";
//31. IM聊天限制充值
  static const String SOURCE_31 = "im_limit";
//32.玩老虎机 金币不足充值
  static const String SOURCE_32 = "slot_machine";
//33.动态送礼物金币不足充值
  static const String SOURCE_33 = "moment_gift";
//34.第三方支付 充值
  static const String SOURCE_34 = "tpp";
//35.快速匹配 充值
  static const String SOURCE_35 = "flash";
//36.切换摄像头金币不足
  static const String SOURCE_36 = "switch_camera";
//37.玩新版老虎机 金币不足充值
  static const String SOURCE_37 = "jackpot_recharge";     //游戏 WebView 唤起原生支付弹窗
//38.多人连线
  static const String SOURCE_38 = "multiple_call";
//39.索要媒体礼物
  static const String SOURCE_39 = "ask_for";
//40.主播守护引起的金币不足
  static const String SOURCE_40 = "anchor_guardian";
//41.动态中主动点击礼物弹框getCoin引起悬浮快捷弹窗。
  static const String SOURCE_41 = "moment";
//42.关闭摄像头金币不足
  static const String SOURCE_42 = "close_camera";
//43.音转文主动开启金币不足
  static const String SOURCE_43 = "voice_to_text";
//44. 视频通话中赠送索要礼物金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_44 = "video_ask_for_gift";
//45. im 中赠送索要礼物金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_45 = "im_ask_for_gift";
//46. 道具背包充值卡
  static const String SOURCE_46 = "backpack_recharge_card";
// 47. 解锁 关注人列表引起的充值
  static const String SOURCE_47 = "unlock_followers";
// 48. 解锁 访客列表引起的充值
  static const String SOURCE_48 = "unlock_visitors";
// 49. 访客列表金币不足引起的充值
  static const String SOURCE_49 = "visitors_call";
// 50. 关注/被关注列表金币不足引起的充值
  static const String SOURCE_50 = "follow_call";
// 51. 访客列表进入主播详情金币不足引起的充值
  static const String SOURCE_51 = "followed_list";
// 52. 主播图片详情页拨打电话金币不足引起的悬浮快捷弹窗。
  static const String SOURCE_52 = "anchor_profile_photo_call";
// 53. 主播详情查看未解锁图片。
  static const String SOURCE_53 = "anchor_profile_photo_unlock";
// 54. 主播详情查看未解锁视频。
  static const String SOURCE_54 = "anchor_profile_video_unlock";
// 55. 通话记录呼叫主播金币不足
  static const String SOURCE_55 = "calls_record";
// 动态查看器
  static const String SOURCE_56  = "media_viewer";
//  动态列表
  static const String SOURCE_57  = "moment_list";
//  动态详情
  static const String SOURCE_58  = "moment_detail";

  /**
   *  
主播墙Hi按钮 
max_say_hi_count
IM栏解锁
 im_chat_unlock
IM图片解锁
 im_photo_message_unlock
IM视频解锁
 im_video_message_unlock
假VideoCall接听按钮
 
click_im_trigger_call


   */

  static const String SOURCE_59  = "max_say_hi_count";
  static const String SOURCE_60  = "im_chat_unlock";
  static const String SOURCE_61  = "im_photo_message_unlock";
  static const String SOURCE_62  = "im_video_message_unlock";
  static const String SOURCE_63  = "click_im_trigger_call";
}

/// 订阅来源
class SubscribeEntry {
  static const String DAILY_DIALOG = "dailyDialog";    // 每日弹窗
  static const String EXPIRE_DIALOG = "expireDialog";  // 到期弹窗
  static const String VIP_DETAIL = "vipDetail";        // vip页面
  static const String VIP_DIALOG = "vipDialog";        // vip弹窗
  static const String VIP_DIALOG_RECHARGE_PAGE = "vipDialog_rechargePage"; // 全屏充值页面点击的弹窗
  static const String VIP_DIALOG_RECHARGE_DIALOG = "vipDialog_rechargeDialog"; // 充值弹窗
  static const String VIP_DIALOG_ANCHOR_DETAIL = "vipDialog_anchorDetail";     // 主播详情页通话折扣提示
  static const String VIP_DIALOG_MATCH_TIPS = "vipDialog_matchTips";           // 匹配页折扣提示
  static const String VIP_DIALOG_CLOSE_CAMERA = "vipDialog_closeCamera";       // 关闭摄像头弹窗
  static const String VIP_DIALOG_SWITCH_CAMERA = "vipDialog_switchCamera";     // 切换前后摄像头弹窗
  static const String VIP_DIALOG_MATCH_TOP = "vipDialog_matchTop";             // 匹配页右上角VIP按钮
  static const String VIP_DIALOG_IM_LIMIT = "vipDialog_imLimit";               // im 聊天限制
  static const String VIP_DIALOG_BACKPACK = "vipDialog_backpack";              // 背包 vip
}
