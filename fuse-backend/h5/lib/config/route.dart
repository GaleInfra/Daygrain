import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/pages/flash_chat/match_connect/binding.dart';
import 'package:untitled1/pages/flash_chat/match_connect/view.dart';
import 'package:untitled1/pages/index/binding.dart';
import 'package:untitled1/pages/index/view.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/pages/mine/about/binding.dart';
import 'package:untitled1/pages/mine/about/view.dart';
import 'package:untitled1/pages/mine/blocked/binding.dart';
import 'package:untitled1/pages/mine/blocked/view.dart';
import 'package:untitled1/pages/mine/coin_store/binding.dart';
import 'package:untitled1/pages/mine/coin_store/view.dart';
import 'package:untitled1/pages/mine/modify_info/binding.dart';
import 'package:untitled1/pages/mine/modify_info/page/country_select_page.dart';
import 'package:untitled1/pages/mine/modify_info/view.dart';
import 'package:untitled1/pages/mine/my_level/my_level_binding.dart';
import 'package:untitled1/pages/mine/my_level/my_level_page.dart';
import 'package:untitled1/pages/mine/setting/binding.dart';
import 'package:untitled1/pages/mine/setting/view.dart';
import 'package:untitled1/pages/report/view.dart';
import 'package:untitled1/pages/report/report_detail/view.dart';
import 'package:untitled1/pages/robot/binding.dart';
import 'package:untitled1/pages/robot/view.dart';

import 'package:untitled1/pages/see_video/binding.dart';
import 'package:untitled1/pages/see_video/view.dart';
import 'package:untitled1/pages/video_call/on_call/binding.dart';
import 'package:untitled1/pages/video_call/on_call/view.dart';
import 'package:untitled1/pages/video_call/video_call/binding.dart';
import 'package:untitled1/pages/video_call/video_call/view.dart';
// import 'package:untitled1/pages/vip/vip_binding.dart';
// import 'package:untitled1/pages/vip/vip_page.dart';
import 'package:untitled1/pages/vip/vip_privileges_binding.dart';
import 'package:untitled1/pages/vip/vip_privileges_page.dart';
import 'package:untitled1/pages/web_view/binding.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/pages/welcome/binding.dart';
import 'package:untitled1/pages/welcome/view.dart';
import 'package:untitled1/pages/see_image/see_image_page.dart';

import '../bh_will_popscope_root_widget.dart';
import '../common_logic/user_status_service.dart';
import '../pages/broadcaster/ranking/binding.dart';
import '../pages/broadcaster/ranking/view.dart';
import '../pages/flash_chat/start_match/binding.dart';
import '../pages/flash_chat/start_match/view.dart';
import '../pages/language/view.dart';
import '../pages/video_call/call/binding.dart';
import '../pages/video_call/call/view.dart';
import '../res/my_keys.dart';
import '../utils/sp_util.dart';

import 'package:untitled1/pages/c_page/view.dart';

/// create: 2023/4/23
/// desc: 路由管理
class Routes {
  static final routePages = <GetPage>[
    GetPage(
      name: RoutePath.welcomePage,
      page: () => WelcomePage(),
      binding: WelcomeBinding(),
      transitionDuration: Duration.zero,
      transition: null,
    ),
    GetPage(
      name: RoutePath.indexPage,
      page: () => const BHWillPopScopeRootWidget(
        isRootRoute: true,
        child: IndexPage(),
      ),
      binding: IndexBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.rankingPage,
      page: () => RankingPage(),
      binding: RankingBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.broadcasterDetailPage,
      page: () => const BroadcasterDetailPage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
        NoParamsMiddleware(priority: 2),
      ],
    ),
    GetPage(
      name: RoutePath.seeImagePage,
      page: () => const SeeImagePage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
        NoParamsMiddleware(priority: 2),
      ],
    ),
    GetPage(
      name: RoutePath.seeVideoPage,
      page: () => SeeVideoPage(),
      binding: SeeVideoBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
        NoParamsMiddleware(priority: 2),
      ],
    ),
    GetPage(
      name: RoutePath.messageChatPage,
      page: () => const MessageChatPage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
        NoParamsMiddleware(priority: 2),
      ],
    ),
    GetPage(
      name: RoutePath.callPage,
      page: () => const CallPage(),
      binding: CallBinding(),
      // transition: Transition.downToUp,
      transition: Transition.fade,
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.onCallPage,
      page: () => OnCallPage(),
      binding: OnCallBinding(),
      transition: Transition.fade,
      // transition: Transition.downToUp,
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.videoCallPage,
      page: () => const VideoCallPage(),
      binding: VideoCallBinding(),
      transition: Transition.fade,
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.modifyInfoPage,
      page: () => ModifyInfoPage(),
      binding: ModifyInfoBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.selectCountryPage,
      page: () => const CountrySelectPage(),
    ),
    GetPage(
      name: RoutePath.aboutPage,
      page: () => AboutPage(),
      binding: AboutBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.robotPage,
      page: () => const RobotPage(),
      showCupertinoParallax: false,
      binding: RobotBinding(),
    ),
    GetPage(
      name: RoutePath.blockedPage,
      page: () => BlockedPage(),
      showCupertinoParallax: false,
      binding: BlockedBinding(),
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.settingPage,
      page: () => SettingPage(),
      showCupertinoParallax: false,
      binding: SettingBinding(),
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.coinStorePage,
      page: () => CoinStorePage(),
      binding: CoinStoreBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.webViewPage,
      page: () => const WebViewPage(),
      showCupertinoParallax: false,
      binding: WebViewBinding(),
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
        NoParamsMiddleware(priority: 2),
      ],
    ),
    GetPage(
      name: RoutePath.startMatchPage,
      page: () => const StartMatchPage(),
      binding: StartMatchBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.matchConnectPage,
      page: () => MatchConnectPage(),
      binding: MatchConnectBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.vipPrivilegesPage,
      page: () => VipPrivilegesPage(),
      binding: VipPrivilegesBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.myLevelPage,
      page: () => MyLevelPage(),
      binding: MyLevelBinding(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.languagePage,
      page: () => const LanguagePage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.cPage,
      page: () => const CPage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.reportPage,
      page: () => ReportPage(),
      showCupertinoParallax: false,
      middlewares: [
        LoginMiddleware(priority: 0),
        InitMiddleware(priority: 1),
      ],
    ),
    GetPage(
      name: RoutePath.reportDetailPage,
      page: () => const ReportDetailPage(),
    ),
  ];
}

class RoutePath {
  /// 测试页
  static const String testPage = "/testPage";

  /// 欢迎页
  static const String welcomePage = "/welcomePage";

  /// 登录页
  static const String loginPage = "/loginPage";

  /// 主页
  static const String indexPage = "/IndexPage";

  /// 排行榜
  static const String rankingPage = "/rankingPage";

  /// 主播资料页
  static const String broadcasterDetailPage = "/broadcasterDetailPage";

  /// 全屏看图
  static const String seeImagePage = "/seeImagePage";

  /// 全屏看视频
  static const String seeVideoPage = "/seeVideoPage";

  /// 私聊页
  static const String messageChatPage = "/messageChatPage";

  /// 视频通话-呼叫页
  static const String callPage = "/callPage";

  /// 视频通话-被呼叫页
  static const String onCallPage = "/onCallPage";

  /// 视频通话-视频通话页
  static const String videoCallPage = "/videoCallPage";

  /// 我的-修改个人资料页
  static const String modifyInfoPage = "/modifyInfoPage";

  /// 我的-修改个人资料页
  static const String selectCountryPage = "/selectCountryPage";

  /// 我的-关于页
  static const String aboutPage = "/aboutPage";

  /// 我的-机器人
  static const String robotPage = "/robotPage";

  /// 我的-黑名单列表页
  static const String blockedPage = "/blockedPage";

  /// 我的-设置页
  static const String settingPage = "/settingPage";

  /// 我的-金币充值页
  static const String coinStorePage = "/coinStorePage";

  /// webView页
  static const String webViewPage = "/webViewPage";

  /// 开始匹配页
  static const String startMatchPage = "/startMatchPage";

  /// 匹配连接页
  static const String matchConnectPage = "/matchConnectPage";

  /// VIP订阅页
  static const String vipPage = "/vipPage";

  /// VIP权限页
  static const String vipPrivilegesPage = "/vipPrivilegesPage";

  /// 个人等级页
  static const String myLevelPage = "/myLevelPage";

  ///多语言切换页
  static const String languagePage = "/languagePage";

  /// C页面
  static const String cPage = "/cPage";

  /// 举报页面
  static const String reportPage = "/report_page";

  /// 举报详情页面
  static const String reportDetailPage = "/report_detail";
}

//拦截器
//未登录Gex拦截器
class LoginMiddleware extends GetMiddleware {
  LoginMiddleware({super.priority});
  @override
  RouteSettings? redirect(String? route) {
    if (!SPUtil.containsKey(MyKeys.token)) {
      return const RouteSettings(name: RoutePath.welcomePage);
    }
    return null;
  }
}

//拦截未初始化就进入其他页面
class InitMiddleware extends GetMiddleware {
  InitMiddleware({super.priority});
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<UserStatusService>()) {
      return const RouteSettings(name: RoutePath.welcomePage);
    }
    return null;
  }
}

//没有传参拦截器退回首页
class NoParamsMiddleware extends GetMiddleware {
  NoParamsMiddleware({super.priority});
  @override
  RouteSettings? redirect(String? route) {
    // if (Get.arguments == null) {
    //   return const RouteSettings(name: RoutePath.indexPage);
    // }
    return null;
  }
}
