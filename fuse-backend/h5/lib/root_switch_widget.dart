
// GlobalKey<RootSwitchWidgetState> switchKey = GlobalKey<RootSwitchWidgetState>();

// /// desc: 根页面切换组件，使用这个的原因是ScreenUtilInit的designSize不一致，当初没有确定，B面用小了
// class RootSwitchWidget extends StatefulWidget {
//   const RootSwitchWidget({
//     Key? key,
//     required this.checkBuilder,
//     required this.contentBuilder,
//   }) : super(key: key);

//   /// 策略widget
//   final Widget Function() checkBuilder;

//   /// 内容widget
//   final Widget Function() contentBuilder;

//   /// 登录成功跳转
//   static void loginSuccess() {
//     switchKey.currentState?.onLoginSuccess();
//   }

//   /// 退出登录
//   static void logout() {
//     switchKey.currentState?.onLogout();
//   }

//   @override
//   State<RootSwitchWidget> createState() => RootSwitchWidgetState();
// }

// class RootSwitchWidgetState extends State<RootSwitchWidget> {
//   bool _switch = false;

//   Future onLoginSuccess() async {
//     // 切换前清除根内容
//     Get.clearRouteTree();
//     Get.clearTranslations();
//     Get.resetRootNavigator();
//     _switch = true;
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   Future onLogout() async {
//     // 切换前清除根内容
//     Get.clearRouteTree();
//     Get.clearTranslations();
//     Get.resetRootNavigator();
//     _switch = false;
//     if (mounted) {
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_switch) {
//       return widget.contentBuilder.call();
//     } else {
//       return widget.checkBuilder.call();
//     }
//   }
// }
