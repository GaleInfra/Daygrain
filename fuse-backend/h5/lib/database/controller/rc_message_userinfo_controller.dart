import 'package:get/get.dart';
import 'package:untitled1/database/base/base_controller.dart';
import 'package:untitled1/database/dao/rc_message_userinfo_dao.dart';
import 'package:untitled1/database/mapper/rc_message_userinfo_mapper.dart';

/// create: 2023/5/5
/// desc: 融云消息会话用户数据控制器
class RCMessageUserInfoController extends BaseController {
  final _rcUserInfo = Get.find<RCMessageUserInfoMapper>();

  /// 插入用户数据
  Future insertUserInfo({
    required String userId,
    required String nickname,
    required String avatar,
  }) async {
    bool exist = await _rcUserInfo.queryExist(userId);
    if (exist) {

    } else {
      _rcUserInfo.insertUserInfo(RcMessageUserinfoDao(
        userId: userId,
        nickname: nickname,
        avatar: avatar,
      ));
    }
  }
}
