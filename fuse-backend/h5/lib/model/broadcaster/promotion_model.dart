/// goodsId : "dac727e5-e042-11ed-b21b-064332c4a6d1"
/// code : "7407"
/// icon : "3"
/// type : "0"
/// tags : "Special Offer"
/// discount : 0.5
/// originalPrice : 9.99
/// price : 4.99
/// exchangeCoin : 1200
/// originalPriceRupee : 749.0
/// priceRupee : 389.0
/// localPaymentPriceRupee : 0.0
/// isPromotion : true
/// localPayOriginalPrice : 0
/// localPayPrice : 0
/// surplusMillisecond : "43200000"

class PromotionModel {
  PromotionModel({
    this.goodsId,
    this.code,
    this.icon,
    this.type,
    this.tags,
    this.discount,
    this.originalPrice,
    this.price,
    this.exchangeCoin,
    this.originalPriceRupee,
    this.priceRupee,
    this.localPaymentPriceRupee,
    this.isPromotion,
    this.localPayOriginalPrice,
    this.localPayPrice,
    this.surplusMillisecond,
  });

  PromotionModel.fromJson(dynamic json) {
    goodsId = json['goodsId'];
    code = json['code'];
    icon = json['icon'];
    type = json['type'];
    tags = json['tags'];
    discount = json['discount'];
    originalPrice = json['originalPrice'];
    price = json['price'];
    exchangeCoin = json['exchangeCoin'];
    originalPriceRupee = json['originalPriceRupee'];
    priceRupee = json['priceRupee'];
    localPaymentPriceRupee = json['localPaymentPriceRupee'];
    isPromotion = json['isPromotion'];
    localPayOriginalPrice = json['localPayOriginalPrice'];
    localPayPrice = json['localPayPrice'];
    surplusMillisecond = json['surplusMillisecond'];
  }

  String? goodsId;
  String? code;
  String? icon;
  String? type;
  String? tags;
  double? discount;
  double? originalPrice;
  double? price;
  int? exchangeCoin;
  double? originalPriceRupee;
  double? priceRupee;
  double? localPaymentPriceRupee;
  bool? isPromotion;
  int? localPayOriginalPrice;
  int? localPayPrice;
  String? surplusMillisecond;

  PromotionModel copyWith({
    String? goodsId,
    String? code,
    String? icon,
    String? type,
    String? tags,
    double? discount,
    double? originalPrice,
    double? price,
    int? exchangeCoin,
    double? originalPriceRupee,
    double? priceRupee,
    double? localPaymentPriceRupee,
    bool? isPromotion,
    int? localPayOriginalPrice,
    int? localPayPrice,
    String? surplusMillisecond,
  }) =>
      PromotionModel(
        goodsId: goodsId ?? this.goodsId,
        code: code ?? this.code,
        icon: icon ?? this.icon,
        type: type ?? this.type,
        tags: tags ?? this.tags,
        discount: discount ?? this.discount,
        originalPrice: originalPrice ?? this.originalPrice,
        price: price ?? this.price,
        exchangeCoin: exchangeCoin ?? this.exchangeCoin,
        originalPriceRupee: originalPriceRupee ?? this.originalPriceRupee,
        priceRupee: priceRupee ?? this.priceRupee,
        localPaymentPriceRupee: localPaymentPriceRupee ?? this.localPaymentPriceRupee,
        isPromotion: isPromotion ?? this.isPromotion,
        localPayOriginalPrice: localPayOriginalPrice ?? this.localPayOriginalPrice,
        localPayPrice: localPayPrice ?? this.localPayPrice,
        surplusMillisecond: surplusMillisecond ?? this.surplusMillisecond,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['goodsId'] = goodsId;
    map['code'] = code;
    map['icon'] = icon;
    map['type'] = type;
    map['tags'] = tags;
    map['discount'] = discount;
    map['originalPrice'] = originalPrice;
    map['price'] = price;
    map['exchangeCoin'] = exchangeCoin;
    map['originalPriceRupee'] = originalPriceRupee;
    map['priceRupee'] = priceRupee;
    map['localPaymentPriceRupee'] = localPaymentPriceRupee;
    map['isPromotion'] = isPromotion;
    map['localPayOriginalPrice'] = localPayOriginalPrice;
    map['localPayPrice'] = localPayPrice;
    map['surplusMillisecond'] = surplusMillisecond;
    return map;
  }
}
