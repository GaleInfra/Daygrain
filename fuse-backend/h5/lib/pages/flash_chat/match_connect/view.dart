import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

/// 匹配连接中页
class MatchConnectPage extends StatelessWidget {
  final logic = Get.find<MatchConnectLogic>();

  MatchConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {

      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          // image: DecorationImage(
          //   image: AssetImage(ImageAssets.flashBackground),
          //   fit: BoxFit.cover,
          // ),
        ),
        child: GetBuilder<MatchConnectLogic>(
          builder: (logic) {
            return const Stack(
              children: [],
            );
          },
        ),
      ),
    );
  }
}
