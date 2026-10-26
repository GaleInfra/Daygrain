import 'package:untitled1/model/user/user_info_model.dart';

/// isFirstRegister : false
/// token : "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxNjUwMDc1OTMyMDM3MzQ5Mzc2IiwidXNlcl90eXBlIjoxLCJleHAiOjQ4Mzc5MTczOTksImNyZWF0ZWQiOjE2ODIyNDM3OTk5NTl9.A56hpxe2O3itIdnY6nhr2AHj6Z7fGEz5ZN5-B3EskcNGwqV1aXVPau2ui9blOL1ucM-KtQqVyzB6KcTiK5BdTg"
/// userInfo : {"age":28,"auditStatus":1,"availableCoins":0,"avatar":"avatar/default/male_52.png","avatarMiddleThumbUrl":"http://cdn-test.livchat.me/avatar/default/male_52.png?Expires=1687951269&OSSAccessKeyId=LTAI4Foco21kGXAUhzdXytpQ&Signature=weukdUfqc%2B377cQk5zueSrsdogE%3D&x-oss-process=image%2Fresize%2Cm_lfit%2Ch_480%2Cw_480%2Climit_1","avatarThumbUrl":"http://cdn-test.livchat.me/avatar/default/male_52.png?Expires=1687951269&OSSAccessKeyId=LTAI4Foco21kGXAUhzdXytpQ&Signature=ODA1zTWlc8T%2FAMCCkeD2DmTem5w%3D&x-oss-process=image%2Fresize%2Cm_lfit%2Ch_160%2Cw_160%2Climit_1","avatarUrl":"http://cdn-test.livchat.me/avatar/default/male_52.png?Expires=1687951269&OSSAccessKeyId=LTAI4Foco21kGXAUhzdXytpQ&Signature=2IqPt3S%2F%2BHXxmN2JY%2BkkoRRUoa0%3D&x-oss-process=image%2Fresize%2Cm_lfit%2Ch_1080%2Cw_1080%2Climit_1","birthday":"1995-01-01","country":"USA","createTime":1682243733572,"followNum":0,"gender":1,"isAnswer":true,"isBlock":false,"isHavePassword":false,"isInternal":false,"isMultiple":false,"isRecharge":false,"isReview":false,"isSwitchNotDisturbCall":false,"isSwitchNotDisturbIm":false,"isVip":false,"level":0,"loginPkgName":"com.fengchao5.android","nickname":"Jonas","praiseNum":0,"registerCountry":"CN","registerPkgName":"com.fengchao5.android","rongcloudToken":"qGA+IzJnFfz9CnJhEv8ghzY0Azh1XAwDnL9go1cwpVAp7h/vZUeJD8VaRr5Fi2jp@hw3r.cn.rongnav.com;hw3r.cn.rongcfg.com","tagDetails":[{"tag":"NEW","tagColor":"#24c45d","tagTip":"Attention: If the call duration is < 40s, you'll not get coins."},{"tag":"Coinless","tagColor":"#999999","tagTip":"Send him a recharge link with discount after the call"},{"tag":"English","tagColor":"#1278f4","tagTip":"He speaks English. Talk to him if you can"}],"tagsList":["New"],"userId":"1650075932037349376","userType":1}

class LoginModel {
  LoginModel({
    this.isFirstRegister,
    this.token,
    this.userInfo,
  });

  LoginModel.fromJson(dynamic json) {
    isFirstRegister = json['isFirstRegister'];
    token = json['token'];
    userInfo = json['userInfo'] != null
        ? UserInfoModel.fromJson(json['userInfo'])
        : null;
  }

  bool? isFirstRegister;
  String? token;
  UserInfoModel? userInfo;

  LoginModel copyWith({
    bool? isFirstRegister,
    String? token,
    UserInfoModel? userInfo,
  }) =>
      LoginModel(
        isFirstRegister: isFirstRegister ?? this.isFirstRegister,
        token: token ?? this.token,
        userInfo: userInfo ?? this.userInfo,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isFirstRegister'] = isFirstRegister;
    map['token'] = token;
    if (userInfo != null) {
      map['userInfo'] = userInfo?.toJson();
    }
    return map;
  }
}
