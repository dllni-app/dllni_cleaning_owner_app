import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/worker_app_colors.dart';

class MissionTimerCard extends StatelessWidget {
  const MissionTimerCard({
    super.key,
    required this.serviceDate,
    required this.statusText,
    required this.titleText,
    required this.valueText,
    required this.gradientColors,
    this.helperText,
    this.startTimeLabel,
    this.startTimeValue,
    this.endTimeLabel,
    this.endTimeValue,
  });

  final String serviceDate;
  final String statusText;
  final String titleText;
  final String valueText;
  final String? helperText;
  final List<Color> gradientColors;
  final String? startTimeLabel;
  final String? startTimeValue;
  final String? endTimeLabel;
  final String? endTimeValue;

  bool get _hasTwoTimes => startTimeValue != null && endTimeValue != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WorkerAppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WorkerAppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.labelLarge(
                  serviceDate,
                  color: WorkerAppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WorkerAppColors.brandPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AppText.labelMedium(
                  statusText,
                  color: WorkerAppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WorkerAppColors.canvas,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: WorkerAppColors.brandPrimary,
                  size: 26,
                ),
                const SizedBox(height: 7),
                AppText.bodyMedium(
                  titleText,
                  color: WorkerAppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                AppText.headlineMedium(
                  valueText,
                  color: WorkerAppColors.brandPrimary,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                if (_hasTwoTimes) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: WorkerAppColors.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeColumn(
                          label: startTimeLabel ?? '',
                          value: startTimeValue!,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: WorkerAppColors.border,
                      ),
                      Expanded(
                        child: _TimeColumn(
                          label: endTimeLabel ?? '',
                          value: endTimeValue!,
                        ),
                      ),
                    ],
                  ),
                ],
                if (helperText != null) ...[
                  const SizedBox(height: 12),
                  AppText.bodySmall(
                    helperText!,
                    color: WorkerAppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.bodySmall(
          label,
          color: WorkerAppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        AppText.bodyLarge(
          value,
          color: WorkerAppColors.textPrimary,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
