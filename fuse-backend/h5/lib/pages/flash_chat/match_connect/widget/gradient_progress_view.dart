import 'package:flutter/material.dart';

class GradientProgressView extends StatefulWidget {
  final List<Color> progressColors;
  final double progressCornerRadius;
  final Color backgroundColor;
  final bool isRightToLeft;
  final double progress;
  final Duration animationDuration;
  final Function(double progress)? onProgressUpdate;
  final double height;
  final EdgeInsets padding;

  const GradientProgressView({
    Key? key,
    required this.progressColors,
    this.progressCornerRadius = 0,
    this.backgroundColor = Colors.white,
    this.isRightToLeft = false,
    this.progress = 1.0,
    this.animationDuration = const Duration(milliseconds: 2500),
    this.onProgressUpdate,
    this.height = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 34),
  }) : super(key: key);

  @override
  State<GradientProgressView> createState() => _GradientProgressViewState();
}

class _GradientProgressViewState extends State<GradientProgressView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))..addListener(() {
      setState(() {
        _currentProgress = _animation.value;
        widget.onProgressUpdate?.call(_currentProgress);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(GradientProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  void reset() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.progressCornerRadius),
          child: Container(
            color: widget.backgroundColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // 底层完整进度条（静态）
                    Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.progressColors,
                          begin: widget.isRightToLeft 
                              ? Alignment.centerRight 
                              : Alignment.centerLeft,
                          end: widget.isRightToLeft 
                              ? Alignment.centerLeft 
                              : Alignment.centerRight,
                        ),
                      ),
                    ),
                    // 白色遮罩层（动画）
                    Positioned(
                      left: widget.isRightToLeft ? 0 : null,
                      right: widget.isRightToLeft ? null : 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: constraints.maxWidth * (1 - _currentProgress),
                        color: widget.backgroundColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}