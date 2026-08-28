import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;

  static EdgeInsetsDirectional pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return EdgeInsetsDirectional.symmetric(horizontal: width >= 600 ? xl : md);
  }
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppIconSize {
  static const sm = 18.0;
  static const md = 24.0;
  static const lg = 28.0;
  static const xl = 40.0;
}

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);

  static Duration resolved(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

abstract final class AppGradients {
  static const hero = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[Color(0xFF1E2A7B), Color(0xFF0F766E)],
  );

  static const heroSoft = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[Color(0xFFE8ECFF), Color(0xFFD7F5F1)],
  );
}

abstract final class AppShadows {
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x1A172033), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0F172033), blurRadius: 14, offset: Offset(0, 4)),
  ];
}
