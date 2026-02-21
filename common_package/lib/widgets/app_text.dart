import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:text_scroll/text_scroll.dart';

import '../theme/text_theme.dart';

class AppText extends StatelessWidget {
  AppText(
    this.text, {
    super.key,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,
    TextStyle? style,
    this.color,
    this.scrollText = false,
  }) : style = (style ?? const TextStyle()).copyWith(color: color);

  final String text;
  final TextAlign? textAlign;
  final ui.TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextStyle? style;
  final Color? color;
  final bool scrollText;
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return scrollText
        ? TextScroll(
            text,
            mode: TextScrollMode.endless,
            velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
            delayBefore: const Duration(milliseconds: 1000),
            pauseBetween: const Duration(milliseconds: 2000),
            style: style?.copyWith(color: color),
            selectable: true,
            intervalSpaces: 5,
            textAlign: textAlign,
          )
        : Text(
            text,
            style: style?.copyWith(color: color, textBaseline: TextBaseline.alphabetic, decoration: decoration),
            key: key,
            locale: locale,
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
            textAlign: textAlign ?? TextAlign.center,
            textDirection: textDirection,
          );
  }

  const AppText.marquee(
    this.text, {
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,

    this.style,
    this.color,
    this.scrollText = true,
    super.key,
  });

  AppText.displayLarge(
    this.text, {
    this.textAlign,
    this.textDirection,
    this.locale,
    this.decoration,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    this.scrollText = false,
    TextStyle? style,
    FontWeight? fontWeight,
    super.key,
  }) : style = textTheme.displayLarge?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.displayMedium(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.decoration,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.displayMedium?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.displaySmall(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.decoration,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.displaySmall?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.headlineLarge(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.decoration,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.headlineLarge?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.headlineMedium(
    this.text, {
    this.scrollText = false,
    this.decoration,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.headlineMedium?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.headlineSmall(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    super.key,
    this.decoration,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.headlineSmall?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.titleLarge(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    this.decoration,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.titleLarge?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.titleMedium(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.decoration,
    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.titleMedium?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.titleSmall(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    this.decoration,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.titleSmall?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.labelLarge(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.color,
    this.decoration,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.labelLarge?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.labelMedium(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.decoration,
    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.labelMedium?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.labelSmall(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.labelSmall?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.bodyLarge(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.bodyLarge?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.bodyMedium(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.decoration,
    this.color,
    super.key,
    TextStyle? style,
    FontWeight? fontWeight,
  }) : style = textTheme.bodyMedium?.merge(style).copyWith(fontWeight: fontWeight);

  AppText.bodySmall(
    this.text, {
    this.scrollText = false,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,

    this.decoration,
    this.color,
    TextStyle? style,
    FontWeight? fontWeight,
    super.key,
  }) : style = textTheme.bodySmall?.merge(style).copyWith(fontWeight: fontWeight);
}
