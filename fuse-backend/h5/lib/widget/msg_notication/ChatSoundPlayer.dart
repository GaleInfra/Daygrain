import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:untitled1/my_app.dart';

class ChatSoundPlayer {
  ChatSoundPlayer._initial();
  static final ChatSoundPlayer _instance = ChatSoundPlayer._initial();
  static ChatSoundPlayer get instance => _instance;

  AudioPlayer? _chatPlayer;

  Future init() async {}

  // IM铃声
  Future chatSoundPlay() async {
    if(myAppLifecycleState == AppLifecycleState.paused) {
      //如果退到后台则不播放铃声
      return;
    }
    try {
      if (_chatPlayer != null && (_chatPlayer?.playing ?? false)) {
        chatSoundPause();
      }
      _chatPlayer = AudioPlayer();
      await _chatPlayer?.setAsset('assets/audio/chathub_message_alter.mp3');
      _chatPlayer?.play();
    } catch (e) {
      // Log.e("IM铃声播放错误: $e");
    }
  }

  Future chatSoundPause() async {
    try {
      _chatPlayer?.stop();
      _chatPlayer = null;
    } catch (e) {
      // Log.e("IM铃声暂停错误: $e");
    }
  }
}
