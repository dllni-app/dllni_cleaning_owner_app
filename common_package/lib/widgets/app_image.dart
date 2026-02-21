import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum Source { assets, network }

class AppImage extends StatelessWidget {
  const AppImage.asset(
    this.path, {
    super.key,
    this.alignment,
    this.fit,
    this.height,
    this.width,
    this.color,
    this.colorFilter,
    this.loadingBuilder,
    this.failedBuilder,
    this.size,
    this.borderRadius,
    this.errorWidget,
  }) : _source = Source.assets;

  const AppImage.network(
    this.path, {
    super.key,
    this.alignment,
    this.fit,
    this.height,
    this.width,
    this.color,
    this.loadingBuilder,
    this.failedBuilder,
    this.colorFilter,
    this.size,
    this.errorWidget,
    this.borderRadius,
  }) : _source = Source.network;

  final Source _source;

  final String path;
  final Alignment? alignment;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final Color? color;
  final WidgetBuilder? loadingBuilder;

  final Widget? errorWidget;

  ///pass size will overwrite height and width
  final double? size;

  ///this will be ignored if the image source is [SvgPicture.network]
  final WidgetBuilder? failedBuilder;

  ///only work on svg and color will be ignore
  final ColorFilter? colorFilter;

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (path.contains('.svg')) {
      switch (_source) {
        case Source.assets:
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: SvgPicture.asset(
              path,
              colorFilter: colorFilter ?? (color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null),
              alignment: alignment ?? Alignment.center,
              fit: fit ?? BoxFit.contain,
              height: size ?? height,
              width: size ?? width,
            ),
          );
        case Source.network:
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: SvgPicture.network(
              path,
              colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
              alignment: alignment ?? Alignment.center,
              fit: fit ?? BoxFit.contain,
              height: size ?? height,
              width: size ?? width,
            ),
          );
      }
    } else {
      switch (_source) {
        case Source.assets:
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Image.asset(path, color: color, alignment: alignment ?? Alignment.center, fit: fit, height: size ?? height, width: size ?? width),
          );
        case Source.network:
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: CachedNetworkImage(
              imageUrl: path,
              color: color,
              errorWidget: (context, v, trace) {
                return errorWidget ?? const SizedBox();
              },
              placeholder: (context, url) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              alignment: alignment ?? Alignment.center,
              fit: fit,
              height: size ?? height,
              width: size ?? width,
            ),
          );
      }
    }
  }

  Widget copyWith(Color? color) {
    if (_source == Source.network) {
      return AppImage.network(
        path,
        color: color ?? this.color,
        width: width,
        height: height,
        size: size,
        alignment: alignment,
        fit: fit,
        colorFilter: colorFilter,
        failedBuilder: failedBuilder,
        loadingBuilder: loadingBuilder,
        key: key,
      );
    }
    return AppImage.asset(
      path,
      color: color ?? this.color,
      width: width,
      height: height,
      size: size,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
      failedBuilder: failedBuilder,
      loadingBuilder: loadingBuilder,
      key: key,
    );
  }
}
