import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'app_layout.dart';

abstract final class AppTheme {
  static const navy = Color(0xFF1E2A7B);
  static const interactiveTeal = Color(0xFF0F766E);
  static const brandTeal = Color(0xFF2EC4B6);
  static const background = Color(0xFFF7F8FC);
  static const text = Color(0xFF172033);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'cairo',
    colorScheme: const ColorScheme.light(
      primary: navy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE4FF),
      onPrimaryContainer: navy,
      secondary: interactiveTeal,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD7F5F1),
      onSecondaryContainer: Color(0xFF064E49),
      tertiary: brandTeal,
      onTertiary: Color(0xFF073B4C),
      surface: Colors.white,
      onSurface: text,
      surfaceContainerHighest: Color(0xFFEAEFF6),
      outline: Color(0xFF687386),
      outlineVariant: Color(0xFFD5DAE3),
      error: Color(0xFFB42318),
      onError: Colors.white,
      errorContainer: Color(0xFFFFE9E7),
      onErrorContainer: Color(0xFF65120E),
    ),
    scaffoldBackgroundColor: background,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    ).apply(bodyColor: text, displayColor: text),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: text,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: AppSpace.md,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        side: BorderSide(color: Color(0xFFD5DAE3)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        side: const BorderSide(color: interactiveTeal),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'cairo',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: interactiveTeal,
      ),
    ),
    chipTheme: const ChipThemeData(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
      shape: StadiumBorder(),
      side: BorderSide(color: Color(0xFFD5DAE3)),
      labelStyle: TextStyle(
        fontFamily: 'cairo',
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFFD5DAE3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFFD5DAE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: interactiveTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFFB42318)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFD5DAE3), space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      showDragHandle: true,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Color(0xFFD7F5F1),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    extensions: const [
      AppSemanticColors(
        textPrimary: text,
        textSecondary: Color(0xFF4F5B70),
        border: Color(0xFFD5DAE3),
        success: Color(0xFF087443),
        onSuccess: Colors.white,
        successContainer: Color(0xFFDDF8E9),
        warning: Color(0xFF8A4B00),
        onWarning: Colors.white,
        warningContainer: Color(0xFFFFF1D6),
        danger: Color(0xFFB42318),
        onDanger: Colors.white,
        dangerContainer: Color(0xFFFFE9E7),
        info: Color(0xFF155E9B),
        infoContainer: Color(0xFFE1F0FF),
      ),
    ],
  );
}
