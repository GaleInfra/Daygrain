import 'package:flutter/material.dart';
import 'package:untitled1/res/image_assets.dart';

class LoseWidget extends StatelessWidget {
  final bool isBroadcaster;
  final BorderRadius? borderRadius;
  final BoxShape? shape;

  const LoseWidget({
    Key? key,
    this.isBroadcaster = false,
    this.borderRadius,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? (shape == BoxShape.circle ? BorderRadius.circular(1000) : BorderRadius.zero);
    return ClipRRect(
      borderRadius: r,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF2A1352),
        child: Image.asset(
          ImageAssets.broadcasterPlaceholderImageFull,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
