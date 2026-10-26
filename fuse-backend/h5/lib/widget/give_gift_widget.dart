import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class GiveGiftWidget extends StatefulWidget {
  const GiveGiftWidget({
    Key? key,
    required this.onEnd,
    required this.giftImage,
  }) : super(key: key);

  final void Function(String key) onEnd;
  final String giftImage;

  @override
  State<GiveGiftWidget> createState() => _GiveGiftWidgetState();
}

class _GiveGiftWidgetState extends State<GiveGiftWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  double vWidth = 130.w;
  double imageWidth = 60.w;

  @override
  void initState() {
    super.initState();
    // 提前缓存图片，减少首帧开销
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage(ImageAssets.goldenLight), context);
      precacheImage(AssetImage(widget.giftImage), context);
    });

    if (!kIsWeb) {
      _rotationController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      );
      _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
        CurvedAnimation(parent: _rotationController, curve: Curves.linear),
      );
      _rotationController.repeat();
    }

    // 停止动画 + 回调
    Future.delayed(const Duration(seconds: 3), () {
      
      widget.onEnd.call((widget.key as ValueKey<String>).value);
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _rotationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: vWidth,
              height: vWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (kIsWeb)
                    WebRotatingImage(
                      imageUrl: ImageAssets.goldenLight,
                      width: vWidth,
                      height: vWidth,
                    )
                  else
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        ImageAssets.goldenLight,
                        width: vWidth,
                        height: vWidth,
                      ),
                    ),
                  
                  Image.asset(
                    widget.giftImage,
                    width: imageWidth,
                    height: imageWidth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class WebRotatingImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final String viewType;
  const WebRotatingImage({Key? key, required this.imageUrl, required this.width, required this.height, String? viewType})
      : viewType = viewType ?? 'goldenLightViewType',
        super(key: key);

  @override
  State<WebRotatingImage> createState() => _WebRotatingImageState();
}

class _WebRotatingImageState extends State<WebRotatingImage> {
  static bool _cssInjected = false;
  static int _viewTypeCounter = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = '${widget.viewType}_${_viewTypeCounter++}';
    if (!_cssInjected) {
      final style = html.StyleElement()
        ..innerHtml = '''
        @-webkit-keyframes rotate360 { from { -webkit-transform: rotate(0deg); } to { -webkit-transform: rotate(360deg); } }
        @keyframes rotate360 { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .rotate360 {
          -webkit-animation: rotate360 3s linear infinite;
          animation: rotate360 3s linear infinite;
          display: block;
          margin: 0 auto;
          object-fit: contain;
        }
      ''';
      html.document.head!.append(style);
      _cssInjected = true;
    }
    // 只注册一次 viewType
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = "./assets/assets/images/message/golden_light.webp"
        ..width = widget.width.toInt()
        ..height = widget.height.toInt()
        ..className = 'rotate360';
      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}