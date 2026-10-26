import 'package:get/get.dart';
import 'package:untitled1/base/get_base_page_controller.dart';
import 'package:untitled1/database/controller/video_call_contoller.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';
import 'package:untitled1/net/base/response_parse.dart';

import '../../../database/base/database_result.dart';

class CallsListLogic extends GetBasePageController<VideoCallDao> {
  final videoSql = Get.find<VideoCallController>();

  @override
  void onReady() {
    initRefresh(showLoading: true);
    super.onReady();
  }

  @override
  Future onRequest(Success onSuccess, Fail onFail, {int page = 1}) async {
    if (page == 1) {
      DatabaseResult<List<VideoCallDao>> result = await videoSql.getList(
        id: 0,
        limit: limit,
      );
      if (result.status) {
        onSuccess.call(result.data);
      } else {
        onFail.call(-1, 'error');
      }
    } else {
      DatabaseResult<List<VideoCallDao>> result = await videoSql.getList(
        id: list.last.id ?? 0,
        limit: limit,
      );
      if (result.status) {
        onSuccess.call(result.data);
      } else {
        onFail.call(-1, 'error');
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
