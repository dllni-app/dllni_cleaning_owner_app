import 'package:flutter/material.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/widgets/app_surface_card.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.containerColor,
    required this.imageColor,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleTrailing,
  });

  final Color containerColor;
  final Color imageColor;
  final IconData image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppSurfaceCard(
      onTap: onTap,
      semanticLabel: '$title، $subtitle',
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: containerColor,
            ),
            child: Icon(image, size: AppIconSize.md, color: imageColor),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      titleTrailing!,
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AppIconSize.sm,
            color: colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
