import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:untitled1/database/base/base_mapper.dart';
import 'package:untitled1/database/box/video_call_box.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';
import 'package:untitled1/database/db/hive_database_manager.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../../utils/common_util.dart';

/// create: 2023/5/11
/// desc: 视频通话记录表
class VideoCallMapper extends BaseMapper {
  @override
  String tableName() => "VideoCall";

  /// id 列id
  /// channelName 频道号
  /// userId 对方用户ID
  /// nickname 对方用户名称
  /// avatar 对方头像
  /// callType 通话类型
  /// endTime 结束时间
  /// duration 通话时长
  ///
  /// 通话类型定义：
  ///
  /// Missed call 呼进,自己没有接听
  /// Rejected call 呼进,自己点了拒绝
  /// Cancelled call 呼出,自己点了挂断按钮
  /// Unanswered call 呼出,自己没有点拒绝按钮,自己也还没触发超时挂断,但收到对方的挂断消息
  ///
  /// 其他只要接通了需要显示通话的时长,呼出是Outgoing call,呼进是Incoming call
  @override
  String tableSqlString() {
    return '''create table ${tableName()} (
    id integer primary key autoincrement,
    channelName text not null,
    userId text not null,
    nickname text not null,
    avatar text not null,
    callType text not null,
    endTime integer not null,
    duration integer not null
    )''';
  }

  //上一条记录id
  int lastId = 0;
  //初始化数据库
  Future<void> initWebDB() async {
    if (kIsWeb) {
      await HiveDatabaseManager.initDatabase();
      lastId = await queryLastId();
      logger.d("${tableName()}初始化数据库成功,上一条记录id===> $lastId");
      //异步执行
      Future(() async {
        // 导入SPUtil中的历史数据
        String callListStr = SPUtil.getString("callList");
        if (callListStr.isNotEmpty) {
          List<VideoCallDao> oldCallList =
              List.from(VideoCallDao.fromJsonList(callListStr));
          try {
            oldCallList.sort((a, b) => a.endTime!.compareTo(b.endTime!));
            for (var dao in oldCallList) {
              //旧数据写死ID = 1 导致导入数据的时候丢失，所以首次导入应该清空id重新导入
              dao.id = 0;
              await insert(dao);
            }
          } catch (e) {
            logger.e("${tableName()}导入历史数据失败===> $e");
          }
          // 清除SPUtil中的数据
          SPUtil.remove("callList");
        }
      });
    }
  }

  @override
  String updateSqlString(int oldVersion, int newVersion) => "";

  Box<VideoCallBox> get box => HiveDatabaseManager.videoCallBox;

  /// 保存数据
  Future<bool> insert(VideoCallDao dao) async {
    if (kIsWeb) {
      //避免空值
      dao.handleNull();
    }
    //根据channelName和userId查询是否存在
    final exists = await queryExist(
      userId: dao.userId ?? "",
      channelName: dao.channelName ?? "",
    );
    if (exists) {
      await update(dao);
      logger.d("${tableName()}更新通话记录成功");
      return true;
    }

    if (dao.id == 0 || dao.id == null) {
      dao.id = lastId + 1;
      lastId = dao.id!;
    }
    final videoCallBox = VideoCallBox.fromDao(dao);
    await box.put(dao.id, videoCallBox);
    logger.d("${tableName()}插入通话记录成功");
    return true;
  }

  //获取最后一天记录的id
  Future<int> queryLastId() async {
    final records = box.values.toList();
    records.sort((a, b) => (b.key as int).compareTo(a.key as int));
    final lastRecord = records.firstOrNull;
    if (lastRecord?.key is int) {
      return lastRecord!.key as int;
    }
    return 0;
  }

  /// 更新某个记录
  Future<bool> update(VideoCallDao dao) async {
    if (kIsWeb) {
      //避免空值
      dao.handleNull();
    }
    final record = box.values.firstWhere(
      (element) =>
          element.userId == dao.userId &&
          element.channelName == dao.channelName,
      orElse: () => throw Exception('Record not found'),
    );
    record.nickname = dao.nickname ?? record.nickname;
    record.avatar = dao.avatar ?? record.avatar;
    record.callType = dao.callType ?? record.callType;
    record.endTime = dao.endTime ?? record.endTime;
    record.duration = dao.duration ?? record.duration;
    record.isFromMatch = dao.isFromMatch ?? record.isFromMatch;
    await record.save();
    logger.d("${tableName()}更新${dao.channelName}的记录成功");
    return true;
  }

  /// 更新用户头像和名称
  Future<bool> updateUserInfo(VideoCallDao dao) async {
    if (kIsWeb) {
      //避免空值
      dao.handleNull();
    }
    final records = box.values.where((element) => element.userId == dao.userId);
    for (var record in records) {
      record.nickname = dao.nickname ?? record.nickname;
      record.avatar = dao.avatar ?? record.avatar;
      await record.save();
    }
    logger.d("${tableName()}更新${dao.userId}的用户数据成功");
    return true;
  }

  /// 更新通话时长
  Future<bool> updateDuration({
    required String channelName,
    required int duration,
    required String type,
    required int endTime,
  }) async {
    final record = box.values.firstWhere(
      (element) => element.channelName == channelName,
      orElse: () => throw Exception('Record not found'),
    );
    record.duration = duration;
    record.callType = type;
    record.endTime = endTime;
    await record.save();
    logger.d("${tableName()}更新$channelName的通话时长成功");
    return true;
  }

  /// 查询数据
  Future<List<Map<String, dynamic>>> queryList({
    required int id,
    required int limit,
  }) async {
    final records = box.values.toList();
    records.sort((a, b) => (b.id as int).compareTo(a.id as int));
    final filteredRecords = id == 0
        ? records.take(limit)
        : records.where((r) => (r.id as int) < id).take(limit);
    final result = filteredRecords.map((r) => r.toDao().toJson()).toList();
    logger.d("${tableName()}查询数据结果===> ${result.length}");
    return result;
  }

  /// 清空表
  Future<void> deleteAll() async {
    await box.clear();
    logger.d("==========${tableName()}表数据清空==========");
  }

  /// 查询是否存在
  Future<bool> queryExist({
    required String userId,
    required String channelName,
  }) async {
    final exists = box.values.any(
      (element) =>
          element.userId == userId && element.channelName == channelName,
    );
    logger.d("查询通话记录【$userId】【$channelName】 是否存在==========> $exists");
    return exists;
  }
}
