import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';

import 'package:untitled1/utils/bh_platform.dart';

/// create: 2023/5/6
/// desc: 语音录制功能
class ChatVoiceWidget extends StatefulWidget {
  const ChatVoiceWidget({
    Key? key,
    required this.onVoiceBack,
  }) : super(key: key);

  /// 录制返回
  final Function(String path, int duration) onVoiceBack;

  @override
  State<ChatVoiceWidget> createState() => _ChatVoiceWidgetState();
}

class _ChatVoiceWidgetState extends State<ChatVoiceWidget>
    with SingleTickerProviderStateMixin {
  /// 控制器
  // late final RecorderController controller;

  /// 当前用户ID
  late String userId;

  /// 路径
  late String path;

  ///分贝
  double? decibels;

  ///时间
  int duration = 0;

  /// 是否录制中
  bool recording = false;

  ///动画控制器
  late AnimationController _controller;
  late Animation<double> _animation;

  ///使用flutter_sound插件
  FlutterSoundRecorder? mRecorder = FlutterSoundRecorder();

  ///记录录音流
  StreamSubscription? recorderSubscription;

  String _dots = '';

  // late Timer? timer;

  @override
  void initState() {
    super.initState();
    userId = Get.find<AppConfigManager>().userInfo.userId ?? "";
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    // timer?.cancel();
    _controller.dispose();
    mRecorder?.stopRecorder();
    mRecorder?.closeRecorder();
    mRecorder = null;
    if (recorderSubscription != null) {
      recorderSubscription!.cancel();
      recorderSubscription = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: recording
                ? AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 30),
                        painter:
                            WaveformPainter(animationValue: _animation.value),
                      );
                    },
                  )
                : const SizedBox(height: 30),
          ),
        ),
        MyGaps.hGaps3w,
        GestureDetector(
          onTap: _onReset,
          child: const Icon(
            Icons.refresh,
            color: MyColor.white,
          ),
        ),
        MyGaps.hGaps3w,
        GestureDetector(
          onTap: startOrStopRecord,
          child: Icon(
            recording ? Icons.stop : Icons.mic,
            color: recording ? MyColor.redFF5E5E : MyColor.white,
          ),
        ),
      ],
    );
  }

  /// 重置
  void _onReset() {
    if (recording) {
      // timer?.cancel();
      mRecorder?.stopRecorder();
      setState(() {
        recording = false;
        _dots += '';
      });
    }
  }

  /// 开启/停止录制
  Future startOrStopRecord() async {
    var status = await Permission.microphone.request();
    //打印
    print("status: ${status.toString()}");
    if (status != PermissionStatus.granted) {
      return;
    }

    // Timer.periodic(Duration(seconds: 1), (Timer timer) {
    //   this.timer = timer;
    //   setState(() {
    //     _dots += '. ';
    //   });
    // });

    try {
      if (recording) {
        // timer?.cancel();

        /// 录制中，停止录制
        setState(() {
          recording = false;
          _dots += '';
        });
        final recorderUrl = await mRecorder?.stopRecorder();
        print("存储路径：$path");
        final url = BHPlatform.isWeb ? recorderUrl : path;

        if (url != null && duration > 0) {
          widget.onVoiceBack
              .call(url, duration);
        } else {
          // Toast.showMsg("warning_shortTalkTime".bhTR);
        }
      } else {
        /// 未录制，开启录制
        setState(() {
          recording = true;
        });

        ///打开录音机
        await mRecorder?.openRecorder();

        ///获取路径
        /// Web平台使用内存存储，其他平台使用本地文件存储
        if (kIsWeb) {
          final time = DateTime.now().millisecondsSinceEpoch;
          path = '$time.aac';
        } else {
          Directory tempDir = await getApplicationSupportDirectory();
          final time = DateTime.now().millisecondsSinceEpoch;
          path = '${tempDir.path}/$time.aac';
        }

        ///开始录音
        await mRecorder?.startRecorder(toFile: path, codec: Codec.aacMP4);

        await mRecorder?.setSubscriptionDuration(const Duration(seconds: 1));

        /// 监听录音
        recorderSubscription = mRecorder!.onProgress!.listen((e) async {
          duration = e.duration.inSeconds;
          decibels = e.decibels;
          // getRecordingVoiceLogic()?.decibels.value = decibels!;
          // getRecordingVoiceLogic()?.duration.value = duration;
          if (duration >= 60) {
            // timer?.cancel();
            setState(() {
              recording = false;
              _dots += '';
            });
            await mRecorder?.stopRecorder();
            print("存储路径：$path");
            if (duration > 0) {
              widget.onVoiceBack.call(path, duration);
            } else {
              // Toast.showMsg("warning_shortTalkTime".bhTR);
            }
          }

          print("duration：${e.duration.inSeconds}");
          print("当前振幅：${e.decibels}");
        });
      }
    } catch (e) {
      setState(() {
        recording = false;
      });
      print("录制或停止录制失败===> ${e.toString()}");
    }
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;

  WaveformPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final waveHeight = size.height * 0.5;
    final waveWidth = size.width / 10;

    for (int i = 0; i < 30; i++) {
      final x = i * waveWidth;
      final height = waveHeight +
          (waveHeight * 0.5 * sin((animationValue + i * 0.1) * 2 * pi));
      canvas.drawRect(
          Rect.fromLTWH(x, size.height / 2 - height / 2, 2, height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
