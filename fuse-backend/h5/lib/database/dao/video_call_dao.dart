import 'dart:convert';

class VideoCallDao {
  VideoCallDao({
    this.id,
    this.channelName,
    this.userId,
    this.nickname,
    this.avatar,
    this.callType,
    this.endTime,
    this.duration,
    this.isFromMatch,
  });

  VideoCallDao.fromJson(dynamic json) {
    id = json['id'];
    channelName = json['channelName'];
    userId = json['userId'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    callType = json['callType'];
    endTime = json['endTime'];
    duration = json['duration'];
    isFromMatch = json['isFromMatch'];
  }

  int? id;
  String? channelName;
  String? userId;
  String? nickname;
  String? avatar;
  String? callType;
  int? endTime;
  int? duration;
  bool? isFromMatch;

  VideoCallDao copyWith({
    int? id,
    String? channelName,
    String? userId,
    String? nickname,
    String? avatar,
    String? callType,
    int? endTime,
    int? duration,
    bool? isFromMatch,
  }) =>
      VideoCallDao(
        id: id ?? this.id,
        channelName: channelName ?? this.channelName,
        userId: userId ?? this.userId,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        callType: callType ?? this.callType,
        endTime: endTime ?? this.endTime,
        duration: duration ?? this.duration,
        isFromMatch: isFromMatch ?? this.isFromMatch,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['channelName'] = channelName;
    map['userId'] = userId;
    map['nickname'] = nickname;
    map['avatar'] = avatar;
    map['callType'] = callType;
    map['endTime'] = endTime;
    map['duration'] = duration;
    map['isFromMatch'] = isFromMatch;
    return map;
  }

  static List<VideoCallDao> fromJsonList(String callListStr) {
    if (callListStr.isEmpty) {
      return [];
    }
    return jsonDecode(callListStr)
        .map<VideoCallDao>((e) => VideoCallDao.fromJson(e))
        .toList();
  }

  static String toJsonList(List<VideoCallDao> callList) {
    return jsonEncode(callList.map((e) => e.toJson()).toList());
  }

  //整理空值
  void handleNull() {
    // id ??= 0;
    channelName ??= '';
    userId ??= '';
    nickname ??= '';
    avatar ??= '';
    callType ??= '';
    endTime ??= 0;
    duration ??= 0;
    isFromMatch ??= false;
  }
}
