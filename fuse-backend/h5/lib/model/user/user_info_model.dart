
import '../skip_model.dart';

class UserInfoModel {
  UserInfoModel({
    this.about,
    this.acceptMultipleCall,
    this.age,
    this.auditStatus,
    this.availableCoins,
    this.avatar,
    this.avatarMiddleThumbUrl,
    this.avatarThumbUrl,
    this.avatarUrl,
    this.birthday,
    this.clubAvatar,
    this.clubAvatarMiddleThumbUrl,
    this.clubAvatarThumbUrl,
    this.clubAvatarUrl,
    this.country,
    this.createTime,
    this.email,
    this.favors,
    this.firstRechargeTime,
    this.followNum,
    this.gender,
    this.giftWallAction,
    this.grade,
    this.guardianDiscountUnitPrice,
    this.guardianUnitPrice,
    this.horizontalAvatar,
    this.horizontalAvatarMiddleThumbUrl,
    this.horizontalAvatarThumbUrl,
    this.horizontalAvatarUrl,
    this.isAnswer,
    this.isBlock,
    this.isClub,
    this.isFriend,
    this.isHavePassword,
    this.isInternal,
    this.isMultiple,
    this.isProbationPeriod,
    this.isRecharge,
    this.isReview,
    this.isShowReviewSupplementTips,
    this.isSpecialFollow,
    this.isSwitchNotDisturbCall,
    this.isSwitchNotDisturbIm,
    this.isVip,
    this.hasEquity,
    this.equityExpiryTime,
    this.language,
    this.level,
    this.loginPkgName,
    this.mediaList,
    this.mediumAvatar,
    this.mediumAvatarMiddleThumbUrl,
    this.mediumAvatarThumbUrl,
    this.mediumAvatarUrl,
    this.mediumMediaId,
    this.nickname,
    this.pkgName,
    this.praiseNum,
    this.registerCountry,
    this.registerPkgName,
    this.registerPlatform,
    this.rongcloudToken,
    this.tagDetails,
    this.tagsList,
    this.unitPrice,
    this.userId,
    this.userType,
    this.vipExpiryTime,
    this.vipLevel,
    this.vipUnitPrice,
  });

  UserInfoModel.fromJson(dynamic json) {
    about = json['about'];
    acceptMultipleCall = json['acceptMultipleCall'];
    age = json['age'];
    auditStatus = json['auditStatus'];
    availableCoins = json['availableCoins'];
    avatar = json['avatar'];
    avatarMiddleThumbUrl = json['avatarMiddleThumbUrl'];
    avatarThumbUrl = json['avatarThumbUrl'];
    avatarUrl = json['avatarUrl'];
    birthday = json['birthday'];
    clubAvatar = json['clubAvatar'];
    clubAvatarMiddleThumbUrl = json['clubAvatarMiddleThumbUrl'];
    clubAvatarThumbUrl = json['clubAvatarThumbUrl'];
    clubAvatarUrl = json['clubAvatarUrl'];
    country = json['country'];
    createTime = json['createTime'];
    email = json['email'];
    favors = json['favors'];
    firstRechargeTime = json['firstRechargeTime'];
    followNum = json['followNum'];
    gender = json['gender'];
    giftWallAction = json['giftWallAction'];
    grade = json['grade'];
    guardianDiscountUnitPrice = json['guardianDiscountUnitPrice'];
    guardianUnitPrice = json['guardianUnitPrice'];
    horizontalAvatar = json['horizontalAvatar'];
    horizontalAvatarMiddleThumbUrl = json['horizontalAvatarMiddleThumbUrl'];
    horizontalAvatarThumbUrl = json['horizontalAvatarThumbUrl'];
    horizontalAvatarUrl = json['horizontalAvatarUrl'];
    isAnswer = json['isAnswer'];
    isBlock = json['isBlock'];
    isClub = json['isClub'];
    isFriend = json['isFriend'];
    isHavePassword = json['isHavePassword'];
    isInternal = json['isInternal'];
    isMultiple = json['isMultiple'];
    isProbationPeriod = json['isProbationPeriod'];
    isRecharge = json['isRecharge'];
    isReview = json['isReview'];
    isShowReviewSupplementTips = json['isShowReviewSupplementTips'];
    isSpecialFollow = json['isSpecialFollow'];
    isSwitchNotDisturbCall = json['isSwitchNotDisturbCall'];
    isSwitchNotDisturbIm = json['isSwitchNotDisturbIm'];
    isVip = json['isVip'];
    hasEquity = json['hasEquity'];
    equityExpiryTime = json['equityExpiryTime'];
    language = json['language'];
    level = json['level'];
    loginPkgName = json['loginPkgName'];
    if (json['mediaList'] != null) {
      mediaList = [];
      json['mediaList'].forEach((v) {
        mediaList?.add(MediaList.fromJson(v));
      });
    }
    mediumAvatar = json['mediumAvatar'];
    mediumAvatarMiddleThumbUrl = json['mediumAvatarMiddleThumbUrl'];
    mediumAvatarThumbUrl = json['mediumAvatarThumbUrl'];
    mediumAvatarUrl = json['mediumAvatarUrl'];
    mediumMediaId = json['mediumMediaId'];
    nickname = json['nickname'];
    pkgName = json['pkgName'];
    praiseNum = json['praiseNum'];
    registerCountry = json['registerCountry'];
    registerPkgName = json['registerPkgName'];
    registerPlatform = json['registerPlatform'];
    rongcloudToken = json['rongcloudToken'];
    if (json['tagDetails'] != null) {
      tagDetails = [];
      json['tagDetails'].forEach((v) {
        tagDetails?.add(TagDetails.fromJson(v));
      });
    }
    tagsList = json['tagsList'] != null ? json['tagsList'].cast<String>() : [];
    unitPrice = json['unitPrice'];
    userId = json['userId'];
    userType = json['userType'];
    vipExpiryTime = json['vipExpiryTime'];
    vipLevel = json['vipLevel'];
    vipUnitPrice = json['vipUnitPrice'];
  }

  String? about;
  bool? acceptMultipleCall;
  int? age;
  int? auditStatus;
  int? availableCoins;
  String? avatar;
  String? avatarMiddleThumbUrl;
  String? avatarThumbUrl;
  String? avatarUrl;
  String? birthday;
  String? clubAvatar;
  String? clubAvatarMiddleThumbUrl;
  String? clubAvatarThumbUrl;
  String? clubAvatarUrl;
  String? country;
  dynamic createTime;
  String? email;
  String? favors;
  dynamic firstRechargeTime;
  int? followNum;
  int? gender;
  int? giftWallAction;
  int? grade;
  int? guardianDiscountUnitPrice;
  int? guardianUnitPrice;
  String? horizontalAvatar;
  String? horizontalAvatarMiddleThumbUrl;
  String? horizontalAvatarThumbUrl;
  String? horizontalAvatarUrl;
  bool? isAnswer;
  bool? isBlock;
  bool? isClub;
  bool? isFriend;
  bool? isHavePassword;
  bool? isInternal;
  bool? isMultiple;
  bool? isProbationPeriod;
  bool? isRecharge;
  bool? isReview;
  bool? isShowReviewSupplementTips;
  bool? isSpecialFollow;
  bool? isSwitchNotDisturbCall;
  bool? isSwitchNotDisturbIm;
  bool? isVip;
  bool? hasEquity;
  String? equityExpiryTime;
  String? language;
  int? level;
  String? loginPkgName;
  List<MediaList>? mediaList;
  String? mediumAvatar;
  String? mediumAvatarMiddleThumbUrl;
  String? mediumAvatarThumbUrl;
  String? mediumAvatarUrl;
  String? mediumMediaId;
  String? nickname;
  String? pkgName;
  int? praiseNum;
  String? registerCountry;
  String? registerPkgName;
  String? registerPlatform;
  String? rongcloudToken;
  List<TagDetails>? tagDetails;
  List<String>? tagsList;
  int? unitPrice;
  String? userId;
  int? userType;
  String? vipExpiryTime;
  int? vipLevel;
  int? vipUnitPrice;

  UserInfoModel copyWith({
    String? about,
    String? transAbout,
    bool? acceptMultipleCall,
    int? age,
    int? auditStatus,
    int? availableCoins,
    String? avatar,
    String? avatarMiddleThumbUrl,
    String? avatarThumbUrl,
    String? avatarUrl,
    String? birthday,
    String? clubAvatar,
    String? clubAvatarMiddleThumbUrl,
    String? clubAvatarThumbUrl,
    String? clubAvatarUrl,
    String? country,
    dynamic createTime,
    String? email,
    String? favors,
    dynamic firstRechargeTime,
    int? followNum,
    int? gender,
    int? giftWallAction,
    int? grade,
    int? guardianDiscountUnitPrice,
    int? guardianUnitPrice,
    String? horizontalAvatar,
    String? horizontalAvatarMiddleThumbUrl,
    String? horizontalAvatarThumbUrl,
    String? horizontalAvatarUrl,
    bool? isAnswer,
    bool? isBlock,
    bool? isClub,
    bool? isFriend,
    bool? isHavePassword,
    bool? isInternal,
    bool? isMultiple,
    bool? isProbationPeriod,
    bool? isRecharge,
    bool? isReview,
    bool? isShowReviewSupplementTips,
    bool? isSpecialFollow,
    bool? isSwitchNotDisturbCall,
    bool? isSwitchNotDisturbIm,
    bool? isVip,
    bool? hasEquity,
    String? equityExpiryTime,
    String? language,
    int? level,
    String? loginPkgName,
    List<MediaList>? mediaList,
    String? mediumAvatar,
    String? mediumAvatarMiddleThumbUrl,
    String? mediumAvatarThumbUrl,
    String? mediumAvatarUrl,
    String? mediumMediaId,
    String? nickname,
    String? pkgName,
    int? praiseNum,
    String? registerCountry,
    String? registerPkgName,
    String? registerPlatform,
    String? rongcloudToken,
    List<TagDetails>? tagDetails,
    List<String>? tagsList,
    int? unitPrice,
    String? userId,
    int? userType,
    String? vipExpiryTime,
    int? vipLevel,
    int? vipUnitPrice,
  }) =>
      UserInfoModel(
        about: about ?? this.about,
        acceptMultipleCall: acceptMultipleCall ?? this.acceptMultipleCall,
        age: age ?? this.age,
        auditStatus: auditStatus ?? this.auditStatus,
        availableCoins: availableCoins ?? this.availableCoins,
        avatar: avatar ?? this.avatar,
        avatarMiddleThumbUrl: avatarMiddleThumbUrl ?? this.avatarMiddleThumbUrl,
        avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        birthday: birthday ?? this.birthday,
        clubAvatar: clubAvatar ?? this.clubAvatar,
        clubAvatarMiddleThumbUrl:
            clubAvatarMiddleThumbUrl ?? this.clubAvatarMiddleThumbUrl,
        clubAvatarThumbUrl: clubAvatarThumbUrl ?? this.clubAvatarThumbUrl,
        clubAvatarUrl: clubAvatarUrl ?? this.clubAvatarUrl,
        country: country ?? this.country,
        createTime: createTime ?? this.createTime,
        email: email ?? this.email,
        favors: favors ?? this.favors,
        firstRechargeTime: firstRechargeTime ?? this.firstRechargeTime,
        followNum: followNum ?? this.followNum,
        gender: gender ?? this.gender,
        giftWallAction: giftWallAction ?? this.giftWallAction,
        grade: grade ?? this.grade,
        guardianDiscountUnitPrice:
            guardianDiscountUnitPrice ?? this.guardianDiscountUnitPrice,
        guardianUnitPrice: guardianUnitPrice ?? this.guardianUnitPrice,
        horizontalAvatar: horizontalAvatar ?? this.horizontalAvatar,
        horizontalAvatarMiddleThumbUrl: horizontalAvatarMiddleThumbUrl ??
            this.horizontalAvatarMiddleThumbUrl,
        horizontalAvatarThumbUrl:
            horizontalAvatarThumbUrl ?? this.horizontalAvatarThumbUrl,
        horizontalAvatarUrl: horizontalAvatarUrl ?? this.horizontalAvatarUrl,
        isAnswer: isAnswer ?? this.isAnswer,
        isBlock: isBlock ?? this.isBlock,
        isClub: isClub ?? this.isClub,
        isFriend: isFriend ?? this.isFriend,
        isHavePassword: isHavePassword ?? this.isHavePassword,
        isInternal: isInternal ?? this.isInternal,
        isMultiple: isMultiple ?? this.isMultiple,
        isProbationPeriod: isProbationPeriod ?? this.isProbationPeriod,
        isRecharge: isRecharge ?? this.isRecharge,
        isReview: isReview ?? this.isReview,
        isShowReviewSupplementTips:
            isShowReviewSupplementTips ?? this.isShowReviewSupplementTips,
        isSpecialFollow: isSpecialFollow ?? this.isSpecialFollow,
        isSwitchNotDisturbCall:
            isSwitchNotDisturbCall ?? this.isSwitchNotDisturbCall,
        isSwitchNotDisturbIm: isSwitchNotDisturbIm ?? this.isSwitchNotDisturbIm,
        isVip: isVip ?? this.isVip,
        hasEquity: hasEquity ?? this.hasEquity,
        equityExpiryTime: equityExpiryTime ?? this.equityExpiryTime,
        language: language ?? this.language,
        level: level ?? this.level,
        loginPkgName: loginPkgName ?? this.loginPkgName,
        mediaList: mediaList ?? this.mediaList,
        mediumAvatar: mediumAvatar ?? this.mediumAvatar,
        mediumAvatarMiddleThumbUrl:
            mediumAvatarMiddleThumbUrl ?? this.mediumAvatarMiddleThumbUrl,
        mediumAvatarThumbUrl: mediumAvatarThumbUrl ?? this.mediumAvatarThumbUrl,
        mediumAvatarUrl: mediumAvatarUrl ?? this.mediumAvatarUrl,
        mediumMediaId: mediumMediaId ?? this.mediumMediaId,
        nickname: nickname ?? this.nickname,
        pkgName: pkgName ?? this.pkgName,
        praiseNum: praiseNum ?? this.praiseNum,
        registerCountry: registerCountry ?? this.registerCountry,
        registerPkgName: registerPkgName ?? this.registerPkgName,
        registerPlatform: registerPlatform ?? this.registerPlatform,
        rongcloudToken: rongcloudToken ?? this.rongcloudToken,
        tagDetails: tagDetails ?? this.tagDetails,
        tagsList: tagsList ?? this.tagsList,
        unitPrice: unitPrice ?? this.unitPrice,
        userId: userId ?? this.userId,
        userType: userType ?? this.userType,
        vipExpiryTime: vipExpiryTime ?? this.vipExpiryTime,
        vipLevel: vipLevel ?? this.vipLevel,
        vipUnitPrice: vipUnitPrice ?? this.vipUnitPrice,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['about'] = about;
    map['acceptMultipleCall'] = acceptMultipleCall;
    map['age'] = age;
    map['auditStatus'] = auditStatus;
    map['availableCoins'] = availableCoins;
    map['avatar'] = avatar;
    map['avatarMiddleThumbUrl'] = avatarMiddleThumbUrl;
    map['avatarThumbUrl'] = avatarThumbUrl;
    map['avatarUrl'] = avatarUrl;
    map['birthday'] = birthday;
    map['clubAvatar'] = clubAvatar;
    map['clubAvatarMiddleThumbUrl'] = clubAvatarMiddleThumbUrl;
    map['clubAvatarThumbUrl'] = clubAvatarThumbUrl;
    map['clubAvatarUrl'] = clubAvatarUrl;
    map['country'] = country;
    map['createTime'] = createTime;
    map['email'] = email;
    map['favors'] = favors;
    map['firstRechargeTime'] = firstRechargeTime;
    map['followNum'] = followNum;
    map['gender'] = gender;
    map['giftWallAction'] = giftWallAction;
    map['grade'] = grade;
    map['guardianDiscountUnitPrice'] = guardianDiscountUnitPrice;
    map['guardianUnitPrice'] = guardianUnitPrice;
    map['horizontalAvatar'] = horizontalAvatar;
    map['horizontalAvatarMiddleThumbUrl'] = horizontalAvatarMiddleThumbUrl;
    map['horizontalAvatarThumbUrl'] = horizontalAvatarThumbUrl;
    map['horizontalAvatarUrl'] = horizontalAvatarUrl;
    map['isAnswer'] = isAnswer;
    map['isBlock'] = isBlock;
    map['isClub'] = isClub;
    map['isFriend'] = isFriend;
    map['isHavePassword'] = isHavePassword;
    map['isInternal'] = isInternal;
    map['isMultiple'] = isMultiple;
    map['isProbationPeriod'] = isProbationPeriod;
    map['isRecharge'] = isRecharge;
    map['isReview'] = isReview;
    map['isShowReviewSupplementTips'] = isShowReviewSupplementTips;
    map['isSpecialFollow'] = isSpecialFollow;
    map['isSwitchNotDisturbCall'] = isSwitchNotDisturbCall;
    map['isSwitchNotDisturbIm'] = isSwitchNotDisturbIm;
    map['isVip'] = isVip;
    map['hasEquity'] = hasEquity;
    map['equityExpiryTime'] = equityExpiryTime;
    map['language'] = language;
    map['level'] = level;
    map['loginPkgName'] = loginPkgName;
    if (mediaList != null) {
      map['mediaList'] = mediaList?.map((v) => v.toJson()).toList();
    }
    map['mediumAvatar'] = mediumAvatar;
    map['mediumAvatarMiddleThumbUrl'] = mediumAvatarMiddleThumbUrl;
    map['mediumAvatarThumbUrl'] = mediumAvatarThumbUrl;
    map['mediumAvatarUrl'] = mediumAvatarUrl;
    map['mediumMediaId'] = mediumMediaId;
    map['nickname'] = nickname;
    map['pkgName'] = pkgName;
    map['praiseNum'] = praiseNum;
    map['registerCountry'] = registerCountry;
    map['registerPkgName'] = registerPkgName;
    map['registerPlatform'] = registerPlatform;
    map['rongcloudToken'] = rongcloudToken;
    if (tagDetails != null) {
      map['tagDetails'] = tagDetails?.map((v) => v.toJson()).toList();
    }
    map['tagsList'] = tagsList;
    map['unitPrice'] = unitPrice;
    map['userId'] = userId;
    map['userType'] = userType;
    map['vipExpiryTime'] = vipExpiryTime;
    map['vipLevel'] = vipLevel;
    map['vipUnitPrice'] = vipUnitPrice;
    return map;
  }
}
