import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/language/bh_language_manager.dart';

/// VIP购买成功后赠送金币弹窗
class VipCoinGiftDialog extends StatelessWidget {
  const VipCoinGiftDialog({
    Key? key,
    required this.coins,
  }) : super(key: key);

  final int coins;
  static const String tag = "VipCoinGiftDialog";

  /// 显示弹窗
  static Future<void> show({required int coins}) async {
    await DialogUtil.showDialog(
      alignment: Alignment.center,
      keepSingle: true,
      clickMaskDismiss: false,
      backDismiss: false,
      tag: tag,
      child: VipCoinGiftDialog(coins: coins),
    );
  }

  /// 关闭弹窗
  static Future<void> dismiss() async {
    await DialogUtil.dismiss(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Stack(
          children: [
            Image.asset(ImageAssets.dialogbg),
            // 使用背景图片
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 7.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明文本
                          Text(
                            "vip_coin_gift_description".bhTR,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 7.w),
                          // Spacer(),
                          // 接收按钮
                          GestureDetector(
                            onTap: () {
                              dismiss();
                            },
                            child: Container(
                              width: double.maxFinite,
                              height: 23.w,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Play Now".bhTR,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            ),
        
          
          ],
        ),
      ),
    );
  }
}
