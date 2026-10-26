import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/pay_bridge.dart';
import 'package:untitled1/common_logic/pay_handler.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/model/pay/coin_pay_channel_model.dart';
import 'package:untitled1/pages/broadcaster/widget/promotion_dialog.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:untitled1/net/request_repository.dart';

import '../../pages/broadcaster/widget/special_offer_dialog.dart';
import '../button/my_gradient_button.dart';

/// 商品类型
enum GoodsType {
  /// 普通商品
  normal,

  /// 新用户促销
  promotion,

  /// 活动促销
  specialOffer,

  /// 充值邀请
  rechargeLink,
}

/// create: 2023/5/19
/// desc: 支付渠道弹窗
class PayChannelDialog extends StatefulWidget {
  PayChannelDialog({
    super.key,
    required this.model,
    required this.list,
    required this.goodsType,
    required this.entry,
    this.robotUserId,
    this.hideNativePay = false,
  });

  static Future show({
    required CoinGoodsModel model,
    required List<ChannelList> list,
    required GoodsType goodsType,
    required String entry,
    String? robotUserId,
    bool hideNativePay = false,
  }) async {
    PayChannelDialog channelDialog = PayChannelDialog(
      model: model,
      list: list,
      goodsType: goodsType,
      entry: entry,
      robotUserId: robotUserId,
      hideNativePay: hideNativePay,
    );
    channelDialog.logHandle.initLog('special_recharge');
    DialogUtil.showDialog(
        keepSingle: true,
        bindPage: true,
        tag: "PayChannelDialog",
        alignment: Alignment.bottomCenter,
        child: channelDialog,
        onDismiss: () {
          channelDialog.logHandle.onClose();
        });
  }

  //关闭
  static void dismiss() {
    SmartDialog.dismiss(tag: "PayChannelDialog");
  }

  /// 商品数据
  final CoinGoodsModel model;

  LogHandle logHandle = LogHandle();

  /// 渠道列表
  final List<ChannelList> list;

  /// 商品类型，如果是邀请充值，原生支付要有+10%的字样
  final GoodsType goodsType;

  final String entry;
  final String? robotUserId;

  /// 是否隐藏原生支付渠道
  final bool hideNativePay;

  @override
  State<PayChannelDialog> createState() => _PayChannelDialogState();
}

class _PayChannelDialogState extends State<PayChannelDialog> {
  /// 额外金币比例
  num extraCoinPercent = 0;

  /// 当前选中索引
  int selectIndex = 0;
  bool isVipGoods = false;

  ChannelList? currentChannel;

  final payLogic = Get.find<PayHandler>();

  @override
  void initState() {
    // 获取推荐位渠道
    int index = widget.list.indexWhere((element) => element.itemType == 1);
    // 获取默认的额外比例
    _onSelect(index == -1 ? 0 : index, widget.list[selectIndex]);
    isVipGoods = widget.model.isVipTerm;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            PayChannelDialog.dismiss();
          },
          child: Container(
            height: MediaQuery.of(context).size.height * .20,
            width: double.infinity,
            color: Colors.transparent,
          ),
        ),
        Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * .80,
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(9.w)),
                color: MyColor.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 19.w,
                  ),
                  Text(
                    "label_paymentMethod".bhTR,
                    style: FontUtils.sansSemiBold(
                      color: MyColor.black,
                      size: 9.sp,
                    ),
                  ),
                  SizedBox(
                    height: 4.5.w,
                  ),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFC0E9FF).withOpacity(0.3), borderRadius: BorderRadius.all(Radius.circular(11.8.w))),
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 26.w,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Item".bhTR,
                                textAlign: BHLanguageMar().isRightToLeft.value ? TextAlign.right : TextAlign.left,
                                style: FontUtils.sansSemiBold(size: 7.sp, color: const Color(0xFF686868)),
                              ),
                              const Spacer(),
                              Text(
                                "Price".bhTR,
                                textAlign: BHLanguageMar().isRightToLeft.value ? TextAlign.right : TextAlign.left,
                                style: FontUtils.sansSemiBold(size: 7.sp, color: const Color(0xFF686868)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Color(0xFF97CEFA),
                          height: 1,
                        ),
                        SizedBox(
                          height: 26.w,
                          child: Row(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: isVipGoods ? [
Text(
                                    "${widget.model.getDisplyValidity()} VIP",
                                    style: TextStyle(
                                      color: const Color(0xFF2C2B29),
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),

                                ]:[
                                  Image.asset(
                                    ImageAssets.broadcasterDiamondBig,
                                    width: 9.w,
                                    height: 9.w,
                                  ),
                                  MyGaps.hGaps2w,
                                  Text(
                                    "${widget.model.exchangeCoin}",
                                    style: TextStyle(
                                      color: const Color(0xFF2C2B29),
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  MyGaps.hGaps3w,
                                  Visibility(
                                    visible: extraCoinPercent > 0,
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 14.w,
                                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: .5.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2.w),
                                        gradient: const LinearGradient(
                                          colors: MyColor.btnGradientColors,
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                        ),
                                      ),
                                      child: Text(
                                        "+${((widget.model.exchangeCoin ?? 0) * (extraCoinPercent / 100)).toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: MyColor.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  localPrice(widget.model, chooseChannel: currentChannel?.payChannel),
                                  style: FontUtils.sansSemiBold(
                                    color: const Color(0xFFFE3E69),
                                    size: 7.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  MyGaps.vGaps5w,
                  Expanded(
                    child: ListView.separated(
                      itemCount: _getFilteredChannelList().length,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      separatorBuilder: (_, __) => MyGaps.vGaps7w,
                      itemBuilder: (ctx, index) {
                        final filteredList = _getFilteredChannelList();
                        return _Item(
                          select: selectIndex == _getOriginalIndex(filteredList[index]),
                          item: filteredList[index],
                          goodsType: widget.goodsType,
                          present: _getChannelPresent(filteredList[index]),
                          onTap: () => _onSelect(_getOriginalIndex(filteredList[index]), filteredList[index]),
                        );
                      },
                    ),
                  ),
                  MyGaps.vGaps5w,
                  MyGradientButton(
                    text: "Pay".bhTR,
                    onTap: () {
                      // PayChannelDialog.dismiss();
                      throttleUtil.throttle(
                        () async {
                          _onPay();
                        },
                        key: "payContinue",
                      );
                    },
                  ),
                  SizedBox(
                    height: DeviceUtil().bottomSafe,
                  )
                ],
              ),
            ),
            Positioned(
              top: 4.w,
              right: BHLanguageMar().isRightToLeft.value ? null : 4.w,
              left: BHLanguageMar().isRightToLeft.value ? 4.w : null,
              child: Align(
                alignment: BHLanguageMar().isRightToLeft.value ? Alignment.bottomLeft : Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    PayChannelDialog.dismiss();
                  },
                  child: Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyColor.black.withOpacity(0.4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: MyColor.white,
                      weight: 0.8,
                      size: 10.w,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  /// 选择
  void _onSelect(int index, ChannelList item) {
    selectIndex = index;
    extraCoinPercent = _getChannelPresent(item);
    currentChannel = widget.list[selectIndex];
    setState(() {});
  }

  /// 支付
  Future<void> _onPay() async {
    //显示加载框

    ChannelList item = widget.list[selectIndex];
    if (isNativePayChannel(item.payChannel) && !hasNativePayBridge()) {
      Toast.showMsg('recharge_failed_please_try_again_later'.bhTR);
      return;
    }
    if (isNativePayChannel(item.payChannel)) {
      // 点击支付埋点（本地全屏机器人路径）：subPage=主播id
      try {
        final String uid = (widget.robotUserId ?? "");
        if (uid.isNotEmpty) {
          getReqRepo()?.log(
            event: "click",
            page: "fullscreen_video",
            subPage: uid,
          );
        }
      } catch (_) {}
      logger.d(
          "message:${Get.find<AppConfigManager>().strategyModel?.isSwitchStrongGuide}:${Get.find<AppConfigManager>().strongGuideModel?.content}:${Get.find<AppConfigManager>().strongGuideModel?.nativeRechargeRedirect}");
      if (Get.find<AppConfigManager>().strategyModel?.isSwitchStrongGuide ==
              true &&
          Get.find<AppConfigManager>()
                  .strongGuideModel
                  ?.nativeRechargeRedirect ==
              0) {
        StrongGuideSheetV2.show(Get.context);
      } else {
        // 走原生
        Toast.showLoading(backDismiss: false, clickMaskDismiss: false, isShowCloseBtn: true);
        if (!SPUtil.containsKey(MyKeys.firstRecharge)) {
          /// 添加首次充值标志
          SPUtil.setBool(MyKeys.firstRecharge, true);
        }

        await payLogic.executePay(
          widget.model.code!,
          item.payChannel!,
          widget.model.invitationId ?? "",
          widget.entry,
        );
      }
    } else {
      Toast.showLoading(backDismiss: false, clickMaskDismiss: false, isShowCloseBtn: true);
      try {
        await payLogic.coinRechargeCreate(
        goodsCode: widget.model.code!,
        payChannel: item.payChannel!,
        source: widget.model.invitationId ?? "",
        entry: widget.entry,
        // robotUserId: widget.robotUserId,
        onSuccess: (data) async {
          // 订单已创建埋点：subPage=主播id；terPage=pay_订单号
          try {
            final orderNo = data.orderNo ?? "";
            final String uid = (widget.robotUserId ?? "");
            if (uid.isNotEmpty) {
              getReqRepo()?.log(
                event: "click",
                page: "fullscreen_video",
                subPage: uid,
                terPage: orderNo.isNotEmpty ? "pay_${orderNo}" : null,
              );
            }
          } catch (_) {}
          Toast.dismiss(status: SmartStatus.loading, force: true);
          PromotionDialog.dismiss();
          SpecialOfferDialog.dismiss();
          // jumpType 0 stays in the app. Any other value, including a missing one, opens Safari.
          final inside = readJumpType(item.jumpType) == 0;
          if (BHPlatform.isWeb) {
            try {
              await JSRongCloudManager.myBrowser(
                  data.requestUrl!, inside ? 0 : 1, 1);
            } catch (e) {}
            payLogic.listenRecharge();
            return;
          }
          if (inside) {
            WebViewPage.onJump(url: data.requestUrl!, isCanMultiWindow: false)
                .then((value) {
              payLogic.listenRecharge();
            });
            return;
          }
          payLogic.listenRecharge();
        },
        onFail: (code, msg) {
          Toast.showMsg('recharge_failed_please_try_again_later'.bhTR);
          Toast.dismiss(status: SmartStatus.loading, force: true);
        },
      );
      } catch (e) {
        Toast.showMsg('recharge_failed_please_try_again_later'.bhTR);
        Toast.dismiss(status: SmartStatus.loading, force: true);
      }
    }
  }

  /// 获取渠道的额外比例
  num _getChannelPresent(ChannelList item) {
    num present = 0;
    if (widget.goodsType == GoodsType.specialOffer) {
      // 为活动促销商品
      if (_isNative(item.payChannel)) {
        // 为原生支付，获取普通额外比例最大值
        present = _getMaxPresent(widget.model.extraCoinPercent ?? 0, item);
      } else {
        // 三方支付，获取渠道与商品三方比例的最大值
        present = _getMaxPresent(widget.model.thirdpartyCoinPercent ?? 0, item);
      }
    } else if (widget.goodsType == GoodsType.rechargeLink && _isNative(item.payChannel)) {
      // 邀请充值商品且原生支付
      present = 10;
    } else {
      // 普通商品，取普通额外比例最大值
      present = _getMaxPresent(widget.model.extraCoinPercent ?? 0, item);
    }
    return present;
  }

  /// 获取额外比例最大值
  num _getMaxPresent(num present, ChannelList item) {
    if (widget.model.isPromotion ?? false) {
      // 促销
      if ((item.promotionPresentCoinRatio ?? 0) > present) {
        present = item.promotionPresentCoinRatio!;
      }
    } else {
      // 非促销
      if ((item.presentCoinRatio ?? 0) > present) {
        present = item.presentCoinRatio!;
      }
    }
    return present;
  }

  /// 判断是否是原生支付
  bool _isNative(String? name) {
    return name == "GP" || name == "IAP";
  }

  /// 获取过滤后的渠道列表
  List<ChannelList> _getFilteredChannelList() {
    if (!widget.hideNativePay) {
      // 如果不需要隐藏原生支付，返回全部渠道列表
      return widget.list;
    }

    // 隐藏原生支付渠道（GP和IAP）
    final filtered = widget.list.where((channel) => !_isNative(channel.payChannel)).toList();

    // 如果过滤后没有任何渠道，则返回原始列表，确保有支付选项
    return filtered.isNotEmpty ? filtered : widget.list;
  }

  /// 获取原始列表中的索引
  int _getOriginalIndex(ChannelList item) {
    return widget.list.indexWhere((channel) => channel.payChannel == item.payChannel);
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.select,
    required this.item,
    required this.present,
    required this.onTap,
    required this.goodsType,
  }) : super(key: key);

  /// 是否选中
  final bool select;

  /// 渠道数据
  final ChannelList item;

  final num present;

  final GoodsType goodsType;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(select ? 1.w : 1),
        decoration: BoxDecoration(
          gradient: select
              ? const LinearGradient(
                  colors: [Color(0xFF95FFE2), Color(0xFF51CAFF)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFE0E0E0), Color(0xFFE0E0E0)],
                ),
          borderRadius: BorderRadius.circular(7.w),
        ),
        height: 37.w,
        // clipBehavior: Clip.hardEdge,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
                child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.w),
                color: Colors.white,
              ),
            )),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
              child: Row(
                children: [
                  MyExtendedNetworkImage(
                    url: item.iconUrl ?? "",
                    width: 30.w,
                    height: 30.w,
                    fit: BoxFit.contain,
                  ),
                  MyGaps.hGaps5w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MyColor.black,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (present > 0)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "+$present% ${"action_buyMoreDiamonds".bhTR}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFFFF3000),
                                    fontSize: 6.sp,
                                  ),
                                ),
                              ),
                              MyGaps.hGaps2w,
                              Image.asset(
                                ImageAssets.broadcasterDiamondSmall,
                                width: 7.w,
                                height: 7.w,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: item.itemType == 1,
                    child: Container(
                        padding: EdgeInsets.only(bottom: 5.w),
                        width: 15.w,
                        child: Image.asset(
                          ImageAssets.rechargeIcFire,
                          width: 13.w,
                          height: 15.w,
                        )),
                  )
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: Visibility(
                visible: item.itemType == 1,
                child: // 非原生支付，且推荐位
                    Container(
                  padding: EdgeInsets.only(left: 2.w, right: 2.w, bottom: 1.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(3.w), bottomRight: Radius.circular(3.w)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF95FFE2), Color(0xFF51CAFF)],
                    ),
                  ),
                  child: Text(
                    item.recommendReason ?? "",
                    style: FontUtils.boldItalic(
                      color: const Color(0xFFFF3200),
                      size: 6.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
