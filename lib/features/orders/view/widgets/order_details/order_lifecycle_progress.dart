import 'package:flutter/material.dart';

import '../../../../../core/theme/app_layout.dart';

class OrderLifecycleProgress extends StatelessWidget {
  const OrderLifecycleProgress({super.key, required this.currentStep});

  final int currentStep;

  static const _labels = <String>['الطلب', 'الطريق', 'التحقق', 'المهمة'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = currentStep.clamp(0, _labels.length - 1);

    return Semantics(
      container: true,
      label: 'مرحلة ${_labels[step]}، ${step + 1} من ${_labels.length}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < _labels.length; index++) ...[
                Expanded(
                  child: _LifecycleStep(
                    label: _labels[index],
                    index: index,
                    isCurrent: index == step,
                    isComplete: index < step,
                  ),
                ),
                if (index < _labels.length - 1)
                  Container(
                    width: AppSpace.lg,
                    height: 2,
                    margin: const EdgeInsets.only(top: 15),
                    color: index < step
                        ? colorScheme.tertiary
                        : colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LifecycleStep extends StatelessWidget {
  const _LifecycleStep({
    required this.label,
    required this.index,
    required this.isCurrent,
    required this.isComplete,
  });

  final String label;
  final int index;
  final bool isCurrent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = isCurrent || isComplete;
    final background = isCurrent
        ? colorScheme.primary
        : isComplete
        ? colorScheme.tertiary
        : colorScheme.surfaceContainerHighest;
    final foreground = active
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: isCurrent,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppMotion.resolved(context, AppMotion.quick),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isComplete
                ? Icon(Icons.check_rounded, size: 18, color: foreground)
                : Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? colorScheme.primary : colorScheme.outline,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
