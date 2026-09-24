import 'package:flutter/material.dart';

import '../theme/worker_app_colors.dart';

enum WorkerActionButtonVariant { primary, secondary, destructive, neutral }

class WorkerActionButton extends StatelessWidget {
  const WorkerActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = WorkerActionButtonVariant.primary,
    this.height = 50,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final WorkerActionButtonVariant variant;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final colors = switch (variant) {
      WorkerActionButtonVariant.primary => (
        WorkerAppColors.brandPrimary,
        Colors.white,
        WorkerAppColors.brandPrimary,
      ),
      WorkerActionButtonVariant.secondary => (
        WorkerAppColors.brandPrimarySoft,
        WorkerAppColors.brandPrimary,
        WorkerAppColors.brandPrimarySoft,
      ),
      WorkerActionButtonVariant.destructive => (
        WorkerAppColors.dangerSoft,
        WorkerAppColors.danger,
        WorkerAppColors.danger,
      ),
      WorkerActionButtonVariant.neutral => (
        WorkerAppColors.surfaceSubtle,
        WorkerAppColors.textSecondary,
        WorkerAppColors.border,
      ),
    };

    final background = enabled ? colors.$1 : WorkerAppColors.surfaceSubtle;
    final foreground = enabled ? colors.$2 : WorkerAppColors.textTertiary;
    final border = enabled ? colors.$3 : WorkerAppColors.border;

    final button = SizedBox(
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(WorkerAppRadius.md),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: foreground),
                if (loading || icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
