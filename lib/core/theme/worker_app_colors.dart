import 'package:flutter/material.dart';

/// Visual tokens approved in the worker-app Pen design system.
abstract final class WorkerAppColors {
  static const brandPrimary = Color(0xFF1E2A7B);
  static const brandPrimaryStrong = Color(0xFF28399B);
  static const brandPrimarySoft = Color(0xFFE9ECF8);
  static const accent = Color(0xFF2EC4B6);
  static const secondary = Color(0xFF6C63FF);

  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFFF7ED);
  static const danger = Color(0xFFD92341);
  static const dangerSoft = Color(0xFFFFF1F2);
  static const info = Color(0xFF0284C7);
  static const infoSoft = Color(0xFFF0F9FF);
}

abstract final class WorkerAppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class WorkerAppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

abstract final class WorkerAppDurations {
  static const control = Duration(milliseconds: 120);
  static const stateChange = Duration(milliseconds: 180);
  static const overlay = Duration(milliseconds: 240);
}
