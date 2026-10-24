import 'package:flutter/material.dart';

/// Primitive brand and surface colors; semantic roles are assigned in the theme.
abstract final class WrColors {
  static const navy = Color(0xFF1E2A7B);
  static const navyStrong = Color(0xFF28399B);
  static const teal = Color(0xFF2EC4B6);
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const ink = Color(0xFF0F172A);
  static const secondaryInk = Color(0xFF475569);
  static const border = Color(0xFFD9E1EA);
  static const success = Color(0xFF065F46);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFF92400E);
  static const warningBg = Color(0xFFFFF7ED);
  static const danger = Color(0xFF9F1239);
  static const dangerBg = Color(0xFFFFF1F2);
  static const info = Color(0xFF075985);
  static const infoBg = Color(0xFFF0F9FF);
}

abstract final class WrSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class WrRadius {
  static const control = 12.0;
  static const panel = 16.0;
  static const sheet = 24.0;
}

abstract final class WrMotion {
  static const control = Duration(milliseconds: 150);
  static const overlay = Duration(milliseconds: 220);
}

/// Cairo font styles use explicit line heights to preserve Arabic marks.
abstract final class WrType {
  static const body = TextStyle(fontFamily: 'cairo', fontSize: 16, height: 1.5);
  static const support = TextStyle(
    fontFamily: 'cairo',
    fontSize: 14,
    height: 22 / 14,
  );
  static const section = TextStyle(
    fontFamily: 'cairo',
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w700,
  );
  static const page = TextStyle(
    fontFamily: 'cairo',
    fontSize: 24,
    height: 34 / 24,
    fontWeight: FontWeight.w700,
  );
  static const keyValue = TextStyle(
    fontFamily: 'cairo',
    fontSize: 28,
    height: 38 / 28,
    fontWeight: FontWeight.w700,
  );
}
