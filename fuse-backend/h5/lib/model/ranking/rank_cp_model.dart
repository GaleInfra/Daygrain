class RankCpModel {
  RankCpModel({
    this.monthName,
    this.rankData,
    this.sortNo,
  });

  RankCpModel.fromJson(dynamic json) {
    monthName = json['monthName'];
    if (json['rankData'] != null) {
      rankData = [];
      json['rankData'].forEach((v) {
        rankData?.add(RankData.fromJson(v));
      });
    }
    sortNo = json['sortNo'];
  }

  String? monthName;
  List<RankData>? rankData;
  String? sortNo;

  RankCpModel copyWith({
    String? monthName,
    List<RankData>? rankData,
    String? sortNo,
  }) =>
      RankCpModel(
        monthName: monthName ?? this.monthName,
        rankData: rankData ?? this.rankData,
        sortNo: sortNo ?? this.sortNo,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['monthName'] = monthName;
    if (rankData != null) {
      map['rankData'] = rankData?.map((v) => v.toJson()).toList();
    }
    map['sortNo'] = sortNo;
    return map;
  }
}

class RankData {
  RankData({
    this.broadcastetModel,
    this.sort,
    this.userModel,
  });

  RankData.fromJson(dynamic json) {
    broadcastetModel = json['broadcastetModel'] != null ? BroadcastetModel.fromJson(json['broadcastetModel']) : null;
    sort = json['sort'];
    userModel = json['userModel'] != null ? UserModel.fromJson(json['userModel']) : null;
  }

  BroadcastetModel? broadcastetModel;
  int? sort;
  UserModel? userModel;

  RankData copyWith({
    BroadcastetModel? broadcastetModel,
    int? sort,
    UserModel? userModel,
  }) =>
      RankData(
        broadcastetModel: broadcastetModel ?? this.broadcastetModel,
        sort: sort ?? this.sort,
        userModel: userModel ?? this.userModel,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (broadcastetModel != null) {
      map['broadcastetModel'] = broadcastetModel?.toJson();
    }
    map['sort'] = sort;
    if (userModel != null) {
      map['userModel'] = userModel?.toJson();
    }
    return map;
  }
}

class UserModel {
  UserModel({
    this.avatar,
    this.avatarMapPath,
    this.nickname,
    this.sort,
    this.userId,
  });

  UserModel.fromJson(dynamic json) {
    avatar = json['avatar'];
    avatarMapPath = json['avatarMapPath'];
    nickname = json['nickname'];
    sort = json['sort'];
    userId = json['userId'];
  }

  String? avatar;
  String? avatarMapPath;
  String? nickname;
  int? sort;
  String? userId;

  UserModel copyWith({
    String? avatar,
    String? avatarMapPath,
    String? nickname,
    int? sort,
    String? userId,
  }) =>
      UserModel(
        avatar: avatar ?? this.avatar,
        avatarMapPath: avatarMapPath ?? this.avatarMapPath,
        nickname: nickname ?? this.nickname,
        sort: sort ?? this.sort,
        userId: userId ?? this.userId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['avatar'] = avatar;
    map['avatarMapPath'] = avatarMapPath;
    map['nickname'] = nickname;
    map['sort'] = sort;
    map['userId'] = userId;
    return map;
  }
}

class BroadcastetModel {
  BroadcastetModel({
    this.avatar,
    this.avatarMapPath,
    this.nickname,
    this.sort,
    this.userId,
  });

  BroadcastetModel.fromJson(dynamic json) {
    avatar = json['avatar'];
    avatarMapPath = json['avatarMapPath'];
    nickname = json['nickname'];
    sort = json['sort'];
    userId = json['userId'];
  }

  String? avatar;
  String? avatarMapPath;
  String? nickname;
  int? sort;
  String? userId;

  BroadcastetModel copyWith({
    String? avatar,
    String? avatarMapPath,
    String? nickname,
    int? sort,
    String? userId,
  }) =>
      BroadcastetModel(
        avatar: avatar ?? this.avatar,
        avatarMapPath: avatarMapPath ?? this.avatarMapPath,
        nickname: nickname ?? this.nickname,
        sort: sort ?? this.sort,
        userId: userId ?? this.userId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['avatar'] = avatar;
    map['avatarMapPath'] = avatarMapPath;
    map['nickname'] = nickname;
    map['sort'] = sort;
    map['userId'] = userId;
    return map;
  }
}
