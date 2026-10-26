import 'dart:async';
import 'dart:developer';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/web_view/utils/js_channel.dart';
import 'package:untitled1/pages/web_view/utils/run_javascript.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config/route_observer.dart';
import '../../event_bus/video_call/video_call_event.dart';
import '../../res/video_call_data.dart';
import '../../js/rc_manager_js.dart';
import '../../utils/bh_platform.dart';
import '../../utils/launch_util.dart';
import 'logic.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// WebView页
class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  static Future onJump({
    required String url,
    String? title,
    bool isCanMultiWindow = true,
    int itemType = 0,
  }) async {
    if (BHPlatform.isWeb) {
      // web
      try {
        await JSRongCloudManager.myBrowser(url, 0,itemType);
        return;
      } catch (e) {}

      //打开新的网页
      html.window.open(url, title ?? "");
      return;
    }
    //打开新的网页
      // html.window.open(url, title ?? "");
      // return;
    return await Get.toNamed(RoutePath.webViewPage, preventDuplicates: false, arguments: {
      "url": url,
      if (title != null && title.isNotEmpty) "title": title,
      "isCanMultiWindow": isCanMultiWindow,
    });
  }

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with RouteAware {
  final logic = Get.find<WebViewLogic>();

  WebViewController? controller;

  String url = "";

  String title = "";
  bool isCanMultiWindow = false;

  /// 充值成功event
  StreamSubscription<RechargeSuccessEvent>? _event;

  StreamSubscription<VideoCallEvent>? _videoEvent;

  int progress = 0;
  late PlatformWebViewController _webController;
  @override
  void initState() {
    if (Get.arguments != null) {
      Map<String, dynamic> map = Get.arguments;
      if (map.containsKey("title")) title = map['title'];
      if (map.containsKey("url")) url = map['url'];
      if (map.containsKey("isCanMultiWindow")) {
        isCanMultiWindow = map['isCanMultiWindow'] ?? false;
      }
      if (url.startsWith("http")) {
        if (kIsWeb) {
          _webController = PlatformWebViewController(
            const PlatformWebViewControllerCreationParams(),
          )..loadRequest(
              LoadRequestParams(
                uri: Uri.parse(url),
              ),
            );
        } else {
          _onInitController();
        }
      } else {
        title = "error";
      }
    }
    _event = EventBusUtil.listen<RechargeSuccessEvent>((event) async {
      if (kIsWeb) {
      } else {
        // 充值成功，刷新当前页面的金币数
        await controller?.runJavaScript("HttpTool.NativeToJs('recharge')");
      }
    });
    _videoEvent = EventBusUtil.listen<VideoCallEvent>((event) {
      if (event.command == SocketCommandKey.onHangUp) {
        if (kIsWeb) {
        } else {
//如果收到挂断关闭键盘
          controller?.runJavaScript('document.activeElement.blur();');
        }
      }
    });
    super.initState();
  }

  void _onInitController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (urlChange) {
            log("URL=> ${urlChange.url}");
          },
          onProgress: (progress) {
            this.progress = progress;
            if (mounted) {
              setState(() {});
            }
          },
          onPageFinished: (String url) async {
            // String? title = await controller?.getTitle();
            // if (title != null && this.title.isEmpty && !title.startsWith("http")) {
            //   this.title = title;
            //   if (mounted) {
            //     setState(() {});
            //   }
            // }
            try {
              String script =
                  RunJavaScript.getInitWebView(JsChannel().getSupportApi());
              await controller?.runJavaScript(script);
              String script2 = RunJavaScript.setJsApiWithGetSupportApi(
                  JsChannel().getSupportApi());
              await controller?.runJavaScript(script2);
            } catch (e) {
              logger.e("evaluating JavaScript has error: $e");
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (!request.url.startsWith("http")) {
              try {
                // launchUrl可以打开 intent url 和 scheme. url
                if (mounted) {
                  LaunchUtil.launchJump(url: request.url);
                }
              } catch (e) {
                Toast.showMsg("error_unableToLaunch".bhTR);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    JsChannel()
      ..newTppClose(controller!)
      ..openVipService(controller!)
      ..newTppLogEvent(controller!)
      ..recharge(controller!)
      ..rechargeSource(controller!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // 回到当前页
    if (isCanMultiWindow) {
      if (kIsWeb) {
      } else {
        controller?.loadRequest(Uri.parse(url));
      }
    }

    super.didPopNext();
  }

  @override
  void didPushNext() {
    if (isCanMultiWindow) {
      if (kIsWeb) {
      } else {
        controller?.loadRequest(Uri.parse("about:blank"));
      }
    }
    super.didPushNext();
  }

  @override
  void dispose() {
    _event?.cancel();
    _videoEvent?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? webView;

    if (kIsWeb) {
      webView = Container(
        child: PlatformWebViewWidget(
          PlatformWebViewWidgetCreationParams(controller: _webController),
        ).build(context),
      );
    } else {
      Column(
        children: [
          if (progress != 100)
            LinearProgressIndicator(
              value: progress / 100,
              color: Colors.blue,
            ),
          if (controller != null)
            Expanded(
              child: WebViewWidget(
                controller: controller!,
              ),
            ),
          if (controller == null)
            Center(
              child: Text(
                "error_invalidLink".bhTR,
                style: TextStyle(
                  color: MyColor.black,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: () async {
        bool canBack = await controller?.canGoBack() ?? false;
        if (!canBack) {
          Get.back();
        }
        return false;
      },
      child: GradientBackgroundWidget(
        child: Scaffold(
          backgroundColor: MyColor.appBackground,
          appBar: DefaultAppBar(title: title),
          body: Container(
            color: Colors.white,
            child: SafeArea(
              child: webView!, // Provide default value to avoid null error
            ),
          ),
        ),
      ),
    );
  }
}
