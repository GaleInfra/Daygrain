import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/video_call/video_call_event.dart';
import 'package:untitled1/model/infoflow/info_flow_model.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/dy_video_controls.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/logic.dart';
import 'package:untitled1/pages/index/logic.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/event_bus/bgm_event.dart';

typedef viewRefreshBack = void Function();

class DyVideoHandleModel {
  DyVideoHandleModel({required this.item, required this.itemIndex}) {
    onInit();
  }
  final int itemIndex;
  final InfoFlowModel item;
  viewRefreshBack? viewRefresh;
  Rx<InfoFlowModel?> currentItem = Rx<InfoFlowModel?>(null);
  AppConfigManager? appConfig;

  VideoPlayerController? videoPlayerController;
  ChewieController? controller;
  final logic = Get.find<DyScaleVideoLogic>();
  StreamSubscription<VideoCallEvent>? _event;
  bool isDispose = false;
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleStateEvent;
  StreamSubscription? _bgmEventSub;
  bool calling = false;
  bool isAutoPlaying = false;

  Worker? videoWork;
  Worker? indexTabWork;
  var tips = "";
  final isVideoInitialized = false.obs;
  bool _isInitializing = false;
  //当前销毁状态
  bool isDisposed = false;
  bool isDelay = false;
  DyVideoControls? _dyVideoControls;
  bool isVideoPage = true;
  Future<void> initializeVideo() async {
    isAutoPlaying = logic.index.value == itemIndex;
    isDisposed = false;
    isDispose = false;
    if (isVideoInitialized.value && videoPlayerController == null) {
      dispose();
      isVideoInitialized.value = false;
    }
    if (isVideoInitialized.value || _isInitializing || isDispose) return;
    try{
      _isInitializing = true;
      setupEventListeners();
      final videoPlayerOptions = VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      );
      videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(item.videoPaths?.first.mediaUrl ?? ""),
          videoPlayerOptions: videoPlayerOptions,
          formatHint: VideoFormat.dash);
      videoPlayerController?.setLooping(true);
      videoPlayerController?.addListener(_onVideoStateChanged);
      if (logic.index.value == itemIndex) {
        if (viewRefresh != null) {
          viewRefresh!();
        }
      }

      await videoPlayerController?.initialize().then((_){
        Future.delayed(const Duration(seconds: 2), () {
          if (!isVideoPage && !isAutoPlaying) {
            videoPlayerController?.pause();
          }else {
            videoPlayerController?.play();
          }
        });
      });

      if (controller == null) {
        _dyVideoControls = DyVideoControls();
        controller = ChewieController(
          videoPlayerController: videoPlayerController!,
          autoPlay: false,
          looping: true,
          customControls: _dyVideoControls,
          showControls: true,
          allowFullScreen: true,
          allowMuting: true,
          allowPlaybackSpeedChanging: true,
          autoInitialize: true,
          showControlsOnInitialize: true,
        );
      }

      _isInitializing = false;
      isDispose = false;
      if (isDisposed) {
        dispose();
        return;
      }
      if (logic.index.value == itemIndex) {
        if (viewRefresh != null) {
          viewRefresh!();
        }
      }

    }catch(e){
      videoPlayerController?.pause();
    }

  }

  void disposeVideo() {
    isDisposed = true;
    if (!isVideoInitialized.value) return;
    isDispose = true;
    isVideoInitialized.value = false;
    if (controller != null) {
      controller?.pause();
      controller?.dispose();
      controller = null;
    }
    if (videoPlayerController != null) {
      videoPlayerController?.pause();
      videoPlayerController?.dispose();
      videoPlayerController = null;
    }

  }

  void openWakelock() async {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!kIsWeb) await WakelockPlus.enable();
    });
  }

  void _onVideoStateChanged() {
    try{
      if (videoPlayerController == null) return;
      if (videoPlayerController!.value.hasError) {
        // Video has finished loading
        logger.d(
            "测试视频：3-- ${videoPlayerController?.value} -- ${videoPlayerController?.value.position.inMilliseconds}--${logic.index.value} -- $itemIndex");
        dispose();
        onInit();
        initializeVideo();
        // tips = "error_network".bhTR;
        if (logic.index.value == itemIndex) {
          if (viewRefresh != null) {
            viewRefresh!();
          }
        }
      } else if (videoPlayerController!.value.isBuffering) {
        // Video has started playing
        // if (!isAutoPlaying) {
        //   controller?.pause();
        // }
        logger.d(
            "测试视频：1-- ${videoPlayerController?.value} -- ${videoPlayerController?.value.position.inMilliseconds}-${logic.index.value} -- $itemIndex");
        if (!isVideoPage) {
          videoPlayerController?.pause();
        }
      } else if (videoPlayerController!.value.isPlaying) {

        if (videoPlayerController == null) return;


        if (!isVideoInitialized.value) {
          isVideoInitialized.value = true;
        }
        if (!isVideoPage || !isAutoPlaying) {
          videoPlayerController?.pause();
        }

        logger.d(
            "测试视频：2 -- ${videoPlayerController?.value} -- ${videoPlayerController?.value.position.inMilliseconds}--${logic.index.value} -- $itemIndex");

        if (!isAutoPlaying) {
          // videoPlayerController?.pause();
          if (videoPlayerController!.value.position.inMilliseconds > 0) {
            if(!isDelay) {
              isDelay = true;
              Future.delayed(const Duration(seconds: 1), () {
                if ((!isVideoPage || !isAutoPlaying) &&
                    videoPlayerController!.value.position.inMilliseconds > 0) {
                  videoPlayerController?.pause();
                }
              });
            }
          }
          logger.d("测试视频：5 -- ${logic.index.value} -- $itemIndex");
        } else if (isAutoPlaying &&
            videoPlayerController!.value.position.inMilliseconds > 0) {
          videoPlayerController?.play();
          if(!isDelay) {
            isDelay = true;
            Future.delayed(const Duration(seconds: 2), () {
              if (isAutoPlaying &&
                  videoPlayerController!.value.position.inMilliseconds > 0 && _dyVideoControls?.isTapPlay == true && isVideoPage) {
                videoPlayerController?.play();
                logger.d("测试视频：17 -- ${logic.index.value} -- $itemIndex");
              }else {
                videoPlayerController?.pause();
                logger.d("测试视频：18 -- ${logic.index.value} -- $itemIndex");
              }
            });
          }
        }else {
          if (!isVideoPage) {
            videoPlayerController?.pause();
            logger.d("测试视频：16 -- ${logic.index.value} -- $itemIndex");
          }
        }

      }
    }catch(e){}

  }

  void didPopNext() {
    isVideoPage = true;

    if (logic.index.value == itemIndex) {
      isAutoPlaying = logic.index.value == itemIndex;
      final indexLogic = Get.find<IndexLogic>();
      if ((videoPlayerController?.value.isInitialized ?? false) &&
          indexLogic.currentIndex.value == 1) {
        videoPlayerController?.play();
      }
    } else {
      if ((videoPlayerController?.value.isInitialized ?? false)) {
        _dyVideoControls?.displayBufferingIndicator = false;
        videoPlayerController?.pause();
        logger.d(
            "测试视频：3 -- ${logic.index.value} -- $itemIndex");
      }
    }
    if (logic.index.value == itemIndex) {
      if (viewRefresh != null) {
        viewRefresh!();
      }
    }
  }

  void didPushNext() {
    isVideoPage = false;
    isAutoPlaying = false;

    // dispose();
    if (videoPlayerController != null) {
      videoPlayerController?.pause();
      _dyVideoControls?.displayBufferingIndicator = false;

      logger.d(
          "测试视频：4 -- ${logic.index.value} -- $itemIndex");
    }
  }

  Future onInit() async {
    // await initializeVideo();
  }

  void setupEventListeners() {
    final indexLogic = Get.find<IndexLogic>();
    indexTabWork = ever(indexLogic.currentIndex, (callback) {
      if (callback != 1) {
        isAutoPlaying = false;
        // videoPlayerController?.initialize().then((_){
        //   Future.delayed(const Duration(seconds: 2), () {
        //     if (!isAutoPlaying) {
        //       videoPlayerController?.pause();
        //     }
        //   });
        // });
        _dyVideoControls?.displayBufferingIndicator = false;
        videoPlayerController?.pause();
      } else {
        if (logic.index.value == itemIndex) {
          isAutoPlaying = true;
          if (videoPlayerController?.value.isInitialized ?? false) {
            videoPlayerController?.play();
          }
          openWakelock();
        }
      }
      if (logic.index.value == itemIndex) {
        if (viewRefresh != null) {
          viewRefresh!();
        }
      }
    });

    videoWork = ever(
      logic.index,
      (callback) {
        if (callback != itemIndex) {
          isAutoPlaying = false;

          if (videoPlayerController?.value.isInitialized ?? false) {
            _dyVideoControls?.displayBufferingIndicator = false;
            videoPlayerController?.pause();
            logger.d("测试视频：7 -- ${logic.index.value} -- $itemIndex");
          }
        } else {
          isAutoPlaying = true;
          calling = false;
          logger.d(
              "测试视频：11 -- ${videoPlayerController?.value} -- ${videoPlayerController?.value.position.inMilliseconds}--${logic.index.value} -- $itemIndex");
          if (videoPlayerController?.value.isInitialized ?? false) {
            videoPlayerController?.play();
            if (viewRefresh != null) {
              viewRefresh!();
            }
          }
        }
      },
      condition: () => true,
    );

    _event = EventBusUtil.listen<VideoCallEvent>((event) {
      calling = true;
      isAutoPlaying = false;
      if (videoPlayerController?.value.isInitialized ?? false) {
        _dyVideoControls?.displayBufferingIndicator = false;
        videoPlayerController?.pause();
        logger.d("测试视频：8 -- ${logic.index.value} -- $itemIndex");
      }
    });

    // 背景音乐控制事件：弹窗出现暂停视频、关闭后在合适时机恢复
    _bgmEventSub = EventBusUtil.listen((event) {
      try {
        if (event is BGMPauseEvent) {
          if (videoPlayerController?.value.isInitialized ?? false) {
            _dyVideoControls?.displayBufferingIndicator = false;
            videoPlayerController?.pause();
          }
        } else if (event is BGMResumeEvent) {
          final indexLogic = Get.find<IndexLogic>();
          if ((videoPlayerController?.value.isInitialized ?? false) && indexLogic.currentIndex.value == 1 && logic.index.value == itemIndex && isVideoPage) {
            videoPlayerController?.play();
          }
        }
      } catch (_) {}
    });

    _appLifecycleStateEvent =
        EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        if ((videoPlayerController?.value.isInitialized ?? false) &&
            indexLogic.currentIndex.value == 1 &&
            logic.index.value == itemIndex) {
          if (isVideoPage) {
            // dispose();
            // initializeVideo();
            isAutoPlaying = true;
            videoPlayerController?.play();
          }

          // isAutoPlaying = false;
          // _dyVideoControls?.displayBufferingIndicator = false;
          // controller?.pause();
        }
        if (logic.index.value == itemIndex) {
          if (viewRefresh != null) {
            viewRefresh!();
          }
        }
      } else {
        isAutoPlaying = false;
        videoPlayerController?.initialize().then((_){
          Future.delayed(const Duration(seconds: 2), () {
            if (!isAutoPlaying) {
              videoPlayerController?.pause();
            }
          });
        });
        if (videoPlayerController?.value.isInitialized ?? false) {
          _dyVideoControls?.displayBufferingIndicator = false;
          videoPlayerController?.pause();
          // logger.d("测试视频：9 -- ${logic.index.value} -- ${itemIndex}");
        }
      }
    });
  }

  void dispose() {
    disposeVideo();
    if (_event != null) {
      _event?.cancel();
    }
    if (_appLifecycleStateEvent != null) {
      _appLifecycleStateEvent?.cancel();
    }
    if (_bgmEventSub != null) {
      _bgmEventSub?.cancel();
    }

    _event = null;
    if (videoWork != null) {
      videoWork?.dispose();
      videoWork = null;
    }
    if (indexTabWork != null) {
      indexTabWork?.dispose();
      indexTabWork = null;
    }

    controller = null;
  }
}
