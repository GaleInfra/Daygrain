import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/utils/upload_oss_util.dart';

class MineLogic extends GetBaseController {
  final appConfig = Get.find<AppConfigManager>();

  @override
  void onInit() {
    super.onInit();
    logHandle.initLog('setting');
  }

  /// 更新头像
  void onUpdateAvatar() async {
    UploadUtil.selectAndUploadOSS(
      updateRequest: (model, cancelToken) async {
        await request.userUpdateAvatar(
          avatar: model?.filename ?? "",
          cancelToken: cancelToken,
          onSuccess: (data) {
            appConfig.saveUserInfo(
              appConfig.userInfo.copyWith(
                avatar: data.mediaPath,
                avatarUrl: data.mediaUrl,
                avatarThumbUrl: data.middleThumbUrl,
              ),
            );
          },
          onFail: (code, msg) {
            Toast.showMsg("error_network".bhTR);
            throw Exception(msg);
          },
        );
      },
    );
  }

  /// 检查用户是否是付费用户（包括充值用户和VIP用户）
  bool get isPaidUser {
    // 付费用户包括已充值用户和VIP用户
    return appConfig.userInfo.isRecharge == true ||
        appConfig.userInfo.isVip == true ||
        hasVipEquity();
  }

  /// 获取用户付费状态标识字符串，用于日志上报的terPage参数
  /// 返回 "isPaidUser" 或 "notPaidUser"
  String get userPaidStatusForLog {
    return isPaidUser ? "isPaidUser" : "notPaidUser";
  }

  /// 检查用户是否拥有VIP特权
  bool hasVipEquity() {
    // 检查用户是否有VIP权益
    final hasEquity = appConfig.userInfo.hasEquity ?? false;
    if (!hasEquity) {
      return false;
    }

    // 检查权益是否已过期
    final expiryTimeStr = appConfig.userInfo.equityExpiryTime;
    if (expiryTimeStr == null || expiryTimeStr.isEmpty) {
      return false;
    }

    try {
      // 解析过期时间并判断是否已过期
      final now = DateTime.now();
      DateTime expiryDate;

      if (expiryTimeStr.contains("-")) {
        // ISO格式日期字符串，如"2023-06-15T10:30:00.000Z"
        expiryDate = DateTime.parse(expiryTimeStr);
      } else {
        // 时间戳格式，如"1686827400000"
        expiryDate =
            DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTimeStr));
      }

      return now.isBefore(expiryDate); // 如果当前时间在过期时间之前，则未过期
    } catch (e) {
      return false;
    }
  }
}
