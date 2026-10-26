class BroadcasterExtraInfoModel {
  BroadcasterExtraInfoModel({
    this.applicableTags,
    this.giftList,
    this.labelsList,
    this.specialEffectsGiftList,
  });

  BroadcasterExtraInfoModel.fromJson(dynamic json) {
    applicableTags = json['applicableTags'] != null ? json['applicableTags'].cast<String>() : [];
    giftList = json['giftList'] != null ? json['giftList'].cast<String>() : [];
    labelsList = json['labelsList'] != null ? json['labelsList'].cast<String>() : [];
    specialEffectsGiftList = json['specialEffectsGiftList'] != null ? json['specialEffectsGiftList'].cast<String>() : [];
  }

  List<String>? applicableTags;
  List<String>? giftList;
  List<String>? labelsList;
  List<String>? specialEffectsGiftList;

  BroadcasterExtraInfoModel copyWith({
    List<String>? applicableTags,
    List<String>? giftList,
    List<String>? labelsList,
    List<String>? specialEffectsGiftList,
  }) =>
      BroadcasterExtraInfoModel(
        applicableTags: applicableTags ?? this.applicableTags,
        giftList: giftList ?? this.giftList,
        labelsList: labelsList ?? this.labelsList,
        specialEffectsGiftList: specialEffectsGiftList ?? this.specialEffectsGiftList,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['applicableTags'] = applicableTags;
    map['giftList'] = giftList;
    map['labelsList'] = labelsList;
    map['specialEffectsGiftList'] = specialEffectsGiftList;
    return map;
  }
}
