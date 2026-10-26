class ImLimitModel {
  ImLimitModel({
    this.balance,
    this.broadcasterIds,
  });

  ImLimitModel.fromJson(dynamic json) {
    balance = json['balance'];
    broadcasterIds = json['broadcasterIds'] != null ? json['broadcasterIds'].cast<String>() : [];
  }

  int? balance;
  List<String>? broadcasterIds;

  ImLimitModel copyWith({
    int? balance,
    List<String>? broadcasterIds,
  }) =>
      ImLimitModel(
        balance: balance ?? this.balance,
        broadcasterIds: broadcasterIds ?? this.broadcasterIds,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['balance'] = balance;
    map['broadcasterIds'] = broadcasterIds;
    return map;
  }
}
