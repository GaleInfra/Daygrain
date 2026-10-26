import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/widget/status/lose_widget.dart';
import 'package:untitled1/widget/strong_image.dart';

/// @description: ExtendedImage.network的封装
class MyExtendedNetworkImage extends StatelessWidget {
  final bool isBroadcaster;
  const MyExtendedNetworkImage({
    Key? key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.shape,
    this.borderRadius,
    this.cache = true,
    this.startReload = false,
    this.isBroadcaster = false,
    this.isPlaceholder = true,
    this.isAnimation = true,
    this.fallbackUrl,
  }) : super(key: key);

  final String url;
  final String? fallbackUrl;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final BoxShape? shape;

  final BorderRadius? borderRadius;

  final bool cache;
  final bool isPlaceholder;
  final bool isAnimation;

  /// 开启加载失败时点击重载
  final bool startReload;

  @override
  Widget build(BuildContext context) {
    Widget child;

    final url = this.url.startsWith("http://") ? this.url.replaceAll("http://", "https://") : this.url;

    if (url.isEmpty) {
      child = isPlaceholder
          ? LoseWidget(
              isBroadcaster: isBroadcaster,
              shape: shape,
              borderRadius: borderRadius,
            )
          : Container();
    } else {
      // HtmlImage on web cannot decode at a target width; a ResizeImage only adds a second cache key.
      final memCacheWidth = !kIsWeb && (width ?? 0) > 0 && ((width ?? 0) < double.maxFinite) ? width!.toInt() : null;
      // Web image streams are never synchronous, so any fade runs on every scroll-in, even for cached images.
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        cacheManager: StrongImage.cacheManager,
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
        memCacheWidth: memCacheWidth,
        placeholder: (context, url) {
          return isPlaceholder
              ? LoseWidget(
                  isBroadcaster: isBroadcaster,
                  shape: shape,
                  borderRadius: borderRadius,
                )
              : Container();
        },
        errorWidget: (context, failedUrl, error) {
          final next = fallbackUrl;
          if (next != null && next.isNotEmpty && next != failedUrl) {
            return MyExtendedNetworkImage(
              url: next,
              width: width,
              height: height,
              fit: fit,
              shape: shape,
              borderRadius: borderRadius,
              isBroadcaster: isBroadcaster,
              isPlaceholder: isPlaceholder,
            );
          }
          return LoseWidget(
            isBroadcaster: isBroadcaster,
            shape: shape,
            borderRadius: borderRadius,
          );
        },
      );
      if (shape == BoxShape.circle) {
        child = ClipOval(child: child);
      } else if (borderRadius != null) {
        child = ClipRRect(borderRadius: borderRadius!, child: child);
      }
    }
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}
