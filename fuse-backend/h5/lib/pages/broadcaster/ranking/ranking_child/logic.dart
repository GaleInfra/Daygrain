import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/ranking/ranking_model.dart';

class RankingChildLogic extends GetBaseController {
  /// 用户ID
  String userId = '';

  /// 用户昵称
  String userNickname = "";

  /// 用户头像
  String userAvatar = "";

  final tagList = ["label_charm".bhTR, "label_rich".bhTR];

  /// 排行榜类型
  late String type;

  /// 主播列表数据
  final list = <RankingModel>[];

  late Function(List<RankingModel>) onDataBack;

  @override
  void onInit() {
    userId = Get.find<AppConfigManager>().userInfo.userId ?? "";
    userNickname = Get.find<AppConfigManager>().userInfo.nickname ?? "";
    userAvatar = Get.find<AppConfigManager>().userInfo.avatarUrl ?? "";
    // logHandle.initLog('rank',subPage: type == tagList[0] ? 'charm' : 'rich');
    super.onInit();
  }

  /// 初始化类型
  void initType(String type) async {
    this.type = type;
    onRefresh();
  }

  /// 刷新
  Future onRefresh() async {
    changeLoading();
    if (type == tagList[0]) {
      rankBroadcasterSearch();
    } else {
      rankUserSearch();
    }
  }

  /// 主播排行榜
  Future rankBroadcasterSearch() async {
    await request.rankBroadcasterSearch(
      onSuccess: (data) {
        list.clear();
        list.addAll(data);
        onDataBack(list);
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }

  /// 用户排行榜
  Future rankUserSearch() async {
    await request.rankUserSearch(
      onSuccess: (data) {
        list.clear();
        list.addAll(data);
        onDataBack(list);
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }
}
