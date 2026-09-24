import 'package:flutter/material.dart';

import '../theme/worker_app_colors.dart';

class WorkerSurfaceCard extends StatelessWidget {
  const WorkerSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsetsDirectional.all(16),
    this.margin,
    this.backgroundColor = WorkerAppColors.surface,
    this.borderColor = WorkerAppColors.border,
    this.borderWidth = 1,
    this.radius = WorkerAppRadius.lg,
    this.shadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadow
          ? const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );

    final body = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: body,
      ),
    );
  }
}
