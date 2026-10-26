import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/index/logic.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

import '../../res/image_assets.dart';
import '../../res/my_color.dart';
import '../../utils/font_utils.dart';
import '../../utils/device_util.dart';
import 'logic.dart';

/// 消息
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();

}

class _MessagePageState extends State<MessagePage> with AutomaticKeepAliveClientMixin,RouteAware {
  final logic = Get.put(MessageLogic());

  @override
  void didPopNext() {
    // TODO: implement didPopNext
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // TODO: implement didPushNext
    super.didPushNext();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GradientBackgroundWidget(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (BHPlatform.isWeb)
              SizedBox(
                height: DeviceUtil().statusBarHeight,
              ),
            _TabBar(),
            Expanded(
              child: TabBarView(
                controller: logic.tabController,
                children: logic.pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TabBar extends StatelessWidget {
  _TabBar({Key? key}) : super(key: key);
  final logic = Get.put(MessageLogic());

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Obx(() {
        int index = logic.index.value;


        return SizedBox(
          height: 24.w,
          child: TabBar(
            dividerColor: MyColor.transparent,
            tabAlignment: TabAlignment.start,
            controller: logic.tabController,
            isScrollable: true,
            indicatorColor: MyColor.appBackground,
            
            tabs: [
              for (int i = 0; i < logic.tagList.length; i++) ...{
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    if (index == i )
                      Padding(padding: EdgeInsets.only(left: 2.w),child: Image.asset(
                        ImageAssets.messageTabTop,
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.contain,
                      ),),
                    Container(
                      alignment: Alignment.bottomCenter,
                      padding: EdgeInsets.only(bottom: 4.w),
                      child: Text(
                        logic.tagList[i].bhTR,
                        style: index == i ? FontUtils.boldItalic(
                            size:  10.w,
                            color: MyColor.white
                        ) : FontUtils.sansSemiBold(
                            size:  8.7.w,
                            color: MyColor.topBarColor
                        ),
                      ),
                    ),
                
                
                      if (logic.tagList[i] == "label_messages" &&
                  Get.find<IndexLogic>().unreadCount.value > 0)
                Positioned(
                  right: BHLanguageMar().isRightToLeft.value ? null: 0,
                  left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                  top: 4.w,
                  child: Container(
                    width: 3.5.w,
                    height: 3.5.w,
                    decoration: const BoxDecoration(
                      color: MyColor.pinkFE3E69,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                  ],
                )
          
          
              }
            ],
          ),
        );
      }),
    );
  }
}
