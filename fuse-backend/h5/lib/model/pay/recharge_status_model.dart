class RechargeStatusModel {
  RechargeStatusModel({
    this.orderNo,
    this.userId,
    this.code,
    this.status,
  });

  RechargeStatusModel.fromJson(dynamic json) {
    orderNo = json['orderNo'];
    userId = json['userId'].toString();
    code = json['code'];
    status = json['status'];
  }

  String? orderNo;
  String? userId;
  String? code;
  int? status;

  RechargeStatusModel copyWith({
    String? orderNo,
    String? userId,
    String? code,
    int? status,
  }) =>
      RechargeStatusModel(
        orderNo: orderNo ?? this.orderNo,
        userId: userId ?? this.userId,
        code: code ?? this.code,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['orderNo'] = orderNo;
    map['userId'] = userId;
    map['code'] = code;
    map['status'] = status;
    return map;
  }
}
