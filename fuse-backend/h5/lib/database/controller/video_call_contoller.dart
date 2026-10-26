import 'package:get/get.dart';
import 'package:untitled1/database/base/base_controller.dart';
import 'package:untitled1/database/base/database_result.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';
import 'package:untitled1/database/mapper/video_call_mapper.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/message/calls_list/logic.dart';

import '../../common_logic/cache_manager.dart';

/// create: 2023/5/11
/// desc: 视频通话记录操作类
class VideoCallController extends BaseController {
  final _videoMapper = Get.find<VideoCallMapper>();

  /// 接口仓库
  final _request = Get.find<RequestRepository>();

  /// 添加记录
  Future<DatabaseResult<bool>> insert({required VideoCallDao dao}) async {
    if ((dao.userId?.isEmpty ?? true) && (dao.channelName?.isEmpty ?? true)) {
      return DatabaseResult.fail(msg: "userId and channelName is null");
    }

    bool exist = await _videoMapper.queryExist(
        userId: dao.userId!, channelName: dao.channelName!);
    if (exist) {
      return DatabaseResult.fail(msg: "该记录已存在");
    }
    if ((dao.nickname?.isEmpty ?? true) || (dao.avatar?.isEmpty ?? true)) {
      final userId = dao.userId;
      if (userId != null) {
        //缓存获取用户数据
        final user = CacheManager.userGetNameAndAvatarCache(userId);
        if (user != null &&
            (user.clubAvatar?.isNotEmpty ?? false) &&
            (user.nickname?.isNotEmpty ?? false)) {
          dao = dao.copyWith(
            avatar: user.avatarUrl,
            nickname: user.nickname,
          );
        } else {
          // 获取用户最新昵称头像
          await _request.userGetNameAndAvatar(
            userId: userId,
            onSuccess: (data) async {
              dao = dao.copyWith(
                avatar: data.avatarUrl,
                nickname: data.nickname,
              );
            },
          );
        }
      }
      // 如果仍然没有头像，设置默认头像
      if (dao.avatar?.isEmpty ?? true) {
        dao = dao.copyWith(avatar: "");
      }
      // 如果仍然没有昵称，设置默认昵称
      if (dao.nickname?.isEmpty ?? true) {
        dao = dao.copyWith(nickname: "");
      }
    }
   
    // 插入新数据
    bool result = await _videoMapper.insert(dao);

    if (Get.isRegistered<CallsListLogic>()) {
      // 刷新通话记录
      Get.find<CallsListLogic>().initRefresh();
    }

    return DatabaseResult.success(data: result);
  }

  /// 更新通话时长、通话状态、结束时间
  Future updateDuration({
    required String channelName,
    required int duration,
    required String type,
    required int endTime,
  }) async {
    if (channelName.isEmpty) {
      return DatabaseResult.fail(msg: "channelName is null");
    }
    bool result = await _videoMapper.updateDuration(
      channelName: channelName,
      duration: duration,
      type: type,
      endTime: endTime,
    );

    if (Get.isRegistered<CallsListLogic>()) {
      // 刷新通话记录
      Get.find<CallsListLogic>().initRefresh();
    }

    return DatabaseResult.success(data: result);
  }

  /// 更新某个记录
  // Future<DatabaseResult<bool>> update({required VideoCallDao dao}) async {
  //   if (dao.userId?.isEmpty ?? true && (dao.channelName?.isEmpty ?? true)) {
  //     return DatabaseResult.fail(msg: "userId and channelName is null");
  //   }
  //   bool result = await _videoMapper.update(dao);
  //   return DatabaseResult.success(data: result);
  // }

  /// 查询记录
  /// [id] 自增长id，
  /// [limit] 数量
  Future<DatabaseResult<List<VideoCallDao>>> getList(
      {required int id, required int limit}) async {
    List<Map<String, Object?>> result =
        await _videoMapper.queryList(id: id, limit: limit);
    List<VideoCallDao> list = [];
    list.addAll(
        result.map<VideoCallDao>((e) => VideoCallDao.fromJson(e)).toList());
    return DatabaseResult.success(data: list);
  }

  /// 清空表
  Future deleteAll() async {
    await _videoMapper.deleteAll();
  }
}
