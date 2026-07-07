import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

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

  bool get _hasTwoTimes =>
      startTimeValue != null && endTimeValue != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradientColors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelLarge(serviceDate, color: Colors.white),
              AppText.labelLarge(
                statusText,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_hasTwoTimes)
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
                        color: Colors.white.withAlpha(64),
                      ),
                      Expanded(
                        child: _TimeColumn(
                          label: endTimeLabel ?? '',
                          value: endTimeValue!,
                        ),
                      ),
                    ],
                  )
                else ...[
                  AppText.bodyMedium(
                    titleText,
                    color: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  AppText.bodyLarge(
                    valueText,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (helperText != null) ...[
                  const SizedBox(height: 6),
                  AppText.bodySmall(
                    helperText!,
                    color: Colors.white,
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
  const _TimeColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.bodySmall(
          label,
          color: Colors.white,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        AppText.bodyLarge(
          value,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
