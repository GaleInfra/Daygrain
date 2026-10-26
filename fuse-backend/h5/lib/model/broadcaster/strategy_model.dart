import '../skip_model.dart';

class StrategyModel {
  StrategyModel({
    this.activityCategory,
    this.activityCategoryImageUrl,
    this.broadcasterFollowOfficialUserIds,
    this.broadcasterWallRegions,
    this.broadcasterWallTagList,
    this.broadcasterWallTags,
    this.clubSubTags,
    this.extraCategoryName,
    this.flashChatConfig,
    this.freeUserCallStaySecond,
    this.freeUserImStaySecond,
    this.genderMatchCoin,
    this.imIncentiveBlacklistUserIds,
    this.imSessionBalance,
    this.imSessionBroadcasterIds,
    this.initTab,
    this.isAutoAccept,
    this.isCallCameraClose,
    this.isCallRearCamera,
    this.isCloseCamera,
    this.isDisplayNotDisturbCall,
    this.isDisplayNotDisturbIm,
    this.isEnableGuardian,
    this.isForceEvaluationInstruct,
    this.isMaskOpen,
    this.isMatchCallFree,
    this.isNewTppUsable,
    this.isOpenBroacasterInvitation,
    this.isOpenFlashChat,
    this.isOpenSpeechToText,
    this.isRandomUploadPaidEvents,
    this.isRearCamera,
    this.isReportFB,
    this.isReviewPkg,
    this.isShowAutoTranslate,
    this.isShowBroadcasterRank,
    this.isShowDeletedButton,
    this.isShowFlowInfo,
    this.isShowLP,
    this.isShowMatch,
    this.isShowMatchGender,
    this.isShowRookieGuide,
    this.isSilence,
    this.isSwitchClub,
    this.isSwitchExtraCategory,
    this.isSwitchIMIncentive,
    this.isSwitchIMLimit,
    this.isSwitchInstruct,
    this.isSwitchMultipleCall,
    this.isSwitchOneKeyFollow,
    this.isSwitchStrongGuide,
    this.lpDiscount,
    this.lpPromotionDiscount,
    this.officialBlacklistUserIds,
    this.payChannels,
    this.rechargeUserCallStaySecond,
    this.rechargeUserImStaySecond,
    this.reviewOfficialBlacklistUserIds,
    this.storeReviews,
    this.tabType,
    this.timestamp,
    this.topOfficialUserIds,
    this.userInvitation,
    this.userMultipleLevel,
    this.userServiceAccountId,
    this.userWallCategorys,
    this.videoStreamCategory,
    this.visitorOfficialUserId,
    this.voiceToTextConfig,
    this.sayHiMaxCount,
    this.sayHiQuickPhrases,
    this.customList,
  });

  StrategyModel.fromJson(dynamic json) {
    activityCategory = json['activityCategory'];
    activityCategoryImageUrl = json['activityCategoryImageUrl'];
    broadcasterFollowOfficialUserIds =
        json['broadcasterFollowOfficialUserIds'] != null
            ? json['broadcasterFollowOfficialUserIds'].cast<String>()
            : [];
    broadcasterWallRegions = json['broadcasterWallRegions'] != null
        ? json['broadcasterWallRegions'].cast<String>()
        : [];
    if (json['broadcasterWallTagList'] != null) {
      broadcasterWallTagList = [];
      json['broadcasterWallTagList'].forEach((v) {
        broadcasterWallTagList?.add(BroadcasterWallTagList.fromJson(v));
      });
    }
    broadcasterWallTags = json['broadcasterWallTags'] != null
        ? json['broadcasterWallTags'].cast<String>()
        : [];
    if (json['clubSubTags'] != null) {
      clubSubTags = [];
      json['clubSubTags'].forEach((v) {
        clubSubTags?.add(ClubSubTags.fromJson(v));
      });
    }
    extraCategoryName = json['extraCategoryName'];
    flashChatConfig = json['flashChatConfig'] != null
        ? FlashChatConfig.fromJson(json['flashChatConfig'])
        : null;
    freeUserCallStaySecond = json['freeUserCallStaySecond'];
    freeUserImStaySecond = json['freeUserImStaySecond'];
    genderMatchCoin = json['genderMatchCoin'] != null
        ? GenderMatchCoin.fromJson(json['genderMatchCoin'])
        : null;
    imIncentiveBlacklistUserIds = json['imIncentiveBlacklistUserIds'] != null
        ? json['imIncentiveBlacklistUserIds'].cast<String>()
        : [];
    imSessionBalance = json['imSessionBalance'];
    imSessionBroadcasterIds = json['imSessionBroadcasterIds'] != null
        ? json['imSessionBroadcasterIds'].cast<String>()
        : [];
    initTab = json['initTab'];
    isAutoAccept = json['isAutoAccept'];
    isCallCameraClose = json['isCallCameraClose'];
    isCallRearCamera = json['isCallRearCamera'];
    isCloseCamera = json['isCloseCamera'];
    isDisplayNotDisturbCall = json['isDisplayNotDisturbCall'];
    isDisplayNotDisturbIm = json['isDisplayNotDisturbIm'];
    isEnableGuardian = json['isEnableGuardian'];
    isForceEvaluationInstruct = json['isForceEvaluationInstruct'];
    isMaskOpen = json['isMaskOpen'];
    isMatchCallFree = json['isMatchCallFree'];
    isNewTppUsable = json['isNewTppUsable'];
    isOpenBroacasterInvitation = json['isOpenBroacasterInvitation'];
    isOpenFlashChat = json['isOpenFlashChat'];
    isOpenSpeechToText = json['isOpenSpeechToText'];
    isRandomUploadPaidEvents = json['isRandomUploadPaidEvents'];
    isRearCamera = json['isRearCamera'];
    isReportFB = json['isReportFB'];
    isReviewPkg = json['isReviewPkg'];
    isShowAutoTranslate = json['isShowAutoTranslate'];
    isShowBroadcasterRank = json['isShowBroadcasterRank'];
    isShowDeletedButton = json['isShowDeletedButton'];
    isShowFlowInfo = json['isShowFlowInfo'];
    isShowLP = json['isShowLP'];
    isShowMatch = json['isShowMatch'];
    isShowMatchGender = json['isShowMatchGender'];
    isShowRookieGuide = json['isShowRookieGuide'];
    isSilence = json['isSilence'];
    isSwitchClub = json['isSwitchClub'];
    isSwitchExtraCategory = json['isSwitchExtraCategory'];
    isSwitchIMIncentive = json['isSwitchIMIncentive'];
    isSwitchIMLimit = json['isSwitchIMLimit'];
    isSwitchInstruct = json['isSwitchInstruct'];
    isSwitchMultipleCall = json['isSwitchMultipleCall'];
    isSwitchOneKeyFollow = json['isSwitchOneKeyFollow'];
    isSwitchStrongGuide = json['isSwitchStrongGuide'];
    lpDiscount = json['lpDiscount'];
    lpPromotionDiscount = json['lpPromotionDiscount'];
    officialBlacklistUserIds = json['officialBlacklistUserIds'] != null
        ? json['officialBlacklistUserIds'].cast<String>()
        : [];
    payChannels =
        json['payChannels'] != null ? json['payChannels'].cast<String>() : [];
    rechargeUserCallStaySecond = json['rechargeUserCallStaySecond'];
    rechargeUserImStaySecond = json['rechargeUserImStaySecond'];
    reviewOfficialBlacklistUserIds =
        json['reviewOfficialBlacklistUserIds'] != null
            ? json['reviewOfficialBlacklistUserIds'].cast<String>()
            : [];
    storeReviews = _readBool(json['store_reviews'] ?? json['storeReviews']);
    tabType = json['tabType'];
    timestamp = json['timestamp'];
    topOfficialUserIds = json['topOfficialUserIds'] != null
        ? json['topOfficialUserIds'].cast<String>()
        : [];
    userInvitation = json['userInvitation'] != null
        ? UserInvitation.fromJson(json['userInvitation'])
        : null;
    userMultipleLevel = json['userMultipleLevel'];
    userServiceAccountId = json['userServiceAccountId'];
    userWallCategorys = json['userWallCategorys'] != null
        ? json['userWallCategorys'].cast<String>()
        : [];
    videoStreamCategory = json['videoStreamCategory'] != null
        ? json['videoStreamCategory'].cast<String>()
        : [];
    visitorOfficialUserId = json['visitorOfficialUserId'];
    voiceToTextConfig = json['voiceToTextConfig'] != null
        ? VoiceToTextConfig.fromJson(json['voiceToTextConfig'])
        : null;
    sayHiMaxCount = json['sayHiMaxCount'];
    sayHiQuickPhrases = json['sayHiQuickPhrases'] != null
        ? json['sayHiQuickPhrases'].cast<String>()
        : [];
    // 从嵌套的 data 字段中读取 custom_list
    if (json['data'] != null && json['data'] is Map) {
      final dataObj = json['data'] as Map<String, dynamic>;
      storeReviews ??=
          _readBool(dataObj['store_reviews'] ?? dataObj['storeReviews']);
      // 尝试多种可能的字段名
      if (dataObj['custom_list'] != null) {
        customList = CustomListModel.fromJson(dataObj['custom_list']);
      } else if (dataObj['customList'] != null) {
        customList = CustomListModel.fromJson(dataObj['customList']);
      }
    }
  }

  String? activityCategory;
  String? activityCategoryImageUrl;
  List<String>? broadcasterFollowOfficialUserIds;
  List<String>? broadcasterWallRegions;
  List<BroadcasterWallTagList>? broadcasterWallTagList;
  List<String>? broadcasterWallTags;
  List<ClubSubTags>? clubSubTags;
  String? extraCategoryName;
  FlashChatConfig? flashChatConfig;
  String? freeUserCallStaySecond;
  String? freeUserImStaySecond;
  GenderMatchCoin? genderMatchCoin;
  List<String>? imIncentiveBlacklistUserIds;
  int? imSessionBalance;
  List<String>? imSessionBroadcasterIds;
  int? initTab;
  bool? isAutoAccept;
  bool? isCallCameraClose;
  bool? isCallRearCamera;
  bool? isCloseCamera;
  bool? isDisplayNotDisturbCall;
  bool? isDisplayNotDisturbIm;
  bool? isEnableGuardian;
  bool? isForceEvaluationInstruct;
  bool? isMaskOpen;
  bool? isMatchCallFree;
  bool? isNewTppUsable;
  bool? isOpenBroacasterInvitation;
  bool? isOpenFlashChat;
  bool? isOpenSpeechToText;
  bool? isRandomUploadPaidEvents;
  bool? isRearCamera;
  bool? isReportFB;
  bool? isReviewPkg;
  bool? isShowAutoTranslate;
  bool? isShowBroadcasterRank;
  bool? isShowDeletedButton;
  bool? isShowFlowInfo;
  bool? isShowLP;
  bool? isShowMatch;
  bool? isShowMatchGender;
  bool? isShowRookieGuide;
  bool? isSilence;
  bool? isSwitchClub;
  bool? isSwitchExtraCategory;
  bool? isSwitchIMIncentive;
  bool? isSwitchIMLimit;
  bool? isSwitchInstruct;
  bool? isSwitchMultipleCall;
  bool? isSwitchOneKeyFollow;
  bool? isSwitchStrongGuide;
  int? lpDiscount;
  int? lpPromotionDiscount;
  List<String>? officialBlacklistUserIds;
  List<String>? payChannels;
  String? rechargeUserCallStaySecond;
  String? rechargeUserImStaySecond;
  List<String>? reviewOfficialBlacklistUserIds;
  bool? storeReviews;
  int? tabType;
  String? timestamp;
  List<String>? topOfficialUserIds;
  UserInvitation? userInvitation;
  int? userMultipleLevel;
  String? userServiceAccountId;
  List<String>? userWallCategorys;
  List<String>? videoStreamCategory;
  int? visitorOfficialUserId;
  VoiceToTextConfig? voiceToTextConfig;
  int? sayHiMaxCount;
  List<String>? sayHiQuickPhrases;
  CustomListModel? customList;

  StrategyModel copyWith({
    String? activityCategory,
    String? activityCategoryImageUrl,
    List<String>? broadcasterFollowOfficialUserIds,
    List<String>? broadcasterWallRegions,
    List<BroadcasterWallTagList>? broadcasterWallTagList,
    List<String>? broadcasterWallTags,
    List<ClubSubTags>? clubSubTags,
    String? extraCategoryName,
    FlashChatConfig? flashChatConfig,
    String? freeUserCallStaySecond,
    String? freeUserImStaySecond,
    GenderMatchCoin? genderMatchCoin,
    List<String>? imIncentiveBlacklistUserIds,
    int? imSessionBalance,
    List<String>? imSessionBroadcasterIds,
    int? initTab,
    bool? isAutoAccept,
    bool? isCallCameraClose,
    bool? isCallRearCamera,
    bool? isCloseCamera,
    bool? isDisplayNotDisturbCall,
    bool? isDisplayNotDisturbIm,
    bool? isEnableGuardian,
    bool? isForceEvaluationInstruct,
    bool? isMaskOpen,
    bool? isMatchCallFree,
    bool? isNewTppUsable,
    bool? isOpenBroacasterInvitation,
    bool? isOpenFlashChat,
    bool? isOpenSpeechToText,
    bool? isRandomUploadPaidEvents,
    bool? isRearCamera,
    bool? isReportFB,
    bool? isReviewPkg,
    bool? isShowAutoTranslate,
    bool? isShowBroadcasterRank,
    bool? isShowDeletedButton,
    bool? isShowFlowInfo,
    bool? isShowLP,
    bool? isShowMatch,
    bool? isShowMatchGender,
    bool? isShowRookieGuide,
    bool? isSilence,
    bool? isSwitchClub,
    bool? isSwitchExtraCategory,
    bool? isSwitchIMIncentive,
    bool? isSwitchIMLimit,
    bool? isSwitchInstruct,
    bool? isSwitchMultipleCall,
    bool? isSwitchOneKeyFollow,
    bool? isSwitchStrongGuide,
    int? lpDiscount,
    int? lpPromotionDiscount,
    List<String>? officialBlacklistUserIds,
    List<String>? payChannels,
    String? rechargeUserCallStaySecond,
    String? rechargeUserImStaySecond,
    List<String>? reviewOfficialBlacklistUserIds,
    bool? storeReviews,
    int? tabType,
    String? timestamp,
    List<String>? topOfficialUserIds,
    UserInvitation? userInvitation,
    int? userMultipleLevel,
    String? userServiceAccountId,
    List<String>? userWallCategorys,
    List<String>? videoStreamCategory,
    int? visitorOfficialUserId,
    VoiceToTextConfig? voiceToTextConfig,
    int? sayHiMaxCount,
    List<String>? sayHiQuickPhrases,
  }) =>
      StrategyModel(
        activityCategory: activityCategory ?? this.activityCategory,
        activityCategoryImageUrl:
            activityCategoryImageUrl ?? this.activityCategoryImageUrl,
        broadcasterFollowOfficialUserIds: broadcasterFollowOfficialUserIds ??
            this.broadcasterFollowOfficialUserIds,
        broadcasterWallRegions:
            broadcasterWallRegions ?? this.broadcasterWallRegions,
        broadcasterWallTagList:
            broadcasterWallTagList ?? this.broadcasterWallTagList,
        broadcasterWallTags: broadcasterWallTags ?? this.broadcasterWallTags,
        clubSubTags: clubSubTags ?? this.clubSubTags,
        extraCategoryName: extraCategoryName ?? this.extraCategoryName,
        flashChatConfig: flashChatConfig ?? this.flashChatConfig,
        freeUserCallStaySecond:
            freeUserCallStaySecond ?? this.freeUserCallStaySecond,
        freeUserImStaySecond: freeUserImStaySecond ?? this.freeUserImStaySecond,
        genderMatchCoin: genderMatchCoin ?? this.genderMatchCoin,
        imIncentiveBlacklistUserIds:
            imIncentiveBlacklistUserIds ?? this.imIncentiveBlacklistUserIds,
        imSessionBalance: imSessionBalance ?? this.imSessionBalance,
        imSessionBroadcasterIds:
            imSessionBroadcasterIds ?? this.imSessionBroadcasterIds,
        initTab: initTab ?? this.initTab,
        isAutoAccept: isAutoAccept ?? this.isAutoAccept,
        isCallCameraClose: isCallCameraClose ?? this.isCallCameraClose,
        isCallRearCamera: isCallRearCamera ?? this.isCallRearCamera,
        isCloseCamera: isCloseCamera ?? this.isCloseCamera,
        isDisplayNotDisturbCall:
            isDisplayNotDisturbCall ?? this.isDisplayNotDisturbCall,
        isDisplayNotDisturbIm:
            isDisplayNotDisturbIm ?? this.isDisplayNotDisturbIm,
        isEnableGuardian: isEnableGuardian ?? this.isEnableGuardian,
        isForceEvaluationInstruct:
            isForceEvaluationInstruct ?? this.isForceEvaluationInstruct,
        isMaskOpen: isMaskOpen ?? this.isMaskOpen,
        isMatchCallFree: isMatchCallFree ?? this.isMatchCallFree,
        isNewTppUsable: isNewTppUsable ?? this.isNewTppUsable,
        isOpenBroacasterInvitation:
            isOpenBroacasterInvitation ?? this.isOpenBroacasterInvitation,
        isOpenFlashChat: isOpenFlashChat ?? this.isOpenFlashChat,
        isOpenSpeechToText: isOpenSpeechToText ?? this.isOpenSpeechToText,
        isRandomUploadPaidEvents:
            isRandomUploadPaidEvents ?? this.isRandomUploadPaidEvents,
        isRearCamera: isRearCamera ?? this.isRearCamera,
        isReportFB: isReportFB ?? this.isReportFB,
        isReviewPkg: isReviewPkg ?? this.isReviewPkg,
        isShowAutoTranslate: isShowAutoTranslate ?? this.isShowAutoTranslate,
        isShowBroadcasterRank:
            isShowBroadcasterRank ?? this.isShowBroadcasterRank,
        isShowDeletedButton: isShowDeletedButton ?? this.isShowDeletedButton,
        isShowFlowInfo: isShowFlowInfo ?? this.isShowFlowInfo,
        isShowLP: isShowLP ?? this.isShowLP,
        isShowMatch: isShowMatch ?? this.isShowMatch,
        isShowMatchGender: isShowMatchGender ?? this.isShowMatchGender,
        isShowRookieGuide: isShowRookieGuide ?? this.isShowRookieGuide,
        isSilence: isSilence ?? this.isSilence,
        isSwitchClub: isSwitchClub ?? this.isSwitchClub,
        isSwitchExtraCategory:
            isSwitchExtraCategory ?? this.isSwitchExtraCategory,
        isSwitchIMIncentive: isSwitchIMIncentive ?? this.isSwitchIMIncentive,
        isSwitchIMLimit: isSwitchIMLimit ?? this.isSwitchIMLimit,
        isSwitchInstruct: isSwitchInstruct ?? this.isSwitchInstruct,
        isSwitchMultipleCall: isSwitchMultipleCall ?? this.isSwitchMultipleCall,
        isSwitchOneKeyFollow: isSwitchOneKeyFollow ?? this.isSwitchOneKeyFollow,
        isSwitchStrongGuide: isSwitchStrongGuide ?? this.isSwitchStrongGuide,
        lpDiscount: lpDiscount ?? this.lpDiscount,
        lpPromotionDiscount: lpPromotionDiscount ?? this.lpPromotionDiscount,
        officialBlacklistUserIds:
            officialBlacklistUserIds ?? this.officialBlacklistUserIds,
        payChannels: payChannels ?? this.payChannels,
        rechargeUserCallStaySecond:
            rechargeUserCallStaySecond ?? this.rechargeUserCallStaySecond,
        rechargeUserImStaySecond:
            rechargeUserImStaySecond ?? this.rechargeUserImStaySecond,
        reviewOfficialBlacklistUserIds: reviewOfficialBlacklistUserIds ??
            this.reviewOfficialBlacklistUserIds,
        storeReviews: storeReviews ?? this.storeReviews,
        tabType: tabType ?? this.tabType,
        timestamp: timestamp ?? this.timestamp,
        topOfficialUserIds: topOfficialUserIds ?? this.topOfficialUserIds,
        userInvitation: userInvitation ?? this.userInvitation,
        userMultipleLevel: userMultipleLevel ?? this.userMultipleLevel,
        userServiceAccountId: userServiceAccountId ?? this.userServiceAccountId,
        userWallCategorys: userWallCategorys ?? this.userWallCategorys,
        videoStreamCategory: videoStreamCategory ?? this.videoStreamCategory,
        visitorOfficialUserId:
            visitorOfficialUserId ?? this.visitorOfficialUserId,
        voiceToTextConfig: voiceToTextConfig ?? this.voiceToTextConfig,
        sayHiMaxCount: sayHiMaxCount ?? this.sayHiMaxCount,
        sayHiQuickPhrases: sayHiQuickPhrases ?? this.sayHiQuickPhrases,
        customList: customList,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['activityCategory'] = activityCategory;
    map['activityCategoryImageUrl'] = activityCategoryImageUrl;
    map['broadcasterFollowOfficialUserIds'] = broadcasterFollowOfficialUserIds;
    map['broadcasterWallRegions'] = broadcasterWallRegions;
    if (broadcasterWallTagList != null) {
      map['broadcasterWallTagList'] =
          broadcasterWallTagList?.map((v) => v.toJson()).toList();
    }
    map['broadcasterWallTags'] = broadcasterWallTags;
    if (clubSubTags != null) {
      map['clubSubTags'] = clubSubTags?.map((v) => v.toJson()).toList();
    }
    map['extraCategoryName'] = extraCategoryName;
    if (flashChatConfig != null) {
      map['flashChatConfig'] = flashChatConfig?.toJson();
    }
    map['freeUserCallStaySecond'] = freeUserCallStaySecond;
    map['freeUserImStaySecond'] = freeUserImStaySecond;
    if (genderMatchCoin != null) {
      map['genderMatchCoin'] = genderMatchCoin?.toJson();
    }
    map['imIncentiveBlacklistUserIds'] = imIncentiveBlacklistUserIds;
    map['imSessionBalance'] = imSessionBalance;
    map['imSessionBroadcasterIds'] = imSessionBroadcasterIds;
    map['initTab'] = initTab;
    map['isAutoAccept'] = isAutoAccept;
    map['isCallCameraClose'] = isCallCameraClose;
    map['isCallRearCamera'] = isCallRearCamera;
    map['isCloseCamera'] = isCloseCamera;
    map['isDisplayNotDisturbCall'] = isDisplayNotDisturbCall;
    map['isDisplayNotDisturbIm'] = isDisplayNotDisturbIm;
    map['isEnableGuardian'] = isEnableGuardian;
    map['isForceEvaluationInstruct'] = isForceEvaluationInstruct;
    map['isMaskOpen'] = isMaskOpen;
    map['isMatchCallFree'] = isMatchCallFree;
    map['isNewTppUsable'] = isNewTppUsable;
    map['isOpenBroacasterInvitation'] = isOpenBroacasterInvitation;
    map['isOpenFlashChat'] = isOpenFlashChat;
    map['isOpenSpeechToText'] = isOpenSpeechToText;
    map['isRandomUploadPaidEvents'] = isRandomUploadPaidEvents;
    map['isRearCamera'] = isRearCamera;
    map['isReportFB'] = isReportFB;
    map['isReviewPkg'] = isReviewPkg;
    map['isShowAutoTranslate'] = isShowAutoTranslate;
    map['isShowBroadcasterRank'] = isShowBroadcasterRank;
    map['isShowDeletedButton'] = isShowDeletedButton;
    map['isShowFlowInfo'] = isShowFlowInfo;
    map['isShowLP'] = isShowLP;
    map['isShowMatch'] = isShowMatch;
    map['isShowMatchGender'] = isShowMatchGender;
    map['isShowRookieGuide'] = isShowRookieGuide;
    map['isSilence'] = isSilence;
    map['isSwitchClub'] = isSwitchClub;
    map['isSwitchExtraCategory'] = isSwitchExtraCategory;
    map['isSwitchIMIncentive'] = isSwitchIMIncentive;
    map['isSwitchIMLimit'] = isSwitchIMLimit;
    map['isSwitchInstruct'] = isSwitchInstruct;
    map['isSwitchMultipleCall'] = isSwitchMultipleCall;
    map['isSwitchOneKeyFollow'] = isSwitchOneKeyFollow;
    map['isSwitchStrongGuide'] = isSwitchStrongGuide;
    map['lpDiscount'] = lpDiscount;
    map['lpPromotionDiscount'] = lpPromotionDiscount;
    map['officialBlacklistUserIds'] = officialBlacklistUserIds;
    map['payChannels'] = payChannels;
    map['rechargeUserCallStaySecond'] = rechargeUserCallStaySecond;
    map['rechargeUserImStaySecond'] = rechargeUserImStaySecond;
    map['reviewOfficialBlacklistUserIds'] = reviewOfficialBlacklistUserIds;
    map['store_reviews'] = storeReviews;
    map['tabType'] = tabType;
    map['timestamp'] = timestamp;
    map['topOfficialUserIds'] = topOfficialUserIds;
    if (userInvitation != null) {
      map['userInvitation'] = userInvitation?.toJson();
    }
    map['userMultipleLevel'] = userMultipleLevel;
    map['userServiceAccountId'] = userServiceAccountId;
    map['userWallCategorys'] = userWallCategorys;
    map['videoStreamCategory'] = videoStreamCategory;
    map['visitorOfficialUserId'] = visitorOfficialUserId;
    if (voiceToTextConfig != null) {
      map['voiceToTextConfig'] = voiceToTextConfig?.toJson();
    }
    map['sayHiMaxCount'] = sayHiMaxCount;
    map['sayHiQuickPhrases'] = sayHiQuickPhrases;
    if (customList != null) {
      map['customList'] = customList?.toJson();
    }
    return map;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
