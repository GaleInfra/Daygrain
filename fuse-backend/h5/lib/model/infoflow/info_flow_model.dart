class InfoFlowModel {
  String? userId;
  String? nickname;
  String? avatar;
  String? avatarMapPath;
  int? gender;
  int? age;
  String? country;
  String? status;
  int? callCoins;
  String? unit;
  bool? isFriend;
  String? about;
  int? followNum;
  List<VideoPaths>? videoPaths;

  InfoFlowModel(
      {this.userId,
        this.nickname,
        this.avatar,
        this.avatarMapPath,
        this.gender,
        this.age,
        this.country,
        this.status,
        this.callCoins,
        this.unit,
        this.isFriend,
        this.about,
        this.followNum,
        this.videoPaths});

  InfoFlowModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    avatarMapPath = json['avatarMapPath'];
    gender = json['gender'];
    age = json['age'];
    country = json['country'];
    status = json['status'];
    callCoins = json['callCoins'];
    unit = json['unit'];
    isFriend = json['isFriend'];
    about = json['about'];
    followNum = json['followNum'];
    if (json['videoPaths'] != null) {
      videoPaths = <VideoPaths>[];
      json['videoPaths'].forEach((v) {
        videoPaths!.add(VideoPaths.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['nickname'] = nickname;
    data['avatar'] = avatar;
    data['avatarMapPath'] = avatarMapPath;
    data['gender'] = gender;
    data['age'] = age;
    data['country'] = country;
    data['status'] = status;
    data['callCoins'] = callCoins;
    data['unit'] = unit;
    data['isFriend'] = isFriend;
    data['about'] = about;
    data['followNum'] = followNum;
    if (videoPaths != null) {
      data['videoPaths'] = videoPaths!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VideoPaths {
  String? mediaPath;
  String? thumbUrl;
  String? middleThumbUrl;
  String? mediaUrl;

  VideoPaths(
      {this.mediaPath, this.thumbUrl, this.middleThumbUrl, this.mediaUrl});

  VideoPaths.fromJson(Map<String, dynamic> json) {
    mediaPath = json['mediaPath'];
    thumbUrl = json['thumbUrl'];
    middleThumbUrl = json['middleThumbUrl'];
    mediaUrl = json['mediaUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mediaPath'] = mediaPath;
    data['thumbUrl'] = thumbUrl;
    data['middleThumbUrl'] = middleThumbUrl;
    data['mediaUrl'] = mediaUrl;
    return data;
  }
}
