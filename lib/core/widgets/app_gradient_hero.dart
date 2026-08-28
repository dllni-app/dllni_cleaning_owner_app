import 'package:flutter/material.dart';

import '../theme/app_layout.dart';

class AppGradientHero extends StatelessWidget {
  const AppGradientHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.child,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title، $subtitle',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        decoration: const BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  trailing!,
                ],
              ],
            ),
            if (child != null) ...[const SizedBox(height: AppSpace.lg), child!],
          ],
        ),
      ),
    );
  }
}
