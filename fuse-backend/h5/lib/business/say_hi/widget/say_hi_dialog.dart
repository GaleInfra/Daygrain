import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/broadcaster/broadcaster_model.dart';
import 'package:untitled1/business/say_hi/widget/recommended_broadcaster_card.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/overlay_util.dart';

/// Say Hi弹框
class SayHiDialog extends StatelessWidget {
  final List<SayHiRecommendBroadcasterModel> broadcasters;
  final VoidCallback? onSayHiPressed;

  const SayHiDialog({
    Key? key,
    required this.broadcasters,
    this.onSayHiPressed,
  }) : super(key: key);

  static const String tag = "SayHiDialog";

   /// 显示Say Hi弹框
  static Future show({
   required List<SayHiRecommendBroadcasterModel> broadcasters,
    VoidCallback? onSayHiPressed,
    BuildContext? bindWidget,
  }) async{
    // 先关闭之前的弹框
    await dismiss();
    
    return DialogUtil.showDialog(
        keepSingle: true,
        tag: tag,
        clickMaskDismiss: false,
        // bindWidget: bindWidget,
        bindPage: false,
        
        alignment: Alignment.center,
        child: SayHiDialog(
          broadcasters: broadcasters,
          onSayHiPressed: onSayHiPressed,
        ),
    );
  }

  /// 关闭Say Hi弹框
  static Future dismiss() {
    return DialogUtil.dismiss(tag: SayHiDialog.tag);
  }
@override
  Widget build(BuildContext context) {
     double containerW = (Get.width - (24.w*2));
    return Center(
      child: GestureDetector(
        onTap: () {}, // 阻止点击穿透
        child: Container(
          width: containerW,
          height: containerW * 1.12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 第一层：蓝色背景框
              Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Container(
                     width: containerW,
                  height: containerW * 0.7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.5.w),
                      color: const Color(0xFF504B6C),
                    ),
                  ),
                ],
              ),
            ),
              // 第二层：星光背景
              Positioned(
                top: 2.w,
                left: 0,
                right: 0,
                child: Container(
                  width: containerW,
                  height: containerW * 0.7,
                  decoration:const BoxDecoration(
                    image:  DecorationImage(
                      image: AssetImage(ImageAssets.sayHiBg),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // 第三层：内容层
              _buildContentLayer(),
            ],
          ),
        ),
      ),
    );
  }



  /// 构建内容层（顶层）
  Widget _buildContentLayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 推荐主播卡片
        _buildBroadcasterCards(),
        SizedBox(height: 10.w),
        // 标题
        _buildTitle(),
        SizedBox(height: 5.w),
        Padding(
          padding: EdgeInsets.only(left: 14.w,right: 14.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Say Hi按钮
          Padding(
            padding: EdgeInsets.only(top: 10.w),
            child: _buildSayHiButton(),
          ),
            Positioned(
              top: 0,
              child: Image.asset(ImageAssets.sayHi,width: 18.w,height: 19.5.w,)),
          
            ]
          ),
        )
       
      ],
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    return Text(
      'You might like these girls'.bhTR,
      style: FontUtils.sansSemiBold(
        color: Colors.white,
        size: 7.sp,
      ),
      textAlign: TextAlign.center,
    );
  }

    /// 构建推荐主播卡片
  Widget _buildBroadcasterCards() {    
    return SizedBox(
      height: 81.w,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            //卡片1 最底部。 左边旋转30度 对齐左边
            Positioned(
              bottom: 15.w,
              child: Transform.rotate(
                angle:- 15 * pi / 180,
                child: Padding(
                  padding: EdgeInsets.only(right: 70.w),
                  child: RecommendedBroadcasterCard(
                    broadcaster: broadcasters[0],
                    width: 45.75.w,
                    height: 61.w,
                  ),
                ),
              ),
            ),
            //卡片2 夹在中间的。 右边旋转30度 对齐右边
            Positioned(
              bottom: 8.w,
              child: Transform.rotate(
                angle: 13 * pi / 180,
                child: Padding(
                  padding: EdgeInsets.only(left: 70.w),
                  child: RecommendedBroadcasterCard(
                    broadcaster: broadcasters[1],
                    width: 45.75.w,
                      height: 61.w,
                  ),
                ),
              ),
            ),
            //卡片3 最上层。 左边旋转5度 居中对齐
            Positioned(
              bottom: 0,
              child: Transform.rotate(
                angle: 3 * pi / 180,
                child: RecommendedBroadcasterCard(
                  broadcaster: broadcasters[2],
                  width: 61.w,
                height: 81.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// 构建Say Hi按钮
  Widget _buildSayHiButton() {
    return GestureDetector(
      onTap: _onSayHiPressed,
      child: Container(
        width: double.infinity,
        height: 22.w,
        // padding: EdgeInsets.all(1.5.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11.w),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF7C2FB1),
              Color(0xFF755AFC),
              Color(0xFF6182F8),
              Color(0xFF3EBDFC),
              Color(0xFF01FFD1),
            ],
          ),
          
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11.w),
            border: Border.all(color: const Color(0xFFCECCFF).withValues(alpha: 0.3), width: 1.5.w),
            gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF7C2FB1),
              Color(0xFF755AFC),
              Color(0xFF6182F8),
              Color(0xFF3EBDFC),
              Color(0xFF01FFD1),
           
            ],
          ),
          ),
          child: Center(
            child: Text(
              'SayHi and Date with her'.bhTR,
              style: FontUtils.sansSemiBold(
                color: Colors.white,
                size: 6.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理Say Hi按钮点击
  void _onSayHiPressed() {
    // 关闭弹框
    _onDismiss();
    
    // 调用外部回调
    if (onSayHiPressed != null) {
      onSayHiPressed!();
    }
    
    logger.d('Say Hi button pressed');
  }

  /// 关闭弹框
  void _onDismiss() {
    SayHiDialog.dismiss();
  }

}

