import 'dart:async';
import 'dart:convert';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/rong_cloud/rc_message_manager.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/gift_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';

import '../../common_logic/coin_goods_logic.dart';
import '../../custom/swiper_pagination/my_swiper_pagination.dart';
import '../../model/gift/gift_model.dart';
import '../../res/pay_entry.dart';

/// create: 2023/4/28
/// desc: 礼物弹窗
class GiftSheet extends StatefulWidget {
  GiftSheet.show({
    super.key,
    required this.list,
    required this.channelName,
    required this.userInfo,
    BuildContext? bindWidget,
  }) {
    DialogUtil.showDialog(
      alignment: Alignment.bottomCenter,
      child: this,
      maskColor: Colors.transparent,
      tag: tag,
      bindPage: true,
      debounce: true,
      keepSingle: true,
    );
  }

  /// 排序后的礼物数据
  final List<GiftModel> list;

  /// 视频通话频道号，如果私聊就为空
  final String channelName;

  /// 对方用户数据
  final UserInfoModel userInfo;

  static const String tag = "GiftSheet";

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> with AutomaticKeepAliveClientMixin {
  final request = Get.find<RequestRepository>();

  final appConfig = Get.find<AppConfigManager>();

  final coinGoodsLogic = Get.find<CoinGoodsLogic>();

  /// 是否发送礼物中
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: 3.w, right: 9.w, left: 9.w, bottom: 5.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
            color: widget.channelName.isEmpty ? const Color(0xFF1C192C) : const Color(0xFF1C192C).withValues(alpha: 0.6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color:const Color(0xFF848484),
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
              SizedBox(height: 10.w,),
              SizedBox(
                height: 110.w,
                child: Swiper(
                  itemCount: (widget.list.length / 8).ceil(),
                  loop: false,
                  itemBuilder: (ctx, index) {
                    int start = index * 8;
                    int end = (index + 1) * 8 > widget.list.length ? widget.list.length : (index + 1) * 8;
                    return _GiftGridPage(
                      list: widget.list.sublist(start, end),
                      onGive: (item) {
                        // DialogUtil.dismiss(tag: GiftSheet.tag);
                        throttleUtil.throttle(() => _onGiveGift(item), key: "giveGift");
                      },
                    );
                  },
                  pagination:  SwiperPagination(
                    builder: MySwiperPagination(
                      activeColor: MyColor.white,
                      color: MyColor.grey575757,
                      activeWidth: 6.w,
                            width: 3.w,
                            height: 3.w,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w,vertical: 3.5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C192C),
                      borderRadius: BorderRadius.circular(9.w),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                    ImageAssets.broadcasterDiamondBig,
                    width: 11.5.w,
                    height: 11.5.w,
                  ),
                  MyGaps.hGaps3w,
                  GetBuilder<AppConfigManager>(
                    builder: (logic) {
                      return Text(
                        "${logic.userInfo.availableCoins ?? 0}",
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 8.sp,
                        ),
                      );
                    },
                  )
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // DialogUtil.dismiss(tag: GiftSheet.tag);
                      String entry = PayEntry.SOURCE_20;
                      if (widget.channelName.isNotEmpty) {
                        entry = PayEntry.SOURCE_6;
                      }
                      RechargeDialog.show(entry: entry, bindWidget: context);
                    },
                    child: Container(
                      height: 20.w,
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: MyColor.btnGradientColors,
                        ),
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                      child: Center(
                        child: Text(
                          "action_get_coins".bhTR,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DeviceUtil().bottomSafe,)
            ],
          ),
        ),
      ],
    );
  }

  /// 送出礼物
  Future<void> _onGiveGift(GiftModel item) async {
    if ((appConfig.userInfo.availableCoins ?? 0) < (item.coinPrice ?? 0)) {
      Toast.showMsg("error_insufficientDiamonds".bhTR);

      String entry = PayEntry.SOURCE_19;
      if (widget.channelName.isNotEmpty) {
        entry = PayEntry.SOURCE_5;
      }
      RechargeDialog.show(entry: entry, bindWidget: context);
      return;
    }
    if (sending) {
      return;
    }

    sending = true;
    request
        .userGiveGift(
      channelName: widget.channelName,
      giftCode: item.code ?? "",
      num: 1,
      recipientUserId: widget.userInfo.userId ?? "",
      onSuccess: (data) {
        appConfig.saveUserInfo(appConfig.userInfo.copyWith(
          availableCoins: data,
        ));
        if (Get.currentRoute == RoutePath.messageChatPage) {
          // 当前在私聊页，发送消息
          Map map = {
            "giftCode": item.code,
            "fromUserName": appConfig.userInfo.nickname ?? "",
            "toUserName": widget.userInfo.nickname,
          };
          RCMessageManager()
              .sendSingleJsonMessage(
            targetId: widget.userInfo.userId ?? "",
            content: jsonEncode(map),
            contentType: "gift",
            customExtra: "",
          )
              .then((value) {
            sending = false;
          }).onError((error, stackTrace) {
            sending = false;
          }).timeout(const Duration(seconds: 3), onTimeout: () {
            sending = false;
          });
        }
      },
      onFail: (code, msg) {
        sending = false;
      },
    )
        .then((value) {
      sending = false;
    }).onError((error, stackTrace) {
      sending = false;
    }).timeout(const Duration(seconds: 3), onTimeout: () {
      sending = false;
    });
  }

  @override
  bool get wantKeepAlive => true;
}

class _GiftGridPage extends StatelessWidget {
  const _GiftGridPage({
    Key? key,
    required this.list,
    required this.onGive,
  }) : super(key: key);

  /// 排序后的礼物数据
  final List<GiftModel> list;

  /// 送礼
  final Function(GiftModel item) onGive;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4.5.w,
        crossAxisSpacing: 4.5.w,
        childAspectRatio: 80.0/88.0,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        return GestureDetector(
          onTap: () {
            onGive.call(list[index]);
          },
          child: Container(
            // decoration: BoxDecoration(
            //   color: const Color(0xFF373634),
            //   borderRadius: BorderRadius.circular(4.5.w),
            // ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  GiftUtil.giftImageList
                      .firstWhere((element) => element.name == list[index].code)
                      .image,
                  width: 56*(Get.width/375.0),
                  height: 56*(Get.width/375.0),
                ),
                MyGaps.vGaps3w,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      ImageAssets.broadcasterDiamondSmall,
                      width: 6.w,
                      height: 6.w,
                    ),
                    MyGaps.hGaps3w,
                    Text(
                      "${list[index].coinPrice ?? 0}",
                      style: TextStyle(
                        color: MyColor.white,
                        fontSize: 5.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
