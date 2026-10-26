import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../res/my_color.dart';
import '../status/lose_widget.dart';

/// create: 2023/5/5
/// desc: 显示Base64图片
class MyMemoryImage extends StatelessWidget {
  const MyMemoryImage({
    Key? key,
    required this.base64Str,
    this.width,
    this.height,
  }) : super(key: key);

  final String base64Str;

  final double? width;

  final double? height;

  @override
  Widget build(BuildContext context) {
    Uint8List bytes = base64.decode(base64Str);
    Widget child = SizedBox(
      height: height,
      width: width,
      child: const LoseWidget(),
    );
    if (bytes.isNotEmpty) {
      child = GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=> _SeeMemoryImage(bytes: bytes,))),
        child: Image.memory(
          bytes,
          height: height,
          width: width,
          fit: BoxFit.cover,
          gaplessPlayback: true, //防止重绘
        ),
      );
    }
    return child;
  }
}

class _SeeMemoryImage extends StatelessWidget {
  const _SeeMemoryImage({
    Key? key,
    required this.bytes,
  }) : super(key: key);

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MyColor.black,
        body: Stack(
          children: [
            Image.memory(
              bytes,
              height: double.infinity,
              width: double.infinity,
              //fit: BoxFit.contain,
              gaplessPlayback: true, //防止重绘
            ),
            Positioned(
              left: 15,
              top: kToolbarHeight / 2 + 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: MyColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
