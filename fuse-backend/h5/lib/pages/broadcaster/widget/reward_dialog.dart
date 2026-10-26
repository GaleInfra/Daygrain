import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/broadcaster/reward_model.dart';
import 'package:untitled1/utils/MyLinearGradient.dart';
import 'package:untitled1/utils/dialog_util.dart';

import '../../../res/image_assets.dart';
import '../../../res/my_color.dart';

/// create: 2023/5/31
/// desc: 新用户注册奖励弹窗
class RewardDialog extends StatelessWidget {
  const RewardDialog({super.key, required this.rewardModel});

  static Future show({
    required RewardModel rewardModel,
  }) {
    return DialogUtil.showDialog(
      keepSingle: true,
      // bindPage: false,
      // bindWidget: bindWidget,
      tag: tag,
      child: RewardDialog(rewardModel: rewardModel),
    );
  }

  final RewardModel rewardModel;

  static const String tag = "RewardDialog";

  @override
  Widget build(BuildContext context) {
    double containerW = (Get.width - 16.w);
    double containerH = 242.w - 44.w;
    double aspectRatio = 8 / 16;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 242.w,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.w),
            color: MyColor.gray45,
          ),
          child: Stack(
            children: [
              SizedBox(
                width: containerW,
                height: 242.w,
                child: Image.asset(ImageAssets.reward,fit: BoxFit.fill,),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //标题
                  Text(
                    "offer_newUserSurprise".bhTR,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MyColor.blue51,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  Text(
                                      "offer_luckyRewards".bhTR,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: MyColor.white,
                                        fontSize: 7.sp,
                                      ),
                                    ),
                  SizedBox(height: 14.5.w),
                  Container(
                    width: double.infinity,
                    height: 45.w,
                    padding: EdgeInsets.symmetric(horizontal: 7.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8.w),
                        bottomRight: Radius.circular(8.w),
                      ),
                      gradient: MyLinearGradient.getGradient(),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(ImageAssets.coinsStore1,
                            width: 21.5.w, height: 21.5.w, fit: BoxFit.contain),
                        SizedBox(
                          width: 4.w,
                        ),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${rewardModel.coins ?? 0} ${"Coins".bhTR}",
                              maxLines: 1,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: MyColor.white,
                                fontSize: 12.5.sp,
                              ),
                            )
                          ],
                        )),
                        GestureDetector(
                          onTap: () async {
                            DialogUtil.dismiss(tag: tag);
                          },
                          child: SizedBox(
                            width: 50.w,
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 50.w,
                                    height: 23.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(11.5.w),
                                        color: MyColor.blank1E),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "action_receiveNow".bhTR,
                                          style: TextStyle(
                                              color: MyColor.white,
                                              fontSize: 9.sp,
                                              fontWeight: FontWeight.w700),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  // Container(
                  //   height: 198.w,
                  //   alignment: Alignment.bottomCenter,
                  //   child: Stack(
                  //     alignment: Alignment.bottomCenter,
                  //     children: [
                  //       Container(
                  //         margin: EdgeInsets.only(bottom: 6.w),
                  //         child: Column(
                  //           mainAxisAlignment: MainAxisAlignment.end,
                  //           children: [
                  //             Row(
                  //               textDirection: TextDirection.ltr,
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 Image.asset(
                  //                   ImageAssets.broadcasterPromotionDiamond,
                  //                   width: 33.w,
                  //                 ),
                  //                 MyGaps.hGaps3w,
                  //                 Text(
                  //                   "${logic.specialOfferModel?.exchangeCoin ?? 0}",
                  //                   maxLines: 1,
                  //                   style: TextStyle(
                  //                     fontWeight: FontWeight.bold,
                  //                     color: MyColor.white,
                  //                     fontSize: 28.sp,
                  //                   ),
                  //                 ),
                  //                 MyGaps.hGaps7w,
                  //                 // if (extraCoin.isNotEmpty) MyGaps.hGaps2w,
                  //                 Visibility(
                  //                   visible: extraCoin.isNotEmpty,
                  //                   child: Container(
                  //                     decoration: BoxDecoration(
                  //                       image: DecorationImage(
                  //                         image: AssetImage(ImageAssets.broadcasterPromotionExtraCoinBg),
                  //                       ),
                  //                     ),
                  //                     child: Container(
                  //                       margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                  //                       child: Text(
                  //                         "+$extraCoin",
                  //                         style: TextStyle(
                  //                           color: MyColor.white,
                  //                           fontSize: 7.sp,
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             MyGaps.vGaps5w,
                  //             Text(
                  //               "offer_limitedTime".bhTR,
                  //               textAlign: TextAlign.center,
                  //               style: TextStyle(
                  //                 color: MyColor.white,
                  //                 fontSize: 10.sp,
                  //                 fontWeight: FontWeight.w400,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Stack(
                  //   children: [
                  //     Container(
                  //       height: 44.w,
                  //       width: double.infinity,
                  //       alignment: Alignment.center,
                  //       child: GestureDetector(
                  //         onTap: () async {
                  //           // DialogUtil.dismiss();
                  //           await logic.onPay(
                  //             model: logic.specialOfferModel!,
                  //             goodsType: GoodsType.specialOffer,
                  //             entry: PayEntry.SOURCE_29,
                  //           );
                  //         },
                  //         child: Container(
                  //           width: 105.w,
                  //           height: 24.w,
                  //           decoration: BoxDecoration(
                  //             gradient: const LinearGradient(
                  //               colors: [
                  //                 MyColor.themeColor,
                  //                 MyColor.themeColor2,
                  //               ],
                  //               begin: Alignment.centerLeft,
                  //               end: Alignment.centerRight,
                  //               stops: [0.0, 1.0],
                  //             ),
                  //             borderRadius: BorderRadius.circular(12.w),
                  //           ),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Text(
                  //                 localPrice(logic.specialOfferModel ?? CoinGoodsModel()),
                  //                 textDirection: TextDirection.ltr,
                  //                 style: TextStyle(
                  //                   color: MyColor.white,
                  //                   fontSize: 8.sp,
                  //                   fontWeight: FontWeight.bold,
                  //                 ),
                  //               ),
                  //               if (logic.specialOfferModel?.price != logic.specialOfferModel?.originalPrice) MyGaps.hGaps5w,
                  //               if (logic.specialOfferModel?.price != logic.specialOfferModel?.originalPrice)
                  //                 Text(
                  //                   localOriginalPrice(logic.specialOfferModel ?? CoinGoodsModel()),
                  //                   style: TextStyle(
                  //                     color: MyColor.greyC6C5C6,
                  //                     fontSize: 7.sp,
                  //                     decoration: TextDecoration.lineThrough,
                  //                   ),
                  //                 ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),

              // Positioned(
              //   bottom: 30.w,
              //   right: 30.w,
              //   child: Visibility(
              //     visible: residueNum > 1,
              //     child: Container(
              //       width: 18.w,
              //       height: 11.h,
              //       padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.only(topRight: Radius.circular(5.w), topLeft: Radius.circular(5.w), bottomRight: Radius.circular(5.w)),
              //         gradient:  LinearGradient(
              //           colors: MyColor.btnGradientColors,
              //           begin: Alignment.centerLeft,
              //           end: Alignment.centerRight,
              //         ),
              //       ),
              //       child: Text(
              //         "x$residueNum",
              //         style: TextStyle(
              //           color: MyColor.white,
              //           fontSize: 7.sp,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              ///头部那两个按钮
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.only(top: 6.w),
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  width: double.infinity,
                  height: 16.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                      ),
                      GestureDetector(
                        onTap: () {
                          DialogUtil.dismiss(tag: tag);
                        },
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: MyColor.black.withOpacity(.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 10.w,
                            color: MyColor.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
    // return Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Container(
    //       width: double.infinity,
    //       height: 208.w,
    //       margin: EdgeInsets.symmetric(horizontal: 11.w),
    //       decoration: BoxDecoration(
    //         borderRadius: BorderRadius.circular(6.w),
    //         image: DecorationImage(
    //           image: AssetImage(ImageAssets.reward),
    //           fit: BoxFit.fill,
    //         ),
    //       ),
    //       child: Stack(
    //         children: [
    //           Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 8.w),
    //             child: Column(
    //               mainAxisAlignment: MainAxisAlignment.end,
    //               crossAxisAlignment: CrossAxisAlignment.center,
    //               children: [
    //                 Flexible(
    //                   child: AutoSizeText(
    //                     "offer_newUserSurprise".bhTR,
    //                     maxLines: 1,
    //                     textAlign: TextAlign.center,
    //                     style: TextStyle(
    //                       color: MyColor.black,
    //                       fontSize: 10.sp,
    //                     ),
    //                   ),
    //                 ),
    //                 MyGaps.vGaps11w,
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   children: [
    //                     Image.asset(
    //                       ImageAssets.broadcasterPromotionDiamond,
    //                       width: 33.w,
    //                     ),
    //                     MyGaps.hGaps7w,
    //                     Flexible(
    //                       child: AutoSizeText(
    //                         "${rewardModel.coins ?? 0}",
    //                         maxLines: 1,
    //                         style: TextStyle(
    //                           color: MyColor.black,
    //                           fontSize: 28.sp,
    //                           fontWeight: FontWeight.bold,
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 MyGaps.vGaps10w,
    //                 Text(
    //                   "offer_luckyRewards".bhTR,
    //                   textAlign: TextAlign.center,
    //                   style: TextStyle(
    //                     color: const Color(0xFF671996),
    //                     fontSize: 8.sp,
    //                   ),
    //                 ),
    //                 MyGaps.vGaps7w,
    //                 GestureDetector(
    //                   onTap: () => DialogUtil.dismiss(tag: tag),
    //                   child: Container(
    //                     width: 106.w,
    //                     height: 24.w,
    //                     alignment: Alignment.center,
    //                     decoration: BoxDecoration(
    //                       color: MyColor.black,
    //                       borderRadius: BorderRadius.circular(12.w),
    //                       border: Border.all(
    //                         color: MyColor.white,
    //                         width: 1.w,
    //                       ),
    //                     ),
    //                     child: Text(
    //                       "action_receiveNow".bhTR,
    //                       style: TextStyle(
    //                         color: MyColor.white,
    //                         fontSize: 8.sp,
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //                 MyGaps.vGaps12w,
    //               ],
    //             ),
    //           ),
    //           Positioned(
    //             right: 3.w,
    //             top: 26.w,
    //             child: GestureDetector(
    //               onTap: () => DialogUtil.dismiss(tag: tag),
    //               child: Container(
    //                 width: 14.w,
    //                 height: 14.w,
    //                 decoration: BoxDecoration(
    //                   color: MyColor.black.withOpacity(.6),
    //                   shape: BoxShape.circle,
    //                 ),
    //                 child: Icon(
    //                   Icons.close,
    //                   size: 10.w,
    //                   color: MyColor.white,
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ],
    // );
  }
}
