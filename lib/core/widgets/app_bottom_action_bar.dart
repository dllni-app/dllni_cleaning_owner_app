import 'package:flutter/material.dart';

import '../theme/app_layout.dart';

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpace.md,
      AppSpace.sm,
      AppSpace.md,
      AppSpace.sm,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.16),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpace.xs),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
