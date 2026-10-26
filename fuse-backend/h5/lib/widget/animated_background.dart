//动态背景
import 'package:flutter/material.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
 

// class AnimatedBackground extends StatefulWidget {
//   final String userId;
//   const AnimatedBackground({Key? key, required this.userId}) : super(key: key);

//   @override
//   State<AnimatedBackground> createState() => _AnimatedBackgroundState();
// }

// class _AnimatedBackgroundState extends State<AnimatedBackground> {
  
//   late VideoPlayerController videoController;
//   late ChewieController chewieController;
//   final isPlaying = false.obs;
//   StreamSubscription? _appLifecycleSubscription;
//   @override
//   void dispose() {
//       videoController.dispose();
//       chewieController?.dispose();
//       _appLifecycleSubscription?.cancel();
//     super.dispose();
//   }
//   @override
//   void initState() {
//     videoController = VideoPlayerController.asset(AnimatedBackgroundManager.getInstance().next(widget.userId));
//     videoController.setLooping(true);
//     videoController.addListener(() {
//       if (videoController.value.isInitialized) {
//         if (!videoController.value.isPlaying) {
//           videoController.seekTo(Duration.zero);
//           videoController.play();
//           isPlaying.value = true;
//           setState(() {});
//         }
//       }
//     });
//     videoController.initialize().then((value) {
//        chewieController = ChewieController(
//                       videoPlayerController: videoController,
//                       autoPlay: true,
//                       looping: true,
//                       showControls: false,
//                       aspectRatio:886 / 1920.0,
//                     );
//     });

//     //监听前后台切换
//     _appLifecycleSubscription =
//         EventBusUtil.listen<AppLifecycleStateEvent>((event) {
//       if (event.state == AppLifecycleState.resumed) {
//         if (videoController.value.isInitialized) {
//           if (!videoController.value.isPlaying) {
//             videoController.play();
//             isPlaying.value = true;
//             setState(() {});
//           }
//         }
//       } else if (event.state == AppLifecycleState.paused) {
//         if (videoController.value.isInitialized) {
//           if (videoController.value.isPlaying) {
//             videoController.pause();
//             isPlaying.value = false;
//             setState(() {});
//           }
//         }
//       }
//     });
//     super.initState();

//   }
//   @override
//   Widget build(BuildContext context) {
//     double containerW = Get.width;
//     double containerH = Get.height;
//     double aspectRatio = 886 / 1920.0;

//     //计算视频组件的宽高 使其充满屏幕
//     double videoWidth = containerW;
//     double videoHeight = containerH;
//     double scale = 1.0;
//     if (videoWidth / aspectRatio > videoHeight) {
//       videoHeight = videoWidth / aspectRatio;
//       scale = videoHeight / containerH;
//     } else {
//       videoWidth = videoHeight * aspectRatio;
//       scale = videoWidth / containerW;
//     }
//     return SizedBox(
//               height: videoHeight,
//               width: videoWidth,
//               child: ClipRect(
//                 child: Transform.scale(
//                   scale: scale,
//                   child: isPlaying.value
//                       ? Chewie(controller: chewieController)
//                       : Container(),
//                 ),
//               ),
//             );
//   }
// }

// //背景图管理器 从数组中随机获取图片不重复。 当都获取完一遍后 再全部重新随机开始获取 ,记录下每个用户ID和对应的index 进行绑定
// class AnimatedBackgroundManager {
//   //单例
//   static AnimatedBackgroundManager? _instance;

//   static AnimatedBackgroundManager getInstance() {
//     if(_instance == null){
//       _instance = AnimatedBackgroundManager._internal();
//       _instance!.map = SPUtil.getMap(MyKeys.animatedBackground);
//     }
    
//     return _instance!;
//   }
  
//     AnimatedBackgroundManager._internal();
  
//   var map = {};
//   var index = 0;
//   var list = [
//     'assets/images/gif/v1.mp4',
//     'assets/images/gif/v1.mp4',
//     'assets/images/gif/v1.mp4',
//     'assets/images/gif/v1.mp4',
//     'assets/images/gif/v1.mp4',
//   ];

//   String next(String userId) {
//     if(map.containsKey(userId)){
//       return list[map[userId]!];
//     }
//     index++;
//     if (index >= list.length) {
//       index = 0;
//     }
//     map[userId] = index;
//     //保存SP
//     SPUtil.setMap(MyKeys.animatedBackground, map);
//     return list[index];
//   }
// }



class AnimatedBackground extends StatefulWidget {
  final String userId;
  const AnimatedBackground({Key? key, required this.userId}) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  
  // late VideoPlayerController videoController;
  // late ChewieController chewieController;
  // final isPlaying = false.obs;
  // StreamSubscription? _appLifecycleSubscription;
  @override
  void dispose() {
      // videoController.dispose();
      // chewieController?.dispose();
      // _appLifecycleSubscription?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    // videoController = VideoPlayerController.asset(AnimatedBackgroundManager.getInstance().next(widget.userId));
    // videoController.setLooping(true);
    // videoController.addListener(() {
    //   if (videoController.value.isInitialized) {
    //     if (!videoController.value.isPlaying) {
    //       videoController.seekTo(Duration.zero);
    //       videoController.play();
    //       isPlaying.value = true;
    //       setState(() {});
    //     }
    //   }
    // });
    // videoController.initialize().then((value) {
    //    chewieController = ChewieController(
    //                   videoPlayerController: videoController,
    //                   autoPlay: true,
    //                   looping: true,
    //                   showControls: false,
    //                   aspectRatio:886 / 1920.0,
    //                 );
    // });

    // //监听前后台切换
    // _appLifecycleSubscription =
    //     EventBusUtil.listen<AppLifecycleStateEvent>((event) {
    //   if (event.state == AppLifecycleState.resumed) {
    //     if (videoController.value.isInitialized) {
    //       if (!videoController.value.isPlaying) {
    //         videoController.play();
    //         isPlaying.value = true;
    //         setState(() {});
    //       }
    //     }
    //   } else if (event.state == AppLifecycleState.paused) {
    //     if (videoController.value.isInitialized) {
    //       if (videoController.value.isPlaying) {
    //         videoController.pause();
    //         isPlaying.value = false;
    //         setState(() {});
    //       }
    //     }
    //   }
    // });
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    
    return  MyExtendedNetworkImage(url: AssetsHandle.instance.getPassiveAssetsDomain(AnimatedBackgroundManager.getInstance().next(widget.userId)) ,isPlaceholder: false, fit: BoxFit.cover,);
  }
}

//背景图管理器 从数组中随机获取图片不重复。 当都获取完一遍后 再全部重新随机开始获取 ,记录下每个用户ID和对应的index 进行绑定
class AnimatedBackgroundManager {
  //单例
  static AnimatedBackgroundManager? _instance;

  static AnimatedBackgroundManager getInstance() {
    if(_instance == null){
      _instance = AnimatedBackgroundManager._internal();
      _instance!.map = SPUtil.getMap(MyKeys.animatedBackground);
    }
    
    return _instance!;
  }
  
    AnimatedBackgroundManager._internal();
  
  var map = {};
  var index = 0;
  /*

  */
  var list = [
 'assets/images/gif/000.webp','assets/images/gif/001.webp','assets/images/gif/002.webp','assets/images/gif/003.webp','assets/images/gif/004.webp','assets/images/gif/005.webp','assets/images/gif/006.webp','assets/images/gif/007.webp','assets/images/gif/008.webp','assets/images/gif/009.webp','assets/images/gif/010.webp','assets/images/gif/011.webp','assets/images/gif/012.webp','assets/images/gif/013.webp','assets/images/gif/014.webp','assets/images/gif/015.webp','assets/images/gif/016.webp','assets/images/gif/017.webp','assets/images/gif/018.webp','assets/images/gif/019.webp','assets/images/gif/020.webp','assets/images/gif/021.webp','assets/images/gif/022.webp','assets/images/gif/023.webp','assets/images/gif/024.webp','assets/images/gif/025.webp','assets/images/gif/026.webp','assets/images/gif/027.webp','assets/images/gif/028.webp','assets/images/gif/029.webp','assets/images/gif/030.webp','assets/images/gif/031.webp','assets/images/gif/032.webp','assets/images/gif/033.webp','assets/images/gif/034.webp','assets/images/gif/035.webp','assets/images/gif/036.webp','assets/images/gif/037.webp','assets/images/gif/038.webp','assets/images/gif/039.webp','assets/images/gif/040.webp','assets/images/gif/041.gif','assets/images/gif/042.webp'
  ];

  String next(String userId) {
    if(map.containsKey(userId)){
      return list[map[userId]!];
    }
    // 简洁稳定：对 userId 做稳定哈希得到固定下标，避免刷新后变化
    int stableHash(String s) {
      int h = 0;
      for (final code in s.codeUnits) {
        h = (h * 131 + code) & 0x7fffffff; // 简单稳定哈希
      }
      return h;
    }
    final int selected = list.isEmpty ? 0 : (stableHash(userId) % list.length);
    map[userId] = selected;
    //保存SP
    SPUtil.setMap(MyKeys.animatedBackground, map);
    return list[selected];
  }
}