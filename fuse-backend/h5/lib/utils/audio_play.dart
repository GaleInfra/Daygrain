import 'package:just_audio/just_audio.dart';
import 'package:untitled1/utils/throttle_util.dart';

class AudioPlay {
  //单例
  AudioPlay._initial();
  static final AudioPlay _instance = AudioPlay._initial();
  static AudioPlay get instance => _instance;

  AudioPlayer? _chatPlayer;


  // IM铃声
  Future playHangUpSound() async {
    //防抖 2 秒内只会执行一次
    // throttleUtil.throttle(() async {
    //    try {
    //       if (_chatPlayer != null && (_chatPlayer?.playing ?? false)) {
    //         stopSound();
    //       }
    //       _chatPlayer = AudioPlayer();
    //       await _chatPlayer?.setAsset('assets/audio/hangup.mp3');
    //       _chatPlayer?.play();
    //     } catch (e) {
    //       // Log.e("IM铃声播放错误: $e");
    //     }
    // },key: "playHangUpSound",time: 2000);
    return;
   
  }

  Future stopSound() async {
    // try {
    //   _chatPlayer?.stop();
    //   _chatPlayer = null;
    // } catch (e) {
    //   // Log.e("IM铃声暂停错误: $e");
    // }
  }
}
