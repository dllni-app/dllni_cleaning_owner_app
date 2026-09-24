import 'package:flutter/material.dart';

import 'worker_app_colors.dart';

abstract final class WorkerAppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: WorkerAppColors.brandPrimary,
      onPrimary: Colors.white,
      secondary: WorkerAppColors.secondary,
      onSecondary: Colors.white,
      error: WorkerAppColors.danger,
      onError: Colors.white,
      surface: WorkerAppColors.surface,
      onSurface: WorkerAppColors.textPrimary,
      primaryContainer: WorkerAppColors.accent,
      onPrimaryContainer: Colors.white,
      secondaryContainer: WorkerAppColors.brandPrimarySoft,
      onSecondaryContainer: WorkerAppColors.brandPrimary,
      tertiary: WorkerAppColors.info,
      onTertiary: Colors.white,
      tertiaryContainer: WorkerAppColors.infoSoft,
      onTertiaryContainer: WorkerAppColors.info,
      errorContainer: WorkerAppColors.dangerSoft,
      onErrorContainer: WorkerAppColors.danger,
      surfaceContainerLowest: WorkerAppColors.surface,
      surfaceContainerLow: WorkerAppColors.canvas,
      surfaceContainer: WorkerAppColors.surfaceSubtle,
      surfaceContainerHigh: Color(0xFFE9EEF5),
      surfaceContainerHighest: Color(0xFFDDE4EE),
      outline: WorkerAppColors.textSecondary,
      outlineVariant: WorkerAppColors.border,
      shadow: Color(0x160F172A),
      scrim: Color(0x660F172A),
      inverseSurface: WorkerAppColors.textPrimary,
      onInverseSurface: WorkerAppColors.canvas,
      inversePrimary: Color(0xFFBFC8FF),
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: WorkerAppColors.canvas,
      canvasColor: WorkerAppColors.canvas,
      dividerColor: WorkerAppColors.border,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: WorkerAppColors.textPrimary,
      displayColor: WorkerAppColors.textPrimary,
      fontFamily: 'cairo',
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: WorkerAppColors.surface,
        foregroundColor: WorkerAppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: WorkerAppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(WorkerAppRadius.lg)),
          side: BorderSide(color: WorkerAppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: WorkerAppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: WorkerAppColors.brandPrimary,
        linearTrackColor: WorkerAppColors.brandPrimarySoft,
        circularTrackColor: WorkerAppColors.brandPrimarySoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WorkerAppColors.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          borderSide: const BorderSide(color: WorkerAppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          borderSide: const BorderSide(
            color: WorkerAppColors.brandPrimary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          borderSide: const BorderSide(color: WorkerAppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          borderSide: const BorderSide(
            color: WorkerAppColors.danger,
            width: 1.5,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: WorkerAppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: WorkerAppColors.surface,
        modalBarrierColor: Color(0x730F172A),
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WorkerAppRadius.lg),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: WorkerAppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(WorkerAppRadius.lg)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WorkerAppColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'cairo'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(WorkerAppRadius.md)),
        ),
      ),
    );
  }
}
