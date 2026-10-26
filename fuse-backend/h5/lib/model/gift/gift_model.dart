class GiftModel {
  GiftModel({
    this.code,
    this.coinPrice,
    this.name,
    this.sortNo,
    this.count,
  });

  GiftModel.fromJson(dynamic json) {
    code = json['code'];
    coinPrice = json['coinPrice'];
    name = json['name'];
    sortNo = json['sortNo'];
    count = json['count'];
  }

  String? code;
  int? coinPrice;
  String? name;
  int? sortNo;

  /// 自己添加，礼物数量
  int? count;

  GiftModel copyWith({
    String? code,
    int? coinPrice,
    String? name,
    int? sortNo,
    int? count,
  }) =>
      GiftModel(
        code: code ?? this.code,
        coinPrice: coinPrice ?? this.coinPrice,
        name: name ?? this.name,
        sortNo: sortNo ?? this.sortNo,
        count: count ?? this.count,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['coinPrice'] = coinPrice;
    map['name'] = name;
    map['sortNo'] = sortNo;
    map['count'] = count;
    return map;
  }
}
