import 'dart:async';

import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:untitled1/pages/see_video/widget/my_video_progress_bar.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:video_player/video_player.dart';


/// create: 2023/4/26
/// desc: 自定义播放UI
class DyVideoControls extends StatefulWidget {
   DyVideoControls({
    this.showPlayButton = false,
    Key? key,
  }) : super(key: key);

  final bool showPlayButton;
  bool isTapPlay = true;
  bool displayBufferingIndicator = false;
  @override
  State<StatefulWidget> createState() {
    return _MyVideoControlsState();
  }
}

class _MyVideoControlsState extends State<DyVideoControls> with SingleTickerProviderStateMixin {
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  Timer? _hideTimer;
  Timer? _initTimer;
  late var _subtitlesPosition = Duration.zero;
  bool _subtitleOn = false;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  Timer? _bufferingDisplayTimer;


  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;
  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          // if (_latestValue.isPlaying) {
          //   if (_displayTapped) {
          //     setState(() {
          //       notifier.hideStuff = true;
          //     });
          //   } else {
          //     _cancelAndRestartTimer();
          //   }
          // } else {
          //
          // }

          _playPause();

          setState(() {
            notifier.hideStuff = true;
          });
          _cancelAndRestartTimer();
        },
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              if (widget.displayBufferingIndicator)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              else
                _buildHitArea(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  _buildBottomBar(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final bool showPlayButton = controller.value.isPlaying ?  !notifier.hideStuff : true;
    return AnimatedOpacity(
      opacity:  (widget.displayBufferingIndicator || showPlayButton) ? 1.0: 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: 1.w,
        margin: EdgeInsets.only(bottom: 2.w),
        child: _buildProgressBar(),
      ),
    );
  }

  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton = controller.value.isPlaying ?  !notifier.hideStuff : true;

    return GestureDetector(
      onTap: () {
        _playPause();
        widget.isTapPlay = !widget.isTapPlay;
        setState(() {
          notifier.hideStuff = true;
        });
      },
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: CenterPlayButton(
          backgroundColor: Colors.black54,
          iconColor: Colors.white,
          isFinished: isFinished,
          isPlaying: controller.value.isPlaying,
          show: showPlayButton,
          onPressed: _playPause,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = true;
        });
      });
    }
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
        widget.isTapPlay = false;
        logger.d("测试视频：10");
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          logger.d("测试视频：14");
          controller.initialize().then((_) {
            controller.play();
            widget.isTapPlay = true;
            logger.d("测试视频：15");
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
          }
          logger.d("测试视频：12");
          controller.play();
          widget.isTapPlay = true;
        }
      }
    });
  }

  void _startHideTimer() {
    final hideControlsTimer = chewieController.hideControlsTimer.isNegative ? ChewieController.defaultHideControlsTimer : chewieController.hideControlsTimer;
    _hideTimer = Timer(hideControlsTimer, () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _bufferingTimerTimeout() {
    widget.displayBufferingIndicator = true;
    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (!mounted) return;

    // display the progress bar indicator only after the buffering delay if it has been set
    if (chewieController.progressIndicatorDelay != null) {
      if (controller.value.isBuffering) {
        _bufferingDisplayTimer ??= Timer(
          chewieController.progressIndicatorDelay!,
          _bufferingTimerTimeout,
        );
      } else {
        if (controller.value.position.inMilliseconds > 100) {
          _bufferingDisplayTimer?.cancel();
          _bufferingDisplayTimer = null;
          widget.displayBufferingIndicator = false;
        }else if (controller.value.isPlaying && !widget.displayBufferingIndicator) {
          widget.displayBufferingIndicator = true;
          setState(() {
          });
        }
      }
    } else {
      if (controller.value.position.inMilliseconds > 0) {
        widget.displayBufferingIndicator = false;
      }else if (controller.value.isPlaying && !widget.displayBufferingIndicator) {
        widget.displayBufferingIndicator = true;
        setState(() {
        });
      }
    }

    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar() {
    return MyVideoProgressBar(
      controller,
      onDragStart: () {
        setState(() {
          _dragging = true;
        });

        _hideTimer?.cancel();
      },
      onDragEnd: () {
        setState(() {
          _dragging = false;
        });

        _startHideTimer();
      },
      colors: chewieController.materialProgressColors ??
          ChewieProgressColors(
            playedColor: MyColor.grey565656,
            handleColor: MyColor.grey565656,
            bufferedColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            backgroundColor: MyColor.blank22.withValues(alpha: 0.54),
          ),
    );
  }
}
