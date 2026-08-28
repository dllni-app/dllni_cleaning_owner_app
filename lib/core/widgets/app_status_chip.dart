import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

enum AppStatusTone { success, warning, danger, info, neutral }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colors = switch (tone) {
      AppStatusTone.success => (semantic.successContainer, semantic.success),
      AppStatusTone.warning => (semantic.warningContainer, semantic.warning),
      AppStatusTone.danger => (semantic.dangerContainer, semantic.danger),
      AppStatusTone.info => (semantic.infoContainer, semantic.info),
      AppStatusTone.neutral => (
        Theme.of(context).colorScheme.surfaceContainerHighest,
        semantic.textSecondary,
      ),
    };
    return Semantics(
      label: label,
      child: Chip(
        avatar: icon == null ? null : Icon(icon, size: 16, color: colors.$2),
        label: Text(label),
        labelStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.$2),
        side: BorderSide(color: colors.$2),
        backgroundColor: colors.$1,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
