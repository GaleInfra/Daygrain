
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/gift/gift_model.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/widget/button/my_button.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart' as net;

import '../../model/user/user_info_model.dart';
import '../../res/my_color.dart';

/// create: 2023/5/10
/// desc: 二次确定弹窗
class ConfirmDialog extends StatelessWidget {
  ConfirmDialog({
    Key? key,
    required this.title,
    this.titleStyle,
    this.message,
    this.messageStyle,
    String? cancel,
    this.cancelStyle,
    String? confirm = "Confirm",
    this.confirmStyle,
    this.onCancel,
    this.onConfirm,
    this.swap = false,
    this.child,
    this.bgColor,
  }) : super(key: key) {
    this.cancel = "action_cancel".bhTR;
    this.confirm = "action_confirm".bhTR;
  }
  final Widget? child;

  //是否交换左右按钮位置
  final bool swap;

  /// 标题
  final String title;

  /// 标题栏样式
  final TextStyle? titleStyle;

  /// 标题
  final String? message;

  /// 标题栏样式
  final TextStyle? messageStyle;

  late String cancel;

  final TextStyle? cancelStyle;

  late String confirm;

  final TextStyle? confirmStyle;

  final VoidCallback? onCancel;

  final VoidCallback? onConfirm;

  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: DialogBgWidget(
            bgColor: bgColor,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                children: [
                  Container(
                    padding: child == null ? EdgeInsets.only(top: 19.w) : null,
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: titleStyle ??
                          TextStyle(
                            color: MyColor.white,
                            fontSize: 8.sp,
                          ),
                    ),
                  ),
                  child ?? Container(),
                  Visibility(
                    visible: message != null,
                    child: Container(
                      padding: EdgeInsets.only(top: 6.w),
                      alignment: Alignment.center,
                      child: Text(
                        message ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                              color: Colors.red,
                              fontSize: 8.sp,
                            ),
                      ),
                    ),
                  ),
                  MyGaps.vGaps10w,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: swap ? (BHLanguageMar().isRightToLeft.value ? TextDirection.ltr : TextDirection.rtl) : (BHLanguageMar().isRightToLeft.value ? TextDirection.rtl : TextDirection.ltr),
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onConfirm,
                          child: Container(
                            height: 23.w,
                            padding: EdgeInsets.only(left: .2.w, top: .4.w),
                            // decoration: BoxDecoration(
                            //   borderRadius: BorderRadius.circular(19.w / 2.0),
                            //   color: MyColor.white,
                            // ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 4.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23.w / 2.0),
                                gradient: const LinearGradient(colors: MyColor.btnGradientColors2),
                              ),
                              child: Text(
                                confirm,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: confirmStyle ??
                                    TextStyle(
                                      color: MyColor.white,
                                      fontSize: 8.sp,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 12.w,
                      ),
                      Expanded(
                        child: MyButton(
                          text: cancel,
                          textStyle: cancelStyle ??
                              TextStyle(
                                color: MyColor.white,
                                fontSize: 8.sp,
                              ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 4.w),
                          borderRadius: BorderRadius.circular(23.w / 2.0),
                          height: 23.w,
                          background: MyColor.greyA8A8A8,
                          onTap: onCancel ?? () => DialogUtil.dismiss(),
                        ),
                      ),
                    ],
                  ),
                  MyGaps.vGaps10w,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DialogBgWidget extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  const DialogBgWidget({Key? key, required this.child,this.bgColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            padding:
                const EdgeInsets.only(left: 1.5, right: 0.5, top: 2, bottom: 0),
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(9.w),
            //   gradient: const LinearGradient(
            //     colors: [
            //       Color(0xFFB0B0B0),
            //       MyColor.dialogBgColor2,
            //     ],
            //     begin: Alignment.topLeft,
            //     end: Alignment.bottomRight,
            //   ),
            // ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9.w),
                color:  bgColor ?? MyColor.grey5D5D5D,
                // gradient: const LinearGradient(
                //   colors: [
                //     MyColor.dialogBgColor1,
                //     MyColor.dialogBgColor2,
                //   ],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class BottomDialogBgWidget extends StatelessWidget {
  final Widget child;

  const BottomDialogBgWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.w), // 左上角圆角
                topRight: Radius.circular(18.w), // 右上角圆角
              ),
              color: MyColor.white,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.w), // 左上角圆角
                  topRight: Radius.circular(18.w), // 右上角圆角
                ),
                color:MyColor.white,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class InnerShadow extends StatelessWidget {
  final Color color;
  final Offset offset;
  final double blurRadius;
  final Widget child;

  const InnerShadow({super.key, 
    required this.color,
    required this.offset,
    required this.blurRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _InnerShadowPainter(
                color: color,
                offset: offset,
                blurRadius: blurRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final Color color;
  final Offset offset;
  final double blurRadius;

  _InnerShadowPainter({
    required this.color,
    required this.offset,
    required this.blurRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadowPaint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
      ..blendMode = BlendMode.srcOut;

    final Paint paint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.dstOut;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.translate(-offset.dx, -offset.dy);
    canvas.drawRect(Offset.zero & size, shadowPaint);
    canvas.translate(offset.dx, offset.dy);
    canvas.drawRect(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// create: 2023/5/10
/// desc: 关闭视频通话，二次确定弹窗
class CloseVideoCallConfirmDialog extends StatelessWidget {
   CloseVideoCallConfirmDialog({
    Key? key,
    required this.title,
    required this.userInfo,
    this.titleStyle,
    this.message,
    this.messageStyle,
    String? cancel,
    this.cancelStyle,
    String? confirm = "Confirm",
    this.confirmStyle,
    this.onCancel,
    this.onConfirm,
    this.swap = false,
    this.child,
     this.bgColor
  }) : super(key: key) {
    this.cancel = "action_cancel".bhTR;
    this.confirm = "action_confirm".bhTR;
  }
  final Widget? child;
  final UserInfoModel? userInfo;

  //是否交换左右按钮位置
  final bool swap;
  final Color? bgColor;
  /// 标题
  final String title;

  /// 标题栏样式
  final TextStyle? titleStyle;

  /// 标题
  final String? message;

  /// 标题栏样式
  final TextStyle? messageStyle;

  late String cancel;

  final TextStyle? cancelStyle;

  late String confirm;

  final TextStyle? confirmStyle;

  final VoidCallback? onCancel;

  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(top: 21.5.w),
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.w),
                  border: Border.all(color: MyColor.themeColorNew, width: 1.w),
                  color: MyColor.black.withValues(alpha: 0.5)
                  // gradient:const LinearGradient(colors: MyColor.messageBGs, begin: Alignment.centerLeft, end: Alignment.centerRight),
                ),
                child: Container(
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(9.w),
                  //   color: bgColor ?? MyColor.grey5D5D5D,
                  // ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Column(
                    children: [
                      Container(
                        padding: child == null ? EdgeInsets.only(top: 14.w) : null,
                        alignment: Alignment.center,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: titleStyle ??
                              TextStyle(
                                color: MyColor.white,
                                fontSize: 8.sp,
                              ),
                        ),
                      ),
                      child ?? Container(),
                      Visibility(
                        visible: message != null,
                        child: Container(
                          padding: EdgeInsets.only(top: 6.w),
                          alignment: Alignment.center,
                          child: Text(
                            message ?? "",
                            textAlign: TextAlign.center,
                            style: messageStyle ??
                                TextStyle(
                                  color: MyColor.white,
                                  fontSize: 8.sp,
                                ),
                          ),
                        ),
                      ),
                      MyGaps.vGaps10w,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: swap ? (BHLanguageMar().isRightToLeft.value ? TextDirection.ltr : TextDirection.rtl) : (BHLanguageMar().isRightToLeft.value ? TextDirection.rtl : TextDirection.ltr),
                        children: [
                          
                          Expanded(
                            child: MyButton(
                              text: cancel,
                              textStyle: cancelStyle ??
                                  TextStyle(
                                    color: MyColor.white,
                                    fontSize: 8.sp,
                                  ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 4.w),
                              borderRadius: BorderRadius.circular(23.w / 2.0),
                              height: 23.w,
                              background: MyColor.greyA8A8A8,
                              onTap: onCancel ?? () => DialogUtil.dismiss(),
                            ),
                          ),
                           SizedBox(
                            width: 12.w,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: onConfirm,
                              child: Container(
                                height: 23.w,
                                padding: EdgeInsets.only(left: .2.w, top: .4.w),
                                // decoration: BoxDecoration(
                                //   borderRadius: BorderRadius.circular(19.w / 2.0),
                                //   color: MyColor.white,
                                // ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 4.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23.w / 2.0),
                                    gradient: const LinearGradient(colors: MyColor.btnGradientColors2),
                                  ),
                                  child: Text(
                                    confirm,
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: confirmStyle ??
                                        TextStyle(
                                          color: MyColor.white,
                                          fontSize: 8.sp,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                         
                        ],
                      ),
                      MyGaps.vGaps10w,
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                child: Container(
                  width: 45.w,
                  height: 45.w,
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(45.w/2.0),
                    gradient:const LinearGradient(colors: MyColor.messageBGs, begin: Alignment.centerLeft, end: Alignment.centerRight),
                  ),
                  child: net.MyExtendedNetworkImage(url: userInfo?.avatarThumbUrl ?? "", fit: BoxFit.cover, borderRadius: BorderRadius.circular(43.w/2.0),),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

/// create: 2023/5/10
/// desc: 送礼二次确认
class GiftSureConfirmDialog extends StatelessWidget {
  GiftSureConfirmDialog({
    Key? key,
    this.item,
    String? cancel,
    this.cancelStyle,
    String? confirm = "Confirm",
    this.confirmStyle,
    this.onCancel,
    this.onConfirm,
    this.swap = false,
    this.child,
    this.bgColor
  }) : super(key: key) {
    this.cancel = "action_cancel".bhTR;
    this.confirm = "action_confirm".bhTR;
  }
  final Widget? child;
  final GiftModel? item;
  //是否交换左右按钮位置
  final bool swap;
  final Color? bgColor;

  late String cancel;

  final TextStyle? cancelStyle;

  late String confirm;

  final TextStyle? confirmStyle;

  final VoidCallback? onCancel;

  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    String text = "Send a gift costs ### coins".bhTR.replaceAll("###", (item?.coinPrice ?? 0).toString());
    String number = RegExp(r'\d+').firstMatch(text)?.group(0) ?? ''; // 提取数字
    List<String> parts = text.split(RegExp(r'\d+')); // 按数字分割字符串
    List<TextSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(color: Colors.white,fontSize: 8.sp,fontWeight: FontWeight.w500 ), // 白色文本
      ));
      if (i == 0) {
        if (number.isNotEmpty) {
          spans.add(TextSpan(
            text: number,
            style: TextStyle(color: Colors.red,fontSize: 8.sp,fontWeight: FontWeight.w500), // 红色文本
          ));
        }// 如果找到数字，则添加为红色
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.w),
                    border: Border.all(color: MyColor.themeColorNew, width: 1.w),
                    color: MyColor.black.withValues(alpha: 0.5)
                  // gradient:const LinearGradient(colors: MyColor.messageBGs, begin: Alignment.centerLeft, end: Alignment.centerRight),
                ),
                child: Container(
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(9.w),
                  //   color: bgColor ?? MyColor.grey5D5D5D,
                  // ),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Column(
                    children: [
                      Container(
                        padding: child == null ? EdgeInsets.only(top: 14.w) : null,
                        alignment: Alignment.center,
                        child: Text(
                          "Send a gift".bhTR,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                                color: MyColor.themeColorNew,
                                fontSize: 11.sp,
                            fontWeight: FontWeight.w700
                              ),
                        ),
                      ),
                      child ?? Container(),
                      Visibility(
                        visible: text != null,
                        child: Container(
                          padding: EdgeInsets.only(top: 6.w),
                          alignment: Alignment.center,
                          child: Text.rich(
                            TextSpan(
                              children: spans,
                            ),
                          ),
                        ),
                      ),
                      MyGaps.vGaps10w,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: swap ? (BHLanguageMar().isRightToLeft.value ? TextDirection.ltr : TextDirection.rtl) : (BHLanguageMar().isRightToLeft.value ? TextDirection.rtl : TextDirection.ltr),
                        children: [

                          Expanded(
                            child: MyButton(
                              text: cancel,
                              textStyle: cancelStyle ??
                                  TextStyle(
                                    color: MyColor.white,
                                    fontSize: 8.sp,
                                  ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 4.w),
                              borderRadius: BorderRadius.circular(23.w / 2.0),
                              height: 23.w,
                              background: MyColor.greyA8A8A8,
                              onTap: onCancel ?? () => DialogUtil.dismiss(),
                            ),
                          ),
                          SizedBox(
                            width: 12.w,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: onConfirm,
                              child: Container(
                                height: 23.w,
                                padding: EdgeInsets.only(left: .2.w, top: .4.w),
                                // decoration: BoxDecoration(
                                //   borderRadius: BorderRadius.circular(19.w / 2.0),
                                //   color: MyColor.white,
                                // ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 4.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(23.w / 2.0),
                                    gradient: const LinearGradient(colors: MyColor.btnGradientColors2),
                                  ),
                                  child: Text(
                                    confirm,
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: confirmStyle ??
                                        TextStyle(
                                          color: MyColor.white,
                                          fontSize: 8.sp,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                      MyGaps.vGaps10w,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}