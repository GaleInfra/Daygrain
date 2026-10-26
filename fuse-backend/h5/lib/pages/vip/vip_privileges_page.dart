import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/widget/dialog/vip_coin_gift_dialog.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/res/constant.dart';
import 'dart:math' as math;

/// VIP特权页面
class VipPrivilegesPage extends StatefulWidget {
  const VipPrivilegesPage({Key? key}) : super(key: key);

  @override
  State<VipPrivilegesPage> createState() => _VipPrivilegesPageState();
}

class _VipPrivilegesPageState extends State<VipPrivilegesPage> {
  // 当前选中的订阅选项索引
  int _selectedIndex = 1; // 默认选中1 Month选项

  // 添加CoinGoodsLogic引用
  final CoinGoodsLogic _coinGoodsLogic = Get.find<CoinGoodsLogic>();

  // 添加AppConfigManager引用
  final AppConfigManager _appConfigManager = Get.find<AppConfigManager>();

  // 周会员和月会员商品
  CoinGoodsModel? _weekVipProduct;
  CoinGoodsModel? _monthVipProduct;

  // 用于监听充值成功事件
  late StreamSubscription<RechargeSuccessEvent> _rechargeSuccessSubscription;

  // 用于监听支付成功商品代码
  late Worker _paySuccessWorker;

  @override
  void initState() {
    super.initState();
    // 始终加载 VIP 商品数据，即使用户已经是 VIP 会员
    // 这样可以确保我们仍然展示正确的价格和选项
    _loadVipProducts();

    // 监听充值成功事件
    _rechargeSuccessSubscription = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      // 订阅支付成功后，更新用户信息然后刷新UI
      if (event.subscribePay) {
        _updateUserInfoAndRefresh();

        // 检查是否为VIP商品，如果是，则显示金币赠送弹窗
        _showVipCoinGiftDialogIfNeeded(event);
      }
    });

    // 使用GetX的Worker监听paySuccessGoodsCode变化
    _paySuccessWorker = ever(_coinGoodsLogic.payLogic.paySuccessGoodsCode, (String code) {
      if (code.isNotEmpty) {
        // 检查是否是VIP商品
        final isVipProduct = _coinGoodsLogic.vipList.any((item) => item.code == code);
        if (isVipProduct) {
          // 如果是VIP商品，则更新页面
          _updateUserInfoAndRefresh();

          // 查找对应的VIP商品并显示金币赠送弹窗
          _showVipCoinGiftDialogForCode(code);
        }
      }
    });

    // 页面初始化时获取最新用户信息
    _updateUserInfoAndRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 页面依赖变化时（通常是页面重新显示时）刷新用户信息
    _updateUserInfoAndRefresh();
  }

  @override
  void dispose() {
    // 取消订阅
    _rechargeSuccessSubscription.cancel();
    _paySuccessWorker.dispose();
    super.dispose();
  }

  // 更新用户信息并刷新UI
  Future<void> _updateUserInfoAndRefresh() async {
    // 刷新用户信息
    await _appConfigManager.onGetInfo();
    // 刷新UI
    if (mounted) {
      setState(() {
        // 这里不需要做任何事情，setState会触发重建
      });
    }
  }

  // 加载VIP商品数据
  void _loadVipProducts() {
    // 如果vipList为空，先获取商品列表
    if (_coinGoodsLogic.vipList.isEmpty) {
      _coinGoodsLogic.getCoinGoodsSearch(bindPage: false).then((_) {
        _initVipProducts();
      });
    } else {
      _initVipProducts();
    }
  }

  // 初始化VIP商品数据
  void _initVipProducts() {
    setState(() {
      // 查找周会员商品(subType=103)
      if(_coinGoodsLogic.vipList.isNotEmpty) {
        _weekVipProduct =  _coinGoodsLogic.vipList[0];
      }

      // 查找月会员商品(subType=101)
      if(_coinGoodsLogic.vipList.length > 1){
        _monthVipProduct = _coinGoodsLogic.vipList[1];
      }
      

      // 默认选中月会员
      _selectedIndex = _monthVipProduct != null ? 1 : 0;
    });
  }

  // 获取当前选中的商品。槽位为空时用 exchangeDays/validDays/validity 会员档补上。
  CoinGoodsModel? get _selectedProduct {
    final slotted = _selectedIndex == 0 ? _weekVipProduct : _monthVipProduct;
    return _coinGoodsLogic.resolveVipPurchase(slotted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // 让内容延伸到AppBar下方
      appBar: PreferredSize(
        // 设置AppBar的高度包含状态栏高度
        preferredSize: Size.fromHeight(kToolbarHeight + (DeviceUtil().statusBarHeight ?? 0)),
        child: Container(
          // 为AppBar添加顶部padding，等于状态栏高度
          padding: EdgeInsets.only(top: DeviceUtil().statusBarHeight ?? 0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 30.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 0.w),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 10.sp,
                  color: Colors.white,
                ),
                onPressed: () => Get.back(),
              ),
            ),
            title: Text(
              "title_vip_privileges".bhTR,
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 顶部背景图 - 始终保持从最顶部开始
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 112.w,
              decoration:const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ImageAssets.viptop),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 主内容
          Column(
            children: [
              // 占位区域，与顶部图片高度相同，包含安全高度
              SizedBox(height: 95.w),

              // 10% OFF文本位置
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: 15.w),
                alignment: Alignment.center,
                child: Text(
                  "vip_privilege_call_discount_save".bhTR,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建页面内容
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivilegesList(),
            _buildSubscriptionOptions(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // VIP特权列表
  Widget _buildPrivilegesList() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 3.w),
      child: Column(
        children: [
          _buildPrivilegeItem("vip_privilege_coins_gift".bhTR, true),
          _divider(),
          _buildPrivilegeItem("vip_privilege_call_discount".bhTR, true),
          _divider(),
          _buildPrivilegeItem("vip_privilege_camera_switch".bhTR, true),
          _divider(),
          _buildPrivilegeItem("vip_privilege_avatar_frame".bhTR, true),
        ],
      ),
    );
  }

  // 分隔线
  Widget _divider() {
    return Container(
      width: double.infinity,
      height: 0.5.w,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  // 单个特权项
  Widget _buildPrivilegeItem(String title, bool isEnabled) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.w),
      child: Row(
        children: BHLanguageMar().isRightToLeft.value
            ? [
                // 在阿拉伯语环境下反转UI元素顺序
                Container(
                  width: 12.w,
                  height: 12.w,
                  child: Image.asset(
                    ImageAssets.right,
                    width: 8.w,
                    height: 8.w,
                    color: isEnabled ? Color(0xFFFFD700) : Colors.grey,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                    ),
                  ),
                ),
                SizedBox(width: 7.5.w),
                Container(
                  width: 16.w,
                  height: 16.w,
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //       color: Colors.grey.withOpacity(0.3), width: 0.5.w),
                  //   borderRadius: BorderRadius.circular(2.5.w),
                  // ),
                  child: _getIconForPrivilege(title),
                ),
              ]
            : [
                // 在默认语言环境下的原始顺序
                Container(
                  width: 16.w,
                  height: 16.w,
                  // decoration: BoxDecoration(
                  //   border: Border.all(
                  //       color: Colors.grey.withOpacity(0.3), width: 0.5.w),
                  //   borderRadius: BorderRadius.circular(2.5.w),
                  // ),
                  child: _getIconForPrivilege(title),
                ),
                SizedBox(width: 7.5.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                    ),
                  ),
                ),
                Container(
                  width: 12.w,
                  height: 12.w,
                  child: Image.asset(
                    ImageAssets.right,
                    width: 8.w,
                    height: 8.w,
                    // color: isEnabled ? Color(0xFFFFD700) : Colors.grey,
                  ),
                ),
              ],
      ),
    );
  }

  // 根据特权类型返回对应图标
  Widget _getIconForPrivilege(String title) {
    if (title == "vip_privilege_coins_gift".bhTR) {
      return Image.asset(
        ImageAssets.coins,
        width: 10.w,
        height: 10.w,
      );
    } else if (title == "vip_privilege_call_discount".bhTR) {
      return Image.asset(
        ImageAssets.calls,
        width: 10.w,
        height: 10.w,
      );
    } else if (title == "vip_privilege_camera_switch".bhTR) {
      return Image.asset(
        ImageAssets.camera,
        width: 10.w,
        height: 10.w,
      );
    } else if (title == "vip_privilege_avatar_frame".bhTR) {
      return Image.asset(
        ImageAssets.qurrn,
        width: 10.w,
        height: 10.w,
      );
    } else {
      return Icon(
        Icons.star,
        color: Color(0xFFFFD700),
        size: 10.w,
      );
    }
  }

  // 订阅选项
  Widget _buildSubscriptionOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 5.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Obx(() => _buildSubscriptionCard(
                    duration: _weekVipProduct?.getDisplyValidity() ?? "",
                    price: _weekVipProduct == null ? "":localPrice(_weekVipProduct!),
                    bonus: "+${_weekVipProduct?.exchangeCoin ?? 100}",
                    isHot: false,
                    isSelected: _selectedIndex == 0,
                  )),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: Obx(() => _buildSubscriptionCard(
                    duration: _monthVipProduct?.getDisplyValidity() ?? "",
                    price: _monthVipProduct == null ? "" : localPrice(_monthVipProduct!),
                    bonus: "+${_monthVipProduct?.exchangeCoin ?? 500}",
                    isHot: true,
                    isSelected: _selectedIndex == 1,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  // 单个订阅卡片
  Widget _buildSubscriptionCard({
    required String duration,
    required String price,
    required String bonus,
    required bool isHot,
    bool isSelected = false,
  }) {
    final Color borderColor = isSelected ? Color(0xFFFFDAB1) : const Color(0xFF2F2F2F);
    final Color textColor = isSelected ? Colors.white : Colors.white;
    final Color priceColor = isSelected ? Colors.black : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: BorderRadius.circular(5.w),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      padding: EdgeInsets.all(1.w),
      child: Stack(
        clipBehavior: Clip.none, // 允许子元素溢出父容器
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 上半部分
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isSelected ? [Color(0xFF623C0F), Color(0xFF050503)] : [Color(0xFF232323), Color(0xFF232323)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.w),
                    topRight: Radius.circular(4.w),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.75.w),
                          decoration: BoxDecoration(
                            color: Color(0xFF111419),
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                ImageAssets.coins,
                                width: 10.w,
                                height: 10.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                bonus,
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 6.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      ImageAssets.queen,
                      width: 17.w,
                      height: 17.w,
                    ),
                    Text(
                      duration,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.w),
                  ],
                ),
              ),
              // 下半部分
              Container(
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFFFDAB1) : Color(0xFF363636),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4.w),
                    bottomRight: Radius.circular(4.w),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 4.5.w),
                alignment: Alignment.center,
                child: Text(
                  price,
                  style: TextStyle(
                    color: priceColor,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
          if (isHot)
            Positioned(
              top: 3.w,
              // 根据语言环境调整位置，阿拉伯语环境下放在左侧，其他语言环境下放在右侧
              right: BHLanguageMar().isRightToLeft.value ? null : -6.w,
              left: BHLanguageMar().isRightToLeft.value ? -6.w : null,
              child: Image.asset(
                ImageAssets.hot,
                width: 29.w,
                height: 8.w,
              ),
            ),
        ],
      ),
    );
  }

  // 底部按钮和条款
  Widget _buildFooter() {
    // 获取AppConfigManager以检查用户是否有VIP权益
    final appConfig = Get.find<AppConfigManager>();

    // 检查是否有VIP权益
    final hasVipEquity = appConfig.userInfo.hasEquity ?? false;

    // 获取VIP过期时间
    final expiryTimeStr = appConfig.userInfo.equityExpiryTime;

    // 格式化过期时间
    String formattedExpiryTime = "";
    if (expiryTimeStr != null && expiryTimeStr.isNotEmpty) {
      try {
        DateTime expiryDate;
        if (expiryTimeStr.contains("-")) {
          // ISO格式日期字符串，如"2023-06-15T10:30:00.000Z"
          expiryDate = DateTime.parse(expiryTimeStr);
        } else {
          // 时间戳格式，如"1686827400000"
          expiryDate = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTimeStr));
        }
        // 格式化为YYYY-MM-DD
        formattedExpiryTime = "${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print("Error parsing expiry time: $e");
        formattedExpiryTime = "unknown".bhTR;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 7.5.w),
      child: Column(
        children: [
          // 根据用户是否有VIP权益显示不同的内容
          hasVipEquity
              ? Container(
                  width: double.infinity,
                  height: 22.5.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.25.w),
                    color: Color(0xFF524B43),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${("vip_expires".bhTR)}: $formattedExpiryTime",
                    style: TextStyle(
                      color: Color(0xFFFFDAB1),
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : MyGradientButton(
                  width: double.infinity,
                  height: 22.5.w,
                  borderRadius: BorderRadius.circular(11.25.w),
                  gradientColor: const [
                    Color(0xFFDB9A4A),
                    Color(0xFFFFDCB6),
                    Color(0xFFDB9E4E),
                    Color(0xFFFFD06A),
                    Color(0xFFECBB54),
                  ],
                  onTap: () {
                    _purchaseSelectedVip();
                  },
                  child: Text(
                    "action_buy_now".bhTR,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
          SizedBox(height: 7.5.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextButton("vip_terms_of_use".bhTR),
              SizedBox(width: 12.w),
              _buildTextButton("vip_privacy".bhTR),
              SizedBox(width: 12.w),
              _buildTextButton("vip_restore".bhTR),
            ],
          ),
          SizedBox(height: 10.w),
        ],
      ),
    );
  }

  // 底部文字按钮
  Widget _buildTextButton(String text) {
    return GestureDetector(
      onTap: () {
        // 处理点击事件
        if (text == "vip_terms_of_use".bhTR) {
          // 跳转到用户协议页面
          WebViewPage.onJump(url: Constant.termsConditions, title: "terms_termsConditions".bhTR);
        } else if (text == "vip_privacy".bhTR) {
          // 跳转到隐私政策页面
          WebViewPage.onJump(url: Constant.privacyPolicy, title: "terms_privacyPolicy".bhTR);
        } else if (text == "vip_restore".bhTR) {
          // 显示刷新成功提示
          Toast.showMsg("refresh_success".bhTR);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF676767),
          fontSize: 6.sp,
        ),
      ),
    );
  }

  // 根据充值成功事件检查并显示VIP赠送金币弹窗
  void _showVipCoinGiftDialogIfNeeded(RechargeSuccessEvent event) {
    if (event.subscribePay) {
      // 获取支付成功的商品代码
      final successCode = _coinGoodsLogic.payLogic.paySuccessGoodsCode.value;
      if (successCode.isNotEmpty) {
        _showVipCoinGiftDialogForCode(successCode);
      }
    }
  }

  // 根据商品代码查找VIP商品并显示金币赠送弹窗
  void _showVipCoinGiftDialogForCode(String code) {
    // 查找对应的VIP商品
    final vipItem = _coinGoodsLogic.vipList.firstWhere((item) => item.code == code, orElse: () => CoinGoodsModel());

    // 如果找到了商品并且有赠送金币
    if (vipItem.code != null && (vipItem.exchangeCoin ?? 0) > 0) {
      // 延迟一下显示弹窗，确保UI先更新
      Future.delayed(const Duration(milliseconds: 500), () {
        VipCoinGiftDialog.show(coins: vipItem.exchangeCoin!.toInt());
      });
    }
  }

  // 购买选中的VIP商品
  void _purchaseSelectedVip() {
    final selectedProduct = _coinGoodsLogic.resolveVipPurchase(_selectedProduct);
    final appConfig = Get.find<AppConfigManager>();

    // 检查是否已经有VIP权益
    final hasVipEquity = appConfig.userInfo.hasEquity ?? false;

    if (hasVipEquity) {
      Toast.showMsg("error_already_vip".bhTR);
      return;
    }

    // 检查选中的商品是否有效
    if (selectedProduct == null || selectedProduct.code == null) {
      Toast.showMsg("error_product_incomplete".bhTR);
      return;
    }

    // 执行购买操作
    _coinGoodsLogic.onPay(
      model: selectedProduct,
      goodsType: GoodsType.normal, // 使用normal类型，因为枚举中没有vip类型
      entry: "VipPrivilegesPage",
    );
  }
}
