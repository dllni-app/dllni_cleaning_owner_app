import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:text_scroll/text_scroll.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.decoration,
    this.style,
    this.color,
    this.scrollText = false,
  }) : _role = null,
       _fontWeight = null;

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
  final _AppTextRole? _role;
  final FontWeight? _fontWeight;

  @override
  Widget build(BuildContext context) {
    final themedStyle =
        _role?.resolve(Theme.of(context).textTheme) ?? const TextStyle();
    final resolvedStyle = themedStyle
        .merge(style)
        .copyWith(
          color: color ?? style?.color ?? themedStyle.color,
          fontWeight:
              _fontWeight ?? style?.fontWeight ?? themedStyle.fontWeight,
          decoration: decoration ?? style?.decoration ?? themedStyle.decoration,
          textBaseline: TextBaseline.alphabetic,
        );
    final resolvedTextAlign = textAlign ?? TextAlign.start;
    final mayAnimate = scrollText && !MediaQuery.disableAnimationsOf(context);

    return mayAnimate
        ? TextScroll(
            text,
            mode: TextScrollMode.endless,
            velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
            delayBefore: const Duration(milliseconds: 1000),
            pauseBetween: const Duration(milliseconds: 2000),
            style: resolvedStyle,
            selectable: true,
            intervalSpaces: 5,
            textAlign: resolvedTextAlign,
          )
        : Text(
            text,
            style: resolvedStyle,
            key: key,
            locale: locale,
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
            textAlign: resolvedTextAlign,
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
  }) : _role = null,
       _fontWeight = null;

  const AppText.displayLarge(
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
    this.style,
    FontWeight? fontWeight,
    super.key,
  }) : _role = _AppTextRole.displayLarge,
       _fontWeight = fontWeight;

  const AppText.displayMedium(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.displayMedium,
       _fontWeight = fontWeight;

  const AppText.displaySmall(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.displaySmall,
       _fontWeight = fontWeight;

  const AppText.headlineLarge(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.headlineLarge,
       _fontWeight = fontWeight;

  const AppText.headlineMedium(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.headlineMedium,
       _fontWeight = fontWeight;

  const AppText.headlineSmall(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.headlineSmall,
       _fontWeight = fontWeight;

  const AppText.titleLarge(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.titleLarge,
       _fontWeight = fontWeight;

  const AppText.titleMedium(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.titleMedium,
       _fontWeight = fontWeight;

  const AppText.titleSmall(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.titleSmall,
       _fontWeight = fontWeight;

  const AppText.labelLarge(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.labelLarge,
       _fontWeight = fontWeight;

  const AppText.labelMedium(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.labelMedium,
       _fontWeight = fontWeight;

  const AppText.labelSmall(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.labelSmall,
       _fontWeight = fontWeight;

  const AppText.bodyLarge(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.bodyLarge,
       _fontWeight = fontWeight;

  const AppText.bodyMedium(
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
    this.style,
    FontWeight? fontWeight,
  }) : _role = _AppTextRole.bodyMedium,
       _fontWeight = fontWeight;

  const AppText.bodySmall(
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
    this.style,
    FontWeight? fontWeight,
    super.key,
  }) : _role = _AppTextRole.bodySmall,
       _fontWeight = fontWeight;
}

enum _AppTextRole {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  labelLarge,
  labelMedium,
  labelSmall,
  bodyLarge,
  bodyMedium,
  bodySmall;

  TextStyle? resolve(TextTheme textTheme) => switch (this) {
    _AppTextRole.displayLarge => textTheme.displayLarge,
    _AppTextRole.displayMedium => textTheme.displayMedium,
    _AppTextRole.displaySmall => textTheme.displaySmall,
    _AppTextRole.headlineLarge => textTheme.headlineLarge,
    _AppTextRole.headlineMedium => textTheme.headlineMedium,
    _AppTextRole.headlineSmall => textTheme.headlineSmall,
    _AppTextRole.titleLarge => textTheme.titleLarge,
    _AppTextRole.titleMedium => textTheme.titleMedium,
    _AppTextRole.titleSmall => textTheme.titleSmall,
    _AppTextRole.labelLarge => textTheme.labelLarge,
    _AppTextRole.labelMedium => textTheme.labelMedium,
    _AppTextRole.labelSmall => textTheme.labelSmall,
    _AppTextRole.bodyLarge => textTheme.bodyLarge,
    _AppTextRole.bodyMedium => textTheme.bodyMedium,
    _AppTextRole.bodySmall => textTheme.bodySmall,
  };
}
