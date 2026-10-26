class RearCameraModel {
  RearCameraModel({
    this.isOpenCamera,
    this.openCoins,
    this.openDay,
  });

  RearCameraModel.fromJson(dynamic json) {
    isOpenCamera = json['isOpenCamera'];
    openCoins = json['openCoins'];
    openDay = json['openDay'];
  }

  bool? isOpenCamera;
  int? openCoins;
  int? openDay;

  RearCameraModel copyWith({
    bool? isOpenCamera,
    int? openCoins,
    int? openDay,
  }) =>
      RearCameraModel(
        isOpenCamera: isOpenCamera ?? this.isOpenCamera,
        openCoins: openCoins ?? this.openCoins,
        openDay: openDay ?? this.openDay,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpenCamera'] = isOpenCamera;
    map['openCoins'] = openCoins;
    map['openDay'] = openDay;
    return map;
  }
}
