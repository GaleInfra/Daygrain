import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/language/bh_language_manager.dart';

import '../../res/image_assets.dart';
import '../../res/my_color.dart';
import '../../res/my_gaps.dart';
import '../../utils/online_status_util.dart';
import 'my_gradient_button.dart';

/// create: 2023/5/23
/// desc:
class CallButton extends StatelessWidget {
  final String? price;
  final String? text;
  const CallButton({
    Key? key,
    required this.status,
    required this.onTap,
    this.price,
    this.text,
  }) : super(key: key);

  /// 状态
  final String status;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    bool isOnline = status == OnlineStatusUtil.online ||
        status == OnlineStatusUtil.available;
    return Container(
      width: double.infinity,
      height: 24.w,
      // padding: EdgeInsets.only(top: .5.w, left: .4.w),
      decoration: const BoxDecoration(
        color: MyColor.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.w),
        child: Stack(
          children: [
            Padding(
              padding:const  EdgeInsets.all(0.5),
              child: MyGradientButton(
                width: double.infinity,
                gradient:const LinearGradient(
                  colors:  MyColor.btnGradientColors,
                  begin:  Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                onTap: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // textDirection: TextDirection.ltr,
                  children: [
                    Image.asset(
                      ImageAssets.broadcasterVideo,
                      width: 15.w,
                      height: 15.w,
                    ),
                    MyGaps.hGaps5w,
              
                  Image.asset(
                    ImageAssets.broadcasterDiamondSmall,
                    width: 9.w,
                    height: 9.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    price ?? "--",
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 6.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "/min".bhTR,
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 6.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )
              
                    
                  ],
                ),
              ),
            ),
            if(!isOnline)
              Positioned.fill(child: IgnorePointer(
                ignoring: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColor.black.withValues(alpha: 0.6),
                  ),
                ),
              ))
          ],
        ),
      ),
    );
  }
}
