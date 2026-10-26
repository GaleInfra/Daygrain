class VideoCallResultModel {
  VideoCallResultModel({
    this.channelName,
    this.broadcasterId,
    this.duration,
    this.tagList,
    this.badTagList,
    this.recommendList,
    this.isClubService,
  });

  VideoCallResultModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    broadcasterId = json['broadcasterId'];
    duration = json['duration'];
    tagList = json['tagList'] != null ? json['tagList'].cast<String>() : [];
    badTagList = json['badTagList'] != null ? json['badTagList'].cast<String>() : [];
    if (json['recommendList'] != null) {
      recommendList = [];
      json['recommendList'].forEach((v) {
        recommendList?.add(RecommendList.fromJson(v));
      });
    }
    isClubService = json['isClubService'];
  }

  String? channelName;
  String? broadcasterId;
  int? duration;
  List<String>? tagList;
  List<String>? badTagList;
  List<RecommendList>? recommendList;
  bool? isClubService;

  VideoCallResultModel copyWith({
    String? channelName,
    String? broadcasterId,
    int? duration,
    List<String>? tagList,
    List<String>? badTagList,
    List<RecommendList>? recommendList,
    bool? isClubService,
  }) =>
      VideoCallResultModel(
        channelName: channelName ?? this.channelName,
        broadcasterId: broadcasterId ?? this.broadcasterId,
        duration: duration ?? this.duration,
        tagList: tagList ?? this.tagList,
        badTagList: badTagList ?? this.badTagList,
        recommendList: recommendList ?? this.recommendList,
        isClubService: isClubService ?? this.isClubService,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['broadcasterId'] = broadcasterId;
    map['duration'] = duration;
    map['tagList'] = tagList;
    map['badTagList'] = badTagList;
    if (recommendList != null) {
      map['recommendList'] = recommendList?.map((v) => v.toJson()).toList();
    }
    map['isClubService'] = isClubService;
    return map;
  }
}

class RecommendList {
  RecommendList({
    this.broadcasterId,
    this.broadcasterName,
    this.avatarThumbUrl,
    this.avatarMapPath,
    this.gender,
    this.unitPrice,
  });

  RecommendList.fromJson(dynamic json) {
    broadcasterId = json['broadcasterId'];
    broadcasterName = json['broadcasterName'];
    avatarThumbUrl = json['avatarThumbUrl'];
    avatarMapPath = json['avatarMapPath'];
    gender = json['gender'];
    unitPrice = json['unitPrice'];
  }

  String? broadcasterId;
  String? broadcasterName;
  String? avatarThumbUrl;
  String? avatarMapPath;
  int? gender;
  int? unitPrice;

  RecommendList copyWith({
    String? broadcasterId,
    String? broadcasterName,
    String? avatarThumbUrl,
    String? avatarMapPath,
    int? gender,
    int? unitPrice,
  }) =>
      RecommendList(
        broadcasterId: broadcasterId ?? this.broadcasterId,
        broadcasterName: broadcasterName ?? this.broadcasterName,
        avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
        avatarMapPath: avatarMapPath ?? this.avatarMapPath,
        gender: gender ?? this.gender,
        unitPrice: unitPrice ?? this.unitPrice,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['broadcasterId'] = broadcasterId;
    map['broadcasterName'] = broadcasterName;
    map['avatarThumbUrl'] = avatarThumbUrl;
    map['avatarMapPath'] = avatarMapPath;
    map['gender'] = gender;
    map['unitPrice'] = unitPrice;
    return map;
  }
}
