import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/video_call_result_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';

import '../../../res/my_keys.dart';
import '../../../utils/common_util.dart';
import '../../../utils/sp_util.dart';
import '../../../utils/toast.dart';
import '../../../widget/dialog/five_sstar_praise_dialog.dart';
import 'widget/evaluate_dialog.dart';

/// create: 2023/6/14
/// desc: 视频通话结束的弹窗处理
class VideoCallEndDialog {
  VideoCallEndDialog._internal();

  static final VideoCallEndDialog _instance = VideoCallEndDialog._internal();

  factory VideoCallEndDialog() => _instance;

  final _videoHandler = Get.find<VideoCallHandler>();

  final _coinLogic = Get.find<CoinGoodsLogic>();

  final _appConfig = Get.find<AppConfigManager>();

  Future handler({
    required UserInfoModel userInfo,
    required String channelName,
    required VideoCallResultModel? resultModel,
  }) async {
    // 检查是否需要自动匹配，如果需要则不显示评价弹窗
    if (Get.isRegistered<VideoCallLogic>()) {
      if (Get.find<VideoCallLogic>().isBackMatch) {
        // 自动匹配情况下不显示评价弹窗
        return;
      }
    }

    if ((_appConfig.strategyModel?.storeReviews ?? true) &&
        !SPUtil.containsKey(MyKeys.firstEvaluate)) {
      DialogQueueUtil.to.addDialog(DialogQueueElement(
          onShow: () => FiveStarPraiseDialog.show(
                onCall: () => _showOtherDialog(
                  userInfo: userInfo,
                  channelName: channelName,
                  resultModel: resultModel,
                ),
              )));
      return;
    }
    DialogQueueUtil.to.addDialog(DialogQueueElement(
        onShow: () => _showOtherDialog(
              userInfo: userInfo,
              channelName: channelName,
              resultModel: resultModel,
            )));
  }

  Future _showOtherDialog({
    required UserInfoModel userInfo,
    required String channelName,
    required VideoCallResultModel? resultModel,
  }) async {
    try {
      if (_appConfig.userInfo.isRecharge ?? false) {
        if (resultModel == null) {
          // 无响应结果
          // _videoHandler.resetData();
          return;
        }
        if (userInfo.userId?.isEmpty ?? true) {
          // 无用户信息
          //获取缓存是否有用户信息
          final user =
              CacheManager.userInfoCache(resultModel.broadcasterId ?? "");
          if (user != null) {
            userInfo = user;
          } else {
            final request = Get.find<RequestRepository>();
            try {
              userInfo = await request.userGetInfo(
                  userId: resultModel.broadcasterId ?? "",
                  onSuccess: (data) {
                    userInfo = data;
                  },
                  onFail: (code, msg) {});
            } catch (e) {}
          }
        }
        if (userInfo.userId?.isEmpty ?? true) {
          // 无用户信息
          return;
        }
        // 充值用户，弹主播评价弹窗
        EvaluateDialog.show(
          channelName: channelName,
          userInfo: userInfo,
          resultModel: resultModel,
        );
        // _videoHandler.resetData();
      } else {
        // 非充值用户，获取商品列表弹主播引导充值弹窗
        try {
          // 刷新金币数据
          _coinLogic.getCoinPromotion();
          _coinLogic.getCoinGoodsSearch(
            bindPage: false,
            showLoading: false,
            onSuccess: (data) {
              // 在数据加载成功后显示弹窗
              // GuidedRechargeDialog.show(userInfo: userInfo);
              // logger.e("csd打开弹窗");
            },
            onFail: (code, msg) {},
          );
        } catch (error) {
          logger.e("获取商品列表失败==> ${error.toString()}");
        } finally {
          Toast.dismiss(tag: "GuidedRechargeDialog");
        }
      }
      // _videoHandler.resetData();
    } finally {
      // 保证数据清空
      // 在执行此方法前已清空
      // _videoHandler.resetData();
    }
  }
}
