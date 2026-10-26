import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

/// 推荐主播卡片
class RecommendedBroadcasterCard extends StatelessWidget {
  final SayHiRecommendBroadcasterModel broadcaster;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const RecommendedBroadcasterCard({
    Key? key,
    required this.broadcaster,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 80.w,
        height: height ?? 110.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.w),
          child: Stack(
            children: [
              MyExtendedNetworkImage(
                url: broadcaster.avatarUrl ?? '',
                width: width ?? 80.w,
                height: height ?? 110.w,
                // borderRadius: BorderRadius.circular(6.w),
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 0,
                left:  0 ,
                right:0,
                
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w,),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(6.w),
                      bottomRight: Radius.circular(6.w),
                    ),
                    //渐变黑色
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.0),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名字
                      _buildName(),
                      // 国家和年龄
                      _buildCountryAndAge(),
                      SizedBox(height: 2.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// 构建名字
  Widget _buildName() {
    return Text(
      broadcaster.broadcasterName ?? 'Unknown',
      style: FontUtils.sansSemiBold(
        color: Colors.white,
        size: 6.sp,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  /// 构建国家和年龄
  Widget _buildCountryAndAge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [

        // 国家代码
        if (broadcaster.countryAndEmoji != null) ...[
          Text(
            broadcaster.countryAndEmoji!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 5.sp,
            ),
          ),
        ],
        // 年龄
        if (broadcaster.age != null) ...[
          Text(
            ', ${broadcaster.age}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 5.sp,
            ),
          ),
        ],
      ],
    );
  }
} 