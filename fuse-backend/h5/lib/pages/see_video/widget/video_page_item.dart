import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/see_video/logic.dart';
import 'package:untitled1/pages/see_video/widget/my_video_controls.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../event_bus/base/event_bus_util.dart';
import '../../../event_bus/video_call/video_call_event.dart';
import '../../../event_bus/bgm_event.dart';

/// create: 2023/4/26
/// desc:
class VideoPageItem extends StatefulWidget {
  const VideoPageItem({
    Key? key,
    required this.url,
    required this.thumUrl,
    required this.index,
  }) : super(key: key);

  /// 当前链接
  final String url;

  final String thumUrl;

  /// 当前页所在索引
  final int index;

  @override
  State<VideoPageItem> createState() => _VideoPageItemState();
}

class _VideoPageItemState extends State<VideoPageItem> with AutomaticKeepAliveClientMixin, RouteAware {
  late VideoPlayerController videoPlayerController;
  ChewieController? controller;
  final logic = Get.find<SeeVideoLogic>();
  StreamSubscription<VideoCallEvent>? _event;
  StreamSubscription? _bgmEventSub;

  bool calling = false;

  Worker? videoWork;

  var tips = "";

  /// 控制器已就绪，可展示 [Chewie]（与是否播放分离，避免 loading 时先出声）
  bool _showPlayer = false;

  bool _listenerAttached = false;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    onInit();
    // 监听Swiper索引的改变
    videoWork = ever(
      logic.index,
      (_) => _syncPlayback(),
      condition: () => true,
    );
    // 视频通话监听
    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      // if (event.command == SocketCommandKey.onCall) {
      // 来电呼叫，暂停播放
      calling = true;
      _syncPlayback(forcePause: true);
      // }
    });

    // 背景音乐控制：机器人全屏电话弹窗出现/关闭时暂停/恢复本视频
    _bgmEventSub = EventBusUtil.listen((event) {
      try {
        if (event is BGMPauseEvent) {
          _syncPlayback(forcePause: true);
        } else if (event is BGMResumeEvent) {
          _syncPlayback();
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    controller?.pause();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    controller?.pause();
    super.didPushNext();
  }

  Future onInit() async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    tips = "status_connecting".bhTR;
    try {
      await videoPlayerController.initialize();
    } catch (_) {
      if (_isActive) {
        tips = "error_network".bhTR;
        setState(() {});
      }
      return;
    }
    if (!_isActive) {
      return;
    }
    controller = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: false,
      looping: true,
      customControls: const MyVideoControls(showPlayButton: true),
      showControls: true,
      // showOptions: false,
    );
    videoPlayerController.addListener(_onVideoStateChanged);
    _listenerAttached = true;
    if (!_isActive) {
      _releasePlayer();
      return;
    }
    setState(() {
      tips = "";
      _showPlayer = true;
    });
    _syncPlayback();
  }

  bool get _isActive => mounted && !_disposed;

  void _releasePlayer() {
    if (_listenerAttached) {
      videoPlayerController.removeListener(_onVideoStateChanged);
      _listenerAttached = false;
    }
    controller?.dispose();
    controller = null;
  }

  /// 仅当前 Swiper 页且未在通话中才播放，避免后台页或 loading 阶段先出声
  void _syncPlayback({bool forcePause = false}) {
    if (!_isActive || controller == null) {
      return;
    }
    if (!videoPlayerController.value.isInitialized) {
      return;
    }
    final shouldPlay =
        !forcePause && !calling && logic.index.value == widget.index;
    if (shouldPlay) {
      controller!.play();
    } else {
      controller!.pause();
    }
  }

  void _onVideoStateChanged() {
    if (!_isActive) {
      return;
    }
    if (videoPlayerController.value.hasError) {
      tips = "error_network".bhTR;
      _showPlayer = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (tips.isNotEmpty) {
      return Stack(
        children: [
          Center(
            child: MyExtendedNetworkImage(
              url: widget.thumUrl,
              key: ValueKey("image_${widget.thumUrl}"),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fitWidth,
              isAnimation: false,
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        ],
      );
    }

    if (_showPlayer &&
        controller != null &&
        controller!.videoPlayerController.value.isInitialized) {
      return Chewie(
        controller: controller!,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _disposed = true;
    videoWork?.dispose();
    videoWork = null;
    _releasePlayer();
    videoPlayerController.dispose();
    _event?.cancel();
    _event = null;
    _bgmEventSub?.cancel();
    _bgmEventSub = null;
    routeObserver.unsubscribe(this);
    super.dispose();
  }
}
