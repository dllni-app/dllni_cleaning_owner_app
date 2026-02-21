import 'package:flutter/material.dart';

extension ThemeExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get primary => colorScheme.primary;

  Color get onPrimary => colorScheme.onPrimary;

  Color get secondary => colorScheme.secondary;

  Color get onSecondary => colorScheme.onSecondary;

  Color get error => colorScheme.error;

  Color get onError => colorScheme.onError;

  Color get surface => colorScheme.surface;

  Color get onSurface => colorScheme.onSurface;

  Color get inversePrimary => colorScheme.inversePrimary;

  Color get inverseSurface => colorScheme.inverseSurface;

  Color get onInverseSurface => colorScheme.onInverseSurface;

  Color get secondaryContainer => colorScheme.secondaryContainer;

  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;

  Color get primaryContainer => colorScheme.primaryContainer;

  Color get onPrimaryContainer => colorScheme.onPrimaryContainer;

  DefaultTextStyle get defaultTextStyle => DefaultTextStyle.of(this);
}