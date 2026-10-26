import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../res/image_assets.dart';

/// 自定义轮播组件，实现中间突出显示、左右部分可见的卡片效果
class CarouselWidget extends StatefulWidget {
  const CarouselWidget({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 300),
    this.width,
    this.height = 200.0,
    this.centerItemScale = 1.0,
    this.sideItemScale = 0.9,
    this.sideItemOpacity = 0.6,
    this.borderRadius = 12.0,
    this.viewportFraction = 0.7,
  }) : super(key: key);

  /// 数据列表
  final List<dynamic> items;

  /// 构建每个卡片的回调
  final Widget Function(dynamic item, int index) itemBuilder;

  /// 是否自动播放
  final bool autoPlay;

  /// 自动播放间隔时间
  final Duration autoPlayInterval;

  /// 动画持续时间
  final Duration animationDuration;

  /// 组件高度
  final double height;

  /// 中心卡片缩放比例
  final double centerItemScale;

  /// 侧边卡片缩放比例
  final double sideItemScale;

  /// 侧边卡片透明度
  final double sideItemOpacity;


  /// 边框圆角
  final double borderRadius;

  /// 视口比例
  final double viewportFraction;

  /// 组件宽度
  final double? width;

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  bool _isVisible = true;
  
  // 无限轮播相关
  static const int _infiniteCount = 1000000; // 一个很大的数字
  late int _initialPage;

  @override
  void initState() {
    super.initState();
    // 计算初始页面，让它在中间位置，这样可以向左右无限滑动
    _initialPage = (_infiniteCount ~/ 2) - ((_infiniteCount ~/ 2) % widget.items.length);
    
    // 设置初始的当前索引
    _currentIndex = _initialPage % widget.items.length;
    
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: _initialPage,
    );
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (!widget.autoPlay || widget.items.length <= 1) return;
    
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_isVisible && mounted && _pageController.hasClients) {
        _nextPage();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _nextPage() {
    if (mounted && _pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? _initialPage;
      _pageController.animateToPage(
        currentPage + 1,
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _animateToPage(int index) {
    if (mounted && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _isVisible = info.visibleFraction > 0.5;
    if (_isVisible) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  Widget _buildCard(dynamic item, int index, double scale, double opacity) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w ,vertical: 6.w),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: widget.itemBuilder(item, index),
        ),
      ),
    );
  }

  /// 计算卡片的缩放和透明度，基于页面偏移量实现平滑过渡
  Map<String, double> _calculateCardProperties(int pageIndex) {
    if (!_pageController.hasClients) {
      return {
        'scale': widget.sideItemScale,
        'opacity': widget.sideItemOpacity,
      };
    }

    final currentPage = _pageController.page ?? _initialPage.toDouble();
    final offset = (pageIndex - currentPage).abs();
    
    // 当偏移量为0时，是中心卡片
    // 当偏移量为1时，是侧边卡片
    // 使用插值函数实现平滑过渡
    final t = (1.0 - offset.clamp(0.0, 1.0));
    
    final scale = ui.lerpDouble(widget.sideItemScale, widget.centerItemScale, t) ?? widget.sideItemScale;
    final opacity = ui.lerpDouble(widget.sideItemOpacity, 1.0, t) ?? widget.sideItemOpacity;
    
    return {
      'scale': scale,
      'opacity': opacity,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.height);
    }

    // 如果只有一个项目，不需要无限轮播
    if (widget.items.length == 1) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: _buildCard(widget.items[0], 0, widget.centerItemScale, 1.0),
        ),
      );
    }

    return VisibilityDetector(
      key: const ValueKey('carousel_widget'),
      onVisibilityChanged: _onVisibilityChanged,
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return PageView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    itemCount: _infiniteCount,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        _currentIndex = pageIndex % widget.items.length;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      final realIndex = pageIndex % widget.items.length;
                      final item = widget.items[realIndex];
                      
                      // 根据页面偏移量计算卡片的缩放和透明度
                      final cardProperties = _calculateCardProperties(pageIndex);
                      final scale = cardProperties['scale']!;
                      // final opacity = cardProperties['opacity']!;
                      
                      return _buildCard(item, realIndex, scale, 1);
                    },
                  );
                },
              ),
            ),
            // 固定的匹配框图片
            Center(
              child: IgnorePointer(
                child: SizedBox(
                  width: (widget.width ?? Get.width * widget.viewportFraction + 6.w),
                  height: widget.height + 4.w,
                  child: Image.asset(
                    ImageAssets.matchFrame,
                    width: (Get.width * widget.viewportFraction + 4.w),
                    height: widget.height + 4.w,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}