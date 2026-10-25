import 'package:flutter/material.dart';

import '../../../../../core/theme/worker_app_colors.dart';

/// A compact task section shared by the worker's specialized detail screens.
class WorkerDetailSection extends StatelessWidget {
  const WorkerDetailSection({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.checklist_rounded,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WorkerAppColors.surface,
      border: Border.all(color: WorkerAppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: WorkerAppColors.brandPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}
