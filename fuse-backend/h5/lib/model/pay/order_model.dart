class OrderModel {
  OrderModel({
    String? goodsCode,
    String? goodsName,
    String? orderNo,
    num? paidAmount,
    String? paidCurrency,
    num? payAmount,
    String? requestUrl,
    String? tradeNo,
  }) {
    _goodsCode = goodsCode;
    _goodsName = goodsName;
    _orderNo = orderNo;
    _paidAmount = paidAmount;
    _paidCurrency = paidCurrency;
    _payAmount = payAmount;
    _requestUrl = requestUrl;
    _tradeNo = tradeNo;
  }

  OrderModel.fromJson(dynamic json) {
    _goodsCode = json['goodsCode'];
    _goodsName = json['goodsName'];
    _orderNo = json['orderNo'];
    _paidAmount = json['paidAmount'];
    _paidCurrency = json['paidCurrency'];
    _payAmount = json['payAmount'];
    _requestUrl = json['requestUrl'];
    _tradeNo = json['tradeNo'];
  }
  String? _goodsCode;
  String? _goodsName;
  String? _orderNo;
  num? _paidAmount;
  String? _paidCurrency;
  num? _payAmount;
  String? _requestUrl;
  String? _tradeNo;
  OrderModel copyWith({
    String? goodsCode,
    String? goodsName,
    String? orderNo,
    num? paidAmount,
    String? paidCurrency,
    num? payAmount,
    String? requestUrl,
    String? tradeNo,
  }) =>
      OrderModel(
        goodsCode: goodsCode ?? _goodsCode,
        goodsName: goodsName ?? _goodsName,
        orderNo: orderNo ?? _orderNo,
        paidAmount: paidAmount ?? _paidAmount,
        paidCurrency: paidCurrency ?? _paidCurrency,
        payAmount: payAmount ?? _payAmount,
        requestUrl: requestUrl ?? _requestUrl,
        tradeNo: tradeNo ?? _tradeNo,
      );
  String? get goodsCode => _goodsCode;
  String? get goodsName => _goodsName;
  String? get orderNo => _orderNo;
  num? get paidAmount => _paidAmount;
  String? get paidCurrency => _paidCurrency;
  num? get payAmount => _payAmount;
  String? get requestUrl => _requestUrl;
  String? get tradeNo => _tradeNo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['goodsCode'] = _goodsCode;
    map['goodsName'] = _goodsName;
    map['orderNo'] = _orderNo;
    map['paidAmount'] = _paidAmount;
    map['paidCurrency'] = _paidCurrency;
    map['payAmount'] = _payAmount;
    map['requestUrl'] = _requestUrl;
    map['tradeNo'] = _tradeNo;
    return map;
  }
}
