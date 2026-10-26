import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/overlay_util.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:video_player/video_player.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart' as net;
import 'package:just_audio/just_audio.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
import 'package:untitled1/widget/msg_notication/message_notication.dart';
import 'dart:async';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/bgm_event.dart';

/// 机器人搭讪通话弹窗
/// 全屏显示，顶部头像+昵称，右上角挂断按钮，底部提示+大按钮
class RobotChatDialog extends StatefulWidget {
  final Map<String, dynamic> broadcasterData;
  final VoidCallback onClose;
  final VideoPlayerController? videoController;
  final String? thumbUrl;
  final String? avatarUrl;

  const RobotChatDialog({
    Key? key,
    required this.broadcasterData,
    required this.onClose,
    this.videoController,
    this.thumbUrl,
    this.avatarUrl,
  }) : super(key: key);

  /// 显示机器人搭讪弹窗
  static void show({
    required Map<String, dynamic> broadcasterData,
    required VoidCallback onClose,
    VideoPlayerController? videoController,
    String? thumbUrl,
    String? avatarUrl,
  }) {
    OverlayUtil().dismiss(tag: tag);
    // 确保该弹窗优先级更高：先关闭消息弹窗横条
    MessageNotication.dismiss();
    OverlayUtil().show(
      context: Get.overlayContext!,
      child: RobotChatDialog(
        broadcasterData: broadcasterData,
        onClose: onClose,
        videoController: videoController,
        thumbUrl: thumbUrl,
        avatarUrl: avatarUrl,
      ),
      tag: tag,
    );
    _isShowing = true;
  }

  /// 关闭弹窗
  static void dismiss({VoidCallback? onDismiss}) {
    OverlayUtil().dismiss(tag: tag);
    _isShowing = false;
    if (onDismiss != null) {
      onDismiss();
    }
  }

  static const String tag = "RobotChatDialog";
  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  @override
  State<RobotChatDialog> createState() => _RobotChatDialogState();
}

class _RobotChatDialogState extends State<RobotChatDialog> {
  VoidCallback? _videoListener;
  AudioPlayer? _ringPlayer;
  StreamSubscription<AppLifecycleStateEvent>? _lifecycleSub;
  StreamSubscription? _ringControlSub;
  
  // 30秒自动关闭相关
  Timer? _autoCloseTimer;
  int _remainingSeconds = 30;
  bool _isAutoClosing = false;

  @override
  void initState() {
    super.initState();
    _attachVideoListener(widget.videoController);
    _startRinging();
    _startAutoCloseTimer();

    // 弹窗出现时，通知全局暂停背景音乐
    try {
      EventBusUtil.fire(BGMPauseEvent());
    } catch (_) {}

    // 监听前后台切换，参照项目现有实现
    _lifecycleSub = EventBusUtil.listen<AppLifecycleStateEvent>((event) async {
      try {
        if (event.state == AppLifecycleState.paused) {
          await _pauseBgm();
        } else if (event.state == AppLifecycleState.resumed) {
          await _resumeBgm();
        }
      } catch (_) {}
    });
    
    // 监听VIP弹窗的铃声控制事件
    _ringControlSub = EventBusUtil.listen((event) {
      try {
        if (event is RobotRingPauseEvent) {
          _pauseBgm();
        } else if (event is RobotRingResumeEvent) {
          _resumeBgm();
        }
      } catch (_) {}
    });
    
    // 如果视频控制器已经初始化，确保它开始播放
    if (widget.videoController != null && widget.videoController!.value.isInitialized) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && widget.videoController != null) {
          try {
            widget.videoController!.play();
            logger.d('弹窗初始化时开始播放视频');
          } catch (e) {
            logger.e('弹窗初始化时播放视频失败: $e');
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant RobotChatDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoController != widget.videoController) {
      _detachVideoListener(oldWidget.videoController);
      _attachVideoListener(widget.videoController);
      
      // 如果新的视频控制器已经初始化，开始播放
      if (widget.videoController != null && widget.videoController!.value.isInitialized) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && widget.videoController != null) {
            try {
              widget.videoController!.play();
              logger.d('视频控制器更新时开始播放');
            } catch (e) {
              logger.e('视频控制器更新时播放失败: $e');
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _detachVideoListener(widget.videoController);
    _stopRinging();
    _cancelAutoCloseTimer();
    _lifecycleSub?.cancel();
    _lifecycleSub = null;
    _ringControlSub?.cancel();
    _ringControlSub = null;

    // 弹窗关闭时，通知全局恢复背景音乐
    try {
      EventBusUtil.fire(BGMResumeEvent());
    } catch (_) {}
    
    // 确保视频控制器正确释放
    if (widget.videoController != null) {
      try {
        widget.videoController!.pause();
        widget.videoController!.seekTo(Duration.zero);
        // 注意：不要在这里dispose，因为控制器是从外部传入的
      } catch (e) {
        logger.e('释放视频控制器失败: $e');
      }
    }
    
    super.dispose();
  }

  /// 启动30秒自动关闭定时器
  void _startAutoCloseTimer() {
    _remainingSeconds = 30;
    _isAutoClosing = false;
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          _isAutoClosing = true;
          _cancelAutoCloseTimer();
          _handleClose();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// 取消自动关闭定时器
  void _cancelAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  /// 处理关闭逻辑（统一入口）
  void _handleClose() {
    if (_isAutoClosing) {
      // 自动关闭：直接调用回调
      RobotChatDialog.dismiss();
      widget.onClose();
    } else {
      // 手动关闭：取消定时器后调用回调
      _cancelAutoCloseTimer();
      RobotChatDialog.dismiss();
      widget.onClose();
    }
  }

  Future<void> _startRinging() async {
    try {
      _ringPlayer?.dispose();
      _ringPlayer = AudioPlayer();
      await _ringPlayer!.setAsset('assets/audio/audio_new.aac');
      await _ringPlayer!.setLoopMode(LoopMode.one);
      _ringPlayer!.setVolume(0.6);
      _ringPlayer!.play();
    } catch (_) {}
  }

  Future<void> _stopRinging() async {
    try {
      await _ringPlayer?.stop();
      await _ringPlayer?.dispose();
    } catch (_) {}
    _ringPlayer = null;
  }

  Future<void> _pauseBgm() async {
    try {
      await _ringPlayer?.pause();
    } catch (_) {}
  }

  Future<void> _resumeBgm() async {
    try {
      if (_ringPlayer != null && _ringPlayer!.playing == false) {
        await _ringPlayer!.play();
      }
    } catch (_) {}
  }

  void _attachVideoListener(VideoPlayerController? c) {
    if (c == null) return;
    _videoListener = () {
      if (mounted) setState(() {});
    };
    c.addListener(_videoListener!);
  }

  void _detachVideoListener(VideoPlayerController? c) {
    if (c == null || _videoListener == null) return;
    c.removeListener(_videoListener!);
    _videoListener = null;
  }

  @override
  Widget build(BuildContext context) {
    final String name = (widget.broadcasterData['name'] ?? 'Aurora').toString();
    final controller = widget.videoController;
    final bool canPlay = controller != null && controller.value.isInitialized;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black, // 纯黑背景，去掉橙色/渐变底色
          child: Stack(
            children: [
              // 中部占位大图/视频
              Positioned.fill(
                child: canPlay
                    ? FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : Opacity(
                        opacity: 0.9,
                        child: widget.thumbUrl != null && widget.thumbUrl!.isNotEmpty
                            ? net.MyExtendedNetworkImage(
                                url: widget.thumbUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                isPlaceholder: true,
                              )
                            : Image.asset(
                                ImageAssets.broadcasterPlaceholderImageFull,
                                fit: BoxFit.cover,
                              ),
                      ),
              ),

              // 顶部：头像 + 名称 + 挂断
              Positioned(
                top: 20.h,
                left: 15.w,
                right: 15.w,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 25.w,
                      height: 25.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                          ? net.MyExtendedNetworkImage(
                              url: widget.avatarUrl!,
                              width: 22.w,
                              height: 22.w,
                              fit: BoxFit.fill,
                              isPlaceholder: true,
                            )
                          : Image.asset(
                              ImageAssets.broadcasterPlaceholderImage,
                              fit: BoxFit.cover,
                            ),
                    ),
                    MyGaps.hGaps5w,
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // 倒计时显示
                    // Container(
                    //   margin: EdgeInsets.only(right: 8.w),
                    //   padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    //   decoration: BoxDecoration(
                    //     color: Colors.black.withOpacity(0.6),
                    //     borderRadius: BorderRadius.circular(10.w),
                    //   ),
                    //   child: Text(
                    //     '$_remainingSeconds',
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontSize: 8.sp,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),
                    GestureDetector(
                      onTap: () {
                        _handleClose();
                      },
                      child: Container(
                        width: 19.w,
                        height: 19.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D67),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4D67).withOpacity(0.35),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 11.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 底部提示 + Answer按钮
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 28.h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "She's inviting you to have a Call 💗".bhTR,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 3),
                        ],
                      ),
                    ),
                    MyGaps.vGaps15w,
                    GestureDetector(
                      onTap: () {
                        // 显示VIP弹窗，引导付费；不关闭当前通话弹窗
                        try {
                          // Toast.showMsg("error_insufficientDiamonds".bhTR);
                          VipPrivilegesSheet.show(fromRobotChat: true);
                        } catch (e) {}
                      },
                      child: Container(
                        width: 119.w,
                        height: 23.w,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(ImageAssets.dsBotton),
                              fit: BoxFit.fill,
                            ),
                        ),
                        child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  ImageAssets.callBotton,
                                  width: 14.w,
                                  height: 12.w,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Answer'.bhTR,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.15,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Positioned(
              //   bottom: 7.h,
              //   left: 0,
              //   right: 0,
              //   child: Center(
              //     child: Container(
              //       width: 60.w,
              //       height: 2.h,
              //       decoration: BoxDecoration(
              //         color: Colors.white.withOpacity(0.7),
              //         borderRadius: BorderRadius.circular(1.h),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
