import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/message/calls_list/widget/calls_list_item.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';

import 'logic.dart';

/// 通话列表
class CallsListWidget extends StatefulWidget {
  const CallsListWidget({super.key});

  @override
  State<CallsListWidget> createState() => _CallsListWidgetState();
}

class _CallsListWidgetState extends State<CallsListWidget>
    with AutomaticKeepAliveClientMixin {
  final logic = Get.put(CallsListLogic());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<CallsListLogic>(
      builder: (logic) {
        return RefreshWidget(
          logic: logic,
          emptyMsg: "status_noCallRecord".bhTR,
          child: ListView.builder(
            itemCount: logic.list.length,
            itemBuilder: (ctx, index) {
              return CallsListItem(
                dao: logic.list[index],
              );
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
