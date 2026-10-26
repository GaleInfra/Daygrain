class AppConfigModel {
  AppConfigModel({
    this.rvsta,
    this.ver,
    this.items,
    this.riskControlInfoConfig,
  });

  AppConfigModel.fromJson(dynamic json) {
    rvsta = json['rvsta'];
    ver = json['ver'];
    if (json['items'] != null) {
      items = [];
      json['items'].forEach((v) {
        items?.add(Items.fromJson(v));
      });
    }
    riskControlInfoConfig = json['riskControlInfoConfig'] != null ? RiskControlInfoConfig.fromJson(json['riskControlInfoConfig']) : null;
  }

  String? rvsta;
  String? ver;
  List<Items>? items;
  RiskControlInfoConfig? riskControlInfoConfig;

  AppConfigModel copyWith({
    String? rvsta,
    String? ver,
    List<Items>? items,
    RiskControlInfoConfig? riskControlInfoConfig,
  }) =>
      AppConfigModel(
        rvsta: rvsta ?? this.rvsta,
        ver: ver ?? this.ver,
        items: items ?? this.items,
        riskControlInfoConfig: riskControlInfoConfig ?? this.riskControlInfoConfig,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['rvsta'] = rvsta;
    map['ver'] = ver;
    if (items != null) {
      map['items'] = items?.map((v) => v.toJson()).toList();
    }
    if (riskControlInfoConfig != null) {
      map['riskControlInfoConfig'] = riskControlInfoConfig?.toJson();
    }
    return map;
  }
}

class Items {
  Items({
    this.data,
    this.name,
  });

  Items.fromJson(dynamic json) {
    data = json['data'];
    name = json['name'];
  }

  dynamic data;
  String? name;

  Items copyWith({
    dynamic data,
    String? name,
  }) =>
      Items(
        data: data ?? this.data,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['data'] = data;
    map['name'] = name;
    return map;
  }
}

class RiskControlInfoConfig {
  RiskControlInfoConfig({
    this.kInterval,
    this.kFactor,
    this.kFactorNum,
  });

  RiskControlInfoConfig.fromJson(dynamic json) {
    kInterval = json['k_interval'];
    kFactor = json['k_factor'];
    kFactorNum = json['k_factor_num'];
  }

  int? kInterval;
  String? kFactor;
  String? kFactorNum;

  RiskControlInfoConfig copyWith({
    int? kInterval,
    String? kFactor,
    String? kFactorNum,
  }) =>
      RiskControlInfoConfig(
        kInterval: kInterval ?? this.kInterval,
        kFactor: kFactor ?? this.kFactor,
        kFactorNum: kFactorNum ?? this.kFactorNum,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['k_interval'] = kInterval;
    map['k_factor'] = kFactor;
    map['k_factor_num'] = kFactorNum;
    return map;
  }
}
