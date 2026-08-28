import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import '../theme/app_semantic_colors.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(AppSpace.md),
    this.onTap,
    this.semanticLabel,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final material = Material(
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: emphasized ? 2 : 0,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.semanticColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null && semanticLabel == null) return material;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: material,
    );
  }
}
