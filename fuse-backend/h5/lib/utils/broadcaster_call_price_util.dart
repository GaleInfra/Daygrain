import 'package:untitled1/model/user/user_info_model.dart';

/// 主播视频通话单价展示（金币/分钟），与 [CallButton] 一致。
///
/// 仅使用服务端下发的 [UserInfoModel.unitPrice]（或通话中的 [onCallUnitPrice]），
/// 不做 VIP 前端折扣（如 `unitPrice * 0.9`）。
class BroadcasterCallPriceUtil {
  BroadcasterCallPriceUtil._();

  /// 通话中若已有接通价（如 [onCallModel.unitPrice]），优先展示该值。
  static int displayPerMinutePrice({
    UserInfoModel? broadcaster,
    int? onCallUnitPrice,
  }) {
    if (onCallUnitPrice != null && onCallUnitPrice > 0) {
      return onCallUnitPrice;
    }
    return broadcaster?.unitPrice ?? 0;
  }

  static String displayPerMinutePriceText({
    UserInfoModel? broadcaster,
    int? onCallUnitPrice,
  }) {
    return '${displayPerMinutePrice(
      broadcaster: broadcaster,
      onCallUnitPrice: onCallUnitPrice,
    )}';
  }
}
