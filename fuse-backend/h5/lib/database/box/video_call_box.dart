import 'package:hive/hive.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';

part 'video_call_box.g.dart';

@HiveType(typeId: 1)
class VideoCallBox extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String channelName;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String nickname;

  @HiveField(4)
  String avatar;

  @HiveField(5)
  String callType;

  @HiveField(6)
  int endTime;

  @HiveField(7)
  int duration;

  @HiveField(8)
  bool isFromMatch;

  VideoCallBox({
    this.id,
    required this.channelName,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.callType,
    required this.endTime,
    required this.duration,
    this.isFromMatch = false,
  });

  // 从DAO转换为Box对象
  factory VideoCallBox.fromDao(VideoCallDao dao) {
    return VideoCallBox(
      id: dao.id,
      channelName: dao.channelName ?? '',
      userId: dao.userId ?? '',
      nickname: dao.nickname ?? '',
      avatar: dao.avatar ?? '',
      callType: dao.callType ?? '',
      endTime: dao.endTime ?? 0,
      duration: dao.duration ?? 0,
      isFromMatch: dao.isFromMatch ?? false,
    );
  }

  // 转换为DAO对象
  VideoCallDao toDao() {
    return VideoCallDao()
      ..id = id
      ..channelName = channelName
      ..userId = userId
      ..nickname = nickname
      ..avatar = avatar
      ..callType = callType
      ..endTime = endTime
      ..duration = duration
      ..isFromMatch = isFromMatch;
  }
}
