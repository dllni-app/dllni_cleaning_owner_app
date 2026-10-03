import 'package:flutter/material.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_surface_card.dart';

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
    return WorkerSurfaceCard(
      onTap: onTap,
      shadow: false,
      radius: WorkerAppRadius.lg,
      padding: const EdgeInsetsDirectional.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: containerColor,
            ),
            alignment: Alignment.center,
            child: Icon(image, size: 22, color: imageColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: WorkerAppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 8),
                      titleTrailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WorkerAppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: WorkerAppColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}
