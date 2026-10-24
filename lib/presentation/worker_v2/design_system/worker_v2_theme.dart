import 'package:flutter/material.dart';
import 'tokens.dart';

/// Standalone light theme for the worker rebuild, applied by S00 at integration.
abstract final class WorkerV2Theme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: WrColors.navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: WrColors.navy,
          onPrimary: Colors.white,
          secondary: WrColors.teal,
          onSecondary: WrColors.navy,
          surface: WrColors.surface,
          onSurface: WrColors.ink,
          error: WrColors.danger,
          onError: Colors.white,
          outline: WrColors.secondaryInk,
          outlineVariant: WrColors.border,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: 'cairo',
      scaffoldBackgroundColor: WrColors.canvas,
      textTheme: const TextTheme(
        bodyLarge: WrType.body,
        bodyMedium: WrType.support,
        titleMedium: WrType.section,
        headlineSmall: WrType.page,
        headlineMedium: WrType.keyValue,
      ).apply(bodyColor: WrColors.ink, displayColor: WrColors.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WrColors.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: WrSpace.md,
          vertical: WrSpace.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WrRadius.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WrRadius.control),
          borderSide: const BorderSide(color: WrColors.border),
        ),
      ),
      dividerColor: WrColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: WrColors.surface,
        foregroundColor: WrColors.ink,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
