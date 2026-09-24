import 'package:flutter/material.dart';

import '../theme/worker_app_colors.dart';

class WorkerScreenHeader extends StatelessWidget {
  const WorkerScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.action,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WorkerAppColors.surface,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: WorkerAppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WorkerAppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

class WorkerHeaderAction extends StatelessWidget {
  const WorkerHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: WorkerAppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: WorkerAppColors.brandPrimary, size: 24),
                if (badge != null && badge!.isNotEmpty)
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WorkerAppColors.danger,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
