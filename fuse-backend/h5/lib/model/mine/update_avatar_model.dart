class UpdateAvatarModel {
  UpdateAvatarModel({
      this.mediaId, 
      this.userId, 
      this.mediaType, 
      this.mediaPath, 
      this.thumbUrl, 
      this.middleThumbUrl, 
      this.mediaUrl, 
      this.sort, 
      this.coins,});

  UpdateAvatarModel.fromJson(dynamic json) {
    mediaId = json['mediaId'];
    userId = json['userId'];
    mediaType = json['mediaType'];
    mediaPath = json['mediaPath'];
    thumbUrl = json['thumbUrl'];
    middleThumbUrl = json['middleThumbUrl'];
    mediaUrl = json['mediaUrl'];
    sort = json['sort'];
    coins = json['coins'];
  }
  String? mediaId;
  String? userId;
  String? mediaType;
  String? mediaPath;
  String? thumbUrl;
  String? middleThumbUrl;
  String? mediaUrl;
  int? sort;
  int? coins;
UpdateAvatarModel copyWith({  String? mediaId,
  String? userId,
  String? mediaType,
  String? mediaPath,
  String? thumbUrl,
  String? middleThumbUrl,
  String? mediaUrl,
  int? sort,
  int? coins,
}) => UpdateAvatarModel(  mediaId: mediaId ?? this.mediaId,
  userId: userId ?? this.userId,
  mediaType: mediaType ?? this.mediaType,
  mediaPath: mediaPath ?? this.mediaPath,
  thumbUrl: thumbUrl ?? this.thumbUrl,
  middleThumbUrl: middleThumbUrl ?? this.middleThumbUrl,
  mediaUrl: mediaUrl ?? this.mediaUrl,
  sort: sort ?? this.sort,
  coins: coins ?? this.coins,
);
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mediaId'] = mediaId;
    map['userId'] = userId;
    map['mediaType'] = mediaType;
    map['mediaPath'] = mediaPath;
    map['thumbUrl'] = thumbUrl;
    map['middleThumbUrl'] = middleThumbUrl;
    map['mediaUrl'] = mediaUrl;
    map['sort'] = sort;
    map['coins'] = coins;
    return map;
  }

}