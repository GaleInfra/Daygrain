import 'package:untitled1/model/ranking/rank_cp_model.dart';

import '../../../../base/get_base_controller.dart';

/// create: 2024/3/27
/// desc:
class RankingCpLogic extends GetBaseController {
  RankCpModel? cpModel;
  Function(List<RankData>)? onDataBack;
  @override
  void onInit() {
    super.onInit();
    // logHandle.initLog('rank',subPage: 'couple');
    onGetCpList();
  }

  /// 获取列表数据
  Future onGetCpList() async {
    await request.searchCouple(
      onSuccess: (data) {
        cpModel = data;
        if (onDataBack != null) onDataBack!(cpModel?.rankData ?? []);
        changeSuccess();
      },
      onFail: onChangeError,
    );
  }
}
